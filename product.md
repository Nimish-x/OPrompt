# Project: OPrompt (Universal Prompt Optimizer)

## Vision
A native macOS desktop utility that acts as a "Universal AI Translation Layer." It bridges the gap between a human's rough, messy thoughts and the highly structured, constraint-heavy prompts required by advanced LLMs. 

## Core Capabilities
- **Global Activation:** Trigger the optimizer from any application via a system-wide hotkey (`Cmd+Shift+O`).
- **In-Place Replacement:** Automatically reads the user's text, optimizes it, and replaces it natively.
- **Auto-Select:** If no text is highlighted, the app automatically selects all text in the active field before optimizing.
- **App-Aware Context:** Reads the macOS `NSWorkspace` to detect the frontmost app (e.g., Xcode, Chrome) and silently injects environment context into the AI.
- **Ghost Templates:** Users can type a bracketed tag (e.g., `[SEO]`) anywhere in their text to force the LLM to adopt that specific persona.
- **Intelligent Routing (The Standalone Test):** Differentiates between new ideas (which get the heavy 4-Pillar optimization) and conversational follow-ups (which bypass the 4-Pillars to preserve the target AI's context).
- **Soft Memory (Context-Aware Mode):** An optional Beta feature that maintains a short-term, sliding-expiration (15m) history of the last 5 prompts. It isolates history strictly by App Name and Window Title (e.g., separating ChatGPT and Claude tabs) to provide context for ambiguous follow-up requests.

## Target User Requirements
1. **Zero Friction:** No web interfaces. Optimization happens entirely in-place.
2. **Speed & Intelligence:** Uses Groq Cloud API with Meta's **Llama 3.3 70B Versatile** model for maximum reasoning capabilities in under 2 seconds.
3. **Browser Compatibility:** Uses a Clipboard Fallback (Cmd+C/Cmd+V) mechanism to support complex web apps (SPAs) where native macOS Accessibility APIs fail.

## The 4-Pillar Meta-Prompting Structure
The AI does not fulfill the task; it outputs a master-level prompt from the **First-Person POV** containing:
1. **Role:** (e.g., "Act as a Senior iOS Developer")
2. **Task:** The core goal.
3. **Tone & Emotion:** Inferred from the user's rough input.
4. **Constraints/Format:** Guardrails (e.g., word counts, "output only code").

## Technical Stack
- **Engine:** Swift (Native macOS App)
- **UI Framework:** Pure SwiftUI (`MenuBarExtra` and `SettingsLink`)
- **Automation:** macOS Accessibility API (`AXUIElement`), `NSEvent` (Global Hotkeys), and `CGEvent` / `NSPasteboard` (Clipboard Fallback).
- **AI Orchestration:** Groq API (Llama 3.3 70B). *Ready for future Ollama integration.*
