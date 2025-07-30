import Foundation

/// Represents a voice message and its various transformations
struct Message: Identifiable, Codable, Equatable {
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
    
    // MARK: - Equatable
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
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