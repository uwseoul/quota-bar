import AppKit
import Foundation
import SwiftUI

enum GLMPlatform: String, CaseIterable, Identifiable {
    case zai = "z.ai"
    case bigmodel = "bigmodel.cn"

    var id: String { rawValue }

    var baseURL: String {
        switch self {
        case .zai:
            return "https://api.z.ai"
        case .bigmodel:
            return "https://bigmodel.cn"
        }
    }
}

enum DisplayStyle: String, CaseIterable, Identifiable {
    case percent = "Percent (%)"
    case graph = "Graph (Bar)"
    case speed = "Speed (Rate)"

    var id: String { rawValue }
}

enum MenuBarMode: String, CaseIterable, Identifiable {
    case highest = "A) Highest Usage"
    case first = "B) First Quota of Each Platform"
    case onePerPlatform = "C) One Per Platform"
    case manual = "D) Manual Select"

    var id: String { rawValue }
}

enum SpeedStatus {
    case fast
    case normal
    case slow

    var color: NSColor {
        switch self {
        case .fast:
            return NSColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
        case .normal:
            return NSColor(red: 0.12, green: 0.39, blue: 0.93, alpha: 1.0)
        case .slow:
            return NSColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0)
        }
    }
}

enum DarkMode: String, CaseIterable, Identifiable {
    case auto = "Auto (System)"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }
}

struct QuotaEntry: Identifiable {
    let id: String
    let platformId: String
    let name: String
    let usagePercent: Double
    let usage: Int?
    let total: Int?
    let resetSeconds: Int?
    let totalDurationSeconds: Int?

    var speedStatus: SpeedStatus {
        guard let resetSeconds = resetSeconds, resetSeconds > 0,
              let totalDuration = totalDurationSeconds, totalDuration > 0 else {
            if usagePercent > 0.8 { return .fast }
            if usagePercent < 0.3 { return .slow }
            return .normal
        }

        let elapsedSeconds = totalDuration - resetSeconds
        let elapsedPercent = Double(elapsedSeconds) / Double(totalDuration)
        let remainingTimePercent = 1.0 - elapsedPercent
        let remainingUsagePercent = 1.0 - usagePercent

        if remainingUsagePercent < remainingTimePercent * 0.5 {
            return .fast
        } else if remainingUsagePercent > remainingTimePercent * 1.3 {
            return .slow
        } else {
            return .normal
        }
    }
}

struct PlatformResult {
    var entries: [QuotaEntry]
    var error: String?
    var isLoading: Bool
}

@MainActor
final class Storage: ObservableObject {
    private enum Keys {
        static let legacyAPIKey = "GLM_API_KEY"
        static let legacyPlatform = "GLM_PLATFORM"
        static let legacyDisplayStyle = "GLM_DISPLAY_STYLE"
        static let legacyShow5h = "GLM_SHOW_5H"
        static let legacyShowWeekly = "GLM_SHOW_WEEKLY"
        static let legacyShowMonthly = "GLM_SHOW_MONTHLY"
        static let legacyLaunchAtLogin = "GLM_LAUNCH_AT_LOGIN"
        static let legacyDarkMode = "GLM_DARK_MODE"
        static let apiKeys = "QB_API_KEYS"
        static let enabledPlatforms = "QB_ENABLED_PLATFORMS"
        static let menuBarMode = "QB_MENU_BAR_MODE"
        static let visibleQuotas = "QB_VISIBLE_QUOTAS"
        static let alwaysOnTop = "QB_ALWAYS_ON_TOP"
    }

    private let defaults = UserDefaults.standard
    private var isSyncingAPIState = false

    @Published var apiKey: String {
        didSet {
            defaults.set(apiKey, forKey: Keys.legacyAPIKey)
            syncDictionaryAPIKey(platformId: "glm", value: apiKey)
        }
    }

    @Published var apiKeys: [String: String] {
        didSet {
            defaults.set(apiKeys, forKey: Keys.apiKeys)
            syncLegacyAPIKeyFromDictionary()
        }
    }

    @Published var enabledPlatforms: [String: Bool] {
        didSet {
            defaults.set(enabledPlatforms, forKey: Keys.enabledPlatforms)
        }
    }

    @Published var selectedPlatform: GLMPlatform {
        didSet {
            defaults.set(selectedPlatform.rawValue, forKey: Keys.legacyPlatform)
        }
    }

    @Published var displayStyle: DisplayStyle {
        didSet {
            defaults.set(displayStyle.rawValue, forKey: Keys.legacyDisplayStyle)
        }
    }

    @Published var show5h: Bool {
        didSet {
            defaults.set(show5h, forKey: Keys.legacyShow5h)
        }
    }

    @Published var showWeekly: Bool {
        didSet {
            defaults.set(showWeekly, forKey: Keys.legacyShowWeekly)
        }
    }

