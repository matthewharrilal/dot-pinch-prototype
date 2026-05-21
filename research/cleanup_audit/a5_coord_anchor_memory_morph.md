# Audit A5 — Coordinator + Anchor + Memory + Morph
ROLE: AUDIT-A5

Live entry: `AppDelegate → V2RootViewController()` (App/AppDelegate.swift:23). V2RootViewController references ONLY V2 types (TimelineCanvas, TimelineDataSourceAdapter, ChatViewController, ConversationStore, DummyConversationLoader, Theme). NONE of the files in this audit are reached from the V2 path.

All seven files are reachable only via the V1 entry point chain `ConversationComposer.make() → ConversationViewController(...)` and from `Tests/`. Since `ConversationComposer` has no caller (grep confirms no references in App/, Conversation/V2/, or anywhere outside its own definition), the entire chain is dead in production. Tag **V1_ONLY** applies to every production symbol; tests are recursively V1_ONLY because they exercise the V1 graph.

Debug-only consumers exist (`MorphScrubberDebug` calls `coordinator.setProgressForScrubbing`; `TimelineCanvasPreviewVC` mentions TokenApplier in a comment only) but these too live behind the V1 graph (scrubber discovers via Mirror reflection from the rootVC — under V2 root it would find no coordinator).

Verdict: **whole-file deletes** are appropriate for all seven files in this audit. Aggressive purge per task brief.

---

## File: DotPinchPrototype/Conversation/Coordinator/ActiveConversationCoordinator.swift

### Symbols (with tags)

| Symbol | Tag |
|---|---|
| `class ActiveConversationCoordinator` (915 LOC) | V1_ONLY |
| `init(animator:store:tokenApplier:)` | V1_ONLY |
| `private(set) var morphState: MorphState` | V1_ONLY |
| `var pinchAnchorInView: CGPoint?` | V1_ONLY |
| `func requestActivate(_ conversationID: UUID)` | V1_ONLY |
| `func requestCollapse()` | V1_ONLY |
| `func attach(timeline:)` | V1_ONLY |
| `func attach(overlay:)` | V1_ONLY |
| `func attach(blurHost:)` | V1_ONLY |
| `func attachChrome(pinchGlyph:menuButton:)` | V1_ONLY |
| `internal func handleAnimatorTick(_:)` | V1_ONLY |
| `internal func handleAnimatorCompletion(_:)` | V1_ONLY |
| `private func liftActiveCellIfNeeded()` | V1_ONLY |
| `private func lowerLiftedCellIfNeeded()` | V1_ONLY |
| `private func transitionToChat / toIdle / toExpanding / toContracting()` | V1_ONLY |
| `internal func startObservingApplicationLifecycle()` | V1_ONLY |
| `private func handleBackgrounding()` | V1_ONLY |
| `func setProgressForScrubbing(_:)` | V1_ONLY (debug, consumer is MorphScrubberDebug — also V1-graph reachable only) |
| `deinit` | V1_ONLY |

External call sites (all V1-graph):
- `ConversationComposer.make()` (App/ConversationComposer.swift:54-58, :63) — constructs + attaches timeline
- `ConversationViewController.viewDidLoad` (Conversation/ConversationViewController.swift:334, :340, :351) — attaches overlay/blurHost/chrome
- `ConversationViewController` — observes morphState, calls requestActivate/requestCollapse
- `MorphScrubberDebug.discoverCoordinator()` (Debug/MorphScrubberDebug.swift:144-157) — discovers via Mirror under V1 rootVC; never finds it under V2RootViewController
- Tests: PinchGlyphPhaseTests, ConversationViewControllerSubviewOrderTests, TapTargetTests, BlurReparentTests, MemoryTimelineTests, Wave7cSurvivabilityTests, MorphStateTests, CompositionTests, PinchFromIdleActivationTests, AnchorSpringContinuityTests, EmptyBubbleFixTests

