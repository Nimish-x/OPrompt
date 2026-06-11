# Project Context: OPrompt

## Current Status: V1 Core Complete
- **Goal:** Build a "superb" native macOS prompt optimizer.
- **Key Decision:** Use Swift and pure SwiftUI (`MenuBarExtra`) for a seamless, background-first experience.
- **AI Provider:** Upgraded to Groq API using **Llama 3.3 70B** for maximum contextual reasoning and instruction-following.

## Architecture Highlights
1. **The Settings UI:** Pure SwiftUI `SettingsView` using `@AppStorage` for secure API Key management and feature toggles (Context-Aware Mode).
2. **Robust Accessibility (`AccessibilityManager.swift`):**
    - Uses native `AXUIElement` for fast text replacement in native apps.
    - Uses AppleScript specifically to extract frontmost tab titles in browsers.
    - Implements a **Clipboard Fallback (`CGEvent`)** to support browsers and Electron apps.
3. **The "Brain" (`PromptOptimizer.swift`):**
    - Uses a Regex parser to dynamically extract `[Ghost Templates]`.
    - Employs a strict "Standalone Test" to route inputs. New requests get a "4-Pillar" First-Person system prompt. Follow-ups bypass the heavy formatting and receive minimal clarity/grammar fixes.
4. **Soft Memory (`MemoryManager.swift`):**
    - A Ring Buffer (max 5 items) with a 15-minute sliding expiration.
    - Aggressively isolates conversational history using a combined key of `AppName + WindowTitle` to prevent context bleeding between different browser tabs (e.g., ChatGPT vs Claude).

## Next Steps (Future Roadmap)
1. **Local Privacy Mode:** Re-introduce the Ollama toggle for offline enterprise usage.
2. **Auto-Routing:** Automatically open the target AI (ChatGPT/Claude) after optimization.
