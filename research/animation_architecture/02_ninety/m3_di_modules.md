# METACOGNITIVE — DI + module architecture for animation systems
POSTURE: janum

How senior shops carve animation code across module boundaries and inject
time/frame/coordinator deps to make animation testable.

**Current state**: one target. `Animation/` is a folder. `AnimationController()`
is constructed inside `TimelineCanvas` (line 85) — not a singleton, but consumers
can't substitute it. `SpringAnimator(controller:spring:)` and
`CameraAnimator(canvas:controller:spring:)` already constructor-inject.
`PinchTuning` is service-locator-by-globals. `CACurrentMediaTime()` at
`SpringAnimator` lines 99/123 is the only direct clock dep in the substrate.

## SPM module layout — monolithic vs sliced

### Canonical shape (Airbnb Epoxy)
Multi-package monorepo, sibling SPM products: `EpoxyCore`, `EpoxyLayoutGroups`,
`EpoxyCollectionView`, `EpoxyBars`, `EpoxyNavigationController`,
`EpoxyPresentations`. ONE `Package.swift`, many `.library` products. Strictly
downward deps; substrate (`EpoxyCore`) has no UIKit-list code.

Buys Airbnb: build-time enforcement that features can't reach Core privates
(`internal` invisible across modules); per-product test target; faster builds;
explicit `public` is a design decision, not a lint suggestion.

### Strengths / weaknesses
- **+** Forces design of `public` surface; `internal` enforces boundary.
- **+** Per-module mocks live next to protocols.
- **−** `@testable import` per module multiplies test setup.
- **−** Cross-module `internal` extensions don't work — convenience inits on a
  Core type from a UI module require those inits be `public`.
- **−** `@MainActor` / `Sendable` declared at boundary, not deferred.

Shipping: airbnb/epoxy-ios (six SPM products, one repo); pointfreeco/TCA
(`Dependencies`, `Clocks`, `CombineSchedulers`, `CasePaths` as separate
packages); airbnb/lottie-ios (single product, `Sources/Public` vs
`Sources/Private` with a lint asserting no Public file imports Private —
discipline without split).

Migration cost: low for ONE SPM package, no product split (~half day). Higher
for AnimationKit + AnimationUI split — UIView extensions cross the boundary,
`PinchTuning` either splits or stays in the app.

## Protocol boundaries for testability

### Canonical shape (Pointfree-style)
```swift
public protocol Clock: Sendable { func now() -> TimeInterval }
public protocol DisplayLinkProviding: AnyObject {
    var isPaused: Bool { get set }
    var preferredFrameRateRange: CAFrameRateRange { get set }
    func add(to runloop: RunLoop, forMode mode: RunLoop.Mode)
    func invalidate()
    var onTick: ((TimeInterval, TimeInterval) -> Void)? { get set }
}
public final class AnimationController {
    public init(clock: Clock = SystemClock(),
                displayLinkFactory: @escaping () -> DisplayLinkProviding
                    = { CADisplayLinkAdapter() }) { ... }
}
```
Factory closure because `CADisplayLink` needs target/selector at construction —
protocol exposes only post-construction surface.

**+** Tests step `TestClock` + `ManualDisplayLink`; deterministic, no vsync waits.
**−** Abstraction leaks: `.common` vs `.tracking` runloop-mode subtleties.

Shipping: pointfreeco/combine-schedulers — `AnySchedulerOf` + `TestScheduler`.
jtrivedi/Wave (our `SpringAnimator` lineage) does NOT do this — reads
`CACurrentMediaTime()` directly. Same testability gap we inherit.

Migration: ~30 LoC to thread `Clock` through controller → animator. Harder
cost: every existing real-time test gets rewritten to step the clock.

## DI mechanisms — five options

- **Constructor injection** (current). Most explicit, most boilerplate. Dep
  graph visible at call site. Deep graphs cause "constructor tunneling."
- **`@Environment`-style / responder-chain** (`UIViewController.transitionCoordinator`
  internally). Zero ceremony at call sites; per-subtree override. Dep invisible at
  call site; teardown races (`next == nil` mid-removal falls back to a DIFFERENT
  default, manifests as "completion fires twice").
