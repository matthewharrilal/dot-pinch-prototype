# CARTOGRAPHY — SwiftUI animation primitives
POSTURE: janum

Scope: the menu a senior staff engineer at a triple-A iOS shop considers when adopting SwiftUI animations inside a UIKit app via `UIHostingController`. iOS 17+ assumed (DotPinchPrototype target). All entries map back to the load-bearing artifact: the three chained `UIView.animate(delay:)` blocks in `V2RootViewController.revealChat` (lines 110–124).

---

## `withAnimation { }` + `Animation` API — iOS 13+; refreshed iOS 17
- **What**: imperative-feeling wrapper around state mutation that triggers an implicit animation on every view whose body depends on the mutated state. Curves: `.linear`, `.easeIn/Out/InOut`, `.spring(...)`, `.interactiveSpring`, plus iOS 17 named springs `.smooth`, `.snappy`, `.bouncy`. (https://developer.apple.com/documentation/swiftui/animation, WWDC23 #10157 "Animate with springs")
- **Strengths**: choreography expressed as state, not as nested closures. Re-entering `withAnimation` mid-flight automatically picks up from current animated value (velocity preserved when using springs).
- **Limitations**: implicit dependency graph — debugging "why did THIS view animate?" is harder than reading a `UIView.animate` closure. Group/sequence semantics require `PhaseAnimator` or manual `DispatchQueue` (anti-pattern in SwiftUI).
- **Cancellable / pausable / reversible**: cancellable by mutating state again inside another `withAnimation` (the new animation re-targets from current value); not pausable; reversible only by setting target back to origin.
- **Composes with**: `matchedGeometryEffect`, `Transition`, `.animation(_:value:)`, every other SwiftUI primitive.
- **Apple's own use**: pervasive — Photos, Music, Weather, Settings.
- **UIKit-bridging cost**: zero if the animated surface is a SwiftUI subtree hosted in a `UIHostingController`. Host once, animate inside.
- **Replaces what UIKit pattern**: the entire `UIView.animate(delay:)` family when the animated surface is owned by SwiftUI. Multi-stage choreography moves to `PhaseAnimator`.

---

## `matchedGeometryEffect` + `Namespace` — iOS 14+
- **What**: declares a shared identity across two views. When the view tree updates and the same `id` appears in a different position/size, SwiftUI animates the geometric delta. `matchedGeometryEffect(id:in:properties:anchor:isSource:)`. (https://developer.apple.com/documentation/swiftui/view/matchedgeometryeffect)
- **Strengths**: zero-arithmetic hero transitions. Designer specifies "this is the same element"; framework solves the layout interpolation. Replaces ~200 lines of manual frame-conversion code per transition.
- **Limitations**: both source and destination must be in the SwiftUI view tree at the same time during the animation (one with `isSource: true`, the other not). Cross-`Namespace` transitions (e.g. across `NavigationStack` push) are awkward pre-iOS 18. View must actually render at destination — z-order quirks with sheets.
- **Cancellable**: inherits `withAnimation` semantics — re-target mid-flight by changing state again.
- **Composes with**: `withAnimation`, custom `Transition`, `PhaseAnimator`.
- **Apple's own use**: Photos zoom-in to detail, Music cover art expansion, App Library, Calendar event tap-to-expand.
- **UIKit-bridging cost**: source AND destination both need to be inside the same SwiftUI tree. Bridging a UIKit collection cell → SwiftUI detail loses the matchedGeometry leverage. iOS 18's `NavigationTransition` (`.zoom`) finally bridges across nav.
- **Replaces what UIKit pattern**: custom `UIViewControllerAnimatedTransitioning`, manual `convert(_:to:)` frame math, snapshot-view choreography.

---

## `PhaseAnimator` — iOS 17+
- **What**: declarative state machine for multi-phase animations. You declare an ordered set of phases; SwiftUI cycles through them with a configurable `animation(_:for:)` per phase. (https://developer.apple.com/documentation/swiftui/phaseanimator, WWDC23 #10156 "Wind your way through advanced animations")
- **Strengths**: directly replaces "chain three animations with manual delays". Each phase declares its own duration/curve; the framework owns the handoff. No drift on dropped frames — phase transitions are dispatched on the render loop, not on wall-clock `delay:`.
- **Limitations**: phases progress strictly forward (loop or one-shot via `trigger:`); not free-scrubbable. Cancellation snaps to current phase unless you re-design as a value-driven animator.
- **Cancellable / pausable / reversible**: trigger re-fires from phase 0; not pausable; not reversible without manual phase ordering.
- **Composes with**: `withAnimation`, `matchedGeometryEffect`, `Transition`.
- **Apple's own use**: Symbol-effect bounces, onboarding pulse animations, Sandbox-level error indicators.
- **UIKit-bridging cost**: full SwiftUI primitive — must host the animated surface in `UIHostingController`. Trigger can be driven from UIKit via `@Observable` model.
- **Replaces what UIKit pattern**: **directly replaces `revealChat`'s three-block delay chain.** Phases: `.hidden → .blurIn → .chatVisible → .blurOut`, each with its own duration. See conclusion.

---

## `KeyframeAnimator` — iOS 17+
- **What**: keyframe-based animation where multiple properties animate on independent timelines. `KeyframeTrack(\.scale) { ... }` per property. (https://developer.apple.com/documentation/swiftui/keyframeanimator, WWDC23 #10156)
- **Strengths**: precise designer-driven choreography. Multiple `KeyframeTrack`s let scale, opacity, rotation each follow their own curve over the same timeline — exactly the model Lottie/AE export. Trigger-driven.
- **Limitations**: one-shot per trigger. No mid-flight retargeting (springs are better for that). Computed at evaluation time — not a layer-backed animation.
- **Cancellable**: trigger restart only; no fluid interruption.
- **Composes with**: itself nested, `Transition`.
- **Apple's own use**: complex symbol animations, Health summary chart entrance, Fitness ring fills.
- **UIKit-bridging cost**: SwiftUI-only surface. Drive trigger via `@Observable` from UIKit.
- **Replaces what UIKit pattern**: hand-rolled `CADisplayLink`-driven `masterTimer` (TimelineCanvas line ~1322), multi-property `CABasicAnimation` groups.

---

## `Transition` protocol — iOS 17+
- **What**: composable transitions for view insertion/removal. `.transition(.scale.combined(with: .opacity))`, custom via `Transition` protocol with `body(content:phase:)`. (https://developer.apple.com/documentation/swiftui/transition)
- **Strengths**: declarative appear/disappear. Authors a single function `(content, phase) -> View` — framework handles the rest. Asymmetric in/out trivially supported.
- **Limitations**: tied to view identity changes (insert/remove). Not for "animate this property of an existing view".
- **Cancellable**: interruptible — removing a view mid-insert reverses cleanly.
- **Composes with**: `.combined(with:)`, `.animation(_:)`, `matchedGeometryEffect`.
- **Apple's own use**: Notifications drop-in, Control Center tile expand, Lock Screen widget reveals.
- **UIKit-bridging cost**: SwiftUI-only.
- **Replaces what UIKit pattern**: `UIView.transition(with:duration:options:)`, manual snapshot crossfades.

---

## `SymbolEffect` + `ContentTransition` — iOS 17+
- **What**: built-in animations for SF Symbols (`.bounce`, `.pulse`, `.variableColor`, `.replace`, `.appear`, `.disappear`, iOS 18 `.breathe`, `.rotate`, `.wiggle`) and content transitions for text/numbers (`.numericText()`, `.interpolate`, `.symbolEffect`). (https://developer.apple.com/documentation/swiftui/symboleffect, WWDC23 #10257)
- **Strengths**: one-line animations for the highest-frequency UI affordances. Numeric `.contentTransition(.numericText())` ticks counters at Apple-grade quality for free.
- **Limitations**: limited to symbols and `Text`. No analog for custom views.
- **Cancellable**: yes — re-trigger overrides.
- **Composes with**: `SensoryFeedback`.
- **Apple's own use**: every SF-Symbol-bearing surface in iOS 17+ (Mail, Messages, Music play/pause).
- **UIKit-bridging cost**: SwiftUI-only, but `UIImageView` has `addSymbolEffect(_:options:animated:)` API too (iOS 17+) — UIKit gets the same primitive.
- **Replaces what UIKit pattern**: custom `CAKeyframeAnimation` on symbol image-views, manual number-rolling counters.

---

## `SensoryFeedback` — iOS 17+
- **What**: declarative haptic feedback driven by state changes. `.sensoryFeedback(.impact, trigger: state)`. (https://developer.apple.com/documentation/swiftui/view/sensoryfeedback)
- **Strengths**: coordinates haptic with the same `trigger` value driving visual animation — no separate "did the animation finish" handoff for the haptic.
- **Limitations**: SwiftUI-only API. UIKit equivalent is still manual `UIImpactFeedbackGenerator`.
- **Composes with**: any value-driven animation.
- **Apple's own use**: Lock Screen, Wallet, Health.

---

## `.animation(_:value:)` modifier + `.animation(_:body:)` — iOS 13/17
- **What**: scope an animation to specific value changes. iOS 17's `.animation(_:body:)` variant animates only the modifiers inside the body closure when the value changes — solves the "animation leaked into a child I didn't want" problem. (https://developer.apple.com/documentation/swiftui/view/animation(_:value:))
- **Strengths**: surgical scoping. Replaces `withAnimation`'s global blast-radius.
- **Limitations**: must name the trigger value; not implicit.
- **Composes with**: every other primitive.
- **Apple's own use**: list-row insertion/removal scoping, settings toggles.
- **Replaces what UIKit pattern**: nothing direct — but it's the antidote to `withAnimation`'s over-reach, which is the SwiftUI analog of "I animated the wrong thing in this `UIView.animate` block."

---

## `@State` / `@Observable` + animation tracking — iOS 13+/17+
- **What**: SwiftUI's reactive substrate. Animation IS state change observed by the view tree. `@Observable` (iOS 17, Swift Observation) replaces `ObservableObject` with property-granular dependency tracking.
- **Strengths**: animation phase becomes a first-class model property — exactly the "no central animation phase model" blind spot the gauge identifies. Cancellation = state mutation. Composition = struct composition.
- **Limitations**: requires buying into the SwiftUI mental model. Mixed UIKit/SwiftUI ownership of the same animation state is painful.
- **Composes with**: every primitive in this document.
- **Apple's own use**: every iOS 17+ Apple-shipped SwiftUI app.
- **UIKit-bridging cost**: `@Observable` works from UIKit too (via `withObservationTracking { }` or by hosting the SwiftUI subtree); the model layer can be shared.
- **Replaces what UIKit pattern**: ad-hoc `extensionFactor`/`progress` scattered across VC + canvas + cell.

---

## `Canvas` + `TimelineView` — iOS 15+
- **What**: low-level immediate-mode drawing (`Canvas` — Core Graphics-flavored draw closure) and per-frame redraw scheduling (`TimelineView` — schedules `Date`-stamped redraws at `.animation`, `.periodic(from:by:)`, or `.explicit(_:)`). (https://developer.apple.com/documentation/swiftui/canvas, https://developer.apple.com/documentation/swiftui/timelineview, WWDC21 #10021)
- **Strengths**: SwiftUI's escape hatch into custom rendering with the framework's render-loop integration. `TimelineView(.animation)` schedules at display refresh rate — equivalent to `CADisplayLink` without the boilerplate.
- **Limitations**: re-runs the draw closure each frame — not free. No layer-tree retention; everything redraws.
- **Composes with**: `.drawingGroup()` for Metal offload.
- **Apple's own use**: Weather lock-screen widget, Watch complications, Activity rings.
- **Replaces what UIKit pattern**: `AnimationController` + bespoke `CADisplayLink` masterTimer pattern (the prototype's `TimelineCanvas`).

---

## Spring physics — `.spring(duration:bounce:)` — iOS 17+
- **What**: spring API parameterized by perceptual `duration` and `bounce` (-1 = overdamped, 0 = critically damped, 1 = high bounce) instead of mass/stiffness/damping. (WWDC23 #10158 "Animate with springs")
- **Strengths**: designer-friendly params. Mid-flight retargeting preserves velocity automatically. Named presets `.smooth`, `.snappy`, `.bouncy` are tuned by Apple's HI team.
- **Limitations**: still a closed-form `Spring`; if you need a custom physical model (gravity, friction), drop to `Animatable` + `TimelineView`.
- **Cancellable**: yes — re-target via state mutation, velocity preserved.
- **Apple's own use**: Music expand, App Switcher dismiss, Photos drag-to-dismiss, every iOS 17+ Apple-shipped sheet.
- **UIKit-bridging cost**: SwiftUI-only API, but the prototype's `SpringAnimator<CGFloat>` is already the UIKit equivalent — same physics, less ergonomics.

---

## `UIViewRepresentable` / `UIHostingController` bridge — iOS 13+
- **What**: bidirectional bridge. `UIViewRepresentable` / `UIViewControllerRepresentable` wraps UIKit inside SwiftUI; `UIHostingController` hosts SwiftUI inside UIKit. (https://developer.apple.com/documentation/swiftui/uihostingcontroller, https://developer.apple.com/documentation/swiftui/uiviewrepresentable)
- **Strengths**: incremental adoption. Host one screen, one cell, one overlay — keep the rest UIKit. `UIHostingConfiguration` (iOS 16+) embeds SwiftUI inside `UICollectionViewListCell`. Sizing of `UIHostingController` is finally robust in iOS 16+ (`sizingOptions = [.intrinsicContentSize]`).
- **Limitations**: layout boundary — SwiftUI inside `UIHostingController` doesn't share the UIKit Auto Layout pass cleanly until the iOS 16 sizingOptions. Gesture conflicts at the bridge (SwiftUI gesture vs. parent UIPanGestureRecognizer) require manual `UIGestureRecognizerDelegate` plumbing. Hosting a SwiftUI view that uses `matchedGeometryEffect` only matches WITHIN the SwiftUI subtree — no cross-bridge geometry sync.
- **Composes with**: everything UIKit and everything SwiftUI, at the cost of a layout boundary per bridge.
- **Apple's own use**: Apple Music's Now Playing (SwiftUI inside a UIKit shell), Notes, Reminders, Find My, Health.
- **Bridge cost for revealChat**: the SwiftUI subtree would own `chatVC.view` + the blur overlay. Host once at the reveal layer; `PhaseAnimator` drives the choreography inside. UIKit pan/pinch on `TimelineCanvas` stays UIKit.

---

## Compositional pairings

The high-leverage compositions for THIS app:

- **`PhaseAnimator` + `.spring(duration:bounce:)`** — replaces `revealChat`'s delay chain with a phase machine where each phase uses a tuned spring. Cancellation = trigger re-fire.
- **`matchedGeometryEffect` + `withAnimation(.spring)`** — for the cell → chat hero. Source = TimelineCanvas cell, destination = ChatVC header. Both ends need to live in the same SwiftUI tree, which means the morph surface migrates to SwiftUI.
- **`KeyframeAnimator` + multiple `KeyframeTrack`s** — replaces TimelineCanvas's hand-rolled masterTimer when the choreography is designer-driven (scale + alpha + rotation on independent curves).
- **`@Observable` phase model + `.animation(_:value:)`** — gives the gauge's "no central animation phase model" blind spot a first-class home. Phase is a `@Observable` enum; views animate off it; UIKit code reads it via `withObservationTracking`.
- **`Canvas` + `TimelineView(.animation)`** — pure-SwiftUI substitute for `AnimationController` + `CADisplayLink` if the team commits to SwiftUI for the morph surface.
- **`SymbolEffect` + `SensoryFeedback`** — every symbol-bearing affordance in chat gets Apple-grade haptic+visual coordination with zero code.

---

## SwiftUI advantages over UIKit for THIS app's pain point

1. **Choreography is declarative.** `PhaseAnimator` replaces "manually-tuned delay: 0, 0.2, 0.5" with named phases. Re-timing a phase doesn't drift the others.
2. **Cancellation is free.** Re-firing the trigger or mutating state re-targets the animation with velocity preserved. The prototype's UIView.animate chain cannot be cancelled mid-flight without snapping.
3. **Hero transitions are a one-liner.** `matchedGeometryEffect` collapses ~200 lines of UIViewControllerAnimatedTransitioning + frame math into `.matchedGeometryEffect(id:, in:)` on each end.
4. **Animation phase becomes first-class state.** `@Observable` phase enum is the central model the gauge identifies as missing.
5. **Apple's named springs are HI-tuned.** `.smooth`/`.snappy`/`.bouncy` save the team from re-discovering Apple's perceptual curves.
6. **Symbol + haptic coordination is built in.** `SymbolEffect` + `SensoryFeedback` for free at every symbol affordance.

---

## What SwiftUI CANNOT do (for completeness)

- **Cross-bridge `matchedGeometryEffect`**: source in UIKit, destination in SwiftUI (or vice versa) does NOT match. Both ends must be in the same SwiftUI tree. iOS 18's `NavigationTransition.zoom` is the first crack at this and only works inside `NavigationStack`.
- **Pixel-perfect interruption of a `PhaseAnimator` mid-phase**: cancellation re-fires the trigger; mid-phase scrubbing requires value-driven animators (springs) instead.
- **`UIViewPropertyAnimator`-style fraction scrubbing on arbitrary properties**: SwiftUI has no first-class fractional scrubber. You re-implement via `@State` of `progress: Double` driven by a gesture, with `.animation(nil)` to suppress implicit animation.
- **Per-frame closure that mutates UIKit views**: SwiftUI render loop won't drive UIKit; you keep `CADisplayLink` for that.
- **Gesture-driven animation that crosses the SwiftUI/UIKit boundary**: pinch on a UIKit canvas driving a SwiftUI matchedGeometry hero requires manual progress plumbing.
- **Custom `CALayer` keypath animations**: SwiftUI doesn't expose layer-level animation. Drop to `UIViewRepresentable` to wrap a CALayer-bearing UIView.

---

## Direct answer: would a `UIHostingController`-bridged SwiftUI animation block REPLACE the `UIView.animate(delay:)` chain in `V2RootViewController.revealChat`?

**Yes — and it's the highest-leverage substitution available.** Concrete shape:

1. **Migrate the reveal surface to SwiftUI.** Replace `chatVC.view` add + blur overlay with a SwiftUI `RevealSurface` view hosted in a `UIHostingController`. UIKit owns `TimelineCanvas`; SwiftUI owns the reveal.
2. **Model phase as `@Observable`.** `enum RevealPhase { case hidden, blurring, chatVisible, blurFading }`. Held by a `@Observable RevealCoordinator`.
3. **`PhaseAnimator(values: RevealPhase.allCases, trigger: coordinator.phase)`** drives the choreography. Each phase gets its own `.animation(_:for:)` — `.smooth(duration: 0.3)` for the blur-in, `.smooth(duration: 0.3)` for the chat fade-in, `.easeInOut(duration: 0.7)` for the blur-fade-out.
4. **Cancellation**: mutating `coordinator.phase` mid-flight re-targets cleanly. The current UIView.animate chain cannot do this without snap.

**Tradeoffs**:
- **+ Choreography drift eliminated** (the original pain). Phase transitions dispatched on the render loop, not wall-clock `delay:`.
- **+ Cancellation works.** Re-fire the trigger to abort. Velocity preserved on spring phases.
- **+ Future hero transition unlocked.** `matchedGeometryEffect` between a SwiftUI canvas cell and ChatVC header becomes possible IF the cell migrates to SwiftUI too.
- **+ Apple-grade defaults.** `.smooth`/`.snappy` named springs replace hand-tuned curves.
- **− Layout boundary at `UIHostingController`.** Sizing + gesture handoff with the UIKit shell is one-time engineering pain — robust in iOS 16+ but a real cost.
- **− Bridge does NOT cross for `matchedGeometryEffect`.** Until the cell is also SwiftUI, no hero transition. Half-migration leaves you with two animation substrates instead of one.
- **− Team must internalize SwiftUI's reactive model.** "Animation IS state" is a paradigm shift from UIView.animate's imperative closures.
- **− `CADisplayLink`-driven `masterTimer` and `SpringAnimator<CGFloat>` stay UIKit-side** unless the morph surface also migrates. Mixed-substrate state persists through partial migration.

**Verdict**: the reveal chain is the right place to start a SwiftUI migration — small, self-contained, no cross-substrate state, directly demonstrates the cancellation + non-drift wins. The morph (TimelineCanvas + SpringAnimator) is the harder migration and should follow only after the team has paid the hosting-bridge tax once.
