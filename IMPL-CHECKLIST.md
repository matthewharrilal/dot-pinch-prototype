# Chat→Cell Pinch — Implementation Checklist

Single source of truth, traced item-by-item against the codebase as of 2026-05-26. Each entry: spec behavior → current state at exact file:line → change → dependencies/order → collateral. No items added outside the 13 spec behaviors.

File abbreviations used throughout:
- TC = `DotPinchPrototype/Conversation/Timeline/TimelineCanvas.swift`
- CV = `DotPinchPrototype/Conversation/Timeline/CellView.swift`
- MC = `DotPinchPrototype/Conversation/Timeline/MorphChoreographer.swift`
- RC = `DotPinchPrototype/Conversation/Timeline/RevealCoordinator.swift`
- CCC = `DotPinchPrototype/Conversation/ChatBody/ChatContentContainer.swift`
- V2R = `DotPinchPrototype/App/V2RootViewController.swift`
- CSC = `DotPinchPrototype/Conversation/Timeline/ConversationStateController.swift`

Ordering legend at the end of each item: **BLOCKS** (others can't land until this does) / **DEPENDS** (needs these landed first).

---

## 1. Single persistent surface

**Spec**: One numerically identical UIView holds the chat state and the cell state. The cell is the chat with edges off-screen; contraction reveals pre-existing cell-ness. No cross-dissolve between two objects.

**Current state (VIOLATED, two-object cross-dissolve)**:
- `RC:71` `let chatVC = installChatViewController(in: parent, parentView: parentView, conversation: conversation)` instantiates a `ChatViewController` and adds its view as a sibling of the canvas inside `parentView`.
- `RC:178-194` `performHandoff()` runs `transferState()` → `performAtomicAlphaSwap()` → `detachAndReleaseChatVC()`. The "atomic swap" at `RC:209-221` writes `chatVC.view.alpha = 0` AND `chatContent.alpha = 1` inside one suppressed CATransaction. That is the cross-dissolve.
- `V2R:151-177` `handleMorphRevealReady` is the entry point: on K7 morph completion it calls `installChatContentInParallel(...)` (V2R:171) AND `revealCoordinator.present(conversation:)` (V2R:176). The cell's `chatContentContainer` (the persistent representation) is installed *parallel* to the temporary `ChatViewController` so the two can be swapped.
- `RC:244-249` `detachAndReleaseChatVC` removes chatVC from the parent VC tree and transitions `revealState = .idle`. The chatVC instance is released after the swap.
- `CCC:51-66` `init(parentVC:)` already constructs the chat content as a self-contained UIView with `header + bubbleStack + composer + illegibilityBlur`. This is the candidate single persistent surface — it just isn't allowed to BE the chat surface during reveal; instead, chatVC owns that role until handoff.

**Change**: Eliminate `ChatViewController` and `RevealCoordinator` from the morph reveal path. `CellView.chatContentContainer` IS the chat surface from install onward.
- Delete `ChatViewController` and its presentation. After `installChatContentInParallel` lands chatContent inside the cell, the cell is already chat-ready; no second VC is needed.
- Delete `RevealCoordinator.installChatViewController`, `installRevealBlur`, `runRevealChoreography`, `performHandoff`, `transferState`, `performAtomicAlphaSwap`, `detachAndReleaseChatVC` (RC:85-250). The blur fade-in/cross-fade choreography is replaced by `CellView.chatContent.alpha`/`illegibilityBlur` being driven directly by the gesture.
- Rewire `V2R.handleMorphRevealReady` so it only installs `cell.chatContentContainer` (the install-parallel-with-chatVC flow at V2R:193-208 already exists — just drop the `revealCoordinator.present(...)` call at V2R:176).
- Rename: stop calling the post-morph signal "reveal." There is no reveal to coordinate. The cell IS chat after the morph; chatContent.alpha goes 0→1 inside the same animator that drives the surface transform.

**Dependencies/Order**: Must land FIRST. Behaviors 2–13 all assume one surface. **BLOCKS**: 2, 4, 7, 10, 12.

**Collateral (every site that references the two-object architecture)**:
- V2R:17 `private lazy var revealCoordinator` — initializer.
- V2R:130 `revealCoordinator.cancelInFlight()` — scene-deactivate hook.
- V2R:134 `revealCoordinator.completeHandoffIfPending()` — scene-activate hook.
- V2R:152-176 `handleMorphRevealReady` — the only caller of `.present`.
- V2R:169 `revealCoordinator.stateController = stateController` — state injection.
- V2R:179-188 `syncExistingChatContentIntoStateController` — depends on the dual-object model; can be deleted under single-object.
- TC `onMorphRevealReady` callback (TC:1388 `self.onMorphRevealReady?(revealK)`) — semantic shifts from "ready for chatVC present" to "morph complete, chatContent now visible." Likely keep the callback name or rename to `onCellExpansionComplete`.
- CSC.captureFromChatVC (CSC:57) becomes obsolete under single-object. CSC.bindToChatVCAtInstall (CSC:68) becomes obsolete.
- All `ChatViewController` references in the project (deletion of the file affects the test target if any test imports it; grep first).
- `RevealBlurOverlay` (referenced at RC:99 `installRevealBlur`) — orphan after RC simplification.

---

## 2. Uniform two-axis scale via one scalar

**Spec**: A single scalar `s` drives both width and height of the surface. Aspect ratio locked. Corners traverse diagonals. Implemented as `CGAffineTransform` (or layer.transform) scale, not as constraint animation.

**Current state (VIOLATED — height-only constraint animation + tiny X inset)**:
- `CV:242` `let heightC = heightAnchor.constraint(equalToConstant: naturalHeight)` is the cell's height constraint; mutated throughout the gesture.
- `CV:238` `let widthC = widthAnchor.constraint(equalToConstant: pageWidth - 2 * horizontalInset)` is the width constraint; only changes via `applyHorizontalInsetFromScale`.
- `CV:411-422` `applyHorizontalInsetFromScale(chatRestScale:)` ramps `leadingConstraint.constant` and `widthConstraint.constant` over a `1 - scaleProgress` curve. Width range is from `pageWidth - 32` (16pt inset each side at cell-rest) to `pageWidth` (edge-to-edge at chat-rest) — a delta of ~32pt. Height range is `naturalHeight` to `naturalHeight × chatRestFactor × marginFactor` — a delta of ~700pt on iPhone 16. The two axes change by different ratios → anisotropic.
- `TC:1143` (handlePinchChanged) `heightC.constant = clampedExtension` — main pinch driver, writes height only.
- `TC:1175` (handlePinchEnded) `let currentFactor = heightC.constant / naturalH` — commit decision reads height.
- `TC:1285` (applyExtensionTick spring valueChanged) `heightC.constant = value` — spring writes height.
- `TC:1412` `heightC.constant = naturalH * chatRestFactor` — snapToChatRestState writes height.
- `TC:1434` `heightC.constant = activeCell.naturalHeight` — snapToCellRestState writes height.
- `TC:1498, 1546, 1753, 1819` — playTapToChatMorph, springToChatRest, playPinchToCellsMorph, springToCellRest all read/target `heightC.constant`.
- `TC:1636` `cell.heightConstraint?.constant = bounds.height` — normalize extension.
- `MC:81` `heightC.constant = newHeight` — MorphChoreographer ticks height per choreography t.
- `TC:1346-1372` K7 cane curve animates `contentHost.layer.transform.scale` (`transform.scale` keypath, additive). This scales the ENTIRE contentHost, not the active cell, and the only scale here is on the camera-substrate; cell.bounds still depends on the heightConstraint mutated separately.
- `CV:193` `layer.transform = CATransform3DIdentity` — explicit invariant at init: cell.layer.transform stays identity. Conflicts with the spec's requirement that the cell's transform IS the animation primitive.

**Change**:
- Delete every `heightC.constant = …` write listed above (TC:1143, 1285, 1412, 1434, 1498, 1546, 1636, 1753, 1819; MC:81). The height constraint becomes constant — set once at install to a value chosen so the cell.bounds equals the chat-rest viewport-coterminous size (see CV:242). The cell IS this big always; it's the transform that makes it look smaller at cell-rest.
- Reverse the magnitude convention: `heightConstraint.constant = naturalHeight × chatRestScale × marginFactor` permanently (the chat-rest size). At cell-rest the surface APPEARS small via transform.scale ≈ `1 / (chatRestScale × marginFactor)`; at chat-rest the surface APPEARS viewport-coterminous via transform.scale = 1.0.
- Replace all spring/animator targets with `cell.layer.transform` writes. Springs interpolate a scalar `s ∈ [cellRestScale, 1.0]` and write `CGAffineTransform(scaleX: s, y: s)` (with the anchor offset per #3 below).
- Delete `applyHorizontalInsetFromScale` (CV:411-422) and its caller in `setCamera` (CV:358). The transform handles X scaling automatically.
- Delete `widthConstraint` mutation paths (CV:421 `widthC.constant = pageWidth - 2 * currentInset`).
- Rewrite `handlePinchChanged` (TC:1125-1161) to derive `s` from `recognizer.scale / pinchState.initialScale` and write `cell.layer.transform`.
- Rewrite `applyExtensionTick` (TC:1279-1292) to read animator value as `s` and write transform.
- Rewrite K7 cane curve (TC:1346-1372) to animate `cell.layer.transform.scale` instead of `contentHost.layer.transform.scale`. The cane curve becomes a scalar-s animation with windup + zoom + (optional Y lift); Z is already 0 per MorphTokens.unifiedArcZMagnitude.
- Rewrite `MorphChoreographer.apply` (MC:66-85) to interpolate `s` instead of height.
- Rename `extensionAnimator` → `scaleAnimator` (TC:146 valueChanged handler + every reference site) to reflect what it now drives.

**Dependencies/Order**: Requires single-persistent-surface (#1) so we have ONE layer to anchor the transform on. **DEPENDS**: 1. **BLOCKS**: 3, 4, 5, 11.

**Collateral**:
- `pinchState.initialExtension` (TC:1115) currently captures heightConstraint.constant. Becomes `pinchState.initialScale` (capturing the layer transform's current `m11`).
- `currentCanvasProgress` (TC) — currently `extensionFactor - 1 / chatRestRange`. Becomes `(1.0 - currentTransformScale) / (1.0 - cellRestScale)`.
- `updateNeighborTranslations` (TC:761) reads `activeCell.bounds.height - activeCell.naturalHeight` to compute growth. Becomes scalar-driven: growth derived from the active cell's transform.scale.
- `CellView.currentScale` (CV:366) currently `bounds.height / naturalHeight`. Becomes `layer.transform.m11`.
- All applier functions in CV (`applyShadowGate`, `applyCellRestChromeAlphasFromScale`, `applyChatContentScaleFade`, `applyIllegibilityBlur`, `applyChatRestAffordanceFromScale`) read `currentScale` and continue to work IF currentScale is redefined to the transform value.
- `CellView.computeProgress(viewport:)` (CV:375-387) — orphan after extensionFactor goes away.
- `cell.heightConstraint?.constant = bounds.height` in normalizeToChatRest (TC:1636) — orphan.
- `resetHeightConstraintToNatural` (CV:281-283) — orphan.
- WaveR34BoundaryEmergenceTests, CellLayoutTests — many use heightConstraint.constant directly. Some test setups need rewriting to drive scale instead of height.

---

## 3. Off-center anchor

**Spec**: The single scalar's anchor is at approximately (0.4, 0.85) of the surface — left-of-center, near the bottom. Visible consequence: corners converge on a low-left point; surface drifts slightly left and settles low; the gap above the contracted cell is where the neighbor resolves.

**Current state (ABSENT)**:
- `CV:181-198` cell init: no `layer.anchorPoint` written. UIView default is `CGPoint(x: 0.5, y: 0.5)`.
- `TC:1346-1372` K7 cane curve operates on `contentHost.layer`, whose `anchorPoint` is also UIView default (0.5, 0.5).
- No file in the project sets `anchorPoint` to anything off-center (grep `anchorPoint` returns layout-related references only).

**Change**:
- After #2 lands and `cell.layer.transform` is the scale primitive, set `cell.layer.anchorPoint = CGPoint(x: 0.4, y: 0.85)` at install time (CV:185-198). Compensate `layer.position` so the view's visible center at scale=1.0 stays exactly where the constraint puts it — `position` shifts by `(anchor - 0.5) × bounds.size`. Equivalent formulation: apply scale via `CGAffineTransform.identity.translatedBy(x: anchor.x, y: anchor.y).scaledBy(x: s, y: s).translatedBy(x: -anchor.x, y: -anchor.y)` in surface-local pt without touching anchorPoint.

**Dependencies/Order**: Trivial once #2 is in. **DEPENDS**: 2. **BLOCKS**: nothing strictly, but the gap-for-neighbors (#10) depends on the off-center contraction to produce the right gap geometry.

**Collateral / Measurement task**:
- **The value (0.4, 0.85) is the user's number, NOT measured against frames.** Mark this as a measurement task:
  - Extract corner positions of the contracting surface across f028–f045 of `_frames/dot_pinch.mov` at frame-by-frame fidelity.
  - For each frame, compute corner trajectories. The four corner trajectories must each be straight lines (per uniform scale). Fit the single point all four lines pass through — that's the anchor.
  - Treat the value as a token in `MorphTokens.swift` (e.g., `cellTransformAnchor: CGPoint`), not a hardcoded literal at the call site, so the measured value can replace the provisional one without code surgery.

---

## 4. Track A leads, Track B gated

**Spec**: Track A (content scale + blur) runs from t=0 to threshold X. Track B (bounds visibly committing, shadow asserting) starts ONLY AFTER A crosses X. They are sequenced, not parallel. Tails overlap; starts are offset.

**Current state (VIOLATED — single-curve parallel)**:
- The same scalar `currentScale = bounds.height / naturalHeight` (CV:366) drives EVERY applier called from `setCamera` (CV:350-364):
  - `applyCellRestChromeAlphasFromScale` (chrome alpha)
  - `applyChatRestAffordanceFromScale` (affordance alpha)
  - `applyHorizontalInsetFromScale` (X inset)
  - `applyShadowGate` (shadow opacity, "Track B" property)
  - `applyIllegibilityBlur` (blur fraction, "Track A" property)
  - `applyChatContentScaleFade` (chatContent alpha)
- All run on every tick of the same animator. They use different scale-bands inside `StageOrdering` (CV:392, 406, 425, 432) to position themselves at different points along the scale axis, but the BANDS are tuned-in-parallel — there is no gating condition between A and B. As soon as the cell extends, every applier is computing its output for the current scale value.
- The structural absence: nowhere does the code subscribe to "Track A's blur reaching its full-illegibility magnitude" before starting Track B. There is no event, no flag, no trigger relationship — only a shared `currentScale` parameter feeding parallel functions.

**Change**:
- Split `setCamera` into two phases.
  - **Track A appliers** (run on every tick, gesture t=0 onward): `applyContentScale` (rewritten — applies transform.scale to chatContent's INNER content layer, see #7) and `applyIllegibilityBlur`.
  - **Track B appliers** (run only after legibility-event fires): `applyBoundsScale` (transform.scale on the cell as a whole, see #2/#3), `applyShadowGate`, the chrome fades (`applyCellRestChromeAlphasFromScale`, etc.).
- Add a `legibilityEventFired: Bool` state on `CellView` (or `TimelineCanvas`). At each setCamera tick, after `applyIllegibilityBlur` writes the blur fraction, check `if blurFraction ≥ illegibilityThreshold && !legibilityEventFired { legibilityEventFired = true }`. Once true, Track B appliers run.
- Once `legibilityEventFired`, the SAME pinch progress drives both A and B for the rest of the gesture (overlap window) — A's tail (blur deepening past full) and B's start (bounds contracting). The condition gates Track B's *start*, not its concurrency afterward.
- On cancel-before-X (#13) and on reverse-of-reverse: reset `legibilityEventFired = false` when the gesture restarts.

**Dependencies/Order**: Requires #1 (one surface to scale) and #2 (transform-based scaling). **DEPENDS**: 1, 2. **BLOCKS**: 5 (legibility event trigger is the implementation of this gate), 10 (neighbor resolution gates on the same threshold), 11 (active-cell-precedes-neighbor lag is downstream).

**Collateral**:
- `StageOrdering` (Conversation/Tuning/StageOrdering.swift) currently defines all bands on the chatRestScale axis. The "focalBlurBand" stays as Track A's blur curve. The "cellShadowBand", "cellRestChromeBand", "chatContentFadeBand" become Track B properties that are CLAMPED to 0 (no-op) until `legibilityEventFired` is true.
- StageOrderingInvariantTests (Tests/V2/StageOrderingInvariantTests.swift) — the "never two figures at once" test currently asserts at most one band is in (0,1) for any scale. Under gating it must additionally assert Track B bands return 0 when `legibilityEventFired == false` regardless of scale.
- The illegibility-toe constants `illegibilityToeIn` / `illegibilityToeFull` in StageOrdering — the latter becomes the comparison threshold for the gate event.

---

## 5. Legibility event as trigger

**Spec**: Track B starts when the blur magnitude reaches its text-killing value — not at a clock time, not at a fixed scale value. The gate subscribes to the legibility event.

**Current state (ABSENT — blur is decorative today)**:
- `CV:430-437` `applyIllegibilityBlur(chatRestScale:)` computes `chatContent.setIllegibilityFraction(rising * falling)` — a bump curve peaking inside `StageOrdering.focalBlurBand`. The fraction is written into the blur view's alpha (CCC:97-99). Nothing reads this fraction.
- `CV:424-428` `applyShadowGate(chatRestScale:)` reads `currentScale` directly (NOT the blur fraction) and decides shadow opacity independently.
- The illegibility threshold exists nominally — `StageOrdering.illegibilityToeFull(chatRestScale:)` is referenced once at TC:1176 to gate the commit decision (`commitThreshold`), but no Track B animation listens for it as an event.

**Change**:
- Define `illegibilityThreshold: CGFloat = 0.85` (or measured value — see below) as the blur fraction beyond which text is unresolvable.
- In `applyIllegibilityBlur`, after writing the fraction, compare against the threshold. When the fraction first crosses it (rising), set `legibilityEventFired = true` and fire a callback (e.g., `onLegibilityEvent?()`) that any Track B applier or animation subscribes to.
- Track B animators (cell.transform.scale ramp from 1.0 → cellRestScale; shadow opacity ramp; chrome alpha) are STARTED in that callback, not at gesture-began. Before the callback fires, the cell's transform stays at 1.0 (full-screen-coterminous), shadow at 0, chrome at chat-rest values.
- Add a corresponding reset: when the gesture reverses past the threshold (blur fraction drops below `illegibilityThreshold - hysteresis_margin`), the event un-fires and any in-flight Track B animators are stopped/reversed.

**Dependencies/Order**: This IS the implementation of #4. **DEPENDS**: 1, 2, 4 (this is part of 4). **BLOCKS**: 10, 11.

**Collateral / Measurement task**:
- **The blur fraction at full illegibility is NOT measured.** Mark as measurement task:
  - Examine reference video frames ~5.7-6.0s. Identify the frame where ANY remaining word becomes unreadable (visual-OCR or manual squint test).
  - At that frame, compute what the blur fraction was — either by inspecting the implementation's bump curve evaluated at the corresponding scale, or by reverse-engineering the blur intensity from the rendered frame.
  - Until measured, `illegibilityThreshold = 0.85` is a placeholder. Token-driven via StageOrdering or a new constant.

---

## 6. Uniform (non edge-priority) blur

**Spec**: Whole-surface focal defocus, uniform across the surface. NOT edge-priority (which would read as atmospheric depth).

**Current state (CORRECT)**:
- `CCC:18-24` `UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))`. `systemMaterial` is a uniform full-field blur — the system applies the same blur radius across the entire view bounds. No edge feathering. ✓
- `CCC:84-95` installViewHierarchy pins `illegibilityBlur` to all four edges of the container — covers the full surface uniformly. ✓
- `CCC:97-99` `setIllegibilityFraction(_:)` writes the view's `alpha`, not edge mask values. The blur layer is either present (alpha ≥ epsilon) or transparent (alpha < epsilon), but its intensity profile across the view is uniform regardless of alpha. ✓

**Change**: None required for the spatial profile. One nuance worth verifying:
- At alpha ≈ 0.5 the blur is half-transparent, so the underlying chatContent is half-visible through the blur. The user sees a half-blurred, half-sharp composite. Confirm against reference video whether this composite at the mid-fade frame matches the reference's blur intensity. If reference shows a STRONGER blur effect at mid-fade than alpha=0.5 produces, switch from alpha-driven to UIViewPropertyAnimator-driven `fractionComplete` on a paused animator that interpolates between `effect = nil` and `effect = UIBlurEffect(style: .systemMaterial)` — the effect itself ramps continuously rather than being overlaid at fractional opacity.

**Dependencies/Order**: Independent.

**Collateral**: The setIllegibilityFraction signature is read by `CV:436` (`applyIllegibilityBlur`) and by `CV:535` (`snapToChatRestChromeEndState` writes 0) and by `TC:1088` (handlePinchBegan resets to 0). If the impl switches from alpha to fractionComplete, those three call sites stay (semantics is preserved); only the implementation inside `setIllegibilityFraction` changes.

---

## 7. Two text layers, opposite alpha-vs-scale curves

**Spec**: Two simultaneously-resident content layers inside the single surface — body (scales with surface) and label (at OWN fixed readable size, doesn't scale). Cross-fade on opposite alpha-vs-scale curves. Level-of-detail swap.

**Current state (PARTIALLY PRESENT but with a body-doesn't-scale bug)**:
- CV has THREE distinct text representations:
  - `labelStack` (CV:52-59) = `dateLabel + topicSummaryLabel + todayLabel`, vertical stack pinned top-left of cell. Fades via `applyCellRestChromeAlphasFromScale` (CV:391-396) — alpha=1 at cell-rest, alpha=0 at chat-rest.
  - `chatRestCenterLabel` (CV:63-72) = centered day-marker label. Driven by `performMorphChromeTransition` (CV:543-588) via a CABasicAnimation that fades 0→1 over the K7 morph; reset to alpha=0 at cell-rest.
  - `chatContentContainer.header + bubbleStack + composer` (CCC:14-16) = the body. Driven by `applyChatContentScaleFade` (CV:404-409) via alpha=smoothstep(chatContentFadeBand, currentScale).
- Body sizing problem: chatContent is pinned to cell edges (CV:463-468). When the cell's heightConstraint extends (cell-rest → chat-rest), chatContent extends with it. But the bubbles inside the bubbleStack have their own intrinsic UIStackView layout — they don't UNIFORMLY scale, they just have more layout-height available at chat-rest so more bubbles fit. At cell-rest, fewer bubbles fit, and the ones that do show are at their original intrinsic size, not scaled down to fit. This is exactly the "the body should scale with the surface" violation.
- Label sizing: labelStack is anchored to cell.safeAreaLayoutGuide.topAnchor + leadingAnchor (CV:301-303). At cell-rest (cell.bounds.height = naturalHeight = 200pt), labelStack renders at natural readable font sizes (CV:22-50 — `Theme.Typography.destinationDate/destinationBody`). At chat-rest, labelStack is still at the same font sizes but pinned to the top of the now-much-larger cell.bounds — i.e., it's at fixed point size, NOT scaling with the cell. Then `applyCellRestChromeAlphasFromScale` fades it to alpha=0. ✓ correct mechanics for the label.

**Change**:
- KEEP labelStack as-is (correct already). Its label-fixed-size + alpha-curve-on-scale is exactly the spec's "label layer."
- KEEP chatRestCenterLabel as the chat-rest day-marker (separate from the body LOD-swap — it's a third element on the surface, like the keyboard hint at chat-rest).
- FIX the body: replace the current "chatContent stretches with cell.bounds" model with "chatContent's contents scale uniformly via a transform." Concretely: wrap `header + bubbleStack + composer` inside CCC in an inner content container (a new `bodyScaler: UIView`); apply `bodyScaler.layer.transform = CGAffineTransform(scaleX: s, y: s)` where `s = currentScale / chatRestScale` (normalized so s=1 at chat-rest, s=cellRestScale at cell-rest). The bodyScaler.bounds stays at chat-rest size (= cell.bounds at chat-rest = viewport-coterminous); the scale transform shrinks the visible rendering uniformly. The cell-content's bubbleStack lays out as if at chat-rest dimensions; the transform downscales for the cell-rest display.
- chatContent.alpha (already driven by `applyChatContentScaleFade`) keeps fading 1→0 toward cell-rest. The body is invisible by cell-rest. ✓ already correct.

**Dependencies/Order**: Requires #1 (single surface, so chatContent persists as the body layer of that surface, not the chatVC's separate body). **DEPENDS**: 1.

**Collateral**:
- `applyChatContentScaleFade` (CV:404-409) writes `chatContent.layer.transform = CATransform3DIdentity` (line 408). That write becomes wrong once the bodyScaler holds a non-identity transform; the line must be removed or redirected. Alternatively the transform write moves INTO the chatContent (writing bodyScaler.layer.transform = scale, and chatContent.layer.transform stays identity — which is what CV:408 already enforces, so the constraint stays valid).
- `ConversationStateController.scrollOffset` (CSC:22) is read/written by RC and CSC.bind — the scroll position is in the bubbleStack's scrollContentOffset (CCC.bubbleStack.scrollContentOffset). If bubbleStack is inside a scale-transformed wrapper, the scrollContentOffset is still in untransformed bubbleStack-local coordinates — fine, no change.
- `chatContentContainer.composer.composerTextField` first-responder behavior. Under transform, hit testing still routes touches through the transformed view correctly. UITextField + first responder are unaffected by the parent's transform. ✓
- The `illegibilityBlur` (CCC:18-24) is pinned to the ChatContentContainer edges (CCC:90-94), not to the bodyScaler. If we want the blur to overlay only the scaled body content (and NOT the (would-be) padding around it), the blur view should move inside the bodyScaler. Default placement (pinned to CCC edges) means the blur covers the full chat-rest viewport area regardless of scale — fine, since CCC.bounds = cell.bounds and the cell-bounds-as-chat-rest-size is constant after #2. Verify visually after #2+#7 land.

---

## 8. Corners pre-rounded on entry

**Spec**: Corner radius is constant at its theme value throughout — never animated from 0 to rounded. The corners enter the viewport already rounded.

**Current state (CORRECT)**:
- `CV:186` `layer.cornerRadius = Theme.Radius.card` set once at init.
- `CV:540` `layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: Theme.Radius.card).cgPath` rebuilt on layoutSubviews — uses the same constant.
- `CCC:58` `layer.cornerRadius = Theme.Radius.card` — also set once at init.
- `grep -rn "cornerRadius" DotPinchPrototype/` shows no animation key writing to cornerRadius. ✓

**Change**: None required.

**Dependencies/Order**: Independent.

**Collateral**: Adding any CABasicAnimation with keyPath `cornerRadius` would silently violate this. Worth a compile-time grep guard or a debug assertion. Low priority — no current site does this.

---

## 9. Edge = contrast boundary, not a stroke

**Spec**: The card's visible edge is the contrast boundary between fill and surrounding gradient. No `borderWidth`, no stroked path.

**Current state (CORRECT)**:
- `grep -rn "borderWidth" DotPinchPrototype/` returns nothing in production code.
- `CV:188` `backgroundColor = Theme.Cell.fill` — single uniform fill.
- Page gradient is implemented as a `CAGradientLayer` (pageGradientLayer at TC:240, 266) — a persistent sibling layer behind contentHost. The contrast comes from `Theme.Cell.fill` (a near-white) against the gradient bands (cool grey top, mauve pink bottom). ✓
- Cell.layer has shadow properties (CV:189-192) but those are `shadowOpacity=0` at chat-rest by default and gated by Track B (#4) — they're not the edge, they're a separate object-ness signal.

**Change**: None required.

**Dependencies/Order**: Independent.

**Collateral**: Persisting the pageGradientLayer as the visible "behind" of the contracting surface is correct. Verify after #2+#3 land that as the cell's transform shrinks, the gradient IS what appears around the contracted cell (not transparent black, not a debug color). Visual check post-#2.

---

## 10. Neighbors hidden during shrink, resolving in place at threshold

**Spec**: Neighbors are alpha=0 (or unrendered) during the entire shrink. They resolve in a 0.2–0.3s window at the legibility-event threshold, in the gap that opens above the contracting active cell.

**Current state (VIOLATED — progressive smoothstep, no gap-based resolution)**:
- `TC:745` `let neighborAlpha = 1 - smoothstep(0.30, 0.70, progress)` — neighbor alpha continuously fades from 1 (at progress=0, cell-rest) to 0 (at progress=1, chat-rest). Reversed direction works the same. The fade is proportional to gesture progress, not gated on a threshold event.
- `TC:748` `cell.alpha = isActive ? 1.0 : neighborAlpha` — every visible cell that isn't the active one gets this proportional alpha.
- `TC:761-779` `updateNeighborTranslations()` — neighbors translate `±growth/2` to follow the active cell's extension symmetrically around centerY. This is the followActive mechanic. Neighbors don't go off-screen; they stay laid out at their natural page positions but visually shifted to maintain spacing. So they're partially visible throughout the shrink.

**Change**:
- Replace the progressive smoothstep at TC:745 with a binary-ish state: `cell.alpha = 0` for all non-active cells whenever a pinch is in progress (or whenever activeCellIndex is non-nil AND the legibility event has not yet fired-and-reversed).
- When the legibility event fires (Track B starts, see #5), trigger a separate animator: neighbor cells animate `alpha 0 → 1` over ~0.25s, eased.
- The neighbors' POSITIONS at the moment they fade in must match where the active cell has landed. Concretely: the active cell's bounds are constant (per #2), but its rendered position via the transform-anchor at (0.4, 0.85) (per #3) determines the visible footprint. The natural-layout page positions of all cells stay as they are (TC's pageFrameForCell/accumulatedYs); neighbors fade in at those positions, no slide-in animation.

**Dependencies/Order**: Requires #2 (transform-based scale so the active cell's contraction defines a "gap" rather than just less heightConstraint), #3 (off-center anchor so the gap is asymmetrically above), #4/#5 (legibility event to gate the fade-in). **DEPENDS**: 2, 3, 4, 5.

**Collateral**:
- `updateNeighborTranslations` (TC:761-779) — under #2, the "growth" concept disappears. Either delete this function or repurpose: neighbors no longer follow-translate to maintain spacing because the active cell's bounds are constant; the spacing is preserved automatically by the page layout. Delete `cell.followActive(...)` (CV:511-515) and `cell.resetFollowTransform()` (CV:517-519) and their call sites.
- `currentCanvasProgress` (which feeds TC:745's smoothstep) — orphan after #2 if extensionFactor goes away. Either rewire to read `1.0 - cell.layer.transform.m11` or delete and replace with the on/off neighbor logic.
- Tests that check `neighborAlpha` over progress (WaveR32NeighborPositionTests, possibly others) will need rewriting.

---

## 11. Active cell commits to slot slightly before neighbors populate

**Spec**: ~100ms temporal lead. Active cell's bounds-contraction reaches its final slot first; then neighbors fade in.

**Current state (ABSENT)**:
- Under today's parallel-tracks model (#4 violated), there's no concept of "Track B completing" — the spring just settles into the new heightConstraint value, and neighbors are continuously fading the whole time. No temporal lead exists because there's no two-phase commit.

**Change**:
- Implement the lag via the neighbor fade-in's `delay` parameter. When Track B's scale animator engages, attach a completion observer at, e.g., the spring's `valueChanged` threshold (when the active cell's transform.scale crosses ~0.95 of its cell-rest target, i.e., the active cell is "essentially landed"). At that observation point, fire the neighbor-fade-in.
- Equivalent simpler approach: schedule neighbor fade-in at `+0.1s` after Track B start. Approximate but matches the 0.2-0.3s window cited from frames.
- Reverse direction (cell → chat via tap or pinch-back): neighbors fade OUT FIRST, then the active cell expands. (Mirrored — preserves the perceptual "lead.")

**Dependencies/Order**: **DEPENDS**: 10 (neighbor fade-in mechanic must exist), 5 (Track B trigger must exist).

**Collateral**:
- The `~100ms` figure is from the user's frame-by-frame analysis, not measured by me independently. Add to the measurement-task list: confirm the lead by extracting the active cell's bounds-completion-frame vs the neighbor's first-alpha-visible frame from `_frames/dot_pinch.mov` at native fps.

---

## 12. Round-trip state restoration

**Spec**: Body text, scroll position, composer state, typed-but-unsent text — all persist across the round-trip. Under the single-object architecture, persistence is automatic; no manual capture/restore needed.

**Current state (PARTIALLY PRESENT — works, but via manual two-object state transfer)**:
- `ConversationStateController` (CSC) holds `composerText`, `scrollOffset`, `composerIsFirstResponder`, `selectedTextRange` (CSC:21-24).
- `CSC.captureFromChatVC(_:)` (CSC:57-61) reads state out of chatVC at handoff.
- `CSC.bindToChatVCAtInstall(_:)` (CSC:68-72) seeds chatVC with state at install.
- `CSC.bind(to: chatContent:)` (CSC:42-47) writes state into chatContent at handoff.
- `CSC.applyToBoundChatContent()` (CSC:80-85) re-writes state on demand.
- V2R:179-188 `syncExistingChatContentIntoStateController` reads chatContent state INTO the controller before chatVC instantiation — because chatContent IS the persistent store; the controller is just a transit buffer.
- This whole machinery exists because of the two-object cross-dissolve (#1 violated). Under single-object architecture, the chatContent ALWAYS holds the state — no transfer needed.

**Change**:
- Under #1's resolution (eliminate ChatViewController + RevealCoordinator), `captureFromChatVC` and `bindToChatVCAtInstall` become orphans. Delete (CSC:57-72).
- `CSC.bind(to: chatContent:)` becomes the only setter — and is only called at first install (V2R's `installChatContentIfNeeded`). The cell.chatContentContainer instance carries the state across pinch round-trips naturally (it's the same UIView, in the cell's view tree, throughout).
- `ConversationStateController` may collapse to "key for state storage across pool LRU eviction" — when a cell is evicted from the keyed pool and chatContent is torn down, CSC retains composerText/scrollOffset so re-binding later restores them. That's its only remaining role.
- `V2R.syncExistingChatContentIntoStateController` (V2R:179-188) — orphan, delete.

**Dependencies/Order**: **DEPENDS**: 1.

**Collateral**:
- The chatVC's composerTextField first-responder state (currently transferred via `restoreFirstResponderIfNeeded` at RC:226-241) becomes a non-event because chatContent's composerTextField was the responder the whole time (no swap).
- Pool LRU eviction (`teardownChatContent` at CV:480-486, `teardownChatContentForMemoryPressure` at CV:491-496) — these tear down chatContent on memory pressure. State must be flushed to CSC BEFORE teardown so it survives. Current `unbind()` (CSC:49-55) likely already handles this — verify.

---

## 13. Cancel before threshold

**Spec**: If gesture is released before the legibility event crosses, spring back to chat-rest. Track B never fires. Body text returns to readable, blur reverses to 0, cell-bounds-as-surface stays at chat-rest dimensions.

**Current state (PARTIALLY PRESENT — origin-based commit decision works, but no "Track B never fires" guarantee because Track B doesn't exist as a separable concept)**:
- `TC:1166-1236` `handlePinchEnded` decides via `weightedFactor > commitThreshold` (TC:1183) where `commitThreshold = StageOrdering.illegibilityToeFull(chatRestScale:)` (TC:1176). If the user released before reaching the illegibility threshold, `commitToChatRest = false` → routes to `springToCellRest` (TC:1230-1235) OR `playPinchToCellsMorph` (TC:1228) depending on flag.
- BUT: `originatedFromCellRest = pinchState.initialExtension <= naturalH * 1.05` (TC:1203). If the user started AT cell-rest and didn't cross threshold, `commit = .cancelled` (TC:1212) and the spring brings them back to cell-rest (where they started).
- If the user started AT chat-rest (reverse pinch) and released before crossing — `originatedFromCellRest = false`, `commitToChatRest = false`, `commit = .cancelled` again — and `springToCellRest` runs, which would bring them to CELL-REST, NOT back to chat-rest. **This is wrong against the spec.**
- The bug: cancel-before-threshold from a chat-rest origin should spring back TO chat-rest. Current behavior springs to cell-rest.

**Change**:
- In `handlePinchEnded`, when `commit == .cancelled`, route based on origin:
  - Originated from cell-rest (tap-to-chat path partially in flight): spring back to cell-rest. (current behavior — correct.)
  - Originated from chat-rest (reverse pinch released before threshold): spring back to chat-rest. (current behavior is wrong.)
- TC:1208 currently classifies `commitToChatRest && !originatedFromCellRest` as `.cancelled`. That's the case where reverse-pinch crosses threshold but Track B-eligible path. The cancellation case is `!commitToChatRest && !originatedFromCellRest` — that's at TC:1211-1212 currently mapping to `.cancelled`. Behavior at TC:1230 (`springToCellRest`) is the bug.
- Fix: for the `commit == .cancelled && !originatedFromCellRest` case, route to `springToChatRest` (TC:1259-1264 already has the call shape — replicate here in handlePinchEnded).
- Under #4/#5, additionally: when cancel-before-threshold fires AND `legibilityEventFired == false`, abort any pending Track B animator engagement (since none was started, this is a no-op safety net).
- `handlePinchCancelled` (TC:1244-1266) already routes by origin correctly (TC:1252 / TC:1258) — confirm this stays right under the new architecture.

**Dependencies/Order**: **DEPENDS**: 1, 2, 5. Threshold is meaningful only after legibility-event is implemented.

**Collateral**:
- Velocity bias at TC:1180 (`velocityBias = (extensionVel / naturalH) * 0.15`) — under #2, `extensionVel` is no longer extension velocity; rename to `scaleVel` and rederive units.
- Tests that exercise commit-from-chat-rest paths (search Tests/V2 for `pinchToCells` and `.cancelled` cases) need rewriting for the corrected springToChatRest behavior.

---

## Open questions for you (decisions I need before implementation)

1. **Anchor measurement protocol**: do you have native-fps frame extraction tooling, or should I script it (ffmpeg + a corner-tracker) to extract anchor coordinates from `_frames/dot_pinch.mov`? Without measurement, (0.4, 0.85) stays provisional.

2. **Illegibility threshold blur fraction**: same question — do you want me to derive `illegibilityThreshold` empirically (rendering the implementation's bump curve at the scale value matching the frame where text becomes unreadable), or do you have a preferred starting value?

3. **`reverseCinematographyEnabled` flag** (TC:1226): currently a static toggle for whether reverse-pinch routes through MorphChoreographer or springs directly. Under the spec, do we still need MorphChoreography as a primitive at all? My read: the reverse direction is the mirror of forward (same single-surface contract, same legibility-gated handoff just running 1→0 in s), so MorphChoreographer becomes a dead path. Confirm we eliminate it.

4. **Existing tests**: the `WaveR*` test suites and `Phase0*` suites contain ~20+ tests that exercise heightConstraint-based behavior directly. Acceptable to mark them obsolete during the refactor and rewrite the invariant tests against the transform-based behavior? Or keep the old tests pinned-skipped and add a new test suite?

5. **The `pinchGlyph` and `chatRestAffordance`**: these are cell-state-only chrome (CV:78-89, 95-107). Under the new architecture they're still on the cell-the-surface, fading on the same Track B chrome curve as labelStack. Confirm — or are they redundant under the new model?
