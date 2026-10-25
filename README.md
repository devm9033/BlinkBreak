# BlinkBreak 👁️

A beautifully crafted, ultra-lightweight native macOS menu bar app engineered to eliminate digital eye strain and dry eyes using the **20-20-20 rule** and gentle **micro-blink reminders**.

Designed following modern Apple Design Principles, featuring fluid Dynamic Island notch integration, an Apple Intelligence-style ambient edge glow, and tactile Force Touch haptics.

---

## Highlights

- ⚡ **Zero-Waste Performance:** **0.0% idle CPU** and only **~12 MB RAM**. Zero background string churn and macOS kernel timer coalescing for maximum battery life.
- 🏝️ **Dynamic Island Liquid Pill:** Floats seamlessly 8pt beneath your MacBook hardware notch with an organic internal fluid aurora light wave and adaptive obsidian/crystal glass styling.
- ✨ **Subtle Perimeter Edge Glow:** An Apple Intelligence-inspired ambient aurora glow along your screen bezels reminds you to blink without ever obstructing your work or center windows.
- 🛡️ **Zero Work Interruption:** Screen effects run with `ignoresMouseEvents = true`—you will never drop keyboard focus, miss a keystroke, or have mouse clicks blocked.
- 🎬 **Smart Video & Display Sleep Detection:** Detects active video playback across Safari, Chrome, Arc, Brave, Firefox, VLC, QuickTime, IINA, and more. Independently pause eye breaks, blink nudges, or both. Timers automatically freeze when your Mac screen sleeps or your MacBook lid is closed.
- 📳 **Tactile Force Touch Haptics:** Subtle haptic alignment ticks when touching the floating pill, dismissing alerts, or snapping interval sliders.
- 🔒 **100% Private & Offline:** Zero analytics, zero telemetry, zero network permissions. Runs purely on-device.

---

## Features

### 1. Eye Rest Break (The 20-20-20 Rule)
Every 20 minutes, gaze at an object 20 feet away for 20 seconds to relax your eye ciliary muscles.
- **Frosted Glass Rest Plaque:** A clean, static card with a luminous gradient countdown ring and bold, direct guidance (*"Look 20 feet away"*).
- **Ambient Light Halo:** A soft, continuously revolving multi-hue ambient halo diffused behind the card perimeter.
- **Quick Controls:** Easy **Snooze (5m)** and **Skip (`Esc`)** buttons with tactile press responses.

### 2. Micro-Blink Reminders (Dry Eye Prevention)
Staring at screens reduces your natural blink rate by up to 66%, leading to dry, fatigued eyes.
- **Zen Liquid Glass Pill:** Drops smoothly from the MacBook notch with an internal multi-axis aurora wave (Electric Cyan, Indigo, Apple Rose, Mint).
- **Subtle Perimeter Edge Glow:** A non-intrusive ambient light sweep along the display edges draws gentle peripheral awareness to blink.
- **Adaptive Appearance:** Automatically morphs between Obsidian Liquid Glass in Dark Mode and White Crystal Glass in Light Mode.
- **Frosted Dismiss Button:** Tactile circular cut symbol to instantly dismiss the pill, or let it auto-retract after 5 seconds.

### 3. Smart Detection & Power Coalescing
- **Media Playback Guard:** Queries IOKit power assertions to know when you're watching videos or movies. Configurable per reminder type in Preferences.
- **Display Sleep Freezing:** Timers pause immediately when your display goes to sleep or you lock your Mac, preventing phantom breaks when you're away.
- **Zero Closed-Menu Allocations:** Countdown strings are only formatted when the menu bar dropdown is actually open, saving over 86,000 background string allocations daily.
- **XNU Kernel Timer Coalescing:** 100ms tolerance allows macOS to bundle timer wakeups with other system activity, keeping CPU cores in deep sleep states.

---

## System Requirements

- **Operating System:** macOS 13.0 (Ventura) or later (macOS Sonoma & Sequoia fully supported).
- **Architecture:** Apple Silicon (M1/M2/M3/M4) and Intel Macs.
- **Permissions:** None required.