    @Published var showMonthly: Bool {
        didSet {
            defaults.set(showMonthly, forKey: Keys.legacyShowMonthly)
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.legacyLaunchAtLogin)
            updateLaunchAgent(enabled: launchAtLogin)
        }
    }

    @Published var darkMode: DarkMode {
        didSet {
            defaults.set(darkMode.rawValue, forKey: Keys.legacyDarkMode)
            applyAppearance()
        }
    }

    @Published var menuBarMode: MenuBarMode {
        didSet {
            defaults.set(menuBarMode.rawValue, forKey: Keys.menuBarMode)
        }
    }

    @Published var visibleQuotas: Set<String> {
        didSet {
            defaults.set(Array(visibleQuotas), forKey: Keys.visibleQuotas)
        }
    }

    @Published var alwaysOnTop: Bool {
        didSet {
            defaults.set(alwaysOnTop, forKey: Keys.alwaysOnTop)
        }
    }

    init() {
        let storedAPIKeys = defaults.dictionary(forKey: Keys.apiKeys) as? [String: String]
        let legacyAPIKey = defaults.string(forKey: Keys.legacyAPIKey) ?? ""
        let resolvedAPIKeys: [String: String]

        if let storedAPIKeys {
            resolvedAPIKeys = storedAPIKeys
        } else if !legacyAPIKey.isEmpty {
            resolvedAPIKeys = ["glm": legacyAPIKey]
            defaults.set(resolvedAPIKeys, forKey: Keys.apiKeys)
        } else {
            resolvedAPIKeys = [:]
        }

        self.apiKeys = resolvedAPIKeys
        self.apiKey = resolvedAPIKeys["glm"] ?? legacyAPIKey

        let enabledDefaults = defaults.dictionary(forKey: Keys.enabledPlatforms) as? [String: Bool]
        self.enabledPlatforms = enabledDefaults ?? ["glm": true, "minimax": false, "codex": false, "opencodego": false]

        let platformRaw = defaults.string(forKey: Keys.legacyPlatform) ?? GLMPlatform.zai.rawValue
        self.selectedPlatform = GLMPlatform(rawValue: platformRaw) ?? .zai

        let styleRaw = defaults.string(forKey: Keys.legacyDisplayStyle) ?? DisplayStyle.percent.rawValue
        self.displayStyle = DisplayStyle(rawValue: styleRaw) ?? .percent

        self.show5h = defaults.object(forKey: Keys.legacyShow5h) as? Bool ?? true
        self.showWeekly = defaults.object(forKey: Keys.legacyShowWeekly) as? Bool ?? true
        self.showMonthly = defaults.object(forKey: Keys.legacyShowMonthly) as? Bool ?? true

        let shouldLaunch = defaults.object(forKey: Keys.legacyLaunchAtLogin) as? Bool ?? false
        let darkModeRaw = defaults.string(forKey: Keys.legacyDarkMode) ?? DarkMode.auto.rawValue
        self.darkMode = DarkMode(rawValue: darkModeRaw) ?? .auto
        self.launchAtLogin = shouldLaunch

        let menuBarModeRaw = defaults.string(forKey: Keys.menuBarMode) ?? MenuBarMode.highest.rawValue
        self.menuBarMode = MenuBarMode(rawValue: menuBarModeRaw) ?? .highest

        let storedVisibleQuotas = defaults.array(forKey: Keys.visibleQuotas) as? [String]
        self.visibleQuotas = Set(storedVisibleQuotas ?? [])

        self.alwaysOnTop = defaults.object(forKey: Keys.alwaysOnTop) as? Bool ?? false

        if defaults.object(forKey: Keys.enabledPlatforms) == nil {
            defaults.set(enabledPlatforms, forKey: Keys.enabledPlatforms)
        }
    }

    func apiKey(for platformId: String) -> String {
        if platformId == "opencodego" {
            let workspace = apiKeys["opencodego_workspace"] ?? ""
            let cookie = apiKeys["opencodego_cookie"] ?? ""
            if workspace.isEmpty && cookie.isEmpty { return "" }
            return "\(workspace):\(cookie)"
        }
        return apiKeys[platformId] ?? ""
    }

    func isPlatformEnabled(_ platformId: String) -> Bool {
        enabledPlatforms[platformId] ?? false
    }

    func visibleMenuBarEntries(from entries: [QuotaEntry]) -> [QuotaEntry] {
        let enabled = enabledPlatforms.filter { $0.value }.map(\.key)
        let enabledEntries = entries.filter { enabled.contains($0.platformId) }

        switch menuBarMode {
        case .highest:
            if let candidate = enabledEntries.max(by: { $0.usagePercent < $1.usagePercent }) {
                return [candidate]
            }
            return Array(enabledEntries.prefix(1))

        case .first:
            let grouped = Dictionary(grouping: enabledEntries, by: { $0.platformId })
            return grouped.compactMap { _, platformEntries in
                platformEntries.first
            }

        case .onePerPlatform:
            let grouped = Dictionary(grouping: enabledEntries, by: { $0.platformId })
            return grouped.compactMap { _, platformEntries in
                platformEntries.max(by: { $0.usagePercent < $1.usagePercent })
            }

        case .manual:
            let manualEntries = enabledEntries.filter { visibleQuotas.contains($0.id) }
            return manualEntries.isEmpty ? Array(enabledEntries.prefix(1)) : manualEntries
        }
    }

    func applyAppearance() {
        let appearance: NSAppearance? = {
            switch darkMode {
            case .auto:
                return nil
            case .light:
                return NSAppearance(named: .aqua)
            case .dark:
                return NSAppearance(named: .darkAqua)
            }
        }()

        NSApplication.shared.appearance = appearance
    }

    private func syncDictionaryAPIKey(platformId: String, value: String) {
        guard !isSyncingAPIState else { return }

        isSyncingAPIState = true
        var updated = apiKeys
        updated[platformId] = value
        apiKeys = updated
        isSyncingAPIState = false
    }

    private func syncLegacyAPIKeyFromDictionary() {
        guard !isSyncingAPIState else { return }

        isSyncingAPIState = true
        let glmAPIKey = apiKeys["glm"] ?? ""
        if apiKey != glmAPIKey {
            apiKey = glmAPIKey
        }
        defaults.set(glmAPIKey, forKey: Keys.legacyAPIKey)
        isSyncingAPIState = false
    }

    private func updateLaunchAgent(enabled: Bool) {
        let launchAgentDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents")
        let plistPath = launchAgentDir.appendingPathComponent("com.zhipu.glmbar.plist")

        if enabled {
            try? FileManager.default.createDirectory(at: launchAgentDir, withIntermediateDirectories: true)
            var currentPath = ProcessInfo.processInfo.arguments[0]
            if !currentPath.hasPrefix("/") {
                currentPath = FileManager.default.currentDirectoryPath + "/" + currentPath
            }

            let executablePath = URL(fileURLWithPath: currentPath).standardizedFileURL.path
            let plistContents: [String: Any] = [
                "Label": "com.zhipu.glmbar",
                "ProgramArguments": [executablePath],
                "RunAtLoad": true,
                "StandardOutPath": "/dev/null",
                "StandardErrorPath": "/dev/null"
            ]

            (plistContents as NSDictionary).write(to: plistPath, atomically: true)
        } else {
            try? FileManager.default.removeItem(at: plistPath)
        }
    }
}

