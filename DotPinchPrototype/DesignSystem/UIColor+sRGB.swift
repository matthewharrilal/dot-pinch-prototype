import UIKit

extension UIColor {
    var sRGBLockedCGColor: CGColor {
        guard let sRGB = CGColorSpace(name: CGColorSpace.sRGB) else { return cgColor }
        let result = cgColor.converted(to: sRGB, intent: .defaultIntent, options: nil) ?? cgColor
        #if DEBUG
        assert(result.colorSpace?.name == CGColorSpace.sRGB,
               "UIColor.sRGBLockedCGColor: conversion produced non-sRGB color space")
        #endif
        return result
    }
}
