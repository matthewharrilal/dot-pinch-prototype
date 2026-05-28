import CoreGraphics
import Foundation

/// Single source of truth for camera-scale band allocation across all staged pinch events.
///
/// Per §50.5 / NEW-4: every stage event (focal blur, chatContent fade, cell shadow,
/// labelStack appearance, edge masks, neighbor alpha, horizontal inset) reads its
/// scale band from this enum. The "never two figures at once" invariant
/// (NEW-4.4 scale-sweep test) checks ≤1 band in (0,1) at every scale.
///
/// Bands are expressed as FRACTIONS of (chatRestScale − 1.0), derived per-cell from
/// `chatRestScale(for: cell)` to handle device-size variation (iPhone SE vs iPhone 16,
/// portrait vs landscape, production naturalH ≈ 438 vs test fixtures naturalH = 200).
///
/// Stage order on the camera.scale axis, scale DECREASING from chatRestScale → 1.0
/// (i.e., reverse pinch chat → cell):
///   Stage 1 (scale ∈ [chatRestScale, focalBlur.upper]): text alone scales, no chrome
///   Crossing 1 (focalBlur band): blur engages (illegibility)
///   Stage 2 (between focalBlur and chatContentFade): blurred texture
///   Crossing 2 (chatContentFade band): chatContent.alpha → 0 (texture → absence)
///   Stage 3 (between chatContentFade and cellShadow): empty cell-fill, shadow emerging
///   Crossing 3 (cellRestChrome band): labelStack appears
///   Stage 4 (scale ≤ cellRestChrome.lower): resolved arrival
///
/// Prose proportions ("first third" Stage 1 / "between a third and halfway" Crossing 1)
/// pin focalBlur.upper at scale-progress 1/3 of (chatRestScale → 1.0).
enum StageOrdering: Sendable {

    /// Stage 1 ends at this scale-progress fraction (text-alone region). Per prose:
    /// "roughly the first third of the available pinch travel."
    static let stage1Fraction: CGFloat = 1.0 / 3.0

    /// Crossing 1 width (focalBlur band). Per prose: "between a third and halfway."
    static let focalBlurWidth: CGFloat = 1.0 / 6.0

    /// Crossing 2 width (chatContent fade band).
    static let chatContentFadeWidth: CGFloat = 1.0 / 6.0

    /// Stage 3 / cellShadow band width.
    static let cellShadowWidth: CGFloat = 1.0 / 6.0

    /// Crossing 3 / labelStack appearance band width.
    static let cellRestChromeWidth: CGFloat = 1.0 / 6.0

    /// Compute focalBlur band for given chatRestScale.
    /// At scale-progress (chatRest → 1.0): [1/3 − 1/6, 1/3] = [1/6, 1/3].
    static func focalBlurBand(chatRestScale: CGFloat) -> ClosedRange<CGFloat> {
        bandAtFraction(chatRestScale: chatRestScale, lowFraction: stage1Fraction - focalBlurWidth, highFraction: stage1Fraction)
    }

    /// Compute chatContentFade band. Scale-progress [1/3, 1/2].
    static func chatContentFadeBand(chatRestScale: CGFloat) -> ClosedRange<CGFloat> {
        bandAtFraction(chatRestScale: chatRestScale, lowFraction: stage1Fraction, highFraction: stage1Fraction + chatContentFadeWidth)
    }

    /// Compute cellShadow band. Scale-progress [1/2, 2/3].
    static func cellShadowBand(chatRestScale: CGFloat) -> ClosedRange<CGFloat> {
        let low = stage1Fraction + chatContentFadeWidth
        return bandAtFraction(chatRestScale: chatRestScale, lowFraction: low, highFraction: low + cellShadowWidth)
    }

    /// Compute cellRestChrome band (labelStack appearance). Scale-progress [5/6, 1].
    static func cellRestChromeBand(chatRestScale: CGFloat) -> ClosedRange<CGFloat> {
        bandAtFraction(chatRestScale: chatRestScale, lowFraction: 1.0 - cellRestChromeWidth, highFraction: 1.0)
    }

    /// Convert scale-progress fraction f ∈ [0, 1] to absolute scale value.
    /// f=0 → chatRestScale; f=1 → 1.0 (cell-rest). Linear interpolation.
    private static func scaleAtFraction(chatRestScale: CGFloat, fraction: CGFloat) -> CGFloat {
        chatRestScale - fraction * (chatRestScale - 1.0)
    }

    private static func bandAtFraction(chatRestScale: CGFloat, lowFraction: CGFloat, highFraction: CGFloat) -> ClosedRange<CGFloat> {
        let upper = scaleAtFraction(chatRestScale: chatRestScale, fraction: lowFraction)
        let lower = scaleAtFraction(chatRestScale: chatRestScale, fraction: highFraction)
        return lower...upper
    }

    /// Convenience helper: illegibility threshold per NEW-7.c.
    /// Returns the scale at which blur is fully engaged (= focalBlurBand.lowerBound).
    static func illegibilityToeFull(chatRestScale: CGFloat) -> CGFloat {
        focalBlurBand(chatRestScale: chatRestScale).lowerBound
    }

    static func illegibilityToeIn(chatRestScale: CGFloat) -> CGFloat {
        focalBlurBand(chatRestScale: chatRestScale).upperBound
    }
}
