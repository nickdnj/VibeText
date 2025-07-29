## **Software Architecture Specification: VibeText**

### **System Design**

* **App Type**: Native iOS app with iMessage extension

* **Components**:

  * iOS Main App (Settings & Permissions)

  * iMessage Extension UI (Main interaction point)

  * Voice-to-Text Transcriber (on-device)

  * AI Processing Layer (remote OpenAI integration)

  * Tone Selector and Prompt Modifier

  * Settings Interface with API Key Management

---

### **Architecture Pattern**

* **Client-Side Architecture**: MVVM (Model-View-ViewModel) with SwiftUI

* **Backend Integration**: Stateless API calls to OpenAI’s GPT-4o endpoints

* **Modularization**:

  * `SpeechManager` for voice capture & transcription

  * `MessageFormatter` for API interaction

  * `ToneTransformer` for tone style application

  * `SettingsManager` for storing and retrieving the OpenAI API key

---

### **State Management**

* **Framework**: SwiftUI @StateObject / @ObservedObject

* **Global State**: App-wide `EnvironmentObject` for shared settings (e.g., current API key)

* **View Model**: Each view (e.g., recorder, review, settings) has a dedicated ViewModel

---

### **Data Flow**

1. User initiates recording in iMessage extension

2. `SpeechManager` performs on-device transcription

3. Transcript is passed to `MessageFormatter` with API key from `SettingsManager`

4. Response from OpenAI includes cleaned-up base message

5. User selects tone \-\> triggers `ToneTransformer` to regenerate message

6. User optionally adds prompt instructions \-\> modified prompt sent again to OpenAI

7. Final message appears in UI \-\> user taps to insert into iMessage composer

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

* iOS app has the following logical views:

  * `/` – App launcher or Settings

  * `/settings` – API Key input and configuration

  * `/extension` – iMessage extension entry point

  * `/compose` – Voice-to-message interface

  * `/review` – View and edit AI message

---

### **API Design**

* **Endpoint**: `https://api.openai.com/v1/chat/completions`

* **Headers**: `Authorization: Bearer <user_or_default_api_key>`

* **Model**: `gpt-4o`

* **Request Body**:

```json
{
  "model": "gpt-4o",
  "messages": [
    {"role": "system", "content": "You are an assistant that reformats text messages."},
    {"role": "user", "content": "<transcript and optional prompt>"}
  ]
}
```

*   
  **Response**: JSON with cleaned or tone-adapted text

---

### **Database Design ERD**

* No full database in MVP; local persistence only

* **Local Schema** (UserDefaults & Keychain):

  * `user_api_key: String?`

  * `last_used_tone: String`

  * `recent_messages: [String]` (optional feature)

---

### **Configuration Management**

* **Source Control**: Git (hosted on GitHub)

* **Repo Structure**:

  * `MainApp/` – iOS app source

  * `MessageExtension/` – iMessage UI components

  * `Shared/` – Common utilities and models

  * `Config/` – `.xcconfig` files for managing keys and environment variables

* **Environment Handling**:

  * Use `.gitignore` to exclude sensitive files like `Secrets.plist`

  * Provide `Secrets.sample.plist` for contributors

* **Branching Strategy**: Feature branches merged to `main` via pull requests

* **CI/CD (Future)**: Optional integration with GitHub Actions for build and test workflows

---

*Created by Nick and ChatGPT – July 2025*

