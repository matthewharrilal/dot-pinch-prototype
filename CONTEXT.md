# CONTEXT.md — DotPinch glossary

Project-specific terms with precise definitions. This file is a glossary, not a spec — implementation details live in code; rationale lives in ADRs (when warranted).

## Phenomenology

**Continuous-Embodied Phenomenology** — DotPinch's organizing stance. The app presents one continuous world the user manipulates by direct gesture, rather than a tree of discrete screens the user navigates. Opposite of *Discontinuous-Spatial Phenomenology* (orthodox iOS default).

**Substrate** — Load-bearing architectural commitment, decided once at the architectural level. In DotPinch: the camera primitive (`contentHost.layer.sublayerTransform`), the master `CADisplayLink` (in `AnimationController`), the identity-keyed cell pool (`cellPoolByConversationID`), suppressed implicit animations (`CATransaction.withSuppressedActions`), additive `CABasicAnimation` composition, the perspective `m34 = -1/1000`. The substrate is what makes propagations possible — it is not, itself, anything the user directly sees.

**Propagation** — Surface decision that extends (or violates, or is neutral to) the substrate's commitment. A surface is *substrate-consistent* if its decision extends the commitment, *substrate-broken* if its decision violates the commitment despite the substrate being available, *substrate-neutral* if its decision is genuinely independent.

**Phenomenological accent** — A substrate-level commitment that answers one (or a few) of the six structural questions (space / time / identity / causation / world-extension / animation / role) with a non-default answer, applied consistently across the app. Distinct from a UI pattern or signature effect: an accent passes the substrate-commitment test, the dimensional-coherence test, and the experiential-signature test.

## Cell lifecycle states

**Cell-rest** — Cell at its natural height (`CellLayoutTuning.naturalCellHeight = 200pt`) in its cell-list slot. Cell-rest chrome is visible: `labelStack` (date + summary + today marker) and `pinchGlyph` (the outward-arrows expand affordance, SF symbol `arrow.up.left.and.arrow.down.right`).

**Chat-rest** — Cell extended to viewport height (`heightConstraint.constant = naturalHeight * chatRestFactor` where `chatRestFactor = viewport.height / naturalHeight`). At chat-rest, the cell occupies the viewport edge-to-edge (horizontal inset = 0). Cell-rest chrome is alpha 0; `chatRestCenterLabel` (the day-marker header) is alpha 1.

**Active cell** — The cell currently being interacted with (gesture target). Identified by `activeCellIndex`. Set on gesture `.began`; cleared when camera settles at cell-rest. Active cell receives hit-test priority and is brought to front via `contentHost.bringSubviewToFront`.

## Gesture commits

**`.tapToChat`** — Forward commit. Tap-from-cell-rest OR pinch-out-from-cell-rest that crosses the commitment threshold. Runs `playTapToChatMorph` (cane curve: windup + zoom + lift + centering, additive CABasicAnimations) to chat-rest geometry, then fires `onMorphRevealReady`.

**`.pinchToCells`** — Reverse commit. Pinch-in-from-chat-rest that falls below the commitment threshold. Currently runs `springToCellRest` to return the cell to cell-rest geometry. NOTE: as of 2026-05-24, this commit branch is wired in `handlePinchEnded` (line 1141) but is unreachable in practice because chat-state presents `ChatViewController` over the canvas with `canvas.alpha = 0`, blocking the canvas pinch recognizer from receiving touches.

**`.cancelled`** — Involuntary cancellation (Control Center swipe, incoming call, etc.). Distinct from `.ended` so the commit-or-bail decision does NOT run on involuntary cancellation. Restores to whichever rest the gesture originated from with zero velocity.

## Identity

**Conversation** — The data entity. Has a stable `UUID` and a list of messages. Lives in `ConversationStore`.

**Cell identity** — Currently *type-keyed at dequeue but data-keyed at re-attach.* Cells in `cellPool` are anonymous (any cell can host any conversation), but cells that previously hosted a specific `UUID` are preferentially re-attached via `cellPoolByConversationID` keyed lookup. LRU-bounded at `maxKeyedPoolSize = 20`. This is the propagation of the substrate's identity-persistence commitment to the cell layer.

## Animation choreography

**Cane curve** — The forward (tap-to-chat) morph trajectory. Composed of four additive CABasicAnimations on `contentHost.layer.transform`: `windupScale` (brief inward scale, "compression before zoom"), `zoomScale` (main scale to chat-rest), `windupTranslate` (vertical lift), `morphCentering` (camera-equivalent translation to center the active cell). All on `additive: true`, fillMode `.forwards`, `isRemovedOnCompletion = false`. Cell-internal chrome (`labelStack`, `pinchGlyph`, `chatRestCenterLabel`) crossfades synchronously via `performMorphChromeTransition`.

**Phase-locked motion** — Multiple visible cells move simultaneously in lockstep because they share one parent transform (`contentHost.layer.sublayerTransform`, plus contentHost.layer.transform during cane-curve). Coherence is structural (mathematical), not procedural (per-cell timing).

## TODO terms (not yet resolved)

- **ChatBody** — currently `ChatViewController` (separate VC, sibling of canvas). Pending decision on hosting strategy: subview of CellView vs. sibling of contentHost vs. child-VC-in-cell vs. keep current with touch-routing fix.
- **Reverse-direction affordance** — currently no inward-arrows symbol exists in code. Pending decision on whether to add one or repurpose existing.
