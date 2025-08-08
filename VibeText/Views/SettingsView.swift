import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    // BYOK state removed
    
    var body: some View {
        NavigationView {
            Form {
                // BYOK UI removed
                
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
                            // BYOK: removed
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
        // BYOK state removed
    }
}

#Preview {
    SettingsView(settingsManager: SettingsManager())
} 