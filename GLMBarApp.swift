import SwiftUI

@main
struct GLMBarApp: App {
    @StateObject private var storage = Storage()
    @StateObject private var fetcher = UsageFetcher()
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(storage)
                .environmentObject(fetcher)
        } label: {
            MenuBarLabel()
                .environmentObject(storage)
                .environmentObject(fetcher)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarLabel: View {
    @EnvironmentObject var storage: Storage
    @EnvironmentObject var fetcher: UsageFetcher
    
    var body: some View {
        if fetcher.limits.isEmpty {
            Text("GLM")
                .font(.system(size: 13, weight: .medium))
        } else {
            let img = createImage(for: getDisplayLimits(), style: storage.displayStyle)
            Image(nsImage: img)
        }
    }
    
    // CoreGraphics를 통해 이미지를 직접 그려 macOS 메뉴바 짤림 현상을 원천 방지합니다.
    private func createImage(for limits: [GLMLimit], style: DisplayStyle) -> NSImage {
        let height: CGFloat = 22
        let itemWidth: CGFloat = 36
        let totalWidth = max(itemWidth * CGFloat(limits.count), 20)
        let image = NSImage(size: NSSize(width: totalWidth, height: height))
        
        image.lockFocus()
        
        for (i, limit) in limits.enumerated() {
            let xOffset = CGFloat(i) * itemWidth
            
            // 상단 라벨 (크기: 9pt, 약간 투명)
            let labelStyle = NSMutableParagraphStyle()
            labelStyle.alignment = .center
            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 9, weight: .regular),
                .foregroundColor: NSColor.labelColor.withAlphaComponent(0.6),
                .paragraphStyle: labelStyle
            ]
            let labelStr = NSAttributedString(string: getShortLabel(for: limit.name), attributes: labelAttrs)
            // NSImage 좌표계는 좌측 하단이 (0,0)
            labelStr.draw(in: NSRect(x: xOffset, y: 11, width: itemWidth, height: 11))
            
            // 하단 수치 또는 분율 (Percent / Graph)
            if style == .percent {
                let valStyle = NSMutableParagraphStyle()
                valStyle.alignment = .center
                let valAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .bold),
                    .foregroundColor: NSColor.labelColor,
                    .paragraphStyle: valStyle
                ]
                let valStr = NSAttributedString(string: "\(Int(limit.usagePercent * 100))%", attributes: valAttrs)
                valStr.draw(in: NSRect(x: xOffset, y: 0, width: itemWidth, height: 12))
            } else {
                // 막대 그래프 직접 그리기
                let barWidth: CGFloat = 24
                let barHeight: CGFloat = 4
                let barX = xOffset + (itemWidth - barWidth) / 2
                let barY: CGFloat = 4
                
                let bgPath = NSBezierPath(roundedRect: NSRect(x: barX, y: barY, width: barWidth, height: barHeight), xRadius: 2, yRadius: 2)
                NSColor.labelColor.withAlphaComponent(0.2).setFill()
                bgPath.fill()
                
                let fillWidth = barWidth * CGFloat(min(max(limit.usagePercent, 0.05), 1.0))
                let fgPath = NSBezierPath(roundedRect: NSRect(x: barX, y: barY, width: fillWidth, height: barHeight), xRadius: 2, yRadius: 2)
                NSColor.labelColor.setFill() // Template 이미지에서는 색상 대신 대비/투명도로 구분됨
                fgPath.fill()
            }
        }
        
        image.unlockFocus()
        image.isTemplate = true // 다크/라이트 모드 자동 적응
        return image
    }
    
    private func getShortLabel(for name: String) -> String {
        if name.contains("5 Hours") { return "5H" } 
        if name.contains("Weekly") { return "WK" }
        if name.contains("Monthly") { return "MO" }
        return "QT"
    }
    
    private func getDisplayLimits() -> [GLMLimit] {
        var result: [GLMLimit] = []
        if storage.show5h, let q = fetcher.limits.first(where: { $0.name.contains("5 Hours") }) { result.append(q) }
        if storage.showWeekly, let q = fetcher.limits.first(where: { $0.name.contains("Weekly") }) { result.append(q) }
        if storage.showMonthly, let q = fetcher.limits.first(where: { $0.name.contains("Monthly") }) { result.append(q) }
        
        if result.isEmpty && !fetcher.limits.isEmpty {
             result = Array(fetcher.limits.prefix(3))
        }
        return result
    }
}

