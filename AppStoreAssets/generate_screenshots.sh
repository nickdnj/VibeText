#!/bin/bash

# VibeText Screenshot Generation Script
# This script helps generate App Store screenshots for required device sizes

set -e

echo "📱 VibeText Screenshot Generator"
echo "==============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}📱 $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Device configurations
IPHONE_16_PRO_SIM="iPhone 16 Pro"
IPHONE_15_PRO_SIM="iPhone 15 Pro"
PROJECT_PATH="/Users/nickd/Workspaces/VibeText"
SCHEME="VibeText"

# Screenshot directories
SCREENSHOT_DIR="$PROJECT_PATH/AppStoreAssets/Screenshots"
IPHONE_67_DIR="$SCREENSHOT_DIR/iPhone-6.7"
IPHONE_65_DIR="$SCREENSHOT_DIR/iPhone-6.5"

echo ""
echo "📋 SCREENSHOT REQUIREMENTS:"
echo "- iPhone 6.7\" (1290×2796) - iPhone 16 Pro, 15 Pro Max"
echo "- iPhone 6.5\" (1242×2688) - iPhone 15 Pro, 14 Pro Max, etc."
echo ""

# Function to take screenshots from simulator
take_simulator_screenshots() {
    local device_name=$1
    local output_dir=$2
    local size_name=$3
    
    print_status "Starting $device_name simulator for $size_name screenshots..."
    
    # Get device UUID - improved parsing
    if [[ "$device_name" == "iPhone 16 Pro" ]]; then
        DEVICE_UUID="04DC4AA3-3F4B-4FA3-8C6C-0D873FB175C4"
    elif [[ "$device_name" == "iPhone 15 Pro" ]]; then
        # Fallback to iPhone 16 Pro Max for 6.5" screenshots since 15 Pro isn't available
        DEVICE_UUID="2DDB5B8A-06DA-4965-9F79-72DCCC0D0C08"
        device_name="iPhone 16 Pro Max"
    else
        DEVICE_UUID=$(xcrun simctl list devices available | grep "$device_name" | head -1 | sed 's/.*(\([^)]*\)).*/\1/')
    fi
    
    if [ -z "$DEVICE_UUID" ]; then
        print_error "Could not find $device_name simulator"
        return 1
    fi
    
    print_status "Using device: $device_name ($DEVICE_UUID)"
    
    # Boot simulator
    print_status "Booting simulator..."
    xcrun simctl boot "$DEVICE_UUID" 2>/dev/null || true
    sleep 5
    
    # Build and install app
    print_status "Building app for simulator..."
    xcodebuild -scheme "$SCHEME" -destination "platform=iOS Simulator,id=$DEVICE_UUID" -configuration Debug build
    
    print_status "Installing app on simulator..."
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "VibeText.app" -path "*Debug-iphonesimulator*" | head -1)
    if [ -z "$APP_PATH" ]; then
        print_error "Could not find built app. Please check the build output above."
        return 1
    fi
    print_status "Found app at: $APP_PATH"
    xcrun simctl install "$DEVICE_UUID" "$APP_PATH"
    
    # Launch app
    print_status "Launching VibeText..."
    xcrun simctl launch "$DEVICE_UUID" com.d3marco.VibeText
    
    sleep 3
    
    # Take screenshots
    print_status "Ready to take screenshots for $size_name!"
    echo ""
    print_warning "MANUAL STEPS:"
    echo "1. The $device_name simulator should now be running VibeText"
    echo "2. Navigate through these 5 key screens and take screenshots:"
    echo "   📱 Screen 1: Main voice capture (large microphone button)"
    echo "   📱 Screen 2: Recording active (with waveform/timer)"
    echo "   📱 Screen 3: Message review (AI-processed text)"
    echo "   📱 Screen 4: Tone selection (show tone grid)"
    echo "   📱 Screen 5: iMessage integration (Messages app drawer)"
    echo ""
    echo "3. For each screen, press Cmd+S in Simulator to save screenshot"
    echo "4. Save screenshots to: $output_dir"
    echo "5. Name them: screenshot-1.png, screenshot-2.png, etc."
    echo ""
    
    read -p "Press Enter when you've finished taking screenshots for $size_name..."
    
    # Shutdown simulator
    print_status "Shutting down simulator..."
    xcrun simctl shutdown "$DEVICE_UUID"
    
    print_success "Screenshots completed for $size_name"
}

