# Audit A8 — Gestures + Placeholders + Debug
ROLE: AUDIT-A8

Live entry: AppDelegate -> V2RootViewController -> TimelineCanvas (V2). V1 (ConversationComposer/ConversationViewController/ActiveConversationCoordinator/TokenApplier/ConversationMorphTokens/ChatBodyView/ListComposerView) is wholly dead. PinchTuning is the ONLY scoped file with surviving live consumers (V2: TimelineCanvas, CameraAnimator, V2-tests).

---

## File: DotPinchPrototype/Gestures/PinchMorphState.swift  (37 LOC)

### Symbols (with tags)
- `struct PinchMorphState` — **V1_ONLY**. SpringInterpolatable progress carrier.
  - Producers: `PinchToMemoryInteraction` (V1), `ActiveConversationCoordinator` (V1), `ConversationMorphTokens` (V1), `TokenApplier` (V1), `ConversationViewController` (V1), `MemoryTimeline` (V1), `ConversationComposer` (V1).
  - V2 reachable callers from `V2RootViewController`: NONE. V2 uses `Camera` (translation scalar) + `CameraAnimator` directly; no `SpringAnimator<PinchMorphState>` in the V2 graph.
  - Tests: 16+ test files reference it; all reference V1 internals (TokenApplier, ActiveConversationCoordinator, PinchToMemoryInteraction). Tests under Tests/V2/ do NOT reference `PinchMorphState` directly.
- `static let zero` — **V1_ONLY**. Used only by V1 paths.
- `static func updateValue(...)` — **V1_ONLY**. Required by `SpringInterpolatable` conformance; used by `SpringAnimator<PinchMorphState>` ticks (V1 only).
- `typealias ValueType / VelocityType` — **V1_ONLY**.

### Comment-slim
- Drop the 4-line `// The gesture's integrated state ...` if file is kept. Replace with terse 2-line docstring describing the SpringInterpolatable scalar. (Moot if file deleted.)
- Inline doc `/// progress ∈ [0, 1] ...` — KEEP if file survives (semantic anchor).

### Hard deletes
- **DELETE WHOLE FILE** — V1-only, no V2 consumer.

### Cross-ref warnings
- Deletion cascades through V1 graph: `Conversation/Coordinator/ActiveConversationCoordinator.swift`, `Conversation/Morph/TokenApplier.swift`, `Conversation/ConversationMorphTokens.swift`, `Conversation/ConversationViewController.swift`, `Conversation/Memory/MemoryTimeline.swift`, `App/ConversationComposer.swift`, and ~16 V1 test files. All expected to be hard-deleted by parallel audits (A2/A3/A4 — V1 Conversation tree, V1 Composer, V1 Tests).
- MASTER-CHECKLIST.json contains ~14 historical references — ignore (non-code documentation).

---

## File: DotPinchPrototype/Gestures/PinchToMemoryInteraction.swift  (419 LOC)

### Symbols (with tags)
- `class PinchToMemoryInteraction: NSObject, UIInteraction` — **V1_ONLY**.
  - Constructed only by `ConversationComposer.make()` (V1). V2 (`V2RootViewController` / `TimelineCanvas`) has its own pinch gesture wiring inside `TimelineCanvas.installGestures()` — confirmed in V2RootViewController.swift comment "I7 V1 mechanics retirement (PinchToMemoryInteraction etc.)".
- `view: UIView?` (UIInteraction conformance) — **V1_ONLY**
- `willMove(to:)` / `didMove(to:)` — **V1_ONLY**
- `var onPinchAnchorChanged: ((CGPoint?) -> Void)?` — **V1_ONLY**. Consumer is V1 `ActiveConversationCoordinator.pinchAnchorInView`.
- `var onPinchBeganIdleActivation: ((CGPoint) -> Bool)?` — **V1_ONLY**. Wired in V1 VC.installInteractionIfNeeded.
- `init(animator: SpringAnimator<PinchMorphState>)` — **V1_ONLY**.
- `handlePinch(_:)`, `handlePinchBegan`, `handlePinchChanged`, `handlePinchEnded`, `shouldUseReducedMotion`, `snapToOppositeTarget`, `gestureProgress`, `progressVelocity` — all **V1_ONLY**.

