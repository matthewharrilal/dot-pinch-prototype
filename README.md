# DotPinchPrototype

A UIKit prototype exploring "pinch-to-memory" — a gesture that compresses a
fullscreen conversation into a static destination card via a uniform 2D
similarity transform, with staged figure/ground relay, blur, and a staggered
bottom-up colour dissolve.

The mechanic sits on a hand-rolled spring substrate (Wave-derived): a single
shared `CADisplayLink`, velocity preserved across mid-flight target changes,
gesture velocity injected into the spring at release.

---

## Run

```bash
brew install xcodegen          # one-time
xcodegen generate              # regenerate the .xcodeproj
open DotPinchPrototype.xcodeproj
```

Pinch on the chat surface. In the simulator: hold Option for two-finger pinch.

Tested on iPhone 16 / iOS 18.0. Targets iOS 17+.

---

## Architecture

```
DotPinchPrototype/
├── App/                  AppDelegate + ConversationComposer (composition root)
├── Conversation/         Feature UI + render-token derivation
│   ├── ConversationViewController.swift
│   ├── ConversationContentView.swift
│   ├── ChatBubbleView.swift
│   ├── ConversationMorphTokens.swift   ← single source of every progress-derived render value
│   └── MorphTiming.swift               ← visual-timing constants
├── Gestures/             Pinch interaction
│   ├── PinchToMemoryInteraction.swift
│   ├── PinchMorphState.swift           ← just `progress` (spring-interpolable)
│   └── PinchTuning.swift               ← gesture-physics constants
├── Animation/            Reusable spring kit (Wave-derived)
│   ├── Spring.swift / SpringAnimator.swift / SpringInterpolatable.swift
│   ├── AnimationController.swift
│   └── MathUtilities.swift
├── DesignSystem/         Theme tokens, AccessibilityID, SymbolName
└── Placeholders/         Static chat transcript + destination preview text
```

The shape of the data flow:

```
UIPinchGestureRecognizer
        │
        ▼
PinchToMemoryInteraction  (writes scalar progress)
        │
        ▼
SpringAnimator<PinchMorphState>  (integrates progress through spring physics)
        │
        ▼  animator.valueChanged
ConversationViewController
        │
        ▼
ConversationMorphTokens(state:)   ← derives every visual property in one place
        │
        ▼
[ ConversationContentView, destinationCard, affordances, composer ]   ← pure projection
```

`ConversationMorphTokens` is the lens: every progress-derived visual property
(blur fraction, chat mask alphas, card emergence, label emergence, affordance
alpha, composer fade) is computed in one pure function with zero UIKit
dependency. The view layer reads tokens off the bundle and writes them to
view properties. No curve math lives in views.

---

## The nine depth-cue refusals

The mechanic suppresses every depth cue that would make the morph read as
"3D recession" instead of "in-place compression":

| # | Refusal | Where it lives |
|---|---|---|
| 1 | Uniform scale, no foreshortening | `ConversationMorphTokens.similarityScale` — `sx = sy` |
| 2 | Photometric continuity (card = page material) | `Theme.Page.surface` reused across gradient middle, card, composer |
| 3 | No parallax | chrome views are siblings of the card, never children |
| 4 | Binary shadow | set only at `.finished`, never animated |
| 5 | Uniform blur | one full-bounds `UIVisualEffectView`; no per-region masks |
| 6 | No vanishing point | no `CATransform3D`, no `m34`, no rotation |
| 7 | Camera stays still | page gradient never moves |
| 8 | Stacking preserved | subview hierarchy built once in `viewDidLoad`, never reordered |
| 9 | No specular | no radial gradients, no `CIFilter` on the card subtree |

---

## Tuning

Two cohesion-aligned files:

- **`Gestures/PinchTuning.swift`** — gesture physics (sensitivity, rubber-band,
  spring response/damping, commit threshold). Reusable across morphs.
- **`Conversation/MorphTiming.swift`** — visual choreography (blur ramps,
  dissolve windows, alpha emergence ranges). This feature's feel.

No morph-progress numeric literal appears inline in the rest of the codebase.

---

## Accessibility

Reduce Motion / VoiceOver / Switch Control / Cross-Fade Transitions all
skip the spring path — the pinch snaps directly to its target. See
`PinchToMemoryInteraction.shouldUseReducedMotion`.

---

## Maestro flows

```bash
./scripts/run-maestro.sh
```

Flows in `.maestro/` — `smoke`, `pinch_in`, `pinch_out`, `mid_flight_reverse`.
iOS 18 simulator only: Maestro 2.5.1 returns an empty accessibility tree on
iOS 26+ sims.

---

## Status

Prototype. The mechanic, staged figure relay, render-token bundle, and
design-token invariants are in place. There are no unit tests yet.

### Future considerations

- **`Animation/` as a Swift package.** The folder is fully feature-independent
  (imports only Foundation / QuartzCore / CoreGraphics / UIKit). When this UX
  is ready to ship as a reusable component, the natural next step is
  `swift package init`-ing it as e.g. `PinchSpringKit` so consumers can
  depend on the substrate without the demo feature.

---

# Tap-to-Chat Morph — The Cane-Curve Trajectory

> Reference commit: **`78c129c`** — `tap-morph: lift-dominant head with slow-start zoom (cane-curve trajectory via additive composition)`
>
> Implementation: `DotPinchPrototype/Conversation/V2/TimelineCanvas.swift` → `func animateCameraToChatRest(forCellAt:)`

This section documents the V2 tap-to-chat morph that fires when a user taps a cell in the timeline. It produces a "cane curve" motion — the cell first appears to lift sharply upward, then the cell zooms toward the viewer as the lift settles. Both motions are concurrent throughout the animation but their progress curves are deliberately mismatched to produce a curved trajectory in motion-space rather than the sequential L-shaped motion of naïve implementations.

The goal of this document is not just to explain what the code does, but to explain **why this specific shape works**, what would happen if any of the design choices were changed, and (most importantly) **how hard it was to articulate the visual specification clearly enough to produce correct code**. The articulation problem was the larger problem.

---

## 1. The visual specification — what the user actually sees

The motion runs over **5.4 seconds** at the slowed-down analysis speed (production would scale this to ~0.8–1.2s by dividing all durations proportionally). The full sequence the eye reads:

