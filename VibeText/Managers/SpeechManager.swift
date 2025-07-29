import Foundation
import Speech
import AVFoundation
import Combine

/// Manages voice recording and speech-to-text transcription
class SpeechManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var errorMessage: String?
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override init() {
        super.init()
        speechRecognizer?.delegate = self
        requestSpeechAuthorization()
    }
    
    // MARK: - Authorization
    
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                if status != .authorized {
                    self?.errorMessage = "Speech recognition permission is required to use VibeText."
                }
            }
        }
    }
    
    // MARK: - Recording
    
    func startRecording() {
        guard !isRecording else { return }
        
        // Reset state
        transcript = ""
        errorMessage = nil
        
        // Check authorization
        guard authorizationStatus == .authorized else {
            errorMessage = "Speech recognition permission is required."
            return
        }
        
        // Check if speech recognizer is available
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition is not available."
            return
        }
        
        // Configure audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Failed to configure audio session: \(error.localizedDescription)"
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Failed to create recognition request."
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
            return
        }
        
        // Start recognition
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Recognition error: \(error.localizedDescription)"
                    self?.stopRecording()
                    return
                }
                
                if let result = result {
                    self?.transcript = result.bestTranscription.formattedString
                }
            }
        }
        
        isRecording = true
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        // Stop audio engine
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // Stop recognition
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Reset state
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
    
    // MARK: - Public Interface
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func clearTranscript() {
        transcript = ""
        errorMessage = nil
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension SpeechManager: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            if !available {
                self.errorMessage = "Speech recognition became unavailable."
            }
        }
    }
} 