import SwiftUI

struct SettingsView: View {
    // AppStorage automatically saves this to macOS UserDefaults
    @AppStorage("groqAPIKey") private var apiKey: String = ""
    @AppStorage("enableContextAwareMode") private var enableContextAwareMode: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("OPrompt Settings")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Groq API Key (Llama 3.3 70B)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                SecureField("Enter your gsk_... key here", text: $apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
                
                Text("Required for cloud-based optimization.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Enable Context-Aware Mode (Beta)", isOn: $enableContextAwareMode)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(enableContextAwareMode ? "Memory Active: OPrompt will remember your last few prompts to better understand follow-ups like 'make it shorter'." : "Memory Disabled: OPrompt will only aggressively optimize your first prompt and safely pass-through follow-ups.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Done") {
                    NSApplication.shared.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 350, height: 260)
    }
}