```
t=0.0 ─── tap fires; cell is at cell-rest
t=0.0 ─ 0.5  cell SHOOTS upward; scale barely changes. Eye reads:
              "the cell is leaping up like it's been kicked"
t=0.5 ─ 1.5  upward motion decelerating; cell beginning to inflate slightly.
              Eye reads: "the cell is gathering momentum at the top of its arc"
t=1.5 ─ 3.0  lift mostly done; scale accelerating into the zoom.
              Eye reads: "the cell is releasing forward toward me"
t=3.0 ─ 5.0  scale dominant; lift settled at peak.
              Eye reads: "the cell is filling the screen"
t=5.0 ─ 5.4  both motions damping; arriving at chat-rest.
              Eye reads: "settled"
```

Two key dimensions of motion participate:

- **Lift** (`transform.translation.y`): the cell moves vertically. Target: −50pt (cell moves UP by 50pt from its natural position).
- **Scale** (`transform.scale`): the cell expands uniformly around its layer anchor. Target: 2.30× (cell becomes 2.3× its natural size, exceeding screen bounds).

Both dimensions run concurrently from `t=0` to `t=5.4`. Critically, **at no point is only one dimension changing** — that property is what eliminates the perceptual "L-corner" we battled with extensively (described later).

---

## 2. The mechanism — code architecture

Three concurrent `CABasicAnimation` objects on `contentHost.layer`, all with `isAdditive=true` so their contributions sum into the layer's effective transform:

### 2.1 Windup scale — the "preparation" cue

```swift
let windupScale = CABasicAnimation(keyPath: "transform.scale")
windupScale.fromValue = 0
windupScale.toValue = 0.08
windupScale.duration = 2.8                              // shorter than zoom
windupScale.beginTime = now
windupScale.timingFunction = CAMediaTimingFunction(name: .easeOut)
windupScale.fillMode = .forwards
windupScale.isRemovedOnCompletion = false
windupScale.isAdditive = true
```

A brief, additive scale-up contribution that runs for only the first 2.8s. Adds at most **+0.08** to the layer's scale. Held at 0.08 after completion via `fillMode: .forwards`. Provides a slight "preparation" / "anticipation" cue at the start of the morph, ahead of the dominant zoom.

### 2.2 Zoom scale — the dominant scale contribution

```swift
let zoomScale = CABasicAnimation(keyPath: "transform.scale")
zoomScale.fromValue = 0
zoomScale.toValue = 1.22
zoomScale.duration = 5.4                                // full morph duration
zoomScale.beginTime = now                               // starts WITH windup
zoomScale.timingFunction = CAMediaTimingFunction(controlPoints: 0.7, 0.0, 0.4, 1.0)
zoomScale.fillMode = .forwards
zoomScale.isRemovedOnCompletion = false
zoomScale.isAdditive = true
```

Adds **+1.22** to the layer's scale over the full 5.4s. The custom cubic-Bezier timing `(0.7, 0.0, 0.4, 1.0)` is the load-bearing choice: it produces **near-zero velocity at the start**, accelerates aggressively through the middle, decelerates smoothly to settle. This curve is what gives the lift the runway to dominate early.

### 2.3 Lift — the vertical motion

```swift
let translate = CABasicAnimation(keyPath: "transform.translation.y")
translate.fromValue = 0
translate.toValue = -50
translate.duration = 5.4                                // full morph duration
translate.beginTime = now
translate.timingFunction = CAMediaTimingFunction(controlPoints: 0.0, 0.0, 0.2, 1.0)
translate.fillMode = .forwards
translate.isRemovedOnCompletion = false
translate.isAdditive = true
```

Adds **−50pt** to the layer's translation.y over 5.4s. Custom timing `(0.0, 0.0, 0.2, 1.0)` is an aggressively front-loaded easeOut: the control point `c2 = (0.2, 1.0)` means the curve reaches 1.0 (its end value) by the time t/duration = 0.2. About **50% of the lift completes in the first 10% of total time**. The cell visibly shoots upward.

### 2.4 The composition

Because all three are additive on sub-keypaths of `transform`, CoreAnimation sums their contributions in the render pipeline:

```
effective_scale(t)         = 1.0 (model)   + windup_scale(t)   + zoom_scale(t)
effective_translation_y(t) =  0  (model)   + lift(t)
```

No coordination code is needed. Each animation runs independently; the layer's render-tree value is the sum. The cell's effective transform at any moment is the composition.

This is the **central elegance**: there is no orchestrator, no per-frame tick, no master timer. Three independent CABasicAnimations with carefully tuned timing functions. CoreAnimation does the rest.

### 2.5 Supporting writes (pre-morph forced state)

Before adding the animations, the active cell's "chat-rest content" subviews are force-set to alpha=0 so they cannot leak through during the morph:

```swift
activeCell.scrollView.alpha = 0
activeCell.pillContainer.alpha = 0
activeCell.chatRevealBlur.alpha = 0
activeCell.blurOverlay.alpha = 0
```

These are NOT animated — they're set instantly outside the CATransaction context, so no implicit animation fires. This guarded against an earlier failure mode where the chat scrollView's contents (message bubbles) would become visible during the cell's extension because the default UIView alpha is 1.0 and V2's `setCamera` hadn't fired yet to set it to 0.

A separate `morphInProgress: Bool` flag on `CellView` gates V2's `setCamera` from clobbering our alpha writes during the morph — without this gate, `setCamera`'s bounds-derived progress calculation would set all chat-rest alphas to 1.0 the moment our animations began.

A delayed label fade (`labelStack` + `pinchGlyph` to alpha=0) is scheduled for `t=2.8s` via `DispatchQueue.main.asyncAfter`. This fades the cell-rest content (the small date/title labels and pinch glyph) as the morph progresses past its halfway point.

---

## 3. Why this produces a cane curve — the geometry

### 3.1 Motion-space framing

Think of the cell's two dimensions of motion as **axes of a 2D space**:

```
              SCALE (axis →)
        1.0    1.3    1.6    1.9    2.3
        │      │      │      │      │
LIFT  0 ●─                              ← starting point
(↓)     │ ╲
       │   ╲
       │     ╲      The trajectory through this space
       │       ╲    is what determines whether the
   −20 │         ╲   motion FEELS curved or angular.
       │           ╲
       │             ╲
       │               ╲___
   −40 │                    ──___
       │                          ──___
   −50 │                                ●  ← ending point (chat-rest)
```

The trajectory the cell traces through (lift, scale) space is determined by the parametric relationship between `lift(t)` and `scale(t)`. If they advance at the same rate, the trajectory is a **straight line**. If they advance at different rates, the trajectory **bends**.

### 3.2 The asymmetric easing trick

Lift uses an **aggressively front-loaded easeOut** — most of its motion is done early. Zoom uses a **slow-start bezier** — most of its motion is done late. Their progress rates are deliberately mismatched:

