//
//  VibeTextMessageView.swift
//  VibeText-imessage
//
//  Created by Nick DeMarco on 7/30/25.
//

import SwiftUI
import os

struct VibeTextMessageView: View {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var messageFormatter: MessageFormatter
    @StateObject private var viewModel: MessageExtensionViewModel
    @State private var showAPIKeyInput = false
    @State private var tempAPIKey = ""
    @State private var editableMessageText = ""
    
    private let onSendMessage: (String) -> Void
    
    init(onSendMessage: @escaping (String) -> Void) {
        print("🎯 VibeText Extension: VibeTextMessageView.init() called")
        NSLog("🎯 VibeText Extension: VibeTextMessageView.init() called")
        self.onSendMessage = onSendMessage
        
        let settings = SettingsManager()
        let speechManager = SpeechManager()
        let formatter = MessageFormatter(settingsManager: settings)
        let viewModel = MessageExtensionViewModel(
            speechManager: speechManager,
            messageFormatter: formatter,
            settingsManager: settings
        )
        
        self._settingsManager = StateObject(wrappedValue: settings)
        self._speechManager = StateObject(wrappedValue: speechManager)
        self._messageFormatter = StateObject(wrappedValue: formatter)
        self._viewModel = StateObject(wrappedValue: viewModel)
        print("✅ VibeText Extension: VibeTextMessageView initialization complete")
        NSLog("✅ VibeText Extension: VibeTextMessageView initialization complete")
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "mic.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("VibeText")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            if viewModel.showToneSelection {
                // Tone Selection and Message Review
                VStack(spacing: 0) {
                    // Message Display - Fixed at top
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your message:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        if let currentMessage = viewModel.currentMessage {
                            ZStack(alignment: .topLeading) {
                                // iMessage-style background
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(UIColor.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color(UIColor.systemGray4), lineWidth: 0.5)
                                    )
                                
                                // Multiline, scrollable TextEditor
                                TextEditor(text: $editableMessageText)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.clear)
                                    .font(.body)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 120, maxHeight: 180)
                                
                                // Placeholder when empty
                                if editableMessageText.isEmpty {
                                    Text("Tap to edit message...")
                                        .foregroundColor(Color(UIColor.placeholderText))
                                        .font(.body)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .allowsHitTesting(false)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    // Tone Selection - Scrollable
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose a tone:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(MessageTone.allCases, id: \.self) { tone in
                                    Button(action: {
                                        Task {
                                            await regenerateWithTone(tone)
                                        }
                                    }) {
                                        VStack(spacing: 4) {
                                            Text(tone.emoji)
                                                .font(.title3)
                                            Text(tone.rawValue)
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 4)
                                        .background(viewModel.currentMessage?.tone == tone ? Color.blue : Color.gray.opacity(0.1))
                                        .foregroundColor(viewModel.currentMessage?.tone == tone ? .white : .primary)
                                        .cornerRadius(8)
                                    }
                                    .disabled(viewModel.isProcessing)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Processing indicator
                            if viewModel.isProcessing {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Processing...")
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            viewModel.reset()
                        }
                        .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Send Message") {
                            // Send the edited text directly from the canvas
                            onSendMessage(editableMessageText)
                            viewModel.reset()
                            editableMessageText = ""
                        }
                        .disabled(editableMessageText.isEmpty)
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
            } else {
                // Voice Recording Interface
                VStack(spacing: 20) {
                    // Microphone Button
                    Button(action: {
                        NSLog("🎯 VibeText Extension: MICROPHONE BUTTON TAPPED")
                        os_log("🎯 VibeText Extension: MICROPHONE BUTTON TAPPED")
                        
                        NSLog("🎯 VibeText Extension: isRecording status: %@", speechManager.isRecording ? "true" : "false")
                        
                        if speechManager.isRecording {
                            NSLog("🛑 VibeText Extension: Stopping recording...")
                            viewModel.stopRecording()
                            viewModel.errorMessage = "STOPPED: Recording stopped by user"
                        } else {
                            NSLog("🎙️ VibeText Extension: Starting recording...")
                            viewModel.startRecording()
                            NSLog("🎙️ VibeText Extension: startRecording() returned")
                            viewModel.errorMessage = "STARTED: Recording attempt made"
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(buttonColor)
                                .frame(width: 80, height: 80)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: buttonIcon)
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .scaleEffect(speechManager.isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: speechManager.isRecording)
                    .disabled(viewModel.isProcessing || speechManager.isTranscribing)
                    
                    // Status Display
                    VStack(spacing: 8) {
                        Text(statusText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(statusColor)
                        
                        if speechManager.isRecording {
                            // Recording duration
                            Text(formatRecordingDuration(speechManager.recordingDuration))
                                .font(.caption)
                                .foregroundColor(speechManager.recordingDuration >= 240 ? .orange : .secondary)
                                .fontWeight(speechManager.recordingDuration >= 240 ? .semibold : .regular)
                            
                            // Animated waveform
                            SimpleWaveformView()
                        } else if speechManager.isTranscribing {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Transcribing...")
                                    .font(.caption)
                            }
                        } else if viewModel.isProcessing {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Processing...")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding(.vertical, 20)
            }
            
            // Error Display
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
            
            // API Key Input Section (Simplified approach)
            if settingsManager.isUsingDefaultKey || showAPIKeyInput {
                VStack(spacing: 8) {
                    if !showAPIKeyInput {
                        Button("⚙️ Configure API Key") {
                            showAPIKeyInput = true
                            tempAPIKey = settingsManager.openAIAPIKey
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 8) {
                            Text("Enter OpenAI API Key:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            SecureField("sk-proj-...", text: $tempAPIKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.caption)
                                .padding(.horizontal)
                            
                            HStack(spacing: 12) {
                                Button("Cancel") {
                                    showAPIKeyInput = false
                                    tempAPIKey = ""
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                                
                                Button("Save") {
                                    settingsManager.saveAPIKey(tempAPIKey)
                                    showAPIKeyInput = false
                                    viewModel.errorMessage = "✅ API key saved!"
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                                .disabled(tempAPIKey.isEmpty)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
            }
            
            Spacer()
        }
        .frame(maxHeight: 350) // Constrain height for iMessage extension
        .onChange(of: viewModel.currentMessage?.cleanedText) { newText in
            // Update editable text when a new message is processed or regenerated
            if let text = newText, !text.isEmpty {
                editableMessageText = text
            }
        }
        .onChange(of: viewModel.currentMessage?.id) { _ in
            // Initialize editable text when a new message is created
            if let message = viewModel.currentMessage {
                editableMessageText = message.cleanedText
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func regenerateWithTone(_ tone: MessageTone) async {
        guard let message = viewModel.currentMessage else { 
            print("❌ VibeTextMessageView: No current message to regenerate")
            return 
        }
        
        // Use the messageFormatter to transform the current canvas text (including user edits)
        // This makes the canvas the source of truth instead of the original transcript
        if let newText = await messageFormatter.transformMessageWithTone(
            editableMessageText, // Use the current canvas text instead of original transcript
            tone: tone,
            customPrompt: message.customPrompt
        ) {
            await MainActor.run {
                editableMessageText = newText
                viewModel.currentMessage?.cleanedText = newText
                viewModel.currentMessage?.tone = tone
                settingsManager.saveLastUsedTone(tone)
            }
        } else {
            // Handle the case where transformation failed
            await MainActor.run {
                print("❌ VibeTextMessageView: Failed to transform message with tone: \(tone.rawValue)")
                // The error will be handled by the view model's error handling
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var buttonColor: Color {
        if speechManager.isRecording {
            return .red
        } else if viewModel.isProcessing || speechManager.isTranscribing {
            return .gray
        } else {
            return .blue
        }
    }
    
    private var buttonIcon: String {
        if speechManager.isRecording {
            return "stop.fill"
        } else {
            return "mic.fill"
        }
    }
    
    private var statusText: String {
        if speechManager.isRecording {
            return "Recording..."
        } else if speechManager.isTranscribing {
            return "Transcribing..."
        } else if viewModel.isProcessing {
            return "Processing..."
        } else {
            return "Tap to record your message"
        }
    }
    
    private var statusColor: Color {
        if speechManager.isRecording {
            return .red
        } else if speechManager.isTranscribing {
            return .orange
        } else if viewModel.isProcessing {
            return .blue
        } else {
            return .secondary
        }
    }
}

// MARK: - Helper Functions

private func formatRecordingDuration(_ duration: TimeInterval) -> String {
    let minutes = Int(duration) / 60
    let seconds = Int(duration) % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

// MARK: - Simple Waveform View

struct SimpleWaveformView: View {
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.red)
                    .frame(width: 2, height: 12)
                    .scaleEffect(y: waveformHeight(for: index), anchor: .bottom)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever()
                        .delay(Double(index) * 0.1),
                        value: animationPhase
                    )
            }
        }
        .onAppear {
            animationPhase = 1
        }
    }
    
    private func waveformHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 0.4
        let maxHeight: CGFloat = 1.0
        
        let wave = sin(Double(index) * 0.8 + animationPhase * 2 * .pi)
        return baseHeight + (maxHeight - baseHeight) * CGFloat(abs(wave))
    }
}

// MARK: - Message Extension ViewModel

class MessageExtensionViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var currentMessage: Message?
    @Published var showToneSelection = false
    
    private let speechManager: SpeechManager
    private let messageFormatter: MessageFormatter
    private let settingsManager: SettingsManager
    
    init(speechManager: SpeechManager, messageFormatter: MessageFormatter, settingsManager: SettingsManager) {
        self.speechManager = speechManager
        self.messageFormatter = messageFormatter
        self.settingsManager = settingsManager
        
        // Observe transcript changes
        speechManager.$transcript
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transcript in
                if !transcript.isEmpty {
                    Task {
                        await self?.processTranscript(transcript)
                    }
                }
            }
            .store(in: &cancellables)
        
        // Observe errors
        speechManager.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.errorMessage = error
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Recording Control
    
    func startRecording() {
        print("🎙️ VibeText Extension: MessageExtensionViewModel.startRecording() called")
        reset()
        let result = speechManager.startRecording()
        print("🎙️ VibeText Extension: speechManager.startRecording() returned: \(result)")
    }
    
    func stopRecording() {
        speechManager.stopRecording()
    }
    
    func reset() {
        currentMessage = nil
        showToneSelection = false
        errorMessage = nil
        speechManager.transcript = ""
    }
    
    // MARK: - Message Processing
    
    @MainActor
    private func processTranscript(_ transcript: String) async {
        guard !transcript.isEmpty else { return }
        
        NSLog("🎯 Processing transcript: '%@' with length: %d", transcript, transcript.count)
        
        isProcessing = true
        errorMessage = nil
        
        let tone = settingsManager.lastUsedTone
        NSLog("🎯 Using tone: %@", tone.rawValue)
        
        if let processedText = await messageFormatter.processTranscript(transcript, tone: tone) {
            currentMessage = Message(
                originalTranscript: transcript,
                cleanedText: processedText,
                tone: tone
            )
            showToneSelection = true
        } else {
            // Show the specific error from MessageFormatter instead of generic message
            errorMessage = messageFormatter.errorMessage ?? "Failed to process your message. Please try again."
            NSLog("🚨 Message processing failed: %@", errorMessage ?? "Unknown error")
        }
        
        isProcessing = false
    }
    
    @MainActor
    func regenerateWithTone(_ tone: MessageTone) async {
        guard let message = currentMessage else { return }
        
        isProcessing = true
        settingsManager.saveLastUsedTone(tone)
        
        if let processedText = await messageFormatter.regenerateWithTone(
            message.originalTranscript,
            tone: tone,
            customPrompt: message.customPrompt
        ) {
            currentMessage = Message(
                originalTranscript: message.originalTranscript,
                cleanedText: processedText,
                tone: tone,
                customPrompt: message.customPrompt
            )
        } else {
            errorMessage = messageFormatter.errorMessage ?? "Failed to regenerate with \(tone.rawValue) tone."
            NSLog("🚨 Message regeneration failed: %@", errorMessage ?? "Unknown error")
        }
        
        isProcessing = false
    }
}

// MARK: - Import Combine for Publishers

import Combine

#Preview {
    VibeTextMessageView { message in
        print("Would send message: \(message)")
    }
    .frame(height: 350)
}