import AppKit

guard CommandLine.arguments.count == 3 else {
    fputs("usage: generate-icon.swift <iconset-directory> <icns-file>\n", stderr)
    exit(2)
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let icnsURL = URL(fileURLWithPath: CommandLine.arguments[2])
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let variants: [(String, Int)] = [
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

func drawIcon(size: Int) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw CocoaError(.fileWriteUnknown)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    let s = CGFloat(size)
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: s, height: s).fill()

    let tileRect = NSRect(x: s * 0.04, y: s * 0.04, width: s * 0.92, height: s * 0.92)
    let tile = NSBezierPath(roundedRect: tileRect, xRadius: s * 0.22, yRadius: s * 0.22)
    NSColor(red: 0.06, green: 0.08, blue: 0.12, alpha: 1).setFill()
    tile.fill()

    // BigLights: a magnifying-glass over a growing button. Three
    // same-colored circles (not traffic-light colors) scale up from left
    // to right, suggesting buttons being enlarged.
    let buttonColor = NSColor(red: 0.30, green: 0.55, blue: 0.95, alpha: 1)
    let diameters: [CGFloat] = [s * 0.16, s * 0.21, s * 0.27]
    let gap = s * 0.06
    let totalWidth = diameters.reduce(0, +) + gap * 2
    let startX = (s - totalWidth) / 2
    let baselineY = s * 0.28
    for (index, diameter) in diameters.enumerated() {
        let circleRect = NSRect(
            x: startX + diameters.prefix(index).reduce(0, +) + CGFloat(index) * gap,
            y: baselineY,
            width: diameter,
            height: diameter
        )
        buttonColor.setFill()
        NSBezierPath(ovalIn: circleRect).fill()
        // Glossy highlight for a lit-glass feel.
        let highlight = NSBezierPath(
            ovalIn: NSRect(
                x: circleRect.minX + circleRect.width * 0.18,
                y: circleRect.minY + circleRect.height * 0.55,
                width: circleRect.width * 0.42,
                height: circleRect.height * 0.26
            )
        )
        NSColor.white.withAlphaComponent(0.30).setFill()
        highlight.fill()
    }

    // Magnifying-glass lens overlapping the largest button.
    let lensDiameter = s * 0.42
    let lensRect = NSRect(
        x: s * 0.56,
        y: s * 0.52,
        width: lensDiameter,
        height: lensDiameter
    )
    NSColor(red: 0.90, green: 0.93, blue: 0.98, alpha: 0.92).setFill()
    NSBezierPath(ovalIn: lensRect).fill()
    let lensHandle = NSBezierPath()
    lensHandle.lineWidth = max(1, s * 0.055)
    lensHandle.lineCapStyle = .round
    NSColor(red: 0.85, green: 0.88, blue: 0.95, alpha: 1).setStroke()
    lensHandle.move(to: NSPoint(x: lensRect.maxX - lensDiameter * 0.12, y: lensRect.minY + lensDiameter * 0.12))
    lensHandle.line(to: NSPoint(x: lensRect.maxX + lensDiameter * 0.30, y: lensRect.minY - lensDiameter * 0.30))
    lensHandle.stroke()

    NSGraphicsContext.restoreGraphicsState()
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    return data
}

var rendered: [Int: Data] = [:]
for (filename, size) in variants {
    let data = try rendered[size] ?? drawIcon(size: size)
    rendered[size] = data
    try data.write(to: outputDirectory.appendingPathComponent(filename))
}

func appendUInt32(_ value: UInt32, to data: inout Data) {
    var bigEndian = value.bigEndian
    withUnsafeBytes(of: &bigEndian) { data.append(contentsOf: $0) }
}

let icnsEntries: [(String, Int)] = [
    ("icp4", 16), ("icp5", 32), ("icp6", 64),
    ("ic07", 128), ("ic08", 256), ("ic09", 512), ("ic10", 1024)
]
var body = Data()
for (type, size) in icnsEntries {
    guard let png = rendered[size], let typeData = type.data(using: .ascii) else { continue }
    body.append(typeData)
    appendUInt32(UInt32(png.count + 8), to: &body)
    body.append(png)
}
var icns = Data("icns".utf8)
appendUInt32(UInt32(body.count + 8), to: &icns)
icns.append(body)
try FileManager.default.createDirectory(at: icnsURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try icns.write(to: icnsURL)
