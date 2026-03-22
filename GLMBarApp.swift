import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let storage = Storage()
    private let fetcher = UsageFetcher()
    private let updaterController = UpdaterController()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem?
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        storage.applyAppearance()
        configurePopover()
        configureStatusItem()
        observeState()
        refreshUsage()
        startRefreshTimer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        refreshTimer?.invalidate()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 300, height: 500)
        popover.contentViewController = NSHostingController(
            rootView: ContentView()
                .environmentObject(storage)
                .environmentObject(fetcher)
                .environmentObject(updaterController)
        )
    }

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover(_:))
        statusItem.button?.imageScaling = .scaleProportionallyDown
        self.statusItem = statusItem
        updateStatusItem()
    }

    private func observeState() {
        storage.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateStatusItem()
                }
            }
            .store(in: &cancellables)

        fetcher.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateStatusItem()
                }
            }
            .store(in: &cancellables)
    }

    private func startRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshUsage()
            }
        }
    }

    private func refreshUsage() {
        fetcher.fetch(apiKey: storage.apiKey, platform: storage.selectedPlatform)
    }

    private func updateStatusItem() {
        guard let button = statusItem?.button else { return }

        if let image = MenuBarLabel.makeStatusImage(storage: storage, fetcher: fetcher) {
            button.image = image
            button.title = ""
            button.imagePosition = .imageOnly
        } else {
            button.image = nil
            button.title = "GLM"
            button.imagePosition = .noImage
        }
    }

    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
            return
        }

        guard let button = statusItem?.button else { return }
        NSApplication.shared.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
}

@main
struct GLMBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

struct MenuBarLabel: View {
    @EnvironmentObject var storage: Storage
    @EnvironmentObject var fetcher: UsageFetcher

    var body: some View {
        if let image = Self.makeStatusImage(storage: storage, fetcher: fetcher) {
            Image(nsImage: image)
        } else {
            Text("GLM")
                .font(.system(size: 13, weight: .medium))
        }
    }

    static func makeStatusImage(storage: Storage, fetcher: UsageFetcher) -> NSImage? {
        guard !fetcher.limits.isEmpty else { return nil }
        return createImage(for: getDisplayLimits(storage: storage, fetcher: fetcher), style: storage.displayStyle)
    }

    private static func createImage(for limits: [GLMLimit], style: DisplayStyle) -> NSImage {
        let height: CGFloat = 22
        let itemWidth: CGFloat = 36
        let totalWidth = max(itemWidth * CGFloat(limits.count), 20)
        let image = NSImage(size: NSSize(width: totalWidth, height: height))

        image.lockFocus()

        for (i, limit) in limits.enumerated() {
            let xOffset = CGFloat(i) * itemWidth

            let labelStyle = NSMutableParagraphStyle()
            labelStyle.alignment = .center
            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 9, weight: .regular),
                .foregroundColor: NSColor.labelColor.withAlphaComponent(0.6),
                .paragraphStyle: labelStyle
            ]
            let labelStr = NSAttributedString(string: getShortLabel(for: limit.name), attributes: labelAttrs)
            labelStr.draw(in: NSRect(x: xOffset, y: 11, width: itemWidth, height: 11))

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
            } else if style == .graph {
                let barWidth: CGFloat = 24
                let barHeight: CGFloat = 4
                let barX = xOffset + (itemWidth - barWidth) / 2
                let barY: CGFloat = 4

                let bgPath = NSBezierPath(roundedRect: NSRect(x: barX, y: barY, width: barWidth, height: barHeight), xRadius: 2, yRadius: 2)
                NSColor.labelColor.withAlphaComponent(0.2).setFill()
                bgPath.fill()

                let fillWidth = barWidth * CGFloat(min(max(limit.usagePercent, 0.05), 1.0))
                let fgPath = NSBezierPath(roundedRect: NSRect(x: barX, y: barY, width: fillWidth, height: barHeight), xRadius: 2, yRadius: 2)
                limit.speedStatus.color.setFill()
                fgPath.fill()
            } else if style == .speed {
                let barWidth: CGFloat = 24
                let barHeight: CGFloat = 4
                let barX = xOffset + (itemWidth - barWidth) / 2
                let barY: CGFloat = 4

                let bgPath = NSBezierPath(roundedRect: NSRect(x: barX, y: barY, width: barWidth, height: barHeight), xRadius: 2, yRadius: 2)
                NSColor.labelColor.withAlphaComponent(0.2).setFill()
                bgPath.fill()

                let fillWidth = barWidth * CGFloat(min(max(limit.usagePercent, 0.05), 1.0))
                let fgPath = NSBezierPath(roundedRect: NSRect(x: barX, y: barY, width: fillWidth, height: barHeight), xRadius: 2, yRadius: 2)
                limit.speedStatus.color.setFill()
                fgPath.fill()
                
                let speedIndicator = speedSymbol(for: limit.speedStatus)
                let speedAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 8, weight: .bold),
                    .foregroundColor: limit.speedStatus.color
                ]
                let speedStr = NSAttributedString(string: speedIndicator, attributes: speedAttrs)
                let speedSize = speedStr.size()
                speedStr.draw(at: NSPoint(x: xOffset + (itemWidth - speedSize.width) / 2, y: 0))
            }
        }

        image.unlockFocus()
        image.isTemplate = (style == .percent)
        return image
    }

    private static func speedSymbol(for status: SpeedStatus) -> String {
        switch status {
        case .fast: return "▲"
        case .normal: return "●"
        case .slow: return "▼"
        }
    }

    private static func getShortLabel(for name: String) -> String {
        if name.contains("5 Hours") { return "5H" }
        if name.contains("Weekly") { return "WK" }
        if name.contains("Monthly") { return "MO" }
        return "QT"
    }

    private static func getDisplayLimits(storage: Storage, fetcher: UsageFetcher) -> [GLMLimit] {
        var result: [GLMLimit] = []
        if storage.show5h, let limit = fetcher.limits.first(where: { $0.name.contains("5 Hours") }) { result.append(limit) }
        if storage.showWeekly, let limit = fetcher.limits.first(where: { $0.name.contains("Weekly") }) { result.append(limit) }
        if storage.showMonthly, let limit = fetcher.limits.first(where: { $0.name.contains("Monthly") }) { result.append(limit) }

        if result.isEmpty && !fetcher.limits.isEmpty {
            result = Array(fetcher.limits.prefix(3))
        }

        return result
    }
}

