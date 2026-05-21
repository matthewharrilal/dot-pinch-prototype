# Audit A1 — Conversation/V2/ + App/
ROLE: AUDIT-A1
SCOPE: V2 live core

## Reachability summary

Live entry: `App/AppDelegate.swift:23` instantiates `V2RootViewController()`
→ `TimelineCanvas`, `TimelineDataSourceAdapter`, `ConversationStore`,
`DummyConversationLoader`, `ChatViewController`. Canvas wires
`CameraAnimator`, `SpringAnimator<CGFloat>` (extension + an unused master),
pan + pinch recognizers, and a pool of `CellView`.

`ConversationComposer.make()` constructs `ConversationViewController` (V1
root) and is **not referenced** by AppDelegate. Only Tests/* fixtures and
doc comments reference it ⇒ entire file is V1_ONLY and deletable once V1
tests retire.

---

## File: DotPinchPrototype/App/AppDelegate.swift

### Symbols
| Name | Kind | Line | Vis | Tag | External refs |
|------|------|------|-----|-----|---------------|
| AppDelegate | class @main | 4 | internal | LIVE_REACHABLE | system |
| window | property | 6 | internal | LIVE_REACHABLE | self |
| application(_:didFinishLaunchingWithOptions:) | method | 8 | internal | LIVE_REACHABLE | system |

### Comment-slim (~8 lines removable)
- L13-16: 4-line "pre-empt launch-screen flash" → compress to 1.
- L18-22: 5-line "Wave I5 — V2RootViewController hosts TimelineCanvas..."
  wave-narrative block — DELETE.

### Hard deletes
- None. Live entry point.

### Cross-ref warnings
- None.

---

## File: DotPinchPrototype/App/V2RootViewController.swift

### Symbols
| Name | Kind | Line | Vis | Tag | External refs |
|------|------|------|-----|-----|---------------|
| V2RootViewController | class | 25 | internal final @MainActor | LIVE_REACHABLE | AppDelegate.swift:23 |
| store / adapter / timelineCanvas / activeChatVC / revealBlurOverlay | properties | 27-31 | private | LIVE_REACHABLE | self |
| init() | init | 35 | internal | LIVE_REACHABLE | AppDelegate |
| init?(coder:) | required unavailable | 47 | — | LIVE_REACHABLE | NSCoder boilerplate |
| loadView() | override | 53 | internal | LIVE_REACHABLE | UIKit |
| viewDidLoad() | override | 61 | internal | LIVE_REACHABLE | UIKit |
| handleTap(_:) | @objc | 99 | private | LIVE_REACHABLE | selector |
| revealChat(forCellAt:) | method | 107 | private | LIVE_REACHABLE | viewDidLoad closure |

### Comment-slim (~35-40 lines removable)
- L1-20: Wave I5 / I3/I4/I6/I7/I8 narrative + ConversationViewController
  reference. KEEP 3-line class purpose; DELETE the rest.
- L13-15 launch-flash comment in loadView: compress to 1.
- L66-73: 8-line geometric setup essay → 2 lines.
- L81-83 + L86-89: "Adapter must outlive…" + "Tap-to-chat: tap on a cell…"
  wave-narrative — DELETE.

### Hard deletes
- None — all methods live.

### Cross-ref warnings
- None.

---

## File: DotPinchPrototype/App/ConversationComposer.swift

### Symbols
| Name | Kind | Line | Vis | Tag | External refs |
|------|------|------|-----|-----|---------------|
| ConversationComposer | enum @MainActor | 10 | internal | V1_ONLY | Tests/* + doc comments |
| make() | static | 14 | internal | V1_ONLY | Tests fixtures (builds ConversationViewController) |
| makeStore() | static | 82 | internal | V1_ONLY | self + Tests/Support/Fixtures.swift |

### Hard deletes
- **DELETE ENTIRE FILE** (lines 1-86). Wires V1-only symbols (Animation
  Controller, Spring, SpringAnimator<PinchMorphState>,
  PinchToMemoryInteraction, MemoryTimeline, SpatialAnchorResolver,
  ListComposerView, TokenApplier, ActiveConversationCoordinator,
  ConversationViewController).
- Remove pbxproj entries (lines 40, 223, 240, 622).

### Cross-ref warnings
- WARN: Conversation/ (other agent): `ConversationViewController` init
  signature is orphaned after Composer dies.
- WARN: Tests/ (other agent): PinchGlyphPhaseTests:32+57, TapTargetTests:46,
  MemoryTimelineTests:197, Support/Fixtures.swift:90 all use Composer.
- WARN: docs (README.md:32, MASTER-CHECKLIST.json) name Composer as the
  composition root — update or accept stale.

---

## File: DotPinchPrototype/Conversation/V2/Camera.swift

### Symbols
| Name | Kind | Line | Vis | Tag | External refs |
|------|------|------|-----|-----|---------------|
| Camera | struct Equatable | 23 | internal | LIVE_REACHABLE | TimelineCanvas, CameraAnimator, tests |
| translation | property | 27 | internal | LIVE_REACHABLE | many |
| init(translation:) | init | 29 | internal | LIVE_REACHABLE | many |
| validate(translation:) | static | 37 | internal | LIVE_REACHABLE | TimelineCanvas:603 |
| identity | static let | 43 | internal | LIVE_REACHABLE | TimelineCanvas:56 |
| isApproximatelyEqual(_:tolerance:) | method | 48 | internal | LIVE_REACHABLE | CameraAnimator:166 |

### Comment-slim (~15 lines removable)
- L1-18: 18-line wave-narrative top of file → 4-line docstring.
- L34-36 validate doc → 1 line.

### Hard deletes
- None.

### Cross-ref warnings
- None.

---

## File: DotPinchPrototype/Conversation/V2/CameraAnimator.swift

### Symbols
| Name | Kind | Line | Vis | Tag | External refs |
|------|------|------|-----|-----|---------------|
| CameraVelocity | struct | 19 | public | LIVE_REACHABLE | TimelineCanvas, Tests/V2/WaveR12 |
| CameraVelocity members (translationVelocity, .zero, init) | — | 20-26 | public | LIVE_REACHABLE | many |
| CameraAnimator | class @MainActor | 33 | internal final | LIVE_REACHABLE | TimelineCanvas |
| velocityFloor | static let | 40 | internal | LIVE_REACHABLE | self |
| canvas (weak), translationAnimator, pendingCompletion, outerCompletionFired, stoppedByCaller | properties | 44-51 | private | LIVE_REACHABLE | self |
| init(canvas:controller:spring:) | init | 55 | internal | LIVE_REACHABLE | TimelineCanvas:313 |
| wireValueChangedAndCompletion() | method | 72 | private | LIVE_REACHABLE | self |
| isRunning | computed | 85 | internal | LIVE_REACHABLE | tests |
| animationControllerIdentity | computed | 92 | internal | TEST_ONLY | WaveR41 |
| **translationVelocityForTesting** | computed | 104 | internal | AMBIGUOUS | no current grep readers |
| lastAnimateVelocityForTesting | property | 113 | internal private(set) | TEST_ONLY | WaveR43 |
| animate(to:velocity:spring:completion:) | method | 125 | internal | LIVE_REACHABLE | TimelineCanvas x3 |
| dampingRatioForTesting / responseForTesting | computed | 183 / 189 | internal | TEST_ONLY | WaveR44 |
| stop(immediately:) | method | 195 | internal | LIVE_REACHABLE | TimelineCanvas |
| writeCameraFromInnerValue() | method | 204 | private | LIVE_REACHABLE | self |
| tryFireOuterCompletion() | method | 212 | private | LIVE_REACHABLE | self |

### Comment-slim (~50 lines removable)
- L1-11 wave-narrative → 3-line docstring.
- L19-31: drop "Pre-Wave-4a logScaleVelocity is retired"; trim "API surface
  preserved from Wave 3".
- L88-94, L96-103, L108-113, L181-191: testing-accessor doc blocks → 1-line
  each.
- L115-148 animate() doc + inline R4.4 § comments → 6 lines.
- L157-160 R4.3 testing hook comment → 1 line.

### Hard deletes
- DELETE `translationVelocityForTesting` (L96-106, ~10 lines including
  docstring) — no readers found via grep. AMBIGUOUS; confirm before
  deletion.

### Cross-ref warnings
- WARN: Tests/V2/ (other agent): WaveR41SubstrateCanaryTests,
  WaveR43TranslationVelocityCaptureTests, WaveR44PerDirectionProfileTests
  use the remaining ForTesting accessors. Those tests must keep them, OR
  migrate to a non-internal probe.

---

## File: DotPinchPrototype/Conversation/V2/CellView.swift

### Symbols (35 — abbreviated)
| Name | Kind | Line | Vis | Tag | External refs |
|------|------|------|-----|-----|---------------|
| CellView | class final UIView | 46 | internal | LIVE_REACHABLE | TimelineCanvas, tests, Debug, V2RootVC (comment) |
| index | property | 52 | internal | LIVE_REACHABLE | TimelineCanvas + tests |
| onTap | property | 58 | internal | LIVE_REACHABLE | TimelineCanvas:1055 |
| **tapRecognizer** | property | 62 | internal private(set) | AMBIGUOUS | no current grep external readers |
| activeConversationID | property | 68 | internal private(set) | LIVE_REACHABLE | TimelineCanvas pool |
| dateLabel / topicSummaryLabel / todayLabel / labelStack / chatRestCenterLabel | properties | 73-91 | internal private(set) | LIVE_REACHABLE | TimelineCanvas morph paths |
| morphInProgress | property | 97 | internal | LIVE_REACHABLE | TimelineCanvas:1739, self:420 |
| pinchGlyph | property | 102 | internal private(set) | LIVE_REACHABLE | TimelineCanvas:1824 |
| naturalHeight / heightConstraint / widthConstraint / centerYConstraint / leadingConstraint | properties | 111-132 | internal private(set) | LIVE_REACHABLE | TimelineCanvas + tests |
| naturalHorizontalInset / pageWidth | properties | 136 / 141 | private | LIVE_REACHABLE | self |
| init(frame:) | init | 145 | override | LIVE_REACHABLE | TimelineCanvas:1221 |
| init?(coder:) | unavailable | 170 | — | LIVE_REACHABLE | NSCoder |
| **deinit** | deinit | 174-178 | — | ORPHAN | empty body — only a comment |
| invalidateConversationBinding() | method | 183 | internal | LIVE_REACHABLE | TimelineCanvas:681,1281 |
| installLayout(...) | method | 201 | internal | LIVE_REACHABLE | TimelineCanvas |
| deactivateLayoutConstraints() | method | 242 | internal | LIVE_REACHABLE | TimelineCanvas:1256 |
| resetHeightConstraintToNatural() | method | 258 | internal | LIVE_REACHABLE | TimelineCanvas:1255 |
| setupSubviews / installLabelStack / installPinchGlyph / activateConstraints / installTapRecognizer | private | 267-376 | private | LIVE_REACHABLE | init |
| configure(with:) | method | 382 | internal | LIVE_REACHABLE | TimelineDataSourceAdapter:38 |
| todayLabelText(for:) | static | 393 | private | LIVE_REACHABLE | self |
| setCamera(_:viewport:) | method | 416 | internal | LIVE_REACHABLE | TimelineCanvas + tests |
| handleTap | @objc | 452 | private | LIVE_REACHABLE | selector |

### Comment-slim (~80-90 lines removable)
- L1-41: 41-line top-of-file (Content hierarchy + Critical disciplines with
  §7.1/§7.2/§7.3/§13.4 refs) → 5-line docstring.
- L52-141: per-property docstrings each carry wave/§ refs. Keep 1-line each;
  drop pre-mortem references. ~40 lines saved.
- L143-167 init body: drop pre-mortem §4.1 (a) + §7.2 refs; keep
  CATransaction reason. ~10 lines.
- L187-340 installLayout / setupSubviews / activateConstraints: heavy
  wave-narrative + a load-bearing-feeling keyboardLayoutGuide-history
  block (L327-340) that's actually stale (no kbd-guide constraint is
  installed today). DELETE that block; compress per-method doc. ~30 lines.
- L342-376 inline constraint comments + installTapRecognizer pre-mortem
  reference: trim. ~15 lines.
- L401-446 setCamera doc + inline §4.2.6/§7.1/§7.2 history: → 4-line
  functional doc + minimal inline. ~15 lines.

### Hard deletes
- DELETE `deinit` (L174-178). Body is empty — only a 4-line comment about
  "Defensive: if a cell is evicted from the pool while holding first-
  responder, dismiss the keyboard cleanly". The body does NOT call
  `endEditing(true)`. Either remove the deinit entirely (no behavior is
  lost) or add the missing call. Recommendation: DELETE entirely.

### Cross-ref warnings
- WARN: `tapRecognizer` (L62) is `private(set) var` exposed for tests per
  comment, but I found no test reader via grep. AMBIGUOUS — confirm
  before downgrading to private.

---

## File: DotPinchPrototype/Conversation/V2/ChatViewController.swift

### Symbols
| Name | Kind | Line | Vis | Tag | External refs |
|------|------|------|-----|-----|---------------|
| ChatViewController | class final @MainActor | 4 | internal | LIVE_REACHABLE | V2RootViewController:112 |
| headerLabel / scrollView / bubbleStack / composerContainer / composerTextField / conversation | properties | 6-12 | private | LIVE_REACHABLE | self |
| loadView() / viewDidLoad() | overrides | 14 / 19 | internal | LIVE_REACHABLE | UIKit |
| configure(with:) | method | 27 | internal | LIVE_REACHABLE | V2RootViewController:124 |
| headerText(for:) | static | 37 | private | LIVE_REACHABLE | self |
| installHeader / installScrollView / installComposer / activateConstraints | methods | 45-84 | private | LIVE_REACHABLE | viewDidLoad |
| rebuildBubbles(from:) | method | 113 | private | LIVE_REACHABLE | configure |
| scrollToBottom(animated:) | method | 123 | private | LIVE_REACHABLE | configure |
| **layoutIfNeeded()** | method | 129 | private | LIVE_REACHABLE but trivial | only called at line 124 |

### Comment-slim (~2 lines)
File is the cleanest in scope; no wave-narrative blocks. A short top-of-
file 3-line docstring would be useful for consistency.

### Hard deletes
- POTENTIALLY DELETE `layoutIfNeeded()` (L129-131) — private 3-line wrapper
  around `view.layoutIfNeeded()`. Inline its single call site. Save ~3
  lines.

### Cross-ref warnings
- WARN: Placeholders/ (other agent): `DestinationContent.composerHint`
  used at L78 — confirm LIVE.
- WARN: Conversation/ChatBody/ (other agent): `ChatBubbleView` used at
  L119 — confirm V2-still-needed (not retired with V1).

---

## File: DotPinchPrototype/Conversation/V2/TimelineCanvas.swift

### Symbols (80+ — abbreviated to load-bearing + flagged ones)
| Name | Kind | Line | Vis | Tag | External refs |
|------|------|------|-----|-----|---------------|
| TimelineCanvas | class final UIView | 33 | internal | LIVE_REACHABLE | V2RootViewController, Debug, 35+ Tests/V2/* |
| cellSpacing / cullMargin / cellHorizontalInset / maxKeyedPoolSize / edgeMaskHeight | static lets | 38-432 | internal | LIVE_REACHABLE | self/tests |
| camera | property | 56 | internal private(set) | LIVE_REACHABLE | many |
| activeCellIndex | property | 70 | internal private(set) | LIVE_REACHABLE | self + tests |
| instantiatedCells / cellPool / cellPoolByConversationID / poolOrder | properties | 77-109 | internal private(set) | LIVE_REACHABLE | self + tests |
| dataSource (weak) | property | 120 | internal | LIVE_REACHABLE | V2RootVC, tests |
| panRecognizer / pinchRecognizer | properties | 127 / 139 | internal private(set) | LIVE_REACHABLE | self |
| panInitialCameraTranslationY / pinchInitialScale / pinchInitialExtension / pinchAnchorPageY / pinchPreviousCentroidY / pinchPreviousCentroidTimestamp | properties | 132-172 | private | LIVE_REACHABLE | self |
| animationController | property | 180 | internal | LIVE_REACHABLE | self |
| onMorphRevealReady | property | 185 | internal | LIVE_REACHABLE | V2RootViewController:94 |
| cameraAnimator / extensionAnimator | properties | 190 / 196 | internal private(set) | LIVE_REACHABLE | tests + self |
| **masterAnimator** | property | 205 | internal private(set) | **ORPHAN** | created in init, `valueChanged` wired but `.start()` never called anywhere. Effectively dead. |
| masterTimer / masterTimerStart / masterTimerDuration / masterTimerCompletion | properties | 212-215 | private | LIVE_REACHABLE | self (used for actual tap-to-chat) |
| masterStartHeight / masterEndHeight / masterStartCameraY / masterEndCameraY | properties | 219-222 | private | LIVE_REACHABLE | self |
| **masterUncompensatedCameraTarget** | property | 223 | private | **ORPHAN** | written L1925, never read |
| masterUnifiedArcMagnitude / masterActiveCellIndex | properties | 224-225 | private | LIVE_REACHABLE | self |
| **activeCellArcOffset / activeCellScalePulse** | properties | 230 / 234 | private | **DEAD-CODE-PATH** | written but always 0 / 1.0 (hardcoded at L2026-2027); read at L1142-1143 — composed transform reduces to identity |
| anticipationAnimator | property | 242 | internal private(set) | DEAD-FEATURE | tests reference state but the only producer (engageAnticipation) is orphan |
| lastCellRestScrollY | property | 250 | internal private(set) | LIVE_REACHABLE | self |
| pageGradientLayer / contentHost / topRevealMask / bottomRevealMask | properties | 257-287 | internal | LIVE_REACHABLE | self/tests |
| accumulatedYCache / cachedCellCount | properties | 298 / 302 | private | LIVE_REACHABLE | self |
| init(frame:) | override | 306 | internal | LIVE_REACHABLE | V2RootViewController |
| init?(coder:) | unavailable | 342 | — | LIVE_REACHABLE | NSCoder |
| installViewHierarchy / installEdgeMasks / installPageGradient / installPanRecognizer / installPinchRecognizer | private | 347-484 | private | LIVE_REACHABLE | init |
| layoutSubviews() | override | 488 | internal | LIVE_REACHABLE | UIKit |
| updateEdgeMaskAlphas() | private | 550 | private | LIVE_REACHABLE | self |
| currentCanvasProgress() | method | 572 | internal | LIVE_REACHABLE | Debug + tests + self |
| anchorToCellRestIfAtInitialState() | private | 586 | private | LIVE_REACHABLE | layoutSubviews |
| setCamera(_:) | method | 602 | internal | LIVE_REACHABLE | self + tests |
| setActiveCellIndex(_:) | private | 628 | private | LIVE_REACHABLE | self |
| onCameraChanged | property | 650 | internal | LIVE_REACHABLE | Debug, self |
| reloadData() | method | 656 | internal | LIVE_REACHABLE | V2RootViewController:84 |
| visiblePageRect | property | 698 | internal | LIVE_REACHABLE | self |
| viewportCenter | computed | 710 | private | LIVE_REACHABLE | self |
| pagePointFromViewportPoint(_:) | method | 719 | internal | LIVE_REACHABLE | V2RootViewController:101 |
| **viewportPointFromPagePoint(_:)** | method | 726 | internal | AMBIGUOUS | no callers in source or tests |
| pageRectFromViewportRect(_:) | method | 736 | internal | LIVE_REACHABLE | self |
| **viewportRectFromPageRect(_:)** | method | 757 | internal | **ORPHAN** | no callers anywhere |
| applyCameraTransform / transform3D / viewportPoint(fromPage:) / pagePoint(fromViewport:) | methods | 782-810 | private/static | LIVE_REACHABLE | self |
| pageWidth / pageHeight / pageFrameForCell(at:) / cellIndex(atPagePoint:) / cellIndices(in:plusMargin:) | layout API | 818-913 | internal | LIVE_REACHABLE | V2RootVC, tests, self |
| invalidateLayout / accumulatedYs / cellCount / heightForCell | private | 919-958 | private | LIVE_REACHABLE | self |
| updateVisibleCells() | private | 972 | private | LIVE_REACHABLE | self |
| restoreNaturalSiblingOrder() | private | 1076 | private | LIVE_REACHABLE | self |
| pushCameraToVisibleCells() | private | 1096 | private | LIVE_REACHABLE | self |
| updateNeighborTranslations() | private | 1125 | private | LIVE_REACHABLE | self |
| dequeueCell(preferredConversationID:) / returnToPool(_:) | private | 1173 / 1239 | private | LIVE_REACHABLE | self |
| **visibleCells** | computed | 1317 | internal | AMBIGUOUS | no grep readers found |
| hitTest(_:with:) | override | 1342 | internal | LIVE_REACHABLE | UIKit |
| handlePan / handlePinch | @objc | 1385 / 1445 | private | LIVE_REACHABLE | selectors |
| clampedWithRubberband(_:) | private | 1421 | private | LIVE_REACHABLE | handlePan |
| handlePinchBegan / handlePinchChanged / handlePinchEnded | methods | 1468 / 1517 / 1577 | internal | LIVE_REACHABLE | handlePinch + tests |
| SpringDirection enum + springProfile(for:) | fileprivate | 1665 / 1675 | fileprivate | LIVE_REACHABLE | self |
| applyExtensionTick() | private | 1692 | private | LIVE_REACHABLE | extensionAnimator wire |
| animateCameraToCellRest() | method | 1712 | internal | LIVE_REACHABLE | Debug, tests |
| animateCameraToChatRest(forCellAt:) | method | 1732 | internal | LIVE_REACHABLE | V2RootViewController:104, Debug, tests |
| **engageAnticipation(forCell:then:)** | private | 1836 | private | **ORPHAN** | no callers in source or tests |
| animateCameraToChatRestPath(...) | fileprivate | 1871 | fileprivate | LIVE_REACHABLE | self |
| startMasterTimer / masterTimerTick / applyMasterTick | private | 1970-1999 | private | LIVE_REACHABLE | self |
| animateCameraToCellRestPath(...) | fileprivate | 2061 | fileprivate | LIVE_REACHABLE | self |
| tryClearActiveCellAtRest(expectedIdx:) | private | 2123 | private | LIVE_REACHABLE | self |
| handleCellTap(at:) | private | 2140 | private | LIVE_REACHABLE | self |
| startSpringDeceleration(initialVelocityY:) | private | 2147 | private | LIVE_REACHABLE | handlePan ended |
| gestureRecognizer(_:shouldRecognizeSimultaneouslyWith:) | method | 2171 | internal | LIVE_REACHABLE | UIKit delegate |

### Comment-slim (~300-400 lines removable in 2192-line file)
- L1-29 wave-narrative + STUB descriptions → 6-line class purpose.
- L36-242 property-doc block (cellSpacing through anticipationAnimator) is
  ~170 lines with extensive pre-mortem/§/Adversary references. Reduce to
  1-line per property. ~120 lines saved.
- L244-302 layer-hierarchy + memoization docs (V1 chatMask history, Wave 5
  §10.56, accumulated-Y T1.6.K refs) → ~30 lines saved.
- L347-484 install* functions: keep the perspective explanation (non-
  obvious math); compress wave/§ refs. ~45 lines.
- L488-625 layoutSubviews + updateEdgeMaskAlphas + currentCanvasProgress
  + setCamera + setActiveCellIndex: ~45 lines of FM/§ history removable.
- L638-695 onCameraChanged + reloadData: ~35 lines (FM-1/FM-04/§11.18.d).
- L702-810 page↔viewport helpers: 5 helpers each with 5-7 line cartography
  docs → 1-line each; KEEP the CATransform3DMakeTranslation explanation.
  ~30 lines.
- L847-913 cellIndex/cellIndices: ~5 lines (remove the dead `_ = bottom`
  block + comment).
- L960-1117 updateVisibleCells / restoreNaturalSiblingOrder / pushCameraTo
  VisibleCells: ~50 lines of §2.3/Adversary R3/Wave 4d/§4.3.7.3/FM/§10.81
  references.
- L1118-1149 updateNeighborTranslations: the "composed transform — translate
  up (arc) THEN scale up past 1.0 at peak (depth-axis approach burst)"
  comment (L1137-1141) is STALE — see Hard Deletes. ~10 lines.
- L1151-1311 dequeueCell / returnToPool: ~50 lines of §4.3.7.3 / Wave 4b /
  pre-mortem / FM-1 / §13.4 / §7.8 / §7.10 references.
- L1323-1432 hitTest + handlePan + clampedWithRubberband: ~30 lines.
- L1434-1659 pinch handlers (Began/Changed/Ended) + SpringDirection +
  springProfile: ~95 lines of R4.2 / R4.3 / R4.4 / §7.13 / §7.19 / §7.25 /
  §7.27 / §5.7.3 / §5.7.4 / Adversary HIGH 4 / cartography Watch-out refs.
  Compress to ~30. ~65 lines.
- L1707-1731 animate*Rest entry-point docs: ~15 lines.
- L1865-1956 animateCameraToChatRestPath: ~30 lines of R4.4 / §7.13 /
  Adversary HIGH 1 / MEDIUM 7 references.
- L1958-2050 master tick docs + curve essays: ~30 lines (keep the math
  rationale; drop the "Standing too close to the elephant" prose).
- L2052-2104 animateCameraToCellRestPath: ~25 lines of §1.3.3 / R1.1 /
  Adversary HIGH 1 / MEDIUM 7 history.
- L2106-2137 tryClearActiveCellAtRest: KEEP. Non-trivial race-discussion.
- L2162-2192: gestureRecognizer delegate docs (~8 lines slim) + trailing
  PanDecelerator-retirement comment block at L2185-2192 — **DELETE**
  (refers to a class that no longer exists). ~8 lines.

### Hard deletes
- DELETE `masterAnimator` property + init wiring. Lines: L197-205 (decl +
  7-line preamble doc), L326-337 (init block). `.start()` is **never
  called** anywhere; `applyMasterTick` is driven exclusively by
  `masterTimer` (CADisplayLink). Save ~20 lines.
- DELETE `masterUncompensatedCameraTarget` (L223 decl + L1925 write).
  Written once, never read. Save 2 lines.
- DELETE `activeCellArcOffset` + `activeCellScalePulse` (L227-234 decl +
  L1944-1945 + L2026-2027 + L2040-2041 writes). Values are ALWAYS 0 / 1.0
  → the composed transform in updateNeighborTranslations (L1142-1143)
  always reduces to `.identity`. Collapse the active-cell branch back to
  `cell.transform = .identity`. Save ~15 lines.
- DELETE `engageAnticipation(forCell:then:)` (L1833-1863) — no callers
  anywhere. Save ~28 lines. NOTE: if entire R7.2 anticipation feature is
  truly dead, also delete `anticipationAnimator` property (L242) and the
  defensive nil-set in handlePinchBegan (L1473-1474), AND retire the
  Wave4f / R72 / R73 / R74 / R75 tests that assert `anticipationAnimator
  == nil`. AMBIGUOUS — flag for synthesis / user decision.
- DELETE `viewportRectFromPageRect(_:)` (L756-774). No callers in source
  or tests. Save 19 lines.
- DELETE `viewportPointFromPagePoint(_:)` (L723-728). No callers found via
  grep. AMBIGUOUS. Save ~6 lines.
- DELETE `visibleCells` computed (L1313-1321). No external grep readers
  found. AMBIGUOUS — may be reflection-used. Save ~9 lines.
- DELETE trailing comment block at L2185-2192 (refers to retired
  PanDecelerator). Save 8 lines.
- DELETE the dead local var pattern in cellIndices(in:plusMargin:) at
  L883-891 (the `bottom` local + `_ = bottom // unused; keep explicit
  version` block). Save ~3 lines.

### Cross-ref warnings
- WARN: Animation/ (other agent): `SpringAnimator`, `Spring`,
  `AnimationController` are all LIVE_REACHABLE via TimelineCanvas + camera
  animator. Do not retire.
- WARN: Animation/ (other agent): `smoothstep`, `rubberband`, `project`,
  `clamp` (math utilities) read at L431, L1109, L1426, L2153, L2155.
- WARN: Gestures/ (other agent): `PinchTuning` is LIVE_REACHABLE. If
  R7.2 anticipation is purged (above), `PinchTuning.anticipationMagnitude`
  + `anticipationDuration` become UNUSED in this scope. Flag for
  Gestures-owning agent.
- WARN: DesignSystem/ (other agent): Theme.Page.* + Theme.Cell.fill +
  Theme.Radius.card + Theme.Text.* + Theme.Typography.* + Theme.Symbol.* +
  AccessibilityID.conversationSurface + SymbolName.pinchExpandAffordance
  all LIVE via CellView + TimelineCanvas.
- WARN: Debug/ (other agent): `TimelineCanvasPreviewVC.swift` consumes
  `onCameraChanged`, `currentCanvasProgress()`, `animateCameraToChatRest
  (forCellAt:)`, `animateCameraToCellRest()`. The first two have ONLY
  Debug + Tests readers — if Debug retires, `currentCanvasProgress()` and
  `onCameraChanged` become near-orphaned (only test readers).

---

## File: DotPinchPrototype/Conversation/V2/TimelineDataSource.swift

### Symbols
| Name | Kind | Line | Vis | Tag | External refs |
|------|------|------|-----|-----|---------------|
| TimelineDataSource | protocol (AnyObject) | 30 | internal | LIVE_REACHABLE | TimelineCanvas, Adapter, tests |
| numberOfCells(in:) | requirement | 32 | internal | LIVE_REACHABLE | adapter |
| canvas(_:configureCell:at:) | requirement | 37 | internal | LIVE_REACHABLE | adapter |
| canvas(_:heightForCellAt:) | requirement | 40 | internal | LIVE_REACHABLE | adapter |
| canvas(_:conversationIDForCellAt:) | requirement | 51 | internal | LIVE_REACHABLE | adapter |
| canvas(_:conversationIDForCellAt:) default | extension | 58 | internal | LIVE_REACHABLE | test data sources |

### Comment-slim (~30 lines removable)
- L1-20 top-of-file → 4-line docstring.
- L25-29 + L31-58: per-requirement docs lose pre-mortem T1.5.A / §2.4 /
  §13.4 / §4.3.7.3 refs; keep functional 1-line each.

### Hard deletes
- None.

### Cross-ref warnings
- None.

---

## File: DotPinchPrototype/Conversation/V2/TimelineDataSourceAdapter.swift

### Symbols
| Name | Kind | Line | Vis | Tag | External refs |
|------|------|------|-----|-----|---------------|
| TimelineDataSourceAdapter | class final @MainActor | 19 | internal | LIVE_REACHABLE | V2RootViewController:28,38 |
| store / naturalCellHeight | properties | 21-22 | private | LIVE_REACHABLE | self |
| init(store:naturalCellHeight:) | init | 24 | internal | LIVE_REACHABLE | V2RootViewController |
| numberOfCells(in:) | method | 31 | internal | LIVE_REACHABLE | TimelineCanvas |
| canvas(_:configureCell:at:) | method | 35 | internal | LIVE_REACHABLE | TimelineCanvas |
| canvas(_:heightForCellAt:) | method | 41 | internal | LIVE_REACHABLE | TimelineCanvas |
| canvas(_:conversationIDForCellAt:) | method | 45 | internal | LIVE_REACHABLE | TimelineCanvas |

### Comment-slim (~13 lines removable)
- L1-14 top-of-file (Wave I1 + stale CellView.swift:631 line-number back-
  reference + §7.8 / §13.4 refs) → 3-line functional docstring.

### Hard deletes
- None.

### Cross-ref warnings
- None.

---

## Summary

- Files audited: 10
- Symbols audited: ~145
- ORPHAN count: 5 hard orphans —
  `ConversationComposer` enum (entire file, V1_ONLY, ~86 lines),
  `masterAnimator` property + wiring (TimelineCanvas L205, L326-337),
  `masterUncompensatedCameraTarget` field (TimelineCanvas L223),
  `engageAnticipation` method (TimelineCanvas L1836),
  `viewportRectFromPageRect` method (TimelineCanvas L756-774),
  plus `deinit` on CellView (L174-178, empty body / comment-only).
- DEAD-CODE-PATH count: 2 — `activeCellArcOffset` and
  `activeCellScalePulse` (write-and-read but values are always identity).
- V1_ONLY count: 1 file (`App/ConversationComposer.swift`, ~86 lines).
- AMBIGUOUS / probably-deletable accessors:
  `translationVelocityForTesting` on CameraAnimator,
  `tapRecognizer` on CellView (claimed test-probed in comment but no
  current grep reader),
  `visibleCells` on TimelineCanvas (no grep readers),
  `viewportPointFromPagePoint` on TimelineCanvas (no callers).
- LIVE_REACHABLE count: ~120
- Total lines deletable (hard): ~195 (Composer file 86 + master/
  anticipation orphans ~75 + CellView deinit + misc ~30)
- Total lines comment-removable: ~520-600 across all 10 files;
  TimelineCanvas alone accounts for ~350.

### Top-level recommendations for synthesis

1. **Delete `ConversationComposer.swift` outright** — coordinate with V1
   test purge (Tests/Support/Fixtures.swift, PinchGlyphPhaseTests,
   TapTargetTests, MemoryTimelineTests all use it).
2. **Delete the dead R7.2 anticipation feature** — `engageAnticipation`
   has no callers. Decide whether the `anticipationAnimator` property +
   defensive nil-sets stay (with tests that assert nil) or all retire
   together. Surface to user.
3. **Delete the unused `masterAnimator` SpringAnimator** — production
   uses `masterTimer` (CADisplayLink). The spring was a spike that never
   won.
4. **Collapse the active-cell composed transform back to `.identity`** —
   `activeCellArcOffset` and `activeCellScalePulse` are always 0 and 1.0;
   the "ferris-wheel / depth-axis approach burst" comment at
   TimelineCanvas:1137-1141 is stale.
5. **TimelineCanvas comment-slim is the highest-volume win** — ~350 lines
   of historical wave/§/pre-mortem/Adversary references removable without
   touching any behavior.