| time | lift progress | zoom progress | ratio (lift:zoom) |
|------|---------------|---------------|-------------------|
| 0.3s | ~30% | <1% | ~50:1 |
| 0.5s | ~50% | 1% | ~50:1 |
| 1.0s | ~75% | 5% | ~15:1 |
| 2.0s | ~92% | 25% | ~3.7:1 |
| 3.0s | ~97% | 50% | ~1.9:1 |
| 4.5s | ~99% | 85% | ~1.16:1 |
| 5.4s | 100% | 100% | 1:1 |

Position in motion-space at those moments:

```
t=0.0:  (lift, scale) = (   0, 1.00)     ← rest
t=0.3:                = ( −15, 1.02)     ← lift dominates
t=0.5:                = ( −25, 1.03)     ← still lift-dominant
t=1.0:                = ( −37, 1.07)     ← lift slowing, zoom waking up
t=2.0:                = ( −46, 1.36)     ← handoff zone
t=3.0:                = ( −49, 1.66)     ← zoom dominant
t=4.5:                = ( −49.5, 2.06)   ← settling
t=5.4:                = ( −50, 2.30)     ← chat-rest
```

Plotted, this is the cane:

```
SCALE:  1.0─────────────────────────────────────── 2.3
LIFT 0  ●
        │ (nearly vertical — lift moves, scale doesn't)
        ↓
        ●
        │
        ↓
        ●
         \  (curve begins — both moving)
          \
           ●_
             ──_
                ──_
                    ──___  (nearly horizontal — scale moves, lift doesn't)
-50                       ●

```

A neck of vertical motion at the start, a smooth bend in the middle, a tail of horizontal motion at the end. **A cane.**

### 3.3 Why this never produces an L

The L-shape failure mode (what we battled through many iterations) occurs when:
1. Lift completes BEFORE zoom starts (sequential motion)
2. Lift and zoom use the SAME timing curve (proportional motion = straight line, but with a hard corner when one completes first)

This implementation avoids both:
- Lift's `duration = 5.4s` matches zoom's `duration = 5.4s`. **Neither completes before the other.**
- Lift and zoom use DIFFERENT timing curves. **Neither finishes its work proportionally to the other** — they're staggered in progress rate.

The trajectory has no corner because at every moment, both dimensions are changing (even if at very different rates).

---

## 3.5 The velocity-continuity problem — why additive composition solves the zero-dip

The single hardest perceptual challenge in this work was eliminating velocity dips at animation transition boundaries. This is what made the early implementations feel "disjointed" and "stopping" even when the scale value was monotonically increasing on screen. This section documents the problem precisely, why it isn't solved by position continuity alone, the multiple attempts that failed, and the mathematical reason that **additive composition with complementary curves naturally produces velocity continuity** without any explicit handoff or retarget logic.

### 3.5.1 Position continuity ≠ perceptual continuity

A naive view: "as long as the scale value moves smoothly from 1.0 to 2.3, the motion will feel smooth." This is wrong. **The human visual system is sensitive to velocity (the first derivative of position), not just position.** A motion can have continuous position but discontinuous velocity and the eye will read the velocity discontinuity as a stop, a stutter, or a "jerky" moment.

This is the entire reason the early CAKeyframeAnimation implementation felt disjointed at t=2.8s (the 1.08 keyframe boundary) even though the scale value was monotonically increasing. The scale never paused. The VELOCITY dipped to zero. The eye perceived a stop.

Visualizing the difference between position and velocity curves for the failed `[easeOut, easeIn]` approach:

```
Position (scale value)                Velocity (d scale / d t)
                                                                
     2.3 ┤              ●                  HIGH ●           ●
         │            ╱                          ╲         ╱
         │          ╱                             ╲       ╱
    1.08 ┤    ●───●                                 ╲   ╱
         │    │                              ──────  ╲ ╱  ──────
     1.0 ●────                                MED      ●        
         │                                              ↑
         │                                              ZERO at t=2.8s
         └─────────────→ time                  └────────────────→ time
              t=2.8s                                  t=2.8s
                                                      ^
                                       this dip to zero is what the eye reads as a STOP
```

The position curve is smooth. The velocity curve has a zero crossing. The zero crossing is the bug.

### 3.5.2 Why CAMediaTimingFunctions naturally dip to zero velocity at endpoints

`CAMediaTimingFunction` is a cubic Bézier curve from `(0,0)` to `(1,1)` parameterized by two control points `(c1x, c1y)` and `(c2x, c2y)`. The velocity at each endpoint is determined by the curve's slope at that endpoint, which is determined by the control points.

For a cubic Bézier from `(0,0)` to `(1,1)`:
- **Velocity at t=0** = `3 · c1y / c1x` (when `c1x ≠ 0`)
- **Velocity at t=1** = `3 · (1 - c2y) / (1 - c2x)` (when `c2x ≠ 1`)

Apply this to standard easings:

| Name | Bezier `(c1x, c1y, c2x, c2y)` | Velocity at start | Velocity at end |
|---|---|---|---|
| `linear` | `(0, 0, 1, 1)` | constant 1.0 | constant 1.0 |
| `easeIn` | `(0.42, 0, 1, 1)` | **0.0** | high |
| `easeOut` | `(0, 0, 0.58, 1)` | high | **0.0** |
| `easeInEaseOut` | `(0.42, 0, 0.58, 1)` | **0.0** | **0.0** |

The pattern: **any non-linear easing has a zero-velocity endpoint by construction.** It's not a bug; it's the geometric definition of the curve type. easeOut's `c2 = (0.58, 1.0)` means the curve "approaches the end horizontally," which means velocity = 0 at the end. easeIn's `c1 = (0.42, 0.0)` means the curve "leaves the start horizontally," which means velocity = 0 at the start.

So **any time you compose two animations sequentially with `easeOut → easeIn` (or `easeInEaseOut → anything`), the join has velocity zero on at least one side, and the perceptual stop is inevitable.**

This is what was happening in our original CAKeyframeAnimation:

```
Segment 1: [1.0 → 1.08] easeOut over 0-2.8s   → velocity at 2.8s = 0
Segment 2: [1.08 → 2.3] easeIn  over 2.8-5.4s → velocity at 2.8s = 0
                                                         ▲
                                              ZERO-VELOCITY DIP
                                              at the boundary
```

### 3.5.3 The cubic-spline "fix" and why it created new problems

`CAKeyframeAnimation` with `calculationMode = .cubic` interpolates through keyframes with a Catmull-Rom-like cubic spline. Catmull-Rom is **C1-continuous at every interior keyframe** — meaning the velocity IS continuous at the keyframe values. This solved the velocity-zero at 1.08.

We tried this. It introduced three new problems:

