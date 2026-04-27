[한국어 버전 (README_KR.md)](./README_KR.md)

# Quota Bar 🚀

A lightweight and powerful macOS menu bar application to monitor your **AI coding plan usage** across multiple platforms in real-time.

**Previously known as GLM Bar** — now supports 4 platforms!

![App UI Sample](https://github.com/uwseoul/quota-bar/raw/main/screenshot_placeholder.png) 
*(UI Example: Multi-platform card layout)*

## ✨ Key Features

- **Multi-Platform Support**: Monitor usage across **GLM (z.ai)**, **MiniMax**, **OpenAI Codex**, and **OpenCode Go** — all in one app.
- **iStat Menus Style UI**: Optimized vertical layout for the menu bar.
- **Multi-Quota Monitoring**: Track 5-Hour (5H), Weekly (WK), Monthly (MO), Rolling, 7D, and more.
- **Three Display Modes**:
  - **Percent (%)**: Shows usage percentage
  - **Graph (Bar)**: Visual bar graph
  - **Speed (Signal)**: Traffic light indicator (Green/Yellow/Red) for usage speed
- **Four Menu Bar Modes**:
  - **Highest Usage**: Show the single highest usage quota across all platforms
  - **First Quota per Platform**: Show the first quota from each active platform
  - **One per Platform**: Show the highest usage quota from each platform
  - **Manual Select**: Choose exactly which quotas appear in the menu bar
- **Speed-Based Color Indication**:
  - 🔴 Red (Fast): Rapid usage — risk of exceeding quota
  - 🟡 Yellow (Normal): Average usage speed
  - 🟢 Green (Slow): Slow usage — safe margin
- **Dark Mode Support**: White text adapts to both dark and light menu bar themes
- **Card-Style Popover**: Platform usage displayed in clean, separated cards
- **Right-Click for Settings**: Quick access to settings via right-click on the menu bar icon
- **Privacy Focused**: Your API Key is NOT stored in the source code; it's kept locally and securely on your Mac using `UserDefaults`.
- **Launch at Login**: Option to automatically start the app when you log in.
- **Native Performance**: Built with Swift/SwiftUI for extremely low CPU and memory footprint.

## 🛠 Installation & Usage

### 1. Download App (Recommended) - `.app` Bundle
The easiest way to use the app. Works like any other macOS application.
1. Download `QuotaBar.zip` from the [Releases](https://github.com/uwseoul/quota-bar/releases) page.
2. Extract the ZIP and move `QuotaBar.app` to your **Applications** folder.
3. Launch the app. (If you see an "Unidentified Developer" warning, right-click the app and select 'Open'.)

### 2. Download Terminal Binary
1. Download `quota-bar-macos.tar.gz` from the Releases page.
2. Extract and run via terminal: `chmod +x quota-bar && ./quota-bar &`

### 3. Build from Source
If you prefer to build it yourself, run the following in your terminal:

```bash
swiftc QuotaBarApp.swift Models/Storage.swift Services/UsageFetcher.swift Services/GLMFetcher.swift Services/MiniMaxFetcher.swift Services/CodexFetcher.swift Services/OpenCodeGoFetcher.swift Views/ContentView.swift Views/SettingsView.swift Views/MenuBarRenderer.swift -o QuotaBar
```

Or use the build script:
```bash
./scripts/build-universal.sh
```

This creates a **Universal Binary** (works on both Intel and Apple Silicon Macs):
- `dist/quota-bar` - Terminal binary
- `dist/QuotaBar.app` - App bundle

**Requirements:** macOS 11.0 (Big Sur) or later

## ⚙️ Platform Setup

### GLM (z.ai / bigmodel.cn)
1. Open Settings from the popup.
2. Enter your **Z.ai API Key**.
3. Select your platform (`z.ai` or `bigmodel.cn`).

### MiniMax TokenPlan
1. Enable MiniMax in Settings → Platforms.
2. Enter your **MiniMax Token Plan API Key** (format: `sk-cp-...`).

### OpenAI Codex
1. Enable Codex in Settings → Platforms.
2. Make sure you have run `codex login` in your terminal.
3. The app automatically reads `~/.codex/auth.json` — no manual key entry needed.

### OpenCode Go
1. Enable OpenCode Go in Settings → Platforms.
2. Enter your **Workspace ID** (from the URL: `https://opencode.ai/workspace/{id}/go`).
3. Enter your **Auth Cookie** value (from browser DevTools → Application → Cookies → `auth`).
4. Click "연결 방법 보기" for detailed instructions.

## 🔄 Update Behavior

The app can check the latest GitHub release from inside the popup.

- Manual check: open app popup → `Check for Updates...`
- If a newer version exists, the app opens the GitHub Releases page
- Install updates by downloading the latest `QuotaBar.zip`

## 📝 Tech Stack
- **Language**: Swift
- **Framework**: SwiftUI, AppKit (CoreGraphics rendering)
- **Build**: Pure `swiftc` (no Xcode project, no SPM)
- **Status**: Active Development

## 📄 License
MIT License

---
*Created with ❤️ for AI coding plan users.*
