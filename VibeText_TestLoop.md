# VibeText Development Test Loop

## 🎯 Quick Start Checklist

### Before Testing:
- [ ] iPhone 16 is connected via USB
- [ ] Device is unlocked and trusted
- [ ] Xcode is open with VibeText project
- [ ] Latest changes are saved

### Build & Deploy Commands:
```bash
# Build for iPhone
xcodebuild -scheme VibeText -destination "platform=iOS,id=00008140-000A24EC3C90801C" -configuration Debug build

# Install on device
xcrun devicectl device install app --device 00008140-000A24EC3C90801C /Users/nickd/Library/Developer/Xcode/DerivedData/VibeText-dcdywwtrrkccicbdrrneuvfblqmi/Build/Products/Debug-iphoneos/VibeText.app
```

## 📋 Test Scenarios

### 1. Core Recording Functionality
**Test Steps:**
1. Open VibeText app
2. Tap "Start Recording" button
3. Speak for 10-15 seconds
4. Tap "Stop Recording" button
5. Review the transcript

**Expected Results:**
- ✅ Recording starts immediately
- ✅ Live transcript appears while speaking
- ✅ Timer shows MM:SS format
- ✅ Recording stops cleanly
- ✅ Final transcript is accurate

**Common Issues:**
- ❌ Audio session error (-50)
- ❌ No live transcript
- ❌ Recording stops prematurely
- ❌ Poor transcription quality

### 2. Audio Session Stability
**Test Steps:**
1. Start recording
2. While recording, edit text in review screen
3. Continue recording after editing
4. Test with keyboard active

**Expected Results:**
- ✅ Recording continues after TextEditor interaction
- ✅ No audio session conflicts
- ✅ Smooth transition between UI states

**Common Issues:**
- ❌ Recording stops when TextEditor becomes active
- ❌ Audio session configuration errors
- ❌ Interference from keyboard input

### 3. Message Editing Feature
**Test Steps:**
1. Complete a recording
2. In review screen, edit the AI-generated text
3. Test copy functionality
4. Test with long messages

**Expected Results:**
- ✅ TextEditor is fully editable
- ✅ Cursor positioning works correctly
- ✅ Copy button uses edited text
- ✅ Long text scrolls properly

**Common Issues:**
- ❌ TextEditor not editable
- ❌ Copy button uses original text
- ❌ UI layout issues with long text

### 4. Interruption Handling
**Test Steps:**
1. Start recording
2. Receive a phone call (or simulate)
3. Return to app after call
4. Try recording again

**Expected Results:**
- ✅ Recording stops gracefully during interruption
- ✅ App recovers properly after interruption
- ✅ New recording works after interruption

**Common Issues:**
- ❌ App crashes during interruption
- ❌ Recording doesn't stop during call
- ❌ Can't record after interruption

### 5. Duration Limits
**Test Steps:**
1. Start recording
2. Let it run for 4+ minutes
3. Observe timer behavior

**Expected Results:**
- ✅ Timer shows MM:SS format
- ✅ Timer turns orange at 4 minutes
- ✅ Auto-stops at 5 minutes
- ✅ Clear warning before auto-stop

**Common Issues:**
- ❌ Timer doesn't update
- ❌ No visual warning
- ❌ Doesn't auto-stop

### 6. Offline Mode Error Handling
**Test Steps:**
1. Enable airplane mode or disconnect from internet
2. Start recording and complete a message
3. Try to process the transcript
4. Observe error handling behavior
5. Reconnect to internet and retry

**Expected Results:**
- ✅ App shows user-friendly error message
- ✅ No crashes occur during offline mode
- ✅ Retry button appears for network errors
- ✅ App remains fully functional after error dismissal
- ✅ Processing works correctly after reconnecting

**Common Issues:**
- ❌ App crashes during offline mode
- ❌ Force unwrap errors in error handling
- ❌ No retry option for network errors
- ❌ App becomes unusable after error

### 7. Error Recovery & Retry
**Test Steps:**
1. Trigger a network error (offline mode)
2. Tap "Retry" button
3. Verify app recovers properly
4. Test with different error types

