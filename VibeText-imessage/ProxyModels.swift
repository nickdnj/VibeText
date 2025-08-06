import Foundation

// MARK: - Request Models

struct ChatCompletionRequest: Codable {
    let messages: [[String: String]]
    let model: String
    let temperature: Double
    let maxTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case messages, model, temperature
        case maxTokens = "max_tokens"
    }
}

// MARK: - Response Models

struct ChatCompletionResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [ChatChoice]
    let usage: TokenUsage
}

struct ChatChoice: Codable {
    let index: Int
    let message: ChatMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct TokenUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Error Models

struct ProxyErrorResponse: Codable {
    let error: String
}

enum ProxyError: Error, LocalizedError {
    case authenticationFailed(String)
    case invalidRequest(String)
    case invalidResponse(String)
    case networkError(String)
    case timeout
    case decodingError(String)
    case badRequest(String)
    case rateLimited(String)
    case serverError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .timeout:
            return "Request timed out. Please try again."
        case .decodingError(let message):
            return "Data decoding error: \(message)"
        case .badRequest(let message):
            return "Bad request: \(message)"
        case .rateLimited(let message):
            return "Rate limited: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}