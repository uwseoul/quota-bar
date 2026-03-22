import Combine
import AppKit
import Foundation

final class UpdaterController: ObservableObject {
    @Published private(set) var latestVersion: String?
    @Published private(set) var updateAvailable = false
    @Published private(set) var checkingForUpdates = false
    @Published private(set) var lastCheckDate: Date?

    private let releasesURL = "https://github.com/uwseoul/glm-bar/releases/latest"
    private let apiURL = "https://api.github.com/repos/uwseoul/glm-bar/releases/latest"

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    func checkForUpdatesInBackground() {
        Task {
            await checkLatestRelease()
        }
    }

    func checkForUpdates() {
        Task {
            await checkLatestRelease()
            if updateAvailable, let url = URL(string: releasesURL) {
                NSWorkspace.shared.open(url)
            }
        }
    }

    func openReleasesPage() {
        if let url = URL(string: releasesURL) {
            NSWorkspace.shared.open(url)
        }
    }

    private func checkLatestRelease() async {
        checkingForUpdates = true
        defer { checkingForUpdates = false }

        guard let url = URL(string: apiURL) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String else {
                return
            }

            let version = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
            latestVersion = version
            lastCheckDate = Date()
            updateAvailable = isNewerVersion(version, than: currentVersion)
        } catch {
            print("[Updater] Failed to check for updates: \(error)")
        }
    }

    private func isNewerVersion(_ new: String, than current: String) -> Bool {
        let newParts = new.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }

        let maxCount = max(newParts.count, currentParts.count)

        for i in 0..<maxCount {
            let newPart = i < newParts.count ? newParts[i] : 0
            let currentPart = i < currentParts.count ? currentParts[i] : 0

            if newPart > currentPart { return true }
            if newPart < currentPart { return false }
        }

        return false
    }
}
