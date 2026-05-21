// Math primitives: rubber-band damping, projection, clamping, smoothstep.

import Foundation
import CoreGraphics

/// Rubber-band damping for out-of-range values. c=0.55 matches UIScrollView.
public func rubberband(
    value: CGFloat,
    range: ClosedRange<CGFloat>,
    interval: CGFloat,
    c: CGFloat = 0.55
) -> CGFloat {
    if range.contains(value) {
        return value
    }
    if value < range.lowerBound {
        let offset = range.lowerBound - value
        return range.lowerBound - rubberbandClamp(offset: offset, interval: interval, c: c)
    } else {
        let offset = value - range.upperBound
        return range.upperBound + rubberbandClamp(offset: offset, interval: interval, c: c)
    }
}

private func rubberbandClamp(offset: CGFloat, interval: CGFloat, c: CGFloat) -> CGFloat {
    (1.0 - (1.0 / (offset * c / interval + 1.0))) * interval
}

/// Closed-form integral of v(t) = v0 · decelerationRate^t. With decelerationRate = 0.998
/// (UIScrollView default), returns total travel distance from a given initial velocity.
public func project(initialVelocity: CGFloat, decelerationRate: CGFloat = 0.998) -> CGFloat {
    (initialVelocity / 1000.0) * decelerationRate / (1.0 - decelerationRate)
}

/// Clamp a value to a closed range, no rubber-banding.
public func clamp<T: Comparable>(_ value: T, _ minValue: T, _ maxValue: T) -> T {
    min(max(value, minValue), maxValue)
}

/// GLSL-style smoothstep — Hermite-interpolated S-curve from 0 → 1 over
/// `[edge0, edge1]`, clamped to [0, 1] outside the range. Continuous in
/// both value and first derivative at the edges.
public func smoothstep(_ edge0: CGFloat, _ edge1: CGFloat, _ x: CGFloat) -> CGFloat {
    let denom = edge1 - edge0
    guard abs(denom) > 1e-12 else { return x < edge0 ? 0 : 1 }
    let t = clamp((x - edge0) / denom, 0, 1)
    return t * t * (3 - 2 * t)
}
