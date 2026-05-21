# Audit A3 — Conversation/Cells/ + Conversation/Chrome/
ROLE: AUDIT-A3

## Scope summary

Three files audited:

- `DotPinchPrototype/Conversation/Cells/CellSummaryView.swift` (141 LOC)
- `DotPinchPrototype/Conversation/Cells/ConversationCell.swift` (1063 LOC)
- `DotPinchPrototype/Conversation/Chrome/ListComposerView.swift` (190 LOC)

Live path is `AppDelegate -> V2RootViewController() -> TimelineCanvas + CellView` (V2). All three files are consumed exclusively by the V1 path (`ConversationComposer.make() -> ConversationViewController -> MemoryTimeline -> ConversationCell -> {CellSummaryView, ChatBodyView}` and `ConversationViewController + ListComposerView`). `ConversationComposer.make()` is never called from production code; the only callers are XCTest fixtures in `/Tests/`. Therefore every symbol below is V1_ONLY relative to the live V2 path, even if it remains TEST_ONLY-reachable via xctest.

V2 dir (`DotPinchPrototype/Conversation/V2/`) has zero source references to any of these three types. The only string match in V2 is a Maestro/UI-test-selector comment in `V2/CellView.swift:161` mentioning ChatBodyView for parity, not a code reference.

Classification convention used below:
- V1_ONLY = symbol is reachable only from the V1 path; not reachable from V2RootViewController.
- TEST_ONLY = symbol's only remaining external references are in `/Tests/`.
- For the three files at hand, V1_ONLY is the dominant tag; individual members are LIVE_REACHABLE within the V1 subgraph.

---

## File: DotPinchPrototype/Conversation/Cells/CellSummaryView.swift

### Symbols

| Name | Kind | Line | Visibility | Tag | External refs |
|---|---|---|---|---|---|
| `CellSummaryView` | class | 12 | internal | V1_ONLY | `ConversationCell.swift:76` (sole production use); 5 test files (TokenApplierTests, ReactiveBindingsTests, EmptyBubbleFixTests, ThemeCellFillTests, Wave7cSurvivabilityTests) walk subview tree via `CellSummaryView.self` |
| `dateLabel` | stored property | 16 | private | V1_ONLY | none external |
| `summaryLabel` | stored property | 17 | private | V1_ONLY | none external |
| `conversation` | weak stored | 21 | private | V1_ONLY | none external |
| `summaryBinder` | stored property | 30 | private | V1_ONLY | none external |
| `init()` | initializer | 34 | internal | V1_ONLY | `ConversationCell.swift:76`; `ReactiveBindingsTests.swift:69,89,108,127,160` |
| `init?(coder:)` | initializer | 40 | required | V1_ONLY | UIKit-required |
| `bind(to:)` | method | 46 | internal | V1_ONLY | `ConversationCell.swift:319`; ReactiveBindingsTests |
| `unbind()` | method | 59 | internal | V1_ONLY | `ConversationCell.swift:234` |
| `armObservation()` | method | 81 | private | V1_ONLY | call-site `bind(to:)` |
| `renderCurrentValues()` | method | 96 | private | V1_ONLY | call-sites in `bind(to:)` + `armObservation` apply closure |
| `configureSubviews()` | method | 115 | private | V1_ONLY | call-site `init` |
| `activateLayoutConstraints()` | method | 128 | private | V1_ONLY | call-site `init` |

### Comment-slim (~25 lines removable)

- Lines 3-6: stale narrative about an `Observation` import being dropped + Wave-7a citation. The current file no longer imports `Observation`; this paragraph documents history, not behavior. Delete.
- Lines 23-29: 7-line Wave-7a E-4 D1 migration block on `summaryBinder`. Replace with a 1-line note: `/// ReactiveBinder owns the deferred-apply Task + cancellation.`
- Lines 53-58: 6-line `unbind()` historical narrative (E-2 / E-3 / Wave-7a E-4 D1). Keep semantics ("cancel before nil-ing conversation"), drop wave refs. Trim to 2 lines.
- Lines 68-80: 13-line `armObservation` docstring with wave refs, partition history, E-1/E-2/E-3/E-6 citations. Trim to 4 lines: "Routes the (read, apply) tuple through ReactiveBinder. Narrow read partition: curatedSummary + displayDate only. Apply guards conversation != nil so a stale hop bails."
- Line 44-45: W2-G3 citation is two-line comment on `bind`; replace with one line.

