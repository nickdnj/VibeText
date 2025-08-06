import Foundation

class ProxyNetworkService {
    static let shared = ProxyNetworkService()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.shared.timeout
        config.timeoutIntervalForResource = APIConfig.shared.timeout
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Chat Completions
    
    func sendChatCompletion(
        messages: [[String: String]], 
        model: String = "gpt-4o-mini",
        temperature: Double = 0.7,
        maxTokens: Int = 500,
        completion: @escaping (Result<ChatCompletionResponse, ProxyError>) -> Void
    ) {
        guard let authToken = APIConfig.shared.getAuthToken() else {
            completion(.failure(.authenticationFailed("No auth token found")))
            return
        }
        
        let requestBody = ChatCompletionRequest(
            messages: messages,
            model: model,
            temperature: temperature,
            maxTokens: maxTokens
        )
        
        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            completion(.failure(.invalidRequest("Failed to encode request")))
            return
        }
        
        var request = URLRequest(url: APIConfig.shared.chatURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        print("🌐 ProxyNetworkService: Making request to \(APIConfig.shared.chatURL.absoluteString)")
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.handleChatResponse(data: data, response: response, error: error, completion: completion)
            }
        }.resume()
    }
    
    private func handleChatResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        completion: @escaping (Result<ChatCompletionResponse, ProxyError>) -> Void
    ) {
        // Handle network errors
        if let error = error {
            print("❌ ProxyNetworkService: Network error: \(error.localizedDescription)")
            if (error as NSError).code == NSURLErrorTimedOut {
                completion(.failure(.timeout))
            } else {
                completion(.failure(.networkError(error.localizedDescription)))
            }
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ ProxyNetworkService: Invalid response type")
            completion(.failure(.invalidResponse("Invalid response type")))
            return
        }
        
        guard let data = data else {
            print("❌ ProxyNetworkService: No data received")
            completion(.failure(.invalidResponse("No data received")))
            return
        }
        
        print("🌐 ProxyNetworkService: Received response with status code: \(httpResponse.statusCode)")
        
        // Handle HTTP status codes
        switch httpResponse.statusCode {
        case 200:
            // Success - decode response
            do {
                let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
                print("✅ ProxyNetworkService: Successfully decoded chat response")
                completion(.success(chatResponse))
            } catch {
                print("❌ ProxyNetworkService: Decoding error: \(error.localizedDescription)")
                completion(.failure(.decodingError("Failed to decode response: \(error.localizedDescription)")))
            }
            
        case 401:
            print("❌ ProxyNetworkService: Authentication failed")
            completion(.failure(.authenticationFailed("Invalid or expired token")))
            
        case 400:
            // Try to decode error response
            if let errorResponse = try? JSONDecoder().decode(ProxyErrorResponse.self, from: data) {
                print("❌ ProxyNetworkService: Bad request: \(errorResponse.error)")
                completion(.failure(.badRequest(errorResponse.error)))
            } else {
                print("❌ ProxyNetworkService: Bad request (unknown error)")
                completion(.failure(.badRequest("Invalid request")))
            }
            
        case 429:
            print("❌ ProxyNetworkService: Rate limited")
            completion(.failure(.rateLimited("Rate limit exceeded")))
            
        case 500...599:
            print("❌ ProxyNetworkService: Server error (\(httpResponse.statusCode))")
            completion(.failure(.serverError("Server error (\(httpResponse.statusCode))")))
            
        default:
            print("❌ ProxyNetworkService: Unexpected status code: \(httpResponse.statusCode)")
            completion(.failure(.unknownError("Unexpected status code: \(httpResponse.statusCode)")))
        }
    }
}