struct QuotaBar: View {
    let percent: Double
    let width: CGFloat = 20
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.primary.opacity(0.15))
                .frame(width: width, height: 6)
            RoundedRectangle(cornerRadius: 2)
                .fill(percent > 0.8 ? Color.orange : Color.blue)
                .frame(width: width * CGFloat(min(max(percent, 0.05), 1.0)), height: 6)
        }
    }
}
struct ContentView: View {
    @EnvironmentObject var storage: Storage
    @EnvironmentObject var fetcher: UsageFetcher
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 8) {
            if showingSettings {
                settingsHeader
                SettingsView()
                Divider()
                Button("Back to Usage") { showingSettings = false }
                    .buttonStyle(.bordered)
                    .padding(.bottom, 8)
            } else {
                usageHeader
                usageContent
                Divider()
                HStack {
                    Button("Settings...") { showingSettings = true }
                        .buttonStyle(.bordered)
                    Spacer()
                    Button("Quit") { NSApplication.shared.terminate(nil) }
                        .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .frame(width: 280)
        .padding(.top, 10)
        .onAppear {
            fetcher.fetch(apiKey: storage.apiKey, platform: storage.selectedPlatform)
            Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
                fetcher.fetch(apiKey: storage.apiKey, platform: storage.selectedPlatform)
            }
        }
    }
    
    private var usageHeader: some View {
        HStack {
            Text(storage.selectedPlatform.rawValue)
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
            Button(action: {
                fetcher.fetch(apiKey: storage.apiKey, platform: storage.selectedPlatform)
            }) {
                Image(systemName: fetcher.isLoading ? "arrow.clockwise.circle.fill" : "arrow.clockwise.circle")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }
    
    private var settingsHeader: some View {
        HStack {
            Text("Settings")
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var usageContent: some View {
        Group {
            if let error = fetcher.lastError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            } else if fetcher.limits.isEmpty {
                Text(fetcher.isLoading ? "Loading..." : "No data. Please set API Key in Settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 2) {
                    ForEach(fetcher.limits) { limit in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(limit.name)
                                    .font(.system(size: 11, weight: .semibold))
                                Spacer()
                                Text("\(Int(limit.usagePercent * 100))%")
                                    .font(.system(size: 11))
                                    .foregroundColor(limit.usagePercent > 0.8 ? .orange : .primary)
                            }
                            ProgressView(value: limit.usagePercent)
                                .scaleEffect(x: 1, y: 0.5)
                                .tint(limit.usagePercent > 0.8 ? .orange : .blue)
                            HStack {
                                if let reset = limit.resetTimeSeconds {
                                    Text("Reset in \(reset / 60)m").font(.system(size: 9)).foregroundColor(.secondary)
                                }
                                Spacer()
                                if let usage = limit.usage, let rem = limit.remaining {
                                    Text("\(usage) / \(usage + rem)").font(.system(size: 9)).foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var storage: Storage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Account API")
            Picker("Platform", selection: $storage.selectedPlatform) {
                ForEach(GLMPlatform.allCases) { platform in
                    Text(platform.rawValue).tag(platform)
                }
            }
            .pickerStyle(.segmented)
            
            SecureField("API Key", text: $storage.apiKey)
                .textFieldStyle(.roundedBorder)
            
            Divider().padding(.vertical, 4)
            
            SectionHeader(title: "Menu Bar Display")
            Picker("Style", selection: $storage.displayStyle) {
                ForEach(DisplayStyle.allCases) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.radioGroup)
            
            VStack(alignment: .leading, spacing: 4) {
                Toggle("5 Hours Quota", isOn: $storage.show5h)
                Toggle("Weekly Quota", isOn: $storage.showWeekly)
                Toggle("Monthly Quota", isOn: $storage.showMonthly)
            }
            .font(.caption)
            
            Divider().padding(.vertical, 2)
            
            Toggle("Launch at Login (Auto Start)", isOn: $storage.launchAtLogin)
                .font(.caption)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.secondary)
    }
}
