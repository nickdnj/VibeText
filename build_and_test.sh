#!/bin/bash

# VibeText Build and Test Script
# Usage: ./build_and_test.sh

set -e  # Exit on any error

echo "🎯 VibeText Development Test Loop"
echo "=================================="

# Device ID for iPhone 16
DEVICE_ID="00008140-000A24EC3C90801C"
PROJECT_NAME="VibeText"
BUILD_PATH="/Users/nickd/Library/Developer/Xcode/DerivedData/VibeText-dcdywwtrrkccicbdrrneuvfblqmi/Build/Products/Debug-iphoneos/VibeText.app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}📱 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Step 1: Check device connection
print_status "Checking device connection..."
if xcrun devicectl list devices | grep -q "iPhone16"; then
    print_success "iPhone 16 is connected"
else
    print_error "iPhone 16 not found. Please connect your device."
    exit 1
fi

# Step 2: Build the project
print_status "Building VibeText project..."
if xcodebuild -scheme "$PROJECT_NAME" -destination "platform=iOS,id=$DEVICE_ID" -configuration Debug build; then
    print_success "Build completed successfully"
else
    print_error "Build failed"
    exit 1
fi

# Step 3: Install on device
print_status "Installing app on device..."
if xcrun devicectl device install app --device "$DEVICE_ID" "$BUILD_PATH"; then
    print_success "App installed successfully"
else
    print_error "Installation failed"
    exit 1
fi

# Step 4: Test checklist
echo ""
echo "🧪 TEST CHECKLIST:"
echo "=================="
echo "1. Open VibeText app on your iPhone"
echo "2. Test core recording functionality:"
echo "   - Tap 'Start Recording'"
echo "   - Speak for 10-15 seconds"
echo "   - Tap 'Stop Recording'"
echo "   - Check live transcript appears"
echo "   - Verify timer shows MM:SS format"
echo ""
echo "3. Test audio session stability:"
echo "   - Start recording"
echo "   - Edit text in review screen"
echo "   - Continue recording after editing"
echo ""
echo "4. Test message editing:"
echo "   - Edit AI-generated text"
echo "   - Test copy functionality"
echo "   - Test with long messages"
echo ""
echo "5. Test interruption handling:"
echo "   - Start recording"
echo "   - Receive a call (or simulate)"
echo "   - Return to app"
echo "   - Try recording again"
echo ""

# Step 5: Prompt for test results
echo "📝 TEST RESULTS:"
echo "================"
echo "Please describe what you observed:"
echo "- What worked as expected?"
echo "- What didn't work?"
echo "- Any error messages?"
echo "- Any unexpected behavior?"
echo ""

print_success "Ready for testing! Please run the tests above and report back." 