- **Property-wrapper DI** — Factory (hmlongco/Factory, ~2k stars, KeyPath-based,
  current pick), Swinject/Resolver (older, string-keyed). Removes constructor
  boilerplate; invisible until first access → crash-at-first-use if container
  not bootstrapped.
- **Service locator** (`AppGraph.shared`) — singleton with a fig leaf. Almost
  never the right answer.
- **Composition root** — Apple's convention: `application(_:didFinishLaunching...)`
  or `scene(_:willConnectTo:...)`. Wire once at top, hand down via constructor
  injection. TCA does the same with `Store`.

### Shipping evidence
- Factory ~2k, TCA `@Dependency` macro ~13k, Swinject ~6k (enterprise).
- **Airbnb: composition root in app delegate, hand-rolled constructor injection
  elsewhere. No DI framework.** (Per engineering blog + open-source.)

## The Animation Environment (UIKit `@Environment` analogue)

```swift
public struct AnimationEnvironment {
    public let clock: Clock
    public let controller: AnimationController
    public let defaultSpring: Spring
    public let reducedMotion: Bool  // UIAccessibility.isReduceMotionEnabled
}
public protocol AnimationEnvironmentProviding {
    var animationEnvironment: AnimationEnvironment { get }
}
extension UIResponder {
    public var animationEnvironment: AnimationEnvironment {
        (self as? AnimationEnvironmentProviding)?.animationEnvironment
            ?? next?.animationEnvironment ?? .systemDefault
    }
}
```

- **+** Zero param-tunneling; per-subtree override.
- **−** Responder chain mutable + racy during teardown — `next == nil` mid-removal
  falls back to `.systemDefault` (different controller).

## Per-feature coordinators + app graph

```swift
@MainActor public final class RevealCoordinator {
    private let env: AnimationEnvironment
    private let canvas: TimelineCanvas
    public func reveal(cellIndex: Int, completion: @escaping () -> Void) { ... }
}
public final class AppGraph {
    public func revealCoordinator(for canvas: TimelineCanvas) -> RevealCoordinator
}
```
Factory method (not `shared`) — coordinator lifetime bound to canvas, not app.
**+** Small coordinators, single responsibilities, constructable in tests.
**−** Discoverability at 30+ coordinators.

Shipping evidence: XCoordinator (~3k), RxFlow, Khanlou's coordinator article.
Airbnb uses coordinators for screen-level FLOW, not animation; animation lives
in Epoxy item models.

## Test injection shape (fast deterministic tests)

```swift
let clock = TestClock()
let controller = AnimationController(clock: clock,
                                     displayLinkFactory: { ManualDisplayLink() })
let animator = CameraAnimator(canvas: canvas, controller: controller, spring: .test)
animator.animate(to: Camera(translation: 100))
clock.advance(by: 0.016); controller.tick()   // explicit drive
XCTAssertEqual(canvas.camera.translation, ..., accuracy: 0.01)
```
Manual tick beats `XCTestExpectation + 50ms wait`. Today's Wave-style animator
can't be driven this way without injecting `Clock` + exposing `tick()`.

## Cross-module animation contracts

```swift
public protocol CustomPushTransitionProviding {
    func transitionAnimator(for op: UINavigationController.Operation)
        -> UIViewControllerAnimatedTransitioning?
}
```
FeatureA conforms its top VC; FeatureB's nav delegate asks the top VC. Neither
module knows the other; both depend on a shared `TransitionsKit`. Weakness:
opaque types get noisy when transitions want generic param info; workaround is
erasing to `Any` at the boundary.

## Apple's no-DI pattern — what it teaches

`UIView.animate` static. `UIViewPropertyAnimator` direct `init()`. `CADisplayLink`
requires a real runloop. No injected clock, no swappable engine.

Read carefully: Apple does NOT believe in DI for animation PRIMITIVES because
the primitives are identical across calls — the dependency is "the system frame
loop" and there is only one. DI surfaces ONLY when you build a coordinator on
top that holds POLICY (which spring, which canvas, which completion-firing rule).
DI is for policy, not integration. Our `AnimationController` is a policy object
→ DI. Our `SpringAnimator` math is not → no DI of spring math. Spring TUNING,
clock, frame source → DI.

