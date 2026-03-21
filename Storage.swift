import Foundation
import SwiftUI

enum GLMPlatform: String, CaseIterable, Identifiable {
    case zai = "z.ai"
    case bigmodel = "bigmodel.cn"
    var id: String { self.rawValue }
    var baseURL: String {
        switch self {
        case .zai: return "https://api.z.ai"
        case .bigmodel: return "https://bigmodel.cn"
        }
    }
}

enum DisplayStyle: String, CaseIterable, Identifiable {
    case percent = "Percent (%)"
    case graph = "Graph (Bar)"
    case speed = "Speed (Rate)"
    var id: String { self.rawValue }
}

enum SpeedStatus {
    case fast
    case normal
    case slow
    
    var color: NSColor {
        switch self {
        case .fast: return NSColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
        case .normal: return NSColor(red: 0.12, green: 0.39, blue: 0.93, alpha: 1.0)
        case .slow: return NSColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0)
        }
    }
}

enum DarkMode: String, CaseIterable, Identifiable {
    case auto = "Auto (System)"
    case light = "Light"
    case dark = "Dark"
    var id: String { self.rawValue }
}

class Storage: ObservableObject {
    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: "GLM_API_KEY") }
    }
    @Published var selectedPlatform: GLMPlatform {
        didSet { UserDefaults.standard.set(selectedPlatform.rawValue, forKey: "GLM_PLATFORM") }
    }
    @Published var displayStyle: DisplayStyle {
        didSet { UserDefaults.standard.set(displayStyle.rawValue, forKey: "GLM_DISPLAY_STYLE") }
    }
    @Published var show5h: Bool {
        didSet { UserDefaults.standard.set(show5h, forKey: "GLM_SHOW_5H") }
    }
    @Published var showWeekly: Bool {
        didSet { UserDefaults.standard.set(showWeekly, forKey: "GLM_SHOW_WEEKLY") }
    }
    @Published var showMonthly: Bool {
        didSet { UserDefaults.standard.set(showMonthly, forKey: "GLM_SHOW_MONTHLY") }
    }
    @Published var launchAtLogin: Bool {
        didSet { 
            UserDefaults.standard.set(launchAtLogin, forKey: "GLM_LAUNCH_AT_LOGIN")
            updateLaunchAgent(enabled: launchAtLogin)
        }
    }
    @Published var darkMode: DarkMode {
        didSet { 
            UserDefaults.standard.set(darkMode.rawValue, forKey: "GLM_DARK_MODE")
            applyAppearance()
        }
    }
    
    init() {
        self.apiKey = UserDefaults.standard.string(forKey: "GLM_API_KEY") ?? ""
        let platformRaw = UserDefaults.standard.string(forKey: "GLM_PLATFORM") ?? GLMPlatform.zai.rawValue
        self.selectedPlatform = GLMPlatform(rawValue: platformRaw) ?? .zai
        let styleRaw = UserDefaults.standard.string(forKey: "GLM_DISPLAY_STYLE") ?? DisplayStyle.percent.rawValue
        self.displayStyle = DisplayStyle(rawValue: styleRaw) ?? .percent
        self.show5h = UserDefaults.standard.object(forKey: "GLM_SHOW_5H") as? Bool ?? true
        self.showWeekly = UserDefaults.standard.object(forKey: "GLM_SHOW_WEEKLY") as? Bool ?? true
        self.showMonthly = UserDefaults.standard.object(forKey: "GLM_SHOW_MONTHLY") as? Bool ?? true
        
        let shouldLaunch = UserDefaults.standard.object(forKey: "GLM_LAUNCH_AT_LOGIN") as? Bool ?? false
        let darkModeRaw = UserDefaults.standard.string(forKey: "GLM_DARK_MODE") ?? DarkMode.auto.rawValue
        self.darkMode = DarkMode(rawValue: darkModeRaw) ?? .auto
        self.launchAtLogin = shouldLaunch
    }
    
    func applyAppearance() {
        let appearance: NSAppearance? = {
            switch darkMode {
            case .auto: return nil
            case .light: return NSAppearance(named: .aqua)
            case .dark: return NSAppearance(named: .darkAqua)
            }
        }()
        NSApplication.shared.appearance = appearance
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
            
            let dict: [String: Any] = [
                "Label": "com.zhipu.glmbar",
                "ProgramArguments": [executablePath],
                "RunAtLoad": true,
                "StandardOutPath": "/dev/null",
                "StandardErrorPath": "/dev/null"
            ]
            (dict as NSDictionary).write(to: plistPath, atomically: true)
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
        case ("TIME_LIMIT", 5): return "Monthly MCP"
        case ("TOKENS_LIMIT", 3): return "5 Hours Quota"
        case ("TOKENS_LIMIT", 6): return "Weekly Quota"
        default: return "\(type ?? "?") (\(unit ?? 0))"
        }
    }
    var usagePercent: Double { Double(percentage ?? 0) / 100.0 }
    var resetTimeSeconds: Int? {
        guard let nextResetTime = nextResetTime else { return nil }
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let diff = nextResetTime - now
        return diff > 0 ? Int(diff / 1000) : nil
    }
    
    var totalDurationSeconds: Int {
        switch (type, unit) {
        case ("TOKENS_LIMIT", 3): return 5 * 60 * 60
        case ("TOKENS_LIMIT", 6): return 7 * 24 * 60 * 60
        case ("TIME_LIMIT", 5): return 30 * 24 * 60 * 60
        default: return 24 * 60 * 60
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
}