1. **Endpoint tangents are computed from phantom points.** The spline algorithm needs to fabricate a control point beyond the first keyframe to compute the start tangent. With our asymmetric keyframes `[1.0, 1.08, 2.3]`, the fabricated tangent at t=0 produced unexpected initial behavior — the cell appeared to scale DOWN slightly or move strangely before scaling up. The user reported "weird pre-windup scaling."

2. **The shape of the spline is determined by the keyframe positions, not by our aesthetic intent.** We wanted easeOut character for the windup (fast initial, decelerating). The spline produced its own shape that wasn't easeOut. We lost the perfect windup feel that we had with explicit timing functions.

3. **The math is opaque.** You can't easily compute "at this t, what is the velocity?" because the spline's curve depends on neighboring keyframes in non-obvious ways. Tuning becomes guess-and-check.

**Conclusion**: cubic splines solve one velocity problem and create three new ones. Avoid them when you want precise control over the shape AND continuous velocity.

### 3.5.4 The Wave-spring retargeting insight (used as a teaching mechanism, not the final solution)

We dispatched a deep-dive agent on Wave (jtrivedi/Wave), specifically asking how it preserves velocity when retargeting a spring animation mid-flight. The agent returned a comprehensive 2500-word report. The single most important sentence from the report:

> **A spring's state is `(position, velocity)`. A retarget changes the target (equilibrium point) without touching the velocity. The integrator just keeps integrating from `(x, v)` with the new target. Continuity is structural, not handled.**

The implication: if you're using a **numerical integrator** (like a damped harmonic oscillator / spring), velocity preservation is FREE — you just don't reset it. If you're using a **parametric timing function** (like a CAMediaTimingFunction), velocity at boundaries is whatever the curve dictates, and you have no control.

We TRIED to implement this with V2's existing `SpringAnimator<CGFloat>` (which is itself a Wave port). It worked mathematically but introduced separate visual bugs (top-left anchor offset when writing `layer.transform` directly rather than via the `transform.scale` sub-keypath, plus an "immediate jumping" artifact from initial state writes). After two failed iterations we abandoned the spring approach and returned to CABasicAnimations — but armed with the conceptual understanding of WHY velocity continuity matters and the structural pattern (carrying state across boundaries) that solves it.

**The spring approach taught us the principle; we then applied that principle to a different mechanism (additive composition) that didn't have the spring's anchor-write bugs.**

### 3.5.5 The breakthrough: additive composition has structural velocity continuity

Here is the mathematical reason that our current implementation produces continuous velocity without any explicit handoff or retarget logic.

**With multiple concurrent additive animations contributing to the same property, the total velocity at any time is the SUM of the individual velocities.** For our morph's scale axis:

```
total_scale_velocity(t) = windup_velocity(t) + zoom_velocity(t)
```

Each individual animation has its own velocity profile. They CAN dip to zero individually. But their **sum doesn't have to dip** — as long as one is HIGH when the other is LOW.

This is the load-bearing math. **Velocity dips are individual-animation problems, not composition problems.** By having multiple animations contributing to the same property at the same time with DIFFERENT timing curves, the sum is always smooth even when each individual curve has a zero-velocity moment.

The proof reduces to a simple observation:

- `windup_velocity(2.8) = 0` ← yes, windup's easeOut decelerates to zero at its end
- `zoom_velocity(2.8) > 0` ← but zoom is mid-flight, with its slow-start bezier producing peak velocity in the middle of its 5.4s duration
- Therefore `total_velocity(2.8) = 0 + (positive) = positive` ≠ 0

The dip that exists in EACH individual curve is masked by the other curve being active. Neither animation has a "boundary" perceivable in the total motion.

### 3.5.6 Why our specific composition has no velocity dip — the proof

Concrete velocity values for the scale axis at key moments:

| time (s) | windup velocity | zoom velocity | TOTAL scale velocity | notes |
|----------|-----------------|---------------|----------------------|-------|
| 0.0 | high (easeOut start) | very low (slow-start bezier) | medium-high | windup carries |
| 0.3 | high-decreasing | very low | medium-high | windup still dominant |
| 0.5 | medium | low | medium | windup decelerating |
| 1.0 | low | rising | medium-low | crossover begins |
| 1.5 | very low | medium | medium | balanced |
| 2.0 | very low | medium-high | medium-high | zoom dominant |
| **2.8** | **0** (windup ending) | **medium-high** | **medium-high** | **NO DIP** ✓ |
| 3.5 | 0 (windup done, held) | high (zoom peak) | high | zoom alone |
| 4.5 | 0 | medium (zoom decelerating) | medium | settling |
| 5.4 | 0 | 0 | 0 | both at rest |

Plotted, the total velocity rises gently from t=0, peaks around t=3.0–3.5, and decays to zero by t=5.4. **No zeros in the middle. No dips. No stops.**

```
Total scale velocity (smooth, no zero dips except at t=0 and t=5.4):

  HIGH  ┤             ╱──╲
        │           ╱       ╲___
        │         ╱             ───
        │       ╱                  ──╲
   MED  │     ╱                       ─╲
        │   ╱                            ─╲
        │  ╱                                ─╲
   LOW  │ ╱                                    ─╲
        │/                                       ─╲
    0   ●────────────────────────────────────────────●
        0    1    2    3    4    5  (seconds)        5.4
                              ▲
              this used to be the zero-dip at t=2.8s
              now it's just a smooth curve passing through
```

The critical moment is t=2.8s. At that instant, windup's velocity has decelerated to zero (its individual easeOut animation is at its natural end). If we had ONLY windup — or if windup were SEQUENTIAL with zoom — the velocity would hit zero at t=2.8s. The classic dip.

But because zoom's velocity is HIGH at that exact moment (its slow-start bezier has been gradually accelerating since t=0 and is in its peak-velocity region around t=3.0), the TOTAL velocity remains medium-high. The dip in windup is invisible because zoom is filling in.

This is why the user perceives no stop. **There is no stop.** The math says so.

### 3.5.7 The complementary-curve principle (the key insight to internalize)

For additive composition to produce continuous velocity, the contributing animations must have **complementary velocity profiles** — where one is decelerating, another is accelerating.

```
windup_velocity:    HIGH ──── decreasing ────── 0 (at t=2.8)
                    └────────────────────┘
                       fills 0 → 2.8s

zoom_velocity:      0 ─── gradually rising ── HIGH ─── decreasing ─── 0 (at t=5.4)
                    └────────────────────────────────────────────────┘
                       fills 0 → 5.4s, but front portion is very low

sum velocity:       always positive between t=0+ and t=5.4-, smooth throughout
```

