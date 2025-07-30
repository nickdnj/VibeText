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
    @Published var isTranscribing = false
    @Published var recordingDuration: TimeInterval = 0 // Recording duration in seconds
    
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
    }
    
    // MARK: - Authorization
    
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                if status != .authorized {
                    self?.errorMessage = "Speech recognition permission is required to use VibeText."
                } else {
                    // After speech recognition is authorized, request microphone permission
                    self?.requestMicrophonePermission()
                }
            }
        }
    }
    
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if !granted {
                    self?.errorMessage = "Microphone permission is required to record your voice."
                    print("❌ Microphone permission denied by user")
                } else {
                    print("✅ Microphone permission granted")
                }
            }
        }
    }
    
    // MARK: - Audio Session Interruption Handling
    
    private func setupAudioSessionInterruptionHandling() {
        audioSessionInterruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAudioSessionInterruption(notification)
        }
        
        // Also observe route changes (e.g., when TextEditor becomes active)
        audioSessionRouteChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAudioSessionRouteChange(notification)
        }
    }
    
    private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            print("⚠️ Audio session interruption began")
            // Don't stop recording immediately, let the system handle it
            break
            
        case .ended:
            print("✅ Audio session interruption ended")
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            
            if options.contains(.shouldResume) && isRecording {
                print("🔄 Resuming recording after interruption")
                // Try to resume recording if it was interrupted
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.ensureAudioSessionIsActive()
                }
            }
            
        @unknown default:
            break
        }
    }
    
    private func handleAudioSessionRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        print("🔄 Audio session route changed: \(reason)")
        
        // If we're recording and the route changed, check if we need to handle it
        if isRecording {
            switch reason {
            case .newDeviceAvailable, .oldDeviceUnavailable:
                // Device changes might affect our recording
                print("⚠️ Audio device changed during recording")
                handleAudioSessionConflict()
            case .categoryChange:
                // Category changes might be from TextEditor activation
                print("⚠️ Audio category changed during recording")
                handleAudioSessionConflict()
            default:
                break
            }
        }
    }
    
    // MARK: - Audio Session Management
    
    private func resetAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Try to deactivate any existing session
            do {
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                print("🔄 Reset: Deactivated audio session")
            } catch {
                print("⚠️ Reset: Audio session deactivation failed: \(error)")
            }
            
            // Reset category to default
            try audioSession.setCategory(.playback, mode: .default)
            
            isAudioSessionConfigured = false
            print("✅ Audio session reset completed")
        } catch {
            print("❌ Failed to reset audio session: \(error)")
        }
    }
    
    private func ensureAudioSessionIsActive() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            if !audioSession.isOtherAudioPlaying {
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                print("✅ Audio session reactivated after interruption")
            }
        } catch {
            print("❌ Failed to reactivate audio session: \(error)")
        }
    }
    
    private func handleAudioSessionConflict() {
        print("⚠️ Audio session conflict detected, attempting to resolve...")
        
        // Wait a moment for any UI transitions to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.isRecording {
                // Reconfigure audio session if we're still recording
                if !self.configureAudioSession() {
                    print("❌ Failed to resolve audio session conflict")
                    self.errorMessage = "Audio session conflict detected. Please try recording again."
                    self.stopRecording()
                } else {
                    print("✅ Audio session conflict resolved")
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
        
        // Configure audio session with retry logic
        var audioSessionConfigured = false
        for attempt in 1...3 {
            if configureAudioSession() {
                audioSessionConfigured = true
                break
            } else {
                print("⚠️ Audio session configuration attempt \(attempt) failed")
                if attempt < 3 {
                    // Reset audio session before retrying
                    resetAudioSession()
                    // Brief pause before retrying (avoid Thread.sleep on main thread)
                    usleep(500000) // 0.5 seconds in microseconds
                }
            }
        }
        
        guard audioSessionConfigured else {
            errorMessage = "Failed to configure audio session after multiple attempts. Please try again."
            return
        }
        
        // Start audio recording (file only, no live recognition)
        if startAudioRecording() {
            isRecording = true
            recordingDuration = 0
            startRecordingTimer()
            print("🎤 Recording started successfully")
        } else {
            errorMessage = "Failed to start recording."
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        print("🛑 Stopping recording...")
        
        // Stop recording timer
        stopRecordingTimer()
        
        // Stop audio recording
        if let audioURL = stopAudioRecording() {
            isRecording = false
            
            // Start deferred transcription
            transcribeAudioFile(audioURL)
        } else {
            errorMessage = "Failed to stop recording."
            isRecording = false
        }
        
        // Deactivate audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            if audioSession.isOtherAudioPlaying {
                // Only deactivate if session is actually active
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                print("✅ Audio session deactivated successfully")
            } else {
                print("ℹ️ Audio session already inactive")
            }
            isAudioSessionConfigured = false
        } catch {
            print("⚠️ Failed to deactivate audio session: \(error)")
            // Don't treat this as a critical error - session might already be inactive
        }
        
        print("✅ Recording stopped successfully")
    }
    
    // MARK: - Recording Timer
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.recordingDuration += 1.0
                
                // Auto-stop if maximum duration reached
                if self?.recordingDuration ?? 0 >= self?.maxRecordingDuration ?? 300.0 {
                    print("⏰ Maximum recording duration reached, stopping automatically")
                    self?.stopRecording()
                }
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    // MARK: - Audio Recording (File Only - No Live Recognition)
    
    private func startAudioRecording() -> Bool {
        print("🎤 ULTRA-SIMPLE: Starting basic recording...")
        
        // Emergency crash protection
        return startAudioRecordingSimple()
    }
    
    private func startAudioRecordingSimple() -> Bool {
        print("🔥 EMERGENCY MODE: Simplest possible recording")
        
        // Step 1: Just stop the engine if running
        if audioEngine.isRunning {
            audioEngine.stop()
            print("✅ Engine stopped")
        }
        
        // Step 2: Clear any tap (might crash here)
        audioEngine.inputNode.removeTap(onBus: 0)
        print("✅ Tap cleared")
        
        // Step 3: Create simple recording file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingURL = documentsPath.appendingPathComponent("simple_recording.m4a")
        
        guard let recordingURL = recordingURL else {
            print("❌ Failed to create URL")
            return false
        }
        
        // Step 4: Get native input format (NO CONVERSION!)
        let inputNode = audioEngine.inputNode
        let nativeFormat = inputNode.outputFormat(forBus: 0)
        print("✅ Got native format: \(nativeFormat)")
        
        // Step 5: Create audio file with NATIVE format
        do {
            audioFile = try AVAudioFile(forWriting: recordingURL, settings: nativeFormat.settings)
            print("✅ Audio file created with native format")
        } catch {
            print("❌ File creation failed: \(error)")
            return false
        }
        
        // Step 6: Install tap with NATIVE format (no conversion)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: nativeFormat) { [weak self] buffer, _ in
            // Direct write - no conversion bullshit
            try? self?.audioFile?.write(from: buffer)
        }
        print("✅ Tap installed")
        
        // Step 7: Start engine
        do {
            audioEngine.prepare()
            try audioEngine.start()
            print("🎯 SIMPLE SUCCESS: Engine started")
            return true
        } catch {
            print("❌ Start failed: \(error)")
            return false
        }
    }
    
    private func stopAudioRecording() -> URL? {
        // Stop audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            print("🛑 Audio engine stopped")
        }
        
        // Properly close and flush audio file
        if let audioFile = audioFile {
            // The file is automatically flushed when deallocated, but let's be explicit
            print("📁 Closing audio file - recorded \(audioFile.length) samples")
        }
        audioFile = nil
        
        print("🛑 Audio recording stopped")
        
        // Verify the recorded file before returning
        if let url = recordingURL {
            if validateAudioFile(url) {
                print("✅ Audio file validation passed")
                return url
            } else {
                print("❌ Audio file validation failed")
                return nil
            }
        }
        
        return nil
    }
    
    // MARK: - Transcription
    
    private func transcribeAudioFile(_ audioURL: URL) {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition is not available."
            print("❌ Speech recognizer not available")
            return
        }
        
        print("🔄 Starting transcription process...")
        print("   - Audio file: \(audioURL.lastPathComponent)")
        print("   - Speech recognizer locale: \(speechRecognizer.locale.identifier)")
        print("   - Speech recognizer available: \(speechRecognizer.isAvailable)")
        
        // Validate audio file before transcription
        guard validateAudioFile(audioURL) else {
            errorMessage = "Invalid audio recording. Please try recording again."
            return
        }
        
        isTranscribing = true
        print("🎯 Creating SFSpeechURLRecognitionRequest...")
        
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        request.taskHint = .dictation
        
        print("🎯 Starting recognition task...")
        
        speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                print("📥 Recognition task callback received")
                if let error = error {
                    print("❌ Recognition task error: \(error)")
                }
                if let result = result {
                    print("📝 Recognition result received - final: \(result.isFinal)")
                    print("📝 Best transcription: '\(result.bestTranscription.formattedString)'")
                } else {
                    print("⚠️ Recognition result is nil")
                }
                self?.handleTranscriptionResult(result: result, error: error)
            }
        }
    }
    
    private func handleTranscriptionResult(result: SFSpeechRecognitionResult?, error: Error?) {
        isTranscribing = false
        
        if let error = error {
            print("❌ Transcription error: \(error.localizedDescription)")
            
            // Provide more specific error messages
            if error.localizedDescription.contains("no speech") {
                errorMessage = "No speech detected. Please try speaking more clearly or for a longer duration."
            } else if error.localizedDescription.contains("network") {
                errorMessage = "Network error during transcription. Please check your internet connection."
            } else {
                errorMessage = "Transcription failed: \(error.localizedDescription)"
            }
            return
        }
        
        if let result = result {
            let newTranscript = result.bestTranscription.formattedString
            if !newTranscript.isEmpty {
                transcript = newTranscript
                print("✅ Transcription completed: \(newTranscript)")
            } else {
                print("⚠️ Transcription completed but no text was detected")
                errorMessage = "No speech detected in recording. Please try speaking more clearly."
            }
        } else {
            print("⚠️ Transcription completed with no result")
            errorMessage = "Transcription completed but no result was returned."
        }
    }
    
    // MARK: - Audio File Validation
    
    private func validateAudioFile(_ url: URL) -> Bool {
        print("🔍 Validating audio file: \(url.lastPathComponent)")
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌ Audio file does not exist: \(url.path)")
            return false
        }
        
        // Check file size
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            print("📁 Audio file size: \(fileSize) bytes")
            
            if fileSize < 1024 {
                print("❌ Audio file too small: \(fileSize) bytes")
                return false
            }
        } catch {
            print("⚠️ Could not check file attributes: \(error)")
            return false
        }
        
        // Try to create an AVAudioFile to validate format
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let duration = Double(audioFile.length) / audioFile.processingFormat.sampleRate
            
            print("✅ Audio file validation:")
            print("   - Duration: \(String(format: "%.2f", duration)) seconds")
            print("   - Samples: \(audioFile.length)")
            print("   - Sample Rate: \(audioFile.processingFormat.sampleRate) Hz")
            print("   - Channels: \(audioFile.processingFormat.channelCount)")
            print("   - Format: \(audioFile.processingFormat.commonFormat.rawValue)")
            
            // Check minimum duration (should be at least 0.1 seconds)
            if duration < 0.1 {
                print("❌ Audio duration too short: \(duration) seconds")
                return false
            }
            
            // Check if the format is supported by SFSpeechRecognizer
            let supportedFormats: [AVAudioCommonFormat] = [.pcmFormatFloat32, .pcmFormatInt16, .pcmFormatInt32]
            if !supportedFormats.contains(audioFile.processingFormat.commonFormat) {
                print("⚠️ Audio format may not be optimal for speech recognition: \(audioFile.processingFormat.commonFormat)")
            }
            
            return true
        } catch {
            print("❌ Invalid audio file format: \(error)")
            return false
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func configureAudioSession() -> Bool {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Check if session is already active before trying to deactivate
            if audioSession.isOtherAudioPlaying || audioSession.category != .playAndRecord {
                // Only deactivate if session is in a different state
                do {
                    try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                    print("🔄 Deactivated existing audio session")
                } catch {
                    print("⚠️ Audio session deactivation failed (may already be inactive): \(error)")
                    // Continue anyway - the session might already be inactive
                }
            }
            
            // Set category with more appropriate options for voice recording
            try audioSession.setCategory(
                .playAndRecord, // Changed from .record to .playAndRecord for better compatibility
                mode: .voiceChat, // Changed from .measurement to .voiceChat
                options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker]
            )
            
            // Set preferred sample rate and I/O buffer duration for better performance
            try audioSession.setPreferredSampleRate(44100.0)
            try audioSession.setPreferredIOBufferDuration(0.005)
            
            // Activate the session with more robust options
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            isAudioSessionConfigured = true
            print("✅ Audio session configured successfully")
            return true
        } catch {
            errorMessage = "Failed to configure audio session: \(error.localizedDescription)"
            print("❌ Audio session configuration failed: \(error)")
            
            // Try a fallback configuration
            return configureAudioSessionFallback()
        }
    }
    
    private func configureAudioSessionFallback() -> Bool {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Check if session needs deactivation before fallback
            if audioSession.isOtherAudioPlaying || audioSession.category != .record {
                do {
                    try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                    print("🔄 Deactivated audio session for fallback")
                } catch {
                    print("⚠️ Audio session deactivation failed in fallback: \(error)")
                    // Continue anyway
                }
            }
            
            // Fallback to simpler configuration
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
            
            isAudioSessionConfigured = true
            print("✅ Audio session configured with fallback")
            return true
        } catch {
            errorMessage = "Failed to configure audio session (fallback also failed): \(error.localizedDescription)"
            print("❌ Audio session fallback configuration failed: \(error)")
            return false
        }
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
                print("⚠️ Speech recognition became unavailable")
            } else {
                print("✅ Speech recognition became available")
            }
        }
    }
}