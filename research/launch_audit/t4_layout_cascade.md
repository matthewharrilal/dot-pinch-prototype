# T4 — First `layoutSubviews` Cascade

Symptom branch: white-screen 1–3s + occasional crash. The cascade in
`TimelineCanvas.layoutSubviews()` runs synchronously before iOS gets to commit
the first frame; everything below is on the hot path between
`AppDelegate.didFinishLaunching` and the first visible pixel.

Files cited:
- `DotPinchPrototype/Conversation/V2/TimelineCanvas.swift`
- `DotPinchPrototype/Conversation/V2/CellView.swift`

---

## 1. Cost breakdown — first `layoutSubviews` pass

`TimelineCanvas.layoutSubviews()` body lives at L260–285. Phases (the
`CATransaction.withSuppressedActions` block at L263 wraps all of them, so
implicit-animation suppression is fast; the bulk is genuine compute):

| # | Phase | Lines | Est. cost (release, A15) | Notes |
|---|---|---|---|---|
| 1 | `pageGradientLayer.frame = bounds` | L264 | <0.05ms | 3-stop sRGB-locked gradient, frame-only write |
| 2 | `contentHost.frame = bounds` | L265 | <0.05ms | TAMIC=true (L180); no Auto Layout fire |
| 3 | `topRevealMask.frame` + `bottomRevealMask.frame` | L267–273 | <0.1ms | Two `CGRect` writes |
| 4 | `anchorToCellRestIfAtInitialState()` | L276 → L321 | <0.05ms | Pure scalar arithmetic |
| 5 | `applyCameraTransform()` | L277 → L447 | <0.05ms | One `CATransform3DMakeTranslation` + `sublayerTransform` set |
| 6 | `updateVisibleCells()` first call | L278 → L596 | **5–25ms** | See §1a |
| 7 | `pushCameraToVisibleCells()` | L281 → L692 | **2–8ms** | See §1b |
| 8 | `updateEdgeMaskAlphas()` | L283 → L291 | <0.1ms | Smoothstep curves + opacity writes |

**Total first-cascade estimate: ~8–35ms** — well under one runloop, so it does
NOT alone explain a 1–3s white screen. It DOES, however, force iOS to wait for
this to complete before the very first commit. If anything upstream
(`heightForCellAt` / data-source / model warm-up) blocks, all of §1a is gated
on it.

### 1a. `updateVisibleCells` — the dominant cost

Inside `updateVisibleCells` (L596–674):

1. `cellCount()` → `dataSource.numberOfCells(in:)` (L582). If the data source
   does any deferred CoreData / fixture-decoding work, **this is the hidden
   blocker** — and it's on the first paint's critical path.
2. `accumulatedYs()` (L560–579) — O(n) over `cellCount`. Each
   `heightForCell(at:)` (L586) hits the data source. Without caching at the
   data-source side, this materializes the **entire** vertical layout for the
   whole conversation list on first layout, not just visible cells.
3. `cellIndices(in:plusMargin:)` (L519–548) — O(n) linear scan from index 0
   until first-visible. For a long list this gets slower as you scroll, but on
   FIRST layout it's small.
4. For each of ~4 visible cells:
   - `dequeueCell` (L743) — pool empty on first launch, falls to
     `CellView(frame: .zero)` (L768). Full `init` (L65) → `setupSubviews`
     (L156) → `installLabelStack` (L164) → `installPinchGlyph` (L203) →
     `activateConstraints` (L216, 7 constraints). UIKit label
     instantiation + `UIImage(systemName:)` resolution is the heaviest single
     step here (~1–3ms per cell).
   - `addSubview(cell)` (L652) → triggers `contentHost` invalidation.
   - `cell.installLayout(...)` (L653–659 → CellView L101) — activates 4
     constraints.
   - `dataSource.canvas(self, configureCell:at:)` (L664) → label `.text` writes
     (CellView L247) → text-layout invalidation.

Net: 4 cells × (~2ms init + ~0.5ms layout) ≈ 8–10ms on a warm sim, more on
device cold-start. Plus a **single** Auto Layout pass at the end of the
`withSuppressedActions` block that resolves 16 cell constraints + 7×4=28 cell-
internal constraints in one shot.

### 1b. `pushCameraToVisibleCells` — secondary cost

L692–706. For each visible cell:
- `cell.alpha = ...` (L701) — implicit-anim free under the wrapping
  `CATransaction`, still triggers display-list invalidation.