### Comment-slim
File is dense with wave/phase/explorer/retro references (W4-G1, W6-G3, P4.T6, E-5, E-12, etc.). Examples to delete in slim pass:
- Lines 9-13 (worker-state/transitions/edge-cases ownership breakdown)
- Lines 50-56 (W6-G3 retrospective on deleted `animationController` weak ref)
- Lines 60-66 (Wave-6 resolution note on Option B)
- Lines 169-188 (Wave-8 W8-T3 storage seam essay on `pinchAnchorInView`)
- Lines 197-201 (Wave-7d Architecture B.a UUID-tracking commentary)
- Lines 216-225 (E-12 closure ownership essay in init)
- Lines 233-239 (P4.T6 / E-10 lifecycle note)
- Lines 241-246 (W4 bridge handshake note)
- Lines 318-354 (`handleAnimatorTick` wave-by-wave running commentary)
- Lines 380-468 (`handleAnimatorCompletion` ~80 lines of three-source `.finished` essay, including the Phase 3.6 retro-S-1 explanation)
- Lines 482-495, 530-541 (requestActivate/requestCollapse re-entry rule recap)
- Lines 545-557 (W8-T10 scroll-before-collapse explanation)
- Lines 580-598, 600-613, 615-626, 628-650 (attach() docstrings — keep one-liners)
- Lines 652-657 (Internal Transitions intro)
- Lines 666-676 (transitionToIdle Wave-7d explanation)
- Lines 697-728 (Animator Bridge handshake essay)
- Lines 730-761 (Concurrency essay — E-9, P4.T4)
- Lines 766-772 (`backgroundObserverToken` rationale)
- Lines 774-787 (startObservingApplicationLifecycle docstring)
- Lines 832-858 (Cold Launch essay — P4.T7, E-11)
- Lines 861-873 (debug seam intro)
- Lines 897-907 (deinit Swift 6 isolation essay)
Comment-slim potential: ~450 LOC of the 915 (≈49%) — but moot if whole-file delete.

### Hard deletes
**WHOLE FILE** (915 LOC). No V2 reach.

