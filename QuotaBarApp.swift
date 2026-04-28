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
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        storage.applyAppearance()
        configurePopover()
        configureStatusItem()
        observeState()
        setupRightClickMonitor()
        refreshUsage()
        updaterController.checkForUpdatesInBackground()
        startRefreshTimer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        refreshTimer?.invalidate()
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

        let isDarkMode: Bool = {
            switch storage.darkMode {
            case .dark:
                return true
            case .light:
                return false
            case .auto:
                if #available(macOS 10.14, *) {
                    return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                }
                return false
            }
        }()

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
                let line = result.entries.map { "\($0.name): \(Int($0.usagePercent * 100))%" }.joined(separator: ", ")
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

@MainActor
final class UpdaterController: ObservableObject {
    @Published private(set) var latestVersion: String?
    @Published private(set) var updateAvailable = false
    @Published private(set) var checkingForUpdates = false
    @Published private(set) var lastCheckDate: Date?

    private let releasesURL = "https://github.com/uwseoul/quota-bar/releases/latest"
    private let apiURL = "https://api.github.com/repos/uwseoul/quota-bar/releases/latest"
    private var cancellables = Set<AnyCancellable>()

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var statusMessage: String {
        if checkingForUpdates {
            return "Checking latest GitHub release..."
        }

        guard let latestVersion else {
            return "Checks GitHub Releases and opens the download page when a newer version is available."
        }

        if updateAvailable {
            return "Version \(latestVersion) is available on GitHub Releases."
        }

        return "You are on the latest version (\(currentVersion))."
    }

    func checkForUpdatesInBackground() {
        checkLatestRelease(openPageIfAvailable: false)
    }

    func checkForUpdates() {
        checkLatestRelease(openPageIfAvailable: true)
    }

    func openReleasesPage() {
        guard let url = URL(string: releasesURL) else { return }
        NSWorkspace.shared.open(url)
    }

    private func checkLatestRelease(openPageIfAvailable: Bool) {
        guard let url = URL(string: apiURL) else { return }

        checkingForUpdates = true

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .tryMap { data -> String in
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String else {
                    throw UpdaterError.invalidResponse
                }

                if tagName.hasPrefix("v") {
                    return String(tagName.dropFirst())
                }

                return tagName
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                self.checkingForUpdates = false
                if case .failure(let error) = completion {
                    print("[Updater] Failed to check for updates: \(error)")
                }
            } receiveValue: { [weak self] version in
                guard let self else { return }
                self.latestVersion = version
                self.lastCheckDate = Date()
                self.updateAvailable = self.isNewerVersion(version, than: self.currentVersion)

                if openPageIfAvailable, self.updateAvailable {
                    self.openReleasesPage()
                }
            }
            .store(in: &cancellables)
    }

    private func isNewerVersion(_ new: String, than current: String) -> Bool {
        let newParts = new.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }
        let maxCount = max(newParts.count, currentParts.count)

        for index in 0..<maxCount {
            let newPart = index < newParts.count ? newParts[index] : 0
            let currentPart = index < currentParts.count ? currentParts[index] : 0

            if newPart > currentPart { return true }
            if newPart < currentPart { return false }
        }

        return false
    }
}

private enum UpdaterError: Error {
    case invalidResponse
}
