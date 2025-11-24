# Building Slow Blurn

## Option 1: Using Xcode (Recommended)

1. **Install Xcode** (if not already installed):
   - Open the App Store
   - Search for "Xcode"
   - Click "Get" or "Install"
   - Wait for installation to complete (this may take a while)

2. **Open the project**:
   ```bash
   cd /Users/davefowler/Projects/slowblurn
   open SlowBlurn.xcodeproj
   ```

3. **Build and Run**:
   - In Xcode, press `⌘R` (Command+R) to build and run
   - Or click the Play button in the top left
   - Or go to Product → Run

4. **Build for Release**:
   - In Xcode, go to Product → Archive
   - This creates a distributable app

## Option 2: Using Command Line (Requires Xcode)

Once Xcode is installed, you can build from the command line:

```bash
cd /Users/davefowler/Projects/slowblurn
./build.sh
```

Or manually:

```bash
xcodebuild -project SlowBlurn.xcodeproj -scheme SlowBlurn -configuration Release build
```

The built app will be in `build/DerivedData/Build/Products/Release/SlowBlurn.app`

## Setting Up Xcode Developer Directory

If you have Xcode installed but get errors about the developer directory:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

You may need to accept the license:
```bash
sudo xcodebuild -license accept
```

## First Run

When you first run the app:
1. macOS may ask for Screen Recording permission - grant it (required for the overlay)
2. The settings window will open automatically
3. A menu bar icon (moon/stars) will appear
4. The app will start monitoring time and apply effects at your configured times

## Troubleshooting

**"xcodebuild requires Xcode" error:**
- Install Xcode from the App Store (not just Command Line Tools)
- Set the developer directory: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`

**Build errors:**
- Make sure all Swift files are included in the project
- Check that Info.plist is properly configured
- Verify macOS deployment target is set to 13.0 or higher

**App doesn't show overlay:**
- Grant Screen Recording permission in System Settings → Privacy & Security → Screen Recording
- Check that the time is within your configured start/end window
- Use "Test Effect" button in settings to verify

