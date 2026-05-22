# T3 — Crash Modes (HOT)

Read-only audit. Goal: classify every crash hazard, propose refactors that make crashes structurally impossible (type-system + init-ordering, not defensive guards).

**Scope:** TimelineCanvas, CellView, CameraAnimator, Camera, SpringAnimator, AnimationController, V2RootViewController.

**Notable absence:** **zero force-unwrap (`x!`) call sites in V2 production code** — every IUO is accessed via optional-chaining, optional-binding, or after init returns. The `!`s are crash *contracts*, not active sites. Real hazards are init-ordering, not arithmetic.

---

## Ranked crash hazards (blast radius descending)

| # | Hazard | Class | Likelihood |
|---|--------|-------|-----------|
| 1 | `cameraAnimator: CameraAnimator!` accessed before init assignment | LOAD-BEARING | low — silent today |
| 2 | `extensionAnimator: SpringAnimator<CGFloat>!` same hazard | LOAD-BEARING | low |
| 3 | `panRecognizer!` / `pinchRecognizer!` pre-install access | LOAD-BEARING | very low |
| 4 | CellView 7 IUO labels/recognizer accessed before `setupSubviews()` | LOAD-BEARING | very low |
| 5 | `Camera.validate` precondition — NaN/inf into CATransform3D | LOAD-BEARING | low (all upstream guarded) |
| 6 | `pageFrameForCell` precondition on out-of-range index | PHANTOM (today) → LOAD-BEARING if delete path added | very low |
| 7 | `SpringAnimator.start()` value/target nil preconditions | LOAD-BEARING | low — gated upstream |
| 8 | `Spring.updateValue` `response > 0` precondition | PHANTOM | zero |
| 9 | `cellIndices margin >= 0` precondition | PHANTOM | zero |
| 10 | `PinchTuning.anticipation*` setter preconditions | PHANTOM | zero |
| 11 | `fatalError` in 3× `required init?(coder:)` | PHANTOM | zero — `@available(*, unavailable)` blocks |

---

## Hazard #1 + #2 — animator IUOs (LOAD-BEARING — KEYSTONE)

**Site:** `TimelineCanvas.swift:90,94`, init `149-168`.

```swift
private(set) var cameraAnimator: CameraAnimator!
private(set) var extensionAnimator: SpringAnimator<CGFloat>!

override init(frame: CGRect) {
    super.init(frame: frame)
    installViewHierarchy()
    installPageGradient()
    installPanRecognizer()
    installPinchRecognizer()
    cameraAnimator = CameraAnimator(canvas: self, controller: animationController)
    extensionAnimator = SpringAnimator<CGFloat>( ... )
    extensionAnimator.valueChanged = { [weak self] _ in self?.applyExtensionTick() }
    applyCameraTransform()
}
```

### Six-question trace

- **WHAT DOES THIS REST ON?** That no UIView lifecycle callback (`layoutSubviews`, `traitCollectionDidChange`) fires between `super.init(frame:)` and the `cameraAnimator = ...` line; AND that nothing inside `installViewHierarchy/Page/Pan/Pinch` synchronously triggers a layout pass that reaches `setCamera`.
- **WHY DOES THIS EXIST?** `CameraAnimator.init` requires `canvas: TimelineCanvas` — must be post-super.init. Author picked IUO over `lazy var` or two-phase factory.
- **WHAT ASSUMPTIONS DOES THIS ENCODE?** UIKit doesn't synchronously layout during `super.init(frame: .zero)` (true today, undocumented contract). Sub-installers don't reach `setCamera` (verified — `applyCameraTransform` only reads `camera`).
- **WHAT WOULD CHANGE?** `!` → `let` requires breaking the self-reference cycle. `lazy var` defers init to first access — risk: first access could be mid-frame from a gesture, synchronously building the animator.
- **WHAT IF REMOVED?** Compile error — every call site assumes non-nil (no `?.animate(...)` exists).
- **WHAT'S ABSENT?** No assertion fence. No test that no UIKit callback can fire pre-assignment. No documentation that explicitly cites the invariant.

### Refactor — break the self-cycle by injecting closures

`CameraAnimator` doesn't need `TimelineCanvas` — it needs a way to *write* the camera. Replace the weak canvas with closures:

```swift
final class CameraAnimator {
    private let writeCamera: (CGFloat) -> Void
    private let readCamera: () -> CGFloat
    init(writeCamera: @escaping (CGFloat) -> Void,
         readCamera: @escaping () -> CGFloat,
         controller: AnimationController, spring: Spring) { ... }
}

final class TimelineCanvas: UIView {
    let animationController = AnimationController()
    let cameraAnimator: CameraAnimator
    let extensionAnimator: SpringAnimator<CGFloat>

    override init(frame: CGRect) {
        let ac = AnimationController()
        var weakSelfRef: TimelineCanvas?
        self.cameraAnimator = CameraAnimator(
            writeCamera: { t in weakSelfRef?.setCamera(Camera(safe: t)) },
            readCamera:  { weakSelfRef?.camera.translation ?? 0 },
            controller: ac, spring: ...)
        self.extensionAnimator = SpringAnimator<CGFloat>(controller: ac, spring: ...)
        self.animationController = ac
        super.init(frame: frame)
        weakSelfRef = self  // late-bind, post-super.init, pre-any-callback
        extensionAnimator.valueChanged = { [weak self] _ in self?.applyExtensionTick() }
        installViewHierarchy(); installPanRecognizer(); installPinchRecognizer()
        applyCameraTransform()
    }
}
```