# Function to scale existing screenshots
scale_screenshots() {
    local source_dir=$1
    local target_dir=$2
    local target_width=$3
    local target_height=$4
    local size_name=$5
    
    print_status "Scaling screenshots for $size_name ($target_width×$target_height)..."
    
    if [ ! -d "$source_dir" ] || [ -z "$(ls -A $source_dir)" ]; then
        print_warning "No source screenshots found in $source_dir"
        return 1
    fi
    
    mkdir -p "$target_dir"
    
    for screenshot in "$source_dir"/*.png; do
        if [ -f "$screenshot" ]; then
            filename=$(basename "$screenshot")
            target_file="$target_dir/$filename"
            
            print_status "Scaling $filename to ${target_width}×${target_height}..."
            
            # Use sips to scale the image
            sips -z "$target_height" "$target_width" "$screenshot" --out "$target_file" >/dev/null 2>&1
            
            if [ $? -eq 0 ]; then
                print_success "Scaled: $filename"
            else
                print_error "Failed to scale: $filename"
            fi
        fi
    done
}

# Main menu
echo "📱 SCREENSHOT GENERATION OPTIONS:"
echo "1. Generate 6.7\" screenshots using iPhone 16 Pro simulator"
echo "2. Generate 6.5\" screenshots using iPhone 15 Pro simulator"  
echo "3. Scale existing iPhone 16 screenshots to required sizes"
echo "4. Take screenshots on physical iPhone 16 (6.1\" display)"
echo "5. Complete automated generation (simulators + scaling)"
echo ""

read -p "Choose option (1-5): " choice

case $choice in
    1)
        print_status "Generating 6.7\" screenshots..."
        mkdir -p "$IPHONE_67_DIR"
        take_simulator_screenshots "$IPHONE_16_PRO_SIM" "$IPHONE_67_DIR" "6.7\""
        ;;
    2)
        print_status "Generating 6.5\" screenshots..."
        mkdir -p "$IPHONE_65_DIR"
        take_simulator_screenshots "$IPHONE_15_PRO_SIM" "$IPHONE_65_DIR" "6.5\""
        ;;
    3)
        echo "📱 SCALING REQUIREMENTS:"
        echo "This option requires existing screenshots to scale from."
        echo ""
        read -p "Enter source directory path (or press Enter for iPhone 16 physical): " source_path
        
        if [ -z "$source_path" ]; then
            source_path="$SCREENSHOT_DIR/iPhone-6.1-Source"
            print_warning "Using default: $source_path"
            print_warning "Please manually take screenshots on your iPhone 16 and place them in: $source_path"
            print_warning "Then re-run this script with option 3"
            exit 1
        fi
        
        mkdir -p "$IPHONE_67_DIR" "$IPHONE_65_DIR"
        scale_screenshots "$source_path" "$IPHONE_67_DIR" 1290 2796 "6.7\""
        scale_screenshots "$source_path" "$IPHONE_65_DIR" 1242 2688 "6.5\""
        ;;
    4)
        print_status "Taking screenshots on physical iPhone 16..."
        echo ""
        print_warning "MANUAL STEPS FOR PHYSICAL DEVICE:"
        echo "1. Build and install VibeText on your iPhone 16:"
        echo "   cd $PROJECT_PATH && ./build_and_test.sh"
        echo ""
        echo "2. Take 5 key screenshots on your iPhone 16:"
        echo "   📱 Screen 1: Voice capture interface"
        echo "   📱 Screen 2: Recording active"
        echo "   📱 Screen 3: Message review"
        echo "   📱 Screen 4: Tone selection"
        echo "   📱 Screen 5: iMessage integration"
        echo ""
        echo "3. AirDrop or sync screenshots to Mac"
        echo "4. Place them in: $SCREENSHOT_DIR/iPhone-6.1-Source/"
        echo "5. Re-run this script with option 3 to scale them"
        echo ""
        mkdir -p "$SCREENSHOT_DIR/iPhone-6.1-Source"
        ;;
    5)
        print_status "Running complete automated generation..."
        mkdir -p "$IPHONE_67_DIR" "$IPHONE_65_DIR"
        
        print_status "Step 1: Generating 6.7\" screenshots..."
        take_simulator_screenshots "$IPHONE_16_PRO_SIM" "$IPHONE_67_DIR" "6.7\""
        
        print_status "Step 2: Generating 6.5\" screenshots..."
        take_simulator_screenshots "$IPHONE_15_PRO_SIM" "$IPHONE_65_DIR" "6.5\""
        
        print_success "Complete automated generation finished!"
        ;;
    *)
        print_error "Invalid option. Please run script again."
        exit 1
        ;;
esac

echo ""
print_success "Screenshot generation completed!"
echo ""
echo "📁 NEXT STEPS:"
echo "1. Review screenshots in:"
echo "   - $IPHONE_67_DIR"
echo "   - $IPHONE_65_DIR"
echo ""
echo "2. Upload to App Store Connect:"
echo "   - Go to 'Previews and Screenshots'"
echo "   - Drag screenshots to appropriate device sections"
echo ""
echo "3. Ensure you have 3-5 high-quality screenshots per device size"

echo ""
print_success "Ready for App Store submission! 🎉"