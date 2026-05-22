# METACOGNITIVE — Type-level Swift architecture for animation systems
POSTURE: janum

Scope: how senior-staff iOS shops STRUCTURE animation code at the type level — protocols, generics, builders, phantom vs enum state, value vs reference. Substrate questions, not per-animation tactics. Where DotPinch's `SpringAnimator<T: SpringInterpolatable>` sits and what the next 10% of type design buys a real `RevealCoordinator`.

---

## 1. Protocol-oriented animator surface
```swift
protocol Animator: AnyObject, Identifiable {
    var id: UUID { get }
    var state: AnimatorState { get }
    var fractionComplete: CGFloat { get }
    func start(); func pause(); func stop(immediately: Bool)
}
```
**Strengths** Single dispatch surface; coordinators hold `[any Animator]` without caring about spring vs keyframe. `AnyObject` matches reality of mid-flight retargeting (mutation through reference). Witness-table dispatch cost negligible vs per-frame integration.
**Weaknesses** Existentials can't expose `associatedtype` (`T: SpringInterpolatable`) — must downcast or re-erase.
**Shipping evidence** DotPinch `AnimatorProviding` is exactly this. Wave `AnimationProviding`. Apple's `UIViewImplicitlyAnimating` (behind `UIViewPropertyAnimator`) is class-bound with `fractionComplete`, `startAnimation()`, `pauseAnimation()`, `stopAnimation(_:)`.
**Composes with** §6 enum state, §8 generic value, §9 tokens.
**Migration cost** Low — `UIView.animate` blocks become `view.fadeAnimator.start()`.

---

## 2. Generic animation as a VALUE type
```swift
struct Animation<Value: Animatable>: Hashable {
    var from: Value; var to: Value
    var timing: Timing       // .spring(Spring) | .curve(CubicTiming) | .linear
    var delay: TimeInterval = 0
    var repeats: RepeatPolicy = .none
}
protocol Animatable: Hashable {
    static func interpolate(_ a: Self, _ b: Self, _ t: CGFloat) -> Self
}
```
**Strengths** SwiftUI's `Animation` is struct on purpose. Free `Equatable` for diffing (`if old != new { reapply }`), free `Hashable` for cache keys, trivial `let` snapshots in async contexts. Description separable from runtime — same recipe re-played, inverted, archived.
**Weaknesses** Value can't itself "run" — it's a recipe. Still need reference-typed `Animator` for velocity, startTime. Two-tier design is the cost. Generic `Value` blocks heterogeneous storage without `AnyAnimation` erasure.
**Shipping evidence** SwiftUI `Animation`, `AnyTransition`, `KeyframeTrack<Root, Value>` all value types. Epoxy `AnimatableValue` value-typed descriptions with animators stored separately on the cell.
**Composes with** §3 builders, §5 phantom runners.
**Migration cost** Medium — split "what" (struct) from "running" (class). Worth it once >1 caller reuses (initial drop AND retry).

---

## 3. Result builders for animation DSLs
```swift
@resultBuilder enum AnimationBuilder {
    static func buildBlock(_ p: AnimationStep...) -> [AnimationStep] { p }
    static func buildOptional(_ p: [AnimationStep]?) -> [AnimationStep] { p ?? [] }
    static func buildEither(first p: [AnimationStep]) -> [AnimationStep] { p }
    static func buildEither(second p: [AnimationStep]) -> [AnimationStep] { p }
}
struct Sequence {
    let steps: [AnimationStep]
    init(@AnimationBuilder _ body: () -> [AnimationStep]) { self.steps = body() }
}
// let reveal = Sequence {
//     Fade.from(0).to(1).duration(0.3)
//     Slide.from(.below).to(.center).spring(.bouncy).delay(0.15)
//     if shouldBounce { Scale.from(1).to(1.05).then(1).spring(.snappy) }
// }
```
**Strengths** Declarative top-down read; mirrors how designers describe motion. `buildOptional`/`buildEither` puts policy (reduce-motion branch) IN the DSL instead of `if` ladders around `UIView.animate`. SE-0289 settled the design.
**Weaknesses** Compile errors notoriously poor — wrong types surface as cryptic "cannot convert". DSL is yours to maintain forever.
**Shipping evidence** SwiftUI ViewBuilder, `@KeyframesBuilder` (SE-0411). Arc internal `MotionBuilder` (public talks). pointfree-co swift-composable-animations.
**Composes with** §2 value Animation, §9 tokens (`Sequence{}.start()` returns one composite token).
**Migration cost** High up-front, low per-callsite once it exists. Not worth it for <5 distinct flows.

---

