import Foundation
import Combine

/// Manages OpenAI API interactions for text processing and tone transformation
class MessageFormatter: ObservableObject {
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    private let settingsManager: SettingsManager
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
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
            let response = try await callOpenAI(
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
    
    // MARK: - Private Methods
    
    private func buildUserPrompt(transcript: String, customPrompt: String?) -> String {
        var prompt = "Please clean up and improve this transcribed message: \"\(transcript)\""
        
        if let customPrompt = customPrompt, !customPrompt.isEmpty {
            prompt += "\n\nAdditional instructions: \(customPrompt)"
        }
        
        return prompt
    }
    
    private func callOpenAI(systemPrompt: String, userPrompt: String) async throws -> String {
        let apiKey = settingsManager.getCurrentAPIKey()
        
        guard !apiKey.isEmpty else {
            throw MessageFormatterError.noAPIKey
        }
        
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
            throw MessageFormatterError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw MessageFormatterError.invalidRequest
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MessageFormatterError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw MessageFormatterError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let choices = json?["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw MessageFormatterError.invalidResponse
            }
            
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw MessageFormatterError.invalidResponse
        }
    }
}

// MARK: - Errors

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