### Comment-slim
- Comments occupy ~180 of 419 LOC (43%). Heavy wave-numbered prose throughout.
- DELETE: the four large prose blocks (lines 41-60 anchor-publish; 72-132 idle-activation rationale + Option A/B; 153-218 race-safety + ordering invariants; 258-299 anchor-spring-continuity; 366-385 polarity-rebuild; 200-235 idle-activation pre-amble). Total ~150 LOC of comment removable.
- KEEP: 3-4 line top-of-file docstring; `// MARK: -` markers; short doc lines on the two callbacks (`onPinchAnchorChanged`, `onPinchBeganIdleActivation`); doc on `gestureProgress` (the formula). Moot if file deleted.

### Hard deletes
- **DELETE WHOLE FILE** — V1-only. V2 uses its own gesture system in `Conversation/V2/TimelineCanvas.swift`.

### Cross-ref warnings
- `App/ConversationComposer.swift:37` constructs it (V1 composer, expected to be deleted by audit A4).
- `Conversation/ConversationViewController.swift:232,268,765-796` declares property + installs (V1 VC).
- `Conversation/Memory/MemoryTimeline.swift:502,532` comment-only references.
- `Conversation/Coordinator/ActiveConversationCoordinator.swift:145,332,385,389,429,436,459,494` comment + code references (all V1).
- `Conversation/Morph/TokenApplier.swift:150,320` comment references.
- Tests: 9 test files instantiate or reference `PinchToMemoryInteraction` (PinchGlyphPhaseTests, StateMachineCompletenessTests, ConversationViewControllerSubviewOrderTests, BlurReparentTests, TapTargetTests, MorphStateTests, PinchFromIdleActivationTests, AnchorSpringContinuityTests, Wave7cSurvivabilityTests). All V1; expected to be deleted by audit A9 (Tests).

---

## File: DotPinchPrototype/Gestures/PinchTuning.swift  (153 LOC)

### Symbols (with tags)
- `enum PinchTuning` — **LIVE** (V2 consumer present).
- `baselineSimilarityS` — **V1_ONLY** (refs: V1 `ConversationMorphTokens` only).
- `destinationSimilarityS` — **V1_ONLY** (refs: V1 `ConversationMorphTokens` only).
- `anchorPoint` — **V1_ONLY** (refs: V1 `ChatBodyView.composerAnchorPoint` only).
- `pinchSensitivity` — **V1_ONLY** (refs: `PinchToMemoryInteraction` only).
- `rubberBandDampingC` — **V1_ONLY** (refs: `PinchToMemoryInteraction` only).
- `rubberBandInterval` — **V1_ONLY** (refs: `PinchToMemoryInteraction` only).
- `gestureClampLowerBound` — **V1_ONLY** (refs: `PinchToMemoryInteraction` only).
- `gestureClampUpperBound` — **V1_ONLY** (refs: `PinchToMemoryInteraction` only).
- `commitProjectionThreshold` — **V1_ONLY** (refs: `PinchToMemoryInteraction` + StateMachineCompletenessTests).
- `velocityHandoffFloorPerSecond` — **V1_ONLY** (refs: `PinchToMemoryInteraction` only).
- `tapToExpandReadyThreshold` — **ORPHAN** (0 refs anywhere).
- `tapToExpandKickVelocity` — **ORPHAN** (0 refs anywhere).
- `springResponse` — **LIVE** (V2: `TimelineCanvas.swift:320,1682`, `CameraAnimator.swift:60`).
- `springDamping` — **LIVE** (V2: `TimelineCanvas.swift:319`, `CameraAnimator.swift:59`).
- `tapToChatDamping` — **LIVE** (V2: `TimelineCanvas.swift:1678` + Tests/V2/WaveR44 + Tests/V2/WaveR74).
- `pinchToCellsDamping` — **LIVE** (V2: `TimelineCanvas.swift:1679` + Tests/V2/WaveR44).
- `cancelledDamping` — **LIVE** (V2: `TimelineCanvas.swift:1680` + Tests/V2/WaveR44 + Tests/V2/WaveR74).
- `anticipationMagnitude` (incl. precondition setter) — **LIVE** (V2: `TimelineCanvas.swift:1844` + Tests/V2/WaveR72).
- `anticipationDuration` (incl. precondition setter) — **LIVE** (V2: `TimelineCanvas.swift:1849` + Tests/V2/WaveR72).
- `anticipationDisabled` — **TEST_ONLY** (V2 production never reads it; Tests/V2/WaveR73DisableFlagTests references). Recommend: keep until WaveR73 test deleted, or delete both together. Likely deletion candidate.

