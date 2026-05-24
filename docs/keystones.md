# Keystones

The 8 substrate-defining decisions. Each is load-bearing — touching one is OUT OF SCOPE for any refactor. Each is enforced either by canary test, by runtime `assert`, or by structural impossibility (e.g. there is no second instance of the type to compare against).

## K1 — `sublayerTransform`-driven camera

**Site:** `Conversation/Timeline/TimelineCanvas.swift` `applyCameraTransform()` (~line 467), `transform3D(for:viewportCenter:)` (~line 476).

The camera is **not** a transform on cells. It is a single `CATransform3D` applied to `contentHost.layer.sublayerTransform`. Every cell is a subview of `contentHost`; every cell inherits the camera transform through the layer tree.

```swift
contentHost.layer.sublayerTransform = CATransform3DMakeTranslation(
    0, viewportCenter.y - camera.translation, 0
)
```

**Why it's load-bearing:** multi-property phase-locking depends on it. Z-translation per cell stacks on top of the camera's Y-translation in one matrix, with foreshortening from `m34 = -1/1000`. A per-cell transform model would require manual recompositing every frame and would lose the matrix-stack semantics CAlayer provides for free.

**Invariant:** the cell's own `layer.transform` is always `CATransform3DIdentity`. The camera lives on `contentHost.layer.sublayerTransform`, never on the cell. Enforced structurally — `CellView.init` sets identity once (`CellView.swift:122`) and nothing else writes `layer.transform` on a cell.

## K2 — Cell pool LIFO + UUID-keyed secondary index

**Site:** `Conversation/Timeline/TimelineCanvas.swift` cell-pool dequeue (search `dequeueCell`), `TimelineDataSource.canvas(_:conversationIDForCellAt:)`.

Cells are pooled. The pool dequeues in LIFO order, with a UUID-keyed secondary index that prefers the cell instance previously bound to a given `Conversation.id`. State preserved across pool round-trips: scroll offset, draft text, cursor, extension height.

**Why it's load-bearing:** state preservation across pool round-trips. A pure-LIFO pool would let a cell that previously hosted conversation A get re-bound to conversation B, losing A's in-cell state. The UUID index lets the pool say "if a cell for this conversation is in the free list, reuse it."

**Invariant:** `CellView.activeConversationID` matches the `Conversation.id` it is currently displaying. Reset to `nil` only via `invalidateConversationBinding()` (`CellView.swift:137`) — the pool-return path.

## K3 — `activeCellIndex` + `tryClearActiveCellAtRest` dual-spring AND-gate

**Site:** `Conversation/Timeline/TimelineCanvas.swift` `tryClearActiveCellAtRest` (~line 1508), `springToCellRest` (~line 1465).

Returning from chat-rest to cell-rest involves TWO springs (camera Y + extension height). Both must settle before `activeCellIndex` clears — otherwise camera lands at cell-rest while the cell is still tall, or the cell shrinks while the camera is still moving.

The clear is **AND-gated on value-vs-target**, not animator state, because `SpringAnimator` fires completion BEFORE setting `state = .ended`:

```swift
let cameraAtTarget = abs(camera.translation - cellRestTarget) < 1.0
let extensionAtTarget = abs(extensionValue - cell.naturalHeight) < 1.0
if cameraAtTarget && extensionAtTarget {
    setActiveCellIndex(nil)
    restoreNaturalSiblingOrder()
}
```

**Why it's load-bearing:** closes the camera/extension settle race. Earlier versions used "camera completion fires → clear active cell" and silently broke under camera same-target short-circuit (camera fires synchronously while extension is still tall).

**Invariant:** completion firing order. `SpringAnimator.updateAnimation` asserts at the final tick (`SpringAnimator.swift:149`) that `state == .running` when completion fires. Wave 7.

## K4 — `CATransaction.withSuppressedActions` discipline

**Site:** `Animation/CATransaction+Helpers.swift`, applied at every per-frame view write site.

UIKit interpolates between consecutive layer-property writes with an implicit 0.25s `CABasicAnimation` unless explicitly suppressed. The substrate ticks at 120Hz on iPhone 16. Without suppression, every tick fights an implicit tween → motion is smeared, springs overshoot.

```swift
CATransaction.withSuppressedActions {
    layer.transform = newTransform
}
```

