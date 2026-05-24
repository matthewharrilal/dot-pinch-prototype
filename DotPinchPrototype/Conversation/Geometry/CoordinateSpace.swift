import CoreGraphics
import Foundation

struct PageY: Sendable, Equatable {
    let raw: CGFloat
    init(_ raw: CGFloat) { self.raw = raw }
}

struct ViewportY: Sendable, Equatable {
    let raw: CGFloat
    init(_ raw: CGFloat) { self.raw = raw }
}

struct ScaleFactor: Sendable, Equatable {
    let raw: CGFloat
    init(_ raw: CGFloat) { self.raw = raw }
}

struct DampingRatio: Sendable, Equatable {
    let raw: CGFloat
    init(_ raw: CGFloat) {
        precondition(raw >= 0, "DampingRatio must be non-negative; got \(raw)")
        self.raw = raw
    }
}