- `cell.setCamera(camera, viewport:)` (L702 → CellView L269):
  - Progress math (L274–279)
  - Two alpha writes on `labelStack` and `pinchGlyph` (L282–283)
  - `layer.sublayerTransform = CATransform3DIdentity` (L285) — a write every
    push, even when already identity
  - Two constraint-constant mutations on `leadingC` / `widthC` (L290–291) —
    **this re-dirties Auto Layout** AFTER `installLayout` activated them, so a
    second resolution pass may fire on the same runloop turn

Plus `updateNeighborTranslations()` (L705 → L714) — at first paint there's no
`activeCellIndex`, so it short-circuits to identity-write per cell.

---

## 2. Six-question trace

### Q1. What is `anchorToCellRestIfAtInitialState` resting on, and why is it in `layoutSubviews`?

**Trace:** L321–324. It writes
`camera = Camera(translation: lastCellRestScrollY + bounds.height/2)`. The
dependency is `bounds.height` — it MUST be valid (>0). The guard at L322
proves the author knew this:
`guard !hasExternalCameraWrite, bounds.width > 0, bounds.height > 0 else { return }`.

`bounds` is `.zero` during `init` (L149) and remains so until the view is
added to a window and a layout pass runs. `viewWillAppear` is too early on
some routes — the view's bounds aren't guaranteed valid until
`viewWillLayoutSubviews`. So the placement is structurally correct.

**Why it's a problem:** it runs on EVERY `layoutSubviews`, gated only by
`hasExternalCameraWrite`. After first paint the guard short-circuits, but the
function-call + bounds checks still execute. Cheap, but it conflates "first
valid-bounds anchor" with "every layout pass". A boolean flip after the first
successful anchor would clarify intent and let viewDidAppear pre-warm the
camera if bounds happen to be valid by then.

### Q2. Why does `pushCameraToVisibleCells` fire as part of `layoutSubviews`?

**Trace:** L281, called immediately after `updateVisibleCells`. The comment
at L279–280 explains: "Push (possibly recomputed) camera state so cell-internal
alpha curves track viewport-derived chatRestScale after rotation/resize."

It's defending the **rotation/resize** path, where `bounds.height` changes →
`viewport.height / naturalH` changes → progress curves change → alpha must
re-resolve. That's a real invariant. But on **first** layout, every cell was
just instantiated; their alphas are already correct defaults (1.0 from init).
The first push exists solely to re-apply state to cells that already had it
implicitly.

**Counterfactual:** if first-layout skips the push, the only at-rest values
that differ are `labelStack.alpha`, `pinchGlyph.alpha`, `leadingC.constant`,
`widthC.constant`. At progress=0 (no active cell), all of those are at their
identity values: alphas=1, leading=`naturalHorizontalInset`, width=`pageWidth -
2*naturalHorizontalInset`. So the push on first layout is essentially writing
values that are already correct. **Removable on first pass.**

### Q3. Could constraints be pre-built / reused across cells?

**Trace:** Each `CellView.installLayout` (L101–131) deactivates the prior 4
constraints (L113) and creates 4 fresh `NSLayoutConstraint` instances (L115–
123) on every install. Across 4 cells = 16 constraint allocations on first
layout. Plus the 7 internal cell-content constraints from `activateConstraints`
(L217–231) per cell × 4 = 28 more, but those are install-once-per-cell.

The 4 outer constraints reference `contentHost`. They mutate (`heightConstraint`
during pinch; `leadingC` / `widthC` during push). Reuse-across-cells would
require either:
- Per-cell pre-built constraints persisted on `CellView` (pay once at first
  install; later installs flip `.isActive`). This is feasible — the constraint
  REFERENCES (`leadingAnchor`, `widthAnchor`, `centerYAnchor`, `heightAnchor`)
  are stable across pool round-trips. Only constants change.
- Frame-based layout for outer placement (skip constraints entirely).

The keyed-pool path (L744) already preserves the cell across round-trips and
deactivates+rebuilds. Caching constraints on the cell and toggling
`.isActive` + mutating `.constant` would cut allocation pressure on every
re-install. **Per-launch saving: small** (~0.5–1ms) because only first-paint
matters here. **Per-scroll saving: real** — every scroll-driven dequeue
allocates 4 constraints today.

### Q4. Counterfactuals

#### Removal — skip `pushCameraToVisibleCells` on first layout pass

