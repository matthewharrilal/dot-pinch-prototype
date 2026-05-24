# CLAUDE.md — Working in This Codebase

This file is read by AI assistants on every session in this repo. It exists so that the phenomenological commitment underlying every architectural decision in DotPinch is not lost or accidentally violated by tooling that doesn't see the *why* of the code, only the *what*.

The README.md is the philosophical foundation. This file is the operational consequence — what to do, what not to do, and why the defaults you would normally reach for are wrong here.

---

## Part 1 — The Phenomenological Orientation

### What this codebase is

DotPinch is constructed under **continuous-embodied phenomenology**, not the **discontinuous-spatial phenomenology** that iOS apps default to. The README explains both phenomenologies in detail; the short version:

- **Orthodox iOS**: tree of discrete screens; navigation via tap; transitions are punctuation marks between settled states; cells are anonymous and interchangeable; the framework manages lifecycle.
- **DotPinch**: one continuous world; transformation via gesture; time is unbroken; cells have persistent data-keyed identity; the canvas owns lifecycle.

Every architectural decision in this codebase propagates from the continuous-embodied commitment. If you change a decision without understanding the commitment, you partially break the phenomenology — and that breakage appears as something small and fixable but is actually a phenomenological inconsistency.

### What "honor the phenomenology" means concretely

When working in this codebase, before making any non-trivial change:

1. Read the README.md sections relevant to the area you're touching.
2. Identify what phenomenological commitment the existing code expresses.
3. Verify your change preserves that commitment.
4. If it doesn't, propose an alternative that does — or escalate to the user with the conflict named.

This is not a style preference. It is the architecture.

---

## Part 2 — Operational Patterns (What to Do, What Not to Do)

These are the day-to-day patterns that follow from the phenomenology. Treat each as a discipline; deviation requires justification.

### 2.1 Animation

**DO**: Use `CABasicAnimation` directly on `CALayer` for primary motion. Sub-keypath access (`transform.scale`, `transform.translation.y`) is the load-bearing capability that enables additive composition.

**DO**: Set `isAdditive = true` when composing multiple animations on the same property. This is how the cane curve is built (windup + zoom additively summing to the trajectory).

**DO**: Wrap every synchronous mutation in `CATransaction.withSuppressedActions { ... }`. The discipline is universal — implicit animations are *never* permitted to fire alongside our explicit ones.

**DO**: Use `SpringAnimator<T>` for physical motion where velocity continuity across interruption matters (gesture-to-animation handoff). Springs carry velocity across retargeting; curves do not.

**DON'T**: Reach for `UIView.animate(withDuration:)` as the default. It's not forbidden, but its use should be questioned: does this motion need velocity continuity? Does it compose with other motion? Should it be additive? Usually the answer is yes to at least one of these, and CABasicAnimation is the better tool.

**DON'T**: Animate `layer.transform` directly via `=` assignment when you want anchor-centered behavior. Use the sub-keypath form (`setValue(_, forKeyPath: "transform.scale")`) or `CABasicAnimation(keyPath: "transform.scale")`. The direct assignment bypasses the KVC anchor-handling and produces top-left-origin scaling bugs.

**DON'T**: Add a second `CADisplayLink` for any reason. The `AnimationController`'s display link is the single heartbeat. Animators register with it as subscribers via the `AnimatorProviding` protocol. Path A (the substrate consolidation move) explicitly forbids parallel display links.

### 2.2 Substrate

**DO**: Treat `contentHost.layer.sublayerTransform` as THE camera. Every scroll-related write goes through `applyCameraTransform()` which mutates this one matrix. All cells inherit it.

**DO**: Treat `canvas.layer.sublayerTransform.m34` as a load-bearing architectural commitment. It is set once at install and never touched. Its value (`-1/1000`) is calibrated for the Z-magnitudes used in the pinch-commit sin-bell arc.

**DO**: Add new visual elements as children of `contentHost` if they should inherit the camera/morph transforms, or as siblings of `contentHost` if they should NOT inherit them (e.g., overlays that should stay viewport-fixed).

**DON'T**: Add a `UIScrollView` for any "easy scrolling" need. The camera IS the scroll primitive. UIScrollView's contentOffset is a parallel scroll mechanism that would compete with the camera and break phase-locking.

**DON'T**: Mutate `contentHost.layer.sublayerTransform` outside of `applyCameraTransform()`. This is the camera-update funnel; bypassing it desynchronizes the camera value from the rendered position.

