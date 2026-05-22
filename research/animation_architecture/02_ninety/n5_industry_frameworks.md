# NINETY — Industry frameworks + canonical transition patterns
# Intention 4 — internal behaviors | Intention 5 — philosophical inheritance
POSTURE: janum

Orientation: substrate-level patterns senior iOS engineers COMPOSE into custom
animation architectures. Unit of analysis is the PATTERN, not the app. Any
non-toy system is a composition of the ten below. DotPinchPrototype test case:
`revealChat(forCellAt:)` in `V2RootViewController.swift:110–124` chains three
`UIView.animate(delay:)` calls (blur-in 0.0–0.3, crossfade 0.2–0.5, blur-out
0.5–1.2). `TimelineCanvas.swift:1225+` is the same anti-pattern.

---

## Pattern 1: `UIViewPropertyAnimator` + `UIViewControllerAnimatedTransitioning` + `UIPercentDrivenInteractiveTransition`

```swift
final class RevealAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var propertyAnimator: UIViewPropertyAnimator?
    func transitionDuration(_: UIViewControllerContextTransitioning?) -> TimeInterval { 0.6 }
    func interruptibleAnimator(using ctx: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        if let a = propertyAnimator { return a }
        let a = UIViewPropertyAnimator(duration: 0.6, dampingRatio: 0.85) { /* end */ }
        a.addCompletion { pos in ctx.completeTransition(pos == .end) }
        propertyAnimator = a; return a
    }
    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        interruptibleAnimator(using: ctx).startAnimation()
    }
}
let driver = UIPercentDrivenInteractiveTransition()
driver.update(fraction);  driver.finish() // or .cancel()
```
**Choose when**: cross-VC transitions that must be **interruptible mid-flight** by gesture or new target. Animator is single source of truth — `fractionComplete` is mutable.
**Composes with**: 2 (`continueAnimation(withTimingParameters:durationFactor:)`), 3 (snapshot lifecycle), 7 (states named in machine).
**Cost**: medium-high. Three protocols, transitioning-delegate wiring. ~150–300 LOC.
**Industry**: Photos app photo→detail. WWDC 2013 #218, WWDC 2018 #803.
**Lesson**: **The animator IS the truth.** All gestures, releases, completions refer to the same object. Core of "interruptible animation".

---

## Pattern 2: Spring physics fundamentals

```swift
let spring = UISpringTimingParameters(dampingRatio: 0.85, initialVelocity: CGVector(dx: vx, dy: vy))
let a = UIViewPropertyAnimator(duration: 0.6, timingParameters: spring)
// Retarget mid-flight:
let v = a.velocity                                // iOS 17+
a.stopAnimation(true)
let next = UIViewPropertyAnimator(duration: 0.6,
    timingParameters: UISpringTimingParameters(dampingRatio: 0.85, initialVelocity: v))
next.addAnimations { /* new target */ }; next.startAnimation()
```
**Choose when**: gesture release, anything "physical", anything whose target can change mid-flight. Default choice unless explicitly drawing a curve.
**Composes with**: 1, 3, 5, 6, 7, 8, 10. Spring is the **timing primitive** every higher pattern consumes.
**Cost**: low. Math is well-documented; API is one line.
**Industry**: SwiftUI `.spring()`, iOS 17 named springs, SpringBoard, Telegram-iOS `transitionToValue:`, Wave.
**Lesson**: **Duration is derived, not chosen.** `response` + `dampingRatio` define a physical system; apparent duration is settling time. Stop choosing 0.3/0.5/0.7 in seconds.

---

## Pattern 3: `matchedGeometryEffect` / hero / snapshot-and-animate

