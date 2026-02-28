#!/usr/bin/env swift
// Generates Penmark app icon PNGs at all required macOS sizes.
// Design: A diagonal fountain pen on a deep navy-to-purple gradient.
// Run from repo root: swift scripts/generate_icon.swift

import AppKit
import CoreGraphics

let outputDir = "Sources/Assets.xcassets/AppIcon.appiconset"
let sizes = [16, 32, 64, 128, 256, 512, 1024]

let cs = CGColorSpace(name: CGColorSpace.displayP3)!

func p3(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1.0) -> CGColor {
    CGColor(colorSpace: cs, components: [r, g, b, a])!
}

// Draws the pen outline path (local coords: cap at +y, nib tip at -y, centered at origin)
func penPath(penTop: CGFloat, nibTip: CGFloat, nibTrans: CGFloat, halfW: CGFloat) -> CGMutablePath {
    let capRadius = halfW
    let path = CGMutablePath()
    path.addArc(center: CGPoint(x: 0, y: penTop - capRadius),
                radius: capRadius, startAngle: 0, endAngle: .pi, clockwise: false)
    path.addLine(to: CGPoint(x: -halfW, y: nibTrans))
    path.addLine(to: CGPoint(x: 0, y: nibTip))
    path.addLine(to: CGPoint(x: halfW, y: nibTrans))
    path.addLine(to: CGPoint(x: halfW, y: penTop - capRadius))
    path.closeSubpath()
    return path
}

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
    guard let gfxCtx = NSGraphicsContext(bitmapImageRep: rep) else { fatalError() }
    NSGraphicsContext.current = gfxCtx
    let cg = gfxCtx.cgContext

    // ── Background: deep navy (top-left) → vivid purple (bottom-right) ──────
    let bgColors = [p3(0.08, 0.10, 0.28), p3(0.45, 0.22, 0.72)] as CFArray
    let bgGrad = CGGradient(colorsSpace: cs, colors: bgColors, locations: [0, 1])!
    cg.drawLinearGradient(bgGrad,
        start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

    // ── Pen ─────────────────────────────────────────────────────────────────
    // Rotate so cap → upper-left, nib → lower-right (π/4 CCW in CG coords)
    cg.saveGState()
    cg.translateBy(x: s * 0.5, y: s * 0.5)
    cg.rotate(by: .pi / 4)

    let pH      = s * 0.375        // half the pen length from center
    let penTop  = pH
    let nibTip  = -pH
    let nibTrans = -pH * 0.36      // barrel-to-nib shoulder
    let halfW   = s * 0.062        // half-width of barrel

    // Soft glow behind pen (blends it into the background)
    if size >= 32 {
        cg.saveGState()
        let glowR = halfW * 4.5
        let glowCenterY = (penTop + nibTip) * 0.5
        let glowColors = [p3(0.70, 0.55, 0.92, 0.25), p3(0.70, 0.55, 0.92, 0.0)] as CFArray
        let glowGrad = CGGradient(colorsSpace: cs, colors: glowColors, locations: [0, 1])!
        cg.drawRadialGradient(glowGrad,
            startCenter: CGPoint(x: 0, y: glowCenterY), startRadius: 0,
            endCenter: CGPoint(x: 0, y: glowCenterY), endRadius: glowR,
            options: [])
        cg.restoreGState()
    }

    // Drop shadow (offset toward lower-right in local space)
    if size >= 32 {
        cg.saveGState()
        cg.translateBy(x: s * 0.018, y: -s * 0.018)
        cg.addPath(penPath(penTop: penTop, nibTip: nibTip, nibTrans: nibTrans, halfW: halfW))
        cg.setFillColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.18))
        cg.fillPath()
        cg.restoreGState()
    }

    // Main pen body — lavender-tinted gradient (cap lighter, nib darker)
    cg.saveGState()
    cg.addPath(penPath(penTop: penTop, nibTip: nibTip, nibTrans: nibTrans, halfW: halfW))
    cg.clip()
    let penColors = [p3(0.88, 0.84, 0.95), p3(0.72, 0.65, 0.85)] as CFArray
    let penGrad = CGGradient(colorsSpace: cs, colors: penColors, locations: [0, 1])!
    cg.drawLinearGradient(penGrad,
        start: CGPoint(x: 0, y: penTop), end: CGPoint(x: 0, y: nibTip),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    cg.restoreGState()

    // Subtle outline to give the pen definition without harsh edges
    if size >= 32 {
        cg.addPath(penPath(penTop: penTop, nibTip: nibTip, nibTrans: nibTrans, halfW: halfW))
        cg.setStrokeColor(p3(0.55, 0.42, 0.78, 0.30))
        cg.setLineWidth(max(0.5, s * 0.005))
        cg.strokePath()
    }

    // Accent ring at barrel/nib junction
    if size >= 32 {
        let bandH = max(1.5, s * 0.020)
        let bandRect = CGRect(x: -halfW, y: nibTrans - bandH * 0.5,
                               width: halfW * 2, height: bandH)
        cg.setFillColor(p3(0.50, 0.32, 0.78, 0.75))
        cg.fill(bandRect)
    }

    // Glossy highlight stripe down the barrel center
    if size >= 64 {
        let hw = halfW * 0.18
        let hTop = penTop - halfW - s * 0.025
        let hBot = nibTrans + s * 0.045
        let highlightRect = CGRect(x: -hw, y: hBot, width: hw * 2, height: hTop - hBot)
        let hr = hw
        let hPath = CGMutablePath()
        hPath.addRoundedRect(in: highlightRect, cornerWidth: hr, cornerHeight: hr)
        cg.addPath(hPath)
        cg.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.30))
        cg.fillPath()
    }

    // Nib slit (the groove in a real fountain pen nib)
    if size >= 32 {
        let slitPath = CGMutablePath()
        slitPath.move(to:    CGPoint(x: 0, y: nibTrans - s * 0.012))
        slitPath.addLine(to: CGPoint(x: 0, y: nibTip + s * 0.048))
        cg.addPath(slitPath)
        cg.setStrokeColor(p3(0.38, 0.20, 0.62, 0.50))
        cg.setLineWidth(max(0.5, s * 0.009))
        cg.setLineCap(.round)
        cg.strokePath()
    }

    // Ink drop at nib tip (visible at 128+)
    if size >= 128 {
        let dr = s * 0.025
        cg.addEllipse(in: CGRect(x: -dr, y: nibTip - dr * 0.4, width: dr * 2, height: dr * 2))
        cg.setFillColor(p3(0.50, 0.32, 0.78, 0.85))
        cg.fillPath()
    }

    cg.restoreGState()

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
