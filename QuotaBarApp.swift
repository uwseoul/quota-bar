import AppKit
import Combine
import SwiftUI

extension Notification.Name {
    static let showSettingsPopover = Notification.Name("ShowSettingsPopover")
    static let showUsagePopover = Notification.Name("ShowUsagePopover")
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let storage = Storage()
    private let fetcher = UsageFetcher()
    private let updaterController = UpdaterController()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem?
    private var refreshTimer: Timer?
    private var rightClickMonitor: Any?
    private var appearanceObservation: NSKeyValueObservation?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        storage.applyAppearance()
        configurePopover()
        configureStatusItem()
        observeState()
        observeAppearanceChanges()
        setupRightClickMonitor()
        refreshUsage()
        updaterController.checkForUpdatesInBackground()
        startRefreshTimer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        refreshTimer?.invalidate()
        appearanceObservation?.invalidate()
        if let monitor = rightClickMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 360, height: 600)
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

    private func setupRightClickMonitor() {
        rightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            guard let self = self, event.window == self.statusItem?.button?.window else {
                return event
            }
            self.showPopover(showSettings: true)
            return nil
        }
    }

    private func observeAppearanceChanges() {
        appearanceObservation = NSApplication.shared.observe(
            \.effectiveAppearance,
            options: [.new]
        ) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.updateStatusItem()
            }
        }
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
        fetcher.fetchAll(storage: storage)
    }

    private func updateStatusItem() {
        guard let button = statusItem?.button else { return }

        // Match the menu bar's actual rendering context. applyAppearance()
        // forces NSApp.appearance for light/dark overrides, and .auto follows
        // the system, so effectiveAppearance always reflects what the status
        // item is drawn against — including live system theme switches.
        let isDarkMode: Bool
        if #available(macOS 10.14, *) {
            isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        } else {
            isDarkMode = false
        }

        let visibleEntries = storage.visibleMenuBarEntries(from: fetcher.entries)

        if let image = MenuBarRenderer.makeStatusImage(entries: visibleEntries, displayStyle: storage.displayStyle, isDarkMode: isDarkMode) {
            button.image = image
            button.title = ""
            button.imagePosition = .imageOnly
        } else {
            button.image = nil
            button.title = "QB"
            button.imagePosition = .noImage
        }

        let toolTipLines = storage.enabledPlatforms
            .filter { $0.value }
            .compactMap { (platformId, _) -> String? in
                guard let result = fetcher.perPlatformResults[platformId], !result.entries.isEmpty else { return nil }
                let line = result.entries.map { "\($0.name): \($0.displayPercent)%" }.joined(separator: ", ")
                return "\(platformId.uppercased()): \(line)"
            }
        button.toolTip = toolTipLines.isEmpty ? "Quota Bar" : toolTipLines.joined(separator: "\n")
    }

    private func showPopover(showSettings: Bool) {
        if popover.isShown {
            if showSettings {
                NotificationCenter.default.post(name: .showSettingsPopover, object: nil)
            } else {
                NotificationCenter.default.post(name: .showUsagePopover, object: nil)
            }
            return
        }

        guard let button = statusItem?.button else { return }
        if showSettings {
            NotificationCenter.default.post(name: .showSettingsPopover, object: nil)
        } else {
            NotificationCenter.default.post(name: .showUsagePopover, object: nil)
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    @objc private func togglePopover(_ sender: Any?) {
        showPopover(showSettings: false)
    }
}

@main
struct QuotaBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
