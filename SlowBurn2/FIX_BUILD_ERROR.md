# Fix "Undefined symbol: _main" Error

This error means Xcode can't find the app's entry point. Here's how to fix it:

## Solution 1: Check File is Added to Target

1. **In Xcode, select `SlowBlurnApp.swift`** in the Project Navigator
2. **Open the File Inspector** (right sidebar, or `⌘⌥1`)
3. **Under "Target Membership"**, make sure **SlowBlurn** is **CHECKED**
4. If it's unchecked, check it

## Solution 2: Remove Duplicate Files

Xcode might have created a duplicate `SlowBlurnApp.swift`. Check:

1. Look in Project Navigator for **TWO** `SlowBlurnApp.swift` files
2. If you see two:
   - Select the one that's in a folder (like `SlowBlurn/SlowBlurnApp.swift`)
   - Right-click → **Delete** → **Remove Reference** (NOT Move to Trash)
   - Keep the one in the root directory

## Solution 3: Clean Build Folder

1. In Xcode menu: **Product → Clean Build Folder** (or `⌘⇧K`)
2. Try building again (`⌘R`)

## Solution 4: Verify @main Attribute

Make sure `SlowBlurnApp.swift` has `@main` at the top:

```swift
@main
struct SlowBlurnApp: App {
    // ...
}
```

## Solution 5: Check Build Settings

1. Select **SlowBlurn** project (top item)
2. Select **SlowBlurn** target
3. Go to **Build Settings** tab
4. Search for **"Swift Compiler"**
5. Make sure **"Swift Language Version"** is set to **Swift 5** or higher

## Solution 6: Re-add the File

If nothing works:

1. **Remove** `SlowBlurnApp.swift` from project (right-click → Delete → Remove Reference)
2. **Re-add** it: Right-click project → Add Files → Select `SlowBlurnApp.swift`
3. Make sure **"Add to targets: SlowBlurn"** is checked
4. Build again

Try these in order - Solution 1 usually fixes it!

