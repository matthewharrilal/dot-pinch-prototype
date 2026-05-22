# NINETY — Apple system apps
# Intention 3 — peer rebuild
POSTURE: janum

Apple's system apps are the canonical 90% reference: the surface UIKit ships publicly is the same vocabulary an Apple framework engineer uses, but Apple's internal apps compose those primitives under rules largely tacit — encoded in WWDC architecture talks, HIG (Motion), and private internals (`_UIVisualEffectBackdropView`, `_UIPreviewInteractionController`, `UISystemGestureGate`). This file reverse-engineers seven of Apple's most visible animation surfaces.

---

## App: Apple Music

### Observable animations
- Mini-player → Now-Playing card: artwork is the **anchor** — physically translates + scales from mini-bar to centered hero. No cross-fade. Corner radius animates continuously (~12pt → ~6pt at peak, settles ~10pt).
- Background blur ramps **continuously** lock-step with card position — never stepped.
- Chrome (title, artist, scrubber, transport row) **cascades in**: each fades + rises ~8pt with ~16–24ms stagger, all driven from one master progress.
- Interruptible: mid-expand, a downward drag retargets immediately. Card reverses with **preserved velocity**, no jump.
- Dismiss is symmetric: percent-driven by pan; above-velocity-threshold completes, below settles back; artwork lands in mini-bar with sub-pixel registration.

### Likely primitives + architecture
- `UIViewPropertyAnimator` with `UISpringTimingParameters` is the master clock. `fractionComplete` = single source of truth.
- `UIPercentDrivenInteractiveTransition` subclass bridges pan → `fractionComplete`.
- `UIViewControllerAnimatedTransitioning` + `UIViewControllerTransitioningDelegate` for the container-managed `.custom` presentation.
- Artwork hero: matched-geometry by hand — real artwork view reparented to `transitionContext.containerView`, restored in `animationEnded(_:)`. Destination uses a stand-in.
- Blur: `UIViewPropertyAnimator.addAnimations { effectView.effect = blur }` — the only public API path that **interpolates** UIBlurEffects.
- Chrome cascade: ONE animator with N `addAnimations(_:, delayFactor:)` calls. Not separate animators.

### 90% rules encoded
1. **Single master clock, many participants.** One `fractionComplete`, N `addAnimations(_:, delayFactor:)`. Never two animators racing.
2. **Velocity-preserving retarget.** `animator.isReversed.toggle()` + `continueAnimation(withTimingParameters:durationFactor:)` carries spring physics through interruption.
3. **Reparent, don't duplicate.** Same UIView crosses VCs via `containerView`.
4. **Parametric blur is continuous.** Only UIViewPropertyAnimator interpolates UIBlurEffect — architecture-shaping constraint.
5. **Cascade via delayFactor, not chained delays.** Stagger lives in animator API, never `DispatchQueue.main.asyncAfter`.

### Citations
- WWDC 2017 #230 "Advanced Animations with UIKit" — Lewis & Hyrkas. The reference talk on UIViewPropertyAnimator, interruptibility, retargeting.
- WWDC 2018 #803 "Designing Fluid Interfaces" — Karunamuni. Velocity preservation + handoff principles.
- WWDC 2016 #216 "Advances in UIKit Animations and Transitions" — original property-animator introduction.

---

## App: SpringBoard / App Switcher

### Observable animations
- App launch: icon **expands** outward, masked into rounded-rect that grows to fill screen. Corner radius animates icon-radius (~13.5pt at 60pt icon) → device corner radius (~47–55pt).
- Swipe-up-from-home-indicator: any frame in launch is reversible — release at 30% reverses to icon with carried velocity.
- App Switcher: cards arc with perspective transform, ~8% screen-width spacing, parallax on horizontal drag.
- Home indicator arbitrates scroll / drag-to-switcher / swipe-to-home using **velocity + position**, not position alone.

### Likely primitives + architecture
- Internally SpringBoard uses private `BSAnimationSettings` / `BKSAnimation`. Public-API analog: `UIViewPropertyAnimator` + `UISpringTimingParameters(initialVelocity:)`.
- Gesture decision tree: state machine with simultaneous-recognition, owning current "intent" classification — not branching ifs.
- Corner radius: `CABasicAnimation` on `cornerRadius` keypath, with `layer.cornerCurve = .continuous` (iOS 13+).
- iOS 18+ exposes a public analog: `UIZoomTransitionOptions` — likely the canonical 10% expression of this 90% internal.

