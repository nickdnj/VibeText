#!/bin/bash

# Script to add required frameworks to VibeText project
echo "🔧 Adding required frameworks to VibeText project..."

# Navigate to project directory
cd "$(dirname "$0")"

# Add frameworks to main app target
echo "📱 Adding frameworks to main app target..."

# Speech framework
echo "Adding Speech.framework..."
xcodebuild -project VibeText.xcodeproj -target VibeText -add-framework Speech.framework

# AVFoundation framework  
echo "Adding AVFoundation.framework..."
xcodebuild -project VibeText.xcodeproj -target VibeText -add-framework AVFoundation.framework

# Security framework
echo "Adding Security.framework..."
xcodebuild -project VibeText.xcodeproj -target VibeText -add-framework Security.framework

echo "✅ Frameworks added to main app target!"

# Add frameworks to extension target (if it exists)
if [ -d "VibeTextExtension" ]; then
    echo "📱 Adding frameworks to extension target..."
    
    # Speech framework
    echo "Adding Speech.framework to extension..."
    xcodebuild -project VibeText.xcodeproj -target VibeTextExtension -add-framework Speech.framework
    
    # AVFoundation framework
    echo "Adding AVFoundation.framework to extension..."
    xcodebuild -project VibeText.xcodeproj -target VibeTextExtension -add-framework AVFoundation.framework
    
    # Security framework
    echo "Adding Security.framework to extension..."
    xcodebuild -project VibeText.xcodeproj -target VibeTextExtension -add-framework Security.framework
    
    echo "✅ Frameworks added to extension target!"
else
    echo "⚠️  Extension target not found. Please create the iMessage extension first."
fi

echo "🎉 Framework setup complete!"
echo ""
echo "Next steps:"
echo "1. Open VibeText.xcodeproj in Xcode"
echo "2. Verify frameworks are added in the 'General' tab"
echo "3. Build and test the project" 