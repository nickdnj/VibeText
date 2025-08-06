#!/bin/bash

# VibeText Screenshot Checker
# This script helps you verify and organize your App Store screenshots

set -e

echo "📱 VibeText Screenshot Checker"
echo "=============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}📋 $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

echo ""
print_status "Checking for recent screenshots on Desktop..."

# Find recent screenshots (from today)
TODAY=$(date +%Y-%m-%d)
RECENT_SCREENSHOTS=$(find ~/Desktop -name "*Screenshot*${TODAY}*" -o -name "*Screen Shot*${TODAY}*" 2>/dev/null | head -10)

if [ -z "$RECENT_SCREENSHOTS" ]; then
    print_warning "No screenshots from today found on Desktop"
    echo "Looking for any recent screenshots..."
    RECENT_SCREENSHOTS=$(find ~/Desktop -name "*Screenshot*" -o -name "*Screen Shot*" -mtime -1 2>/dev/null | head -10)
fi

echo ""
print_status "Recent screenshots found:"
if [ -n "$RECENT_SCREENSHOTS" ]; then
    echo "$RECENT_SCREENSHOTS" | while read screenshot; do
        if [ -f "$screenshot" ]; then
            echo "📷 $(basename "$screenshot")"
            # Try to get dimensions using sips
            DIMENSIONS=$(sips -g pixelWidth -g pixelHeight "$screenshot" 2>/dev/null | grep "pixelWidth\|pixelHeight" | awk '{print $2}' | tr '\n' 'x' | sed 's/x$//')
            if [ -n "$DIMENSIONS" ]; then
                echo "   Size: $DIMENSIONS pixels"
                
                # Check if dimensions match App Store requirements
                WIDTH=$(echo "$DIMENSIONS" | cut -d'x' -f1)
                HEIGHT=$(echo "$DIMENSIONS" | cut -d'x' -f2)
                
                if [ "$WIDTH" = "1290" ] && [ "$HEIGHT" = "2796" ]; then
                    print_success "   ✅ Perfect for iPhone 6.7\" (1290×2796)"
                elif [ "$WIDTH" = "1242" ] && [ "$HEIGHT" = "2688" ]; then
                    print_success "   ✅ Perfect for iPhone 6.5\" (1242×2688)"
                elif [ "$WIDTH" = "2796" ] && [ "$HEIGHT" = "1290" ]; then
                    print_warning "   🔄 Landscape - needs to be portrait (2796×1290)"
                elif [ "$WIDTH" = "2688" ] && [ "$HEIGHT" = "1242" ]; then
                    print_warning "   🔄 Landscape - needs to be portrait (2688×1242)"
                else
                    print_warning "   ⚠️  Non-standard size - may need resizing"
                fi
            else
                echo "   Size: Unable to determine"
            fi
            echo ""
        fi
    done
else
    print_error "No recent screenshots found"
fi

echo ""
print_status "Checking current screenshot directories..."

# Check 6.7" screenshots
SCREENSHOT_67_DIR="AppStoreAssets/Screenshots/iPhone-6.7"
SCREENSHOT_65_DIR="AppStoreAssets/Screenshots/iPhone-6.5"

echo ""
echo "📁 iPhone 6.7\" directory ($SCREENSHOT_67_DIR):"
if [ -d "$SCREENSHOT_67_DIR" ]; then
    COUNT_67=$(ls -1 "$SCREENSHOT_67_DIR"/*.png 2>/dev/null | wc -l | tr -d ' ')
    if [ "$COUNT_67" -gt 0 ]; then
        print_success "$COUNT_67 screenshots found"
        ls -la "$SCREENSHOT_67_DIR"/*.png 2>/dev/null | while read line; do
            echo "  $line"
        done
    else
        print_warning "Directory exists but no screenshots found"
    fi
else
    print_error "Directory doesn't exist"
fi

echo ""
echo "📁 iPhone 6.5\" directory ($SCREENSHOT_65_DIR):"
if [ -d "$SCREENSHOT_65_DIR" ]; then
    COUNT_65=$(ls -1 "$SCREENSHOT_65_DIR"/*.png 2>/dev/null | wc -l | tr -d ' ')
    if [ "$COUNT_65" -gt 0 ]; then
        print_success "$COUNT_65 screenshots found"
        ls -la "$SCREENSHOT_65_DIR"/*.png 2>/dev/null | while read line; do
            echo "  $line"
        done
    else
        print_warning "Directory exists but no screenshots found"
    fi
else
    print_error "Directory doesn't exist"
fi

echo ""
print_status "App Store Requirements:"
echo "📱 iPhone 6.7\": 1290×2796 pixels (iPhone 15 Pro Max, 16 Pro)"
echo "📱 iPhone 6.5\": 1242×2688 pixels (iPhone 14 Pro Max, 15 Pro)"
echo "📱 Required: 3-5 screenshots per device size"
echo "📱 Format: PNG, high quality, portrait orientation"

echo ""
print_status "Screenshot Content Checklist:"
echo "1. 📱 Voice Capture: Main screen with large microphone button"
echo "2. 🎙️  Recording Active: Show waveform/timer during recording"
echo "3. ✨ Message Review: AI-processed text displayed clearly"
echo "4. 🎭 Tone Selection: Grid showing all tone options"
echo "5. 💬 iMessage Integration: VibeText in Messages app drawer"

echo ""
print_status "Next Steps:"
echo ""
if [ "$COUNT_67" -lt 3 ] || [ "$COUNT_65" -lt 3 ]; then
    print_warning "You need at least 3 screenshots per device size for App Store submission"
    echo ""
    echo "🔧 To fix this:"
    echo "1. Run the screenshot generator again:"
    echo "   cd /Users/nickd/Workspaces/VibeText"
    echo "   AppStoreAssets/generate_screenshots.sh"
    echo ""
    echo "2. Or manually copy recent screenshots:"
    echo "   cp ~/Desktop/Screenshot*.png AppStoreAssets/Screenshots/iPhone-6.7/"
    echo "   (Make sure they're the right dimensions first!)"
else
    print_success "You have enough screenshots for App Store submission!"
    echo ""
    echo "🎉 Ready for upload to App Store Connect:"
    echo "1. Go to App Store Connect → VibeText → Previews and Screenshots"
    echo "2. Upload screenshots from:"
    echo "   - AppStoreAssets/Screenshots/iPhone-6.7/ (for 6.7\" devices)"
    echo "   - AppStoreAssets/Screenshots/iPhone-6.5/ (for 6.5\" devices)"
    echo "3. Add optimized App Store copy from AppStoreAssets/Metadata/app-store-copy.txt"
fi

echo ""
print_success "Screenshot check complete! 📱✨"