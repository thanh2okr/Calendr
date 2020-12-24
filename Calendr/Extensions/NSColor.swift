//
//  NSColor.swift
//  Calendr
//
//  Created by Paker on 07/12/2022.
//

import AppKit

extension NSColor {

    /// Store as 8-char hex "RRGGBBAA" in UserDefaults
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r: Double
        let g: Double
        let b: Double
        let a: Double
        switch cleaned.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
            a = 1
        case 8:
            r = Double((int >> 24) & 0xFF) / 255
            g = Double((int >> 16) & 0xFF) / 255
            b = Double((int >> 8) & 0xFF) / 255
            a = Double(int & 0xFF) / 255
        default:
            r = 1; g = 59.0/255; b = 48.0/255; a = 1
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    var hexString: String {
        guard let c = usingColorSpace(.sRGB) else { return "FF3B30FF" }
        return String(
            format: "%02X%02X%02X%02X",
            Int((c.redComponent * 255).rounded()),
            Int((c.greenComponent * 255).rounded()),
            Int((c.blueComponent * 255).rounded()),
            Int((c.alphaComponent * 255).rounded())
        )
    }

    // 🔨 Fix issue with cgColor returning the wrong color after switching between dark & light themes
    var effectiveCGColor: CGColor {
        var color: CGColor!
        NSApp.effectiveAppearance.performAsCurrentDrawingAppearance {
            color = cgColor
        }
        return color
    }

    func striped(alpha: CGFloat = 1) -> NSColor {

        let stripes = CIFilter.stripesGenerator()
        stripes.color0 = CIColor(color: self.withAlphaComponent(alpha))!
        stripes.color1 = .clear
        stripes.width = 2.5
        stripes.sharpness = 0

        let rotated = CIFilter.affineClamp()
        rotated.inputImage = stripes.outputImage!
        rotated.transform = CGAffineTransform(rotationAngle: -.pi / 4)

        let ciImage = rotated.outputImage!.cropped(to: CGRect(x: 0, y: 0, width: 300, height: 300))
        let rep = NSCIImageRep(ciImage: ciImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)

        return NSColor(patternImage: nsImage)
    }
}
