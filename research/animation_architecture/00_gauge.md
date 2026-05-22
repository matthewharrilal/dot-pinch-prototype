# GAUGE — Animation Architecture (current state of DotPinchPrototype)

POSTURE: janum

## Current symptoms
The animation surface today is a patchwork of mechanisms with brittle handoffs:
- **`UIView.animate(delay:)` chains** in `V2RootViewController.revealChat` (lines 110-124) — three blocks chained by manually-tuned `delay:` values (0, 0.2, 0.5) covering one logical reveal. Time-shift any block and the choreography drifts.
- **CADisplayLink-driven `masterTimer`** in `TimelineCanvas` (around line 1322) — bespoke timeline-based driver for the tap-to-chat morph, hand-rolled spring-equivalent.
- **`SpringAnimator<CGFloat>`** for camera + extension (`CameraAnimator`) — proper spring physics, shared `AnimationController` for phase-locked dt.
- **`UIViewPropertyAnimator`** — not used.
- **`CABasicAnimation`** — used for individual layer keypaths in the morph.
- **`smoothstep` alpha curves** driven by externally-pushed progress (`setCamera(_:)` → `pushCameraToVisibleCells`).

## Current tier estimate: Tier 2B
- Confidence: high.
- Spring physics + AnimationController + dt-coupled animators is solid foundation (above Tier 2A).
- Reveal-half UIView.animate chains, masterTimer hand-roll, and the manual-delay choreography are below Tier 3. Three different timing substrates coexisting with manual handoffs is the brittleness the user is feeling.

## Required tier: Tier 3B (Apple-grade)
- User explicitly named target: "how triple-A iOS companies like Airbnb handle and coordinate complex animations."
- Apple Music expand, App Switcher, Things' add-to-inbox, Linear's transitions — these are the comparative bar.

## Gap: +1 to +1.5 tiers (positive)
- Pull patches: replace UIView.animate chains with a unified driver, unify CADisplayLink coordination, model the reveal as continuous-progress.
- Architectural: introduce a coordinator/state-machine that owns animation phase, supports cancellation + velocity preservation, and produces a single-primitive composition per interaction.

## Primitives in active use
- `UIView.animate(withDuration:delay:options:animations:completion:)`
- `CADisplayLink` (via `AnimationController` + `masterTimer`)
- `CABasicAnimation` (individual keypath animations on morph)
- `CATransaction.withSuppressedActions { }`
- `Spring` + `SpringAnimator<CGFloat>` + `AnimationController` (V2's robust path)
- `smoothstep`-driven manual interpolation in `setCamera`

## Assumed compositional patterns (some may be wrong)
- That UIView.animate's `delay:` parameter is a safe choreography seam (it isn't: VSync misses + thread contention drift it).
- That a hand-rolled CADisplayLink masterTimer is the only way to do timeline-based progress (UIViewPropertyAnimator + KeyframeAnimator iOS 17 are alternatives).
- That spring + timeline can't compose (Apple Music's expansion does both: a UIViewPropertyAnimator drives interruptible UIView properties, spring drives the artwork hand-off, layer animations run alongside).
- That progress-pushed alpha curves are the right substrate for chrome.

## Visible blind spots
1. No coordinator pattern — animations are scattered across VC + canvas + cell.
2. No interruptibility for the reveal — once a UIView.animate block starts, it can't be cancelled mid-flight without snapping.
3. No matchedGeometry-style hero transition substrate.
4. No reactive/declarative layer (Combine, RxSwift, custom Observable).
5. No central animation phase model — `progress` is computed implicitly from extensionFactor in each cell, not a first-class state.
6. The "delay-chained UIView.animate" anti-pattern is the load-bearing user complaint and the most visible Tier 2B → 3 gap.

## Recommended next skills
- `/cartography` on animation primitives: enumerate UIKit native + CA + SwiftUI + open-source + coordinator/orchestrator patterns
- `/ninety` on premium consumer apps: Airbnb, Apple Music, Instagram, Things 3, Linear, Cash App, Telegram-iOS, Apple Notes/Photos
- `/conjecture` on the calibrated composition: which substrate + which coordinator pattern fits THIS app's morph + reveal + future complexity
- THEN implementation (refactor the current chained UIView.animate into the chosen pattern)

This Wave 1 frames the work. The 4 cartography agents + 5 ninety agents (Wave 2) will produce the atlas.
