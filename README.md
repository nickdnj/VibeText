# VibeText 🎙️✨

**VibeText** is a voice-first iOS app that transforms your spoken thoughts into perfectly crafted messages, tailored for any audience or tone. Whether you're texting your Gen Z nephew, replying to a professional email, or sending a heartfelt note, VibeText helps you say exactly what you mean — in the right voice.

## 🚀 Features

- **🎙️ Voice Capture**: Tap-to-record with live waveform and on-device transcription using Apple's Speech framework
- **✨ AI-Powered Cleanup**: Transform rambling thoughts into clear, polished messages
- **🎭 Tone Transformation**: Instantly reframe your message with 14 AI-powered tone presets:
  - 🎓 Professional • 👴 Boomer • 😎 Gen X • 👶 Gen Z • 🎉 Casual
  - 🧠 Millennial • 🇺🇸 Trump • 🎩 Shakespearean • 📱 Corporate Speak
  - 🧊 Dry/Sarcastic • 🎮 Gamer Mode • 💘 Romantic • 🧘 Zen • 🤖 Robot/AI Literal
- **💬 Smart Refinement**: Chat with AI to further adjust your message ("shorter," "add warmth," "make more casual," etc.)
- **📱 iMessage Integration**: Seamless integration as an iMessage app extension
- **🔒 Privacy-First**: All voice processing is local by default; online AI features are opt-in
- **⚙️ Secure Settings**: Manage your OpenAI API key securely with Keychain storage

## 🛠️ Architecture

- **Swift & SwiftUI** for a modern, responsive iOS experience
- **Apple Speech Framework** for on-device transcription
- **OpenAI GPT-4o** for tone transformation and AI chat (optional, via secure API)
- **MVVM Pattern** with SwiftUI for clean, maintainable code
- **Keychain Storage** for secure API key management
- **Local Storage** using UserDefaults for settings and history

## 📱 Getting Started

### Prerequisites

- Xcode 15.0+ (latest version recommended)
- iOS 17.0+ deployment target
- OpenAI API key (optional, for AI features)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/nickdnj/VibeText.git
   cd VibeText
   ```

2. **Open in Xcode:**
   - Open `VibeText.xcodeproj` in Xcode
   - Select your target device or simulator

3. **Configure API (Optional):**
   - Enter your OpenAI API key in the app's Settings panel to enable AI-powered features
   - For testing, the app includes a default API key

4. **Build and Run:**
   - Select your target device/simulator
   - Press `Cmd+R` to build and run

## 🎨 User Experience Flow

### 1. Voice Capture
- Tap the microphone button in the iMessage app drawer
- Speak your message naturally
- On-device transcription begins immediately

### 2. Message Review & Tone Selection
- Review the AI-cleaned transcript
- Choose from tone presets (Professional, Gen Z, Boomer, etc.)
- Edit manually if needed

### 3. Optional Refinement
- Add custom instructions ("make it more excited", "add that we're bringing snacks")
- Regenerate with new guidance

### 4. Insert & Send
- Preview the final message
- Tap to insert directly into iMessage
- Send with confidence!

## 🏗️ Project Structure

```
VibeText/
├── VibeText/                    # Main iOS app
│   ├── VibeTextApp.swift       # App entry point
│   ├── ContentView.swift       # Main content view
│   ├── Managers/               # Core business logic
│   │   ├── SpeechManager.swift # Voice capture & transcription (600+ lines)
│   │   ├── MessageFormatter.swift # OpenAI integration & tone transformation
│   │   └── SettingsManager.swift # Keychain storage & API key management
│   ├── Models/                 # Data models
│   │   └── Message.swift       # Message & 14-tone system definitions
│   ├── ViewModels/             # MVVM layer
│   │   └── VoiceCaptureViewModel.swift # Main app business logic
│   ├── Views/                  # SwiftUI views
│   │   ├── MessageReviewView.swift # Message editing & tone selection
│   │   └── SettingsView.swift  # Settings configuration
│   └── Assets.xcassets/        # App assets
├── VibeText-imessage/          # iMessage app extension
│   ├── VibeTextMessageView.swift # Extension UI (streamlined)
│   ├── SharedManagers.swift   # Duplicated managers for extension isolation
│   ├── MessagesViewController.swift # iMessage integration controller
│   └── Secrets.plist          # Default API key (gitignored)
├── VibeText.xcodeproj/         # Xcode project
├── docs/                       # Documentation & legal pages
│   ├── 🎨 VibeText UX Design Overview.md
│   ├── Product Requirements Document_ VibeText.md
│   ├── Software Architecture Specification_ VibeText.md
│   ├── privacy-policy.html     # App Store compliance
│   ├── terms-of-use.html       # Legal terms
│   └── index.html              # GitHub Pages legal landing
├── build_and_test.sh          # Automated build & deployment script
├── VibeText_TestLoop.md       # Comprehensive testing procedures
└── README.md                  # This file
```

## 🔧 Technical Implementation

### Dual-App Architecture

**Main App Features:**
- Full voice recording interface with waveform visualization
- Message review with 14 tone presets and real-time switching
- Settings management with Keychain storage and Secrets.plist fallback
- Comprehensive audio session conflict resolution
- Stand-alone functionality for development and power users

**iMessage Extension Features:**
- Streamlined voice-to-message interface optimized for iMessage drawer
- Direct message insertion into iMessage composer via `MSConversation.insertText`
- Shared codebase via duplicated `SharedManagers.swift` for extension isolation
- Compact UI optimized for quick workflow

### Core Components

- **SpeechManager**: 600+ lines handling complex audio session management, file recording, format conversion, and robust transcription with interruption recovery
- **MessageFormatter**: OpenAI API integration with dual processing modes:
  - **Transcript Cleanup**: Stream-of-consciousness → structured message
  - **Tone Transformation**: Preserves user edits while applying new tone
- **SettingsManager**: Keychain-based API key storage with automatic fallback to embedded default key via Secrets.plist
- **VoiceCaptureViewModel**: Main app business logic with automatic transcript processing
- **MessageExtensionViewModel**: iMessage extension-specific workflow management

### Advanced Audio Session Management

```swift
// Sophisticated audio session handling
- Dual configuration strategy (primary + fallback)
- Real-time route change monitoring  
- TextEditor conflict resolution
- Format standardization (16kHz mono)
- Screen sleep prevention during recording
- 5-minute auto-stop with duration tracking
```

### OpenAI Integration Architecture

```swift
// Dual-mode AI processing
let endpoint = "https://api.openai.com/v1/chat/completions"
let model = "gpt-4o"