The KEY design choice: zoom's `(0.7, 0.0, 0.4, 1.0)` timing function has a HIGH `c1x` (0.7), which means it stays near zero for the first ~30% of its duration, then accelerates. This deferred acceleration is EXACTLY when windup is decelerating. They hand off without either being noticeable individually.

**Principle**: for visually continuous motion across an extended period, use multiple concurrent animations with COMPLEMENTARY timing curves rather than a single animation or chained animations. The complementarity is what produces velocity continuity.

### 3.5.8 The same principle solves both the cane curve AND the velocity continuity

Section 3 explained that the cane curve in motion-space emerges from MISMATCHED progress rates across dimensions (lift uses one curve, zoom uses another). This section explained that VELOCITY CONTINUITY emerges from complementary velocity profiles on the same dimension.

These are **two applications of the same architectural principle**: use multiple animations with deliberately different timing curves instead of one animation with one timing function.

- **Mismatch ACROSS dimensions** (lift uses aggressive easeOut, zoom uses slow-start bezier) → curved motion-space trajectory (the cane curve)
- **Mismatch WITHIN a dimension** (windup uses easeOut, zoom uses slow-start bezier, both contributing to scale) → continuous velocity (no dip)

Both visual properties (the cane curve AND the smooth velocity) emerge from the SAME architectural decision: **additive composition with asymmetric timing curves**.

If we had used one CABasicAnimation per dimension with one timing function each, we would have either an L-shape (no curve) or a velocity dip (if there were any waypoints). The architectural shift to "multiple complementary animations per dimension" solves both problems with one mechanism.

### 3.5.9 What we had to do to solve the velocity problem, in five sentences

1. Recognize that position continuity is necessary but not sufficient — **velocity continuity is the perceptual bar** because the eye is velocity-sensitive.
2. Realize that single CAMediaTimingFunctions CANNOT preserve velocity at endpoints by construction (cubic Bezier endpoints have zero velocity by definition of the easing names).
3. Stop trying to find ONE clever curve that has all the properties (windup feel + smooth velocity + curved trajectory) — no single cubic Bezier can.
4. Learn from spring-based velocity-preserving retargeting that **carrying state across boundaries** is the structural solution, then apply that pattern to CABasicAnimations via additive composition.
5. Tune the individual curves so their velocities are **complementary** — where one is decelerating, another is accelerating — so the sum is always smooth and the eye perceives no transition.

This is the architectural shift that solved the problem after 10+ iterations of trying to find single-curve solutions. The insight is generalizable: any time you face "I can't make this animation feel smooth with one curve," the answer is probably "use two complementary animations contributing to the same property."

### 3.5.10 The meta-lesson

Single-curve thinking is the trap. The desire to express a complex motion as ONE animation feels architecturally clean but fights the math: cubic Beziers are too constrained to encode all the perceptual properties we want simultaneously.

**Multiple-curve thinking is the escape**. Decompose the desired motion into independent contributions, each simple, each with one curve, all running on the same clock and SUMMING into the final visible motion. CoreAnimation's `isAdditive` mechanism gives us this composition for free.

The cane curve, the windup feel, the continuous velocity — none of these required a clever algorithm. They required REFRAMING the problem from "what is the right single curve?" to "what is the right composition of simple curves?"

---

## 4. The invariants — what each parameter does, what changes if you change it

This section documents the perceptual consequence of each tuning parameter. Treat these as load-bearing — change them only with intent.

### 4.1 Lift's `toValue = -50`

Controls **how high the cell rises**.

| Value | Visual consequence |
|-------|-------------------|
| −20 | Lift is subtle, easy to miss. The cane's neck is short — looks more like a slight overshoot than a deliberate gesture. |
| −32 (earlier iteration) | "Visible" but not dominant. The cell rises but doesn't claim attention. |
| **−50 (current)** | The cell visibly LEAPS upward. The lift dominates the first beat of the motion. |
| −80 | Cell goes way off-screen at the top. Loses connection to the destination state. |

### 4.2 Lift's timing function `(0.0, 0.0, 0.2, 1.0)`

Controls **how fast the lift happens at the very start**.

| `c2x` value | Visual consequence |
|-------------|-------------------|
| 0.58 (standard easeOut) | Lift moves with the same character as the zoom — proportional → linear trajectory → L-shape, no curve. |
| 0.4 | Lift somewhat front-loaded but doesn't break away fast enough from zoom. |
| **0.2 (current)** | Lift completes 50% in the first 10% of time. Cell visibly leaps before zoom registers. |
| 0.05 | Lift practically instant. Becomes a teleport rather than motion. |

The lower `c2x`, the more aggressively the curve "reaches up" early. The relationship between `c2x` and visible early-progress is nonlinear — small changes near 0 have large perceptual effect.

### 4.3 Zoom's timing function `(0.7, 0.0, 0.4, 1.0)`

Controls **when the zoom becomes visible**.

| `c1x` value | Visual consequence |
|-------------|-------------------|
| 0.0 (standard easeOut) | Zoom is FAST at start. Competes with lift for attention. Lift dominance is destroyed. |
| 0.42 (standard easeInEaseOut) | Zoom slow-start, but not slow enough — at 500ms in, zoom has visible progress, disrupting lift dominance. |
| **0.7 (current)** | Zoom is near-invisible for the first ~500ms. Lift owns the start. |
| 0.9 | Zoom doesn't begin meaningful motion until ~1.5s in. May feel like the cell freezes at the apex of the lift. |

The higher `c1x`, the more the zoom defers its action. Too high and the cell appears to pause mid-flight; too low and the cane curve collapses to an L.

### 4.4 Windup's `toValue = 0.08`

Controls **the strength of the "preparation" anticipation cue**.

| Value | Visual consequence |
|-------|-------------------|
| 0.0 | No windup contribution. Cell scales smoothly toward chat-rest with no preparation moment. Loses the "gathering energy" feel. |
| **0.08 (current)** | Subtle but readable. Combined with the aggressive lift, the cell appears to coil before zooming. |
| 0.20 | Windup is dramatic — cell visibly inflates at the start. May overshadow the zoom's preparation. |
| 0.50 | Windup competes with zoom for the scale dimension. Feels confused. |

### 4.5 Concurrency — what happens if any animation's `beginTime` is offset

All three currently start at `now`. If any is offset:

| Change | Visual consequence |
|--------|-------------------|
| Zoom delayed by 1s (`beginTime = now + 1.0`) | Cell lifts, FREEZES at apex for 1 second, then begins zooming. The "freeze" is perceptually fatal — reads as a bug. |
| Lift delayed by 0.3s | Cell scales briefly, THEN starts lifting. The motion has two beats instead of one continuous arc. |
| Windup delayed by 0.5s | The preparation cue arrives AFTER the lift already started — feels like a small jitter on top of the lift. |

