# VibeText

**VibeText** is a voice-first iOS app that transforms your spoken thoughts into perfectly crafted messages, tailored for any audience or tone. Whether you’re texting your Gen Z nephew, replying to a professional email, or sending a heartfelt note, VibeText helps you say exactly what you mean — in the right voice.

---

## 🚀 Features

- **Voice Capture:** Tap-to-record with live waveform and on-device transcription (Apple Speech framework).
- **Transcript Review:** Edit and clean up your transcript before processing.
- **Tone Transformation:** Instantly reframe your message with AI-powered tone presets (Gen Z, Professional, Friendly, and more).
- **AI Message Refinement:** Chat with AI to further adjust your message (“shorter,” “add warmth,” “make more casual,” etc.).
- **Easy Export:** Copy, share, or save your final message with one tap.
- **Session History:** Search, tag, and favorite past messages for quick access.
- **Privacy-First:** All processing is local by default; online AI features are opt-in and API keys are stored securely.

---

## 🛠️ Architecture

- **Swift & SwiftUI** for a modern, responsive iOS experience.
- **Apple Speech Framework** for on-device transcription.
- **OpenAI GPT-4o/Claude** for tone transformation and AI chat (optional, via secure API).
- **Local Storage** using Core Data or FileManager for history and settings.
- **Secure Keychain** for API key management.

See the [`docs/`](docs/) directory for:
- Product Requirements Document (PRD)
- Software Architecture Document (SAD)
- UX Design Document (UXD)

---

## 📱 Getting Started

1. **Clone the repo:**
   ```bash
   git clone https://github.com/nickdnj/VibeText.git
   cd VibeText
   ```

2. **Open in Xcode:**
   - Open `VibeText.xcodeproj` in Xcode (latest version recommended).

3. **Run the app:**
   - Select a simulator or your device and hit Run.

4. **Configure AI (optional):**
   - Enter your OpenAI/Anthropic API key in the app’s Settings panel to enable online tone transformation.

---

## 🤝 Contributing

Contributions are welcome! Please open issues or pull requests for features, bug fixes, or suggestions.

---

## 📄 License

[MIT License](LICENSE) (to be added)

---

## 👋 About

VibeText is built with ❤️ by [@nickdnj](https://github.com/nickdnj) and is inspired by the need for clear, tone-aware communication in a fast-paced, multi-generational world.

---

**Ready to vibe up your messages? Start with VibeText!** 