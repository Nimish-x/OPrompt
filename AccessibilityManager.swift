import Foundation
import ApplicationServices
import AppKit

/// The AccessibilityManager is responsible for interacting with other applications.
/// It uses the macOS Accessibility API (AXUIElement) as a primary method,
/// and falls back to Clipboard/Keystroke simulation for complex apps like Chrome.
class AccessibilityManager {
    
    /// Errors that can occur during accessibility operations.
    enum AccessibilityError: Error {
        case permissionsNotGranted
        case noFocusedElement
        case secureFieldDetected
        case secureDomainDetected
        case apiError(String)
        case clipboardFailed
    }

    /// Checks if the application has accessibility permissions.
    static func checkPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    // MARK: - Native AXUIElement Methods
    
    private func getFocusedElement() throws -> AXUIElement {
        let systemElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(systemElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        guard result == .success, let element = focusedElement as! AXUIElement? else {
            throw AccessibilityError.noFocusedElement
        }
        
        if isSecureField(element: element) {
            throw AccessibilityError.secureFieldDetected
        }
        
        return element
    }

    private func isSecureField(element: AXUIElement) -> Bool {
        var role: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
        if let roleString = role as? String {
            return roleString == "AXSecureTextField"
        }
        return false
    }

    // MARK: - Main Public Methods (With Fallbacks)

    /// Reads the currently selected text, falling back to Cmd+C if necessary.
    func readText() async throws -> String {
        do {
            // Try the fast, native way first
            let element = try getFocusedElement()
            var textValue: CFTypeRef?
            
            let result = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &textValue)
            if result == .success, let text = textValue as? String, !text.isEmpty {
                return text
            }
            
            let valueResult = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &textValue)
            if valueResult == .success, let text = textValue as? String {
                return text
            }
            
            // If it found the element but couldn't read the text, trigger fallback
            throw AccessibilityError.noFocusedElement
            
        } catch AccessibilityError.noFocusedElement {
            // FALLBACK: Simulate Cmd+C
            print("Native read failed. Falling back to Cmd+C...")
            return try await readFromClipboardFallback()
        }
    }

    /// Replaces the text, falling back to Cmd+V if necessary.
    func replaceText(with newText: String) async throws {
        do {
            // Try the fast, native way first
            let element = try getFocusedElement()
            
            let result = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, newText as CFTypeRef)
            if result != .success {
                let selectResult = AXUIElementSetAttributeValue(element, kAXSelectedTextAttribute as CFString, newText as CFTypeRef)
                if selectResult != .success {
                    throw AccessibilityError.noFocusedElement
                }
            }
        } catch AccessibilityError.noFocusedElement {
            // FALLBACK: Simulate Cmd+V
            print("Native write failed. Falling back to Cmd+V...")
            try await writeToClipboardFallback(text: newText)
        }
    }
    
    // MARK: - Clipboard Fallback Logic
    
    private func readFromClipboardFallback() async throws -> String {
        let pasteboard = NSPasteboard.general
        let previousChangeCount = pasteboard.changeCount
        
        // Attempt 1: Simulate Cmd+C to copy whatever is currently selected
        simulateKeystroke(keyCode: 8, useCommand: true) // 'C' key
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Check if the clipboard actually updated (meaning text was selected)
        if pasteboard.changeCount != previousChangeCount {
            if let copiedText = pasteboard.string(forType: .string), !copiedText.trimmingCharacters(in: .whitespaces).isEmpty {
                return copiedText
            }
        }
        
        // Attempt 2: If we get here, no text was selected. 
        // We will simulate Cmd+A (Select All) and then try Cmd+C again.
        print("No text selected. Triggering Cmd+A to auto-select all text...")
        simulateKeystroke(keyCode: 0, useCommand: true) // 'A' key
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        let secondChangeCount = pasteboard.changeCount
        simulateKeystroke(keyCode: 8, useCommand: true) // 'C' key
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        if pasteboard.changeCount != secondChangeCount {
            if let copiedText = pasteboard.string(forType: .string), !copiedText.trimmingCharacters(in: .whitespaces).isEmpty {
                return copiedText
            }
        }
        
        throw AccessibilityError.clipboardFailed
    }
    
    private func writeToClipboardFallback(text: String) async throws {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Simulate Cmd+V
        simulateKeystroke(keyCode: 9, useCommand: true) // 'V' key
    }
    
    private func simulateKeystroke(keyCode: CGKeyCode, useCommand: Bool) {
        let source = CGEventSource(stateID: .hidSystemState)
        
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        
        if useCommand {
            keyDown?.flags = .maskCommand
            keyUp?.flags = .maskCommand
        }
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    /// Returns the localized name of the currently active (frontmost) application.
    func getFrontmostAppName() -> String? {
        return NSWorkspace.shared.frontmostApplication?.localizedName
    }
    
    /// Returns the title of the frontmost window of the currently active application.
    /// This is crucial for distinguishing between different browser tabs (e.g. "ChatGPT" vs "Claude" in Chrome).
    func getFrontmostWindowTitle() -> String? {
        guard let appName = getFrontmostAppName() else { return nil }
        
        // 1. AppleScript Fast-Path for Known Browsers
        // Chrome hides titles from AXUIElement, so we must use AppleScript.
        // This will prompt the user for "Automation" permissions the first time.
        if ["Google Chrome", "Safari", "Brave Browser", "Arc", "Microsoft Edge"].contains(appName) {
            if let title = getBrowserTitleViaAppleScript(appName: appName) {
                return title
            }
            print("AppleScript failed or returned nil, falling back to AXUIElement for \(appName)...")
        }
        
        // 2. Native AXUIElement Fallback for standard macOS Apps
        let systemElement = AXUIElementCreateSystemWide()
        var focusedApp: CFTypeRef?
        
        let appResult = AXUIElementCopyAttributeValue(systemElement, kAXFocusedApplicationAttribute as CFString, &focusedApp)
        guard appResult == .success, let appElement = focusedApp as! AXUIElement? else {
            return nil
        }
        
        var focusedWindow: CFTypeRef?
        let windowResult = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)
        guard windowResult == .success, let windowElement = focusedWindow as! AXUIElement? else {
            return nil
        }
        
        var title: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(windowElement, kAXTitleAttribute as CFString, &title)
        
        if titleResult == .success, let titleString = title as? String, !titleString.isEmpty {
            return titleString
        }
        
        return nil
    }
    
    /// Checks if the frontmost app is a browser currently on a blocked domain.
    func isFrontmostAppOnBlockedDomain() -> Bool {
        guard let appName = getFrontmostAppName() else { return false }
        
        if ["Google Chrome", "Safari", "Brave Browser", "Arc", "Microsoft Edge"].contains(appName) {
            if let url = getBrowserURLViaAppleScript(appName: appName) {
                print("Detected URL: \(url)")
                return PrivacyManager.shared.isBlockedDomain(url: url)
            }
        }
        return false
    }
    
    /// Executes a safe, localized AppleScript to grab the active tab URL from supported browsers.
    private func getBrowserURLViaAppleScript(appName: String) -> String? {
        var scriptSource = ""
        
        if appName == "Safari" {
            scriptSource = "tell application \"Safari\" to return URL of front document"
        } else {
            // Chrome, Brave, Arc, Edge all use the Chromium AppleScript dictionary
            scriptSource = "tell application \"\(appName)\" to return URL of active tab of front window"
        }
        
        if let script = NSAppleScript(source: scriptSource) {
            var error: NSDictionary?
            let output = script.executeAndReturnError(&error)
            if error == nil, let url = output.stringValue {
                return url
            }
        }
        
        return nil
    }
    
    /// Executes a safe, localized AppleScript to grab the active tab name from supported browsers.
    private func getBrowserTitleViaAppleScript(appName: String) -> String? {
        var scriptSource = ""
        
        if appName == "Safari" {
            scriptSource = "tell application \"Safari\" to return name of front document"
        } else {
            // Chrome, Brave, Arc, Edge all use the Chromium AppleScript dictionary
            scriptSource = "tell application \"\(appName)\" to return title of active tab of front window"
        }
        
        if let script = NSAppleScript(source: scriptSource) {
            var error: NSDictionary?
            let output = script.executeAndReturnError(&error)
            if error == nil, let title = output.stringValue {
                return title
            } else {
                print("AppleScript Error (likely needs Automation permission): \(String(describing: error))")
            }
        }
        
        return nil
    }
}
