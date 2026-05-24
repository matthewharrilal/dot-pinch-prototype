# DotPinchPrototype

A UIKit prototype built under a different phenomenology of UI experience than the one iOS apps default to.

This README is, first, a description of that phenomenology — what it means, where the orthodox one came from, why ours is rare. Second, it is a record of how the phenomenological commitment propagates into every implementation decision. Third, it is honest about the journey: implementation came first, the phenomenological articulation came late, through long conversation. Capturing it here so the *why* doesn't get lost — the same way orthodoxy lost its origins.

---

## TL;DR — The Claim

iOS, as a platform, encodes a specific phenomenology of UI experience by default: **discontinuous-spatial**. The user perceives a tree of screens. Navigation is traversal between discrete places. Time is punctuated by transitions. Identity is anonymous (cells are interchangeable). Causation is request-response (you tap, the system delivers).

DotPinch is constructed under a different phenomenology: **continuous-embodied**. The user perceives one continuous world. Movement is transformation in place, not transition between states. Time is unbroken. Identity is persistent (cells are *this conversation*, with state intact across reuse). Causation is direct manipulation (your gesture *is* the change).

Neither phenomenology is correct. They are different positions on the same axes about what UI experience *is*. The orthodox one is the default in iOS because the framework's vocabulary was designed under 2008 hardware constraints that became architectural commitments that became cultural orthodoxy. The continuous one is rare because constructing the substrate for it requires opting out of the framework's default vocabulary at the architectural level.

DotPinch made that opt-out. Every implementation decision in this codebase — the camera value type, `sublayerTransform` as substrate, `m34` perspective as ambient projection, additive `CABasicAnimation` composition, identity-keyed cell pool, single master `CADisplayLink`, suppressed implicit animation discipline — propagates from the phenomenological commitment.

The visible manifestation: when you tap a cell, every visible cell executes the cane curve in phase-locked synchrony. The world lunges toward your choice. This does not happen in stock iOS apps because the framework's default vocabulary doesn't support it.

---

## Table of Contents

