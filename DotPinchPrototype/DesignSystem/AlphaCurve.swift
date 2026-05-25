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

    // MARK: - chatContent residual alpha (§23 hybrid Z + alpha)

    /// Below this progress, chatContent is fully invisible (Z-fade is dominant
    /// in 0.55–1.0; alpha completes the hide in 0.55–1.0).
    static let chatContentAlphaIn: CGFloat = 0.55

    /// Above this progress, chatContent is fully opaque; Z-translation handles
    /// the apparent shrink via m34.
    static let chatContentAlphaFull: CGFloat = 1.0

    // MARK: - chatContent Z-translation (§23 substrate-pure distance-fade)

    /// Maximum Z-translation at progress=0 (cell-rest). Magnitude matches
    /// MorphTiming.unifiedArcZMagnitude (forward pinch-commit's sin-bell peak)
    /// for symmetric depth feel between forward and reverse.
    static let chatContentZMax: CGFloat = MorphTiming.unifiedArcZMagnitude

    // MARK: - precision

    /// Below this magnitude, chatRestRange is treated as degenerate (naturalH ≈ viewport.height).
    static let progressDenominatorEpsilon: CGFloat = 1e-6
}
