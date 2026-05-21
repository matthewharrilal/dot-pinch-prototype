# Audit A7 — Animation/
ROLE: AUDIT-A7

Live entry: AppDelegate → V2RootViewController → TimelineCanvas. V1 path
(ConversationComposer → ConversationViewController → PinchToMemoryInteraction
→ ChatBodyView → TokenApplier → ConversationMorphTokens) is NOT routed from
AppDelegate and is therefore dead in production. V1 symbols still compile and
still have V1-only tests, but no LIVE_REACHABLE traversal touches them.

Audit policy:
- LIVE_REACHABLE = reached from V2RootViewController traversal.
- V1_ONLY = only reached via ConversationViewController/Composer/Interaction.
- TEST_ONLY = only referenced from Tests/ (and possibly transitively from V1).
- ORPHAN = no references anywhere.
- AMBIGUOUS = referenced internally only / dead-via-default.

---

## File: DotPinchPrototype/Animation/AnimationController.swift  (118 LOC)

### Symbols (with tags)
- `class DisplayLinkProxy` (private) — LIVE_REACHABLE. Required by
  AnimationController's init/deinit; weak-proxy retain-cycle fix.
- `class AnimationController` — LIVE_REACHABLE.
  - Constructed at `TimelineCanvas.swift:180` (`let animationController = AnimationController()`).
  - Also constructed at `ConversationComposer.swift:26` (V1_ONLY path).
  - V2 use is the live path; instance flows to `extensionAnimator`, `masterAnimator`,
    and `cameraAnimator` (via `CameraAnimator(controller:)`).
- `init()`, `deinit`, `_displayLinkFired`, `runPropertyAnimation` — LIVE_REACHABLE.
- Private stored props (`animations`, `displayLink`, `proxy`) — LIVE_REACHABLE.

