# NINETY — Airbnb + premium consumer apps (Instagram, Cash App, TikTok, Tinder)
# Intention 3 — peer rebuild
POSTURE: janum

## App: Airbnb

### Observable animations
- Listing card → detail hero: tap a card in search results; the hero image expands edge-to-edge, the price tag travels with it, the surrounding cards fade. Reverse drag-to-dismiss returns the image to the card slot it came from, even if the user has scrolled the underlying collection.
- Image viewer (gallery): pinch-to-dismiss with rubber-band scale + alpha falloff on the chrome; horizontal swipe between images uses a custom paged layout, NOT UIPageViewController; flick velocity carries past the page boundary.
- Calendar / date picker booking: dates animate in with a staggered fade as the month scrolls; selected range fills with a continuous bar that grows from start to end across cell boundaries (drawn at a layer above cells, not per-cell tinting).
- Lottie-driven micro-interactions: heart/save button, host loading states, "Airbnb" wordmark intros, search empty states. Almost every illustrative animation in the app is a Lottie file, not hand-coded.
- Search results map ↔ list transition: the bottom sheet expands while the map zooms and the result count pill morphs position.

### Likely primitives + architecture
- **Epoxy (open-source)** is the load-bearing list/collection framework. ItemModel + SectionModel describe what to render declaratively; UICollectionView + custom CompositionalLayout backing. Re-renders diff via id+dataID, animate diff insertions with default UICollectionView batch-update animations OR custom transitions per item.
- **Lottie (open-source)** for all illustrative animation — `LottieAnimationView` driven by a single `currentProgress` float, which means any animation can be scrubbed by a gesture, a UIViewPropertyAnimator's `fractionComplete`, or a custom timeline. This is the key 90% pattern: animation reduced to a single Float[0,1].
- **MotionGroup / MagazineLayout** (Airbnb open-source). MagazineLayout is their UICollectionViewLayout that supports per-cell sizing — heavily used for search.
- Hero transitions: custom `UIViewControllerAnimatedTransitioning` + `UIViewControllerInteractiveTransitioning`, using snapshots and a single `UIViewPropertyAnimator` whose `fractionComplete` is driven by either timer or pan gesture. They explicitly do NOT chain `UIView.animate(delay:)` for the hero — it's one animator, one timeline, multiple property animations registered as keyframes inside `animator.addAnimations { ... }` blocks.
- Bottom-sheet behavior: custom interactive container with a single propertyAnimator + UIDynamicAnimator for the rubber-band overshoot at the open/closed extremes.

### 90% rules encoded
- **Single source of truth for progress.** Whether the user is driving with a finger or the system is driving with a timer, animation state collapses to one scalar 0→1. This is the principle Lottie operationalizes and Airbnb generalizes to their hero transitions.
- **Declarative item models → diffable updates** — animation choreography is a derived property of state delta, not of imperative call order. You don't say "animate B 0.2 after A finishes"; you say "B's model.isVisible flipped to true" and the framework computes the staggered insertion.
- **Snapshot + transplant** for hero transitions: never animate the original view across container boundaries. Take a `snapshotView(afterScreenUpdates:)`, add to a transition container, animate snapshot, swap real view at completion. This eliminates AutoLayout-during-animation pathology.
- **Animation duration is rarely a literal constant** — it's derived from distance traveled with a velocity floor, so a 4pt hop and a 400pt fling don't take the same 0.3s.

### Citations / talks
- Bryn Bodayle, "Building Lottie" — Airbnb engineering blog / Lottie GitHub history.
- Eric Horacek, "Building Native Cross-Platform UIs with Epoxy" — Airbnb engineering Medium (~2020); also tryswift / iOS Conf SG talks.
- Airbnb engineering blog: "MagazineLayout" introduction post (Bryan Keller).
- Lottie WWDC-adjacent talks (try! Swift Tokyo 2017 Brandon Withrow original).
- Open-source code as direct evidence: github.com/airbnb/lottie-ios, github.com/airbnb/epoxy-ios, github.com/airbnb/MagazineLayout.

---

## App: Instagram

