import UIKit

extension UIColor {
    /// CGColor locked to sRGB. Without this, layer colors drift on P3 displays
    /// (CAGradientLayer interpolates in sRGB regardless of device gamut).
    var sRGBLockedCGColor: CGColor {
        guard let sRGB = CGColorSpace(name: CGColorSpace.sRGB) else { return cgColor }
        return cgColor.converted(to: sRGB, intent: .defaultIntent, options: nil) ?? cgColor
    }
}
