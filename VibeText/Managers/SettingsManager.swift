import Foundation
import Security

/// Manages app settings and secure storage of API keys
class SettingsManager: ObservableObject {
    @Published var lastUsedTone: MessageTone = .casual
    @Published var defaultTone: MessageTone = .casual
    
    private let lastToneKey = "LastUsedTone"
    private let defaultToneKey = "DefaultTone"
    
    init() {
        loadSettings()
        // One-time cleanup of legacy BYOK keychain item
        cleanupLegacyAPIKey()
    }
    
    // MARK: - Tone Settings
    
    func saveLastUsedTone(_ tone: MessageTone) {
        lastUsedTone = tone
        UserDefaults.standard.set(tone.rawValue, forKey: lastToneKey)
    }
    
    func saveDefaultTone(_ tone: MessageTone) {
        defaultTone = tone
        UserDefaults.standard.set(tone.rawValue, forKey: defaultToneKey)
        print("🎵 SettingsManager: Saved default tone: \(tone.rawValue)")
    }
    
    // MARK: - Private Methods
    
    private func loadSettings() {
        print("🔧 Main App: Loading settings (BYOK removed)...")
        
        // Load last used tone
        if let toneString = UserDefaults.standard.string(forKey: lastToneKey),
           let tone = MessageTone(rawValue: toneString) {
            lastUsedTone = tone
        }
        
        // Load default tone
        if let defaultToneString = UserDefaults.standard.string(forKey: defaultToneKey),
           let tone = MessageTone(rawValue: defaultToneString) {
            defaultTone = tone
            print("🎵 Main App: Loaded default tone: \(tone.rawValue)")
        } else {
            // Set default to casual if not previously configured
            defaultTone = .casual
            saveDefaultTone(.casual)
            print("🎵 Main App: Initialized default tone to casual")
        }
    }
    
    private func cleanupLegacyAPIKey() {
        // Remove legacy Keychain item if present
        let keychainService = "com.d3marco.VibeText"
        let apiKeyKey = "OpenAIAPIKey"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: apiKeyKey
        ]
        SecItemDelete(query as CFDictionary)
    }
}