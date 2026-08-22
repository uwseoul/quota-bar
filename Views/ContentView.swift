import AppKit
import SwiftUI

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
                Button("Back to Usage") {
                    showingSettings = false
                }
                .buttonStyle(.bordered)
                .padding(.bottom, 8)
            } else {
                usageHeader
                usageContent
                Divider()
                HStack {
                    Button("Settings...") {
                        showingSettings = true
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("Check for Updates...") {
                        updaterController.checkForUpdates()
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.bottom, 8)
            }
        }
        .frame(width: 300)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .onAppear {
            fetcher.fetchAll(storage: storage)
        }
    }

    private var usageHeader: some View {
        HStack {
            Text(storage.selectedPlatform.rawValue)
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer()

            Button(action: {
                fetcher.fetchAll(storage: storage)
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

    @ViewBuilder
    private var usageContent: some View {
        if let error = fetcher.lastError, groupedSections.isEmpty {
            Text(error)
                .foregroundColor(.red)
                .font(.caption)
                .padding()
        } else if groupedSections.isEmpty {
            Text(fetcher.isLoading ? "Loading..." : "No data. Please set API Key in Settings.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        } else {
            VStack(spacing: 12) {
                ForEach(groupedSections) { section in
                    platformSection(section)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var groupedSections: [QuotaPlatformSection] {
        let enabledPlatforms = storage.enabledPlatforms
            .filter { $0.value }
            .map(\.key)

        return enabledPlatforms.compactMap { platformId in
            let platformEntries = fetcher.perPlatformResults[platformId]?.entries ?? fetcher.entries.filter { $0.platformId == platformId }
            let error = fetcher.perPlatformResults[platformId]?.error

            if platformEntries.isEmpty, error == nil {
                return nil
            }

            return QuotaPlatformSection(
                id: platformId,
                title: title(for: platformId),
                entries: platformEntries.sorted(by: UsageFetcher.sortEntries),
                error: error
            )
        }
    }

    @ViewBuilder
    private func platformSection(_ section: QuotaPlatformSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(section.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
                if let error = section.error {
                    Text("⚠️ \(error)")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.06))

            if section.id == "glm" && storage.selectedPlatform == .zai {
                peakBanner
            }

            if let error = section.error, section.entries.isEmpty {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(section.entries.enumerated()), id: \.element.id) { index, entry in
                    if index > 0 {
                        Divider()
                            .padding(.horizontal, 10)
                    }
                    quotaEntryRow(entry)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.35), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var peakBanner: some View {
        PeakBannerView()
    }

    @ViewBuilder
    private func quotaEntryRow(_ entry: QuotaEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.name)
                    .font(.system(size: 11, weight: .semibold))

                Spacer()

                HStack(spacing: 4) {
                    speedBadge(for: entry.speedStatus)
                    Text("\(entry.displayPercent)%")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(entry.usagePercent > 0.8 ? .orange : .primary)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.12))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(entry.speedStatus.swiftUIColor)
                        .frame(width: progressWidth(for: entry, totalWidth: geometry.size.width), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                if let reset = entry.resetSeconds {
                    Text("Reset in \(formatTime(reset))")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let usage = entry.usage, let total = entry.total {
                    Text("\(usage) / \(total)")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func title(for platformId: String) -> String {
        switch platformId {
        case "glm":
            return storage.selectedPlatform.rawValue
        case "minimax":
            return "MiniMax"
        case "codex":
            return "Codex"
        case "opencodego":
            return "OpenCode Go"
        default:
            return platformId.uppercased()
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        if seconds < 3600 {
            return "\(seconds / 60)m"
        }

        if seconds < 86400 {
            return "\(seconds / 3600)h \((seconds % 3600) / 60)m"
        }

        return "\(seconds / 86400)d \((seconds % 86400) / 3600)h"
    }

    private func speedBadge(for status: SpeedStatus) -> some View {
        HStack(spacing: 2) {
            Circle()
                .fill(status.swiftUIColor)
                .frame(width: 6, height: 6)

            Text(speedLabel(for: status))
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(status.swiftUIColor)
        }
    }

    private func progressWidth(for entry: QuotaEntry, totalWidth: CGFloat) -> CGFloat {
        guard entry.displayPercent > 0 else { return 0 }
        return totalWidth * CGFloat(min(max(entry.usagePercent, 0.05), 1.0))
    }

    private func speedLabel(for status: SpeedStatus) -> String {
        switch status {
        case .fast:
            return "FAST"
        case .normal:
            return "OK"
        case .slow:
            return "SLOW"
        }
    }

}

private struct QuotaPlatformSection: Identifiable {
    let id: String
    let title: String
    let entries: [QuotaEntry]
    let error: String?
}

/// z.ai 혼잡 시간대 배너 (macOS 11 호환: TimelineView 대신 Timer 사용)
private struct PeakBannerView: View {
    @State private var now = Date()

    private let minuteTimer = Timer.publish(every: 60, on: .main, in: .common)
        .autoconnect()

    var body: some View {
        let isPeak = PeakHours.isPeak(at: now)
        let remaining = PeakHours.secondsUntilTransition(at: now)
        let isWeekend = PeakHours.isWeekend(at: now)

        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: isPeak ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 10))
                Text(isPeak ? "현재 혼잡 시간대" : "현재 비혼잡 시간대")
                    .font(.system(size: 11, weight: .semibold))
            }

            if isPeak {
                Text("혼잡 \(PeakHours.windowLabelKST) · 종료까지 \(PeakHours.formatRemaining(remaining))")
                    .font(.system(size: 9))
            } else if isWeekend {
                Text("주말 · 혼잡: 평일 \(PeakHours.windowLabelKST)")
                    .font(.system(size: 9))
            } else {
                Text("혼잡 \(PeakHours.windowLabelKST) · 시작까지 \(PeakHours.formatRemaining(remaining))")
                    .font(.system(size: 9))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            isPeak
                ? Color.orange.opacity(0.18)
                : Color.primary.opacity(0.05)
        )
        .overlay(
            Rectangle()
                .fill(isPeak ? Color.orange.opacity(0.5) : Color.primary.opacity(0.15))
                .frame(height: 0.5),
            alignment: .bottom
        )
        .foregroundColor(isPeak ? .orange : .secondary)
        .onReceive(minuteTimer) { _ in
            refresh()
        }
    }

    private func refresh() {
        now = Date()
    }
}
