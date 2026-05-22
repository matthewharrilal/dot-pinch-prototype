# METACOGNITIVE — Animation design tokens + API governance
POSTURE: janum

Orientation: triple-A iOS shops treat animation parameters as a typed, named, audited vocabulary — not magic numbers. Current state: `PinchTuning` partial-tokens + `Theme` for chromatics + naked `Spring(dampingRatio:response:)` at `CameraAnimator.swift:44` and `TimelineCanvas.swift:159`, plus naked `UIView.animate(withDuration: 0.08/0.17/0.20/0.3/0.7/1.2 …)` at `V2RootViewController.swift:110–124` and `TimelineCanvas.swift:1225+,1153–1154`. Load-bearing question: minimum viable `Motion.swift` + what governance.

---

## Spring fingerprint tokens

### Canonical Swift form
```swift
enum MotionSpring {
    static let reveal   = Spring(dampingRatio: 0.85, response: 0.55) // entrance, single-shot
    static let dismiss  = Spring(dampingRatio: 0.90, response: 0.45) // exit, faster
    static let response = Spring(dampingRatio: 0.78, response: 0.35) // direct-manip release
    static let snap     = Spring(dampingRatio: 1.00, response: 0.30) // monotonic settle, no overshoot
    static let bouncy   = Spring(dampingRatio: 0.62, response: 0.55) // playful overshoot (sparingly)
}
```
Call sites read `MotionSpring.reveal`, never `Spring(dampingRatio: 0.85, response: 0.55)`.

### Strengths / weaknesses
- (+) Refactor-safe: re-tune `reveal` once, every entrance updates.
- (+) Semantic vocabulary shared by designer + engineer ("use `response`, not `reveal`").
- (+) Audit-friendly: grep for `Spring(` literal calls flags violations.
- (−) Wrong abstraction risk: if `reveal` and `dismiss` later need to diverge per-surface, the named token becomes a lie. Mitigation: keep the token set **small** and let surfaces compose by velocity, not by spawning `reveal2`.
- (−) Tokens hide physics. Engineers stop reasoning about `response`/`dampingRatio`. Mitigation: doc comments + DocC linking to Apple's spring math.

### Shipping evidence
- **Apple iOS 17** `Animation.bouncy / .smooth / .snappy` (SwiftUI) — three curated springs, full stop. UIKit-usable via `UISpringTimingParameters`. The curation discipline is the lesson.
- **Material M3 motion** — `emphasized / standard / decelerated / accelerated` spring + curve sets, four tokens not forty.
- **Wave by Janum Trivedi** — `.defaultAnimated / .snappy / .bouncy / .smooth`; DotPinchPrototype's `Spring.swift` derives from Wave.

### Migration cost
~30 min. Add `MotionSpring` enum. Replace 3 call sites (`CameraAnimator.swift:44`, `TimelineCanvas.swift:159`, `TimelineCanvas.swift:1110`). `PinchTuning.springResponse / springDamping` graduate to `MotionSpring.response`. Per-direction profiles (`tapToChatDamping / pinchToCellsDamping / cancelledDamping`) stay in `PinchTuning` — gesture-physics, not design tokens.

---

## Duration tokens

### Canonical Swift form
```swift
enum MotionDuration {
    static let instant: TimeInterval     = 0.10  // micro acknowledge
    static let quick: TimeInterval       = 0.20  // small UI change
    static let standard: TimeInterval    = 0.30  // default
    static let emphasized: TimeInterval  = 0.50  // hero / reveal
    static let deliberate: TimeInterval  = 0.70  // long surface change
}
```

### Strengths / weaknesses
- (+) Kills `withDuration: 0.08 / 0.17 / 0.20 / 0.3 / 0.7 / 1.2` proliferation seen across `TimelineCanvas.swift:1225+` and `V2RootViewController.swift:110+`.
- (−) Spring physics make duration **derived** (`Spring.settlingDuration`), so durations only apply to curve-based, non-spring paths. For DotPinchPrototype that is still ~half the animations (the chained `UIView.animate` reveals).
- (−) Choosing the bucket can feel arbitrary at edges (is 0.17 `instant` or `quick`?). Mitigation: round to bucket; if it must be different, the bucket vocabulary is wrong.

### Shipping evidence
- **Material M3** — `short1..4 / medium1..2 / long1..4 / extraLong1..4` = 16 duration tokens. Over-tokenized; Apple is wiser.
- **Apple HIG (Motion)** — does not publish numeric duration tokens; principle: durations derived from interaction.
- **Stripe motion** — internal xs/sm/md/lg/xl ≈ 100/200/300/500/700ms.
- **IBM Carbon** — `productive / expressive` × `duration-fast-01 … duration-slow-02` (5 buckets).

### Migration cost
~20 min. 5 statics, ~10 call sites. Bucket round: `0.08 → instant`, `0.17/0.20 → quick`, `0.3 → standard`, `0.7 → deliberate`, `1.2 → choreography (do not tokenize)`.

---