### Comment-slim
- File has 153 LOC, ~50% comment. KEEP top-of-file 3-4 line docstring, MARK headers, short docstrings on LIVE constants (springResponse, springDamping, per-direction damping triplet, anticipationMagnitude/Duration).
- DELETE: §, R7.x, P5, R4.4, R7.6, retros/ wave references inside doc-comments. The "wave-8 W8-T8 dead-zone" block on `pinchSensitivity` is moot once that constant is deleted.
- DELETE doc references to "§7.8.4 Π''' fallback per §7.8.4" / "§7.24" / "§10.78" — keep precondition message terse: e.g. `"anticipationMagnitude must be in [0.95, 0.99]"`.

### Hard deletes
- DELETE constants (V1-only or orphan):
  - `baselineSimilarityS`, `destinationSimilarityS`, `anchorPoint`, `pinchSensitivity`, `rubberBandDampingC`, `rubberBandInterval`, `gestureClampLowerBound`, `gestureClampUpperBound`, `commitProjectionThreshold`, `velocityHandoffFloorPerSecond` (10 V1-only constants).
  - `tapToExpandReadyThreshold`, `tapToExpandKickVelocity` (2 orphans).
- DELETE the `// MARK: - Similarity transform`, `// MARK: - Pinch gesture mapping`, `// MARK: - Commit / release`, `// MARK: - Tap-to-expand` sections wholesale.
- KEEP file overall (LIVE for V2). Post-slim target: ~50-60 LOC retaining only `springResponse`, `springDamping`, three per-direction damping vars, two anticipation vars (and optionally `anticipationDisabled`).

### Cross-ref warnings
- `pinchSensitivity` deletion requires deletion of `PinchToMemoryInteraction.swift` first (same audit).
- `baselineSimilarityS`/`destinationSimilarityS`/`anchorPoint` deletions cascade to V1 `ConversationMorphTokens.swift` and `ChatBodyView.swift` — both expected dead by audit A3.
- Tests/V2/WaveR73DisableFlagTests assumes `anticipationDisabled` exists; if kept, fine; if deleted, that test deletes with it.
- Renaming `Gestures/` -> something like `Animation/` may be warranted after slim, since only spring-physics tunables remain — but rename is out of scope for this audit.

---

## File: DotPinchPrototype/Placeholders/ChatTranscript.swift  (50 LOC)

### Symbols (with tags)
- `struct ChatMessage` — **ORPHAN**. Referenced only by `ChatTranscript` itself; no consumer.
- `enum ChatTranscript` — **ORPHAN**. `past` and `current` are referenced only in doc-comments inside `DummyConversationLoader.swift` (line 13, 43, 50, 51 — all "// Messages migrated from ChatTranscript ..." prose). No code reference.

### Comment-slim
- N/A — file deleted whole.

### Hard deletes
- **DELETE WHOLE FILE** — fully orphaned. V2 uses `DummyConversationLoader` -> `Conversation` -> `Message` model.

### Cross-ref warnings
- `Conversation/Data/DummyConversationLoader.swift:13,43,50,51` contains comment-only references ("migrated from ChatTranscript.swift"). Those comments become stale-but-harmless after deletion; consider stripping them in the V2 data file (out of scope here — would belong to audit A3 or A5).

---

## File: DotPinchPrototype/Placeholders/DestinationContent.swift  (9 LOC)

### Symbols (with tags)
- `enum DestinationContent`
  - `static let date` — **ORPHAN** (only doc-comment refs in `DummyConversationLoader.swift:16`).
  - `static let preview` — **ORPHAN** (only doc-comment refs in `DummyConversationLoader.swift:15`).
  - `static let composerHint` — **LIVE** (V2: `Conversation/V2/ChatViewController.swift:78`). Also V1: `Conversation/Chrome/ListComposerView.swift:109` + `Conversation/ChatBody/ChatBodyView.swift:520` (both V1-dead).

### Comment-slim
- Drop the 2-line top-of-file prose; replace with 1-line `/// Placeholder strings for the V2 chat composer placeholder.`

