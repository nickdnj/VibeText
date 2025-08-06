# 📱 Manual Screenshot Scaling Guide

## 🎯 Your iPhone 16 vs Required Sizes

### Your Device:
- **iPhone 16**: 6.1" display, **1179×2556 pixels**

### Required App Store Sizes:
- **iPhone 6.7"**: 1290×2796 pixels (iPhone 15 Pro Max, 16 Pro)
- **iPhone 6.5"**: 1242×2688 pixels (iPhone 14 Pro Max, 15 Pro)

---

## 🔧 **EASIEST APPROACH: Use Simulators**

The fastest way is to use the simulators you already have installed:

### Step 1: Run the Automated Script
```bash
cd AppStoreAssets
./generate_screenshots.sh
```

Choose **Option 5** (Complete automated generation) - this will:
1. Launch iPhone 16 Pro simulator (6.7")
2. Build and install VibeText 
3. Let you take screenshots at the exact required resolution
4. Launch iPhone 15 Pro simulator (6.5") 
5. Repeat the process

### Screenshots to Take (5 key screens):
1. **Voice Capture** - Main screen with large microphone button
2. **Recording Active** - Show waveform/timer during recording
3. **Message Review** - AI-processed text display
4. **Tone Selection** - Grid showing all 14 tone options
5. **iMessage Integration** - VibeText icon in Messages app drawer

---

## 🖼️ **ALTERNATIVE: Scale Your iPhone 16 Screenshots**

If you prefer using your physical device:

### Step 1: Take Screenshots on iPhone 16
```bash
# Build and install on your device
./build_and_test.sh

# Then take 5 screenshots on your phone
# AirDrop them to your Mac
```

### Step 2: Scale Using Built-in Tools

#### Using Preview (macOS):
1. Open screenshot in Preview
2. Tools → Adjust Size...
3. Set dimensions:
   - **For 6.7"**: Width: 1290, Height: 2796
   - **For 6.5"**: Width: 1242, Height: 2688
4. Save as new file

#### Using Command Line (sips):
```bash
# Create directories
mkdir -p Screenshots/iPhone-6.1-Source
mkdir -p Screenshots/iPhone-6.7  
mkdir -p Screenshots/iPhone-6.5

# Place your iPhone 16 screenshots in iPhone-6.1-Source/
# Then scale them:

# Scale to 6.7" (1290×2796)
for file in Screenshots/iPhone-6.1-Source/*.png; do
    filename=$(basename "$file")
    sips -z 2796 1290 "$file" --out "Screenshots/iPhone-6.7/$filename"
done

# Scale to 6.5" (1242×2688)  
for file in Screenshots/iPhone-6.1-Source/*.png; do
    filename=$(basename "$file")
    sips -z 2688 1242 "$file" --out "Screenshots/iPhone-6.5/$filename"
done
```

---

## 📐 **Resolution Comparison**

| Device | Screen Size | Resolution | Aspect Ratio |
|--------|-------------|------------|--------------|
| **iPhone 16** (Your device) | 6.1" | 1179×2556 | 19.5:9 |
| **iPhone 16 Pro** (6.7" required) | 6.7" | 1290×2796 | 19.5:9 |
| **iPhone 15 Pro** (6.5" required) | 6.5" | 1242×2688 | 19.5:9 |

✅ **Good news**: All have the same aspect ratio, so scaling won't distort the UI!

---

## 🎯 **RECOMMENDED APPROACH**

### **Option A: Use Simulators (Recommended)**
- ✅ Exact required resolutions
- ✅ No quality loss from scaling
- ✅ Apple prefers simulator screenshots
- ✅ Professional appearance

**Steps:**
```bash
cd AppStoreAssets
./generate_screenshots.sh
# Choose option 5 (Complete automated generation)
```

### **Option B: Scale iPhone 16 Screenshots**
- ✅ Uses your actual device
- ✅ Real hardware rendering
- ⚠️ Slight quality loss from scaling
- ✅ Still acceptable for App Store

**Steps:**
1. Take screenshots on iPhone 16
2. Use the scaling commands above
3. Review quality and upload

---

## 📋 **Screenshot Checklist**

For each device size, ensure you have:

### ✅ **Screen 1: Voice Capture**
- Large blue microphone button centered
- "Tap to record your message" text
- Clean, professional background

### ✅ **Screen 2: Recording Active**  
- Waveform animation visible
- Timer showing (00:15 or similar)
- Recording indicator active

### ✅ **Screen 3: Message Review**
- AI-processed text displayed
- Clear, readable message content
- Edit and tone selection buttons visible

### ✅ **Screen 4: Tone Selection**
- Grid of tone options visible
- Show variety: Professional, Gen Z, Casual, etc.
- Highlight the breadth of options

### ✅ **Screen 5: iMessage Integration**
- Messages app open
- VibeText icon visible in app drawer
- Shows integration context

---

## 🚀 **Quick Start Command**

```bash
# Run this to get started immediately:
cd /Users/nickd/Workspaces/VibeText/AppStoreAssets
./generate_screenshots.sh
```

**Choose Option 5** for the complete automated process!

---

## 📱 **Final File Structure**

After completion, you should have:
```
AppStoreAssets/Screenshots/
├── iPhone-6.7/
│   ├── screenshot-1.png (1290×2796)
│   ├── screenshot-2.png (1290×2796)  
│   ├── screenshot-3.png (1290×2796)
│   ├── screenshot-4.png (1290×2796)
│   └── screenshot-5.png (1290×2796)
└── iPhone-6.5/
    ├── screenshot-1.png (1242×2688)
    ├── screenshot-2.png (1242×2688)
    ├── screenshot-3.png (1242×2688) 
    ├── screenshot-4.png (1242×2688)
    └── screenshot-5.png (1242×2688)
```

Then upload these directly to App Store Connect! 🎉