## Curve / easing tokens

### Canonical Swift form
```swift
enum MotionCurve {
    static let standard   = CAMediaTimingFunction(name: .easeInEaseOut)
    static let decelerate = CAMediaTimingFunction(name: .easeOut)        // enter
    static let accelerate = CAMediaTimingFunction(name: .easeIn)         // exit
    static let emphasized = CAMediaTimingFunction(controlPoints: 0.2, 0.0, 0.0, 1.0) // M3 emphasized
    // Domain-specific (current canvas usage):
    static let morphZoom  = CAMediaTimingFunction(controlPoints: 0.7, 0.0, 0.4, 1.0) // TimelineCanvas zoomScale
    static let morphLift  = CAMediaTimingFunction(controlPoints: 0.0, 0.0, 0.2, 1.0) // TimelineCanvas translate
}
```

### Strengths / weaknesses
- (+) The cubic-bezier control points `(0.7, 0.0, 0.4, 1.0)` and `(0.0, 0.0, 0.2, 1.0)` already appear twice each in `TimelineCanvas.swift:1179/1205` and `:1189`. Two free-form curves = two tokens.
- (−) Named curves invite proliferation. `morphZoom` is a specific name for a specific surface; if it generalizes, rename to `emphasizedDecelerate`; if it doesn't, leave it scoped to `MorphTiming`, not `MotionCurve`.

### Shipping evidence
- **Material M3** — `emphasized / emphasized-decelerate / emphasized-accelerate / standard`. Four bezier presets cover M3.
- **Apple HIG** — `linear / easeIn / easeOut / easeInOut / default` is the entire public-API curve vocabulary.
- **Shopify Polaris** — `motion-ease-in / out / in-out` only.

### Migration cost
~15 min. Replace 4 inline `CAMediaTimingFunction` constructions.

---

## Stagger tokens

### Canonical Swift form
```swift
enum MotionStagger {
    static let none: TimeInterval     = 0.00
    static let tight: TimeInterval    = 0.03  // chrome cascade
    static let cascade: TimeInterval  = 0.05  // list reveal
    static let loose: TimeInterval    = 0.08  // hero chrome
}
```

### Strengths / weaknesses
- (+) The `UIView.animate(delay: 0.03 / 0.08)` chain at `TimelineCanvas.swift:1229/1233` is a stagger pattern with the values inlined. Tokenizing exposes the **intent** (cascade).
- (−) Stagger is best expressed as `UIViewPropertyAnimator.addAnimations(_:delayFactor:)` (per Apple Music pattern in `n2_apple_system.md`), where the parameter is a **fraction of total duration**, not an absolute time. Token form must match the API form being adopted.

### Shipping evidence
- **Apple Music chrome cascade** — `delayFactor: 0.0 / 0.2 / 0.5` on one 0.6s animator. Stagger as fraction.
- **Material M3** — no formal stagger token; documents "list animations should cascade".
- **Things 3 magic-plus** — 16–32ms stagger between row reveals.

### Migration cost
~10 min absolute-time; ~30 min if migrating `revealChat`'s chained `UIView.animate(delay:)` to one `UIViewPropertyAnimator` + `delayFactor:` (recommended by `n2`).

---

## API discoverability + governance

### Autocomplete + DocC
Typed enum cases (`Motion.Spring.<TAB>`) beat string-keyed lookup for a single-app codebase — IDE teaches the vocabulary. Each token gets `///` doc comment: semantic role + Apple analog + when-to-use. Build DocC via `Motion.docc/` target.

### Audit tooling — SwiftLint custom rules (`.swiftlint.yml`)
```yaml
custom_rules:
  inline_spring:
    regex: '\bSpring\s*\(\s*dampingRatio'
    excluded: ".*Motion\\.swift"
    message: "Use Motion.Spring.<token>, not inline Spring(dampingRatio:response:)."
  inline_uiview_duration:
    regex: 'UIView\.animate\s*\(\s*withDuration:\s*[0-9.]+'
    excluded: ".*Motion\\.swift"
    message: "Use Motion.Duration.<token>."
  inline_bezier:
    regex: 'CAMediaTimingFunction\s*\(\s*controlPoints'
    excluded: ".*Motion(Curve|Timing)\\.swift"
    message: "Define bezier in Motion.Curve."
```

### Deprecation + Figma + telemetry
Value bumps silent (recompile). Renames: `@available(*, deprecated, renamed:)`. Semantic-intent changes: new token + grace period; CHANGELOG `## Motion` section. Figma handoff manual at this scale (Lottie loses spring physics; Tokens Studio motion-sync immature). Skip per-token telemetry — `MetricKit.MXAnimationMetric` for hitch tracking is the production telemetry that matters.

---

## Synthesis: recommended `Motion.swift` for DotPinchPrototype

