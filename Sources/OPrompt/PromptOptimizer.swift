import Foundation

/// The PromptOptimizer is the "Brain" of the application. 
/// It takes raw text and uses an LLM to rewrite it into a highly effective prompt.
@MainActor
class PromptOptimizer {
    
    private let endpoint = "https://api.groq.com/openai/v1/chat/completions"
    private var apiKey: String
    private let targetModel = "llama-3.3-70b-versatile"
    
    /// The System Prompt is what makes the LLM act like an optimizer rather than a chatbot.
    private var baseSystemInstruction: String {
        return """
        You are a Universal Prompt Optimizer. Your ONLY job is to rewrite the user's raw text.
        CRITICAL RULE: YOU MUST NEVER ANSWER THE USER'S QUESTION OR FULFILL THE TASK. You are NOT a conversational assistant. DO NOT say "Please provide more context." You ONLY output the rewritten text.

        CRITICAL STEP 1: ROUTING (PATH A vs PATH B)
        Analyze the input:
        - If the input is a complete, brand new thought (e.g. "Write an essay about AI"): Route to PATH A.
        - If the input starts with words like "also", "but", "remove", "change", OR if "SOFT MEMORY ACTIVE" history is provided below: YOU MUST ROUTE TO PATH B.

        =========================================
        PATH A: HEAVY OPTIMIZATION (For brand new tasks only)
        =========================================
        Create a master-prompt from the FIRST-PERSON POV ("I need") with:
        - Role: (e.g., "Act as a Senior Developer")
        - Task: What needs to be done.
        - Tone: Dictate the tone.
        - Constraints: Smart guardrails.

        =========================================
        PATH B: CONTEXTUAL FOLLOW-UP (For ongoing chats / revisions)
        =========================================
        The user is talking to another AI in an ongoing chat. DO NOT use the heavy 4-pillars (Role, Task, Tone, Constraints).
        Your job is purely to be a GRAMMAR and CLARITY fixer. 
        - Keep the exact original intent. 
        - Fix typos. 
        - Make it sound professional.
        - Do NOT add a "Role".
        Example Input: "also include the significance of mother in last para"
        Example PATH B Output: "Additionally, please include the significance of mothers in the final paragraph."
        Example Input: "but here i dont like eggs"
        Example PATH B Output: "However, in this specific recipe, I would prefer not to use eggs."

        CRITICAL STEP 2: PRIVACY TAGS
        If you see tags like [REDACTED_EMAIL], treat them as literal strings. Do not remove them.

        CRITICAL STEP 3: OUTPUT FORMATTING
        OUTPUT ABSOLUTELY NOTHING EXCEPT THE FINAL OPTIMIZED STRING.
        """
    }

    init(apiKey: String = "") {
        self.apiKey = apiKey
    }

    /// Takes the raw text, sends it to the LLM, and returns the optimized version.
    func optimize(rawText: String, appName: String? = nil, windowTitle: String? = nil) async throws -> String {
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        
        // Phase 1: Ghost Template Syntax
        let (template, cleanText) = extractTemplate(from: rawText)
        
        var dynamicSystemInstruction = baseSystemInstruction
        if let template = template {
            dynamicSystemInstruction += "\n\nSPECIAL DIRECTIVE: The user has explicitly requested the [\(template)] template. You MUST strictly format the optimized prompt to align with the domain, tone, and goals of '\(template)'."
        }
        
        // Phase 2: App-Aware Context Injection
        if let appName = appName {
            dynamicSystemInstruction += "\n\nENVIRONMENT CONTEXT: The user is currently typing inside the application '\(appName)'. Use this to subtly infer their goal. ABSOLUTE RULE: DO NOT under any circumstances include the application name in your final output. DO NOT say 'browsing on Chrome' or 'working in Xcode'. The application name must remain a secret."
        }
        
        // Phase 3: Soft Memory Injection
        if MemoryManager.shared.isContextAwareModeEnabled, let historyJSON = MemoryManager.shared.getHistoryJSON(appName: appName, windowTitle: windowTitle) {
            dynamicSystemInstruction += "\n\nSOFT MEMORY ACTIVE:\nHere is the short-term local history of the last few prompts sent in this specific app/window. Use this history ONLY to clarify ambiguous follow-ups (e.g., if they say 'make it shorter', refer to the history to know what 'it' is). Do not answer the prompt yourself; just output the optimized follow-up string.\n\nHistory:\n\(historyJSON)"
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": targetModel,
            "messages": [
                ["role": "system", "content": dynamicSystemInstruction],
                ["role": "user", "content": cleanText]
            ],
            "temperature": 0.3
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("API Error: \(String(data: data, encoding: .utf8) ?? "Unknown")")
            throw URLError(.badServerResponse)
        }

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            
            let finalOutput = content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Phase 4: Save to Soft Memory
            MemoryManager.shared.addInteraction(rawInput: rawText, optimizedOutput: finalOutput, appName: appName, windowTitle: windowTitle)
            
            return finalOutput
        }
        
        throw URLError(.cannotParseResponse)
    }
    
    /// Parses the raw text to see if it contains a bracketed tag anywhere (e.g., "check this [Code Review]")
    private func extractTemplate(from text: String) -> (template: String?, cleanText: String) {
        let pattern = "\\[(.*?)\\]"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
            
            if let match = regex.firstMatch(in: text, options: [], range: nsRange) {
                // Extract the template name (the part inside the brackets)
                let matchRange = match.range(at: 1)
                if let swiftRange = Range(matchRange, in: text) {
                    let templateName = String(text[swiftRange])
                    
                    // Remove the entire bracketed tag [TemplateName] from the original text
                    let fullMatchRange = match.range(at: 0)
                    if let fullSwiftRange = Range(fullMatchRange, in: text) {
                        var cleanText = text
                        cleanText.removeSubrange(fullSwiftRange)
                        return (templateName, cleanText.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
            }
        } catch {
            print("Regex error: \(error)")
        }
        
        // No template found, return the original text
        return (nil, text)
    }
}