### 90% rules encoded
1. **Every animation is interruptible.** Prime directive since iOS 11 (Karunamuni: "you can't predict what the user will do next").
2. **Velocity is a first-class input.** Spring params derived from `UIPanGestureRecognizer.velocity(in:)` → `CGVector` for `UISpringTimingParameters`.
3. **Continuous corners.** `cornerCurve = .continuous` — squircle, not circular arc.
4. **Gesture arbitration is state-machine, not branch.** One coordinator owns "what is the user doing right now."
5. **Layer-level animation under view-level orchestration.** `CAAnimation`s composed under a higher coordinator.

### Citations
- WWDC 2018 #803 "Designing Fluid Interfaces" — Karunamuni. THE canonical talk; live demo of interruptible app launch + velocity-preserved home indicator IS this app.
- WWDC 2018 #228 "Advanced Animations & Effects with Cocoa Animation" — Mac analog, same Core Animation substrate.

---

## App: Apple Photos

### Observable animations
- Tap thumbnail → photo zooms from grid frame to full-screen; surrounding cells gently parallax away.
- Swipe-down-dismiss: photo follows finger 1:1, scales + corner-radius proportional to drag, background dims continuously. Release velocity-classified.
- Memories tab: Ken Burns slow zoom + crossfade, music-tempo-locked cuts (likely AVPlayer time observers driving alpha/transform).

### Likely primitives + architecture
- `UIViewControllerInteractiveTransitioning` + `UIViewControllerAnimatedTransitioning` pair.
- `UIPercentDrivenInteractiveTransition` for interactive dismissal.
- Custom animator using `UIViewPropertyAnimator` internally — pause/resume/reverse for free.
- Hero photo reparented into `containerView`; destination cell hidden until `animationEnded(_:)`.
- Background dim: black `UIView`, alpha = `transitionContext.percentComplete`.

### 90% rules encoded
1. **Interactive transitions ARE the dismissal.** Tap-to-dismiss is a degenerate case of the interactive path, not separate animation. One implementation, two entry points.
2. **PercentComplete drives EVERYTHING.** Dim, scale, corner radius, parallax — all functions of one Float.
3. **Hide-the-destination during transition.** Grid cell hidden while photo in flight; un-hidden in `animationEnded(_:)`. Otherwise you see two of the same image.

### Citations
- WWDC 2013 #218 "Custom Transitions Using View Controllers" — Bruce Nilo. Foundational.
- WWDC 2014 #214 "View Controller Advancements in iOS 8".
- WWDC 2017 #230 "Advanced Animations with UIKit" — property-animator-inside-transition pattern.

---

## App: Apple Notes

### Observable animations
- Magic-plus: `+` glyph morphs with SF Symbol `.replace` effect (iOS 17+).
- List reorder: long-press lifts row (`scaledBy(1.04)` + shadow); other rows slide.
- Quick-jot: bottom-sheet slide-up with soft spring, partial detent, drag-dismiss with rubber-band at extremes.

### Likely primitives + architecture
- `UISheetPresentationController` (iOS 15+) with custom detents for quick-jot.
- `UITableView`/`UICollectionView` reorder built-ins, layered with `UIViewPropertyAnimator` for lift.
- iOS 17 `addSymbolEffect(_:)` API (`.bounce`, `.replace`, `.scale`, `.appear`).
- Quiet motion: damping ratios 0.85–0.95, no overshoot.

### 90% rules encoded
1. **Restraint is a value system.** Notes never draws attention with motion — motion clarifies state, period.
2. **Symbol effects are the new micro-animation surface.** iOS 17's `addSymbolEffect(_:)` replaces hand-rolled glyph crossfades.
3. **Sheet detents are state, not animation.** Animate the model; view follows.

### Citations
- WWDC 2023 #10157 "Animate symbols in your app".
- WWDC 2021 #10063 "Customize and resize sheets in UIKit".

---

## App: Apple Mail (iOS 16+)

### Observable animations
- Compose card: slides up with spring; corner radius 0 → 13pt; underlying list dims + scales 0.92.
- Swipe-to-delete: row tracks finger 1:1 until threshold, then spring-snaps. Action reveal **proportional** to swipe distance, not discrete.
- Drag-to-folder: `UIDragInteraction`; drop target highlights with inset + tint; row collapses with height-animated deletion on drop.

### Likely primitives + architecture
- Compose: `UISheetPresentationController`, `.pageSheet` on iPhone.
- Swipe actions: `UISwipeActionsConfiguration` (iOS 11+) — proportional reveal for free.
- Drag/drop: `UIDragInteraction` + `UIDropInteraction` with custom preview parameters.

### 90% rules encoded
1. **Use system gestures.** `UISwipeActionsConfiguration` over hand-rolled pan — Apple uses public API because proportional reveal + haptics + a11y are baked in.
2. **Drag is physical.** Velocity matters; invalid-drop preview spring-returns to source.
3. **Card presentations are sheets, not transitions.** Compose is a detented sheet, not a custom transition.

