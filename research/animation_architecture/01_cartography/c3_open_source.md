# CARTOGRAPHY — Open-source iOS animation libraries
POSTURE: janum

Read-only research on the OSS libraries the triple-A consumer cohort uses or
has been shaped by. Each entry captures the architectural lesson, not a
recommendation. **Wave** is treated deeper; the "adopt vs extract" question is
addressed at the bottom.

## Wave (Janum Trivedi) — https://github.com/jtrivedi/Wave — ACTIVE (low cadence; mature)
- Problem: Smooth, *retargetable*, *velocity-preserving* spring animations on
  UIView/NSView/CALayer. Interrupting mid-flight (new gesture target) does not
  "snap" — animation bends to the new target with current velocity intact.
- API (block-based, front of the 10%):
  ```swift
  let spring = Spring(dampingRatio: 0.68, response: 0.80)
  Wave.animate(withSpring: spring, gestureVelocity: pan.velocity(in: view)) {
      pipView.animator.center = destination          // retargetable
      pipView.animator.scale  = CGPoint(x: 1.1, y: 1.1)
  } completion: { finished, retargeted in /* … */ }
  ```
  The `view.animator.*` proxy is the key — assigning to it either retargets
  the in-flight animator or creates a new one.
- API (property-based, middle of the 10%):
  ```swift
  let a = SpringAnimator<CGPoint>(spring: spring)
  a.value = view.center; a.target = destination; a.velocity = gestureVelocity
  a.valueChanged = { [weak self] p in self?.view.center = p }; a.start()
  ```
- Patterns taught:
  1. **Animator-per-property**, not per-view. Each (target, keypath) gets its
     own (value, target, velocity). Retargeting is local.
  2. **View-attached proxy** gives block-based ergonomics on top of the
     property-based engine — elegant unification of the two APIs.
  3. **Velocity as first-class settable input**. Gesture handoff is explicit.
  4. **Two-valued completion** `(finished, retargeted)` distinguishes "ended
     at my target" from "another call replaced my target." Missing in UIView.animate.
- Interrupt/cancel/reverse: reassign `target` (velocity preserved);
  `stop(immediately:)` or target = current value cancels; reverse = target back
  to origin.
