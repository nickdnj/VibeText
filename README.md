# VibeText 🎙️✨

**VibeText** is a voice-first iOS app that transforms your spoken thoughts into perfectly crafted messages, tailored for any audience or tone. Whether you're texting your Gen Z nephew, replying to a professional email, or sending a heartfelt note, VibeText helps you say exactly what you mean — in the right voice.

## 🚀 Features

- **🎙️ Voice Capture**: Tap-to-record with live waveform and on-device transcription using Apple's Speech framework
- **✨ AI-Powered Cleanup**: Transform rambling thoughts into clear, polished messages
- **🎭 Tone Transformation**: Instantly reframe your message with AI-powered tone presets:
  - 🎓 Professional
  - 👴 Boomer  
  - 😎 Gen X
  - 👶 Gen Z
  - 🎉 Casual
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
│   └── Assets.xcassets/        # App assets
├── VibeText.xcodeproj/         # Xcode project
├── docs/                       # Documentation
│   ├── 🎨 VibeText UX Design Overview.md
│   ├── Product Requirements Document_ VibeText.md
│   └── Software Architecture Specification_ VibeText.md
└── README.md                   # This file
```

## 🔧 Technical Implementation

### Core Components

- **SpeechManager**: Handles voice capture and on-device transcription
- **MessageFormatter**: Manages OpenAI API interactions
- **ToneTransformer**: Applies tone presets to messages
- **SettingsManager**: Handles API key storage and retrieval

### API Integration

```swift
// OpenAI API Configuration
let endpoint = "https://api.openai.com/v1/chat/completions"
let model = "gpt-4o"
let headers = ["Authorization": "Bearer \(apiKey)"]
```

### Security

- API keys stored securely in iOS Keychain
- Voice processing happens on-device
- Optional online features with user consent

## 📚 Documentation

See the `docs/` directory for detailed specifications:

- **[🎨 UX Design Overview](docs/🎨%20VibeText%20UX%20Design%20Overview.md)**: Complete user experience flow and design principles
- **[Product Requirements Document](docs/Product%20Requirements%20Document_%20VibeText.md)**: Functional requirements and user stories
- **[Software Architecture Specification](docs/Software%20Architecture%20Specification_%20VibeText.md)**: Technical architecture and implementation details

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

## 🐛 Known Issues & Roadmap

### Current Status
- ✅ Basic iOS app structure
- ✅ Documentation complete
- 🔄 Voice capture implementation (in progress)
- 🔄 iMessage extension (planned)
- 🔄 OpenAI integration (planned)

### Upcoming Features
- [ ] Voice recording with waveform visualization
- [ ] On-device speech transcription
- [ ] iMessage app extension
- [ ] OpenAI API integration
- [ ] Tone preset system
- [ ] Settings panel with API key management
- [ ] Message history and favorites

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