The reason starting simultaneously works: the asymmetric easings produce the perceptual sequencing automatically. The lift is visible first because of its aggressive curve. The zoom is visible second because of its slow-start curve. They run on the same clock but appear sequenced.

### 4.6 The "morph duration" knob

Currently `totalMorphDuration = 5.4s` for analysis. For production:

| Duration | Use case |
|----------|----------|
| 5.4s | Frame-by-frame analysis (current) |
| 1.2s | Production-feeling (Dot reference is ~1.0s) |
| 0.6s | Aggressive / snappy variant |
| < 0.4s | Reads as "snap" — the curve detail is lost |

To rescale, divide ALL durations (windupDuration, totalMorphDuration, label-fade delay) by the same factor. The CURVES preserve their shape; only the time scale changes.

---

## 5. The journey — what didn't work, and why

The current implementation is the result of perhaps 15+ failed iterations. Each failure taught something specific. Documenting them so future-you doesn't repeat them.

### 5.1 V2 motion (Y-arc + Z-perspective bell curves)

**Approach**: a master `CADisplayLink` timer drove a single `t ∈ [0, 1]` value; every visual property (heightConstraint, camera y, Y-arc translation, scale pulse) was a deterministic function of `t`. Z-perspective via `contentHost.layer.sublayerTransform.m34 = -1/1000`.

**Failure**: At peak (`t ≈ 0.35`), the Z-translation reached 700pt, producing apparent scale `1000/(1000-700) = 3.33×`. Text and content became massively zoomed mid-morph ("giant text mid-morph"), then snapped back. Subview twitch from per-tick `heightConstraint.constant + layoutIfNeeded()` updates. The composition was a Frankenstein.

**Lesson**: per-frame multi-property orchestration is fragile. The same logical motion can be expressed as a few well-tuned animations on independent properties without an orchestrator.

### 5.2 Bounds-based extension with `heightConstraint`

**Approach**: animate `cell.heightConstraint.constant` from natural to viewport height inside `UIView.animate`, with `layoutIfNeeded()`. The cell visibly extends to fill the screen.

**Failure**: V2's `CellView.setCamera` is called by `updateVisibleCells` on every layout pass. With the constraint animating, `setCamera` fires repeatedly with bounds-derived `progress` computed from the model layer (which jumps to the end value immediately). The result: every layout pass clobbered our alpha writes with bounds-derived ones, the chat scrollView's bubbles became visible during the morph, and the cell-rest content didn't fade correctly.

**Lesson**: bounds-based animations interact badly with bounds-derived computations elsewhere in the codebase. A `morphInProgress: Bool` gate eventually solved this — but the fundamental issue was that we were trying to drive the morph from the wrong dimension. Scale (a layer transform) is orthogonal to bounds (a layout property), and orthogonality eliminates the conflict.

### 5.3 Snapshot-based approaches

**Approach**: capture the cell as a bitmap via `drawHierarchy(in:afterScreenUpdates:)` at tap time, animate the bitmap separately from the live cell. Multiple variants: portal-mirror, dual-bitmap crossfade, masked-reveal-of-pre-rendered-backdrop.

**Failure**: every variant ran into Vertigo Effect issues — when you combine a bitmap-scale with the live cell's own bounds extension, the apparent size composition is non-monotonic. Mid-morph the user saw a giant smeared bitmap occluding the destination. Frame analysis later (frames 19.4-19.8 of `dot_pinch.mov`) eventually disproved that Dot uses any snapshot — pixel-diff showed the chat-rest content's BACKDROP is bounded by the cells' own fills, never revealing a separate surface from underneath.

**Lesson**: trust the frame analysis. The simplest mechanism that matches the visible behavior is almost always the right one. Snapshots add architectural complexity that pays off only when no native composition matches.

### 5.4 CAKeyframeAnimation with `[easeOut, easeIn]` timing functions

**Approach**: a single `CAKeyframeAnimation` on `transform.scale` with `values = [1.0, 1.08, 2.3]`, `timingFunctions = [easeOut, easeIn]`. The position curve passes through 1.08 (the "windup waypoint") on its way from 1.0 to 2.3.

**Failure**: easeOut DECELERATES to zero velocity at its end. easeIn STARTS at zero velocity. At the 1.08 keyframe, the velocity hits the floor. The position curve is continuous but the velocity is not — a near-zero velocity period at the inflection reads as a **perceptual stop**, even though the scale value is monotonically increasing. The eye reads "the cell decelerates, stops at 1.08, and then re-accelerates."

**Lesson**: position continuity is necessary but not sufficient for perceptual continuity. **Velocity continuity is the bar.** The eye is sensitive to velocity, not just position.

### 5.5 CAKeyframeAnimation with `.cubic` calculation mode

**Approach**: same `CAKeyframeAnimation` but with `calculationMode = .cubic` and `timingFunctions` removed. Catmull-Rom-like cubic spline interpolation through `[1.0, 1.08, 2.3]`. The spline is C1 continuous (continuous velocity at every keyframe).

**Failure**: the cubic spline's tangent at the FIRST keyframe (1.0, t=0) is computed from a "phantom" point that the spline algorithm fabricates. With three asymmetric keyframes (1.0 → 1.08 → 2.3), the start-tangent computation produced unexpected initial motion — the spline made the cell appear to scale DOWN momentarily before scaling up, or scale up very slowly, before catching up. The windup felt "jarring and weird."

**Lesson**: cubic splines through arbitrary keyframes don't respect your aesthetic intent at the endpoints. The shape of the spline is a consequence of the keyframe positions, not a choice you make. Custom Bézier per segment gives more control.

### 5.6 SpringAnimator with velocity-preserving retarget (Wave-style)

**Approach**: replace the CAKeyframeAnimation with a `SpringAnimator<CGFloat>` that targets 1.08 first; mid-flight (before settling), retarget to 2.3. Velocity is preserved by the integrator — the spring just bends toward the new target without resetting.

**Failure**: I wrote the spring's `valueChanged` callback to set `contentHost.layer.transform` directly. CALayer's `transform` is applied around `layer.anchorPoint`, but my direct write bypassed the sub-keypath KVC path that handles anchor centering correctly. The result: the cell appeared to zoom from the TOP-LEFT corner instead of the center. Cells visually offset to the right as they scaled. Also "immediate jumping" because the model layer transform was being set instantaneously.

**Lesson**: there are TWO ways to write `layer.transform`:
1. `layer.setValue(_, forKeyPath: "transform.scale")` — KVC path, decomposes/recomposes, anchored at `layer.anchorPoint`
2. `layer.transform = CATransform3D...` — direct write, not anchored automatically