---

## Download & Installation

### Option 1: Direct Download (Prebuilt)
1. Download **`BlinkBreak-macOS.zip`** from the [Releases](https://github.com/devm9033/BlinkBreak/releases) page.
2. Unzip the archive and drag **`BlinkBreak.app`** into your **`/Applications`** folder.
3. Open **BlinkBreak** from Launchpad or Spotlight (`⌘ Space`).

> [!NOTE]
> **macOS Gatekeeper Note (Unverified Developer):**  
> Because this is an open-source application distributed outside the Mac App Store, macOS may show a prompt stating that the developer cannot be verified.  
> 
> **To open:**  
> **Right-click (or Control-click)** `BlinkBreak.app` in Finder and select **Open** → click **Open**.  
> *Or run this one-line command in Terminal:*  
> ```bash
> xattr -cr /Applications/BlinkBreak.app
> ```

---

## Build from Source

Requirements: Xcode Command Line Tools (`xcode-select --install`).

```bash
# 1. Clone repository
git clone https://github.com/devm9033/BlinkBreak.git
cd BlinkBreak

# 2. Build and package release application
./build.sh

# 3. Launch application
open build/BlinkBreak.app
```

To run unit tests:
```bash
swift test
```

---

## Keyboard Shortcuts & Menu Controls

| Action | Shortcut / Access | Description |
| :--- | :--- | :--- |
| **Open Menu** | Click 👁 in Menu Bar | Displays live countdowns and quick triggers |
| **Take Break Now** | `⌘ B` | Manually triggers an Eye Rest Break |
| **Blink Reminder Now** | `⌘ L` | Manually triggers the Notch Pill & Edge Glow |
| **Preferences** | `⌘ ,` | Configure intervals, sounds, video detection, and glow |
| **Pause Reminders** | Submenu in Menu Bar | Pause for 15m, 30m, 1h, or until tomorrow |
| **Skip Active Break** | `Esc` | Instantly dismisses the fullscreen rest break |

---

## Architecture Overview

```
BlinkBreak/
├── Package.swift                             # Swift Package Manager manifest
├── build.sh                                  # Release build & code-signing script
├── generate_icon.swift                       # CoreGraphics app icon generator
├── Sources/BlinkBreak/
│   ├── BlinkBreak.swift                      # @main entry point & NSApplication bootstrap
│   ├── AppDelegate.swift                     # App lifecycle & status bar initialization
│   ├── Controllers/
│   │   ├── MenuBarController.swift           # NSStatusItem, NSMenuDelegate & zero-waste ticker
│   │   ├── BlinkToastController.swift        # Dynamic Island floating panel below hardware notch
│   │   ├── BlinkScreenEffectController.swift # Click-through transparent perimeter glow overlay
│   │   ├── BreakOverlayController.swift      # Fullscreen eye rest window manager
│   │   └── SettingsWindowController.swift    # Preferences window controller
│   ├── Models/
│   │   └── AppSettings.swift                 # UserDefaults persistence & live reactive settings
│   ├── Services/
│   │   ├── BreakManager.swift                # Core timer state engine & display sleep handler
│   │   ├── VideoPlaybackDetector.swift       # IOKit assertion scanner & display sleep detector
│   │   ├── HapticManager.swift               # NSHapticFeedbackManager trackpad tactility
│   │   └── SoundManager.swift                # NSSound chimes and notifications
│   └── Views/
│       ├── BlinkToastView.swift              # Liquid Glass pill with fluid aurora wave
│       ├── BlinkScreenEffectView.swift       # Apple Intelligence perimeter edge glow
│       ├── BreakOverlayView.swift            # Eye rest card with ambient revolving halo
│       ├── SettingsView.swift                # Preferences UI with interactive sliders
│       └── AppleTactileButtonStyle.swift     # Tactile spring button styles
└── Tests/BlinkBreakTests/
    └── BlinkBreakTests.swift                 # Comprehensive Swift Testing suite (14 tests)
```

---

## License

This project is licensed under the **MIT License**. Free and open source for everyone.