## 4. Property wrappers for animated state
```swift
@propertyWrapper
final class Animated<V: SpringInterpolatable> where V.ValueType == V {
    private var animator: SpringAnimator<V>
    private var current: V
    var wrappedValue: V {
        get { current }
        set { animator.value = current; animator.target = newValue; animator.start() }
    }
    var projectedValue: SpringAnimator<V> { animator }
    init(wrappedValue: V, spring: Spring, controller: AnimationController) {
        self.current = wrappedValue
        self.animator = SpringAnimator(controller: controller, spring: spring,
                                       value: wrappedValue, target: wrappedValue)
        self.animator.valueChanged = { [weak self] v in self?.current = v }
    }
}
// final class RevealCoordinator {
//     @Animated(spring: .snappy, controller: ctrl) var progress: CGFloat = 0
//     func reveal() { progress = 1 }   // implicit spring
// }
```
**Strengths** Eliminates `.value = …; .target = …; .start()` trinity at every callsite. Policy (spring choice) lives at declaration. `$progress` exposes raw animator for mid-flight velocity injection.
**Weaknesses** Wrappers can't take `self`-relative deps (SE-0258) — `controller` must be init-injected. Hides controller registration — exactly where you want a breakpoint debugging the display link.
**Shipping evidence** SwiftUI `@State` + `withAnimation` is spiritual cousin. Few public UIKit examples; leading-edge in-house.
**Composes with** §5 phantoms on `projectedValue`.
**Migration cost** Medium — properties migrate one at a time; coexists with raw `SpringAnimator` callsites.

---

## 5. Phantom types / type-state machines
```swift
enum Idle {}; enum Running {}; enum Paused {}; enum Settled {}
struct Animator<State> { let id: UUID; fileprivate let box: AnimatorBox }
extension Animator where State == Idle {
    func start() -> Animator<Running> { box.start(); return .init(id: id, box: box) }
}
extension Animator where State == Running {
    func pause() -> Animator<Paused>  { box.pause(); return .init(id: id, box: box) }
    func stop()  -> Animator<Settled> { box.stop();  return .init(id: id, box: box) }
}
// Animator<Settled>: no methods. Terminal at the type level.
```
**Strengths** `start()` returns a *different type*. Cannot call `pause()` on `Animator<Idle>` — compile-time enforcement. Type signature IS the state diagram.
**Weaknesses** Heterogeneous storage hostile — `[Animator<???>]` requires erasure that collapses the guarantee. Most animation systems have ASYNC transitions (display-link flips Running→Settled) the type system can't observe — the phantom is lying.
**Shipping evidence** TCA `Effect<Action, Failure>`. Animation code: rare — async-flip kills it.
**Composes with** §4 — `$progress` returns `Animator<Running>` only while live (but async problem persists).
**Migration cost** High and probably wrong for animation. Reserve for protocol-level invariants (`URLSession` task state).

---

## 6. Enum-based state machines (the realist's answer)
```swift
enum AnimatorState: Equatable {
    case idle
    case running(progress: CGFloat, velocity: CGFloat)
    case paused(progress: CGFloat, velocity: CGFloat)
    case settled(at: CGFloat)
}
extension AnimatorState {
    mutating func transition(to event: Event) {
        switch (self, event) {
        case (.idle, .start):                  self = .running(progress: 0, velocity: 0)
        case (.running(let p, let v), .pause): self = .paused(progress: p, velocity: v)
        case (.paused(let p, let v), .resume): self = .running(progress: p, velocity: v)
        case (.running, .settle(let f)):       self = .settled(at: f)
        default: break  // illegal — log, don't crash
        }
    }
}
```
**Strengths** Associated values carry STATE into state. `.running` without progress is unrepresentable. Exhaustive switch surfaces missed cases at compile time. Plays with snapshot tests, time-travel debugging.
**Weaknesses** No type-level prevention of "pause on settled" — runtime check only. Mutating doesn't compose with reference semantics; awkward when animator is a class.
**Shipping evidence** DotPinch `AnimatorState` is this shape WITHOUT associated values (`.inactive | .running | .ended`). Next 10% = add payload. Apple `URLSessionTask.State`, TCA reducer state.
**Composes with** §1 (protocol exposes `state`), §7 (callbacks fire on transitions).
**Migration cost** Low — drop-in replacement for `isAnimating` booleans.

---