**Why it's load-bearing:** prevents implicit per-frame tweens. The helper exists because the discipline is impossible to maintain via raw `CATransaction.begin / setDisableActions / commit` — too easy to forget the commit.

**Invariant:** zero raw `CATransaction.begin()` calls in production source. Verified by grep at every wave-close gate.

## K5 — Push pattern (`pushCameraToVisibleCells`)

**Site:** `Conversation/Timeline/TimelineCanvas.swift` `pushCameraToVisibleCells`, called from `setCamera`, `applyMorphTickCameraWrite`.

Camera mutations push current camera state to every visible cell so each cell can update its own foreshortening / neighbor-translation / chrome alpha. There is no pull — cells never read the camera. Single source of truth flows outward.

```swift
func setCamera(_ newCamera: Camera) {
    camera = newCamera
    applyCameraTransform()
    pushCameraToVisibleCells()
    updateEdgeMaskAlphas()
    onCameraChanged?(camera, bounds)
}
```

**Why it's load-bearing:** single-source-of-truth for cell visual state. Pull-based would require every cell to observe the camera, multiplying notification cost and de-correlating tick order.

**Refinement (Wave 7 retro):** every camera mutation pushes universally; height mutations push selectively (active cell only via `applyMasterTick`'s targeted write).

## K6 — `accumulatedYCache` lazy invalidation

**Site:** `Conversation/Timeline/TimelineCanvas.swift` `accumulatedYCache: [CGFloat]?` (~line 120), invalidated on `reloadData`.

The y-position of each cell in page coordinates is computed by summing heights of all earlier cells. With N cells visible during pinch, the per-tick recomputation is O(N²). The cache makes it O(1) amortized.

**Why it's load-bearing:** performance. The contract is "heights stable while count stable" — the cache is `nil` iff layout needs recomputation; any height change or count change invalidates it.

**Invariant:** `accumulatedYCache == nil` after every `reloadData()`. Set lazily on first read after layout.

## K7 — `masterTimer` + bell-curve Z-translation

**Site:** `Conversation/Timeline/MorphChoreographer.swift`, `Conversation/Timeline/MorphChoreography.swift`, `DesignSystem/MorphTiming.swift`.

The tap-to-chat morph is **NOT** a spring — it is a deterministic curve with a finite duration (`MorphTiming.masterTimerDuration` = 1.2s). A `CurveAnimator<CGFloat>` ticks `t` from 0 to 1; the choreographer reads `t` and applies a Y-translation + Z-arc (bell curve, peaking mid-morph for the "lift" feel) + extension-height write + neighbor transforms + chrome cross-fade.

**Why it's load-bearing:** deterministic finite duration. A spring would have non-deterministic settling time, ruining the reveal-fire timing (`onMorphRevealReady` fires at `masterTimerDuration + revealReadyDelay`). The bell-curve Z-translation is what makes the morph feel like a "lift", not a "stretch".

**Invariant:** `MorphChoreographer.engage` constructs a fresh `MorphChoreography` spec per engagement; the spec is immutable for the duration of the timer.

## K8 — Per-canvas `AnimationController` instance identity

**Site:** `App/V2RootViewController.swift` (owner), `Conversation/Timeline/TimelineCanvas.swift` (consumer), `Tests/V2/WaveR41SubstrateCanaryTests.swift` (canary).

Exactly one `AnimationController` instance per app. Owned by the composition root, passed into every animator. The canary test asserts that `cameraAnimator` and `extensionAnimator` share the same controller instance:

```swift
XCTAssertTrue(canvas.cameraAnimator.animationControllerIdentityForTesting
              === canvas.extensionAnimator.animationControllerIdentityForTesting)
```

**Why it's load-bearing:** all animators must share one display-link tick so their `dt` is identical and their writes phase-lock. Two controllers = two display links = two ticks per frame = race.

**Invariant:** the canary test. Hoisting the controller from per-canvas to per-app (Wave 3 — `V2RootViewController.swift`) PRESERVED K8 because the canvas still receives ONE controller instance at construction; the change moved the ownership boundary, not the identity.

## See also

- `docs/architecture.md` — layer structure.
- `docs/animation-substrate.md` — L1 kernel.
- `REFACTOR-CHECKLIST.md` §Keystones — DO NOT TOUCH (line ~702).
- `REFACTOR-CHECKLIST.md` §8E.3 — runtime asserts for the 5 hardest invariants (Wave 7 Task 7.3).
