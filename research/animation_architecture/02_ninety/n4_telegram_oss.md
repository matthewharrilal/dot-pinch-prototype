# NINETY — Telegram-iOS open-source animation architecture
# Intention 3 — peer rebuild (with source-verification)
POSTURE: janum

> All source citations below are public on github.com/TelegramMessenger/Telegram-iOS @ master. Where line numbers are cited they were verified via WebFetch on the raw file. Lines drift between commits — pin to the master HEAD I read against this session.

---

## Source layout overview

Telegram-iOS does not have one animation system. It has **three concentric ones**, layered historically:

1. `submodules/Display/` — the original imperative substrate (forked AsyncDisplayKit + custom helpers). Layer-level animation extensions, transition enum, ListView with its own animator. This is what most of the chat UI is still built on.
   - Source: `submodules/Display/Source/*.swift` (≈ 150 files)
   - Key files: `ContainedViewLayoutTransition.swift`, `CAAnimationUtils.swift`, `DisplayLinkAnimator.swift`, `ListViewAnimation.swift`, `Spring.swift`, `ListViewItemNode.swift`.

2. `submodules/ComponentFlow/` — newer declarative substrate. SwiftUI-ish but built on the same `Display` primitives underneath.
   - `Source/Base/{Component,CombinedComponent,Transition,Environment,ChildComponentTransitions}.swift`
   - This is where newer features (Stories, Premium UI, the new Camera) live.

3. `submodules/UIKitRuntimeUtils/` — the Objective-C escape hatch. Instantiates real-but-undocumented behaviors (private blur classes, CAFilter via `NSClassFromString`) and wraps `CASpringAnimation` with project-default tunings.
   - `Source/UIKitRuntimeUtils/UIKitUtils.{h,m}`

The whole thing pivots on **one type**: `ContainedViewLayoutTransition` (legacy) / `ComponentTransition` (new). Every layout function in the codebase takes one as a parameter. Pass `.immediate` and the code becomes synchronous; pass `.animated(...)` and the exact same code path produces the animation. That is the central architectural decision.

---

## Animation primitive surface

### Display framework: `ContainedViewLayoutTransition`

File: `submodules/Display/Source/ContainedViewLayoutTransition.swift`

```swift
// lines 87–91
public enum ContainedViewLayoutTransition {
    case immediate
    case animated(duration: Double, curve: ContainedViewLayoutTransitionCurve)
}

// lines 7–16
public enum ContainedViewLayoutTransitionCurve {
    case linear
    case easeInOut
    case easeIn
    case spring
    case customSpring(damping: CGFloat, initialVelocity: CGFloat)
    case custom(Float, Float, Float, Float)   // cubic-bezier control points
    static var slide: ... { .custom(0.33, 0.52, 0.25, 0.99) }
}
```

The methods bolted onto this enum (≈ 1700 lines of them) are all variants of
`updateX(node/view/layer:, X: T, transition: ...)`:

| Method                                    | Lines      | Purpose                          |
| ----------------------------------------- | ---------- | -------------------------------- |
| `updateFrame(node:frame:...)`             | 262–307    | ASDisplayNode frame (validated)  |
| `updateFrame(view:frame:...)`             | 1157–1210  | UIView frame                     |
| `updateFrame(layer:frame:...)`            | 1212–1236  | Bare CALayer frame               |
| `updateAlpha(node:|layer:)`               | 1238–1299  | Opacity                          |
| `updatePosition(node:|layer:)`            | 529–587    | Center point (anchor-aware)      |
| `updateTransformScale(node:|layer:)`      | 1008–1059  | `transform.scale` keypath        |
| `updatePositionSpring(...)`               | 589–625    | Spring variant of position       |
| `animateView { … }`                       | 1680–1691  | Escape hatch — wraps UIView.animate with the curve's options |

Every call has the same three-line internal shape: read current value → call `layer.animate(from:to:keyPath:...)` from `CAAnimationUtils.swift` → forward completion.

### `CAAnimationUtils.swift` — the layer-keypath kernel

File: `submodules/Display/Source/CAAnimationUtils.swift`

The single function `animate(from:to:keyPath:timingFunction:duration:delay:mediaTimingFunction:removeOnCompletion:additive:completion:key:)` at **lines 357–430** is the funnel everything goes through. Three timing-function paths:

- line 359: project-custom spring prefix (`kCAMediaTimingFunctionSpring`-style keys with explicit dampings)
- line 377: real `kCAMediaTimingFunctionSpring`
- line 401: standard named curves (`easeInEaseOut`, etc.)

Spring animations defer to **public** `CASpringAnimation`, configured in Objective-C in `UIKitRuntimeUtils/UIKitUtils.m`:

```objc
// lines 40–50
CASpringAnimation *a = [CASpringAnimation animationWithKeyPath:keyPath];
a.mass = 3.0f;
a.stiffness = 1000.0f;
a.damping = 500.0f;

// lines 60–81 — the "bounce" variant
a.mass = 5.0f;
a.stiffness = 900.0f;
a.damping = damping;   // caller-supplied
```

**Notable:** Telegram does NOT roll its own spring solver. They calibrate `CASpringAnimation`'s public parameters. The famous "feel" is just `(mass=3, stiffness=1000, damping=500)` consistently applied for normal motion and `(5, 900, ~110)` for bouncier motion. `Spring.swift` itself (despite the name) is a Bézier helper — no solver.

### `DisplayLinkAnimator` + `SharedDisplayLinkDriver`

File: `submodules/Display/Source/DisplayLinkAnimator.swift`

```swift
// SharedDisplayLinkDriver — line 45
public static let shared = SharedDisplayLinkDriver()
// .add(...) — lines 232–238
public func add(framesPerSecond: FramesPerSecond = .fps(60),
                _ update: @escaping (CGFloat) -> Void) -> Link
```

One global `CADisplayLink` batches every per-frame subscriber in the app. The driver iterates request contexts, throttles per-subscriber via `request.lastDuration >= secondsPerFrame * 0.95` (line ≈ 200), and invalidates itself entirely when no subscribers remain (lines 171–190). Individual `DisplayLinkAnimator` instances become thin: just `(from, to, duration, startTime, update, completion)` plus a `tick()` that computes clamped progress (lines 262–268) — no display link of their own.

### ComponentFlow: `ComponentTransition`

File: `submodules/ComponentFlow/Source/Base/Transition.swift`

```swift
// lines 233–241
public struct ComponentTransition {
    public enum Animation {
        public enum Curve { /* easeInOut, easeIn, spring, linear,
                               custom(Float,Float,Float,Float),
                               bounce(stiffness:, damping:) */ }
        case none
        case curve(duration: Double, curve: Curve)
    }
    public var animation: Animation
}
```

Methods (`setFrame` 321–368, `setBounds` 401–422, `setPosition` 452–473, `setAlpha` 566–593, `setScale` 598–640, `setTransform` 670–723) mirror the Display API but are a struct instead of an enum and decouple position from bounds animation:

```swift
// inside setFrame
self.animatePosition(view: view, from: previousPosition, to: updatedPosition,
                     completion: completion)
if previousBounds.size != frame.size {
    self.animateBoundsSize(view: view, from: previousBounds.size, to: frame.size)
}
```

`attachAnimation(view:id:completion:)` (lines 506–517) is the **phantom-keypath trick**: it animates a synthetic keypath named `id` from 0→1 on the layer, so external Swift code (any closure) can be synchronized to the same timing curve / interruption semantics as a CALayer animation, without there being any visual property to animate. This is how ComponentFlow drives non-CA state (text content, layout passes) on the same timing manifold as the visuals.

---

## Specific interactions reverse-engineered

### Pinch-to-zoom on media — `ContextUI/Sources/PinchSourceContainerNode.swift` + `TelegramUI/Components/ContextControllerImpl/Sources/PinchController.swift`

Two-file split: the **container node** owns the gesture state machine, the **controller** owns the transform.

- `PinchSourceGesture` is a subclass of `UIPinchGestureRecognizer`. State machine in `gestureUpdated()` lines 82–111: tracks `currentOffset`, `initialLocation`, `currentNumberOfTouches`. On lift-to-one-finger it gracefully transfers; on `.ended/.cancelled` it raises `updated` and `deactivated` callbacks (lines 155–159, 183–184). It does NOT touch any layer — it only emits `(scale, pinchLocation, offset)` tuples.

- `PinchController.swift` lines 55–67 apply the transform:

```swift
let pinchOffset = CGPoint(
    x: pinchLocation.x - initialSourceFrame.width / 2.0,
    y: pinchLocation.y - initialSourceFrame.height / 2.0
)
transform = CATransform3DTranslate(transform,
    offset.x - pinchOffset.x * (scale - 1.0), ..., 0.0)
transform = CATransform3DScale(transform, scale, scale, 0.0)
```

Anchor-around-pinch-point is faked via translation, not by mutating `layer.anchorPoint` (which would re-center the layer at runtime — they avoid that headache entirely).

- Release / spring-back, lines 101–119:

```swift
self.sourceNode.contentNode.layer.animateSpring(
    from: scale as NSNumber, to: 1.0 as NSNumber,
    keyPath: "transform.scale",
    duration: duration * 1.2, damping: 110.0)
```

Plus a simultaneous additive position spring back to the initial center (lines 121–124). Damping = 110 on the bouncy `CASpringAnimation` profile.

