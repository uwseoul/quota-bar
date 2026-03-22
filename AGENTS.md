# AGENTS.md - Development Guidelines for GLM Bar

This document provides guidelines for agentic coding agents working on this repository.

## Project Overview

GLM Bar is a lightweight macOS menu bar application that monitors Zhipu AI (z.ai) coding plan usage in real-time. Built with Swift/SwiftUI.

- **Language**: Swift
- **Framework**: SwiftUI, AppKit (CoreGraphics)
- **Status**: Active Development

---

## Build Commands

### Build the App
```bash
swiftc GLMBarApp.swift Storage.swift UsageFetcher.swift -o GLMBar
```

### Run the App
```bash
./glm-bar &
```

### Build Release
```bash
swiftc GLMBarApp.swift Storage.swift UsageFetcher.swift -o GLMBar
zip -r GLMBar.zip GLMBar README.md README_KR.md
```

### GitHub Release Workflow
Builds automatically on tag push (`v*`):
```bash
swiftc GLMBarApp.swift Storage.swift UsageFetcher.swift -o GLMBar
zip -r GLMBar.zip GLMBar README.md README_KR.md
```

---

## Testing

**No formal test suite exists.** To verify changes:
1. Build with `swiftc` command above
2. Run the binary and verify menu bar functionality
3. Test with valid/invalid API keys
4. Test both platforms (z.ai, bigmodel.cn)

---

## Code Style Guidelines

### General Conventions
- Follow standard Swift naming: `camelCase` for variables/functions, `PascalCase` for types
- Use Swift's type inference when obvious, but prefer explicit types for public APIs
- Keep lines under 120 characters when practical

### Imports
```swift
import Foundation
import SwiftUI
import Combine
// Add AppKit only when needed for NSImage, NSApplication, etc.
```

### SwiftUI Patterns
- Use `@StateObject` for view model initialization
- Use `@EnvironmentObject` for dependency injection across views
- Use `@Published` for observable properties in ObservableObject classes

```swift
@StateObject private var storage = Storage()
@EnvironmentObject var storage: Storage
```

### State Management
- Use `@State` for local view state
- Use `@Binding` for two-way binding
- Use `@Published` + `@StateObject` for shared mutable state

### Error Handling
- Use optionals and `guard` statements for early returns
- Store errors in `@Published var lastError: String?`
- Provide user-friendly error messages (Korean in UI responses acceptable)

```swift
guard !apiKey.isEmpty else {
    self.lastError = "API Key가 설정되지 않았습니다."
    return
}
```

### Networking
- Use Combine's `URLSession.shared.dataTaskPublisher`
- Chain `.map()`, `.decode()`, `.receive(on:)`, `.sink()`
- Always handle both success and failure in `.sink`

```swift
URLSession.shared.dataTaskPublisher(for: request)
    .decode(type: GLMUsageResponse.self, decoder: JSONDecoder())
    .receive(on: DispatchQueue.main)
    .sink { completion in
        // Handle error
    } receiveValue: { response in
        // Handle success
    }
    .store(in: &cancellables)
```

### Menu Bar Apps
- Use `MenuBarExtra` with `.menuBarExtraStyle(.window)`
- Use CoreGraphics (`NSImage`) for custom menu bar rendering to avoid clipping issues
- Set `image.isTemplate = true` for dark/light mode adaptation

### Models & Codable
- Use `Codable` for all API response models
- Use `Identifiable` for collections in SwiftUI ForEach
- Use computed properties for derived values

```swift
struct GLMLimit: Codable, Identifiable {
    var id: String { "\(type ?? "unknown")_\(unit ?? 0)" }
    var usagePercent: Double { Double(percentage ?? 0) / 100.0 }
}
```

### UserDefaults Persistence
- Use didSet observers for automatic persistence
- Provide sensible defaults in initializers

```swift
@Published var apiKey: String {
    didSet { UserDefaults.standard.set(apiKey, forKey: "GLM_API_KEY") }
}

init() {
    self.apiKey = UserDefaults.standard.string(forKey: "GLM_API_KEY") ?? ""
}
```

---

## Project Structure

```
GLMBarApp.swift    # Main app entry, MenuBarExtra, Views
Storage.swift      # UserDefaults persistence, Models, Enums
UsageFetcher.swift # API calls, data fetching logic
```

---

## Common Tasks

### Adding a New Setting
1. Add property to `Storage` class with `@Published` and `didSet`
2. Add UI control in `SettingsView`
3. Default value in `Storage.init()`

### Adding a New API Endpoint
1. Add method to `UsageFetcher`
2. Create new Codable model struct if needed
3. Handle response in View via `@EnvironmentObject`

### Modifying Menu Bar Display
- Edit `MenuBarLabel` view in `GLMBarApp.swift`
- Use CoreGraphics for custom rendering
- Test both dark and light menu bar themes

---

## Known Limitations

- No unit/integration tests
- No Swift Package Manager or Xcode project (pure swiftc)
- No linting/formatting tools configured

---

## Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Swift Language Guide](https://docs.swift.org/swift-book/)
- [Menu Bar App Tutorial](https://developer.apple.com/documentation/swiftui/menu-bar-apps)
