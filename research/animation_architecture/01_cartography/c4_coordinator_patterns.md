# CARTOGRAPHY — Animation coordinator + orchestrator patterns
POSTURE: janum

Scope: architectural patterns for coordinating complex animation systems, independent of any specific primitive (UIKit, SwiftUI, Pop, Lottie, etc.). Patterns transcend libraries; the same shape recurs in CALayer, UIView, SwiftUI, and game engines. Pain point under audit: `V2RootViewController.revealChat` is three `UIView.animate(delay:)` blocks whose timing seams are hardcoded `delay:` values — re-tuning one block silently breaks the choreography because there is no single source of truth for the timeline.

---

## 1. State machine pattern
- Definition: An interaction is modeled as a finite set of states (`.idle, .expanding, .settling, .cancelled, .completed`) with explicit transitions. Each state owns its entry/exit animation block. The state, not the animation block, is the load-bearing thing.
- Canonical form:
  ```swift
  enum RevealPhase { case idle, blurringIn, swappingContent, blurringOut, done, cancelled }
  func transition(to: RevealPhase) { /* dispatch animation for the transition */ }
  ```
- Strengths: Cancellation is a first-class transition (`.cancelled`), not a magic completion-handler check. Re-entrancy is provable. State diagram is reviewable on paper.
- Weaknesses: Verbose for short choreographies. Tends to encode timing inside transition handlers, so the brittle `delay:` numbers can hide inside each transition unless paired with another pattern (timeline, choreographer).
- Implementation effort: medium (the state graph) + small (each transition).
- Composable with: timeline (state = which timeline is running), coordinator object (the SM lives inside one), reactive (states emitted as a Publisher), interactive transition (UIPanGestureRecognizer states map 1:1).
- Apps shipping it: Apple's SpringBoard uses an explicit state machine for App Switcher / Home / Cover Sheet. UIGestureRecognizer is the canonical iOS state machine — every gesture is one. Apple's `UIDocumentBrowserViewController` transitions. Linear desktop's command-palette open/close.
- Replaces chained UIView.animate(delay:): partially — gives you transition seams but doesn't by itself solve "I need step B to start 200ms after step A inside the .expanding state."
- Counter-pattern: Don't use when there are no meaningful intermediate states (a single fade-in is not a state machine).
- Lesson for coordination: Make the phases explicit. The bug in chained `UIView.animate` is that there is no `.swappingContent` symbol — only three anonymous blocks. Naming the phases makes the choreography legible.

## 2. Timeline / scrubber pattern
- Definition: A single canonical `progress: 0.0...1.0` value drives every visible property through deterministic interpolation. Time becomes data. The animation is a pure function of progress.
- Canonical form:
  ```swift
  func apply(progress p: Double) {
      blur.alpha = curve(p, in: 0.00...0.30)
      chat.alpha = curve(p, in: 0.20...0.50)
      timeline.alpha = 1 - curve(p, in: 0.20...0.50)
      blur.alpha = (p > 0.5) ? (1 - curve(p, in: 0.50...1.0)) : blur.alpha
  }
  ```
