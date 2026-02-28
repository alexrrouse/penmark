#!/usr/bin/env swift
// Generates Penmark app icon PNGs at all required macOS sizes.
// Run from repo root: swift scripts/generate_icon.swift

import AppKit
import CoreGraphics

let outputDir = "Sources/Assets.xcassets/AppIcon.appiconset"

// All sizes needed for a macOS app icon
let sizes = [16, 32, 64, 128, 256, 512, 1024]

for size in sizes {
    let s = CGFloat(size)

    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    ) else { fatalError("Could not create bitmap rep for size \(size)") }

    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    let cg = ctx.cgContext

    // ── Background gradient: indigo → blue ──────────────────────────────────
    let cs = CGColorSpace(name: CGColorSpace.displayP3)!
    let gradColors = [
        CGColor(colorSpace: cs, components: [0.22, 0.18, 0.82, 1.0])!, // #3830D1 indigo
        CGColor(colorSpace: cs, components: [0.05, 0.55, 0.95, 1.0])!, // #0D8CF2 blue
    ] as CFArray
    let gradient = CGGradient(colorsSpace: cs, colors: gradColors, locations: [0, 1])!
    cg.drawLinearGradient(gradient,
        start: CGPoint(x: 0, y: s),
        end:   CGPoint(x: s, y: 0),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

    // ── Document shape ───────────────────────────────────────────────────────
    let margin  = s * 0.17
    let dw      = s - margin * 2          // document width
    let dh      = dw * 1.28              // document height
    let dx      = margin
    let dy      = (s - dh) / 2
    let cr      = s * 0.07               // corner radius
    let fold    = s * 0.22               // folded corner size

    let doc = CGMutablePath()
    doc.move(to: CGPoint(x: dx + cr, y: dy))
    doc.addLine(to: CGPoint(x: dx + dw - fold, y: dy))
    doc.addLine(to: CGPoint(x: dx + dw, y: dy + fold))
    doc.addLine(to: CGPoint(x: dx + dw, y: dy + dh - cr))
    doc.addArc(center: CGPoint(x: dx + dw - cr, y: dy + dh - cr), radius: cr,
               startAngle: 0, endAngle: .pi / 2, clockwise: false)
    doc.addLine(to: CGPoint(x: dx + cr, y: dy + dh))
    doc.addArc(center: CGPoint(x: dx + cr, y: dy + dh - cr), radius: cr,
               startAngle: .pi / 2, endAngle: .pi, clockwise: false)
    doc.addLine(to: CGPoint(x: dx, y: dy + cr))
    doc.addArc(center: CGPoint(x: dx + cr, y: dy + cr), radius: cr,
               startAngle: .pi, endAngle: 3 * .pi / 2, clockwise: false)
    doc.closeSubpath()

    cg.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.96))
    cg.addPath(doc); cg.fillPath()

    // Fold shadow triangle
    let foldPath = CGMutablePath()
    foldPath.move(to: CGPoint(x: dx + dw - fold, y: dy))
    foldPath.addLine(to: CGPoint(x: dx + dw - fold, y: dy + fold))
    foldPath.addLine(to: CGPoint(x: dx + dw, y: dy + fold))
    foldPath.closeSubpath()
    cg.setFillColor(CGColor(srgbRed: 0.22, green: 0.18, blue: 0.82, alpha: 0.25))
    cg.addPath(foldPath); cg.fillPath()

    // ── "#" markdown symbol ──────────────────────────────────────────────────
    // Only draw the text mark for sizes >= 64 where it stays crisp
    if size >= 64 {
        let fontSize = dw * 0.44
        let font = NSFont.boldSystemFont(ofSize: fontSize)
        let color = NSColor(srgbRed: 0.22, green: 0.18, blue: 0.82, alpha: 0.85)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let str = NSAttributedString(string: "#", attributes: attrs)
        let sz = str.size()
        // Center the glyph on the document (slightly above center)
        let tx = dx + (dw - sz.width) / 2
        let ty = dy + (dh - sz.height) / 2 + dh * 0.03
        str.draw(at: NSPoint(x: tx, y: ty))
    }

    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("Could not create PNG for size \(size)")
    }

    let filename = "\(outputDir)/icon_\(size)x\(size).png"
    do {
        try data.write(to: URL(fileURLWithPath: filename))
        print("✓ \(filename)")
    } catch {
        fatalError("Failed to write \(filename): \(error)")
    }
}

print("Done — \(sizes.count) icons written to \(outputDir)/")