- Composes with: UIKit drop-in, SwiftUI interop, Combine manually. Zero deps.
- Shipped by: Studio Lin (Janum Trivedi); indie apps. Physics by Ben Oztalay.
- Implementation (https://github.com/jtrivedi/Wave/tree/main/Sources/Wave):
  A `DisplayLinkProvider` ticks every frame via `CADisplayLink`. One shared
  tick loop services every registered `Animation`. Each tick integrates the
  spring step from `dampingRatio` + `response` decomposed to stiffness/damping.
  120 fps requires `CADisableMinimumFrameDuration = true`.
- Lesson for our codebase: We already have the architectural core
  (`SpringAnimator<CGFloat>` + shared `AnimationController` +
  `SpringInterpolatable` is a faithful port of Wave's property engine).
  Missing: **proxy + retarget ergonomics** and **two-valued completion**.
  Both extractable without the dependency.

## Pop (Facebook, archived 2020) — https://github.com/facebookarchive/pop — ARCHIVED
- Problem: Physics-based animations decoupled from CAAnimation; spring + decay
  + basic + custom primitives driven by `CADisplayLink`. Animates any NSObject
  property. API (Obj-C):
  ```objc
  POPSpringAnimation *a = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerBounds];
  a.toValue = [NSValue valueWithCGRect:CGRectMake(0,0,400,400)];
  [layer pop_addAnimation:a forKey:@"size"];
  ```
- Patterns taught: (1) **Four-primitive taxonomy** — Spring, Decay, Basic,
  Custom. Decay (velocity → zero with friction) is the missing UIKit primitive
  and why flick-to-dismiss felt right in Paper. (2) **Animations as keyed
  detachable objects** — retarget by reassigning `toValue`. (3) **POPCustomAnimation**
  hands you dt — same shape as our `TimelineCanvas.masterTimer`.
- Interrupt/cancel: `pop_removeAnimationForKey:`; reassign `toValue` to retarget.
- Shipped by: Paper, Origami (Facebook), most 2014-2018 social apps. Direct
  ancestor of Wave/Motion/Advance.
- Lesson for our codebase: **Decay primitive is missing from our toolkit.**
  When gesture flick-to-dismiss arrives we will want decay alongside spring.
  The four-primitive taxonomy is a clean organizing principle for `Animation/`.

## Motion (Adam Bell / b3ll) — https://github.com/b3ll/Motion — ACTIVE
- Problem: SIMD-backed quantitative replacement for Pop. Game-engine model,
  `CADisplayLink`, gestural UIs. 5000 `SpringAnimation<SIMD64<Double>>` step
  in ~130ms per the README. API:
  ```swift
  let a = SpringAnimation<CGPoint>(initialValue: view.center)
  a.toValue = destination; a.velocity = gestureVelocity
  a.onValueChanged { p in view.center = p }; a.start()
  ```
- Patterns taught: (1) **`SIMDRepresentable` protocol** — CGRect becomes one
  4-wide SIMD op instead of four scalars. (2) **Game-engine model** — every
  animation steps on the main runloop tick; no Core Animation backing store.
  (3) Same retarget + velocity-input design as Wave; sibling library.
- Interrupt/cancel: `stop()`, `updateValue(to:)`, `velocity = …`.
- Shipped by: Indie apps; b3ll was at Apple working on motion design.
- Lesson for our codebase: **SIMD matters only when stepping thousands of
  properties.** We step ~20. Validates Wave's design independently — extraction
  targets are the same.

## Advance (Tim Donnelly) — https://github.com/timdonnelly/Advance — ACTIVE (low cadence)
- Problem: General-purpose physics + timed animation framework. Predates
  Motion's SIMD. API:
  ```swift
  let spring = Spring(initialValue: view.center)
  spring.tension = 30; spring.damping = 2
  spring.onChange = { view.center = $0 }; spring.target = destination
  ```
- Patterns taught: (1) **`VectorConvertible` protocol** — first articulation
  of "animatable type ↔ vector" that Motion later SIMD-ified. (2) **`Animator`
  with hand-off** between timed → spring → decay, *preserving velocity across
  animation-type changes*. Drag releases hand off a timed scrub to a spring
  with the scrub's instantaneous velocity.
- Lesson for our codebase: **Hand-off between timed and spring is a real
  primitive.** Our reveal lives entirely in timed UIView.animate blocks. The
  picture we want — drag with a timed scrub, release with a velocity-preserving
  spring landing — is exactly Advance's `Animator`.

## Lottie (Airbnb) — https://github.com/airbnb/lottie-ios — ACTIVE (very)
- Problem: Render After Effects compositions (Bodymovin JSON) at runtime,
  faithfully, across platforms. Decouples designer from engineer for
  illustration/mascot/loading-state animation. API:
  ```swift
  let v = LottieAnimationView(name: "checkmark-success")
  view.addSubview(v); v.play { finished in /* … */ }
  v.currentProgress = 0.42   // scrubbable
  ```
- Patterns taught: (1) **Animation-as-data**, not animation-as-code. JSON is
  source of truth; runtime is interpreter. Lottie's biggest architectural
  contribution — also most misapplied (illustration, not chrome/transitions).
  (2) **Multiple rendering backends** — Main (manual CALayer tree), Core
  Animation (compiles JSON into `CAAnimationGroup` for off-main playback),
  SwiftUI. The CA backend is the architectural gem. (3) **Progress as
  universal control surface** — `currentProgress ∈ [0,1]` parametrizes every
  animation. Same substrate as our `setCamera(_:)`.
- Interrupt/cancel: `pause()`, `stop()`, set `currentProgress`. No physics —
  player, not simulator.
- Shipped by: Airbnb (origin), Uber, Duolingo, Disney+ — every consumer app
  with success/loading mascot animations.
- Lesson: **Progress is the universal control surface for authored
  choreography.** Our reveal half is authored choreography. Model the whole
  reveal as one `progress ∈ [0,1]` curve, one driver pushes it forward.
  Delay-chain eliminated. (No JSON needed — geometry is in code.)

## Hero / HeroTransitions — https://github.com/HeroTransitions/Hero — MAINTAINED (slow)
- Problem: Declarative matched-geometry hero transitions for UIKit.
  `view.hero.id = "x"` on source + destination → framework auto-builds the
  cross-VC animation graph. API:
  ```swift
  thumbnail.hero.id = "card-42"            // VC A
  self.hero.isEnabled = true               // VC B
  detailImage.hero.id = "card-42"          // auto-animates
  ```
- Patterns taught: (1) **Identifier-matched geometry** — same idea SwiftUI
  later shipped as `matchedGeometryEffect`. Hero predates it. (2) Animation
  graph computed at transition-start from tagged-view union, driven by single
  `UIViewPropertyAnimator` (interactive) or `CADisplayLink`. (3) **Modifiers
  compose**: `[.fade, .translate, .scale]` stack on one view.
- Interrupt/cancel: Fully interactive — pan can scrub/cancel mid-transition.
  Strongest interactive transition story in OSS UIKit.
- Shipped by: Mid-tier consumer apps; not the FAANG choice (Apple Music/Photos
  roll their own).
- Lesson: **Matched-geometry is an architectural pattern, not a library
  feature.** Our dot → chat transition is conceptually a hero transition. Tag
  source, tag destination, coordinator computes the delta — right shape for
  the morph.

## Texture / AsyncDisplayKit — https://github.com/TextureGroup/Texture — MAINTAINED
- Problem: 60 fps on complex feeds by moving layout/text-sizing/image-decoding
  off-main. `ASDisplayNode` is a thread-safe UIView/CALayer abstraction. Not
  an animation library per se.
- Pattern taught: **Frame budget is the constraint, not API surface.** Every
  main-thread op requires justification.
- Shipped by: Pinterest, Buffer, Vine (RIP), Facebook (origin).
- Lesson: Not directly applicable (~20 animated properties, not 2000). The
  principle — 16ms is sacred — is the bar for any refactor.

## RxSwift / Combine animation orchestration — N/A (pattern, not a library)
- Problem: Compose time-based animation phases via `delay`, `debounce`,
  `combineLatest`, `zip`, `concatenate`. Replaces nested completion-block
  pyramids with a flat declarative pipeline. API (Combine):
  ```swift
  let dot    = Just(()).delay(for: .seconds(0.0), scheduler: RunLoop.main)
  let extend = Just(()).delay(for: .seconds(0.2), scheduler: RunLoop.main)
  let reveal = Just(()).delay(for: .seconds(0.5), scheduler: RunLoop.main)
  Publishers.MergeMany(dot, extend, reveal)
      .sink { phase in /* trigger UIView.animate per phase */ }
  ```
  Companion: RxAnimated (https://github.com/RxSwiftCommunity/RxAnimated) wraps
  RxCocoa bindings in UIView.animate.
- Patterns taught: (1) **Phases are values, not callsites** — a `Phase` enum
  stream lets you reason about choreography as a pipeline. (2) **Cancellation
  is structural** — disposing the subscription cancels downstream animations.
- Shipped by: Most apps adopt Combine for state, rarely for animation. Pattern
  is more documented than shipped at FAANG scale.
- Lesson for our codebase: **The delay-chained UIView.animate is a stream of
  phases pretending to be a single block.** Even without Combine, modeling
  reveal as a `Phase` enum driven by `AnimationController` ticks gives the
  same structural cancellation. The *minimum-viable* refactor of `revealChat`.

## TCA — https://github.com/pointfreeco/swift-composable-architecture — ACTIVE
- Problem: Unidirectional state machine; animations modeled as state
  transitions with `.animation(...)` annotations on effects.
- Pattern taught: **Animation as a property of a state transition**, not a
  side-effect of a view callback. State machine owns the timing graph.
- Lesson: Adopting TCA is out of scope, but **modeling the reveal as a state
  machine** (`.idle → .extending(progress) → .revealing → .open`) with
  spring/timeline drivers as effects is the right shape. Coordinator pattern.

## Other libs surveyed briefly
- **Spring (Meng To)** — https://github.com/MengTo/Spring — ABANDONED ~2018.
  IBInspectable preset animations. Animation-as-attribute pattern; modern
  descendant is `UIViewPropertyAnimator` + SwiftUI `.transition()`. Skip.
- **CocoaSprings (MacPaw)** — https://github.com/MacPaw/CocoaSprings — ACTIVE.
  ~300 LOC spring simulator at CALayer/UIView/NSWindow level. Confirms the
  entire pattern fits in 300 LOC (build-vs-buy intuition).
- **FlightAnimator** — https://github.com/AntonTheDev/FlightAnimator — chain-DSL
  over CAAnimation. Sugar; no new primitives.
- **interpolate.swift / FAEasing** — easing-curve presets. Trivial math (we
  already have `smoothstep`).
- **Pulse** (https://github.com/kean/Pulse) — network logging, *not* animation.

## Comparative table

| Library          | Substrate       | Spring | Decay | Retarget | Velocity | Composable | Status   |
|------------------|-----------------|:------:|:-----:|:--------:|:--------:|:----------:|----------|
| Wave             | CADisplayLink   |   Y    |   N   |    Y     |    Y     |     M      | Active   |
| Motion           | CADisplayLink   |   Y    |   Y   |    Y     |    Y     |     M      | Active   |
| Advance          | CADisplayLink   |   Y    |   Y   |    Y     |    Y     |     M      | Active   |
| Pop              | CADisplayLink   |   Y    |   Y   |    Y     |    Y     |     L      | Archived |
| Lottie           | CALayer/CA      |   N    |   N   |    N     |    N     |     H      | Active   |
| Hero             | UIViewPropAnim  |   N    |   N   |    Y*    |    Y*    |     H      | Slow     |
| Texture          | (layout)        |   -    |   -   |    -     |    -     |     -      | Active   |
| TCA              | (state machine) |   -    |   -   |    -     |    -     |     H      | Active   |
| Spring (MengTo)  | UIView.animate  |   N    |   N   |    N     |    N     |     L      | Dead     |
| CocoaSprings     | CADisplayLink   |   Y    |   N   |    Y     |    Y     |     M      | Active   |

(Y* = via interactive gesture transition only)

## Pattern synthesis — what the OSS landscape teaches Tier-3B coordination

1. **Animator-per-property is the convergent answer.** Wave, Motion, Advance,
   Pop, CocoaSprings — five independent designs all land on: one animator per
   (target, keypath), holding (value, target, velocity), ticked by a shared
   CADisplayLink. UIView.animate's block-of-property-changes is the outlier.

2. **The proxy pattern makes property-based animators ergonomic.**
   `view.animator.center = x` (Wave) hides per-property animator lookup.
   Without it, callers hold animator references; with it, ergonomics match
   UIView.animate without losing retargetability.

3. **Velocity is a structural input, not an emergent property.** Every physics
   lib treats `velocity` as a settable animator property fed from
   `pan.velocity(in:)`. UIView.animate has `initialSpringVelocity` but doesn't
   preserve it across calls — Wave/Motion close that gap.

4. **Phase-based authored choreography uses a single progress curve.** Lottie,
   Hero, UIViewPropertyAnimator, TCA all model authored sequences as
   `progress ∈ [0, 1]` driven by *one* timing source. Multiple UIView.animate
   blocks with hand-tuned delays are the anti-pattern every mature substrate
   eliminates.

5. **Cancellation is a property of the substrate, not a flag.** Every library
   handling interruption well makes the animation a first-class object you
   can hold a reference to (or look up by key/proxy) and mutate.
   UIView.animate's "block gone after start" is the structural reason our
   chained reveal can't cancel.

## Wave specifically: adopt directly, or extract patterns?

**Option A — Adopt Wave wholesale.** Replace our `SpringAnimator` /
`AnimationController` with Wave. Gain: proxy ergonomics, two-valued
completion. Lose: Wave's `DisplayLinkProvider` is internal — we lose the
shared `AnimationController` that phase-locks dt across our spring +
masterTimer. **Not recommended.**

**Option B — Extract proxy + retarget + two-valued completion into our code.**
Add (1) `UIView.animator` proxy looking up per-keypath `SpringAnimator`s,
(2) `(finished, retargeted)` on `SpringAnimator.completion`, (3) the "retarget
if present, else create new with current value + zero velocity" lookup rule.
~150 LOC. Wave's ergonomic surface on top of our owned physics, preserves the
phase-lockable single-`CADisplayLink` model. **Recommended.**

**Option C — Take only the mental model (velocity-input + retarget), leave
the proxy.** Keep `SpringAnimator<T>` as is; call sites hold animator
references and reassign `target` for retargets. **Acceptable** first step;
reveals whether the proxy is load-bearing or sugar. The morph + camera
already work this way.

Deeper insight: **Wave is what our `SpringAnimator` would be with two more
features (proxy, retarget-detecting completion).** One weekend of work from
Wave-equivalence, and we keep the phase-lockable single-`CADisplayLink` model
Wave's encapsulated provider doesn't expose. The 90% answer is Option B.

Sibling lesson from Pop/Motion/Advance: **add `DecayAnimator<T>`** at the
same time — same architectural shape as `SpringAnimator` with friction in
place of spring. Needed once gesture flick-to-dismiss enters the design.