struct GLMUsageResponse: Codable {
    let code: Int
    let msg: String
    let data: GLMUsageData
}

struct GLMUsageData: Codable {
    let limits: [GLMLimit]?
    let level: String?
}

struct GLMLimit: Codable, Identifiable {
    var id: String { "\(type ?? "unknown")_\(unit ?? 0)_\(number ?? 0)" }

    let type: String?
    let unit: Int?
    let number: Int?
    let percentage: Int?
    let nextResetTime: Int64?
    let usage: Int?
    let remaining: Int?

    var name: String {
        switch (type, unit) {
        case ("TIME_LIMIT", 5):
            return "Monthly MCP"
        case ("TOKENS_LIMIT", 3):
            return "5 Hours Quota"
        case ("TOKENS_LIMIT", 6):
            return "Weekly Quota"
        default:
            return "\(type ?? "?") (\(unit ?? 0))"
        }
    }

    var usagePercent: Double {
        Double(percentage ?? 0) / 100.0
    }

    var resetTimeSeconds: Int? {
        guard let nextResetTime else { return nil }
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let diff = nextResetTime - now
        return diff > 0 ? Int(diff / 1000) : nil
    }

    var totalDurationSeconds: Int {
        switch (type, unit) {
        case ("TOKENS_LIMIT", 3):
            return 5 * 60 * 60
        case ("TOKENS_LIMIT", 6):
            return 7 * 24 * 60 * 60
        case ("TIME_LIMIT", 5):
            return 30 * 24 * 60 * 60
        default:
            return 24 * 60 * 60
        }
    }

    var speedStatus: SpeedStatus {
        guard let remaining = resetTimeSeconds else { return .normal }

        let total = totalDurationSeconds
        let elapsed = max(total - remaining, 1)
        let elapsedPercent = Double(elapsed) / Double(total)

        if elapsedPercent < 0.01 { return .normal }

        let speedRatio = usagePercent / elapsedPercent

        if speedRatio > 1.3 { return .fast }
        if speedRatio < 0.7 { return .slow }
        return .normal
    }

    var speedPercent: Double {
        guard let remaining = resetTimeSeconds else { return 0.5 }

        let total = totalDurationSeconds
        let elapsed = max(total - remaining, 1)
        let elapsedPercent = Double(elapsed) / Double(total)

        if elapsedPercent < 0.01 { return 0.5 }

        let speedRatio = usagePercent / elapsedPercent
        return min(max(speedRatio, 0), 2) / 2.0
    }

    var total: Int? {
        guard let usage, let remaining else { return nil }
        return usage + remaining
    }

    func toQuotaEntry(platformId: String) -> QuotaEntry {
        QuotaEntry(
            id: id,
            platformId: platformId,
            name: name,
            usagePercent: usagePercent,
            usage: usage,
            total: total,
            resetSeconds: resetTimeSeconds,
            totalDurationSeconds: totalDurationSeconds
        )
    }
}