```swift
// DotPinchPrototype/Animation/Motion.swift
// Canonical motion design tokens. Inline Spring()/duration/curve construction
// is lint-flagged outside this file. Add a token here BEFORE using a new value
// at a call site.

import QuartzCore
import UIKit

enum Motion {

    /// Curated spring vocabulary. If a surface needs a spring outside these
    /// five, the answer is almost always "use `response` with carried velocity,"
    /// not "add a sixth spring."
    enum Spring {
        /// Entrance / hero reveal. Slight overshoot. Apple `.smooth` analog.
        static let reveal   = DotPinchPrototype.Spring(dampingRatio: 0.85, response: 0.55)
        /// Exit / dismiss. Faster, less overshoot.
        static let dismiss  = DotPinchPrototype.Spring(dampingRatio: 0.90, response: 0.45)
        /// Direct-manipulation release (gesture lift). Carries velocity.
        static let response = DotPinchPrototype.Spring(dampingRatio: 0.78, response: 0.35)
        /// Monotonic settle, no overshoot. Critically damped.
        static let snap     = DotPinchPrototype.Spring(dampingRatio: 1.00, response: 0.30)
        /// Playful overshoot. Use sparingly. Apple `.bouncy` analog.
        static let bouncy   = DotPinchPrototype.Spring(dampingRatio: 0.62, response: 0.55)
    }

    /// Durations for curve-based (non-spring) animations. Spring animations
    /// derive duration from physics — do not pass these to spring paths.
    enum Duration {
        static let instant: TimeInterval     = 0.10
        static let quick: TimeInterval       = 0.20
        static let standard: TimeInterval    = 0.30
        static let emphasized: TimeInterval  = 0.50
        static let deliberate: TimeInterval  = 0.70
    }

    /// Curves. Five tokens cover the M3 vocabulary; add domain-specific
    /// curves only when reused 2+ times.
    enum Curve {
        static let standard   = CAMediaTimingFunction(name: .easeInEaseOut)
        static let decelerate = CAMediaTimingFunction(name: .easeOut)
        static let accelerate = CAMediaTimingFunction(name: .easeIn)
        static let emphasized = CAMediaTimingFunction(controlPoints: 0.2, 0.0, 0.0, 1.0)
        /// Morph-specific bezier (TimelineCanvas zoom/centering). Promote to
        /// `emphasizedDecelerate` if it generalizes; keep scoped if not.
        static let morphZoom  = CAMediaTimingFunction(controlPoints: 0.7, 0.0, 0.4, 1.0)
    }

    /// Stagger between participants in a cascade. Prefer
    /// `UIViewPropertyAnimator.addAnimations(_:delayFactor:)` over manual delay.
    enum Stagger {
        static let tight: TimeInterval   = 0.03
        static let cascade: TimeInterval = 0.05
        static let loose: TimeInterval   = 0.08
    }
}
```
Total: ~50 lines + doc comments. Single file. Lint guards inline construction. Five springs, five durations, five curves, three staggers — small enough to memorize, large enough to express the app's vocabulary.

---

## What we should NOT over-tokenize

1. **Per-surface springs (`cellRevealSpring`, `chatExpandSpring`, `dotPinchSpring`)** — proliferation kills the vocabulary. Either the surface uses an existing token + carried velocity, or there is a genuine new semantic role (rare).
2. **Sub-100ms duration buckets** — M3's `short1/2/3/4` (50/100/150/200ms) is over-tokenized for a one-team codebase. `instant=0.10, quick=0.20` is enough.
3. **Damping presets independent of response (`MotionDamping.critical/light/heavy`)** — damping and response are coupled in perceived feel; tokenize the **pair** as a spring fingerprint, not each axis separately.
4. **Stagger as fraction enum** — if migrating to `delayFactor:`, fractions are call-site math (`0.0, 1.0/3, 2.0/3`), not tokens. Keep stagger tokens as absolute-time for the curve-based paths only.
5. **Easing for spring paths** — springs do not consume `CAMediaTimingFunction`. Don't tokenize "the spring's curve."
6. **Telemetry hooks per-token at prototype scale** — overkill. PR review + grep + lint is the governance until the team grows past 3 engineers or the app ships to 100K+ users.
7. **`PinchTuning`'s per-direction damping values** — these are gesture-physics constants (`tapToChatDamping=0.62 / pinchToCellsDamping=1.00 / cancelledDamping=0.95`), not motion **design** tokens. They are the dot-pinch mechanic's internal parameters. Keep in `PinchTuning`, do not promote into `Motion.Spring`. The boundary: motion tokens are surface-facing semantics ("reveal looks like _this_"); pinch tuning is mechanism-facing physics ("the gesture decides between these dampings"). Confusing them creates a token surface that grows with every gesture variant.
8. **The `1.2s` master timer + `0.78s` windup + `1.5s` total morph at `TimelineCanvas.swift:1153–1154,1297`** — these are choreography/staging values for the specific morph sequence, not reusable durations. Keep in a `MorphTiming` enum scoped to `Conversation/V2/`, not promoted to `Motion`. Co-locating timing with the choreography it serves prevents `Motion.Duration` from growing into a junk drawer of one-off values.
