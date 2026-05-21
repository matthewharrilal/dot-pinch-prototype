# Audit A2 — Conversation/ChatBody/
ROLE: AUDIT-A2
SCOPE: ChatBody (ChatBodyView V1, ChatBubbleView live)

Reachability axiom: AppDelegate → V2RootViewController → TimelineCanvas → CellView, plus V2RootViewController → ChatViewController for chat-rest. V1 path (ConversationViewController) is only reachable via `ConversationComposer.make()`, which is itself an orphan (no callers in `DotPinchPrototype/App/` outside its own file). Therefore ALL ChatBodyView symbols are V1_ONLY (or TEST_ONLY downstream).

## File: DotPinchPrototype/Conversation/ChatBody/ChatBubbleView.swift

### Symbols
| Name | Kind | Line | Visibility | Tag | External refs |
|---|---|---|---|---|---|
| `ChatBubbleView` | final class : UIView | 14 | internal | LIVE_REACHABLE | V2: `ChatViewController.swift:119` (live); V1: `ChatBodyView.swift:760` |
| `init(message:)` | init | 18 | internal | LIVE_REACHABLE | same as class |
| `init?(coder:)` | required init | 64 | internal | LIVE_REACHABLE | fatalError stub — required by UIView |
| `displayName(for:)` | static func | 72 | private | LIVE_REACHABLE | self (line 24) |
| `timestampFormatter` | static let | 84 | private | LIVE_REACHABLE | self (line 41) |

### Comment-slim (~12 lines removable)
- Lines 2-10: top-of-file doc is 9 lines; slim to 3-4 lines. Drop "Tier 3B+", drop the docs/VOCABULARY.md cross-ref, drop the "user/assistant preserved at data layer" essay. Keep: "ChatBubbleView — renders one Message as a sender/body/timestamp row. Used by both V2 ChatViewController and V1 ChatBodyView."
- Line 35: `// live reflow during the morph` — V1-morph-specific; trivial in V2 context. Delete.
- Lines 68-71: 4-line docstring on `displayName(for:)` — explains "data layer keeps canonical user/assistant"; trivial. Slim to 1 line or delete.
- Lines 81-83: 3-line docstring on `timestampFormatter` — justifies caching. Slim to 1 line: `/// Cached — DateFormatter init is expensive.`

### Hard deletes
- None. Every method is reached from live V2 ChatViewController.

### Cross-ref warnings
- KEEP this file. ChatBubbleView is LIVE_REACHABLE via V2 path.
- If V1 (ChatBodyView) is deleted, the V1 ref at ChatBodyView.swift:760 disappears but V2 ref at ChatViewController.swift:119 remains — file still required.
- The `// live reflow during the morph` comment (line 35) refers to V1 morph behavior; if V1 is purged, comment becomes a lie. Already on the comment-slim list above.

---

## File: DotPinchPrototype/Conversation/ChatBody/ChatBodyView.swift