// Mode 1: Initial transcript cleanup
systemPrompt: "Clean up stream-of-consciousness transcript..."

// Mode 2: Tone transformation (preserves edits)
systemPrompt: tone.systemPrompt // 14 sophisticated tone definitions
userPrompt: "Transform this message: \(editedText)"
```

### Security & Configuration

- **API Keys**: Secure Keychain storage with Secrets.plist fallback system
- **Voice Processing**: 100% on-device via Apple Speech Framework
- **Extension Isolation**: Duplicated managers prevent main app dependencies
- **Build Automation**: `build_and_test.sh` with device-specific deployment
- **Testing**: Comprehensive `VibeText_TestLoop.md` procedures

## 📚 Documentation

See the `docs/` directory for detailed specifications:

- **[🎨 UX Design Overview](docs/🎨%20VibeText%20UX%20Design%20Overview.md)**: Complete user experience flow and design principles
- **[Product Requirements Document](docs/Product%20Requirements%20Document_%20VibeText.md)**: Functional requirements and user stories  
- **[Software Architecture Specification](docs/Software%20Architecture%20Specification_%20VibeText.md)**: Technical architecture and implementation details

### Development Documentation

- **[`build_and_test.sh`](build_and_test.sh)**: Automated build, deployment, and testing workflow
- **[`VibeText_TestLoop.md`](VibeText_TestLoop.md)**: Comprehensive testing procedures and checklists
- **[Legal Documentation](docs/)**: App Store compliance with privacy policy and terms

### Missing Documentation (Needed)

The following documentation should be created to fully document the implementation:

- **Audio Session Architecture Guide**: 600+ lines of sophisticated audio session management
- **Extension Code Duplication Strategy**: Why SharedManagers.swift vs App Groups
- **API Key Management System**: Secrets.plist + Keychain implementation details
- **TestFlight Distribution Guide**: Preparation and submission procedures
- **Developer Onboarding Guide**: Setup, build, and contribution workflow

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes** and add tests if applicable
4. **Commit your changes**: `git commit -m 'Add amazing feature'`
5. **Push to the branch**: `git push origin feature/amazing-feature`
6. **Open a Pull Request**

### Development Guidelines

- Follow Swift style guidelines
- Add comments for complex logic
- Test on both simulator and device
- Update documentation for new features

## 🚀 Implementation Status & Roadmap

### Current Status
- ✅ Complete iOS app structure with full UI
- ✅ Voice capture with waveform visualization 
- ✅ On-device speech transcription with robust audio session management
- ✅ OpenAI GPT-4o integration with dual processing modes
- ✅ 14-tone transformation system (Professional, Gen Z, Millennial, Trump, etc.)
- ✅ Message review and editing interface with real-time tone switching
- ✅ Settings panel with secure Keychain API key management
- ✅ iMessage app extension with streamlined workflow
- ✅ Dual-app architecture (Main app + iMessage extension)
- ✅ Build automation and comprehensive testing procedures
- 🔄 TestFlight distribution (planned)

### Advanced Features Implemented
- [x] Sophisticated audio session conflict resolution
- [x] TextEditor integration without recording interruption
- [x] Custom prompt refinement system
- [x] Message tone transformation preserving user edits
- [x] Automated build and deployment scripts
- [x] 5-minute recording limits with auto-stop
- [x] Default API key fallback via Secrets.plist
- [x] Comprehensive interruption handling (calls, route changes)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👋 About

VibeText is built with ❤️ by [@nickdnj](https://github.com/nickdnj) and is inspired by the need for clear, tone-aware communication in a fast-paced, multi-generational world.

---

**Ready to vibe up your messages? Start with VibeText!** 🎉

## Support

- 📧 Email: [your-email@example.com]
- 🐛 Issues: [GitHub Issues](https://github.com/nickdnj/VibeText/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/nickdnj/VibeText/discussions) 