**Expected Results:**
- ✅ Retry functionality works for retryable errors
- ✅ App state is properly reset after error
- ✅ Non-retryable errors show appropriate messaging
- ✅ Error dismissal returns to normal operation

## 🔄 Test Loop Template

### Step 1: Pre-Test Setup
```
📱 DEVICE CHECK:
- iPhone 16 connected: [YES/NO]
- Device unlocked: [YES/NO]
- App installed: [YES/NO]
```

### Step 2: Build & Deploy
```bash
# Run these commands:
xcodebuild -scheme VibeText -destination "platform=iOS,id=00008140-000A24EC3C90801C" -configuration Debug build
xcrun devicectl device install app --device 00008140-000A24EC3C90801C /Users/nickd/Library/Developer/Xcode/DerivedData/VibeText-dcdywwtrrkccicbdrrneuvfblqmi/Build/Products/Debug-iphoneos/VibeText.app
```

### Step 3: Test Execution
```
🧪 TESTING:
- Test Scenario: [Which scenario above]
- Changes Made: [Brief description of recent changes]
- Expected Result: [What should happen]
- Actual Result: [What actually happened]
```

### Step 4: Issue Documentation
```
🐛 ISSUES FOUND:
- Issue 1: [Description]
- Issue 2: [Description]
- Priority: [High/Medium/Low]
```

### Step 5: Next Steps
```
📋 NEXT ACTIONS:
- Fix 1: [Specific fix needed]
- Fix 2: [Specific fix needed]
- Re-test: [What to test after fixes]
```

## 🚨 Common Error Patterns

### Audio Session Errors:
- **Error -50**: Audio session configuration conflict
- **Error -108**: Audio session not available
- **Error -561015905**: Audio session interrupted

### UI Issues:
- **TextEditor not editable**: Check @State binding
- **Copy not working**: Check text binding in VoiceCaptureViewModel
- **Layout issues**: Check VStack/ScrollView constraints

### Recording Issues:
- **No live transcript**: Check SFSpeechRecognizer setup
- **Premature stop**: Check audio session lifecycle
- **Poor quality**: Check microphone permissions

## 📝 Test Log Template

```
=== VIBETEXT TEST LOG ===
Date: [Date]
Build: [Build number/commit]
Device: iPhone 16 Pro

CHANGES MADE:
- [List recent changes]

TESTS PERFORMED:
1. [Test name] - [PASS/FAIL]
2. [Test name] - [PASS/FAIL]
3. [Test name] - [PASS/FAIL]

ISSUES FOUND:
- [Issue description with steps to reproduce]

NEXT FIXES:
- [Specific fixes needed]

NOTES:
- [Any additional observations]
```

## 🎯 Quick Commands for Cursor

### Build Commands:
```bash
# Quick build
xcodebuild -scheme VibeText -destination "platform=iOS,id=00008140-000A24EC3C90801C" -configuration Debug build

# Quick install
xcrun devicectl device install app --device 00008140-000A24EC3C90801C /Users/nickd/Library/Developer/Xcode/DerivedData/VibeText-dcdywwtrrkccicbdrrneuvfblqmi/Build/Products/Debug-iphoneos/VibeText.app

# Build and install in one command
xcodebuild -scheme VibeText -destination "platform=iOS,id=00008140-000A24EC3C90801C" -configuration Debug build && xcrun devicectl device install app --device 00008140-000A24EC3C90801C /Users/nickd/Library/Developer/Xcode/DerivedData/VibeText-dcdywwtrrkccicbdrrneuvfblqmi/Build/Products/Debug-iphoneos/VibeText.app
```

### Device Commands:
```bash
# List devices
xcrun devicectl list devices

# Check device status
xcrun devicectl device info --device 00008140-000A24EC3C90801C
```

## 🔄 Repeatable Test Loop

1. **🔌 Device Check**: Ensure iPhone 16 is connected
2. **🔨 Build**: Run build command
3. **📱 Deploy**: Install on device
4. **🧪 Test**: Execute test scenarios
5. **📝 Log**: Document results and issues
6. **🔧 Fix**: Implement necessary fixes
7. **🔄 Repeat**: Go back to step 2

---

**Remember**: Always test on the actual device, not just the simulator, as audio session behavior can differ significantly between simulator and real device. 