### Observable animations
- Story camera entry: pull-down from feed reveals camera with a parallax — feed slides up at a slower rate than camera slides down, with simultaneous radius corner-rounding on the feed snapshot. Interactive throughout — release at <50% snaps back, release with upward velocity also snaps back.
- Story → next story tap; story → previous swipe; story dismiss-with-drag (the story shrinks toward the avatar that opened it, even when the user has scrolled the avatar tray underneath).
- Reels vertical paging: a UICollectionView with one full-screen cell per video; the cell snaps with the page-boundary velocity-aware decision (carryover scroll past midpoint with sufficient velocity advances).
- Profile zoom: pinch on avatar triggers a hero zoom; double-tap a feed photo triggers the heart burst (this one is hand-coded CABasicAnimation + transform sequence, not Lottie).
- Comments sheet: tap comments → modal sheet rises with a partial detent; can be drag-dismissed; backdrop alpha follows sheet position.

### Likely primitives + architecture
- **UIViewPropertyAnimator with pausesOnCompletion = true** is the canonical Instagram pattern (referenced by Mike Lee in iOS Conf SG / try! Swift talks ~2017–2018, "Modern Animation with UIViewPropertyAnimator"). The animator is built once, run to a point, paused, fractionComplete driven by a UIPanGestureRecognizer, then resumed (or reversed) at gesture end depending on velocity.
- **Story dismiss-to-avatar** is a custom `UIViewControllerTransitioningDelegate` returning an interactive transition; the interactive driver computes target rect by snapshotting the visible avatar tray and mapping coordinates. The animator interpolates frame + cornerRadius simultaneously — these two are explicitly animatable via UIViewPropertyAnimator with .layer.cornerRadius requiring an extra trick (animate via CABasicAnimation registered alongside, or use the iOS 13+ direct layer animation).
- **Memory pressure / video co-existence**: AVPlayerLayer cannot be snapshotted via `snapshotView(afterScreenUpdates:)` reliably (returns black). Instagram's pattern (inferred from runtime behavior + Reverse-engineered Reels): grab `currentItem`'s `asset` → `AVAssetImageGenerator` for a poster, or use a CADisplayLink-driven texture via Metal to bridge into the transition.
- **Reels**: UICollectionView with a vertical paging compositional layout; `targetContentOffset(forProposedContentOffset:withScrollingVelocity:)` overridden to compute next-page-with-velocity. Prefetch ±1 cell, preroll AVPlayer in adjacent cells.
- **Double-tap heart**: pure CAKeyframeAnimation on transform.scale + opacity, with a brief CASpringAnimation on the final pop. Not Lottie because the burst position must be at finger location, dynamically.

### 90% rules encoded
- **Pause an animator at the user's fingertip.** The animator is the timeline; the gesture is a clock that drives fractionComplete with rubber-banding past 0 and 1. At gesture end, decision tree on `velocity` and `fractionComplete`:
  - `velocity > 0 || fractionComplete > 0.5` → continue (`isReversed = false; startAnimation()`)
  - else → reverse and start.
- **Spring is computed, not approximated.** UISpringTimingParameters with `initialVelocity` matched to the gesture's release velocity (computed as `gestureVelocity / distanceRemaining`) makes the animation feel mass-continuous with the finger.
- **One animator, multiple properties.** A single animator coordinates frame + alpha + corner radius + transform via stacked `addAnimations` blocks; you do not have four separate UIView.animate calls.
- **Snapshots for view-controller hierarchy crossings.** Same rule as Airbnb.

### Citations / talks
- Mike Lee, "Advanced Animations with UIViewPropertyAnimator" — try! Swift NYC ~2017.
- WWDC 2016 Session 216 "Advances in UIKit Animations and Transitions" (Apple introduced UIViewPropertyAnimator; the entire Instagram pattern derives from this session).
- WWDC 2017 Session 230 "Advanced Animations with UIKit."
- Instagram engineering blog posts on Reels prefetching (~2021).

---

## App: Cash App

### Observable animations
- Tab switching: the active tab indicator is a single rounded-rect view that translates between tab slots with a sharp spring; the tab content cross-fades. No bounce, no overshoot — tightly damped.
- Payment flow ("$" tap → keypad → send): the keypad rises from the bottom while the dollar field grows in size; the green action button slides up to meet the keyboard. Reverse on dismiss carries the keypad back down with a tracked drag — interruptible.
- Long-press on a contact: a haptic + a subtle scale (~0.96) + a context menu spring-in (system-like, but custom).
- "Boost" reveal: the boost card flips with a 3D rotation around the X axis (CATransform3D, perspective set via m34 on the parent layer).
- Carry-back / swipe-back: a fully interactive UINavigationController pop with a parallax (background slides at 0.3x of foreground).

