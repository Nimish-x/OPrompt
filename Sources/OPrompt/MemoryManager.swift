import Foundation

/// Represents a single interaction within the Soft Memory buffer.
struct MemoryEntry: Codable {
    let timestamp: Date
    let rawInput: String
    let optimizedOutput: String
}

/// Manages a short-term, sliding-expiration local history to provide context for follow-up prompts.
/// It aggressively isolates contexts based on both Application Name and Window Title.
class MemoryManager {
    static let shared = MemoryManager()
    
    // Limits
    private let maxHistoryItems = 5
    private let expirationTimeInterval: TimeInterval = 15 * 60 // 15 minutes
    
    // State
    private var currentContextKey: String?
    private var historyBuffer: [MemoryEntry] = []
    
    // To support SettingsView toggle without forcing logic here
    var isContextAwareModeEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "enableContextAwareMode")
    }

    private init() {}

    /// Generates a unique key based on the app and window.
    /// E.g., "Google Chrome - ChatGPT"
    private func generateContextKey(appName: String?, windowTitle: String?) -> String {
        let app = appName ?? "UnknownApp"
        let window = windowTitle ?? "UnknownWindow"
        return "\(app) - \(window)"
    }

    /// Adds a new interaction to the memory buffer.
    /// It automatically handles context switching and expiration.
    func addInteraction(rawInput: String, optimizedOutput: String, appName: String?, windowTitle: String?) {
        guard isContextAwareModeEnabled else {
            clearMemory() // Ensure memory stays empty if disabled
            return
        }

        let newContextKey = generateContextKey(appName: appName, windowTitle: windowTitle)
        let now = Date()
        
        // 1. Check for Context Switch
        if currentContextKey != newContextKey {
            // User switched apps or tabs (e.g. from ChatGPT to Claude). Flush memory.
            clearMemory()
            currentContextKey = newContextKey
        }
        
        // 2. Check for Time Decay (Sliding Expiration)
        if let lastEntry = historyBuffer.last {
            if now.timeIntervalSince(lastEntry.timestamp) > expirationTimeInterval {
                clearMemory()
            }
        }
        
        // 3. Add to Buffer
        let entry = MemoryEntry(timestamp: now, rawInput: rawInput, optimizedOutput: optimizedOutput)
        historyBuffer.append(entry)
        
        // 4. Enforce Size Limit
        if historyBuffer.count > maxHistoryItems {
            historyBuffer.removeFirst()
        }
    }

    /// Retrieves the current memory buffer formatted as a JSON string for the LLM system prompt.
    /// Returns nil if memory is empty or disabled.
    func getHistoryJSON(appName: String?, windowTitle: String?) -> String? {
        guard isContextAwareModeEnabled else { return nil }
        
        // 1. Proactively check for context switch BEFORE returning history
        let requestedContextKey = generateContextKey(appName: appName, windowTitle: windowTitle)
        if let currentKey = currentContextKey, currentKey != requestedContextKey {
            // Context has changed since the last interaction. The history is irrelevant.
            return nil
        }
        
        guard !historyBuffer.isEmpty else { return nil }
        
        // Before returning, do a quick time decay check against `now`
        // just in case they haven't prompted in 16 mins, but the hotkey was pressed.
        if let lastEntry = historyBuffer.last, Date().timeIntervalSince(lastEntry.timestamp) > expirationTimeInterval {
            clearMemory()
            return nil
        }

        let mappedHistory = historyBuffer.map { entry in
            return [
                "user_input": entry.rawInput,
                "optimized_prompt_sent_to_ai": entry.optimizedOutput
            ]
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: mappedHistory, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            print("MemoryManager: Failed to encode history to JSON: \(error)")
        }
        
        return nil
    }

    /// Flushes the memory buffer manually.
    func clearMemory() {
        historyBuffer.removeAll()
        // We don't necessarily clear the currentContextKey here because
        // we might just be starting a fresh queue in the same context.
    }
}