### Citations
- WWDC 2017 #223 "Drag and Drop with Collection and Table Views".
- WWDC 2021 #10063 "Customize and resize sheets in UIKit".
- HIG: Motion — https://developer.apple.com/design/human-interface-guidelines/motion

---

## App: Apple Maps

### Observable animations
- Tap pin → place card slides up while map **simultaneously** blurs + pans + zooms so pin stays visible above card.
- Drag place card down → map un-blurs continuously, card slides, pin re-centers. Threshold-classified.
- Search transition: search field expands collapsed-inset → full-screen results, map blurs underneath.

### Likely primitives + architecture
- `UISheetPresentationController` with small/medium/large detents.
- `MKMapView.setCamera(_:animated:)` synchronized via `sheetPresentationController.animateChanges { }`.
- Continuous blur: `UIVisualEffectView` driven by a `UIViewPropertyAnimator` started then immediately `pauseAnimation()` — the documented "paused-animator-as-slider" trick.
- Sheet drag is master; map camera + blur are slaves to detent fraction.

### 90% rules encoded
1. **Parametric blur via paused property animator.** ONLY public-API path to a blur intensity slider. Document, reuse.
2. **One gesture, many followers.** Sheet pan drives map + blur + pin — never three independent handlers.
3. **Detents are perceptual snap points.** Users think "peek / half / full," not "presented/dismissed."

### Citations
- WWDC 2021 #10063 "Customize and resize sheets in UIKit".
- WWDC 2017 #237 "What's New in MapKit".
- WWDC 2017 #230 "Advanced Animations with UIKit" — paused-animator-as-slider.

---

## App: iOS lock screen / Control Center / Notification Center

### Observable animations
- Pull-down rubber-band: position-following with progressively increasing resistance past threshold. Apple's documented function: `b = (1 - 1/(x*c/d + 1)) * d`, c≈0.55.
- Wallpaper parametric blur: continuous, lock-step with pull.
- Notification card dismissal: swipe with spring.

### Likely primitives + architecture
- SpringBoard internals (`SBChevronView`, `SBHomeAffordanceView`). Public analog: rubber-band function on `UIPanGestureRecognizer.translation`; blur via paused property animator; card dismissal via `UIPercentDrivenInteractiveTransition`.

### 90% rules encoded
1. **Rubber-band is a documented function.** UIScrollView source. Implement once, reuse.
2. **Wallpaper blur is paused-animator.** Same pattern as Maps.
3. **System gestures > custom recognizers.** Lock-screen pull-down is `UIScreenEdgePanGestureRecognizer` semantically.

### Citations
- WWDC 2018 #803 "Designing Fluid Interfaces" — Karunamuni.
- WWDC 2010 #104 "Designing Apps with Scroll Views" — rubber-band math.

---

## Apple's documented design philosophy

### Chan Karunamuni's "Designing Fluid Interfaces" (WWDC 2018 #803) — principles

THE canonical Apple talk on animation coordination. Distilled:

1. **"An interface is fluid if it is fast, responsive, and natural."** Fluidity is not aesthetic — it is a measurable property of the coordination architecture.
2. **"Every animation must be interruptible."** Once a user touches the screen, no animation in flight may override their input. This is the architectural constraint that forces single-master-clock design.
3. **"Velocity must be preserved through interruption."** When a user grabs an animating object, its current velocity becomes initial velocity of the new animation. `UISpringTimingParameters(dampingRatio:initialVelocity:)` is the public-API expression.
4. **"Use a single source of truth for animation progress."** SpringBoard uses one fraction across multiple participants (background blur, scale, alpha, position). No two animators racing.
5. **"Build for the gesture, not the result."** Design starts with the gesture (velocity, drag distance, finger position); destination is derived. Inverts the usual "animate from A to B" mental model.
6. **"Direct manipulation must be 1:1 until threshold."** Finger down = position follows finger exactly. Only on release does physics take over. This is why progress-pushed architectures dominate Apple's interactive transitions.
7. **"Soft thresholds, not hard ones."** State transitions are velocity + position combined. Fast flick at 20% completes; slow drag at 60% reverses.
8. **"Hide complexity behind a coordinator."** SpringBoard's app launch has dozens of layers/masks/timings, but user perception is one event. A coordinator marshals them.

---

## Cross-app pattern synthesis (Apple's animation ethos)

