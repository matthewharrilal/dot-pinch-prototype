# Audit A9 — DesignSystem + Tests
ROLE: AUDIT-A9

Live entry: `AppDelegate → V2RootViewController()`. Reachability classification below is
relative to V2 path only; "V1_ONLY" means the symbol is dead once
`ConversationViewController.swift` and its V1 subtree are purged.

V2-reachable production files surveyed: `V2RootViewController`, `TimelineCanvas`,
`ChatViewController`, `CellView`, `TimelineDataSourceAdapter`, `TimelineDataSource`,
`Camera`, `CameraAnimator`, `ChatBubbleView`, `ConversationStore`,
`DummyConversationLoader`, `AppDelegate`, models, animation/, gestures/.

V1-only production (dead post-purge): `ConversationViewController`,
`ActiveConversationCoordinator`, `MorphState`, `MemoryTimeline`,
`PinchToMemoryInteraction`, `MorphBlurHost`, `ConversationMorphTokens`,
`MorphTiming`, `TokenApplier`, `ReactiveBinder`, `ConversationCell`,
`CellSummaryView`, `ChatBodyView`, `ListComposerView`, `ConversationComposer`,
`SpatialAnchorResolver`, `CellMetrics`, `Debug/TimelineCanvasPreviewVC`,
`Debug/MorphScrubberDebug`.

---

## File: DotPinchPrototype/DesignSystem/AccessibilityID.swift

### Symbols (with tags)

