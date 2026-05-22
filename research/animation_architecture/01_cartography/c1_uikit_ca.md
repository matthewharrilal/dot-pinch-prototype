# CARTOGRAPHY — UIKit native + Core Animation primitives
POSTURE: janum

Scope: the full menu of UIKit + Core Animation primitives a senior staff iOS engineer would put on the table when designing a Tier-3B animation architecture. Read-only enumeration; composition decisions live downstream.

---

## UIView.animate(withDuration:animations:) — iOS 4+
- What: simplest implicit animation, animates animatable UIView properties (frame, bounds, center, transform, alpha, backgroundColor, etc.) with default ease-in-out curve.
- Strengths: one-liner, ideal for trivial fades and slides. Coalesces multiple property changes into one CATransaction implicitly.
- Limitations: no curve control, no spring, no completion handler, no delay; cannot be cancelled cleanly mid-flight (only by starting a new animation on same properties with `.beginFromCurrentState`).
- Cancellable / pausable / reversible: cancel: indirect (start new anim with `.beginFromCurrentState`). Pause: no. Reverse: no.
- Composes with: CATransaction (wraps it), other UIView.animate calls (overlap on different properties).
- Apple's own use: trivial keyboard fades, alpha toggles in stock UI.
- When to choose this over alternatives: only for fire-and-forget one-shot animations with no interruption requirement. Never for the dot-pinch morph chain.

