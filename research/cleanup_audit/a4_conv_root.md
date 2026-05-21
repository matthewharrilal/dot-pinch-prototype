# Audit A4 — Conversation/ root files
ROLE: AUDIT-A4

Live entry: `AppDelegate.swift:23 → V2RootViewController()` (no `ConversationViewController` reference in V2 root or AppDelegate).
`ConversationViewController` is reachable from production only via `ConversationComposer.make()`, which has ZERO call sites in production (`grep -rn "ConversationComposer.make\|ConversationComposer()" DotPinchPrototype/` returns 0 prod hits). Tests still construct VC directly (PinchGlyphPhaseTests, TapTargetTests, BlurReparentTests, ConversationViewControllerSubviewOrderTests, Wave7cSurvivabilityTests, etc.). So this entire VC subtree is V1_ONLY; helpers grep'd only from inside ConversationViewController are V1_ONLY transitively.

---

## File: `/Users/spacewizardmoneygang/Desktop/XcodeInstall/dot-pinch-prototype/DotPinchPrototype/Conversation/ConversationViewController.swift`

(1216 LOC; ~67k bytes; absolute path)

### Symbols (with tags)

| Line | Symbol | Tag | Notes |
|------|--------|-----|-------|
| 56 | `ConversationViewController` (class) | V1_ONLY | V1 root; never instantiated by AppDelegate. Tests construct it directly. |
| 66 | `static dismissKeyboardTapName = "DismissKeyboardTap"` | V1_ONLY | Used only by `TapTargetTests.swift:108,126` (TEST_ONLY consumer) — V1 contract. |
| 75 | `preferredStatusBarStyle` (override) | V1_ONLY | UIViewController contract for V1 VC. |
| 112 | `memoryTimeline: MemoryTimeline` | V1_ONLY | Injected via init; lives only inside V1 VC. |
| 118 | `listComposerView: ListComposerView` | V1_ONLY | Same. |
| 122 | `statusLabel = UILabel()` | V1_ONLY + ORPHAN-PRESENTATION | `isHidden = true` debug surface, never enabled at runtime. |
| 133 | `pinchGlyph = UIImageView()` | V1_ONLY | Chrome glyph; wired in `installChrome()` / `applyPinchGlyphForPhase`. |
| 151 | `menuButton = UIImageView()` | V1_ONLY | Chrome glyph; tap handler intentionally empty (line 989). |
| 180 | `morphBlurHost = MorphBlurHost()` | V1_ONLY | Held strong; passed to coordinator via `attach(blurHost:)`. |
| 218 | `overlayContainer = PassthroughView()` | V1_ONLY | Strong; passed via `attach(overlay:)`. |
| 230 | `animationController: AnimationController` | V1_ONLY | DI. |
| 231 | `animator: SpringAnimator<PinchMorphState>` | V1_ONLY | DI. |
| 232 | `pinchInteraction: PinchToMemoryInteraction` | V1_ONLY | DI. |
| 240 | `store: ConversationStore` | V1_ONLY | DI. V2 has its own store init. |
| 247 | `coordinator: ActiveConversationCoordinator` | V1_ONLY | DI. |
| 251 | `fullscreenRect: CGRect` | V1_ONLY | Read only by `installInteractionIfNeeded` zero-guard. |
| 252 | `pageGradient: CAGradientLayer?` | V1_ONLY | Re-framed in `layOutGeometry`. |
| 253 | `didInstallInteraction: Bool` | V1_ONLY | Idempotence latch. |
| 262 | `pendingScrollEnableUpdate: Task<Void, Never>?` | V1_ONLY | Re-arm hop. |
| 266 | `init(...)` | V1_ONLY | 7-arg DI init. |
| 294 | `init?(coder:)` | V1_ONLY | Required boilerplate. |
| 308 | `deinit` | V1_ONLY | Cancels Task. |
| 316 | `viewDidLoad()` | V1_ONLY | Wires the V1 lifecycle. |
| 369 | `viewDidLayoutSubviews()` | V1_ONLY | Geometry + interaction install. |
| 378 | `installV2DebugEntryButton()` | V1_ONLY + DEBUG | `#if DEBUG`; presents `TimelineCanvasPreviewVC` (V2 debug harness). Reachable only when V1 root is live — under V2-root entry this never runs. |
| 397 | `presentTimelineCanvasPreview()` | V1_ONLY + DEBUG | Same. |
| 411 | `installPageGradient()` | V1_ONLY | Branch 8 / F-18 sRGB lock. |
| 472 | `installViewHierarchy()` | V1_ONLY | Composes V1 z-stack. |
| 525 | `installMorphBlurHost()` | V1_ONLY | Pins blur host. |
| 544 | `morphBlurHostView() -> UIView` | V1_ONLY + ORPHAN | Public accessor; ZERO call sites in prod or tests (grep returns 0 hits outside this file). The coordinator wires the host through `coordinator.attach(blurHost: morphBlurHost)` directly on line 340, never via this accessor. |
| 575 | `installOverlayContainer()` | V1_ONLY | Pins overlay host. |
| 594 | `chatBodyOverlayContainer() -> UIView` | V1_ONLY + ORPHAN | Public accessor; ZERO call sites outside this file (coordinator is wired via `attach(overlay:)` on line 334). |
| 602 | `installMemoryTimeline()` | V1_ONLY | |
| 622 | `installListComposer()` | V1_ONLY | |
| 662 | `installChrome()` | V1_ONLY | |
| 732 | `installStatusLabel()` | V1_ONLY | |
| 749 | `layOutGeometry()` | V1_ONLY | |
| 783 | `installInteractionIfNeeded()` | V1_ONLY | |
| 865 | `wireMemoryTimelineCallbacks()` | V1_ONLY | |
| 887 | `wireListComposerSubmit()` | V1_ONLY | |
| 921 | `installTapToDismissKeyboard()` | V1_ONLY | |
| 944 | `handleViewTap(_:)` | V1_ONLY | |
| 963 | `installPinchGlyphAction()` | V1_ONLY | |
| 973 | `handlePinchGlyphTap()` | V1_ONLY | |
| 983 | `installMenuButtonAction()` | V1_ONLY | |
| 988 | `handleMenuButtonTap()` | V1_ONLY + ORPHAN-BODY | Empty body — TODO(wave-7); never wires anything. |
| 1021 | `armMorphStateObservation()` | V1_ONLY | |
| 1044 | `applyMorphPhaseToTimeline()` | V1_ONLY | |
| 1090 | `applyPinchGlyphForPhase(_:)` | V1_ONLY | |
| 1158 | `extension … UIGestureRecognizerDelegate` | V1_ONLY | Issue #12 fix. |
| 1159 | `gestureRecognizer(_:shouldRecognizeSimultaneouslyWith:)` | V1_ONLY | |
| 1197 | `PassthroughView` (class) | V1_ONLY | Used only at line 218 inside this same file. |
| 1198 | `PassthroughView.point(inside:with:)` | V1_ONLY | |

