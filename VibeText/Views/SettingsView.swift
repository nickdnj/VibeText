import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    @State private var tempAPIKey: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var lastButtonPressed: String = "none" // Debug tracking
    
    var body: some View {
        NavigationView {
            Form {
                Section("OpenAI API Key") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("API Key")
                                .font(.headline)
                            Spacer()
                            if settingsManager.isUsingDefaultKey {
                                Text("Using Default")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        SecureField("Enter your OpenAI API key", text: $tempAPIKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("Your API key is stored securely in the device keychain.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Debug info
                        Text("Last button pressed: \(lastButtonPressed)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    HStack {
                        Button("Save Key") {
                            lastButtonPressed = "Save Key"
                            print("🔵 Save Key button tapped with value: '\(tempAPIKey)'")
                            
                            // Validate the API key format (OpenAI keys start with "sk-")
                            if tempAPIKey.hasPrefix("sk-") {
                                print("✅ Valid key detected, saving...")
                                settingsManager.saveAPIKey(tempAPIKey)
                                alertMessage = "API key saved successfully!"
                                showAlert = true
                            } else if tempAPIKey.isEmpty {
                                print("❌ Empty key detected")
                                alertMessage = "Please enter a valid API key"
                                showAlert = true
                            } else {
                                print("❌ Invalid key format detected: '\(tempAPIKey)'")
                                alertMessage = "Invalid API key format. OpenAI keys start with 'sk-'"
                                showAlert = true
                            }
                        }
                        .disabled(tempAPIKey.isEmpty)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    }
                    
                    HStack {
                        Button("Reset to Default") {
                            lastButtonPressed = "Reset to Default"
                            print("🟠 Reset to Default button tapped")
                            settingsManager.resetToDefaultKey()
                            tempAPIKey = ""
                            alertMessage = "Reset to default key"
                            showAlert = true
                        }
                        .foregroundColor(.orange)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
                
                Section("Voice & Tone Settings") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Default Voice Tone")
                            .font(.headline)
                        
                        Text("This tone will be used for the first message in each session. Subsequent messages will use the last selected tone unless changed.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Default Tone", selection: $settingsManager.defaultTone) {
                            ForEach(MessageTone.allCases, id: \.self) { tone in
                                Text(tone.displayName)
                                    .tag(tone)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: settingsManager.defaultTone) { _, newTone in
                            settingsManager.saveDefaultTone(newTone)
                        }
                    }
                }
                
                Section("App Information") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Default Tone")
                        Spacer()
                        Text(settingsManager.defaultTone.displayName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Last Used Tone")
                        Spacer()
                        Text(settingsManager.lastUsedTone.displayName)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("About") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("VibeText transforms your voice into perfectly crafted messages tailored for any audience.")
                            .font(.body)
                        
                        Text("Features:")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Voice-to-text transcription")
                            Text("• AI-powered message cleanup")
                            Text("• Tone transformation (Professional, Gen Z, etc.)")
                            Text("• Custom prompt refinement")
                            Text("• Secure API key storage")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            tempAPIKey = settingsManager.openAIAPIKey
        }
        .alert("Settings", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

#Preview {
    SettingsView(settingsManager: SettingsManager())
} 