Use the first when you want anchor-centered behavior. The fact that V2's working CABasicAnimations on `"transform.scale"` always used the first path (because that's the only thing CABasicAnimation can do on a sub-keypath) was load-bearing — my SpringAnimator approach lost it.

### 5.7 Separated sequential CABasicAnimations (`easeOut` → `easeOut`)

**Approach**: two distinct CABasicAnimations chained at `beginTime`. Windup: 1.0 → 1.08, easeOut, 0–2.8s. Zoom: 1.08 → 2.3, easeOut, 2.8–5.6s. The "easeOut → easeOut" choice was supposed to feel like "decelerating, then snapping into a fast release."

**Failure**: the join still felt disjointed. The velocity at t=2.8s went from "windup decelerating to ~0" to "zoom starting at HIGH velocity" — a velocity DISCONTINUITY. Even though the eye sometimes reads such jumps as "release," in this case the windup's deceleration was prominent enough that the user perceived the stop before the release.

**Lesson**: replacing one velocity-zero with one velocity-jump doesn't fix the underlying problem. The velocity profile needs to be SMOOTH, not just non-zero.

### 5.8 Additive CABasicAnimations with brief overlap

**Approach**: both windup and zoom on the same `transform.scale` keypath with `isAdditive=true`. Windup runs 0–2.8s; zoom runs 2.2–5.4s (0.6s overlap window). Their contributions sum.

**Improvement**: during the overlap window, both animations are contributing velocity, so the combined velocity doesn't dip — windup's deceleration is masked by zoom's acceleration.

**Failure**: still felt slightly disjointed because the overlap window was only 0.6s. The user perceived an "L corner" in motion-space because the LIFT animation (translate.y) was still ending at 2.8s while only zoom continued after — a sharp dimensional handoff.

**Lesson**: overlap helps but isn't sufficient when there are other dimensions of motion. ALL motion dimensions need to remain alive throughout, not just the dimension that's being overlapped.

### 5.9 Fully simultaneous animations with same easings

**Approach**: all three animations (windup, zoom, lift) start at `t=0` and end at `t=5.4`. All use `easeOut`. Maximum overlap.

**Improvement**: no more L-corner from sequential phases. The COMBINED motion has no inflection points.

**Failure**: with all three using the same easing, the trajectory in (lift, scale) motion-space was a **straight diagonal line**. The motion was proportional — at any moment, lift and scale had advanced the same percentage of their targets. The user described this as "the L is gone but it's a straight diagonal, not a cane."

**Lesson**: same easings on different dimensions = linear motion-space trajectory. To get a CURVED trajectory, the dimensions must have DIFFERENT easings so they advance at different rates.

### 5.10 Asymmetric easings — the breakthrough (current implementation)

**Approach**: lift uses aggressive easeOut `(0.0, 0.0, 0.2, 1.0)` (front-loaded), zoom uses slow-start easeIn-like bezier `(0.7, 0.0, 0.4, 1.0)` (back-loaded). Both run concurrently from `t=0` to `t=5.4`.

**Success**: lift advances 50% in the first 10% of time while zoom advances <1%. The cell visibly LEAPS upward before the zoom registers. As lift decelerates into its tail, zoom is ramping up. Both finish together at t=5.4s. The trajectory in motion-space bends from "mostly vertical at the start" to "mostly horizontal at the end" — a cane.

**The insight**: it took 15+ iterations to arrive here because each fix targeted a symptom but introduced a different one. The KEY insight wasn't any single change — it was understanding that **the cane curve emerges from MISMATCHED progress rates across dimensions**, not from any single animation's timing function. The breakthrough came from articulating the problem in (lift, scale) motion-space rather than in time.

---

## 6. Frame-analysis methodology — how to extract truth from a reference video

We spent many hours analyzing `_frames/dot_pinch.mov` (the Dot reference). Here is the methodology, written so future-you doesn't repeat the mistakes.

### 6.1 Detect the actual frame rate before sampling

The video's `ffprobe` metadata claimed `r_frame_rate=120/1`. In reality, `nb_frames=895` over `duration=45.15s` yields ~19.83fps. The metadata was misleading.

**Mistake**: extracting frames at 50ms intervals assuming 120fps — produced duplicate extracted frames at adjacent timestamps (aliasing) which I misinterpreted as "motion plateaus." There were no plateaus; my sampling rate exceeded the video's actual frame rate.

**Correct approach**: query `ffprobe -show_entries packet=pts_time` to get the actual timestamp of every encoded frame. Extract one frame per unique timestamp. This guarantees no duplicates and no missed frames.

```bash
ffprobe -loglevel error -select_streams v:0 -show_entries packet=pts_time \
  -of csv=p=0 path/to/video.mov | sort -n
```

### 6.2 Use pixel-diff to detect sub-perceptual motion

For seemingly-static segments, visual inspection at typical viewing zoom is insufficient. `magick compare -metric AE -fuzz 1%` quantifies how many pixels differ between frames. Use a small fuzz factor (1%) to ignore codec noise.

**What we found**: the supposedly-static "baseline" at 18.00–19.08s actually had monotonically-growing pixel differences from 18.28s onward — a ~700ms wind-up phase that was invisible to side-by-side comparison but visible in pixel-diff.

This is what eventually became our windup animation.

### 6.3 Diff visualization with `-highlight-color`

```bash
magick compare -metric AE -highlight-color red baseline.png end.png diff.png
```

Produces an image where changed pixels are red. The SHAPE of the red regions tells you WHAT moved, not just THAT something moved. For our case, the red highlighted the cells' EDGES — specifically the TOP edge had thicker red than the BOTTOM edge, which is the geometric signature of "scale + lift up" (top moves more than bottom).

This is how we confirmed the asymmetric expansion that became our lift + scale combination.

### 6.4 Vertical-slice temporal stacking

To see motion through a specific X column over time, stack thin vertical strips horizontally:

```bash
for f in frame_*.png; do
  magick "$f" -crop 8x1000+390+200 +repage "slice_$f"
done
magick slice_*.png +append timeline.png
```

The resulting image visualizes how a vertical slice of the original moves over time. Horizontal stripes in the result correspond to vertical motion in the source. We used this to track the divider line between cells over time, which revealed when (and how fast) the cells were compressing.

### 6.5 Cropping landmarks for measurement

Once you've identified an important visible feature (like a specific glyph), crop the same region from multiple frames and stack them side-by-side at high zoom:

```bash
for f in baseline.png mid.png end.png; do
  magick "$f" -crop 250x300+0+800 +repage "pinch_$f"
done
magick pinch_*.png +append -scale 1200x stack.png
```