1. [Two Phenomenologies of UI Experience](#1-two-phenomenologies-of-ui-experience)
2. [Why the Orthodox Phenomenology Is the Default](#2-why-the-orthodox-phenomenology-is-the-default-the-snowball)
3. [What DotPinch Built Instead](#3-what-dotpinch-built-instead-the-substrate)
4. [The Perceptual Signature: Phase-Locked Cinematography](#4-the-perceptual-signature-phase-locked-cinematography)
5. [Taste Through Consistency](#5-taste-through-consistency)
6. [The Journey to Articulation](#6-the-journey-to-articulation)
7. [How the Phenomenology Propagates Into Implementation](#7-how-the-phenomenology-propagates-into-implementation-code-grounding)
8. [The Five-Layer Framework](#8-the-five-layer-framework)
9. [TIER ELEVATION — The Mechanism](#9-tier-elevation--the-mechanism)
10. [How to Continue and Advance This Phenomenology](#10-how-to-continue-and-advance-this-phenomenology-concrete-directions)
11. [The Phenomenology in Adjacent Crafts](#11-the-phenomenology-in-adjacent-crafts)
12. [Running, Testing, Architecture](#12-running-testing-architecture)
13. [Appendix — The Cane-Curve Trajectory (Detailed Technical Reference)](#13-appendix--the-cane-curve-trajectory-detailed-technical-reference)

---

## 1. Two Phenomenologies of UI Experience

Phenomenology, as used here, is the study of experience as it appears to the user — not what the system *is* underneath, but what the user *encounters* while using it. Two apps can perform the same task and produce categorically different experiences. The difference is in the *structure* of the experience.

Every interface adopts a phenomenology, usually without naming it. The phenomenology determines what the user understands the app to BE, what their own role inside it is, what time/space/identity/causation mean while using it, and what gestures signify.

### The Discontinuous-Spatial Phenomenology (orthodox iOS)

The structure:

| Aspect | Discontinuous-Spatial |
|---|---|
| Space | Partitioned into discrete states (screens) |
| Movement | Transition between states (discontinuous event) |
| Time | Punctuated by arrivals (before-transition, after-transition) |
| Identity | Anonymous reuse — cells are interchangeable instances of a type |
| Causation | Request-response (you tap, system processes, system delivers) |
| Viewport | Is the world — what's on screen is what exists |
| Animation | Per-element — each element animates on its own timeline |
| User role | Navigator visiting places |

This phenomenology is coherent, internally consistent, and maps cleanly onto small-screen mobile constraints. It works for the overwhelming majority of apps. It is what iOS users learn to expect and what iOS developers learn to produce.

### The Continuous-Embodied Phenomenology (DotPinch)

The structure:

| Aspect | Continuous-Embodied |
|---|---|
| Space | One continuous world; cells live at fixed page-positions |
| Movement | Transformation in place (continuous deformation of objects) |
| Time | Unbroken — no settled states punctuated by transitions |
| Identity | Persistent and data-keyed — *this view IS this conversation* |
| Causation | Direct manipulation — the gesture IS the transformation |
| Viewport | A window onto a world that extends beyond it |
| Animation | Scene-coherent — visible elements share trajectories atomically |
| User role | Actor inside a continuous space |

This phenomenology is also coherent, also internally consistent. It maps onto direct-manipulation interfaces, game engines, and the lineage of Bret Victor's work on responsive systems. It works for apps where the experience is *operating on something continuous* rather than *navigating between discrete things*.

### What disagrees

These two phenomenologies disagree on what's primary:

- **What's real**: discrete screens (orthodox) vs the continuous world (DotPinch)
- **What persists**: data with views as temporary projections (orthodox) vs objects with ongoing existence (DotPinch)
- **What gestures do**: request system actions (orthodox) vs cause world changes (DotPinch)
- **What "back" means**: pop the stack (orthodox) vs undeform what was deformed (DotPinch)

These are not better-or-worse axes. They are different positions on the same axes. Each phenomenology answers the same questions differently.

---

## 2. Why the Orthodox Phenomenology Is the Default (The Snowball)

This is the structural answer to "why is the continuous-embodied phenomenology rare in iOS apps."

iOS's framework vocabulary was established in iPhone OS 2 (2008) under specific constraints:

**The hardware**: A 320×480 display in 2008 with limited memory and CPU. Chunking information into discrete screens was the only way to make complex apps usable. Holding many views in memory simultaneously was expensive — recycling views via `UITableView`'s dequeue pattern was a memory necessity.

**The cognitive simplicity**: Discrete states are easier to reason about than continuous transformations. "I am on this screen" is a simpler mental model than "I am inside this transforming object." For most utility apps, the simpler model is appropriate.

**The framework structure**: `UIViewController` was designed as the unit of an iOS app. The whole VC lifecycle (`viewWillAppear`, `viewDidLoad`, `viewWillDisappear`) presupposes discontinuous states. The framework vocabulary — *push, pop, present, dismiss, transition* — encodes the discontinuous paradigm at the deepest level.

**The pedagogical reinforcement**: Apple's documentation, WWDC sessions, sample code, and Human Interface Guidelines all teach the discontinuous paradigm. Engineers learn it as "how iOS works."

### The snowball

The historical sequence:

```
2008 hardware constraints
        │
        ▼
Architectural accommodations (UITableView reuse, UIViewController lifecycle, push/pop navigation)
        │
        ▼
Framework primitives (UICollectionView, UINavigationController, UIPresentationController)
        │
        ▼
Default vocabulary (push, pop, present, dismiss, transition)
        │
        ▼
Apple's pedagogy (WWDC, HIG, sample code)
        │
        ▼
Community orthodoxy (Stack Overflow, conference talks, books)
        │
        ▼
Cognitive default (engineers don't notice it's a choice anymore)
        │
        ▼
THE ORIGINS ARE FORGOTTEN. THE CONCLUSIONS REMAIN.
```

The discontinuous-spatial phenomenology started as an *accommodation of 2008 constraints*. Through this snowball, it became the *cognitive default* of an entire industry. The constraints that justified it (320×480 display, 128MB RAM, 600MHz ARM) are gone. The vocabulary they produced remains, and now produces phenomenologies whose original justifications no longer apply.

### The lost epistemic awareness

This is the structural reason engineers don't see other possibilities. Not because they can't think. Because **orthodoxy hides its own origins**. By the time an engineer learns iOS, the discontinuous paradigm is presented as the way iOS *is*, not as a choice made under historical constraints. The vocabulary feels neutral; the assumptions feel like physics.

A developer working from defaults today produces a discontinuous-spatial-phenomenology app without making any explicit phenomenological choice. The choice was made for them by the framework's vocabulary forty years before their app exists.

The "right way" trap is the cultural reinforcement: deviation reads as code smell, as inexperience, as someone who hasn't learned the conventions. This pressure makes engineers police themselves before any external reviewer needs to. The cost is not just bad code — it is unrecoverable lost design space. A team that has internalized the right-way trap cannot even propose alternative phenomenologies; they are filtered out before reaching the whiteboard.

---

## 3. What DotPinch Built Instead (The Substrate)

To produce the continuous-embodied phenomenology, a developer must opt out of the framework's default vocabulary at the substrate level. They must construct primitives that the iOS SDK provides but doesn't surface as architectural keystones.

The substrate DotPinch built:

### The camera as a domain primitive

**File**: [`DotPinchPrototype/Conversation/Timeline/Camera.swift`](DotPinchPrototype/Conversation/Timeline/Camera.swift)
**Used at**: [`TimelineCanvas.swift:470`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift) (`applyCameraTransform`)

```swift
struct Camera {
    let translation: CGFloat
}
```

A `Sendable` value type the controller owns. Single source of truth for the canvas's spatial state. Applied via one matrix mutation on `contentHost.layer.sublayerTransform`. Every visible cell's apparent position derives from it.

This is the inverse of `UIScrollView.contentOffset`. UIScrollView's offset is *view-owned* — KVO-able but bound to the scroll view's lifecycle. The camera is *controller-owned* — composes with morph transforms, exists independently of any view.

### Phase-locking via sublayerTransform

**File**: [`TimelineCanvas.swift:470`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift), [`TimelineCanvas.swift:476`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift)

```swift
contentHost.layer.sublayerTransform = CATransform3DMakeTranslation(
    0, viewportCenter.y - camera.translation, 0)
```

One matrix on `contentHost.layer`. Every child cell inherits it atomically per render commit. There is no scheduling problem to get wrong; the five cells are not five animations that need to be coordinated, they are one animation whose effects propagate.

This is the inverse of per-element transforms. In orthodox iOS, if you wanted five cells to animate together, you would write five animations and hope the render server schedules them on the same commit. Under thrash or dropped frames, one might lag by a frame — the "jelly" or "tearing" effect. DotPinch literally cannot have this bug because the rendering structure makes the question not arise.

### m34 perspective as ambient projection

**File**: [`TimelineCanvas.swift:174-176`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift)

```swift
var perspective = CATransform3DIdentity
perspective.m34 = -1.0 / 1000   // focal length 1000pt
layer.sublayerTransform = perspective
```

Installed once at canvas init, never touched again. Every descendant of `canvas.layer` receives perspective foreshortening. Z-translations during the pinch-commit morph produce real depth motion — the cell rushes *toward* the viewer at the peak of the arc, not just gets bigger.

In orthodox iOS, m34 is treated as a one-off styling decision for parallax tutorials. Here it is an ambient architectural commitment that defines the visual physics of the entire app.

### Additive CABasicAnimation composition

**Files**: [`TimelineCanvas.swift:1273-1300`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift) (tap-to-chat morph)

Four `CABasicAnimation` objects on `contentHost.layer`, all with `isAdditive = true`. Their contributions sum into the layer's effective transform. The cane-curve trajectory in (lift, scale) motion-space emerges from the composition — no orchestrator, no master timer, no per-frame tick. CoreAnimation does the math.

This is the inverse of `UIView.animate` thinking. Single-curve animation cannot produce the cane curve because cubic Bézier endpoints have zero velocity by construction. Composition of complementary curves does, because their summed velocity is always non-zero.

### Identity-keyed cell pool

**File**: [`TimelineCanvas.swift:47-48`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift) (declarations), [`TimelineCanvas.swift:763-789`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift) (dequeue), [`TimelineCanvas.swift:797`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift) (return)

```swift
private(set) var cellPool: [CellView] = []
private(set) var cellPoolByConversationID: [UUID: CellView] = [:]
```

Two structures: LIFO array + UUID-keyed map. `dequeueCell(preferredConversationID:)` prefers a same-conversation cell so state preservation is automatic when the same data returns.

This is the inverse of `dequeueReusableCellWithIdentifier:`. Orthodox iOS treats cells as anonymous and `prepareForReuse` resets their state. DotPinch treats cells as identity-bound — the same conversation always returns to the same CellView instance, with in-flight animations, scroll position, and composer text intact.

### Master CADisplayLink heartbeat

**File**: [`DotPinchPrototype/Animation/AnimationController.swift`](DotPinchPrototype/Animation/AnimationController.swift)

One `CADisplayLink` at the app level. Every animator (`SpringAnimator`, `CurveAnimator`, `MorphChoreographer`) registers as a subscriber. Insertion-ordered iteration for deterministic per-frame ordering.

This is the inverse of per-animation timers. Orthodox iOS apps have many CADisplayLinks across the lifecycle (one per ad-hoc animation). DotPinch has one, and it feeds everything. The substrate has a *heartbeat*, not a *queue*.

### Suppressed implicit animation discipline

**File**: [`DotPinchPrototype/Animation/CATransaction+Helpers.swift`](DotPinchPrototype/Animation/CATransaction+Helpers.swift), used throughout

```swift
extension CATransaction {
    public static func withSuppressedActions(_ body: () -> Void) {
        begin()
        setDisableActions(true)
        defer { commit() }
        body()
    }
}
```

Every mutation path through the canvas wraps in `CATransaction.withSuppressedActions { … }`. The default is "snap." Animation is *never* implicit; it is always explicit.

This is the inverse of orthodox iOS where every layer property write triggers an implicit 0.25s ease-in-out animation. Here, animations don't compound with framework defaults. Explicit motion stands out because it's the only motion.

### Direct gesture recognizers on the canvas

**File**: [`TimelineCanvas.swift:246-256`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift)

`UIPanGestureRecognizer` + `UIPinchGestureRecognizer` attached directly to the canvas. Custom recognition logic. Pan and pinch can recognize simultaneously ([`TC:1540-1543`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift)).

This is the inverse of `UIScrollView`'s built-in pan plus gesture-conflict negotiation. The canvas owns gesture interpretation end-to-end; no fighting with framework physics.

### The point: every primitive is a commitment

Each item above is a *published, documented iOS API*. Nothing here uses private API. Nothing requires secret knowledge. The substrate decisions are commitments to *which APIs become load-bearing in our architecture* — which we trust as substrate vs which we treat as one-off utilities. That commitment is what makes the phenomenology possible.

---

## 4. The Perceptual Signature: Phase-Locked Cinematography

The visible manifestation of the substrate commitment is one specific phenomenon worth naming precisely, because it is the single thing about DotPinch that immediately reads as "not orthodox."

When the user taps a cell, **every visible cell on screen executes the cane-curve trajectory in phase-locked synchrony**.

Not "one cell animates." Not "two cells trade places via a transition." Every visible cell, simultaneously, performs the same windup, the same zoom, the same lift, the same centering. Five cells, one trajectory. A corps de ballet, not a soloist.

This works because all visible cells are children of `contentHost`, and the 4 additive `CABasicAnimation`s are on `contentHost.layer`. Every child inherits the parent's animations automatically. There is no list of animations to coordinate — there is one set of animations on one parent, and N children execute them in phase. Phase-locking is a *structural guarantee*, not a careful schedule.

What the eye reads:

- **Frame 1 (0ms)**: nothing visible has changed
- **Frame 6 (~100ms)**: subtle motion has begun — all cells have inched upward, none different from the others yet
- **Frame 18 (~300ms)**: the whole scene has lifted. Every cell is slightly bigger. None has broken from the formation.
- **Frame 36 (~600ms)**: the world is leaning toward you. Active cell dominating the center, neighbors moving toward viewport edges, all still in their phase of the dance.
- **Frame 60 (~1000ms)**: only the active cell remains in view. The others have completed their trajectory off-screen.
- **Frame 90 (~1500ms)**: settled. Reveal blur begins.

The perceptual reading is: **the world lunges toward the thing you chose**. Not "this cell got bigger." Not "the other cells went away." The world tilted around your choice. Every element in the scene participated in the gesture of acknowledgment. The active cell becomes dominant because *everything else moved out of its way in a coordinated motion*, not because we did anything special to that specific cell.

This is the same effect a film camera produces when it dollies toward a subject. The subject doesn't get bigger; the camera moves toward it. Everything in the frame appears to grow because the frame is closing distance. The subject is privileged by its position relative to the camera's trajectory, not by being animated differently.

This effect does not appear in stock iOS apps. There is no API for it. The closest analog is the springboard app-launch zoom (one icon zooms while others fade), but that is one-tapped-icon-zooms + everything-else-fades, categorically different from "every icon executes a shared trajectory with the tapped icon as the focal point."

This phenomenon is what the rest of the substrate makes possible. Without `sublayerTransform`, without additive composition, without identity-keyed cells, without master timer, this specific cinematic moment cannot occur. The substrate is the precondition; the cinematography is the manifestation.

---

## 5. Taste Through Consistency

The question worth answering: *why does this read as tasteful rather than gimmicky?*

Unorthodox UX is risky. Most attempts at it produce showy garbage — visual tricks for their own sake, parallax effects that don't serve the experience, custom gestures that confuse users. The reason DotPinch doesn't read this way isn't superior aesthetic taste in the abstract. It's structural consistency.

**Tasteful unorthodoxy**: every decision propagates from the same phenomenological commitment. The substrate, the gesture interpretation, the visual identity, the state model, the lifecycle — all express the same underlying claim about what the app is. The result is *internally coherent*. Each part reinforces every other. The unorthodox piece appears in exactly one place (at the substrate level) and the rest of the code is conventional in service of it.

**Gimmicky unorthodoxy**: the unorthodox piece is the point. The user (or code reviewer) is meant to notice "ooh, clever." It spreads — once you've broken one convention, you break more to maintain the first one. The visual flourish doesn't propagate from a deeper commitment; it stands alone, advertising itself.

DotPinch's substrate commitment propagates through every layer:

- Continuous-embodied phenomenology → ⤵
- The world must be a continuous space → ⤵
- Cells must live at fixed page-positions → ⤵
- A camera must translate over them → ⤵
- The camera must be a domain primitive (not UIScrollView's contentOffset) → ⤵
- All visible cells must inherit one transform (sublayerTransform on a shared parent) → ⤵
- Animations must compose (additive CABasicAnimations, not UIView.animate) → ⤵
- Cells must persist identity across reuse (data-keyed pool) → ⤵
- Gestures must transform the world directly (pinch as transition, not zoom) → ⤵
- Implicit animations must be suppressed (so explicit motion is legible) → ⤵
- Phase-locking must be structural (not scheduled)

Every decision below the first one is consequent. None of them is a flourish. The cane-curve trajectory exists because additive composition exists because single-curve thinking can't produce velocity continuity because the eye reads velocity discontinuities as stops. The chain is unbroken.

Internal consistency is the taste. The app does not feel "designed" in the unfortunate sense because every part of it follows the same logic. The fact that the logic isn't the framework's default logic is what produces the "not orthodox" reading. The fact that the logic is *consistently* applied is what produces the "tasteful" reading.

---

## 6. The Journey to Articulation

This section is honest about the order things happened.

The implementation came first. The phenomenological articulation came late, through long conversation, after the substrate was already built and shipping. For many weeks the team had a working prototype that *felt different* without being able to say *why* in precise terms. The articulation that this README captures was assembled retroactively — the same way orthodoxy's origins were forgotten and had to be reconstructed.

This is worth documenting so the *why* doesn't get lost again.

### The starting point

The project started with a reference video at `_frames/dot_pinch.mov`. Not a design doc. Not a spec. A 4-second recording showing the target tap-to-chat interaction. The visual identity of the product was a video, and the job was to reproduce it.

The team treated the video as an executable spec — frame-by-frame analysis at 0.25x speed, screenshotting frames, measuring positions/scales/opacities, plotting motion-space trajectories. This empirical practice was the only authoritative spec; there was no documentation telling us how to build it.

### The 15+ failed iterations

The cane-curve doc (Appendix, §5) records the journey through failed mechanisms:

1. **V2 motion (master CADisplayLink + per-tick property orchestration)** — Frankenstein composition
2. **Bounds-based extension with heightConstraint** — clobbered by other layout passes
3. **Snapshot-based bitmap approaches** — Vertigo Effect; frame analysis disproved the hypothesis
4. **CAKeyframeAnimation with [easeOut, easeIn]** — velocity dip at keyframe boundary; perceptual stop
5. **CAKeyframeAnimation with .cubic spline** — phantom tangent at endpoints; weird pre-windup motion
6. **SpringAnimator with Wave-style velocity retarget** — anchor offset bug from direct transform writes
7. **Sequential CABasicAnimations easeOut→easeOut** — velocity discontinuity at the join
8. **Additive CABasicAnimations with brief overlap** — partial fix; still L-shape from dimensional handoff
9. **Fully simultaneous animations with same easings** — straight diagonal in motion-space
10. **Asymmetric easings with full simultaneity** — the breakthrough

Each failure eliminated a hypothesis. After 10+ iterations the hypothesis space had contracted to a single remaining candidate: multiple complementary curves on the same property, composed via `isAdditive = true`, with mismatched easings across dimensions producing a cane curve in motion-space.

The breakthrough wasn't insight from nowhere. It was the only candidate left after the failures eliminated everything else.

### The articulation came later

For many weeks after the prototype shipped, the team could *use* the substrate but couldn't *describe* it as more than "we built it custom." The phenomenological framing — that DotPinch operates under a different phenomenology than orthodox iOS — emerged through long conversation about what made the experience feel different.

Specifically, the articulation arrived through:

- Recognizing that "we used `sublayerTransform`" wasn't the right level — many engineers have used it; we treated it as load-bearing substrate (the **TIER ELEVATION** move)
- Recognizing that "iOS apps are usually different" wasn't precise enough — iOS apps default to a *discontinuous-spatial phenomenology* (named, structured)
- Recognizing that "ours is unorthodox but tasteful" had a structural explanation — every decision propagates from one phenomenological commitment, producing internal coherence

The articulation is itself a record of work. It took as long to find the words as it took to build the substrate.

### The meta-acknowledgment

This is why the README is structured the way it is. Documentary intro (defines terms neutrally). Manifesto core (states what we built). Narrative for the journey (how we arrived). Implementation propagation (how the philosophy shows up in code). Framework (how to do this again).

We are documenting now what was tacit then so that future-us, future contributors, and future tools (the AI assistants reading `CLAUDE.md`) inherit not just the code but the *phenomenology the code expresses*. The substrate without the phenomenology is just unusual code. The phenomenology without the substrate is empty philosophy. Together they are the project.

---

## 7. How the Phenomenology Propagates Into Implementation (Code Grounding)

For each layer of the codebase, the phenomenological commitment manifests as specific architectural decisions. These are concrete and can be inspected.

### Substrate layer

| Decision | File:Line | What the phenomenology requires |
|---|---|---|
| Camera as value type | [`Camera.swift`](DotPinchPrototype/Conversation/Timeline/Camera.swift) | The world has a single spatial state owned by the controller, not a view |
| sublayerTransform as the camera applier | [`TimelineCanvas.swift:470`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift) | All visible cells inherit one matrix atomically (phase-locking) |
| m34 perspective installed once at init | [`TimelineCanvas.swift:174-176`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift) | The world has depth; Z-translations are visually meaningful |
| Edge mask gradients | [`TimelineCanvas.swift:182+`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift) | The world has horizons; off-screen fades rather than clips |

### Animation layer

| Decision | File:Line | What the phenomenology requires |
|---|---|---|
| Single CADisplayLink in AnimationController | [`AnimationController.swift`](DotPinchPrototype/Animation/AnimationController.swift) | One heartbeat for the world; animators don't have private timers |
| CABasicAnimation directly on CALayer | [`TimelineCanvas.swift:1273-1300`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift) | Sub-keypath access (transform.scale, transform.translation.y); additive composition |
| `isAdditive = true` on all morph animations | [`TimelineCanvas.swift:1297-1300`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift) | Complementary curves compose to velocity continuity |
| `CATransaction.withSuppressedActions` discipline | [`CATransaction+Helpers.swift`](DotPinchPrototype/Animation/CATransaction+Helpers.swift) | Implicit animations forbidden; all motion is explicit |
| Spring physics with velocity-preserving retarget | [`SpringAnimator.swift`](DotPinchPrototype/Animation/SpringAnimator.swift) | Motion is physical, not curve-parametric; interruption preserves momentum |
| `@frozen enum AnimatorState` | [`AnimatorProviding.swift`](DotPinchPrototype/Animation/AnimatorProviding.swift) | The animator state machine is exhaustive and committed |

### Domain / state layer

| Decision | File:Line | What the phenomenology requires |
|---|---|---|
| Identity-keyed cell pool | [`TimelineCanvas.swift:47-48`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift) | Cells have ongoing identity; same conversation → same view instance |
| `dequeueCell(preferredConversationID:)` | [`TimelineCanvas.swift:763`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift) | State preservation across reuse is the contract |
| `returnToPool(_:)` preserves state | [`TimelineCanvas.swift:797`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift) | In-flight animations + scroll position + composer text survive pool round-trip |
| EngagementState ladder | [`EngagementState.swift`](DotPinchPrototype/Conversation/Timeline/EngagementState.swift) | The engagement state machine is explicit (.idle / .engaged(completion:) / .stopping) |
| GestureCommit classification | [`GestureTypes.swift`](DotPinchPrototype/Conversation/Timeline/GestureTypes.swift) | Pinch release is a three-way decision (.tapToChat / .pinchToCells / .cancelled), not binary |
| `activeCellIndex + morphInProgress + isQuiet` | [`TimelineCanvas.swift`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift) | Three coordinated predicates gate which gestures can fire |

### Gesture layer

| Decision | File:Line | What the phenomenology requires |
|---|---|---|
| Custom canvas owns recognizers directly | [`TimelineCanvas.swift:246-256`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift) | Gesture interpretation is the canvas's, not a framework wrapper's |
| Pinch as transition gesture | [`TimelineCanvas.swift:998+`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift) | Gestures cause world transformations directly; pinch is not zoom-within-content |
| Pan + Pinch simultaneous recognition | [`TimelineCanvas.swift:1540-1543`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift) | No framework-mediated gesture conflict |
| Velocity-biased commit threshold | [`TimelineCanvas.swift:1107-1144`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift) | Gestures read intent (position + velocity + origin), not just final position |

### Lifecycle layer

| Decision | File:Line | What the phenomenology requires |
|---|---|---|
| DispatchWorkItem for cancellable reveal | [`TimelineCanvas.swift:1311-1321`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift) | Mid-flight state changes can interrupt the reveal cleanly |
| UIScene.willDeactivateNotification observer | [`V2RootViewController.swift:64-69`](DotPinchPrototype/App/V2RootViewController.swift) | Backgrounding mid-morph cancels in-flight animations without leaving broken state |
| `cancelInFlightAnimations()` coordination | [`TimelineCanvas.swift:1443`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift) | Surgical cancellation; per-animator stop, not blanket `removeAllAnimations` |

### Composition root

| Decision | File:Line | What the phenomenology requires |
|---|---|---|
| AnimationController constructed at root | [`V2RootViewController.swift:25`](DotPinchPrototype/App/V2RootViewController.swift) | The substrate's heartbeat is owned by the composition root, not embedded |
| TimelineCanvas receives AnimationController via init | [`V2RootViewController.swift:27`](DotPinchPrototype/App/V2RootViewController.swift) | Dependency injection at the composition root; no singletons |
| RevealCoordinator owns the reveal pipeline | [`RevealCoordinator.swift`](DotPinchPrototype/Conversation/Timeline/RevealCoordinator.swift) | The morph and the reveal are separate concerns with explicit handoff |

### What this table makes visible

Every entry in the table is a small decision. Each one, in isolation, looks like a reasonable engineering choice. The integrated picture — every choice propagating from one phenomenological commitment — is what produces the experience the user encounters.

If you change any one of these decisions, you partially break the phenomenology. Replacing `sublayerTransform` with per-cell transforms loses phase-locking. Replacing additive composition with single-curve animation loses velocity continuity. Replacing identity-keyed cells with anonymous reuse loses state persistence. The phenomenology is the intersection of all of these decisions, not any one of them.

---

## 8. The Five-Layer Framework

The articulation that produced this README applies to more than this project. It generalizes into a framework for *recognizing when and how to make moves like the one DotPinch made*.

```
LAYER 5 — SURFACES        where the moves land in product experience
LAYER 4 — MECHANISM       how each move is implemented (TIER ELEVATION)
LAYER 3 — VOCABULARY      the named moves the method generates
LAYER 2 — METHOD          disciplines that operationalize the stance
LAYER 1 — STANCE          the way of knowing that sees what others don't
```

### Layer 1 — The Stance (Phenomenological Materialism)

The visual phenomenon is the ground truth, not the framework documentation. Frame-by-frame empirical observation outranks WWDC sessions. Composition knowledge (how primitives combine) is the scarce thing. Refusal of implicit ontology (frameworks ENCODE claims about what kind of thing you're building; refuse them when they're wrong for your experience). Failure is information. Convergence is the match against the visual spec, not the elegance of the code.

### Layer 2 — The Method (10 Disciplines)

1. Visual spec before mechanism (frame-by-frame analysis as data, motion-space plots, derivative inspection)
2. Resisting single-mechanism thinking (composition over Frankenstein orchestration)
3. Triaging orthodoxy (load-bearing vs decorative — single render server is inviolable, "views are the things being animated" is decorative)
4. Counterfactual reasoning (REMOVAL, MUTATION, SUBSTITUTION before commitment)
5. Iteration discipline (hold spec frozen, vary mechanism, produce one written claim per iteration)
6. Spec the outcome, not the implementation
7. The "inevitable in retrospect" criterion (fighting test, surprise test, subtraction test)
8. Frame-by-frame as data not opinion
9. Reframing the question (level up when stuck)
10. Tasteful vs gimmicky discrimination (did the spec drive the mechanism, or did the mechanism drive the spec?)

### Layer 3 — The Vocabulary (Named Moves)

A periodic table of paradigm-break moves. Each one inverts a specific orthodoxy:

- Property-vs-Progress Inversion (drive single t → derive all)
- Push-Pull Inversion (substrate pushes; cells don't pull)
- State-Location Inversion (state in substrate, not in views)
- Identity Preservation over Anonymous Reuse
- Mask-vs-Clip Inversion (soft horizons)
- Layer-Over-View Animation (CABasicAnimation, not UIView.animate)
- Additive Composition over Single-Curve
- Imperative-vs-Physical (springs with velocity carry)
- Anchor Reframing (anchorPoint where the narrative happens)
- Projection-by-Commitment (m34 as ambient)
- World-First Coordinate Space (page-coords)
- Lifecycle-Ownership Inversion (you own visibility)
- Gesture-Replacement over Gesture-Negotiation
- Implicit-Animation Suppression as Discipline
- Continuous-Tick over Event-Driven Update
- Inertial Handoff (gesture and post-gesture are one continuous spring)

DotPinch stacks ~10 of these.

### Layer 4 — The Mechanism (TIER ELEVATION)

See §9. The act of taking a published mid/late 10% API and treating it as load-bearing architectural keystone.

### Layer 5 — The Surfaces (Where to Apply)

See §10. The map of UX surfaces where moves can land — navigation transitions, modal presentation, tab switching, list browsing, photo viewing, chat experiences, settings, onboarding, search, pull-to-refresh, empty states, hero animations, modality, loading states, deep linking.

---

## 9. TIER ELEVATION — The Mechanism

The act we made at the API level deserves its own name, because it's distinct from the existing "10/90 framework" axis (which is about *depth of knowledge* — public iOS surface vs Apple's private internal substrate).

**TIER ELEVATION** is the act of taking a published Apple API and changing its role in your architecture from passing utility to load-bearing substrate. The API doesn't change. Your relationship to it does.

### Definition

Most engineers operate on a single relational mode with any given API: call it when needed, then move on. `contentHost.layer.sublayerTransform = ...` appears in a parallax tutorial, gets copy-pasted into a project for a one-off effect, and is forgotten. The API was *used*. It performed a service. It was never *trusted* — never given a structural responsibility that the rest of the system depends on.

Tier elevation is the opposite: you take the same API and reorganize the codebase around it. Recognition criterion: **if you removed this API call, how much of the architecture collapses?** A used API leaves a hole — patch it with another approach. An elevated API leaves a crater — the surrounding code was *designed around its contract*; replacing it means rewriting the architecture.

### How it differs from 10/90

The 10/90 framework distinguishes:
- 10% = Apple's intentional developer surface (public APIs, documentation, WWDC sessions)
- 90% = Apple's internal substrate (private frameworks, undocumented behaviors, code-review tacit knowledge inside Apple)

TIER ELEVATION operates *entirely within the 10%*. Same surface, different role.

Two orthogonal axes:

| | LOW commitment | HIGH commitment |
|---|---|---|
| **LOW knowledge (10%)** | typical mid-tier iOS dev | unsustainable idiosyncratic build |
| **HIGH knowledge (10%+90%)** | WWDC-informed conventional apps | **PRINCIPAL-TIER WORK (DotPinch lives here)** |

Knowledge is necessary but not sufficient. Rare knowledge isn't even necessary. DotPinch's substrate uses APIs documented since iOS 2 (`sublayerTransform`) and 2010 (`m34`). The move wasn't *find the secret*. The move was *trust this one thing and build the house on it*.

### Where elevation lives: mid/late 10%

- **Early 10%** (UIView, UIViewController, Auto Layout): load-bearing by default in every iOS app. Floor, not move.
- **Mid 10%** (CABasicAnimation, CALayer.mask, UIDynamicAnimator, UIBezierPath, UIVisualEffectView): most engineers have used these once; few have made them the spine of a product.
- **Late 10%** (CATransform3D.m34, CAEmitterLayer, CAReplicatorLayer, UIPercentDrivenInteractiveTransition, CATiledLayer): exotic surface. Almost no one ships an app where they're central.

Tier elevation lives in mid and late 10%.

### Candidate APIs for elevation (beyond DotPinch's set)

| API | Typical use | Tier-elevated use | UX it unlocks |
|---|---|---|---|
| `CALayer.mask` + `CAGradientLayer` | Edge fade on a scroll view | Primary composition primitive — every reveal/transition/focus is a mask animation | Content reveals through *shape*, not fade |
| `CAEmitterLayer` | Confetti for completion | Primary visualization mechanism — particle streams represent live data | Information density that doesn't read as a chart |
| `CAReplicatorLayer` | Loading spinner; reflection | Multi-instance state mirror — render one, replicate N with offset transforms | Backgrounds that breathe coherently |
| `UIViewPropertyAnimator.fractionComplete` | Pause/resume an animation | Universal gesture-to-state primitive — every interaction is fractional scrubbing | Interruptible everything; the user's finger is the playhead |
| `UIPercentDrivenInteractiveTransition` | Custom swipe-back gesture | Every transition is interactive by default; tap is degenerate gesture | Every transition has a back-half you can grab and reverse |
| `UIDynamicAnimator + behaviors` | Novelty effect | Physics substrate for the layout system | Layouts that feel inhabited; cells nestle under gravity |
| `UIBezierPath + CAShapeLayer` | Custom shape | Layout-defining primitive; cells/focus indicators are paths | Non-rectangular interfaces that don't feel hacked |
| `UIVisualEffectView + UIBlurEffect` | Static frosted backdrop | Continuous-state surface; blur intensity scrubbed by interaction | Focus mode that fades by literal optical defocus |
| `intrinsicContentSize` | Override on custom label | Load-bearing contract for the layout system | Layouts that are content-shaped, not container-shaped |
| `UILayoutPriority` | Break constraint ties | Layout-system discriminator; preference graph, not constraint system | Layouts that gracefully degrade without manual size-class branching |
| `CATiledLayer` | PDF viewer; map tiles | Substrate for infinite content surfaces | Infinite whiteboards/mind maps that don't degrade |
| `UIContextMenuConfiguration` | Long-press preview | Primary action surface; tap is shortcut, long-press is full command set | Discoverability without UI clutter |

### Recognition discipline

Good candidates: mid/late 10%; composable (substrate for other things); stable (Apple won't deprecate); performant at elevated scale; geometric or temporal (operates on space or time); O(1) write produces O(N) propagation.

Disqualifies: early 10% (already universal); single-use by design; has a commonly-shipped "right way"; deprecation risk; doesn't compose.

---

## 10. How to Continue and Advance This Phenomenology (Concrete Directions)

DotPinch instantiates the continuous-embodied phenomenology for one specific UX (tap-to-chat morph + pinch-to-commit). The phenomenology generalizes. Below are concrete directions for advancing it — each describes a UX, the move it requires, what tier elevation makes it possible, and what the user would see.

### 10.1 The Photos app reimagined under continuous-embodied

**Move**: World-First Coordinate Space + Property-vs-Progress Inversion + Continuous-Tick

**Substrate**: a single zoomable scrollable layer with `sublayerTransform` driven by pinch velocity; the "grid view" is the camera pulled back; the "detail view" is the camera at z=0 on a single tile. Use `CATiledLayer` for performance at extreme zoom.

**User experience**: there is no "enter" or "exit" for a photo. There is one continuous zoom from the entire library to a single image, with intermediate stops (4-photo view, 16-photo view, single-photo view) as first-class states. The user scrubs the pinch gesture in either direction continuously and reversibly. No back button because no "back."

### 10.2 Chat conversations as temporal landscapes

**Move**: Property-vs-Progress Inversion (drive layout from time gaps) + Mask-vs-Clip Inversion (gradient seams at day boundaries)

**Substrate**: message density derived from inter-message time gaps. Rapid exchanges compress (tight stacking with shared backgrounds); long pauses create perceptual space (extra padding); day boundaries are gradient seams the eye registers as "the day broke here."

**User experience**: the shape of a conversation is visible at a glance. A burst at noon and a single reply at midnight don't look the same as a sustained 50-message exchange. The user reads not just *what* was said but *when* and *how fast*.

### 10.3 Settings as live in-place manipulation

**Move**: Lifecycle-Ownership Inversion + State-Location Inversion + UIVisualEffectView tier-elevation

**Substrate**: settings is a translucent overlay (`UIVisualEffectView` with `.systemUltraThinMaterial`) over the running app; every adjustment reflects in real time on the visible content below.

**User experience**: they tilt the world while standing in it. Adjusting "text size" doesn't navigate anywhere — the text behind the panel grows under their finger. Closing the panel confirms a state they've already been living in. No "Save."

### 10.4 Search as a lens, not a mode

**Move**: World-First Coordinate Space + Anchor Reframing

**Substrate**: typing the query doesn't change the screen; it applies a *filter transform* to the existing world. Non-matching items fade and shrink; matching items spring toward the top.

**User experience**: they start typing, and the world rearranges around their intent. They never lose their place. Clearing the query un-rearranges — items spring back. Search is filtering-as-physical-sorting, not navigating-to-a-different-screen.

### 10.5 Pull-to-refresh as physical reveal

**Move**: World-First Coordinate Space + Property-vs-Progress Inversion (pull distance drives the surface)

**Substrate**: the list's top edge stretches; the further pulled, the more "future" content peeks from above (real upcoming items, rendered at low opacity, slightly desaturated). Release at sufficient pull → items animate into final positions with a spring.

**User experience**: refresh is not a request — it is the visible arrival of what was already on its way. The user sees the data before they commit to fetching it. The indicator IS the content.

### 10.6 Modal presentation as Z-depth recession

**Move**: Projection-by-Commitment + Anchor Reframing

**Substrate**: present a modal by tilting the presenting view back into Z-depth (m34 = -1/800), rotating it 4° on X, scaling to 0.92x. The modal arrives at z=0.

**User experience**: the previous screen tilts away like a page laid flat on a desk; the new content arrives at the front of the room. Dismissal reverses — the room returns to vertical. Spatial, not stack-based.

### 10.7 Tab switching as lateral world

**Move**: World-First Coordinate Space + Inertial Handoff

**Substrate**: the tab bar is a horizontal index into a continuous lateral world. Adjacent tabs are spatially adjacent. Tapping tab 5 from tab 1 flies past 2/3/4 with brief motion blur (fast translation + alpha drop on intermediate tabs).

**User experience**: the app has lateral geography. They feel the distance between Library and Search. The tab bar is a map, not a remote.

### 10.8 Onboarding as progressive disclosure of the app itself

**Move**: Lifecycle-Ownership Inversion

**Substrate**: no onboarding screens. First launch shows the primary surface with one affordance highlighted via ambient pulsing on `shadowOpacity`. The next affordance becomes visible only after the first is used — composed in via opacity + slight scale-up from where it will live permanently.

**User experience**: they never see a tutorial. They see a quiet room that gains furniture as they learn to use it. The third or fourth affordance feels like discovery, not instruction. No "Skip" because nothing to skip.

### 10.9 Cross-screen micro-interactions: hero as identity propagation

**Move**: State-Location Inversion + Anchor Reframing

**Substrate**: the hero is the only continuous identity; all other elements on both screens are *derivative* of it. Destination's color palette sampled from the hero's image via `CIAreaAverage` at touch-down. Destination's shadow, typography color, accent ribbon are all derived from that sample.

**User experience**: tapping an album cover doesn't just expand the cover — it tints the entire destination with the cover's mood. Each detail screen looks designed for *that* item.

### 10.10 Modality (alerts/menus) as origin-emergence

**Move**: Anchor Reframing + Continuous-Tick

**Substrate**: dialogs emerge from the element that triggered them; surrounding world continues breathing at 0.3x energy. Soft tether (gradient/shadow line) connects dialog to origin.

**User experience**: the button they tapped *became* the dialog. The rest of the app didn't stop — it just got quieter. Dismissing is the button re-becoming a button.

### 10.11 Loading states as prediction-and-correction

**Move**: State-Location Inversion + Identity Preservation

**Substrate**: render structural prediction at full fidelity with low-confidence guesses from cache. Real data corrects each field with a quick 150ms crossfade as it arrives.

**User experience**: the screen is fully formed from frame one; values settle into truth like a photograph developing. Loading stops being a state and becomes a refinement.

### 10.12 Deep linking as immediate arrival

**Move**: Lifecycle-Ownership Inversion + State-Location Inversion

**Substrate**: app starts at the deep link with the back stack composed retroactively. Only when the user taps Back does the parent context construct itself, sliding in from the left.

**User experience**: they tapped a notification about Sarah's message and they *are* in the conversation with Sarah. No journey, no breadcrumb of screens flashing past. If they want context, they tap Back and the inbox materializes as revelation of surroundings.

### 10.13 List/feed browsing as attention-translation

**Move**: Property-vs-Progress Inversion + Continuous-Tick + Anchor Reframing

**Substrate**: drive a single continuous t-parameter from `contentOffset.y` against item size. Each visible item's scale/rotation/opacity/y-offset derives from its signed distance from the focal band. Items in the focal band sit at 1.0 scale; items above/below curve away on a cane-like trajectory.

**User experience**: the list breathes. There is one item that is *now*, and the rest curve away from it in both directions. Scrolling is not translation of a viewport — it's translation of *attention*.

### 10.14 Empty states as the first-content state

**Move**: State-Location Inversion + Lifecycle-Ownership Inversion

**Substrate**: empty state occupies the same layout populated state will occupy, with placeholder content that *demonstrates what will live there*. Placeholders are static (no shimmer), low opacity, with one primary affordance highlighted by ambient pulse.

**User experience**: the app is not empty — it is *waiting*, with the shape of its future visible at low intensity. Adding the first item doesn't reveal a new layout; it lights up the layout that was already there. First action feels like turning on a light, not building a room.

### 10.15 Notifications as world-bleed

**Move**: World-First Coordinate Space + Mask-vs-Clip Inversion

**Substrate**: a new notification doesn't slide in as a banner; the *current world dims at its edges* (gradient mask intensity rises), and the new content emerges from the dimmed region. Acknowledging it returns the world to its original luminance.

**User experience**: notifications don't interrupt — they cast a brief shadow over the world that the user can attend to or ignore. The current task doesn't stop; it darkens.

### 10.16 Image annotation as substrate-direct manipulation

**Move**: Layer-Over-View Animation + UIBezierPath tier-elevation

**Substrate**: annotations are CALayers added to the image's layer. Each annotation is a `UIBezierPath` rendered by `CAShapeLayer`. Manipulation gestures directly transform the path's control points.

**User experience**: drawing on an image feels like touching the image, not interacting with a tool layer above it. The annotation IS part of the image during manipulation.

### How to use this list

Each entry above is a sketch, not an implementation. Each requires careful substrate work to realize without becoming gimmicky. The discipline is the same: identify the orthodox baseline, identify the assumption that's contingent, invert it via tier elevation, verify the result is internally consistent with the rest of the app's phenomenology.

The list is open-ended. Any UX surface that has an orthodox default has an alternative under continuous-embodied phenomenology. Most of those alternatives have never been built because the substrate cost is high. They become tractable when the substrate has been built for *one* such experience and can be extended to others — which is the position DotPinch sits in.

---

## 11. The Phenomenology in Adjacent Crafts

The substrate-commitment move generalizes beyond iOS UX engineering. Every craft has an orthodox vocabulary (the 10% surface) and a tier-elevated practice (the same vocabulary used as substrate). The epistemic stance recognizes the second.

| Craft | Orthodox move | Substrate move |
|---|---|---|
| **Typography** | Pick a font + a size scale | Typography is a SYSTEM: hierarchy through subtraction, rhythm through vertical metrics, optical adjustment per axis, weight as structural primitive |
| **Motion design** | Spring presets + easeInOut | Motion is a PHRASE with onset/body/accent/tail; each segment with its own timing and overlap |
| **Haptics** | `UIImpactFeedbackGenerator(.medium)` at event | Haptics is CHOREOGRAPHY: phrase of impacts and intensities timed against visual motion, with onsets that precede/accent/trail |
| **In-app sound** | Single SFX per event | UI sound is a STATE LADDER: onset/body/decay/release per interaction; envelopes hand off to/from visual motion |
| **Color / luminance** | A palette of swatches | Color is a TEMPORAL SYSTEM: hue and luminance that shift with state, motion, focus, depth |
| **Layout** | Auto Layout constraints | Layout is a FIELD that responds to content/gestures/state; constraint priorities as discriminators; intrinsicContentSize as load-bearing |
| **Information architecture** | Tree of screens with navigation | Continuous space of objects with transformation |
| **Cinematography** | Cuts between shots | Continuous camera moves; depth as expressive |
| **Music** | Sequence of notes | Voice leading as substrate; tension/release as architecture |
| **Architecture (buildings)** | Rooms separated by walls | Continuous space organized by light and section |

The thread across all of these: every craft has a 10% surface vocabulary that is taught and a tier-elevated substrate that must be discovered. The stance recognizes the second. The recognition is not domain-specific — it is the same epistemic move applied to different material. Build the stance once and it transfers.

---

## 12. Running, Testing, Architecture

### Run

```bash
brew install xcodegen          # one-time
xcodegen generate              # regenerate the .xcodeproj
open DotPinchPrototype.xcodeproj
```

Pinch on the chat surface. In the simulator: hold Option for two-finger pinch.

Tested on iPhone 16 / iOS 18.0. Targets iOS 17+.

### Folder structure

```
DotPinchPrototype/
├── App/
│   ├── AppDelegate.swift                      Scene-lifecycle adoption
│   ├── SceneDelegate.swift                    Window + root VC composition
│   ├── V2RootViewController.swift             Composition root; owns AnimationController
│   └── UIView+Pin.swift                       Auto Layout pinning extension
├── Animation/                                 L1 — substrate (CADisplayLink + animators)
│   ├── AnimationController.swift              The master heartbeat
│   ├── AnimatorProviding.swift                Protocol + @frozen AnimatorState
│   ├── SpringAnimator.swift                   Wave-derived spring physics
│   ├── Spring.swift                           Spring parameters
│   ├── SpringInterpolatable.swift             Interpolation protocol
│   ├── CurveAnimator.swift                    Generic curve-based animator
│   ├── CATransaction+Helpers.swift            withSuppressedActions discipline
│   └── MathUtilities.swift                    Project, clamp, etc.
├── Conversation/
│   ├── Models/
│   │   ├── Conversation.swift                 Domain model
│   │   └── Message.swift                      Domain model
│   ├── Data/
│   │   ├── ConversationStore.swift            Data with identity preservation
│   │   └── DummyConversationLoader.swift      Sample data
│   ├── Geometry/
│   │   └── CoordinateSpace.swift              Typed wrappers (PageY, ViewportY, etc.)
│   ├── Tuning/
│   │   └── Tuning.swift                       PhysicsTuning + CellLayoutTuning
│   ├── ChatBody/
│   │   ├── ChatViewController.swift           Chat surface
│   │   └── ChatBubbleView.swift               Message bubble
│   └── Timeline/                              L3 — domain (timeline scene)
│       ├── TimelineCanvas.swift               THE CANVAS (substrate consumer)
│       ├── Camera.swift                       Domain primitive
│       ├── CellView.swift                     Cell with morph seams
│       ├── CameraAnimator.swift               L3 animator
│       ├── MorphChoreography.swift            Sendable snapshot
│       ├── MorphChoreographer.swift           @MainActor pinch-commit driver
│       ├── EngagementState.swift              Animator state machine
│       ├── GestureTypes.swift                 GestureCommit + PinchState
│       ├── TimelineDataSource.swift           Protocol + adapter
│       ├── RevealCoordinator.swift            L4 reveal pipeline
│       └── RevealBlurOverlay.swift            Blur surface
└── DesignSystem/
    ├── Theme.swift                            Color tokens
    ├── MorphTokens.swift                      Animation tokens (timing, curves, keys)
    ├── RevealTokens.swift                     Reveal pipeline timing
    ├── UIColor+sRGB.swift                     sRGB-locked CGColor helper
    ├── AccessibilityID.swift                  A11y identifiers
    └── SymbolName.swift                       SF Symbols
```

The 5-layer concurrency contract:
- L1 (Animation/): `@MainActor` substrate
- L2 (tokens, models, value types): `Sendable` value types
- L3 (Conversation/Timeline/): `@MainActor` domain
- L4 (MorphChoreographer, RevealCoordinator): `@MainActor` choreography
- L5 (App/V2RootViewController): `@MainActor` composition root

### Tests

```bash
xcodebuild -project DotPinchPrototype.xcodeproj -scheme DotPinchPrototype \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' build

# Invariant tests
xcodebuild -project DotPinchPrototype.xcodeproj -scheme DotPinchPrototype \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' \
  -only-testing:DotPinchPrototypeTests/InvariantHardeningTests test
```

InvariantHardeningTests cover 5 load-bearing invariants:
- SpringAnimator final-tick state ordering
- CellView centerY-anchored frame invariant
- Camera + extension spring.response coordination
- sRGBLockedCGColor color-space invariant
- ConversationStore.insert dual-index integrity

### Maestro flows

```bash
./scripts/run-maestro.sh
```

Flows in `.maestro/` — `smoke`, `pinch_in`, `pinch_out`, `mid_flight_reverse`, etc. **iOS 18 simulator only**: Maestro 2.5.1 returns an empty accessibility tree on iOS 26+ sims.

### Status

The substrate, the tap-to-chat morph (cane-curve trajectory via additive composition), the pinch-commit morph (MorphChoreographer + sin-bell Y/Z arc), the reveal pipeline, the cell pool with identity preservation, the engagement state machine, and the invariant hardening tests are all in place. The phenomenological articulation that this README captures was retrofitted onto the implementation through long conversation.

---

## 13. Appendix — The Cane-Curve Trajectory (Detailed Technical Reference)

The detailed technical exposition of the tap-to-chat morph's cane-curve trajectory — the deepest worked example of the phenomenology in action — lives below. It documents the 15+ failed iterations, the frame-by-frame methodology, the velocity-continuity problem, and the asymmetric-easings breakthrough. Read this to see how the phenomenological commitment shows up at the API and math level of one specific feature.

> Reference commit: **`78c129c`** — `tap-morph: lift-dominant head with slow-start zoom (cane-curve trajectory via additive composition)`
>
> Implementation: [`DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift`](DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift) → `func animateCameraToChatRest(forCellAt:)`

### A1. The visual specification

The motion runs over 5.4 seconds at the slowed-down analysis speed (production: ~0.8–1.2s by dividing all durations proportionally):

```
t=0.0 ─── tap fires; cell is at cell-rest
t=0.0 ─ 0.5  cell SHOOTS upward; scale barely changes
t=0.5 ─ 1.5  upward motion decelerating; cell beginning to inflate
t=1.5 ─ 3.0  lift mostly done; scale accelerating into the zoom
t=3.0 ─ 5.0  scale dominant; lift settled at peak
t=5.0 ─ 5.4  both motions damping; arriving at chat-rest
```

Two motion dimensions:
- **Lift** (`transform.translation.y`): target −50pt
- **Scale** (`transform.scale`): target 2.30× via `1.0 + 0.08 (windup) + 1.22 (zoom)`

Both run concurrently for the full duration. **At no point is only one dimension changing** — this property eliminates the perceptual L-corner.

### A2. The four CABasicAnimations

```swift
// On contentHost.layer, all with isAdditive = true, fillMode = .forwards,
// isRemovedOnCompletion = false

// 1. Windup scale — anticipation cue
windupScale: transform.scale, 0 → 0.08, duration 2.8s, easeOut

// 2. Zoom scale — dominant scale contribution
zoomScale: transform.scale, 0 → 1.22, duration 5.4s,
           timingFunction: (0.7, 0.0, 0.4, 1.0)   // slow-start bezier

// 3. Lift — vertical motion
translate: transform.translation.y, 0 → -50, duration 5.4s,
           timingFunction: (0.0, 0.0, 0.2, 1.0)   // aggressive easeOut

// 4. Centering — compensates active cell back to viewport center
centering: transform.translation.y, 0 → -cellOffsetFromViewportCenter * finalScale,
           duration 5.4s, timingFunction: (0.7, 0.0, 0.4, 1.0)
```

Because all are additive, the layer's effective transform at any moment is the sum. No orchestrator, no master timer, no per-frame tick.

### A3. Why the cane curve emerges

The trajectory in (lift, scale) motion-space:

```
SCALE:  1.0─────────────────────────────────────── 2.3
LIFT 0  ●
        │ (nearly vertical — lift moves, scale doesn't)
        ↓
        ●
         \  (curve begins — both moving)
          \
           ●_
             ──_  (handoff zone)
                ──___  (nearly horizontal — scale moves, lift doesn't)
-50                       ●
```

This is the cane shape. A neck at the start, a bend in the middle, a tail at the end.

Why this never produces an L:
- Lift duration = zoom duration (5.4s each). Neither completes before the other.
- Lift and zoom use different timing curves. Neither finishes proportionally to the other.
- At every moment, both dimensions are changing (even at vastly different rates).

### A4. Why velocity is continuous (the load-bearing math)

The single hardest perceptual challenge was eliminating velocity dips at animation transition boundaries. The position curves looked continuous; the *velocity* curves had zero crossings; the eye reads zero-velocity moments as perceptual stops.

The cubic Bézier endpoints' velocity is determined by the control points:
- Velocity at t=0 = `3 · c1y / c1x`
- Velocity at t=1 = `3 · (1 - c2y) / (1 - c2x)`

Any non-linear easing has a zero-velocity endpoint by construction. `easeOut`'s c2 = (0.58, 1.0) → velocity = 0 at end. `easeIn`'s c1 = (0.42, 0.0) → velocity = 0 at start. Sequential `easeOut → easeIn` joins have velocity zero on at least one side. Perceptual stop is inevitable.

**The breakthrough**: with multiple concurrent *additive* animations on the same property, the total velocity is the SUM:

```
total_scale_velocity(t) = windup_velocity(t) + zoom_velocity(t)
```

Each individual animation can dip to zero. Their *sum* doesn't have to dip, as long as one is high when the other is low. This is the complementary-curves principle: where one decelerates, another accelerates. The dip in one is masked by the other.

At t = 2.8s (the moment windup ends):
- `windup_velocity(2.8) = 0` (easeOut decelerating to zero)
- `zoom_velocity(2.8) > 0` (slow-start bezier in its peak-velocity region)
- `total = positive ≠ 0`. **No dip.** The math says so.

This is why the user perceives no stop. There is no stop.

### A5. The 15+ failed iterations (lessons in eliminated hypotheses)

Each prior failure produced a written claim about the design space:

1. **V2 motion (master CADisplayLink + per-tick orchestration)**: per-frame multi-property orchestration is fragile. Same motion can be expressed as a few well-tuned independent animations.
2. **Bounds-based extension with heightConstraint**: bounds-based animations interact badly with bounds-derived computations elsewhere. Use orthogonal dimensions (scale, a layer transform) instead of bounds (a layout property).
3. **Snapshot-based bitmap approaches**: snapshots add architectural complexity that pays off only when no native composition matches. Trust the frame analysis — pixel-diff disproved the snapshot hypothesis.
4. **CAKeyframeAnimation [easeOut, easeIn]**: position continuity is necessary but not sufficient. Velocity continuity is the perceptual bar.
5. **CAKeyframeAnimation .cubic spline**: cubic splines through arbitrary keyframes don't respect aesthetic intent at endpoints. Phantom tangents produce unexpected initial motion.
6. **SpringAnimator with Wave-style retarget**: writing `layer.transform` directly bypasses anchor centering. Use sub-keypath `setValue(_, forKeyPath: "transform.scale")` for anchor-respecting transforms.
7. **Sequential CABasicAnimations easeOut → easeOut**: replacing one velocity-zero with one velocity-jump doesn't fix the underlying problem. The velocity profile needs to be SMOOTH, not just non-zero.
8. **Additive with brief overlap**: overlap helps but isn't sufficient when other dimensions have sequential handoffs. ALL motion dimensions need to remain alive throughout.
9. **Fully simultaneous with same easings**: same easings on different dimensions = linear motion-space trajectory. Curved trajectories require *different* easings across dimensions.
10. **Asymmetric easings — the breakthrough**: lift uses front-loaded easeOut (0.0, 0.0, 0.2, 1.0); zoom uses slow-start bezier (0.7, 0.0, 0.4, 1.0). Both run concurrently. Lift dominates the early phase; zoom dominates the late phase. The trajectory in motion-space is the cane.

### A6. Frame-by-frame methodology

Frame extraction at actual frame rate (not metadata-reported):

```bash
ffprobe -loglevel error -select_streams v:0 -show_entries packet=pts_time \
  -of csv=p=0 path/to/video.mov | sort -n
```

Pixel-diff for sub-perceptual motion detection:

```bash
magick compare -metric AE -fuzz 1% baseline.png end.png diff.png
```

Diff visualization with `-highlight-color` reveals what moved by SHAPE, not just by magnitude. Vertical-slice temporal stacking (`magick "$f" -crop 8x1000+390+200`) reveals motion through a column over time as horizontal stripes.

### A7. Tuning reference (commit `78c129c`)

```swift
let windupDuration: CFTimeInterval = 2.8       // brief preparation cue
let totalMorphDuration: CFTimeInterval = 5.4   // analysis speed (production: 1.0–1.2s)

windupScale.fromValue = 0
windupScale.toValue = 0.08
windupScale.duration = windupDuration
windupScale.timingFunction = CAMediaTimingFunction(name: .easeOut)

zoomScale.fromValue = 0
zoomScale.toValue = 1.22
zoomScale.duration = totalMorphDuration
zoomScale.timingFunction = CAMediaTimingFunction(controlPoints: 0.7, 0.0, 0.4, 1.0)

translate.fromValue = 0
translate.toValue = -50
translate.duration = totalMorphDuration
translate.timingFunction = CAMediaTimingFunction(controlPoints: 0.0, 0.0, 0.2, 1.0)

// Final state at t=5.4s:
//   layer scale = 1.0 + 0.08 + 1.22 = 2.30
//   layer translation.y = -50pt
```

To rescale for production: divide all durations by the same factor (e.g., 4.5× faster → windupDuration = 0.62, totalMorphDuration = 1.2). Curves preserve their shape; only time scales.

### A8. The articulation lesson

The longest stretches of this work were not spent writing code. They were spent finding the right LANGUAGE to specify what the motion should look like.

Multiple times, the user described what they wanted in metaphors that didn't parse correctly: "cane shape, not L shape" was a motion-space description that was initially parsed as screen-space; "like a vertex but U-shape not V-shape" described the dimensional handoff, not the velocity curve; "perpendicular, facing me" meant a Z-axis component that was almost missed.

The pattern: visual specification problems are usually *larger* than implementation problems. Treat the conversation as the work. Use `AskUserQuestion` before building when the spec is ambiguous about its referent. Frame-by-frame analysis is the tie-breaker between user perception and code behavior — never argue without visual evidence.

Most failed iterations were not code failures. They were failures of *shared understanding* the code was supposed to encode. Once shared understanding crystallized (around motion-space framing), the code change was trivial.

This is the standard lesson of building visual systems. The implementation took ~30 minutes of typing. The articulation took weeks.

---

## Closing — Why This README Exists

The original README for this project described the project as "a UIKit prototype exploring pinch-to-memory." That description was accurate but missed what was actually built. What was built was an instantiation of a specific phenomenology of UI experience — one that orthodox iOS doesn't default to and that almost no shipping apps express.

The articulation in this README was assembled retroactively through long conversation. It is captured here so the *why* doesn't get lost the way orthodoxy lost its origins. Future-us, future contributors, and the AI assistants reading `CLAUDE.md` should be able to inherit not just the code but the phenomenology the code expresses.

If you change a load-bearing substrate decision in this codebase without understanding the phenomenological commitment it propagates from, you will partially break the experience the user has. That breakage will appear as something small and fixable. It will actually be a phenomenological inconsistency. The substrate decisions in this codebase are not optimizations or conventions; they are commitments to what kind of experience the user has when they tap a cell. Honor them.