### Symbols
| Name | Kind | Line | Visibility | Tag | External refs |
|---|---|---|---|---|---|
| `ChatBodyView` | @MainActor final class : UIView | 26 | internal | V1_ONLY | `ConversationCell.swift` (101, 118, 685, 789, 843, 890, 905); Tests: `ComposerAnchorTests`, `ChatComposerResponderTests`, `BlurReparentTests`, `TokenApplierTests:580` |
| `contentRoot` | let UIView | 48 | private | V1_ONLY | self |
| `contentTransformLayer` | let UIView | 61 | private | V1_ONLY | self |
| `scrollView` | let UIScrollView | 62 | private | V1_ONLY | self |
| `contentView` | let UIStackView | 63 | private | V1_ONLY | self |
| `chatComposerTextField` | let UITextField | 90 | private | V1_ONLY | self; tests reach via AID lookup |
| `chatComposerSendButton` | let UIButton | 91 | private | V1_ONLY | self; tests via AID |
| `scrollViewTopConstraint` | var NSLayoutConstraint? | 100 | private | V1_ONLY | self |
| `chatComposerPill` | let UIView | 117 | private | V1_ONLY | self |
| `activeConversationID` | var UUID? | 123 | private | V1_ONLY | self |
| `onSendMessage` | var closure | 129 | internal | V1_ONLY | `ConversationCell.swift:191, 745` |
| `onDraftTextChanged` | var closure | 135 | internal | V1_ONLY | `ConversationCell.swift:194, 746` |
| `blurOverlay` | let UIVisualEffectView | 138 | private | V1_ONLY | self |
| `blurAnimator` | var UIViewPropertyAnimator? | 139 | private | V1_ONLY | self |
| `baselineOffsetY` | var CGFloat | 143 | private | V1_ONLY | self |
| `didCaptureBaseline` | var Bool | 144 | private | V1_ONLY | self |
| `conversation` | weak var Conversation? | 204 | private | V1_ONLY | self |
| `pastBubbleCount` | var Int | 208 | private | V1_ONLY | self |
| `init(frame:)` | override init | 218 | internal | V1_ONLY | `ConversationCell.swift:685`; tests |
| `init?(coder:)` | required init | 231 | internal | V1_ONLY | fatalError stub |
| `deinit` | deinit | 242 | — | V1_ONLY | self |
| `configureSelfAppearance` | func | 270 | private | V1_ONLY | self |
| `configureContentHierarchy` | func | 284 | private | V1_ONLY | self |
| `activateLayoutConstraints` | func | 321 | private | V1_ONLY | self |
| `configureChatComposer` | func | 488 | private | V1_ONLY | self |
| `installBlurOverlay` | func | 565 | private | V1_ONLY | self |
| `blurOverlayView` | computed var UIView | 608 | internal | V1_ONLY | no external refs found — DEAD (see warning) |
| `attachBlur(to:)` | func | 630 | internal | V1_ONLY | `ConversationCell.swift:895` |
| `detachBlurFromHost` | func | 654 | internal | V1_ONLY | `ConversationCell.swift:910` |
| `bind(to:)` | func | 688 | internal | V1_ONLY | `ConversationCell.swift:324, 748`; tests |
| `unbind` | func | 705 | internal | V1_ONLY | self |
| `renderMessages(_:)` | func | 743 | private | V1_ONLY | self |
| `layoutSubviews` | override func | 766 | internal | V1_ONLY | UIKit |
| `transcriptTopInset` | computed var CGFloat | 787 | private | V1_ONLY | self |
| `safeAreaInsetsDidChange` | override func | 794 | internal | V1_ONLY | UIKit |
| `captureBaselineOffsetIfNeeded` | func | 805 | private | V1_ONLY | self |
| `apply(_:)` | func | 839 | internal | V1_ONLY | `ConversationCell.swift` (via cell apply pipeline); tests |
| `recaptureBaseline` | func | 945 | internal | V1_ONLY | `ConversationCell.swift:105, 299, 659` |
| `installTapOutsideDismiss` | func | 972 | private | V1_ONLY | self |
| `handleTapOutsideComposer(_:)` | @objc func | 981 | private | V1_ONLY | gesture target |
| `effectiveAnchorPoint` | computed var CGPoint | 997 | private | V1_ONLY | self |
| `assertSimilarity(_:)` | #if DEBUG func | 1006 | private | V1_ONLY | self |
| `handleSendTap` | @objc func | 1015 | private | V1_ONLY | button target |
| `handleEditingChanged` | @objc func | 1023 | private | V1_ONLY | editingChanged target |
| `submitMessage` | func | 1066 | private | V1_ONLY | self + UITextFieldDelegate ext |
| `textFieldShouldReturn(_:)` | UITextFieldDelegate | 1080 | internal | V1_ONLY | UIKit |

