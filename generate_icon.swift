import AppKit
import CoreGraphics

func createIcon() -> NSImage {
    let size = NSSize(width: 1024, height: 1024)
    let image = NSImage(size: size)
    
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }
    
    // Enable antialiasing
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)
    
    // Squircle geometry (Apple standard: 824x824 centered in 1024x1024)
    let squircleRect = CGRect(x: 100, y: 100, width: 824, height: 824)
    let cornerRadius: CGFloat = 185
    let squirclePath = CGPath(roundedRect: squircleRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    
    // 1. Draw outer shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 32, color: NSColor.black.withAlphaComponent(0.45).cgColor)
    ctx.addPath(squirclePath)
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.fillPath()
    ctx.restoreGState()
    
    // 2. Draw Squircle background gradient
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        NSColor(red: 0.05, green: 0.12, blue: 0.20, alpha: 1.0).cgColor, // Deep navy
        NSColor(red: 0.02, green: 0.05, blue: 0.09, alpha: 1.0).cgColor  // Midnight abyss
    ] as CFArray
    let bgLocations: [CGFloat] = [0.0, 1.0]
    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
        ctx.drawLinearGradient(bgGradient, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])
    }
    
    // Radial ambient cyan aura in upper center
    let auraColors = [
        NSColor(red: 0.0, green: 0.78, blue: 0.95, alpha: 0.35).cgColor,
        NSColor(red: 0.0, green: 0.45, blue: 0.85, alpha: 0.0).cgColor
    ] as CFArray
    if let auraGradient = CGGradient(colorsSpace: colorSpace, colors: auraColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(auraGradient, startCenter: CGPoint(x: 512, y: 560), startRadius: 20, endCenter: CGPoint(x: 512, y: 560), endRadius: 360, options: [])
    }
    
    // 3. Central Eye Glyph Artwork
    // Draw stylized outer eyelid almond curves
    let eyeCenter = CGPoint(x: 512, y: 512)
    
    // Eyelid path
    let eyelidPath = CGMutablePath()
    eyelidPath.move(to: CGPoint(x: 270, y: 512))
    // Upper eyelid curve
    eyelidPath.addCurve(to: CGPoint(x: 754, y: 512), control1: CGPoint(x: 400, y: 690), control2: CGPoint(x: 624, y: 690))
    // Lower eyelid curve
    eyelidPath.addCurve(to: CGPoint(x: 270, y: 512), control1: CGPoint(x: 624, y: 334), control2: CGPoint(x: 400, y: 334))
    eyelidPath.closeSubpath()
    
    // Fill eyelid with subtle dark glass
    ctx.saveGState()
    ctx.addPath(eyelidPath)
    ctx.setFillColor(NSColor(red: 0.0, green: 0.35, blue: 0.65, alpha: 0.18).cgColor)
    ctx.fillPath()
    
    // Stroke eyelid with luminous cyan gradient
    let strokeGradientColors = [
        NSColor(red: 0.20, green: 0.90, blue: 1.0, alpha: 0.95).cgColor,
        NSColor(red: 0.05, green: 0.55, blue: 0.98, alpha: 0.85).cgColor
    ] as CFArray
    if let strokeGrad = CGGradient(colorsSpace: colorSpace, colors: strokeGradientColors, locations: [0.0, 1.0]) {
        ctx.addPath(eyelidPath)
        ctx.setLineWidth(24)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.replacePathWithStrokedPath()
        ctx.clip()
        ctx.drawLinearGradient(strokeGrad, start: CGPoint(x: 270, y: 690), end: CGPoint(x: 754, y: 334), options: [])
    }
    ctx.restoreGState()
    
    // Draw outer iris ring
    ctx.saveGState()
    let irisOuterRadius: CGFloat = 135
    let irisOuterRect = CGRect(x: eyeCenter.x - irisOuterRadius, y: eyeCenter.y - irisOuterRadius, width: irisOuterRadius * 2, height: irisOuterRadius * 2)
    
    ctx.addEllipse(in: irisOuterRect)
    ctx.setFillColor(NSColor(red: 0.0, green: 0.15, blue: 0.30, alpha: 0.70).cgColor)
    ctx.fillPath()
    
    ctx.addEllipse(in: irisOuterRect)
    ctx.setLineWidth(16)
    ctx.setStrokeColor(NSColor(red: 0.0, green: 0.88, blue: 1.0, alpha: 0.95).cgColor)
    ctx.strokePath()
    ctx.restoreGState()
    
    // Draw inner pupil with glowing iris gradient
    ctx.saveGState()
    let pupilRadius: CGFloat = 68
    let pupilRect = CGRect(x: eyeCenter.x - pupilRadius, y: eyeCenter.y - pupilRadius, width: pupilRadius * 2, height: pupilRadius * 2)
    let pupilColors = [
        NSColor(red: 0.0, green: 0.75, blue: 0.95, alpha: 1.0).cgColor,
        NSColor(red: 0.02, green: 0.10, blue: 0.22, alpha: 1.0).cgColor
    ] as CFArray
    if let pupilGrad = CGGradient(colorsSpace: colorSpace, colors: pupilColors, locations: [0.0, 1.0]) {
        ctx.addEllipse(in: pupilRect)
        ctx.clip()
        ctx.drawRadialGradient(pupilGrad, startCenter: CGPoint(x: 512, y: 524), startRadius: 4, endCenter: CGPoint(x: 512, y: 512), endRadius: pupilRadius, options: [])
    }
    ctx.restoreGState()
    
    // Draw lifelike reflection highlight dot (top right)
    ctx.saveGState()
    let highlightRect = CGRect(x: 532, y: 532, width: 28, height: 28)
    ctx.addEllipse(in: highlightRect)
    ctx.setFillColor(NSColor.white.withAlphaComponent(0.92).cgColor)
    ctx.fillPath()
    
    let highlightSub = CGRect(x: 486, y: 482, width: 14, height: 14)
    ctx.addEllipse(in: highlightSub)
    ctx.setFillColor(NSColor.white.withAlphaComponent(0.55).cgColor)
    ctx.fillPath()
    ctx.restoreGState()
    
    // 4. Subtle inner bevel rim on squircle (Apple standard)
    ctx.saveGState()
    let rimColors = [
        NSColor.white.withAlphaComponent(0.35).cgColor,
        NSColor.white.withAlphaComponent(0.05).cgColor
    ] as CFArray
    if let rimGrad = CGGradient(colorsSpace: colorSpace, colors: rimColors, locations: [0.0, 1.0]) {
        ctx.addPath(squirclePath)
        ctx.setLineWidth(2.5)
        ctx.replacePathWithStrokedPath()
        ctx.clip()
        ctx.drawLinearGradient(rimGrad, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])
    }
    ctx.restoreGState()
    
    ctx.restoreGState() // unclip squircle
    
    image.unlockFocus()
    return image
}

let image = createIcon()

guard let tiffData = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiffData),
      let pngData = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to convert image to PNG")
}

let fileManager = FileManager.default
let iconsetDir = "AppIcon.iconset"
try? fileManager.removeItem(atPath: iconsetDir)
try? fileManager.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let masterURL = URL(fileURLWithPath: "\(iconsetDir)/icon_512x512@2x.png")
try pngData.write(to: masterURL)

// Generate all standard icon sizes using sips
let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512)
]

for (name, sz) in sizes {
    let targetPath = "\(iconsetDir)/\(name)"
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    task.arguments = ["-z", "\(sz)", "\(sz)", "\(iconsetDir)/icon_512x512@2x.png", "--out", targetPath]
    try? task.run()
    task.waitUntilExit()
}

print("Successfully generated all iconset resolutions!")
