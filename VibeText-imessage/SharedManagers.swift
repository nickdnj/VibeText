//
//  SharedManagers.swift
//  VibeText-imessage
//
//  Created by Nick DeMarco on 7/30/25.
//

import Foundation
import Speech
import AVFoundation
import Combine
import Security

// MARK: - Message Model

struct Message: Identifiable, Codable {
    let id: UUID
    let originalTranscript: String
    var cleanedText: String
    var tone: MessageTone
    var customPrompt: String?
    let createdAt: Date
    
    init(originalTranscript: String, cleanedText: String, tone: MessageTone, customPrompt: String? = nil) {
        self.id = UUID()
        self.originalTranscript = originalTranscript
        self.cleanedText = cleanedText
        self.tone = tone
        self.customPrompt = customPrompt
        self.createdAt = Date()
    }
}

/// Available tone presets for message transformation
enum MessageTone: String, CaseIterable, Codable {
    case professional = "Professional"
    case boomer = "Boomer"
    case genX = "Gen X"
    case genZ = "Gen Z"
    case casual = "Casual"
    case millennial = "Millennial"
    case trump = "Trump"
    case shakespearean = "Shakespearean"
    case corporateSpeak = "Corporate Speak"
    case drySarcastic = "Dry/Sarcastic"
    case gamerMode = "Gamer Mode"
    case romantic = "Romantic"
    case zen = "Zen"
    case robotLiteral = "Robot/AI Literal"
    
    var emoji: String {
        switch self {
        case .professional: return "🎓"
        case .boomer: return "👴"
        case .genX: return "😎"
        case .genZ: return "👶"
        case .casual: return "🎉"
        case .millennial: return "🧠"
        case .trump: return "🇺🇸"
        case .shakespearean: return "🎩"
        case .corporateSpeak: return "📱"
        case .drySarcastic: return "🧊"
        case .gamerMode: return "🎮"
        case .romantic: return "💘"
        case .zen: return "🧘"
        case .robotLiteral: return "🤖"
        }
    }
    
    var displayName: String {
        return "\(emoji) \(rawValue)"
    }
    
