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
            let labelString = NSAttributedString(string: shortLabel(for: entry.platformId), attributes: labelAttributes)
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
                    string: "\(entry.displayPercent)%",
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

        let fillWidth = entry.displayPercent == 0 ? 0 : barWidth * CGFloat(min(max(entry.usagePercent, 0.05), 1.0))
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
        entry.speedStatus.color.setFill()
        indicatorPath.fill()
    }

    private static func shortLabel(for platformId: String) -> String {
        switch platformId {
        case "glm":
            return "GLM"
        case "minimax":
            return "MMX"
        case "codex":
            return "CDX"
        case "opencodego":
            return "OCG"
        default:
            return String(platformId.prefix(3)).uppercased()
        }
    }
}
