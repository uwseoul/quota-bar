import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var storage: Storage
    @EnvironmentObject var fetcher: UsageFetcher
    @EnvironmentObject var updaterController: UpdaterController

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        ScrollView {
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

                    SectionHeader(title: "Platforms")
                    Toggle("GLM", isOn: platformEnabledBinding("glm"))
                        .font(.caption)
                    Toggle("MiniMax", isOn: platformEnabledBinding("minimax"))
                        .font(.caption)
                    if storage.isPlatformEnabled("minimax") {
                        SecureField("MiniMax API Key", text: apiKeyBinding("minimax"))
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                    }
                    Toggle("Codex", isOn: platformEnabledBinding("codex"))
                        .font(.caption)
                    HStack {
                        Text(codexAuthStatus)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    Toggle("OpenCode Go", isOn: platformEnabledBinding("opencodego"))
                        .font(.caption)
                    if storage.isPlatformEnabled("opencodego") {
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Workspace ID", text: apiKeyBinding("opencodego_workspace"))
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                            SecureField("Auth Cookie", text: apiKeyBinding("opencodego_cookie"))
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                            Button("연결 방법 보기") {
                                showOpenCodeGoHelpAlert()
                            }
                            .font(.caption)
                            .buttonStyle(.plain)
                        }
                    }

                    Divider().padding(.vertical, 4)

                    SectionHeader(title: "Menu Bar Display")
                    Picker("Mode", selection: $storage.menuBarMode) {
                        ForEach(MenuBarMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .font(.caption)

                    Picker("Style", selection: $storage.displayStyle) {
                        ForEach(DisplayStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.radioGroup)

                    if storage.menuBarMode == .manual {
                        SectionHeader(title: "Manual Quota Selection")
                        let allQuotas = fetcher.entries
                        if allQuotas.isEmpty {
                            Text("데이터를 불러온 후 선택할 수 있습니다.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(allQuotas) { entry in
                                    Toggle("\(platformDisplayName(entry.platformId)): \(entry.name)", isOn: visibleQuotaBinding(entry.id))
                                        .font(.caption)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("5 Hours Quota", isOn: $storage.show5h)
                        Toggle("Weekly Quota", isOn: $storage.showWeekly)
                        Toggle("Monthly Quota", isOn: $storage.showMonthly)
                    }
                    .font(.caption)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Divider().padding(.vertical, 2)

                    SectionHeader(title: "Updates")
                    Text(updaterController.statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let lastCheckDate = updaterController.lastCheckDate {
                        Text("Last checked: \(Self.dateFormatter.string(from: lastCheckDate))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Button(updaterController.updateAvailable ? "Open Latest Release" : "Check GitHub Releases") {
                        updaterController.checkForUpdates()
                    }
                    .buttonStyle(.bordered)

                    Divider().padding(.vertical, 2)

                    SectionHeader(title: "Window")
                    Toggle("Always on Top (Widget Mode)", isOn: $storage.alwaysOnTop)
                        .font(.caption)

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
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private func platformEnabledBinding(_ platformId: String) -> Binding<Bool> {
        Binding(
            get: { storage.enabledPlatforms[platformId] ?? false },
            set: { storage.enabledPlatforms[platformId] = $0 }
        )
    }

    private func apiKeyBinding(_ platformId: String) -> Binding<String> {
        Binding(
            get: { storage.apiKeys[platformId] ?? "" },
            set: { storage.apiKeys[platformId] = $0 }
        )
    }

    private func visibleQuotaBinding(_ quotaId: String) -> Binding<Bool> {
        Binding(
            get: { storage.visibleQuotas.contains(quotaId) },
            set: { isVisible in
                if isVisible {
                    storage.visibleQuotas.insert(quotaId)
                } else {
                    storage.visibleQuotas.remove(quotaId)
                }
            }
        )
    }

    private func platformDisplayName(_ platformId: String) -> String {
        switch platformId {
        case "glm": return "GLM"
        case "minimax": return "MiniMax"
        case "codex": return "Codex"
        case "opencodego": return "OpenCode Go"
        default: return platformId.uppercased()
        }
    }

    private var codexAuthStatus: String {
        let authURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex/auth.json")
        if FileManager.default.fileExists(atPath: authURL.path) {
            return "Codex auth found at ~/.codex/auth.json"
        } else {
            return "Codex auth not found. Run `codex login` first."
        }
    }

    private func showOpenCodeGoHelpAlert() {
        let alert = NSAlert()
        alert.messageText = "OpenCode Go 연결 방법"
        alert.informativeText = """
        1. 브라우저에서 opencode.ai 에 로그인
        2. 워크스페이스 URL에서 Workspace ID 복사
           예: https://opencode.ai/workspace/WRK_ID/go
        3. 개발자 도구(F12) → Application → Cookies → opencode.ai
        4. 'auth' 쿠키 값 복사
        5. 위 필드에 각각 붙여넣기
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "확인")
        if let window = NSApplication.shared.keyWindow {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
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
