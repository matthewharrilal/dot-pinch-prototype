# GAUGE — INTROSPECTIVE — Reveal/Transition Mechanism (morph-end → chat surface)

POSTURE: janum

## Posture check
Treating the latter end of the 10% (CAFilter, _UI-prefixed types, CARemoteLayer, undocumented Metal pixel formats, header-only Core Image kernels) as research territory Apple has shipped and made reachable — not as a wishlist of complaints. Apple did document the latter end; just not in prose. The job is to read the framework binaries, validate empirically, and accept the documentation absence as part of the work. If the right answer for the reveal lives at the latter end, the cartography will surface it and the 90% dip will tell us how to compose it safely.

## Task
Reveal the chat surface beneath a morphed cell with a sense of depth and atmosphere that reads as premium / Dot-grade, not as "circle expanded" or "two effects layered."

## Current tier estimate: Tier 2A
- Confidence: high.
- Both attempted compositions (blur-mediated alpha crossfade; twin-mask radial reveal with defocus pull) were built entirely from front-of-10% APIs (`UIVisualEffectView`, `CAShapeLayer`, `CAGradientLayer.type=.radial`, `CABasicAnimation` on `transform.scale.xy` and `path`).
- No latter-end primitive considered. No 90% rule consulted. No reverse engineering of any reference app.

## Required tier for work: Tier 3 (Apple-grade)
- User is explicitly comparing against Dot's reveal — a polished consumer interaction.
- User has rejected two pure-10% compositions as feeling "generic," "obviously a circle," "conflicted not smooth."
- The shipping target is "premium feel," not "functional reveal."
- Users WILL perceive the difference between Tier 2B and Tier 3 for this specific surface — this is a hero interaction, not chrome.

## Gap: +1 tier (positive — work needs more depth)
- Pure-10% composition is structurally insufficient. The "looks conflicted not smooth" verdict on the layered approach is the signal that the 10% alone is not closing it.
- Closing the gap requires cartography of the latter end + 90% dip on what compositional rules govern the latter-end primitives + identification of which 90% knowledge Dot / Apple Music / Halide / Apollo / Procreate / etc. encode in their reveals.

## Primitives currently being reached for (all front-of-10%)
- `UIVisualEffectView` with `.systemMaterial` / `.systemThinMaterial` blur presets — only documented effect swaps, not parametric.
- `CAGradientLayer` with `type = .radial` as `layer.mask` — animating `transform.scale.xy` to grow soft-edged mask.
- `CAShapeLayer` with circular `UIBezierPath` as `layer.mask` — animating `path` keypath for hard-edge ripple.
- `CABasicAnimation` with cubic-Bezier timing.
- `UIView.animate` with `.curveEaseInOut` for alpha crossfades.

## Assumed compositional patterns (likely some are wrong)
- That a soft-edged radial gradient mask + blur dissolve sums to "depth." Empirically it does not — it reads as two disjoint mechanisms running in parallel.
- That radial reveals always read as "circles expanding." May be solvable at a different substrate (shader-based blend, parametric blur radius animation, light-bloom compositing) but unverified.
- That `UIBlurEffect` swaps are the right defocus primitive. Likely wrong — preset swaps are stepped, not continuous. Triple-A apps almost certainly drive parametric blur radius (CIGaussianBlur input, or CAFilter `gaussianBlur` with animated `inputRadius`).
- That all transition logic belongs in Core Animation. Likely wrong — the transition *zone* (where revealed and unrevealed meet) is exactly where shader-driven composition shows its difference vs. mask-driven alpha.
- That a single mask animating from small to large IS the reveal. Triple-A apps likely model reveals as displacement / refraction / light propagation through a substrate, not as visibility cutouts.

## Visible blind spots
1. **Entire latter-end-of-10% cartography unmapped for reveals.** `CAFilter` named recipes (`gaussianBlur`, `colorMatrix`, `vibrantColorMatrix`, `plusD`, `plusL`, `alphaFromLuminance`, `sourceAtop`, `colorDodgeBlendMode`, `darkVibrant`, `screenBlendMode`, etc.); `_UIVisualEffectBackdropView` direct access for parametric blur; `_UIPortalView` for cross-layer rendering; `CARemoteLayer` same-process variant; `CABackdropLayer`; undocumented `CALayer` filter keypaths.
2. **Metal / `MTKView` / `CAMetalLayer` substrate** — never considered as the transition substrate. Triple-A apps with custom reveals (Apollo's gesture handoffs, Halide's mode switches, Procreate's canvas-to-gallery, Things' add-to-list) likely composite the transition zone with shaders.
3. **`CoreImage` filter chains** — `CIGaussianBlur` with animated `inputRadius`, `CIMaskedVariableBlur` for spatially-varying blur, `CIBlendKernel` for custom shader-driven blending in the transition zone.
4. **Reverse-engineering of reference apps** — Dot's reveal (the literal target), Apple Music's now-playing → expanded, Halide's mode transitions, Apollo's swipe-to-detail, Things' add-to-inbox, Procreate's gallery-to-canvas. Each likely encodes specific 90% rules.
5. **Wave-style velocity-preserving spring retargeting** applied to mask animations — never considered.
6. **Parametric blur** vs preset blur — `UIBlurEffect` is preset-based; the smooth blur radius animation that gives Apple-grade defocus pulls almost certainly comes from `_UIVisualEffectBackdropView.inputRadius` or CIFilter `inputRadius` or `CAFilter` `gaussianBlur.inputRadius`.

## Recommended next skills
- `/cartography` on **reveal-mechanism** domain, **substrate-open** scope. Six parallel sub-agents by gradient × framework: (a) UIKit/CALayer front-of-10%, (b) SwiftUI transition front-of-10%, (c) CoreImage middle-of-10%, (d) Metal middle-of-10%, (e) CAFilter latter-end, (f) UIKit internals latter-end.
- `/ninety` on **intention 3 (peer rebuild)** + **intention 4 (internal behaviors)** + **intention 6 (compositional pairings)**. Five parallel sub-agents: reverse-engineer Dot, reverse-engineer Apple Music, reverse-engineer a third reference app, CAFilter composition rules, material/backdrop pipeline rules.
- `/conjecture` **SKIPPED** per user direction. Research deliverable only.

## Sufficiency check (preliminary — to be re-evaluated after cartography)
Pure-10% composition has demonstrably not closed the gap. Confidence is high that the latter end of the 10% + 90% rules together will surface the missing substrate (most likely candidates: parametric blur via `_UIVisualEffectBackdropView` or `CAFilter gaussianBlur`, plus a shader-driven transition zone via CIBlendKernel or Metal). The cartography wave will validate or refute this.
