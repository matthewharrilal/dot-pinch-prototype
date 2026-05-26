// PHash.swift — perceptual hash for visual-diff comparison.
//
// Per HANDOFF-CHECKLIST.md §47.6 N15 and T6 finding: visual-diff infrastructure
// compares captured screenshots against golden frames from `_frames/dot_pinch.mov`.
// pHash + Hamming distance gives a cheap (~80 LOC) per-frame similarity score
// that tolerates rendering noise while catching structural divergence.
//
// Reference: http://www.phash.org/docs/pubs/thesis_zauner.pdf
//
// Algorithm:
//   1. Downsample image to 32x32 grayscale
//   2. Compute DCT
//   3. Take top-left 8x8 of DCT coefficients (low-frequency)
//   4. Compute median DCT value (excluding DC component)
//   5. Bit = 1 if coefficient > median, else 0
//   6. Pack 64 bits into UInt64 hash
//
// Comparison: Hamming distance between two hashes. ≤ 5/64 typically same image.

import CoreImage
import Foundation

#if DEBUG

public struct PHash {
    public let bits: UInt64

    public static func compute(from cgImage: CGImage) -> PHash? {
        guard let downsampled = downsample(cgImage, to: CGSize(width: 32, height: 32)) else { return nil }
        let grayscale = toGrayscale(downsampled)
        let dct = computeDCT(grayscale)
        return PHash(bits: pack(dct: dct))
    }

    public func hammingDistance(to other: PHash) -> Int {
        (bits ^ other.bits).nonzeroBitCount
    }

    public func isSimilar(to other: PHash, threshold: Int = 5) -> Bool {
        hammingDistance(to: other) <= threshold
    }

    // MARK: - Pipeline stubs (implementation deferred to visual-diff wave)

    private static func downsample(_ image: CGImage, to size: CGSize) -> CGImage? {
        let context = CIContext()
        let ciImage = CIImage(cgImage: image)
        let scaleX = size.width / CGFloat(image.width)
        let scaleY = size.height / CGFloat(image.height)
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        return context.createCGImage(scaled, from: scaled.extent)
    }

    private static func toGrayscale(_ image: CGImage) -> [Float] {
        let w = image.width, h = image.height
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        let context = CGContext(data: &pixels, width: w, height: h,
                                bitsPerComponent: 8, bytesPerRow: w * 4,
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        context?.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        var gray = [Float](repeating: 0, count: w * h)
        for i in 0..<(w * h) {
            let r = Float(pixels[i * 4])
            let g = Float(pixels[i * 4 + 1])
            let b = Float(pixels[i * 4 + 2])
            gray[i] = 0.299 * r + 0.587 * g + 0.114 * b
        }
        return gray
    }

    private static func computeDCT(_ pixels: [Float]) -> [Float] {
        // PLACEHOLDER: real DCT computation deferred to visual-diff wave.
        // For now returns the input (identity DCT) so the harness can wire up.
        // A proper DCT-II implementation goes here for ≤32x32 ~ negligible cost.
        return pixels
    }

    private static func pack(dct: [Float]) -> UInt64 {
        // Take top-left 8x8 (64 coefficients) of the 32x32 DCT.
        var coeffs: [Float] = []
        for row in 0..<8 {
            for col in 0..<8 {
                let idx = row * 32 + col
                if idx < dct.count { coeffs.append(dct[idx]) }
            }
        }
        guard coeffs.count == 64 else { return 0 }
        let sorted = coeffs.dropFirst().sorted()  // exclude DC component
        let median = sorted[sorted.count / 2]
        var bits: UInt64 = 0
        for (i, c) in coeffs.enumerated() {
            if c > median { bits |= (UInt64(1) << i) }
        }
        return bits
    }
}

#endif
