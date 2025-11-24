#!/bin/bash

# Create a fresh Xcode project for SlowBlurn

cd "$(dirname "$0")"

# Create project using xcodebuild (if available) or provide instructions
echo "Creating new Xcode project..."

# List all Swift files
SWIFT_FILES="SlowBlurnApp.swift BlurManager.swift BlurOverlayView.swift SettingsView.swift ModeType.swift ModeViews.swift"

echo "Swift files to include:"
for file in $SWIFT_FILES; do
    if [ -f "$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file (missing!)"
    fi
done

echo ""
echo "Please create a new project in Xcode:"
echo "1. Open Xcode"
echo "2. File → New → Project"
echo "3. Choose 'macOS' → 'App'"
echo "4. Name: SlowBlurn"
echo "5. Interface: SwiftUI"
echo "6. Language: Swift"
echo "7. Save in: $(pwd)"
echo ""
echo "Then add all the Swift files and Info.plist to the project."

