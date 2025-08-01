import SwiftUI

struct MessageReviewView: View {
    let message: Message
    @ObservedObject var viewModel: VoiceCaptureViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var customPrompt: String = ""
    @State private var showCustomPrompt = false
    @State private var editableText: String = ""
    @State private var isRegenerating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Message Display - Fixed at top
                VStack(alignment: .leading, spacing: 16) {
                    Text("Here's your message:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ZStack(alignment: .topLeading) {
                        // Background with iMessage-style appearance
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(UIColor.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color(UIColor.systemGray4), lineWidth: 0.5)
                            )
                        
                        // Multiline, scrollable TextEditor
                        TextEditor(text: $editableText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.clear)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 140, maxHeight: 240)
                        
                        // Placeholder text when empty
                        if editableText.isEmpty {
                            Text("Your message will appear here...")
                                .foregroundColor(Color(UIColor.placeholderText))
                                .font(.body)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 18)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .background(Color(UIColor.systemBackground))
                
                // Scrollable content area
                ScrollView {
                    VStack(spacing: 20) {
                        // Tone Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose a tone:")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(MessageTone.allCases, id: \.self) { tone in
                                    Button(action: {
                                        Task {
                                            await regenerateWithTone(tone)
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
                                        .background(viewModel.currentMessage?.tone == tone ? Color.blue : Color.gray.opacity(0.1))
                                        .foregroundColor(viewModel.currentMessage?.tone == tone ? .white : .primary)
                                        .cornerRadius(12)
                                    }
                                    .disabled(isRegenerating)
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
                            .disabled(isRegenerating)
                            
                            if let customPrompt = viewModel.currentMessage?.customPrompt, !customPrompt.isEmpty {
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
                        
                        // Processing indicator
                        if isRegenerating {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Regenerating...")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                            .padding()
                        }
                        
                        // Extra padding at bottom for safe scrolling
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
                
                // Action Buttons - Fixed at bottom
                VStack(spacing: 12) {
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
                .padding(.bottom, 16)
                .background(Color(UIColor.systemBackground))
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
                viewModel: viewModel,
                editableText: $editableText
            )
        }
        .onAppear {
            // Initialize editable text with the current message
            editableText = message.cleanedText
        }
        .onChange(of: viewModel.currentMessage?.cleanedText) { newValue in
            // Update editable text when the message is regenerated
            if let newValue = newValue, !newValue.isEmpty {
                editableText = newValue
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func regenerateWithTone(_ tone: MessageTone) async {
        guard let message = viewModel.currentMessage else { 
            print("❌ MessageReviewView: No current message to regenerate")
            return 
        }
        
        await MainActor.run {
            isRegenerating = true
        }
        
        // Use the ViewModel's regenerateWithTone method instead of creating a new MessageFormatter
        await viewModel.regenerateWithTone(tone)
        
        await MainActor.run {
            isRegenerating = false
        }
    }
}

struct CustomPromptView: View {
    @Binding var customPrompt: String
    @ObservedObject var viewModel: VoiceCaptureViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var editableText: String
    @State private var isRegenerating = false
    
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
                
                // Processing indicator
                if isRegenerating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Regenerating...")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .padding()
                }
                
                Spacer()
                
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Apply & Regenerate") {
                        Task {
                            await regenerateWithCustomPrompt()
                        }
                    }
                    .disabled(customPrompt.isEmpty || isRegenerating)
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
    
    // MARK: - Private Methods
    
    private func regenerateWithCustomPrompt() async {
        guard let message = viewModel.currentMessage else { 
            print("❌ CustomPromptView: No current message to regenerate")
            return 
        }
        
        await MainActor.run {
            isRegenerating = true
        }
        
        // Use the MessageFormatter to transform the current canvas text with custom prompt
        let messageFormatter = MessageFormatter(settingsManager: SettingsManager())
        
        if let newText = await messageFormatter.transformMessageWithTone(
            editableText, // Use the current canvas text as source
            tone: message.tone,
            customPrompt: customPrompt
        ) {
            await MainActor.run {
                editableText = newText
                viewModel.currentMessage?.cleanedText = newText
                viewModel.currentMessage?.customPrompt = customPrompt
                dismiss()
            }
        } else {
            // Handle the case where transformation failed
            await MainActor.run {
                print("❌ CustomPromptView: Failed to transform message with custom prompt")
                // Don't dismiss - let user see the error and retry
            }
        }
        
        await MainActor.run {
            isRegenerating = false
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