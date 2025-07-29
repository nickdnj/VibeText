import Foundation
import Combine

/// ViewModel for the voice capture screen
class VoiceCaptureViewModel: ObservableObject {
    @Published var currentMessage: Message?
    @Published var isProcessing = false
    @Published var showReview = false
    @Published var errorMessage: String?
    
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
        speechManager.startRecording()
    }
    
    func stopRecording() {
        speechManager.stopRecording()
    }
    
    func processTranscript() async {
        guard !speechManager.transcript.isEmpty else {
            errorMessage = "No transcript to process"
            return
        }
        
        await MainActor.run {
            isProcessing = true
            errorMessage = nil
        }
        
        let tone = settingsManager.lastUsedTone
        
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
            }
        } else {
            await MainActor.run {
                errorMessage = messageFormatter.errorMessage ?? "Failed to process transcript"
            }
        }
        
        await MainActor.run {
            isProcessing = false
        }
    }
    
    func regenerateWithTone(_ tone: MessageTone) async {
        guard let message = currentMessage else { return }
        
        await MainActor.run {
            isProcessing = true
            errorMessage = nil
        }
        
        if let newText = await messageFormatter.regenerateWithTone(
            message.originalTranscript,
            tone: tone,
            customPrompt: message.customPrompt
        ) {
            await MainActor.run {
                currentMessage?.cleanedText = newText
                currentMessage?.tone = tone
                settingsManager.saveLastUsedTone(tone)
            }
        } else {
            await MainActor.run {
                errorMessage = messageFormatter.errorMessage ?? "Failed to regenerate text"
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
            errorMessage = nil
        }
        
        if let newText = await messageFormatter.processTranscript(
            message.originalTranscript,
            tone: message.tone,
            customPrompt: prompt
        ) {
            await MainActor.run {
                currentMessage?.cleanedText = newText
                currentMessage?.customPrompt = prompt
            }
        } else {
            await MainActor.run {
                errorMessage = messageFormatter.errorMessage ?? "Failed to regenerate text"
            }
        }
        
        await MainActor.run {
            isProcessing = false
        }
    }
    
    func reset() {
        currentMessage = nil
        showReview = false
        errorMessage = nil
        speechManager.clearTranscript()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Monitor speech manager errors
        speechManager.$errorMessage
            .compactMap { $0 }
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }
} 