Keep: top-of-file 3-line class docstring (8-10), `// MARK: -` markers, the doc-comment on `bind(to:)`/`unbind()` (slimmed).

### Hard deletes

None — every symbol is referenced within the V1 subgraph that backs production-equivalent tests. (Whole-file delete only viable if the V1 path itself is purged; see Summary.)

### Cross-ref warnings

- 5 test files locate `CellSummaryView` by type (`findSubview(of: CellSummaryView.self, in: cell)`). If this file is deleted as part of V1 purge, those tests must be deleted in lock-step: `TokenApplierTests.swift`, `ReactiveBindingsTests.swift`, `EmptyBubbleFixTests.swift`, `ThemeCellFillTests.swift`, `Wave7cSurvivabilityTests.swift`.
- `ConversationMorphTokens.swift:291`, `MorphTiming.swift:66`, `ConversationStore.swift:131`, `Conversation.swift:61,75`, `MemoryTimeline.swift:115,263`, `ActiveConversationCoordinator.swift:792,907`, `ConversationViewController.swift:298,998`, `Morph/ReactiveBinder.swift:4,18`, `ChatBody/README.md:2`, `Memory/CellMetrics.swift:53,59,62,65,68` all contain doc-comment references to `CellSummaryView`. These break only if the symbol moves; not load-bearing for compilation. Slim or delete during V1 purge.

---

## File: DotPinchPrototype/Conversation/Cells/ConversationCell.swift

### Symbols

| Name | Kind | Line | Visibility | Tag | External refs |
|---|---|---|---|---|---|
| `ConversationCell` | class | 37 | internal | V1_ONLY | `MemoryTimeline.swift:170,171,196,198,461,463,488,489,490`; `ActiveConversationCoordinator.swift` (multiple); 8 test files |
| `reuseIdentifier` | static let | 43 | internal | V1_ONLY | `MemoryTimeline.swift:171,196` |
| `morphContainer` | stored property | 71 | private | V1_ONLY | internal only |
| `summaryView` | stored property | 76 | private | V1_ONLY | internal only (tests reach via subview walk) |
| `chatBody` | stored property | 101 | private | V1_ONLY | exposed via `chatBodyView` accessor |
| `hasObservedFirstActivation` | stored property | 110 | private | V1_ONLY | internal only |
| `chatBodyView` | computed property | 118 | internal | V1_ONLY | `ActiveConversationCoordinator.swift` (liftActiveCellIfNeeded) |
| `chatBodyHeightConstraint` | stored property | 130 | private | V1_ONLY | internal only |
| `chatBodyTopConstraint` | stored property | 138 | private | V1_ONLY | internal only |
| `chatBodyWidthConstraint` | stored property | 148 | private | V1_ONLY | internal only |
| `cellAnchoredConstraints` | stored property | 163 | private | V1_ONLY | internal only |
| `overlayAnchoredConstraints` | stored property | 164 | private | V1_ONLY | internal only |
| `lifted` | stored property | 171 | private | V1_ONLY | internal only |
| `conversation` | private(set) | 181 | internal | V1_ONLY | `ActiveConversationCoordinator`, `MemoryTimeline` |
| `onChatSendMessage` | stored closure | 190 | internal | V1_ONLY | `MemoryTimeline.cellProvider` |
| `onChatDraftTextChanged` | stored closure | 193 | internal | V1_ONLY | `MemoryTimeline.cellProvider` |
| `init(frame:)` | initializer | 199 | override | V1_ONLY | UIKit dequeue path |
| `init?(coder:)` | initializer | 205 | required | V1_ONLY | UIKit-required |
| `prepareForReuse()` | method | 211 | override | V1_ONLY | UIKit lifecycle |
| `configure(with:)` | method | 317 | internal | V1_ONLY | `MemoryTimeline.cellProvider` |
| `configureAppearance()` | method | 333 | private | V1_ONLY | call-site `init` |
| `configureSubviews()` | method | 390 | private | V1_ONLY | call-site `init` |
| `apply(_:)` | method | 476 | internal | V1_ONLY | `TokenApplier.applyToCell` |
| `instantiateChatBodyIfNeeded()` | method | 683 | private | V1_ONLY | call-site `configureSubviews` |
| `lift(chatBody:to:)` | method | 789 | internal | V1_ONLY | `ActiveConversationCoordinator.liftActiveCellIfNeeded` |
| `lower(chatBody:to:)` | method | 843 | internal | V1_ONLY | `ActiveConversationCoordinator.lowerLiftedCellIfNeeded` + `prepareForReuse:222` self-call |
| `liftBlur(blur:to:)` | method | 890 | internal | V1_ONLY | `ActiveConversationCoordinator.liftActiveCellIfNeeded` |
| `lowerBlur(blur:)` | method | 905 | internal | V1_ONLY | `ActiveConversationCoordinator.lowerLiftedCellIfNeeded` + `prepareForReuse:229` |
| `MorphContainerView` | class | 991 | internal | V1_ONLY | line 71 (sole consumer) |
| `MorphContainerView.maskCornerRadius` | stored property | 999 | internal | V1_ONLY | `ConversationCell.swift:267,353,585` |
| `MorphContainerView.cornerMaskLayer` | stored | 1003 | private | V1_ONLY | internal |
| `MorphContainerView.init(frame:)` | initializer | 1027 | override | V1_ONLY | line 71 |
| `MorphContainerView.init?(coder:)` | initializer | 1033 | required | V1_ONLY | UIKit-required |
| `MorphContainerView.layoutSubviews()` | override | 1037 | internal | V1_ONLY | UIKit lifecycle |
| `MorphContainerView.refreshMaskPath()` | method | 1046 | private | V1_ONLY | internal |