### Cross-ref warnings
- Deleting kills `ConversationComposer.make()` (already orphaned)
- Deleting kills VC viewDidLoad lines 334/340/351 attach calls
- Deleting kills `MorphScrubberDebug.discoverCoordinator()` reflection target — debug overlay becomes inert in V2 (already true since V2 doesn't expose a coordinator)
- 11 test files transitively dependent (see V1_ONLY cluster summary at end)

---

## File: DotPinchPrototype/Conversation/Coordinator/MorphState.swift

### Symbols (with tags)

| Symbol | Tag |
|---|---|
| `struct MorphState: Equatable, Sendable` | V1_ONLY |
| `enum MorphState.Phase` (.idle, .expanding, .chat, .contracting) | V1_ONLY |
| `var phase: Phase` | V1_ONLY |
| `var activeID: UUID?` | V1_ONLY |
| `static let idle = MorphState(...)` | V1_ONLY |
| `var isInFlight: Bool` | ORPHAN — only definition site references itself; no external readers across `DotPinchPrototype/` or `Tests/` (grep `isInFlight` returns ONE match: line 36 def) |

External consumers:
- `ActiveConversationCoordinator` (its primary holder)
- `ConversationViewController.applyPinchGlyphForPhase(_:)` consumes `MorphState.Phase` (Conversation/ConversationViewController.swift:1090)
- Tests (MorphStateTests, etc.)

### Comment-slim
- Lines 1-14 (wave-4 stub provenance / vocabulary reference)
- Lines 31-35 (`isInFlight` docstring — moot since prop is orphaned)
Comment-slim potential: ~22 LOC of 39 (≈56%).

### Hard deletes
- **WHOLE FILE** (39 LOC). V1_ONLY.
- Even under non-whole-file scenarios, `isInFlight` (lines 31-38) would be **ORPHAN** delete — no consumers.

### Cross-ref warnings
- Deleting breaks `ActiveConversationCoordinator` + `ConversationViewController.applyPinchGlyphForPhase` (both also V1_ONLY and slated for deletion).

---

## File: DotPinchPrototype/Conversation/Anchor/SpatialAnchorResolver.swift

### Symbols (with tags)

| Symbol | Tag |
|---|---|
| `class SpatialAnchorResolver` | V1_ONLY |
| `private weak var timeline: MemoryTimeline?` | V1_ONLY |
| `init(timeline:)` | V1_ONLY |
| `func anchorFrame(forConversation:) -> CGRect?` | V1_ONLY |

External consumers:
- `ConversationComposer.make()` (App/ConversationComposer.swift:40) constructs it
- `TokenApplier` holds it strongly (Conversation/Morph/TokenApplier.swift:52, :176)
- Tests: SpatialAnchorResolverTests.swift, PinchGlyphPhaseTests, ConversationViewControllerSubviewOrderTests, TapTargetTests, BlurReparentTests

### Comment-slim
- Lines 1-42 (40-line file-header essay — wave-5 wiring decision W5-G10, boundary discipline E-12, memory ownership E-18, fallback strategy P6.T1.S2.A2, per-tick safety E-11)
Comment-slim potential: ~38 LOC of 96 (≈40%).

### Hard deletes
**WHOLE FILE** (96 LOC). V1_ONLY.

### Cross-ref warnings
- Deleting kills TokenApplier line 52 (`let resolver: SpatialAnchorResolver`) — TokenApplier also slated for deletion
- Deleting kills `ConversationComposer.make` line 40 — composer also slated
- SpatialAnchorResolverTests.swift becomes deletable as a whole file (tests of dead code)

---

## File: DotPinchPrototype/Conversation/Memory/CellMetrics.swift

### Symbols (with tags)

| Symbol | Tag |
|---|---|
| `enum CellMetrics` (namespace) | V1_ONLY |
| `static let restHeight: CGFloat = 120` | V1_ONLY |
| `static let restCornerRadius: CGFloat = 18` | V1_ONLY |
| `static let fullscreenCornerRadius: CGFloat = 39` | V1_ONLY |
| `static let interCellSpacing: CGFloat = 16` | V1_ONLY |
| `static let cellMarginHorizontal: CGFloat = 16` | V1_ONLY |
| `static let sectionInsetVertical: CGFloat = 16` | V1_ONLY |
| `static let summaryDateGap: CGFloat = 8` | V1_ONLY |
| `static let summaryInsetTop / Leading / Trailing / Bottom` | V1_ONLY |

External consumers (all V1_ONLY themselves):
- `MemoryTimeline` (this audit — Conversation/Memory/MemoryTimeline.swift:130, :136, :141, :143, :145, :559, :565)
- `ConversationCell` (Conversation/Cells/ConversationCell.swift:262, :267, :277, :348, :353, :407, :411, :415, :419, :721, :999)
- `ConversationMorphTokens` (Conversation/ConversationMorphTokens.swift:660-661)
- `CellSummaryView` (Conversation/Cells/CellSummaryView.swift:134)

NOTE: V2 (Conversation/V2/CellView.swift) reads its own `naturalCellHeight` parameter (200, set in V2RootViewController.swift:40) and does NOT consume CellMetrics — verified by grep.

### Comment-slim
- Lines 1-20 (file-header rationale — resolved decision P2.T3.S1, vocabulary discipline, constraints)
- Lines 27, 31, 35, 39, 43, 47-50, 53-55, 58-69 (per-constant docstrings)
Comment-slim potential: ~35 LOC of 70 (≈50%).

### Hard deletes
**WHOLE FILE** (70 LOC). V1_ONLY (all consumers also V1_ONLY).

### Cross-ref warnings
- Deleting cascades to all V1 cell + token + timeline files (all already V1_ONLY)
- V2 does NOT need to inherit these constants — V2 has its own sizing via `TimelineDataSourceAdapter(naturalCellHeight: 200)`

---

## File: DotPinchPrototype/Conversation/Memory/MemoryTimeline.swift

### Symbols (with tags)

| Symbol | Tag |
|---|---|
| `class MemoryTimeline: UIView` | V1_ONLY |
| `enum Section` | V1_ONLY |
| `var onSelectConversation: ((UUID) -> Void)?` | V1_ONLY |
| `init(store:)` | V1_ONLY |
| `deinit` | V1_ONLY |
| `static func makeLayout()` | V1_ONLY |
| `private func configureCollectionView/configureDataSource()` | V1_ONLY |
| `private func applyInitialSnapshot / applyCurrentSnapshot()` | V1_ONLY |
| `private func armCollectionObservation()` | V1_ONLY |
| `func flushPendingSnapshot()` | V1_ONLY |
| `func setScrollEnabled(_:)` | V1_ONLY |
| `func haltScroll()` | V1_ONLY |
| `func scrollToCellIfNeeded(for:animated:)` | V1_ONLY |
| `func indexPath(for:)` | V1_ONLY |
| `func cell(at:)` | V1_ONLY |
| `func layoutAttributes(at:)` | V1_ONLY |
| `func convertFrameToScreen(_:)` | V1_ONLY |
| `func conversationCell(forConversation:)` | V1_ONLY |
| `func nonActiveVisibleCells(excluding:)` | V1_ONLY |
| `func conversationID(atWindowPoint:)` | V1_ONLY |
| `func brandNewConversationAnchorFrame()` | V1_ONLY |
| `collectionView(_:didSelectItemAt:)` (delegate ext.) | V1_ONLY |

External consumers (all V1_ONLY):
- `ConversationComposer.make()` (line 39)
- `ConversationViewController` (stored property + many call sites — :112, :271, :799, :841, :898, :1049, :1056, :957 etc.)
- `SpatialAnchorResolver` (this audit) holds weak ref
- `TokenApplier` (this audit) holds weak ref
- `ActiveConversationCoordinator.attach(timeline:)` (this audit)
- Tests: MemoryTimelineTests, PinchGlyphPhaseTests, ConversationViewControllerSubviewOrderTests, TapTargetTests, BlurReparentTests, Wave7cSurvivabilityTests, Wave7cSurvivabilityTests, SpatialAnchorResolverTests, etc.

NOTE: `AccessibilityID.memoryTimeline = "MemoryTimeline"` string in DesignSystem/AccessibilityID.swift:21 is set on `collectionView.accessibilityIdentifier` (line 162). The constant is unused outside the timeline → could also be ORPHANED if MemoryTimeline is deleted.

### Comment-slim
- Lines 1-41 (file-header — substrate decision P2.T1.S2.A1, wrapper rationale, layout-static z-order, dual-observation invariant, etc.)
- Lines 60-76 (`onSelectConversation` docstring)
- Lines 79-93 (`pendingSnapshotApply`, `Section` enum docstrings)
- Lines 152-167 (`configureCollectionView` Z-order/tap-routing comments)
- Lines 184-219 (`configureDataSource` W2-G1/wave-7b integration commentary)
- Lines 251-290 (`armCollectionObservation` essay — E-1, E-5, E-6, E-7, E-8, Swift 6 isolation)
- Lines 292-319 (`flushPendingSnapshot` rationale — wave-7b F-2)
- Lines 341-403 (scroll control + W8-T10 essay)
- Lines 417-427 (Anchor helpers intro)
- Lines 449-453 (`convertFrameToScreen` docstring)
- Lines 466-487 (`nonActiveVisibleCells` wave-7c fix-bundle Issue #11 commentary)
- Lines 497-544 (`conversationID(atWindowPoint:)` wave-7c.next Phase 3.7 + W7-G4 UIKit anchors essay)
- Lines 553-557 (`brandNewConversationAnchorFrame`)
- Lines 570-581 (Layout regime P8.T2 / E-12)
- Lines 584-610 (Tap delegate W5-G9 / E-7 / E-8 / P5.T8 essay)
Comment-slim potential: ~280 LOC of 623 (≈45%).

### Hard deletes
**WHOLE FILE** (623 LOC). V1_ONLY.

### Cross-ref warnings
- Deleting cascades to all 7 files in this audit + ConversationViewController + ConversationComposer (all already slated)
- `AccessibilityID.memoryTimeline` (DesignSystem/AccessibilityID.swift:21) becomes ORPHAN — recommend deleting that constant in the DesignSystem audit pass
- 8+ test files (MemoryTimelineTests is the focused one; many others use timeline via Fixtures.swift)

---

## File: DotPinchPrototype/Conversation/Morph/ReactiveBinder.swift

### Symbols (with tags)

| Symbol | Tag |
|---|---|
| `class ReactiveBinder` | V1_ONLY |
| `private var pending: Task<Void, Never>?` | V1_ONLY |
| `func arm(read:apply:)` | V1_ONLY |
| `func cancel()` | V1_ONLY |
| `deinit` | V1_ONLY |

External consumers:
- `CellSummaryView` (Conversation/Cells/CellSummaryView.swift:30) — `private let summaryBinder = ReactiveBinder()` and uses `summaryBinder.arm(...)` in line 68's `armObservation`
- Tests: ReactiveBindingsTests.swift

CellSummaryView is part of the V1 cell rendering, embedded inside ConversationCell (which is rendered inside MemoryTimeline). It is V1_ONLY (V2 has its own CellView at Conversation/V2/CellView.swift).

The header's "Migration plan" comment block (lines 16-19) acknowledges only ONE site migrated to use the binder. The shape was speculative across wave-3 retro S-3 / wave-6 retro lift but most sites still inline the pattern.

### Comment-slim
- Lines 1-19 (file-header — wave-6 extraction, migration-plan rationale)
- Lines 29-31 (`arm` docstring)
- Lines 51, 57-61 (cancel / deinit docstrings)
Comment-slim potential: ~28 LOC of 64 (≈44%).

### Hard deletes
**WHOLE FILE** (64 LOC). V1_ONLY (CellSummaryView is V1_ONLY).

### Cross-ref warnings
- Deleting breaks `CellSummaryView.summaryBinder` (V1_ONLY, slated for deletion in cells audit)
- ReactiveBindingsTests.swift becomes deletable (V1 graph)

---

## File: DotPinchPrototype/Conversation/Morph/TokenApplier.swift

### Symbols (with tags)

| Symbol | Tag |
|---|---|
| `class TokenApplier` | V1_ONLY |
| `private weak var timeline: MemoryTimeline?` | V1_ONLY |
| `private let resolver: SpatialAnchorResolver` | V1_ONLY |
| `private weak var listComposerView / pinchGlyph / menuButton: UIView?` | V1_ONLY |
| `init(timeline:resolver:listComposerView:)` | V1_ONLY |
| `func attachChrome(pinchGlyph:menuButton:)` | V1_ONLY |
| `func apply(state:activeID:pinchAnchorInView:)` | V1_ONLY |

External consumers:
- `ConversationComposer.make()` (App/ConversationComposer.swift:49) constructs it
- `ActiveConversationCoordinator` holds it strongly (`private let tokenApplier: TokenApplier?` line 74; calls `apply` from `handleAnimatorTick`)
- Tests: TokenApplierTests.swift, ChatBodyEagerInstantiationTests.swift, EmptyBubbleFixTests.swift, ComposerAnchorTests.swift (via Fixtures.makeTokenApplierFixture)

### Comment-slim
- Lines 1-31 (file-header — per-tick path enumeration, W6-G7 frame budget, wave-6 handshake, W8-T3 narrative)
- Lines 38-93 (per-property docstring essays — every weak ref has a 5–10 line preamble)
- Lines 107-123 (`attachChrome` docstring)
- Lines 125-164 (`apply` docstring — wave-8 W8-T3 essay + parameter doc)
- Lines 165-207 (idle-branch wave-7d/7f reset commentary)
- Lines 213-234 (degenerate-geometry branch reset commentary)
- Lines 236-244 (fullscreenWidth derivation note)
- Lines 246-274 (Wave-8 W8-T3 projection essay)
- Lines 300-336 (token/cell apply commentary — wave-7c-fix Issue #7, wave-7d W1 chrome ramp, wave-7e chrome-removal note)
- Lines 339-354 (non-active fade pass wave-7c fix-bundle Issue #11)
Comment-slim potential: ~210 LOC of 360 (≈58%).

### Hard deletes
**WHOLE FILE** (360 LOC). V1_ONLY.

### Cross-ref warnings
- Deleting breaks `ActiveConversationCoordinator.tokenApplier` field + `attachChrome` forwarder + `handleAnimatorTick` apply call (all V1_ONLY, slated)
- Deleting breaks `ConversationComposer.make` line 49 (slated)
- `ChatBodyEagerInstantiationTests`, `TokenApplierTests`, `EmptyBubbleFixTests`, `ComposerAnchorTests` all become deletable
- `TimelineCanvasPreviewVC` has a stale comment-only reference at line 87 — purely cosmetic, can stay or be slimmed in debug audit

---

## Summary

- **ORPHAN: 1** (`MorphState.isInFlight` — also V1_ONLY by enclosing struct, but distinctly unreferenced)
- **V1_ONLY: ~70 symbols** spanning all 7 files (every public/internal symbol traces back to ConversationComposer → ConversationViewController, both V1-graph dead)
- **LIVE_REACHABLE: 0**
- **TEST_ONLY: 0** (no symbol exists solely for tests; tests piggyback the V1 graph)
- **AMBIGUOUS: 0**

**Hard-delete LOC: 2207** (915 + 39 + 96 + 70 + 623 + 64 + 360)
**Comment-slim LOC if files retained instead: ~1063** (450 + 22 + 38 + 35 + 280 + 28 + 210)
**Whole-file deletes: 7 of 7**

### Cascade warnings to other audit lanes
Deleting these 7 files requires coordinated deletion of:
- `App/ConversationComposer.swift` (entire file orphaned — no V2 caller)
- `Conversation/ConversationViewController.swift` (entire file — V1 root)
- `Conversation/MorphBlurHost.swift`, `Conversation/MorphTiming.swift`, `Conversation/ConversationMorphTokens.swift` (V1-graph collaborators)
- `Conversation/Cells/ConversationCell.swift`, `Conversation/Cells/CellSummaryView.swift` (V1 cell-rendering)
- `Conversation/Chrome/ListComposerView.swift` (V1 chrome — constructed by composer)
- `Gestures/PinchToMemoryInteraction.swift` (V1 gesture; uses PinchMorphState which IS reachable from V2 SpringAnimator — but the interaction itself is not)
- `Debug/MorphScrubberDebug.swift` (Mirror-discovers ActiveConversationCoordinator under V1 rootVC only — inert under V2 — recommend deletion)
- `Debug/TimelineCanvasPreviewVC.swift` (only referenced from ConversationViewController.swift:398 debug seam — orphaned with VC deletion)
- `DesignSystem/AccessibilityID.swift:21` (`memoryTimeline` constant becomes ORPHAN)
- ~18 test files transitively dependent (all referencing V1 fixtures via `Fixtures.makeTokenApplierFixture` / `Fixtures.makeCoordinatorFixture` / direct V1 construction): ChatBodyEagerInstantiationTests, PinchGlyphPhaseTests, ConversationViewControllerSubviewOrderTests, TapTargetTests, BlurReparentTests, MemoryTimelineTests, MorphStateTests, Wave7cSurvivabilityTests, MorphContainerRetirementTests, CompositionTests, PinchFromIdleActivationTests, AnchorSpringContinuityTests, EmptyBubbleFixTests, SpatialAnchorResolverTests, TokenApplierTests, ReactiveBindingsTests, ComposerAnchorTests, ConversationMorphTokensTests, ReferenceCorrelationTests, ChatComposerResponderTests, CohesionInvariantTests, ThemeCellFillTests, StateMachineCompletenessTests, VisualAuditHarnessTests, Tests/Support/Fixtures.swift

### Cross-lane verification recommendations
- The PinchMorphState type (Gestures/PinchMorphState.swift) IS still consumed by `SpringAnimator` (Animation/) — confirm with the Gestures/Animation audit lane that PinchMorphState survives even if `PinchToMemoryInteraction` is purged. Currently the type carries `progress: Double` and `velocity` boilerplate that satisfies SpringAnimator's generic constraints; if V2 keeps using SpringAnimator<PinchMorphState>, the type must remain.
- AccessibilityID.memoryTimeline is only set on the V1 collection view — recommend its deletion in the DesignSystem audit.