    /// System prompt for OpenAI to apply this tone
    var systemPrompt: String {
        switch self {
        case .professional:
            return "You will receive voice input describing what someone wants to text/message. Your job is to understand their intent and create the actual message they want to send in a professional tone. Use clear, formal, and business-appropriate language. Use proper grammar, avoid slang, and maintain a respectful tone. Return ONLY the message to be sent with no commentary, explanations, or framing text."
        case .boomer:
            return "You will receive voice input describing what someone wants to text/message. Your job is to understand their intent and create the actual message they want to send in a tone that older adults would appreciate. Be warm, respectful, and avoid modern slang and abbreviations. Return ONLY the message to be sent with no commentary, explanations, or framing text."
        case .genX:
            return "You will receive voice input describing what someone wants to text/message. Your job is to understand their intent and create the actual message they want to send in a Gen X tone. Be friendly but not overly casual, using language that resonates with Gen X (born 1965-1980). Return ONLY the message to be sent with no commentary, explanations, or framing text."
        case .genZ:
            return "You will receive voice input describing what someone wants to text/message. Your job is to understand their intent and create the actual message they want to send in a Gen Z tone. Be casual, use modern slang appropriately, emojis, and language that younger people would use naturally. Return ONLY the message to be sent with no commentary, explanations, or framing text."
        case .casual:
            return "You will receive voice input describing what someone wants to text/message. Your job is to understand their intent and create the actual message they want to send in a casual tone. Be warm and approachable while maintaining clarity and natural flow. Return ONLY the message to be sent with no commentary, explanations, or framing text."
        case .millennial:
            return "You will receive voice input describing what someone wants to text/message. Your job is to understand their intent and create the actual message they want to send in a Millennial tone. Be warm, polite, slightly self-deprecating, with subtle enthusiasm. Use natural language like \"just wanted to check,\" \"no worries if not,\" or \"hope you're doing well.\" Return ONLY the message to be sent with no commentary, explanations, or framing text."
        case .trump:
            return "You will receive voice input describing what someone wants to text/message. Your job is to understand their intent and create the actual message they want to send in Donald Trump's style. Use short, confident sentences with strong adjectives (e.g., \"tremendous,\" \"amazing,\" \"a total disaster\"), repetition for emphasis, and a combative or victorious tone if relevant. Make it bold and unmistakable. Return ONLY the message to be sent with no commentary, explanations, or framing text."
        case .shakespearean:
            return "You will receive voice input describing what someone wants to text/message. Your job is to understand their intent and create the actual message they want to send in Shakespearean English. Use poetic phrasing, archaic vocabulary (e.g., thee, thou, thy), and metaphor when appropriate. Preserve the meaning but reframe it as if spoken in a dramatic play. Return ONLY the message to be sent with no commentary, explanations, or framing text."
        case .corporateSpeak:
            return "You will receive voice input describing what someone wants to text/message. Your job is to understand their intent and create the actual message they want to send in corporate jargon. Use phrases like \"let's circle back,\" \"synergize,\" or \"moving forward.\" Be vague, diplomatic, and slightly over-structured. Avoid direct language. Return ONLY the message to be sent with no commentary, explanations, or framing text."
        case .drySarcastic:
            return "You will receive voice input describing what someone wants to text/message. Your job is to understand their intent and create the actual message they want to send with a dry, sarcastic tone. Use minimal emotion, deadpan phrasing, and implied judgment or irony where appropriate. Keep it cool and detached. Return ONLY the message to be sent with no commentary, explanations, or framing text."
        case .gamerMode:
            return "You will receive voice input describing what someone wants to text/message. Your job is to understand their intent and create the actual message they want to send like a gamer would. Use gaming slang, abbreviations, and casual tone (e.g., \"GG,\" \"bruh,\" \"OP,\" \"nerfed\"). Keep it edgy but readable. Avoid actual profanity. Return ONLY the message to be sent with no commentary, explanations, or framing text."
        case .romantic:
            return "You will receive voice input describing what someone wants to text/message. Your job is to understand their intent and create the actual message they want to send with an affectionate and romantic tone. Use warm, sincere language, gentle tone, and thoughtful phrasing. Express care or love directly and honestly. Return ONLY the message to be sent with no commentary, explanations, or framing text."
        case .zen:
            return "You will receive voice input describing what someone wants to text/message. Your job is to understand their intent and create the actual message they want to send in a calm, peaceful, and grounding tone. Use soothing language, positive affirmations, and present-tense mindfulness. It should feel like something from a meditation guide or supportive friend. Return ONLY the message to be sent with no commentary, explanations, or framing text."
        case .robotLiteral:
            return "You will receive voice input describing what someone wants to text/message. Your job is to understand their intent and create the actual message they want to send with a robotic, overly literal tone. Use precise language, avoid idioms, and eliminate emotional expression. Structure sentences like a machine might. The result should sound like a helpful but unemotional AI. Return ONLY the message to be sent with no commentary, explanations, or framing text."
        }
    }
}

// MARK: - Settings Manager

/// Manages app settings and secure storage of API keys
class SettingsManager: ObservableObject {
    @Published var openAIAPIKey: String = ""
    @Published var lastUsedTone: MessageTone = .casual
    @Published var isUsingDefaultKey: Bool = true
    
    private let keychainService = "com.d3marco.VibeText"
    // App Groups temporarily disabled due to provisioning issues
    // private let keychainAccessGroup = "group.com.d3marco.VibeText.shared"
    // private let sharedUserDefaults = UserDefaults(suiteName: "group.com.d3marco.VibeText.shared")
    private let apiKeyKey = "OpenAIAPIKey"
    private let lastToneKey = "LastUsedTone"
    // Load default API key from Secrets.plist
    private var defaultAPIKey: String {
        // Try multiple bundle approaches for extension compatibility
        let bundlesToTry = [
            Bundle.main,
            Bundle(for: MessagesViewController.self)
        ]
        
        for bundle in bundlesToTry {
            if let path = bundle.path(forResource: "Secrets", ofType: "plist"),
               let plist = NSDictionary(contentsOfFile: path),
               let key = plist["DefaultOpenAIAPIKey"] as? String {
                NSLog("🔑 Extension: Successfully loaded default API key from Secrets.plist via %@ (length: %d)", bundle.bundleIdentifier ?? "unknown", key.count)
                return key
            }
        }
        
        NSLog("❌ Extension: Failed to load default API key from Secrets.plist from any bundle")
        return "sk-proj-1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef" // Fallback
    }
    
    init() {
        loadSettings()
    }
    