We did this for the pinch glyph at the bottom-left of the Today card. At high zoom, the position changes that were invisible at native resolution became measurable.

---

## 7. The articulation problem — why this was the hardest part

The longest stretches of this work were not spent writing code. They were spent finding the right LANGUAGE to specify what the motion should look like. This section documents that struggle so future-you takes it more seriously.

### 7.1 Mismatched mental models

Multiple times, the user described what they wanted in metaphors that my mental model didn't parse correctly:

- **"Cane shape, not L shape"** — at first I parsed this as a description of the cell's visible trajectory across the screen. After several wrong implementations, I realized they meant the motion-space trajectory (lift × scale), not screen-space trajectory.
- **"Like a vertex, but U-shape not V-shape"** — this was a description of how the dimensional handoff should feel. I initially interpreted it as the velocity curve shape; the user meant the geometric motion in 2D dimension-space.
- **"Snapshot behind the cells"** — the user had a sophisticated hypothesis about Dot using a backdrop reveal mechanism. I had to do extensive frame analysis to disprove this respectfully and propose the simpler native-animation explanation.
- **"Perpendicular, facing me"** — meant "the motion has a Z-axis (toward viewer) component" — i.e., scale-toward-viewer. I almost missed this dimension entirely because I was thinking only about X and Y motion.

**The pattern**: the user's mental model and mine often diverged on the dimensionality or framing of the problem. Reconciling this required asking specific questions ("when you say X, are you describing dimension A, B, or C?") rather than guessing.

### 7.2 The role of `AskUserQuestion`

Use it BEFORE building when the user's spec is ambiguous about its referent.

When the user said "L shape vs U shape," the right move was NOT to start coding a fix. The right move was to ask: "is the L you're describing (a) the trajectory in motion-space, (b) the velocity curve over time, or (c) the cell's visible path on screen?" These three interpretations require very different code changes.

The cost of asking is one round-trip. The cost of guessing wrong is a build + visual inspection + revert + apology cycle that costs 5–10 round-trips.

### 7.3 Frame-by-frame as the source of truth

When user perception and my code disagreed, frame-by-frame analysis was always the tie-breaker. Specifically:

- When the user said "I'm seeing pre-windup scaling," frame extraction proved them right (it was the cubic spline's start tangent doing unexpected motion).
- When the user said "the chat is showing through," frame extraction confirmed it was the scrollView's bubbles, not a different element.
- When the user said "I shouldn't be seeing this screen," the screenshot they shared was unambiguous evidence and required immediate revert.

**Lesson**: never argue with the user's perception. Either reproduce it via frame extraction and admit the bug, or precisely identify the disconnect via AskUserQuestion. Arguments without visual evidence are arguments about who's right, not about what's true.

### 7.4 What took so long, in five sentences

1. Multiple aborted attempts that addressed symptoms rather than root causes (subview twitch, chat-content leaking, anchor offset, top-left scaling, velocity-zero, L-corner) each introduced a new symptom that took another round to identify.
2. The frame rate of the reference video was misidentified at first (15fps actual vs 120fps claimed), causing me to think there were "motion plateaus" that didn't exist.
3. The wrong cell was assumed to be the agent of motion (I thought Raffi was being tapped/animated, actually it was Today).
4. Multiple architectural transforms were attempted (V2 motion, bounds-extension, snapshots, springs, keyframes) before settling on the simplest viable composition (three additive CABasicAnimations).
5. The geometric insight that "asymmetric easings produce curved motion-space trajectories" took ~10 iterations to discover, because it's not a fact about animation that's documented anywhere — it has to be derived from the motion-space framing the user provided ("cane vs L").

### 7.5 The meta-lesson

**The hardest part of this task was not implementation.** Implementation took maybe 30 minutes of typing across the whole project. The hard parts were:

- Articulating the visible behavior precisely enough to map to code
- Distinguishing perceptual signals (the user's eye) from algorithmic signals (the code's behavior)
- Recognizing which mental model the user was using (motion-space vs screen-space vs velocity-time vs frame-by-frame)
- Knowing when to ask before coding vs when to revert and start over

Most of the failed iterations were not failures of the code — they were failures of the SHARED UNDERSTANDING that the code was supposed to encode. Once the shared understanding crystallized (around the "cane curve in motion-space" framing), the code change was almost trivial.

This is the standard lesson of building visual systems: the specification problem is usually larger than the implementation problem. Treat the conversation as the work.

---

## 8. Reference tuning values (current)

For reproducibility at commit `78c129c`:

```swift
// In TimelineCanvas.swift → animateCameraToChatRest(forCellAt:)

let windupDuration: CFTimeInterval = 2.8       // brief preparation cue
let totalMorphDuration: CFTimeInterval = 5.4   // analysis speed (production: 1.0–1.2s)

// Windup scale (additive, brief)
windupScale.fromValue = 0
windupScale.toValue = 0.08
windupScale.duration = windupDuration
windupScale.timingFunction = CAMediaTimingFunction(name: .easeOut)

// Zoom scale (additive, dominant, slow-start)
zoomScale.fromValue = 0
zoomScale.toValue = 1.22
zoomScale.duration = totalMorphDuration
zoomScale.timingFunction = CAMediaTimingFunction(controlPoints: 0.7, 0.0, 0.4, 1.0)

// Lift (additive, aggressive front-loaded easeOut)
translate.fromValue = 0
translate.toValue = -50
translate.duration = totalMorphDuration
translate.timingFunction = CAMediaTimingFunction(controlPoints: 0.0, 0.0, 0.2, 1.0)

// Final layer scale at t=5.4s: 1.0 + 0.08 + 1.22 = 2.30
// Final layer translation.y at t=5.4s: -50pt
```

All three on `contentHost.layer` with `isAdditive=true`, `fillMode=.forwards`, `isRemovedOnCompletion=false`.

Pre-morph (instant, before adding animations):
- `activeCell.scrollView.alpha = 0`
- `activeCell.pillContainer.alpha = 0`
- `activeCell.chatRevealBlur.alpha = 0`
- `activeCell.blurOverlay.alpha = 0`
- `activeCell.morphInProgress = true`

Delayed (at `t = windupDuration = 2.8s`):
- `labelStack.alpha = 0` + `pinchGlyph.alpha = 0` via `UIView.animate(withDuration: 2.6, options: .curveEaseIn)`

To scale to production timing: divide `windupDuration` and `totalMorphDuration` by the same factor (e.g., 4.5× faster = `windupDuration = 0.62`, `totalMorphDuration = 1.2`). The timing functions and target values stay the same.
