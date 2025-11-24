# Setting Up Fresh Xcode Project

The project file was corrupted. Let's create a fresh one:

## Step 1: Create New Project in Xcode

1. **Open Xcode**
2. **File → New → Project** (or `⌘⇧N`)
3. Select **macOS** tab
4. Choose **App**
5. Click **Next**
6. Fill in:
   - **Product Name:** `SlowBlurn`
   - **Team:** (your team or None)
   - **Organization Identifier:** `com.slowblurn` (or your own)
   - **Interface:** `SwiftUI`
   - **Language:** `Swift`
   - **Storage:** `None` (we don't need Core Data)
7. Click **Next**
8. **IMPORTANT:** Navigate to `/Users/davefowler/Projects/slowblurn`
9. **Uncheck** "Create Git repository" (unless you want it)
10. Click **Create**

## Step 2: Replace Generated Files

Xcode will create `SlowBlurnApp.swift` - **delete it** and add our files instead:

1. In Project Navigator, right-click on the project name
2. Select **Add Files to "SlowBlurn"...**
3. Navigate to the project directory
4. Select **ALL** these files:
   - `SlowBlurnApp.swift`
   - `BlurManager.swift`
   - `BlurOverlayView.swift`
   - `SettingsView.swift`
   - `ModeType.swift`
   - `ModeViews.swift`
   - `Info.plist`
5. Make sure **"Copy items if needed"** is **UNCHECKED**
6. Make sure **"Add to targets: SlowBlurn"** is **CHECKED**
7. Click **Add**

## Step 3: Configure Info.plist

1. Select the project in Navigator (top item)
2. Select the **SlowBlurn** target
3. Go to **Info** tab
4. Find **"Application Category"** and set it to **"Utility"** or leave default
5. Make sure **"LSUIElement"** is set to **YES** (this hides the dock icon)

Or manually edit Info.plist and ensure it has:
```xml
<key>LSUIElement</key>
<true/>
```

## Step 4: Build Settings

1. Select the **SlowBlurn** target
2. Go to **Build Settings** tab
3. Search for **"macOS Deployment Target"**
4. Set it to **13.0** or higher

## Step 5: Build and Run

1. Select **"My Mac"** as the destination (top toolbar)
2. Press **⌘R** (Command+R) or click the Play button
3. The app should build and run!

## Troubleshooting

**If files show red (missing):**
- Right-click the file → "Show in Finder" to verify it exists
- Remove from project (Move to Trash) and re-add

**If build errors:**
- Make sure all Swift files are added to the target
- Check that Info.plist is included
- Verify macOS deployment target is 13.0+

**If app doesn't run:**
- Check Console for errors
- Grant Screen Recording permission in System Settings