**DON'T**: Touch `m34` after init. Changing focal length changes the visual physics of the entire app. If you genuinely need different perspective for a feature, propose it explicitly — it's an architectural decision, not a tuning value.

### 2.3 Cells

**DO**: Use `dequeueCell(preferredConversationID:)` for cell vending. This preserves cell-to-conversation identity binding.

**DO**: Use `returnToPool(_:)` (not `removeFromSuperview`) for cell teardown. This preserves in-flight animations, scroll position, composer text across the round-trip.

**DO**: Add new cell state (e.g., a new label, a new sub-animation) as state that survives pool round-trip. The cell pool's contract is that state persists; respect it.

**DON'T**: Reset cell state in any function analogous to `prepareForReuse`. The cell pool's contract is the *inverse* of `UICollectionView`'s. State persists. Resetting it is a phenomenological violation.

**DON'T**: Anonymize cell-to-data binding. Cells are identity-keyed by `conversationID`. Switching to anonymous reuse (e.g., by index alone) would break state preservation across reuse cycles.

**DON'T**: Add a `UICollectionView` or `UITableView` for "convenience" in some new feature. The cell pool semantics are incompatible with `dequeueReusableCell`'s contract. If a list-like feature is needed, use the existing `TimelineCanvas` substrate or build a new canvas that follows the same pattern.

### 2.4 Gestures

**DO**: Attach gesture recognizers directly to `TimelineCanvas` (not to a wrapping `UIScrollView`). The canvas owns gesture interpretation end-to-end.

**DO**: Allow pan + pinch simultaneous recognition via the canvas's `UIGestureRecognizerDelegate` (see `TC:1540-1543`). No framework-mediated conflict resolution.

**DO**: Use the three-way `GestureCommit` classification (`.tapToChat / .pinchToCells / .cancelled`) for pinch-end interpretation. The classification considers geometry + velocity + origin.

**DON'T**: Treat pinch as a zoom gesture for content inside a view. In this codebase, pinch is a transition gesture (it commits to a chat-rest state). Adding a "pinch to zoom this image" feature without explicit phenomenological reconciliation would create gesture-vocabulary inconsistency.

**DON'T**: Use UIScrollView's built-in pan recognizer for any new scrollable surface. Build a custom pan recognizer that writes to a camera primitive, the same way `TimelineCanvas`'s pan handler does.

### 2.5 State

**DO**: Respect the engagement state machine: `activeCellIndex` + `morphInProgress` (derived predicate on CellView) + `isQuiet` (derived predicate on canvas). These three together gate which gestures can fire when.

**DO**: Use `EngagementState` (`.idle / .engaged(completion:) / .stopping`) for animator completion ladders. The completion-carrying case is load-bearing for coordinating multi-animator settles.

**DO**: Maintain `ConversationStore`'s dual-index invariant — `conversations: [Conversation]` (insertion-ordered) and `conversationsByID: [UUID: Conversation]` (keyed). These must stay in sync; the `insert` method has a `precondition` enforcing it.

**DON'T**: Bypass the engagement-state predicates for "convenience." If a new gesture seems to need to fire during a morph, propose extending the state machine — don't carve out an exception.

**DON'T**: Replace `EngagementState`'s case-based state machine with a plain enum or set of bools. The associated values (the completion closure on `.engaged`) are load-bearing.

### 2.6 Concurrency (9S contract)

The codebase has a per-layer concurrency contract:

| Layer | Path | Annotation |
|---|---|---|
| L1 — Animation substrate | `Animation/` | `@MainActor` (UI-bound substrate) |
| L2 — Tokens, models, value types | `DesignSystem/`, `Conversation/Models/`, `Conversation/Tuning/`, `Conversation/Geometry/`, `GestureTypes.swift`, `MorphChoreography.swift` | `Sendable` (value types) |
| L3 — Domain | `Conversation/Timeline/`, `Conversation/ChatBody/`, `Conversation/Data/` | `@MainActor` |
| L4 — Choreography / lifecycle | `MorphChoreographer.swift`, `RevealCoordinator.swift`, `RevealBlurOverlay.swift` | `@MainActor` |
| L5 — Composition root | `App/V2RootViewController.swift`, `App/SceneDelegate.swift` | `@MainActor` |

