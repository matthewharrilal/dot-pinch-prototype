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

    // MARK: - Blur & illegibility (Register 2 onset)

    /// Progress at which the blur ramp begins. Below this, text is fully legible.
    static let illegibilityRampStart: CGFloat = 0.30

    /// Progress at which the blur ramp completes — text fully unreadable.
    static let illegibilityRampComplete: CGFloat = 0.40

    // MARK: - Chat-surface dissolve (Stage 2 staggered mask)

    /// Progress at which the chat surface begins dissolving via the bottom-up mask.
    static let chatDissolveStart: CGFloat = 0.60

    /// Progress at which the dissolve is complete (chat surface fully transparent).
    static let chatDissolveEnd: CGFloat = 0.75

    /// Fraction of the dissolve phase over which the BOTTOM of the chat fades.
    /// Bottom fades from phase 0 → dissolveBottomFadeFraction.
    static let dissolveBottomFadeFraction: CGFloat = 0.7

    /// Offset into the dissolve phase at which the TOP begins fading.
    /// Top fades from phase dissolveTopFadeOffset → 1.0.
    static let dissolveTopFadeOffset: CGFloat = 0.3

    // MARK: - Destination emergence (Stage 3 & 4)

    /// Progress range over which the destination card silhouette emerges.
    static let cardEmergeStart: CGFloat = 0.72
    static let cardEmergeEnd:   CGFloat = 0.85

    /// Progress range over which the destination card's text labels fade in
    /// (begins only after the silhouette has resolved).
    static let labelEmergeStart: CGFloat = 0.85
    static let labelEmergeEnd:   CGFloat = 1.0

    // MARK: - Commit / settle thresholds

    /// On gesture .ended, the projected rest is compared against this threshold;
    /// past it the morph commits to destination, below it returns to baseline.
    static let commitProjectionThreshold: CGFloat = 0.4

    /// Affordance icons begin fading in past this progress.
    static let affordanceMaterializesAt: CGFloat = 0.6

    /// Progress range allowed during active gesture, before rubber-band damping.
    /// Slightly wider than [0, 1] so the gesture can overshoot perceptibly.
    static let gestureClampLowerBound: CGFloat = -0.2
    static let gestureClampUpperBound: CGFloat = 1.2

    /// Rubber-band interval (width over which the damping curve operates).
    static let rubberBandInterval: CGFloat = 0.2

    /// Tap-to-expand: minimum progress at which the destination is "ready" for a tap.
    static let tapToExpandReadyThreshold: CGFloat = 0.9

    /// Velocity injected when the user taps the destination card to expand back.
    /// Negative — drives progress toward 0.
    static let tapToExpandKickVelocity: CGFloat = -2.0

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
