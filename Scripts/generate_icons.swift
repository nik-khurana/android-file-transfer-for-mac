import AppKit

func drawAndroidLiquidGlassIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let img = NSImage(size: NSSize(width: s, height: s))
    img.lockFocus()
    
    let ctx = NSGraphicsContext.current?.cgContext
    ctx?.saveGState()
    
    // Enable highest quality antialiasing
    ctx?.setAllowsAntialiasing(true)
    ctx?.setShouldAntialias(true)
    ctx?.interpolationQuality = .high
    
    // -------------------------------------------------------------------------
    // 1. APPLE macOS SQUIRCLE FOUNDATION
    // -------------------------------------------------------------------------
    let pad = s * 0.088
    let rect = NSRect(x: pad, y: pad, width: s - 2 * pad, height: s - 2 * pad)
    let corner = s * 0.185
    let squircle = NSBezierPath(roundedRect: rect, xRadius: corner, yRadius: corner)
    
    // Squircle Drop Shadow for macOS Dock depth
    ctx?.saveGState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.48)
    shadow.shadowOffset = NSSize(width: 0, height: -s * 0.035)
    shadow.shadowBlurRadius = s * 0.065
    shadow.set()
    
    // Background Base: Deep Space Obsidian-Sapphire (#05070F -> #0A1329)
    let baseGradient = NSGradient(colorsAndLocations:
        (NSColor(red: 0.02, green: 0.04, blue: 0.08, alpha: 1.0), 0.0),
        (NSColor(red: 0.04, green: 0.08, blue: 0.16, alpha: 1.0), 0.5),
        (NSColor(red: 0.07, green: 0.12, blue: 0.24, alpha: 1.0), 1.0)
    )
    baseGradient?.draw(in: squircle, angle: -45)
    ctx?.restoreGState()
    
    // Clip inside squircle for all internal layers
    squircle.addClip()
    
    // -------------------------------------------------------------------------
    // 2. AMBIENT CAUSTIC GLOWS (Android Emerald & Electric Cyan)
    // -------------------------------------------------------------------------
    // Radial glow bottom-right (Android Emerald #00E676 / #10B981)
    let brCenter = CGPoint(x: s * 0.78, y: s * 0.24)
    let brColors = [
        NSColor(red: 0.05, green: 0.85, blue: 0.45, alpha: 0.52).cgColor,
        NSColor(red: 0.02, green: 0.55, blue: 0.35, alpha: 0.20).cgColor,
        NSColor.clear.cgColor
    ] as CFArray
    if let brGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: brColors, locations: [0.0, 0.45, 1.0]) {
        ctx?.drawRadialGradient(brGrad, startCenter: brCenter, startRadius: 0, endCenter: brCenter, endRadius: s * 0.60, options: [])
    }
    
    // Radial glow top-left (Mac Electric Cyan #00E5FF / #38BDF8)
    let tlCenter = CGPoint(x: s * 0.24, y: s * 0.78)
    let tlColors = [
        NSColor(red: 0.00, green: 0.82, blue: 0.98, alpha: 0.55).cgColor,
        NSColor(red: 0.10, green: 0.45, blue: 0.90, alpha: 0.22).cgColor,
        NSColor.clear.cgColor
    ] as CFArray
    if let tlGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: tlColors, locations: [0.0, 0.50, 1.0]) {
        ctx?.drawRadialGradient(tlGrad, startCenter: tlCenter, startRadius: 0, endCenter: tlCenter, endRadius: s * 0.62, options: [])
    }
    
    // -------------------------------------------------------------------------
    // 3. REFRACTIVE GLASS DISCS (Subtle Liquid Ring)
    // -------------------------------------------------------------------------
    let glassRingRect = NSRect(x: s * 0.15, y: s * 0.15, width: s * 0.70, height: s * 0.70)
    let glassRing = NSBezierPath(ovalIn: glassRingRect)
    NSColor(white: 1.0, alpha: 0.04).setFill()
    glassRing.fill()
    NSColor(white: 1.0, alpha: 0.12).setStroke()
    glassRing.lineWidth = max(1.0, s * 0.008)
    glassRing.stroke()
    
    // -------------------------------------------------------------------------
    // 4. FLOATING FROSTED GLASS ANDROID DOME & EMBLEM
    // -------------------------------------------------------------------------
    let headCenter = CGPoint(x: s * 0.50, y: s * 0.46)
    let headRadius = s * 0.23
    
    // Symmetrical Android Head Semi-Dome
    let androidHead = NSBezierPath()
    androidHead.appendArc(withCenter: headCenter, radius: headRadius, startAngle: 0, endAngle: 180, clockwise: false)
    androidHead.line(to: CGPoint(x: headCenter.x + headRadius, y: headCenter.y))
    androidHead.close()
    
    ctx?.saveGState()
    // Translucent Frosted Glass fill
    let headGrad = NSGradient(colorsAndLocations:
        (NSColor(red: 0.08, green: 0.22, blue: 0.35, alpha: 0.88), 0.0),
        (NSColor(red: 0.04, green: 0.15, blue: 0.24, alpha: 0.75), 0.5),
        (NSColor(red: 0.03, green: 0.28, blue: 0.26, alpha: 0.85), 1.0)
    )
    headGrad?.draw(in: androidHead, angle: -60)
    
    // Android Head Specular Glass Edge
    NSColor(red: 0.25, green: 0.95, blue: 0.75, alpha: 0.85).setStroke()
    androidHead.lineWidth = max(1.5, s * 0.016)
    androidHead.stroke()
    ctx?.restoreGState()
    
    // Android Antennae (Angled at 30 degrees)
    let antLength = s * 0.085
    let antWidth = max(1.5, s * 0.022)
    
    func drawAntenna(angleDeg: CGFloat) {
        let rad = angleDeg * .pi / 180.0
        let baseDist = headRadius * 0.88
        let startX = headCenter.x + baseDist * cos(rad)
        let startY = headCenter.y + baseDist * sin(rad)
        let endX = startX + antLength * cos(rad)
        let endY = startY + antLength * sin(rad)
        
        let antPath = NSBezierPath()
        antPath.move(to: CGPoint(x: startX, y: startY))
        antPath.line(to: CGPoint(x: endX, y: endY))
        antPath.lineCapStyle = .round
        antPath.lineWidth = antWidth
        NSColor(red: 0.20, green: 0.95, blue: 0.70, alpha: 0.95).setStroke()
        antPath.stroke()
    }
    
    drawAntenna(angleDeg: 58)   // Right antenna
    drawAntenna(angleDeg: 122)  // Left antenna
    
    // Android Eyes (Cutout / Luminous Dots)
    let eyeR = s * 0.024
    let eyeDist = headRadius * 0.52
    let eyeY = headCenter.y + headRadius * 0.42
    
    for side: CGFloat in [-1.0, 1.0] {
        let eyeX = headCenter.x + side * eyeDist
        let eyeRect = NSRect(x: eyeX - eyeR, y: eyeY - eyeR, width: eyeR * 2, height: eyeR * 2)
        let eyePath = NSBezierPath(ovalIn: eyeRect)
        
        // Deep cutout backdrop
        NSColor(red: 0.02, green: 0.05, blue: 0.10, alpha: 0.95).setFill()
        eyePath.fill()
        
        // Inner electric glow dot
        let pupil = NSBezierPath(ovalIn: NSRect(x: eyeX - eyeR * 0.55, y: eyeY - eyeR * 0.55, width: eyeR * 1.1, height: eyeR * 1.1))
        NSColor(red: 0.20, green: 0.95, blue: 0.75, alpha: 0.90).setFill()
        pupil.fill()
    }
    
    // -------------------------------------------------------------------------
    // 5. BIDIRECTIONAL HIGH-SPEED HOLOGRAPHIC DATA BEAMS
    // -------------------------------------------------------------------------
    let arrowW = s * 0.22
    let arrowH = s * 0.065
    
    // Stream 1: Cyan Data Beam (Right-pointing: Mac ➔ Android)
    let a1x = s * 0.39
    let a1y = s * 0.35
    let arrow1 = NSBezierPath()
    arrow1.move(to: CGPoint(x: a1x, y: a1y + arrowH * 0.45))
    arrow1.line(to: CGPoint(x: a1x + arrowW * 0.65, y: a1y + arrowH * 0.45))
    arrow1.line(to: CGPoint(x: a1x + arrowW * 0.65, y: a1y + arrowH * 0.85))
    arrow1.line(to: CGPoint(x: a1x + arrowW, y: a1y))
    arrow1.line(to: CGPoint(x: a1x + arrowW * 0.65, y: a1y - arrowH * 0.85))
    arrow1.line(to: CGPoint(x: a1x + arrowW * 0.65, y: a1y - arrowH * 0.45))
    arrow1.line(to: CGPoint(x: a1x, y: a1y - arrowH * 0.45))
    arrow1.close()
    
    ctx?.saveGState()
    let a1Shadow = NSShadow()
    a1Shadow.shadowColor = NSColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 0.75)
    a1Shadow.shadowBlurRadius = s * 0.040
    a1Shadow.set()
    let a1Grad = NSGradient(
        starting: NSColor(red: 0.0, green: 0.82, blue: 1.0, alpha: 0.95),
        ending: NSColor(red: 0.1, green: 0.95, blue: 0.8, alpha: 0.95)
    )
    a1Grad?.draw(in: arrow1, angle: 0)
    ctx?.restoreGState()
    
    // Stream 2: Emerald Data Beam (Left-pointing: Android ➔ Mac)
    let a2x = s * 0.61
    let a2y = s * 0.23
    let arrow2 = NSBezierPath()
    arrow2.move(to: CGPoint(x: a2x, y: a2y + arrowH * 0.45))
    arrow2.line(to: CGPoint(x: a2x - arrowW * 0.65, y: a2y + arrowH * 0.45))
    arrow2.line(to: CGPoint(x: a2x - arrowW * 0.65, y: a2y + arrowH * 0.85))
    arrow2.line(to: CGPoint(x: a2x - arrowW, y: a2y))
    arrow2.line(to: CGPoint(x: a2x - arrowW * 0.65, y: a2y - arrowH * 0.85))
    arrow2.line(to: CGPoint(x: a2x - arrowW * 0.65, y: a2y - arrowH * 0.45))
    arrow2.line(to: CGPoint(x: a2x, y: a2y - arrowH * 0.45))
    arrow2.close()
    
    ctx?.saveGState()
    let a2Shadow = NSShadow()
    a2Shadow.shadowColor = NSColor(red: 0.05, green: 0.95, blue: 0.45, alpha: 0.75)
    a2Shadow.shadowBlurRadius = s * 0.040
    a2Shadow.set()
    let a2Grad = NSGradient(
        starting: NSColor(red: 0.10, green: 0.95, blue: 0.50, alpha: 0.95),
        ending: NSColor(red: 0.00, green: 0.80, blue: 0.90, alpha: 0.95)
    )
    a2Grad?.draw(in: arrow2, angle: 180)
    ctx?.restoreGState()
    
    // -------------------------------------------------------------------------
    // 6. SPECULAR GLASS HIGHLIGHT & PRISMATIC TOP REFLECTION
    // -------------------------------------------------------------------------
    let sheenPath = NSBezierPath()
    sheenPath.move(to: CGPoint(x: rect.minX, y: rect.maxY - corner))
    sheenPath.curve(to: CGPoint(x: rect.maxX, y: rect.maxY - corner),
                    controlPoint1: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.maxY - rect.height * 0.30),
                    controlPoint2: CGPoint(x: rect.minX + rect.width * 0.75, y: rect.maxY - rect.height * 0.30))
    sheenPath.line(to: CGPoint(x: rect.maxX, y: rect.maxY))
    sheenPath.line(to: CGPoint(x: rect.minX, y: rect.maxY))
    sheenPath.close()
    
    let sheenGrad = NSGradient(
        starting: NSColor(white: 1.0, alpha: 0.24),
        ending: NSColor(white: 1.0, alpha: 0.02)
    )
    sheenGrad?.draw(in: sheenPath, angle: -90)
    
    // Squircle Bevel Rim Highlight (Ultra-fine liquid edge)
    squircle.lineWidth = max(1.0, s * 0.014)
    NSColor(white: 1.0, alpha: 0.45).setStroke()
    squircle.stroke()
    
    ctx?.restoreGState()
    img.unlockFocus()
    return img
}

let fm = FileManager.default
let iconsetDir = "AppIcon.iconset"
try? fm.removeItem(atPath: iconsetDir)
try? fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in sizes {
    let img = drawAndroidLiquidGlassIcon(size: size)
    if let tiff = img.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        let path = "\(iconsetDir)/\(name)"
        try? png.write(to: URL(fileURLWithPath: path))
    }
}

print("✅ Universal Android Liquid Glass Iconset generated successfully in \(iconsetDir)")