### Hard deletes
- DELETE `static let date` (orphan).
- DELETE `static let preview` (orphan).
- KEEP `static let composerHint` (V2 ChatViewController consumer).
- KEEP file shell — but it's down to a single 1-line constant. Strongly consider INLINING `composerHint = "Share with Dot…"` into `ChatViewController.swift` and DELETING the file entirely. That removes the `Placeholders/` directory.
- **Recommended hard-delete: whole file + inline the single live string at consumer.**

### Cross-ref warnings
- `DummyConversationLoader.swift:15,16` doc-comments reference `DestinationContent.preview` / `.date` (prose only; harmless stale after file deletion).
- If file kept but `date`/`preview` deleted, audit A3/A5 may notice the "migrated from" doc lines and prune them.
- V1 ChatBodyView + ListComposerView references die with V1 (audit A3).

---

## File: DotPinchPrototype/Debug/MorphScrubberDebug.swift  (388 LOC)

### Symbols (with tags)
- `class MorphScrubberDebug` — **V1_ONLY / DEBUG_HARNESS**. Sole production trigger is `ActiveConversationCoordinator.setProgressForScrubbing` (V1, dead). Singleton reaches into the V1 coordinator via `Mirror` reflection; V2 has no `ActiveConversationCoordinator`.
- `static let isEnabled` — **V1_ONLY** (only used internally + by `MorphScrubberBootstrap.kick`).
- `static let isOverlayEnabled` — **V1_ONLY** (only `ConversationViewController` was the documented installer; not actually called anywhere).
- `static let shared` — **V1_ONLY**.
- `platformTag`, `lastCommandValue`, `commandPollTimer`, `logEntries`, `logFileURL` — internal **V1_ONLY**.
- `init`, `bootstrapIfEnabled`, `discoverCoordinator`, `startCommandPolling`, `pollCommandFile` — **V1_ONLY**.
- `func stepTo(progress:)` — **V1_ONLY**. Calls `ActiveConversationCoordinator.setProgressForScrubbing`.
- `func runSweep(direction:steps:)` — **V1_ONLY**.
- `enum Direction` — **V1_ONLY**.
- `func installOverlay(on:layers:)` — **V1_ONLY**. Documented to be called from `ConversationViewController.viewDidLoad`; actual call site does NOT exist in `ConversationViewController.swift` (confirmed: 0 call sites).
- `func recordTokens(progress:summary:)` — **V1_ONLY**, 0 external callers.
- `static func handle(url:)` — **V1_ONLY**. Documented as "reserved for a future AppDelegate hook"; not wired today.
- `class MorphScrubberBootstrap` + `static let kick` — **V1_ONLY**; `kick` is referenced ONLY in its own docstring ("we trigger that reference from..."). No actual call site references `MorphScrubperBootstrap.kick` or `MorphScrubberBootstrap.kick`. The bootstrap mechanism is dead-on-arrival.

### Comment-slim
- N/A — file deleted whole.

### Hard deletes
- **DELETE WHOLE FILE** — Wave-7e debug harness for V1 mechanics. User scope: "remove debug helpers".

### Cross-ref warnings
- `Conversation/Coordinator/ActiveConversationCoordinator.swift:862-885` contains `setProgressForScrubbing(_:)` debug seam + `_ = MorphScrubberDebug.shared` reference. These dies together with V1 coordinator (audit A4).
- `scripts/visual-audit-scrub.sh` references `MORPH_DEBUG_SCRUB` and `dotpinch-debug://` URL scheme. Script will become non-functional but is non-code; flag for cleanup by audit A1 or A9.
- `maestro/flows/wave-7c-snapshot-driver.yaml:15` references `PinchTuning.springResponse` (still valid post-cleanup).
- `Conversation/Cells/ConversationCell.swift:770` comment-only reference to `installOverlayContainer` (V1, dies with audit A3).

---

## File: DotPinchPrototype/Debug/TimelineCanvasPreviewVC.swift  (356 LOC, #if DEBUG)

### Symbols (with tags)
- `class TimelineCanvasPreviewVC: UIViewController, TimelineDataSource` — **DEBUG_HARNESS / V2-adjacent**. Only instantiated by `ConversationViewController.swift:398` (V1 dead path). Not reachable from V2 entry.
- All instance properties (`canvas`, `scaleSlider`, `translationSlider`, `scaleLabel`, `translationLabel`, `tapCellButtons`, `cellRestButton`, `pinchGlyph`, `menuButton`, `pinchExpandImage`, `pinchCollapseImage`) — **DEBUG_ONLY**.
- All methods (`viewDidLoad`, `viewDidLayoutSubviews`, `installChrome`, `updateChrome`, `handleChromeGlyphTap`, `installCanvas`, `installControls`, `installTapButtons`, `tapCellButtonPressed`, `cellRestButtonPressed`, `slidersChanged`, `updateLabels`, TimelineDataSource conformance methods) — **DEBUG_ONLY**.
- `static let cellColors` — **DEBUG_ONLY**.

