# Animation Substrate

Everything that moves in DotPinch flows through a small, principled L1 kernel in `DotPinchPrototype/Animation/`. The substrate is 8 files, ~450 LOC total, with zero non-substrate dependencies. It is Bottling-ready as `SpringSubstrate` (deferred — see REFACTOR-CHECKLIST.md §Bottling Destination).

## The kernel

### `AnimationController` — `Animation/AnimationController.swift`

One `CADisplayLink`, one tick handler, one shared `dt`. All registered animators advance in lockstep each frame, so multi-property animations (camera + extension height + cell transforms) stay phase-locked. Each frame opens a `CATransaction(setDisableActions: true)` so UIKit's implicit 0.25s tweens never appear under per-frame view writes.

- `runPropertyAnimation(_ animator: AnimatorProviding)` registers an animator. The controller wakes the display link if needed and starts ticking. When all animators report `state == .ended` the link is paused.
- The controller is `@MainActor`-isolated. The display link callback hops to the main runloop via `CADisplayLink.add(to: .main, forMode: .common)`.
- `preferredFrameRateRange` is set for ProMotion 120Hz on iPhone 16 (`AnimationController.swift:25`).

There is exactly **one** `AnimationController` instance per app. It is owned by the composition root (`V2RootViewController`) and passed into every consumer. Keystone K8 enforces this — the canary test asserts that `cameraAnimator` and `extensionAnimator` share the same controller identity.

### `AnimatorProviding` — `Animation/AnimatorProviding.swift`

The animator contract. Every animator has an `id: UUID`, a `state: AnimatorState`, and an `updateAnimation(dt:)` method. The controller stores animators by `id`, ticks them in insertion order, and removes them when `state == .ended`.

`AnimatorState`: `.inactive` → `.running` → `.ended`. Insertion order is load-bearing: callers that depend on cross-animator state coordination (e.g. `tryClearActiveCellAtRest`'s dual-spring AND-gate) must register the first-to-tick animator first.

### `Spring` — `Animation/Spring.swift`

Spec value-type. Two parameters: `dampingRatio` and `response`. Closed-form `settlingDuration` derived from the spec. No mutable runtime state — the spec describes the spring, the integrator drives it.

### `SpringInterpolatable` — `Animation/SpringInterpolatable.swift`

Numeric protocol with `+`, `-`, `*`, `zero`, `isFinite`, and an `updateValue(spring:value:target:velocity:dt:)` static. `CGFloat` conforms. The protocol is the substrate's only generic boundary.

### `SpringAnimator<T>` — `Animation/SpringAnimator.swift`

Generic stateful spring integrator. Wave-style (adapted from `jtrivedi/Wave`). Velocity is preserved across in-flight target changes: setting `target` while `state == .running` resets `startTime`, fires `.retargeted`, and bends the trajectory. Settling completes via the spring's closed-form `settlingDuration`, not a position threshold.

The **final-tick ordering contract** (load-bearing — `SpringAnimator.swift:111-155`):

```
value → valueChanged → completion → state = .ended
```

`tryClearActiveCellAtRest` (in `TimelineCanvas`) depends on `completion` firing while `state` is still `.running` — Wave 7 hardened this to a runtime `assert` (`SpringAnimator.swift:149`).

### `CurveAnimator<T>` — `Animation/CurveAnimator.swift`

Generic deterministic curve animator. Single `Curve` spec (`duration`, `timingFunction`, `from`, `to`); the integrator advances `t` linearly in wall-clock time and applies the `CAMediaTimingFunction` curve. Used where determinism beats simulation — chrome cross-fades, mask reveals, the master-timer Z-arc.

### `CATransaction+Helpers` — `Animation/CATransaction+Helpers.swift`

```swift
extension CATransaction {
    static func withSuppressedActions<T>(_ body: () throws -> T) rethrows -> T {
        begin(); setDisableActions(true)
        defer { commit() }
        return try body()
    }
}
```

Discipline universally adopted. Grep for raw `CATransaction.begin()` in production returns zero hits — Keystone K4.

## Animator-on-controller, NOT animator-on-view

Wave's canonical surface is `extension UIView { var animator: ViewAnimator }`. DotPinch refuses this (rejection #19). The reason:

> "DotPinch's animatable units are domain scalars (`Camera.translation`, extension-height), NOT view properties. A per-view associated-object would hide controller ownership behind a hidden global lookup."

Instead, animators are constructed against the controller directly:

```swift
let extensionAnimator = SpringAnimator<CGFloat>(
    controller: animationController,
    spring: Spring(dampingRatio: tuning.springDamping,
                   response: tuning.springResponse)
)
extensionAnimator.valueChanged = { [weak self] _ in self?.applyExtensionTick() }
```

The seam between the integrator and the UIKit/CALayer world is `valueChanged` — the integrator produces a `T.ValueType`, the closure applies it to whatever destination makes sense (a layer's `transform`, a constraint's `constant`, multiple destinations at once).

## Spring profile coordination

The Camera animator and the extension-height animator MUST share `spring.response` whenever they're running together — the camera's page-y motion and the cell's height change are derived from one physical spring, sampled twice. Mismatched response would visibly drift them apart mid-animation.

Wave 7 hardened this to a runtime `assert` at all three spring-swap sites:

```swift
assert(extensionAnimator.spring.response == cameraAnimator.responseForTesting,
       "Animator coordination invariant: camera + extension MUST share spring.response")
```

Sites: `TimelineCanvas.swift` `engageTapToChat` (~line 1380), `springToChatRest` (~line 1432), `springToCellRest` (~line 1491).

## Choreographers (L4)

L4 is composition of L1 animators into a single semantic timeline.

- **`MorphChoreographer`** — `Conversation/Timeline/MorphChoreographer.swift`. Drives the tap-to-chat morph: master timer (`CurveAnimator<CGFloat>`) ticks 1.2s; on each tick, applies a Y-translation + Z-arc + extension-height write + neighbor transforms + chrome cross-fade. Fires `onMorphRevealReady` when settled. Single-source-of-truth for the morph keystone K7.
- **`RevealCoordinator`** — `Conversation/Timeline/RevealCoordinator.swift`. Drives the chat-presentation lifecycle: blur fade in (`UIViewPropertyAnimator`), `ChatViewController` add, blur fade out, swap-back on dismiss.

Both choreographers hold the substrate via constructor injection. Neither owns the controller; both push to it.

## Per-tick CATransaction discipline

Every per-frame view write inside an animator's `valueChanged` is wrapped in `CATransaction.withSuppressedActions { ... }` either at the controller boundary (every frame) or at the use site (cell `setCamera`, transform writes). Without this, UIKit interpolates between consecutive writes with its own 0.25s tween — fighting the substrate's tick rate at 5×.

## See also

- `docs/keystones.md` — the 8 substrate-defining decisions.
- `docs/architecture.md` — layer structure.
- `Tests/V2/WaveR41SubstrateCanaryTests.swift` — the K8 canary test.
- `REFACTOR-CHECKLIST.md` §Bottling Destination — the SPM extraction plan (deferred).
