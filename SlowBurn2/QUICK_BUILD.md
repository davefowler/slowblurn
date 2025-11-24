# Quick Build Instructions

The Xcode project file may need to be fixed. Here's the easiest way:

## Step 1: Open in Xcode
The project should now be opening in Xcode. If not, run:
```bash
open SlowBlurn.xcodeproj
```

## Step 2: Let Xcode Fix the Project
Xcode will automatically fix any project file issues when it opens.

## Step 3: Build
Once Xcode is open:
1. Select the "SlowBlurn" scheme (top toolbar)
2. Select "My Mac" as the destination
3. Press `⌘R` (Command+R) or click the Play button

## Step 4: Run
The app will build and run. You should see:
- Settings window opens
- Menu bar icon appears (moon/stars)
- App is ready to use!

## Alternative: Build from Command Line (after Xcode fixes project)

Once Xcode has opened and fixed the project, you can build from terminal:

```bash
cd /Users/davefowler/Projects/slowblurn
xcodebuild -project SlowBlurn.xcodeproj -scheme SlowBlurn -configuration Release build
```

The app will be in: `build/DerivedData/Build/Products/Release/SlowBlurn.app`