Both animators become `let`. `weakSelfRef` is set once, post-super.init, before any animator engages (engagement requires `.animate()` calls only gesture handlers issue, all post-init). IUO crash class disappears at type level.

---

## Hazard #3 — pan/pinch IUOs (LOAD-BEARING)

**Site:** `TimelineCanvas.swift:58,65`. Read at lines 343, 356 (`panRecognizer.isEnabled = ...`).

Same shape as #1, but **simpler** — `UIPanGestureRecognizer()` is constructible with zero `self` reference. Convert to `let`:

```swift
let panRecognizer: UIPanGestureRecognizer
let pinchRecognizer: UIPinchGestureRecognizer

override init(frame: CGRect) {
    let pan = UIPanGestureRecognizer()
    let pinch = UIPinchGestureRecognizer()
    self.panRecognizer = pan
    self.pinchRecognizer = pinch
    super.init(frame: frame)
    pan.addTarget(self, action: #selector(handlePan(_:)))
    pinch.addTarget(self, action: #selector(handlePinch(_:)))
    pan.delegate = self; pinch.delegate = self
    addGestureRecognizer(pan); addGestureRecognizer(pinch)
    // ...
}
```

Zero risk. Eliminates 2 IUOs.

---

## Hazard #4 — CellView IUO labels (LOAD-BEARING — easiest win)

**Site:** `CellView.swift:20,28-31,35,42`. 7 IUOs:
```swift
private(set) var tapRecognizer: UITapGestureRecognizer!
private(set) var dateLabel: UILabel!
private(set) var topicSummaryLabel: UILabel!
private(set) var todayLabel: UILabel!
private(set) var labelStack: UIStackView!
private(set) var chatRestCenterLabel: UILabel!
private(set) var pinchGlyph: UIImageView!
```

All seven constructible without `self`. Refactor to `let`:

```swift
final class CellView: UIView {
    let dateLabel = UILabel()
    let topicSummaryLabel = UILabel()
    let todayLabel = UILabel()
    let chatRestCenterLabel = UILabel()
    let pinchGlyph = UIImageView()
    let tapRecognizer = UITapGestureRecognizer()
    let labelStack: UIStackView

    override init(frame: CGRect) {
        self.labelStack = UIStackView(arrangedSubviews: [dateLabel, topicSummaryLabel, todayLabel])
        super.init(frame: frame)
        configureLabels(); activateConstraints()
        tapRecognizer.addTarget(self, action: #selector(handleTap))
        tapRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(tapRecognizer)
    }
}
```

**Eliminates 7 crash time-bombs in one mechanical edit.** Do this first.

---

## Hazard #5 — NaN/inf into `Camera` (LOAD-BEARING)

**Site:** `Camera.swift:21-23`, called at `Camera.init` and `setCamera` (TimelineCanvas:333).

### NaN audit (all upstream sites)

- `pinchInitialScale = recognizer.scale` line 963 — guarded by `guard pinchInitialScale > 1e-6` at line 977. SAFE.
- `pinchAnchorPageY + bounds.height / 2 - currentCentroidViewportY` line 1005 — all inputs finite UIKit values. SAFE. (Also explicit `guard newTranslation.isFinite` at 1006.)
- `velocityBias = (extensionVel / naturalH) * 0.15` line 1037 — `naturalH > 0` guarded at 1029. SAFE.
- `clampedWithRubberband` math — all finite. SAFE.
- `currentCentroidY` velocity divide line 1051 — `dt > 1e-6 && dt.isFinite` guarded. SAFE.

**Latent hole:** `Camera.translation` is declared `var`. Internal callers could (in theory) write `camera.translation = .nan` bypassing `validate`. Currently `camera` is `private(set)` and no internal site does this. But the door is open.

### Refactor — make `translation` immutable + add NaN-safe init

```swift
struct Camera: Equatable {
    let translation: CGFloat            // ← was var

    init(translation: CGFloat) {
        precondition(translation.isFinite, "Camera.translation must be finite")
        self.translation = translation
    }

    /// NaN-safe constructor for gesture/animator boundaries.
    init(safe translation: CGFloat) {
        self.translation = translation.isFinite ? translation : 0
    }

    static let identity = Camera(translation: 0)
}
```

Then at gesture-handler call sites:
```swift
// BEFORE: Camera(translation: newTranslation)
// AFTER:  Camera(safe: newTranslation)
setCamera(Camera(safe: newTranslation))    // line 1007
setCamera(Camera(safe: clamped))           // line 897
camera = Camera(safe: newCameraY)          // line 1369
```

