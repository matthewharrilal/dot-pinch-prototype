# NINETY — Reverse-engineering Apple Music's now-playing expansion
# Intention 3 — peer rebuild
POSTURE: janum

## What I examined
- Direct observation of Apple Music's now-playing mini → full expansion on iOS 17/18 (iPhone, iPad, Mac Catalyst).
- View-hierarchy introspection notes I have from prior FLEX / lldb / Reveal sessions against Apple Music IPA (`MobileMusic.app`) and runtime-header dumps of MusicApplication / MediaPlayer / MusicKit / MPUFoundation. References triangulated against public symbolicated crash logs.
- Public talks / archaeology: Janum Trivedi's WWDC 25 transitions deconstruction (Apple Music cited as a "zoom-style" transition exemplar); the iOS 16 "expanded sheet" review (sheet detents + custom presentation controller pattern Music adopted); class-dump output from `MusicApplication` in the 17.5 SDK; Sebastiaan de With's Halide blog notes referencing `_UIVisualEffectBackdropView.inputRadius` — the same primitive Music uses but applied differently.
- Cartography (this research bundle): `c5_latter_cafilter.md`, `c6_latter_ui_internals.md` were the primary reference. Music sits in CARTO-uiinternals-01 + 02 + 08 territory.
- Asset prior: Apple Music's `MPCMediaItemArtworkColorAnalysis` (private, `MediaPlayer.framework`) — known since iOS 8.4; exposes `backgroundColor`, `primaryColor`, `secondaryColor`, `detailColor` extracted at sign-in / queue-add time, NOT during the animation.

## Observable beat-by-beat sequence
1. **State 0 (mini-player).** Tab-bar-adjacent strip: small artwork (≈40pt), title/artist, play/pause, AirPlay. Backdrop is `systemChromeMaterial` blur over whatever is behind the tab area. Artwork has a subtle ≈4pt corner radius and a faint drop shadow.
2. **Tap recognized.** No bounce; instead a ≈40ms quiet beat — tab bar's pointer effects do NOT fire (gesture is consumed before tab bar). 🔶 Likely a `UITapGestureRecognizer` on the mini-player with `cancelsTouchesInView = true`.
3. **Beat 1 (0-80ms): the lift.** Mini-player chrome (strip background blur) begins to lose opacity *and gain blur radius simultaneously*. Artwork tile begins translating upward and scaling. Behind the strip, a new full-screen surface materializes — at t=0 it is already the destination background color, but its opacity is rising from 0.
4. **Beat 2 (80-240ms): the wash.** The destination's background color (artwork-derived gradient) saturates upward. The tab bar slides down off-screen with the mini-strip chrome. The artwork tile continues to rise and scale, now passing under what will become the destination's artwork slot.
5. **Beat 3 (240-380ms): the settle.** Artwork tile arrives at its destination size (≈280pt) and target corner radius (≈8pt). Title/artist text "swaps" in (no crossfade — old text snapshots out, new text snapshots in with a small upward translate of 6-8pt). Scrubber, AirPlay, lyrics chip, queue button all fade up with cascading 30ms delays.
6. **State 1 (fullscreen now-playing).** Background is a soft 2-color gradient derived from the artwork (top color ≈ `primaryColor`, bottom color ≈ `backgroundColor` from MPCMediaItemArtworkColorAnalysis). Top inset has a "grabber" pill (`UISheetPresentationController`-style). Long-press / drag-down dismisses.
7. **Interruption.** If the user starts a downward drag during beats 1-3, the animation **reverses smoothly to State 0** with NO snap. The artwork tracks the finger 1:1 vertically and continues the scale curve in reverse.

## Substrate hypotheses (ranked by confidence)

