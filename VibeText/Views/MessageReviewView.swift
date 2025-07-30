import SwiftUI

struct MessageReviewView: View {
    let message: Message
    @ObservedObject var viewModel: VoiceCaptureViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var customPrompt: String = ""
    @State private var showCustomPrompt = false
    @State private var editableText: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Message Display
                VStack(alignment: .leading, spacing: 16) {
                    Text("Here's your message:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $editableText)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .frame(minHeight: 100, maxHeight: 300)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                
                // Tone Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose a tone:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(MessageTone.allCases, id: \.self) { tone in
                            Button(action: {
                                Task {
                                    await viewModel.regenerateWithTone(tone)
                                }
                            }) {
                                VStack(spacing: 8) {
                                    Text(tone.emoji)
                                        .font(.title2)
                                    Text(tone.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(message.tone == tone ? Color.blue : Color.gray.opacity(0.1))
                                .foregroundColor(message.tone == tone ? .white : .primary)
                                .cornerRadius(12)
                            }
                            .disabled(viewModel.isProcessing)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Custom Prompt
                VStack(alignment: .leading, spacing: 12) {
                    Button(action: {
                        showCustomPrompt = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add custom instructions")
                        }
                        .foregroundColor(.blue)
                    }
                    .disabled(viewModel.isProcessing)
                    
                    if let customPrompt = message.customPrompt, !customPrompt.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Custom instructions:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(customPrompt)
                                .font(.caption)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    if viewModel.isProcessing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Processing...")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Copy to Clipboard") {
                            UIPasteboard.general.string = editableText
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Review Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Update the message with edited text before dismissing
                        viewModel.updateMessageText(editableText)
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showCustomPrompt) {
            CustomPromptView(
                customPrompt: $customPrompt,
                viewModel: viewModel
            )
        }
        .onAppear {
            // Initialize editable text with the current message
            editableText = message.cleanedText
        }
        .onChange(of: message.cleanedText) { newValue in
            // Update editable text when message is regenerated
            editableText = newValue
        }
    }
}

struct CustomPromptView: View {
    @Binding var customPrompt: String
    @ObservedObject var viewModel: VoiceCaptureViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add custom instructions to refine your message")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Examples:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Make it more excited")
                        Text("• Add that we're bringing snacks")
                        Text("• Make it shorter")
                        Text("• Add more warmth")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                TextEditor(text: $customPrompt)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .frame(minHeight: 80, maxHeight: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                Spacer()
                
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Apply & Regenerate") {
                        Task {
                            await viewModel.regenerateWithCustomPrompt(customPrompt)
                            dismiss()
                        }
                    }
                    .disabled(customPrompt.isEmpty || viewModel.isProcessing)
                    .foregroundColor(.blue)
                }
            }
            .padding()
            .navigationTitle("Custom Instructions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MessageReviewView(
        message: Message(
            originalTranscript: "Hey there, I was thinking we should maybe grab some food later if you're free",
            cleanedText: "Hey! Would you like to grab some food later if you're free?",
            tone: .casual
        ),
        viewModel: VoiceCaptureViewModel(
            speechManager: SpeechManager(),
            messageFormatter: MessageFormatter(settingsManager: SettingsManager()),
            settingsManager: SettingsManager()
        )
    )
} 