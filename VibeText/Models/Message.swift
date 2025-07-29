import Foundation

/// Represents a voice message and its various transformations
struct Message: Identifiable, Codable {
    let id = UUID()
    let originalTranscript: String
    var cleanedText: String
    var tone: MessageTone
    var customPrompt: String?
    let createdAt: Date
    
    init(originalTranscript: String, cleanedText: String = "", tone: MessageTone = .casual) {
        self.originalTranscript = originalTranscript
        self.cleanedText = cleanedText
        self.tone = tone
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
    
    var emoji: String {
        switch self {
        case .professional: return "🎓"
        case .boomer: return "👴"
        case .genX: return "😎"
        case .genZ: return "👶"
        case .casual: return "🎉"
        }
    }
    
    var displayName: String {
        return "\(emoji) \(rawValue)"
    }
    
    /// System prompt for OpenAI to apply this tone
    var systemPrompt: String {
        switch self {
        case .professional:
            return "You are a professional communication assistant. Transform the given text into clear, formal, and business-appropriate language. Use proper grammar, avoid slang, and maintain a respectful tone."
        case .boomer:
            return "You are helping someone communicate with older family members. Transform the text to be warm, respectful, and use language that older adults would appreciate. Avoid modern slang and abbreviations."
        case .genX:
            return "You are helping someone communicate with Gen X (born 1965-1980). Transform the text to be friendly but not overly casual, using language that resonates with this generation."
        case .genZ:
            return "You are helping someone communicate with Gen Z (born 1997-2012). Transform the text to be casual, use modern slang appropriately, emojis, and language that younger people would use naturally."
        case .casual:
            return "You are helping someone communicate in a friendly, casual tone. Transform the text to be warm and approachable while maintaining clarity and natural flow."
        }
    }
} 