// Single source of truth for the numeric constants governing the pinch-to-memory
// similarity transform. Invariant: no numeric literal here may also appear inline
// in the codebase — references go through this enum.

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

    // MARK: - Affordance materialization

    /// Progress past which affordance icons begin fading in.
    static let affordanceMaterializesAt: CGFloat = 0.6

    // MARK: - Spring physics

    /// Spring response (s) — how quickly the spring settles from unit displacement.
    static let springResponse: CGFloat = 0.55

    /// Damping ratio. Near-critical to keep progress monotonic across [0, 1].
    static let springDamping: CGFloat = 0.85

    // MARK: - Velocity projection (WWDC 2018 fluid-interfaces)

    /// Minimum normalized velocity at which gesture velocity is injected into
    /// the spring on .ended; below this the spring settles unforced.
    static let velocityHandoffFloorPerSecond: CGFloat = 0.1

    // MARK: - Conversation content

    /// Number of past messages laid out above the current message.
    static let pastMessageCount: Int = 5
}
