#!/usr/bin/env swift

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size: CGFloat = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()

guard let context = CGContext(
    data: nil,
    width: Int(size),
    height: Int(size),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    print("Failed to create context")
    exit(1)
}

// White background
context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
context.fill(CGRect(x: 0, y: 0, width: size, height: size))

// Bar colors (your brand: muted blue, sage green, warm tan)
let colors: [(r: CGFloat, g: CGFloat, b: CGFloat)] = [
    (0.43, 0.60, 0.76),  // #6e98c2
    (0.54, 0.73, 0.63),  // #8abba2
    (0.76, 0.68, 0.58),  // #c2ad95
]

// Bar dimensions - ascending heights with pill shape
let barWidth: CGFloat = 160
let spacing: CGFloat = 60
let totalWidth = 3 * barWidth + 2 * spacing
let startX = (size - totalWidth) / 2
let bottomY: CGFloat = 220  // distance from bottom
let barHeights: [CGFloat] = [300, 480, 620]
let cornerRadius = barWidth / 2  // pill shape

for i in 0..<3 {
    let x = startX + CGFloat(i) * (barWidth + spacing)
    let height = barHeights[i]
    let y = bottomY  // CoreGraphics origin is bottom-left
    
    let rect = CGRect(x: x, y: y, width: barWidth, height: height)
    let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    
    // Subtle shadow
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -6), blur: 12, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.15))
    
    let color = colors[i]
    context.setFillColor(CGColor(red: color.r, green: color.g, blue: color.b, alpha: 1.0))
    context.addPath(path)
    context.fillPath()
    context.restoreGState()
}

// Save to file
guard let image = context.makeImage() else {
    print("Failed to create image")
    exit(1)
}

let outputPath = NSString(string: "~/Documents/repo/0-payload/Fundra/AppIcon.png").expandingTildeInPath
let url = URL(fileURLWithPath: outputPath)

guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    print("Failed to create image destination")
    exit(1)
}

CGImageDestinationAddImage(destination, image, nil)

if CGImageDestinationFinalize(destination) {
    print("✅ App icon saved to: \(outputPath)")
} else {
    print("Failed to save image")
    exit(1)
}