**Mechanism:** Track `hasCompletedFirstLayout: Bool`; gate the push at L281
behind it. Visual result on first paint:
- `labelStack.alpha` defaults to 1 from cell init — labels visible (correct
  at-rest state).
- `pinchGlyph.alpha` defaults to 1 — glyph visible (correct).
- `leadingC.constant` set during `installLayout` to `horizontalInset` = 16 —
  correct cell-rest horizontal inset.
- `widthC.constant` = `pageWidth - 2 * 16` — correct.
- `layer.sublayerTransform` = identity from cell init (CellView L75) — correct.
- `updateNeighborTranslations` short-circuits to identity anyway when no
  active cell.

**Verdict:** safe to skip on first layout. Removes one full pass over all
visible cells + a second Auto Layout dirty (the constant writes at L290–291).
Saves ~2–8ms. **Recommended.**

#### Mutation — lazy-load visible cells

**Mechanism:** First layout instantiates ONE cell (centered on
`lastCellRestScrollY + bounds.height/2`). Queue the remaining ~3 via
`Task { @MainActor in ... }` scheduled in `viewDidAppear`. Each subsequent
cell goes on its own runloop turn (or batched 2-and-2).

Visual result: 1 cell at center on first paint, with surrounding page-gradient
visible. Cells fill in over ~33ms (next 2 frames). Reads as "content already
there, neighbors materializing".

Risk: scroll/pinch arrive on cell 0 immediately; needs guards. The
`cullMargin: 2` invariant (L19) is partially violated mid-stream — acceptable
because hit-test only matters once visible.

**Verdict:** strong perceptual win for first-frame latency; complexity in
keeping `cellIndices` / `visibleRange` honest across the staggered fills.

#### Substitution — `CADisplayLink` deferred kickoff

**Mechanism:** First `layoutSubviews` paints ONLY the gradient + edge masks
(skip `updateVisibleCells` and `pushCameraToVisibleCells` entirely). Schedule
a one-shot `CADisplayLink` callback that fires at the next vsync (≤16.67ms)
and runs the cell cascade then.

Visual result: first paint shows pure page background (Theme.Page gradient)
with edge masks. ~16ms later, cells appear. The page reads as "loaded, just
populating", not "frozen".

Subtlety: tap/pan/pinch gestures arriving in that 16ms window must be
buffered or ignored. Gesture recognizers attach to `self` (L246, L254) so
they'd fire on no-content. Probably fine to ignore — user can't have meant a
cell-tap on a screen with no cells.

**Verdict:** highest perceptual win, lowest implementation complexity. Best
single move. Use a `Task { @MainActor in await Task.yield(); ... }` pattern
instead of `CADisplayLink` if Swift Concurrency is preferred — yields to the
runloop, hits next paint, no token-management.

---

## 3. Three concrete defer strategies

### Strategy A — Skip first-pass push (low risk, modest win)

**Where:** `TimelineCanvas.layoutSubviews()` L260.

**How:**
```swift
override func layoutSubviews() {
    super.layoutSubviews()
    CATransaction.withSuppressedActions {
        pageGradientLayer.frame = bounds
        contentHost.frame = bounds
        // ... mask frames ...
        anchorToCellRestIfAtInitialState()
        applyCameraTransform()
        updateVisibleCells()
        if hasCompletedFirstLayout {
            pushCameraToVisibleCells()
            updateEdgeMaskAlphas()
        }
        hasCompletedFirstLayout = true
    }
}
```

**Lifecycle hook:** none — gated inline by a flag.

**Tradeoff:** Saves ~2–8ms on first paint. Subsequent layouts (rotation,
resize, scroll) behave unchanged. Risk: if any first-pass cell defaults
deviate from "what the push would write", visible jank on second layout.
Verified above (Q4 removal) that defaults match.

### Strategy B — Defer cells to `viewDidAppear` via Swift Concurrency

**Where:** `TimelineCanvas.layoutSubviews()` first pass + a new
`primeCellsAfterFirstPaint()` method.

**How:**
```swift
override func layoutSubviews() {
    super.layoutSubviews()
    CATransaction.withSuppressedActions {
        pageGradientLayer.frame = bounds
        contentHost.frame = bounds
        // ... mask frames ...
        anchorToCellRestIfAtInitialState()
        applyCameraTransform()
        if hasCompletedFirstLayout {
            updateVisibleCells()
            pushCameraToVisibleCells()
            updateEdgeMaskAlphas()
        }
    }
}

// Called by V2RootViewController.viewDidAppear:
func primeCellsAfterFirstPaint() {
    Task { @MainActor in
        await Task.yield()  // ensure first paint has committed
        CATransaction.withSuppressedActions {
            updateVisibleCells()
            pushCameraToVisibleCells()
            updateEdgeMaskAlphas()
        }
        hasCompletedFirstLayout = true
    }
}
```