### Comment-slim (~410 lines removable)

This file is ~1063 lines of which ~732 lines are comments (`//`) and 286 lines are doc-comments (`///`) — a 1018-line comment surface. Per the project rules (one top-of-file docstring, top-of-method docstring only for non-trivial methods, kill wave refs/§/phase/pre-mortem refs), aggressive but conservative trim targets:

- Lines 1-33: 33-line top-of-file narrative dense with CP1/CP4 wave refs, EC7 history, W2-G1 citations. Trim to 4 lines: "Container cell carrying a single Conversation. Identity preserved across morph: same UIView instance at cell-state and chat-state; only metrics/alphas/foreground change. configure(with:) binds per-dequeue; prepareForReuse() drops the binding."
- Lines 49-70: 22-line `morphContainer` docstring (wave-6 history, W8-T2 narrative). Trim to 3 lines: "Morph container — visible cell surface (fill, corners, clip) decoupled from contentView's autoresize. Constraint-pinned so bounds stay stable under transform."
- Lines 78-100: 23-line `chatBody` docstring (Wave-7e WE10 history, memory analysis, lazy-vs-eager narrative). Trim to 4 lines: "Chat-state foreground (transcript + composer). Eagerly instantiated at init; opacity-ramped during morph. Optional storage kept for source-compat with chatBody?.x call sites."
- Lines 103-110: 8 lines on `hasObservedFirstActivation`. Trim to 2: "Set on first apply() tick with chatBodyAlpha > 0 — gates ChatBodyView.recaptureBaseline()."
- Lines 112-118: 7 lines on `chatBodyView`. Trim to 2: "Read-only accessor for ActiveConversationCoordinator.liftActiveCellIfNeeded()."
- Lines 122-129: 8 lines on `chatBodyHeightConstraint` (Wave-7c.next Path-A narrative). Trim to 2.
- Lines 132-138: 7 lines on `chatBodyTopConstraint`. Trim to 1: "Reset to 0 in prepareForReuse."
- Lines 140-148: 9 lines on `chatBodyWidthConstraint`. Trim to 1.
- Lines 150-162: 13 lines on `cellAnchoredConstraints`/`overlayAnchoredConstraints`. Trim to 3: "Constraint sets toggled by lift/lower. cellAnchored: chatBody under contentView (rest). overlayAnchored: chatBody pinned fullscreen to VC overlay (mid-morph)."
- Lines 166-171: 6 lines on `lifted` flag. Trim to 1.
- Lines 175-181: 7 lines on `conversation`. Trim to 1.
- Lines 183-189: 7 lines on the chat-composer callback forwarding section header. Trim to 2.
- Lines 214-229: 16-line defensive-lower commentary in prepareForReuse. Trim the rationale, keep the code, leave a 2-line note.
- Lines 236-243: 8-line `endEditing` rationale. Trim to 1 line.
- Lines 244-256: 13 lines on visual resets + Wave-7c fix-bundle Issue #11 history. Trim to 3.
- Lines 263-267: 5-line W8-T2 mask reset note. Trim to 1: "Reset mask radius to rest."
- Lines 268-289: 22-line block detailing 7c.next Path-A/Issue#1/Issue#2 height/top/width resets. Trim to 4 lines.
- Lines 291-304: 14-line "Note: chatBody is intentionally NOT released" + WE10 first-activation reset rationale. Trim to 4.
- Lines 308-317: 10-line `configure(with:)` docstring. Trim to 3.
- Lines 320-328: 9-line E-8 rebind note + rest-state visuals comment. Trim to 2.
- Lines 333-388: 56 lines of dense narrative in `configureAppearance` (P3.T6.S1.A4, Wave-7c Issue #4, Wave-7c.next Path-A, clipsToBounds explainers, P3.T8.S1.A1). Trim to 8 lines: "Visible surface lives on morphContainer (fill + corners + clip). contentView stays a transparent layout shell; clipsToBounds=false so the sibling chatBody can extend past contentView at chat-state. Suppress default UICollectionViewCell highlight."
- Lines 390-433: 44-line `configureSubviews` already mostly code + a final 11-line WE10 chatBody-instantiation comment. Trim the WE10 block to 2 lines.
- Lines 436-445: 10-line hit-test deferral commentary (P3.T7). Delete entirely — speculative wave-6 placeholder.
- Lines 447-475: 29-line `apply(_:)` docstring (W3-G2, Wave-7e WE10, W8-T3, W7-G4 references). Trim to 6 lines: "Per-tick morph token application. Drives morphContainer alpha + fill + cornerRadius + chatBody alpha + zPosition; routes through chatBody.apply(tokens). Single CATransaction wraps the whole tick."
- Lines 478-506: 29-line preamble inside apply() (W8-T3 pinchAnchor discard rationale, WE10 baseline-recapture seam, hasObservedFirstActivation discussion). Trim to 5.
- Lines 513-547: 35-line WE3 morphContainer.transform retirement narrative + Wave-6 known limitation + Wave-7c Issue #4 paragraph (lines 548-560). 70-line block total. Trim to 4 lines: "Wave-7e WE3 retired the per-tick morphContainer transform. Fill interpolates Theme.Cell.fill -> Theme.Chat.bottomTint as p ramps 0->1 (Issue #4 fix)."
- Lines 561-566: 6-line "lerp inline (no helper)" justification. Delete.
- Lines 578-585: 8-line W8-T2 mask narrative inside apply. Trim to 1.
- Lines 586-617: 32-line EMPTY-BUBBLE FIX block with progress-table comments (p=1.00, p=0.50, etc.). Trim to 6 lines: "Hide morphContainer while chatBody covers the rest slot. Bound to progress (not lifted flag) to avoid the settle-vs-tick race. Threshold 0.01 to defang floating-point dust around p=0."
- Lines 619-628: 10-line F-2 max-collapse narrative. Trim to 2: "F-2 collapse: chatBody alpha rides contentTransformAlpha (chatBodyAlpha was always ≤ p)."
- Lines 630-653: 24-line "removed per-tick constraint envelope" Arch-B narrative. Delete entirely or trim to 2 lines.
- Lines 662-672: 11-line WE3 clipsToBounds rationale. Trim to 2.
- Lines 677-681: 5-line chat-body re-route comment. Trim to 1.
- Lines 688-712: 25-line `instantiateChatBodyIfNeeded` Arch-B narrative + z-order paragraph. Trim to 5.
- Lines 715-742: 28 lines of constraint-building with mid-block Arch-B retirement narrative interspersed. Trim narrative; keep code. ~10 lines removable.
- Lines 753-788: 36-line `lift(chatBody:to:)` docstring (Arch-B, idempotency, constraint-handoff steps, gesture-recognizer R1 risk, why-not-transform-frame rationale). Trim to 6 lines: "Reparent chatBody into overlay host and pin fullscreen. Idempotent. Deactivates cellAnchored constraints, reparents, activates fresh overlay-pinned constraints. Recognizers survive (attached to chatBody itself)."
- Lines 799-822: 24-line inline numbered comments inside lift(). Keep the numbered structure, trim each block to 1 line.
- Lines 826-842: 17-line `lower(chatBody:to:)` docstring. Trim to 4.
- Lines 856-866: 11-line "race-window closure" historical narrative inside lower. Delete entirely — current code doesn't write morphContainer.alpha here.
- Lines 868-889: 22-line `liftBlur` docstring. Trim to 4.
- Lines 898-904: 7-line `lowerBlur` docstring. Trim to 2.
- Lines 913-933: 21-line "Layout regime" P8.T2 trailing comment block. Delete entirely — content is documented at the per-property level.
- Lines 935-989: 55-line `MorphContainerView` preamble (W8-T2 bug history, why-UIView-subclass, trade-off-carried-forward narrative). Trim to 8: "UIView subclass that hosts a CAShapeLayer mask rendering a rounded-rect bounded path. Renders rounded corners independent of clipsToBounds/masksToBounds, which the per-tick cornerRadius ramp needed during morph. Path refreshes on layoutSubviews (bounds-change) and on maskCornerRadius setter."
- Lines 994-1001: 8-line `maskCornerRadius` docstring. Trim to 3.
- Lines 1004-1024: 21 lines of CAShapeLayer init narrative (actions suppression, fillColor convention). Trim to 4.
- Lines 1037-1043: 7-line layoutSubviews rationale. Trim to 1.
- Lines 1049-1056: 8-line UIBezierPath-vs-squircle digression. Delete.

Approximate total comment-slim: ~410 lines removable. File would shrink from 1063 -> ~650 LOC.

### Hard deletes

None at the symbol level — every property and method is reachable from the V1 production graph or its test harness. Specifically:

- `lift`/`lower`/`liftBlur`/`lowerBlur` are called from `ActiveConversationCoordinator` (lines 122, 344 et al.) + `prepareForReuse` self-calls + `BlurReparentTests`.
- `MorphContainerView` is consumed only by line 71 in this same file, but that consumer is live in the V1 graph.

Whole-file deletion is the legitimate cleanup if the V1 path is purged — see Summary.

### Cross-ref warnings

- `MemoryTimeline.swift:170-198,461,488-490` constructs `ConversationCell` directly and uses `ConversationCell.reuseIdentifier`. Deleting this file forces MemoryTimeline deletion (which the A2 audit owns).
- `ActiveConversationCoordinator.swift` calls `cell.lift/lower/liftBlur/lowerBlur` and reads `cell.chatBodyView` + `cell.conversation`. Coordinator deletion in lock-step.
- 8 test files instantiate or type-match on `ConversationCell`: `TokenApplierTests`, `ChatBodyEagerInstantiationTests`, `MorphContainerRetirementTests`, `EmptyBubbleFixTests`, `AnchorSpringContinuityTests`, `ThemeCellFillTests`, `Wave7cSurvivabilityTests`, plus indirect refs via `Tests/Support/Fixtures.swift:46`.
- `TokenApplier.swift:17,26` references `cell.apply(tokens)` in docstrings + `tokenApplier.applyToCell` call site (call site verified live).
- `ConversationMorphTokens.swift` has 9 doc-comment refs to `ConversationCell` — stale on delete, but non-load-bearing.

---

## File: DotPinchPrototype/Conversation/Chrome/ListComposerView.swift

### Symbols

| Name | Kind | Line | Visibility | Tag | External refs |
|---|---|---|---|---|---|
| `ListComposerView` | class | 30 | internal | V1_ONLY | `ConversationComposer.swift:48`; `ConversationViewController.swift:118,272`; `TokenApplier` init param (composer wiring); 4 test files (`PinchGlyphPhaseTests:81`, `ConversationViewControllerSubviewOrderTests:59`, `BlurReparentTests:62`, `TapTargetTests:68`, `Wave7cSurvivabilityTests:131`) |
| `textField` | stored property | 34 | private | V1_ONLY | none external |
| `sendButton` | stored property | 35 | private | V1_ONLY | none external |
| `onSubmit` | stored closure | 48 | internal | V1_ONLY | `ConversationViewController` (closure wiring at viewDidLoad) |
| `init()` | initializer | 52 | internal | V1_ONLY | `ConversationComposer.swift:48` + test fixtures |
| `init?(coder:)` | initializer | 58 | required | V1_ONLY | UIKit-required |
| `configureAppearance()` | method | 62 | private | V1_ONLY | call-site `init` |
| `configureSubviews()` | method | 79 | private | V1_ONLY | call-site `init` |
| `configureTextField()` | method | 104 | private | V1_ONLY | call-site `configureSubviews` |
| `configureSendButton()` | method | 126 | private | V1_ONLY | call-site `configureSubviews` |
| `handleSendTap()` | objc method | 139 | private | V1_ONLY | UIControl target-action |
| `submitIfNonEmpty()` | method | 150 | private | V1_ONLY | internal |
| `intrinsicContentSize` | override | 171 | internal | V1_ONLY | UIKit layout |
| `textFieldShouldReturn(_:)` | UITextFieldDelegate | 185 | internal | V1_ONLY | UIKit delegate |

### Comment-slim (~50 lines removable)

- Lines 1-26: 26-line top-of-file narrative (CP2/CP13 wave-7b citations, vocabulary discipline). Trim to 5: "Bottom-of-screen 'Share with Dot…' composer. Idle-state root chrome — starts a new conversation. onSubmit fires after trim+clear+resign; the chat-state composer lives in ChatBodyView."
- Lines 39-47: 9-line `onSubmit` docstring with retain-cycle warning. Trim to 3: "Fires on submit (return key or send button). Text is trimmed + non-empty by the time this fires. textField clears and resigns BEFORE callback so morph engages with keyboard down."
- Lines 64-70: 7-line F-19 wave-7d Branch 8 narrative on backgroundColor. Trim to 1: "Transparent fill + hairline stroke (page-gradient is the sole backdrop)."
- Lines 88-101: keep — constraints are self-documenting but the 6-line math arithmetic comment (lines 94-96) on send button geometry is decorative; trim to 1 line.
- Lines 105-107: 3-line `attributedPlaceholder` lineage note. Delete.
- Lines 127-129: 3-line wave-7f H3 reference parity narrative. Trim to 1 line: "Audio waveform glyph (parity with ChatBodyView send button)."
- Lines 143-149: 7-line `submitIfNonEmpty` docstring with ordering rationale + ConversationViewController:67-86 citation. Trim to 3: "Trim, guard non-empty, clear, resign, fire callback. Keyboard down before callback so the chat-body morph's chatMask animation isn't fought by keyboard inset."
- Lines 159-170: 12-line intrinsicContentSize wave-5 hot-fix narrative (Maestro/screenshot review citation). Trim to 4: "Fixed height matches placeholder visual weight (~64pt). Without a bounded height the parent's pinned-to-self.top constraint left height ambiguous."
- Lines 180-184: 5-line `textFieldShouldReturn` docstring. Trim to 2.

Approximate total comment-slim: ~50 lines removable. File would shrink from 190 -> ~140 LOC.

### Hard deletes

None at the symbol level — every method is reachable within the V1 graph.

Whole-file deletion is the legitimate cleanup if the V1 path is purged — see Summary.

### Cross-ref warnings

- `ConversationComposer.swift:48` constructs `ListComposerView()` and passes it to both `TokenApplier(listComposerView:)` and `ConversationViewController(listComposerView:)`. Delete in lock-step with the composer.
- `TokenApplier`'s init signature accepts a `ListComposerView` — type deletion forces TokenApplier signature change.
- `ConversationViewController.swift:118,272,286,636` references — VC must be deleted in same purge wave.
- 5 test files instantiate `ListComposerView()` directly (PinchGlyphPhaseTests, ConversationViewControllerSubviewOrderTests, BlurReparentTests, TapTargetTests, Wave7cSurvivabilityTests). These tests reconstruct ConversationComposer.make()'s graph manually and would all need deletion.
- `AccessibilityID.composerPlaceholder`, `AccessibilityID.listComposerTextField`, `AccessibilityID.listComposerSendButton` consumed here only. If file goes, retire those constants too (A6 design-system audit owns AccessibilityID.swift).
- `DestinationContent.composerHint` referenced at line 109; check whether anyone else still reads it after this purge (likely V1_ONLY too).

---

## Summary

- **ORPHAN:** 0 individual symbols (within the V1 subgraph all symbols are referenced).
- **V1_ONLY:** ALL 3 files. The entire content of every file is reachable only through `ConversationComposer.make() -> ConversationViewController`, which is never called from `AppDelegate -> V2RootViewController`.
- **LIVE_REACHABLE (from V2):** 0 files, 0 symbols. V2 has zero source-level references to any of these three types.
- **TEST_ONLY:** All three files have their only non-V1-production callers in `/Tests/`. Once V1 production is deleted, every reference collapses to test-suite-only.
- **AMBIGUOUS:** 0.

### Whole-file deletes (recommended on V1 purge)

| File | Reason |
|---|---|
| `DotPinchPrototype/Conversation/Cells/CellSummaryView.swift` | V1_ONLY. Only production consumer is `ConversationCell` (also in this audit, also V1_ONLY). Tests in 5 files target it directly — delete tests in lock-step. |
| `DotPinchPrototype/Conversation/Cells/ConversationCell.swift` | V1_ONLY. Only production consumer is `MemoryTimeline` (V1) + `ActiveConversationCoordinator` (V1). Contains nested `MorphContainerView` which has no consumers outside this file. 8 tests target it — delete in lock-step. |
| `DotPinchPrototype/Conversation/Chrome/ListComposerView.swift` | V1_ONLY. Only production consumer is `ConversationComposer.make()` (V1) + `ConversationViewController` (V1). 5 tests target it — delete in lock-step. |

### LOC accounting (this audit's scope only)

- Hard-delete LOC if V1 purge proceeds: ~1394 LOC (141 + 1063 + 190).
- Comment-slim LOC if V1 retained: ~485 LOC removable across the three files (25 + 410 + 50).
- Net files unchanged: 0 — every file is either purged whole or comment-slimmed.

### Inter-audit dependencies

- **A2 (MemoryTimeline area)** must coordinate: `ConversationCell` deletion forces `MemoryTimeline.registerCells` + diffable-data-source code changes.
- **A4 (Coordinator / Animation)** must coordinate: `ActiveConversationCoordinator.lift/lower/liftBlur/lowerBlur/chatBodyView` call sites bind to `ConversationCell` methods.
- **A5 (ChatBody)** must coordinate: `ChatBodyView` is instantiated only inside `ConversationCell.instantiateChatBodyIfNeeded()`; if this cell is deleted, A5 should classify `ChatBodyView` as V1_ONLY too (no V2 consumer exists).
- **A6 (DesignSystem)** must coordinate: `AccessibilityID.conversationCell`, `AccessibilityID.composerPlaceholder`, `AccessibilityID.listComposerTextField`, `AccessibilityID.listComposerSendButton` lose their only consumers after this purge.
- **A7-A8 (Tests)** must coordinate: 8 distinct test files reference at least one of the three types. Cross-reference list (for purge sequencing):
  - `TokenApplierTests.swift` — refs CellSummaryView + ConversationCell
  - `ReactiveBindingsTests.swift` — instantiates CellSummaryView
  - `EmptyBubbleFixTests.swift` — refs CellSummaryView + ConversationCell
  - `ThemeCellFillTests.swift` — refs CellSummaryView + ConversationCell
  - `Wave7cSurvivabilityTests.swift` — refs CellSummaryView + ConversationCell + ListComposerView
  - `ChatBodyEagerInstantiationTests.swift` — refs ConversationCell
  - `MorphContainerRetirementTests.swift` — refs ConversationCell
  - `AnchorSpringContinuityTests.swift` — refs ConversationCell
  - `PinchGlyphPhaseTests.swift` — refs ListComposerView
  - `ConversationViewControllerSubviewOrderTests.swift` — refs ListComposerView
  - `BlurReparentTests.swift` — refs ListComposerView
  - `TapTargetTests.swift` — refs ListComposerView
  - `Tests/Support/Fixtures.swift` — refs ConversationCell

### Conservative-mode recommendation (V1 retained for reference)

If user opts to keep V1 dormant rather than purge: apply the comment-slim recs above (~485 LOC) and leave symbol structure intact. Estimated post-slim sizes: CellSummaryView ~115 LOC, ConversationCell ~650 LOC, ListComposerView ~140 LOC.

### Aggressive-mode recommendation (V1 purged)

Hard-delete all three files plus the cascade noted above. Net repo savings within this audit's scope: ~1394 LOC of production code plus the test-file cascade (~1500+ LOC if tests are deleted in lock-step). Sequence: tests first, then `ConversationCell` + `ListComposerView` + `CellSummaryView` together, then the upstream V1 graph (`MemoryTimeline`, `ConversationViewController`, `ActiveConversationCoordinator`, `TokenApplier`, `ConversationComposer`, `ChatBodyView`, `Conversation`-data-store-if-V2-doesn't-use-it).
