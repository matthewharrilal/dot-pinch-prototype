# METACOGNITIVE — Warm branches survey
POSTURE: janum

---

## Branch G — Reduce Motion

### Apple's pattern
`UIAccessibility.isReduceMotionEnabled` is a read at call time — `UIView.animate` does NOT
check it automatically. Your spring integrator, the `CADisplayLink` master timer, and
`CABasicAnimation` keychains all animate regardless of the system setting. You own the gate.
`UIAccessibility.reduceMotionStatusDidChangeNotification` lets you react to live toggles.
(WWDC 2019 #224 — Accessibility in iOS and iPadOS)

### Decision points for DotPinchPrototype
Three tiers of motion, with different reduce-motion treatment:

| Motion | Semantic meaning? | Reduce Motion policy |
|---|---|---|
| Pan scroll deceleration | No — pure navigation | Snap or short crossfade |
| Spring settle (pinch/tap-to-chat) | Yes — morph indicates cell→surface transition | Simplify: shorten duration, keep direction; do NOT remove |
| CABasicAnimation morph keychain (windup + zoom + centering) | Core semantic | Replace with opacity crossfade + immediate extension; still show the transition |

The `animateCameraToChatRest` method has a 1.5 s CABasicAnimation keychain with perspective
arc and Z-translation. Under Reduce Motion this should collapse to a ~0.25 s opacity + bounds
crossfade. The `masterTimer` in `applyMasterTick` (1.2 s linear) should likewise snap to a
2–3 frame cut-to-end (rawT jumps to 1.0).

Check point: add a `reduceMotionEnabled` flag to `AnimationController` (or a separate policy
object) so all engagement paths branch from one place. The current code has zero RM awareness.

### HOT escalation
**Not HOT for this prototype.** Worthwhile to design the branch point before shipping,
but none of this blocks prototype iteration.

---

## Branch H — Lifecycle / Scene state

### Pattern
`CADisplayLink` pauses automatically when the app is backgrounded (iOS suspends the run loop).
The `AnimationController.displayLink` will be paused-by-iOS while backgrounded. On foreground
return the display link resumes from whatever `isPaused` state was in effect, but the
`SpringAnimator` integration clock is `CACurrentMediaTime()` — so `runningTime` on next tick
reflects wall-clock elapsed, including background time. Outcome: an animation that was mid-
flight when backgrounded will jump its spring forward by the background duration on the first
foreground tick, likely snapping directly past `settlingDuration`.

The `masterTimer` CADisplayLink (for tap-to-chat morph) has the same exposure: `elapsed =
CACurrentMediaTime() - masterTimerStart` — if backgrounded for 3 seconds during a 1.2 s
morph, the first foreground tick fires with `rawT = 1.0` immediately, jumping to final state.
This is the CORRECT behavior for the morph (don't leave the cell half-morphed), but worth
documenting as intentional.

The `SpringAnimator` case deserves a decision: during a spring deceleration pan (user lifts
finger, spring settles), background-to-foreground snap-to-end is also correct — the
alternative (long background, resume smooth spring from 2 s ago) is confusing.

`UIApplication.didEnterBackgroundNotification` / `willEnterForegroundNotification` subscription
is absent from `AnimationController`. If you want explicit snap-to-end behavior
(rather than clock-skip), observe `willEnterForegroundNotification` and call
`animator.stop(immediately: false)` (sets target as current). Not required for the prototype.

Multi-window / iPad: TimelineCanvas holds a single `AnimationController`. iPad split view /
Stage Manager would need per-scene controllers if multiple windows host canvases — irrelevant
at iPhone-only scope.

### HOT escalation
Not HOT. Clock-skip behavior is acceptable and arguably correct for this prototype. Note for
when the app ships: add an explicit foreground-notification handler that snaps any in-flight
springs if the elapsed background time exceeds a threshold (e.g. 500 ms).

---

## Branch I — Cross-platform (Catalyst, visionOS, iPad)

### Pattern
`TARGETED_DEVICE_FAMILY = "1,2"` means iPad is declared. iPad-specific concerns today:

- **Split View / Slide Over**: `TimelineCanvas` is a full-screen view. In Slide Over its
  `bounds.width` can be ~320 pt. `pageFrameForCell` uses `bounds.width` directly — layout
  degrades gracefully because cell layout is width-relative. The spring mechanics are
  viewport-H-relative (`chatRestFactor = bounds.height / naturalH`) — this holds on iPad.

- **Landscape**: Layout is purely constraint-driven + `bounds`-relative. No hardcoded screen
  dimensions found. Should be fine.

- **Pointer hover (iPad + Magic Keyboard/Trackpad)**: No `UIHoverGestureRecognizer` in the
  codebase. The pinch glyph on each cell has no hover preview. Low priority for prototype.

**Mac Catalyst / visionOS**: Not in scope. The project target is iOS. No decisions needed now.

### HOT escalation
Not HOT. iPad landscape/split-view warrants a visual verification pass before any public
release, but mechanics are sound.

---

## Branch J — Memory management (retain cycle discipline)

### Existing strengths
- `DisplayLinkProxy` pattern in `AnimationController` correctly breaks the
  CADisplayLink → target retain cycle.
- `SpringAnimator.controller` is `private weak var`.
- `CameraAnimator.canvas` is `private weak var`.
- `CameraAnimator.wireValueChangedAndCompletion` uses `[weak self]` on both closures.
- `TimelineCanvas.extensionAnimator.valueChanged` uses `[weak self]`.

### Gaps

**`animateCameraToCellRestPath` closure capture:**
```swift
cameraAnimator.animate(to:...) { [weak self] in
    self?.tryClearActiveCellAtRest(expectedIdx: activeIdxCaptured)
}
extensionAnimator.completion = { [weak self] event in
    if case .finished = event {
        self?.tryClearActiveCellAtRest(expectedIdx: activeIdxCaptured)
    }
}
```
Both use `[weak self]` — correct. `activeIdxCaptured` is a value type (Int) — no cycle risk.

**`V2RootViewController.revealChat` UIView.animate completion:**
```swift
completion: { _ in
    blur.removeFromSuperview()
    if self.revealBlurOverlay === blur { self.revealBlurOverlay = nil }
}
```
This captures `self` **strongly** in a `UIView.animate` completion. `UIView.animate`
retains its completion until it fires and then releases — the VC will not be deallocated
until the blur animation completes (~0.7 s), but it cannot cause a permanent cycle because
UIKit releases the block after firing. Borderline; `[weak self]` is still the right habit.

**`masterTimerTick`**: `CADisplayLink(target: self, ...)` inside `startMasterTimer`. This
creates a strong reference from the displayLink → TimelineCanvas. `masterTimer.invalidate()`
is called on completion and on `handlePinchBegan`. As long as `invalidate()` is always called
before the canvas releases, no leak. The absence of a `deinit` invalidation on `masterTimer`
in `TimelineCanvas` is a gap — if a canvas is deallocated mid-morph, the display link
continues calling `masterTimerTick` on a nil-reachable (but not yet dealloc'd?) object.

**Recommendation**: add to `TimelineCanvas`:
```swift
deinit { masterTimer?.invalidate() }
```

### HOT escalation
**FLAG**: `masterTimer` CADisplayLink has no `deinit` invalidation on `TimelineCanvas`.
Not a crash risk in the prototype's single-VC lifecycle, but a correctness gap. Low severity.

---

## Branch K — Frame-budget-aware degradation

### Current state
`AnimationController.displayLink` is configured:
```swift
link.preferredFrameRateRange = CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120)
```
The `masterTimer` CADisplayLink uses default rate (likely 60 Hz). Mismatch: the spring
animations run at up to 120 Hz but the master morph timer runs at 60 Hz. The morph would
tick at 60 Hz while spring decelerations tick at 120 Hz — perceptible only if both run
simultaneously, which they don't by design (master timer stops the springs).

### Frame skip behavior
`SpringAnimator.updateAnimation(dt:)` uses the actual `dt` between frames. If a frame takes
16 ms (dropped at 120 Hz), the spring integrates a double-step on the next tick. This is
correct forward-Euler behavior — no jitter accumulation because the integration is
`CACurrentMediaTime()` wall-clock anchored, not accumulated-dt.

`applyMasterTick` uses `rawT = elapsed / duration` — also wall-clock anchored, drops are
invisible (progress jumps ahead by the missed time). Correct behavior.

### Adaptive degradation
No adaptive quality mechanisms exist (blur radius, shadow softness, particle count). Not
needed: the prototype has no blur-driven spring properties, no particle system. The
`UIVisualEffectView` blur in `revealChat` is constant-style, not animated-intensity.
If a dynamic blur were added, `CADisplayLink.targetTimestamp - timestamp` gives per-tick
budget headroom for adaptation decisions.

### HOT escalation
**FLAG**: `masterTimer` uses default frame rate (60 Hz) vs `AnimationController`'s 120 Hz
range. Non-critical today (no simultaneous execution), but worth aligning if the morph path
ever coexists with spring animations. Add `preferredFrameRateRange` to `masterTimer`.

---

## Branch L — Lottie / asset pipeline

### Pattern
Lottie renders designer JSON animations at runtime. Appropriate for: loading spinners,
mascot sequences, onboarding illustrations, multi-keyframe state machines with authored
easing. Inappropriate for: gesture-coupled animations (Lottie's `animationProgress` API
supports gesture scrubbing but adds overhead and coupling), physics-driven animations
(spring integrators and Lottie fight), any animation whose geometry depends on runtime layout.

### DotPinchPrototype relevance
The prototype's animations are entirely layout-driven and gesture-coupled (springs, pinch
extension, morph). No authored illustration assets. Lottie has no role here. The one place
Lottie-style thinking applies: the `pinchGlyph` — currently a `UIImageView`. If a designer
wanted an animated glyph (pulse, bounce), Lottie would be appropriate for that isolated asset.

### HOT escalation
Not HOT. No Lottie integration decision is needed for this prototype.

---

## Branch M — Server-driven animations

### Pattern
SDUI animation specs: server sends `{ type: "spring", damping: 0.6, response: 1.1 }` etc.,
client maps to local primitives. Enables A/B testing animation parameters, hot-patching UX
without a release. Scales when: animation parameters (not structure) vary; client has a
stable execution model. Breaks when: animation topology changes (new properties, new
coordinators), interactive/gesture coupling, timing coordination contracts (like the
masterTimer's `tryClearActiveCellAtRest` handshake).

### DotPinchPrototype relevance
`PinchTuning` is already a centralized constants namespace — `springDamping`,
`tapToChatDamping`, `anticipationMagnitude`, etc. This is the seed of a server-overridable
config. For prototype and early production, static config is correct. SDUI for animation
params becomes relevant only when you have a CI/CD pipeline and a controlled rollout
infrastructure — at 1-team / 1-app scale, shipping a new build is faster and safer.

The `animateCameraToChatRest` morph has too many interdependent geometric constants
(`windupDuration`, `totalMorphDuration`, `liftEndMagnitude`, `zoomContribution`) to safely
externalize — they'd need a compatibility-versioned schema.

### HOT escalation
Not HOT. `PinchTuning` is the right abstraction for now. SDUI is a future infrastructure
decision, not an architecture decision for this prototype.

---

## Cross-cutting findings

1. **Clock-anchored integration is consistent**: both `SpringAnimator` (wall-clock
   `runningTime`) and `applyMasterTick` (`elapsed / duration`) use absolute time, not
   accumulated `dt`. Background-to-foreground transitions snap to end rather than resuming
   — this is correct behavior, but unintentional. Make it intentional (document or test).

2. **No lifecycle notification subscriptions anywhere**: `AnimationController`,
   `TimelineCanvas`, and `V2RootViewController` have no observers for background/foreground or
   reduce-motion change notifications. Safe for prototype; required before shipping.

3. **`masterTimer` is a second `CADisplayLink` not managed by `AnimationController`**: it runs
   independently, at 60 Hz default, has no `deinit` invalidation on `TimelineCanvas`. The two-
   displayLink architecture works today because they never run simultaneously, but creates a
   maintenance surface.

---

## HOT escalations

| Branch | Finding | Severity |
|---|---|---|
| J | `masterTimer` CADisplayLink has no `deinit` invalidation on `TimelineCanvas` | Low — no crash in prototype; correctness gap |
| K | `masterTimer` default 60 Hz vs `AnimationController` 120 Hz range | Low — no simultaneous execution today |
| H | Clock-skip-to-end on foreground return is correct but undocumented/untested | Info — document as intentional |

No branch escalates to re-investigation depth. The architectural decisions that matter before
shipping are: (1) a single Reduce Motion gate in `AnimationController`, (2) `masterTimer`
lifecycle ownership, (3) foreground-notification snap-to-end for long backgrounding.
