// Gesture-physics constants for the pinch-to-memory mechanic. Reusable across
// gesture/morph implementations — these describe HOW the gesture maps to
// progress, not WHEN the conversation morph's visual effects fire. Visual-
// timing lives in Conversation/MorphTiming.swift.

import CoreGraphics

enum PinchTuning {

    // MARK: - Similarity transform

    /// Baseline scale at progress=0 (card at full size).
    static let baselineSimilarityS: CGFloat = 1.0

    /// Destination scale at progress=1. Same scalar applied to width AND height.
    static let destinationSimilarityS: CGFloat = 0.4

    /// Anchor point in normalized layer bounds (LTR). Fixed point of the similarity
    /// transform — composed via translation matrix:  T(p) = translate(anchor·(1-s)) · scale(s).
    static let anchorPoint: CGPoint = CGPoint(x: 0.4, y: 0.85)

    // MARK: - Pinch gesture mapping

    /// Sensitivity for pinch.scale → progress. k=2.5 → pinch.scale ≈ 0.6 reaches progress 1.0.
    static let pinchSensitivity: CGFloat = 2.5

    /// Rubber-band damping coefficient. UIScrollView-tuned (Apple's c = 0.55).
    static let rubberBandDampingC: CGFloat = 0.55

    /// Rubber-band interval (width over which the damping curve operates).
    static let rubberBandInterval: CGFloat = 0.2

    /// Progress range allowed during active gesture, before rubber-band damping.
    /// Slightly wider than [0, 1] so the gesture can overshoot perceptibly.
    static let gestureClampLowerBound: CGFloat = -0.2
    static let gestureClampUpperBound: CGFloat = 1.2

    // MARK: - Commit / release

    /// On gesture .ended, the projected rest is compared against this threshold;
    /// past it the morph commits to destination, below it returns to baseline.
    static let commitProjectionThreshold: CGFloat = 0.4

    /// Minimum normalized velocity at which gesture velocity is injected into the
    /// spring on .ended; below this the spring settles unforced.
    static let velocityHandoffFloorPerSecond: CGFloat = 0.1

    // MARK: - Tap-to-expand

    /// Minimum progress at which the destination is "ready" for a tap-to-expand.
    static let tapToExpandReadyThreshold: CGFloat = 0.9

    /// Velocity injected when the user taps the destination card to expand back.
    /// Negative — drives progress toward 0.
    static let tapToExpandKickVelocity: CGFloat = -2.0

    // MARK: - Spring physics

    /// Spring response (s) — how quickly the spring settles from unit displacement.
    static let springResponse: CGFloat = 0.55

    /// Damping ratio. Near-critical to keep progress monotonic across [0, 1].
    static let springDamping: CGFloat = 0.85
}
