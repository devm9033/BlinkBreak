# BlinkBreak 👁️

A lightweight, native macOS menu bar app designed to prevent digital eye strain and dry eyes using the 20-20-20 rule.

---

## Features

- **Eye Rest Break (20-20-20 Rule):** Beautiful frosted-glass card with a countdown ring reminding you to rest your eyes on distant objects. Includes **Snooze (5m)** and **Skip (Esc)**.
- **Dynamic Island Blink Nudge:** Floats right beneath your MacBook notch in a sleek, non-intrusive micro-capsule with an animated blinking eye and countdown.
- **Smart Video Detection (v2.0):** Automatically pauses the full-screen break timer when watching videos in browsers (Safari, Chrome, Arc, Edge) or media players (QuickTime, VLC, IINA). The notch blink nudge stays active so your eyes stay hydrated. Easily toggled in Preferences.
- **Ultra-Lightweight & Native:** Pure Swift and SwiftUI. Uses **0.0% idle CPU** and only **~23 MB RAM**.
- **Tactile & Fluid:** Physical spring animations, Force Touch trackpad haptics on sliders, and native macOS notification chimes.
- **Adaptive Appearance:** Automatically switches between Light and Dark mode with high-contrast typography.
- **100% Offline & Private:** Zero tracking, zero network permissions, zero background telemetry.

---

## Download & Installation

### Option 1: Direct Download (Prebuilt)
1. Download **`BlinkBreak-macOS.zip`** from the [Latest Release](https://github.com/USERNAME/BlinkBreak/releases).
2. Unzip the file and drag **`BlinkBreak.app`** into your **`/Applications`** folder.
3. Open **BlinkBreak** from Launchpad or Spotlight (`⌘ Space`).

> [!NOTE]
> **macOS Gatekeeper Note (Unverified Developer):**  
> Because this is an open-source indie app distributed outside the Mac App Store, macOS may show a prompt saying *"BlinkBreak cannot be opened because the developer cannot be verified"*.  
> 
> **To open:**  
> **Right-click (or Control-click)** `BlinkBreak.app` in Finder and select **Open** → click **Open**.  
> *Or run this one-line command in Terminal:*  
> ```bash
> xattr -cr /Applications/BlinkBreak.app
> ```

---

## Build from Source

Requirements: macOS 13.0+ and Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/USERNAME/BlinkBreak.git
cd BlinkBreak
./build.sh
open build/BlinkBreak.app
```

---

## Shortcuts & Controls

- **Menu Bar Icon:** Click the eye icon in the top menu bar to view remaining times or open **Preferences (`⌘,`)**.
- **Take Break Now:** `⌘B`
- **Blink Reminder Now:** `⌘L`
- **Skip Active Break:** `Esc`

---

## License

MIT License. Free and open source.
