import Foundation

struct MemoryEntry: Codable {
    let timestamp: Date
    let rawInput: String
    let optimizedOutput: String
}

class MemoryManager {
    static let shared = MemoryManager()
    
    private let maxHistoryItems = 5
    private let expirationTimeInterval: TimeInterval = 15 * 60
    
    private var currentContextKey: String?
    private var historyBuffer: [MemoryEntry] = []
    
    var isContextAwareModeEnabled: Bool = true

    private init() {}

    private func generateContextKey(appName: String?, windowTitle: String?) -> String {
        let app = appName ?? "UnknownApp"
        let window = windowTitle ?? "UnknownWindow"
        return "\(app) - \(window)"
    }

    func addInteraction(rawInput: String, optimizedOutput: String, appName: String?, windowTitle: String?) {
        let newContextKey = generateContextKey(appName: appName, windowTitle: windowTitle)
        let now = Date()
        
        if currentContextKey != newContextKey {
            print("MemoryManager: Context switch detected (\(newContextKey)). Flushing previous memory.")
            clearMemory()
            currentContextKey = newContextKey
        }
        
        let entry = MemoryEntry(timestamp: now, rawInput: rawInput, optimizedOutput: optimizedOutput)
        historyBuffer.append(entry)
        
        print("MemoryManager: Added interaction to memory. Current buffer size: \(historyBuffer.count)")
    }
    
    func getHistoryJSON() -> String? {
        guard isContextAwareModeEnabled, !historyBuffer.isEmpty else { return nil }
        
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

    func clearMemory() {
        historyBuffer.removeAll()
    }
}

let memory = MemoryManager.shared
// First interaction in ChatGPT
print("--- Interaction 1 (ChatGPT) ---")
print("History JSON Before: \(memory.getHistoryJSON() ?? "nil")")
memory.addInteraction(rawInput: "write an essay on yoga day", optimizedOutput: "optimized yoga day", appName: "Google Chrome", windowTitle: "ChatGPT")
print("History JSON After: \(memory.getHistoryJSON() ?? "nil")")

// Second interaction in Claude (Simulating the bug)
print("\n--- Interaction 2 (Claude) ---")
print("History JSON Before: \(memory.getHistoryJSON() ?? "nil")")
// Wait, the PromptOptimizer calls getHistoryJSON() BEFORE addInteraction()!
let historyBeforeOptimize = memory.getHistoryJSON()
print("History retrieved by PromptOptimizer for Claude: \(historyBeforeOptimize ?? "nil")")
memory.addInteraction(rawInput: "reduce the last para", optimizedOutput: "optimized reduce", appName: "Google Chrome", windowTitle: "New chat - Claude")
print("History JSON After: \(memory.getHistoryJSON() ?? "nil")")
