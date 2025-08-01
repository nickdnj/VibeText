import Foundation
import Combine

/// Manages OpenAI API interactions for text processing and tone transformation
class MessageFormatter: ObservableObject, ErrorHandling {
    @Published var isProcessing = false
    @Published var currentError: AppError?
    
    private let settingsManager: SettingsManager
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private var currentTask: Task<Void, Never>?
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
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
                let response = try await callOpenAI(
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
                let response = try await callOpenAI(
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
    
    private func callOpenAI(systemPrompt: String, userPrompt: String) async throws -> String {
        print("🌐 Main App: Starting OpenAI API call...")
        let apiKey = settingsManager.getCurrentAPIKey()
        
        print("🌐 Main App: API key length: \(apiKey.count)")
        print("🌐 Main App: API key starts with: \(String(apiKey.prefix(10)))...")
        
        guard !apiKey.isEmpty else {
            print("❌ Main App: No API key configured")
            throw AppError.noAPIKey
        }
        
        // Validate API key format
        guard apiKey.hasPrefix("sk-") else {
            print("❌ Main App: Invalid API key format")
            throw AppError.apiKeyInvalid
        }
        
        print("✅ Main App: API key found and valid")
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "max_tokens": 500,
            "temperature": 0.7
        ]
        
        guard let url = URL(string: baseURL) else {
            throw AppError.unknownError("Invalid API URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30.0 // 30 second timeout
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw AppError.unknownError("Failed to create request: \(error.localizedDescription)")
        }
        
        print("🌐 Main App: Making network request to OpenAI...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Main App: Invalid HTTP response")
                throw AppError.invalidAPIResponse
            }
            
            print("🌐 Main App: Received response with status code: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Main App: API error (status \(httpResponse.statusCode)): \(errorMessage)")
                
                // Handle specific HTTP status codes
                switch httpResponse.statusCode {
                case 401:
                    throw AppError.apiKeyInvalid
                case 429:
                    throw AppError.apiError(statusCode: httpResponse.statusCode, message: "Rate limit exceeded. Please try again later.")
                case 500...599:
                    throw AppError.apiError(statusCode: httpResponse.statusCode, message: "Server error. Please try again later.")
                default:
                    throw AppError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
                }
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let choices = json?["choices"] as? [[String: Any]],
                      let firstChoice = choices.first,
                      let message = firstChoice["message"] as? [String: Any],
                      let content = message["content"] as? String else {
                    print("❌ Main App: Failed to parse OpenAI response")
                    throw AppError.invalidAPIResponse
                }
                
                let result = content.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Validate response is not empty
                guard !result.isEmpty else {
                    throw AppError.invalidAPIResponse
                }
                
                print("✅ Main App: OpenAI API call successful, response length: \(result.count)")
                return result
            } catch {
                print("❌ Main App: JSON parsing error: \(error.localizedDescription)")
                throw AppError.invalidAPIResponse
            }
        } catch let error as AppError {
            // Re-throw AppError as-is
            throw error
        } catch {
            // Handle network errors with better error mapping
            if let urlError = error as? URLError {
                print("❌ Main App: Network error: \(urlError.localizedDescription)")
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    throw AppError.networkUnreachable
                case .timedOut:
                    throw AppError.apiTimeout
                case .cannotFindHost, .cannotConnectToHost:
                    throw AppError.networkUnreachable
                default:
                    throw AppError.unknownError("Network error: \(urlError.localizedDescription)")
                }
            } else {
                print("❌ Main App: Unknown error: \(error.localizedDescription)")
                throw AppError.unknownError(error.localizedDescription)
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
} 