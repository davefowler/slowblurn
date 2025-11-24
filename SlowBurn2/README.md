# Slow Blurn

A macOS app with multiple modes to gradually make your screen unusable starting at 9pm, reaching maximum effect by 10pm to help you wind down and stop using your computer.

## Modes

### 1. **Blur** - Slow Blur
Gradual blur effect using multiple layers of macOS blur materials. At maximum intensity, 25+ blur layers make the screen completely unreadable.

### 2. **Pixel Freeze** - Random Pixel Freezing
Randomly "freezes" pixels across the screen at an increasing rate. Pixels appear as random colored squares, simulating a frozen screen effect.

### 3. **Pixel Blackout** - Random Pixel Blacking
Randomly blacks out pixels across the screen. Starts slow and increases until significant portions of the screen are blacked out.

### 4. **Sleepy Emoji** - Emoji Overlay
Slowly covers the screen with more and more sleepy emojis (😴💤😪🥱😵🛌) randomly placed. By 10pm, your screen is covered in emojis!

### 5. **Distortion** - Funky Distortion
A wavy distortion effect overlay that gets progressively worse with time. Multiple distortion layers create a trippy, unusable screen.

### 6. **Messages** - Bedtime Messages
Fills the screen with message overlays saying things like:
- "Hey - go to bed"
- "For real, it's time to sleep"
- "You're tired"
- "Stop staring at the screen"
- And more...

### 7. **Side Swipe** - Rainbow Swipe
A rainbow gradient starts coming in from the right side of the screen, slowly moving to the left over the course of an hour until it covers the entire screen.

## How It Works

- **9:00 PM** (configurable): Effect begins gradually
- **10:00 PM** (configurable): Maximum intensity reached
- The overlay window is non-interactive (clicks pass through) but makes the screen progressively harder to use
- All effects use configurable acceleration curves for different progression styles

## Building

### Option 1: Using Xcode (Recommended)

1. Open Xcode
2. Create a new project: File → New → Project
3. Choose "macOS" → "App"
4. Name it "SlowBlurn"
5. Set Interface to "SwiftUI"
6. Replace the generated files with the files in this directory:
   - `SlowBlurnApp.swift` → Replace `App.swift`
   - Add `BlurManager.swift`, `BlurOverlayView.swift`, `SettingsView.swift`
7. In Project Settings → Info → Custom macOS Application Target Properties:
   - Add key `LSUIElement` with value `YES` (to hide dock icon)
8. Build and run (⌘R)

### Option 2: Using Swift Compiler Directly

```bash
chmod +x build.sh
./build.sh
```

Then run: `./build/SlowBlurn`

## Running

The app runs as a background app (no dock icon due to `LSUIElement`). To access settings:
- The settings window opens automatically when you launch the app
- You can close the settings window - the app continues running in the background
- To quit, use Activity Monitor or: `killall SlowBlurn`

## Features

- **7 different modes** - Choose the effect that works best for you
- **Configurable acceleration curves** - Linear, Ease In, Ease Out, Ease In/Out, or Exponential
- **Customizable schedule** - Set your own start and end times
- **Fullscreen overlay** - Covers all displays (multi-monitor support)
- **Non-intrusive** - Clicks pass through so you can still interact (but won't want to!)
- **Runs in background** - Menu bar app with no dock icon
- **Settings window** - Check current intensity and configure everything

## How the Blur Works

The app uses multiple techniques for maximum blur effect:
1. **NSVisualEffectView** with different materials (sidebar, popover, hudWindow)
2. **Multiple overlapping layers** - up to 25+ layers at maximum intensity
3. **Darkening overlay** - adds black opacity at high intensities
4. **Screen saver window level** - ensures it stays above all other windows

## Customization

All customization is done through the Settings window:

1. **Select Mode** - Choose from 7 different effect modes
2. **Acceleration Curve** - Control how quickly the effect ramps up:
   - **Linear** - Constant rate
   - **Ease In** - Slow start, fast end
   - **Ease Out** - Fast start, slow end
   - **Ease In/Out** - Smooth acceleration and deceleration
   - **Exponential** - Very slow start, explosive end
3. **Schedule** - Set custom start and end times (default 9pm-10pm)

### Advanced Customization

For code-level tweaks, you can modify:
- **Mode intensity multipliers** in `ModeViews.swift` for each mode
- **Time calculation** in `BlurManager.swift` for schedule logic
- **Acceleration curves** in `ModeType.swift` for custom curves

## Permissions

The app may need **Screen Recording** permission to create overlays. macOS will prompt you automatically. Grant permission in System Settings → Privacy & Security → Screen Recording.

## Quitting the App

Since there's no dock icon, quit via:
- Activity Monitor (search for "SlowBlurn")
- Terminal: `killall SlowBlurn`
- Or add a quit option to the settings window (future enhancement)

