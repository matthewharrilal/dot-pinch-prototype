// Math primitives bottled from Wave's UIMathUtilities and WWDC 2018 Session 803:
// rubber-band damping, projection, velocity normalization, clamping.

import Foundation
import CoreGraphics

/// Rubber-band damping for out-of-range values. c=0.55 matches UIScrollView.
public func rubberband(
    value: CGFloat,
    range: ClosedRange<CGFloat>,
    interval: CGFloat,
    c: CGFloat = 0.55
) -> CGFloat {
    // Per Wave's implementation: the formula maps an out-of-range value to a damped
    // version with exponentially-decreasing slope at the edge.
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

/// Project where a value will rest given an initial velocity and exponential decay.
///
/// Closed-form integral of v(t) = v0 · decelerationRate^t. With decelerationRate = 0.998
/// (UIScrollView default), returns total travel distance from a given initial velocity.
public func project(initialVelocity: CGFloat, decelerationRate: CGFloat = 0.998) -> CGFloat {
    (initialVelocity / 1000.0) * decelerationRate / (1.0 - decelerationRate)
}

/// WWDC 2018 Session 803 velocity-normalization formula.
///
/// Given the gesture's terminal velocity (in property units per second) and the remaining
/// distance to the animation target, returns the dimensionless ratio that goes into
/// `UISpringTimingParameters.initialVelocity` or directly into `SpringAnimator.velocity`.
///
/// Example: if `gestureVelocity = 600` pts/sec and `target - current = 200` pts,
/// the normalized velocity is 3.0 — meaning the spring starts moving 3× its natural
/// per-second response rate.
public func normalizedVelocity(gestureVelocity: CGFloat, target: CGFloat, current: CGFloat) -> CGFloat {
    let distance = target - current
    guard abs(distance) > 0.0001 else { return 0 }
    return gestureVelocity / distance
}

/// Clamp a value to a closed range, no rubber-banding.
public func clamp<T: Comparable>(_ value: T, _ minValue: T, _ maxValue: T) -> T {
    min(max(value, minValue), maxValue)
}
