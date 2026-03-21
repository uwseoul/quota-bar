import AppKit
import CoreGraphics

// Z.ai logo colors
let logoColor = NSColor(red: 0.12, green: 0.39, blue: 0.93, alpha: 1.0) // #1F63EC
let bgColor = NSColor.white

let sizes = [16, 32, 128, 256, 512]

for size in sizes {
    let rect = NSRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size))
    let image = NSImage(size: rect.size)
    image.lockFocus()
    
    // Draw white background
    bgColor.setFill()
    rect.fill()
    
    // Draw rounded square with Z.ai logo
    let padding: CGFloat = CGFloat(size) * 0.1
    let logoRect = NSRect(
        x: padding,
        y: padding,
        width: CGFloat(size) - padding * 2,
        height: CGFloat(size) - padding * 2
    )
    
    // Draw rounded rect
    let cornerRadius = CGFloat(size) * 0.22
    let path = NSBezierPath(roundedRect: logoRect, xRadius: cornerRadius, yRadius: cornerRadius)
    logoColor.setFill()
    path.fill()
    
    // Draw "Z" text in white
    let fontSize = CGFloat(size) * 0.65
    let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
    
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white
    ]
    
    let text = "Z" as NSString
    let textSize = text.size(withAttributes: attrs)
    let textRect = NSRect(
        x: logoRect.midX - textSize.width / 2,
        y: logoRect.midY - textSize.height / 2 - fontSize * 0.1,
        width: textSize.width,
        height: textSize.height
    )
    text.draw(in: textRect, withAttributes: attrs)
    
    image.unlockFocus()
    
    // Save regular size
    if let tiffData = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        try? pngData.write(to: URL(fileURLWithPath: "icon_\(size)x\(size).png"))
        print("Saved icon_\(size)x\(size).png")
    }
    
    // Save retina size (2x)
    let retinaSize = size * 2
    let rect2x = NSRect(x: 0, y: 0, width: CGFloat(retinaSize), height: CGFloat(retinaSize))
    let image2x = NSImage(size: rect2x.size)
    image2x.lockFocus()
    
    bgColor.setFill()
    rect2x.fill()
    
    let padding2x: CGFloat = CGFloat(retinaSize) * 0.1
    let logoRect2x = NSRect(
        x: padding2x,
        y: padding2x,
        width: CGFloat(retinaSize) - padding2x * 2,
        height: CGFloat(retinaSize) - padding2x * 2
    )
    
    let cornerRadius2x = CGFloat(retinaSize) * 0.22
    let path2x = NSBezierPath(roundedRect: logoRect2x, xRadius: cornerRadius2x, yRadius: cornerRadius2x)
    logoColor.setFill()
    path2x.fill()
    
    let fontSize2x = CGFloat(retinaSize) * 0.65
    let font2x = NSFont.systemFont(ofSize: fontSize2x, weight: .bold)
    
    let attrs2x: [NSAttributedString.Key: Any] = [
        .font: font2x,
        .foregroundColor: NSColor.white
    ]
    
    let textSize2x = text.size(withAttributes: attrs2x)
    let textRect2x = NSRect(
        x: logoRect2x.midX - textSize2x.width / 2,
        y: logoRect2x.midY - textSize2x.height / 2 - fontSize2x * 0.1,
        width: textSize2x.width,
        height: textSize2x.height
    )
    text.draw(in: textRect2x, withAttributes: attrs2x)
    
    image2x.unlockFocus()
    
    if let tiffData2x = image2x.tiffRepresentation,
       let bitmap2x = NSBitmapImageRep(data: tiffData2x),
       let pngData2x = bitmap2x.representation(using: .png, properties: [:]) {
        try? pngData2x.write(to: URL(fileURLWithPath: "icon_\(size)x\(size)@2x.png"))
        print("Saved icon_\(size)x\(size)@2x.png")
    }
}

print("All icons generated!")