struct ContentView: View {
    @EnvironmentObject var storage: Storage
    @EnvironmentObject var fetcher: UsageFetcher
    @EnvironmentObject var updaterController: UpdaterController
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
                    Button("Check for Updates...") {
                        updaterController.checkForUpdates()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!updaterController.canCheckForUpdates)
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
                                HStack(spacing: 4) {
                                    speedBadge(for: limit.speedStatus)
                                    Text("\(Int(limit.usagePercent * 100))%")
                                        .font(.system(size: 11))
                                        .foregroundColor(limit.usagePercent > 0.8 ? .orange : .primary)
                                }
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.primary.opacity(0.15))
                                        .frame(height: 6)
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(speedColor(for: limit.speedStatus))
                                        .frame(width: geo.size.width * CGFloat(min(max(limit.usagePercent, 0.05), 1.0)), height: 6)
                                }
                            }
                            .frame(height: 6)
                            HStack {
                                if let reset = limit.resetTimeSeconds {
                                    Text("Reset in \(formatTime(reset))").font(.system(size: 9)).foregroundColor(.secondary)
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
    
    private func formatTime(_ seconds: Int) -> String {
        if seconds < 3600 {
            return "\(seconds / 60)m"
        } else if seconds < 86400 {
            return "\(seconds / 3600)h \((seconds % 3600) / 60)m"
        } else {
            return "\(seconds / 86400)d \((seconds % 86400) / 3600)h"
        }
    }
    
    private func speedBadge(for status: SpeedStatus) -> some View {
        HStack(spacing: 2) {
            Circle()
                .fill(speedColor(for: status))
                .frame(width: 6, height: 6)
            Text(speedLabel(for: status))
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(speedColor(for: status))
        }
    }
    
    private func speedLabel(for status: SpeedStatus) -> String {
        switch status {
        case .fast: return "FAST"
        case .normal: return "OK"
        case .slow: return "SLOW"
        }
    }
    
    private func speedColor(for status: SpeedStatus) -> Color {
        switch status {
        case .fast: return .red
        case .normal: return .blue
        case .slow: return .green
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var storage: Storage
    @EnvironmentObject var updaterController: UpdaterController
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Group {
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
            }
            
            Group {
                Divider().padding(.vertical, 2)
                
                SectionHeader(title: "Appearance")
                Picker("Theme", selection: $storage.darkMode) {
                    ForEach(DarkMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                
                Divider().padding(.vertical, 2)
                
                Toggle("Launch at Login (Auto Start)", isOn: $storage.launchAtLogin)
                    .font(.caption)

                Divider().padding(.vertical, 2)

                Toggle(
                    "Automatic Updates",
                    isOn: Binding(
                        get: { updaterController.automaticUpdatesEnabled },
                        set: { updaterController.setAutomaticUpdatesEnabled($0) }
                    )
                )
                .font(.caption)
            }
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
