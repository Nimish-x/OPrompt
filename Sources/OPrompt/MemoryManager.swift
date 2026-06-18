import Foundation

/// Represents a single interaction within the Soft Memory buffer.
struct MemoryEntry: Codable {
    let timestamp: Date
    let rawInput: String
    let optimizedOutput: String
}

/// Manages a short-term, sliding-expiration local history to provide context for follow-up prompts.
/// It aggressively isolates contexts based on both Application Name and Window Title.
@MainActor
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
    func addInteraction(rawInput: String, optimizedOutput: String, appName: String?, windowTitle: String?) {
        guard isContextAwareModeEnabled else {
            clearMemory()
            return
        }

        let newContextKey = generateContextKey(appName: appName, windowTitle: windowTitle)
        let now = Date()
        
        // 1. Check for Context Switch
        if let currentKey = currentContextKey, currentKey != newContextKey {
            // User switched apps or tabs. Flush memory.
            clearMemory()
        }
        
        // Update the context key to the current one
        currentContextKey = newContextKey
        
        // 2. Check for Time Decay
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
    func getHistoryJSON(appName: String?, windowTitle: String?) -> String? {
        guard isContextAwareModeEnabled else { return nil }
        
        let requestedContextKey = generateContextKey(appName: appName, windowTitle: windowTitle)
        
        // If the context doesn't match our current tracking, history is irrelevant.
        if let currentKey = currentContextKey, currentKey != requestedContextKey {
            return nil
        }
        
        guard !historyBuffer.isEmpty else { return nil }
        
        // Time decay check
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
            // Silently fail encoding
        }
        
        return nil
    }

    func clearMemory() {
        historyBuffer.removeAll()
    }
}