- Strengths: Scrubbable — you can jump to t=0.4 instantly for debugging. Reversible for free. Deterministic, snapshot-testable. Mid-flight retargeting is just changing the function driving `progress`.
- Weaknesses: Spring physics don't fit a fixed 0...1 progress cleanly (overshoot). Requires you to model every property as a function of one scalar — sometimes that scalar must be vector-valued (translation + rotation + alpha each on their own timeline).
- Implementation effort: small (the substrate) + medium (defining every property's curve segment).
- Composable with: state machine (each state owns a timeline), coordinator (coordinator owns the timeline), display-link driver (DL pushes progress), interactive transition (gesture sets `fractionComplete`).
- Apps shipping it: Apple Music's now-playing expansion (UIViewPropertyAnimator with `fractionComplete`). Apple's Photos picker dismiss. iOS Control Center pull-down. The DotPinchPrototype's `setCamera(_:)` → `pushCameraToVisibleCells` is already this shape for the cell chrome.
- Replaces chained UIView.animate(delay:): yes — this is the direct replacement. The `delay:` values become start points on a normalized timeline.
- Counter-pattern: Don't use for rest-state spring physics where overshoot is the point. Don't use when the animation is event-driven rather than time-driven.
- Lesson for coordination: One scalar source of truth eliminates drift. Three `delay:` numbers in three blocks is three sources of truth that must agree by construction; one `progress` is one source by definition.

## 3. Coordinator object pattern
- Definition: A dedicated class owns the animation graph for one logical interaction. Views are inputs; the coordinator decides what runs, in what order, how to cancel, how to retarget. Per-interaction granularity — `RevealCoordinator`, `MorphCoordinator`, `PinchReturnCoordinator`.
- Canonical form:
  ```swift
  final class RevealCoordinator {
      init(presenter: UIView, blur: UIVisualEffectView, chat: UIView, timeline: UIView)
      func start() -> AnyCancellable
      func cancel()
      func retarget(to: RevealTarget)
  }
  ```
- Strengths: View controllers shrink. Each coordinator is independently testable. Lifetime and cancellation become objects — easy to reason about. Same coordinator can be invoked from different call sites (cell tap, deep link, restoration).
- Weaknesses: Adds a layer. Risk of becoming "controllers that own controllers" if not disciplined about scope (one coordinator = one interaction, not one screen).
- Implementation effort: medium per coordinator.
- Composable with: every other pattern — coordinator is the *container* for state machine, timeline, choreographer, etc. It is structural, not behavioral.
- Apps shipping it: Airbnb's "coordinator" architectural style (extended from navigation coordinators to animation coordinators in their iOS app). Uber's RIBs include "Interactors" which play this role for transitions. Square Cash's transaction-detail expand. Many internal-Apple animation seams use private "transition coordinator" objects (`UIViewControllerTransitionCoordinator` is the public face).
- Replaces chained UIView.animate(delay:): partially — gives you a home for the choreography but you still need a pattern *inside* it (timeline, choreographer).
- Counter-pattern: Don't create a coordinator for a 1-property fade. The overhead exceeds the value.
- Lesson for coordination: Animations have lifecycles. Lifecycles want owners. View controllers are the wrong owner because they outlive interactions.

## 4. Choreographer pattern
- Definition: A declarative timeline specification — "at t=0 start A, at t=200ms start B, at t=700ms end A" — handed to a runtime that schedules the events. The spec is data; the runtime is generic.
- Canonical form:
  ```swift
  let spec: [Cue] = [
      Cue(at: 0.00, run: blurUp),
      Cue(at: 0.20, run: chatFade),
      Cue(at: 0.50, run: blurDown),
  ]
  Choreographer(spec).run()
  ```
- Strengths: The choreography is one inspectable list. Reorder, retime, A/B-test by editing the list. Pairs well with serialization (load from JSON, Lottie, After Effects).
- Weaknesses: Cues fire in absolute time — interruption still needs explicit handling. Cancellation of in-flight cues is on you. Spec authors must understand that cues are events, not animations themselves (the animation is what the cue triggers).
- Implementation effort: small (the runtime is ~30 lines on top of a display link) + small per spec.
- Composable with: timeline (cues become keyframes), state machine (each state has a choreography spec), coordinator (coordinator owns the spec).
- Apps shipping it: Pop's `POPSequence` and `POPCompositeAnimation` (Facebook, used in Paper and Slingshot). Apple's `CAKeyframeAnimation` is a primitive form. `UIViewPropertyAnimator.addAnimations(_:delayFactor:)` is a deliberately minimal choreographer. Lottie is a choreographer driving CALayer — the spec is the .json. Rive does the same with a richer state graph.
- Replaces chained UIView.animate(delay:): yes — this is the most literal replacement. Same shape, one source of truth, runtime cancellation.
- Counter-pattern: Don't use for physics-driven interactive animations where the target moves continuously with the user's finger — cues are time-anchored, fingers are not.
- Lesson for coordination: Separate the *what-when* from the *how*. The choreography spec is the design artifact; the runtime is the engineering artifact. Today both are tangled in three UIView.animate blocks.

## 5. Declarative timeline DSL
- Definition: Same as choreographer, but with Swift result builders / operator overloading so the spec reads like prose. `0.0 ~> blur.alpha(1)`, `0.2 ~> chat.alpha(1)`.
- Canonical form:
  ```swift
  Timeline {
      0.0  ~> blur.alpha(to: 1, dur: 0.3)
      0.2  ~> chat.alpha(to: 1, dur: 0.3)
      0.5  ~> blur.alpha(to: 0, dur: 0.7)
  }
  ```
- Strengths: Maximum readability. The choreography reads like a storyboard. Designers can review it. Compiler-checked.
- Weaknesses: DSL design is hard. Result builder ergonomics constrain expressiveness. Debugging custom operators is painful. Onboarding cost for new engineers.
- Implementation effort: large (good DSL) — or small if you accept a less polished surface.
- Composable with: choreographer (DSL emits a spec), coordinator (DSL inside a coordinator), state machine (per-state DSL block).
- Apps shipping it: SwiftUI's `withAnimation` + `Animation` API is itself a small DSL. Vapor's animation DSLs in internal projects. Less common in shipped consumer iOS apps than the bare choreographer pattern.
- Replaces chained UIView.animate(delay:): yes — it IS that, with sugar.
- Counter-pattern: Don't build a DSL for a codebase with one interaction. The leverage is in 5+ choreographies sharing the substrate.
- Lesson for coordination: Syntax matters. The reason chained UIView.animate feels brittle is partly that the syntax doesn't communicate that the three blocks are one choreography — they look like three independent calls.

## 6. Reactive composition (Combine / RxSwift)
- Definition: Animations as values over time, composed with stream operators: `delay`, `merge`, `zip`, `combineLatest`, `flatMap`. The choreography is a publisher pipeline.
- Canonical form:
  ```swift
  let blurUp = animate(blur, alpha: 1, dur: 0.3)
  let chatFade = animate(chat, alpha: 1, dur: 0.3).delay(for: 0.2)
  let blurDown = animate(blur, alpha: 0, dur: 0.7).delay(for: 0.5)
  Publishers.Merge3(blurUp, chatFade, blurDown).sink { ... }
  ```
- Strengths: Time-based composition is the native operation. Cancellation is `AnyCancellable.cancel()`. Backpressure built in. Plays nicely with state-driven UIs.
- Weaknesses: Animations don't really fit Combine's value semantics — they're side-effects on views. The wrapping to bridge `UIView.animate` into a `Publisher` is awkward. Schedulers + main-thread are easy to get wrong.
- Implementation effort: medium (bridging UIView.animate → Publisher) + small per choreography.
- Composable with: state machine (states are a `Publisher`), coordinator (owns subscriptions), timeline (publish progress as a value).
- Apps shipping it: Many React Native / Reactive Cocoa apps from 2016-2020 (Trello, parts of Instagram). Apple's own SwiftUI uses Combine under `withAnimation` but not as the user-facing model.
- Replaces chained UIView.animate(delay:): partially — replaces the *composition*, but the actual animation work is still UIView.animate underneath unless paired with a substrate (e.g., DisplayLink → CurrentValueSubject<Double, Never>).
- Counter-pattern: Don't introduce Combine just for animations if the rest of the codebase is imperative. Too much ceremony.
- Lesson for coordination: Operators are valuable because they compose. `delay()` is a real value, not a magic argument to `UIView.animate`.

## 7. CADisplayLink-driven progress modeling
- Definition: One CADisplayLink ticks at vsync. One `progress` source advances each tick. Every animator reads the current progress and updates its property. Pattern shown by the "Wave / Studio Lin" school and Twitter's Hyperion. Already the substrate of DotPinchPrototype's `masterTimer`.
- Canonical form:
  ```swift
  final class Driver {
      var progress: Double = 0
      var subscribers: [(Double) -> Void] = []
      @objc func tick(_ link: CADisplayLink) {
          progress = min(progress + link.duration / duration, 1)
          subscribers.forEach { $0(progress) }
      }
  }
  ```
- Strengths: One source of frame time → phase-locked animations across the system. Zero drift. Easy to pause, reverse, scrub. Cheap (one DL is cheaper than N UIView.animate spawns).
- Weaknesses: You write the easing yourself. You write cancellation yourself. Easy to leak the DL if not careful (retain cycles on the target).
- Implementation effort: small substrate + small per animator. The DotPinchPrototype already has `AnimationController` doing this.
- Composable with: timeline (DL IS the timeline driver), choreographer (DL ticks fire cues), state machine (state owns its DL config), coordinator (coordinator owns the DL).
- Apps shipping it: Twitter/X iOS (TweetTimeline animation). Snapchat camera. Apple's Photos zoom transitions. Pop is structurally this pattern (one DL, multiple animators). The DotPinchPrototype's `masterTimer` + `AnimationController` is already half of this — the gap is that the *reveal* and the *masterTimer morph* don't share the substrate.
- Replaces chained UIView.animate(delay:): yes — and unifies with the existing morph substrate.
- Counter-pattern: Don't use for a single 0.3s fade. UIView.animate is cheaper.
- Lesson for coordination: One driver, one clock. The brittleness of three UIView.animate(delay:) blocks comes from each having its own implicit clock (UIKit's animation timer + its own start instant).

## 8. Composable animations (functional)
- Definition: Each animation is a value (struct), not a call site. Combinators (`then`, `parallel`, `delay`, `repeat`, `reverse`) compose values into larger animations. The composed value is "run" by an interpreter.
- Canonical form:
  ```swift
  let reveal = parallel(
      animate(blur, .alpha, 1, dur: 0.3),
      delay(0.2, animate(chat, .alpha, 1, dur: 0.3)),
      delay(0.5, animate(blur, .alpha, 0, dur: 0.7))
  )
  reveal.run(on: driver)
  ```
- Strengths: Composition is algebraic. Animations are inspectable, transformable (you can `.reversed()` any composed animation). Substitution: swap `.alpha` for `.scale` and the whole shape still works.
- Weaknesses: Requires a substrate interpreter. Performance characteristics depend on the interpreter. Type system gymnastics for heterogeneous animations.
- Implementation effort: medium (interpreter) + small per choreography.
- Composable with: choreographer (the composed value IS a choreography), coordinator (coordinator holds the value and runs it), display link (the interpreter).
- Apps shipping it: Pop's API design. ReactiveAnimation libraries in Haskell/Elm (FRP roots). RxAnimated. Less common in shipped iOS apps because the ergonomic ceiling is lower than DSL.
- Replaces chained UIView.animate(delay:): yes — the most "principled" replacement.
- Counter-pattern: Don't use when speed of iteration matters more than principle. The combinators take getting used to.
- Lesson for coordination: Animations CAN be values. Treating them as side-effects of method calls is what creates the brittleness. `UIView.animate` is a call; `Animation` is a thing.

## 9. Interactive transition pattern
- Definition: `UIViewControllerAnimatedTransitioning` + `UIPercentDrivenInteractiveTransition` (or `UIViewPropertyAnimator` with `fractionComplete`) lets a gesture scrub the transition. Pause, reverse, complete based on velocity.
- Canonical form:
  ```swift
  let animator = UIViewPropertyAnimator(duration: 0.5, curve: .easeInOut) { /* fully-applied state */ }
  panGesture.handler = { animator.fractionComplete = pan.translation.y / view.height }
  ```
- Strengths: Built-in iOS support. Pause/reverse/scrub for free. Velocity hand-off to spring on release.
- Weaknesses: API surface is narrow (one block of "fully applied" — sequencing inside is awkward). `UIViewControllerTransitioning` lifecycle is rigid.
- Implementation effort: small for property animator, medium for full transition coordinator.
- Composable with: timeline (fractionComplete IS the progress), state machine (gesture states drive transitions), coordinator.
- Apps shipping it: Apple modal sheets (drag to dismiss). Apple Music expand-from-mini-player (gesture-driven). Photos zoom-out gesture. Instagram's swipe-back. Telegram-iOS's interactive transitions for every modal.
- Replaces chained UIView.animate(delay:): partially — it's the perfect substrate for one timeline, but you still need an outer pattern (choreographer / coordinator) for multi-phase compositions.
- Counter-pattern: Don't use if the interaction isn't gesture-scrubbable. Tap-to-reveal isn't interactive in this sense.
- Lesson for coordination: User input is a clock too. Designing for "could a finger drive this?" is the test that exposes which animations are *really* about time.

## 10. Side-effect-free declarative animations
- Definition: SwiftUI's model. State changes; the framework diffs the view tree and animates the differences inside a `withAnimation` scope. Animation is implicit, derived from state.
- Canonical form:
  ```swift
  withAnimation(.spring(duration: 0.5)) { phase = .expanded }
  // view body responds: opacity, scale, offset all derived from phase
  ```
- Strengths: Maximum compositional. Designer-friendly. Hierarchy-wide consistency. The state machine is the model layer.
- Weaknesses: UIKit codebases can't adopt it without bridge. Imperative escape hatches (CATransaction) get awkward. Frame-perfect timing of multiple properties needs `matchedGeometryEffect` + `phaseAnimator`.
- Implementation effort: small if you're in SwiftUI; large if you're bridging from UIKit.
- Composable with: state machine (states drive view shape), coordinator (per-feature state model).
- Apps shipping it: Apple's Wallet (post-2023), parts of Settings, Apple's Sandbox apps. Things 3's iOS app uses heavy SwiftUI for inbox animations. Linear iOS. Notion's newer surfaces.
- Replaces chained UIView.animate(delay:): no, in the UIKit shell. yes, if the screen were rewritten in SwiftUI — which is a much larger move than substituting a pattern.
- Counter-pattern: Don't rewrite a working UIKit screen for the animation pattern alone. The cost vastly exceeds the brittleness fix.
- Lesson for coordination: When the data model carries the animation seams, the choreography becomes a property of state, not of imperative code. This is the destination state of the field — but a bridge cost is real.

---

## Hybrid patterns observed in shipping apps

- **Apple Music's now-playing expansion** = State machine (collapsed / dragging / expanded) + Timeline (a `UIViewPropertyAnimator` scrubbing all properties via `fractionComplete`) + Coordinator (private `MPNowPlayingTransitionCoordinator`) + Interactive transition (gesture scrubs the animator). All four at once.
- **Things 3's add-to-inbox** = SwiftUI declarative (matchedGeometry between the FAB and the inbox row) + State machine (idle / dragging / committed) + Choreographer for the chime + check sequence.
- **Apple Photos zoom-into-photo** = Coordinator (`UIViewControllerTransitionCoordinator`) + Timeline (single progress drives source/destination mask + scale + alpha) + Interactive (pinch-down to dismiss is scrubbed).
- **Apple App Switcher** = State machine (gesture states) + DisplayLink-driven progress (single clock across all card animations) + private layered coordinator.
- **Pop / Paper (Facebook 2014)** = DisplayLink driver + Composable animations + Choreographer (`POPSequence`). The most algebraically pure shipped example.
- **Telegram-iOS chat transitions** = State machine + Interactive transition + DisplayLink-pushed progress with hand-rolled spring on release.

The pattern across premium-tier apps is unambiguous: **no single pattern is sufficient**. Tier-3 animation systems combine 3-4 of these patterns, where one is structural (Coordinator), one is temporal (Timeline or Choreographer), one is reactive to input (State machine or Interactive transition), and one is the substrate (DisplayLink or UIViewPropertyAnimator).

---

## Recommended pattern selection matrix for DotPinchPrototype

| Interaction | Best pattern (composite) | Why |
|---|---|---|
| Reveal (currently chained UIView.animate(delay:)) | Coordinator (`RevealCoordinator`) + Timeline (one `UIViewPropertyAnimator` driving fractionComplete OR a CADisplayLink emitting progress) + Choreographer (cues at 0.00/0.20/0.50/0.70 on the normalized timeline) | Direct fix to the three-`delay:` brittleness. One source of truth replaces three. Timeline is scrubbable, retargettable, cancellable. Reuses existing `AnimationController` substrate. |
| Tap-to-chat morph (currently `masterTimer` CADisplayLink) | Keep DisplayLink-driven progress substrate + wrap in Coordinator (`MorphCoordinator`) + State machine (`.idle / .morphingIn / .settled / .morphingOut`) | The substrate is already correct (Tier 2B+). The gap is that the morph and the reveal don't share substrate or coordinator. Hoisting into named coordinators makes them peers. |
| Pinch return-to-rest | SpringAnimator (already correct) + State machine inside a Coordinator (`PinchCoordinator`) with `.tracking / .returning / .settled / .cancelled` | Spring physics is the right primitive — don't normalize it onto a timeline. State machine handles cancellation when user re-pinches mid-return. |
| Cell chrome alpha (currently `setCamera`/`pushCameraToVisibleCells`) | Already Timeline-pattern. Formalize: expose `Camera` as a Publisher<Progress> or a `progress`-bearing struct read by cells. Coordinator can subscribe. | The substrate is right; only the naming and ownership want hoisting. |
| Future: gesture-scrubbed reveal (drag down to dismiss chat) | Interactive transition + Timeline (same animator used for tap-reveal, just with `fractionComplete` driven by gesture instead of clock) | If the timeline pattern is adopted for reveal, this becomes free — same animator, different driver. This is exactly the Apple Music move. |

The unifying recommendation: **one `AnimationCoordinator` per interaction + one shared display-link substrate (already exists as `AnimationController`) + per-interaction choice of timeline (scrubbable choreographies) or spring (physics rest)**. The state machine is the connective tissue inside each coordinator.

---

## What no single pattern provides (motivates hybrid)

- **State machine alone** names the phases but doesn't solve sub-phase timing — you still get `delay:` smuggled inside transition handlers.
- **Timeline alone** doesn't model interruption / cancellation crisply — needs a state machine on top.
- **Coordinator alone** is just structure — needs a behavioral pattern inside.
- **Choreographer alone** runs cues but doesn't unify physics-driven animations (springs don't fit on a 0...1 progress).
- **DSL alone** is just sugar over the choreographer; sugar without substrate is bikeshedding.
- **Reactive alone** composes time but the side-effecting on views is awkward without a substrate.
- **DisplayLink alone** is a clock — no semantics about choreography.
- **Composable values alone** are mathematically pretty but ergonomically taxing.
- **Interactive transition alone** is gesture-scrubbing; doesn't help tap-driven reveals.
- **Declarative/SwiftUI alone** requires the host environment — non-portable to UIKit screens.

The synthesis: **Coordinator (structure) + State machine (phases) + Timeline OR Spring (substrate, per-phase) + DisplayLink (shared clock)**. This is the shape Apple's premium animations take, and the shape that retires the chained `UIView.animate(delay:)` pattern definitively.
