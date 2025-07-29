## **🎨 VibeText UX Design Overview**

### **💬 Entry Point: iMessage App Drawer**

* User taps the **VibeText icon** inside a message thread.

* A minimal panel slides up, not taking over the whole screen.

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

* **Tone Selector** (horizontal pill buttons):

  * 🎓 Professional

  * 👴 Boomer

  * 😎 Gen X

  * 👶 Gen Z

  * 🎉 Casual

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

## **4\. 📤 Insert into iMessage**

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

* **Private**: Speech is processed on-device.

* **Fast**: Output appears in seconds.

* **Fun**: Tone shift adds personality.

* **Familiar**: iMessage style—blends right in.

