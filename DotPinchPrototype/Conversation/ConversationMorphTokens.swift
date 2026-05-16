// Render-token bundle for the Conversation morph. A pure function of
// PinchMorphState.progress — no UIKit dependencies, no side effects. The view
// layer reads tokens off this struct and writes view properties directly.
// All blur/dissolve/ramp curve math lives in one place where it can be tested
// without a simulator.

import CoreGraphics

struct ConversationMorphTokens {

    // MARK: - Geometry

    /// Uniform scale applied to contentRoot (chat content). Same scalar on
    /// both axes — Refusal #1.
    let similarityScale: CGFloat

    // MARK: - Chat surface

    /// 0 at baseline, 1 at peak illegibility. Drives the blur overlay + animator.
    let blurFraction: CGFloat

    /// Alpha at the chat-surface dissolve mask's top stop (cool-grey reveal).
    let chatTopAlpha: CGFloat

    /// Alpha at the chat-surface dissolve mask's bottom stop (warm-pink reveal).
    let chatBottomAlpha: CGFloat

    // MARK: - Destination

    /// Card silhouette emergence (Stage 3).
    let destinationCardAlpha: CGFloat

    /// Date + body labels (Stage 4) — fade in after the silhouette resolves.
    let destinationLabelAlpha: CGFloat

    // MARK: - Chrome

    /// Pinch + menu affordance icons.
    let affordanceAlpha: CGFloat

    /// Composer fades from 1 → 0 linearly across the whole morph.
    let composerAlpha: CGFloat

    // MARK: - Derivation

    init(state: PinchMorphState) {
        let p = clamp(state.progress, 0, 1)

        // Geometry
        similarityScale = PinchTuning.baselineSimilarityS
            - (PinchTuning.baselineSimilarityS - PinchTuning.destinationSimilarityS) * p

        // Blur — silent below rampStart, ramps to peak by rampComplete, then holds.
        let rampStart = MorphTiming.illegibilityRampStart
        let rampComplete = MorphTiming.illegibilityRampComplete
        if p < rampStart {
            blurFraction = 0
        } else if p < rampComplete {
            blurFraction = (p - rampStart) / (rampComplete - rampStart)
        } else {
            blurFraction = 1
        }

        // Chat dissolve — staggered: bottom fades first, top fades later.
        let dissolvePhase = clamp(
            (p - MorphTiming.chatDissolveStart)
            / (MorphTiming.chatDissolveEnd - MorphTiming.chatDissolveStart),
            0, 1
        )
        let bottomFade = clamp(
            dissolvePhase / MorphTiming.dissolveBottomFadeFraction,
            0, 1
        )
        let topFade = clamp(
            (dissolvePhase - MorphTiming.dissolveTopFadeOffset) / MorphTiming.dissolveBottomFadeFraction,
            0, 1
        )
        chatTopAlpha    = 1 - topFade
        chatBottomAlpha = 1 - bottomFade

        // Destination emergence (staged: silhouette → labels).
        destinationCardAlpha  = ramp(p, from: MorphTiming.cardEmergeStart,  to: MorphTiming.cardEmergeEnd)
        destinationLabelAlpha = ramp(p, from: MorphTiming.labelEmergeStart, to: MorphTiming.labelEmergeEnd)

        // Chrome
        affordanceAlpha = ramp(p, from: MorphTiming.affordanceMaterializesAt, to: 1.0)
        composerAlpha   = 1 - p
    }
}