| Symbol | Tag | Notes |
|---|---|---|
| `demoRoot` | V1_ONLY | only `ConversationViewController` |
| `conversationSurface` | LIVE_REACHABLE | used in V2 `CellView.swift:162` (also `ChatBodyView` V1) |
| `conversationOverlay` | V1_ONLY | `ConversationViewController` + 2 V1 tests |
| `morphBlurHost` | V1_ONLY | `ConversationViewController`, `ActiveConversationCoordinator`, V1 `BlurReparentTests` |
| `composerPlaceholder` | V1_ONLY | only `ListComposerView` (V1 chrome) |
| `statusLabel` | V1_ONLY | only `ConversationViewController` |
| `memoryTimeline` | V1_ONLY | `MemoryTimeline`, `ConversationViewController`, V1 test |
| `conversationCell` | V1_ONLY | `ConversationCell`, `ActiveConversationCoordinator`, `TokenApplier`, V1 tests + Support |
| `pinchGlyph` | V1_ONLY | V1 `ConversationViewController`, `ConversationMorphTokens`, `MorphTiming` (+ 6 V1 tests) |
| `menuButton` | V1_ONLY | V1 `ConversationViewController`, `ConversationMorphTokens`, `TokenApplier` (+ 5 V1 tests) |
| `listComposerTextField` | V1_ONLY | only `ListComposerView` |
| `listComposerSendButton` | V1_ONLY | only `ListComposerView` |
| `chatComposerTextField` | V1_ONLY | only V1 `ChatBodyView` (V2's `ChatViewController` does NOT set this AID) |
| `chatComposerSendButton` | V1_ONLY | only V1 `ChatBodyView` |

### Comment-slim
DELETE verbose phase/wave/Branch-N refs on lines 1-3, 8-9, 11-18, 23-24, 27-29, 32-34.

KEEP top-of-file docstring (3-4 lines, summarising "A11y registry — all UITests/
Maestro selectors route through here, not literals.").

### Hard deletes
Post V1-purge: delete every symbol except `conversationSurface`. File collapses to
~6 lines including the 4-line docstring.

### Cross-ref warnings
`conversationSurface` is also set on V1 `ChatBodyView` — V1 path is dead, but the
constant survives because V2 `CellView` retains the binding. No additional
cleanup needed in V2.

---

## File: DotPinchPrototype/DesignSystem/SymbolName.swift

### Symbols (with tags)

| Symbol | Tag | Notes |
|---|---|---|
| `pinchCollapseAffordance` | V1_ONLY | V1 `ConversationViewController:1099`, V1 `TimelineCanvasPreviewVC:108`, V1 tests (PinchGlyphPhaseTests, Wave7cSurvivabilityTests) |
| `pinchExpandAffordance` | LIVE_REACHABLE | V2 `CellView.swift:321` (also V1 callers) |
| `menu` | V1_ONLY | only V1 `ConversationViewController:690` |

### Comment-slim
DELETE the phantom-retirement paragraph (lines 19-25) — references "Wave-7d W3
F-21 phantom census" / "Synthesis §5" / "Branch 5". Wave/phase refs.

KEEP top-of-file docstring (2 lines already conformant).
KEEP per-symbol one-line docstrings on `pinchExpandAffordance` and `menu`.

### Hard deletes
Post V1-purge: delete `pinchCollapseAffordance` and `menu`. File collapses to
one constant (`pinchExpandAffordance`) — consider inlining the literal into
`CellView.swift:321` and deleting the file entirely.

### Cross-ref warnings
If `pinchCollapseAffordance` survives, ensure V1 test files
(`PinchGlyphPhaseTests`, `Wave7cSurvivabilityTests`) are also purged.

---

## File: DotPinchPrototype/DesignSystem/Theme.swift

### Symbols (with tags)

**Theme.Page**
| Symbol | Tag | Reachability via V2 |
|---|---|---|
| `Page.top` | LIVE_REACHABLE | V2 `TimelineCanvas` (+ V1 VC, V2 test) |
| `Page.surface` | LIVE_REACHABLE | V2 `AppDelegate`, `V2RootViewController`, `TimelineCanvas`, `ChatViewController`, `ListComposerView`, `ChatBodyView`, `Theme` self-ref, V2 test |
| `Page.bottom` | LIVE_REACHABLE | V2 `TimelineCanvas` (+ V1 VC, V1/V2 tests) |

**Theme.Chat**
| Symbol | Tag | Reachability |
|---|---|---|
| `Chat.topTint` | V1_ONLY | only V1 `ConversationViewController` |
| `Chat.bottomTint` | V1_ONLY | V1 `ConversationViewController`, `ConversationCell`, `ChatBodyView`, V1 tests. Self-ref in `Theme.swift` (`Chat.topTint = Page.surface`). Not used in V2. |

**Theme.Cell**
| Symbol | Tag | Reachability |
|---|---|---|
| `Cell.fill` | LIVE_REACHABLE | V2 `ChatViewController:?`, V2 `CellView`. Also V1 `ConversationCell`, V1 `ConversationViewController`, V1 `TimelineCanvasPreviewVC`, V1 tests |

**Theme.Text**
| Symbol | Tag | Reachability |
|---|---|---|
| `Text.primary` | LIVE_REACHABLE | V2 `ChatViewController`, `CellView`, `ChatBubbleView` (via ChatVC) (+ V1) |
| `Text.secondary` | LIVE_REACHABLE | V2 `ChatBubbleView` only |
| `Text.tertiary` | LIVE_REACHABLE | V2 `CellView`, `ChatBubbleView` (+ V1) |
| `Text.placeholder` | V1_ONLY | V1 `ListComposerView`, `ChatBodyView` only |
| `Text.glyph` | LIVE_REACHABLE | V2 `CellView` (+ V1 VC, V1 `TimelineCanvasPreviewVC`) |
| `Text.glyphSubtle` | V1_ONLY | only V1 `ConversationViewController` |
| `Text.serifBody` | LIVE_REACHABLE | V2 `CellView` (+ V1 `CellSummaryView`) |
| `Text.debug` | V1_ONLY | only V1 `ConversationViewController` |

**Theme.Typography**
| Symbol | Tag | Reachability |
|---|---|---|
| `Typography.bubbleSender` | LIVE_REACHABLE | V2 `ChatBubbleView` (via ChatViewController) |
| `Typography.bubbleBody` | LIVE_REACHABLE | V2 `ChatBubbleView` |
| `Typography.bubbleTime` | LIVE_REACHABLE | V2 `ChatBubbleView` |
| `Typography.composerHint` | LIVE_REACHABLE | V2 `ChatViewController` (+ V1 `ListComposerView`, `ChatBodyView`) |
| `Typography.destinationDate` | LIVE_REACHABLE | V2 `CellView` (+ V1 `CellSummaryView`) |
| `Typography.statusLabel` | V1_ONLY | only V1 `ConversationViewController` |
| `Typography.destinationBody` | LIVE_REACHABLE | V2 `CellView`, V2 `ChatViewController` (+ V1 `CellSummaryView`) |
| `Typography.destinationBodyLineHeight` | V1_ONLY | only V1 `CellSummaryView` |

**Theme.Radius**
| Symbol | Tag | Reachability |
|---|---|---|
| `Radius.card` | LIVE_REACHABLE | V2 `CellView` only |
| `Radius.composer` | V1_ONLY | V1 `ListComposerView`, `ChatBodyView` only |

**Theme.Shadow** (ALL ORPHANS)
| Symbol | Tag | Reachability |
|---|---|---|
| `Shadow.cardFinalOffset` | ORPHAN | zero call sites anywhere (incl. tests) |
| `Shadow.cardFinalRadius` | ORPHAN | zero call sites |
| `Shadow.cardFinalOpacity` | ORPHAN | zero call sites |

**Theme.Symbol**
| Symbol | Tag | Reachability |
|---|---|---|
| `Symbol.pinchAffordancePointSize` | LIVE_REACHABLE | V2 `CellView` (+ V1 VC, V1 `ChatBodyView`, V1 `TimelineCanvasPreviewVC`) |
| `Symbol.pinchAffordanceWeight` | LIVE_REACHABLE | V2 `CellView` (+ V1) |
| `Symbol.menuPointSize` | V1_ONLY | only V1 `ConversationViewController` |
| `Symbol.menuWeight` | V1_ONLY | only V1 `ConversationViewController` |

### Comment-slim
File is comment-heavy with wave/RCA references. Aggressive trim required:
- DELETE the 17-line preamble (lines 3-17) explaining `Page.surface` vs
  `Chat.bottomTint` chromatic-continuity rationale. Replace with one
  4-line top-of-enum docstring.
- DELETE wave-7c retro / Issue #4 / `retros/rca-issue-4-...` paragraphs on
  the `Cell` enum (lines 57-75). Replace with one-line "Rest-state cell fill
  (#f6efef)." If `Chat.bottomTint` is purged, the entire interpolation
  rationale dies with it.
- DELETE the 2026-05-17 retune paragraph on `Page.bottom` (lines 30-36).
- DELETE the W8-COMPOSER-P3 retune paragraph on `Chat.bottomTint`
  (lines 47-54) — and the entire `Chat` enum once `bottomTint` and `topTint`
  are V1-purged.
- KEEP `// MARK: -` separators.
- KEEP single-line `///` color-hex docstrings where the hex appears.

### Hard deletes
Post V1-purge, delete these symbols:
- `Chat` enum entirely (`topTint`, `bottomTint`) — both V1_ONLY
- `Text.placeholder`, `Text.glyphSubtle`, `Text.debug`
- `Typography.statusLabel`, `Typography.destinationBodyLineHeight`
- `Radius.composer`
- `Shadow` enum entirely (3 ORPHANS — delete now regardless of V1 purge)
- `Symbol.menuPointSize`, `Symbol.menuWeight`

Theme.swift can collapse from 150 LOC to ~50 LOC after V1-purge + Shadow-orphan
deletion + comment-slim.

### Cross-ref warnings
- `Theme.Chat.topTint = Theme.Page.surface` — when `Chat` is deleted, the
  `Page.surface` reference is fine (Page survives).
- `Cell.fill` interpolation target in `ConversationCell.apply(_:)` dies with
  V1 purge; in V2, `CellView` uses `Cell.fill` as a static color (no lerp). The
  `Cell` enum docstring's "interpolates toward `Theme.Chat.bottomTint`" claim
  becomes stale and must be deleted alongside `Chat`.

---

## File: Tests/AnchorSpringContinuityTests.swift (259 LOC)
V1_ONLY — exercises `PinchToMemoryInteraction` + `ConversationCell.apply`.
**WHOLE-FILE DELETE.**

## File: Tests/BlurReparentTests.swift (270 LOC)
V1_ONLY — `MorphBlurHost` reparent guardrail for V1 coordinator.
**WHOLE-FILE DELETE.**

## File: Tests/ChatBodyEagerInstantiationTests.swift (170 LOC)
V1_ONLY — `ConversationCell.chatBody` lazy/eager regime.
**WHOLE-FILE DELETE.**

## File: Tests/ChatComposerResponderTests.swift (393 LOC)
V1_ONLY — bind/unbind on V1 `ChatBodyView`.
**WHOLE-FILE DELETE.**

## File: Tests/CohesionInvariantTests.swift (612 LOC)
V1_ONLY — `ConversationMorphTokens` cohesion DAG.
**WHOLE-FILE DELETE.**

## File: Tests/ComposerAnchorTests.swift (336 LOC)
V1_ONLY — V1 `ChatBodyView` composer-anchor invariant.
**WHOLE-FILE DELETE.**

## File: Tests/CompositionTests.swift (447 LOC)
V1_ONLY — `ConversationMorphTokens` at intermediate progress.
**WHOLE-FILE DELETE.**

## File: Tests/ConversationDraftTextTests.swift (90 LOC)
LIVE — tests `Conversation.draftText` + `ConversationStore.updateDraftText`.
V2's `ChatViewController`/`CellView` do NOT exercise draftText currently, but
`ConversationStore` survives the V1 purge, so the test still compiles.
TAG: TEST_ONLY (orphan if V2 doesn't add draft persistence; LIVE if V2 plans to).
**RECOMMEND: KEEP** until V2 confirms draftText is/isn't on roadmap.

Comment-slim: docstring trim from 18 → 4 lines.

## File: Tests/ConversationMorphTokensTests.swift (960 LOC)
V1_ONLY — entire suite is `ConversationMorphTokens` (V1).
**WHOLE-FILE DELETE.**

## File: Tests/ConversationViewControllerSubviewOrderTests.swift (178 LOC)
V1_ONLY — z-order guardrail for V1 VC.
**WHOLE-FILE DELETE.**

## File: Tests/EmptyBubbleFixTests.swift (294 LOC)
V1_ONLY — V1 `ConversationCell.morphContainer`, V1 chatBody overlay.
**WHOLE-FILE DELETE.**

## File: Tests/MemoryTimelineTests.swift (262 LOC)
V1_ONLY — V1 `MemoryTimeline.scrollToCellIfNeeded`.
**WHOLE-FILE DELETE.**

## File: Tests/MorphContainerRetirementTests.swift (202 LOC)
V1_ONLY — V1 `ConversationCell` morphContainer transform retirement.
**WHOLE-FILE DELETE.**

## File: Tests/MorphStateTests.swift (357 LOC)
V1_ONLY — `ActiveConversationCoordinator` state machine.
**WHOLE-FILE DELETE.**

## File: Tests/PinchFromIdleActivationTests.swift (392 LOC)
V1_ONLY — V1 `MemoryTimeline` + `TokenApplier` activation flow.
**WHOLE-FILE DELETE.**

## File: Tests/PinchGlyphPhaseTests.swift (267 LOC)
V1_ONLY — V1 `ConversationViewController.applyMorphPhaseToTimeline`.
**WHOLE-FILE DELETE.**

## File: Tests/ReactiveBindingsTests.swift (205 LOC)
V1_ONLY — V1 `ReactiveBinder` cancellation seam.
**WHOLE-FILE DELETE.**

## File: Tests/ReferenceCorrelationTests.swift (394 LOC)
AMBIGUOUS — env-gated (`RUN_VISUAL_AUDIT_HARNESS=1`), `#if os(macOS)`,
shells out to Maestro+ffmpeg+xcodebuild. No direct V1 type references; runs
against captured frames vs reference. The integration depends on the running
app, so V2 reachability is implicit (whatever AppDelegate launches).

**RECOMMEND: KEEP** — visual-audit gate survives V1 purge (operates on
rendered output, not V1 internals). Comment-slim only.

Comment-slim: docstring trim from 37 → 4 lines. DELETE wave-7e WE5 / Phase E /
VAH baseline references throughout.

## File: Tests/SpatialAnchorResolverTests.swift (168 LOC)
V1_ONLY — V1 `SpatialAnchorResolver` against `MemoryTimeline`.
**WHOLE-FILE DELETE.**

## File: Tests/StateMachineCompletenessTests.swift (286 LOC)
V1_ONLY — `ConversationMorphTokens` + `MorphState`.
**WHOLE-FILE DELETE.**

## File: Tests/TapTargetTests.swift (196 LOC)
V1_ONLY — V1 `ConversationViewController` tap recognizer + `PinchToMemoryInteraction`.
**WHOLE-FILE DELETE.**

## File: Tests/ThemeCellFillTests.swift (208 LOC)
V1_ONLY — exercises `ConversationCell` lerp(`Cell.fill` → `Chat.bottomTint`).
**WHOLE-FILE DELETE.**

## File: Tests/TokenApplierTests.swift (605 LOC)
V1_ONLY — entire suite is `TokenApplier`.
**WHOLE-FILE DELETE.**

## File: Tests/VisualAuditHarnessTests.swift (160 LOC)
AMBIGUOUS — env-gated (`RUN_VISUAL_AUDIT_HARNESS=1`), `#if os(macOS)`,
scaffold integration. No direct V1 type references; asserts artifact shape.

**RECOMMEND: KEEP** — same logic as `ReferenceCorrelationTests`. Comment-slim only.

## File: Tests/Wave7cSurvivabilityTests.swift (220 LOC)
V1_ONLY — wave-7c-fix bundle behaviors on `ConversationCell`.
**WHOLE-FILE DELETE.**

## File: Tests/Support/Fixtures.swift (302 LOC)
V1_ONLY — `TestFixture` (ActiveConversationCoordinator + SpringAnimator +
ConversationStore + AnimationController) and `TokenApplierFixture`
(TokenApplier + ConversationCell + MemoryTimeline + SpatialAnchorResolver).
Both bundles wire V1 types exclusively.
**WHOLE-FILE DELETE.**

## File: Tests/Support/TemporalContinuity.swift (234 LOC)
V1_ONLY — `LifecycleDriver` simulates V1 gesture pipeline (coordinator →
applier → cell) via `CoordinatorApplierFixture`.
**WHOLE-FILE DELETE.**

---

## Tests/V2/ — KEEP ALL (with comment-slim)

All 30 files target V2 mechanics (`TimelineCanvas`, `ChatViewController`,
`CellView`, `TimelineDataSource`, `Camera`, `CameraAnimator`, `PinchTuning`).

The single ambiguous case, `Tests/V2/PageGradientFixTests.swift`, references V1
only in a 1-line comment (`line 5: "(mirror of V1 ...)"`); drop the comment,
keep the file.

**Recommended comment-slim across all V2 tests:**
- DELETE D2 §-references / Phase N / Wave RX.Y prefixes in top docstrings.
- DELETE "Wave R3.4 remediation" / "remediation deliverable" framing.
- KEEP one 3-4 line top-of-file docstring per file, no method-level
  docstrings unless setup is non-trivial.
- KEEP `// MARK: -` separators.

Specific high-noise candidates (wave/phase refs to scrub):
- `WaveR1ProgressPointCaptures.swift`, `WaveR11LifecycleAdversarialTests.swift`,
  `WaveR12OptionsACVerification.swift`, `WaveR31-R36`, `WaveR41-R44`,
  `WaveR61R62`, `WaveR64R65`, `WaveR72-R75`.
- `Wave4a-g` series.
- `Phase0Spike07/08` files (D2 §10 spike framing).

Several test files are also named with wave prefixes (`WaveR41SubstrateCanaryTests`,
`Wave4aActiveCellIndexTests`, etc.). Renames out-of-scope for comment-slim but
worth flagging for a follow-up "test name canonicalization" pass.

---

## Summary

### DesignSystem (3 files, 216 LOC total)

**LIVE_REACHABLE symbols (kept):**
- `AccessibilityID.conversationSurface` (1 of 14)
- `SymbolName.pinchExpandAffordance` (1 of 3)
- Theme: `Page.top/surface/bottom`, `Cell.fill`,
  `Text.primary/secondary/tertiary/glyph/serifBody`,
  `Typography.bubbleSender/bubbleBody/bubbleTime/composerHint/destinationDate/destinationBody`,
  `Radius.card`,
  `Symbol.pinchAffordancePointSize/pinchAffordanceWeight` (17 of 31)

**V1_ONLY symbols (deleted with V1 purge):**
- AccessibilityID: 13 of 14 constants
- SymbolName: 2 of 3 (`pinchCollapseAffordance`, `menu`)
- Theme: 14 of 31 (`Chat.topTint`, `Chat.bottomTint`,
  `Text.placeholder/glyphSubtle/debug`,
  `Typography.statusLabel/destinationBodyLineHeight`,
  `Radius.composer`,
  `Symbol.menuPointSize/menuWeight`)

**ORPHAN symbols (delete NOW, no V1-purge dependency):**
- `Theme.Shadow.cardFinalOffset/cardFinalRadius/cardFinalOpacity` (3 fields, ~6 LOC)

**Projected DesignSystem LOC after V1-purge + comment-slim:**
- AccessibilityID.swift: 37 → ~6 LOC (or delete file, inline literal)
- SymbolName.swift: 29 → ~5 LOC (or delete file, inline literal)
- Theme.swift: 150 → ~50 LOC

### Tests (56 files, 13,067 LOC total)

| Bucket | Files | LOC | Action |
|---|---|---|---|
| Top-level V1_ONLY | 21 | ~6,653 | WHOLE-FILE DELETE |
| Support V1_ONLY | 2 | 536 | WHOLE-FILE DELETE |
| Top-level KEEP | 3 | 644 | Comment-slim |
| V2 KEEP | 30 | 4,600 | Comment-slim |

**Whole-file deletes (Tests):**
```
Tests/AnchorSpringContinuityTests.swift         259
Tests/BlurReparentTests.swift                   270
Tests/ChatBodyEagerInstantiationTests.swift     170
Tests/ChatComposerResponderTests.swift          393
Tests/CohesionInvariantTests.swift              612
Tests/ComposerAnchorTests.swift                 336
Tests/CompositionTests.swift                    447
Tests/ConversationMorphTokensTests.swift        960
Tests/ConversationViewControllerSubviewOrderTests.swift  178
Tests/EmptyBubbleFixTests.swift                 294
Tests/MemoryTimelineTests.swift                 262
Tests/MorphContainerRetirementTests.swift       202
Tests/MorphStateTests.swift                     357
Tests/PinchFromIdleActivationTests.swift        392
Tests/PinchGlyphPhaseTests.swift                267
Tests/ReactiveBindingsTests.swift               205
Tests/SpatialAnchorResolverTests.swift          168
Tests/StateMachineCompletenessTests.swift       286
Tests/TapTargetTests.swift                      196
Tests/ThemeCellFillTests.swift                  208
Tests/TokenApplierTests.swift                   605
Tests/Wave7cSurvivabilityTests.swift            220
Tests/Support/Fixtures.swift                    302
Tests/Support/TemporalContinuity.swift          234
                                          --------
                                            7,823 LOC purged
```

**Top-level KEEPs (3 files, 644 LOC):**
- `ConversationDraftTextTests.swift` (90)
- `ReferenceCorrelationTests.swift` (394)
- `VisualAuditHarnessTests.swift` (160)

**V2/ KEEPs (30 files, 4,600 LOC):** all V2 tests survive; comment-slim only.

**Post-purge Tests/ LOC projection:** ~5,244 LOC (down from 13,067, 60% reduction).

### Cross-cutting warnings

1. **`Tests/V2/PageGradientFixTests.swift:5`** has a stale "V1 mirror" comment
   reference — delete in comment-slim.
2. **`Theme.Cell.fill` docstring** references `ConversationCell.apply(_:)` lerp
   site — after V1 purge, the interpolation toward `Chat.bottomTint` dies; update
   docstring or delete `Chat` enum entirely.
3. **`AccessibilityID.conversationSurface`** is set on both V1 `ChatBodyView`
   and V2 `CellView` — V1 site dies with the file, but the constant stays.
4. **No accessibilityIdentifier is set** on V2 `ChatViewController` composer
   textfield/sendButton. If V2 plans Maestro coverage of the chat composer,
   new AIDs will need to be added (the V1 `chatComposer*` constants are dead
   AND V2 has no replacement).
5. **`Tests/V2/` test filenames** carry Wave/R-prefix naming (e.g.
   `WaveR41SubstrateCanaryTests`). Comment-slim doesn't rename files;
   follow-up pass advised if naming canonicalization is desired.
6. **`ConversationDraftTextTests`** is the lone top-level test that survives
   without depending on V1 mechanics — it tests `Conversation.draftText` /
   `ConversationStore.updateDraftText`. V2 does not currently exercise drafts;
   monitor for orphan-status if V2 doesn't grow draft persistence.