**DO**: Honor the layer's annotation when adding new types. L2 value types must be `Sendable`. L1/L3/L4/L5 reference types must be `@MainActor`.

**DON'T**: Add ad-hoc concurrency annotations that violate the contract. If a new type doesn't fit cleanly into a layer, propose extending the contract rather than carving an exception.

### 2.7 Lifecycle

**DO**: Use `DispatchWorkItem` for cancellable deferred work that crosses state boundaries (see the reveal-ready callback at `TC:1311-1321`). Store the work item so it can be cancelled if state changes mid-flight.

**DO**: Observe `UIScene.willDeactivateNotification` for any new in-flight animation system. The existing handler calls `cancelInFlightAnimations()` + `revealCoordinator.cancelInFlight()` — extend it for new cancellable systems.

**DON'T**: Use `dispatch_after` / `DispatchQueue.main.asyncAfter` without a cancellation handle. Deferred work that can outlive its predicate is a bug.

**DON'T**: Use `view.layer.removeAllAnimations()` as a "reset" mechanism. Per-animator stop methods (`animator.stop(immediately:)`) are surgical; the blanket remove is heavy-handed and breaks the engagement state machine.

---

## Part 3 — The Test Question

Before any non-trivial change, ask:

1. **Does it introduce discrete states?** (Adding a new screen, a modal, a "mode" the user enters/exits) → Bad. Look for a way to express it as a continuous transformation of the existing surface.

2. **Does it break phase-locking?** (Per-element animations that need careful scheduling, parallel transforms outside `sublayerTransform`) → Bad. Find a way to use a shared parent transform.

3. **Does it require anonymous cell reuse?** (`prepareForReuse`-style resets, type-keyed dequeue without identity binding) → Bad. Preserve the identity-keyed pool semantics.

4. **Does it use `UIView.animate` for primary motion?** (Where the motion has user-visible weight, where interruption needs velocity continuity) → Question whether `CABasicAnimation` or `SpringAnimator` is more appropriate.

5. **Does it use `UIScrollView.contentOffset` as a scroll mechanism?** (Where the camera primitive should be the truth) → Bad. The camera value type is the truth.

6. **Does it bypass the engagement state machine?** (Firing animations during a morph, ignoring `isQuiet`) → Bad. Extend the state machine instead.

7. **Does the proposed visual outcome match the phenomenology?** (Continuous transformations of objects in place, not discrete state changes) → If unclear, do frame-by-frame analysis of a reference; treat the reference as the spec.

8. **Does every decision propagate from the same phenomenological commitment?** (Or is this an isolated fix?) → Isolated fixes that don't propagate are usually gimmicks. Propagation produces taste.

If any answer is concerning, propose the alternative that aligns with the phenomenology. Escalate to the user if the alternative isn't clear.

---

## Part 4 — Architectural Keystones (Don't Touch Without Reason)

These are load-bearing. Modifying them requires explicit user discussion.

| Keystone | Why it's load-bearing |
|---|---|
| `contentHost.layer.sublayerTransform` as the camera applier | Phase-locking guarantee depends on this single parent transform. Splitting it across multiple layers loses atomicity. |
| `canvas.layer.sublayerTransform.m34 = -1/1000` | Visual physics commitment. Changing focal length changes the depth feeling of the entire app. |
| `AnimationController`'s single `CADisplayLink` | Path A enforces one heartbeat. Adding a second display link forks the timing source. |
| `cellPoolByConversationID` identity-keyed pool | State preservation across reuse depends on this. Replacing with anonymous reuse breaks the phenomenology. |
| `CATransaction.withSuppressedActions` discipline | Implicit-animation suppression is universal. Skipping it lets framework defaults compound with explicit animations. |
| `EngagementState.engaged(completion:)` carrying closure | The completion closure carries the state-transition continuation; replacing with a plain enum loses the multi-animator coordination. |
| 4 additive `CABasicAnimation`s in `animateCameraToChatRest` | Removing any one breaks velocity continuity or the cane curve. Each is doing a specific job. |
| `MorphChoreographer`'s sin-bell Y/Z arc | The 3D depth feeling of the pinch-commit morph depends on this specific arc shape. |
| 5 invariant asserts in `InvariantHardeningTests` | These encode load-bearing invariants discovered through audit. Failing tests are real bugs, not test-suite noise. |

---

## Part 5 — Code Conventions

These are mechanical patterns to follow without thinking.

