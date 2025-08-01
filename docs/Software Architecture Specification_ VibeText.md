## **Software Architecture Specification: VibeText**

### **System Design**

* **App Type**: Dual iOS architecture - Main app + iMessage extension

* **Components**:

  * iOS Main App (Full featured interface, settings, development)

  * iMessage Extension (Streamlined voice-to-message workflow)

  * Shared Business Logic (Duplicated managers for extension isolation)

  * Voice-to-Text Transcriber (on-device, robust audio session handling)

  * AI Processing Layer (OpenAI integration with dual prompt strategies)

  * Tone Transformation System (14 preset tones with custom prompts)

  * Secure Settings Interface (Keychain + default API key fallback)

---

### **Architecture Pattern**

* **Client-Side Architecture**: MVVM (Model-View-ViewModel) with SwiftUI

* **Backend Integration**: Stateless API calls to OpenAI’s GPT-4o endpoints

* **Modularization**:

  * `SpeechManager` for voice capture, audio session management & transcription

  * `MessageFormatter` for OpenAI API interaction AND tone transformation

  * `SettingsManager` for storing and retrieving the OpenAI API key

  * `VoiceCaptureViewModel` for main app business logic

  * `MessageExtensionViewModel` for iMessage extension logic

---

### **State Management**

* **Framework**: SwiftUI @StateObject / @ObservedObject

* **Global State**: App-wide `EnvironmentObject` for shared settings (e.g., current API key)

* **View Model**: Each view (e.g., recorder, review, settings) has a dedicated ViewModel

---

### **Data Flow**

**Main App Flow:**
1. User initiates recording in main app interface
2. `SpeechManager` performs robust on-device transcription with audio session handling
3. Transcript auto-triggers `MessageFormatter` processing with cleanup prompts
4. AI cleanup produces initial message with selected tone
5. User reviews in `MessageReviewView` with full editing capabilities
6. Optional tone changes trigger `transformMessageWithTone` (preserves edits)
7. Final message copied to clipboard or shared

**iMessage Extension Flow:**
1. User opens VibeText from iMessage app drawer
2. Streamlined recording interface with `SharedManagers`
3. Direct tone selection and message review in compact UI
4. Message inserted directly into iMessage composer via `MSConversation.insertText`
5. User sends from iMessage normally

---

### **Technical Stack**

* **Language**: Swift

* **UI Framework**: SwiftUI

* **Speech API**: Apple Speech Framework (`SFSpeechRecognizer`)

* **Networking**: URLSession (for OpenAI API calls)

* **Secure Storage**: Keychain for API key storage

* **Settings**: UserDefaults for non-sensitive settings

---

### **Authentication Process**

* **OpenAI API Key Management**:

  * Default API key embedded for MVP testing

  * User override via settings pane

  * API key stored securely using Keychain

* **No user accounts or backend auth required**

---

### **Route Design**

**Main App Navigation:**
- `/` – ContentView with voice capture interface
- `/settings` – SettingsView for API key and configuration  
- `/review` – MessageReviewView (modal) for message editing and tone selection

**iMessage Extension Navigation:**
- `/extension` – VibeTextMessageView entry point
- Embedded tone selection and message editing
- Direct integration with iMessage composer

---

### **API Design**

* **Endpoint**: `https://api.openai.com/v1/chat/completions`

* **Headers**: `Authorization: Bearer <user_or_default_api_key>`

* **Model**: `gpt-4o`

* **Dual Processing Modes**:

**Mode 1: Transcript Cleanup**
```json
{
  "model": "gpt-4o",
  "messages": [
    {"role": "system", "content": "You are an assistant that reformats text messages."},
    {"role": "user", "content": "Clean up this transcript: <raw_transcript>"}
  ],
  "max_tokens": 500,
  "temperature": 0.7
}
```

**Mode 2: Tone Transformation**
```json
{
  "model": "gpt-4o", 
  "messages": [
    {"role": "system", "content": "<tone_specific_system_prompt>"},
    {"role": "user", "content": "Transform this message: <edited_text>"}
  ],
  "max_tokens": 500,
  "temperature": 0.7
}
```

* **Response**: JSON with cleaned or tone-adapted text

* **Error Handling**: Keychain API key retrieval with Secrets.plist fallback

---

### **Database Design ERD**

* No full database in MVP; local persistence only

* **Local Schema** (UserDefaults & Keychain):

  * `user_api_key: String?` (Keychain)

  * `last_used_tone: String` (UserDefaults)

  * **Note**: No message history persistence in current implementation

  * All processing is ephemeral for privacy

---

### **Configuration Management**

* **Source Control**: Git (hosted on GitHub)

* **Repo Structure**:

  * `VibeText/` – Main iOS app source with full managers

  * `VibeText-imessage/` – iMessage extension with duplicated managers

  * `docs/` – Comprehensive documentation including legal pages

  * `build_and_test.sh` – Automated build, deploy, and test workflow

  * `VibeText_TestLoop.md` – Detailed testing procedures and checklists

* **Configuration Management**:

  * `Secrets.plist` for embedded default API keys (gitignored)

  * Keychain for secure user API key storage

  * No `.xcconfig` files - direct plist configuration

  * Automated device targeting via hardcoded device ID in build script

* **Development Workflow**:

  * Feature branches merged to `main` via pull requests

  * `build_and_test.sh` automates build and device deployment

  * Comprehensive test scenarios in `VibeText_TestLoop.md`

  * No CI/CD currently - manual testing with iPhone 16 target device

---

*Created by Nick and ChatGPT – July 2025*