### Comment-slim (~280 lines removable, if file is kept)
File is V1_ONLY → recommended HARD-DELETE in whole. If kept temporarily, the comment-density is extreme. Per-section accounting (rough — would need a re-pass to be exact):
- Lines 1-22: top docstring is 22 lines, references W2-G10/G2, retros, wave-2 carry-forward. Slim to 3-4 lines: "ChatBodyView (V1 only) — chat surface that renders a Conversation's transcript with similarity-scale morph + blur overlay." (~18 lines removable)
- Lines 30-46: two retired-layer epitaphs (`chatGradient`, `chatMask`) — 17 lines of historical pre-mortem. Delete entirely.
- Lines 49-60: 13-line docstring on `contentTransformLayer`. Slim to 2 lines.
- Lines 65-89: 25-line block-comment on chat-composer + two-constraint design. Slim to 4 lines; the detail belongs at the constraint site or in retros, not in field declarations.
- Lines 93-99: 7-line docstring on `scrollViewTopConstraint`. Slim to 2.
- Lines 102-116: 15-line docstring on `chatComposerPill`. Slim to 2-3.
- Lines 120-122, 126-128, 131-135: 14 lines of closure docstrings. Slim to 1 line each.
- Lines 137, 142, 146-197: 52-line keyboard-inset block comment with iOS 18 vs iOS 26.4 differential analysis, Explorer E-3/E-5 carry-forwards. Delete entirely.
- Lines 199-212: 14-line conversation-binding section incl. TODO(wave-7-composer). Slim to MARK + 1-2 lines.
- Lines 220-222: 3-line wave-7d F-16/F-20 comment at init. Delete.
- Lines 233-241, 244-258: 25 lines of deinit pre-mortem (Wave-7a hot-fix, Wave-7b W6-G6, Wave-7e WE2). Slim to 2-3 lines.
- Lines 263-268, 276-279: 11 lines of retired-layer epitaphs in setup. Delete.
- Lines 289-295: 7-line layered annotation in `configureContentHierarchy`. Slim to 1-2.
- Lines 298-300: 3-line "Start invisible" comment. Delete or slim to 1 line.
- Lines 322-376: 55-line block-comment inside `activateLayoutConstraints` (WE2 two-constraint design, iOS 18 vs iOS 26.4 again, "Why this reverses Phase 4"). Delete entirely — the doc-grade rationale belongs in retros.
- Lines 400-404: 5-line W8-T9 comment on contentTransformLayer pinning. Slim to 1.
- Lines 413-414: 2-line wave-7b W6-G6 anchor comment. Delete.
- Lines 449-460, 489-501: 12 + 13 = 25 lines on W8-COMPOSER-P1 pill chrome. Slim to 3-4.
- Lines 510-519: 10-line W8-COMPOSER-P2 placeholder unification commentary. Slim to 1.
- Lines 524-526: 3-line "Background stays clear" comment. Delete.
- Lines 537-540: 4-line wave-8 W8-T9 sibling comment. Delete.
- Lines 544-547: 4-line wave-7f H3 waveform note. Slim to 1.
- Lines 577-579: 3-line "Paused animator" comment. Slim to 1.
- Lines 588-607: 20-line wave-7d W5 (F-6) docstring on `blurOverlayView`. Slim to 1-2.
- Lines 610-629: 20-line docstring on `attachBlur(to:)`. Slim to 3-4.
- Lines 631-634: 4-line "Collect blurOverlay-anchored constraints" comment. Slim to 1.
- Lines 649-653: 5-line docstring on `detachBlurFromHost`. Slim to 1-2.
- Lines 672-687: 16-line bind(to:) docstring incl. TODO(wave-6) Observation rationale. Slim to 3.
- Lines 691-697, 702-710: 16 lines wave-7b W6-G6 commentary around bind/unbind. Slim to 4.
- Lines 727-742: 16-line renderMessages docstring incl. F-14 spacer rationale. Slim to 3.
- Lines 749-753: 5-line F-14 spacer in-method comment. Delete.
- Lines 768-770: 3-line "F-16 + F-20 retired" in layoutSubviews. Delete.
- Lines 774-786: 13-line transcriptTopInset docstring. Slim to 3-4 (the formula breakdown is non-trivial — keep the formula).
- Lines 796-798: 3-line safe-area comment. Slim to 1.
- Lines 825-828: 4-line "bounces=false hard-clamps" comment in `captureBaselineOffsetIfNeeded`. Keep (non-trivial, explains a load-bearing inset).
- Lines 837-838: 2-line apply docstring. Keep at 2.
- Lines 841-849, 853-860, 862-869, 871-891, 909-919, 922-925: ~60 lines of inline per-tick token rationale inside `apply(_:)`. The math itself is non-trivial (Branch 4 RCA, Branch 3 phantom-dot fix, F-12 lerp). Slim aggressively to 8-10 lines total — the why is in retros.
- Lines 933-944: 12-line recaptureBaseline docstring. Slim to 3.
- Lines 950-971: 22-line tap-outside block comment incl. listsite-symmetry rationale. Slim to 3-4.
- Lines 982-988: 7-line in-method comment in `handleTapOutsideComposer`. Slim to 2.
- Lines 1019-1022: 4-line per-char persistence docstring. Slim to 2.
- Lines 1030-1065: 36-line submitMessage docstring with INTENTIONAL ASYMMETRY essay. Slim to 4-5 (or keep at 8 — the asymmetry note IS load-bearing per the explicit DO NOT footer).
- Lines 1082-1086: 5-line return-key comment. Slim to 1-2.

