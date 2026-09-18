import AppKit
import Foundation

struct Palette {
    let name: String
    let primary: NSColor
    let secondary: NSColor
}

guard CommandLine.arguments.count == 2 else {
    fatalError("Usage: swift render-widget-backgrounds.swift <output-directory>")
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let palettes = [
    Palette(name: "WidgetGlowCloud", primary: NSColor(calibratedRed: 0.30, green: 0.72, blue: 1.00, alpha: 1), secondary: NSColor(calibratedRed: 0.35, green: 0.37, blue: 1.00, alpha: 1)),
    Palette(name: "WidgetGlowRain", primary: NSColor(calibratedRed: 0.08, green: 0.66, blue: 1.00, alpha: 1), secondary: NSColor(calibratedRed: 0.18, green: 0.24, blue: 0.94, alpha: 1)),
    Palette(name: "WidgetGlowSun", primary: NSColor(calibratedRed: 1.00, green: 0.66, blue: 0.20, alpha: 1), secondary: NSColor(calibratedRed: 1.00, green: 0.31, blue: 0.43, alpha: 1)),
    Palette(name: "WidgetGlowIce", primary: NSColor(calibratedRed: 0.55, green: 0.94, blue: 1.00, alpha: 1), secondary: NSColor(calibratedRed: 0.55, green: 0.66, blue: 1.00, alpha: 1))
]

func cgColor(_ color: NSColor, alpha: CGFloat) -> CGColor {
    color.withAlphaComponent(alpha).cgColor
}

for palette in palettes {
    let width = 1200
    let height = 600
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { fatalError("Could not create bitmap") }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let context = NSGraphicsContext.current!.cgContext
    context.setFillColor(NSColor(calibratedRed: 0.025, green: 0.035, blue: 0.055, alpha: 1).cgColor)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))

    func glow(center: CGPoint, radius: CGFloat, color: NSColor, alpha: CGFloat) {
        let colors = [cgColor(color, alpha: alpha), cgColor(color, alpha: 0)] as CFArray
        let locations: [CGFloat] = [0, 1]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations)!
        context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [.drawsAfterEndLocation])
    }

    glow(center: CGPoint(x: 235, y: 425), radius: 430, color: palette.primary, alpha: 0.54)
    glow(center: CGPoint(x: 985, y: 120), radius: 390, color: palette.secondary, alpha: 0.36)
    glow(center: CGPoint(x: 640, y: 610), radius: 330, color: NSColor.white, alpha: 0.10)

    let topLine = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [cgColor(.white, alpha: 0.20), cgColor(.white, alpha: 0)] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(topLine, start: CGPoint(x: 0, y: CGFloat(height)), end: CGPoint(x: 0, y: CGFloat(height) * 0.45), options: [])
    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("Could not encode PNG") }
    try png.write(to: outputDirectory.appendingPathComponent("\(palette.name).png"))
}
