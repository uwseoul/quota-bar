[한국어 버전 (README_KR.md)](./README_KR.md)

# GLM Bar 🚀

A lightweight and powerful macOS menu bar application to monitor your **Zhipu AI (z.ai) Coding Plan** usage in real-time.

![App UI Sample](https://github.com/uwseoul/glm-bar/raw/main/screenshot_placeholder.png) 
*(UI Example: iStat Menus style 2-row layout)*

## ✨ Key Features

- **iStat Menus Style UI**: Optimized 2-row vertical layout (Label/Value) for the menu bar.
- **Multi-Quota Monitoring**: Track 5-Hour (5H), Weekly (WK), and Monthly (MO) usage at a glance.
- **Multiple Display Modes**: Choose between Percentage (%) or intuitive Bar Graph mode.
- **Privacy Focused**: Your API Key is NOT stored in the source code; it's kept locally and securely on your Mac using `UserDefaults`.
- **Launch at Login**: Option to automatically start the app when you log in.
- **Native Performance**: Built with Swift/SwiftUI for extremely low CPU and memory footprint.

## 🛠 Installation & Usage

### 1. Download App (Recommended) - `.app` Bundle
The easiest way to use the app. Works like any other macOS application.
1. Download `GLMBar.zip` from the [Releases](https://github.com/uwseoul/glm-bar/releases) page.
2. Extract the ZIP and move `GLMBar.app` to your **Applications** folder.
3. Launch the app. (If you see an "Unidentified Developer" warning, right-click the app and select 'Open'.)

### 2. Download Terminal Binary
1. Download `glm-bar-macos.tar.gz` from the Releases page.
2. Extract and run via terminal: `chmod +x glm-bar && ./glm-bar &`

### 3. Build from Source
If you prefer to build it yourself, run the following in your terminal:

```bash
swiftc -o glm-bar Storage.swift UsageFetcher.swift GLMBarApp.swift -framework SwiftUI -framework AppKit
./glm-bar &
```

## ⚙️ How to Setup
1. Click the menu bar icon to open the popup.
2. Click the **Settings...** button at the bottom.
3. Enter your **Z.ai API Key** and select your platform (`z.ai` or `bigmodel.cn`).
4. Toggle your preferred display style and quota visibility.

## 📝 Tech Stack
- **Language**: Swift
- **Framework**: SwiftUI, AppKit (CoreGraphics rendering)
- **Status**: Active Development

## 📄 License
MIT License

---
*Created with ❤️ for GLM Coding Plan users.*