## MainActor + Sendable contracts

`@MainActor` on `CameraAnimator` (line 19) is correct. In module extraction:
`Spring`, `Camera`, `CameraVelocity` — all should be `Sendable` (value-type of
primitives; implicit holds). `AnimationController` should be `@MainActor`
(mutates `animations`, ticked from DisplayLink on main runloop). Risk: making
it `public final class` without `@MainActor` lets a cross-module consumer
instantiate from a background queue — technically unsafe even if today it works.

## `internal` vs `public` boundary inside a hypothetical AnimationKit

- `public`: `Spring`, `AnimationController`, `SpringAnimator`, `AnimatorProviding`,
  `AnimationEnvironment`, `Clock`.
- `internal`: spring solver math (`updateValue`), `DisplayLinkProxy`,
  `SpringInterpolatable` conformance details.
- App-target: `CameraAnimator`, `RevealCoordinator`, `PinchTuning`.

Epoxy's rule, restated: named after a domain concept (`Reveal`, `Pinch`, `Chat`)
→ feature. Named after a mechanism (`Spring`, `Animator`, generic `Coordinator`)
→ substrate.

## Synthesis: recommended layout for DotPinchPrototype

**Stay in one target. Add discipline; do not extract SPM.**

```
DotPinchPrototype/
  Animation/                       # substrate (would-be AnimationKit)
    Spring.swift
    SpringInterpolatable.swift
    SpringAnimator.swift
    AnimationController.swift
    AnimationEnvironment.swift     # NEW — clock + controller + defaultSpring
    Clock.swift                    # NEW — protocol + SystemClock + TestClock
    CATransaction+Helpers.swift
    MathUtilities.swift
  Conversation/V2/
    CameraAnimator.swift           # feature coordinator — stays here
    ...
```

**DI mechanism**: constructor injection at all seams. No property wrappers, no
service locator. `AnimationEnvironment` constructed once in
`V2RootViewController.init()` (the composition root) and handed to
`TimelineCanvas` via init, which hands clock+controller to `CameraAnimator`
and `extensionAnimator`.

**Concrete delta**: `TimelineCanvas` stops constructing its own
`AnimationController` (line 85) — becomes `let controller: AnimationController`
set from init param. `SpringAnimator.startTime` reads `env.clock.now()` not
`CACurrentMediaTime()`.

**Migrate to SPM only IF**: second consumer (widget / second app) needs the
spring substrate, OR incremental builds exceed ~30s, OR a second contributor
works on substrate while another works on features. Until then, folder boundary
+ public/internal discipline is sufficient.

## What we should NOT introduce at our scale

- **DI framework (Factory/Swinject/Resolver).** Validates at 50-screen apps,
  not one-target prototypes. Our entire graph is ~5 init params.
- **Responder-chain `AnimationEnvironment` lookup.** Bug surface (mid-teardown
  `next == nil`) real; saved boilerplate trivial. Hold env in stored prop;
  pass explicitly.
- **SPM extraction.** Premature. Revisit when a second consumer appears.
- **Coordinator-per-feature pattern with `AppGraph`.** We have ONE coordinator
  (`CameraAnimator`) + soon-to-be `RevealCoordinator` (currently `revealChat`
  inline in V2RootViewController). Two coordinators is not a graph.
- **`@Injected` property wrappers / `@Environment(\.animationController)`.** Magic
  resolution hides bugs explicit injection catches at compile time.
- **Type-erasing spring math (`AnyAnimator`, `AnyCoordinator`).** Generic
  `SpringAnimator<T>` is fine; two instantiations (`<CGFloat>` ×2). Erasure
  costs allocation + clarity for zero benefit.

**Bottom line**: the right module boundary IS the existing folder boundary, plus
two small additions (`AnimationEnvironment`, `Clock`) that make
`AnimationController` testable WITHOUT changing production wiring. Defer SPM
extraction until a second consumer or build-time pain forces it.
