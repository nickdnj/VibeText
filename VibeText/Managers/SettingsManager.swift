import Foundation
import Security

/// Manages app settings and secure storage of API keys
class SettingsManager: ObservableObject {
    @Published var openAIAPIKey: String = ""
    @Published var lastUsedTone: MessageTone = .casual
    @Published var isUsingDefaultKey: Bool = true
    
    private let keychainService = "com.d3marco.VibeText"
    // App Groups disabled for now - using standard approach
    // private let keychainAccessGroup = "group.com.d3marco.VibeText.shared"
    // private let sharedUserDefaults = UserDefaults(suiteName: "group.com.d3marco.VibeText.shared")
    private let apiKeyKey = "OpenAIAPIKey"
    private let lastToneKey = "LastUsedTone"
    private let defaultAPIKey = "sk-your-default-key-here" // Replace with actual default key
    
    init() {
        loadSettings()
    }
    
    // MARK: - API Key Management
    
    func saveAPIKey(_ key: String) {
        print("SettingsManager.saveAPIKey called with key: '\(key)'")
        openAIAPIKey = key
        // Only treat as default if the key is actually empty
        isUsingDefaultKey = key.isEmpty
        print("isUsingDefaultKey set to: \(isUsingDefaultKey)")
        
        if key.isEmpty {
            print("Key is empty, deleting from keychain")
            deleteAPIKeyFromKeychain()
        } else {
            print("Saving key to keychain")
            saveAPIKeyToKeychain(key)
        }
    }
    
    func getCurrentAPIKey() -> String {
        return openAIAPIKey.isEmpty ? defaultAPIKey : openAIAPIKey
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
        // Load API key from keychain
        openAIAPIKey = loadAPIKeyFromKeychain()
        // Only treat as default if the key is actually empty
        isUsingDefaultKey = openAIAPIKey.isEmpty
        
        // Load last used tone
        if let toneString = UserDefaults.standard.string(forKey: lastToneKey),
           let tone = MessageTone(rawValue: toneString) {
            lastUsedTone = tone
        }
    }
    
    // MARK: - Keychain Operations
    
    private func saveAPIKeyToKeychain(_ key: String) {
        print("🔑 Main App: Saving API key to standard keychain...")
        
        // Standard keychain save (no App Groups for now)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: apiKeyKey,
            kSecValueData as String: key.data(using: .utf8)!
        ]
        
        print("🔑 Main App: Using standard keychain storage")
        // Delete existing key first
        SecItemDelete(query as CFDictionary)
        
        // Add new key
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("❌ Main App: Failed to save API key to keychain: \(status)")
        } else {
            print("✅ Main App: Successfully saved API key to keychain")
        }
    }
    
    private func loadAPIKeyFromKeychain() -> String {
        print("🔑 Main App: Loading API key from standard keychain...")
        
        // Standard keychain load (no App Groups for now)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: apiKeyKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        print("🔑 Main App: Querying standard keychain...")
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let key = String(data: data, encoding: .utf8) {
            print("✅ Main App: Successfully loaded API key from keychain (length: \(key.count))")
            return key
        }
        
        print("❌ Main App: Failed to load API key from keychain (status: \(status))")
        return ""
    }
    
    private func deleteAPIKeyFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: apiKeyKey
        ]
        
        print("🔑 Main App: Deleting API key from standard keychain")
        let status = SecItemDelete(query as CFDictionary)
        print("🔑 Main App: Delete status: \(status)")
    }
} 