## 7. Closures vs delegate protocols
```swift
// Closure (DotPinch today):
final class SpringAnimator<T> {
    var valueChanged: ((T) -> Void)?; var completion: ((Event) -> Void)?
}
// Delegate (Apple style):
protocol AnimatorDelegate: AnyObject {
    func animator(_: any Animator, didReachProgress: CGFloat)
    func animatorDidFinish(_: any Animator)
}
```
**Strengths** Closures: inline callsite, local context capture, multi-subscriber via array. Delegates: single owner/dispatch, weak by default (no retain cycles), better Xcode call hierarchy.
**Weaknesses** Closures: `[weak self]` discipline at every callsite — one miss = leak; hard to introspect. Delegates: one subscriber without multi-delegate plumbing; conformance ceremony for trivial cases.
**Shipping evidence** Closures: SwiftUI, Combine, Wave, DotPinch. Delegates: `UIScrollViewDelegate`, `CAAnimationDelegate`. `UIViewPropertyAnimator.addCompletion(_:)` is closure but animator owns it.
**Composes with** Both work with §6 enum state. Closures for transient ops (gestures); delegates for long-lived animators (coordinator).
**Migration cost** None — both already in use; choose per new API.

---

## 8. Generic spring physics — `Animatable` / `VectorArithmetic`
```swift
// SwiftUI public (SE-0258):
public protocol VectorArithmetic: AdditiveArithmetic {
    mutating func scale(by rhs: Double); var magnitudeSquared: Double { get }
}
public protocol Animatable {
    associatedtype AnimatableData: VectorArithmetic
    var animatableData: AnimatableData { get set }
}
// DotPinch (no AdditiveArithmetic):
public protocol SpringInterpolatable: Equatable {
    associatedtype ValueType: SpringInterpolatable where ValueType.ValueType == ValueType
    associatedtype VelocityType: VelocityProviding
    static func updateValue(spring: Spring, value: ValueType, target: ValueType,
                            velocity: VelocityType, dt: TimeInterval)
                            -> (value: ValueType, velocity: VelocityType)
}
// Apple ships: CGFloat, Double, CGPoint, CGSize, CGRect (AnimatablePair), UIColor (RGBA),
// UIEdgeInsets, CATransform3D (decomposed Animatable3DRotation).
```
**Strengths** One spring integrator, N value types — no per-type animator class. `AnimatablePair` composes `(CGFloat, CGFloat)` into `CGPoint`-like structurally. `T.ValueType == T` (DotPinch has it) closes the recursive-associated-type loop.
**Weaknesses** Per-type conformances non-trivial (UIColor "interpolate in sRGB or OKLab?" is real). Constraint dance hard for newcomers.
**Shipping evidence** SwiftUI `Animatable`/`VectorArithmetic`. Wave `AnimatableProperty`. Motion `SIMDRepresentable`. DotPinch `SpringInterpolatable`.
**Composes with** §2 generic Animation, §4 wrappers parameterized on `<V: SpringInterpolatable>`.
**Migration cost** EXTEND, don't replace — add `CGPoint`, `CGRect`, `CGAffineTransform` conformances incrementally.

---

## 9. Cancellation tokens
```swift
struct AnimationToken: Hashable {
    fileprivate let id: UUID
    fileprivate weak var controller: AnimationController?
    func cancel() { controller?.cancel(id: id) }
}
extension AnimationController {
    @discardableResult
    func animate<V: SpringInterpolatable>(_ a: Animation<V>,
                                          onChange: @escaping (V) -> Void) -> AnimationToken {
        let r = SpringAnimator(controller: self, spring: a.timing.spring, value: a.from, target: a.to)
        r.valueChanged = onChange; r.start()
        return AnimationToken(id: r.id, controller: self)
    }
}
```
**Strengths** Caller holds cheap value handle, not animator. Multiple tokens can address one animator (multi-cancel safety). Plays with structured concurrency: `task.onCancel { token.cancel() }`.
**Weaknesses** Token-after-completion is soft no-op — tests must assert. Querying progress requires a second API.
**Shipping evidence** Combine `AnyCancellable`, `Task<…>` handle, `URLSessionDataTask`.
**Composes with** §3 — `Sequence{}.start()` returns one composite token.
**Migration cost** Low — "stash animator" becomes "stash token".

---

## 10. `any` vs `some` for animator returns
```swift
func makeRevealAnimator() -> some Animator { SpringAnimator<CGFloat>(...) }   // opaque, specialized
func makeRevealAnimator() -> any  Animator { SpringAnimator<CGFloat>(...) }   // existential, dynamic
```
`some`: zero overhead, monomorphized, but one concrete type per signature. `any`: heterogeneous storage (`[any Animator]`), return-type can vary, boxing cost negligible here. SwiftUI built on `some View`; UIKit uses `[any UIVCTransitioningDelegate]`-style for plugin slots.
**Use** `some` for factory callsites; `any` for coordinator storage.

---