### Comment-slim
DELETE (verbose / wave-ref):
- Top docstring lines 13-25 ("Wave 4a §11.15.a — CADisplayLink lifetime fix …
  Pre-fix … `target's deinit can only run AFTER invalidate fires` … `Fix: a
  weak-proxy target …`"). The "what" is in the code; the wave history is noise.
  KEEP lines 1-11 (the docstring describing role + non-singleton contract).
- Inline lines 72-74 (`// Wave 4a §11.15.a / §8.12: the proxy-target pattern …`).
- Inline lines 112-113 (`// Tick once synchronously at dt=0 so the view paints …`)
  — trivial; the `runPropertyAnimation` docstring already says this.
- Line 63 (`// ProMotion 120Hz on iPhone 16. Default would be 60Hz.`) — KEEP
  (load-bearing micro-rationale for the magic number 120).

KEEP:
- File-level docstring lines 1-11 (role + non-singleton contract).
- `DisplayLinkProxy`'s docstring (load-bearing: explains why it exists).
- `displayLink` / `proxy` property doc one-liners (load-bearing: explains weak proxy).
- `_displayLinkFired` docstring (1 line — proxy seam).
- `runPropertyAnimation` docstring (1 line).
- All `// MARK: -` (none currently present; not required to add).

### Hard deletes
None — file is fully LIVE_REACHABLE.

### Cross-ref warnings
- `runPropertyAnimation` is called from `SpringAnimator.start()`. If
  SpringAnimator deletes `start()`, this becomes orphan.

---

## File: DotPinchPrototype/Animation/CATransaction+Helpers.swift  (20 LOC)

### Symbols (with tags)
- `extension CATransaction.withSuppressedActions(_:)` — LIVE_REACHABLE.
  - Called from `AnimationController._displayLinkFired` + `runPropertyAnimation`
    (LIVE).
  - Also called ~8 sites in `TimelineCanvas.swift` (LIVE) and `CellView.swift`
    (LIVE).
  - Also V1-only callers: ConversationViewController, ConversationCell, etc.
    (V1_ONLY but irrelevant — V2 callers anchor it as LIVE).

### Comment-slim
DELETE: nothing meaningful to slim — file is already 20 lines.

KEEP all current content. (File-level docstring + 1-line method docstring is
within the rules.)

### Hard deletes
None.

### Cross-ref warnings
None.

---

## File: DotPinchPrototype/Animation/CGAffineTransform+Similarity.swift  (22 LOC)

### Symbols (with tags)
- `extension CGAffineTransform.similarity(scale:anchor:in:)` — V1_ONLY.
  - Single call site: `ChatBodyView.swift:848`
    (`contentTransformLayer.transform = .similarity(...)`).
  - ChatBodyView is part of V1 chat-rest visual path, not reachable from
    V2RootViewController. V2 uses `CGAffineTransform(scaleX:y:)` directly inside
    TimelineCanvas/CellView; no similarity transform anchored at a unit point.

### Comment-slim
N/A — file is V1_ONLY → hard-delete candidate.

### Hard deletes
**WHOLE FILE — `CGAffineTransform+Similarity.swift`** after V1 retirement.
Until V1 source files are also deleted, ChatBodyView won't compile without it.
Coordinate with V1 audit: delete in same commit as `ChatBodyView.swift`.

### Cross-ref warnings
- Hard-deleting this file breaks `ChatBodyView.swift:848` compilation. Verify
  that ChatBodyView is being deleted in the V1 purge.

---

## File: DotPinchPrototype/Animation/MathUtilities.swift  (86 LOC)

### Symbols (with tags)
- `func rubberband(value:range:interval:c:)` — LIVE_REACHABLE.
  - `TimelineCanvas.swift:1426` (V2 over-pinch rubberband budget).
- `func rubberbandClamp(offset:interval:c:)` (private) — LIVE_REACHABLE
  (helper to `rubberband`).
- `func project(initialVelocity:decelerationRate:)` — LIVE_REACHABLE.
  - `TimelineCanvas.swift:2153` (V2 fling projection).
- `func normalizedVelocity(gestureVelocity:target:current:)` — V1_ONLY.
  - Single call site: `PinchToMemoryInteraction.swift:308`. V2's CameraAnimator
    uses raw velocity directly (see `animate(to:velocity:)`), not normalized.
- `func clamp<T>(_:_:_:)` — LIVE_REACHABLE.
  - `TimelineCanvas.swift:2155`, `SpringInterpolatable.swift` (internal),
    `MathUtilities.swift` (`smoothstep`).
- `func ramp(_:from:to:)` — V1_ONLY.
  - All call sites in `ConversationMorphTokens.swift` (V1_ONLY token applier).
  - V2 uses `smoothstep` exclusively for content alpha/scale curves.
- `func smoothstep(_:_:_:)` — LIVE_REACHABLE.
  - V2 sites: `TimelineCanvas.swift:554,555,559,560,1109`, `CellView.swift:431`,
    `TimelineCanvasPreviewVC.swift:203` (V1-debug — irrelevant).

### Comment-slim
DELETE:
- Line 1-2 file header ("Math primitives bottled from Wave's UIMathUtilities and
  WWDC 2018 Session 803 …") — KEEP (1-2 lines, fits the rule). Actually keep.
- Lines 14-15 inline (`// Per Wave's implementation: the formula maps an
  out-of-range value to a damped version …`) — DELETE (trivial paraphrase).
- Lines 32-34 docstring detail on `project` ("Closed-form integral of v(t) =
  v0 · decelerationRate^t. With decelerationRate = 0.998 (UIScrollView default)
  …") — KEEP (load-bearing math reference for the 0.998 constant).
- Lines 41-48 docstring on `normalizedVelocity` — N/A (function deleted).
- Lines 67-79 docstring on `smoothstep` "Wave-7d Branch-10 / F-23 …" — DELETE
  the wave-history block (lines 73-79). KEEP lines 67-72 (the formula +
  C¹-continuity note are load-bearing math; explain why smoothstep over ramp).

KEEP:
- `rubberband` docstring (1 line).
- `project` docstring (4 lines, math-load-bearing).
- `clamp` docstring (1 line).
- `smoothstep` formula + C¹-continuity note (≤4 lines).

### Hard deletes
- `func normalizedVelocity(...)` — V1_ONLY. Hard delete with V1 retirement.
- `func ramp(...)` — V1_ONLY. Hard delete with V1 retirement.

### Cross-ref warnings
- Hard-deleting `normalizedVelocity` breaks `PinchToMemoryInteraction.swift:308`.
- Hard-deleting `ramp` breaks ~10 sites in `ConversationMorphTokens.swift` and
  related V1 token-applier consumers.
- Coordinate with V1 audit owner.

---

## File: DotPinchPrototype/Animation/Spring.swift  (63 LOC)

### Symbols (with tags)
- `struct Spring` — LIVE_REACHABLE.
  - V2 construction sites:
    - `CameraAnimator.swift:58` (default `Spring(dampingRatio: 1.0, response: 0.45)`).
    - `TimelineCanvas.swift:318` (extension animator spring).
    - `TimelineCanvas.swift:333` (master animator `Spring(1.0, response: 5.0)`).
    - `TimelineCanvas.swift:1682` (`return Spring(dampingRatio: damping, response: PinchTuning.springResponse)`).
  - V1: `ConversationComposer.swift:27` (also constructs, but V1_ONLY).
- `init(dampingRatio:response:mass:)` — LIVE_REACHABLE.
- `var stiffness` — LIVE_REACHABLE (used in `SpringInterpolatable.CGFloat.updateValue`).
- `var dampingCoefficient` — LIVE_REACHABLE (same).
- `var settlingDuration` — LIVE_REACHABLE (used in `SpringAnimator.updateAnimation`
  finish check).
- `static let settlingPercentage`, `static let overdampedMultiplier` (private)
  — LIVE_REACHABLE.

### Comment-slim
DELETE:
- Nothing heavy — file is already tight.

KEEP:
- File-level 1-line header (`// Spring parameters. Adapted from jtrivedi/Wave.`).
- Property docstrings (1-2 lines each, all load-bearing physics rationale).
- `// MARK: - Derived physics quantities`.
- `settlingDuration` docstring (math-load-bearing).
- Lines 52 (`// Critically/overdamped multiplier matches Wave's empirically-tuned value.`)
  — KEEP (justifies the 1.25 constant).

### Hard deletes
None — file is fully LIVE_REACHABLE.

### Cross-ref warnings
None.

---

## File: DotPinchPrototype/Animation/SpringAnimator.swift  (217 LOC)

### Symbols (with tags)
- `protocol AnimatorProviding` — LIVE_REACHABLE. Used by
  `AnimationController.animations: [UUID: AnimatorProviding]`. Conformance:
  `SpringAnimator`.
- `enum AnimatorState { .inactive, .running, .ended }` — LIVE_REACHABLE.
  - V2 reads `.state` in adversarial lifecycle tests + canvas guards.
- `class SpringAnimator<T>` — LIVE_REACHABLE (V2 uses `SpringAnimator<CGFloat>`).
- `SpringAnimator.Event { .finished, .retargeted }` — LIVE_REACHABLE (via
  `completion` callback).
- `var id`, `var state`, `var spring`, `var value`, `var target`, `var velocity`,
  `var mode`, `var valueChanged`, `var completion` — all LIVE_REACHABLE (CameraAnimator + TimelineCanvas).
- `var startTime` (internal) — LIVE_REACHABLE.
- `weak var controller` (private) — LIVE_REACHABLE.
- `internal var animationControllerIdentity` — TEST_ONLY but tests are V2-live.
  - `Tests/V2/WaveR41SubstrateCanaryTests.swift:33-34`.
  - Surfaced via `CameraAnimator.animationControllerIdentity` (re-export).
  - Tag: LIVE_REACHABLE (V2 production-relevant invariant test).
- `init(controller:spring:value:target:)` — LIVE_REACHABLE.
- `func start()` — LIVE_REACHABLE. Called from `CameraAnimator.animate(to:velocity:completion:)`
  and `TimelineCanvas` extension/master starts.
- `func stop(immediately:)` — LIVE_REACHABLE. V2 canvas stops; tests stop.
- `func reset()` — LIVE_REACHABLE (called by AnimationController on `.ended`).
- `var runningTime` (internal) — LIVE_REACHABLE.
- `func updateAnimation(dt:)` (internal) — LIVE_REACHABLE.
- `enum AnimationMode { .animated, .nonAnimated }` — AMBIGUOUS.
  - `.animated` is the init default; no external setter calls
    `animator.mode = .nonAnimated` anywhere in the codebase (verified via
    grep — no matches outside SpringAnimator.swift itself).
  - The mode-branch path (`if isAnimated { … } else { newValue = target; … }`)
    is therefore dead-via-default. Suggest hard-delete of `enum AnimationMode`,
    the `mode` property, and the `if isAnimated { … } else { … }` branch (use
    only the animated path).

### Comment-slim
DELETE:
- Lines 11-32 — the "PUBLIC COMPLETION-ORDERING CONTRACT" + "SUBSTRATE CHOICE
  (R4.1 decision, §10.80)" block. Heavy wave-history. KEEP a 3-4 line summary
  of the completion ordering contract (1-2-3-4 steps); it IS load-bearing
  because TimelineCanvas's `tryClearActiveCellAtRest` depends on it. DELETE
  the §10.80/§7.13/§10.62/§10.76/UIViewPropertyAnimator history (lines 26-32).
- Line 66-69 inline on `state.didSet` — KEEP (1 line — explains startTime side
  effect).
- Lines 109-115 docstring on `animationControllerIdentity` — KEEP a 2-line
  summary; DELETE the §10.80 wave ref but keep "used by canary test to assert
  camera + extension share controller".
- Lines 135-136 inline (`// target.didSet only sets startTime when state==.running.
  On first start state is .inactive, so set startTime here or the spring never
  integrates.`) — KEEP (1 line, load-bearing init-condition note).
- Lines 164-166 docstring on `updateAnimation` — KEEP shortened (the
  CATransaction comment is load-bearing).
- Lines 188-189 inline (`// Non-animated mode still flows through the animator
  so cleanup runs.`) — DELETE IF AnimationMode is removed; KEEP if not.

KEEP:
- All `// MARK: -` (5 of them).
- Per-method 1-line docstrings.
- The completion-ordering 4-step contract (slimmed).

### Hard deletes
- Conditional: `enum AnimationMode` + `var mode: AnimationMode = .animated`
  + the `if isAnimated/else` branch in `updateAnimation`. Frees ~10 LOC.
  Risk: low — confirmed unused via grep. Suggest deletion.
- `precondition(spring.response > 0, "Spring physics requires non-zero response.
  Use mode=.nonAnimated for snap-to-target.")` in
  `SpringInterpolatable.swift` references `mode=.nonAnimated` — update wording
  if mode is removed.

### Cross-ref warnings
- The 4-step completion-ordering contract is depended on by V2 code
  (`TimelineCanvas.tryClearActiveCellAtRest`, see comments in TimelineCanvas).
  Do NOT reorder lines 198-207 of `updateAnimation`.
- Reset wording in deletion comment about §10.80 / §7.7 / §10.62 / §10.76 /
  R3.1 / R4.1: drop the section IDs but keep "value, then valueChanged, then
  completion, then state=.ended" sequence as a 4-line block.

---

## File: DotPinchPrototype/Animation/SpringInterpolatable.swift  (126 LOC)

### Symbols (with tags)
- `protocol VelocityProviding` — LIVE_REACHABLE. Used as `SpringInterpolatable`
  associated-type constraint.
- `protocol SpringInterpolatable` — LIVE_REACHABLE.
  - V2 conformer used: `CGFloat` (via `SpringAnimator<CGFloat>` at
    `CameraAnimator`, `TimelineCanvas.extensionAnimator`, `masterAnimator`).
  - V1 conformer used: `PinchMorphState` (`Gestures/PinchMorphState.swift:9`).
- `extension CGFloat: SpringInterpolatable, VelocityProviding` — LIVE_REACHABLE.
  - `updateValue` is THE Hooke's-law integrator; every CGPoint/CGSize/CGRect
    conformance below decomposes to per-component CGFloat calls. LIVE.
- `extension CGPoint: SpringInterpolatable, VelocityProviding` — ORPHAN.
  - No `SpringAnimator<CGPoint>` constructed anywhere in the codebase (verified
    via grep — zero matches).
- `extension CGSize: SpringInterpolatable, VelocityProviding` — ORPHAN.
  - No `SpringAnimator<CGSize>` constructed anywhere.
- `extension CGRect: SpringInterpolatable, VelocityProviding` — ORPHAN.
  - No `SpringAnimator<CGRect>` constructed anywhere.

### Comment-slim
DELETE:
- Lines 38-39 docstring on `CGFloat.updateValue` ("This is the canonical
  mass-spring-damper model. Every other SpringInterpolatable conformance below
  decomposes to per-component CGFloat updateValue() calls.") — KEEP (load-bearing
  base-case identification).
- Lines 86, 105 inline (`// CGSize already conforms `static var zero` from
  CoreGraphics — no redeclaration needed.`) — DELETE IF extensions are removed;
  otherwise DELETE anyway (compiler-evident).

KEEP:
- File-level docstring (3 lines).
- `// MARK: -` blocks.
- The Hooke's-law formula docstring on CGFloat.updateValue (load-bearing).

### Hard deletes
- `extension CGPoint: SpringInterpolatable, VelocityProviding` (~17 LOC).
- `extension CGSize: SpringInterpolatable, VelocityProviding` (~17 LOC).
- `extension CGRect: SpringInterpolatable, VelocityProviding` (~25 LOC).
- Combined: ~59 LOC removable.
- All three are completely unreferenced; no V1, no V2, no test instantiates
  `SpringAnimator<CGPoint|CGSize|CGRect>`.

### Cross-ref warnings
- The `precondition(spring.response > 0, "... Use mode=.nonAnimated for
  snap-to-target.")` text references AnimationMode (see SpringAnimator audit).
  If AnimationMode is removed, simplify the precondition message.

---

## Summary

### Per-file LOC + status
| File | LOC | Status | Removable LOC |
|------|-----|--------|---------------|
| AnimationController.swift | 118 | LIVE | comment-slim ~15 |
| CATransaction+Helpers.swift | 20 | LIVE | 0 |
| CGAffineTransform+Similarity.swift | 22 | V1_ONLY → DELETE WHOLE FILE | 22 |
| MathUtilities.swift | 86 | LIVE (mixed) | hard-delete `normalizedVelocity` + `ramp` (~20 LOC) + comment-slim ~8 |
| Spring.swift | 63 | LIVE | comment-slim ~3 |
| SpringAnimator.swift | 217 | LIVE | comment-slim ~30, hard-delete `AnimationMode` block ~12 |
| SpringInterpolatable.swift | 126 | LIVE (mixed) | hard-delete CGPoint/CGSize/CGRect extensions (~59 LOC) |
| **Total** | **652** | | **~169 LOC removable** |

### Whole-file deletes
- **CGAffineTransform+Similarity.swift** — V1_ONLY (single caller ChatBodyView).
  Delete in same commit as V1 file purge.

### Symbol-level hard deletes (with V1 retirement)
- `func normalizedVelocity(...)` in MathUtilities.swift — V1_ONLY caller.
- `func ramp(...)` in MathUtilities.swift — V1_ONLY callers.

### Symbol-level hard deletes (independent — V1 not required)
- `extension CGPoint: SpringInterpolatable, VelocityProviding` — ORPHAN.
- `extension CGSize: SpringInterpolatable, VelocityProviding` — ORPHAN.
- `extension CGRect: SpringInterpolatable, VelocityProviding` — ORPHAN.
- `enum AnimationMode` + `var mode` + `if isAnimated/else` branch in
  SpringAnimator.swift — AMBIGUOUS (dead-via-default). No external setter
  exists; safe to remove.

### Cross-ref warnings (consolidated)
1. **CGAffineTransform+Similarity.swift** delete is V1-coupled — coordinate
   with V1 audit (ChatBodyView delete).
2. **MathUtilities `normalizedVelocity` / `ramp`** deletes are V1-coupled —
   coordinate with V1 audit (PinchToMemoryInteraction + ConversationMorphTokens
   deletes).
3. **SpringAnimator `AnimationMode` removal** updates the precondition error
   message in `SpringInterpolatable.swift:48` ("Use mode=.nonAnimated for
   snap-to-target."). Rewrite to omit the mode reference.
4. **SpringAnimator final-tick ordering** (value → valueChanged → completion →
   state=.ended) is depended on by V2's `tryClearActiveCellAtRest`. Comment-slim
   may delete the wave-history but MUST preserve the 4-step ordering note.
5. **AnimationController** is LIVE; do not delete `DisplayLinkProxy` — it is
   the load-bearing retain-cycle fix that makes deinit reachable.

### Audit assertion
After V1 retirement + this audit's recommended deletes:
- Animation/ shrinks from 652 LOC to ~483 LOC (-26%).
- All remaining symbols are V2 LIVE_REACHABLE or V2-test-relevant.
- No ORPHAN symbols remain.
- No AMBIGUOUS symbols remain.
