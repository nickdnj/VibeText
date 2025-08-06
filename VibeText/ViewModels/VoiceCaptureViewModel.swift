import Foundation
import Combine

/// ViewModel for the voice capture screen
class VoiceCaptureViewModel: ObservableObject, ErrorHandling {
    @Published var currentMessage: Message?
    @Published var isProcessing = false
    @Published var showReview = false
    @Published var currentError: AppError?
    
    // Session tracking for default tone behavior
    private var isFirstTransformationInSession = true
    
    private let speechManager: SpeechManager
    private let messageFormatter: MessageFormatter
    private let settingsManager: SettingsManager
    private var cancellables = Set<AnyCancellable>()
    
    init(speechManager: SpeechManager, messageFormatter: MessageFormatter, settingsManager: SettingsManager) {
        self.speechManager = speechManager
        self.messageFormatter = messageFormatter
        self.settingsManager = settingsManager
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    func startRecording() {
        print("🎙️ VibeText Main App: VoiceCaptureViewModel.startRecording() called")
        clearError()
        let result = speechManager.startRecording()
        print("🎙️ VibeText Main App: speechManager.startRecording() returned: \(result)")
        
        if !result {
            ErrorHandler.handle(.recordingFailed, in: self)
        }
    }
    
    func stopRecording() {
        print("🛑 VibeText Main App: VoiceCaptureViewModel.stopRecording() called")
        speechManager.stopRecording()
        
        // Start processing transcript when it becomes available
        // We'll monitor the transcript changes and process when transcription completes
    }
    
    func processTranscript() async {
        guard !speechManager.transcript.isEmpty else {
            ErrorHandler.handle(.unknownError("No transcript to process"), in: self)
            return
        }
        
        await MainActor.run {
            isProcessing = true
            clearError()
        }
        
        // Use default tone for first transformation, then switch to last used
        let tone = isFirstTransformationInSession ? settingsManager.defaultTone : settingsManager.lastUsedTone
        
        print("🎵 VoiceCaptureViewModel: Using tone: \(tone.rawValue) (first transformation: \(isFirstTransformationInSession))")
        
        if let cleanedText = await messageFormatter.processTranscript(
            speechManager.transcript,
            tone: tone
        ) {
            await MainActor.run {
                currentMessage = Message(
                    originalTranscript: speechManager.transcript,
                    cleanedText: cleanedText,
                    tone: tone
                )
                showReview = true
                clearError()
                
                // Mark that we've completed the first transformation
                isFirstTransformationInSession = false
                
                // Reset processing state when successfully showing review
                isProcessing = false
            }
        } else {
            // Error is already set by MessageFormatter
            await MainActor.run {
                isProcessing = false
            }
        }
    }
    
    func regenerateWithTone(_ tone: MessageTone) async {
        guard let message = currentMessage else { 
            print("❌ VoiceCaptureViewModel: No current message to regenerate")
            return 
        }
        
        print("🔄 VoiceCaptureViewModel: Regenerating with tone: \(tone.rawValue)")
        
        await MainActor.run {
            isProcessing = true
            clearError()
        }
        
        if let newText = await messageFormatter.regenerateWithTone(
            message.originalTranscript,
            tone: tone,
            customPrompt: message.customPrompt
        ) {
            await MainActor.run {
                print("✅ VoiceCaptureViewModel: Successfully regenerated text with tone: \(tone.rawValue)")
                currentMessage?.cleanedText = newText
                currentMessage?.tone = tone
                settingsManager.saveLastUsedTone(tone)
                
                // Force UI update by triggering objectWillChange
                objectWillChange.send()
            }
        } else {
            // Error is already set by MessageFormatter
            await MainActor.run {
                print("❌ VoiceCaptureViewModel: Failed to regenerate text with tone: \(tone.rawValue)")
            }
        }
        
        await MainActor.run {
            isProcessing = false
        }
    }
    
    /// Regenerate with tone using the current edited text as source (preserves manual edits)
    func regenerateWithToneFromText(_ currentText: String, tone: MessageTone) async {
        guard let message = currentMessage else { 
            print("❌ VoiceCaptureViewModel: No current message to regenerate")
            return 
        }
        
        print("🔄 VoiceCaptureViewModel: Regenerating with tone: \(tone.rawValue) from current text")
        
        await MainActor.run {
            isProcessing = true
            clearError()
        }
        
        if let newText = await messageFormatter.transformMessageWithTone(
            currentText,
            tone: tone,
            customPrompt: message.customPrompt
        ) {
            await MainActor.run {
                print("✅ VoiceCaptureViewModel: Successfully regenerated text with tone: \(tone.rawValue) from current text")
                currentMessage?.cleanedText = newText
                currentMessage?.tone = tone
                settingsManager.saveLastUsedTone(tone)
                
                // Force UI update by triggering objectWillChange
                objectWillChange.send()
            }
        } else {
            // Error is already set by MessageFormatter
            await MainActor.run {
                print("❌ VoiceCaptureViewModel: Failed to regenerate text with tone: \(tone.rawValue) from current text")
            }
        }
        
        await MainActor.run {
            isProcessing = false
        }
    }
    
    func regenerateWithCustomPrompt(_ prompt: String) async {
        guard let message = currentMessage else { return }
        
        await MainActor.run {
            isProcessing = true
            clearError()
        }
        
        if let newText = await messageFormatter.processTranscript(
            message.originalTranscript,
            tone: message.tone,
            customPrompt: prompt
        ) {
            await MainActor.run {
                currentMessage?.cleanedText = newText
                currentMessage?.customPrompt = prompt
                clearError()
                isProcessing = false
            }
        } else {
            // Error is already set by MessageFormatter
            await MainActor.run {
                isProcessing = false
            }
        }
    }
    
    /// Regenerate with custom prompt using the current edited text as source
    func regenerateWithCustomPromptFromText(_ currentText: String, prompt: String) async {
        guard let message = currentMessage else { return }
        
        await MainActor.run {
            isProcessing = true
            clearError()
        }
        
        if let newText = await messageFormatter.transformMessageWithTone(
            currentText,
            tone: message.tone,
            customPrompt: prompt
        ) {
            await MainActor.run {
                currentMessage?.cleanedText = newText
                currentMessage?.customPrompt = prompt
                clearError()
                isProcessing = false
            }
        } else {
            // Error is already set by MessageFormatter
            await MainActor.run {
                isProcessing = false
            }
        }
    }
    
    func reset() {
        currentMessage = nil
        showReview = false
        isProcessing = false
        clearError()
        speechManager.clearTranscript()
        // Reset session tracking for next session
        isFirstTransformationInSession = true
        print("🎵 VoiceCaptureViewModel: Session reset - next transformation will use default tone")
    }
    
    func updateMessageText(_ newText: String) {
        currentMessage?.cleanedText = newText
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Monitor speech manager errors
        speechManager.$currentError
            .compactMap { $0 }
            .sink { [weak self] error in
                print("❌ VoiceCaptureViewModel: Speech manager error: \(error.localizedDescription)")
                guard let self = self else {
                    print("❌ VoiceCaptureViewModel: Self is nil, cannot handle speech manager error")
                    return
                }
                ErrorHandler.handle(error, in: self)
            }
            .store(in: &cancellables)
        
        // Monitor message formatter errors
        messageFormatter.$currentError
            .compactMap { $0 }
            .sink { [weak self] error in
                print("❌ VoiceCaptureViewModel: Message formatter error: \(error.localizedDescription)")
                guard let self = self else {
                    print("❌ VoiceCaptureViewModel: Self is nil, cannot handle message formatter error")
                    return
                }
                ErrorHandler.handle(error, in: self)
            }
            .store(in: &cancellables)
        
        // Monitor transcript changes and automatically process when transcription completes
        speechManager.$transcript
            .filter { !$0.isEmpty }
            .filter { [weak self] _ in
                // Only process if we're not currently transcribing
                self?.speechManager.isTranscribing == false
            }
            .sink { [weak self] transcript in
                // Process the transcript automatically when it becomes available
                Task {
                    await self?.processTranscript()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Error Handling
    
    func retry() {
        clearError()
        // Retry the last operation based on current state
        if isProcessing {
            // If we were processing, try again
            Task {
                await processTranscript()
            }
        } else if speechManager.isRecording {
            // If we were recording, restart recording
            startRecording()
        } else {
            // Otherwise, start a new recording
            startRecording()
        }
    }
} 