## 11. Why `UIViewPropertyAnimator` is class, `UISpringTimingParameters` struct
`UIViewPropertyAnimator` = **class**: owns mutable lifecycle observable externally; survives handoff to UIKit's runtime (reference identity needed); `addAnimations { }` captures closures — closures + mutable state + shared ownership = class.
`UISpringTimingParameters`, `UICubicTimingParameters` = **structs**: pure parameters, no lifecycle; `Equatable`/`Hashable` free; same params fed to two animators are `==`; copied at init, no shared mutation.
Canonical Apple split: **timing = value, animator = reference**. DotPinch follows it (`Spring` struct, `SpringAnimator` class). Don't drift.

---

## 12. Equatable + Hashable animations
```swift
struct Animation<V: Animatable & Hashable>: Hashable {
    var from: V; var to: V; var spring: Spring; var delay: TimeInterval
}
var cache: [Animation<CGFloat>: SpringAnimator<CGFloat>] = [:]
```
**Strengths** Dedup via dictionary lookup. Epoxy uses hashable descriptors to diff between renders ("did the fade-in change?"). Snapshot testing: hash description, assert stability.
**Weaknesses** Closures on the description (`onComplete`) break Hashable instantly — keep them OFF the value, ON the animator.
**Shipping evidence** Epoxy `AnimatableValueProvider`. SwiftUI `Animation: Equatable` (iOS 17+). TCA effect hashing.
**Migration cost** Low if already a struct; impossible if it carries closures.

---

## Synthesis: ideal type architecture for `RevealCoordinator`

```swift
// Value recipe (Hashable, snapshot-testable):
struct RevealAnimation: Hashable {
    var dotProgress:  Animation<CGFloat>   // 0 → 1
    var dotScale:     Animation<CGFloat>   // 0.6 → 1.0 with overshoot
    var bubbleAlpha:  Animation<CGFloat>   // 0 → 1, delayed
    var cameraOffset: Animation<CGFloat>   // y-offset settle
}

// Reference coordinator owning runtime animators:
final class RevealCoordinator {
    enum State: Equatable { case idle, revealing(progress: CGFloat), revealed }
    private let controller: AnimationController
    private var activeToken: AnimationToken?
    private(set) var state: State = .idle

    init(controller: AnimationController) { self.controller = controller }

    @discardableResult
    func reveal(_ recipe: RevealAnimation,
                applying: @escaping (RevealKeyPath, CGFloat) -> Void) -> AnimationToken {
        cancel()
        state = .revealing(progress: 0)
        // One animator per property, all sharing the single AnimationController/display link:
        let dot    = controller.start(recipe.dotProgress)  { applying(.dotProgress, $0) }
        let scale  = controller.start(recipe.dotScale)     { applying(.dotScale, $0) }
        let alpha  = controller.start(recipe.bubbleAlpha)  { applying(.bubbleAlpha, $0) }
        let camera = controller.start(recipe.cameraOffset) { applying(.cameraOffset, $0) }
        let token = AnimationToken.composite([dot, scale, alpha, camera], controller: controller)
        activeToken = token
        return token
    }
    func cancel() { activeToken?.cancel(); activeToken = nil; state = .idle }
}
enum RevealKeyPath { case dotProgress, dotScale, bubbleAlpha, cameraOffset }
```

Shape: **value recipe (hashable, testable) + reference coordinator (lifecycle, identity) + opaque token (cancellation)**. Existing `SpringAnimator<T>` is reused as per-property runtime. Coordinator never grows N specialized animator subclasses; the `applying:` closure is the seam to UIKit views.

---

## What NOT to do at our scale
1. **Phantom-typed state** — async transitions make the type lie; enum + associated values is strictly better.
2. **Custom result builders** — <5 distinct multi-property flows; builder maintenance > savings.
3. **Type-erased `AnyAnimator`** until `[any Animator]` storage is actually needed. `AnimatorProviding` already erases enough for the UUID dictionary.
4. **Property wrappers on every animated property** — hides controller registration, defeats debugging. Reserve for properties touched at >5 callsites.
5. **Hashable animations everywhere** — only matters when you build a cache; `Equatable` is enough for tests.

---

## Frontiers
- Macro-generated `@Animatable` for view-model structs (Swift 5.9+ macros) auto-synthesizing per-property animator wiring.
- `AsyncSequence<AnimatorState>` on every animator — replaces closures with `for await state in animator.events` and structured-concurrency cancellation.
- Type-level recipe composition: `RevealAnimation + DismissAnimation` via `Concatenable` returning a new `Hashable` value.
- `SnapshotAnimator` test seam: `let frames = animator.simulate(dt: 1/120, until: .settled) -> [Frame]` — deterministic visual tests with no display link.
