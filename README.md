# OPrompt ✨

**A native macOS utility that turns any text field into an AI-powered prompt optimizer.**

OPrompt runs silently in your menu bar. Simply highlight text in *any* application (Chrome, Notes, Slack, etc.), press **Cmd + Shift + O**, and OPrompt will instantly rewrite and optimize your prompt using the Groq API (`llama-3.3-70b-versatile`). 

Crucially, OPrompt is **Context-Aware**. It tracks which app and window you are typing in, maintaining short-term memory of your conversation so follow-up prompts make sense—and strictly isolating that memory when you switch to a new tab or app.

---

## 🚀 Features

*   **Universal Hotkey:** Hit `Cmd + Shift + O` to optimize text anywhere on macOS.
*   **Native Integration:** Uses macOS Accessibility APIs (`AXUIElement`) to seamlessly read and replace text.
*   **Smart Fallbacks:** Automatically falls back to simulating clipboard keystrokes (`Cmd+C` / `Cmd+V`) for apps that block native accessibility (like web browsers).
*   **Context-Aware Memory:** Remembers your last few prompts *per window*. If you ask for a Python script, and then say "make it a web app," OPrompt knows what "it" is.
*   **Strict Memory Isolation:** Switches context instantly. A conversation in ChatGPT will never bleed into a conversation in Claude or Apple Notes.
*   **Lightning Fast:** Powered by Groq's ultra-low-latency inference engine.

## 🛠️ Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/OPrompt.git
   ```
2. **Open in Xcode:**
   Open the folder in Xcode to build and run the application.
3. **API Key Setup:**
   * Run the app. 
   * Click the OPrompt icon `◇` in your macOS Menu Bar.
   * Go to **Settings**.
   * Enter your [Groq API Key](https://console.groq.com/keys). The key is stored securely in your local macOS AppStorage.
4. **Permissions:**
   * On first run, macOS will prompt you to grant **Accessibility** permissions (required to replace text) and **Automation** permissions (required to fetch window titles for context isolation).

## 🧠 How the AI Works

OPrompt is strictly a **Prompt Optimizer**, not an answering engine. It uses strict system prompts to ensure the LLM refines your instruction rather than fulfilling it. 

*   *Input:* `write an essay on women's day`
*   *Output:* `Act as an expert writer and compose a well-structured essay on International Women's Day, incorporating historical context...`

## 👨‍💻 Tech Stack
*   **Language:** Swift 5
*   **Frameworks:** SwiftUI, AppKit
*   **APIs:** macOS Accessibility (`AXUIElement`), NSAppleScript, Groq REST API

## 📝 License
MIT License - feel free to fork, modify, and build upon this!
