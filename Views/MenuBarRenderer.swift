import AppKit

enum MenuBarRenderer {
    static func makeStatusImage(entries: [QuotaEntry], displayStyle: DisplayStyle, isDarkMode: Bool) -> NSImage? {
        guard !entries.isEmpty else { return nil }

        let height: CGFloat = 22
        let itemWidth: CGFloat = (displayStyle == .speed) ? 24 : 36
        let totalWidth = max(itemWidth * CGFloat(entries.count), 20)
        let image = NSImage(size: NSSize(width: totalWidth, height: height))

        image.lockFocus()

        for (index, entry) in entries.enumerated() {
            let xOffset = CGFloat(index) * itemWidth

            let labelStyle = NSMutableParagraphStyle()
            labelStyle.alignment = .center
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 9, weight: .regular),
                .foregroundColor: NSColor.white.withAlphaComponent(0.7),
                .paragraphStyle: labelStyle
            ]
            let labelString = NSAttributedString(string: shortLabel(for: entry.name), attributes: labelAttributes)
            labelString.draw(in: NSRect(x: xOffset, y: 11, width: itemWidth, height: 11))

            switch displayStyle {
            case .percent:
                let valueStyle = NSMutableParagraphStyle()
                valueStyle.alignment = .center
                let valueAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .bold),
                    .foregroundColor: NSColor.white,
                    .paragraphStyle: valueStyle
                ]
                let valueString = NSAttributedString(
                    string: "\(Int(entry.usagePercent * 100))%",
                    attributes: valueAttributes
                )
                valueString.draw(in: NSRect(x: xOffset, y: 0, width: itemWidth, height: 12))

            case .graph:
                drawBar(for: entry, xOffset: xOffset, itemWidth: itemWidth, showSpeedIndicator: false)

            case .speed:
                drawSignalOnly(for: entry, xOffset: xOffset, itemWidth: itemWidth)
            }
        }

        image.unlockFocus()
        return image
    }

    private static func drawBar(for entry: QuotaEntry, xOffset: CGFloat, itemWidth: CGFloat, showSpeedIndicator: Bool) {
        let barWidth: CGFloat = 24
        let barHeight: CGFloat = 4
        let barX = xOffset + (itemWidth - barWidth) / 2
        let barY: CGFloat = 4

        let background = NSBezierPath(
            roundedRect: NSRect(x: barX, y: barY, width: barWidth, height: barHeight),
            xRadius: 2,
            yRadius: 2
        )
        NSColor.lightGray.setFill()
        background.fill()

        let fillWidth = barWidth * CGFloat(min(max(entry.usagePercent, 0.05), 1.0))
        let foreground = NSBezierPath(
            roundedRect: NSRect(x: barX, y: barY, width: fillWidth, height: barHeight),
            xRadius: 2,
            yRadius: 2
        )
        entry.speedStatus.color.setFill()
        foreground.fill()
    }

    private static func drawSignalOnly(for entry: QuotaEntry, xOffset: CGFloat, itemWidth: CGFloat) {
        let indicatorSize: CGFloat = 9
        let indicatorX = xOffset + (itemWidth - indicatorSize) / 2
        let indicatorY: CGFloat = 2
        let indicatorPath = NSBezierPath(ovalIn: NSRect(x: indicatorX, y: indicatorY, width: indicatorSize, height: indicatorSize))
        signalColor(for: entry.speedStatus).setFill()
        indicatorPath.fill()
    }

    private static func signalColor(for status: SpeedStatus) -> NSColor {
        switch status {
        case .fast: return NSColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
        case .normal: return NSColor(red: 1.0, green: 0.75, blue: 0.0, alpha: 1.0)
        case .slow: return NSColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0)
        }
    }

    private static func speedSymbol(for status: SpeedStatus) -> String {
        switch status {
        case .fast:
            return "▲"
        case .normal:
            return "●"
        case .slow:
            return "▼"
        }
    }

    private static func shortLabel(for name: String) -> String {
        if name.contains("5 Hours") || name == "5H" { return "5H" }
        if name.contains("Weekly") || name == "Weekly" { return "WK" }
        if name.contains("Monthly") || name == "Monthly" { return "MO" }
        if name == "7D" { return "7D" }
        if name == "Review" { return "RV" }
        if name == "Rolling" { return "RL" }
        return "QT"
    }
}
