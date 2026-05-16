// Visual-timing constants for the Conversation morph choreography. Separate
// from Gestures/PinchTuning.swift, which holds the gesture-physics constants
// (sensitivity, rubber-band, spring). These two have different reasons to
// change — gesture physics is reusable, morph timing is this feature's feel.

import CoreGraphics

enum MorphTiming {

    // MARK: - Blur ramp (Register 2 onset)

    /// Progress at which the blur ramp begins; below this, text is fully legible.
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

    // MARK: - Destination emergence (Stages 3 & 4)

    /// Progress range over which the destination card silhouette emerges.
    static let cardEmergeStart: CGFloat = 0.72
    static let cardEmergeEnd:   CGFloat = 0.85

    /// Progress range over which the destination labels fade in
    /// (begins only after the silhouette has resolved).
    static let labelEmergeStart: CGFloat = 0.85
    static let labelEmergeEnd:   CGFloat = 1.0

    // MARK: - Affordance materialization

    /// Affordance icons begin fading in past this progress.
    static let affordanceMaterializesAt: CGFloat = 0.6

    // MARK: - Completion threshold (binary shadow flip)

    /// Progress >= this counts as "settled at destination" — used for the binary
    /// shadow flip at .finished.
    static let completionEpsilon: CGFloat = 0.999
}