1. **One master clock per interaction.** `UIViewPropertyAnimator.fractionComplete` is Apple's preferred substrate. Multi-element cascades use `addAnimations(_:, delayFactor:)` on ONE animator.
2. **Interruptibility is default, not enhancement.** Every Apple transition since iOS 11 can be grabbed mid-flight. `UIPercentDrivenInteractiveTransition` + `UIViewPropertyAnimator` is the public-API pair.
3. **Velocity-preserving retarget.** `continueAnimation(withTimingParameters:durationFactor:)` — spring physics carry through interruption.
4. **Matched-geometry by reparenting.** Apple's hero transitions move the same UIView between VCs via `transitionContext.containerView`. Hide destination during flight; restore in `animationEnded(_:)`.
5. **Parametric blur via paused property animator.** Only public-API path to UIBlurEffect intensity slider:
   ```
   let a = UIViewPropertyAnimator(duration: 1, curve: .linear) {
       blurView.effect = UIBlurEffect(style: .systemMaterial)
   }
   a.pausesOnCompletion = true
   a.startAnimation(); a.pauseAnimation()
   // a.fractionComplete = 0...1 on demand
   ```
6. **Sheets over custom presentations where possible.** `UISheetPresentationController` gives interruptibility + detents + drag-dismiss + haptics for free.
7. **Continuous corners everywhere.** `layer.cornerCurve = .continuous` is the iOS visual signature.
8. **Symbol effects for glyph micro-animations.** iOS 17's `addSymbolEffect(_:)` replaces hand-rolled glyph transitions.

---

## Lessons transferable to DotPinchPrototype

Direct answer to: **what does Apple's pattern teach about replacing chained `UIView.animate(delay:)` with a coordinated approach?**

1. **Replace the three chained `UIView.animate(delay:)` blocks in `revealChat` with ONE `UIViewPropertyAnimator`.** Use `addAnimations(_:, delayFactor:)` for stagger:
   ```
   let animator = UIViewPropertyAnimator(duration: 1.0, dampingRatio: 0.85)
   animator.addAnimations({ /* stage 1 */ }, delayFactor: 0.0)
   animator.addAnimations({ /* stage 2 */ }, delayFactor: 0.2)
   animator.addAnimations({ /* stage 3 */ }, delayFactor: 0.5)
   animator.startAnimation()
   ```
   Apple-canonical replacement. One clock, one cancellation point, one `fractionComplete` to query.

2. **Promote masterTimer (or the property animator) to master clock for ALL morph + reveal.** Don't have THREE timing substrates (UIView.animate + masterTimer + spring). Pick one — property-animator — make everything else its participant.

3. **Make reveal interactively reversible.** Today it can't be cancelled mid-flight without snapping. `UIViewPropertyAnimator` gives `isReversed` + `continueAnimation(withTimingParameters:durationFactor:)` for free.

4. **Introduce one `AnimationCoordinator` owning the interaction state machine.** Not scattered across VC + canvas + cell. Coordinator holds animator(s), responds to gestures, classifies intent. SpringBoard pattern.

5. **Express the morph as percent-driven, then drive it with either a gesture OR a timed animator.** Apple Music does exactly this: expansion is a percent-driven transition whose driver is either `UIPercentDrivenInteractiveTransition` (gesture) or `UIViewPropertyAnimator` (non-interactive). Same code path, two drivers.

6. **Use `UISpringTimingParameters(dampingRatio:initialVelocity:)` for the dot pinch's snap-back.** Pass gesture velocity directly. Velocity-preserving rule.

7. **Animate corner radius via `CABasicAnimation` on `cornerRadius` keypath with `cornerCurve = .continuous`, synchronized to master animator.** Apple Music's artwork radius animation is exactly this.

---

## Frontiers

- Does Apple Music's expansion use ONE `UIViewPropertyAnimator` or a coordinated pair? Chrome cascade could be a second animator phase-locked to the first. Instruments → Animation Hitches frame capture would resolve.
- Exact damping ratios: cards (~0.85–0.92 est.) vs sheets (~0.95) vs hero (~0.8) are tacit. WWDC gives ranges, not values. Empirical capture from paused simulator + measurement is the only path.
- `_UIVisualEffectBackdropView` private internals: does Apple use it for Maps blur slider, or pure `UIVisualEffectView` + paused-animator? Suspect the latter publicly, former internally.
- Symbol effect (`.replace`, `.bounce`) underlying spring parameters are not public — iOS 17+ exposes API but values are Apple-tuned.
- How does Apple Music handle full-screen-dismiss WHILE music transport auto-advances mid-dismissal? Suspect a state machine above the animation coordinator queueing model changes during transitions.
- iOS 18+ `UIZoomTransitionOptions` may be the public expression of SpringBoard's app-launch zoom. If so, it is the canonical 10% expression of that 90% internal — adopt directly.