    // MARK: - API Key Management
    
    func saveAPIKey(_ key: String) {
        openAIAPIKey = key
        isUsingDefaultKey = key.isEmpty
        
        if key.isEmpty {
            // Clear extension storage
            UserDefaults.standard.removeObject(forKey: "ExtensionAPIKey")
            NSLog("🗑️ Extension: Cleared API key from extension storage")
        } else {
            // Save to extension's local storage (simplified approach)
            UserDefaults.standard.set(key, forKey: "ExtensionAPIKey")
            NSLog("✅ Extension: Saved API key to extension local storage")
        }
    }
    
    func getCurrentAPIKey() -> String {
        let key = openAIAPIKey.isEmpty ? defaultAPIKey : openAIAPIKey
        NSLog("🔑 Extension: getCurrentAPIKey() returning key with length: %d", key.count)
        NSLog("🔑 Extension: isUsingDefaultKey: %@", isUsingDefaultKey ? "true" : "false")
        return key
    }
    
    func resetToDefaultKey() {
        openAIAPIKey = ""
        isUsingDefaultKey = true
        deleteAPIKeyFromKeychain()
    }
    
    // MARK: - Tone Settings
    
    func saveLastUsedTone(_ tone: MessageTone) {
        lastUsedTone = tone
        UserDefaults.standard.set(tone.rawValue, forKey: lastToneKey)
    }
    
    // MARK: - Private Methods
    
    private func loadSettings() {
        NSLog("🔑 Extension: Loading settings...")
        
        // Load API key from keychain
        if let apiKey = loadAPIKeyFromKeychain() {
            NSLog("✅ Extension: Successfully loaded API key from keychain (length: %d)", apiKey.count)
            openAIAPIKey = apiKey
            isUsingDefaultKey = false
        } else {
            NSLog("❌ Extension: Failed to load API key from keychain, using default")
            isUsingDefaultKey = true
        }
        
        NSLog("🔑 Extension: isUsingDefaultKey: %@", isUsingDefaultKey ? "true" : "false")
        NSLog("🔑 Extension: getCurrentAPIKey() returns key with length: %d", getCurrentAPIKey().count)
        
        // Debug: Test Secrets.plist access
        NSLog("🔍 Extension: Testing Secrets.plist access...")
        let testKey = defaultAPIKey
        NSLog("🔍 Extension: defaultAPIKey length: %d", testKey.count)
        
        // Load last used tone
        if let toneRawValue = UserDefaults.standard.string(forKey: lastToneKey),
           let tone = MessageTone(rawValue: toneRawValue) {
            lastUsedTone = tone
        }
    }
    
    private func saveAPIKeyToKeychain(_ key: String) {
        // Simplified approach - not using keychain for extension
        NSLog("🔑 Extension: Keychain save disabled - using UserDefaults instead")
    }
    
    private func loadAPIKeyFromKeychain() -> String? {
        NSLog("🔑 Extension: App Groups disabled - using extension local storage...")
        
        // SIMPLIFIED APPROACH: Use extension's own UserDefaults
        // This won't share with main app, but allows extension to work independently
        if let apiKey = UserDefaults.standard.string(forKey: "ExtensionAPIKey"),
           !apiKey.isEmpty {
            NSLog("✅ Extension: Successfully loaded API key from extension storage (length: %d)", apiKey.count)
            return apiKey
        }
        
        NSLog("⚠️ Extension: No API key found in extension storage")
        NSLog("💡 Extension: User will need to enter API key directly in extension")
        return nil
    }
    
    private func deleteAPIKeyFromKeychain() {
        // Simplified approach - not using keychain for extension
        NSLog("🔑 Extension: Keychain delete disabled - using UserDefaults instead")
    }
}

// MARK: - Message Formatter

/// Manages D3APIProxy interactions for text processing and tone transformation
class MessageFormatter: ObservableObject {
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    private let proxyService = ProxyNetworkService.shared
    
    init() {
        // No longer need SettingsManager since we use proxy
    }
    
    // MARK: - Text Processing
    
    func processTranscript(_ transcript: String, tone: MessageTone, customPrompt: String? = nil) async -> String? {
        await MainActor.run {
            isProcessing = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isProcessing = false
            }
        }
        
        let userPrompt = buildUserPrompt(transcript: transcript, customPrompt: customPrompt)
        
