# VibeText Implementation Plan

## Phase 1: Core Voice-to-Text Flow
1. **Voice Capture**
   - Implement mic button UI and recording logic (AVFoundation).
   - Show live waveform during recording.
   - Pause/resume/cancel controls.
2. **Transcription**
   - Integrate Apple Speech framework for on-device transcription.
   - Display transcript in a scrollable, editable view.
3. **Transcript Review**
   - Allow inline editing and cleanup of transcript.
   - “Ready for Tone” button to proceed.

## Phase 2: Tone Transformation & AI Integration
4. **Tone Selection**
   - UI for selecting tone presets (Gen Z, Professional, Friendly, etc.).
   - Call OpenAI/Claude API to transform transcript based on selected tone.
   - Show preview of message in selected tone.
5. **AI Chat Refinement**
   - Chat interface for iterative message editing with AI.
   - “Accept,” “Undo,” and “Reset” controls.

## Phase 3: Output & Session Management
6. **Export Options**
   - Copy to clipboard.
   - Share sheet integration (iMessage, Mail, WhatsApp, etc.).
   - Save to local history with tags.
7. **Session History**
   - List of past messages with search, tag, and favorite options.
   - Tap-and-hold for edit/delete/tag.

## Phase 4: Settings & Privacy
8. **Settings Panel**
   - API key input and validation (Keychain).
   - Toggle for online features.
   - Manage tone presets.
   - Privacy controls (clear history, delete all data).
   - Theme toggle (Light/Dark).

## Phase 5: Polish & QA
9. **UI/UX Polish**
   - Color scheme, haptics, accessibility.
   - Animations and transitions.
10. **Testing**
    - Unit and integration tests.
    - Manual QA and bug fixes.

---

## Implementation Checklist

| #  | Task Description                                      | Status     |
|----|-------------------------------------------------------|------------|
| 1  | Voice capture UI and recording logic                  | ⬜ Pending |
| 2  | Live waveform during recording                        | ⬜ Pending |
| 3  | Pause/resume/cancel controls                          | ⬜ Pending |
| 4  | On-device transcription integration                   | ⬜ Pending |
| 5  | Transcript review and editing                         | ⬜ Pending |
| 6  | “Ready for Tone” flow                                 | ⬜ Pending |
| 7  | Tone selection UI and API integration                 | ⬜ Pending |
| 8  | Tone preview display                                  | ⬜ Pending |
| 9  | AI chat refinement interface                          | ⬜ Pending |
| 10 | Accept/Undo/Reset logic                               | ⬜ Pending |
| 11 | Export: copy/share/save                               | ⬜ Pending |
| 12 | Session history management                            | ⬜ Pending |
| 13 | Settings panel (API key, privacy, theme, etc.)        | ⬜ Pending |
| 14 | UI/UX polish (colors, haptics, accessibility)         | ⬜ Pending |
| 15 | Testing and QA                                        | ⬜ Pending |

---

_This plan will be updated as development progresses. Refer to this file for the current status and next steps._ 