### Style

- **NO COMMENTS** unless a hidden constraint exists that the reader cannot infer from well-named identifiers. Default zero. Single-line WHY only where genuinely non-obvious.
- **NO multi-line `//` blocks** explaining what the code does. Names do that.
- **NO references to tasks, audits, PR numbers, or amendment IDs in code**. They rot.
- **NO docstrings** restating method names. If the doc just repeats the signature, delete it.

### File organization

- **L1 substrate**: `Animation/`
- **L2 value types**: `DesignSystem/` (tokens), `Conversation/Models/` (domain models), `Conversation/Tuning/` (config), `Conversation/Geometry/` (coordinate types), plus `MorphChoreography.swift` and `GestureTypes.swift` co-located with their L3 consumers
- **L3 domain**: `Conversation/Timeline/`, `Conversation/ChatBody/`, `Conversation/Data/`
- **L4 choreography**: `MorphChoreographer.swift`, `RevealCoordinator.swift`, `RevealBlurOverlay.swift`
- **L5 composition root**: `App/`

When creating new files, place them in the layer that matches their responsibility. Do not cross layers.

### Commit cadence

- One commit per meaningful checkpoint (typically one "wave" of related changes).
- Terse one-line subject; multi-line body if necessary.
- NEVER include `Co-Authored-By: Claude` or similar AI attributions in commit messages.
- NEVER use `--no-verify` to skip pre-commit hooks.
- NEVER amend an existing commit; create a new one.

### Build verification

Before claiming work is done:

```bash
xcodebuild -project DotPinchPrototype.xcodeproj -scheme DotPinchPrototype \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' build
```

After non-trivial changes, also run the invariant tests:

```bash
xcodebuild -project DotPinchPrototype.xcodeproj -scheme DotPinchPrototype \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' \
  -only-testing:DotPinchPrototypeTests/InvariantHardeningTests test
```

20 baseline test failures pre-exist (visual-diff infra issues, not code regressions). Don't chase them.

---

## Part 6 — When to Escalate to the User

Escalate to the user (don't proceed silently) when:

- A proposed change would violate one of the architectural keystones in Part 4.
- A proposed change would violate the phenomenology (would introduce discrete states, anonymous reuse, framework-mediated transitions, etc.).
- The user's stated visual outcome and the available mechanisms don't have an obvious match — ask for clarification using `AskUserQuestion` before building.
- An existing convention is unclear and your interpretation could go either way.
- A "fix" would touch the cane-curve trajectory, the MorphChoreographer's arc parameters, the m34 focal length, or other tuning values that the README/cane-curve doc identifies as load-bearing.

Escalation is not failure. It is the discipline of not silently breaking the phenomenology.

---

## Part 7 — Pointers

- **Phenomenological foundation**: [`README.md`](README.md) — read sections 1-6 if you've never worked in this codebase before; sections 7-11 for advancing the phenomenology.
- **Architecture overview**: [`docs/architecture.md`](docs/architecture.md) — the 5-layer architecture.
- **Animation substrate**: [`docs/animation-substrate.md`](docs/animation-substrate.md) — `AnimationController`, `SpringAnimator`, `CurveAnimator`.
- **Keystones K1-K8**: [`docs/keystones.md`](docs/keystones.md) — the named invariants the substrate enforces.
- **Megafile memo**: [`MEGAFILE-MEMO.md`](MEGAFILE-MEMO.md) — re-evaluation deadline for `TimelineCanvas` decomposition (2026-12-01).
- **Cane-curve technical reference**: [`README.md` § Appendix](README.md#13-appendix--the-cane-curve-trajectory-detailed-technical-reference) — deepest worked example of the phenomenology in action.

---

## Part 8 — The Spirit

This codebase is not orthodox. It is internally consistent. The unorthodoxy is at the substrate level; the rest is conventional in service of the substrate's commitment.

When you work here, your job is to preserve the consistency. Conventions and "best practices" from the broader iOS ecosystem are inherited under the assumption of the orthodox phenomenology — many of them don't apply here. Question every default. Match the phenomenology, not the convention.

If something feels wrong, it probably is — but the wrongness is usually that a default you absorbed elsewhere doesn't fit here, not that this codebase has a bug. Investigate the phenomenological reason before "fixing."

The phenomenology is what makes this product what it is. The code is downstream of it. Honor the phenomenology; the code follows.