        do {
            let response = try await callProxy(
                systemPrompt: tone.systemPrompt,
                userPrompt: userPrompt
            )
            
            return response
        } catch {
            await MainActor.run {
                errorMessage = "Failed to process text: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    func regenerateWithTone(_ transcript: String, tone: MessageTone, customPrompt: String? = nil) async -> String? {
        return await processTranscript(transcript, tone: tone, customPrompt: customPrompt)
    }
    
    /// Transform an already-processed message text with a new tone
    /// This is used when the user has edited the message and wants to apply a different tone
    func transformMessageWithTone(_ messageText: String, tone: MessageTone, customPrompt: String? = nil) async -> String? {
        await MainActor.run {
            isProcessing = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isProcessing = false
            }
        }
        
        let userPrompt = buildToneTransformationPrompt(messageText: messageText, customPrompt: customPrompt)
        
        do {
            let response = try await callProxy(
                systemPrompt: tone.systemPrompt,
                userPrompt: userPrompt
            )
            
            return response
        } catch {
            await MainActor.run {
                errorMessage = "Failed to transform text: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func buildUserPrompt(transcript: String, customPrompt: String?) -> String {
        var prompt = """
        You're given a raw, stream-of-consciousness transcript where the speaker may change topics mid-sentence, revisit earlier points, or add thoughts out of order.

        Your task is to turn this into a clear, logically organized message that preserves the speaker's intent. Summarize or reorder ideas if needed for clarity, and remove filler or redundant phrases.

        Do not include any commentary—only return the clean, structured message.

        Transcript: "\(transcript)"
        """
        
        if let customPrompt = customPrompt, !customPrompt.isEmpty {
            prompt += "\n\nAdditional instructions: \(customPrompt)"
        }
        
        return prompt
    }
    
    private func buildToneTransformationPrompt(messageText: String, customPrompt: String?) -> String {
        var prompt = """
        You're given a message that the user has already crafted and potentially edited. Your task is to transform this message to match the requested tone while preserving the user's specific content, names, details, and intent.
        
        Do not treat this as a rough transcript to clean up - this is already a complete message that just needs tone adjustment. Preserve all specific information the user has included.
        
        Do not include any commentary—only return the message with the new tone applied.
        
        Message to transform: "\(messageText)"
        """
        
        if let customPrompt = customPrompt, !customPrompt.isEmpty {
            prompt += "\n\nAdditional instructions: \(customPrompt)"
        }
        
        return prompt
    }
    
    private func callProxy(systemPrompt: String, userPrompt: String) async throws -> String {
        NSLog("🌐 iMessage Extension: Starting D3APIProxy call...")
        
        return try await withCheckedThrowingContinuation { continuation in
            let messages = [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ]
            
            proxyService.sendChatCompletion(
                messages: messages,
                model: "gpt-4o-mini",
                temperature: 0.7,
                maxTokens: 500
            ) { result in
                switch result {
                case .success(let response):
                    if let firstChoice = response.choices.first {
                        let content = firstChoice.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        guard !content.isEmpty else {
                            NSLog("❌ iMessage Extension: Empty response from proxy")
                            continuation.resume(throwing: MessageFormatterError.invalidResponse)
                            return
                        }
                        
                        NSLog("✅ iMessage Extension: Proxy API call successful, response length: %d", content.count)
                        continuation.resume(returning: content)
                    } else {
                        NSLog("❌ iMessage Extension: No choices in proxy response")
                        continuation.resume(throwing: MessageFormatterError.invalidResponse)
                    }
                    
                case .failure(let proxyError):
                    NSLog("❌ iMessage Extension: Proxy error: %@", proxyError.localizedDescription)
                    // Map ProxyError to MessageFormatterError
                    let formatterError = self.mapProxyErrorToFormatterError(proxyError)
                    continuation.resume(throwing: formatterError)
                }
            }
        }
    }
    
    private func mapProxyErrorToFormatterError(_ proxyError: ProxyError) -> MessageFormatterError {
        switch proxyError {
        case .authenticationFailed:
            return .noAPIKey
        case .networkError, .invalidResponse, .timeout:
            return .invalidResponse
        case .rateLimited(let message):
            return .apiError(statusCode: 429, message: message)
        case .serverError(let message):
            return .apiError(statusCode: 500, message: message)
        case .badRequest(let message):
            return .apiError(statusCode: 400, message: message)
        case .decodingError, .invalidRequest, .unknownError:
            return .invalidResponse
        }
    }
}

// MARK: - Message Formatter Errors

enum MessageFormatterError: LocalizedError {
    case noAPIKey
    case invalidURL
    case invalidRequest
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured. Please add your OpenAI API key in settings."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidRequest:
            return "Invalid request format"
        case .invalidResponse:
            return "Invalid response from OpenAI"
        case .apiError(let statusCode, let message):
            return "API Error (\(statusCode)): \(message)"
        }
    }
}