```swift
// SwiftUI: @Namespace var ns
// Source.matchedGeometryEffect(id:"card", in:ns); Dest.matchedGeometryEffect(id:"card", in:ns)
let snap = source.snapshotView(afterScreenUpdates: false)!
snap.frame = source.convert(source.bounds, to: container)
container.addSubview(snap); source.isHidden = true; dest.isHidden = true
UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.9) {
    snap.frame = dest.convert(dest.bounds, to: container)
}.startAnimation()
```
**Choose when**: element-to-element morph (cell→detail, thumbnail→full). "One view that travels", not "two views that crossfade".
**Composes with**: 1 (VC transition holds snapshot), 2 (frame interp spring-timed), 5 (progress drives frame + z + opacity).
**Cost**: medium. Snapshot identity management. Edges: rotation, dynamic content, unrendered views.
**Industry**: SwiftUI `matchedGeometryEffect` (WWDC 2020 #10031). UIKit: `Hero` by Luke Zhao, Airbnb photo viewer, Apple Music album-art.
**Lesson**: **Identity over animation.** "This is the same thing in a new place", not "fade A while fading B".

---

## Pattern 4: Lottie (After Effects → JSON → runtime renderer)

```swift
let v = LottieAnimationView(name: "reveal"); v.play()
v.currentProgress = pinchProgress           // gesture scrub
```
**Choose when**: designer-authored illustrative motion — loaders, success ticks, mascots, onboarding. Anything you'd hand-tween bezier paths for.
**Composes with**: 5 (DisplayLink-driven `currentProgress`), 6 (Combine `assign(to: \.currentProgress)`).
**Cost**: build low (designer ships JSON). Runtime heavier — Lottie ships its own renderer. ~1–5 MB bundle.
**Industry**: Airbnb authored (engineering blog Feb 2017). Uber, Tinder, Duolingo. Apple's response: SF Symbol Effects, iOS 17.
**Lesson**: **Decouple authorship from execution.** Animation is data, not code. Same lesson behind keyframe DSLs and `PhaseAnimator`.

---

## Pattern 5: CADisplayLink progress driver / single-primitive composition (Wave's "interpolated" school)

```swift
final class ProgressDriver {
    private(set) var progress: CGFloat = 0   // 0...1 source of truth
    private var link: CADisplayLink?
    var onTick: ((CGFloat) -> Void)?
    func start() { link = CADisplayLink(target: self, selector: #selector(tick))
                   link?.add(to: .main, forMode: .common) }
    @objc private func tick(_ l: CADisplayLink) {
        progress = min(1, progress + CGFloat(l.duration / totalDuration))
        onTick?(progress); if progress >= 1 { link?.invalidate() }
    }
}
driver.onTick = { p in
    blur.alpha     = easeInOut(p, in: 0.00...0.25)
    chat.alpha     = easeInOut(p, in: 0.17...0.42)
    timeline.alpha = 1 - easeInOut(p, in: 0.17...0.42)
    blur.alpha    -= easeInOut(p, in: 0.42...1.00)
}
```
**Choose when**: choreographed multi-property reveals with overlapping windows on one timeline. **Exact replacement for chained `UIView.animate(delay:)`.**
**Composes with**: 2 (progress advanced by spring solver instead of linear time), 6 (publish progress, many subscribers), 10 (timeline DSL is sugar over this).
**Cost**: low–medium. Driver ~30 LOC. One timeline, one cancellation, one debug surface.
**Industry**: Wave (Janum Trivedi, 2022). SwiftUI `TimelineView`. Things 3 transitions (Cultured Code posts).
**Lesson**: **One progress, many derivations.** Senior engineers refuse to let "time" be implicit in 12 separate animation blocks. There is one time; every property is a function of it.

---

## Pattern 6: Reactive composition (Combine, iOS 13+)

```swift
let progress = CurrentValueSubject<CGFloat, Never>(0)
progress.map { easeInOut($0, in: 0...0.5) }.assign(to: \.alpha, on: blur).store(in: &bag)
progress.map { 1 - easeInOut($0, in: 0.33...0.83) }.assign(to: \.alpha, on: timeline).store(in: &bag)
// Drive: progress.send(currentProgress)
```
**Choose when**: Combine already idiomatic. Declarative property bindings keyed to `AnyCancellable` lifetime. `combineLatest` to sync gesture sources.
**Composes with**: 5 (progress publisher driven by DisplayLink), 7 (state machine publishes state), 8 (coordinator owns the bag).
**Cost**: medium. Combine plumbing, retain cycles, async debugging. Worth it iff Combine is already there.
**Industry**: Robinhood, Mercury, reactive fintech. Apple's internal use limited — SwiftUI replaced their need.
**Lesson**: **Animation is data flow.** Properties subscribe to a source. Cancellation is unsubscription.

---

## Pattern 7: State machine for animation

```swift
enum RevealState { case idle, blurUp, contentSwap, blurDown, presented, dismissing }
final class RevealMachine {
    private(set) var state: RevealState = .idle
    func transition(to next: RevealState) {
        guard isValid(state, next) else { return }
        let prev = state; state = next
        cancelOngoing(for: prev); animator(for: next).startAnimation()
    }
}
```
**Choose when**: interactions with explicit named lifecycle. "Interrupt" is meaningful because you have a name for the state you interrupt INTO.
**Composes with**: all — sits ABOVE the animation primitive. Transitions trigger pattern-1 transitions, pattern-5 runs, pattern-10 timelines.
**Cost**: medium. Discipline of enumerating states is the cost; pays back at debugging. Libs: `swift-state-machine`, `Stateful`, Square `Workflow`.
**Industry**: Telegram-iOS `TransitionNode`, `UIGestureRecognizer.State`, every game engine.
**Lesson**: **Cancellation is a transition, not a stop.** "User tapped during reveal" is not `stopAnimation()` — it is `machine.transition(to: .dismissing)`, which knows what `.dismissing` looks like coming from `.blurUp`.

---

## Pattern 8: Coordinator pattern for animations

```swift
final class RevealCoordinator {
    private let driver: ProgressDriver
    private let machine: RevealMachine
    private let snapshot: SnapshotChoreographer
    func start(from cell: UIView, to chat: UIView) { /* ... */ }
    func cancel() { /* ... */ }
    func setProgress(_ p: CGFloat) { /* gesture passthrough */ }
}
```
**Choose when**: logical interaction touches >2 views and >1 framework primitive. Coordinator absorbs orchestration; VC stays thin.
**Composes with**: owns 5, 6, 7, 10 as ivars. Consumed by VC as black box.
**Cost**: medium. One class per significant interaction. Pays back at testability — coordinators test without a window.
**Industry**: Khanlou "Coordinator pattern" (2015) generalised; canonical at Airbnb, Lyft, Square.
**Lesson**: **The VC is not the right home for an animation graph.** Promote it; name it; give it `start/cancel/setProgress`.

---

## Pattern 9: Functional composition / animation-as-value

```swift
struct Anim { let run: (UIView, @escaping () -> Void) -> Void }
extension Anim {
    static func fade(to a: CGFloat, dur: TimeInterval) -> Anim { Anim { v, done in
        UIView.animate(withDuration: dur, animations: { v.alpha = a }, completion: { _ in done() }) }}
    func delayed(by d: TimeInterval) -> Anim { Anim { v, done in
        DispatchQueue.main.asyncAfter(deadline: .now() + d) { self.run(v, done) } }}
}
let chore = sequence([fadeIn(blur).duration(0.3),
                      parallel([fadeIn(chat), fadeOut(timeline)]).delayed(by: 0.2),
                      fadeOut(blur).duration(0.7).delayed(by: 0.5)])
```
**Choose when**: team values referential transparency and composability of animations as first-class values. Functional-Swift shops.
**Composes with**: 10 (DSL = functional composition with operator sugar), 8 (coordinator stores built `Anim` graph).
**Cost**: medium. Interpreter overhead. Cancellation requires explicit tokens — easy to forget.
**Industry**: Pointfree.co animation episodes, RxAnimated, partly Lottie under the hood.
**Lesson**: **Animations are values.** Stored, composed, transformed, returned. `[Anim]` is a script; interpreter plays it.

---

## Pattern 10: Choreographer / sequencer / timeline DSL

```swift
withAnimation(.snappy) { state = .expanded }                                            // SwiftUI iOS 17
.keyframeAnimator(initialValue: 0, trigger: t) { c, p in c.opacity(p).scaleEffect(0.9 + 0.1*p) }
  keyframes: { _ in KeyframeTrack { LinearKeyframe(0, duration: 0); CubicKeyframe(1, duration: 0.6) } }
POPSequence().add(blurUp).then(chat).then(blurDown)                                     // Pop
Timeline().at(0.0).fade(in:blur).over(0.3).at(0.2).fade(in:chat).over(0.3)              // Bespoke
          .at(0.2).fade(out:timeline).over(0.3).at(0.5).fade(out:blur).over(0.7).play()
```
**Choose when**: animation IS a script — events on shared clock. Timing dominates over physics; >3 keyed events.
**Composes with**: 5 (progress driver IS timeline's clock), 9 (functional composition is one way to build the DSL), 2 (each track spring-timed).
**Cost**: DSL build cost is high — once built, every subsequent animation is cheap. Lottie+AE = "buy" version; `KeyframeAnimator` = Apple's "build" version.
**Industry**: `POPSequence`, Lottie keyframes, SwiftUI `KeyframeAnimator` + `PhaseAnimator` (WWDC 2023 #10157), `CAKeyframeAnimation` at lowest level.
**Lesson**: **Time is a first-class axis.** Events on a timeline can be seen, debugged, retimed, scrubbed. Chained `delay:` is the same thing without visualisation.

---

## Spring physics math (foundation for any modern pattern)

**`dampingRatio` (ζ)**: dimensionless ratio of damping to critical damping. ζ<1 underdamped (oscillates), ζ=1 critically damped (fastest non-oscillating), ζ>1 overdamped (slow asymptotic). UI useful range 0.7–1.0. <0.7 "wobbly", >1.0 "dead".

**`response` (T)**: time for one half-oscillation if undamped. UI useful range 0.25–0.6s. Relation to UIKit `(mass, stiffness)`: k = (2π / response)² · m ; c = 2 · ζ · √(k · m).

**Velocity-preserving retarget** (Wave's contribution). Mid-flight, new target B arrives. Naive: stop + restart from rest → visible "kick". Correct: read current velocity, hand as `initialVelocity` to a new spring targeted at B.

```
Underdamped spring (mass 1):
  ω₀ = 2π / response                         // natural freq
  ω_d = ω₀ · √(1 - ζ²)                       // damped freq
  env(t) = exp(-ζ · ω₀ · t)
  x(t) = target + env · (A cos(ω_d t) + B sin(ω_d t))
  v(t) = -ζ ω₀ · env · (A cos + B sin) + env · ω_d · (-A sin + B cos)
At retarget t*: sample x(t*), v(t*).
  initialVelocity_normalized = v(t*) / (newTarget - x(t*))     // per-axis
  spring_new = UISpringTimingParameters(dampingRatio: ζ, initialVelocity: CGVector(...))
```
`initialVelocity` in `UISpringTimingParameters` is **normalised by remaining distance**, NOT raw point/sec. Multiply raw velocity by `1 / (target - current)` per axis. `UIViewPropertyAnimator.velocity` (iOS 17+) returns the normalised vector directly.

**iOS 17 named springs — numeric params** (verifiable via `Spring.smooth.dump()`, WWDC23 #10158):

| Name | response | dampingFraction | Feel |
|---|---|---|---|
| `.smooth` | 0.5 | 1.0 | Critically damped, no bounce. Default for state changes. |
| `.snappy` | 0.5 | 0.85 | Slight overshoot. Direct manipulation. |
| `.bouncy` | 0.5 | 0.7 | Visible bounce. Playful affordances. |
| `.interactiveSpring()` | 0.15 | 0.86 | Fast, gesture-tracking. |

`.bouncy(duration: 0.8, extraBounce: 0.1)` adjusts response and stacks bounce on base damping.

---

## Composition hierarchy (lowest → highest)

1. `CABasicAnimation` / `CASpringAnimation` / `CAKeyframeAnimation` — explicit, off-main, model-vs-presentation. Foundation.
2. `UIView.animate(...)` — convenience over CA; no interruption story.
3. `UIViewPropertyAnimator` — interruptible, scrubbable, spring-timed. First level where senior code lives.
4. `UIViewControllerAnimated/InteractiveTransitioning` — VC-scope wrapper around #3.
5. `matchedGeometryEffect` / hero — semantic identity across animation boundaries.
6. State machine / coordinator — names lifecycle, owns cancellation.
7. Timeline / sequencer / declarative DSL — script-as-data.
8. SwiftUI declarative (`withAnimation` + `PhaseAnimator` + `KeyframeAnimator`) — Apple's bet on layer 7 baked in.

Senior staff iOS rarely writes at 1–2. They write level-3 building blocks composed into level-6 coordinators, occasionally lifted into level-7 DSL when team scales.

---

## Recommended pattern stack for DotPinchPrototype

- **Substrate**: `UIViewPropertyAnimator` + `UISpringTimingParameters` (pattern 2). Replace every `UIView.animate(withDuration:delay:)` in `V2RootViewController.revealChat:110–124` and `TimelineCanvas.swift:1225+`.
- **Composition**: CADisplayLink `ProgressDriver` (pattern 5). The three chained reveal animations become ONE progress run with three overlapping windows: blur `[0.00, 0.25]`, chat+timeline crossfade `[0.17, 0.42]`, blur-out `[0.42, 1.00]`. Single cancellation. Velocity-preserving retarget becomes natural — just re-target the driver.
- **Interaction**: `RevealCoordinator` (pattern 8) owning a `RevealMachine` (pattern 7) with states `{ .idle, .revealing, .presented, .dismissing }`. Pinch gesture → `setProgress`; release → `finish/cancel`. VC becomes a 30-line shell.
- **Authorship (deferred)**: pattern 10 (timeline DSL) is the right destination IF a second similar reveal appears. Don't build for one site. Pattern 4 (Lottie) is overkill — reveal is structural, not illustrative.

**Specifically replacing chained `UIView.animate(delay:)`**: **Pattern 5 (DisplayLink progress driver) + Pattern 2 (spring timing)** is the exact substitution. The three `delay:` args become three `(start, end)` windows on one 0…1 timeline. "Delay" disappears as a primitive — it is now "this window starts at 0.17".

---

## Frontiers

- `PhaseAnimator` + `KeyframeAnimator` (iOS 17) — Apple's declarative pattern-10. Port via `UIHostingController` for individual choreographed surfaces even in UIKit hosts.
- `SymbolEffect` / `SymbolEffectsView` — declarative motion for SF Symbols; API shape signals where Apple is heading (effect-as-value).
- Swift Async Algorithms `AsyncStream` driver — replacement for Combine progress publisher in async-first codebases.
- `Observation` (iOS 17) — fine-grained automatic dependency tracking; eventually replaces Combine `assign(to:)` for property binding.
- Wave (Janum Trivedi) — open source, ships velocity-preserving retarget as public API. Worth reading even if not adopted.
- Telegram-iOS transition system — open source Swift; reads as textbook on patterns 1+2+7+8 composed.

References: WWDC 2013 #218 "Custom Transitions Using View Controllers"; WWDC 2018 #803 "Advanced Animations with UIKit"; WWDC 2020 #10031 "Build SwiftUI views for any platform"; WWDC 2023 #10157 "Wind your way through advanced animations in SwiftUI"; WWDC 2023 #10158 "Animate with springs". Engineering posts: Airbnb "Introducing Lottie" (Feb 2017); Khanlou "Coordinator" (2015); Pointfree.co animations.
