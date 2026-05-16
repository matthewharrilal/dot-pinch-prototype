// UIImage+DepthCue.swift
// Pixel-analysis helpers used by DepthCueRefusalTests. Kept in a separate file
// so the tests read as a checklist of refusals, not as an image-processing
// library. All routines operate on CGImage data directly — no Vision, no CI.

import UIKit

extension UIImage {
    func dpp_detectCardRect() -> CGRect? {
        guard let cg = cgImage, let data = cg.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return nil }
        let w = cg.width, h = cg.height, bpr = cg.bytesPerRow
        let bg = (ptr[0], ptr[1], ptr[2])
        func differs(_ x: Int, _ y: Int) -> Bool {
            let i = y * bpr + x * 4
            return abs(Int(ptr[i]) - Int(bg.0)) + abs(Int(ptr[i + 1]) - Int(bg.1)) + abs(Int(ptr[i + 2]) - Int(bg.2)) > 24
        }
        var minX = w, maxX = 0, minY = h, maxY = 0
        var stride = max(1, w / 200)
        for y in stride(from: 0, to: h, by: stride) {
            for x in stride(from: 0, to: w, by: stride) where differs(x, y) {
                if x < minX { minX = x }
                if x > maxX { maxX = x }
                if y < minY { minY = y }
                if y > maxY { maxY = y }
            }
        }
        guard maxX > minX, maxY > minY else { return nil }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    func dpp_localGradientPeak(inRect rect: CGRect, at normalized: CGPoint) -> CGFloat {
        guard let cg = cgImage, let data = cg.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return 0 }
        let bpr = cg.bytesPerRow
        let cx = Int(rect.minX + rect.width * normalized.x)
        let cy = Int(rect.minY + rect.height * normalized.y)
        var peak: Int = 0
        for dy in -6...6 {
            for dx in -6...6 {
                let i = (cy + dy) * bpr + (cx + dx) * 4
                let j = (cy + dy) * bpr + (cx + dx + 1) * 4
                let d = abs(Int(ptr[i]) - Int(ptr[j])) + abs(Int(ptr[i + 1]) - Int(ptr[j + 1]))
                if d > peak { peak = d }
            }
        }
        return CGFloat(peak) / 255.0
    }

    /// Returns the angle in degrees between the card's bottom edge and the
    /// screen x-axis. A non-zero value implies converging lines → vanishing
    /// point → refusal #6 violated.
    func dpp_baselineAngleDegrees() -> CGFloat {
        guard let r = dpp_detectCardRect(), let cg = cgImage,
              let data = cg.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return 0 }
        let bpr = cg.bytesPerRow
        // Walk along the bottom edge of the detected rect — for each x, find
        // the first y from the bottom whose pixel differs from background.
        let bg = (ptr[0], ptr[1], ptr[2])
        func differs(_ x: Int, _ y: Int) -> Bool {
            let i = y * bpr + x * 4
            return abs(Int(ptr[i]) - Int(bg.0)) + abs(Int(ptr[i + 1]) - Int(bg.1)) + abs(Int(ptr[i + 2]) - Int(bg.2)) > 24
        }
        var xs: [CGFloat] = [], ys: [CGFloat] = []
        let step = max(1, Int(r.width) / 32)
        for x in stride(from: Int(r.minX), to: Int(r.maxX), by: step) {
            var y = Int(r.maxY)
            while y > Int(r.minY) && !differs(x, y) { y -= 1 }
            xs.append(CGFloat(x)); ys.append(CGFloat(y))
        }
        guard xs.count > 2 else { return 0 }
        let mx = xs.reduce(0, +) / CGFloat(xs.count)
        let my = ys.reduce(0, +) / CGFloat(ys.count)
        var num: CGFloat = 0, den: CGFloat = 0
        for i in 0..<xs.count {
            num += (xs[i] - mx) * (ys[i] - my)
            den += (xs[i] - mx) * (xs[i] - mx)
        }
        let slope = den == 0 ? 0 : num / den
        return atan(slope) * 180 / .pi
    }
}