After: type system makes post-init mutation impossible. Gesture-derived translations float to 0 instead of crashing. The precondition stays as a tripwire for programmatic call sites that shouldn't produce NaN.

---

## Hazard #6 — `pageFrameForCell` out-of-range precondition (PHANTOM → LOAD-BEARING)

**Site:** TimelineCanvas:490-498. Reachable only if `instantiatedCells` retains a key `>= cellCount()`. `updateVisibleCells` reaps stale keys (line 616-618), but `hitTest` reads `instantiatedCells.keys` directly. If a future delete path shrinks `numberOfCells` between layout and hit-test, this fires.

**Class today:** PHANTOM. **Class with delete UI:** LOAD-BEARING.

Refactor — Optional return:
```swift
func pageFrameForCell(at index: Int) -> CGRect? {
    let count = cellCount()
    guard index >= 0, index < count else { return nil }
    let ys = accumulatedYs()
    return CGRect(x: 0, y: ys[index], width: pageWidth, height: heightForCell(at: index))
}
```
Forces all callers to handle the nil — turning a future crash into a hit-test miss.

---

## Hazard #7 — `SpringAnimator.start()` preconditions (LOAD-BEARING)

**Site:** SpringAnimator:95-96. All current call sites set `value` + `target` immediately before `start()` (CameraAnimator:145-148, TimelineCanvas:1412-1414). SAFE today.

Refactor — make `.start()` accept both as args, eliminating the optional-storage-as-contract:
```swift
public func start(from value: T.ValueType, to target: T.ValueType,
                  velocity: T.VelocityType = .zero) {
    self.value = value; self.target = target; self.velocity = velocity
    startTime = CACurrentMediaTime()
    controller?.runPropertyAnimation(self)
}
```
Optional storage remains (for in-flight retarget). But the start contract is type-enforced.

---

## Hazards #8, #9, #10, #11 — PHANTOM

- **#8** `Spring.updateValue response > 0` (SpringInterpolatable:45) — `Spring.stiffness` uses `max(response, 0.0001)`; PinchTuning sets `1.10`. Unreachable.
- **#9** `cellIndices margin >= 0` (TimelineCanvas:522) — only called with `Self.cullMargin = 2` and `0`. Unreachable.
- **#10** `PinchTuning.anticipation*` setters (PinchTuning:38, 52) — no write sites in V2.
- **#11** `fatalError` in 3× `required init?(coder:)` — `@available(*, unavailable)` blocks call sites at compile time.

Leave all four. Cheap invariant documentation.

---

## Refactor priority

1. **CellView IUO purge** (#4) — 7 IUOs → 7 `let`. Pure mechanical. Largest cluster, smallest blast.
2. **Camera immutability + `init(safe:)`** (#5) — `var` → `let`, `Camera(translation:)` → `Camera(safe:)` at gesture sites.
3. **TimelineCanvas gesture recognizer purge** (#3) — 2 IUOs → 2 `let`. Trivial.
4. **TimelineCanvas animator restructure** (#1, #2) — closures replace canvas reference. Higher-impact; touches `CameraAnimator` surface. After #1-3.
5. **`SpringAnimator.start(from:to:)`** (#7) — small, eliminates contract violation by construction.
6. **`pageFrameForCell` Optional** (#6) — future-proof for delete paths.

---

## Structurally absent

- **No assert/fence on IUO access.** A debug `assert(cameraAnimator != nil)` at top of every public TimelineCanvas method would catch regressions.
- **No CADisplayLink-fire-before-wired test.** AnimationController creates a paused link; a test registering an animator BEFORE wiring `valueChanged` would lock the contract.
- **No `Camera(translation: .nan)` precondition-fires test.**
- **No `dataSource = nil` mid-animation test.** `cellCount() = 0` if nil; with `activeCellIndex` set, `instantiatedCells[activeIdx]` orphans without `setActiveCellIndex(nil)`. Non-crashing, state-corrupting.
- **No CellView pool round-trip test for constraint-reset ordering.** `resetHeightConstraintToNatural` then `deactivateLayoutConstraints` (line 787-788) — if reordered or skipped, leaves pooled cell with deactivated `heightConstraint` still referenced. Revival hazard, not crash.

---

## Summary

The crash surface is narrower than the IUO count suggests. **Zero active force-unwrap sites** outside IUO declarations. All `fatalError` sites blocked by `@available(*, unavailable)`. All `precondition` sites upstream-guarded.

The real hazards are **init-ordering contracts** encoded as IUOs (#1-4). Silent today — no UIKit callback fires between `super.init` and assignment. Will crash the day someone reorders init, or iOS changes when `layoutSubviews` first fires for a zero-frame UIView.

The structurally-impossible fix is mechanical: IUO → `let` via two-phase init (closures for animators; pure construction for labels/recognizers). After conversion, the type system enforces the invariant the prose comments currently encode. The crash class disappears.