Approximate slim total: ~280 lines of comment + whitespace removable if file is retained. If deleted, this is moot.

### Hard deletes
**Whole-file delete recommended: ChatBodyView.swift**

The entire file is V1_ONLY. Reachable only from:
- `ConversationCell.swift` (V1 cell — itself V1_ONLY; orphaned from AppDelegate)
- 4 test files that test V1 behavior (ComposerAnchorTests, ChatComposerResponderTests, BlurReparentTests, TokenApplierTests)

If V1 (`ConversationCell`, `ConversationViewController`, `ConversationComposer`, V1 tests) is purged, ChatBodyView is dead. Recommended: **delete this file** as part of the V1 purge. ~1089 LOC removed.

If file is kept (deferring V1 purge):
- `blurOverlayView` computed var (line 608): NO refs in `ConversationCell.swift` — cell uses `attachBlur(to:)` / `detachBlurFromHost()` directly, not the read-only accessor. The accessor was authored for a presumed lift API but the lift API ended up using `attachBlur(to:)` instead. **Dead even within V1.** Safe to delete (~21 LOC including 19-line docstring).

### Cross-ref warnings
- **`blurOverlayView` (line 608)** — defined but no external readers found. The wave-7d W5 docstring claims it's used by `ConversationCell.liftBlur(blur:to:)`, but `ConversationCell.swift:890+` calls `body.attachBlur(to:)` (line 895), not `body.blurOverlayView`. Dead accessor within V1.
- **File-deletion blast radius (V1 purge wave):** if ChatBodyView is deleted, the following must move together:
  - `ConversationCell.swift` (V1 cell — all chatBody refs)
  - 4 test files listed above
  - `AccessibilityID.chatComposerTextField` + `chatComposerSendButton` (lines 35-36) — V1-composer-only
  - `AccessibilityID.conversationSurface` (line 7) — used by `ChatBodyView.swift:281` only; verify
  - `ConversationMorphTokens.swift` fields consumed by `apply(_:)` (`similarityScale`, `contentTransformAlpha`, `blurFraction`, `chatComposerPillAlpha`, `chatBodyAlpha`) — verify other consumers before deleting
  - `PinchTuning.anchorPoint` (referenced at line 999) — verify other consumers
- **Comments referencing ChatBodyView in OTHER files** that would become stale if ChatBodyView is deleted:
  - `AccessibilityID.swift:32`
  - `MorphTiming.swift:183, 280`
  - `ConversationMorphTokens.swift:66, 122, 127, 159, 170, 205, 224, 298, 367, 581, 649`
  - `ConversationCell.swift:91, 97, 482, 539, 542, 693`
  - `ConversationViewController.swift:10, 48, 81, 86, 117, 620, 908`
  - `Conversation.swift:76`
  - `CellView.swift:161` (V2 — "Maestro/UITest selector parity with V1's ChatBodyView")
  - `ListComposerView.swift:7, 129`
  - These would all need a slim-pass when V1 is purged. `CellView.swift:161` is the only V2 reference (slim to remove V1 mention).
- **Bind-time draft restore (line 698):** `conversation.draftText` — verify the `draftText` property on `Conversation` is still required by V2 path before deleting; if only V1 consumes it, delete together.

---

## Summary
- ORPHAN: 1 (`blurOverlayView` accessor — dead even within V1) | V1_ONLY: 46 (all ChatBodyView symbols) | LIVE_REACHABLE: 5 (all ChatBubbleView symbols) | TEST_ONLY: 0 (all V1 test refs ride on V1_ONLY symbols) | AMBIGUOUS: 0
- Hard-delete LOC: ~1089 (whole-file ChatBodyView.swift) + ~21 if only the dead `blurOverlayView` accessor is removed in a deferred-purge scenario
- Comment-slim LOC: ~12 (ChatBubbleView) + ~280 (ChatBodyView, if retained)
- Whole-file deletes: `DotPinchPrototype/Conversation/ChatBody/ChatBodyView.swift` (V1_ONLY — delete with V1 purge); also recommend deleting `DotPinchPrototype/Conversation/ChatBody/README.md` (V1-only documentation, references retired `ConversationContentView`)
- Whole-file keeps: `DotPinchPrototype/Conversation/ChatBody/ChatBubbleView.swift` (LIVE_REACHABLE via V2 ChatViewController)
