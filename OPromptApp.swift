import SwiftUI

@main
struct OPromptApp: App {
    // We still need the delegate to handle the background hotkey listening on launch
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Native SwiftUI Menu Bar implementation
        MenuBarExtra("OPrompt", systemImage: "wand.and.stars") {
            // Using the native SettingsLink which macOS was asking for!
            SettingsLink {
                Text("Settings...")
            }
            .keyboardShortcut(",", modifiers: .command)
            
            Divider()
            
            Button("Quit OPrompt") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        
        // The Settings Window
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    // Core Components
    let hotkeyManager = HotkeyManager()
    let accessibilityManager = AccessibilityManager()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Check Accessibility Permissions on launch
        if !AccessibilityManager.checkPermissions() {
            print("WARNING: Accessibility permissions not granted. The app cannot read/write text.")
        }
        
        // 2. Start listening for the trigger (Cmd + Shift + O)
        hotkeyManager.startListening { [weak self] in
            self?.handleOptimizationTrigger()
        }
    }
    
    // MARK: - Core Execution Loop
    
    private func handleOptimizationTrigger() {
        print("Optimization triggered...")
        
        let savedKey = UserDefaults.standard.string(forKey: "groqAPIKey") ?? ""
        
        // Enforce the API key for Groq
        if savedKey.isEmpty {
            print("Error: No API Key found for Groq. Please enter it in Settings.")
            if #available(macOS 13.0, *) {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            return
        }
        
        let optimizer = PromptOptimizer(apiKey: savedKey)
        
        // Grab the name and window of the app the user is currently typing in
        let activeAppName = accessibilityManager.getFrontmostAppName()
        let activeWindowTitle = accessibilityManager.getFrontmostWindowTitle()
        
        Task {
            do {
                // Pre-flight check: Ensure we aren't on a secure domain (e.g. banking)
                if accessibilityManager.isFrontmostAppOnBlockedDomain() {
                    throw AccessibilityManager.AccessibilityError.secureDomainDetected
                }
                
                // Step 1: Read the text safely (now async because of fallback)
                let rawText = try await accessibilityManager.readText()
                print("Read text: \(rawText) from app: \(activeAppName ?? "Unknown") (\(activeWindowTitle ?? "Unknown Window"))")
                
                // Step 2: Privacy Filter - Redact any PII (Email, Phone, CC, SSN) before sending
                let scrubbedText = PrivacyManager.shared.redactPII(from: rawText)
                if rawText != scrubbedText {
                    print("Privacy Warning: Sensitive information redacted before optimization.")
                }
                
                // Step 3: Send to Groq for optimization (passing the scrubbed text and app context!)
                let optimizedText = try await optimizer.optimize(rawText: scrubbedText, appName: activeAppName, windowTitle: activeWindowTitle)
                print("Optimized text: \(optimizedText)")
                
                // Step 4: Put the text back
                await MainActor.run {
                    Task {
                        do {
                            try await accessibilityManager.replaceText(with: optimizedText)
                            print("Text successfully replaced!")
                        } catch {
                            print("Failed to write text: \(error)")
                        }
                    }
                }
                
            } catch AccessibilityManager.AccessibilityError.secureFieldDetected {
                print("Safe Mode: Ignored password field.")
            } catch AccessibilityManager.AccessibilityError.secureDomainDetected {
                print("Safe Mode: Execution blocked on secure domain.")
            } catch {
                print("Optimization flow failed: \(error)")
            }
        }
    }
}