### Message bubble appear — `TelegramUI/Components/Chat/ChatMessageItemView/Sources/ChatMessageItemView.swift` lines 368–376

The full insertion is **shockingly minimal** in the override:

```swift
override func animateInsertion(_ currentTimestamp: Double, duration: Double,
                               options: ListViewItemAnimationOptions) {
    if !options.short {
        self.transitionOffset =
            invertOffsetDirection ? -self.bounds.size.height * 1.6
                                  :  self.bounds.size.height * 1.4
        self.addTransitionOffsetAnimation(0.0,
            duration: duration, beginAt: currentTimestamp)
    }
}
```

That is the entire bubble entrance: shift the node's bounds origin off-screen (1.4× outgoing / 1.6× incoming), then animate `transitionOffset` back to 0. The `transitionOffset` property observer (`ListViewItemNode.swift` lines 703–709) re-derives `bounds` on every set, so the ListView's normal layout pass slides the bubble in — no separate UIView.animate, no group, no concurrent scrollview push.

The list view itself drives the timing — `addTransitionOffsetAnimation` (lines 928–935) inserts a `ListViewAnimation` (the project's CPU-side interpolator) into the node's per-key animation map, applied each frame by the ListView's run loop. Alpha and scale on a new bubble are **explicitly not used**; only Y translation. The bubble doesn't fade in — it slides up under the keyboard.

### Chat list reorder — `Display/Source/ListViewReorderingItemNode.swift`

- Pickup (lines 54–57): two layer alpha fades (top & bottom shadow, both 0→1 over 0.25s). No scale, no shadow blur radius animation — the shadows are pre-rendered as images on adjacent CALayers.
- Drag follow (lines 59–61): direct frame mutation, no animation at all.

```swift
self.copyView.frame = CGRect(
    origin: CGPoint(x: initialLocation.x, y: initialLocation.y + offset),
    size: copyView.bounds.size)
```

- Drop (lines 68–74): `itemNode.addTransitionOffsetAnimation(0.0, duration: 0.3 * UIView.animationDurationFactor(), beginAt: CACurrentMediaTime())` on the original list node while the copy hides. The copy view doesn't fly back; the *real* row beneath does.

The gesture recognizer lives separately at `submodules/Display/Source/ListViewReorderingGestureRecognizer.swift` and only emits offsets — same separation-of-concerns as pinch.

---

## 90% rules encoded in Telegram-iOS

1. **One transition type, every layout function takes it.** Whether a call site is animating or not is decided at the call site, not by writing two implementations. The implementation is identical; the transition object swallows the difference. (`ContainedViewLayoutTransition` is passed to every `update*` in `Display`; `ComponentTransition` in every `update` in `ComponentFlow`.)

2. **Gesture state and transform application are in different files.** `PinchSourceGesture` knows nothing about CALayers; `PinchController` knows nothing about touches. They communicate via `(scale, pinchLocation, offset)` tuples. Same for reorder (`ListViewReorderingGestureRecognizer` → `ListViewReorderingItemNode`). This is the only way the same gesture can drive multiple visual treatments.

3. **Anchor-around-arbitrary-point is faked with a translation, not `layer.anchorPoint`.** `transform = translate(offset - pinchOffset*(scale-1)) * scale(scale)` — verified in `PinchController.swift` lines 55–67.

4. **Public `CASpringAnimation` is good enough; calibrate it once and use it everywhere.** Two profiles: `(mass=3, stiffness=1000, damping=500)` for normal motion, `(mass=5, stiffness=900, damping≈caller)` for bounce. Files: `UIKitRuntimeUtils/UIKitUtils.m` lines 40–50, 60–81.

5. **One CADisplayLink for the whole app.** `SharedDisplayLinkDriver.shared` (`DisplayLinkAnimator.swift` line 45) batches every subscriber. Animators don't own display links; they request a slot and get throttled/coalesced. This invalidates itself when idle.

6. **Animations that need to drive non-CA state ride a phantom keypath.** ComponentFlow's `attachAnimation(view:id:)` (lines 506–517) animates a no-op keypath 0→1 so any closure can be on the same timing manifold as a real layer animation — same interruption, same curve, same completion.

7. **Bubble appears slide; they don't fade.** Y translation through `transitionOffset` only. No alpha, no scale. (`ChatMessageItemView.swift` 368–376.)

8. **The ListView interpolates on the CPU.** `ListViewAnimation` is a `(from, to, duration, curve)` quadruple sampled per frame by the list's run loop, not a `CAAnimation`. This is what lets the scrollview's contentOffset, the incoming bubble's offset, and the outgoing bubble's removal animate on a single coordinated clock — they all read from the same animator pool.

9. **No CADisplayLink stutter from concurrent animators.** All interpolation goes through one driver; all visual transforms go through Core Animation. The two clocks are kept independent.

10. **Decouple position and bounds.** `ComponentTransition.setFrame` (lines 321–368) explicitly fires two animations: one on position, one on bounds.size. Reason: position interruptions don't reset size interpolations, and vice versa.

---

## Patterns transferable to DotPinchPrototype

- **Take `ContainedViewLayoutTransition` directly.** Rebuild as a 200-line Swift enum that wraps UIView.animate / CABasicAnimation / CASpringAnimation. Every layout method on every custom view takes one. This single change kills the chained-`UIView.animate(delay:)` blocks. The brittleness goes away because the *call sites* read identically regardless of whether they animate.

- **Split gesture from transform.** Even with one gesture and one effect today, write `PinchSourceGesture` (emits `(scale, location, offset)`) and `PinchTransformApplier` (consumes them). The day a second visual treatment is needed (e.g. background blur intensifies with scale), no gesture rewrite is required.

- **One `SharedDisplayLinkDriver`-style singleton.** Even at our scale, the discipline of "no view owns a CADisplayLink" prevents the worst of the multi-link CPU-spin problem and gives us a single foreground/background pause point.

- **Phantom-keypath synchronization (`attachAnimation`-style).** Whenever non-CA state (a `CGFloat` we sample, an `NSAttributedString` we crossfade) needs to follow the same timing curve as a real layer animation, ride a 0→1 keypath on the same layer. We don't have to roll a parallel timer.

- **CASpringAnimation calibration constants.** Pick our `(mass, stiffness, damping)` once and use them everywhere. Telegram's `(3, 1000, 500)` standard / `(5, 900, ~110)` bouncy is a documented starting point we can A/B against.

- **Anchor-via-translation trick.** Our pinch already does some anchor math — replace `layer.anchorPoint` mutation with `transform = translate(offset - pinchOffset*(scale-1)) * scale(scale)`. Avoids re-centering glitches.

---

## Things Telegram does that we should NOT copy

- **Fork AsyncDisplayKit.** Off-main-thread layout for a 100M-user chat app. We're prototyping a pinch interaction; UIKit on the main thread is fine. Adopting ASDK is a multi-month yak-shave with no ROI here.

- **CPU-side `ListViewAnimation` interpolator.** Telegram needs it because their entire chat list is one giant manually-batched recycler with bespoke insert/remove animations. We have UIKit's `UIView.animate` + `UICollectionView.performBatchUpdates` — adequate.

- **Two-layer transition system (Display + ComponentFlow).** They're carrying both because of legacy. We should pick one. `ContainedViewLayoutTransition`-shaped enum is the right size for us; ComponentFlow's full declarative substrate is a SwiftUI rewrite-in-disguise and we're committed to UIKit.

- **Obfuscated private-API access (`NSClassFromString(@"_UICustomBlurEffect")`, etc. in `UIKitUtils.m` lines 127, 166, 261).** This is Telegram trading App Review risk against rendering fidelity. We don't have that fidelity bar; we have `UIVisualEffectView`. Don't go private-API.

- **Their pinch's two-file ceremony (`PinchSourceGesture` + `PinchController`) at our scale.** The *idea* (separation of concerns) transfers; the literal file count does not. One source file with two types is fine.

- **Pre-rendered shadow images for the reorder pickup (`ListViewReorderingItemNode.swift` lines 54–57).** That's a performance shortcut for a list of 1000+ chats. Our pickup will use real `layer.shadow*` animations.

---

## Frontiers

- We could not verify from source alone how `transitionOffset` interacts with the scrollview's `contentOffset` when a new bubble arrives while the user is scrolling. The coordination clock has to live somewhere in `ListView.swift` (which is 3000+ lines). Reading that file in full is a follow-up if we want to replicate the "scroll adjusts simultaneously" behavior precisely.
- The TGS sticker pipeline (Lottie-equivalent custom renderer) lives in `submodules/AnimatedStickerNode/` and `submodules/RLottieBinding/`. We didn't go into it — not relevant to DotPinchPrototype's scope.
- The `Display` framework's `ListViewItemNode.layout` interaction with `addTransitionOffsetAnimation` is timer-driven and we did not verify the exact dispatch (is it `displayLink` or run loop observer?). For our purposes the rule "lists drive their own animation clock" is sufficient even without the implementation detail.
- We did not verify that the chat list backdrop blur uses `CABackdropLayer` / `CAFilter` direct instantiation. The earlier-citation in DotPinchPrototype's research/reveal_mechanism notes is not corroborated by file content visible in this session. The only confirmed private-API touch we saw was `_UICustomBlurEffect` and `CAFilter` in `UIKitUtils.m`. Worth re-verifying that earlier claim against the actual source before propagating it.