**Lifecycle hook:** `viewDidAppear(_:)` on the parent VC (the canvas is
already on-window by then; `bounds` is valid). `Task.yield()` lets the
runloop commit the gradient-only first paint before the cell cascade runs.

**Tradeoff:** Best perceptual win — first paint is the page gradient + edge
masks, visible within one runloop turn (~16ms). Cells appear ~16–33ms later.
Risks:
- Tap-to-chat morphs require cells. The morph path (e.g. `handleCellTap` at
  L661) won't fire because there are no cells. Acceptable since user can't
  tap nothing.
- Initial pan/pinch landing on cell-empty viewport — gesture recognizers fire
  but find no `activeCellIndex`. Already a safe no-op in `setActiveCellIndex`.
- The `lastCellRestScrollY` anchor (L323) is still computed correctly.

### Strategy C — Lazy single-cell first paint, neighbors stream in

**Where:** `updateVisibleCells` L596, plus a new
`updateVisibleCellsIncremental(limit:)`.

**How:**
```swift
private func updateVisibleCells() {
    if !hasCompletedFirstLayout {
        updateVisibleCellsIncremental(limit: 1)
        Task { @MainActor in
            await Task.yield()
            CATransaction.withSuppressedActions {
                updateVisibleCellsIncremental(limit: 4)  // fill the rest
                pushCameraToVisibleCells()
            }
        }
        hasCompletedFirstLayout = true
        return
    }
    // ... existing full path ...
}
```

**Lifecycle hook:** inline in `layoutSubviews` + `Task { @MainActor in ... }`
continuation. No VC-level hook needed; the canvas self-manages.

**Tradeoff:** Compromise between A and B. First paint shows ONE cell (the
center one, closest to `lastCellRestScrollY`). Page reads as content-bearing,
just populating. Implementation complexity: `cellIndices` must be filtered to
`limit` cells centered on the camera; `cullMargin` (L19) invariant temporarily
narrowed. Acceptable because cullMargin matters for scroll/hit-test, not
first-frame.

---

## 4. Bedrock observations

- **The cascade is not 1–3s long** on its own (estimate 8–35ms). The white
  screen almost certainly has a contribution from **upstream of layout** —
  e.g. data-source instantiation, CoreData warm-up, fixture decoding, or the
  V2RootViewController's own `viewDidLoad` setup. T4's cascade amplifies any
  upstream delay because `updateVisibleCells` blocks on `cellCount()` and
  `heightForCell(at:)`.
- **The crash** (occasional, per root context) is not explained by anything in
  the layout cascade itself, but: `precondition(index >= 0 && index < count)`
  at L492 will trap if `cellIndices(in:plusMargin:)` produces an index that
  becomes invalid mid-pass (e.g. cellCount changes between
  `accumulatedYs` cache and `pageFrameForCell`). The `accumulatedYCache`
  invalidation contract (L143, comment) is "nil iff layout needs
  recomputation", but `cachedCellCount` (L578) only updates AFTER the cache is
  populated. A racy reload could leave `accumulatedYCache` populated but
  inconsistent with the data source — out-of-cascade hazard worth tracing on
  another branch.
- **Constraint allocation per dequeue** (4 outer + 4 deactivate) is a real
  steady-state inefficiency. Out of scope for first-paint, but a clean target.

## 5. Recommendation order

1. **Strategy B** (`Task { @MainActor in await Task.yield() }` deferral to
   `viewDidAppear`) — highest first-paint win, minimal risk.
2. **Strategy A** (skip first-pass push) — stack on top of B, free saving.
3. **Strategy C** (incremental fill) — only if B doesn't go far enough; adds
   complexity in cell-window bookkeeping.
4. Pre-built constraint reuse on CellView — not a launch fix, but a scroll
   smoothness win worth a follow-up.

Defer everything that doesn't have to be on the first-paint critical path to
`Task { @MainActor in await Task.yield() }` continuations scheduled from
`viewDidAppear`. The cascade as written serializes correctness defenses
(rotation/resize parity) onto the cold-launch path, where they're not yet
needed.
