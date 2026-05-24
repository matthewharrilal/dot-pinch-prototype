# Architecture

DotPinch is a single-screen iOS prototype: a stack of conversation cells that pinch / tap into a chat surface. The codebase is structured as five layers with strict, one-way dependencies.

## Layers

```
L5  App                         composition root (V2RootViewController, AppDelegate)
L4  Choreography                MorphChoreographer, RevealCoordinator
L3  Domain                      TimelineCanvas, CellView, Camera, ConversationStore
L2  Tokens                      Theme, MorphTiming, RevealTiming, PhysicsTuning, CellLayoutTuning
L1  Animation substrate         AnimationController, SpringAnimator, CurveAnimator, Spring
```

Inner layers do not import outer layers. `Animation/` (L1) imports only `Foundation` + `QuartzCore`. `DesignSystem/` (L2) imports only `Foundation` + `CoreGraphics` + `UIKit`. `Conversation/Timeline/` (L3) imports L1 and L2. `Conversation/ChatBody/` is L3-peer (chat-state surface). `App/` (L5) imports everything.

## File map

```
DotPinchPrototype/
├── App/
│   ├── AppDelegate.swift
│   ├── V2RootViewController.swift          (composition root)
│   └── UIView+Pin.swift                    (layout helper)
├── Animation/                              (L1 substrate)
│   ├── AnimationController.swift           (single CADisplayLink, ticks all animators)
│   ├── AnimatorProviding.swift             (animator contract)
│   ├── SpringAnimator.swift                (generic stateful spring integrator)
│   ├── CurveAnimator.swift                 (generic deterministic curve animator)
│   ├── Spring.swift                        (spec value-type: damping + response)
│   ├── SpringInterpolatable.swift          (numeric protocol + CGFloat conformance)
│   ├── MathUtilities.swift
│   └── CATransaction+Helpers.swift         (withSuppressedActions)
├── DesignSystem/                           (L2 tokens)
│   ├── Theme.swift, MorphTiming.swift, MorphCurves.swift, MorphAnimationKey.swift
│   ├── RevealTiming.swift, LabelFadeTiming.swift
│   ├── AccessibilityID.swift, SymbolName.swift, UIColor+sRGB.swift
├── Conversation/
│   ├── Models/                             (L3 — domain types)
│   │   ├── Conversation.swift, Message.swift
│   ├── Data/                               (L3 — persistence + fixtures)
│   │   ├── ConversationStore.swift, DummyConversationLoader.swift
│   ├── Geometry/                           (L3 — coordinate-space types)
│   │   └── CoordinateSpace.swift           (PageY, ViewportY, ScaleFactor, DampingRatio)
│   ├── Tuning/                             (L3-adjacent — feature-specific tokens)
│   │   ├── PhysicsTuning.swift, CellLayoutTuning.swift
│   ├── Timeline/                           (L3 — the timeline surface)
│   │   ├── TimelineCanvas.swift            (the megaclass; <1200 LOC)
│   │   ├── CellView.swift                  (cell-rest summary tile)
│   │   ├── Camera.swift                    (page-y → viewport-y mapping)
│   │   ├── CameraAnimator.swift            (wraps SpringAnimator<CGFloat>)
│   │   ├── MorphChoreographer.swift        (L4 inside Timeline by adjacency)
│   │   ├── MorphChoreography.swift         (spec value-type)
│   │   ├── RevealCoordinator.swift         (L4 — chat presentation orchestrator)
│   │   ├── RevealBlurOverlay.swift
│   │   ├── EngagementState.swift, GestureCommit.swift, PinchState.swift
│   │   ├── TimelineDataSource.swift, TimelineDataSourceAdapter.swift
│   └── ChatBody/                           (L3 — chat-state surface)
│       ├── ChatViewController.swift, ChatBubbleView.swift
```

## Dependency direction

```
   App (L5)
     ↓
   Choreography (L4) ──┐
     ↓                  ↓
   Domain (L3) ──→ Tokens (L2)
     ↓
   Animation (L1)
```

Every arrow is enforced by what the file `import`s. There are no protocol-shimmed exceptions to the direction.

## Ownership

- **`AnimationController` is owned by `V2RootViewController`** (composition root). Hoisted at Wave 3 to make the controller per-app, not per-canvas. The instance is passed into `TimelineCanvas.init(controller:)`. This is what Keystone K8 (per-canvas AnimationController instance identity) enforces — the canary test (`WaveR41SubstrateCanaryTests`) asserts `cameraAnimator` and `extensionAnimator` share the same controller instance.
- **`ConversationStore` is owned by `V2RootViewController`** and passed into `TimelineDataSourceAdapter`. Source of truth for the conversation list.
- **`TimelineCanvas` owns its `cameraAnimator` + `extensionAnimator` + `morphChoreographer`**. The choreographer holds a `weak` reference back to the canvas.
- **`RevealCoordinator` is owned by `V2RootViewController`**. It manages the chat-presentation lifecycle (blur fade in, controller add, blur fade out, swap-back on dismiss). Holds a weak reference to its host VC.
- **Composition root is the only place where dependencies are constructed.** No `.shared`, no service locator, no environment injection. Verified by grep at every wave-close gate.

## Concurrency contract

Every public type in L1-L4 is `@MainActor`-isolated. Model types in `Conversation/Models/` are `@MainActor`-isolated `@Observable` classes (reference-type identity for binding stability). The `Spring`, `Camera`, `MorphChoreography`, `PhysicsTuning`, `CellLayoutTuning`, `PageY`, `ViewportY`, `ScaleFactor`, `DampingRatio` value-types are `Sendable`. There is no `Task`, no `async`, no actor-hop in the per-frame tick.

## What this isn't

- **No DI framework.** Composition root only. The rejection list (REFACTOR-CHECKLIST.md §rejection) explicitly refuses witnesses, service locators, `@Environment`, and Resolver/Swinject.
- **No reactive bindings (Rx / Combine).** `@Observable` is used only for stable identity, not for stream-based propagation.
- **No SwiftUI.** UIKit + CALayer + CADisplayLink throughout.
- **No protocol-everything.** Protocols exist only where there is a real substitution boundary (e.g. `TimelineDataSource`, `AnimatorProviding`). Pre-generic-ing a hypothetical second cell type was explicitly rejected.

## See also

- `docs/animation-substrate.md` — the L1 substrate in detail.
- `docs/keystones.md` — the 8 substrate-defining decisions (K1-K8).
- `REFACTOR-CHECKLIST.md` — full migration ledger, 10 pillars of code quality, rejection list.