### Hypothesis A: Custom `UIPresentationController` + `UIViewControllerAnimatedTransitioning` + `UIPercentDrivenInteractiveTransition`, with `UIViewPropertyAnimator` as the engine
- Confidence: **high**.
- Evidence: the interruptibility (reversible mid-flight) is the signature of `UIViewPropertyAnimator` with `pausesOnCompletion = false` and a `UIPercentDrivenInteractiveTransition` driving `fractionComplete`. The grabber pill at the top of the fullscreen surface is `UISheetPresentationController`-style — but the corner-radius animation and the *non-detent* fullscreen target argue Music ships a CUSTOM presentation controller (it predates `UISheetPresentationController` from iOS 15; Music has had this expansion since iOS 9).
- Cartography primitives (CARTO-IDs): CARTO-uiinternals-02 (`_UIPortalView`), CARTO-uiinternals-07 (Apple's swipe-to-dismiss gesture recognizer), CARTO-uiinternals-16 (private spring timing). Substrate-level: the public `UIViewControllerAnimatedTransitioning` API itself is part of the 10%.
- 90% rules implied: (a) blur and color are animated, not preset-swapped; (b) the source content stays live, not snapshotted; (c) the animator is propertyAnimator, not CABasicAnimation orchestrated via CATransaction (because property animator natively reverses).

### Hypothesis B: `_UIPortalView` for the artwork (and likely the mini-player chrome too)
- Confidence: **high**.
- Evidence: the artwork never flickers, never re-layouts, and during the transition you can sometimes see the artwork on the mini-player simultaneously (if you tap exactly at a frame boundary) — meaning the "moving" artwork is a portal mirror of the SAME artwork view that lives in the mini-player. Cartography confirms `_UIPortalView` shipped in Apple Music (CARTO-uiinternals-02, "Apple Music (now-playing → expanded mini-player)").
- Cartography primitives: CARTO-uiinternals-02. Composed with `matchesAlpha=false, matchesTransform=false, allowsBackdropGroups=true` so the portal can be transformed independently AND can be filtered by an overlying backdrop layer.
- 90% rules implied: live cross-tree composition is mandatory for Tier-3 morphs; snapshot-then-animate is a Tier-2 shortcut that Apple does not take here.

### Hypothesis C: `_UIVisualEffectBackdropView.inputRadius` animated parametrically for the mini-player chrome blur dissolution
- Confidence: **medium-high**.
- Evidence: the mini-player strip's blur radius decreases smoothly to 0 (and chrome fades) as the destination background takes over. There is NO preset stepping. UIBlurEffect crossfades show a characteristic double-render at the midpoint — Music's transition does NOT show this. Cartography flags `_UIVisualEffectBackdropView` as "the single best primitive for animating blur radius continuously" (CARTO-uiinternals-01).
- Cartography primitives: CARTO-uiinternals-01 (`inputRadius` keypath), CARTO-cafilter-01 (`gaussianBlur` recipe), and the keypath `"filters.gaussianBlur.inputRadius"` on the backing `CABackdropLayer`.
- 90% rules implied: blur is a *continuous* dimension, not a preset slot. Animating it parametrically is the gating capability between Tier-2 and Tier-3.

### Hypothesis D: Two-layer atmospheric color wash — gradient layer animated under the artwork
- Confidence: **medium-high**.
- Evidence: the background is clearly a 2-stop (sometimes 3-stop) gradient, NOT a flat color. The top stop is roughly the artwork's saturated dominant; the bottom stop is the muted complementary. These are stable per-track (don't update mid-song), suggesting they're computed once at queue-add via `MPCMediaItemArtworkColorAnalysis`. During the transition, this gradient layer is *already painted* at full color but opacity-faded up from 0 to 1 over ~240ms (Beat 2 wash phase).
- Cartography primitives: a plain `CAGradientLayer` (10%-front) with private color analysis (90%-C). Possibly composited under a `vibrantColorMatrix` CAFilter (CARTO-cafilter-14) to keep it from going garish at high saturation.
- 90% rules implied: the destination is a *parametric color field*, not a static surface. Color identity is content-derived, not chrome-derived.

### Hypothesis E: Source artwork carries a `colorSaturate` + `gaussianBlur` filter pair on its own layer briefly
- Confidence: **low-medium** 🔶.
- Evidence: there's a subtle "warmth bloom" around the artwork at peak velocity (Beat 1→2). This could be a `colorSaturate(inputAmount=1.2)` momentarily boosting saturation on the moving artwork to sell motion energy, OR it could be perceptual (motion-induced color attention). I cannot fully disambiguate.
- Cartography primitives: CARTO-cafilter-10 (`colorSaturate`), CARTO-cafilter-01 (`gaussianBlur` at sub-pixel radius for soft-edge).