### Comment-slim
- N/A — file deleted whole.

### Hard deletes
- **DELETE WHOLE FILE** — only reachable through V1 (dead) and user scope explicitly says "remove debug helpers". V2 production path (`V2RootViewController`) uses `TimelineCanvas` with real `DummyConversationLoader` data; the preview VC's hardcoded 5 cells + sliders are not needed.

### Cross-ref warnings
- `Conversation/ConversationViewController.swift:360,377,398` instantiates this VC behind a #if DEBUG branch. Dies with V1 VC (audit A3).
- TimelineDataSource protocol conformance is harmless — no other type-level dependency.
- TimelineCanvas, Theme.Symbol.pinchAffordancePointSize/Weight, SymbolName.pinchExpand/Collapse, smoothstep, Camera, CellView all remain LIVE in V2 — deletion does not orphan any of them.

---

## Summary

| File | LOC | Status | Action |
|---|---|---|---|
| Gestures/PinchMorphState.swift | 37 | V1_ONLY | DELETE FILE |
| Gestures/PinchToMemoryInteraction.swift | 419 | V1_ONLY | DELETE FILE |
| Gestures/PinchTuning.swift | 153 | LIVE (partial) | SLIM (12 dead constants + ~80 LOC comment) -> ~50-60 LOC |
| Placeholders/ChatTranscript.swift | 50 | ORPHAN | DELETE FILE |
| Placeholders/DestinationContent.swift | 9 | LIVE (1 of 3) | DELETE FILE; inline composerHint at ChatViewController.swift:78 |
| Debug/MorphScrubberDebug.swift | 388 | V1_ONLY | DELETE FILE |
| Debug/TimelineCanvasPreviewVC.swift | 356 | DEBUG/V1_GATED | DELETE FILE |
| **Total in scope** | **1412** | | **6 whole-file deletes; 1 file slimmed by ~100 LOC** |

### Headline numbers
- **Whole-file deletes:** 6 of 7 files (~1262 LOC removed).
- **File slimmed:** 1 (`PinchTuning.swift`, 153 -> ~50-60 LOC).
- **Net LOC removed (this audit):** ~1350 / 1412 (~96%).
- **Surviving LOC:** ~50-60 LOC of `PinchTuning` spring-physics tunables consumed by V2 (`TimelineCanvas`, `CameraAnimator`, Tests/V2/).

### Directory outcomes
- `DotPinchPrototype/Gestures/` — reduces to single file (`PinchTuning.swift`). Consider renaming directory to `Animation/Tunables/` or merging into `Animation/` (out of scope; recommend follow-up).
- `DotPinchPrototype/Placeholders/` — empty after deletes; **remove directory**.
- `DotPinchPrototype/Debug/` — empty after deletes; **remove directory**.

### Coordination hand-offs to other audits
- A3 (V1 Conversation tree): deleting `ConversationViewController.swift` removes the only `TimelineCanvasPreviewVC` call site + the V1 `installOverlay`/`setProgressForScrubbing` references.
- A4 (V1 Composer/Coordinator): deleting `ConversationComposer.swift` removes the only `PinchToMemoryInteraction(...)` call site + `ActiveConversationCoordinator(...)` instantiation; deleting `ActiveConversationCoordinator.swift` removes `setProgressForScrubbing` + the MorphScrubberDebug reference.
- A9 (Tests/): all V1 test files (~16) reference `PinchMorphState` / `PinchToMemoryInteraction`; their deletion is required before deletion of the gesture files compiles cleanly. Tests/V2/ keep `PinchTuning` references — `PinchTuning.swift` must remain.
- Scripts/maestro: `scripts/visual-audit-scrub.sh` and the `dotpinch-debug://` URL scheme become functionally dead; flag for separate cleanup pass.
- Decide separately on `PinchTuning.anticipationDisabled` (test-only flag, Tests/V2/WaveR73DisableFlagTests). If WaveR73 test is retired, the flag goes with it.
