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
        self.launchAtLogin = shouldLaunch
        updateLaunchAgent(enabled: shouldLaunch)
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
    let limits: [GLMLimit]
    let level: String
}

struct GLMLimit: Codable, Identifiable {
    var id: String { "\(type)_\(unit)_\(number)" }
    let type: String
    let unit: Int
    let number: Int
    let percentage: Int
    let nextResetTime: Int64
    let usage: Int?
    let remaining: Int?
    
    var name: String {
        switch (type, unit) {
        case ("TIME_LIMIT", 5): return "Monthly MCP"
        case ("TOKENS_LIMIT", 3): return "5 Hours Quota"
        case ("TOKENS_LIMIT", 6): return "Weekly Quota"
        default: return "\(type) (\(unit))"
        }
    }
    var usagePercent: Double { Double(percentage) / 100.0 }
    var resetTimeSeconds: Int? {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let diff = nextResetTime - now
        return diff > 0 ? Int(diff / 1000) : nil
    }
}
