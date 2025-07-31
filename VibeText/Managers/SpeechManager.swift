import Foundation
import Speech
import AVFoundation
import Combine
import UIKit

/// Manages voice recording and speech-to-text transcription
class SpeechManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var errorMessage: String?
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var isTranscribing = false
    @Published var recordingDuration: TimeInterval = 0
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var isAudioSessionConfigured = false
    private var audioSessionInterruptionObserver: NSObjectProtocol?
    private var recordingTimer: Timer?
    private var audioSessionRouteChangeObserver: NSObjectProtocol?
    
    // Audio engine for file recording only (no live recognition)
    private let audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    
    // Maximum recording duration (5 minutes)
    private let maxRecordingDuration: TimeInterval = 300.0
    
    override init() {
        super.init()
        speechRecognizer?.delegate = self
        requestSpeechAuthorization()
        setupAudioSessionInterruptionHandling()
    }
    
    deinit {
        if let observer = audioSessionInterruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let routeObserver = audioSessionRouteChangeObserver {
            NotificationCenter.default.removeObserver(routeObserver)
        }
        
        // Ensure screen sleep is always re-enabled when manager is deallocated
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    // MARK: - Authorization
    
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                if status == .authorized {
                    self?.requestMicrophonePermission()
                }
            }
        }
    }
    
    private func requestMicrophonePermission() {
        print("🎙️ VibeText Main App: Requesting microphone permission...")
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                print("🎙️ VibeText Main App: Microphone permission result: \(granted)")
                if !granted {
                    print("❌ VibeText Main App: Microphone permission denied")
                    self?.errorMessage = "Microphone permission is required for voice recording."
                } else {
                    print("✅ VibeText Main App: Microphone permission granted")
                }
            }
        }
    }
    
    // MARK: - Recording Control
    
    func startRecording() -> Bool {
        print("🎙️ VibeText Main App: === Starting Recording Process ===")
        print("🎙️ Main App: Current recording state: \(isRecording)")
        print("🎙️ Main App: Audio engine running: \(audioEngine.isRunning)")
        
        // Clear any previous error
        errorMessage = nil
        
        guard authorizationStatus == .authorized else {
            print("❌ Main App: Speech recognition not authorized - status: \(authorizationStatus)")
            if authorizationStatus == .notDetermined {
                print("🔄 Main App: Requesting speech recognition permission...")
                requestSpeechAuthorization()
                return false
            }
            errorMessage = "Speech recognition not authorized"
            return false
        }
        
        print("✅ Main App: Speech recognition authorized")
        
        // Check microphone permission with detailed logging
        let audioSession = AVAudioSession.sharedInstance()
        let micPermission = audioSession.recordPermission
        print("🎙️ Main App: Microphone permission status: \(micPermission)")
        print("🎙️ Main App: Audio session category: \(audioSession.category)")
        print("🎙️ Main App: Other audio playing: \(audioSession.isOtherAudioPlaying)")
        print("🎙️ Main App: Input available: \(audioSession.isInputAvailable)")
        
        if micPermission == .undetermined {
            print("⚠️ Main App: Microphone permission undetermined, requesting...")
            requestMicrophonePermission()
            return false
        }
        
        guard micPermission == .granted else {
            print("❌ Main App: Microphone permission not granted")
            errorMessage = "Microphone permission required"
            return false
        }
        
        print("✅ Main App: Microphone permission granted")
        
        // Configure audio session with detailed logging
        print("🎙️ Main App: Configuring audio session...")
        guard configureAudioSession() else {
            print("❌ Main App: Failed to configure audio session")
            errorMessage = "Failed to configure audio session"
            return false
        }
        
        print("✅ Main App: Audio session configured successfully")
        
        // Start actual recording
        print("🎙️ Main App: Starting audio recording...")
        if startAudioRecording() {
            print("✅ Main App: Audio recording engine started")
            isRecording = true
            transcript = ""
            errorMessage = nil
            startRecordingTimer()
            
            // Keep screen awake during recording
            DispatchQueue.main.async {
                UIApplication.shared.isIdleTimerDisabled = true
            }
            
            print("✅ Main App: === Recording Started Successfully ===")
            return true
        } else {
            print("❌ Main App: Failed to start audio recording engine")
            errorMessage = "Failed to start recording"
            return false
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        print("🛑 Main App: Stopping recording...")
        
        isRecording = false
        stopRecordingTimer()
        stopAudioRecording()
        
        // Re-enable screen sleep
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        
        print("✅ Main App: Recording stopped successfully")
    }
    
    // MARK: - Audio Recording
    
    private func startAudioRecording() -> Bool {
        return startAudioRecordingSimple()
    }
    
    private func startAudioRecordingSimple() -> Bool {
        print("🎙️ Starting stable audio recording for main app...")
        
        // Clean stop any existing recording
        if audioEngine.isRunning {
            audioEngine.stop()
            print("✅ Engine stopped")
        }
        
        audioEngine.inputNode.removeTap(onBus: 0)
        print("✅ Tap cleared")
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingURL = documentsPath.appendingPathComponent("main_app_recording_\(Date().timeIntervalSince1970).m4a")
        
        guard let recordingURL = recordingURL else {
            print("❌ Failed to create URL")
            return false
        }
        
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        print("🎵 Input format: \(inputFormat)")
        
        // Use a standard format to prevent engine reconfigurations
        let recordingFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000, // Standard speech recognition rate
            channels: 1,
            interleaved: false
        )
        
        guard let standardFormat = recordingFormat else {
            print("❌ Could not create standard recording format")
            return false
        }
        
        print("🎵 Using standard format: \(standardFormat)")
        
        do {
            audioFile = try AVAudioFile(forWriting: recordingURL, settings: standardFormat.settings)
            print("✅ Audio file created with standard format")
        } catch {
            print("❌ File creation failed: \(error)")
            return false
        }
        
        // Install tap with format conversion to prevent engine issues
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            // Convert to our standard format if needed
            if inputFormat == standardFormat {
                try? self?.audioFile?.write(from: buffer)
            } else {
                // Convert format for consistency
                if let converter = self?.createAudioConverter(from: inputFormat, to: standardFormat) {
                    self?.convertAndWrite(buffer: buffer, converter: converter)
                }
            }
        }
        print("✅ Tap installed with format conversion")
        
        do {
            audioEngine.prepare()
            try audioEngine.start()
            print("✅ Audio engine started successfully with stable configuration")
            return true
        } catch {
            print("❌ Start failed: \(error)")
            return false
        }
    }
    
    private func createAudioConverter(from inputFormat: AVAudioFormat, to outputFormat: AVAudioFormat) -> AVAudioConverter? {
        return AVAudioConverter(from: inputFormat, to: outputFormat)
    }
    
    private func convertAndWrite(buffer: AVAudioPCMBuffer, converter: AVAudioConverter) {
        guard let audioFile = audioFile else { return }
        
        let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * (converter.outputFormat.sampleRate / converter.inputFormat.sampleRate))
        
        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: outputFrameCapacity) else {
            return
        }
        
        var error: NSError?
        let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        if status == .haveData || status == .endOfStream {
            try? audioFile.write(from: convertedBuffer)
        }
    }
    
    private func stopAudioRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // Flush and close the audio file
        audioFile = nil
        
        // Start transcription if we have a recording
        if let recordingURL = recordingURL {
            print("🎯 Starting transcription for file: \(recordingURL.lastPathComponent)")
            transcribeAudioFile(recordingURL)
        }
    }
    
    // MARK: - Transcription
    
    private func transcribeAudioFile(_ audioURL: URL) {
        print("🎤 Starting transcription of: \(audioURL.lastPathComponent)")
        
        guard validateAudioFile(audioURL) else {
            print("❌ Audio file validation failed")
            DispatchQueue.main.async {
                self.errorMessage = "Invalid audio file - no speech detected"
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isTranscribing = true
        }
        
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        
        print("🎤 Making recognition request...")
        speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            print("🎤 Recognition callback received")
            
            DispatchQueue.main.async {
                self?.isTranscribing = false
                
                if let error = error {
                    print("❌ Recognition error: \(error)")
                    self?.errorMessage = "Transcription failed: \(error.localizedDescription)"
                    return
                }
                
                guard let result = result else {
                    print("❌ No recognition result")
                    self?.errorMessage = "Transcription failed: no result"
                    return
                }
                
                if result.isFinal {
                    let transcribedText = result.bestTranscription.formattedString
                    print("✅ Final transcription: '\(transcribedText)'")
                    
                    if transcribedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        self?.errorMessage = "Transcription failed: no speech detected"
                        print("❌ Empty transcription result")
                    } else {
                        self?.transcript = transcribedText
                        self?.errorMessage = nil
                        print("✅ Transcription successful")
                    }
                }
            }
        }
    }
    
    private func validateAudioFile(_ url: URL) -> Bool {
        print("🔍 Validating audio file: \(url.lastPathComponent)")
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌ Audio file does not exist")
            return false
        }
        
        // Check file size
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            print("📁 File size: \(fileSize) bytes")
            
            guard fileSize > 1000 else { // At least 1KB
                print("❌ Audio file too small")
                return false
            }
        } catch {
            print("❌ Could not get file attributes: \(error)")
            return false
        }
        
        // Try to create AVAudioFile to validate format
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate
            print("🎵 Audio duration: \(duration) seconds")
            print("🎵 Sample rate: \(audioFile.fileFormat.sampleRate)")
            print("🎵 Channel count: \(audioFile.fileFormat.channelCount)")
            
            guard duration > 0.1 else { // At least 100ms
                print("❌ Audio duration too short")
                return false
            }
            
            return true
        } catch {
            print("❌ Could not read audio file: \(error)")
            return false
        }
    }
    
    // MARK: - Timer Management
    
    private func startRecordingTimer() {
        recordingDuration = 0
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.recordingDuration += 1.0
            
            // Auto-stop at maximum duration
            if self.recordingDuration >= self.maxRecordingDuration {
                print("⏰ Maximum recording duration reached - auto-stopping")
                self.stopRecording()
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    // MARK: - Audio Session Management
    
    private func configureAudioSession() -> Bool {
        print("🎯 Configuring audio session for main app...")
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            // Check current category - if it's already suitable, don't change it
            let currentCategory = audioSession.category
            print("🎯 Current audio category: \(currentCategory)")
            
            // Only set category if it's not already recording-capable
            if currentCategory != .record && currentCategory != .playAndRecord {
                print("🎯 Setting audio category for main app...")
                try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker])
            }
            
            // Set preferred sample rate and I/O buffer duration for better performance
            try audioSession.setPreferredSampleRate(44100.0)
            try audioSession.setPreferredIOBufferDuration(0.005)
            
            // Only activate if not already active
            if !audioSession.isOtherAudioPlaying {
                print("🎯 Activating audio session...")
                try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])
            }
            
            isAudioSessionConfigured = true
            print("✅ Audio session configured successfully for main app")
            return true
        } catch {
            print("❌ Failed to configure audio session: \(error)")
            return configureAudioSessionFallback()
        }
    }
    
    private func configureAudioSessionFallback() -> Bool {
        print("🔄 Trying fallback audio session configuration...")
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            // Fallback to simpler configuration
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
            
            isAudioSessionConfigured = true
            print("✅ Fallback audio session configured successfully")
            return true
        } catch {
            print("❌ Even fallback audio session configuration failed: \(error)")
            return false
        }
    }
    
    private func resetAudioSession() -> Bool {
        print("🔄 Attempting to reset audio session...")
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            usleep(500000) // Wait 0.5 seconds
            isAudioSessionConfigured = false
            print("✅ Audio session reset successfully")
            return true
        } catch {
            print("❌ Failed to reset audio session: \(error)")
            return false
        }
    }
    
    private func setupAudioSessionInterruptionHandling() {
        audioSessionInterruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAudioSessionInterruption(notification)
        }
        
        audioSessionRouteChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAudioSessionRouteChange(notification)
        }
    }
    
    private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            print("🔇 Audio session interruption began")
            if isRecording {
                stopRecording()
                errorMessage = "Recording interrupted"
            }
        case .ended:
            print("🔊 Audio session interruption ended")
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    ensureAudioSessionIsActive()
                }
            }
        @unknown default:
            break
        }
    }
    
    private func handleAudioSessionRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .newDeviceAvailable, .oldDeviceUnavailable:
            print("🎧 Audio route changed: \(reason)")
            if isRecording {
                handleAudioSessionConflict()
            }
        default:
            break
        }
    }
    
    private func ensureAudioSessionIsActive() {
        guard !isRecording else { return }
        
        let audioSession = AVAudioSession.sharedInstance()
        if !audioSession.isOtherAudioPlaying {
            do {
                try audioSession.setActive(true)
                print("✅ Audio session reactivated after interruption")
            } catch {
                print("❌ Failed to reactivate audio session: \(error)")
            }
        }
    }
    
    private func handleAudioSessionConflict() {
        print("⚠️ Audio session conflict detected during recording")
        
        // Stop current recording and attempt to reconfigure
        if isRecording {
            print("🛑 Stopping recording due to audio session conflict")
            stopRecording()
            
            // For main app, be more patient with recovery
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                print("🔄 Attempting to recover from audio session conflict...")
                
                // Try to reset and reconfigure
                if self.resetAudioSession() && self.configureAudioSession() {
                    print("✅ Audio session conflict resolved")
                    self.errorMessage = "Audio session recovered. You can try recording again."
                } else {
                    print("❌ Could not recover from audio session conflict")
                    self.errorMessage = "Audio session conflict. Please restart the app."
                }
            }
        }
    }
    
    // MARK: - Public Interface
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            _ = startRecording()
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
                self.errorMessage = "Speech recognition temporarily unavailable"
            }
        }
    }
}