import SwiftUI

struct SettingsView: View {
    // AppStorage automatically saves this to macOS UserDefaults
    @AppStorage("groqAPIKey") private var apiKey: String = ""
    @AppStorage("enableContextAwareMode") private var enableContextAwareMode: Bool = false
    
    var body: some View {
        TabView {
            // MARK: - General Settings
            Form {
                Section(header: Text("API Configuration").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Groq API Key (Llama 3.3 70B)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        SecureField("Enter your gsk_... key here", text: $apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("Required for ultra-fast, cloud-based prompt optimization.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 10)
                
                Section(header: Text("Features").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Enable Context-Aware Mode (Beta)", isOn: $enableContextAwareMode)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(enableContextAwareMode ? "Memory Active: OPrompt temporarily remembers your recent prompts (per app/tab) to understand follow-ups like 'make it shorter'." : "Memory Disabled: OPrompt will treat every request independently and bypass optimization for short follow-ups.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(20)
            .tabItem {
                Label("General", systemImage: "gearshape")
            }
            
            // MARK: - Help & Usage
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How to use OPrompt")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HelpRow(icon: "keyboard", title: "Global Hotkey", description: "Highlight any rough text (or select nothing to auto-select all) and press Cmd+Shift+O to optimize it in-place.")
                        
                        HelpRow(icon: "tag", title: "Ghost Templates", description: "Type a bracketed tag like [SEO] or [Code] anywhere in your text. The AI will adopt that specific persona when optimizing.")
                        
                        HelpRow(icon: "brain.head.profile", title: "Smart Routing", description: "OPrompt detects if you are starting a new idea (full optimization) or just replying to the AI (preserves context).")
                        
                        HelpRow(icon: "lock.shield", title: "Privacy First", description: "Text is only processed when you press the hotkey. Soft Memory (if enabled) expires after 15 minutes and stays local.")
                    }
                    .padding(.vertical, 10)
                    
                    Text("Troubleshooting")
                        .font(.headline)
                    
                    Text("If replacement fails in some web apps (like Notion or ChatGPT), OPrompt uses a clipboard fallback. You might see a quick copy/paste flash—this is normal.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
            }
            .tabItem {
                Label("Help & Usage", systemImage: "questionmark.circle")
            }
        }
        .frame(minWidth: 450, idealWidth: 500, minHeight: 350, idealHeight: 400)
    }
}

// Helper view for the Help section
struct HelpRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