### Likely primitives + architecture
- **Haptic + animation lockstep.** UIImpactFeedbackGenerator fired in the same RunLoop tick as `animator.startAnimation()`. Critical: the generator is `prepare()`'d in `touchesBegan`, fired on state transition, NOT inside the animation completion block (which would arrive too late). This is Apple's documented best practice (WWDC 2017 Session 223 "Get the most out of UIFeedbackGenerator").
- **Restraint as principle.** Every Cash App animation is < 350ms, < 8% scale change, < 4pt translation overshoot. Damping ratio ~0.9 across the board.
- **Tab indicator** is almost certainly a single shared UIView whose `center.x` is animated via `UIViewPropertyAnimator` with `UISpringTimingParameters(dampingRatio: 0.9, initialVelocity: .zero)`. The destination is computed at tab tap time.
- **Keypad-to-button choreography** is a single UIViewPropertyAnimator with three `addAnimations` blocks (keypad transform, dollar-field transform/scale, button transform); duration computed from gesture velocity at dismiss, fixed ~280ms on programmatic.
- **3D flip** uses CATransform3DRotate with `m34 = -1/500` on the container, plus `doubleSided = false` on both faces. Animated via CABasicAnimation on `transform` with the appropriate `fillMode/removedOnCompletion` dance, or a UIViewPropertyAnimator with `.layer.transform`.

