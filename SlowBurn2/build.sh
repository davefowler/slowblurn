#!/bin/bash

# Build script for SlowBlurn macOS app
# Note: This requires Xcode to be installed

set -e

echo "Building SlowBlurn..."

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: xcodebuild not found. Please install Xcode from the App Store."
    echo "Alternatively, open SlowBlurn.xcodeproj in Xcode and build from there."
    exit 1
fi

# Clean build directory
rm -rf build
mkdir -p build

# Build the project
xcodebuild \
    -project SlowBlurn.xcodeproj \
    -scheme SlowBlurn \
    -configuration Release \
    -derivedDataPath build/DerivedData \
    build

# Find the built app
APP_PATH=$(find build/DerivedData -name "SlowBlurn.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "Error: Could not find built app"
    exit 1
fi

# Copy to build directory
cp -R "$APP_PATH" build/

echo ""
echo "Build complete! App is at: build/SlowBlurn.app"
echo "To run: open build/SlowBlurn.app"
