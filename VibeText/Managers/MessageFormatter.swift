import Foundation
import Combine

/// Manages D3APIProxy interactions for text processing and tone transformation
class MessageFormatter: ObservableObject, ErrorHandling {
    @Published var isProcessing = false
    @Published var currentError: AppError?
    
    private let proxyService = ProxyNetworkService.shared
    private var currentTask: Task<Void, Never>?
    
    init() {
        // No longer need SettingsManager since we use proxy
    }
    
    deinit {
        cancelCurrentTask()
    }
    
    // MARK: - Text Processing
    
    func processTranscript(_ transcript: String, tone: MessageTone, customPrompt: String? = nil) async -> String? {
        return await withTaskCancellationHandler(operation: {
            await MainActor.run {
                isProcessing = true
                clearError()
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
                
                await MainActor.run {
                    clearError()
                }
                
                return response
            } catch {
                let appError = mapError(error)
                ErrorHandler.handle(appError, in: self)
                return nil
            }
        }, onCancel: {
            // Task cancellation handled by Swift concurrency
        })
    }
    
    func regenerateWithTone(_ transcript: String, tone: MessageTone, customPrompt: String? = nil) async -> String? {
        return await processTranscript(transcript, tone: tone, customPrompt: customPrompt)
    }
    
    /// Transform an already-processed message text with a new tone
    /// This is used when the user has edited the message and wants to apply a different tone
    func transformMessageWithTone(_ messageText: String, tone: MessageTone, customPrompt: String? = nil) async -> String? {
        return await withTaskCancellationHandler(operation: {
            await MainActor.run {
                isProcessing = true
                clearError()
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
                
                await MainActor.run {
                    clearError()
                }
                
                return response
            } catch {
                let appError = mapError(error)
                ErrorHandler.handle(appError, in: self)
                return nil
            }
        }, onCancel: {
            // Task cancellation handled by Swift concurrency
        })
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
        print("🌐 Main App: Starting D3APIProxy call...")
        
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
                            print("❌ Main App: Empty response from proxy")
                            continuation.resume(throwing: AppError.invalidAPIResponse)
                            return
                        }
                        
                        print("✅ Main App: Proxy API call successful, response length: \(content.count)")
                        continuation.resume(returning: content)
                    } else {
                        print("❌ Main App: No choices in proxy response")
                        continuation.resume(throwing: AppError.invalidAPIResponse)
                    }
                    
                case .failure(let proxyError):
                    print("❌ Main App: Proxy error: \(proxyError.localizedDescription)")
                    // Map ProxyError to AppError
                    let appError = self.mapProxyErrorToAppError(proxyError)
                    continuation.resume(throwing: appError)
                }
            }
        }
    }
    
    // MARK: - Testing & Debugging
    
    /// Test method to simulate offline mode and verify error handling
    func testOfflineMode() async -> Bool {
        print("🧪 Testing offline mode error handling...")
        
        // Simulate a network error by using an invalid URL
        let testURL = "https://invalid-test-url-that-will-fail.com"
        
        guard let url = URL(string: testURL) else {
            print("❌ Test failed: Could not create test URL")
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0 // Short timeout for testing
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            print("❌ Test failed: Request succeeded when it should have failed")
            return false
        } catch {
            print("✅ Test passed: Network error caught correctly: \(error.localizedDescription)")
            return true
        }
    }
    
    // MARK: - Error Handling
    
    func retry() {
        // This will be implemented by the calling view model
        clearError()
    }
    
    func clearError() {
        currentError = nil
    }
    
    private func cancelCurrentTask() {
        // Task cancellation is handled by the calling context
    }
    
    private func mapError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        // Map other errors to AppError
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnreachable
            case .timedOut:
                return .apiTimeout
            default:
                return .unknownError("Network error: \(urlError.localizedDescription)")
            }
        }
        
        return .unknownError(error.localizedDescription)
    }
    
    private func mapProxyErrorToAppError(_ proxyError: ProxyError) -> AppError {
        switch proxyError {
        case .authenticationFailed:
            return .serviceUnavailable
        case .networkError, .invalidResponse:
            return .networkUnreachable
        case .timeout:
            return .apiTimeout
        case .rateLimited:
            return .apiError(statusCode: 429, message: "Rate limit exceeded. Please try again later.")
        case .serverError(let message):
            return .apiError(statusCode: 500, message: message)
        case .badRequest(let message):
            return .apiError(statusCode: 400, message: message)
        case .decodingError:
            return .invalidAPIResponse
        case .invalidRequest, .unknownError:
            return .unknownError(proxyError.localizedDescription)
        }
    }
} 