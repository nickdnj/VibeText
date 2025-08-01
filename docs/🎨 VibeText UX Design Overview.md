## **🎨 VibeText UX Design Overview**

### **💬 Dual Entry Points**

**Main App Launch:**
* User opens VibeText app directly from home screen
* Full-featured interface for power users and development
* Complete settings management and comprehensive message editing

**iMessage App Drawer:**
* User taps the **VibeText icon** inside a message thread
* Streamlined panel optimized for quick voice-to-message workflow
* Direct message insertion into iMessage composer

---

## **1\. 🎙 Voice Capture Screen**

**Purpose**: Capture the user’s raw idea.

**UI Elements**:

* Large, centered **microphone button** with animation.

* “Tap to Speak” label.

* Optional **Cancel** and **Done** buttons.

* Subtle waveform while recording.

* Caption: “Speak your message idea naturally. We’ll clean it up for you.”

**Interaction**:

* User taps mic, speaks freely, taps again to stop.

* Transcription begins immediately on-device.

---

## **2\. ✨ Message Review \+ Tone Selection**

**Purpose**: Show AI’s cleaned-up message and allow tone changes.

**UI Elements**:

* Card-style view showing the **cleaned-up text**.

* “Here’s your message:” with AI output.

* **Tone Selector** (grid layout):

  * 🎓 Professional • 👴 Boomer • 😎 Gen X • 👶 Gen Z • 🎉 Casual

  * 🧠 Millennial • 🇺🇸 Trump • 🎩 Shakespearean • 📱 Corporate Speak

  * 🧊 Dry/Sarcastic • 🎮 Gamer Mode • 💘 Romantic • 🧘 Zen • 🤖 Robot/AI Literal

* **Regenerate** and **Edit** buttons.

* Button to “Add more guidance...” (goes to prompt screen).

**Interaction**:

* Tap tone to instantly regenerate output in that vibe.

* Edit opens a plain text editor for manual tweaks.

---

## **3\. 📝 Optional Prompt Input**

**Purpose**: Let user fine-tune the AI's output.

**UI Elements**:

* Text input field: “What else should we consider?”

* Examples shown: “Make it more excited”, “Add that we’re bringing snacks”

* **Apply & Regenerate** button.

**Interaction**:

* User types or pastes a refinement.

* Message is reprocessed with new instructions.

---

## **4\. 📤 Message Completion (Dual-App Support)**

**Purpose**: Final step before sending.

**UI Elements**:

* Final message preview.

* Button: **Insert into Message**

* “Looks good? We’ll drop it into your text.”

**Interaction**:

* Tapping inserts message into the iMessage compose box, ready to send.

* User stays in the iMessage thread the whole time — no switching apps.

---

## **5\. ⚙️ Settings Screen (accessible via iOS app)**

**Purpose**: Manage the OpenAI API key or switch to personal key.

**UI Elements**:

* OpenAI API Key field (secure text entry)

* Status indicator: Using default or user key

* Option to “Reset to default key”

* Optional toggle: “Remember last tone used”

---

## **✨ Design Principles**

* **Frictionless**: No need to type unless refining.

* **Private**: Speech is processed on-device with no storage.

* **Fast**: Output appears in seconds with dual AI processing modes.

* **Fun**: 14 diverse tone options add creative personality.

* **Familiar**: iMessage style—blends right in.

* **Robust**: Advanced audio session management handles interruptions and UI conflicts.

* **Flexible**: Dual-app architecture serves different use cases.

* **Intelligent**: Dual AI processing preserves user intent while enabling tone transformation.

* **Developer-Friendly**: Comprehensive build automation and test procedures.

