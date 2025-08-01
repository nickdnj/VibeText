## **Product Requirements Document: VibeText**

### **1\. Elevator Pitch**

VibeText is an iPhone app extension for iMessage that helps users effortlessly create clear, well-structured, and audience-tailored text messages. By capturing natural, stream-of-consciousness voice input, VibeText transcribes the speech, uses AI to clean up the message, and allows the user to reformat the tone to suit different recipients (e.g., Gen Z, Boomer, Professional). The app enhances communication clarity while preserving the user's intent and voice.

---

### **2\. Who is this app for**

* iPhone users who prefer speaking over typing

* Professionals who want to improve tone and clarity in messaging

* Older adults who want help composing texts for younger family members

* Anyone seeking to send polished and persona-aware messages effortlessly

---

### **3\. Functional Requirements**

* **Voice Input Capture**: Record and transcribe spoken messages on-device using Apple's Speech framework.

* **AI-Powered Text Cleanup**: Send transcription to OpenAI's GPT-4o to generate a clear and polished version of the message.

* **Tone Transformation Options**: Present tone presets (e.g., Professional, Gen Z, Boomer) to rephrase messages via OpenAI.

* **Custom Prompt Refinement**: Allow user-entered instructions (e.g., "Add more excitement", "Mention we’ll bring cookies") to further guide message generation.

* **iMessage App Extension**: Invoke VibeText from within iMessage, return the finalized message into the text field for easy sending.

* **Offline-first Transcription**: Ensure voice transcription works on-device without requiring internet connectivity.

* **Privacy-aware Design**: All voice processing is local; only text is sent to the AI backend.

* **Settings Panel**: Include an in-app settings pane where users can securely enter and manage their OpenAI API key, required for AI cleanup and tone transformation features.

* **Default API Key Fallback (MVP Testing)**: For early testing builds, the app should include a built-in OpenAI API key that is used by default unless the user overrides it via the settings panel. This is to simplify testing and feedback collection while preserving optional configurability.

* **Dual-App Architecture**: Complete main app and streamlined iMessage extension serving different use cases with shared business logic.

* **Extended Tone System**: 14 sophisticated tone presets (beyond original 5) including Millennial, Trump, Shakespearean, Corporate Speak, Dry/Sarcastic, Gamer Mode, Romantic, Zen, and Robot/AI Literal.

* **Advanced Audio Session Management**: Robust handling of interruptions, route changes, TextEditor conflicts, format standardization, and 5-minute auto-stop limits.

* **Dual AI Processing Modes**: Transcript cleanup for initial processing and tone transformation that preserves user edits.

* **Build & Test Automation**: Comprehensive build scripts and test procedures for reliable development workflow.

---

### **4\. User Stories**

* *As a user*, I want to dictate my message so I don’t have to type.

* *As a user*, I want the app to clean up my babbled speech into a clear message.

* *As a user*, I want to select a tone (e.g., Gen Z) that matches my recipient.

* *As a user*, I want to optionally refine the AI’s suggestion with extra instructions.

* *As a user*, I want to send the final message right from the iMessage conversation.

* *As a user*, I want to manage my OpenAI API key in the app’s settings to enable AI-powered features.

---

### **5\. User Interface**

* **Launch Point**: iMessage app drawer icon to open VibeText interface.

* **Voice Capture Screen**: A large microphone button, waveform animation, and cancel/send controls.

* **Transcription \+ AI Output View**:

  * Display original transcription (optional toggle).

  * Show cleaned-up message with edit and regenerate buttons.

* **Tone Selection Menu**: Horizontal scroll or segmented control with tone styles.

* **Custom Prompt Field**: Optional text box for extra instructions.

* **Send Button**: Final message inserted into iMessage composer with one tap.

* **Settings Pane**: Accessible from the main app or via iOS Settings, with a secure field for entering the OpenAI API key.

---

### **Next Steps**

* Define technical architecture and API scaffolding

* Build SwiftUI-based iMessage extension

* Implement local speech transcription

* Connect to OpenAI API for text processing

* Define tone transformation prompt templates

* Create secure settings UI for OpenAI API key entry

---

*Created by Nick and ChatGPT – July 2025*

