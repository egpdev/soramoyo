import AppKit

let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Assets/Aura-AppIcon.png")
let size = CGFloat(1024)
let image = NSImage(size: NSSize(width: size, height: size))

image.lockFocus()
guard let context = NSGraphicsContext.current?.cgContext else { fatalError("Could not create drawing context") }

let canvas = NSRect(x: 0, y: 0, width: size, height: size)
NSColor(red: 0.035, green: 0.045, blue: 0.060, alpha: 1).setFill()
NSBezierPath(roundedRect: canvas, xRadius: 220, yRadius: 220).fill()

context.saveGState()
context.setShadow(offset: .zero, blur: 44, color: NSColor(calibratedRed: 0.44, green: 0.70, blue: 0.95, alpha: 0.42).cgColor)
let outer = NSBezierPath(ovalIn: NSRect(x: 190, y: 190, width: 644, height: 644))
outer.lineWidth = 42
NSColor(calibratedRed: 0.64, green: 0.82, blue: 0.98, alpha: 0.90).setStroke()
outer.stroke()
context.restoreGState()

let inner = NSBezierPath(ovalIn: NSRect(x: 244, y: 244, width: 536, height: 536))
inner.lineWidth = 5
NSColor.white.withAlphaComponent(0.42).setStroke()
inner.stroke()

let cloudColor = NSColor(calibratedRed: 0.72, green: 0.87, blue: 1, alpha: 0.98)
cloudColor.setFill()
NSBezierPath(roundedRect: NSRect(x: 348, y: 405, width: 328, height: 118), xRadius: 59, yRadius: 59).fill()
NSBezierPath(ovalIn: NSRect(x: 398, y: 458, width: 176, height: 176)).fill()
NSBezierPath(ovalIn: NSRect(x: 520, y: 430, width: 172, height: 172)).fill()

image.unlockFocus()
guard let data = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: data),
      let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("Could not encode icon") }
try png.write(to: output)