## UIView.animate(withDuration:delay:options:animations:completion:) — iOS 4+
- What: the workhorse. Adds delay, UIViewAnimationOptions bitmask, completion block.
- Strengths: completion callback enables sequential chaining. Options control curve (`.curveEaseIn/Out/Linear/EaseInOut`), repeat, autoreverse, interaction (`.allowUserInteraction`), state-merging (`.beginFromCurrentState`), layer keyframe transitions.
- Limitations: delay-based chaining (what the user already calls brittle) is the canonical footgun — re-entrancy, missed completions, bandwidth contention all break it. Curves are limited to four presets unless you wrap in CATransaction with a custom CAMediaTimingFunction.
- Cancellable / pausable / reversible: cancel: only by starting a fresh anim with `.beginFromCurrentState` on the same property. Pause: no. Reverse: no.
- Composes with: CATransaction, CAAnimation (concurrently on different keypaths), nested UIView.animate (footgun: inner animation inherits outer's duration if `.overrideInheritedDuration` is omitted).
- Apple's own use: most pre-iOS-10 system UI animations (alert presentations pre-redesign, basic transitions).
- When to choose this over alternatives: throwaway one-shots only. The `delay:` parameter is the source of the user's brittleness complaint — it's an absolute timeline offset, not a dependency on the prior block finishing. If the prior block runs long for any reason, the next one fires anyway.
- Reference: https://developer.apple.com/documentation/uikit/uiview/1622451-animate

## UIView.animate(withDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:) — iOS 7+
- What: damped-spring variant. `dampingRatio` 0-1 (1 = critically damped, no oscillation), `initialSpringVelocity` in property-units/sec normalized by total displacement.
- Strengths: physically plausible motion, used everywhere in stock iOS. Velocity input enables gesture handoff (final pan velocity → spring initial velocity).
- Limitations: still time-bounded by `withDuration:` rather than physics-determined settle time — fights its own physics if duration < natural settle. Velocity normalization is non-obvious. Not interruptible without `.beginFromCurrentState`.
- Cancellable / pausable / reversible: cancel: same as above. Pause: no. Reverse: no.
- Composes with: same as standard UIView.animate. NOT swap-compatible with CASpringAnimation timing-wise (different math).
- Apple's own use: notification banners, control-center pull, ancient incarnations of the home-screen icon wiggle.
- When to choose this over alternatives: spring motion where you don't need interruption. For the camera/extension path the user already has SpringAnimator — keep that, don't regress to this.

## UIView.transition(with:duration:options:animations:completion:) / transition(from:to:) — iOS 4+
- What: cross-fades / flips between two view states via `.transitionCrossDissolve`, `.transitionFlipFromLeft/Right`, `.transitionCurlUp/Down`. The `from:to:` variant swaps view hierarchy.
- Strengths: cheap snapshot-based crossfade without manual snapshot management.
- Limitations: hardcoded transition options; cannot scrub. Implements via private snapshot — you don't get the snapshot view.
- Cancellable / pausable / reversible: no.
- Composes with: nothing dynamic. It's a sealed transition.
- Apple's own use: legacy modal flips, page-curl reader app.
- When to choose this over alternatives: text label content swap (`UIView.transition(with: label, ...) { label.text = ... }`). Useful for the chat-row text replacement step if you want a clean dissolve without managing two labels.

## UIView.animateKeyframes(withDuration:delay:options:animations:completion:) + addKeyframe(withRelativeStartTime:relativeDuration:animations:) — iOS 7+
- What: multi-stage animation expressed as fractional timeline keyframes (`0.0`...`1.0`).
- Strengths: declarative timeline replaces nested completion-block hell. `.calculationModeLinear/Discrete/Paced/Cubic/CubicPaced` controls interpolation between keyframes.
- Limitations: still time-bounded, still hard to interrupt. No per-keyframe easing curve (only one global calculation mode). No physics. Each keyframe inherits the outer animation's `.allowUserInteraction` only if you set `.allowUserInteraction` on the outer call.
- Cancellable / pausable / reversible: no (only via `.beginFromCurrentState` on a replacement).
- Composes with: CATransaction wrapper for custom timing function on the whole thing.
- Apple's own use: Apple Music album-art transitions, some Keynote build-ins.
- When to choose this over alternatives: a replacement for the current three-block `delay:`-chained `revealChat`. Single keyframe call expresses "fade out (0→0.2), morph (0.2→0.7), fade in (0.5→1.0)" without delay arithmetic. Still not interruptible — for that, jump to UIViewPropertyAnimator.

## UIViewPropertyAnimator — iOS 10+
- What: object-based animator. `addAnimations { }`, `startAnimation()`, `pauseAnimation()`, `stopAnimation(_:)`, `finishAnimation(at:)`, `continueAnimation(withTimingParameters:durationFactor:)`. Has `fractionComplete` settable property for scrubbing. Init with `UICubicTimingParameters` or `UISpringTimingParameters(dampingRatio:initialVelocity:)`. State machine: `.inactive` → `.active` → `.stopped`.
- Strengths: THE canonical interruptible animator. Holdable mid-flight (pause), scrubbable by setting `fractionComplete` (e.g. from a UIPanGestureRecognizer), and `continueAnimation` lets you hand control back to physics with new timing parameters (think: drag to dismiss, release halfway → either complete or reverse based on velocity). `isManualHitTestingEnabled`, `isUserInteractionEnabled`. `addCompletion { position in ... }` gives `.start`, `.end`, `.current`.
- Limitations: only animates animatable UIView properties — not arbitrary CALayer keypaths (use CAAnimation for those). Spring physics is via `UISpringTimingParameters` — solid but not as expressive as a hand-rolled spring (e.g. RBBAnimation / CASpringAnimation with mass/stiffness/damping triplets). `fractionComplete` interpolates linearly across the curve internally, so non-linear curves under scrubbing can feel inconsistent — Apple's guidance is to use `UISpringTimingParameters` with damping ratio 1.0 for predictable scrub. Single-shot — once `.stopped`, the animator is unusable; you must build a new one. Order matters: add animations BEFORE `startAnimation` (or use `addAnimations` after start carefully — durations sub-divide).
- Cancellable / pausable / reversible: YES across all three. `isReversed = true` reverses direction mid-flight. `pauseAnimation` then `startAnimation` resumes.
- Composes with: UIPercentDrivenInteractiveTransition (the canonical hero pattern), CADisplayLink (drive `fractionComplete` per frame), gesture recognizers (most common pairing). Multiple property animators can run concurrently on different views, all individually scrubbable.
- Apple's own use: iOS 10+ Notification Center pull, Control Center reveal, sheet drag-to-dismiss (`UISheetPresentationController` interactive dismissal), Photos zoom dismiss.
- When to choose this over alternatives: anytime the animation MUST be interruptible or scrubbable. For the dot-pinch morph: this is the primitive that solves the "brittle / bandwidth needed" problem — pause when keyboard intervenes, resume when ready, scrub on rejection gesture.
- References: https://developer.apple.com/documentation/uikit/uiviewpropertyanimator ; WWDC 2016 session 216 "Advances in UIKit Animations and Transitions".

## UIViewControllerAnimatedTransitioning + UIViewControllerInteractiveTransitioning — iOS 7+
- What: protocol for custom VC presentation/dismissal animations. `animateTransition(using:)` receives a `UIViewControllerContextTransitioning` with `containerView`, `fromVC`, `toVC`. For interactive: `UIPercentDrivenInteractiveTransition` (iOS 7+) or a fully custom class implementing the protocol. iOS 10+ adds `interruptibleAnimator(using:)` returning a `UIViewImplicitlyAnimating` (UIViewPropertyAnimator conforms) so the system can interrupt and reverse your transition automatically.
- Strengths: the way to do hero transitions, swipe-to-dismiss, drag-down sheets. `interruptibleAnimator` is the ONE Apple-grade interruption point — return a UIViewPropertyAnimator and iOS will scrub/reverse it for free.
- Limitations: lots of boilerplate; the `containerView` is yours to populate (snapshots, etc.); orientation changes mid-transition are tricky. Auto Layout in the middle of a transition is famously fragile (use CGAffineTransform, not frame, where possible).
- Cancellable / pausable / reversible: YES — that's the whole point of `interruptibleAnimator`. Reversible via UIPercentDrivenInteractiveTransition.cancel().
- Composes with: UIViewPropertyAnimator (the modern animator engine), UIPanGestureRecognizer (drives `update(_:)`), UINavigationController/UITabBarController via delegate hooks, UIPresentationController for the presentation chrome.
- Apple's own use: every UINavigationController push, every modal presentation, Photos zoom-to-detail, Files large-thumbnail expand.
- When to choose this over alternatives: cross-VC animations where source and destination live in different containers. If the chat-view is presented modally over the dot-canvas, this is the primitive that lets the morph become the transition itself.
- Reference: https://developer.apple.com/documentation/uikit/uiviewcontrolleranimatedtransitioning ; WWDC 2013 session 218.

## CABasicAnimation — iOS 2+ (already in project)
- What: layer-level animation of a single CAAnimatableProperty keypath between `fromValue` and `toValue` (or `byValue`).
- Strengths: animates anything CALayer exposes — including properties UIView doesn't (path on CAShapeLayer, strokeStart/strokeEnd, lineWidth, shadowPath, contents). Combined with `additive = true` lets you stack multiple animations on the same keypath (e.g., two concurrent translations summed). `isRemovedOnCompletion = false` + `fillMode = .forwards` preserves end state (with the well-known caveat that you should set the model value to the toValue manually to avoid the layer snapping back if the animation is removed for any reason).
- Limitations: animates the PRESENTATION layer, not the model. If you don't update the model layer, the property snaps back when the animation completes (the "fillMode .forwards / removedOnCompletion = false anti-pattern" — works but breaks hit testing, layout, and re-entry). Default `timingFunction` is linear when added via `add(_:forKey:)` (unlike UIView.animate which is ease-in-out by default) — common footgun.
- Cancellable / pausable / reversible: cancel: `removeAnimation(forKey:)` snaps to model value; to cancel-in-place use `layer.presentation()` to read current presentation value and write to model. Pause: via CATransaction trick (set `speed = 0`, `timeOffset = currentTime`). Reverse: set `autoreverses = true` for full ping-pong, or build a reversed CABasicAnimation manually.
- Composes with: CAAnimationGroup (parallel), CATransaction (timing scope), other CAAnimations on the same layer at different keys, UIView.animate (concurrently on different layers).
- Apple's own use: CAShapeLayer path/stroke animations throughout Health, Activity rings (additive stacked strokeEnd animations), checkmark draw-on in Reminders.
- When to choose this over alternatives: any layer-only property (path, strokeStart/End, shadowPath, mask). The TimelineCanvas uses these correctly; the question is whether the higher-level driver should stay CADisplayLink-bespoke or move to UIViewPropertyAnimator + CATransaction.

## CAKeyframeAnimation — iOS 2+
- What: animate a keypath along an arbitrary array of `values` (and optional `keyTimes`, per-segment `timingFunctions`), OR along a CGPath.
- Strengths: arbitrary non-linear paths (motion along a Bezier curve), arbitrary value sequences for non-numeric properties (color cycling, content swap sequences). Per-segment `timingFunctions` for differing ease in each segment — the only built-in primitive that allows this.
- Limitations: more verbose to set up than CABasicAnimation. `calculationMode` (`.linear / .discrete / .paced / .cubic / .cubicPaced`) interaction with `keyTimes` is non-obvious — paced ignores keyTimes.
- Cancellable / pausable / reversible: same semantics as CABasicAnimation.
- Composes with: CAAnimationGroup, path follow + rotation (`rotationMode = .auto` makes the layer's anchor heading follow the tangent of the CGPath — useful for orbiting dots).
- Apple's own use: Find My device-icon orbit, App Store badge bounce-in keyframes, throbbing recording dot in Voice Memos.
- When to choose this over alternatives: motion along an arbitrary path (which a dot-pinch morph absolutely could be), or any animation needing per-segment timing functions without resorting to a custom driver.

## CASpringAnimation — iOS 9+
- What: subclass of CABasicAnimation with `mass`, `stiffness`, `damping`, `initialVelocity`. `settlingDuration` is computed for you — use it to set the animation `duration` so the spring actually settles within the animation lifetime.
- Strengths: physically grounded triplet (mass/stiffness/damping is the ODE form, not the synthetic damping-ratio/velocity form of UIView's iOS 7 spring) — more expressive and matches typical spring libs. `settlingDuration` is the magic accessor that fixes the "duration < settle" issue UIView springs have.
- Limitations: still removed on completion by default; same model-vs-presentation footgun. No mid-flight stiffness change (spring physics is set at animation creation).
- Cancellable / pausable / reversible: same CABasicAnimation semantics. Not natively interruptible — for that, your existing SpringAnimator<CGFloat> (manual ODE step in displayLink) is strictly more powerful.
- Composes with: CAAnimationGroup (with care — group duration overrides), CATransaction.
- Apple's own use: rumored in many places but Apple isn't explicit; the API was introduced for general-purpose spring layer animation in iOS 9. UIDynamicAnimator's attachment behavior uses similar math.
- When to choose this over alternatives: a layer-keypath spring (e.g., shadowOpacity, shadowRadius, gradient stops on a CAGradientLayer) where you don't need interruption. For interruptible springs the project's existing SpringAnimator stays the right tool.

## CAAnimationGroup — iOS 2+
- What: composite of multiple CAAnimations played in parallel on one layer, with shared `duration`, `beginTime`, `timingFunction`, `repeatCount`.
- Strengths: package multiple keypath animations under one logical animation; group-level removal cleans them all up.
- Limitations: group duration TRUNCATES child animations — a child with duration 1.0 inside a group with duration 0.5 stops at the group's 0.5 mark. Footgun. Children share the group's begin time (offsets baked in via child `beginTime` relative to group).
- Cancellable / pausable / reversible: removed as a unit via the group's key.
- Composes with: nested under CATransaction; sibling to other animations on the same layer.
- Apple's own use: shape-layer drawing sequences (path + strokeEnd + fillColor together) in Health, Watch faces (in their iOS-side previews).
- When to choose this over alternatives: when several related keypaths must remove together and share lifecycle.

## CATransition — iOS 2+ (legacy but supported)
- What: layer-level transition: `.fade`, `.moveIn`, `.push`, `.reveal`, with `subtype` (`.fromLeft`, etc.).
- Strengths: applies a transition to layer content (`contents` property of a CALayer) on next setting.
- Limitations: limited preset palette; private filters (`cube`, `suckEffect`, `rippleEffect`) work on iOS but are private and rejection-risk. Outdated aesthetic.
- Cancellable / pausable / reversible: no.
- Composes with: CATransaction.
- Apple's own use: legacy; UIView.transition is the modern wrapper.
- When to choose this over alternatives: rarely. Prefer UIView.transition or a UIViewPropertyAnimator-driven crossfade.

## CAPropertyAnimation (base class) — iOS 2+
- What: shared base for CABasicAnimation, CAKeyframeAnimation, CASpringAnimation. Carries `keyPath`, `isAdditive`, `isCumulative`, `valueFunction`.
- Strengths: `isAdditive = true` + multiple concurrent animations on the SAME keypath = the animations sum. This is the secret sauce behind the iOS app-icon jiggle, Activity ring stacking, scrubbing wheels — concurrent additive translations / rotations compose naturally without manual math. `isCumulative` accumulates each repeat onto the prior cycle (e.g. continuous rotation).
- Strengths (cont.): `valueFunction = CAValueFunction(name: .rotateX/Y/Z)` lets you animate `transform` as a single rotation around an axis without quaternion math.
- Limitations: not used directly; subclass it.
- Cancellable / pausable / reversible: subclass semantics.
- Composes with: itself, with `isAdditive = true` (the canonical compositional layer animation pattern).
- Apple's own use: see above — additive is everywhere in stock UI.
- When to choose this over alternatives: any time multiple time-overlapping animations should sum on the same keypath without manual blending. For the morph + simultaneous gesture nudge, this is the right model.

## CADisplayLink + CADisplayLink.preferredFrameRateRange — iOS 3.1+ / iOS 15+ (FrameRateRange)
- What: per-frame callback synchronized with display refresh. iOS 15+ adds `preferredFrameRateRange` (`CAFrameRateRange(minimum:maximum:preferred:)`) which on ProMotion devices opts you up to 120Hz.
- Strengths: the only way to drive frame-accurate manual animation (your existing `masterTimer`). Frame budget control on ProMotion. Synchronizes with CATransaction commits so reads of `layer.presentation()` are coherent.
- Limitations: you're responsible for everything — easing, interruption, completion. Default on ProMotion is 60Hz; you MUST set `preferredFrameRateRange` to opt into 120Hz, otherwise your hand-driven animations look choppy next to system animations. Easy to leak a strong reference (use a weak proxy wrapper — `CADisplayLinkProxy` pattern — or `add(to: .main, forMode: .common)` plus invalidate-on-VC-dealloc discipline).
- Cancellable / pausable / reversible: yes, via `isPaused` and `invalidate()`.
- Composes with: nothing animation-wise — it IS the substrate. Composes with UIViewPropertyAnimator by driving `fractionComplete` per frame.
- Apple's own use: ScrollView momentum, UIPageViewController interactive paging, anywhere physics-needs-per-frame-update.
- When to choose this over alternatives: keep for bespoke timelines (the morph) IF you need frame-accurate compositing of N independent layers. Otherwise prefer UIViewPropertyAnimator. Always set `preferredFrameRateRange = CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120)` on ProMotion devices.
- Reference: https://developer.apple.com/documentation/quartzcore/cadisplaylink ; WWDC 2021 session 10147 "Optimize for variable refresh rate displays".

## CATransaction — iOS 2+
- What: scopes a batch of layer changes. `begin()` / `commit()` brackets. `setAnimationDuration`, `setAnimationTimingFunction`, `setDisableActions(true)` to suppress implicit animations, `setCompletionBlock`.
- Strengths: the ONLY way to give UIView.animate a custom CAMediaTimingFunction. `setDisableActions(true)` is the silent-update pattern for layer property changes that should not animate. `setCompletionBlock` fires when the implicit animations under the scope complete.
- Limitations: `setCompletionBlock` fires when implicit anims complete — explicit added CAAnimations don't always trigger it predictably (use CAAnimationDelegate / animationDidStop for those). Nested transactions inherit from parent unless you set explicitly.
- Cancellable / pausable / reversible: not in itself; the animations inside it inherit their own cancellability.
- Composes with: every other CA primitive (transactions wrap them), UIView.animate (a UIView.animate block IS a CATransaction internally — you can use CATransaction.setAnimationTimingFunction at the top of a UIView.animate block to override the curve).
- Apple's own use: pervasive — every UIView property change creates an implicit transaction.
- When to choose this over alternatives: custom curve in a UIView.animate block, suppressing implicit animations on layer property changes (e.g. resizing a CAShapeLayer's bounds without it animating), or grouped completion callback.

## UIDynamicAnimator + UIDynamicBehavior subclasses — iOS 7+
- What: 2D physics engine: `UIGravityBehavior`, `UICollisionBehavior`, `UIAttachmentBehavior`, `UISnapBehavior`, `UIPushBehavior`, `UIDynamicItemBehavior` (mass, friction, resistance), `UIFieldBehavior` (iOS 9+, gravity wells / noise fields).
- Strengths: emergent physics for stacks of items (Messages bubble pile, Stocks card flick-to-dismiss). Behaviors compose by adding multiple to the same animator.
- Limitations: heavy; doesn't compose cleanly with CAAnimation on the same view (UIDynamics writes to `center` and `transform` directly each frame); not interruptible in a scrubbable sense. Performance: each item × each behavior adds cost. Largely superseded by Property Animator + manual physics for app UI.
- Cancellable / pausable / reversible: removeBehavior / removeAllBehaviors stops it. No reverse.
- Composes with: poorly with CAAnimation on same view; well with itself (multiple behaviors).
- Apple's own use: Messages bubble physics (iOS 7-era), Stocks list flick.
- When to choose this over alternatives: piles of items reacting to each other (collisions). Almost never for the dot-pinch morph — it's a single coordinated motion, not emergent.

## UIView snapshotView(afterScreenUpdates:) / drawHierarchy(in:afterScreenUpdates:) — iOS 7+
- What: take a UIView snapshot — either a lightweight UIView (snapshotView) backed by a private portal, or a rendered UIImage (drawHierarchy).
- Strengths: the building block of every hero transition. Snapshot the source view, animate the snapshot's frame across the screen, hide the source, reveal the destination, swap snapshot for destination at the end. `_UIPortalView` (private) is what `snapshotView(afterScreenUpdates:)` returns — it's a live mirror of the source layer tree, NOT a static image, so animations on the source continue to show through the snapshot.
- Limitations: `afterScreenUpdates: true` forces a synchronous layout pass — expensive; use `false` if the view is already current. drawHierarchy is slower (full rasterization) but works for views off-screen.
- Cancellable / pausable / reversible: the snapshots themselves are static; the animation driving them is whatever you pick.
- Composes with: UIViewPropertyAnimator + UIViewControllerAnimatedTransitioning (the canonical hero pattern). matchedGeometryEffect (SwiftUI) is the equivalent abstraction.
- Apple's own use: every Photos zoom-to-detail, every App Store card expand, Files icon-to-preview.
- When to choose this over alternatives: cross-view-controller motion where source and destination both must exist visually during transit.

## UIView.modifyAnimations(withRepeatCount:autoreverses:animations:) — iOS 13+
- What: wraps a UIView.animate (or CAAnimation) closure so the contained animations get a `repeatCount` and `autoreverses` applied — works inside UIViewPropertyAnimator and UIView.animate blocks.
- Strengths: the only documented way to add repeat/autoreverse to a UIViewPropertyAnimator-managed animation.
- Limitations: must be nested INSIDE the animator's addAnimations block. Niche.
- Cancellable / pausable / reversible: inherits the wrapping animator's semantics.
- Composes with: UIViewPropertyAnimator (its primary use).
- Apple's own use: stock indicator pulses inside iOS 13+ animators.
- When to choose this over alternatives: looping pulses inside a UIViewPropertyAnimator.

## Symbol effects: UIImageView.addSymbolEffect / setSymbolImage(_:contentTransition:options:) — iOS 17+
- What: animate SF Symbols. Effects: `.bounce`, `.pulse`, `.variableColor`, `.scale`, `.appear`, `.disappear`, `.replace`. `contentTransition` for swap between symbols (`.replace.downUp`, `.automatic`).
- Strengths: built-in symbol motion, GPU-accelerated, accessibility-aware (respects Reduce Motion automatically). `.repeating`, `.nonRepeating`. `byLayer` / `wholeSymbol` controls granularity.
- Limitations: only SF Symbols (UIImage with `symbolConfiguration`). No custom curves.
- Cancellable / pausable / reversible: `removeSymbolEffect(ofType:options:animated:)`.
- Composes with: UIViewPropertyAnimator running on the imageView's transform/alpha simultaneously.
- Apple's own use: every SF-Symbol icon in Settings, Music play/pause toggle, Mail send paper-plane.
- When to choose this over alternatives: any SF Symbol that should react to state change. If the chat-mode UI has SF-Symbol buttons (send / dismiss), this is the right primitive.
- Reference: WWDC 2023 session 10157 "Animate symbols in your app".

---

## Compositional pairings

- **UIViewPropertyAnimator + CADisplayLink:** drive `animator.fractionComplete = progress` per frame for fully custom non-linear scrubbing OR to coordinate the animator's progress with a non-time variable (gesture distance, audio level, scroll offset).
- **UIViewPropertyAnimator + UIPercentDrivenInteractiveTransition:** the canonical hero / interactive-dismissal pair. Return the animator from `interruptibleAnimator(using:)`; iOS scrubs and reverses it for free.
- **UIViewPropertyAnimator + UIPanGestureRecognizer:** drag-to-dismiss. On began: start animator paused. On changed: set fractionComplete. On ended: continueAnimation(withTimingParameters: spring, durationFactor: 1) using gesture velocity → spring initial velocity. Apple's reference: WWDC 2016 session 216 demo app.
- **CABasicAnimation with `isAdditive = true` × N:** stack independent translations / rotations on one layer (gesture nudge + ambient drift + morph displacement, all summed).
- **CATransaction wrapping UIView.animate:** override the implicit ease-in-out curve with any CAMediaTimingFunction (e.g. `controlPoints: 0.2, 0.0, 0.0, 1.0` for Material's emphasized curve).
- **snapshotView + UIViewControllerAnimatedTransitioning + UIViewPropertyAnimator:** the full Apple hero recipe.
- **CADisplayLink + manual spring ODE (existing SpringAnimator):** the project's existing pattern — strictly more powerful than CASpringAnimation because it's interruptible.

## Footguns / known anti-patterns

- **`delay:`-based chaining** (current `revealChat`): delay is an absolute offset, not a dependency. Bandwidth contention, frame drops, or any prior block over-running causes phase misalignment. Replace with `animateKeyframes`, completion-block sequencing, or UIViewPropertyAnimator with a single fractionComplete timeline.
- **`fillMode = .forwards` + `isRemovedOnCompletion = false`** without writing the model value: layer snaps back if anything causes the animation to be removed (backgrounding, screen change). Always set the model value at the end too.
- **CABasicAnimation default linear timing** vs UIView.animate default ease-in-out — mixing both in one screen produces inconsistent motion. Set `timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)` on the CA path.
- **CAAnimationGroup truncating children** when group duration < child duration.
- **`afterScreenUpdates: true` on snapshotView** during a transition that's already mid-layout — forces a re-layout and stutters.
- **UIDynamicAnimator + CAAnimation on the same view** — they fight for the transform.
- **CADisplayLink retain cycle** — link retains its target; use a weak proxy or invalidate in deinit-adjacent lifecycle.
- **ProMotion at 60Hz** by accident — manual CADisplayLink animations look subtly worse than system animations on 120Hz devices unless `preferredFrameRateRange` is set.
- **Mixing UISpringTimingParameters and CASpringAnimation in one coordinated motion** — different math, visible mismatch.
- **`.beginFromCurrentState` is the ONLY clean way to interrupt a UIView.animate** — without it, a new animation on the same property snaps to start.

## What UIKit/CA CANNOT do for Tier-3B coordination

- **Declarative timeline of N concurrent property animators across M views with named milestones / events / phases.** UIKit has UIView.animateKeyframes for time fractions on ONE view's properties — there is no built-in N×M coordinator. (Motivates a custom Coordinator type or open-source — RxAnimated, Stagehand, Advance.)
- **Cross-view-controller scrubbable shared-element transitions** without significant boilerplate. matchedGeometryEffect (SwiftUI) and Hero (open-source) abstract this; UIKit only gives you the snapshot primitives.
- **First-class reactive pause/resume of an arbitrary animation graph** under external pressure (e.g. "keyboard is appearing, defer the morph 80ms"). UIViewPropertyAnimator pauses a single animator; coordinating dozens requires a parent state machine.
- **Phase-based animation (SwiftUI iOS 17 `.phaseAnimator`, `.keyframeAnimator`)** has no clean UIKit equivalent — you build it from animator state machines or a CADisplayLink + interpolator.
- **Spring parameter handoff mid-flight** — UIViewPropertyAnimator.continueAnimation(withTimingParameters:) gives you ONE handoff at one point; mid-animation parameter morphing requires a custom driver.
- **Velocity-aware completion from interrupted animation** — you can read `layer.presentation()` for position but not for velocity; you must track velocity yourself with a CADisplayLink-backed estimator. (Motivates a Velocity Tracker utility class.)
- **Cancellation telemetry** — UIView.animate completion block receives `Bool finished` but not a reason; UIViewPropertyAnimator gives `.start/.end/.current` position but no cancel cause. Apps that need to know "was this aborted by keyboard, by tap, by VC dismissal?" must wrap the animator in a custom controller.
- **Frame-budget-aware degradation** — no built-in "this device is dropping frames, simplify the morph" feedback; must roll via CADisplayLink hitch detection (MetricKit's `MXAnimationHitchTimeRatio` is post-hoc only).
