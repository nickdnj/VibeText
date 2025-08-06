# 📱 App Store Assets for VibeText

This directory contains all assets and metadata needed for App Store submission.

## 📁 Directory Structure

```
AppStoreAssets/
├── Icons/
│   └── AppIcon-1024x1024.png          ✅ Ready for upload
├── Screenshots/
│   ├── iPhone-6.7/                    ❌ Need to create (1290 × 2796)
│   ├── iPhone-6.5/                    ❌ Need to create (1242 × 2688)
│   └── iPad-12.9/                     🟡 Optional (2048 × 2732)
├── Metadata/
│   └── app-store-copy.txt             ✅ Copy-paste ready text
└── README.md                          📖 This file
```

## 🎯 How to Use These Assets

### 1. Icons
- **AppIcon-1024x1024.png**: Upload directly to App Store Connect "App Icon" section
- ✅ Already meets Apple requirements (PNG, RGB, no transparency)

### 2. Screenshots (NEED TO CREATE)
Create screenshots using iPhone 16 Pro and iPhone 15 Pro:

#### Required Screenshots (3-5 per device class):
1. **Voice Capture Screen** - Main microphone button interface
2. **Recording Active** - Show waveform/recording indicator  
3. **Message Review** - AI-processed text display
4. **Tone Selection** - Grid of 14 tone options
5. **iMessage Integration** - App icon in Messages drawer

#### Screenshot Specifications:
- **iPhone 6.7"**: 1290 × 2796 pixels (iPhone 15 Pro, 16 Pro)
- **iPhone 6.5"**: 1242 × 2688 pixels (iPhone 14 Pro, 15 Pro)
- **No simulator chrome** (just home indicator)
- **High quality** - crisp text and clear UI

### 3. App Store Copy
- **app-store-copy.txt**: Contains all optimized text for App Store Connect
- Copy sections directly into App Store Connect fields:
  - Subtitle
  - Promotional Text  
  - Description
  - Keywords
  - Review Notes

## 📝 Next Steps

1. **Take Screenshots** using build_and_test.sh on physical devices
2. **Save Screenshots** in appropriate device folders (iPhone-6.7/, iPhone-6.5/)
3. **Upload to App Store Connect**:
   - Go to "Previews and Screenshots" section
   - Drag/drop screenshots for each device class
   - Upload AppIcon-1024x1024.png to App Information
4. **Copy Metadata** from app-store-copy.txt to App Store Connect forms
5. **Submit for Review**

## 🚨 Critical Requirements

- **Minimum 3 screenshots** per device class
- **Maximum 10 screenshots** per device class  
- **Screenshots must show actual app functionality**
- **No misleading or fake screenshots**
- **High resolution and professional quality**

---

**Note**: Screenshots are the #1 blocker for App Store submission. Everything else is ready to go!