// MARK: - Speech Manager

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
        
        // Note: Screen wake control not available in app extensions
        // Extensions should be brief anyway, so this isn't needed
    }
    
    // MARK: - Authorization
    
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
            }
            
            if status == .authorized {
                self?.requestMicrophonePermission()
            }
        }
    }
    
    private func requestMicrophonePermission() {
        print("🎙️ VibeText Extension: Requesting microphone permission...")
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                print("🎙️ VibeText Extension: Microphone permission result: \(granted)")
                if !granted {
                    print("❌ VibeText Extension: Microphone permission denied")
                    self?.errorMessage = "Microphone permission is required for voice recording."
                } else {
                    print("✅ VibeText Extension: Microphone permission granted")
                }
            }
        }
    }
    
    private func checkExtensionMicrophoneCapability() -> Bool {
        print("🎙️ VibeText Extension: Checking if microphone is available in extension context...")
        
        let audioSession = AVAudioSession.sharedInstance()
        
        // Check if we can set the audio category for recording
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: [])
            print("✅ VibeText Extension: Audio category set successfully")
            
            // Try to activate the session
            try audioSession.setActive(true, options: [])
            print("✅ VibeText Extension: Audio session activated successfully")
            
            // Check if input is available
            if audioSession.isInputAvailable {
                print("✅ VibeText Extension: Audio input is available")
                return true
            } else {
                print("❌ VibeText Extension: Audio input is not available")
                errorMessage = "Microphone not available in Messages extension"
                return false
            }
        } catch {
            print("❌ VibeText Extension: Failed to configure audio for recording: \(error)")
            errorMessage = "Cannot access microphone in Messages extension: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Recording Control
    
    func startRecording() -> Bool {
        print("🎙️ VibeText Extension: === Starting Recording Process ===")
        print("🎙️ Extension: Current recording state: \(isRecording)")
        print("🎙️ Extension: Audio engine running: \(audioEngine.isRunning)")
        
        // Clear any previous error
        errorMessage = nil
        
        // Force microphone permission check for extensions
        print("🎙️ Extension: Checking microphone capability in extension context...")
        if !checkExtensionMicrophoneCapability() {
            print("❌ Extension: Microphone capability check failed")
            return false
        }
        
        guard authorizationStatus == .authorized else {
            print("❌ Extension: Speech recognition not authorized - status: \(authorizationStatus)")
            if authorizationStatus == .notDetermined {
                print("🔄 Extension: Requesting speech recognition permission...")
                requestSpeechAuthorization()
                return false
            }
            errorMessage = "Speech recognition not authorized"
            return false
        }
        
        print("✅ Extension: Speech recognition authorized")
        
        // Check microphone permission with detailed logging
        let audioSession = AVAudioSession.sharedInstance()
        let micPermission = audioSession.recordPermission
        print("🎙️ Extension: Microphone permission status: \(micPermission)")
        print("🎙️ Extension: Audio session category: \(audioSession.category)")
        print("🎙️ Extension: Other audio playing: \(audioSession.isOtherAudioPlaying)")
        print("🎙️ Extension: Input available: \(audioSession.isInputAvailable)")
        
        if micPermission == .undetermined {
            print("⚠️ Extension: Microphone permission undetermined, requesting...")
            requestMicrophonePermission()
            return false
        }
        
        guard micPermission == .granted else {
            print("❌ Extension: Microphone permission not granted")
            errorMessage = "Microphone permission required"
            return false
        }
        
        print("✅ Extension: Microphone permission granted")
        
        // Configure audio session with detailed logging
        print("🎙️ Extension: Configuring audio session...")
        guard configureAudioSession() else {
            print("❌ Extension: Failed to configure audio session")
            errorMessage = "Failed to configure audio session for extension"
            return false
        }
        
        print("✅ Extension: Audio session configured successfully")
        
        // Start actual recording
        print("🎙️ Extension: Starting audio recording...")
        if startAudioRecording() {
            print("✅ Extension: Audio recording engine started")
            isRecording = true
            transcript = ""
            errorMessage = nil
            startRecordingTimer()
            
            print("✅ Extension: === Recording Started Successfully ===")
            return true
        } else {
            print("❌ Extension: Failed to start audio recording engine")
            errorMessage = "Failed to start recording in extension context"
            return false
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        stopRecordingTimer()
        stopAudioRecording()
        
        // Note: Screen wake control not available in app extensions
        
        print("✅ Recording stopped successfully")
    }
    
    // MARK: - Audio Recording
    
    private func startAudioRecording() -> Bool {
        return startAudioRecordingSimple()
    }
    
    private func startAudioRecordingSimple() -> Bool {
        print("🎙️ Starting stable audio recording for extension...")
        
        // Clean stop any existing recording
        if audioEngine.isRunning {
            audioEngine.stop()
            print("✅ Engine stopped")
        }
        
        audioEngine.inputNode.removeTap(onBus: 0)
        print("✅ Tap cleared")
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingURL = documentsPath.appendingPathComponent("extension_recording_\(Date().timeIntervalSince1970).m4a")
        
        guard let recordingURL = recordingURL else {
            print("❌ Failed to create URL")
            return false
        }
        
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        print("🎵 Input format: \(inputFormat)")
        
        // Use a standard format to prevent engine reconfigurations
        // This should help with the sample rate changes we saw in the logs
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
        print("🎯 Configuring audio session for iMessage extension...")
        let audioSession = AVAudioSession.sharedInstance()
        
        // For iMessage extensions, be very conservative with audio session management
        // Only configure if we absolutely need to
        
        do {
            // Check current category - if it's already suitable, don't change it
            let currentCategory = audioSession.category
            print("🎯 Current audio category: \(currentCategory)")
            
            // Only set category if it's not already recording-capable
            if currentCategory != .record && currentCategory != .playAndRecord {
                print("🎯 Setting minimal audio category for extension...")
                // Use minimal options to avoid conflicts with Messages app
                try audioSession.setCategory(.record, mode: .default, options: [.mixWithOthers, .allowBluetooth])
            }
            
            // Only activate if not already active
            if !audioSession.isOtherAudioPlaying {
                print("🎯 Activating audio session gently...")
                try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])
            }
            
            isAudioSessionConfigured = true
            print("✅ Audio session configured successfully for extension")
            return true
        } catch {
            print("❌ Failed to configure audio session: \(error)")
            return configureAudioSessionMinimal()
        }
    }
    
    private func configureAudioSessionMinimal() -> Bool {
        print("🔄 Trying minimal audio session configuration for extension...")
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            // Absolutely minimal configuration - just try to record
            try audioSession.setCategory(.record)
            isAudioSessionConfigured = true
            
            print("✅ Minimal audio session configured successfully")
            return true
        } catch {
            print("❌ Even minimal audio session configuration failed: \(error)")
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
            
            // For extensions, be more patient with recovery
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                print("🔄 Attempting to recover from audio session conflict...")
                
                // Try to reset and reconfigure
                if self.resetAudioSession() && self.configureAudioSession() {
                    print("✅ Audio session conflict resolved")
                    self.errorMessage = "Audio session recovered. You can try recording again."
                } else {
                    print("❌ Could not recover from audio session conflict")
                    self.errorMessage = "Audio session conflict. Please close and reopen the extension."
                }
            }
        }
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

// MARK: - VoiceCaptureViewModel

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
        print("🎙️ VibeText Extension: VoiceCaptureViewModel.startRecording() called")
        _ = speechManager.startRecording()
    }
    
    func stopRecording() {
        print("🛑 VibeText Extension: VoiceCaptureViewModel.stopRecording() called")
        speechManager.stopRecording()
        
        // Start processing transcript when it becomes available
        // We'll monitor the transcript changes and process when transcription completes
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
        speechManager.transcript = ""
    }
    
    func updateMessageText(_ newText: String) {
        currentMessage?.cleanedText = newText
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Monitor speech manager errors
        speechManager.$errorMessage
            .compactMap { $0 }
            .assign(to: \.errorMessage, on: self)
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
}