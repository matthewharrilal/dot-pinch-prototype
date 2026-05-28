// AlphaCurve — smoothstep range thresholds for per-progress alpha curves
// driven by CellView.setCamera. Extracted from inline literals per P2.11
// magic-number doctrine. Tokens scoped per concern (cell-rest chrome,
// chat-rest affordance, chatContent residual, Z-translation magnitude).

import CoreGraphics
import Foundation

enum AlphaCurve {

    // MARK: - cell-rest chrome (labelStack + pinchGlyph)

    /// Fade-in starts as progress drops below this threshold.
    static let cellRestChromeFull: CGFloat = 0.57

    /// Fully visible at and below this threshold.
    static let cellRestChromeIn: CGFloat = 0.33

    // MARK: - chat-rest affordance (inward arrows; §21)

    static let chatRestAffordanceIn: CGFloat = 0.33
    static let chatRestAffordanceFull: CGFloat = 0.57

    // MARK: - precision

    /// Below this magnitude, chatRestRange is treated as degenerate (naturalH ≈ viewport.height).
    static let progressDenominatorEpsilon: CGFloat = 1e-6

    // Shadow gating + labelStack appearance bands superseded by
    // `StageOrdering.cellShadowBand(chatRestScale:)` and
    // `StageOrdering.cellRestChromeBand(chatRestScale:)` — fractional bands derived
    // per-cell so they scale with chatRestScale (production ≠ test fixture).
    // Absolute constants removed to prevent drift from the prose-aligned ordering.
}
