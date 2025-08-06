import Foundation
import Security

class APIConfig {
    static let shared = APIConfig()
    
    // D3APIProxy Configuration
    private let proxyBaseURL = "https://d3apiproxy-1097426221643.us-east1.run.app"
    private let chatEndpoint = "/chat"
    private let requestTimeout: TimeInterval = 10.0
    
    // Keychain Configuration
    private let keychainService = "com.vibetext.apitoken"
    private let keychainAccount = "d3apiproxy_token"
    
    private init() {}
    
    var chatURL: URL {
        return URL(string: proxyBaseURL + chatEndpoint)!
    }
    
    var timeout: TimeInterval {
        return requestTimeout
    }
    
    // MARK: - Token Management
    
    func storeAuthToken(_ token: String) -> Bool {
        let tokenData = token.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: tokenData
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func getAuthToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let tokenData = result as? Data,
              let token = String(data: tokenData, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    func removeAuthToken() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}