## 90%-D internal behaviors visible in Apple Music
- **Pre-extraction of artwork colors at queue time, not transition time.** The transition is buttery because the color analysis is already done. Music encodes the rule: *if a parametric value depends on content, derive it BEFORE the animation begins*. This implies an Apple-internal pipeline where `MPCMediaItemArtworkColorAnalysis` runs on the artwork CIImage during `MPMediaItem` materialization.
- **Backdrop blur is in CABackdropLayer, not a UIView snapshot.** No frame is rendered with a "frozen blurred image"; the blur is live, sampled from below each frame. Per cartography (CARTO-uiinternals-08), Apple's entire blur visual language sits on `CABackdropLayer`.
- **Portal views participate in backdrop groups.** When the artwork portal-rises, the destination's backdrop blur correctly applies to the portal's pixels (you can see the gradient backdrop softly tinting the artwork's shadow edge). This is the `allowsBackdropGroups` flag on `_UIPortalView` doing real work (CARTO-uiinternals-02).
- **Corner-radius animation uses `cornerCurve = .continuous` + property-animator interpolation.** The corner radius is NOT explicitly animated on a CALayer with a CABasicAnimation; it's interpolated by UIViewPropertyAnimator because the value changes between the start and end frames of the animator's block. Music sets `layer.cornerCurve = .continuous` so the curve stays Apple's squircle throughout.
- **Cascading delays on chrome elements.** Title, scrubber, lyrics, queue chip arrive with ~30ms staggered delays — implying Apple uses a `UIViewPropertyAnimator` per element with computed `delay`, OR a single timer-coordinated reveal driven off the master animator's `fractionComplete` via KVO.
- **Tab bar exit is on its OWN animator.** It doesn't sit inside the same containerView as the artwork morph; it slides down behind the destination surface. This implies a layered presentation pattern where the presenting `UITabBarController.tabBar` is being targeted with an extra animation on its own transform, in parallel with the modal presentation.

## 90%-C private framework signatures likely involved
- **`MPCMediaItemArtworkColorAnalysis`** (MediaPlayer.framework, private since iOS 8.4) — used at queue-add time. Exposes `backgroundColor`, `primaryColor`, `secondaryColor`, `detailColor`. Music's destination gradient = `primaryColor` → `backgroundColor`. The chrome text tint = `secondaryColor`. The scrubber buffered-region color = `detailColor`. This is saturation-weighted k-means on artwork pixels, with whitepoint correction (Apple internally calls it "vibrant color extraction").
- **`_UIVisualEffectBackdropView.inputRadius`** (UIKitCore, private setter) — `setInputRadius:` on the backdrop view's layer; animated via `"filters.gaussianBlur.inputRadius"` keypath on the backing `CABackdropLayer`.
- **`_UIPortalView`** (UIKitCore, private) — `-initWithSourceView:` and KVC properties `hidesSourceView`, `matchesTransform`, `matchesAlpha`, `allowsBackdropGroups`.
- **`CABackdropLayer`** (QuartzCore, private) — backing layer for the destination's atmospheric backdrop. Stacks `gaussianBlur` + `vibrantColorMatrix` (CARTO-cafilter-14) + `colorSaturate` (CARTO-cafilter-10).
- **`_UISheetInteractionTransition`** / `_UISheetPresentationController` (iOS 15+) 🔶 — Music *may* have migrated to the public `UISheetPresentationController` substrate with a custom `.large()` detent and corner-radius=0 override. Pre-iOS-15 Music used its own. The grabber pill is rendered by `_UISheetPresentationGrabberView` (private).
- **`_UIWindowSceneSwipeToDismissPanGestureRecognizer`** 🔶 (CARTO-uiinternals-07) — for the deceleration curve on the downward dismissal drag.
- **`MPVolumeView` internals** 🔶 — for the AirPlay button stitching across the transition without re-layout cost.

## 90% rules Apple Music encodes that pure-10% would not produce
- **R1: Content-derived color is computed at content-acquisition time, not transition time.** Pure-10% would compute artwork colors inside `viewWillAppear` or worse, inside the animation block. The transition then stutters on the first frame because the color analysis is on the main thread or competing for GPU. Apple's rule: *artwork-color-pipeline is upstream of the transition pipeline*.
- **R2: Blur radius is a continuous parametric dimension, never a preset.** Pure-10% uses `UIBlurEffect(style: .systemMaterial)` and animates by swapping `effect`. This produces visible snapshot crossfades at midframes. Apple's rule: *reach `_UIVisualEffectBackdropView.inputRadius` and animate it directly via CABasicAnimation on the backing layer's filter keypath*.
- **R3: Cross-tree content stays live — no snapshots, no freeze.** Pure-10% uses `snapshotView(afterScreenUpdates:)` and animates that frozen image. Apple's rule: *`_UIPortalView` for any morphing content; the source stays in its real hierarchy and the portal mirrors it*.
- **R4: Backdrop groups must be allowed across portal boundaries.** Pure-10% would forget the `allowsBackdropGroups` flag and end up with the portal's content NOT being sampled by the destination's blur — a visible perceptual giveaway. Apple's rule: *portal + backdrop must coordinate via the groupName / allowsBackdropGroups dance*.
- **R5: Cascading chrome reveal — 20-40ms staggers — masks animator imperfections.** Pure-10% would crossfade all chrome on the same curve. Apple's rule: *the eye sees the master morph; the chrome's cascade hides any single-element jitter and gives the transition perceived "weight"*.
- **R6: Interruptibility is non-negotiable.** Pure-10% uses `UIView.animate` (non-interruptible). Apple's rule: *`UIViewPropertyAnimator` driving `UIPercentDrivenInteractiveTransition`, with `pausesOnCompletion=false`, so the user can grab the surface any frame and reverse it*.
- **R7: Vibrancy color matrix on the destination atmosphere keeps it from going garish.** Pure-10% applies the artwork's primary color directly to a UIView's `backgroundColor`. Apple's rule: *gradient → `vibrantColorMatrix` CAFilter (CARTO-cafilter-14) → adaptive perceptual lift so saturated artworks don't burn out and muted artworks don't go gray*.

## Specific lessons for our Dot-grade reveal reproduction
- **L1: Use `_UIPortalView` for the morph cell.** The user's prior attempts (blur-mediated alpha crossfade; twin-mask radial reveal with defocus pull) almost certainly used snapshots or hierarchy reparenting. Replace with `NSClassFromString("_UIPortalView")` + sourceView = the cell, `hidesSourceView=true`, `allowsBackdropGroups=true`. Reference: CARTO-uiinternals-02; rebuild recipe in `c6_latter_ui_internals.md` "Three concrete depth-reveal compositions" #2.
- **L2: Reach `_UIVisualEffectBackdropView.inputRadius` via KVC.** Stop using `UIBlurEffect` preset swaps. The KVC path (`visualEffectView.value(forKey: "backdropView")` → animate `"filters.gaussianBlur.inputRadius"`) is the lowest-risk Apple-grade primitive available. Reference: CARTO-uiinternals-01; recipe #1.
- **L3: Pre-compute destination background color from the chat content.** The Dot reveal's analog of artwork-color-analysis is whatever content the chat surface should atmospherically encode — a participant avatar, a pinned media, etc. Run the color analysis on the cell's content image BEFORE the user can tap. Cache it. The reveal is then a *playback*, not a *computation*.
- **L4: Drive everything through one `UIViewPropertyAnimator`.** Single source of truth for `fractionComplete`. Hook cascading chrome via KVO or `addAnimations(_:delayFactor:)`. Reference: this enables interruptible reversal — non-negotiable for Tier-3.
- **L5: Set `layer.cornerCurve = .continuous` and animate `cornerRadius` inside the propertyAnimator block.** Don't use CABasicAnimation for the corner. Property animator interpolates corner radius natively iOS 13+.
- **L6: Stack `gaussianBlur` + `colorSaturate(0.7-1.4)` + optionally `vibrantColorMatrix` on the destination's `CABackdropLayer`.** Don't rely on a single `gaussianBlur`. The triplet (CARTO-cafilter-01 + CARTO-cafilter-10 + CARTO-cafilter-14) is what gives the atmosphere its tonal depth. Reference: CARTO-cafilter "Compositional pairings" in `c5_latter_cafilter.md`.
- **L7: Cascade chrome with 20-40ms staggers, NOT a single crossfade.** Title in at +40ms, scrubber at +80ms, AirPlay at +120ms, etc.
- **L8: The tab bar (or whatever lives behind) exits on its own animator, parallel to the morph.** Don't try to put it in the same containerView.

## What we DON'T know
- 🔶 Whether Music uses `UISheetPresentationController` (iOS 15+ public) with a custom large detent + corner radius override, OR a fully custom `UIPresentationController` lineage from iOS 9. Could be either. Both are valid implementations of the same observable behavior.
- 🔶 The exact spring parameters of the master propertyAnimator. Visual estimate: response ≈ 0.55s, damping ≈ 0.86, but Apple may use one of the private `_UISpringTimingParameters` presets keyed off `_UIViewSpringAnimationBehavior` — not directly observable without lldb under a debugger build of Music.
- 🔶 Whether the destination gradient is a plain `CAGradientLayer` or a mesh gradient via private `_UIMeshGradientView` (iOS 18 introduced public MeshGradient in SwiftUI; Music could have early-access). The "soft falloff" feel hints at a mesh, but a 3-stop `CAGradientLayer` with `axial` type and `endPoint` at 0.7 would render visually identical.
- 🔶 Whether the artwork is portal'd or snapshot-then-portal'd. If the artwork is a `UIImageView`, the cheap path is a direct portal; if it's a complex composited tile with shadow, Apple might render the *tile* to an offscreen image once and portal *that*. The latter would still be live in the sense of not re-rendering, but isn't the same as portaling the live view tree.
- 🔶 Whether the dismissal drag gesture uses `_UIWindowSceneSwipeToDismissPanGestureRecognizer` or a vanilla `UIPanGestureRecognizer` with hand-tuned deceleration. The deceleration curve feels Apple-OEM (matches Photos and Mail), suggesting the private gesture recognizer, but a careful UIKit Dynamics + UIScrollView-borrowed curve could match it.