### Comment-slim

The file is ~1216 LOC of which roughly 55-60% is wave-historical commentary. Per the comment-slim rules:

KEEP:
- Top-of-file docstring (lines 1-52) → COLLAPSE to ~4 lines: purpose + V1 status flag.
- `// MARK: -` markers (Recognizer registry, Status bar, Responder chain, Subviews, Dependencies, Layout state, Init, Lifecycle, View hierarchy setup, Geometry, Interaction, MemoryTimeline callback wiring, List-composer submission wiring, Keyboard dismissal, Chrome interaction, MorphState observation, Animator wiring, UIGestureRecognizerDelegate, Wave-7d Architecture B.a — PassthroughView).
- One docstring line for non-trivial methods (`installInteractionIfNeeded`, `armMorphStateObservation`, `applyPinchGlyphForPhase`, `installPageGradient`, the `PassthroughView` hit-test contract — these encode non-obvious load-bearing behavior).

DELETE (verbose wave/phase/RCA references):
- Lines 1-52 → collapse 51 lines of wave history to ~4 lines.
- Lines 60-66 verbose recognizer-registry rationale → 2 lines.
- Lines 70-74 status bar rationale → 1 line.
- Lines 77-105 entire responder-chain block (codified docs; not load-bearing for this file's compile) → delete; can live in docs/VOCABULARY.md.
- Lines 109-117 docstring on `memoryTimeline` (5 lines) → 1 line.
- Lines 117-118 docstring on `listComposerView` → 1 line.
- Lines 124-132 docstring on `pinchGlyph` (Issue #6 history) → 1 line.
- Lines 136-150 docstring + wave-7e-4 history on `menuButton` → 1 line.
- Lines 153-179 morphBlurHost rationale (~26 lines) → 1 line + xref to `MorphBlurHost.swift`.
- Lines 182-217 overlayContainer rationale (~36 lines of Branch 9 history) → 1 line + xref to `wave-7d-synthesis.md`.
- Lines 220-224 retired-chrome block-comment → delete entirely.
- Lines 256-262 `pendingScrollEnableUpdate` docstring → 1 line.
- Lines 278-289 init-body wave-6 topological-refactor narrative → delete.
- Lines 296-307 deinit Swift-6 isolation rationale → 1 line.
- Lines 329-358 viewDidLoad attach/wiring narrative (~30 lines of E-12 / wave-7d / wave-7e history) → 3 lines.
- Lines 376-378 `installV2DebugEntryButton` docstring → 1 line.
- Lines 405-410 docstring + S-3 resolution on `installPageGradient` → 1 line.
- Lines 413-449 F-18 Display-P3/sRGB Branch 8 hypothesis (~37 lines) → 3 lines explaining only "explicit sRGB lock for stop colors."
- Lines 464-471 `installViewHierarchy()` docstring → 2 lines.
- Lines 475-482 morphBlurHost-before-overlay z-order rationale → 1 line.
- Lines 487-497 F-10 z-order insurance narrative → 1 line.
- Lines 502-506 retired chrome block-comment → delete entirely.
- Lines 508-524 `installMorphBlurHost` docstring (~17 lines, duplicates `MorphBlurHost.swift`) → 1 line.
- Lines 540-543 `morphBlurHostView()` docstring → DELETE METHOD (orphan).
- Lines 548-574 `installOverlayContainer` docstring (~27 lines of Branch 9 rationale) → 1 line.
- Lines 590-593 `chatBodyOverlayContainer()` docstring → DELETE METHOD (orphan).
- Lines 599-614 `installMemoryTimeline()` comments → 2 lines.
- Lines 617-650 `installListComposer()` narrative (wave-7f C1, hit-test rationale, wave-7b keyboardLayoutGuide) → 4 lines.
- Lines 652-661 `installChrome()` docstring (Issue #6 history) → 2 lines.
- Lines 666-689 inline narrative inside installChrome → keep only what is structurally non-obvious (~5 lines).
- Lines 697-709 menuButton install-time alpha narrative → 1 line.
- Lines 718-727 wave-7e-4 centerY narrative → 1 line.
- Lines 752-760 `layOutGeometry()` F-17 narrative → 1 line.
- Lines 765-782 `installInteractionIfNeeded` docstring (~18 lines) → 3 lines.
- Lines 788-836 interior wave narrative inside installInteraction → 5 lines.
- Lines 855-864 `wireMemoryTimelineCallbacks()` docstring → 2 lines.
- Lines 873-886 `wireListComposerSubmit()` docstring → 2 lines.
- Lines 905-920 `installTapToDismissKeyboard()` docstring → 2 lines.
- Lines 923-940 narrative inside installTapToDismissKeyboard → 3 lines.
- Lines 951-962 `installPinchGlyphAction` docstring → 1 line.
- Lines 965-970 interior comment → 1 line.
- Lines 977-983 `installMenuButtonAction` docstring → 1 line.
- Lines 989-993 `handleMenuButtonTap` TODO block → DELETE method body comments; keep method as empty placeholder OR remove method entirely + retire menuButton tap install (see hard-deletes).
- Lines 996-1020 `armMorphStateObservation` docstring → 3 lines.
- Lines 1037-1067 `applyMorphPhaseToTimeline()` narrative → 3 lines.
- Lines 1069-1089 `applyPinchGlyphForPhase` docstring (~21 lines) → 4 lines.
- Lines 1100-1111 inline F-8 / wave-7d narrative → 1 line.
- Lines 1120-1125 accessibilityValue mirror rationale → 1 line.
- Lines 1128-1136 closing animator-wiring epitaph → DELETE entirely.
- Lines 1141-1157 UIGestureRecognizerDelegate Issue #12 docstring (~17 lines) → 3 lines.
- Lines 1163-1167 interior comment → 1 line.
- Lines 1171-1196 PassthroughView header (~26 lines) → 4 lines (hit-test contract docstring is non-trivial; keep summary form).
- Lines 1199-1208 interior of `point(inside:)` → 2 lines.

Estimated comment-slim LOC removal: ~520 LOC of comments out of ~1216 total file size → file shrinks to ~700 LOC.

### Hard deletes

| Line(s) | Symbol | Reason |
|---------|--------|--------|
| 502-506 | retired-chrome block-comment | Phantom doc (chatSafeAreaChrome already removed). |
| 220-224 | retired chatSafeAreaChrome block-comment | Same. |
| 540-546 | `morphBlurHostView() -> UIView` | ORPHAN public accessor; coordinator is wired via `attach(blurHost:)` on line 340 directly. ZERO non-self references. |
| 590-596 | `chatBodyOverlayContainer() -> UIView` | ORPHAN public accessor; coordinator wired via `attach(overlay:)` on line 334 directly. ZERO non-self references. |
| 983-993 | `installMenuButtonAction()` + `handleMenuButtonTap()` + recognizer in installChrome | Tap-recognizer is wired, handler body is empty TODO(wave-7) that never landed. If menu UX is deferred indefinitely, drop the install + handler; the static glyph remains. (Lower priority — keep if any test asserts the recognizer's presence; none found via grep.) |
| 122, 732-745 | `statusLabel: UILabel` + `installStatusLabel()` | Always `isHidden = true`; only `AccessibilityID.statusLabel` referenced. ORPHAN-PRESENTATION. Verify no Maestro flows depend on it before deleting (grep on `.maestro/` clean for `statusLabel`). |
| 1128-1136 | "MARK: - Animator wiring" + closing comment block | Wiring lives in coordinator; the MARK is for a section with no code body. |

Note on `installV2DebugEntryButton` (lines 376-402): debug-only V1→V2 bridge. Under live V2 entry it is structurally unreachable (V1 VC never instantiated → `#if DEBUG` block never runs). Recommend KEEPING — it's gated by `#if DEBUG` AND only runs when V1 VC is alive. Marking it for V1_ONLY hard-delete is safe IF V1 VC itself goes; if VC is retained for tests, keep this in case a debugger uses V1 path to reach V2 preview.

Hard-delete LOC estimate (orphan methods + statusLabel + dead doc-blocks, excluding comment-slim): ~50 LOC.

### Cross-ref warnings

- `dismissKeyboardTapName` (line 66) is referenced by `Tests/TapTargetTests.swift:108,126`. If VC is deleted, those tests must be retired too.
- `morphBlurHost`, `overlayContainer`, `pinchGlyph`, `menuButton` are passed by reference to `ActiveConversationCoordinator` via `attach(overlay:)`, `attach(blurHost:)`, `attachChrome(pinchGlyph:, menuButton:)`. If VC is retired wholesale (whole-file delete), the coordinator's `attach*` seams become structural orphans too (out of A4 scope).
- `PassthroughView` (line 1197) is referenced only by `overlayContainer = PassthroughView()` on line 218 of this same file. ORPHAN once the VC is deleted.
- `AccessibilityID.conversationOverlay` is used by `Tests/ConversationViewControllerSubviewOrderTests.swift:159` + `Tests/BlurReparentTests.swift:145`. Both are V1 test files.
- `AccessibilityID.morphBlurHost` ("MorphBlurHost") referenced only at this file's line 530. ORPHAN AID candidate if VC dies.
- `applyPinchGlyphForPhase` is tested by `Tests/PinchGlyphPhaseTests.swift` (TEST_ONLY consumer of phase-driven behavior).

---

## File: `/Users/spacewizardmoneygang/Desktop/XcodeInstall/dot-pinch-prototype/DotPinchPrototype/Conversation/ConversationMorphTokens.swift`

(745 LOC; ~45k bytes)

### Symbols (with tags)

| Line | Symbol | Tag | Notes |
|------|--------|-----|-------|
| 58 | `struct ConversationMorphTokens` | V1_ONLY | Consumed by `TokenApplier.swift:292`, `ConversationCell.swift:476`, `ChatBodyView.swift:839`, and tests. ALL of those consumers sit under the V1 VC tree (not used by V2/TimelineCanvas). Whole struct is V1_ONLY. |
| 97 | `let masterProgress: CGFloat` | V1_ONLY | |
| 113 | `let similarityScale: CGFloat` | V1_ONLY | |
| 118 | `let blurFraction: CGFloat` | V1_ONLY | |
| 188 | `let pinchGlyphAlpha: CGFloat` | V1_ONLY | |
| 201 | `let menuButtonAlpha: CGFloat` | V1_ONLY | |
| 228 | `let chatComposerPillAlpha: CGFloat` | V1_ONLY | |
| 243 | `let listComposerAlpha: CGFloat` | V1_ONLY + STRUCTURAL-DEAD | Always `= 0` per derivation line 652; consumer in TokenApplier writes `0` to listComposer.alpha every tick. Pure no-op stream; could be retired as a phantom field. |
| 289 | `let cellCornerRadius: CGFloat` | V1_ONLY | |
| 296 | `let summaryAlpha: CGFloat` | V1_ONLY | |
| 300 | `let chatBodyAlpha: CGFloat` | V1_ONLY + LEGACY | Comment line 80-81 marks this as vestigial — consumer collapsed to `contentTransformAlpha` in ConversationCell:645. Verify field is no longer read; if so, retire. |
| 317 | `let contentTransformAlpha: CGFloat` | V1_ONLY | |
| 394 | `let nonActiveCellAlpha: CGFloat` | V1_ONLY | |
| 441 | `let pinchAnchor: CGPoint?` | V1_ONLY | |
| 473 | `init(state: anchorFrame: fullscreenHeight: fullscreenWidth: pinchAnchor:)` | V1_ONLY | |

### Comment-slim

This file is ~745 LOC and roughly 80%+ comments. The DAG history, polarity-hazard prose, wave-7d/7e retirement census, F-21/F-23/F-13/F-8/F-9 cross-references, and W8-T3/W8-T9 sub-history are all wave-archaeology that no longer drives any decision at this file's surface.

KEEP:
- One top-of-file docstring (~4 lines): purpose + V1 status + pointer to `retros/wave-7e-token-dag.md` for the formal DAG.
- One docstring per field (1 line: "what this drives").
- `// MARK:` markers (Canonical source, Geometry, Chat surface, Destination, Chrome, Wave-6 token extensions, Derivation).
- Method-level docstring on `init` (parameter list + pure-function contract — 4-6 lines).
- The polarity-hazard NOTE on `chatComposerPillAlpha` derivation in `init` (4 lines) — load-bearing rewrite-guard.

DELETE:
- Lines 1-12 dual-paragraph wave-6 extension narrative → fold into top docstring.
- Lines 14-54 entire WE0-PRE / DAG / polarity / coupling-invariants block (~41 lines) → 4 lines + pointer.
- Lines 60-87 DEPENDENCY DAG ASCII art (~28 lines) → DELETE; lives in `retros/wave-7e-token-dag.md`.
- Lines 99-112 verbose `similarityScale` polarity narrative → 2 lines.
- Lines 120-128 retired chatTopAlpha/chatBottomAlpha block → DELETE.
- Lines 130-145 retired destinationCardAlpha/destinationLabelAlpha block → DELETE.
- Lines 147-163 retired pinch-affordance + composerAlpha narrative → DELETE.
- Lines 164-170 Wave-7d W3 worker-dispatch contract block → DELETE.
- Lines 172-227 chrome alpha-field docstrings (each is 12-15 lines of wave history) → 2 lines each, ~6 lines total.
- Lines 230-233 retired chatSafeAreaChromeAlpha block → DELETE.
- Lines 245-250 Wave-6 token extensions header narrative → DELETE.
- Lines 252-284 retired cellScale block (~33 lines) → DELETE.
- Lines 292-295 summaryAlpha E-10 docstring → 1 line.
- Lines 298-300 chatBodyAlpha docstring → 1 line (mark vestigial if retired).
- Lines 302-317 contentTransformAlpha W8-T9 narrative → 2 lines.
- Lines 319-330 retired cellTranslationY block → DELETE.
- Lines 332-376 Arch-B.a retired chatBodyHeight/Width/TopOffset block (~45 lines) → DELETE.
- Lines 378-393 nonActiveCellAlpha Issue #11 RCA narrative → 2 lines.
- Lines 396-440 pinchAnchor W8-T3 narrative (~45 lines) → 4 lines.
- Lines 443-472 init docstring → 8 lines (param list + pure-function contract).
- Lines 480-516 inside init: clamp/baseline/polarity-inversion narrative → 4 lines.
- Lines 517-571 blurFraction derivation block (~55 lines of W3/W8-T9/Branch 10 history) → 4 lines + pointer to `retros/rca-wave-7d-branch-10-text-reappearance-timing.md`.
- Lines 577-590 retired chatTopAlpha + destinationCardAlpha derivation blocks → DELETE.
- Lines 592-602 chrome derivation narrative → 2 lines.
- Lines 605-606 menuButtonAlpha mirror comment → 1 line.
- Lines 609-638 chatComposerPillAlpha polarity-derivation block → KEEP the 4-line load-bearing guard; delete the rest (~26 lines retired).
- Lines 641-643 chatSafeAreaChromeAlpha retirement → DELETE.
- Lines 645-651 wave-7f C1 reference parity narrative → 2 lines.
- Lines 654-658 cellScale derivation retirement → DELETE.
- Lines 663-675 staggered-crossfade wave-7c history → 2 lines.
- Lines 679-693 W8-T9 long-form derivation narrative → 2 lines (keep the `scaleRange` defensive guard explanation).
- Lines 695-715 retired cellTranslationY + Arch-B.a constraint envelope narrative → DELETE.
- Lines 717-732 nonActiveCellAlpha Issue #11 narrative → 2 lines.
- Lines 735-742 pinchAnchor W8-T3 narrative → 2 lines.

Estimated comment-slim LOC removal: ~480 LOC of comments out of ~745 → file shrinks to ~260 LOC.

### Hard deletes

| Line(s) | Symbol | Reason |
|---------|--------|--------|
| 243 + 652 | `listComposerAlpha` field + `= 0` derivation | STRUCTURAL-DEAD stream (always 0). The view stays in the tree but its alpha is install-time pinned to 0 (`ConversationViewController.swift:631`). The token field is a no-op carrier — TokenApplier writes 0 every tick. Either delete the field (and the TokenApplier write) OR keep the field and document the no-op intentionally. Conservative: keep field, eliminate ALL the policy comments. Aggressive: delete field + applier write + remove `MorphTiming.listComposerFadeInStart/End` (currently both ORPHAN — see below). |
| 300 | `chatBodyAlpha` field | Comment at line 80-81 explicitly tags this as vestigial; consumer collapsed to `contentTransformAlpha`. Verify via grep across all `apply()` seams; if no live read, delete the field + the derivation line 677. |
| Whole file? | — | NOT a whole-file candidate. Even at slimmed ~260 LOC the struct is consumed by V1's TokenApplier + ConversationCell + ChatBodyView. Delete only if those go (out of A4 scope). |

Hard-delete LOC estimate (field + derivation if `chatBodyAlpha` and `listComposerAlpha` retire): ~4 LOC of structural code, plus the comment retirement above.

### Cross-ref warnings

- `ConversationMorphTokens(state:anchorFrame:fullscreenHeight:fullscreenWidth:pinchAnchor:)` consumed by:
  - `Conversation/Morph/TokenApplier.swift:292` (prod consumer, V1_ONLY)
  - `Tests/ConversationMorphTokensTests.swift` (TEST_ONLY, many sites)
  - `Tests/StateMachineCompletenessTests.swift:44`
  - `Tests/TokenApplierTests.swift:345`
- Field surfaces (`pinchGlyphAlpha`, `menuButtonAlpha`, etc.) are read by `TokenApplier.apply` + `ChatBodyView.apply` + `ConversationCell.apply` — all V1_ONLY consumers.
- `testRetiredMorphTimingConstantsAreGone` (Tests/ConversationMorphTokensTests.swift:716) is a negative-existence guard that greps `MorphTiming.swift` source for retired constant NAMES. Adding new fields/constants must not collide with the retired-name list.

---

## File: `/Users/spacewizardmoneygang/Desktop/XcodeInstall/dot-pinch-prototype/DotPinchPrototype/Conversation/MorphBlurHost.swift`

(90 LOC; ~5.4k bytes)

### Symbols (with tags)

| Line | Symbol | Tag | Notes |
|------|--------|-----|-------|
| 81 | `final class MorphBlurHost: UIView` | V1_ONLY | Instantiated only at `ConversationViewController.swift:180` (`morphBlurHost = MorphBlurHost()`). ZERO references outside V1 VC. The class has no overrides (empty body). Could be replaced by `UIView()` at the V1 install site — the "documentation by class name" rationale at line 74-78 is the only justification for its existence. |

No methods, no stored properties beyond inheritance.

### Comment-slim

KEEP:
- 3-4 line top-of-file docstring.
- The doc-comment on the class declaration (one line; trim the rationale-by-grep paragraph to a single sentence).

DELETE:
- Lines 1-59 entire header block (~60 lines of wave-7d W5 / F-6 / Branch 4 / Branch 11 narrative + ASCII z-stack diagram + pre/post-W5 archaeology). The z-stack invariant is already codified in `ConversationViewController.installViewHierarchy` (per the class-level pointer); duplicating it in this file's header is doc-mass churn. → 4 lines.
- Lines 63-79 class docstring (~17 lines of "why a UIView subclass" rationale) → 2 lines.
- Lines 82-89 interior empty-body comment (~8 lines about default hit-test) → DELETE entirely; the class is empty.

Estimated comment-slim LOC removal: ~80 LOC out of 90 → file shrinks to ~10 LOC.

### Hard deletes

| Line(s) | Symbol | Reason |
|---------|--------|--------|
| Whole file | `MorphBlurHost` | CANDIDATE for whole-file deletion if you're willing to swap `morphBlurHost = MorphBlurHost()` → `morphBlurHost = UIView()` at `ConversationViewController.swift:180` and rename the stored property's type. The class has zero behavior; its only "feature" is the type name. The accessibilityIdentifier (`AccessibilityID.morphBlurHost`) and the install-site rationale are independent of the subclass identity. RECOMMENDED if doing aggressive cleanup — saves ~90 LOC + one Swift type. NOT recommended if the type name is referenced in any Maestro flow or runtime introspection (grep on `.maestro/` shows zero hits for "MorphBlurHost"). |

If NOT doing the whole-file delete, the file shrinks to ~10 LOC via comment-slim.

### Cross-ref warnings

- `MorphBlurHost` declared once at this file; instantiated once at `ConversationViewController.swift:180`. ZERO test references. ZERO Maestro references.
- The type is passed as `UIView` through `coordinator.attach(blurHost:)` so consumers already work against the UIView abstraction — subclass identity is not load-bearing for any consumer.

---

## File: `/Users/spacewizardmoneygang/Desktop/XcodeInstall/dot-pinch-prototype/DotPinchPrototype/Conversation/MorphTiming.swift`

(336 LOC; ~19k bytes)

### Symbols (with tags)

| Line | Symbol | Tag | Notes |
|------|--------|-----|-------|
| 8 | `enum MorphTiming` | V1_ONLY | Namespace consumed only by `ConversationMorphTokens.swift` (V1_ONLY parent). |
| 105 | `static let summaryFadeOutEnd: CGFloat = 0.10` | V1_ONLY | Used at `ConversationMorphTokens.swift:676`. LIVE within V1 subtree. |
| 109 | `static let chatBodyFadeInStart: CGFloat = 0.55` | V1_ONLY | Used at `ConversationMorphTokens.swift:677`. LIVE within V1 subtree. |
| 120 | `static let composerFadeStart: CGFloat = 0.40` | ORPHAN | grep returns ZERO production consumers and ZERO test consumers in Swift code. Only echoed in `FRAME-CORRELATION-FINDINGS.md`, `MASTER-CHECKLIST.json`, and a doc-comment at `TokenApplier.swift:307` (in a phantom-narrative comment, not active code). Phantom constant per W7C-G30 anti-pattern. HARD-DELETE. |
| 123 | `static let composerFadeEnd: CGFloat = 0.65` | ORPHAN | Same as above. HARD-DELETE. |
| 171 | `static let listComposerFadeInStart: CGFloat = 0.0` | ORPHAN-IN-PROD / TEST-DOC-ONLY | ZERO production consumers (the derivation `listComposerAlpha = 0` at `ConversationMorphTokens.swift:652` hardcodes the value and no longer uses the ramp endpoints). Referenced only in doc-comments and the W7C-G34 narrative. HARD-DELETE candidate. |
| 176 | `static let listComposerFadeInEnd: CGFloat = 0.05` | ORPHAN-IN-PROD / TEST-ONLY | ZERO production consumers; ONE test consumer at `Tests/ConversationMorphTokensTests.swift:575` (`PinchMorphState(progress: MorphTiming.listComposerFadeInEnd)`) which exists only to verify `listComposerAlpha == 0` at this progress sample — a tautological test now that the derivation is `= 0` everywhere. The test can be deleted along with the constant. |
| 315 | `static let iOS26BlurStrengthCompensation: CGFloat = 0` | ORPHAN | ZERO production consumers and ZERO test consumers. Documented at length as a "deferred knob" with an acceptance criterion that was never met. Phantom constant. HARD-DELETE. |

### Comment-slim

The entire file is ~336 LOC of which ~325 LOC is wave-archaeology comments documenting retired constants (cardEmerge*, labelEmerge*, completionEpsilon, chatDissolve*, dissolveBottomFadeFraction, dissolveTopFadeOffset, affordanceMaterializesAt, illegibilityRampStart/Complete, blurReleaseStart/End). Per W7C-G30 (phantom-retention-by-test anti-pattern), the file currently behaves like a graveyard inscription wall.

KEEP:
- 3-4 line top-of-file docstring.
- One-line docstring on each live constant.
- `// MARK:` markers for the two LIVE sections (Crossfade stagger, the survived window).

DELETE:
- Lines 1-5 docstring → 2 lines.
- Lines 10-53 "Blur curve" retirement block (44 lines) → DELETE entirely.
- Lines 55-97 "Crossfade stagger" wave-7c history (43 lines) → 4 lines.
- Lines 99-104 docstring on `summaryFadeOutEnd` → 1 line.
- Lines 107-108 docstring on `chatBodyFadeInStart` → 1 line.
- Lines 111-117 "Composer fade" header block → DELETE (the constants below it are ORPHAN).
- Lines 119-123 `composerFadeStart` + `composerFadeEnd` → DELETE constants + their docstrings.
- Lines 125-166 "List-composer fade-in" Issue #7 narrative (42 lines) → DELETE if constants below are retired.
- Lines 168-176 `listComposerFadeInStart` + `listComposerFadeInEnd` → DELETE if test can be retired.
- Lines 178-192 "Chat-surface dissolve" RETIRED block → DELETE.
- Lines 194-226 "Destination emergence" RETIRED block → DELETE.
- Lines 228-238 "Affordance materialization" RETIRED block → DELETE.
- Lines 240-313 "Wave-7d F-7 / iOS 26.4 blur retune" deferred narrative (74 lines) → DELETE alongside the constant.
- Lines 304-315 `iOS26BlurStrengthCompensation` constant + docstring → DELETE.
- Lines 317-334 "Completion threshold RETIRED" block → DELETE.

After all retirements (composerFade*, listComposerFadeIn*, iOS26BlurStrengthCompensation) + retirement-narrative deletion, file shrinks from ~336 LOC to ~15 LOC.

### Hard deletes

| Line(s) | Symbol | Reason |
|---------|--------|--------|
| 119-123 | `composerFadeStart`, `composerFadeEnd` | ZERO production OR test consumers. Phantom constants. |
| 168-176 | `listComposerFadeInStart`, `listComposerFadeInEnd` | ZERO production consumers; one tautological TEST consumer (`testListComposerAlphaAtFadeInEndIsZero` at `Tests/ConversationMorphTokensTests.swift:573-581`). Retire constants + retire the test (the assertion `listComposerAlpha == 0 at p=0.05` is tautological now that `listComposerAlpha = 0` for all p). |
| 304-315 | `iOS26BlurStrengthCompensation` | ZERO consumers. The "acceptance criterion for raising above 0" infrastructure was never built. Phantom-knob anti-pattern. |
| 10-53, 178-192, 194-226, 228-238, 240-303, 317-334 | All "RETIRED" narrative blocks | These document constants that are ALREADY GONE. The negative-existence guard test (`testRetiredMorphTimingConstantsAreGone` at `Tests/ConversationMorphTokensTests.swift:716`) is the structural guarantee; the narrative blocks here are redundant doc-mass. |

Hard-delete LOC estimate: ~5 LOC of structural code (3 constants retire) + ~300 LOC of retirement-narrative comments → file at ~15 LOC after slim.

### Cross-ref warnings

- `MorphTiming.summaryFadeOutEnd` referenced at `ConversationMorphTokens.swift:676` + `Tests/ConversationMorphTokensTests.swift:333` (in error string, not value read).
- `MorphTiming.chatBodyFadeInStart` referenced at `ConversationMorphTokens.swift:677`. Used in comment at `ConversationCell.swift:83`.
- `MorphTiming.listComposerFadeInEnd` referenced ONLY at `Tests/ConversationMorphTokensTests.swift:575`. The test reads the constant to drive a tautological assertion. Both constant and test can retire together.
- `testRetiredMorphTimingConstantsAreGone` at `Tests/ConversationMorphTokensTests.swift:716` greps THIS file for retired constant names. The retired-name list there should be extended with `composerFadeStart`, `composerFadeEnd`, `iOS26BlurStrengthCompensation`, `listComposerFadeInStart`, `listComposerFadeInEnd` after this round of retirements lands.

---

## Summary

- ORPHAN: 7 (within these files)
  - `ConversationViewController.morphBlurHostView()`, `ConversationViewController.chatBodyOverlayContainer()`, `ConversationViewController.statusLabel + installStatusLabel()`, `ConversationViewController.handleMenuButtonTap()` body, `MorphTiming.composerFadeStart`, `MorphTiming.composerFadeEnd`, `MorphTiming.iOS26BlurStrengthCompensation`
- V1_ONLY: every other live symbol across all 4 files (the entire ConversationViewController, all of ConversationMorphTokens, MorphBlurHost, and the live MorphTiming constants). Reachable only from V1's VC subtree; not used by V2/V2RootViewController/TimelineCanvas.
- LIVE_REACHABLE (from V2 root): 0
- TEST_ONLY: 2 (`MorphTiming.listComposerFadeInStart`, `MorphTiming.listComposerFadeInEnd` — only test consumer is tautological and retirable)
- AMBIGUOUS: 2 (`ConversationMorphTokens.chatBodyAlpha` field — marked vestigial in its own docstring; `ConversationMorphTokens.listComposerAlpha` field — always 0)

- Hard-delete LOC: ~60 LOC structural (orphan methods + statusLabel + 3 phantom constants + 2 retirable constants + retire one tautological test + optionally `MorphBlurHost` whole-file → +90 LOC).
- Comment-slim LOC: ~1380 LOC across the four files (~520 in VC, ~480 in tokens, ~80 in MorphBlurHost, ~300 in MorphTiming retirement blocks).
- Whole-file deletes:
  - `MorphBlurHost.swift` — CANDIDATE (recommended if you accept replacing the type with `UIView` at the VC install site; saves ~90 LOC + one Swift type).
  - `ConversationViewController.swift` — CANDIDATE only if the entire V1 subtree retires (out of A4 scope; requires retiring `ConversationComposer.make()`, the coordinator's `attach*` seams, MemoryTimeline, ListComposerView, ConversationCell, ChatBodyView, TokenApplier, MorphTiming, ConversationMorphTokens, the V1 test files, and the `installV2DebugEntryButton` bridge).
  - `MorphTiming.swift` — NOT a whole-file delete (2 constants are LIVE within the V1 subtree); slim to ~15 LOC.
  - `ConversationMorphTokens.swift` — NOT a whole-file delete; slim to ~260 LOC.

Cross-file cleanup hint (out of A4 scope but flagged): if `composerFadeStart`, `composerFadeEnd`, `iOS26BlurStrengthCompensation`, `listComposerFadeInStart/End` retire, also update `Tests/ConversationMorphTokensTests.swift:716` (testRetiredMorphTimingConstantsAreGone) to add those names to the negative-existence list, and retire `testListComposerAlphaAtFadeInEndIsZero` (~Tests/ConversationMorphTokensTests.swift:573-581). Also update doc-comment at `Conversation/Morph/TokenApplier.swift:307` which references `composerFadeStart/composerFadeEnd` in narrative.