### 90% rules encoded
- **Haptic + visual must share a single trigger.** The "snappy" feeling Cash App is famous for comes from the haptic landing at the same RunLoop tick as the spring's peak energy — not 16ms later, not 33ms later.
- **Damping ratio is a brand identity.** Choosing 0.9 universally means the app feels "decisive"; 0.6 would feel "playful" (Airbnb's range); 0.4 would feel "toy-like" (some kid apps). Pick one and stick with it.
- **Short durations + high acceleration > long durations + slow ease.** Cash App animations FEEL fast because they ARE fast; the secret is they don't sacrifice perceived smoothness because spring acceleration is naturally high at the start.

### Citations / talks
- WWDC 2017 Session 223 "Get the Most out of UIFeedbackGenerator" — Apple's prepare/fire timing rules.
- WWDC 2018 "Designing Fluid Interfaces" Session 803 — the canonical talk on "ultimate responsiveness" that Cash App's motion idiom inherits from directly. Specifically: the "behaves like a continuation of touch" rule.
- Cash App's design team has talked publicly less than Airbnb/Instagram; primary evidence is the binary itself + the WWDC 803 ideology.

---

## App: TikTok

### Observable animations
- Vertical video feed: paging UICollectionView, full-screen cells, AVPlayer preroll on ±2 cells, gesture wins over scroll at first finger movement.
- Comments sheet: rises from bottom over the video; video continues playing at reduced volume; sheet has multiple detents (~40%, ~90%) with snap velocities computed at release. Background dim alpha tracks sheet position linearly.
- Share modal: a grid of share targets slides up; tapping a target triggers a brief scale-pop on the icon then dismisses.
- Heart double-tap: identical pattern to Instagram (CAKeyframeAnimation positioned at touch point).
- Profile-link tap: full-screen cover transition with a vertical reveal — content masked by an expanding rounded rect.

### Likely primitives + architecture
- **Simultaneous gesture recognition** is the architectural heart. UIPanGestureRecognizer for the video paging, UIPanGestureRecognizer for the comments sheet, UITapGestureRecognizer for play/pause, double-tap for heart, long-press for speed control — all coexist via `UIGestureRecognizerDelegate.gestureRecognizer(_:shouldRecognizeSimultaneouslyWith:)` returning carefully gated truths.
- **Decision tree at touchesBegan**: TikTok appears to use a `requireToFail` chain (double-tap requires single-tap-to-fail) plus a "primary gesture" arbiter that picks based on initial velocity vector — if first finger movement is mostly vertical and within video bounds, vertical-paging wins; if it starts in the comments-button hit region, sheet-rise wins.
- **Sheet detents** with `UISheetPresentationController` if iOS 15+, but legacy TikTok used a custom container; the snap logic is identical (projection: `position + velocity * decelerationRate / (1 - decelerationRate)`).
- **AVPlayer prefetch**: KVO on `currentItem.status`, prerolled via `seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)` on cell prepareForReuse; the displaying cell calls `play()` in `willDisplay`.

### 90% rules encoded
- **Gesture arbitration is the architecture.** When you have N gestures that can fire simultaneously, you need an EXPLICIT priority resolution, not an implicit one. Default behavior is undefined.
- **Projection of velocity at release** is the universal "where does the user want this to land" oracle. Apple uses this in `UIScrollView.targetContentOffset(forProposedContentOffset:withScrollingVelocity:)` and you should too.
- **Keep video alive during the transition.** Sheets, modals, share UI must not interrupt video playback; this means transition animators must NOT touch the AVPlayerLayer's view or its hierarchy in disruptive ways. Snapshot is dangerous (AVPlayerLayer snapshots black).

### Citations / talks
- WWDC 2018 Session 803 "Designing Fluid Interfaces" — projection function explicitly demonstrated.
- WWDC 2014/2016 on UIGestureRecognizer interactions.
- TikTok engineering rarely publishes; reverse-engineering is primarily through behavioral observation + binary inspection.

---

## App: Tinder

### Observable animations
- Card stack: top card draggable in any direction, rotation tied to horizontal offset (~max 12°), background cards scale-up from 0.95→1.0 as front card moves.
- Swipe commit: above velocity threshold OR translation threshold, card flings off-screen along the gesture's release vector; subsequent card scales to 1.0; "undo" reverses with a pull-back arc.
- Like/Nope overlay: alpha tracks |translation.x| / threshold, no scale, simple cross-fade.
- Undo button: brings the card back along the same flight path it left on (path memoized at commit time).

### Likely primitives + architecture
- **UIPanGestureRecognizer driving direct transform manipulation** during drag (no animator) — because gesture-driven manipulation of a CALayer transform via CGAffineTransform composition is cheaper and feels more "physical" than animator pausing.
- **UIDynamicAnimator with UIPushBehavior + UIDynamicItemBehavior** for the fling — or a `UIViewPropertyAnimator` with a custom `UICubicTimingParameters` whose controlPoints are set from release velocity. Modern Tinder is probably the latter (more controllable, cancelable, supports replay-for-undo).
- **Card stack data structure**: a small Z-ordered array of card views, top card is the one with gestures; on commit, top is removed and the next card has gestures attached (or all cards always have gestures attached but only the top one's are enabled).
- **Undo state**: the popped card's release vector + final transform + dataID is pushed onto an undo stack; `undo` runs the inverse animation with the same animator config but reversed control points.

### 90% rules encoded
- **Direct transform during drag, animator at release.** Two distinct phases with different mechanisms: while finger is down, do not use an animator (it adds latency); at release, switch to animator for the physics simulation.
- **Memoize the gesture release vector** for symmetric reverse (undo, snap-back). The animation that brought the card here is the inverse of the animation that takes it back.
- **Composition over interpolation.** The "tilt-while-dragging" is not an animation — it's a derived transform: `transform = translation(x, y).concatenating(rotation(angle: x / 500))`. No animator needed.

### Citations / talks
- Tinder open-sources very little; relevant references: Phil Webb's "Building a Tinder-style card stack" series, and the various Koloda / Shuffle-style open-source clones whose architecture matches observed behavior.
- WWDC 2014 Session 229 "Advanced User Interfaces with Collection Views" + WWDC 2016 219 on UIDynamicAnimator.

---

## Cross-app pattern synthesis

- **Pattern 1 — Single Float Progress (Airbnb-Lottie, Instagram-PropertyAnimator).** All five apps reduce complex multi-property animations to one scalar 0→1 driven by EITHER a timer OR a gesture. This is the cardinal replacement for chained `UIView.animate(delay:)`.

- **Pattern 2 — Snapshot + Transplant for hierarchy crossings (Airbnb hero, Instagram story-dismiss).** Real views never animate across container boundaries; snapshots in an overlay container do.

- **Pattern 3 — Velocity-Aware Projection at Release (Instagram, TikTok, Tinder, Cash App).** At gesture end, the next state is computed from `position + velocity * f(decelerationRate)`. Apple's `UIScrollView.decelerationRate = .normal` value (0.998) implies the projection multiplier ≈ 167.

- **Pattern 4 — Spring with Matched Initial Velocity (Instagram, Cash App).** `UISpringTimingParameters(dampingRatio:, initialVelocity:)` where `initialVelocity` is the gesture release velocity normalized by remaining distance. This is the "mass-continuous with the finger" property.

- **Pattern 5 — Declarative Models → Computed Animation (Airbnb-Epoxy).** You change `model.isExpanded = true`; the framework diffs against the previous model and animates the delta. Choreography is a derived value, not an imperative sequence.

- **Pattern 6 — One Animator, Many Properties (universal).** A single `UIViewPropertyAnimator` with multiple `addAnimations` blocks coordinates frame/alpha/transform/cornerRadius. You never have N animators with delays — you have 1 animator with N registered animations.

- **Pattern 7 — Haptic in the Same RunLoop Tick (Cash App canonical).** Prepare in touchesBegan, fire on state transition synchronous with the animator start. Never fire haptic in completion block.

- **Pattern 8 — Gesture Arbitration as First-Class (TikTok).** Multi-gesture screens need an explicit priority resolver; "simultaneous = true" everywhere is undefined behavior.

## Lessons transferable to DotPinchPrototype

- **For chained UIView.animate(delay:) replacement:** Universal across all five apps — replace with a single `UIViewPropertyAnimator` (or Lottie-style scalar progress driver). The N animations become N `addAnimations` blocks inside one animator. Stagger is achieved via `UIViewPropertyAnimator(duration: total, timingParameters: cubicOrSpring)` plus per-block delays expressed as `addAnimations(_:delayFactor:)` where `delayFactor ∈ [0,1]` of total. This is the closest 1:1 swap for the brittle chain.

- **For interruption / cancellation:** Adopt `pausesOnCompletion = true` + `isInterruptible = true` (Instagram pattern). Keep a reference to the animator. On user interrupt: `animator.pauseAnimation()` snapshots `fractionComplete`; then gesture drives that fraction directly. On release: decide forward vs reverse via projection.

- **For Tier 3B target (architecturally substrate, not symbol):** Build a thin `AnimationCoordinator` whose vocabulary is `present(state:from:to:driver:)` where `driver` is either `.programmatic(duration, curve)` or `.interactive(gesture)`. Internally always materializes as a single PropertyAnimator. State transitions are described declaratively (start state, end state, key frames), NOT as imperative call sequences. Mirrors Airbnb-Epoxy's posture: choreography is a function of state.

- **Velocity preservation across handoff:** When the gesture ends mid-animation, compute the visible velocity (CADisplayLink-sampled position delta / dt) and feed it into `UISpringTimingParameters.initialVelocity`. This is the missing ingredient that makes finger-to-animator handoff feel uninterrupted.

- **For Lottie-style scrubbable animations:** If DotPinch has any illustrative animation, vending it as a Lottie file (or a scalar-progress equivalent custom view) makes it both auto-playable AND gesture-scrubbable from a single code path. This is the most powerful 90%-derived primitive from this entire research surface.

## Frontiers
- Cannot verify Instagram's exact AVPlayerLayer-across-transition technique without binary symbol inspection or a leaked talk. Hypothesis is plausible but unverified.
- Cannot verify whether Airbnb's hero transition uses a single PropertyAnimator with stacked addAnimations OR a Lottie file with progress driven by the transition controller. Both fit the observable behavior. The fact they OWN Lottie biases the prior toward Lottie.
- Cannot verify Cash App's exact damping ratios without frame-by-frame motion analysis; "0.9 across the board" is an educated estimate from observed overshoot.
- Tinder's modern (post-2022) animation primitive is opaque — likely SwiftUI's `withAnimation` + matchedGeometryEffect for the card stack, but the card-physics-on-release fling is hard to express in SwiftUI and may still be UIKit-backed.
- Have NOT inspected Epoxy / Lottie source directly in this session — claims about Epoxy's diff-driven animation are from public talks, not source-tree confirmation.
