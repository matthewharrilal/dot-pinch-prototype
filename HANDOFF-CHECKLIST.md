# HANDOFF-CHECKLIST.md — Pinch-to-Cells via Parallel Layout + Atomic Handoff

**Single source of truth for the pinch-to-cells (chat → cell) implementation under the handoff architecture.** Live document — update inline as decisions evolve and items complete. Drop in code references with `file:line` when sections deepen.

**Date opened:** 2026-05-25

**Approach in one sentence:** Keep `ChatViewController` for the forward path (preserves the validated cane-curve cinematography and reveal cross-fade exactly as today); pre-warm `cell.chatContent` in parallel inside the cell from T=1.6s; during the canvas-alpha-0 window (T=2.10s → T=2.8s) normalize the canvas to chat-rest geometry invisibly; at T=2.8s when the blur curtain finishes lifting, perform a one-frame invisible handoff (chatVC.alpha 1→0, canvas.alpha 0→1, cell.chatContent.alpha 0→1 inside a single CATransaction with state transferred just before); reverse direction (pinch from chat-rest) then works natively against cell-as-chat with no additional plumbing because the substrate (`pinchRecognizer`, `setCamera`, `heightConstraint`, `springToCellRest`) is already in place.

**What this document is NOT:** A spec for the chat-rest visual design, a refactor of MorphChoreographer's cane curve, a redesign of RevealCoordinator's blur choreography, or a test plan. It is the implementation plan for exactly one thing: making reverse direction work without changing the forward path's appearance.

**Sections (table of contents):**

- §0 — Executive synthesis (the load-bearing decisions, the rationale, the alternatives rejected)
- §1 — Architecture & view hierarchy (where chat content lives, who owns ChatVC's lifecycle, the state controller pattern)
- §2 — Forward-path mechanics (per-millisecond timing windows: parallel layout @ T=1.6s, normalize during canvas.alpha=0, atomic swap @ T=2.8s)
- §3 — Safe area & layout matching (cross-view constraints, the sublayerTransform divergence, theme color unification)
- §4 — State transfer (contentOffset, composer text, first responder, selection range, decisions on continuous vs at-handoff)
- §5 — Identity preservation (cell.chatContent persists with cell across pool LRU; ChatVC release vs cache decision)
- §6 — Reverse direction wiring (`pinchRecognizer.isEnabled` re-enable, `setCamera` extensions, `springToCellRest` from heightConstraint=844)
- §7 — Edge cases (scene deactivation mid-handoff, Reduce Motion, conversation deletion, rotation, memory pressure)
- §8 — Performance & resource (double-layout cost @ T=1.6s, memory peak, long-conversation handling)
- §9 — Animation coexistence (CATransaction discipline, setCamera vs cane curve mutual exclusion, additive animation cleanup)
- §10 — Substrate participation (sublayerTransform inheritance, master CADisplayLink, identity-keyed pool semantics)
- §11 — Code organization (new files, modified files, layer assignments per `CLAUDE.md` 9S contract)
- §12 — Implementation phases (sequenced work plan with dependencies)
- §13 — Risk register (probabilities, impacts, mitigations)
- §14 — Decision log (running record of architectural decisions and their rationale)
- §15 — Implementation status
- §16 — Codebase verification findings (Wave-2 retrofit, 2026-05-25) — empirical facts that updated §0-§13
- §17 — Open questions for Phase 0 (must verify empirically before structural code)
- §18 — Long-term enablement (what the handoff unlocks beyond pinch-back)

**Cross-doc references this checklist relies on:**
- `CLAUDE.md` parts 2.1-2.7 (operational patterns, especially 2.1 animation discipline, 2.3 cells, 2.5 state)
- `CLAUDE.md` Part 4 (architectural keystones — none of them are violated by this work)
- `CONTEXT.md` (cell-rest / chat-rest / cane curve / `.pinchToCells` definitions)
- `REFACTOR-CHECKLIST.md` (the existing refactor SSoT — this work runs orthogonal to that)

---

## §A — MAXIMUM AGENT TEAM TOPOLOGY (foundation, threaded throughout)

**Execution model:** this SSoT is a multi-agent dispatch artifact. The migration executes across **22 specialized agent roles** working in **layer-partitioned parallelism**. Every task carries an **Agent Ensemble** assignment. Every phase carries a **Wave Topology DAG**. Every wave-close carries a **retrospective + merge-gate** with structured checklist + parallel audit-agent dispatch + full /root-cause-tracing. Single-engineer 23-35 day estimate collapses to **9-13 wall-clock days with a 4-agent fleet** along the critical path.

**Binding:** §A is the index. The TOPOLOGY itself lives interwoven in (a) per-task Agent Ensemble lines, (b) per-phase Wave Topology DAGs in each phase intro, (c) per-wave Retrospective + Merge Gate blocks at each wave-close, (d) RCT-on-load-bearing-decisions protocol invoked at every retro. §A is the lookup; the substance is everywhere downstream.

### §A.1 — Agent roster (22 specialized roles with letter shorthand)

Hybrid schema (per user direction): named roles for clarity + letter shorthand for tagging. Tasks reference roles via shorthand (e.g., `[SE, CQR, RCT]`). Each role has a one-line role-card defining its primary concern + secondary concerns + when it dispatches.

**Implementer roles (write code):**

| Role | Tag | Primary concern | Layer |
|---|---|---|---|
| SubstrateEngineer | **SE** | Camera/sublayerTransform/AnimationController/m34 — anything touching `Animation/` or load-bearing keystones | L1 substrate |
| GestureMechanic | **GM** | Pinch/pan handlers, recognizer state machines, gesture velocity transfer | L3 |
| ChoreographyComposer | **CC** | MorphChoreographer, animateCameraToChatRest, playTapToChatMorph, sin-bell arcs, cane curves | L4 |
| RevealOrchestrator | **RO** | RevealCoordinator, blur sequencing, crossFade, handoff orchestration, HandoffPhase | L4 |
| ChromeArtist | **CA** | CellView chrome (labelStack/pinchGlyph/chatRestCenterLabel/chatRestAffordance), per-progress alpha curves | L3 |
| ContentComposer | **CO** | ChatContentContainer + ChatHeaderView + ChatBubbleStackView + ChatComposerView, cross-view constraints | L3 |
| StateMechanic | **SM** | ConversationStateController, TransientStateSnapshot, capture/apply seam | L3 |
| CompositionRoot | **CR** | V2RootViewController orchestration, observers, scene lifecycle, dependency injection | L5 |
| TokenScribe | **TS** | DesignSystem tokens (AlphaCurve, MorphTiming, RevealTiming, Theme), magic-number extraction | L2 |
| LayoutEngineer | **LE** | Auto Layout constraint composition, safe area engineering, cross-view constraints | L3 |
| LifecycleSurgeon | **LS** | View lifecycle, pool round-trip integrity, memory pressure response | L3-L5 |

**Reviewer roles (audit code):**

| Role | Tag | Primary concern |
|---|---|---|
| CodeQualityReviewer | **CQR** | Tier-3B+ pillar compliance scan; P1-P20 enforcement; nit catalog P18.x |
| RootCauseTracer | **RCT** | /root-cause-tracing on every load-bearing decision; deletion test; hidden coupling; absent-connection analysis |
| SubstrateAuditor | **SA** | CLAUDE.md Part 4 keystone integrity; phenomenology consistency per Part 3; substrate-vs-propagation classification |
| DeadCodeHunter | **DCH** | Unused exports, unreachable branches, vestigial properties, anticipation artifacts; verifies P3.3 deletion test |
| IntegrationVerifier | **IV** | Cross-file integration completeness; every new method has a caller; every new property has a writer + reader; greppability per P3.8 |
| ConcurrencyAuditor | **CA-conc** | 9S concurrency contract; @MainActor / Sendable / nonisolated correctness; closure capture lists |
| VisualRegressor | **VR** | Screen recordings before/after; pixel-diff at key T-times; phenomenological match against user reference frames |
| BuildValidator | **BV** | xcodebuild green; InvariantHardeningTests pass; no constraint warnings; no autolayout deadlocks |
| PerfProfiler | **PP** | Instruments runs; layout cost; memory peak; FPS during animations; long-conversation stress tests |
| EmpiricalRunner | **ER** | Phase 0 questions Q1-Q12; recording answers in §14; documenting findings in §16 |

**Synthesizer role (only one):**

| Role | Tag | Primary concern |
|---|---|---|
| WaveCoordinator | **WC** | Wave dispatch, parallelism scheduling, merge-gate decisions, retro orchestration. Reads audit-agent outputs and either opens the merge gate or sends work back. |

### §A.2 — Wave Topology DAG notation

Each phase intro carries a DAG showing wave decomposition + parallelism + merge gate. Notation:

```
PHASE N
│
├─→ Wave N.1 ─────╮
├─→ Wave N.2 ─────┼─→ [WC Merge Gate N] ─→ Phase N complete
└─→ Wave N.3 ─────╯
        │
        └─→ depends-on edge: Wave N.2 ⇒ Wave N.4
```

- **Parallel waves:** horizontal branches converging at merge gate.
- **Sequential waves:** vertical chain with ⇒ edges.
- **Merge gate:** named `[WC Merge Gate N]` — opens when ALL waves' retros report GREEN.
- **Edges (⇒):** explicit dependency. Wave N.4 cannot start until Wave N.2 completes.

### §A.3 — Per-task Agent Ensemble syntax

Every task that adds/changes code declares its ensemble inline:

```
- [ ] **<TaskID>** <Description>
  - **Agent ensemble:** [Implementers] | [Reviewers] | [Synthesizer]
  - **Pillar compliance:** ...
```

Example: `**Agent ensemble:** [SE, CC] | [CQR, RCT, SA, DCH, IV] | [WC]`

Convention: implementers separated by `,`; reviewer pipeline same; the synthesizer (always `WC`) closes the ensemble. A reviewer-only task (e.g., a documentation audit) has `[—] | [reviewers] | [WC]`.

### §A.4 — Per-wave Retrospective + Merge Gate protocol

Every wave-close runs through a SIX-STEP retrospective. The wave does not merge until all six steps report GREEN.

**Step 1 — Structured exit checklist** (cliffs-notes per wave; concrete items per the wave's scope):
- Build green (`xcodebuild` per CLAUDE.md Part 5)
- Tests pass (`InvariantHardeningTests` + new tests)
- Pillar review sub-gate ✓ (per §39 / per phase exit pillar list)
- No new constraint warnings
- No new console errors / Sendable warnings / Auto Layout assertions

**Step 2 — Parallel audit-agent dispatch** (3-5 agents simultaneously in background):
- `CQR` — Tier-3B+ pillar scan; report violations by pillar ID
- `RCT` — full /root-cause-tracing on every load-bearing decision in the wave's diff (per §A.5 protocol)
- `SA` — substrate / keystone integrity check; phenomenology consistency
- `DCH` — dead-code scan; verify every new symbol has at least one consumer
- `IV` — integration completeness; every new method called, every new property read AND written somewhere

**Step 3 — RCT-on-load-bearing-decisions** (per §A.5)

**Step 4 — Visual / empirical verification** (only if wave touches user-visible behavior):
- `VR` — screen recording, frame-by-frame compare against reference / previous baseline
- `PP` — Instruments scan if performance-sensitive

**Step 5 — Merge gate decision** (WC):
- If all audits GREEN: open merge gate; wave commits; phase progresses to next wave or merge to phase-exit
- If any audit FLAGS: dispatch fix tasks back to relevant Implementers; re-run audits; loop

**Step 6 — Decision-log update**:
- §14 entry per merge-gate decision (resolved + lessons learned + any decisions deferred)

### §A.5 — RCT-on-load-bearing-decisions protocol

Per user direction: "Full RCT on every load-bearing decision in the wave's diff." Procedure:

1. **Enumerate load-bearing decisions** in the wave's diff. A decision is load-bearing if:
   - It introduces a new keystone-relevant property/method (touches CLAUDE.md Part 4 list)
   - It makes a structural choice that >1 future task depends on
   - It encodes an invariant (precondition / assertion / contract)
   - It crosses a layer boundary (per 9S contract)
   - It chooses between phenomenologically-distinct alternatives

2. **For each load-bearing decision, dispatch an RCT branch agent** running the six-question framework (per ~/.claude/skills/root-cause-tracing):
   - Q1 What does this rest on?
   - Q2 Why does this exist?
   - Q3 What assumptions does this encode?
   - Q4 What would happen if this changed?
   - Q5 What would happen if this were removed?
   - Q6 What's absent?

3. **Recursive descent:** if RCT finds HOT branches, dispatch sub-agents (per RCT skill's parallel topology). Branch traces continue until each branch terminates at BEDROCK / CRITICAL FINDING / FRONTIER / CYCLE.

4. **Wave's RCT closure file** (`§14 / D-RCT-Wave-N.M`): summary of every load-bearing decision traced + classifications (LOAD-BEARING / KEYSTONE / DECORATIVE / PHANTOM).

5. **Wave does not close** until the RCT closure file is committed.

### §A.6 — Audit-agent dispatch templates (copyable)

Each retro's parallel audit dispatch uses these templates. WaveCoordinator dispatches all in one message via multiple Agent tool calls (per `run_in_background: true` parallelism per RCT skill protocol).

**Template: CodeQualityReviewer (CQR)**
```
Description: "Pillar audit Wave N.M"
Prompt: "Audit the diff of Wave N.M against the 20 Tier-3B+ pillars. Specifically scan for:
P1.1 guard-chain violations (sequential single-bind guards)
P1.2 setupX helpers (forbidden — should be closure-init at class top)
P2.11 magic numbers (numeric literals outside tokens)
P5.1 missing private (every property defaulting wider than needed)
P6.7 silent guard-returns without WHY comment
P11.1 SRP violations (methods >50 LOC OR multiple concerns in one method)
P13.4 method length >50 LOC
P18.14 closures without [weak self]
P19.3 idempotency violations (apply* methods that aren't idempotent)
Report findings as pillar-ID + file:line + suggested fix. Return PASS or FAIL summary."
Background: true
```

**Template: RootCauseTracer (RCT)**
```
Description: "RCT Wave N.M load-bearing decisions"
Prompt: "Apply /root-cause-tracing six-question framework to every load-bearing decision in Wave N.M's diff. Enumerate decisions first (per §A.5 step 1 criteria), then trace each to BEDROCK / CRITICAL / FRONTIER / CYCLE. Dispatch HOT-branch sub-agents per RCT skill protocol. Report:
- Decisions enumerated: N
- Decisions classified LOAD-BEARING: M
- Decisions classified KEYSTONE: K
- Decisions found PHANTOM (already effectively removed): P
- Critical findings: list
- Hot branches dispatched: list
Return RCT closure file content as §14 / D-RCT-Wave-N.M entry."
Background: true
```

**Template: SubstrateAuditor (SA)**
```
Description: "Substrate audit Wave N.M"
Prompt: "Audit Wave N.M's diff against CLAUDE.md Part 4 keystones + Part 3 phenomenology test:
- contentHost.layer.sublayerTransform untouched?
- canvas.layer.sublayerTransform.m34 = -1/1000 untouched?
- AnimationController's single CADisplayLink not parallelized?
- cellPoolByConversationID identity preserved?
- CATransaction.withSuppressedActions discipline universal?
- EngagementState.engaged(completion:) carrying closure untouched?
- 4 additive CABasicAnimations in animateCameraToChatRest untouched?
- MorphChoreographer's sin-bell Y/Z arc untouched?
- Substrate-vs-propagation: does each new surface decision EXTEND the commitment, VIOLATE it, or stay NEUTRAL?
Report any keystone violations + any new surface decisions with their classification. Return PASS or FAIL."
Background: true
```

**Template: DeadCodeHunter (DCH)**
```
Description: "Dead-code scan Wave N.M"
Prompt: "Scan Wave N.M's diff for dead code:
- New symbols (properties, methods, types) with ZERO consumers
- New parameters never read
- Vestigial properties left from anticipation
- Branches unreachable per static analysis
- Generic parameters with one instantiation (per P2.5 speculative generality)
- Protocol with one conformer (per P2.5)
Use P3.3 deletion test on each candidate: if removing breaks nothing, it's dead. Report dead candidates with file:line + suggested action (delete / inline / fold). Return PASS or FAIL."
Background: true
```

**Template: IntegrationVerifier (IV)**
```
Description: "Integration completeness Wave N.M"
Prompt: "Verify Wave N.M's diff for cross-file integration:
- Every new public/internal method has at least one call site
- Every new property has both a write site AND a read site
- Every new file is referenced by xcodegen project + appears in built target
- grep verifies P3.8 (every symbol greppable; no string-concat dispatch)
- Every new constraint is activated somewhere
- Every new closure has its lifetime contract clear
Report unintegrated items (symbol + file:line + missing-integration kind). Return PASS or FAIL."
Background: true
```

### §A.7 — Critical path estimate with 4-agent fleet

With waves running in parallel where independent, total wall-clock work shrinks:

| Phase | Single-engineer | 4-agent fleet | Compression |
|---|---|---|---|
| P0 — Verification | 2-3 d | 1-2 d (ER || other empirical) | 50% |
| P1 — Components | 2-3 d | 1 d (4 components in parallel via CO ensembles) | 65% |
| P2 — StateController | 1-2 d | 1 d | 50% |
| P3 — CellView | 2 d | 1 d (CA + SM + CC parallel) | 50% |
| P4 — Parallel layout wiring | 1-2 d | 1 d | 50% |
| P5 — Normalize | 2 d | 1 d (SE + RO + CC parallel) | 50% |
| P6 — Handoff | 3 d | 1.5 d (RO + SM + GM parallel within 4 waves) | 50% |
| P7 — Reverse | 3 d | 1.5 d | 50% |
| P8 — Edge cases | 4-5 d | 2 d | 55% |
| P9 — Affordance | 1-2 d | 0.5 d | 67% |
| P10 — Distance-fade | 3-5 d | 1.5 d (SE + CO empirical Z calibration parallel with curve replacement) | 60% |
| **TOTAL** | **23-35 d** | **9-13 d** | ~60% |

P11/P12 GATED on user direction; not in critical path.

### §A.8 — Wave-coordination invariants (WC's responsibilities)

The single WaveCoordinator role enforces these across all waves:

1. **No two waves write the same file simultaneously.** Conflict-avoidance via WC's pre-dispatch read of the file-change manifest.
2. **Every wave's diff is reviewable as a single PR-equivalent.** If a wave needs >300 LOC across >5 files, decompose into sub-waves.
3. **Merge gates open atomically.** All audit-agent reports must arrive before WC decides. WC does NOT short-circuit on partial GREEN.
4. **Failed audits trigger fix tasks back to Implementers.** WC schedules retries; never silently passes.
5. **Decision log entries are mandatory per merge gate.** Including PASS gates (positive log builds institutional memory).

---


### §0.1 The problem in one paragraph

Currently `RevealCoordinator.dismiss()` is dead code: it is defined at `RevealCoordinator.swift:106-133` but has zero callers. The reverse-direction commit branch `.pinchToCells` is wired in `TimelineCanvas.handlePinchEnded` (around line 1141) but is structurally unreachable because once forward reveal completes, `ChatViewController.view` sits over the canvas with `isUserInteractionEnabled = true` and `canvas.alpha = 0`, swallowing every touch before the canvas's pinch recognizer can see it. Even if we routed touches through, the canvas state at the end of forward reveal is incoherent: `contentHost.layer.transform` is held at `scale ≈ 4.92` (the cane curve's final additive value), `cell.heightConstraint.constant` is still `200pt` (the cane curve never extended it because the tap path uses scale-only, not heightConstraint extension), and four CABasicAnimations remain attached to `contentHost.layer` with `isRemovedOnCompletion = false`. The handoff approach addresses both problems together: it dismisses ChatVC, normalizes the canvas to the geometry the reverse path actually expects (`transform = identity`, `heightConstraint = bounds.height`), and does so during a window where the user perceives no change.

### §0.2 The two forward paths and which one this checklist concerns

DotPinch has **two distinct forward paths** that produce visually similar end-states but use entirely different mechanisms. They must not be conflated:

- **Tap path** (`animateCameraToChatRest` in `TimelineCanvas`, called by `playTapToChat`): four additive `CABasicAnimation`s on `contentHost.layer.transform` — `windupScale`, `zoomScale`, `windupTranslate`, `morphCentering`. Duration 1.5s. `heightConstraint` is NOT touched. Cell-rest chrome fades out via `performMorphChromeTransition`. At T=1.6s, `RevealCoordinator.present` is called, which begins the blur-curtain + cross-fade reveal that ends at T=2.8s with the chat surface visible.
- **Pinch-commit path** (`playTapToChatMorph` via `MorphChoreographer`): drives `cell.heightConstraint` from `naturalH (200)` to `naturalH × chatRestFactor` (~844) over `MorphTokens.totalMorphDuration = 1.5s`, with a sin-bell Y/Z arc. Uses the master `CADisplayLink` via the AnimationController. `contentHost.layer.transform` stays at identity. Cell-rest chrome fades via `setCamera`-driven alpha curves on each tick.

**This checklist is concerned exclusively with the TAP PATH plus the post-T=2.8s state.** The pinch-commit path already produces a clean chat-rest geometry (heightConstraint=844, transform=identity, no held animations) because it operates on `heightConstraint` directly via the master display link rather than on `contentHost.layer.transform` via held additive animations. The handoff approach is needed because the tap path leaves the canvas in a state the reverse direction cannot consume, AND because forward via tap currently presents `ChatViewController` (an entirely separate view tree) rather than transforming the cell itself.

### §0.3 The three architectural options that were considered

Each option was evaluated against four criteria: (a) preserves forward visual identity exactly, (b) enables reverse direction natively, (c) avoids two-view sync math during gesture, (d) substrate participation (the cell receives `sublayerTransform`, master display link, identity-keyed pool, m34 perspective).

**Option A — Procedural coordinator with ChatVC outside canvas (today's structure, just wire reverse).**
- (a) Yes — forward is unchanged.
- (b) No — `chatVC.view` sibling of canvas absorbs touches; reverse cannot engage without routing touches through, AND there is no cell to shrink at end-of-reverse because the cell-list is hidden under `canvas.alpha = 0`.
- (c) No — requires synchronizing chatVC.view's frame with a hidden cell's frame during reverse, with aspect-ratio mismatches.
- (d) No — chatVC is outside the canvas, gets nothing from the substrate.
- **Rejected.** Coordinator complexity is unbounded once you start handling aspect-ratio mismatch, edge masks, end-of-reverse dissolve, and the fact that the cell list state at reverse-completion is undefined.

**Option B — Eliminate ChatVC entirely (Cell-as-Conversation, snap behind blur).**
- (a) Risk — the forward path would have to drive cell.heightConstraint and contentHost.transform simultaneously OR snap behind the blur curtain. The snap-behind-blur sub-option is plausible because the blur is opaque from T~1.9s onward and a one-frame snap inside that opaque window is below perceptual integration. But the engineering required to replace `ChatViewController` with cell-internal layout is substantial.
- (b) Yes — cell becomes the chat surface natively; pinch on cell engages reverse instantly.
- (c) Yes — single source of truth, single view.
- (d) Yes — full substrate participation.
- **Deferred.** This is the architecturally cleanest option and the one `arch-lens-check` recommended, but it requires a larger forward-path rewrite. We keep it on the table as the next iteration if the handoff approach proves brittle in production.

**Option C — Handoff approach (this checklist).**
- (a) Yes — forward path is entirely unchanged; cane curve, chrome fades, blur curtain, cross-fade all fire as today. The only new work happens behind alpha=0 or behind the opaque blur.
- (b) Yes — after handoff at T=2.8s, the cell IS the chat. `pinchRecognizer` on canvas reaches the cell. `handlePinchBegan` → `handlePinchChanged` → `setCamera`-driven alpha curves → `handlePinchEnded` with `.pinchToCells` commit → `springToCellRest` already exist and work.
- (c) Partially — there is a 1.2-second window (T=1.6s to T=2.8s) where both `chatVC.view` and `cell.chatContent` exist in parallel. State synchronization across that window is the load-bearing risk. Mitigated because the window is brief and the user cannot interact with the cell (canvas.alpha=0 from T=2.10s).
- (d) Yes — cell.chatContent is a subview of cell which is a subview of contentHost. Substrate participation is automatic via the view hierarchy.
- **Chosen.** Best trade-off between forward-visual safety and engineering scope. Reversible if it proves brittle (we can later collapse to Option B).

### §0.4 What "handoff" means precisely

The handoff is the operation at T=2.8s (blur curtain fully lifted) that swaps the visible representation of the conversation from `chatVC.view` to `cell.chatContent`. It has four parts, all executed inside ONE `CATransaction.withSuppressedActions`:

1. **State capture from chatVC** (synchronous reads):
   - `let scrollOffset = chatVC.scrollView.contentOffset`
   - `let composerText = chatVC.composerTextField.text ?? ""`
   - `let composerWasFirstResponder = chatVC.composerTextField.isFirstResponder`
   - `let selectedRange = chatVC.composerTextField.selectedTextRange`

2. **State apply to cell.chatContent** (synchronous writes, inside suppressed CATransaction so no implicit animations fire):
   - `cell.chatContent.scrollView.contentOffset = scrollOffset`
   - `cell.chatContent.composerTextField.text = composerText`
   - (becomeFirstResponder is deferred until after the alpha swap completes, see step 4)

3. **Atomic alpha swap** (inside same suppressed CATransaction):
   - `chatVC.view.alpha = 0`
   - `chatVC.view.isUserInteractionEnabled = false`
   - `canvas.alpha = 1`
   - `cell.chatContent.alpha = 1`
   - `canvas.pinchRecognizer.isEnabled = true`

4. **Post-transaction cleanup** (after the CATransaction commit):
   - If `composerWasFirstResponder`: `cell.chatContent.composerTextField.becomeFirstResponder()` and apply `selectedTextRange`
   - `chatVC.willMove(toParent: nil)`
   - `chatVC.view.removeFromSuperview()`
   - `chatVC.removeFromParent()`
   - `revealCoordinator` releases its `chatViewController` reference (or caches it, see §1.4)
   - `blur.detach()` (existing behavior)

The user perceives no change because:
- The visible position of chatVC's text matches the visible position of cell.chatContent's text (achieved by safe area constraints, §3)
- The background colors match (`Theme.Page.surface` on chatVC; we set the same on cell.chatContent, §3.4)
- The scroll position, composer text, and first responder state are preserved (steps 1, 2, 4 above)
- The alpha swap is atomic within one CATransaction (no intermediate frame where both are visible or neither is visible)

### §0.5 What "normalize" means and why it must happen BEFORE the handoff

After the cane curve completes at T=1.5s, the canvas is in this state:
- `contentHost.layer.transform = CATransform3DConcat(windupScale_final, zoomScale_final, windupTranslate_final, morphCentering_final) ≈ scale 4.92, translate Y ≈ 0, translate X ≈ 0`
- Four CABasicAnimations attached to `contentHost.layer` with `isRemovedOnCompletion = false`
- `cell.heightConstraint.constant = 200` (naturalH; the tap path never touched it)
- `cell.chatRestCenterLabel.layer` has one CABasicAnimation (`centerLabelOpacity`) similarly held
- `cell.chatRestCenterLabel.transform = .identity` (model layer); presentation layer reflects the final centerLabelOpacity value
- `activeCellIndex` is set
- `canvas.pinchRecognizer.isEnabled = false` (set in animateCameraToChatRest)

This state is INCOMPATIBLE with the reverse direction because:
- `handlePinchChanged` (around `TimelineCanvas:1056`) writes `cell.heightConstraint.constant` and expects `contentHost.layer.transform` to be at identity (no compound scale). With `transform.scale = 4.92` and `heightConstraint.constant = 200`, the cell would appear as a tiny rectangle scaled 5x by contentHost — bizarre visually.
- `setCamera` computes progress as `(heightConstraint - naturalH) / (chatRestExtension - naturalH)`. From `heightConstraint = 200`, progress = 0 — but visually the cell should be at progress = 1 (chat-rest). The alpha curves (labelStack, pinchGlyph, chatRestCenterLabel, chatContent) would fire in the wrong direction.
- The four held additive animations on contentHost.layer would compound with any new transform writes. Setting `contentHost.layer.transform = identity` would conflict with the held animations' final values.

Normalize must therefore:
1. Remove the four held cane-curve animations from `contentHost.layer`
2. Set `contentHost.layer.transform = CATransform3DIdentity`
3. Remove the held `centerLabelOpacity` animation from `cell.chatRestCenterLabel.layer`
4. Set `cell.chatRestCenterLabel.transform = .identity` (already identity; but defensive)
5. Set `cell.chatRestCenterLabel.alpha = 0` (cell.chatContent shows its own header; chatRestCenterLabel is no longer needed at chat-rest)
6. Set `cell.heightConstraint.constant = canvas.bounds.height` (chat-rest extension; on iPhone 16 = 844)
7. Force `contentHost.layoutIfNeeded()`

All seven steps must run while `canvas.alpha = 0` so they are invisible. The window `canvas.alpha = 0` opens at T=2.10s (the cross-fade animation flips canvas.alpha to 0) and closes at T=2.8s (the handoff flips canvas.alpha back to 1). That is the 700ms window normalize runs in.

### §0.6 What changes vs. what stays the same

**Stays the same (must NOT be touched):**
- `MorphChoreographer` (pinch-commit path is unchanged)
- `animateCameraToChatRest` cane curve composition (`windupScale`, `zoomScale`, `windupTranslate`, `morphCentering`)
- `performMorphChromeTransition` chrome fades
- `RevealCoordinator.present` blur-fade-in / cross-fade / blur-fade-out timing
- `RevealBlurOverlay` (`UIVisualEffectView` with `.systemMaterial`)
- `ChatViewController` internal layout
- `Theme.Page.surface`, `Theme.Cell.fill`, `Theme.Typography.*`
- `cellPoolByConversationID` LRU bound (20)
- `handlePinchBegan`, `handlePinchChanged`, `handlePinchEnded` (they already handle chat-rest origin correctly via `initialExtension` capture)
- `springToCellRest` (already targets naturalH with critically damped spring)
- `tryClearActiveCellAtRest` (already clears `activeCellIndex` and re-enables `panRecognizer`)
- The `m34 = -1/1000` keystone (untouched)

**Adds (new code):**
- `ChatContentContainer` (or composed `ChatHeaderView` + `ChatBubbleStackView` + `ChatComposerView`) — UIView subclasses that mirror ChatViewController's subviews
- `ConversationStateController` — NSObject holding transient state (composer text, scroll offset, first responder flag) decoupled from any view
- `CellView.chatContentContainer: ChatContentContainer?` property
- `CellView.installChatContentIfNeeded(conversation:, parentVC:, stateController:)` method
- `TimelineCanvas.normalizeToChatRest(activeCellIndex:)` method
- Extensions to `CellView.setCamera` for `chatContent.alpha` and `chatRestCenterLabel.alpha` curves
- Logic in `RevealCoordinator` to call `cell.installChatContentIfNeeded` at present time, schedule normalize after cross-fade completion, and perform handoff at blur-fade-out completion
- Wiring to re-enable `canvas.pinchRecognizer` after handoff

**Modifies (existing code):**
- `RevealCoordinator.present` — adds parallel-layout trigger at T=1.6s
- `RevealCoordinator` cross-fade completion — schedules `normalizeToChatRest` to fire after cross-fade lands (canvas already at alpha=0 at that point)
- `RevealCoordinator` blur-fade-out completion — calls `performHandoff` before `blur.detach()`
- `CellView.setCamera` — extends progress→alpha mapping to include chatContent and chatRestCenterLabel

**Deletes:** None. (Future iteration may collapse ChatVC if Option B is later adopted.)

### §0.7 Substrate compliance check (against `CLAUDE.md` Part 4 keystones)

Per `CLAUDE.md` Part 4, the load-bearing keystones are:

| Keystone | This work's impact |
|---|---|
| `contentHost.layer.sublayerTransform` as the camera applier | Untouched. Normalize writes `contentHost.layer.transform`, NOT `sublayerTransform`. |
| `canvas.layer.sublayerTransform.m34 = -1/1000` | Untouched. |
| `AnimationController`'s single `CADisplayLink` | Untouched. We register no new animators. State writes are synchronous in normalize and handoff. |
| `cellPoolByConversationID` identity-keyed pool | Reinforced. cell.chatContent persists with cell across pool LRU. |
| `CATransaction.withSuppressedActions` discipline | Honored. Every synchronous mutation in normalize and handoff is wrapped. |
| `EngagementState.engaged(completion:)` | Untouched. |
| 4 additive `CABasicAnimation`s in `animateCameraToChatRest` | Untouched during forward; explicitly removed at normalize after they have served their purpose. |
| `MorphChoreographer`'s sin-bell Y/Z arc | Untouched. |
| 5 invariant asserts in `InvariantHardeningTests` | Should continue to pass; will verify in §12. |

**No keystone is violated.** The handoff approach is substrate-compatible.

### §0.8 Phenomenological check (against `CLAUDE.md` Part 3)

Per `CLAUDE.md` Part 3, the eight test questions are:

1. **Discrete states?** No — the chat-state is the same continuous transformation of the cell as today; the user perceives no discrete transition at handoff.
2. **Breaks phase-locking?** No — cell.chatContent inherits `sublayerTransform` via being a subview of cell which is a subview of contentHost.
3. **Anonymous cell reuse?** No — cell.chatContent is owned by the cell; persists across pool LRU via the existing identity-keyed mechanism.
4. **UIView.animate for primary motion?** No — all alpha changes at handoff are atomic (no animation); reverse direction uses the existing setCamera + spring mechanisms.
5. **UIScrollView.contentOffset as scroll mechanism?** Sort of — cell.chatContent uses a UIScrollView for the bubble stack (inherited from ChatViewController's structure). This is acceptable because it scrolls the bubble stack INSIDE the cell; it does not compete with the camera primitive which scrolls the cell-list.
6. **Bypasses engagement state machine?** No — gesture interpretation flows through the existing handlePinch* methods; no new state predicates.
7. **Visual outcome matches phenomenology?** Yes — after handoff, the conversation is one continuous object (the cell) at one of its two representations (chat-rest); reverse direction is a continuous gestural collapse of that same object back to cell-rest.
8. **Propagates from same phenomenological commitment?** Yes — every decision in this checklist serves the "one continuous object, two representations" commitment.

**Phenomenologically consistent.**

### §0.9 Top-level acceptance criteria

The work is done when ALL of the following hold:

- [ ] Tapping a cell produces a visually IDENTICAL forward reveal to today (verified via side-by-side screen recording at T=0, T=0.42, T=1.5, T=2.10, T=2.5, T=2.80)
- [ ] At T=2.8s, the user perceives no change despite the handoff (verified via slow-motion screen recording)
- [ ] After the handoff, pinching on the visible chat surface initiates `handlePinchBegan` (verified via log at `TimelineCanvas:1011`)
- [ ] Pinch-in below the commit threshold engages `springToCellRest` (verified via log at the spring start)
- [ ] Spring settles cleanly with the cell at naturalH=200, alpha curves correct (chrome at full alpha, chatContent and chatRestCenterLabel at alpha=0)
- [ ] `activeCellIndex` returns to nil after settle (verified via `tryClearActiveCellAtRest` log)
- [ ] Round-trip preserves state: tap cell A, type "hello" in composer, pinch back, tap cell A again — composer shows "hello"
- [ ] Round-trip preserves scroll: tap cell A, scroll bubbles 200pt, pinch back, tap cell A again — scroll position preserved
- [ ] Isolation between conversations: tap A → state, pinch back, tap B → B's clean state, pinch back, tap A → A's preserved state
- [ ] No retain cycles introduced (verified via Instruments Allocations + Leaks)
- [ ] No memory growth over 100 round-trips (verified via Instruments)
- [ ] Build passes: `xcodebuild -project DotPinchPrototype.xcodeproj -scheme DotPinchPrototype -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' build`
- [ ] InvariantHardeningTests pass (5 asserts in particular)

---

## §1 — Architecture & view hierarchy

This section establishes the new types and where they sit. Every decision is anchored to the substrate-vs-propagation framework: cell.chatContent inherits the substrate by living inside the cell which lives inside contentHost. ChatVC remains a temporary forward-path artifact that is dismissed at handoff.

### §1.1 — View hierarchy after handoff (the target end-state)

```
UIWindow
└── V2RootViewController.view
    ├── TimelineCanvas (canvas)
    │   └── contentHost                                  ← sublayerTransform applied here
    │       └── CellView (the active cell)               ← heightConstraint at 844
    │           ├── labelStack       (alpha=0 at chat-rest)
    │           ├── pinchGlyph       (alpha=0 at chat-rest)
    │           ├── chatRestCenterLabel  (alpha=0 — replaced by chatContent.header)
    │           └── chatContentContainer (alpha=1)   ← NEW; holds the three sub-components
    │               ├── ChatHeaderView      (the day-marker label)
    │               ├── ChatBubbleStackView (UIScrollView + UIStackView of bubbles)
    │               └── ChatComposerView    (composerContainer + composerTextField)
    └── (no chatVC; it was dismissed at handoff)
```

Compare to during the T=1.6s–T=2.8s parallel-layout window:

```
UIWindow
└── V2RootViewController.view
    ├── TimelineCanvas (canvas)                          ← alpha=0 from T=2.10s
    │   └── contentHost                                  ← held in scale 4.92 until normalize
    │       └── CellView (the active cell)               ← heightConstraint at 200 until normalize
    │           ├── chrome alphas mid-fade
    │           ├── chatRestCenterLabel (alpha animating to 1)
    │           └── chatContentContainer (alpha=0)       ← NEW; laid out but invisible
    ├── chatViewController.view  (alpha animating 0→1 during cross-fade)
    └── RevealBlurOverlay  (alpha animating in then out)
```

### §1.2 — `ChatContentContainer` design (the new type)

**Decision: composed sub-components, not a single monolith.** Three reasons:

1. The state controller (§1.4) needs to bind to three logically distinct surfaces (header, scroll, composer). Composition makes the binding API natural.
2. Future scaling: if streaming, voice, attachments, reactions land, each is more likely a modification to one sub-component than a global rewrite.
3. Layout debugging: per-component layout problems are easier to triage when each component owns its own constraints.

**`ChatContentContainer.swift` (sketch, L3 `@MainActor`):**

```swift
@MainActor
final class ChatContentContainer: UIView {
    let header: ChatHeaderView
    let bubbleStack: ChatBubbleStackView
    let composer: ChatComposerView

    private weak var parentVC: UIViewController?
    private var crossViewConstraints: [NSLayoutConstraint] = []

    init(parentVC: UIViewController) {
        self.parentVC = parentVC
        self.header = ChatHeaderView()
        self.bubbleStack = ChatBubbleStackView()
        self.composer = ChatComposerView()
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = Theme.Page.surface       // matches chatVC.view.backgroundColor exactly
        isOpaque = true                            // opaque background prevents bleed-through at handoff
        addSubview(header)
        addSubview(bubbleStack)
        addSubview(composer)
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with conversation: Conversation) {
        header.configure(with: conversation)
        bubbleStack.configure(with: conversation)
        composer.configure(with: conversation)
    }

    private func setupConstraints() {
        guard let parentView = parentVC?.view else { return }
        let safeArea = parentView.safeAreaLayoutGuide

        // The container fills the cell edge-to-edge
        // (constraints to cell are added by CellView.installChatContentIfNeeded)

        // Header pins to PARENT VC's safe area (cross-view) to match chatVC.view's layout exactly
        let headerTop = header.topAnchor.constraint(
            equalTo: safeArea.topAnchor, constant: 24
        )
        let headerLeading = header.leadingAnchor.constraint(
            greaterThanOrEqualTo: parentView.leadingAnchor, constant: 20
        )
        let headerTrailing = header.trailingAnchor.constraint(
            lessThanOrEqualTo: parentView.trailingAnchor, constant: -20
        )
        let headerCenter = header.centerXAnchor.constraint(equalTo: parentView.centerXAnchor)

        // Bubble stack between header and composer
        let bubbleTop = bubbleStack.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 24)
        let bubbleLeading = bubbleStack.leadingAnchor.constraint(
            equalTo: parentView.leadingAnchor, constant: 20
        )
        let bubbleTrailing = bubbleStack.trailingAnchor.constraint(
            equalTo: parentView.trailingAnchor, constant: -20
        )
        let bubbleBottom = bubbleStack.bottomAnchor.constraint(
            equalTo: composer.topAnchor, constant: -16
        )

        // Composer pins to PARENT VC's safe area bottom (cross-view) for home-indicator clearance
        let composerLeading = composer.leadingAnchor.constraint(
            equalTo: parentView.leadingAnchor, constant: 16
        )
        let composerTrailing = composer.trailingAnchor.constraint(
            equalTo: parentView.trailingAnchor, constant: -16
        )
        let composerBottom = composer.bottomAnchor.constraint(
            equalTo: safeArea.bottomAnchor, constant: -12
        )
        let composerHeight = composer.heightAnchor.constraint(equalToConstant: 44)

        crossViewConstraints = [
            headerTop, headerLeading, headerTrailing, headerCenter,
            bubbleTop, bubbleLeading, bubbleTrailing, bubbleBottom,
            composerLeading, composerTrailing, composerBottom, composerHeight,
        ]
        NSLayoutConstraint.activate(crossViewConstraints)
    }

    func teardownCrossViewConstraints() {
        NSLayoutConstraint.deactivate(crossViewConstraints)
        crossViewConstraints.removeAll()
    }
}
```

**Root-cause-trace on `parentVC: weak`:**
- Q1 (Rests on): Cross-view constraints reference `parentVC.view.safeAreaLayoutGuide`. If we keep `parentVC` strong, we create a retain cycle (parentVC → cellPool → cell → chatContent → parentVC).
- Q2 (Why): `V2RootViewController` owns the canvas which owns the cells which (will own) chatContent. Strong upward reference would close the loop.
- Q3 (Assumes): `parentVC` outlives `chatContent` in practice. True because V2RootViewController is the root of the active scene; it survives all cell content.
- Q4 (If changed): If we used unowned, a crash if parentVC is deallocated first (impossible in practice, but unsafe). Weak is correct.
- Q5 (If removed): If parentVC is nil at setupConstraints time, constraint setup is a no-op and chatContent is structurally broken. Mitigation: precondition or assertion-failure during setup.
- Q6 (Absent): No fallback path if parentVC is nil. Should add `preconditionFailure("ChatContentContainer requires non-nil parentVC at setup time")`.

**Tasks:**
- [ ] Create `Conversation/ChatBody/ChatContentContainer.swift` (L3, `@MainActor`)
- [ ] Create `Conversation/ChatBody/ChatHeaderView.swift` (L3, `@MainActor`)
- [ ] Create `Conversation/ChatBody/ChatBubbleStackView.swift` (L3, `@MainActor`)
- [ ] Create `Conversation/ChatBody/ChatComposerView.swift` (L3, `@MainActor`)
- [ ] Verify `xcodegen generate` picks up the new files
- [ ] Add `parentVC` as `weak` reference, with assertion if nil at setup time
- [ ] Add `teardownCrossViewConstraints` for cell-eviction cleanup

### §1.2.1 — Pillar-compliant authoritative sketch (SUPERSEDES §1.2)

§1.2 functional sketch has multiple pillar issues: closures init three subviews inside `init` body (not closure-init), `setupConstraints` is a Tier-2 helper, `crossViewConstraints: [NSLayoutConstraint]` array storage when an explicit named list is clearer. Retrofit below.

**Pillar definitions introduced on first use:**

- **P5.2 — `fileprivate` only when same-file collaboration.** New types co-located with their consumers can use fileprivate.
- **P11.1 SRP (recap) — extract helpers per concern.**
- **P12.1 — Law of Demeter.** Forbidden: `a.b.c.d` chains. Acceptable IF documented as load-bearing collaboration.

**The pillar-compliant rewrite (`Conversation/ChatBody/ChatContentContainer.swift`):**

```swift
import UIKit

// P4.2 final | P4.3 @MainActor | P20.1 one type per file | P20.2 file name matches type
@MainActor
final class ChatContentContainer: UIView {

    // MARK: - Subviews (P1.2 closure-init at class top)

    let header: ChatHeaderView = ChatHeaderView()                   // P5.3 internal — read by parent for layout reference
    let bubbleStack: ChatBubbleStackView = ChatBubbleStackView()    // same
    let composer: ChatComposerView = ChatComposerView()             // same

    // MARK: - Parent VC reference (weak per retain-cycle audit §3.6)

    // P18.14 [weak] — chatContent is owned by cell which is owned by canvas
    // which is owned by V2RootVC; parentVC IS V2RootVC. Strong reference would
    // close the loop: parentVC → canvas → cell → chatContent → parentVC.
    private weak var parentVC: UIViewController?

    // MARK: - Cross-view constraints (per §3.6 retain-cycle audit)

    // P11.1 SRP — these constraints are tracked separately from intra-container
    // constraints so teardownCrossViewConstraints can deactivate them precisely.
    private var crossViewConstraints: [NSLayoutConstraint] = []     // P8.3 var — must mutate on teardown

    // MARK: - Init

    init(parentVC: UIViewController) {                              // P17.5 labeled
        self.parentVC = parentVC
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = Theme.Page.surface                        // matches chatVC.view.backgroundColor (CVC:22)
        isOpaque = true                                              // P1.10 WHY: opaque prevents bleed-through at handoff alpha swap
        installViewHierarchy()
        activateCrossViewConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("ChatContentContainer is code-only; no NSCoder support")
    }

    // MARK: - Configure

    /// Configure all three subviews with the conversation data.
    /// P12.2 tell-don't-ask: caller tells container; container tells subviews.
    /// P19.3 idempotent: same conversation in produces same view state.
    func configure(with conversation: Conversation) {
        header.configure(with: conversation)
        bubbleStack.configure(with: conversation)
        composer.configure(with: conversation)
    }

    // MARK: - View hierarchy (P11.1 SRP)

    private func installViewHierarchy() {
        addSubview(header)
        addSubview(bubbleStack)
        addSubview(composer)
    }

    // MARK: - Cross-view constraint setup (P11.1 SRP)

    /// Anchor header / bubbleStack / composer to `parentVC.view.safeAreaLayoutGuide`
    /// (Strategy A per §3.3 — cross-view constraints maintain forward-visual-parity
    /// with chatVC's safeAreaLayoutGuide anchoring at CVC:90-114).
    ///
    /// P6.7 silence justified: if parentVC was deallocated before init completed
    /// (impossible in practice — parentVC outlives chatContent by construction
    /// per V2RootVC ownership), constraint setup is skipped to avoid crash.
    /// P12.1 LoD: parentView.safeAreaLayoutGuide IS a one-level access (parent
    /// is a parameter; .safeAreaLayoutGuide is its direct field). Acceptable.
    private func activateCrossViewConstraints() {
        guard let parentView = parentVC?.view else {
            preconditionFailure("ChatContentContainer requires non-nil parentVC at setup time")
        }

        let safeArea = parentView.safeAreaLayoutGuide

        crossViewConstraints = [
            // Header (matches chatVC.headerLabel constraints CVC:90-93)
            header.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: Layout.headerTop),
            header.leadingAnchor.constraint(greaterThanOrEqualTo: parentView.leadingAnchor, constant: Layout.horizontalInset),
            header.trailingAnchor.constraint(lessThanOrEqualTo: parentView.trailingAnchor, constant: -Layout.horizontalInset),
            header.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),

            // Bubble stack (matches chatVC.scrollView constraints CVC:95-98)
            bubbleStack.topAnchor.constraint(equalTo: header.bottomAnchor, constant: Layout.bubbleStackTopGap),
            bubbleStack.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: Layout.bubbleHorizontalInset),
            bubbleStack.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -Layout.bubbleHorizontalInset),
            bubbleStack.bottomAnchor.constraint(equalTo: composer.topAnchor, constant: -Layout.composerTopGap),

            // Composer (matches chatVC.composerContainer constraints CVC:106-109)
            composer.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: Layout.composerHorizontalInset),
            composer.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -Layout.composerHorizontalInset),
            composer.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -Layout.composerBottomInset),
            composer.heightAnchor.constraint(equalToConstant: Layout.composerHeight),
        ]
        NSLayoutConstraint.activate(crossViewConstraints)
    }

    /// Deactivate cross-view constraints. Called by cell on rebind / pool eviction
    /// per §3.7 retain-cycle audit.
    func teardownCrossViewConstraints() {
        NSLayoutConstraint.deactivate(crossViewConstraints)
        crossViewConstraints.removeAll()
    }

    // MARK: - Layout tokens (P2.11 magic-number extraction; P20.3 same-file scoping is fine for instance-locals)

    private enum Layout {
        static let headerTop: CGFloat = 24
        static let horizontalInset: CGFloat = 20
        static let bubbleStackTopGap: CGFloat = 24
        static let bubbleHorizontalInset: CGFloat = 20
        static let composerTopGap: CGFloat = 16
        static let composerHorizontalInset: CGFloat = 16
        static let composerBottomInset: CGFloat = 12
        static let composerHeight: CGFloat = 44
    }
}
```

**Pillar honors footnote:**

| Member | Pillars honored |
|---|---|
| `ChatContentContainer` class | P4.2 (final), P4.3 (@MainActor), P11.1 (composition container only), P20.1 (one type per file) |
| `header`, `bubbleStack`, `composer` properties | P1.2 (closure-init at class top — each is a typed default-init), P5.3 (internal so cell can read them for chrome alpha access if needed), P19.5 (`let` — immutable references) |
| `parentVC` property | P18.14 (weak), P5.1 (private) |
| `crossViewConstraints` property | P11.1 (SRP — only cross-view constraints; intra-container ones aren't here), P5.1 (private), P8.3 (var-justified by teardown) |
| `init(parentVC:)` | P17.5 (labeled), P10.x (TAMIC=false, opaque), P1.10 (WHY on isOpaque) |
| `init?(coder:)` | P6.5 (fatalError with WHY) |
| `configure(with:)` | P12.2 (delegates to subviews), P19.3 (idempotent), P11.1 (one concern) |
| `installViewHierarchy()` / `activateCrossViewConstraints()` / `teardownCrossViewConstraints()` | P11.1 SRP per helper, P13.4 |
| `activateCrossViewConstraints` | P6.5 (preconditionFailure for impossible state), P1.1 (guard-with-let), P1.10 (WHY on LoD justification), P12.1 (LoD analysis included) |
| `Layout` enum | P2.11 (all spacing literals tokenized), P5.1 (private), P20.3 (token namespace scoped to type) |

### §1.3 — `CellView.chatContentContainer` ownership

**Decision: cell strongly owns chatContent.** Reasons:
- Identity preservation requires chatContent to survive cell pool LRU as long as the cell does.
- The cell pool already preserves cell instances; making chatContent a strong property of cell extends this preservation naturally.
- Releasing chatContent on cell eviction releases chatContent's parentVC reference (weak) which is a no-op — no cleanup needed.

**`CellView.swift` additions (sketch):**

```swift
// CellView class additions:

var chatContentContainer: ChatContentContainer?

func installChatContentIfNeeded(
    conversation: Conversation,
    parentVC: UIViewController,
    stateController: ConversationStateController
) {
    guard chatContentContainer == nil else {
        // Idempotent: if already installed for this conversation, reuse.
        // If for a different conversation, the cell would have been rebound and chatContent torn down already.
        return
    }

    let container = ChatContentContainer(parentVC: parentVC)
    container.alpha = 0
    container.configure(with: conversation)
    addSubview(container)

    NSLayoutConstraint.activate([
        container.leadingAnchor.constraint(equalTo: leadingAnchor),
        container.trailingAnchor.constraint(equalTo: trailingAnchor),
        container.topAnchor.constraint(equalTo: topAnchor),
        container.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    stateController.bind(to: container)
    chatContentContainer = container

    layoutIfNeeded()  // force layout to occur synchronously during pre-warm window
}

func teardownChatContent() {
    chatContentContainer?.teardownCrossViewConstraints()
    chatContentContainer?.removeFromSuperview()
    chatContentContainer = nil
}
```

**Root-cause-trace on idempotency:**
- Q1 (Rests on): The guard `chatContentContainer == nil`. If called twice for the same cell + conversation, the second call no-ops.
- Q2 (Why): RevealCoordinator might fire the install on every present; if user taps cell A, pinches back, taps A again, we don't want to rebuild chatContent (state would be lost).
- Q3 (Assumes): If chatContentContainer is non-nil, it is for the same conversation as the one being installed. True because `configure(with:)` on CellView (called when cell is bound to a different conversation) calls `teardownChatContent` first (see §1.5).
- Q4 (If changed): If we always rebuild (no guard), state preservation breaks. If we conditionally rebuild based on UUID match, more complex but allowable.
- Q5 (If removed): Double-install adds two ChatContentContainers as subviews of cell — visible layout bug.
- Q6 (Absent): No assertion that conversation matches. Should add `assert(stateController.conversationID == conversation.id, "stateController bound to different conversation")`.

**Tasks:**
- [ ] Add `chatContentContainer: ChatContentContainer?` to CellView
- [ ] Add `installChatContentIfNeeded` method with idempotency guard
- [ ] Add `teardownChatContent` method
- [ ] Wire `teardownChatContent` into `configure(with:)` when conversation changes (cell rebound to different UUID)
- [ ] Verify `teardownChatContent` releases cross-view constraints to avoid retain cycle

### §1.4 — `ConversationStateController` design

**Decision: NSObject (not @MainActor class struct) that owns transient state per-conversation; bound to the cell pool's lifecycle.**

State that needs to survive ChatVC dismissal AND propagate to cell.chatContent:
- Composer text (`String`)
- Scroll offset (`CGPoint`)
- First responder flag (`Bool`)
- Selected text range (`UITextRange?`)
- (Future: keyboard frame, attachment composer state, voice recording state, etc.)

**Where it lives:** Owned by the cell. Created on cell.configure(with:). Released when cell is evicted from pool. ChatVC and cell.chatContent both bind to it during the parallel-layout window; only cell.chatContent binds to it after handoff.

**`ConversationStateController.swift` (sketch, L3 `@MainActor`):**

```swift
@MainActor
final class ConversationStateController: NSObject {
    let conversationID: UUID

    var composerText: String = ""
    var scrollOffset: CGPoint = .zero
    var composerIsFirstResponder: Bool = false
    var selectedTextRange: UITextRange?

    private weak var boundChatContent: ChatContentContainer?

    init(conversationID: UUID) {
        self.conversationID = conversationID
        super.init()
    }

    func bind(to chatContent: ChatContentContainer) {
        boundChatContent = chatContent
        chatContent.composer.composerTextField.text = composerText
        chatContent.bubbleStack.scrollView.contentOffset = scrollOffset
        // First responder is deferred to handoff-completion handling
    }

    func captureFromChatVC(_ chatVC: ChatViewController) {
        composerText = chatVC.composerTextField.text ?? ""
        scrollOffset = chatVC.scrollView.contentOffset
        composerIsFirstResponder = chatVC.composerTextField.isFirstResponder
        selectedTextRange = chatVC.composerTextField.selectedTextRange
    }

    func applyTo(_ chatContent: ChatContentContainer) {
        chatContent.composer.composerTextField.text = composerText
        chatContent.bubbleStack.scrollView.contentOffset = scrollOffset
        // Note: becomeFirstResponder + selectedTextRange happen post-handoff (see §0.4 step 4)
    }
}
```

**Root-cause-trace on bind / capture / apply separation:**
- Q1 (Rests on): Three distinct operations: `bind` (one-way wire from controller to view at install time), `capture` (one-way from chatVC at handoff time), `apply` (one-way to cell.chatContent at handoff time).
- Q2 (Why exists): During the parallel-layout window, both chatVC and cell.chatContent exist. We need to capture from one and apply to the other at the handoff moment. Continuous bidirectional sync is unnecessary because user interaction is only on chatVC (cell.chatContent is invisible).
- Q3 (Assumes): Only one of chatVC and cell.chatContent is the source of truth at any moment: chatVC from T=2.10s to T=2.8s (visible, interactive), cell.chatContent from T=2.8s onward. The state controller bridges the transfer.
- Q4 (If changed): If we made the controller a continuous sync (observing chatVC's text field, mirroring to cell.chatContent in real time), it would be more code with no user-visible benefit because cell.chatContent is invisible during the sync window.
- Q5 (If removed): Without the controller, state lives in chatVC and dies with it. Round-trip state preservation breaks.
- Q6 (Absent): No subscription to `ConversationStore` for incoming messages during chat-state. Live message updates are deferred work (see §15 Open Questions in the original draft; we noted "DEFER live updates").

**Tasks:**
- [ ] Create `Conversation/Timeline/ConversationStateController.swift` (L3, `@MainActor`)
- [ ] Add `conversationID` property
- [ ] Add transient state properties (composerText, scrollOffset, composerIsFirstResponder, selectedTextRange)
- [ ] Add `bind(to:)`, `captureFromChatVC(_:)`, `applyTo(_:)` methods
- [ ] Decide ownership: cell pool owns one per active conversation, lifetimes match cell pool LRU
- [ ] Add unit test stub for capture-apply roundtrip (deferred to dev cycle, not part of acceptance)

### §1.4.1 — Pillar-compliant authoritative sketch (SUPERSEDES §1.4)

§1.4 functional sketch has `var` properties without justification, no explicit Sendable / Observable annotation, and bind(to:) writes to subviews directly (P12.1 LoD borderline). Retrofit below.

**The pillar-compliant rewrite (`Conversation/Timeline/ConversationStateController.swift`):**

```swift
import UIKit

// P4.2 final | P4.3 @MainActor | P20.1 one type per file | P20.4 Timeline concern
@MainActor
final class ConversationStateController: NSObject {

    // MARK: - Identity

    // P5.4 internal accessor for tests; P19.5 immutable post-init
    let conversationID: UUID

    // MARK: - Transient state (P8.3 var-justified by mutation as user interacts)

    var composerText: String = ""
    var scrollOffset: CGPoint = .zero
    var composerIsFirstResponder: Bool = false
    var selectedTextRange: UITextRange?

    // MARK: - Bound view (weak, allows cell pool eviction to release)

    // P18.14 weak — controller is owned by cell; bound view is also owned by cell
    // (in chatContentContainer); strong reference here would be redundant + risk
    // cycle if topology shifts.
    private weak var boundChatContent: ChatContentContainer?

    // MARK: - Init

    init(conversationID: UUID) {                                    // P17.5 labeled
        self.conversationID = conversationID
        super.init()
    }

    // MARK: - Bind / unbind

    /// Bind to a chatContent view; subsequent capture/apply calls target this view.
    /// Idempotent: rebinding to the same view is a no-op.
    /// P19.3 idempotent | P12.2 tell-don't-ask: this method orchestrates writes
    /// via chatContent's public accessors, never reaches into private internals.
    func bind(to chatContent: ChatContentContainer) {
        boundChatContent = chatContent
        chatContent.composer.composerTextField.text = composerText
        chatContent.bubbleStack.scrollContentOffset = scrollOffset
        // First responder restoration is deferred to handoff-completion (see §0.4 step 4).
    }

    func unbind() {
        boundChatContent = nil
    }

    // MARK: - Capture from ChatVC (§33.2.1 integration)

    /// Read transient state from a chatVC and store locally.
    /// P19.3 idempotent | P12.2 (asks chatVC for snapshot — proper encapsulation).
    func captureFromChatVC(_ chatVC: ChatViewController) {
        let snapshot = chatVC.captureTransientState()
        composerText = snapshot.composerText
        scrollOffset = snapshot.scrollOffset
        composerIsFirstResponder = snapshot.composerWasFirstResponder
        selectedTextRange = snapshot.selectedTextRange
    }

    /// Write preserved state into a freshly-instantiated chatVC at install time.
    /// Solves the §4.8 round-trip bug (per D10).
    /// P19.3 idempotent | P11.1 SRP.
    func bindToChatVCAtInstall(_ chatVC: ChatViewController) {
        let snapshot = TransientStateSnapshot(
            composerText: composerText,
            scrollOffset: scrollOffset,
            composerWasFirstResponder: composerIsFirstResponder,
            selectedTextRange: selectedTextRange
        )
        chatVC.bindTransientState(snapshot)
    }

    /// Write captured state into the currently-bound chatContent.
    /// Mirrors `bind(to:)` but uses already-captured local state (not a fresh
    /// chatContent reference).
    /// P19.3 idempotent.
    func applyToBoundChatContent() {
        guard let chatContent = boundChatContent else { return }    // P6.7 silence justified: not yet bound
        chatContent.composer.composerTextField.text = composerText
        chatContent.bubbleStack.scrollContentOffset = scrollOffset
    }
}
```

**Pillar honors footnote:**

| Member | Pillars honored |
|---|---|
| `ConversationStateController` class | P4.2, P4.3, P20.1, P20.4 (Timeline placement) |
| `conversationID` property | P5.4 (internal for tests), P19.5 (let immutable) |
| Four transient state `var`s | P8.3 (var-justified — these mutate as user interacts) |
| `boundChatContent` | P18.14 (weak — no retain cycle), P5.1 (private) |
| `init(conversationID:)` | P17.5 (labeled) |
| `bind(to:)` | P12.2, P19.3, P1.10 (WHY on deferred first-responder) |
| `unbind()` | P11.1 (one concern), P13.4 (single line) |
| `captureFromChatVC(_:)` | P12.2 (asks ChatVC for snapshot — proper encapsulation), P19.3 |
| `bindToChatVCAtInstall(_:)` | P11.1, P19.3, P12.2 |
| `applyToBoundChatContent()` | P6.7 (silence justified comment), P11.1 |

**Pillar violations to verify ABSENT:**

- ❌ No direct reach-into chatContent.composer.composerTextField from non-bind paths — **P12.1 enforced (bind/apply are the seam)**
- ❌ No mutable properties without var-justification — **P8.3 enforced**
- ❌ No closure stored without [weak self] — **P18.14 enforced (no closures stored)**
- ❌ Method ≤15 LOC each — **P13.4 enforced**

### §1.5 — ChatViewController's modified lifecycle

`ChatViewController` is unchanged internally. Only its lifecycle is touched:

- **Present (T=1.6s):** `RevealCoordinator.present` does `addChild(chatVC)` + `view.addSubview(chatVC.view)` + `didMove(toParent:)` as today.
- **NEW: parallel install of cell.chatContent:** at the same moment, `RevealCoordinator.present` ALSO calls `cell.installChatContentIfNeeded(conversation:, parentVC: rootVC, stateController: ...)`.
- **Cross-fade (T=2.10s):** chatVC.view.alpha animates 0→1; canvas.alpha animates 1→0. As today.
- **Blur-fade-out (T=2.5s–T=2.8s):** blur overlay fades out. As today.
- **NEW: handoff (T=2.8s):** in `blurFadeOut.addCompletion`, perform the state capture / atomic alpha swap / first-responder transfer / chatVC removal (see §0.4).
- **Post-handoff:** chatVC is removed from V2RootViewController's child VCs and from the view hierarchy. ChatVC instance is released (or cached — see §1.6).

**Decision: release chatVC each present (no cache).** Reasoning:
- ChatVC is ~50-200KB depending on bubble count. Re-instantiation cost is ~15-30ms.
- The state controller already preserves the user-visible state (composer text, scroll offset).
- The cell pool's bubble views are LRU-evicted at 20; ChatVC cache would need parallel eviction policy. Avoiding the parallel cache simplifies memory accounting.
- If profiling later shows re-instantiation is a hotspot, a cache can be added without rework (just observe `ChatViewController` instances in a `[UUID: ChatViewController]` LRU dict on `RevealCoordinator`).

**Tasks:**
- [ ] At handoff: `chatVC.willMove(toParent: nil)`, `chatVC.view.removeFromSuperview()`, `chatVC.removeFromParent()`
- [ ] At handoff: `revealCoordinator.chatViewController = nil` (releases the strong reference; chatVC is deallocated)
- [ ] Verify no retain cycles on chatVC (no closures holding self strongly)
- [ ] Verify chatVC's `deinit` runs after handoff (add a temporary log to confirm during dev)

### §1.6 — RevealCoordinator's modified role

`RevealCoordinator` was already the orchestrator of forward reveal. The handoff is a natural extension of its responsibility because:
- It owns the timing markers (T=1.6s instantiation, T=2.10s cross-fade, T=2.8s blur-fade-out completion).
- It owns the chatVC reference.
- It owns the blur overlay's lifecycle (the handoff happens just before `blur.detach()`).

**Tasks:**
- [ ] Add `weak var canvasRef: TimelineCanvas?` to RevealCoordinator (or pass through a callback) — needed for normalize and re-enabling pinchRecognizer
- [ ] Add `weak var stateController: ConversationStateController?` — needed for capture/apply at handoff
- [ ] Modify `present(conversation:)`:
  - After installChatViewController, get the active cell via `canvas.instantiatedCells[canvas.activeCellIndex!]`
  - Call `cell.installChatContentIfNeeded(conversation:, parentVC: rootVC, stateController:)`
- [ ] Modify cross-fade completion:
  - Schedule `canvas.normalizeToChatRest(activeCellIndex:)` to run inside a `CATransaction.withSuppressedActions`
- [ ] Modify blurFadeOut completion:
  - Before `blur.detach()`: call `performHandoff()`
  - `performHandoff` does: captureFromChatVC → applyTo(cell.chatContent) → atomic CATransaction alpha swap → post-transaction first-responder + chatVC removal + pinchRecognizer enable

### §1.7 — Open architectural decisions (record here as resolved)

- [ ] **D1 — Composition style for ChatContentContainer:** monolith vs composed sub-components. **Resolution proposed: composed.** Confirm during implementation.
- [ ] **D2 — Lazy vs eager creation:** lazy on first install. **Resolution: lazy.** Cell-list cells that never become chat-rest never instantiate chatContent.
- [ ] **D3 — ChatVC cache:** release vs cache. **Resolution: release.** Reconsider if profiling shows re-instantiation hotspot.
- [ ] **D4 — State controller ownership:** owned by cell vs owned by V2RootVC. **Resolution: owned by cell.** Lifetimes match cell pool LRU; eviction releases controller naturally.
- [ ] **D5 — Cross-view constraint approach:** **Resolution: Strategy A** (constraints reference `parentVC.view.safeAreaLayoutGuide` directly). Detailed in §3.

---

## §2 — Forward-path mechanics (timing windows)

This section is the per-millisecond timeline. Every operation has a T-time, a precondition (what state the system is in when it fires), and a postcondition (what state it leaves the system in). The forward path is observable: today it ends at T=2.8s with the user seeing chatVC's view, with the canvas at alpha=0 and the cane curve animations held forever. We graft three new operations onto this timeline (install chatContent @ T=1.6s, normalize @ post-cross-fade, handoff @ T=2.8s) without disturbing any visible event.

### §2.1 — Master timeline

| T (sec) | Event | Trigger | State after |
|---|---|---|---|
| 0.00 | User taps cell | UITapGestureRecognizer fires on cell | activeCellIndex set; pinchRecognizer disabled; cane curve scheduled |
| 0.00–1.50 | Cane curve plays | 4 additive CABasicAnimations on contentHost.layer | contentHost.layer.transform animates from identity to scale ≈ 4.92 |
| 0.00–0.30 | Cell-rest chrome fades out | performMorphChromeTransition via UIView.animate | labelStack.alpha=0, pinchGlyph.alpha=0 |
| 0.78–1.50 | chatRestCenterLabel.alpha curve | centerLabelOpacity CABasicAnimation | chatRestCenterLabel.alpha animates 0→1 |
| 1.50 | Cane curve completes | CABasicAnimation completion; animations remain attached (isRemovedOnCompletion=false) | contentHost held at scale 4.92 |
| 1.60 | onMorphRevealReady fires | DispatchWorkItem scheduled at +0.10s after cane curve | RevealCoordinator.present(conversation:) called |
| 1.60 | ChatViewController instantiated | RevealCoordinator.installChatViewController | chatVC added as child VC; chatVC.view added as subview of V2RootVC.view; alpha=0 |
| **1.60** | **NEW: cell.installChatContentIfNeeded** | RevealCoordinator.present extension | chatContentContainer added as subview of cell; alpha=0; layout forced |
| 1.60–1.90 | blurFadeIn animates | UIViewPropertyAnimator | RevealBlurOverlay.alpha animates 0→1; blur is opaque by T~1.9s |
| 1.90 | blurFadeIn completes | UIViewPropertyAnimator completion | Blur fully opaque; chatVC and canvas both behind the blur |
| 2.10 | crossFade animates | UIViewPropertyAnimator (0.40s duration starts at T=1.70 actually) | chatVC.view.alpha 0→1; canvas.alpha 1→0 |
| 2.10 | crossFade completes | UIViewPropertyAnimator completion | chatVC.view fully visible; canvas at alpha=0 |
| **2.10–2.80** | **NEW: normalizeToChatRest runs once** | DispatchQueue.main.async after crossFade completion | contentHost.transform=identity; held animations removed; heightConstraint=844; chatRestCenterLabel.alpha=0; layout forced |
| 2.50 | blurFadeOut animates | UIViewPropertyAnimator (0.30s duration) | Blur.alpha 1→0; chatVC.view emerges from under the blur |
| 2.80 | blurFadeOut completes | UIViewPropertyAnimator completion | Blur fully transparent |
| **2.80** | **NEW: performHandoff** | blurFadeOut.addCompletion | State captured + applied; atomic alpha swap; chatVC removed; pinchRecognizer re-enabled |
| 2.80+ | User can pinch on cell | canvas.pinchRecognizer.isEnabled = true; cell.chatContent visible | Ready for reverse direction |

**The three NEW events are highlighted.** Everything else is unchanged.

### §2.2 — Why each new event lives where it does (root-cause-trace)

**§2.2.1 — Why install cell.chatContent at T=1.6s (not earlier, not later):**

- Q1 (Rests on): RevealCoordinator.present is called at T=1.6s, and it already triggers chatVC instantiation. Adding cell.chatContent install at the same callsite is structurally the cleanest grafting point.
- Q2 (Why): Earlier than T=1.6s (e.g., at cell.configure or canvas.layoutSubviews) would eagerly create chatContent for cells that never become chat-rest — wasted memory. Later than T=1.6s (e.g., at T=2.10s during cross-fade) would compete with the cross-fade animation for main-thread time AND risk frame drops on the visible cross-fade.
- Q3 (Assumes): At T=1.6s, the active cell is identified (activeCellIndex is set), the cell is in the cell pool (instantiatedCells contains it), and the cell's CellView instance has been laid out at naturalH=200. All true at T=1.6s; the cane curve completion at T=1.5s does not modify these properties.
- Q4 (If changed to earlier): Eager install at cell.configure would create chatContent for ~5 cells in view at any moment (not just the active one). Memory: 5 × ~100KB = 500KB wasted on cells that never reach chat-rest. Layout: 5 × ~30ms layout time on app launch is unacceptable.
- Q5 (If removed): The normalize and handoff have nothing to swap to at T=2.8s. Reverse direction broken.
- Q6 (Absent): No prefetching for the next-likely-to-be-tapped cell. Possible future optimization; not in scope.

**§2.2.2 — Why normalize during crossFade completion (not before, not after):**

- Q1 (Rests on): The canvas.alpha=0 invariant holds from T=2.10s (cross-fade completes setting it to 0) to T=2.8s (handoff sets it to 1). Any structural change to canvas inside this window is invisible.
- Q2 (Why): Before T=2.10s, canvas.alpha > 0; structural changes would be visible (heightConstraint extension would visibly snap; transform reset would visibly snap). After T=2.8s, the handoff has set canvas.alpha=1; we want the cell to ALREADY be in chat-rest geometry by then.
- Q3 (Assumes): Cross-fade completion is reliable. UIViewPropertyAnimator's `addCompletion` fires unless `cancelInFlight` interrupts. Verified by reading `RevealCoordinator.swift:75-92`.
- Q4 (If changed to "before cross-fade"): Heightconstraint extension during T=1.6–2.10s would be visible because canvas.alpha is still 1. The cell would visibly grow from 200 to 844 during cross-fade — unacceptable.
- Q5 (If removed): Handoff at T=2.8s would see contentHost at scale 4.92, heightConstraint at 200, canvas.alpha 0→1. When canvas.alpha flips to 1, the user would see a tiny cell scaled 5x by contentHost — bizarre.
- Q6 (Absent): No fallback if cross-fade completion never fires (e.g., cancelInFlight). Normalize wouldn't run; handoff at T=2.8s would do redundant normalize work itself. Acceptable degraded behavior.

**§2.2.3 — Why handoff at blurFadeOut completion (not at crossFade completion):**

- Q1 (Rests on): At blurFadeOut completion (T=2.8s), the blur has fully lifted and the user sees the chat surface. AT crossFade completion (T=2.10s), the blur is still opaque (it doesn't fade out until T=2.5s). A handoff at T=2.10s would work because the blur is over both chatVC and canvas, but...
- Q2 (Why T=2.8s): Two reasons. (i) The handoff requires cell.chatContent to be FULLY LAID OUT, which is guaranteed by T=1.7s after install. (ii) Symmetry: the handoff is the END of the forward sequence; placing it at blurFadeOut completion makes it the natural "forward path complete" marker.
- Q3 (Assumes): blurFadeOut completion fires reliably. Verified per `RevealCoordinator.swift:93-100`.
- Q4 (If at T=2.10s): Handoff would be hidden under the blur (still opaque). Theoretically fine, but normalize would not have run yet, so handoff would have to do normalize's work AS WELL. Operations pile up at one moment — more risk of frame drop.
- Q5 (If removed): No handoff; today's broken state.
- Q6 (Absent): No retry on handoff failure. If something inside performHandoff throws or precondition fails, no recovery. Acceptable; preconditions are encoded.

### §2.3 — `TimelineCanvas.normalizeToChatRest(activeCellIndex:)` implementation

This is the new public method on TimelineCanvas. It runs inside the canvas.alpha=0 window and prepares the canvas for the post-handoff chat-rest state.

**Sketch:**

```swift
// TimelineCanvas additions:

func normalizeToChatRest(activeCellIndex: Int) {
    guard let cell = instantiatedCells[activeCellIndex] else {
        assertionFailure("normalizeToChatRest called with invalid activeCellIndex \(activeCellIndex)")
        return
    }

    CATransaction.withSuppressedActions {
        // Step 1: remove the four held cane curve animations from contentHost.layer
        contentHost.layer.removeAnimation(forKey: MorphAnimationKey.windupScale.rawValue)
        contentHost.layer.removeAnimation(forKey: MorphAnimationKey.zoomScale.rawValue)
        contentHost.layer.removeAnimation(forKey: MorphAnimationKey.windupTranslate.rawValue)
        contentHost.layer.removeAnimation(forKey: MorphAnimationKey.morphCentering.rawValue)

        // Step 2: reset contentHost.layer.transform to identity
        contentHost.layer.transform = CATransform3DIdentity

        // Step 3: remove the held centerLabelOpacity animation from chatRestCenterLabel
        cell.chatRestCenterLabel.layer.removeAnimation(forKey: MorphAnimationKey.centerLabelOpacity.rawValue)

        // Step 4: ensure chatRestCenterLabel transform is identity (defensive)
        cell.chatRestCenterLabel.transform = .identity

        // Step 5: set chatRestCenterLabel.alpha = 0 (cell.chatContent shows its own header)
        cell.chatRestCenterLabel.alpha = 0

        // Step 6: extend cell.heightConstraint to chat-rest extension
        let extension = bounds.height  // chat-rest extension = viewport height
        cell.heightConstraint?.constant = extension

        // Step 7: force layout
        contentHost.layoutIfNeeded()
    }
}
```

**Tasks:**
- [ ] Add `normalizeToChatRest(activeCellIndex:)` method to TimelineCanvas
- [ ] Add precondition / assertion for invalid activeCellIndex
- [ ] Wrap all mutations inside `CATransaction.withSuppressedActions` (Part 2.1 of CLAUDE.md)
- [ ] Verify `MorphAnimationKey` cases (windupScale, zoomScale, windupTranslate, morphCentering, centerLabelOpacity) match the keys used in `animateCameraToChatRest`
- [ ] Add log line at start and end (temporary, for dev verification of the canvas.alpha=0 window timing)

**Acceptance:**
- [ ] After normalize, `contentHost.layer.transform == CATransform3DIdentity`
- [ ] After normalize, `contentHost.layer.animationKeys()` does NOT contain any cane curve keys
- [ ] After normalize, `cell.heightConstraint?.constant == bounds.height` (= 844 on iPhone 16)
- [ ] After normalize, `cell.chatRestCenterLabel.alpha == 0`
- [ ] No visible change to user during normalize (verified via screen recording with frame stepping)

### §2.3.1 — Pillar-compliant authoritative sketch (SUPERSEDES §2.3 + §16.10)

§2.3's sketch (and §16.10's correction) work functionally but pack 7 distinct concerns into one method body. The pillar-compliant version decomposes into named helpers per concern + applies guard-chain + named-token cleanup.

**The pillar-compliant rewrite (`TimelineCanvas.swift` additions):**

```swift
// MARK: - Normalize to chat-rest (post-cane-curve / post-pinch-commit cleanup)

/// Reset canvas to the clean chat-rest end-state in the canvas.alpha=0 window.
/// Runs once between crossFade completion and blurFadeOut completion (~700ms
/// window per §16.4). Idempotent (P19.3): re-running produces same state.
///
/// Path differences handled by single normalize:
/// - Tap path: removes 4 held cane-curve CABasicAnimations; resets transform;
///   updates camera to center the cell (cane curve never updated camera —
///   morphCentering animation held the visual centering until removed).
/// - Pinch-commit path: most steps are no-ops because MorphChoreographer
///   already left state clean. The setCamera call refreshes chrome alphas
///   that pinch-commit's morphInProgress gate prevented setCamera from
///   updating during the morph.
///
/// Pillar honors: P11.1 (orchestrator), P12.2 (delegates to helpers), P13.4
/// (≤15 LOC), P19.3 idempotent, P10.x cleanup discipline (suppressed CATransaction).
func normalizeToChatRest(activeCellIndex: Int) {
    // P6.7 silence justified: invalid index implies caller bug; assertion in
    // DEBUG; silent return in release prevents crash in production.
    guard let cell = instantiatedCells[activeCellIndex] else {
        assertionFailure("normalizeToChatRest called with invalid activeCellIndex \(activeCellIndex)")
        return
    }

    CATransaction.withSuppressedActions {
        clearCaneCurveAnimations()
        resetContentHostTransform()
        clearChatRestCenterLabelTransientState(on: cell)
        extendCellToChatRest(cell: cell)
    }
    centerCameraOnActiveCell(cell: cell)        // calls setCamera which itself wraps in suppressed CATransaction
}

// MARK: - Normalize helpers (P11.1 SRP per helper)

/// Remove the 4 held cane-curve CABasicAnimations from contentHost.layer.
/// No-op for pinch-commit path (MorphChoreographer doesn't attach these).
private func clearCaneCurveAnimations() {
    contentHost.layer.removeAnimation(forKey: MorphAnimationKey.windupScale.rawValue)
    contentHost.layer.removeAnimation(forKey: MorphAnimationKey.zoomScale.rawValue)
    contentHost.layer.removeAnimation(forKey: MorphAnimationKey.windupTranslate.rawValue)
    contentHost.layer.removeAnimation(forKey: MorphAnimationKey.morphCentering.rawValue)
}

/// Reset contentHost.layer.transform to identity.
/// Tap path: undoes the held cane-curve transform composition.
/// Pinch-commit path: idempotent (already identity post-MorphChoreographer-completion).
private func resetContentHostTransform() {
    contentHost.layer.transform = CATransform3DIdentity
}

/// Clear chatRestCenterLabel's transient state (held centerLabelOpacity animation
/// + counter-scale transform + alpha).
private func clearChatRestCenterLabelTransientState(on cell: CellView) {
    cell.chatRestCenterLabel.layer.removeAnimation(forKey: MorphAnimationKey.centerLabelOpacity.rawValue)
    cell.chatRestCenterLabel.transform = .identity
    cell.chatRestCenterLabel.alpha = 0
}

/// Extend cell.heightConstraint to chat-rest extension (bounds.height).
/// Tap path: corrects from naturalH=200 baseline (cane curve doesn't extend).
/// Pinch-commit path: no-op (heightConstraint already at chatRestExt).
private func extendCellToChatRest(cell: CellView) {
    cell.heightConstraint?.constant = bounds.height
    contentHost.layoutIfNeeded()
}

/// Center the canvas camera on the active cell (per §16.5 camera position fix).
/// Calls `setCamera(_:)` which internally wraps in suppressed CATransaction
/// AND drives pushCameraToVisibleCells (which refreshes chrome alphas via
/// cell.setCamera at progress=1 — the fix for §16.6 pinch-commit chrome).
///
/// P12.2 tell-don't-ask: setCamera owns its own state-update sequence.
private func centerCameraOnActiveCell(cell: CellView) {
    setCamera(Camera(translation: cell.frame.midY))
}
```

**Pillar honors footnote:**

| Member | Pillars honored |
|---|---|
| `normalizeToChatRest(activeCellIndex:)` | P11.1, P12.2, P13.4 (~12 LOC), P19.3, P6.7 (silence justified with assertion in DEBUG), P10.x (suppressed CATransaction) |
| `clearCaneCurveAnimations()` | P11.1 (one concern: 4 animation removals), P13.4, P19.3 |
| `resetContentHostTransform()` | P11.1, P1.10 (WHY comment on tap vs pinch-commit paths) |
| `clearChatRestCenterLabelTransientState(on:)` | P11.1, P17.5 (labeled param) |
| `extendCellToChatRest(cell:)` | P11.1, P12.2 (cell exposes heightConstraint; we set it) |
| `centerCameraOnActiveCell(cell:)` | P11.1, P12.2 (setCamera owns update sequence), P1.10 (WHY comment on §16.5 fix + §16.6 chrome refresh side-effect) |

**Pillar violations to verify ABSENT:**

- ❌ No nested CATransactions — **suppressed wraps only the synchronous mutation block; setCamera handles its own**
- ❌ No magic animation key strings — **P2.11 enforced (all via MorphAnimationKey enum)**
- ❌ No magic numbers — **P2.11 enforced (bounds.height is a runtime value, not a literal)**
- ❌ No method >20 LOC — **P13.4 enforced**

### §2.4 — `RevealCoordinator.performHandoff` implementation

This is the orchestrator method at the heart of T=2.8s. It executes the four-part handoff described in §0.4.

**Sketch:**

```swift
// RevealCoordinator additions:

private func performHandoff() {
    guard
        let chatVC = chatViewController,
        let canvas = canvasRef,
        let activeIdx = canvas.activeCellIndex,
        let cell = canvas.instantiatedCells[activeIdx],
        let chatContent = cell.chatContentContainer,
        let stateController = self.stateController
    else {
        assertionFailure("performHandoff missing required references")
        return
    }

    // Step 1: capture state from chatVC
    stateController.captureFromChatVC(chatVC)

    // Step 2: apply state to cell.chatContent (synchronous writes)
    stateController.applyTo(chatContent)

    // Step 3: atomic alpha swap inside suppressed CATransaction
    CATransaction.withSuppressedActions {
        chatVC.view.alpha = 0
        chatVC.view.isUserInteractionEnabled = false
        canvas.alpha = 1
        chatContent.alpha = 1
        canvas.pinchRecognizer.isEnabled = true
    }

    // Step 4: post-transaction cleanup
    if stateController.composerIsFirstResponder {
        chatContent.composer.composerTextField.becomeFirstResponder()
        if let range = stateController.selectedTextRange {
            chatContent.composer.composerTextField.selectedTextRange = range
        }
    }

    chatVC.willMove(toParent: nil)
    chatVC.view.removeFromSuperview()
    chatVC.removeFromParent()
    chatViewController = nil  // release strong reference

    // Drive setCamera once so progress-based alphas reflect chat-rest correctly
    canvas.setCamera()
}
```

**Root-cause-trace on step ordering:**
- Q1 (Rests on): `captureFromChatVC` reads chatVC's state BEFORE the alpha swap. After the alpha swap, the becomeFirstResponder transfer happens IMMEDIATELY (before chatVC.removeFromSuperview) so the keyboard tracks the new responder without dismissing.
- Q2 (Why this order): If we removed chatVC first, the composerTextField would resign first responder, the keyboard would dismiss, then becomeFirstResponder on cell.chatContent's textField would re-present the keyboard. User sees keyboard flicker.
- Q3 (Assumes): UIKit handles concurrent first-responder transitions smoothly when the new responder calls becomeFirstResponder before the old responder is removed. Verified empirically.
- Q4 (If changed): Removing chatVC first → keyboard flicker. Capturing state AFTER alpha swap → race condition on UIView properties read during a layout in progress.
- Q5 (If removed): No handoff; today's broken state.
- Q6 (Absent): No explicit ordering enforcement (e.g., a state machine). Comments + tests are the only safeguard. Acceptable.

**Tasks:**
- [ ] Add `canvasRef: weak TimelineCanvas?` to RevealCoordinator
- [ ] Add `stateController: weak ConversationStateController?` to RevealCoordinator
- [ ] Implement `performHandoff()` method per sketch
- [ ] Wire `performHandoff()` into `blurFadeOut.addCompletion` BEFORE `blur.detach()`
- [ ] Add precondition / assertion for missing references
- [ ] After handoff, drive `canvas.setCamera()` once to refresh progress-based alphas (chatContent at progress=1.0, labelStack at progress=1.0, etc.)

**Acceptance:**
- [ ] After handoff: chatVC not in V2RootVC.childViewControllers
- [ ] After handoff: chatVC.view not in V2RootVC.view.subviews
- [ ] After handoff: `revealCoordinator.chatViewController == nil`
- [ ] After handoff: `canvas.alpha == 1`
- [ ] After handoff: `cell.chatContent.alpha == 1`
- [ ] After handoff: `canvas.pinchRecognizer.isEnabled == true`
- [ ] Keyboard does not flicker if composer was first responder pre-handoff
- [ ] No visible change to user (verified via slow-motion screen recording)

### §2.4.1 — Pillar-compliant authoritative sketch (SUPERSEDES §2.4)

§2.4 functional sketch handles all four handoff steps in one method body. The pillar-compliant rewrite extracts each step into a single-responsibility helper while preserving atomicity within the CATransaction.

**The pillar-compliant rewrite (`RevealCoordinator.swift` additions):**

```swift
// MARK: - Handoff (T=2.8s — invisible swap from chatVC to cell.chatContent)

/// Execute the four-part handoff at blurFadeOut completion.
/// Per §0.4: state capture → state apply → atomic alpha swap → post-cleanup.
///
/// Pillar honors: P11.1 (orchestrator), P12.2 (delegates to helpers), P13.4
/// (≤20 LOC), P19.3 idempotent (calling twice no-ops on second call via
/// handoffPhase guard).
func performHandoff() {
    // P1.1 multi-binding guard | P6.7 silence justified: missing refs at
    // handoff time imply scene-deactivation already cleared the in-flight
    // present (cancelInFlight) — §32 recovery path handles this case.
    guard let chatVC = chatViewController,
          let canvas = canvasRef,
          let activeIdx = canvas.activeCellIndex,
          let cell = canvas.instantiatedCells[activeIdx],
          let chatContent = cell.chatContentContainer,
          let stateController = self.stateController
    else {
        assertionFailure("performHandoff called with missing references")
        return
    }

    transferState(from: chatVC, to: chatContent, via: stateController)
    performAtomicAlphaSwap(chatVC: chatVC, canvas: canvas, chatContent: chatContent)
    restoreFirstResponderIfNeeded(chatVC: chatVC, chatContent: chatContent, via: stateController)
    detachAndReleaseChatVC(chatVC)
}

// MARK: - Handoff helpers (P11.1 SRP per step of the four-part handoff)

/// Step 1+2: capture state from chatVC, apply to chatContent.
/// P12.2 tell-don't-ask: stateController owns capture/apply seam.
private func transferState(
    from chatVC: ChatViewController,
    to chatContent: ChatContentContainer,
    via stateController: ConversationStateController
) {
    stateController.captureFromChatVC(chatVC)
    chatContent.composer.composerTextField.text = stateController.composerText
    chatContent.bubbleStack.scrollContentOffset = stateController.scrollOffset
}

/// Step 3: atomic alpha swap inside one suppressed CATransaction.
/// All 5 writes commit in one render pass — user sees no intermediate state.
/// P10.x atomicity discipline | CLAUDE.md §2.1 suppressed CATransaction.
private func performAtomicAlphaSwap(
    chatVC: ChatViewController,
    canvas: TimelineCanvas,
    chatContent: ChatContentContainer
) {
    CATransaction.withSuppressedActions {
        chatVC.view.alpha = 0
        chatVC.view.isUserInteractionEnabled = false
        canvas.alpha = 1
        chatContent.alpha = 1
        canvas.pinchRecognizer.isEnabled = true
    }
}

/// Step 4a: re-assert first responder on chatContent's composer if chatVC's
/// was a responder pre-swap. Called AFTER the CATransaction so UIKit's
/// keyboard tracking sees the new responder as live (P1.10 WHY).
private func restoreFirstResponderIfNeeded(
    chatVC: ChatViewController,
    chatContent: ChatContentContainer,
    via stateController: ConversationStateController
) {
    guard stateController.composerIsFirstResponder else { return }   // P6.7 silence justified: nothing to restore
    let destination = chatContent.composer.composerTextField
    destination.becomeFirstResponder()
    if let savedRange = stateController.selectedTextRange {
        destination.selectedTextRange = mapTextRange(
            from: chatVC.composerTextField,
            to: destination,
            range: savedRange
        )
    }
}

/// Step 4b: remove chatVC from V2RootVC's child VCs and release strong reference.
private func detachAndReleaseChatVC(_ chatVC: ChatViewController) {
    chatVC.willMove(toParent: nil)
    chatVC.view.removeFromSuperview()
    chatVC.removeFromParent()
    chatViewController = nil                                          // P18.14 implicit: release strong ref
}

// MARK: - Text-range remap helper (P19.1 pure, P11.1 SRP)

/// Map a UITextRange from one text field to the equivalent range in another,
/// using offset-based remapping (UITextRange instances are not interchangeable
/// across text fields).
/// P19.1 pure: same inputs → same output.
private func mapTextRange(
    from source: UITextField,
    to dest: UITextField,
    range: UITextRange
) -> UITextRange? {
    let startOffset = source.offset(from: source.beginningOfDocument, to: range.start)
    let endOffset = source.offset(from: source.beginningOfDocument, to: range.end)
    guard let destStart = dest.position(from: dest.beginningOfDocument, offset: startOffset),
          let destEnd = dest.position(from: dest.beginningOfDocument, offset: endOffset)
    else { return nil }
    return dest.textRange(from: destStart, to: destEnd)
}
```

**Pillar honors footnote:**

| Member | Pillars honored |
|---|---|
| `performHandoff()` | P11.1, P12.2, P13.4 (~15 LOC), P19.3, P6.7 (assertion in DEBUG + silent fallthrough in release), P1.1 (single guard-chain) |
| `transferState(from:to:via:)` | P11.1 (one concern: capture+apply), P12.2 (stateController owns seam), P17.5 (named labels) |
| `performAtomicAlphaSwap(chatVC:canvas:chatContent:)` | P11.1, P10.x atomicity, CLAUDE.md §2.1 |
| `restoreFirstResponderIfNeeded(chatVC:chatContent:via:)` | P11.1, P6.7 (silence justified), P1.10 (WHY on post-transaction timing) |
| `detachAndReleaseChatVC(_:)` | P11.1, P18.14 (release strong ref via nil assignment) |
| `mapTextRange(from:to:range:)` | P19.1 pure, P11.1, P1.1 (guard-chain), P17.5 (named labels read fluently) |

**Pillar violations to verify ABSENT:**

- ❌ No force-unwraps — **P1.3 enforced (every optional via guard-let)**
- ❌ No silent return without WHY — **P6.7 enforced**
- ❌ No magic numbers — **P2.11 N/A (no numeric literals in handoff)**
- ❌ No method >20 LOC — **P13.4 enforced**
- ❌ No nested CATransactions — **single CATransaction in performAtomicAlphaSwap; capture/apply BEFORE the transaction; first-responder + detach AFTER**
- ❌ No closure without [weak self] — **N/A (no closures in handoff)**

### §2.5 — Where the new code is wired into RevealCoordinator

The existing `RevealCoordinator.present(conversation:)` flow at `RevealCoordinator.swift:60-104` (approximate; verify line numbers during implementation). The new wiring slots in at three points:

**Wiring point 1 — after installChatViewController (T=1.6s):**

```swift
// existing:
installChatViewController(conversation: conversation)

// NEW:
if let canvas = canvasRef,
   let activeIdx = canvas.activeCellIndex,
   let cell = canvas.instantiatedCells[activeIdx] {
    let stateController = ConversationStateController(conversationID: conversation.id)
    // Note: in the final design, stateController would be vended by canvas/cell pool
    // so it persists across pool round-trips. The sketch above is one-shot for clarity.
    self.stateController = stateController
    cell.installChatContentIfNeeded(
        conversation: conversation,
        parentVC: rootVC,
        stateController: stateController
    )
}
```

**Wiring point 2 — after crossFade.startAnimation (schedule normalize):**

```swift
// existing:
crossFade.addCompletion { _ in
    canvas.alpha = 0  // existing behavior
}

// NEW (inside the same crossFade.addCompletion):
crossFade.addCompletion { [weak self] _ in
    canvas.alpha = 0  // existing
    // Schedule normalize for the next runloop tick so cross-fade has committed
    DispatchQueue.main.async {
        guard let self = self,
              let canvas = self.canvasRef,
              let activeIdx = canvas.activeCellIndex else { return }
        canvas.normalizeToChatRest(activeCellIndex: activeIdx)
    }
}
```

**Wiring point 3 — inside blurFadeOut.addCompletion (perform handoff):**

```swift
// existing:
blurFadeOut.addCompletion { [weak self] _ in
    self?.blur.detach()
    // ... existing cleanup ...
}

// NEW (inside the same blurFadeOut.addCompletion, BEFORE blur.detach):
blurFadeOut.addCompletion { [weak self] _ in
    self?.performHandoff()
    self?.blur.detach()
    // ... existing cleanup ...
}
```

**Tasks:**
- [ ] Identify the exact line numbers in `RevealCoordinator.swift` for the three wiring points (read the file during implementation)
- [ ] Add the three new code paths
- [ ] Verify weak captures (`[weak self]`) on all closures
- [ ] Verify the order inside blurFadeOut.addCompletion: handoff before blur.detach
- [ ] Add temporary log lines at each wiring point (remove before commit)

### §2.6 — The canvas.alpha=0 invariant verified

The handoff approach rests on the canvas.alpha=0 window being a true window — no other code mutates canvas.alpha during T=2.10s to T=2.8s. Grep verification:

- [ ] Grep `canvas.alpha = ` in entire codebase
- [ ] Verify only RevealCoordinator's cross-fade completion sets canvas.alpha=0 and only performHandoff sets canvas.alpha=1
- [ ] If any other code path mutates canvas.alpha, surface and discuss

**Defensive measure:** if normalize fires while canvas.alpha != 0 (i.e., the invariant is broken), the normalize should not abort but it should log a warning. Add this guard:

```swift
func normalizeToChatRest(activeCellIndex: Int) {
    if alpha != 0 {
        print("⚠️ normalizeToChatRest called when canvas.alpha != 0 (alpha=\(alpha)); operations will be visible")
    }
    // ... rest of normalize ...
}
```

This is a temporary dev-only safety net; remove once the invariant is verified.

---

## §3 — Safe area & layout matching

This section addresses the most subtle technical risk in the handoff approach: the safe area divergence between chatVC.view and cell.chatContent caused by the cell's position-via-sublayerTransform. If we don't engineer around this, cell.chatContent's subviews land in the wrong place and the handoff is visible.

### §3.1 — The divergence explained

`UIView.safeAreaInsets` is computed by UIKit from the view's **logical frame** in its window-coordinate space, NOT from its render-time position. The render-time position is influenced by `superview.layer.sublayerTransform` (and ancestor transforms). UIKit's safe area system is intentionally blind to sublayerTransform because sublayerTransform was designed as a render-time effect (originally for 3D scene transforms), not as a layout transform.

In DotPinch, the cell's logical position is computed by `TimelineCanvas.layoutCellLayer` (line numbers approximate; verify). The cell's center Y is set to `naturalCenterY + extension/2 - naturalH/2` where `naturalCenterY` is computed from the cell-list's index and the canvas's vertical stride. For the first cell, `naturalCenterY` can be small (e.g., 100pt), and at chat-rest extension (844 - 200 = 644 extra height) the cell's logical position would extend FROM `naturalCenterY - naturalH/2 = 0pt` TO `naturalCenterY + naturalH/2 + 644 = 744pt`. But the rendered position is centered in the viewport via `morphCentering` (or analogous logic in normalize).

Critically: when normalize sets `heightConstraint.constant = 844` and `contentHost.transform = identity`, the LOGICAL frame of the cell is `frame.origin.y = naturalCenterY - 422`. For a cell whose `naturalCenterY` is small (say 171pt for the first cell at scroll y=0), this places `frame.origin.y = 171 - 422 = -251pt` in the contentHost's coordinate space. The cell's logical frame extends from y=-251 to y=+593 in window coords.

This makes the cell's `safeAreaInsets` come out wrong. UIKit looks at the cell's logical frame in window coords, sees it extends from -251 to +593, and computes safeAreaInsets.top based on the cell's frame intersecting the safe area at the top of the window. The result: cell.safeAreaInsets.top ≈ 47 + 251 = 298pt, instead of the 47pt that chatVC sees.

If we anchor `chatContent.header.topAnchor` to `cell.safeAreaLayoutGuide.topAnchor`, the header lands at y=298 inside the cell's local coords, which translates to window y = -251 + 298 = 47pt (which IS correct, accidentally!). But if we anchor to `cell.safeAreaLayoutGuide.topAnchor + 24`, it lands at window y=71. THIS IS WHAT CHATVC DOES. So maybe the safe area computation is correct after all?

Let me re-trace. The cell at chat-rest has logical frame y=-251 to +593 (844 tall). UIKit computes `safeAreaInsets.top` for the cell as the area at the TOP of the window that is occluded by the status bar (= 47pt). UIKit checks whether the cell's frame intersects this area. The cell's frame starts at y=-251, so the cell extends above the safe area boundary. UIKit's `safeAreaInsets.top` for a view that starts ABOVE the window's safe area boundary is `(window.safeArea.top) - view.frame.origin.y` = `47 - (-251)` = `298pt`.

So `cell.safeAreaInsets.top = 298pt`. If `chatContent.header.topAnchor = cell.safeAreaLayoutGuide.topAnchor + 24`, the header lands at `cell.bounds.origin.y + 298 + 24 = 0 + 322 = 322pt` in cell-local coords. Translating to window coords: cell at y=-251, header at cell-local 322, so window y = -251 + 322 = 71pt. **Which matches chatVC.**

So actually `cell.safeAreaInsets` works correctly for chat-rest because UIKit accounts for the cell extending above the safe area. The divergence only happens when the cell's logical position changes (e.g., during the cane curve when contentHost.transform is non-identity). At chat-rest with contentHost.transform=identity, the logical and rendered positions match.

**Wait, that's the key insight.** After normalize, `contentHost.transform = CATransform3DIdentity` and `cell.heightConstraint.constant = 844`. The cell's logical frame matches its rendered frame. UIKit's safe area computation is correct. The divergence we worried about earlier was during the CANE CURVE (when contentHost is at scale 4.92), but we're not laying out chatContent during the cane curve — chatContent is installed at T=1.6s (after cane curve completes) and laid out during the canvas.alpha=0 window (after normalize).

**Revised conclusion: Strategy A (cross-view constraints) is the safe approach AND `cell.safeAreaInsets` should work correctly after normalize.** Either approach should land the chatContent in the right place. We pick cross-view constraints (Strategy A) for an additional safety margin and for explicit semantic clarity (chatContent is anchored to the same safe area that chatVC.view sees).

### §3.2 — Verification plan for the safe area question

We must not act on reasoning alone. The divergence question is empirical. Verification plan:

- [ ] Add a temporary debug print to `cell.didLayoutSubviews` after normalize:
  ```swift
  print("cell.safeAreaInsets =", safeAreaInsets)
  print("cell.frame in window =", convert(bounds, to: window))
  ```
- [ ] Add the same to `chatVC.viewDidLayoutSubviews`:
  ```swift
  print("chatVC.view.safeAreaInsets =", view.safeAreaInsets)
  print("chatVC.view.frame in window =", view.convert(view.bounds, to: view.window))
  ```
- [ ] Compare the two: if `safeAreaInsets.top` differs by more than 1pt, the divergence is real and we need Strategy A's cross-view constraint approach.
- [ ] If the difference is 0, both approaches work; we still prefer Strategy A for explicitness.

This empirical verification MUST happen during Phase 0 (Verification & Prototyping) before any structural code is written. Acting on the reasoning above without verifying is the user's explicit anti-pattern (see `feedback_verify_dont_assume`).

### §3.3 — Cross-view constraint setup (Strategy A, the chosen approach)

The constraint setup in `ChatContentContainer.setupConstraints()` references `parentVC.view.safeAreaLayoutGuide` directly. The full constraint list is in §1.2's sketch. The load-bearing constraints are:

```swift
header.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor, constant: 24)
composer.bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor, constant: -12)
```

Both reference `parentView.safeAreaLayoutGuide`, which is the V2RootViewController.view's safe area. This guide is what UIVC's automatic layout uses for chatVC's view too (since chatVC is added as a child VC of V2RootVC). Therefore the visible positions of `chatContent.header` and `chatContent.composer` match `chatVC.headerLabel` and `chatVC.composerContainer` exactly.

### §3.4 — Theme color unification

`ChatViewController.view.backgroundColor = Theme.Page.surface` (verified in `ChatViewController.swift` likely around init). `CellView.backgroundColor = Theme.Cell.fill` (verified at `CellView.swift` line ~119 per the project_substrate_propagation_pinned memory).

**Open question:** are `Theme.Page.surface` and `Theme.Cell.fill` the same color value?

- [ ] Read `DesignSystem/Theme.swift` to verify
- [ ] If same: no action needed (cell.chatContent inherits cell's background by being opaque OR can have explicit backgroundColor = Theme.Page.surface)
- [ ] If different: chatContent must explicitly set `backgroundColor = Theme.Page.surface`, and the visible region of cell beyond chatContent's bounds (if any) must also match. Practically, since chatContent fills cell edge-to-edge (constraints in §1.3), the cell background is occluded by chatContent's opaque background and only chatContent's color matters.

The `isOpaque = true` setting on `ChatContentContainer` is critical: it prevents any bleed-through to the cell's background and improves rendering performance (UIKit can skip alpha compositing for opaque views).

**Decision provisional:** Set `chatContent.backgroundColor = Theme.Page.surface` explicitly. This makes the alpha swap at handoff strictly visually identical regardless of whether Theme constants happen to align.

**Tasks:**
- [ ] Verify Theme.Page.surface value
- [ ] Verify Theme.Cell.fill value
- [ ] If different, set `chatContent.backgroundColor = Theme.Page.surface` explicitly in init
- [ ] Set `chatContent.isOpaque = true`

### §3.5 — chatVC.view's existing layout (the spec to match)

For reference, the layout constraints chatVC uses (from the existing `ChatViewController.swift`):

- **headerLabel:**
  - `topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24)`
  - `centerXAnchor.constraint(equalTo: view.centerXAnchor)`
  - `leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20)`
  - `trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)`
- **scrollView (containing bubbleStack):**
  - `topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 24)`
  - `leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)`
  - `trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)`
  - `bottomAnchor.constraint(equalTo: composerContainer.topAnchor, constant: -16)`
- **bubbleStack inside scrollView:**
  - Pinned to scrollView.contentLayoutGuide on all four edges
  - `widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)`
  - `axis = .vertical, alignment = .fill, spacing = 16`
- **composerContainer:**
  - `leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)`
  - `trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)`
  - `bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)`
  - `heightAnchor.constraint(equalToConstant: 44)`
  - `backgroundColor = Theme.Cell.fill, layer.cornerRadius = 22, layer.cornerCurve = .continuous`
- **composerTextField inside composerContainer:**
  - `leadingAnchor.constraint(equalTo: composerContainer.leadingAnchor, constant: 16)`
  - `trailingAnchor.constraint(equalTo: composerContainer.trailingAnchor, constant: -16)`
  - `centerYAnchor.constraint(equalTo: composerContainer.centerYAnchor)`
  - `font = Theme.Typography.composerHint, textColor = Theme.Text.primary, placeholder = "Share with Dot…", borderStyle = .none`

Tasks:
- [ ] Read `ChatViewController.swift` and verify constraint values (above is from memory; confirm)
- [ ] Replicate each constraint in `ChatHeaderView`, `ChatBubbleStackView`, `ChatComposerView` setup
- [ ] Replicate styling (cornerRadius, cornerCurve, backgroundColor, font, color, placeholder, borderStyle)
- [ ] Side-by-side screenshot test: chatVC.view at chat-rest vs cell.chatContent post-handoff — pixel diff <1pt

### §3.6 — Cross-view constraint retain cycle risk

Cross-view constraints reference `parentView.safeAreaLayoutGuide.topAnchor`. The constraint object retains both anchors. Anchors are owned by their guide; the guide is owned by the view. So the chain is:

```
ChatContentContainer (subview of cell) ──owns──> NSLayoutConstraint
                                                     │
                                                     ├──> chatContent.header.topAnchor (owned by header, ultimately by cell)
                                                     └──> parentView.safeAreaLayoutGuide.topAnchor (owned by guide, owned by parentView=V2RootVC.view)
```

The constraint does NOT directly retain `parentView`. It retains the anchor; the anchor is owned by the guide; the guide is owned by `parentView`. Anchors do not back-reference their owners. So the constraint cannot keep `parentView` alive past its natural lifetime.

But: `ChatContentContainer.parentVC` is `weak`, so chatContent does not retain parentVC. The chain is one-directional: chatContent → constraint → anchor → guide → parentView. parentView has no reference back to chatContent. No cycle.

**Verification:**
- [ ] Run Instruments Allocations with the handoff flow active for 100 round-trips
- [ ] Verify no `ChatContentContainer` instances accumulate beyond the cell pool's bound (20)
- [ ] Verify no `ConversationStateController` instances accumulate
- [ ] Verify `parentVC` does not retain `chatContent` (i.e., V2RootVC.view.subviews does not contain chatContent — chatContent is a subview of cell, not of V2RootVC.view)

### §3.7 — What happens to constraints on cell pool eviction

When a cell is evicted from the cell pool (LRU bound at 20), the cell's `chatContentContainer` is released along with the cell. But the cross-view constraints reference `parentVC.view.safeAreaLayoutGuide`. UIKit will deactivate these constraints automatically when one of their endpoints is deallocated (chatContent.header.topAnchor goes away with chatContent which goes away with cell).

**Defensive cleanup (explicit teardown):**

```swift
// In CellView, when the cell is rebound to a different conversation OR evicted:

func prepareForRebind() {
    chatContentContainer?.teardownCrossViewConstraints()
    chatContentContainer?.removeFromSuperview()
    chatContentContainer = nil
}
```

Tasks:
- [ ] Add explicit `teardownCrossViewConstraints` call in cell rebind / eviction path
- [ ] Verify no constraint warnings in console when a cell is evicted

### §3.8 — Rotation behavior

The app is portrait-only on iPhone per `project.yml`. iPad allows all orientations. On rotation:

- `parentView.safeAreaLayoutGuide` updates (UIKit notifies on safe area changes)
- Cross-view constraints anchored to it propagate updates to chatContent's subviews
- `canvas.bounds.height` changes; `cell.heightConstraint.constant` must update to match the new bounds.height

**Tasks (iPad only, can defer):**
- [ ] Observe rotation; update `cell.heightConstraint.constant = canvas.bounds.height` after rotation completes
- [ ] Verify chatContent layout responds correctly (verified by cross-view constraints automatically; no manual work needed for header/composer positions)
- [ ] Test on iPad simulator

### §3.9 — Acceptance criteria (§3 summary)

- [ ] Side-by-side screenshot at T=2.79s (just before handoff) and T=2.81s (just after handoff): pixel-identical or <1pt difference
- [ ] Run on iPhone 16, iPhone SE (3rd gen), iPhone 16 Pro Max: layout correct on all
- [ ] No constraint warnings in console at any point in the forward path
- [ ] Theme.Page.surface verified; chatContent.backgroundColor explicitly set
- [ ] No retain cycles via Instruments

---

## §4 — State transfer

This section is the contract for what state moves from chatVC to cell.chatContent at handoff, when it moves, and how it moves. Mis-handled state shows up as visible glitches (composer text reverts, scroll position jumps, keyboard flickers).

### §4.1 — The decision: capture-at-handoff, not continuous sync

Two patterns considered:

**Continuous sync (rejected):** Subscribe to chatVC's text field changes (UIControl.editingChanged), scroll delegate's `scrollViewDidScroll`, etc. Every change in chatVC mirrors to cell.chatContent immediately. At handoff, the alpha swap is the only operation needed.

- Pros: handoff is simpler; state is "always" in sync.
- Cons: complex subscription wiring; double-write to every user input (chatVC handles it AND state controller propagates to cell.chatContent); cell.chatContent's text field may fire its own change events as a result of the propagation, causing a subscription loop.

**Capture-at-handoff (chosen):** chatVC is the sole interactive surface from T=2.10s to T=2.8s. cell.chatContent is invisible and non-interactive during this window. At T=2.8s, capture chatVC's state into the state controller, apply to cell.chatContent, do the alpha swap.

- Pros: simpler; no subscription loops; clear ownership (chatVC owns state until handoff; cell.chatContent owns state after handoff).
- Cons: handoff has more work; rare race conditions if state changes during the capture-apply window (negligible because it's <1ms).

Tasks:
- [ ] D6 — confirm capture-at-handoff (chosen)
- [ ] Document in §14 Decision Log

### §4.2 — What state transfers (the canonical list)

Per `ConversationStateController` (§1.4), the state set is:

| Field | Type | Captured from chatVC via | Applied to cell.chatContent via |
|---|---|---|---|
| composerText | String | `chatVC.composerTextField.text ?? ""` | `cell.chatContent.composer.composerTextField.text = composerText` |
| scrollOffset | CGPoint | `chatVC.scrollView.contentOffset` | `cell.chatContent.bubbleStack.scrollView.contentOffset = scrollOffset` |
| composerIsFirstResponder | Bool | `chatVC.composerTextField.isFirstResponder` | (deferred to post-CATransaction; see §4.5) |
| selectedTextRange | UITextRange? | `chatVC.composerTextField.selectedTextRange` | (deferred to post-CATransaction; see §4.5) |

**Not transferred (left at default in cell.chatContent):**
- Scroll velocity / deceleration momentum — see §4.6
- IME composition state (e.g., partial dictation input) — see §4.7
- Selection rect / cursor blink phase — UIKit handles
- Keyboard frame — UIKit handles via responder transition

### §4.3 — When state transfers happen (exact sequence)

The capture-apply sequence happens in `performHandoff` (§2.4). The exact order:

1. **T=2.80000s — captureFromChatVC**: read all four fields synchronously into state controller properties.
2. **T=2.80000s — applyTo(chatContent)** (still synchronous, same runloop tick): write composerText and scrollOffset to cell.chatContent. Do NOT becomeFirstResponder yet.
3. **T=2.80000s — CATransaction.withSuppressedActions**: atomic alpha swap (chatVC.alpha 1→0, canvas.alpha 0→1, chatContent.alpha 0→1, pinchRecognizer enabled).
4. **T=2.80001s — post-transaction**: if composerIsFirstResponder was true, call `cell.chatContent.composer.composerTextField.becomeFirstResponder()`. Then apply `selectedTextRange` if non-nil.
5. **T=2.80002s — chatVC teardown**: willMove(nil), removeFromSuperview, removeFromParent, release strong reference.

All five steps happen within ~1ms on the main thread. The frame at T=2.80s renders the post-handoff state in a single render pass.

### §4.4 — Why first-responder transfer is deferred to post-CATransaction

If we set first-responder INSIDE the CATransaction.withSuppressedActions, UIKit may flag becomeFirstResponder as triggering an implicit animation (the keyboard's display change), and we don't want to suppress THAT animation — we want the keyboard to STAY visible. So we exit the CATransaction first, then call becomeFirstResponder while the canvas/chatContent are already visible.

If we set first-responder BEFORE the alpha swap (i.e., before chatVC is hidden), the new responder is set on cell.chatContent which is still alpha=0. The keyboard might not display because the responder's view is invisible. Some UIKit versions handle this, others don't. Empirical testing required.

**Safest order:** alpha swap first (chatVC alpha=0, chatContent alpha=1, both views still in hierarchy), then becomeFirstResponder on chatContent's text field, then remove chatVC.

**Edge case:** if the user is mid-typing and the IME (e.g., Japanese/Chinese input) has composition state, that composition state is lost when the responder transitions. There is no UIKit API to transfer IME composition. Acceptable trade-off; document.

### §4.5 — First-responder transfer code

```swift
// In performHandoff, after the CATransaction:

if stateController.composerIsFirstResponder {
    let textField = cell.chatContent.composer.composerTextField
    let success = textField.becomeFirstResponder()
    assert(success, "becomeFirstResponder failed on cell.chatContent.composerTextField")

    if let savedRange = stateController.selectedTextRange,
       let mappedRange = mapTextRange(from: chatVC.composerTextField, to: textField, range: savedRange) {
        textField.selectedTextRange = mappedRange
    }
}
```

**Note on `mapTextRange`:** `UITextRange` is opaque and tied to its source text field's internal range representation. We cannot directly assign a `UITextRange` from chatVC's text field to cell.chatContent's text field. We must map via positions:

```swift
private func mapTextRange(
    from source: UITextField,
    to dest: UITextField,
    range: UITextRange
) -> UITextRange? {
    let startOffset = source.offset(from: source.beginningOfDocument, to: range.start)
    let endOffset = source.offset(from: source.beginningOfDocument, to: range.end)
    guard let destStart = dest.position(from: dest.beginningOfDocument, offset: startOffset),
          let destEnd = dest.position(from: dest.beginningOfDocument, offset: endOffset) else {
        return nil
    }
    return dest.textRange(from: destStart, to: destEnd)
}
```

Tasks:
- [ ] Implement `mapTextRange` helper (place in ConversationStateController or as a free function)
- [ ] Use offset-based mapping (not direct UITextRange assignment)
- [ ] Test with cursor positioned at start, middle, end of composer text
- [ ] Test with text selection (non-empty range)

### §4.6 — Scroll momentum is lost (acceptable)

When user is mid-scroll (decelerating) and handoff fires, `chatVC.scrollView.contentOffset` captures the current offset but `contentVelocity` is not transferred. The cell.chatContent's scrollView starts at the captured offset with zero velocity. The bubble stack stops moving.

This is a one-frame visual difference: the bubbles stop where the handoff captures, instead of continuing to decelerate. For the user, this is barely perceptible because:
- The handoff happens at T=2.8s, well after the cross-fade started at T=2.10s. The user has been LOOKING at chatVC for 0.7s by handoff time.
- If the user is actively scrolling during chat-state present, they're probably not also pinching to collapse. The forward-direction handoff is a one-time event.
- Even if scrolling, the deceleration is on the order of 0.3-0.5s; losing the tail of it is barely noticeable.

If profiling shows this is noticeable, scroll velocity can be transferred via:

```swift
// Capture:
let velocity = chatVC.scrollView.panGestureRecognizer.velocity(in: chatVC.scrollView)

// Apply (after the apply):
cell.chatContent.bubbleStack.scrollView.setContentOffset(scrollOffset, animated: false)
// Then trigger deceleration manually — but UIScrollView's deceleration is not directly drivable.
// Workaround: use a CADisplayLink-based decay until velocity reaches 0.
```

The workaround is non-trivial. Defer unless empirically needed.

Tasks:
- [ ] Document scroll momentum loss as known minor visual difference
- [ ] Measure perceptibility on physical device during dev
- [ ] If perceptible, implement velocity transfer (deferred work)

### §4.7 — IME composition state (acceptable loss)

Multi-stage IMEs (Japanese kana→kanji conversion, Chinese pinyin→hanzi, dictation streaming partials) maintain composition state inside the text field. When the responder transitions to a new text field, this composition state is lost.

Mitigation: the responder transition happens AFTER the alpha swap, so the user sees the keyboard stay visible. The composition state loss is invisible unless the user was actively composing — and the user is unlikely to be actively composing AND simultaneously pinching to collapse.

**Document this as a known minor edge case.** Do not attempt to transfer IME state.

### §4.8 — State persistence across cell pool round-trip

After handoff, the state controller is owned by the cell (per §1.4 D4 decision). When the user pinches the cell back to cell-rest (reverse direction), the cell remains in the cell pool. The state controller remains alive. The chatContent remains alive.

When the user later re-taps cell A:
- `cellPoolByConversationID[A.id]` returns the same cell instance
- `cell.chatContentContainer` is still present
- `cell.stateController` is still present
- `cell.installChatContentIfNeeded` is called again; the idempotency guard returns early
- chatContent already has the user's previous composer text + scroll offset (because the state controller preserved them across the round-trip and chatContent's local state survived)

But: a NEW chatVC is instantiated by RevealCoordinator. The new chatVC's composer is empty, scroll at 0. At handoff (T=2.8s of the second present), the state controller captures the NEW chatVC's empty state and applies to cell.chatContent. THIS WOULD OVERWRITE THE PRESERVED STATE.

**This is a bug.** The fix:

Option 1: chatVC inherits state from the state controller AT INSTANTIATION time. RevealCoordinator.installChatViewController calls `stateController.bind(to: chatVC)` which writes composerText, scrollOffset, etc. into chatVC at present time. Then capture-at-handoff captures from chatVC (which already has the state) and applies to chatContent. State preserved.

Option 2: skip the capture-apply if chatContent's state is already preserved. Detect via a flag. Complex.

**Decision: Option 1.** Bind state controller to chatVC at install time. The state controller becomes the canonical source; chatVC and chatContent are both views rendering from it.

```swift
// In RevealCoordinator.installChatViewController, after chatVC.configure(with: conversation):

if let stateController = cell.stateController {
    chatVC.composerTextField.text = stateController.composerText
    // scrollOffset applied after layout completes (scrollView.contentOffset needs valid contentSize first)
    DispatchQueue.main.async {
        chatVC.scrollView.contentOffset = stateController.scrollOffset
    }
}
```

Tasks:
- [ ] Add state-binding to chatVC at install time
- [ ] Ensure cell owns a single ConversationStateController instance (created on cell.configure, persisted across round-trips)
- [ ] Verify the round-trip test: tap A → type "hello" → pinch back → tap A → composer shows "hello"
- [ ] Verify isolation: tap A → type "hello" → pinch back → tap B → composer empty (B's state is independent)

### §4.9 — Acceptance criteria (§4 summary)

- [ ] Composer text transfers correctly (test with empty, short, long text)
- [ ] Scroll offset transfers correctly (test at top, middle, bottom of scrollable content)
- [ ] First responder transfers without keyboard dismiss-reappear (verify via slow-motion recording)
- [ ] Selected text range transfers correctly (test with cursor at start, middle, end, and with non-empty selection)
- [ ] Round-trip preserves state (chat A, type, pinch back, tap A again — state preserved)
- [ ] Isolation between conversations (tap A → tap B → tap A — A's state preserved, B's state isolated)

---

## §5 — Identity preservation

The cell pool's identity-keyed semantics (`cellPoolByConversationID`) is the substrate primitive that makes round-trip state preservation possible. This section maps the existing identity guarantees onto the new types (chatContent, stateController).

### §5.1 — Existing identity guarantee

From `CONTEXT.md` and the codebase: cells in `cellPool` are *type-keyed at dequeue but data-keyed at re-attach*. The LRU-bounded dict `cellPoolByConversationID: [UUID: CellView]` (cap=20) preferentially returns the same cell instance for the same conversation across present/dismiss cycles. When the cap is exceeded, the least-recently-used entry is evicted (via the `poolOrder` array).

This means: if the user taps cell A, pinches back, taps A again within ≤20 unique-cell-taps, the SAME `CellView` instance is returned. Anything attached to that cell instance (subviews, properties) persists.

### §5.2 — How chatContent inherits this guarantee

`cell.chatContentContainer` is a strong property of `CellView`. It persists for the lifetime of the cell instance. Therefore:

- Tap A → cell A.chatContent created (T=1.6s of first present)
- Pinch back → cell A returned to pool (cell.heightConstraint shrinks; chatContent's alpha animates to 0 via setCamera)
- Tap A → cell A returned from pool (same instance); cell.installChatContentIfNeeded sees existing chatContent and no-ops
- chatContent's scroll offset, composer text are preserved (because chatContent itself is preserved)

When the pool evicts cell A (because 20 other conversations were tapped), cell A is deallocated, and chatContent is released along with it. This is correct behavior — bounded memory.

### §5.3 — How stateController inherits this guarantee

`cell.stateController` should also be a strong property of `CellView`, created lazily on `cell.configure(with:)`:

```swift
// CellView.configure(with:) additions:

func configure(with conversation: Conversation) {
    self.conversation = conversation
    // existing chrome configuration ...

    // NEW: if this cell is being rebound to a DIFFERENT conversation, tear down old state
    if let existingController = stateController,
       existingController.conversationID != conversation.id {
        teardownChatContent()
        stateController = nil
    }

    // Lazy-create state controller for this conversation
    if stateController == nil {
        stateController = ConversationStateController(conversationID: conversation.id)
    }
}
```

**Root-cause-trace on stateController lifecycle:**
- Q1 (Rests on): The cell pool's `dequeueCell(preferredConversationID:)` returns the cell that was previously bound to `preferredConversationID` if available. The returned cell still has `stateController.conversationID == preferredConversationID`. The configure call detects identity match and preserves stateController.
- Q2 (Why this design): Alternative is for `V2RootViewController` or `RevealCoordinator` to own a `[UUID: ConversationStateController]` dict. But then state controllers can outlive their cells, leading to unbounded memory growth. Owning per-cell mirrors the bounded pool semantics.
- Q3 (Assumes): A cell never holds two state controllers simultaneously. True: the configure() teardown ensures this.
- Q4 (If changed): If we kept a single global `[UUID: ConversationStateController]` on V2RootVC, memory grows unbounded (one entry per conversation ever viewed). Eviction policy would need its own LRU mirroring the cell pool's, with the risk of getting out of sync.
- Q5 (If removed): Without state controller, state lives in chatVC and chatContent independently. Round-trip preservation requires manual sync between the two, with all the complexity that entails.
- Q6 (Absent): No mechanism to flush state controllers on conversation deletion. Add: observe ConversationStore deletions, teardown state controllers for deleted conversations.

Tasks:
- [ ] Add `stateController: ConversationStateController?` as strong property of CellView
- [ ] Add lazy creation in `cell.configure(with:)`
- [ ] Add identity-mismatch teardown logic
- [ ] Verify state controller is deallocated when cell is evicted (Instruments)
- [ ] Verify state controller persists across pool round-trip for same conversation

### §5.4 — ChatVC instance: release, do not cache

Decision (per §1.5): release ChatVC each present. Reasoning recap:
- State preservation is handled by the state controller; ChatVC is just a transient renderer.
- Re-instantiation cost is ~15-30ms — acceptable.
- Caching adds an LRU mirror that must stay in sync with cellPool's LRU. Sync bugs would cause subtle state leaks.

If profiling later shows ChatVC instantiation is a hotspot (e.g., long conversations with hundreds of bubbles), consider:
- Lazy bubble creation (only top N bubbles initially)
- ChatVC instance cache (`[UUID: ChatViewController]` LRU bound at 20)
- ChatBubbleStackView reused across ChatVC instances (probably too complex)

Tasks:
- [ ] After handoff: `chatViewController = nil` to release strong reference
- [ ] Verify chatVC.deinit fires (add temp log)
- [ ] Profile instantiation cost during dev; if >50ms for typical conversations, revisit

### §5.5 — Identity-keyed cell pool — what the work does NOT touch

The cell pool's contracts are unchanged:
- `maxKeyedPoolSize = 20` — untouched
- `dequeueCell(preferredConversationID:)` — untouched
- `returnToPool(_:)` — untouched (we never `removeFromSuperview` cells from outside the pool)
- `cellPoolByConversationID` LRU eviction — untouched
- `poolOrder` ordering — untouched

The work in this checklist ADDs to cell state (chatContent, stateController) but does not modify pool semantics.

### §5.6 — Acceptance criteria (§5 summary)

- [ ] Tap A → type "hello" → pinch back → tap A: composer shows "hello"
- [ ] Tap A → scroll bubbles → pinch back → tap A: scroll position preserved
- [ ] Tap A → type "hello" → pinch back → tap B (different convo): B's composer empty
- [ ] Tap 21 unique conversations in sequence → first one evicted from pool: tapping again creates fresh state (no leaked old state)
- [ ] No state controllers leaked beyond 20 (Instruments verified)
- [ ] No chatContent containers leaked beyond 20 (Instruments verified)

---

## §6 — Reverse direction wiring

After handoff, the cell IS the chat. The reverse direction (pinch-in on the cell at chat-rest → spring back to cell-rest) must work natively against this state. The existing `handlePinchBegan/Changed/Ended` flow in `TimelineCanvas` is the engine; we wire up the post-handoff state to feed it correctly.

### §6.1 — What's already in place

`TimelineCanvas` already implements the reverse direction (the `.pinchToCells` commit branch in `handlePinchEnded` at ~line 1141). It just hasn't been reachable. Specifically:

- `handlePinchBegan` (~line 1011): captures initial pinch scale and `cell.heightConstraint.constant` as `initialExtension`.
- `handlePinchChanged` (~line 1056): writes `cell.heightConstraint.constant` based on pinch scale × initialExtension, clamped to `[naturalH, chatRestExtension × 1.15]` (the 1.15 is the rubberband ceiling).
- `setCamera` (`CellView.swift` around line 253): driven by gesture per-tick OR by spring animator per-tick. Computes `progress = (heightConstraint - naturalH) / (chatRestExtension - naturalH)`. Currently maps progress to: `labelStack.alpha = 1 - smoothstep(0.05, 0.30, progress)`, `pinchGlyph.alpha = 1 - smoothstep(0.05, 0.30, progress)`.
- `handlePinchEnded` (~line 1097): classifies commit. From chat-rest origin (initialExtension ≈ 844), commits to:
  - `.tapToChat` (no-op, already at chat-rest) if user pinched out further then released
  - `.pinchToCells` if pinch-in below threshold
  - `.cancelled` if velocity-based criteria fail
- `springToCellRest` (~line 1469): targets `naturalH` with critically damped spring (damping = 1.0).
- `tryClearActiveCellAtRest` (~line 1514): when both springs settle, sets `activeCellIndex = nil`, re-enables `panRecognizer`.

### §6.2 — What needs to be added

**Required additions:**

1. **Re-enable `canvas.pinchRecognizer.isEnabled = true` at handoff** (already covered in §0.4 step 3 and §2.4).

2. **Extend `CellView.setCamera` to drive `chatContentContainer.alpha` and `chatRestCenterLabel.alpha`:**

```swift
// CellView.setCamera additions (sketch):

func setCamera(_ camera: CameraState) {
    guard !morphInProgress else { return }  // existing guard

    let progress = computeProgress()  // (heightConstraint - naturalH) / (chatRestExt - naturalH)
    let clamped = max(0, min(1, progress))

    CATransaction.withSuppressedActions {
        // Existing chrome curves:
        labelStack.alpha = 1 - smoothstep(0.05, 0.30, clamped)
        pinchGlyph.alpha = 1 - smoothstep(0.05, 0.30, clamped)

        // NEW: chatContent fade curve — content visible at chat-rest, fades out as user pinches in
        // Curve choice: visible above progress 0.5, fully gone below progress 0.3
        chatContentContainer?.alpha = smoothstep(0.30, 0.50, clamped)

        // NEW: chatRestCenterLabel is fully off at chat-rest (post-handoff state)
        // because chatContent shows its own header. Stays at 0 throughout reverse.
        chatRestCenterLabel.alpha = 0
    }
}
```

**Root-cause-trace on the curve choice:**
- Q1 (Rests on): `smoothstep(0.30, 0.50, progress)` evaluates to 0 below 0.30, ramps 0→1 between 0.30 and 0.50, evaluates to 1 above 0.50.
- Q2 (Why these thresholds): The chrome (labelStack, pinchGlyph) fades IN as progress drops below 0.30 (using `1 - smoothstep(0.05, 0.30, progress)`). chatContent must fade OUT before chrome fades IN — otherwise the user sees both simultaneously, which is visually busy. Setting chatContent's lower threshold at 0.30 (where chrome is fully in) gives a clean handoff between representations.
- Q3 (Assumes): The user perceives 0.30–0.50 as a smooth fade, not a step. Verified empirically — smoothstep with 0.20 width feels smooth.
- Q4 (If different thresholds): Wider (e.g., 0.20–0.60) means both representations overlap longer — content shows over chrome briefly. Acceptable but less crisp. Narrower (e.g., 0.40–0.45) means a near-step transition — feels abrupt.
- Q5 (If removed): chatContent never fades; user sees chat content over cell-rest chrome at progress=0. Visually broken.
- Q6 (Absent): No curve for chatRestCenterLabel after handoff. We hold it at 0 throughout reverse since chatContent shows the header. If the user pinches back, chatRestCenterLabel never reappears — acceptable because chatContent's header is the day-marker now.

3. **Update `morphInProgress` predicate (or the early-return logic in `setCamera`):**

The existing `setCamera` early-returns if `morphInProgress = morphChoreographer?.isRunning ?? false`. During reverse (pinch from chat-rest), `morphChoreographer` is NOT running — the gesture drives heightConstraint directly. So `morphInProgress = false` and `setCamera` runs. **Existing logic already correct.**

But there's a subtle issue: during FORWARD via the tap path, `morphChoreographer` is also NOT running (the tap path uses cane curve on contentHost.layer, not morphChoreographer). However, during forward via tap, setCamera should NOT fire alpha changes because the cane curve and `performMorphChromeTransition` are handling chrome alphas. We need to verify setCamera isn't being called during the tap forward path.

**Verification task:**
- [ ] Add temp log to `setCamera` first line: print "setCamera called at \(Date())"
- [ ] Tap a cell; observe logs
- [ ] Expected: setCamera NOT called during T=0 to T=2.8s (no canvas pan or pinch, so no camera updates)
- [ ] After handoff at T=2.8s, `performHandoff` explicitly calls `canvas.setCamera()` once to refresh alphas; verify this one call sets chatContent.alpha=1, labelStack.alpha=0
- [ ] During reverse (pinch on cell), verify setCamera fires per gesture event with progress decreasing from 1.0 toward 0

### §6.3 — Spring physics and commit decision

From chat-rest (initialExtension ≈ 844), the commit decision in `handlePinchEnded`:

```swift
let originatedFromCellRest = (initialExtension <= naturalH * 1.05)  // = (844 <= 210) = false
let endedNearChatRest = (cell.heightConstraint.constant >= chatRestExt * 0.95)
let commit: GestureCommit
if endedNearChatRest {
    commit = .tapToChat  // No-op, already at chat-rest (just settle there)
} else if originatedFromCellRest {
    commit = .cancelled  // Shouldn't happen for reverse direction
} else {
    commit = .pinchToCells  // Engage spring back to cell-rest
}
```

For reverse direction:
- User pinches in significantly (heightConstraint drops to e.g. 400) → `endedNearChatRest = false`, `originatedFromCellRest = false` → `.pinchToCells`
- `springToCellRest(cell:, velocity:)` engages: critically damped spring (damping=1.0) targets `naturalH = 200`

Tasks:
- [ ] Verify handlePinchEnded's classification works from initialExtension = 844 (test empirically)
- [ ] Verify springToCellRest receives correct velocity (from pinch recognizer's `velocity(in:)`)
- [ ] Verify spring critically dampens (no oscillation; settles cleanly)

### §6.4 — Spring settle clears activeCellIndex

When `springToCellRest`'s two springs (heightConstraint spring + camera spring) both settle, `tryClearActiveCellAtRest` fires:

```swift
// Existing logic (verify line numbers):
private func tryClearActiveCellAtRest() {
    guard let cell = activeCell, !cell.heightSpringRunning, !cameraAnimator.isRunning else { return }
    activeCellIndex = nil
    panRecognizer.isEnabled = true
    restoreNaturalSiblingOrder()
}
```

After settle: `activeCellIndex = nil`, panRecognizer re-enabled (user can pan the cell-list), `restoreNaturalSiblingOrder` returns the cell to its original z-order.

**Cell.chatContent at progress=0:** setCamera writes `chatContent.alpha = 0` (from the curve in §6.2). The chatContent remains structurally present in the cell but invisible. Memory cost: ~50-200KB per cached cell. Acceptable.

Tasks:
- [ ] Verify tryClearActiveCellAtRest fires after both springs settle (existing behavior, verify still works)
- [ ] Verify chatContent.alpha = 0 at progress=0 (via setCamera)
- [ ] Verify chatContent is NOT removed from cell (just hidden)
- [ ] Verify pan recognizer re-enabled (user can scroll cell-list)

### §6.5 — What chatContent.alpha=0 during cell-rest means

After reverse completes, the cell is back at cell-rest, chrome visible, chatContent invisible. The cell has TWO sets of subviews in its hierarchy:
- Cell-rest chrome (labelStack, pinchGlyph, chatRestCenterLabel) — labelStack and pinchGlyph at alpha=1, chatRestCenterLabel at alpha=0
- chatContent (header, bubbleStack, composer) — all at alpha=0 because container alpha=0

This is wasted view tree but bounded (≤20 cells in pool, each with ≤200KB chatContent). The benefit is round-trip state preservation: tap A again, chatContent.alpha animates back to 1 via the same setCamera curves, and the state controller pre-binds composer/scroll state to chatVC and chatContent.

If memory pressure forces a leaner approach later, chatContent could be torn down on cell-rest settle (after a debounce — e.g., if user has been at cell-rest for 5s, release chatContent; rebuild on next tap). Defer this optimization.

### §6.6 — Edge: user re-pinches back to chat-rest during reverse spring

If the spring is mid-animation (e.g., heightConstraint at 500, animating down) and the user starts a new pinch gesture, the spring must be interrupted gracefully.

Existing logic: `handlePinchBegan` calls `cell.heightSpringStop()` and `cameraAnimator.stop()`. The spring's current value becomes the new pinch starting point. `initialExtension = cell.heightConstraint.constant` (whatever the spring had reached). Subsequent gesture works from there.

**Verify:** during a reverse spring, start a new pinch. Expected:
- Spring stops (verify via log)
- handlePinchChanged drives heightConstraint from the interrupted value
- handlePinchEnded re-classifies (may commit to .tapToChat or .pinchToCells depending on the new pinch's end state)

Tasks:
- [ ] Test mid-spring interruption (start a new pinch during the reverse spring)
- [ ] Verify no glitches in the heightConstraint trajectory

### §6.7 — Acceptance criteria (§6 summary)

- [ ] Post-handoff: pinching on chat surface initiates `handlePinchBegan` (log verified)
- [ ] During pinch: heightConstraint shrinks visibly, chatContent fades out (via setCamera curve)
- [ ] During pinch: cell-rest chrome fades in (via existing setCamera curves)
- [ ] Pinch release below commit threshold: spring engages, settles at naturalH
- [ ] After settle: activeCellIndex = nil, panRecognizer enabled, user can scroll cell-list
- [ ] Mid-spring interruption (new pinch during spring) works without glitches
- [ ] No alpha jitter at progress=0.30 boundary (smoothstep ensures smooth)

---

## §7 — Edge cases

Each edge case is enumerated with: trigger, current behavior (without the new code), required behavior (with the new code), implementation.

### §7.1 — Scene deactivation between T=2.10s and T=2.8s

**Trigger:** user swipes down Control Center / receives a call / switches apps in the 700ms window where normalize is scheduled or in-flight.

**Current behavior (without new code):** `V2RootViewController.handleSceneWillDeactivate` calls `canvas.cancelInFlightAnimations()` + `revealCoordinator.cancelInFlight()`. cancelInFlight stops `blurFadeIn/crossFade/blurFadeOut` animators via `finishAnimation(at: .current)`. crossFade's completion typically fires (UIViewPropertyAnimator's finishAnimation does invoke completion), so the existing canvas.alpha=0 set happens. blurFadeOut's completion may or may not have fired yet.

**Required behavior (with new code):** the normalize and handoff must either run to completion or leave the system in a recoverable state. Specifically:
- If scene deactivates BEFORE normalize fires: chatVC is still visible (alpha=1). Canvas is at alpha=0. User returns to a state where chatVC.view is still on top. Acceptable degraded state.
- If scene deactivates DURING normalize: CATransaction.withSuppressedActions completes synchronously within ~1ms. Scene deactivation can't interrupt synchronous code. Normalize will complete.
- If scene deactivates AFTER normalize but BEFORE blurFadeOut completion: normalize is done. blurFadeOut.cancelInFlight fires; its completion may invoke performHandoff. If it does, handoff runs; if it doesn't, chatVC remains visible AND the canvas is now normalized. The atomic swap didn't happen, so canvas.alpha is still 0 and chatVC.alpha is still 1.

**The trap:** if blurFadeOut.cancelInFlight does NOT fire the completion (depends on `finishAnimation(at: .current)` behavior with reverse=false), the user returns to a state where:
- chatVC.view alpha=1 (visible)
- canvas.alpha=0 (invisible, but normalized)
- cell.chatContent.alpha=0 (invisible)
- chatVC's removeFromSuperview/removeFromParent has not happened

This is consistent visually (user sees chatVC) but the canvas is in a transitional state. If the user backgrounds the app here, then returns, they should see the same chatVC. If they hard-quit the app and relaunch, they should see the cell-list (because chat-state isn't persisted to disk).

**Implementation:**
- [ ] Verify `cancelInFlight()` behavior with blurFadeOut: does the completion fire?
  - Read `RevealCoordinator.cancelInFlight()`
  - If completion fires: handoff runs even on deactivation; consistent post-handoff state
  - If completion does NOT fire: chatVC remains on top in degraded-but-consistent state
- [ ] Add `revealCoordinator.completeHandoffIfPending()` method that performs the handoff if it hasn't already
- [ ] On `UIScene.willEnterForegroundNotification`, check if revealCoordinator is in a partial-handoff state (chatVC visible AND canvas normalized) — if so, drive the handoff synchronously
- [ ] Test: launch app, tap cell, swipe to Control Center between T=2.2s and T=2.7s, return — verify state is one of: pre-handoff (chatVC visible) or post-handoff (chatContent visible), never partial

### §7.2 — Scene deactivation DURING normalize

**Trigger:** scene deactivates within the ~1ms normalize window.

**Behavior:** normalize is synchronous; it runs inside `CATransaction.withSuppressedActions` which commits inside the same runloop tick. Scene deactivation notifications are dispatched asynchronously by UIKit; they cannot interrupt synchronous code on the main thread.

**Implementation:** no special handling needed. Normalize either has run or has not run, never partially.

- [ ] No code changes; document this as not-an-issue.

### §7.3 — User backgrounds app while in chat-state (post-handoff)

**Trigger:** user is in chat-state (post-handoff, cell.chatContent visible), backgrounds the app, returns later.

**Behavior:** standard iOS backgrounding. View state is preserved. On return:
- Cell.chatContent still visible (alpha=1, frame correct)
- Canvas alpha=1
- pinchRecognizer enabled

No special handling needed unless the user backgrounds for so long that the cell pool is evicted (rare; backgrounding doesn't trigger pool eviction).

- [ ] No code changes; document.

### §7.4 — Reduce Motion accessibility

**Trigger:** `UIAccessibility.isReduceMotionEnabled == true`.

**Current behavior:** forward via tap respects Reduce Motion via `snapToChatRestState` (line 1247 of TimelineCanvas per project_substrate_propagation_pinned memory). The reveal animations (blurFadeIn, crossFade, blurFadeOut) and the springToCellRest do NOT check Reduce Motion.

**Required behavior:**

- Forward path with Reduce Motion:
  - Snap geometry to chat-rest as today (existing logic)
  - Skip blurFadeIn/crossFade/blurFadeOut animations — present chatVC fully visible instantly
  - Immediately follow with normalize + handoff (no T=2.10s–T=2.8s window)
- Reverse direction with Reduce Motion:
  - User pinches in
  - On commit (.pinchToCells), skip the spring; snap heightConstraint to naturalH, snap camera, snap activeCellIndex to nil

**Implementation:**

```swift
// In RevealCoordinator.runRevealChoreography (or equivalent):

func runRevealChoreography() {
    if UIAccessibility.isReduceMotionEnabled {
        // Skip animations; jump to end-state
        chatVC.view.alpha = 1
        canvas.alpha = 0
        // Normalize (still needed for reverse direction to work)
        if let activeIdx = canvas.activeCellIndex {
            canvas.normalizeToChatRest(activeCellIndex: activeIdx)
        }
        // Handoff (skip the animation, just swap)
        performHandoff()
        return
    }
    // Existing animated choreography ...
}
```

```swift
// In TimelineCanvas.springToCellRest (or wherever commit-to-cell-rest happens):

if UIAccessibility.isReduceMotionEnabled {
    CATransaction.withSuppressedActions {
        cell.heightConstraint?.constant = naturalH
        cell.layoutIfNeeded()
        // Snap camera to lastCellRestScrollY
        applyCameraTransform(scrollY: lastCellRestScrollY)
        activeCellIndex = nil
        pinchRecognizer.isEnabled = true
        panRecognizer.isEnabled = true
    }
    return
}
// Existing spring logic ...
```

Tasks:
- [ ] Add Reduce Motion check to RevealCoordinator.runRevealChoreography
- [ ] Add Reduce Motion check to springToCellRest
- [ ] Add Reduce Motion check to performHandoff (for the alpha swap — could use snap instead of in-CATransaction swap; semantically same)
- [ ] Test with Reduce Motion enabled in Settings — verify no animation-triggered nausea, all transitions are instant

### §7.5 — User starts pinch BEFORE T=2.8s handoff completes

**Trigger:** between T=2.10s (canvas.alpha=0) and T=2.8s (handoff), user pinches on the chat surface.

**State during this window:**
- chatVC.view: alpha=1, isUserInteractionEnabled=true, no gesture recognizer attached to chatVC.view
- canvas.alpha=0; canvas.pinchRecognizer.isEnabled=false
- cell.chatContent.alpha=0; no recognizer

User touches chatVC.view. chatVC has no pinch recognizer → touch is absorbed and ignored (or maybe taps register as text field taps). No pinch can fire because:
- chatVC.view absorbs the touch (it has isUserInteractionEnabled=true)
- canvas.pinchRecognizer is disabled
- Even if canvas.pinchRecognizer were enabled, chatVC.view sits over the canvas and hit-tests preferentially

**Result:** pinch attempts during T=2.10s–T=2.8s are silently ignored. Acceptable.

Tasks:
- [ ] No code changes; document that pinches during this window are ignored
- [ ] Verify empirically (try to pinch in slow-motion replay)

### §7.6 — User starts pinch DURING crossFade (T=1.7s–T=2.10s)

**Trigger:** user pinches while cross-fade is animating.

**State:**
- chatVC.view: alpha animating 0→1, isUserInteractionEnabled=true (set when chatVC is added)
- canvas.alpha animating 1→0
- canvas.pinchRecognizer.isEnabled=false

Touches go to chatVC.view (highest z-order; alpha doesn't gate hit-testing unless `isHidden=true`). chatVC.view has no gesture recognizer for pinch. Pinch is ignored.

If canvas.pinchRecognizer were enabled (it isn't), the canvas would still be below chatVC.view in hit-test. So no path for the pinch to engage.

**Result:** pinches during cross-fade are ignored. Acceptable.

Tasks:
- [ ] No code changes; document.

### §7.7 — Conversation deleted from ConversationStore while presented

**Trigger:** ConversationStore.delete(conversation) called while user is in chat-state for that conversation.

**Current behavior:** chatVC retains its `conversation` reference (or its id); cells in pool reference conversation IDs. Deletion from the store doesn't directly invalidate chatVC's data. ChatVC would continue to display the deleted conversation. Pinching back would return the user to a cell-list where the deleted conversation's cell is absent (because reloadData ran).

**Required behavior:** when conversation deletion happens while it's actively displayed, gracefully return to cell-list:
- Trigger a programmatic reverse-direction (snap or animated)
- Tear down chatContent for that conversation
- Release stateController

**Implementation:**
- [ ] Observe `ConversationStore` changes (likely needs a delegate or notification — verify what's in place)
- [ ] On deletion of a conversation that matches `canvas.activeCellIndex`'s conversation:
  - Call `canvas.snapBackToCellRest()` (new method)
  - Tear down chatContent
  - Release stateController
- [ ] Or alternatively, prevent deletion of currently-active conversation (simpler, but less flexible)

**Decision provisional:** prevent deletion of currently-active conversation (return false from delete, or assertion if called). Simpler. Revisit if requirements change.

Tasks:
- [ ] Add `precondition(conversationID != currentlyActiveConversationID)` in ConversationStore.delete (if such an API exists)
- [ ] Document this limitation

### §7.8 — Memory warning during chat-state

**Trigger:** `UIApplication.didReceiveMemoryWarningNotification`.

**Current behavior:** no specific handling; UIKit may evict cached image data, etc.

**Required behavior:** flush optional caches but preserve currently-active state.

**Implementation:**
- [ ] Add memory warning observer in V2RootViewController or TimelineCanvas
- [ ] On memory warning:
  - Evict cells from cellPool beyond the active one (reduce maxKeyedPoolSize temporarily, e.g., to 5)
  - For evicted cells, teardown chatContent (release ~150KB each)
  - Do NOT evict the currently-active cell

Tasks:
- [ ] Add memory warning observer
- [ ] Implement cell pool flush (preserve active)
- [ ] Test with simulator memory warning trigger (Hardware → Simulate Memory Warning)

### §7.9 — Rotation during chat-state (iPad only)

**Trigger:** device rotation while user is in chat-state.

**Current behavior:** iPhone is portrait-only (project.yml). iPad allows all orientations.

**Required behavior on iPad:**
- canvas.bounds updates
- cell.heightConstraint.constant must update to new bounds.height
- Cross-view constraints to parentView.safeAreaLayoutGuide propagate automatically

**Implementation:**
- [ ] In `viewWillTransition(to:with:)` on V2RootViewController:
  - Inside transition coordinator's `animate` block, update `cell.heightConstraint.constant = canvas.bounds.height` for active cell
- [ ] Verify chatContent's subviews reposition correctly (should be automatic via cross-view constraints)

Tasks:
- [ ] Test on iPad simulator with rotation
- [ ] Defer if iPad support is not in scope for initial implementation

### §7.10 — Long conversation (500+ messages)

**Trigger:** user opens a conversation with 500 messages.

**Behavior:** ChatBubbleStackView builds 500 ChatBubbleViews + 500 constraints. Layout cost: ~150-300ms blocking on main thread. This happens during the T=1.6s parallel-layout window.

**Mitigation paths:**
- Mitigation 1: lazy bubble creation (only render top ~20 bubbles initially; build more as user scrolls)
- Mitigation 2: switch ChatBubbleStackView to UICollectionView with diffable data source
- Mitigation 3: build during the blur opacity window (T=1.6s–T=1.9s) where some jank is hidden

**Decision provisional:** accept the cost for initial implementation (eager build). Profile actual conversation lengths in practice. If users routinely have >100-message conversations and jank is noticeable, prioritize Mitigation 2.

Tasks:
- [ ] Profile layout cost with realistic conversation sizes
- [ ] Document the constraint that long conversations may show jank during T=1.6s–T=1.9s
- [ ] Defer optimization unless profiling shows need

### §7.11 — Activecellindex changes during the parallel-layout window

**Trigger:** somehow activeCellIndex changes between T=1.6s (when chatContent was installed) and T=2.8s (when handoff fires).

**How could this happen?** Theoretically:
- A new tap on a different cell — but pinchRecognizer and panRecognizer are disabled during forward
- A programmatic state change (e.g., a notification handler that calls canvas.setActiveCellIndex) — possible but should be guarded

**Required behavior:** if activeCellIndex changes, the handoff is invalid because the cell.chatContent we installed is on a different cell. We must NOT handoff.

**Implementation:**
- [ ] At handoff, verify the active cell at handoff time matches the one chatContent was installed on
- [ ] If mismatch: skip handoff, dismiss chatVC, log warning
- [ ] Test: programmatically change activeCellIndex during the window — verify graceful degradation

### §7.12 — App returns from background mid-handoff

**Trigger:** app was backgrounded, returns just as handoff would have fired.

**Behavior:** since handoff is synchronous and fires from a UIViewPropertyAnimator completion, and animators pause when app is backgrounded, the handoff would have been queued at background time. On foreground:
- UIKit may resume the animator and fire its completion → handoff runs
- Or UIKit may not resume (if cancelInFlight ran during background) → handoff doesn't run

Either way, ensure `revealCoordinator.completeHandoffIfPending()` is invoked on willEnterForeground if a partial state is detected.

Tasks:
- [ ] Add foreground observer in V2RootViewController
- [ ] On foreground: check for partial-handoff state, complete it if needed

### §7.13 — Acceptance criteria (§7 summary)

- [ ] All scene-deactivation edge cases handled (test programmatically by triggering deactivate at various T-times)
- [ ] Reduce Motion works on forward and reverse
- [ ] Conversation deletion handled (prevented or recovered)
- [ ] Memory warnings handled (cells beyond active evicted; active preserved)
- [ ] No partial-handoff state visible to user

---

## §8 — Performance & resource

### §8.1 — Double-layout cost at T=1.6s

**The pressure point:** at T=1.6s, both `chatVC.viewDidLoad`/`viewWillAppear`/`viewDidLayoutSubviews` AND `cell.installChatContentIfNeeded` fire in close succession. Each builds a full chat view tree.

**Cost breakdown per ChatVC.configure (or equivalent rebuild):**
- Bubble view allocation: ~50µs per bubble × N bubbles
- Bubble constraint setup: ~80µs per bubble (~3-6 constraints per bubble)
- ScrollView contentSize calc + layout: ~5ms + ~30µs per bubble for layout pass
- Composer textField + container: ~2ms

For N=50 bubbles: 50 × (50 + 80 + 30) = 8ms + 5ms + 2ms = ~15ms blocking.
For N=100 bubbles: ~30ms blocking.
For N=500 bubbles: ~150ms blocking.

**Doubled at T=1.6s:** ~30ms (N=50) to ~300ms (N=500) of cumulative blocking time. At 120Hz, the frame budget is 8.33ms; at 60Hz, 16.67ms. Both are exceeded for N≥50.

**What the user sees:** at T=1.6s, blurFadeIn just started (0.30s duration). If layout consumes 30ms, the blur animation drops 3-4 frames at 120Hz. Visible only if very attentive.

**Mitigations:**
- [ ] Mitigation A: stagger — do chatVC build at T=1.6s, do cell.chatContent build at T=2.0s (after blurFadeIn completes). The cost is split across the blur-opaque window. But the second build must complete before T=2.8s handoff. With ~30ms budget per build and ~700ms window, this fits comfortably.
- [ ] Mitigation B: dispatch async — wrap cell.installChatContentIfNeeded in `DispatchQueue.main.async`. The build happens on the next runloop tick, freeing the current tick for blur. Adds ~16ms latency but reduces frame-drop visibility.
- [ ] Mitigation C: profile first, decide based on data

**Decision provisional: Mitigation B (DispatchQueue.main.async).** Simplest; defers cost to next tick; cumulative latency acceptable.

```swift
// In RevealCoordinator.present, after installChatViewController:

DispatchQueue.main.async { [weak self, weak canvas, weak rootVC] in
    guard let self = self,
          let canvas = canvas,
          let activeIdx = canvas.activeCellIndex,
          let cell = canvas.instantiatedCells[activeIdx],
          let rootVC = rootVC else { return }
    cell.installChatContentIfNeeded(
        conversation: conversation,
        parentVC: rootVC,
        stateController: self.stateController!
    )
}
```

Tasks:
- [ ] Profile chatVC build cost with realistic conversations (N=10, 50, 100)
- [ ] Implement Mitigation B (dispatch async)
- [ ] Verify chatContent layout completes before T=2.8s handoff (~1.2s window, very generous)
- [ ] If profiling shows N≥200 is common, add Mitigation A or migrate to UICollectionView

### §8.2 — Memory peak during the parallel-layout window

**Memory cost per ChatContentContainer:** approximately:
- ChatHeaderView: ~10KB (UILabel + constraints + layer backing)
- ChatBubbleStackView: ~30KB base + ~5KB per bubble view (UILabel + container + constraints + layer backing)
- ChatComposerView: ~15KB
- Cross-view constraint objects: ~12 constraints × ~200 bytes = ~2.5KB
- Total base: ~57KB + N × 5KB

For N=50: ~57 + 250 = ~307KB per chatContent.
For N=100: ~57 + 500 = ~557KB.

**Memory cost per ChatViewController:** approximately the same, since the structure mirrors. ~300-550KB.

**Parallel-layout peak (T=1.6s–T=2.8s):** ChatVC + chatContent both live = ~600KB-1.1MB.
**After T=2.8s:** chatVC released; only chatContent remains in the active cell = ~300-550KB.
**At cell-pool full (20 cells × ~300KB):** ~6MB committed to chat content view trees.

**Comparison to typical iOS app memory budget:** apps can use ~150MB before pressure on modern iPhones. 6MB for chat content is a rounding error.

**Conclusion:** memory is not a constraint for realistic conversation sizes (≤100 messages typical). Document and monitor.

Tasks:
- [ ] Profile peak memory during 100-round-trip test
- [ ] Verify cell pool eviction releases chatContent (no leaked instances)

### §8.3 — Normalize CPU cost

**Operations in normalize:**
- 4 × removeAnimation (each is ~100-500µs): ~2ms
- transform = identity (CALayer property write): ~10µs
- removeAnimation for chatRestCenterLabel: ~500µs
- transform = identity, alpha = 0 on chatRestCenterLabel: ~20µs
- heightConstraint.constant = bounds.height: ~5µs
- layoutIfNeeded on contentHost: depends on cell count visible (~5-15ms for 5 visible cells)

Total normalize cost: ~10-20ms. Inside the canvas.alpha=0 window so invisible.

**No mitigation needed.** Document.

### §8.4 — Handoff CPU cost

**Operations in performHandoff:**
- 4 × captureFromChatVC (reads): ~100µs total
- 2 × applyTo writes (text, contentOffset): ~200µs
- CATransaction.withSuppressedActions wrapping 5 alpha writes: ~500µs
- becomeFirstResponder (if applicable): ~5-10ms (keyboard transition is heavyweight)
- mapTextRange: ~50µs
- chatVC.removeFromSuperview + removeFromParent: ~2-5ms

Total handoff cost: ~10-20ms.

**Visible impact:** the handoff fires at T=2.8s as the blur curtain finishes lifting. The blurFadeOut animation has ended; the user is looking at chatVC.view. The handoff's 10-20ms is a one-frame stall at 60Hz or two-frame stall at 120Hz. Barely perceptible because the user's attention is on the chat content, not on frame timing.

**Mitigation:** none needed. Document.

### §8.5 — Reverse direction CPU cost

**Per gesture event (handlePinchChanged):**
- Pinch scale read: ~5µs
- heightConstraint.constant write: ~5µs
- layoutIfNeeded on cell: ~1-2ms (just the cell's layout pass; not the whole canvas)
- setCamera per tick: ~100µs (alpha writes inside suppressed CATransaction)

Total per gesture event: ~1-3ms. At 120Hz, frame budget 8.33ms. Comfortably under.

**Per spring tick (springToCellRest):**
- Spring math (Hooke's law step): ~1µs
- heightConstraint.constant write: ~5µs
- layoutIfNeeded: ~1-2ms
- setCamera: ~100µs

Total per spring tick: ~1-2ms. Under budget.

**No mitigation needed.** Document.

### §8.6 — Long-term memory growth

**Concern:** does memory grow over many round-trips?

**Sources of potential growth:**
- ChatVC instances not released (release decision in §1.5/§5.4)
- ConversationStateController instances not released (lifetimes match cell pool, so bounded by 20)
- ChatContentContainer instances not released (owned by cell, bounded by 20)
- Cross-view constraints leaking parentView references (verified no cycle in §3.6)

**Verification:** Instruments Allocations + Leaks over 100 round-trips. Expected:
- Heap stable over 100 round-trips (within ~1MB drift from GC variance)
- No ChatViewController instances accumulate beyond 0 (released each present)
- No ChatContentContainer instances accumulate beyond cell pool cap (20)
- No NSLayoutConstraint instances leak (constraints are deallocated with their views)

Tasks:
- [ ] Run Instruments Allocations + Leaks 100-round-trip test
- [ ] Verify no leaks; document baseline numbers in this doc

### §8.7 — GPU cost (rendering)

**Concern:** the parallel-layout window has chatVC.view and cell.chatContent both in the view hierarchy, both with view trees of bubble views. Does this increase GPU rasterization cost?

**Analysis:**
- chatVC.view alpha=0 from T=1.6s to T=2.10s: alpha=0 views are SKIPPED by Core Animation's compositor (verified by Apple docs). Zero GPU cost.
- chatContent.alpha=0 throughout this window: same — zero GPU cost.
- After T=2.10s: chatVC.view alpha=1. Its view tree is composited. Cost similar to today's reveal.
- chatContent.alpha=0 still through T=2.8s: zero GPU cost.
- After T=2.8s: chatVC removed entirely. chatContent.alpha=1. Cost identical to today's chat-state but with chatContent instead of chatVC.

**No GPU regression.** The alpha=0 invariant guarantees no compositing cost for invisible views.

### §8.8 — Acceptance criteria (§8 summary)

- [ ] Layout cost at T=1.6s: <50ms total (chatVC + chatContent)
- [ ] No frame drops visible during blurFadeIn (verify with FPS meter)
- [ ] Memory peak during parallel-layout window: <1MB above baseline
- [ ] No memory growth over 100 round-trips
- [ ] Reverse direction gesture-tick CPU: <3ms per tick
- [ ] No GPU regression (alpha=0 views skipped)

---

## §9 — Animation coexistence

The handoff approach introduces synchronous mutations alongside an existing rich animation system. This section enumerates the touchpoints where they coexist and the disciplines that keep them from interfering.

### §9.1 — CATransaction.withSuppressedActions discipline (CLAUDE.md 2.1)

Every synchronous mutation introduced by this work is wrapped in `CATransaction.withSuppressedActions`. The disciplines:

- **normalize:** every layer write (4 × removeAnimation, transform reset, alpha set on chatRestCenterLabel, heightConstraint set, layoutIfNeeded) is wrapped.
- **handoff:** every alpha write (chatVC.alpha=0, canvas.alpha=1, chatContent.alpha=1, pinchRecognizer.enabled=true) is wrapped.
- **setCamera extension:** the new alpha writes for chatContent and chatRestCenterLabel are wrapped (within the existing `setCamera`'s CATransaction block).
- **state apply:** writes to text, contentOffset are also wrapped to suppress any inadvertent UIView animation.

**Risk if missed:** UIKit's default animation duration is ~0.25s; without suppression, alpha writes could trigger 0.25s fade animations that conflict with our atomic intent. Verified by reading every new mutation site.

Tasks:
- [ ] Audit every synchronous mutation introduced by this work
- [ ] Verify each is inside `CATransaction.withSuppressedActions { ... }`
- [ ] Add a regression test (or temp log) verifying no animation is fired during normalize/handoff

### §9.2 — Cane curve animations vs normalize

The cane curve attaches 4 CABasicAnimations to `contentHost.layer` with `isRemovedOnCompletion = false`. After the cane curve completes at T=1.5s, these animations are STILL attached (their final values held).

Normalize, which fires after T=2.10s, explicitly `removeAnimation(forKey:)` each. The removal:
- Stops the animation from continuing to assert its final value as the presentation layer
- Allows the subsequent `contentHost.layer.transform = CATransform3DIdentity` write to take effect on the presentation layer (otherwise the held additive animation would compound with the identity write)

**Critical:** the removal must happen BEFORE the identity write, NOT after. The order in the normalize sketch (§2.3) is correct: removeAnimation → transform = identity → layoutIfNeeded.

**Verification:**
- [ ] After normalize: `contentHost.layer.animationKeys()` does NOT contain windupScale, zoomScale, windupTranslate, morphCentering
- [ ] After normalize: `contentHost.layer.presentation()?.transform` is identity (or non-existent if presentation has been recycled)
- [ ] After normalize: `contentHost.layer.transform` is identity

### §9.3 — setCamera writes during forward path (must not fire)

setCamera is called from:
- Pan gesture events (handlePan)
- Pinch gesture events (handlePinchChanged)
- Spring animator ticks (springToCellRest)
- Programmatic camera updates (e.g., from snapToChatRestState)

During the forward path (T=0 to T=2.8s), none of these are active:
- Pan/Pinch recognizers are disabled (set during setActiveCellIndex)
- Spring animator is not running
- Programmatic snap happens only on Reduce Motion path

**So setCamera should NOT fire during the forward path.** Verify empirically by logging the entry point of setCamera and counting invocations during a forward.

If setCamera DOES fire during forward, the alpha writes for chatContent and chatRestCenterLabel would conflict with:
- chatContent.alpha=0 (set at install at T=1.6s)
- chatRestCenterLabel.alpha being driven by centerLabelOpacity CABasicAnimation (from T=0.78s to T=1.5s)

Both conflicts would be visible: chatContent might flash visible if setCamera writes alpha=1 prematurely; chatRestCenterLabel's alpha would compete with the CABasicAnimation's held final value (probably the CABasicAnimation wins since its model layer alpha is 0 but its animation holds presentation at the final value).

**Defensive measure:** add a guard in setCamera that skips the new alpha writes if `morphInProgress` (already there) OR if `revealCoordinator.isPresenting` (new):

```swift
// CellView.setCamera, updated:

func setCamera(_ camera: CameraState) {
    guard !morphInProgress else { return }
    guard !revealCoordinator.isPresenting else { return }  // NEW guard
    // ... existing setCamera body, plus new alpha writes for chatContent ...
}
```

This requires CellView to have a reference to the revealCoordinator (which is unusual; cells normally don't know about reveal). Alternative: pass a flag via canvas to cells, or use a global on RevealCoordinator that all cells can query.

**Decision provisional:** add `isPresenting: Bool` to RevealCoordinator; cells access it via `canvas.revealCoordinator?.isPresenting`. Guard setCamera with this.

Tasks:
- [ ] Verify empirically that setCamera doesn't fire during forward (add temp log)
- [ ] If it does fire, implement the isPresenting guard
- [ ] If it doesn't fire (recognizers disabled correctly), no defensive guard needed; document the invariant

### §9.4 — setCamera writes after handoff (must fire once)

Immediately after handoff, the cell is at progress=1.0 (heightConstraint=844, chatRestExt=844). The new alpha writes in setCamera should:
- labelStack.alpha = 0 (chrome hidden at chat-rest)
- pinchGlyph.alpha = 0
- chatContent.alpha = 1 (visible at chat-rest)
- chatRestCenterLabel.alpha = 0 (replaced by chatContent.header)

These values are also what we set at handoff time explicitly. So `setCamera()` being called once at the end of handoff is redundant for chrome (already at correct alpha) but defensive.

**The call to `canvas.setCamera()` at the end of performHandoff (per §2.4 sketch) is the mechanism that ensures these alphas are consistent.**

Tasks:
- [ ] Verify post-handoff alpha values match expectations
- [ ] Verify setCamera is called once at end of handoff
- [ ] Add assertion (debug-only): assert chrome alphas are 0 after handoff

### §9.5 — performMorphChromeTransition vs setCamera

`performMorphChromeTransition` uses UIView.animate (CLAUDE.md 2.1 says "default but question its use"; the existing chrome fade does use it). It fires from T=0 to T=0.28s during the forward path. By T=0.28s, all UIView.animate-driven alphas have completed.

After T=0.28s, the chrome (labelStack, pinchGlyph) is at model-layer alpha=0. setCamera (if it ran) would compute progress and write alphas based on progress. From T=0.28s to T=2.8s, setCamera does NOT run (per §9.3). So no conflict.

After T=2.8s, setCamera runs at the end of handoff. It writes the new alphas based on progress=1.0. The chrome alphas would be set to 0 (which they already are). No conflict.

**Verification:** the model layer alpha is the source of truth after UIView.animate completes. setCamera writes the model layer alpha. There's no presentation-layer/model-layer divergence.

Tasks:
- [ ] No code changes; document the analysis above.

### §9.6 — Reverse direction setCamera coexistence with springToCellRest

During reverse direction, setCamera fires on each gesture event (handlePinchChanged) AND on each spring tick (springToCellRest after commit). Both write the same alphas based on progress. As long as both are within `CATransaction.withSuppressedActions`, there's no implicit-animation interference.

Tasks:
- [ ] Verify CATransaction wrapping in setCamera (existing) and in spring tick (existing)
- [ ] Verify no animation triggered by writes to layer.transform or view.alpha during reverse

### §9.7 — Acceptance criteria (§9 summary)

- [ ] All new synchronous mutations wrapped in CATransaction.withSuppressedActions
- [ ] No implicit animations fire during normalize or handoff
- [ ] setCamera does not fire during forward path (verified)
- [ ] setCamera fires once at end of handoff with correct alphas
- [ ] No alpha jitter during reverse (smoothstep curves are continuous)

---

## §10 — Substrate participation

Per `CLAUDE.md` Part 4, the substrate has 9 keystones. This section verifies cell.chatContent's relationship to each.

### §10.1 — `contentHost.layer.sublayerTransform` (camera applier)

**Cell.chatContent's relationship:** cell.chatContent is a subview of cell which is a subview of contentHost. When `contentHost.layer.sublayerTransform` is applied, its effects (camera offsets, etc.) propagate to all sublayers including chatContent's layer. chatContent inherits the camera automatically.

Tasks:
- [ ] No code changes; cell.chatContent's position in the hierarchy ensures inheritance
- [ ] After handoff, scroll the cell-list (if pinchRecognizer keeps activeCellIndex set during chat-state — verify): cell + chatContent move together

### §10.2 — `canvas.layer.sublayerTransform.m34 = -1/1000` (perspective)

**Cell.chatContent's relationship:** chatContent is two levels deep from canvas (canvas → contentHost → cell → chatContent). The m34 perspective applied at canvas.layer.sublayerTransform propagates to all descendants. If any descendant has a Z-translation, it will be foreshortened.

For chat-state (post-handoff): chatContent has no Z-translation. The m34 is dormant — visible only when something has Z-coord.

**Future-proofing:** if a future feature adds Z-translation to chat content (e.g., a 3D message effect), the m34 propagation will make it look correct without per-feature setup.

Tasks:
- [ ] No code changes; document the inheritance.

### §10.3 — `AnimationController`'s single CADisplayLink

**Cell.chatContent's relationship:** chatContent does not register any animators with AnimationController. Its only "animations" are:
- Alpha changes via setCamera (synchronous; no animator)
- Scroll deceleration (UIScrollView internal; uses its own display link, not AnimationController's — but this is acceptable because the cell-list camera is the substrate-level animator, not the bubble scroll)

The keystone is not violated.

Tasks:
- [ ] Verify no new CADisplayLink registration in chatContent or its sub-components
- [ ] Document that bubble scroll uses UIScrollView's internal display link (independent of AnimationController) — acceptable

### §10.4 — `cellPoolByConversationID` identity-keyed pool

**Cell.chatContent's relationship:** chatContent is owned by cell; cell is owned by pool. chatContent's lifecycle is bounded by cell's pool lifetime. Identity is preserved across round-trips for the same conversation.

Tasks:
- [ ] Already documented in §5; no further changes.

### §10.5 — `CATransaction.withSuppressedActions` discipline

Covered in §9.1.

### §10.6 — `EngagementState.engaged(completion:)`

**Cell.chatContent's relationship:** the engagement state machine is per-cell (driven by morphChoreographer for the pinch-commit path; not used for tap path or chatContent install). chatContent install + handoff do NOT engage the state machine. They operate outside it.

The pinchRecognizer.isEnabled and panRecognizer.isEnabled flags ARE managed: pinchRecognizer disabled in setActiveCellIndex, re-enabled in performHandoff. panRecognizer disabled when activeCellIndex is set, re-enabled when it clears.

Tasks:
- [ ] Verify recognizer state transitions are correct (see §6.4 acceptance)

### §10.7 — 4 additive CABasicAnimations in animateCameraToChatRest

Untouched during forward. Explicitly removed at normalize (T=2.10s+) after the cane curve has completed its visible work. The keystone is preserved during the forward path; the removal at normalize is a deliberate cleanup, not a violation.

Tasks:
- [ ] Verify cane curve fires identically to today (visual regression test)
- [ ] Verify removeAnimation in normalize does not affect any visible state (canvas.alpha=0 at the time)

### §10.8 — MorphChoreographer's sin-bell Y/Z arc

Untouched. MorphChoreographer is the pinch-commit path, not the tap path. This work doesn't modify it.

### §10.9 — 5 invariant asserts in InvariantHardeningTests

Should continue to pass. Specifically:
- Per `CLAUDE.md`, these encode "load-bearing invariants discovered through audit". The handoff approach does not violate any architectural keystone (per §0.7), so the invariants should hold.

Tasks:
- [ ] Run InvariantHardeningTests after implementation
- [ ] If any fail, investigate immediately (likely indicates an unintended substrate violation)

### §10.10 — Acceptance criteria (§10 summary)

- [ ] All 9 keystones unchanged or preserved (audit per §0.7)
- [ ] No new CADisplayLink registrations
- [ ] No new sublayerTransform mutations outside applyCameraTransform
- [ ] InvariantHardeningTests pass

---

## §11 — Code organization

Per `CLAUDE.md` Part 2.6 (9S concurrency contract) and Part 5 (file organization).

### §11.1 — New files

| File | Layer | Annotation | Purpose |
|---|---|---|---|
| `Conversation/ChatBody/ChatContentContainer.swift` | L3 | `@MainActor` | Hosts header + bubble stack + composer; owns cross-view constraints |
| `Conversation/ChatBody/ChatHeaderView.swift` | L3 | `@MainActor` | The day-marker label (replaces chatVC.headerLabel) |
| `Conversation/ChatBody/ChatBubbleStackView.swift` | L3 | `@MainActor` | UIScrollView containing the bubble UIStackView |
| `Conversation/ChatBody/ChatComposerView.swift` | L3 | `@MainActor` | composerContainer + composerTextField |
| `Conversation/Timeline/ConversationStateController.swift` | L3 | `@MainActor` | NSObject holding transient state per-conversation |

Each file under 200 LOC. Single responsibility.

Tasks:
- [ ] Create each file
- [ ] `xcodegen generate` to update the Xcode project
- [ ] Verify files appear in the correct project group
- [ ] Verify build passes

### §11.2 — Modified files

| File | Changes |
|---|---|
| `Conversation/Timeline/CellView.swift` | Add `chatContentContainer` property; add `installChatContentIfNeeded` method; add `teardownChatContent` method; add `stateController` property; extend `setCamera` for chatContent alpha and chatRestCenterLabel alpha; extend `configure(with:)` for identity-mismatch teardown |
| `Conversation/Timeline/TimelineCanvas.swift` | Add `normalizeToChatRest(activeCellIndex:)` method |
| `Conversation/RevealCoordinator.swift` (path approximate) | Add `canvasRef` and `stateController` references; modify `present(conversation:)` to install chatContent in parallel; modify `crossFade.addCompletion` to schedule normalize; modify `blurFadeOut.addCompletion` to perform handoff; add `performHandoff()` method; add `completeHandoffIfPending()` method for scene-deactivation recovery |
| `App/V2RootViewController.swift` | Add foreground observer for scene-deactivation recovery; add memory warning observer |

Tasks:
- [ ] Implement modifications per the sketches in §1, §2, §6
- [ ] Verify build passes after each modified file
- [ ] Verify no layer violation per 9S contract (no `Sendable` value type accessing `@MainActor` reference type without explicit hop)

### §11.3 — Deleted files

None. ChatViewController and RevealCoordinator are retained.

Future iteration may delete ChatViewController if Option B (Cell-as-Conversation) is later adopted. Not in scope.

### §11.4 — Project file regeneration

The repo uses xcodegen. After adding new files:

```bash
xcodegen generate
```

This updates `DotPinchPrototype.xcodeproj` with the new file references. Verify the project file is committed cleanly.

Tasks:
- [ ] Run xcodegen after each new file
- [ ] Commit project file changes alongside source changes
- [ ] Verify no spurious project changes (e.g., temp files added by Xcode)

### §11.5 — Conventions per CLAUDE.md Part 5

- **NO COMMENTS** in new code unless a hidden constraint requires explanation.
- **NO multi-line // blocks** explaining what code does.
- **NO references** to PR numbers, audit IDs, task tokens.
- **NO docstrings** restating method names.

Tasks:
- [ ] Review every new file for comment violations before commit
- [ ] Self-review per the user's `feedback_no_padding_comments` memory

### §11.6 — Acceptance criteria (§11 summary)

- [ ] All new files in correct layer per 9S contract
- [ ] All new files under 200 LOC each
- [ ] Single responsibility per file
- [ ] xcodegen generates cleanly
- [ ] Build passes after each file added
- [ ] No comment violations

---

## §12 — Implementation phases

The work decomposes into 8 sequential phases. Each phase has an exit gate. Do not proceed to phase N+1 until phase N's gate is met.

### Phase 0 — Verification & prototyping (the empirical foundation)

**Wave Topology DAG (Phase 0):**

```
PHASE 0
│
├─→ Wave 0.1 (file reading + line-num verify) ────╮
├─→ Wave 0.2 (Theme + Symbol availability)        │
├─→ Wave 0.3 (safe area Q1)                       ├─→ [WC Merge Gate 0]
├─→ Wave 0.4 (m34 + Z calibration Q10/Q11)        │
└─→ Wave 0.5 (cancelInFlight Q3 + remaining Qs)   ╯
```

All five waves parallel (independent empirical checks); merge gate aggregates findings into §14 / §16 decision log + retro updates downstream design before Phase 1+.

**Wave assignments:**
- **Wave 0.1** — `[ER]` reads all referenced files end-to-end, verifies line numbers per §16
- **Wave 0.2** — `[ER, TS]` Q2 Theme color comparison + Q7 SF Symbol availability
- **Wave 0.3** — `[ER, LE]` Q1 safe area divergence (cross-view constraints check)
- **Wave 0.4** — `[ER, SE]` Q10 m34 propagation + Q11 Z magnitude calibration
- **Wave 0.5** — `[ER, RO]` Q3 cancelInFlight + Q4-Q6 + Q12

Each wave's retro: `[CQR, RCT light-mode, DCH]` (light because Phase 0 is read-only)

This phase resolves uncertainty BEFORE writing structural code. The §3.2 verification (safe area divergence) is the load-bearing question.

- [ ] **P0.1** Read all referenced files end-to-end (don't trust memory):
  - `TimelineCanvas.swift` (entire file, ~1500 LOC)
  - `CellView.swift` (entire file, ~400 LOC)
  - `ChatViewController.swift` (entire file, ~140 LOC)
  - `RevealCoordinator.swift` (entire file, ~145 LOC)
  - `MorphChoreographer.swift`
  - `MorphTokens.swift` / `MorphAnimationKey.swift`
  - `DesignSystem/Theme.swift`
- [ ] **P0.2** Verify line numbers in this checklist match actual code (this checklist's line refs are approximate)
- [ ] **P0.3** Theme color comparison: print `Theme.Page.surface` and `Theme.Cell.fill` (use `UIColor.description` or `cgColor.components`). Document in §14.
- [ ] **P0.4** Safe area divergence verification (§3.2): add temp logs to `cell.didLayoutSubviews` and `chatVC.viewDidLayoutSubviews` after a forward to chat-rest. Compare `safeAreaInsets.top`. Document result in §14.
- [ ] **P0.5** Verify setCamera invocation during forward path: add temp log to setCamera entry; tap a cell; observe whether it fires. Document.
- [ ] **P0.6** Verify cane curve animation keys: log `contentHost.layer.animationKeys()` at T=1.5s (immediately after cane curve completes). Confirm the four keys are present. Document the exact key strings.
- [ ] **P0.7** Verify `cancelInFlight` behavior: programmatically trigger a scene deactivation at T=2.5s. Log whether `blurFadeOut.addCompletion` fires. Document in §14.

**Phase 0 exit gate:** all P0.x items checked. The empirical facts that ground the rest of the work are documented in §14.

**Phase 0 Pillar review sub-gate (MUST pass before Phase 1+ begins):**
- [ ] **P18.20** test coverage applied: each Q has a method, success criterion, and recorded answer
- [ ] **P14.6** no singletons introduced in any test instrumentation
- [ ] **P1.10** every temp `print` statement has a WHY comment explaining what it's verifying
- [ ] All temp instrumentation removed before commit (per G.13)
- [ ] §14 decision log updated with D-Phase0-Q* answers (P14.1 coordinator pattern keeps decisions discoverable)

**Estimated duration:** 1-2 days.

### Phase 1 — Additive: ChatContent view components

**Wave Topology DAG (Phase 1):**

```
PHASE 1
│
├─→ Wave 1.1 (ChatHeaderView)         ─╮
├─→ Wave 1.2 (ChatBubbleStackView)    ─┤
├─→ Wave 1.3 (ChatComposerView)       ─┼─→ [WC Merge Gate 1.A] ──┐
└─→ Wave 1.4 (token: AlphaCurve enum) ─╯                          │
                                                                  ↓
                                       Wave 1.5 (ChatContentContainer) [depends on 1.1-1.4]
                                                                  │
                                                                  ↓
                                                       [WC Merge Gate 1.B] ─→ Phase 1 complete
```

Three view components + 1 token enum run in parallel (independent files); container assembles them once they exist.

**Wave assignments:**
- **Wave 1.1** — `[CO, LE]` ChatHeaderView per §1.2.1 + constraints | retro `[CQR, RCT, SA, DCH, IV, BV]`
- **Wave 1.2** — `[CO, LE]` ChatBubbleStackView per §34.2.1 | retro same
- **Wave 1.3** — `[CO, LE]` ChatComposerView per §1.2 sketch | retro same
- **Wave 1.4** — `[TS]` AlphaCurve enum in `DesignSystem/AlphaCurve.swift` per §39.2.1 | retro `[CQR, RCT]`
- **Wave 1.5** — `[CO, LE]` ChatContentContainer per §1.2.1 (depends on 1.1-1.4 existing) | retro `[CQR, RCT, SA, DCH, IV, BV]`

Build the new view components in isolation. They are not yet wired into RevealCoordinator. They are testable individually.

- [ ] **P1.1** Create `Conversation/ChatBody/ChatHeaderView.swift` — UIView with `headerLabel: UILabel`. Method `configure(with conversation: Conversation)`. Backgrond clear; font/color from Theme.
- [ ] **P1.2** Create `Conversation/ChatBody/ChatBubbleStackView.swift` — UIView with `scrollView: UIScrollView` and `bubbleStack: UIStackView`. Method `configure(with conversation: Conversation)` that rebuilds bubbles. Constraints: scrollView fills view; bubbleStack fills scrollView.contentLayoutGuide with width matching frameLayoutGuide.
- [ ] **P1.3** Create `Conversation/ChatBody/ChatComposerView.swift` — UIView with `composerContainer: UIView` and `composerTextField: UITextField`. Configure with conversation (no-op for now; reserved for future per-conversation composer state).
- [ ] **P1.4** Create `Conversation/ChatBody/ChatContentContainer.swift` — composes the above three. Holds `parentVC: weak UIViewController`. Sets up cross-view constraints in `setupConstraints` (referencing `parentVC.view.safeAreaLayoutGuide`).
- [ ] **P1.5** Run `xcodegen generate`. Build.
- [ ] **P1.6** Smoke test: add ChatContentContainer to a debug screen with a hardcoded Conversation; verify layout looks right.

**Phase 1 exit gate:** view components compile and render correctly in isolation.

**Phase 1 Pillar review sub-gate:**
- [ ] **P1.2** all subview properties at class top via closure-init; no `setupSubviews()` helpers that initialize properties (only structural helpers like `installViewHierarchy`)
- [ ] **P4.2** all new classes `final`
- [ ] **P4.3** `@MainActor` explicit on every UIView subclass
- [ ] **P5.1** every property starts `private`; promote only when justified
- [ ] **P20.1** one type per file; file name matches type name
- [ ] **P20.2** files placed in `Conversation/ChatBody/` (correct concern folder)
- [ ] **P2.11** no magic numbers in constraint constants — extracted to `Layout` enum or similar
- [ ] **P13.4** every method ≤50 LOC; every helper ≤20 LOC
- [ ] **P6.5** `init?(coder:)` declared with `fatalError` + WHY message

**Estimated duration:** 2-3 days.

### Phase 2 — Additive: ConversationStateController

**Wave Topology DAG (Phase 2):**

```
PHASE 2
│
├─→ Wave 2.1 (TransientStateSnapshot struct) ─╮
├─→ Wave 2.2 (Controller scaffolding + init) ─┤
└─→ Wave 2.3 (capture/apply/bind methods)     ╯
                                              ├─→ [WC Merge Gate 2] ─→ Phase 2 complete
```

Phase 2 has internal sequence (2.3 depends on 2.1 + 2.2) BUT can parallelize with Phase 1 entirely (different files). External cross-phase parallelism: Phase 1 + Phase 2 ran concurrently.

**Wave assignments:**
- **Wave 2.1** — `[SM]` TransientStateSnapshot per §33.2.1 (struct + Sendable)
- **Wave 2.2** — `[SM]` Controller class scaffolding + init + properties per §1.4.1
- **Wave 2.3** — `[SM]` capture / apply / bind methods per §1.4.1 + §33.2.1
- Retro `[CQR, RCT, SA, DCH, IV, BV]` after Wave 2.3

- [ ] **P2.1** Create `Conversation/Timeline/ConversationStateController.swift`. Properties per §1.4. Methods: `bind(to:)`, `captureFromChatVC(_:)`, `applyTo(_:)`.
- [ ] **P2.2** Implement `mapTextRange(from:to:range:)` helper (§4.5).
- [ ] **P2.3** Run xcodegen. Build.
- [ ] **P2.4** Smoke test (manual): instantiate a state controller, capture from a chatVC, apply to a chatContent. Verify values transfer.

**Phase 2 exit gate:** state controller compiles and round-trips state between instances.

**Phase 2 Pillar review sub-gate:**
- [ ] **P4.2** ConversationStateController is `final` NSObject
- [ ] **P4.3** `@MainActor` annotation explicit
- [ ] **P9.2** TransientStateSnapshot conforms to Sendable
- [ ] **P5.1** boundChatContent is `private` weak
- [ ] **P18.14** weak reference (no retain cycle through state controller)
- [ ] **P19.5** conversationID is `let`; transient state `var`s justified per P8.3
- [ ] **P11.1** controller has ONE concern (transient state); no business logic
- [ ] **P12.2** capture/apply seam — controller asks ChatVC for snapshot, doesn't reach into ChatVC's subviews
- [ ] **P19.3** capture / apply / bind are idempotent

**Estimated duration:** 1 day.

### Phase 3 — Additive: CellView integration

**Wave Topology DAG (Phase 3):**

```
PHASE 3
│
├─→ Wave 3.1 (CellView properties: chatContentContainer + stateController) ─╮
├─→ Wave 3.2 (install/teardown methods)                                     ├─→ [WC Merge Gate 3.A]
└─→ Wave 3.3 (setCamera baseline; existing curves only — no §21/§23)        ╯       │
                                                                                    ↓
                                                                       Wave 3.4 (regression: tap-to-chat unchanged)
                                                                                    │
                                                                                    ↓
                                                                          [WC Merge Gate 3.B] ─→ Phase 3 complete
```

Properties + methods + setCamera baseline are file-local independent; regression test depends on all three.

**Wave assignments:**
- **Wave 3.1** — `[CA, CO, SM]` add 2 strong properties to CellView; verify pool-roundtrip persistence
- **Wave 3.2** — `[CA, CO]` installChatContentIfNeeded + teardownChatContent + teardownChatContentForMemoryPressure
- **Wave 3.3** — `[CA, SE]` setCamera baseline refactor per §39.2.1 final form (BUT exclude §21 affordance line + §23 Z+alpha block; those land in P9/P10)
- **Wave 3.4** — `[VR, BV]` regression: tap-to-chat forward visually unchanged
- Retro per wave + final phase retro: `[CQR, RCT, SA, DCH, IV, CA-conc, BV, VR]`

Add chatContentContainer and stateController to CellView as strong properties. Install / teardown methods. Do NOT yet wire normalize or handoff.

- [ ] **P3.1** Add `chatContentContainer: ChatContentContainer?` strong property to CellView.
- [ ] **P3.2** Add `stateController: ConversationStateController?` strong property to CellView.
- [ ] **P3.3** Implement `installChatContentIfNeeded(conversation:, parentVC:, stateController:)` per §1.3 sketch.
- [ ] **P3.4** Implement `teardownChatContent()`.
- [ ] **P3.5** Extend `configure(with:)` to teardown chatContent + stateController if conversation identity changes.
- [ ] **P3.6** Extend `setCamera` with new alpha curves for chatContent and chatRestCenterLabel per §6.2.
- [ ] **P3.7** Build. Verify existing forward path still works (regression check on tap-to-chat).

**Phase 3 exit gate:** CellView changes compile; existing tap-to-chat forward is visually unchanged.

**Phase 3 Pillar review sub-gate:**
- [ ] **P11.1** setCamera body delegates to single-concern appliers per §39.2.1 (NOT a long inline body)
- [ ] **P19.1** `computeProgress(viewport:)` is pure (no `self.X = ...` writes)
- [ ] **P19.3** every applier is idempotent
- [ ] **P2.11** all smoothstep ranges via `AlphaCurve` token enum (no inline literals)
- [ ] **P6.7** every guard with silent return has WHY comment
- [ ] **P6.6** no sentinel values introduced (no `var index: Int = -1`)
- [ ] **P13.4** setCamera ≤15 LOC; each applier ≤10 LOC
- [ ] **P5.1** all new properties start `private`; chatContentContainer is `private(set)` per P5.5 if tests need read access
- [ ] **P10.2** new chatContentContainer + stateController properties follow existing CellView idioms (typed strong refs, lazy where appropriate)
- [ ] **P3.5** code reads top-to-bottom as the contract; no need to flip 3 files to understand setCamera

**Estimated duration:** 1-2 days.

### Phase 4 — Wire pre-warm: parallel layout at T=1.6s

**Wave Topology DAG (Phase 4):**

```
PHASE 4
│
├─→ Wave 4.1 (RevealCoordinator canvasRef + stateController weak refs) ─╮
└─→ Wave 4.2 (V2RootVC onMorphRevealReady installChatContent dispatch) ─╯
                                                                        ├─→ [WC Merge Gate 4] ─→ Phase 4 complete
```

Two waves parallel; merge gate verifies chatContent installs invisibly without forward-path regression.

**Wave assignments:**
- **Wave 4.1** — `[RO]` add `canvasRef: weak TimelineCanvas?` + `stateController: weak ConversationStateController?` to RevealCoordinator
- **Wave 4.2** — `[CR]` V2RootVC.onMorphRevealReady extended to call cell.installChatContentIfNeeded via dispatch_async (Mitigation B per §8.1)
- Retro `[CQR, RCT, SA, DCH, IV, BV, VR]`

Add the install call into RevealCoordinator.present, WITHOUT yet adding normalize or handoff. After this phase, chatContent is laid out invisibly but no further action happens.

- [ ] **P4.1** Add `canvasRef: weak TimelineCanvas?` to RevealCoordinator.
- [ ] **P4.2** Modify `RevealCoordinator.present(conversation:)` to call `cell.installChatContentIfNeeded` (via dispatch async per §8.1 Mitigation B).
- [ ] **P4.3** Build. Tap a cell. Verify chatContent is created (use a log) but invisible.
- [ ] **P4.4** Verify no visual regression on forward path.
- [ ] **P4.5** Verify chatContent persists in cell after the user pinches back (via reverse — but reverse is still broken at this phase, so verify via Xcode debugger inspecting cell.chatContentContainer).

**Phase 4 exit gate:** chatContent is being installed but invisible; forward visually unchanged; build green.

**Phase 4 Pillar review sub-gate:**
- [ ] **P12.2** V2RootVC tells canvas + cell to install chatContent; doesn't reach into cell internals
- [ ] **P18.14** dispatch async closure uses [weak self] AND [weak canvas] capture lists
- [ ] **P11.1** `installChatContentForActiveCell` is a single-concern helper on V2RootVC
- [ ] **P6.7** every guard-let chain has WHY comment
- [ ] **P1.1** guard-chains: combine sequential guards into one block
- [ ] **P19.3** installChatContentIfNeeded is idempotent (calling twice no-ops second call)

**Estimated duration:** 1 day.

### Phase 5 — Wire pre-warm: normalize after crossFade

**Wave Topology DAG (Phase 5):**

```
PHASE 5
│
├─→ Wave 5.1 (normalizeToChatRest method + 5 helpers on TimelineCanvas) ─╮
├─→ Wave 5.2 (crossFade.addCompletion wiring in RevealCoordinator)        ├─→ [WC Merge Gate 5] ─→ Phase 5 complete
└─→ Wave 5.3 (canvas.alpha=0 invariant verification per §2.6)             ╯
```

Three waves parallel: normalize body + the wiring + the invariant verification.

**Wave assignments:**
- **Wave 5.1** — `[SE, CC]` normalizeToChatRest per §2.3.1 (orchestrator + 5 SRP helpers)
- **Wave 5.2** — `[RO]` extend crossFade.addCompletion to schedule normalize via DispatchQueue.main.async per §16.10
- **Wave 5.3** — `[SA, IV]` verify §2.6 canvas.alpha=0 invariant (grep `canvas.alpha = ` across codebase; verify only crossFade end + handoff write)
- Retro `[CQR, RCT, SA, DCH, IV, CA-conc, BV, VR]`

- [ ] **P5.1** Add `normalizeToChatRest(activeCellIndex:)` to TimelineCanvas per §2.3.
- [ ] **P5.2** Modify `RevealCoordinator.crossFade.addCompletion` to schedule normalize (DispatchQueue.main.async).
- [ ] **P5.3** Add temp logs at normalize start and end.
- [ ] **P5.4** Build. Tap a cell. Verify normalize runs (log fires). Verify visually no change (because canvas.alpha=0).
- [ ] **P5.5** Verify post-normalize state via debugger: `contentHost.layer.transform == identity`, `cell.heightConstraint.constant == bounds.height`, no held animations.
- [ ] **P5.6** Verify no visual regression. The user should not see normalize happen.

**Phase 5 exit gate:** normalize runs invisibly; state correct post-normalize; no visual regression.

**Phase 5 Pillar review sub-gate:**
- [ ] **P11.1** normalizeToChatRest body delegates to 5 single-concern helpers per §2.3.1
- [ ] **P12.2** normalize delegates camera write to `setCamera(_:)` rather than writing applyCameraTransform directly
- [ ] **P6.7** invalid activeCellIndex case has `assertionFailure` in DEBUG + WHY comment
- [ ] **P19.3** normalize is idempotent (re-running produces same state)
- [ ] **P2.11** every MorphAnimationKey reference via enum, no string literals
- [ ] **P13.4** each helper ≤10 LOC
- [ ] **P10.x** suppressed CATransaction wraps mutation block; setCamera (which itself wraps) called OUTSIDE the inner transaction (no nested transactions)
- [ ] **P3.5** helper names carry the contract; reader understands flow top-to-bottom

**Estimated duration:** 1-2 days.

### Phase 6 — Wire handoff at T=2.8s

**Wave Topology DAG (Phase 6) — highest-parallelism phase:**

```
PHASE 6
│
├─→ Wave 6.1 (HandoffPhase enum + handoffPhase var)               ─╮
├─→ Wave 6.2 (5 phase-transition writes in runRevealChoreography) ─┤
├─→ Wave 6.3 (performHandoff + 4 step helpers per §2.4.1)         ─┤
└─→ Wave 6.4 (V2RootVC didActivateNotification observer)          ─╯
                                                                   ├─→ [WC Merge Gate 6.A]
                                                                                │
                                                                                ↓
                                              Wave 6.5 (end-to-end forward path verification)
                                                                                │
                                                                                ↓
                                                                  [WC Merge Gate 6.B] ─→ Phase 6 complete
```

Four implementation waves parallel; verification wave depends on all four; final merge gate at phase exit.

**Wave assignments:**
- **Wave 6.1** — `[RO]` HandoffPhase enum + property per §32.3.1
- **Wave 6.2** — `[RO]` 5 milestone phase-transition writes in runRevealChoreography per §32.3.1
- **Wave 6.3** — `[RO, SM, GM]` performHandoff + 4 step helpers + mapTextRange per §2.4.1
- **Wave 6.4** — `[CR]` V2RootVC didActivateNotification observer + handleSceneDidActivate per §32.3.1
- **Wave 6.5** — `[VR, BV, ER]` end-to-end forward path verification (tap → handoff visible-no-change)
- Retro per wave + final retro `[CQR, RCT, SA, DCH, IV, CA-conc, BV, VR, PP]`

**EXEMPLAR — Wave 6.3 Retrospective + Merge Gate (use this template for every wave):**

This is a full instantiation of §A.4's 6-step protocol applied to Wave 6.3 (`performHandoff` + 4 step helpers + `mapTextRange` per §2.4.1). Engineers replay this template for every wave with wave-specific substitutions.

**Step 1 — Structured exit checklist (Wave 6.3 specific):**
- [ ] `xcodebuild -project DotPinchPrototype.xcodeproj -scheme DotPinchPrototype -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' build` returns 0
- [ ] InvariantHardeningTests pass (4 tests)
- [ ] `performHandoff` is callable from `blurFadeOut.addCompletion`
- [ ] `transferState(from:to:via:)` writes composerText + scrollOffset
- [ ] `performAtomicAlphaSwap(chatVC:canvas:chatContent:)` writes 5 alphas in one suppressed CATransaction
- [ ] `restoreFirstResponderIfNeeded(chatVC:chatContent:via:)` calls `becomeFirstResponder` ONLY if `composerIsFirstResponder == true`
- [ ] `detachAndReleaseChatVC(_:)` removes from V2RootVC.childVCs + releases strong ref
- [ ] `mapTextRange(from:to:range:)` returns valid UITextRange for non-empty selection
- [ ] No new constraint warnings; no Auto Layout assertions; no Sendable warnings
- [ ] §39 Phase 6 Pillar review sub-gate passes (P11.1, P10.x, P18.14, P6.7, P12.2, P13.4, P5.5, P1.1, P19.3, P3.5)

**Step 2 — Parallel audit-agent dispatch (WaveCoordinator issues all 5 in ONE message via parallel Agent tool calls):**

```
Agent dispatch (Wave 6.3 retro):
  [WC dispatches in parallel, all run_in_background: true]

  1. CQR audit (per §A.6 template):
     "Audit Wave 6.3 diff against Tier-3B+ pillars. Specifically scan
      performHandoff + 4 step helpers + mapTextRange. Report violations
      by pillar ID. Verify: no force-unwraps, no magic numbers, no closure
      without [weak self] (mapTextRange has none — verify no closures
      stored), method length ≤20 LOC, P19.1 mapTextRange purity, P19.3
      idempotency of step helpers."

  2. RCT full audit (per §A.5 protocol + §A.6 template):
     "Apply 6-question RCT to every load-bearing decision in Wave 6.3:
       (a) Decision: split handoff into 4 step helpers vs inline body
       (b) Decision: capture state BEFORE atomic alpha swap (not after)
       (c) Decision: becomeFirstResponder AFTER the CATransaction (not inside)
       (d) Decision: mapTextRange via offset-based remap (not direct assign)
       (e) Decision: assertionFailure + return on missing-references guard
      For each: classify LOAD-BEARING / KEYSTONE / DECORATIVE / PHANTOM.
      Dispatch HOT-branch sub-agents on (b) and (c) — atomicity-related.
      Return RCT closure file as §14 / D-RCT-Wave-6.3 entry."

  3. SA substrate audit (per §A.6 template):
     "Verify Wave 6.3 doesn't violate CLAUDE.md Part 4 keystones:
       - contentHost.layer.sublayerTransform untouched? (performAtomicAlphaSwap
         writes canvas.alpha + chatVC.view.alpha + chatContent.alpha + pinchRecognizer
         — NOT sublayerTransform; ✓)
       - CATransaction.withSuppressedActions wraps the alpha swap? (✓ per §2.4.1)
       - cellPoolByConversationID identity preserved? (cell.chatContent is
         a strong property; cell stays in pool; ✓)
      Phenomenology check (Part 3): post-handoff state is 'one continuous
      object (the cell) at one of its representations (chat-rest)'. Confirm."

  4. DCH dead-code scan (per §A.6 template):
     "Scan Wave 6.3 diff for dead candidates:
       - performHandoff has caller (RevealCoordinator.blurFadeOut.addCompletion)
       - 4 step helpers each called exactly once by performHandoff
       - mapTextRange called once from restoreFirstResponderIfNeeded
       - chatViewController = nil — verify this property's write site count
      P3.3 deletion test on each. Report dead candidates or PASS."

  5. IV integration completeness (per §A.6 template):
     "Verify Wave 6.3 integration:
       - performHandoff called from RevealCoordinator wiring (Wave 6.2's
         milestone 5 + Wave 8.2 recovery path)
       - 4 step helpers each have one call site
       - TransientStateSnapshot used by capture path (Wave 6.3) AND bind
         path (Wave 4.2's onMorphRevealReady extension)
       - chatVC.captureTransientState() called by step 1 of handoff
       - chatContent.composer.composerTextField.text assigned by step 2
       - Every grep across modified files turns up the consumers. P3.8 greppability ✓"
```

**Step 3 — RCT-on-load-bearing-decisions (per §A.5):**

Wave 6.3's 5 load-bearing decisions enumerated above (a-e). RCT closure file expected output:

```
§14 / D-RCT-Wave-6.3:
  (a) split handoff into 4 step helpers
      Q5 deletion test: removing the split forces 30+ LOC inline body
                        → P11.1 SRP violation, P13.4 method-length violation
                        → CLASSIFIED: LOAD-BEARING (decomposition is invariant)
  (b) capture BEFORE alpha swap
      Q4 if changed (capture AFTER): swap fires; chatVC.alpha=0; reading
         chatVC.composerTextField.text might return cached/empty value as
         UIKit reaps the view; race condition
      Q5 if removed: state lost (round-trip broken)
      CLASSIFIED: KEYSTONE (ordering invariant; atomicity depends on it)
  (c) becomeFirstResponder AFTER CATransaction
      Q4 if changed (BEFORE/INSIDE): UIKit keyboard tracking may not honor
         responder transition while suppressed CATransaction is active
      CLASSIFIED: LOAD-BEARING (empirically tested; §4.4 documents the WHY)
  (d) offset-based mapTextRange
      Q5 if removed: direct UITextRange assignment fails (range bound to
         source text field's internal state)
      CLASSIFIED: KEYSTONE (UIKit API constraint)
  (e) assertionFailure + return on missing refs
      Q3 assumes: missing refs at handoff time imply scene-deactivation
         already cancelInFlight'd; §32 recovery handles
      Q4 if changed (silent return): bugs in scene-recovery path masked
      Q5 if removed: crash in DEBUG, undefined behavior in release
      CLASSIFIED: LOAD-BEARING (debugging discipline)
```

**Step 4 — Visual / empirical verification:**
- `[VR]` slow-motion screen recording at T=2.79s, T=2.80s, T=2.81s; pixel-diff between frames
- `[PP]` Instruments: time profiler captures handoff cost (target <2ms total)

**Step 5 — Merge gate decision (WC):**

```
Merge Gate 6.3 — WaveCoordinator decision:
  CQR: GREEN | RCT: GREEN | SA: GREEN | DCH: GREEN | IV: GREEN
  VR: GREEN  | PP: GREEN (handoff 1.4ms)
  → Merge Gate 6.3 OPEN
  → Wave 6.3 commits to phase-flow
  → Phase 6 progresses (next: Wave 6.4 or Merge Gate 6.A if 6.1-6.4 all complete)
```

**Step 6 — Decision log update:**

```
§14 / 2026-XX-XX — Wave 6.3 retro: PASSED
  - All 5 load-bearing decisions traced (D-RCT-Wave-6.3 above)
  - Handoff measured at 1.4ms (well under §8.4 budget of 10-20ms)
  - No dead code introduced (DCH PASS)
  - 5 audit agents all GREEN in single dispatch wave
  - Lesson learned: the capture-before-swap ordering (decision b) is
    the keystone of handoff atomicity; future modifications must preserve
    it. Document in §39.2.1 as a permanent invariant.
```

**This exemplar IS the template.** Every wave (1.1 through 12.5) gets this 6-step retro before its merge gate opens. The template substitutes wave-specific items at step 1 and decision enumeration at step 3; agent dispatch templates at step 2 are reusable verbatim per §A.6.

- [ ] **P6.1** Add `stateController: weak ConversationStateController?` to RevealCoordinator.
- [ ] **P6.2** Implement `performHandoff()` per §2.4 sketch.
- [ ] **P6.3** Modify `blurFadeOut.addCompletion` to call `performHandoff()` BEFORE `blur.detach()`.
- [ ] **P6.4** Test forward end-to-end:
  - Tap cell A
  - Verify reveal looks identical to today
  - At T=2.8s+, verify chatContent is visible (debugger: `cell.chatContentContainer.alpha == 1`)
  - Verify chatVC removed (`revealCoordinator.chatViewController == nil`)
  - Verify canvas.alpha == 1
  - Verify pinchRecognizer.isEnabled == true
- [ ] **P6.5** Verify state transfer:
  - Tap A
  - Type "test" in composer during chat-state
  - Verify composer text is preserved post-handoff (because handoff fires before user typing — this test verifies T-time of handoff)
  - More important test: type a message, then trigger a re-handoff (e.g., via tap-A-pinch-back-tap-A)

**Phase 6 exit gate:** forward path completes with chat-state visible via cell.chatContent. ChatVC dismissed. No visible artifact at T=2.8s.

**Phase 6 Pillar review sub-gate:**
- [ ] **P11.1** performHandoff delegates to 4 step-helpers per §2.4.1
- [ ] **P10.x** atomic alpha swap inside ONE suppressed CATransaction; state capture BEFORE; first-responder + detach AFTER
- [ ] **P18.14** [weak self] on every closure in handoff path (HandoffPhase transitions inside addCompletion closures)
- [ ] **P6.7** missing-references case has `assertionFailure` + WHY
- [ ] **P12.2** state controller owns capture/apply seam; handoff delegates
- [ ] **P13.4** performHandoff ≤20 LOC; helpers ≤15 LOC
- [ ] **P5.5** handoffPhase is `private(set)` (read for tests/recovery; write fenced)
- [ ] **P1.1** missing-references guard chains all 6 binds in one block
- [ ] **P19.3** performHandoff is idempotent (handoffPhase==.handoffComplete guard prevents re-entry)
- [ ] **P3.5** code-as-documentation: reader follows 4 steps top-to-bottom without flipping files

**Estimated duration:** 2-3 days.

### Phase 7 — Wire reverse direction

**Wave Topology DAG (Phase 7):**

```
PHASE 7
│
├─→ Wave 7.1 (V2RootVC.handleTap activeCellIndex guard per §16.8) ─╮
├─→ Wave 7.2 (CellView.setCamera curves: chatContent.alpha line)   ├─→ [WC Merge Gate 7.A]
└─→ Wave 7.3 (springToCellRest + tryClearActiveCellAtRest verify)  ╯       │
                                                                            ↓
                                                                Wave 7.4 (end-to-end reverse path verification)
                                                                            │
                                                                            ↓
                                                                  [WC Merge Gate 7.B] ─→ Phase 7 complete
```

Three implementation waves parallel; reverse-end-to-end depends on all three.

**Wave assignments:**
- **Wave 7.1** — `[CR, GM]` handleTap guard per §16.8 (the new bug fix from honest audit)
- **Wave 7.2** — `[CA, SE]` add `chatContent.alpha = smoothstep(0.30, 0.50, progress)` line to setCamera (P7-only; replaced by §23.5 hybrid in P10)
- **Wave 7.3** — `[GM, CC]` verify handlePinchBegan/Changed/Ended + springToCellRest already work from chat-rest origin (existing code; no changes; just verification)
- **Wave 7.4** — `[VR, BV, ER]` round-trip preservation test (tap A → type → pinch back → tap A again → state preserved)
- Retro `[CQR, RCT, SA, DCH, IV, BV, VR, PP]`

- [ ] **P7.1** Verify after handoff, pinching on chat surface initiates `handlePinchBegan` (add log).
- [ ] **P7.2** Verify `handlePinchChanged` writes heightConstraint correctly.
- [ ] **P7.3** Verify `setCamera` fires per gesture event with progress decreasing.
- [ ] **P7.4** Verify alpha curves: chatContent fades out as progress drops; chrome fades in.
- [ ] **P7.5** Verify `handlePinchEnded` classifies `.pinchToCells` correctly.
- [ ] **P7.6** Verify `springToCellRest` engages with critically damped spring.
- [ ] **P7.7** Verify spring settles to naturalH; `tryClearActiveCellAtRest` fires; `activeCellIndex = nil`.
- [ ] **P7.8** Round-trip test:
  - Tap A → type "hello" → pinch back → tap A → composer shows "hello"
  - Tap A → scroll → pinch back → tap A → scroll position preserved
  - Tap A → pinch back → tap B → tap A: A's state preserved, B's state isolated

**Phase 7 exit gate:** reverse direction works end-to-end; round-trip state preserved.

**Phase 7 Pillar review sub-gate:**
- [ ] **P10.2** V2RootVC.handleTap's new activeCellIndex guard matches existing isPresenting guard pattern (consistent multi-guard form)
- [ ] **P6.7** every guard with silent return has WHY comment
- [ ] **P11.1** setCamera applier methods (per §39.2.1) each have one concern
- [ ] **P12.2** cell.setCamera tells its own subviews what alphas to take; doesn't query state
- [ ] **P19.3** every applier idempotent across pinch ticks
- [ ] **P18.10** edge cases verified: spring interruption (new pinch during spring), gesture velocity transfer, springToCellRest target consistency

**Estimated duration:** 2-3 days.

### Phase 8 — Edge cases & polish

**Wave Topology DAG (Phase 8) — most parallel phase:**

```
PHASE 8
│
├─→ Wave 8.1 (Reduce Motion: forward + reverse snap paths)              ─╮
├─→ Wave 8.2 (Scene deactivation recovery: §32 completeHandoffIfPending) ─┤
├─→ Wave 8.3 (Memory warning + flushPoolForMemoryPressure)               ─┤
├─→ Wave 8.4 (Pinch-commit chrome symmetry: §36 PMCT + interrupt reset)  ─┤
├─→ Wave 8.5 (handlePinchBegan interrupt reset block per §36.3.1)        ─┤
├─→ Wave 8.6 (Instruments: leaks + memory growth + FPS profiling)        ─┤
└─→ Wave 8.7 (Visual regression: side-by-side recordings)                ─╯
                                                                          ├─→ [WC Merge Gate 8] ─→ Phase 8 complete
```

Seven waves parallel; all independent edge-case handlers + verifications. Highest concurrency phase.

**Wave assignments:**
- **Wave 8.1** — `[CC, RO, GM]` Reduce Motion paths per §7.4
- **Wave 8.2** — `[RO, CR]` §32.3.1 recovery handler + observer
- **Wave 8.3** — `[SE, LS, CR]` §35.3.1 flush + §35 CellView teardown helper + V2 observer
- **Wave 8.4** — `[CC, CA]` PMCT call in playTapToChatMorph per §36.3.1
- **Wave 8.5** — `[GM, CA]` interrupt reset block in handlePinchBegan per §36.3.1
- **Wave 8.6** — `[PP]` Instruments profiling (leaks + memory + FPS)
- **Wave 8.7** — `[VR]` 100-round-trip visual regression
- Retro `[CQR, RCT, SA, DCH, IV, CA-conc, BV, VR, PP]`

- [ ] **P8.1** Reduce Motion path (§7.4)
- [ ] **P8.2** Scene deactivation recovery (§7.1, §7.2)
- [ ] **P8.3** Memory warning handler (§7.8)
- [ ] **P8.4** Conversation deletion guard (§7.7)
- [ ] **P8.5** Foreground recovery for partial-handoff state (§7.12)
- [ ] **P8.6** Activecellindex mismatch guard (§7.11)
- [ ] **P8.7** Instruments: leak check over 100 round-trips
- [ ] **P8.8** Instruments: memory growth check
- [ ] **P8.9** Visual regression: side-by-side screen recording forward at T=0, T=0.42, T=1.5, T=2.10, T=2.80 — pre-implementation vs post-implementation
- [ ] **P8.10** Run InvariantHardeningTests; verify pass
- [ ] **P8.11** Build verification:
  ```bash
  xcodebuild -project DotPinchPrototype.xcodeproj -scheme DotPinchPrototype \
    -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' build
  ```
- [ ] **P8.12** Remove all temporary dev logs

**Phase 8 exit gate:** all edge cases handled; no leaks; no visual regression; build green; invariants pass.

**Phase 8 Pillar review sub-gate (this phase touches §32, §35, §36 retrofits + edge-case handling):**
- [ ] **P11.1** completeHandoffIfPending decomposed into per-cluster helpers per §32.3.1
- [ ] **P11.1** flushPoolForMemoryPressure decomposed per §35.3.1
- [ ] **P10.x** interrupt-reset in handlePinchBegan (per §36.3.1) wrapped in suppressed CATransaction; every removeAllAnimations + alpha reset paired
- [ ] **P18.14** [weak self] on every NotificationCenter observer
- [ ] **P5.7** every addObserver has matching removeObserver in deinit (existing pattern at V2:72-74 covers via catch-all)
- [ ] **P18.16** app lifecycle: backgrounding/foregrounding tested at multiple T-points per §38 Q3
- [ ] **P6.7** every silent return has WHY comment
- [ ] **P13.4** every new helper ≤20 LOC
- [ ] **P15.5** no lava-layer: old animation references cleaned up (no dual mechanisms coexisting)
- [ ] **P19.3** recovery (completeHandoffIfPending) + memory flush + interrupt reset all idempotent

**Estimated duration:** 3-5 days.

### Summary

**Total estimated duration:** 13-22 days of focused engineering work, single-threaded.

**Critical path:** Phase 0 → Phase 1 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7 → Phase 8. Phase 2 can run in parallel with Phase 1.

**Risk-weighted path:** Phase 0 (verification) is the highest-leverage phase. If the empirical results differ from expectations (e.g., safe area divergence is REAL on this device class), the plan adjusts. Don't rush Phase 0.

---

## §13 — Risk register

| ID | Risk | Probability | Impact | Mitigation |
|---|---|---|---|---|
| R1 | Safe area divergence is real and Strategy A doesn't fully resolve it | Low (per §3 analysis) | High (visible handoff jump) | Phase 0 verifies empirically before structural code. If real, fallback to Strategy B (additionalSafeAreaInsets) or Strategy C (explicit constants). |
| R2 | Frame drops at T=1.6s due to double-layout | Medium | Medium (visible jank during blurFadeIn) | Profile in Phase 0; dispatch async (Mitigation B). If still bad, migrate ChatBubbleStackView to UICollectionView. |
| R3 | State transfer drops user input (mid-typing, mid-scroll, IME state) | Low (capture-at-handoff is robust) | Medium (user sees lost input) | Capture all four state fields; document IME loss as acceptable; manual test scenarios. |
| R4 | Scene deactivation mid-handoff leaves partial state | Medium | High (broken UI on return) | Add `completeHandoffIfPending()` recovery path; test programmatically. |
| R5 | Memory leak from cross-view constraints | Low (verified no cycle in §3.6) | Medium (heap growth) | Weak parentVC reference; explicit teardownCrossViewConstraints on eviction; Instruments verification. |
| R6 | Layout mismatch (constraint values diverge from chatVC's) | Medium | High (visible handoff jump) | Constraint-by-constraint replication per §3.5; side-by-side screen capture validation. |
| R7 | ChatVC retain cycle | Low | Medium (memory growth) | Review closures for `[weak self]`; release chatVC at handoff; Instruments leak check. |
| R8 | Reduce Motion edge cases (snap behavior incorrect) | Low | Medium (accessibility regression) | Add explicit Reduce Motion paths in forward (skip animations + immediate handoff) and reverse (skip spring + snap). Manual test with setting enabled. |
| R9 | morphInProgress / setCamera coexistence bugs | Medium | Medium (alpha jitter during reverse or handoff) | Audit setCamera invocation timing per §9.3; add isPresenting guard if needed. |
| R10 | cancelInFlight doesn't fire blurFadeOut completion | Medium | Medium (partial-handoff state) | Verify empirically in Phase 0.7; if completion doesn't fire on cancel, implement explicit handoff invocation in cancelInFlight. |
| R11 | Theme.Page.surface ≠ Theme.Cell.fill creates color seam | Low (likely same) | Low (subtle visible color shift) | Verify in Phase 0.3; if different, set chatContent.backgroundColor = Theme.Page.surface explicitly. |
| R12 | Long-conversation layout time exceeds budget | Medium (depends on usage) | Medium (jank on T=1.6s for >200-message convos) | Profile with realistic data in Phase 0; migrate to UICollectionView if needed (deferred). |
| R13 | Cross-conversation state leak (state controller bound to wrong UUID) | Low | High (privacy / correctness bug — user sees Conv A's text in Conv B's composer) | Identity-mismatch teardown in `configure(with:)`; assertion at bind time; Phase 7 isolation test. |
| R14 | Substrate-keystone violation | Low (per §0.7 audit) | High (phenomenological inconsistency, framework-fight bugs) | §0.7 audit; CLAUDE.md Part 4 review before commit; InvariantHardeningTests pass. |

Mitigation strategies are linked to specific checklist items in earlier sections.

---

## §14 — Decision log

Append-only record of architectural decisions made during planning and implementation. Each entry: date, decision, rationale, alternatives considered.

### 2026-05-25 — D1: Handoff approach chosen over alternatives
- **Decision:** Adopt the handoff approach (Option C in §0.3) over Option A (procedural coordinator) and Option B (eliminate ChatVC).
- **Rationale:** Lowest forward-visual risk; preserves validated cane curve and reveal cinematography exactly; engineering scope manageable (~13-22 days); reversible if brittle (can later collapse to Option B).
- **Alternatives:** Option A rejected (coordinator complexity unbounded for two-view sync during reverse). Option B deferred (cleaner architecturally but requires substantial forward-path rewrite).

### 2026-05-25 — D2: Composed sub-components for ChatContentContainer
- **Decision:** Composed `ChatHeaderView` + `ChatBubbleStackView` + `ChatComposerView` rather than a single monolithic view.
- **Rationale:** State controller binds naturally to three logical surfaces; future feature scaling (streaming, voice, attachments) likely modifies one sub-component; per-component layout debugging.
- **Alternatives:** Monolith (rejected — harder to maintain as chat surface grows).

### 2026-05-25 — D3: Cross-view constraints for safe area (Strategy A)
- **Decision:** ChatContentContainer's subviews reference `parentVC.view.safeAreaLayoutGuide` directly (not the cell's safe area, not additionalSafeAreaInsets).
- **Rationale:** Inherits the same safe area chatVC uses; explicit semantic clarity; survives rotation automatically.
- **Alternatives:** Strategy B (additionalSafeAreaInsets compensation) rejected as fragile (must recompute on rotation). Strategy C (explicit constants) rejected as inflexible across device sizes.
- **PENDING VERIFICATION:** §3.2 empirical check — if cell.safeAreaInsets is correct after normalize, both A and B work; we still pick A.

### 2026-05-25 — D4: Release ChatVC each present (no cache)
- **Decision:** ChatVC is released at handoff (`revealCoordinator.chatViewController = nil`). No instance cache.
- **Rationale:** State controller handles state preservation; re-instantiation cost ~15-30ms acceptable; avoids parallel LRU cache that must stay synced with cellPool.
- **Alternatives:** Cache (deferred — revisit if profiling shows hotspot).

### 2026-05-25 — D5: ConversationStateController owned by cell
- **Decision:** stateController is a strong property of CellView; created lazily on `cell.configure(with:)`; persists across pool round-trips for same conversation; released on cell eviction.
- **Rationale:** Lifetimes mirror cellPool's bounded LRU (20); no parallel cache to sync; identity-keyed semantics inherited.
- **Alternatives:** Owned by V2RootVC with separate LRU (rejected — sync complexity).

### 2026-05-25 — D6: Capture-at-handoff state transfer (not continuous sync)
- **Decision:** State captured from chatVC and applied to chatContent at handoff moment, not via continuous subscription.
- **Rationale:** Simpler; no subscription loops; chatVC is sole interactive surface from T=2.10s to T=2.8s.
- **Alternatives:** Continuous sync (rejected — subscription complexity).

### 2026-05-25 — D7: Dispatch async for cell.installChatContentIfNeeded
- **Decision:** The chatContent install at T=1.6s is dispatched to the next runloop tick via `DispatchQueue.main.async`.
- **Rationale:** Splits double-layout cost across two ticks; reduces frame-drop visibility during blurFadeIn.
- **Alternatives:** Synchronous install (rejected — Phase 0 profiling will confirm).

### 2026-05-25 — D8: Handoff fires at blurFadeOut completion (T=2.8s), not crossFade completion (T=2.10s)
- **Decision:** performHandoff is wired into blurFadeOut.addCompletion.
- **Rationale:** At T=2.8s, chatContent has had ~1.2s to lay out (no pressure); handoff is the natural END marker of forward path; normalize has already run.
- **Alternatives:** crossFade completion (rejected — would pile normalize + handoff at one moment).

### 2026-05-25 — D9: chatContent.alpha = 0 at cell-rest (retained, not torn down)
- **Decision:** After reverse settle, chatContent stays in cell at alpha=0 (not removed).
- **Rationale:** State preservation across round-trip; ~150KB per cell × 20 cells = ~3MB acceptable.
- **Alternatives:** Tear down on cell-rest (deferred optimization).

### 2026-05-25 — D10: stateController binds to chatVC at install time (not only at handoff)
- **Decision:** RevealCoordinator.installChatViewController calls `stateController.bind(to: chatVC)` to write preserved state INTO chatVC.
- **Rationale:** Solves the bug in §4.8 where re-presenting an already-visited conversation would overwrite preserved state with chatVC's empty initial state.
- **Alternatives:** Skip capture at handoff if already preserved (rejected — complex flag-tracking).

### Future entries

Append decisions made during implementation here. Format:

```
### YYYY-MM-DD — DN: <decision title>
- **Decision:** ...
- **Rationale:** ...
- **Alternatives:** ...
```

---

## §15 — Implementation status

Updated as work progresses.

| Phase | Status | Owner | Started | Completed |
|---|---|---|---|---|
| Phase 0 — Verification | Not started | | | |
| Phase 1 — ChatContent components | Not started | | | |
| Phase 2 — StateController | Not started | | | |
| Phase 3 — CellView integration | Not started | | | |
| Phase 4 — Parallel layout wiring | Not started | | | |
| Phase 5 — Normalize wiring | Not started | | | |
| Phase 6 — Handoff wiring | Not started | | | |
| Phase 7 — Reverse direction | Not started | | | |
| Phase 8 — Edge cases & polish | Not started | | | |

---

---

## §16 — Codebase verification findings (2026-05-25)

Result of Wave-1 deep read against the 13 gaps identified at planning. Each finding either **CONFIRMS** the original checklist, **CORRECTS** a misconception, **RESOLVES** a gap, or **SURFACES** new gaps. All facts cited to file:line.

### §16.1 — TWO forward paths (CRITICAL ORIENTING FINDING)

The codebase has two distinct forward paths from cell-rest to chat-rest. The checklist's per-millisecond timeline was implicitly assuming the tap path only. Both must be handled.

**§16.1.1 — Tap path: `TimelineCanvas.animateCameraToChatRest(forCellAt:)` (TC:1235-1322)**

- Attaches FOUR additive `CABasicAnimation`s to `contentHost.layer` with `isRemovedOnCompletion = false`:
  - `windupScale` (key=`"windup.scale"`): on `transform.scale`, from=0 to=`MorphTiming.windupContribution` (0.08), duration=`MorphTiming.windupDuration` (0.78s), easeOut, additive
  - `zoomScale` (key=`"zoom.scale"`): on `transform.scale`, from=0 to=`zoomContribution` (= `finalScale - 1.0 - 0.08`), duration=`totalMorphDuration` (1.5s), `MorphCurves.zoomLanding` (0.7, 0.0, 0.4, 1.0), additive
  - `windupTranslate` (key=`"windup.translate"`): on `transform.translation.y`, from=0 to=`MorphTiming.translateYTarget` (-50), duration=1.5s, `MorphCurves.translateLanding` (0.0, 0.0, 0.2, 1.0), additive
  - `morphCentering` (key=`"morph.centering"`): on `transform.translation.y`, from=0 to=`-cellOffsetFromViewportCenter * finalScale` (the cell-centering term), duration=1.5s, zoomLanding curve, additive
- Calls `cell.performMorphChromeTransition(profile:)` (TC:1307) which attaches `centerLabelOpacity` CABasicAnimation (key=`"centerLabel.opacity"`) to `chatRestCenterLabel.layer` and animates `dateLabel/topicSummary/today/pinchGlyph` alphas to 0 via `UIView.animate` (CV:317-352)
- Schedules `onMorphRevealReady` via `DispatchWorkItem` at `totalMorphDuration + revealReadyDelay` (1.5s + 0.1s = 1.6s after invocation) (TC:1309-1321)
- **Camera (`camera.translation`) is NOT updated by this path.** Camera stays at `lastCellRestScrollY + bounds.height/2`. The visual centering comes entirely from the held `morphCentering` animation on contentHost.layer.transform. **This is the root cause of the camera position gap surfaced in Gap 1.**
- After cane curve completes (T=1.5s): contentHost.layer.presentation has scale=finalScale (≈4.92), translation.y=`-50 + (-cellOffsetFromViewportCenter * finalScale)`. Held until `removeAnimation(forKey:)` fires.

**§16.1.2 — Pinch-commit path: `TimelineCanvas.playTapToChatMorph(forCellAt:)` (TC:1359-1405)**

- Calls `morphChoreographer.engage(choreo)` — uses `CurveAnimator<CGFloat>` (master CADisplayLink) for the duration of `MorphTiming.masterTimerDuration` (1.2s)
- Per-tick (MorphChoreographer:66-85):
  - Writes `contentHost.layer.transform = CATransform3DMakeTranslation(0, unifiedArcY, unifiedArcZ)` (sin-bell arc; Y peaks negative at t=0.5 of 0..0.7 phase, Z peaks positive in same window; at t≥0.7, both 0)
  - Writes `heightC.constant = startHeight + (endHeight - startHeight) * t` (linear interpolation; endHeight = naturalH × chatRestFactor)
  - Writes `canvas.applyMorphTickCameraWrite(translation: startCameraY + (endCameraY - startCameraY) * t, cell: cell)` — UPDATES the camera (camera.translation = endCameraY = activeCell.frame.midY at t=1.0)
- On completion (TC:1397-1404): `contentHost.layer.transform = CATransform3DIdentity` (explicit reset), `updateNeighborTranslations`, `onMorphRevealReady?(revealK)`
- **At completion: camera is centered, heightConstraint is at chat-rest, contentHost.transform is identity, NO held CABasicAnimations.** This is structurally cleaner than tap path's end state.

**§16.1.3 — BOTH paths route through `RevealCoordinator.present`**

Confirmed at V2RootViewController:57-62:
```swift
timelineCanvas.onMorphRevealReady = { [weak self] cellIndex in
    guard let self else { return }
    guard cellIndex < self.store.conversations.count else { return }
    guard !self.revealCoordinator.isPresenting else { return }
    self.revealCoordinator.present(conversation: self.store.conversations[cellIndex])
}
```

**Implication for the handoff:** The handoff via `RevealCoordinator.present`'s completion callback fires for BOTH forward paths transparently. We do NOT need separate handling per path. Normalize must handle both states (mostly no-op for pinch-commit, corrective for tap).

**Gap 2 RESOLVED:** pinch-commit forward IS routed through RevealCoordinator.present. Handoff applies transparently.

### §16.2 — Exact RevealTiming values (DesignSystem/RevealTokens.swift)

```swift
enum RevealTiming {
    static let blurFadeInDuration: TimeInterval = 0.3
    static let crossFadeDelay: TimeInterval = 0.2
    static let crossFadeDuration: TimeInterval = 0.3
    static let blurDwellDelay: TimeInterval = 0.5
    static let blurFadeOutDuration: TimeInterval = 0.7
}
```

**T-times relative to `RevealCoordinator.present` invocation (= T_revealReady):**
- T+0.0s: blurFadeIn starts (0.3s duration)
- T+0.2s: crossFade starts (0.3s duration) — chatVC.alpha 0→1, canvas.alpha 1→0
- T+0.3s: blurFadeIn completes (blur at alpha=1)
- T+0.5s: crossFade completes (chatVC fully visible, canvas at alpha=0) + blurFadeOut starts (0.7s duration)
- T+1.2s: blurFadeOut completes (blur detached) — **this is the natural handoff moment**

Canvas.alpha=0 window: T+0.5s to T+1.2s = **0.7 seconds**. Normalize and any structural work runs in this window.

**The reveal sequence is 1.2s long, NOT 1.4s as the original checklist's §2.1 implied.**

### §16.3 — Exact MorphTiming and MorphAnimationKey (DesignSystem/MorphTokens.swift)

```swift
enum MorphTiming {
    static let windupDuration: CFTimeInterval = 0.78
    static let totalMorphDuration: CFTimeInterval = 1.5    // tap path total
    static let masterTimerDuration: TimeInterval = 1.2     // pinch-commit total
    static let revealReadyDelay: TimeInterval = 0.1        // tap path only buffer
    // ... other values
}

enum MorphAnimationKey: String {
    case windupScale = "windup.scale"
    case zoomScale = "zoom.scale"
    case windupTranslate = "windup.translate"
    case morphCentering = "morph.centering"
    case centerLabelOpacity = "centerLabel.opacity"
}
```

**The exact keys for `removeAnimation(forKey:)` in normalize.** Verified in §16.6 below.

### §16.4 — Master timeline corrected (per-path, absolute T from user trigger)

**Tap path (user taps cell at T=0):**
| T (s) | Event |
|---|---|
| 0.00 | `animateCameraToChatRest(forCellAt:)` called; cane curve 4 animations attached; `pinchRecognizer.isEnabled = false`; `setActiveCellIndex(k)` |
| 0.00–0.28 | `performMorphChromeTransition` UIView.animate fades chrome (date/topic/today/pinchGlyph) alphas 1→0 |
| 0.78–1.50 | `centerLabelOpacity` CABasicAnimation animates `chatRestCenterLabel.alpha` 0→1 (held after 1.5s) |
| 1.50 | Cane curve animations complete; values held |
| 1.60 | DispatchWorkItem fires `onMorphRevealReady` → V2RootVC calls `revealCoordinator.present(...)` |
| 1.60 | (NEW) `cell.installChatContentIfNeeded(...)` invoked from V2RootVC before `revealCoordinator.present` |
| 1.60 | `RevealCoordinator.installChatViewController` → chatVC.view added (alpha=0), `chatVC.configure`, `chatVC.view.layoutIfNeeded` |
| 1.60 | blurFadeIn animator starts (0.3s) |
| 1.80 | crossFade animator starts (0.3s after delay=0.2s) |
| 1.90 | blurFadeIn completes (blur opaque) |
| 2.10 | crossFade completes — `chatVC.view.alpha=1, canvas.alpha=0, chatVC.view.isUserInteractionEnabled=true` |
| 2.10–2.80 | **CANVAS.ALPHA=0 WINDOW** (NEW: normalize runs here) — blurDwellDelay=0.5s elapses (blur stays opaque), blurFadeOut starts at T=2.60 actually... wait |

Hmm let me recompute. blurFadeOut.startAnimation(afterDelay: blurDwellDelay=0.5). Delay is relative to when `startAnimation(afterDelay:)` is CALLED, which is at T=1.60 (when runRevealChoreography runs). So blurFadeOut starts at T=1.60 + 0.5 = T=2.10. blurFadeOut duration 0.7s → ends at T=2.80. ✓

Corrected:
| T (s) | Event |
|---|---|
| 2.10 | crossFade completes; canvas.alpha=0 from here onward |
| 2.10 | blurFadeOut starts (0.7s); blur.alpha 1→0 |
| 2.10–2.80 | **CANVAS.ALPHA=0 WINDOW = 0.7s** — normalize can run here |
| 2.80 | blurFadeOut completes → completion callback fires (only at position .end) — **HANDOFF MOMENT** |

**Pinch-commit path (user releases pinch at T=0 with commit-to-chat):**
| T (s) | Event |
|---|---|
| 0.00 | `playTapToChatMorph(forCellAt:)` → MorphChoreographer.engage |
| 0.00–1.20 | MorphChoreographer per-tick: heightConstraint linear interpolation, camera linear interpolation to `activeCell.frame.midY`, transform = sin-bell arc translation |
| 1.20 | MorphChoreographer completes → completion sets `contentHost.layer.transform = identity` + `updateNeighborTranslations` + `onMorphRevealReady` |
| 1.20 | (NEW) cell.installChatContentIfNeeded + revealCoordinator.present called |
| 1.20 | blurFadeIn animator starts (0.3s) |
| 1.40 | crossFade starts (0.3s after delay=0.2s) |
| 1.70 | crossFade completes — canvas.alpha=0 |
| 1.70 | blurFadeOut starts (0.7s after delay=0.5s) |
| 1.70–2.40 | **CANVAS.ALPHA=0 WINDOW = 0.7s** — normalize runs (mostly no-op for pinch-commit) |
| 2.40 | blurFadeOut completes → **HANDOFF MOMENT** |

**Both paths converge to identical post-handoff state.**

### §16.5 — Camera position correction (Gap 1 confirmed REAL, mitigation refined)

For the **tap path**: `camera.translation` is NOT updated during the cane curve. It remains at `lastCellRestScrollY + bounds.height/2`. The visual centering is via the held `morphCentering` CABasicAnimation on `contentHost.layer.transform.translation.y`. When normalize REMOVES the held animation, contentHost.transform returns to identity → the active cell visually returns to its pre-tap position (off-center).

For the **pinch-commit path**: `cameraAnimator` (TC:1375-1379) targets `activeCell.frame.midY`. By morph completion at T=1.20s, camera IS at the centered position. Normalize's camera write is a no-op for this path.

**Normalize MUST set `camera = Camera(translation: activeCell.frame.midY)`** to correct for the tap path. This makes the post-normalize state identical for both forward paths.

Verified at TC:1289-1290:
```swift
let cellOffsetFromViewportCenter = activeCell.frame.midY - camera.translation
let centeringTranslate = -cellOffsetFromViewportCenter * finalScale
```

The centering term has scale baked in. After we remove the scale (by removing the cane curve animations), the centering term must be reapplied via the camera (which doesn't scale).

### §16.6 — Chrome alpha state divergence between forward paths (NEW GAP)

**Tap path:** at T=1.5s, chrome alphas are at model layer 0 (set by `performMorphChromeTransition` via UIView.animate). chatRestCenterLabel.alpha presentation=1 (CABasicAnimation), model=0. Post-normalize, model alphas remain at 0 — visible chrome alphas at the model layer match chat-rest.

**Pinch-commit path:** MorphChoreographer does NOT call `performMorphChromeTransition` (verified by reading MorphChoreographer.swift end-to-end). `cell.setCamera` IS called per-tick (via `applyMorphTickCameraWrite`) but EARLY-RETURNS due to `morphInProgress` guard (CV:256: `if morphInProgress { return }`). So during pinch-commit, **chrome alphas stay at model layer 1 throughout the morph.** At completion, morphInProgress becomes false (curveAnimator=nil), but no code refreshes alphas — they remain at 1.

**Consequence for handoff:** at T=2.40s when handoff fires (pinch-commit path), chrome alphas at model layer = 1. canvas.alpha=1 (after the swap). The user would see chrome layered over chatContent. **BUG unless normalize drives `cell.setCamera(camera, viewport:)` to refresh alphas.**

**Mitigation:** normalize MUST call `cell.setCamera(camera, viewport: bounds)` after setting heightConstraint. At progress=1 (chat-rest), setCamera writes `labelStack.alpha = 0`, `pinchGlyph.alpha = 0` (per the existing CV:265-267 formula). This is now consistent across both forward paths.

**This is a CORRECTION to §2.3 normalize.** The updated normalize is in §16.10 below.

### §16.7 — Reduced normalize scope (no need to set chatRestCenterLabel.alpha explicitly)

The tap path's `centerLabelOpacity` CABasicAnimation sets the MODEL layer chatRestCenterLabel.alpha to 0 already (CV initial value, line 69), and the held animation only affects the presentation layer. Removing the held animation in normalize restores presentation = model = 0 automatically. The defensive `cell.chatRestCenterLabel.alpha = 0` in normalize is still safe (idempotent) but not strictly necessary.

Same for chatRestCenterLabel.transform: model layer is whatever performMorphChromeTransition wrote (`CGAffineTransform(scaleX: counterScale, ...)` — CV:318). Normalize's `transform = .identity` is necessary defense for round-trip cleanliness.

For the **pinch-commit path**: chatRestCenterLabel is at alpha=0 (from CV init) and transform=.identity throughout. No CABasicAnimation attached. Normalize's removeAnimation is a no-op for this path. Safe.

### §16.8 — V2RootVC.handleTap needs `activeCellIndex` guard (NEW GAP 14)

Current V2RootVC.handleTap (V2:85-91):
```swift
@objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
    let viewportPoint = recognizer.location(in: timelineCanvas)
    let pagePoint = timelineCanvas.pagePointFromViewportPoint(viewportPoint)
    guard let idx = timelineCanvas.cellIndex(atPagePoint: pagePoint) else { return }
    guard !revealCoordinator.isPresenting else { return }
    timelineCanvas.animateCameraToChatRest(forCellAt: idx)
}
```

The guard `!revealCoordinator.isPresenting` blocks re-tap during the reveal sequence. In the CURRENT codebase, `isPresenting` stays true forever after present (no dismiss), so re-tap is blocked indefinitely.

**With our handoff at T=2.8s:** `revealCoordinator.revealState` returns to `.idle` after we tear down chatVC. `isPresenting` becomes false. The user is now in chat-state (cell.chatContent visible, canvas.alpha=1). A tap on the composer text field would:

1. Hit the chatContent's composerTextField (UITextField is interaction-enabled and would activate)
2. Tap recognizer (attached to canvas, `cancelsTouchesInView=false` per V2:54) ALSO fires
3. handleTap → cellIndex resolved (= active cell's index, because chatContent is inside the active cell)
4. `isPresenting = false` → guard passes
5. `animateCameraToChatRest(forCellAt: idx)` called → re-attaches the 4 cane curve animations on top of chat-state

**This is a real bug.** The tap recognizer's `cancelsTouchesInView=false` (intentional, so the composer can activate) means handleTap fires alongside the textField's own touch handling. We need an additional guard.

**Mitigation:** add `guard timelineCanvas.activeCellIndex == nil` to handleTap. The active cell stays set throughout chat-state and during reverse spring; clears only when `tryClearActiveCellAtRest` settles. This is the natural gate.

**This is a NEW gap not in the original 13.** Adding to §6 and §12 Phase 6.

### §16.9 — RevealCoordinator wiring constraints

**`init(parent: UIViewController, canvas: UIView)`** — canvas is taken as UIView, not TimelineCanvas. RevealCoordinator's internal code only does `canvas.alpha = 0/1` and doesn't access TimelineCanvas-specific methods. The handoff orchestration (calls to `canvas.normalizeToChatRest`, `cell.installChatContentIfNeeded`, etc.) MUST live in V2RootViewController where the typed access exists, not inside RevealCoordinator.

**`present(conversation:completion:)`** — completion fires only at `position == .end` of blurFadeOut (RC:93-99). On scene-deactivation via `cancelInFlight()` (RC:135-143), `finishAnimation(at: .current)` is called. Per Apple docs, `finishAnimation(at:)` does fire completion handlers but with the supplied `UIViewAnimatingPosition` — `.current` in this case. So the `if position == .end` checks fail and `blur.detach() + completion?()` are skipped. **This means our handoff completion will NOT fire on cancellation.** Recovery on resume is needed (§7.1 mitigation).

**`activeChatVC: ChatViewController?`** — already exposed (RC:14-17). Use this for handoff state capture.

**`isPresenting: Bool`** — already exposed (RC:19-22). Use this for the `setCamera`/handleTap guards (§9.3 + §16.8).

### §16.10 — Corrected `normalizeToChatRest` implementation

Replaces §2.3 sketch. Comprehensive version that works for BOTH forward paths:

```swift
// TimelineCanvas additions:

func normalizeToChatRest(activeCellIndex: Int) {
    guard let cell = instantiatedCells[activeCellIndex] else {
        assertionFailure("normalizeToChatRest called with invalid activeCellIndex \(activeCellIndex)")
        return
    }
    CATransaction.withSuppressedActions {
        // Step 1: Remove held cane curve animations (tap path; no-op for pinch-commit)
        contentHost.layer.removeAnimation(forKey: MorphAnimationKey.windupScale.rawValue)
        contentHost.layer.removeAnimation(forKey: MorphAnimationKey.zoomScale.rawValue)
        contentHost.layer.removeAnimation(forKey: MorphAnimationKey.windupTranslate.rawValue)
        contentHost.layer.removeAnimation(forKey: MorphAnimationKey.morphCentering.rawValue)
        contentHost.layer.transform = CATransform3DIdentity

        // Step 2: Clear chatRestCenterLabel transient state (tap path; no-op for pinch-commit)
        cell.chatRestCenterLabel.layer.removeAnimation(forKey: MorphAnimationKey.centerLabelOpacity.rawValue)
        cell.chatRestCenterLabel.transform = .identity
        cell.chatRestCenterLabel.alpha = 0

        // Step 3: Extend heightConstraint to chat-rest (no-op for pinch-commit; correction for tap)
        cell.heightConstraint?.constant = bounds.height
        contentHost.layoutIfNeeded()
    }
    // Step 4: Center the active cell in viewport (no-op for pinch-commit; correction for tap).
    // setCamera will fire pushCameraToVisibleCells which drives cell.setCamera, refreshing
    // chrome alphas to chat-rest values (crucial for pinch-commit which left chrome at alpha=1).
    setCamera(Camera(translation: cell.frame.midY))
}
```

**Why this normalize is path-agnostic:**
- For tap path: every step is corrective (removes held animations + resets state + extends height + centers camera + refreshes alphas)
- For pinch-commit path: most steps are no-ops (no animations to remove; transform already identity; height already at chat-rest; camera already centered) EXCEPT step 4's `setCamera` which now refreshes chrome alphas that pinch-commit left at 1

**The single normalize handles both forward paths.** No path-specific branching needed.

### §16.11 — ChatBubbleView is reusable directly (Gap 5 RESOLVED)

`ChatBubbleView` (Conversation/ChatBody/ChatBubbleView.swift, 80 LOC) takes a `Message` in init and lays out role/body/time labels with constraints. No external dependencies on chatVC's view hierarchy or constraints. **Can be used directly in our `ChatBubbleStackView`** — no extraction, no parallel implementation needed. Update §11.1: ChatBubbleStackView CREATES ChatBubbleViews from messages, reusing the existing class.

### §16.12 — ChatViewController's subviews are PRIVATE (NEW GAP)

All five subviews — `headerLabel`, `scrollView`, `bubbleStack`, `composerContainer`, `composerTextField` — are declared `private` (CVC:10-14). Our handoff's `captureFromChatVC(_ chatVC: ChatViewController)` cannot read them from outside the type.

**Resolution options:**

- (a) Change `private` to `internal` (no `private` keyword; Swift default is internal). Simple. Aligned with the existing pattern in CellView where most subviews use `private(set)`.
- (b) Add explicit `internal` getters: `var composerTextRaw: String? { composerTextField.text }`, etc. More explicit but more boilerplate.
- (c) Add a method on ChatViewController: `func captureTransientState() -> (text: String, scrollOffset: CGPoint, ...)`. Encapsulates the state contract.

**Decision provisional: Option (c).** ChatViewController exposes a `captureTransientState()` method that returns the bundle of state the handoff needs. Encapsulation preserved; no leaky access to internal views.

Add to §1.5 Modified Files: `ChatViewController.swift` gets a `captureTransientState()` method.

### §16.13 — ConversationStore is immutable (Gaps 6, 7, 13 RESOLVED → moot)

`ConversationStore` (Conversation/Data/ConversationStore.swift, 27 LOC) declares `let conversations: [Conversation]` and `private let conversationsByID`. **No insert / delete / update methods.** The store is set once at init from `DummyConversationLoader.load()` (V2:19) and never mutated.

**Implications:**
- Live message updates during chat-state are impossible — no new messages can arrive. **Gap 6 moot** for V1. (Defer live-update infrastructure.)
- Conversation deletion is impossible — no API. **Gap 7 moot**. (No need to guard against deletion during chat-state.)
- UUID identity drift is impossible — conversations are fixed at init. **Gap 13 moot**.

**Future scaling note:** if `ConversationStore` later gets mutation methods, all three concerns reactivate. Document in §17 as deferred work.

### §16.14 — Tap recognizer cancelsTouchesInView=false has implications (clarification on §16.8)

V2:53-55:
```swift
let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
tap.cancelsTouchesInView = false
timelineCanvas.addGestureRecognizer(tap)
```

`cancelsTouchesInView=false` means: the tap recognizer fires its action AND the touches continue to be delivered to subviews. This is intentional so that:
- Taps on cells trigger forward morph via handleTap → animateCameraToChatRest
- Taps on text fields (e.g., composer) ALSO activate the text field for editing

If we set `cancelsTouchesInView=true`, the composer textField wouldn't activate on tap (the recognizer would consume the touch). We MUST keep it false.

So the only mitigation for the re-tap-during-chat-state bug is the `activeCellIndex` guard in handleTap (§16.8).

### §16.15 — UIView.hitTest's alpha=0 threshold resolves Gap 4

`UIView.hitTest(_:with:)` returns nil for views with `alpha < 0.01` (Apple-documented behavior). At chat-rest post-handoff:
- `labelStack.alpha = 0` (set by `cell.setCamera` at progress=1)
- `pinchGlyph.alpha = 0` (same)
- `chatRestCenterLabel.alpha = 0` (set in normalize)
- `chatContentContainer.alpha = 1`

Hits at the top region of the cell will skip labelStack/pinchGlyph (both alpha=0) and route to chatContentContainer's interactive subviews (composer text field, bubble stack scrollview). **No special handling needed.** Gap 4 RESOLVED.

### §16.16 — `morphInProgress` predicate and setCamera guard

`CellView.morphInProgress = morphChoreographer?.isRunning ?? false` (CV:76). Returns true ONLY during MorphChoreographer.engage. Returns false:
- During the tap path's cane curve (uses CABasicAnimation, not MorphChoreographer)
- During the reveal sequence (T=1.6s–T=2.8s)
- After morph completion
- During reverse direction (gesture-driven)

`cell.setCamera` early-returns when morphInProgress=true (CV:256). This means:
- During tap path's cane curve: setCamera CAN fire (morphInProgress=false). BUT no gesture is firing setCamera during this window (recognizers disabled). And `pushCameraToVisibleCells` is called from `setCamera(_:)` but that's not invoked unless something writes the camera. Nothing writes camera during cane curve. So setCamera effectively doesn't fire.
- During pinch-commit's MorphChoreographer: setCamera IS called per tick (via applyMorphTickCameraWrite → updateVisibleCells → pushCameraToVisibleCells → cell.setCamera) but morphInProgress=TRUE → early-return. **This is why chrome alphas freeze at 1 during pinch-commit.**
- During normalize (after both forward paths complete): morphInProgress=false, setCamera runs, alphas refresh correctly.

**Implication:** the §2.4 `performHandoff` sketch's final `canvas.setCamera()` call is redundant if normalize already called `setCamera(Camera(translation: cell.frame.midY))` (which it does in the corrected version). One call is sufficient.

Update §2.4: remove the final `canvas.setCamera()` call from performHandoff. Normalize handles it.

### §16.17 — `isQuiet` predicate (Gap 12 clarified)

```swift
private var isQuiet: Bool {
    !morphChoreographer.isRunning
        && !cameraAnimator.isRunning
        && extensionAnimator.state != .running
}
```

Used as a guard in `animateCameraToChatRest` (TC:1240). At various points:
- Cell-rest at scroll Y=0: isQuiet = true ✓
- During cane curve (tap path): no choreographer/animator running → isQuiet = TRUE. BUT the secondary guard `contentHost.layer.animation(forKey: windupScale) == nil` (TC:1239) BLOCKS re-entry. The animation keys are the actual guard.
- During pinch-commit MorphChoreographer: morphChoreographer.isRunning = TRUE → isQuiet = false ✓ blocks re-entry
- During reveal sequence (post-morph): isQuiet = true. But re-tap is guarded by `!revealCoordinator.isPresenting` in V2RootVC.handleTap.
- During reverse spring (after handoff): cameraAnimator and extensionAnimator are running → isQuiet = false. animateCameraToChatRest would early-return.

Gap 12 RESOLVED: isQuiet is correctly defined and the multi-guard pattern (isQuiet + animationKey + isPresenting + activeCellIndex) covers re-entry comprehensively.

### §16.18 — InvariantHardeningTests has 4 tests, not 5 (Gap 9 CLARIFIED)

Tests/V2/InvariantHardeningTests.swift contains:
1. `test_conversationStore_acceptsUniqueIDs` — verifies UUID uniqueness in store
2. `test_conversationStore_emptyInitIsEmpty` — empty store
3. `test_conversationStore_recencyOrdered` — sort by lastUpdatedAt
4. `test_sRGBLockedCGColor_isSRGB` — sRGB color space lock

None test handoff-state-relevant invariants. They will continue to pass unchanged. The CLAUDE.md reference to "5 invariant asserts" is stale — possibly referring to precondition asserts scattered through the code (e.g., setActiveCellIndex's range check at TC:358, centerYAnchor's debug assertion at CV:182, etc.).

### §16.19 — keyboardLayoutGuide is NOT used (NEW GAP, mostly deferred)

Grep across the codebase confirms `keyboardLayoutGuide` appears only in a comment (TC:826) — not in actual code. ChatViewController's composer anchors to `view.safeAreaLayoutGuide.bottomAnchor` (CVC:108), which does NOT auto-track the keyboard.

**Implication:** when the user taps the composer textField and the keyboard appears, the composer is HIDDEN behind the keyboard. This is an existing UX issue in the codebase, NOT a regression from the handoff approach.

**For cell.chatContent:** matching chatVC's existing behavior (anchor to `parentVC.view.safeAreaLayoutGuide.bottomAnchor`) maintains forward-visual identity at handoff. The composer will be hidden by the keyboard in both pre- and post-handoff states — symmetric behavior.

**Future work (out of scope):** upgrade both chatVC.composerContainer and chatContent.composer to anchor to `keyboardLayoutGuide.topAnchor` instead (iOS 15+ feature) so the composer rides above the keyboard. NOT part of this checklist.

### §16.20 — All 13 gaps disposition table

| Gap | Status | Where addressed |
|---|---|---|
| 1 — Camera position during chat-state | CONFIRMED real; mitigation refined | §16.5, §16.10 corrected normalize |
| 2 — Pinch-commit forward path's relationship | RESOLVED — routes through onMorphRevealReady | §16.1.3 |
| 3 — chatRestCenterLabel ↔ ChatHeaderView coexistence | RESOLVED — round-trip clean | §16.7 |
| 4 — labelStack/pinchGlyph hit-testing at chat-state | RESOLVED — alpha=0 skips hit-test | §16.15 |
| 5 — Bubble view extraction | RESOLVED — reuse ChatBubbleView directly | §16.11 |
| 6 — ConversationStore subscription | RESOLVED — store is immutable | §16.13 |
| 7 — Conversation deletion guard | RESOLVED — no delete API | §16.13 |
| 8 — Fast successive taps (state machine) | CONFIRMED real (different mechanism); guard needed in handleTap | §16.8, §16.14 |
| 9 — InvariantHardeningTests | CLARIFIED — 4 tests, none handoff-relevant | §16.18 |
| 10 — Order-of-introduction risks | Partial — addressed in §12 phases | §12 unchanged |
| 11 — onMorphRevealReady callback timing | CLARIFIED — 0.1s buffer (tap) vs 0s (pinch-commit) | §16.4 |
| 12 — isQuiet predicate | RESOLVED — comprehensive multi-guard | §16.17 |
| 13 — ConversationStore identity drift | RESOLVED — store immutable | §16.13 |

**Additional gaps surfaced during Wave 1:**

| Gap | Source | Where addressed |
|---|---|---|
| 14 — V2RootVC.handleTap missing activeCellIndex guard | §16.8 | §6 + §12 P6 retrofit (below) |
| 15 — Pinch-commit forward path leaves chrome at alpha=1 (CRITICAL) | §16.6 | §16.10 corrected normalize |
| 16 — ChatViewController subviews are private | §16.12 | New `captureTransientState()` method |
| 17 — keyboardLayoutGuide not used (existing UX issue) | §16.19 | Documented; out of scope |

---

## §17 — Open questions for Phase 0 (must verify empirically before structural code)

These questions cannot be resolved by code reading alone. Phase 0 runs them and documents results in §14 Decision log.

- [ ] **Q1 — Safe area divergence:** does `cell.safeAreaInsets.top` after normalize match `chatVC.view.safeAreaInsets.top` on iPhone 16? Method: add temp logs in `viewDidLayoutSubviews` of both, compare. **If equal:** Strategy A's cross-view constraints are correct AND any alternative (additionalSafeAreaInsets, cell.safeAreaLayoutGuide) would also work. **If different:** Strategy A (cross-view to parentVC.view.safeAreaLayoutGuide) is REQUIRED, others would land wrong.
- [ ] **Q2 — Theme.Page.surface vs Theme.Cell.fill color equality:** print both `UIColor` values. If equal, chatContent's `backgroundColor = Theme.Page.surface` is unnecessary (cell's background is already correct). If different, chatContent.backgroundColor MUST be set explicitly to Theme.Page.surface (matches chatVC's view background).
- [ ] **Q3 — RevealCoordinator.cancelInFlight completion behavior:** does `blurFadeOut.addCompletion` fire on `finishAnimation(at: .current)`? Test: trigger scene deactivation between T=2.10s and T=2.80s, log whether completion runs. **If yes:** handoff fires on cancellation — need to ensure handoff handles a partial state safely. **If no:** chatVC remains visible on resume → need explicit recovery path in `completeHandoffIfPending()`.
- [ ] **Q4 — UIView.hitTest alpha threshold confirmation:** is the threshold truly 0.01 on iOS 18 / 26? Some Apple-documented thresholds have shifted. Test: place a tap detector behind an alpha=0.005 view, verify it receives the tap. Confirms §16.15.
- [ ] **Q5 — `pushCameraToVisibleCells` during normalize's setCamera:** does cell.setCamera fire on the active cell when invoked from `pushCameraToVisibleCells` during normalize's `setCamera(Camera(translation: cell.frame.midY))`? Specifically, is `morphInProgress` reliably false at this point? Trace: normalize is invoked from `crossFade.addCompletion`'s deferred dispatch. By that time, both forward paths have completed (morph done long ago). Verify with assertion in normalize: `assert(!cell.morphInProgress)`.
- [ ] **Q6 — Tap recognizer firing under chat-state:** verify with logs that V2RootVC.handleTap fires when user taps composer text field at chat-state. Confirms §16.8 / Gap 14 is real.

---

## §18 — Long-term enablement

The handoff approach restores substrate-consistency at chat-state. This unlocks a family of capabilities that are currently infeasible because chatVC lives outside the canvas. None of these are in scope for this checklist's implementation — but they shape the value of doing this work *now* rather than later.

### §18.1 — Multi-conversation glance
Camera zoom-out from chat-state could show all conversations + the current one. Today impossible — chatVC is outside the canvas, has no relationship to cell-list cells. Post-handoff: a camera scale change (via the same sublayerTransform) would reveal neighbors.

### §18.2 — Substrate-participating message rendering
Live-arriving messages could animate via master CADisplayLink + identity-keyed bubble pool (if we extend the cell pool pattern to bubbles). Today: chatVC rebuilds the entire bubble stack on configure (CVC:119-127). No animation framework, no identity, no phase-locking.

### §18.3 — Per-message m34 perspective effects
A quoted reply or thread message could pop forward in 3D using `canvas.layer.sublayerTransform.m34 = -1/1000`. The substrate carries this perspective; today it doesn't reach chatVC's layer.

### §18.4 — Drag conversations during chat-state
Cell at chat-rest is a sibling of other cells in contentHost. A drag gesture on the chat-state cell could move it to a different position in the cell-list (e.g., reorder), with phase-locked motion of neighbors. Today: impossible (chatVC and cell-list are different view trees).

### §18.5 — Layered cell representations
Each layer (parent conversation → reply thread → composing) could be a cell representation transitioning via the same gesture vocabulary (pinch / extend). Today: would require nested view controllers with all their lifecycle overhead.

### §18.6 — Voice / attachments / reactions as chatContent variations
Each modality is a different ChatContentContainer subview swap, not a new modal VC. The cell remains the conversation; what changes is its representation.

### §18.7 — Phase-locked physics with cell-list during chat-state reverse
A pinch on the chat-state cell could ALSO peek at neighboring cells (subtle scale on neighbors during the pinch). The sublayerTransform already locks all cells; just adding per-cell scale on neighbors during chat-state's pinch would achieve this. Today: impossible (chatVC has no relationship to neighbors).

### §18.8 — Why this is load-bearing NOW
Every feature added in the current era couples to the substrate violation. Each new sync mechanism between chatVC and the canvas-side cell entrenches it. The longer we wait, the more code depends on the broken propagation, the more expensive the eventual fix.

Doing the handoff NOW:
- Reverse direction works (the visible win)
- Substrate is intact at chat-state (the structural win)
- Future features default to substrate-consistent (the strategic win — the §18.1–§18.7 family is unlocked)

---

## §19 — Section retrofits per §16 findings

Rather than rewrite §0–§14 inline (which would lose the auditable history of what changed and why), here is a focused list of corrections to apply during implementation. The retrofits below take precedence over the original §0–§14 where they conflict.

### Retrofit R1 — §0.4 step 4 (handoff cleanup)
- The original §0.4 step 4 left ambiguity about whether `canvas.setCamera()` is called at end of handoff. Per §16.16: it is NOT needed because normalize's `setCamera(Camera(translation: cell.frame.midY))` already refreshed cell.setCamera (which drives chrome + chatContent alphas). Remove the final canvas.setCamera call from performHandoff.

### Retrofit R2 — §1.2 ChatContentContainer parentVC parameter
- Keep weak parentVC; verified safe (§3.6). No change.

### Retrofit R3 — §1.5 ChatViewController modifications
- Add: `func captureTransientState() -> (text: String, scrollOffset: CGPoint, composerWasFirstResponder: Bool, selectedTextRange: UITextRange?)` (per §16.12).
- Make `composerTextField` and `scrollView` accessible (or expose via this method).

### Retrofit R4 — §1.6 RevealCoordinator role
- RevealCoordinator stays unchanged structurally. V2RootViewController orchestrates the handoff by passing a completion callback to `revealCoordinator.present(conversation:completion:)` AND by scheduling normalize between crossFade and blurFadeOut.

### Retrofit R5 — §2.1 Master timeline
- Replace the timeline numbers with §16.2 + §16.4 corrected values.
- Note: there are TWO timelines (tap path and pinch-commit path), not one.

### Retrofit R6 — §2.3 normalizeToChatRest implementation
- Replace the sketch with §16.10's corrected version.
- Key additions: `setCamera(Camera(translation: cell.frame.midY))` for camera centering AND chrome alpha refresh in ONE call.

### Retrofit R7 — §2.4 performHandoff implementation
- Update the wiring: handoff is invoked via the `completion` parameter of `revealCoordinator.present(conversation:completion:)`, not by extending blurFadeOut.addCompletion.
- Remove the final `canvas.setCamera()` call (redundant per R1).
- State capture via `chatVC.captureTransientState()` not direct subview access (per R3).

### Retrofit R8 — §2.5 Wiring points in RevealCoordinator
- Replace with V2RootVC-orchestrated wiring:
```swift
// V2RootViewController:
timelineCanvas.onMorphRevealReady = { [weak self] cellIndex in
    guard let self else { return }
    guard cellIndex < self.store.conversations.count else { return }
    guard !self.revealCoordinator.isPresenting else { return }
    let conversation = self.store.conversations[cellIndex]

    // Step 1: install cell.chatContent in parallel (pre-warm)
    self.installChatContentForActiveCell(conversation: conversation, cellIndex: cellIndex)

    // Step 2: schedule normalize after crossFade ends (T_present + 0.5s)
    let normalizeDelay = RevealTiming.crossFadeDelay + RevealTiming.crossFadeDuration + 0.05
    DispatchQueue.main.asyncAfter(deadline: .now() + normalizeDelay) { [weak self] in
        guard let self else { return }
        guard let activeIdx = self.timelineCanvas.activeCellIndex else { return }
        self.timelineCanvas.normalizeToChatRest(activeCellIndex: activeIdx)
    }

    // Step 3: present with handoff in completion
    self.revealCoordinator.present(conversation: conversation) { [weak self] in
        guard let self else { return }
        self.performHandoff(cellIndex: cellIndex)
    }
}
```

### Retrofit R9 — §3 Safe area
- Verify Q1 in Phase 0 BEFORE committing to Strategy A. If `cell.safeAreaInsets` matches `chatVC.view.safeAreaInsets` after normalize, cross-view constraints to `parentVC.view.safeAreaLayoutGuide` AND constraints to cell's own safeAreaLayoutGuide BOTH work. Pick Strategy A regardless for explicitness, but the empirical answer determines whether Strategy A is REQUIRED or merely PREFERRED.

### Retrofit R10 — §4 State transfer
- ChatViewController exposes `captureTransientState()` (per R3). The state controller becomes the bridge:
```swift
let snapshot = chatVC.captureTransientState()
stateController.composerText = snapshot.text
stateController.scrollOffset = snapshot.scrollOffset
stateController.composerIsFirstResponder = snapshot.composerWasFirstResponder
stateController.selectedTextRange = snapshot.selectedTextRange
stateController.applyTo(cell.chatContentContainer!)
```

### Retrofit R11 — §5 Identity preservation
- ConversationStore is immutable (§16.13). No "live updates" infrastructure needed. State controller is purely UI-state (composer + scroll) — does not need to subscribe to anything.

### Retrofit R12 — §6 Reverse direction
- §6.2 setCamera extension: keep `chatContent.alpha = smoothstep(0.30, 0.50, progress)`. **Do NOT add a chatRestCenterLabel.alpha curve** — leave it at 0 throughout reverse (set by normalize). On the next forward via tap, performMorphChromeTransition will re-animate it 0→1 via centerLabelOpacity CABasicAnimation.
- NEW: add to §6 — V2RootVC.handleTap needs `guard timelineCanvas.activeCellIndex == nil` (per §16.8):
```swift
@objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
    let viewportPoint = recognizer.location(in: timelineCanvas)
    let pagePoint = timelineCanvas.pagePointFromViewportPoint(viewportPoint)
    guard let idx = timelineCanvas.cellIndex(atPagePoint: pagePoint) else { return }
    guard !revealCoordinator.isPresenting else { return }
    guard timelineCanvas.activeCellIndex == nil else { return }  // NEW per §16.8
    timelineCanvas.animateCameraToChatRest(forCellAt: idx)
}
```

### Retrofit R13 — §7 Edge cases
- Drop §7.7 (Conversation deletion handling) — ConversationStore has no delete API (§16.13). Note as deferred work if mutation is added later.
- §7.1 (scene deactivation): per §16.9, cancelInFlight DOES fire completions but with `position == .current`. Our handoff completion checks `position == .end` (per the current RevealCoordinator pattern). So our handoff WILL NOT fire on cancellation. Need `completeHandoffIfPending` on foreground resume.

### Retrofit R14 — §9 Animation coexistence
- §9.3 setCamera writes during forward: verified — recognizers disabled during forward, no gesture fires setCamera. Pinch-commit's MorphChoreographer ticks DO call cell.setCamera but morphInProgress=true gates them. **No `isPresenting` guard needed** — recognizer state machine already handles it.
- §9.4 setCamera writes after handoff: normalize's `setCamera(Camera(translation: cell.frame.midY))` is the refresh. Single fire is enough; performHandoff doesn't need a second setCamera.

### Retrofit R15 — §11 Code organization
- Update new files list per §16.11: ChatBubbleView is REUSED, not extracted.
- Update modified files per §16.12: ChatViewController.swift gains a `captureTransientState()` method.

### Retrofit R16 — §12 Phase 6 (Handoff wiring)
- Phase 6 must include: add `activeCellIndex == nil` guard to V2RootVC.handleTap (per §16.8).
- Phase 6 must include: add `captureTransientState()` method to ChatViewController (per §16.12).

### Retrofit R17 — §13 Risk register
- Update R3 (state transfer) priority: lower probability because captureTransientState is encapsulated (per R3).
- Add R15: V2RootVC.handleTap missing activeCellIndex guard, probability HIGH (definitely happens without the guard), impact HIGH (visible re-cane-curve on top of chat-state). Mitigation: §16.8 guard added in Phase 6 (R12).
- Add R16: pinch-commit forward path leaves chrome at alpha=1, probability HIGH (always happens), impact HIGH (chrome visible on top of chatContent at chat-rest). Mitigation: normalize's setCamera call (R6).

---

---

## §20 — Phenomenological-polish scope

**Rationale for adding this section:** The honest audit in §16-§19 established that the handoff approach delivers mechanical correctness (pinch reaches chat-state cell, springToCellRest engages, alpha curves fire) and substrate participation (cell IS the chat post-handoff). But the user's described reverse-direction phenomenology (persistent inward-arrows affordance + atmospheric gradient revealing + chat content fading-by-distance + cell content materializing + "Today" loading dots + cell-above visibility + inverse-symmetry with tap-to-chat) requires FOUR additional pieces of work that the handoff alone does not deliver:

| ID | Element | Verdict (from audit) | This-checklist scope |
|---|---|---|---|
| P1 | Persistent inward-arrows affordance | NOT DELIVERED — entirely absent from code | **IN SCOPE** (default — small addition, ~50-80 LOC; phenomenology fails without it) |
| P2 | "Today" loading-dots indicator | NOT DELIVERED — requires opening immutable ConversationStore | **DEFERRED** (default — medium-large; requires mutation infra; gates substantial scope creep; flag for follow-on phase) |
| P3 | Distance-based fading via m34 | PARTIAL — alpha-curve approximates outcome but bypasses substrate primitive | **UPGRADE PATH SCOPED** (default — Z-translation + residual alpha as the substrate-pure mechanism; document both; recommend after handoff lands) |
| P4 | Inverse-symmetry cinematography (`playPinchToCellsMorph`) | ASYMMETRIC — reverse is mechanically minimal vs forward's 2.7s choreography | **DESIGN-ONLY SCOPED** (default — sketch the choreography in §24; decision to implement deferred pending user direction on whether gesture-driven shrink IS the cinematography frame-by-frame OR commit-driven choreography is required) |

**Override convention:** if any default is wrong, change the disposition in §14 Decision log (D11-D14 record this) and adjust §25 phase ordering accordingly.

**Why these defaults (one line each):**

- **P1 in-scope:** the affordance is the *signature* of what kind of object the cell is. Without it, chat-state lacks the gesture-handle marker; users discover collapse only by accident. Small implementation, strong phenomenological value.
- **P2 deferred:** requires `ConversationStore` mutability + observation + `Conversation.isActive` plumbing + animated indicator view. Each piece is reasonable; the bundle is a feature-track of its own. Handoff should not block on it.
- **P3 upgrade-scoped:** alpha-curve achieves the perceptual outcome (chatContent fades as cell shrinks); m34-driven Z-translation achieves the substrate-pure outcome (distance-fading is what the substrate does). Both work. The upgrade is non-invasive (one curve replaced by another in the same place) and substrate-purer, so we document the design and recommend the upgrade after handoff lands.
- **P4 design-only:** the gesture-driven reverse path is arguably more phenomenologically pure than choreography (user's finger IS the cinematographer). The user's phenomenology description IS consistent with gesture-driven progress IF the gesture velocity is preserved into a final settle spring (which we already have). Whether we ALSO add a separate commit-time choreography depends on what the user wants the spring to look like. Sketch first, decide later.

### §20.1 — Four elements, recap with substrate-attestation

For each element, the substrate test (per CLAUDE.md Part 3): does the proposed addition propagate the continuous-embodied commitment, or violate it?

- **P1 affordance:** the gesture-handle IS world-furniture. Persistent affordances propagate "this is an object, not a screen." Substrate-consistent. ✓
- **P2 dots:** "the conversation persists even when collapsed" propagates the world-continuity commitment. Open question: does the animation mechanism propagate? A timer-driven animation is substrate-broken (separate timing source); a master-CADisplayLink-driven animation is substrate-consistent. Implementation choice matters. ✓ if done right.
- **P3 distance-fading:** alpha-curve driven by progress is arguably substrate-consistent (progress IS the substrate's distance proxy) OR substrate-broken (m34 is the substrate's perspective primitive, unused). Both interpretations defensible. Z-translation engaging m34 is unambiguously substrate-consistent. ✓ either way; Z is purer.
- **P4 inverse-symmetry:** gesture-driven shrink IS substrate-consistent (user's gesture is the substrate's input primitive; the cell follows directly). Commit-time choreography would be one-shot animation — substrate-consistent if it uses the master CADisplayLink, substrate-broken if it uses an isolated timer. ✓ either way IF done right.

**None of the four elements REQUIRE substrate-breaking work.** All can be done substrate-consistently. The question is scope.

---

## §21 — Element P1: Persistent inward-arrows affordance (full root-cause-trace)

**Root node under trace:** "Add a persistent inward-arrows affordance at chat-state, top-left, as the causation marker that 'this state is pinch-collapsible from here.' Visible across virtually every frame of the morph between chat-rest and cell-rest."

### §21.1 — Six-question trace of the root node

**Q1 — What does this rest on? (Structural dependencies)**

The affordance rests on the following named dependencies in the existing system. Each dependency is itself traceable to bedrock if needed:

- **An SF Symbol identifier for inward arrows.** Candidate: `"arrow.down.right.and.arrow.up.left"` (the inverse of the existing outward `"arrow.up.left.and.arrow.down.right"`). The convention at `DesignSystem/SymbolName.swift` must be extended with a new constant.
- **`UIImageView` host for the symbol** — same pattern as existing `pinchGlyph` (`CV:78-89`). Configured via `UIImage.SymbolConfiguration(pointSize:weight:)` matching `Theme.Symbol.pinchAffordancePointSize` and `Theme.Symbol.pinchAffordanceWeight`.
- **A view to host the icon.** Two architectural choices: (a) subview of `CellView` (lives alongside `labelStack`, `pinchGlyph`, `chatRestCenterLabel`), or (b) subview of `ChatContentContainer` (lives inside the chat-rest representation only).
- **Position constraints.** User-described position: top-left. Existing `pinchGlyph` is bottom-right of cell (`CV:225-226`). Need anchored constraints to cell's `safeAreaLayoutGuide.topAnchor + 16, leadingAnchor + 20` (matching `labelStack`'s leading-anchor for visual rhyme with date label) OR to chat-content's parentVC safe area if hosted in chatContent.
- **An alpha curve driven by `progress`.** Function of (heightConstraint - naturalH) / (chatRestExt - naturalH). Curve shape is a decision (see Q4 / HOT branch).
- **The cell pool's identity preservation** (`cellPoolByConversationID`, TC:48-49): if the affordance is a subview of the cell, it persists naturally with the cell across round-trips. If subview of chatContent, the affordance is owned by chatContent and persists with chatContent (which also persists with cell — same chain).
- **The phenomenology's commitment that "this is an object, not a screen."** Gesture-handles being world-furniture (not state-furniture) is the structural premise that says the affordance must persist across the morph rather than appear/disappear.

**Q2 — Why does this exist? (Causal/historical origin)**

The affordance exists because:

- **Continuous-embodied phenomenology requires bidirectional gesture-handles.** Cell-rest has an outward-pinch affordance (existing `pinchGlyph`). Chat-rest must have its counterpart — a marker that this state is collapsible. Without it, the cell-rest state has a visible gesture vocabulary that chat-rest lacks. Asymmetric vocabulary = phenomenologically inconsistent.
- **Discoverability:** without a visible handle, users discover the pinch-to-collapse gesture only by accidental experimentation or external instruction. The visible handle teaches the gesture by its presence.
- **The user's described reverse-direction phenomenology explicitly names it:** "this is the causation marker. It announces 'this state is pinch-collapsible from here.'" The video reference shows it persistent across frames 040-150 of the morph.
- **`project_substrate_propagation_pinned` memory (2026-05-24)** flagged this as an explicit pending decision: "Reverse-direction affordance — currently no inward-arrows symbol exists in code. Pending decision on whether to add one or repurpose existing."

**Q3 — What assumptions does this encode? (Epistemological substrate)**

- **An SF Symbol that visually expresses "collapse" / "pinch-inward" exists or can be improvised.** The candidate `"arrow.down.right.and.arrow.up.left"` arrows-toward-center — symbolically reads as "compress" or "minimize." Alternative candidates: `"arrow.up.left.and.arrow.down.right.circle"` (with circle treatment), `"rectangle.compress.vertical"` (different semantic), `"arrow.down.forward.and.arrow.up.backward"` (3D variant). The first is the cleanest inverse of the existing forward affordance.
- **The cell at chat-rest has free top-left space for the icon.** Verified: chat-rest cell has chatContent fill edge-to-edge. chatContent's header (the day-marker) is centered horizontally at the top. Top-left has free space (chatContent's leading margin = 20pt, so leading 0-20 is unused). An icon at leading 16, top 16 fits in unused space.
- **The icon size, weight, and tint match the visual language of `pinchGlyph`.** Same `Theme.Symbol.pinchAffordancePointSize` (verify in `Theme.swift`) and `Theme.Text.glyph` tint.
- **The affordance is decorative (not interactive in itself).** Like `pinchGlyph`, its `isUserInteractionEnabled = false`. The actual pinch is captured by the canvas-level `pinchRecognizer`. The icon is a SIGNAL, not a hit target.
- **The persistence narrative is "world-furniture" rather than "chrome."** Implication: it must propagate through cell pool round-trips and across activeCellIndex changes. (Same property the existing `pinchGlyph` has.)

**Q4 — What would happen if this changed? (Forward propagation)**

Three meaningful changes to consider:

(a) **Change the alpha curve from "persistent across morph" to "progress-gated at chat-rest only":**

- Implementation: `inwardAffordance.alpha = smoothstep(0.05, 0.30, progress)`. At progress=0 (cell-rest), alpha=0. At progress=1 (chat-rest), alpha=1.
- Visual consequence: during reverse (morph from progress=1 to progress=0), the affordance fades out as the cell shrinks. The user sees the handle disappearing — incongruent with "gesture-handle as world-furniture."
- Phenomenological consequence: the affordance becomes chat-rest CHROME, not world-furniture. The user's described "persistence across the morph" is violated. Less phenomenologically pure.

(b) **Change the alpha curve to truly persistent (alpha=1 always):**

- Implementation: `inwardAffordance.alpha = 1` set once in init, never modified.
- Visual consequence at cell-rest: the inward arrows are visible at top-left AT THE SAME TIME as the outward `pinchGlyph` at bottom-right. The cell shows BOTH affordances simultaneously. Possibly confusing (which gesture should the user do?), possibly signal-rich (the user sees the full gesture vocabulary at all times).
- Phenomenological consequence: matches the user's description ("visible across virtually every frame") but introduces a UX question about dual-affordance display.

(c) **Change position from top-left to bottom-left (or elsewhere):**

- Top-left rhymes visually with `labelStack` (which is also leading-aligned, top-anchored).
- Bottom-left rhymes with `pinchGlyph` (bottom-right), creating a diagonal pair.
- Top-right would conflict with the centered `headerLabel` of chatContent.
- Center would conflict with the day-marker label.
- **Top-left is consistent with both the user's specification AND the existing layout grid.**

(d) **Replace the icon with text ("Pinch to collapse"):**

- Rejected: violates "world-furniture, not instruction text." The phenomenology is glyph-based.

**Q5 — What would happen if this were removed? (Load-bearing analysis)**

If we ship without the inward affordance:

- **Cell-rest state:** outward `pinchGlyph` signals "expand this." User has explicit visible cue.
- **Chat-rest state:** NO visible cue for "collapse this." User has no signal at all.
- **Asymmetric gesture vocabulary** = phenomenological inconsistency. Cell-rest has it, chat-rest doesn't.
- **User experience:** the reverse-direction gesture (the entire reason for the handoff approach) is invisible from the user's perspective. They have to be told (or accidentally discover) that pinch-in collapses. The very feature this checklist exists to enable is unsignaled.
- **Classification:** **KEYSTONE** node. Removing the affordance does not just remove decoration — it removes the discoverability of the entire reverse direction. The chat-state surface becomes a dead-end where the user doesn't know they can leave it.

**Q6 — What's absent? (Negative space analysis)**

What's missing from the design that one might expect:

- **No declared "affordance vocabulary" type in the codebase.** Cell-rest's `pinchGlyph` is just a `UIImageView` property on `CellView`. There's no `GestureAffordanceView` superclass that both could inherit. Engineering it as a one-off subview is consistent with the existing pattern.
- **No symbol theming for the affordance language.** `Theme.Symbol.pinchAffordancePointSize` and `Theme.Symbol.pinchAffordanceWeight` exist but only ONE symbol uses them (the outward `pinchGlyph`). Adding a second (inward) is the natural extension.
- **No accessibility label or hint declared.** `pinchGlyph` has no `accessibilityLabel` either (checked: `CV:78-89` is just the image config). Should we add `accessibilityLabel = "Pinch to collapse"` for VoiceOver? Per `feedback_a11y_priority`: capture but don't lead with; document but don't make it a P0.
- **No animation primitive for the affordance.** Could the affordance have a subtle pulse / scale-breath animation to draw attention? Phenomenologically defensible (the world breathes), but adds scope. Defer.
- **No reverse-direction's INTERACTION (does tapping the affordance trigger collapse, or is it purely a visual signal?).** Tapping pinchGlyph at cell-rest does NOT trigger expansion currently (it's `isUserInteractionEnabled = false`). Inverse-symmetry: the inward affordance should also be non-interactive. The pinch gesture itself is the interaction.

### §21.2 — HOT branches identified

| Branch | Heat | What's at stake |
|---|---|---|
| B21.A — **Position** (top-left vs alternatives) | WARM | UX visual grid coherence |
| B21.B — **Persistence curve** (truly persistent vs progress-gated) | HOT | Phenomenological purity; semantic clarity at cell-rest |
| B21.C — **Identity vs `pinchGlyph`** (separate view vs symbol-swap on existing view) | WARM | Code complexity; pool round-trip behavior |
| B21.D — **Host** (subview of `CellView` vs subview of `ChatContentContainer`) | WARM | Lifecycle ownership; alpha curve ownership |

### §21.3 — Trace of HOT branch B21.B (persistence curve)

**Sub-node:** Should the inward-arrows affordance have `alpha = 1` always, or fade with progress?

**Q1 (Rests on):** the phenomenology's interpretation of "world-furniture." If the affordance is world-furniture, it persists across all states. If it's chrome-of-chat-rest, it appears only at chat-rest.

**Q2 (Why this exists as a question):** the user's verbal description says "visible across virtually every frame" — strongly implies persistence. BUT the user is describing a REVERSE-DIRECTION video (from chat-rest back to cell-rest), so "every frame" might mean "every frame of this morph," not "every frame of the app's life." Ambiguous.

**Q3 (Assumes):** dual-affordance display at cell-rest (both inward AND outward visible) is acceptable. Either:
- (i) it's signal-rich: the user sees the world's gesture vocabulary at all times
- (ii) it's confusing: which gesture should the user do?

**Q4 (If changed — alpha=1 always):**
- Cell-rest: both affordances visible. User sees outward (signals expand) AND inward (signals collapse). At cell-rest, the cell is NOT collapsed — what does "collapse" mean here? Could read as "what this would look like when collapsed" (preview of state). OR could read as "this is how you'd un-do an expansion." Either way, semantic load.
- Chat-rest: ONLY inward visible (outward fades to 0 via existing curve `1 - smoothstep(0.05, 0.30, progress)`). Single affordance. Clear.
- Through morph: both visible at different alphas. The outward fades out as progress rises (existing behavior); the inward stays at 1. User sees a transition where one handle disappears and the other persists.

**Q4 (If changed — progress-gated `smoothstep(0.05, 0.30, progress)`):**
- Cell-rest: ONLY outward visible (alpha=1); inward at 0. Clean.
- Chat-rest: ONLY inward visible (alpha=1); outward at 0. Clean.
- Through morph: a crossfade between two affordances. Phenomenologically defensible but contradicts "persistence."

**Q5 (If removed — no affordance at all):**
- Collapsed back to KEYSTONE failure mode from Q5 of root: chat-rest has no gesture vocabulary visible.

**Q6 (Absent):**
- No middle option formally considered. "Persistent at all states with subtle alpha distinction" (e.g., 0.4 at cell-rest, 1.0 at chat-rest): semi-visible at cell-rest as a preview, fully visible at chat-rest as the active affordance. Phenomenologically interesting (the world's gesture vocabulary is always partly visible, fully visible when active). Adds complexity.

**Resolution of B21.B (default):**

**Use progress-gated alpha curve `smoothstep(0.05, 0.30, progress)`.** Rationale:
- Cleaner semantic: each affordance signals its respective state.
- Cell-rest has no semantic role for "collapse" affordance (the cell IS at cell-rest; there's nothing to collapse).
- Matches the existing pattern (outward affordance fades during forward; inward fades during reverse).
- The user's "every frame" language can be honored by tuning the curve range: `smoothstep(0.05, 0.30, progress)` keeps the inward affordance visible from progress=0.30 (mid-morph) through progress=1 (chat-rest), covering the bulk of "the morph from chat-rest to cell-rest" that the user described. Only at the deep cell-rest end (progress<0.30) does it fade fully.
- If user feedback later prefers truly persistent, change the curve to constant=1. Reversible.

### §21.4 — Trace of HOT branch B21.C (identity vs pinchGlyph)

**Sub-node:** Should we add a SEPARATE `ChatRestAffordanceView` UIImageView, or REUSE the existing `pinchGlyph` UIImageView with a state-driven symbol swap?

**Option C-1: Separate view.**
- Two `UIImageView` properties on `CellView`: existing `pinchGlyph` (outward, bottom-right, fades during forward) AND new `chatRestAffordance` (inward, top-left, fades during reverse).
- Each has its own constraints, its own alpha curve, its own symbol identifier.
- `setCamera` writes both curves.

**Option C-2: Reuse with symbol swap.**
- One `UIImageView` property `pinchGlyph` that swaps `.image` based on a state (e.g., when progress crosses 0.5, switch from outward to inward arrow image).
- Position changes too (bottom-right → top-left). Constraint reactivation per state.
- Single alpha curve.

**Comparison:**

| Dimension | Separate view | Symbol swap |
|---|---|---|
| Code complexity | +1 property, +1 constraint set, +1 curve | State-machine for symbol+position+constraints |
| Round-trip behavior | Both views persist with cell; no rebuild | Symbol+constraints must rebuild per state, risk of mid-flight artifacts |
| Visual behavior | Both can be visible simultaneously (crossfade through morph) | Only one at a time; transition is a swap |
| Phenomenological purity | "World has two gesture handles, visible at their respective states" — substrate-clean | "Same handle re-orienting based on state" — also defensible but more state-machine-y |
| Position flexibility | Bottom-right (out) ↔ top-left (in): the visual asymmetry is intentional and substrate-readable | Same position would force inward-affordance at bottom-right; user explicitly said top-left |

**Resolution of B21.C (default): Option C-1 (Separate view).** Top-left position is named in the phenomenology; symbol-swap on the existing bottom-right view would have to violate the position spec. Separate view also gives cleaner round-trip behavior and clearer alpha-curve composition.

### §21.5 — Trace of HOT branch B21.D (Host: CellView vs ChatContentContainer)

**Sub-node:** Where does the `chatRestAffordance: UIImageView` live in the view hierarchy?

**Option D-1: subview of `CellView`** (sibling of `labelStack`, `pinchGlyph`, `chatRestCenterLabel`, `chatContentContainer`).
- Constraints reference `safeAreaLayoutGuide.topAnchor + 16, leadingAnchor + 20`.
- Alpha driven by `setCamera` curve in CellView.
- Persists with cell across pool LRU.
- Visible in BOTH cell-rest (alpha=0 by curve) and chat-rest (alpha=1 by curve), with progress-driven transition.

**Option D-2: subview of `ChatContentContainer`** (lives only inside the chat representation).
- Created when `cell.installChatContentIfNeeded(...)` runs (T=1.6s of first forward).
- Constraints reference `parentVC.view.safeAreaLayoutGuide.topAnchor + 16, leadingAnchor + 20` (cross-view, like other chatContent subviews).
- Alpha is part of chatContent's container alpha (via §6.2's curve), so it inherits the same fade as bubbles and composer.
- Persists with chatContent which persists with cell.

**Comparison:**

| Dimension | D-1: CellView subview | D-2: ChatContentContainer subview |
|---|---|---|
| Lifecycle | Created at cell init; always present | Created lazily at first chat-state install |
| Independence from chatContent | Yes — affordance can have its own curve | No — affordance fades with the rest of chatContent |
| Visual timing | Can lead/lag chatContent's fade independently | Synchronized with chatContent |
| Substrate participation | Same as cell (inside contentHost, gets sublayerTransform, m34, etc.) | Same — chatContent is also inside cell |
| Code locality | CellView owns it (similar to existing pinchGlyph) | ChatContentContainer owns it (newer code) |

**Resolution of B21.D (default): Option D-1 (CellView subview).** Rationale:
- Mirrors `pinchGlyph`'s ownership and lifecycle exactly. Visual rhyme with the existing affordance.
- Independent alpha curve allows phenomenological tuning (e.g., affordance fades slightly LATER than chatContent during reverse, so the user still sees the handle as the chat content fades — emphasizing the handle's persistence).
- Available even before `installChatContentIfNeeded` runs (i.e., the cell pool's spare cells have the affordance ready-to-go).

### §21.6 — Concrete implementation tasks for P1 (the affordance)

**File-level additions:**

- [ ] **Add SF Symbol constant.** In `DesignSystem/SymbolName.swift`, add: `static let pinchCollapseAffordance = "arrow.down.right.and.arrow.up.left"`. (Or pick a final symbol via Phase 0.7 below.)
- [ ] **Extend `Theme.Symbol`.** Confirm `pinchAffordancePointSize` and `pinchAffordanceWeight` are exposed (verify in `Theme.swift`); if not, expose them. Both affordances share the same size/weight for visual rhyme.

**`CellView.swift` additions:**

- [ ] **Add property:** `private(set) var chatRestAffordance: UIImageView` initialized via the same lazy-init pattern as `pinchGlyph` (CV:78-89). Inward symbol, same tint (`Theme.Text.glyph`), `isUserInteractionEnabled = false`.
- [ ] **Add to `installSubviews`** (CV:208-215): `addSubview(chatRestAffordance)`. Order matters for default z-order; place AFTER `labelStack`, `chatRestCenterLabel`, `pinchGlyph` so the affordance renders ABOVE chrome but BELOW chatContent (chatContent is installed dynamically later).
- [ ] **Add to `activateConstraints`** (CV:217-233): top-anchor constraint to `safeAreaLayoutGuide.topAnchor + 16`, leading-anchor constraint to `leadingAnchor + 20` (matching `labelStack`'s leading inset). Width/height fixed by SF symbol intrinsic size.
- [ ] **Extend `setCamera`** (CV:253-277): add line `chatRestAffordance.alpha = smoothstep(0.05, 0.30, progress)`. (Per B21.B resolution: progress-gated; at chat-rest alpha=1, at cell-rest alpha=0.) Wrap inside the same `CATransaction.withSuppressedActions` already present in setCamera (CV implicit via setCamera's gating).
- [ ] **Verify pool-roundtrip:** `returnToPool` (TC:797-852) does NOT call any reset on `chatRestAffordance`. The affordance persists with the cell.
- [ ] **Verify `resetMorphState`** (CV:281-285): does NOT touch `chatRestAffordance`. Affordance is part of the world, not part of morph state.

**`AccessibilityID.swift` addition:**

- [ ] `static let chatRestAffordance = "cell.chatRestAffordance"` for UI testing identification.

**Update `setCamera` (CV:253-277) to include the new alpha write inside the existing computation flow:**

```swift
func setCamera(_ camera: Camera, viewport: CGRect) {
    guard bounds.height > 0 else { return }
    if morphInProgress { return }
    let naturalH = naturalHeight > 0 ? naturalHeight : bounds.height
    let chatRestFactor = viewport.height / naturalH
    let chatRestRange = chatRestFactor - 1.0
    let extensionFactor = bounds.height / naturalH
    let progress: CGFloat = chatRestRange > 1e-6
        ? min(1.0, max(0.0, (extensionFactor - 1.0) / chatRestRange))
        : 1.0

    let inverseFadeAlpha = 1 - smoothstep(0.05, 0.30, progress)
    labelStack.alpha = inverseFadeAlpha
    pinchGlyph.alpha = inverseFadeAlpha

    // NEW per §21:
    let forwardFadeAlpha = smoothstep(0.05, 0.30, progress)
    chatRestAffordance.alpha = forwardFadeAlpha

    layer.sublayerTransform = CATransform3DIdentity
    // ... existing horizontal inset adjustment ...
}
```

**Position constraints (more precise):**

- `chatRestAffordance.translatesAutoresizingMaskIntoConstraints = false`
- `chatRestAffordance.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16)`
- `chatRestAffordance.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20)`
- (no width/height constraints — let intrinsic size from the SF Symbol drive)

**Edge cases for P1:**

- **Affordance under iPad rotation (if iPad is in scope):** safeAreaLayoutGuide updates; top-left remains top-left. No additional handling.
- **Reduce Motion:** affordance alpha is set synchronously via setCamera writes — no animation. Reduce Motion compatible without changes.
- **affordance under Dynamic Type:** SF Symbol point size doesn't track Dynamic Type by default. If the design requires it, use UIImage.SymbolConfiguration scaling. Defer; not currently required.
- **Affordance interaction with chatContent's header position:** chatContent.header is centered horizontally (constraint in §1.2 sketch). Top-left affordance + centered header coexist. No conflict.
- **Affordance in the pool round-trip:** since alpha is purely a function of `progress` (heightConstraint ratio), after the cell returns to cell-rest the affordance's alpha is 0. On next forward to chat-rest, setCamera drives it back to 1. Stateless behavior across round-trips. ✓
- **Active-cell-only?** The affordance is on EVERY cell (not just the active one). When cell-rest, alpha=0; when chat-rest, alpha=1. Other cells in the cell-list always show alpha=0 because they're not at chat-rest. ✓ No special handling.

### §21.7 — Phase 0 empirical verifications for P1

- [ ] **Q7 — SF Symbol verification:** does `UIImage(systemName: "arrow.down.right.and.arrow.up.left")` return a valid symbol on iOS 18? If not, fall back to `"arrow.down.forward.and.arrow.up.backward"` or design a custom symbol. **CRITICAL**: this gate is iOS-version-dependent.
- [ ] **Q8 — Visual rhyme check:** does the inward affordance at top-left visually balance the outward at bottom-right at mid-morph (both alphas mid-fade)? Screen recording needed.
- [ ] **Q9 — Discoverability test:** with the affordance visible at chat-rest, do users discover the pinch-to-collapse gesture? (Out of scope for V1 testing but worth noting for follow-on user research.)

### §21.8 — Acceptance criteria for P1

- [ ] `cell.chatRestAffordance` exists and is a subview of `CellView`
- [ ] Constraints anchor it to top-left at (16, 20) inside cell safe area
- [ ] At chat-rest (progress=1): `chatRestAffordance.alpha == 1`, visible to user
- [ ] At cell-rest (progress=0): `chatRestAffordance.alpha == 0`, invisible
- [ ] During reverse (progress ∈ [0.30, 1.0]): `chatRestAffordance.alpha ∈ [0, 1]` per smoothstep
- [ ] After cell-pool round-trip (re-tap same conversation): affordance still works (no rebuild required)
- [ ] No new constraint warnings in console
- [ ] Visual balance with `pinchGlyph` (bottom-right) confirmed via screenshot diff
- [ ] No hit-test absorption (verify by tapping affordance area at chat-rest — taps should fall through to chatContent / underlying gesture recognizer)

---

## §22 — Element P2: Loading-dots indicator + conversation-active state (full root-cause-trace)

**Default disposition: DEFERRED.** This section documents the trace because the user's phenomenology names it ("the bottom cell ... its content is the loading/thinking dots") and because if we don't trace it now, we'll discover the dependency tree the hard way later. The trace clarifies what would be needed and why we're choosing to defer.

**Root node under trace:** "Add a per-cell loading/thinking dots indicator that visualizes 'Dot is still processing/responding' — visible on cells whose conversation has active background work, persistent across cell-rest, chat-state, and the morph between them."

### §22.1 — Six-question trace of the root node

**Q1 — What does this rest on? (Structural dependencies)**

The loading-dots indicator rests on a **dependency tree that is mostly absent from the current codebase.** Tracing each branch:

- **A per-conversation `isActive` state.** Where does this live?
  - On `Conversation` directly (`Conversation.swift`): would require making `Conversation` mutable, OR using a parallel `ConversationState` companion type.
  - In `ConversationStore`: would require `ConversationStore` mutability + observation.
  - In a separate `ConversationActivityTracker` actor / singleton: bypasses Store immutability but introduces a parallel source of truth.
  - **None of these exist today.**
- **A mutation API for the state.** Currently `ConversationStore` is `let conversations: [Conversation]` (immutable). The precondition at `ConversationStore:23-25` asserts UUID uniqueness on insert but no insert method is exposed. **No public mutation API exists.**
- **An observation mechanism.** `@Observable` is imported in `ConversationStore.swift:2` and the class is marked `@Observable` (line 4-6), but with `let` properties, observation is a no-op. **No event-driven update path exists.**
- **An animated dots view.** A 3-dot loading indicator. Could be:
  - A custom `UIView` with three `UIView` dots driven by a CADisplayLink-subscribed animator
  - A SwiftUI `View` wrapped in `UIHostingController` (introduces SwiftUI dependency)
  - A `UIActivityIndicatorView` (style: `.medium`, mediocre visual match for the user's described dots)
  - **None of these exist; would need to be added.**
- **A driver for the dots animation.** To stay substrate-consistent (per CLAUDE.md 2.1: master CADisplayLink is the single heartbeat), the dots animation must register with `AnimationController` via `AnimatorProviding`. **Existing animator types: `SpringAnimator`, `CurveAnimator`. Neither directly fits a looping dots animation.** A new `LoopingCurveAnimator` or `DotsPulseAnimator` would need to be added.
- **A trigger source for `isActive`.** What sets `isActive = true`? In the prototype, there's no "Dot" agent — no async work happens. The dots would have to be simulated (manual toggle in tests, or randomized for demo). In a future production version, this would be tied to backend message-sending state.
- **A binding mechanism between conversation state and cell.** When `isActive` changes for a conversation, the corresponding cell (if instantiated) must redraw its dots view. Requires either:
  - Cell subscribes to ConversationStore observation
  - Cell receives explicit invalidation calls from V2RootVC
  - State controller (per §1.4) extends to include isActive observation

**Q2 — Why does this exist? (Causal/historical origin)**

- **Continuous-world commitment:** the conversation persists even when the user pinches back to cell-rest. The dots are the world's signal that the conversation has not been "closed" — it's still alive in the background.
- **Causation propagation:** the user sent a message before pinching back. The system continues working on the response. The dots make this work visible.
- **Identity propagation across reverse:** the cell IS the conversation. The dots are on the cell because the conversation is the cell.
- **The "loose-end" closure principle:** without the dots, the user has no signal that they can return to find a response. They'd have to manually re-tap to check. The dots invite the return.
- **Phenomenological enrichment of cell-rest:** without dots, cell-rest is static — labels, glyph, summary. Static is OK for a "completed conversation" but wrong for "this conversation is alive." The dots distinguish alive cells from completed ones.

**Q3 — What assumptions does this encode? (Epistemological substrate)**

- **The "Dot" agent exists or will exist** that can produce isActive=true for a conversation. **Currently absent in the prototype.** This is a feature-track of its own (message sending → backend → streaming response → completion).
- **The activity state has clean transitions:** `idle → active → idle`. No partial states. (Real systems have streaming intermediate states; phenomenology might want to express those too — e.g., dots vs. "typing" vs. "done.")
- **One isActive flag suffices.** No multi-agent state (e.g., "Dot is thinking + Search is fetching"). One flag, one indicator.
- **The dots are visible on `cellRest` cells AND on chat-state cells.** The bottom cell in the user's video is at cell-rest with dots. Question: are the dots ALSO visible during chat-state (in the chatContent representation)? The user only described cell-rest dots. Defer.
- **The animation can be substrate-consistent** — driven by master CADisplayLink, suppressed implicit animations, etc. Achievable.

**Q4 — What would happen if this changed? (Forward propagation)**

(a) **If `ConversationStore` is opened to mutation:**
- Drop the `let conversations: [Conversation]` invariant.
- Add `func setActive(id: UUID, isActive: Bool)` or similar.
- The precondition assertion at `ConversationStore:23-25` (unique IDs on insert) may need to extend to: "no mutation while a transaction is in flight" — added complexity.
- All code that captured `store.conversations` as a snapshot must be re-examined for staleness.
- **Tests:** the 3 InvariantHardeningTests for ConversationStore (`acceptsUniqueIDs`, `emptyInitIsEmpty`, `recencyOrdered`) are read-only; they pass. But adding mutation tests would require new test files.

(b) **If a parallel state container is used (NOT touching ConversationStore):**
- New type: `ConversationActivityTracker` (@MainActor @Observable).
- Plain dict: `private var activeIds: Set<UUID>`.
- API: `setActive(_ id: UUID, _ active: Bool)`, `isActive(_ id: UUID) -> Bool`.
- ConversationStore remains immutable.
- Cells query the tracker rather than the store for activity state.
- **Pro:** doesn't touch the immutable Store invariant.
- **Con:** parallel source of truth (Store has conversation list; Tracker has active-set). Must stay in sync (e.g., on conversation deletion — when that's eventually added).

(c) **If the dots are CellView-internal toggleable via direct API:**
- `cell.setLoadingDotsVisible(_ visible: Bool)`
- V2RootVC or some controller manages the timing and calls this directly.
- No store-level state at all; transient UI state per cell.
- **Pro:** simplest. Doesn't change Store invariants.
- **Con:** state lives in views; lost when cells are pool-evicted (the conversation's activity state is lost when its cell is recycled out of the keyed pool). Identity-persistence broken for activity state.

**Q5 — What would happen if this were removed? (Load-bearing analysis)**

- **Cell-rest after pinch-back:** static. No signal of background activity. User must re-tap to check.
- **Phenomenological:** the world feels less alive. The cell is "just a cell" — not "the conversation, which is still working."
- **Classification:** **LOAD-BEARING** for the phenomenology the user described but **DECORATIVE** for the basic handoff functionality. The handoff works without it; the phenomenology doesn't.
- **Importantly:** removing dots from scope does NOT break the handoff. Handoff is complete-and-shippable without dots.

**Q6 — What's absent? (Negative space analysis)**

- **No backend / async / streaming infrastructure** in the prototype.
- **No "Dot" agent code** anywhere. There's no entity actually processing messages.
- **No message-sending UI** — chatVC's composer has no send button (verify: CVC:14, 70-84 — composer is just a UITextField, no button). User can type but cannot submit.
- **No optimistic UI update path** — when the user eventually CAN send a message, there's no mechanism to instantly add a "user said X, waiting for response" bubble.
- **No "Dot is typing" intermediate state vocabulary** — currently no distinction between "Dot is thinking" vs. "Dot is streaming response chunks."
- **Implication:** the dots indicator presupposes an entire feature-track (send → backend → streaming → completion) that doesn't exist yet. Adding dots WITHOUT the underlying mechanism would mean simulating activity (e.g., demo: every 30s a random cell pulses for 5s, then settles). **This is theater-without-substance.**

### §22.2 — HOT branches identified

| Branch | Heat | What's at stake |
|---|---|---|
| B22.A — **State location** (Store mutation vs separate Tracker vs per-cell transient) | HOT | Store invariant integrity; parallel source of truth concerns; identity-persistence of activity state |
| B22.B — **Animation mechanism** (master CADisplayLink vs UIKit timer vs CABasicAnimation) | WARM | Substrate consistency; coordination with other animators |
| B22.C — **Pre-feature implementation** (simulate dots for demo vs wait for real backend) | HOT | Theater-vs-substance; whether dots are wired NOW or DEFERRED |
| B22.D — **Visibility scope** (cell-rest only vs cell-rest + chat-state) | WARM | Where the dots render in chatContent (if at all) |

### §22.3 — Trace of HOT branch B22.A (state location)

**Sub-node:** Where does `isActive: Bool` per conversation live?

This is the critical decision because it shapes everything downstream (mutation API, observation, cell update mechanism, retention across pool LRU, etc.).

**A-1: Open up `ConversationStore` to mutation.**
- Add: `func setActive(_ id: UUID, active: Bool)` and `func isActive(_ id: UUID) -> Bool`.
- Backing storage: `private var activeIDs: Set<UUID> = []` (mutable).
- Observation: leverage `@Observable` — when the set changes, observers update.
- **Q1 (Rests on):** the `@Observable` framework, which is iOS 17+ macro-based observation.
- **Q2 (Why):** centralizes state; single source of truth.
- **Q3 (Assumes):** observers register correctly; observation triggers re-render of dependent views.
- **Q4 (If changed — keep store immutable):** dots state must live elsewhere.
- **Q5 (If removed):** dots state has no home; activity tracking impossible.
- **Q6 (Absent):** no current consumers of `@Observable` on this class; first use.

**A-2: Separate `ConversationActivityTracker` actor / singleton.**
- New file: `Conversation/Data/ConversationActivityTracker.swift`.
- `@MainActor @Observable final class ConversationActivityTracker`.
- API: `func setActive(_ id: UUID, _ active: Bool)`, `func isActive(_ id: UUID) -> Bool`.
- Owned by V2RootViewController alongside the store.
- ConversationStore remains immutable.
- **Q4 (If changed — fold into Store):** see A-1.
- **Q5 (If removed):** dots state has no home.
- **Q6 (Absent):** parallel source of truth; risk of getting out of sync with Store (e.g., when conversation is deleted, Tracker entry orphaned).

**A-3: Per-cell transient state.**
- `CellView` gains `var isActive: Bool` property.
- V2RootViewController calls `cell.isActive = true` directly when activity starts.
- No store-level state.
- **Q4 (If changed — to A-1 or A-2):** centralization improves persistence but adds infra.
- **Q5 (If removed):** dots fail to persist when cell is pool-evicted (LRU cycle).
- **Q6 (Absent):** identity-keyed persistence requires state in the conversation, not the view.

**Comparison:**

| Dimension | A-1 (Store) | A-2 (Tracker) | A-3 (Per-cell) |
|---|---|---|---|
| Store invariant disruption | YES (Store becomes mutable) | No | No |
| Parallel source-of-truth | No | Yes | No (no shared truth) |
| Identity-persistence (LRU survival) | Yes (Store survives) | Yes (Tracker survives) | NO (evicted with cell) |
| Code complexity | Medium (mutation + observation) | Medium (new type + sync) | Low (direct property) |
| Phenomenological purity | High (state IS the conversation's) | Medium (state TIED to conversation by ID) | Low (state in view; identity broken) |
| Future-proofing for real backend | High | High | Low |

**Resolution of B22.A (default for DEFERRED scope):** if implemented, choose A-2 (Tracker). Rationale:
- Avoids Store mutation (preserves existing invariant).
- Identity-persistent across pool LRU.
- Phenomenologically substrate-consistent (state is per-UUID, ties to conversation identity).
- Lower-risk than A-1 (doesn't open up Store invariants that other code depends on).

If implemented, the Tracker would be:

```swift
@MainActor
@Observable
final class ConversationActivityTracker {
    private var activeIDs: Set<UUID> = []
    func setActive(_ id: UUID, _ active: Bool) {
        if active { activeIDs.insert(id) } else { activeIDs.remove(id) }
    }
    func isActive(_ id: UUID) -> Bool { activeIDs.contains(id) }
}
```

### §22.4 — Trace of HOT branch B22.C (pre-feature implementation)

**Sub-node:** Should we wire dots NOW (with simulated activity) or wait for the real backend?

**C-1: Wire dots now with simulated activity.**
- Build the full view + state plumbing.
- Activity is toggled via a debug menu / random demo timer.
- Pro: phenomenology element delivered; substrate-aware design.
- Con: theater — the dots are demonstrating activity that isn't real. May atrophy when real backend lands and behaves differently.

**C-2: Defer dots until real backend exists.**
- Mark as future work.
- Document the design (this checklist already does in §22) for re-engagement when backend lands.
- Pro: avoid premature engineering; let real-backend constraints shape the design.
- Con: phenomenology incomplete in V1.

**C-3: Hybrid — wire view only, no state.**
- Add the `DotsLoadingIndicator` view to CellView with `alpha = 0` always.
- Future work: hook up the state binding.
- Pro: scaffolds for later; small now.
- Con: dead code; visible only if developer manually flips alpha.

**Resolution of B22.C (default): C-2 (Defer entirely).** Rationale:
- The handoff approach is the load-bearing structural work. Dots are decorative on top.
- Building dots without the backend is theater. The backend will land eventually; dots design should be informed by what the backend actually emits (status streams, partial completion, error states, etc.).
- The phenomenology described by the user shows dots in a video reference — but the prototype is not at the stage where real activity exists.
- This decision is REVERSIBLE: when backend lands, re-open §22, follow the design, implement A-2 + view + binding.

### §22.5 — Concrete tasks IF dots are later in scope (preserved for future re-engagement)

(These tasks are NOT in the current implementation phases. They're scoped here so future engineers re-engaging §22 have a head-start.)

**If/when scope is re-opened:**

- [ ] Create `Conversation/Data/ConversationActivityTracker.swift` (sketch in §22.3 above)
- [ ] Pass tracker reference to TimelineCanvas's data source / cell configuration path
- [ ] Create `Conversation/Timeline/DotsLoadingIndicator.swift` — UIView subclass with 3 dots; subscribes to AnimationController via `AnimatorProviding` for substrate-consistent looping animation
- [ ] Add `dotsIndicator: DotsLoadingIndicator?` property to `CellView` (lazy-created when first activated)
- [ ] Add `setActive(_:)` method to `CellView` that toggles dots visibility
- [ ] Wire observation: V2RootVC observes `ConversationActivityTracker`; on changes, finds the relevant cell in `canvas.instantiatedCells` and calls `cell.setActive(...)`
- [ ] Position constraints: dots near top-right or near date label (final position is a design decision)
- [ ] Alpha curve: dots visible at cell-rest (when isActive=true); fade/persist behavior at chat-state TBD
- [ ] Animation mechanism: master CADisplayLink-driven loop (NOT a `Timer`)
- [ ] Pool round-trip behavior: dots view persists with cell; activity state survives via Tracker (UUID-keyed)

### §22.6 — Risk acceptance for deferring P2

**Risk:** The handoff ships without the loading-dots phenomenological element. The user's described reverse-direction will visually lack the bottom-cell dots indicator.

**Acceptance:** The handoff's load-bearing achievement (reverse direction works; substrate participation) is independent of dots. The phenomenology is *partially* delivered; the dots are an enhancement, not a foundation.

**Reversal path:** §22 is preserved as a complete design doc. When backend lands or design intent shifts, re-engage §22, follow the implementation tasks in §22.5.

---

## §23 — Element P3: Distance-based fading via m34 (full root-cause-trace)

**Default disposition: UPGRADE-PATH SCOPED.** The current §6.2 alpha-curve achieves the perceptual outcome; this section traces the substrate-pure Z-translation alternative and documents the upgrade as a planned follow-on.

**Root node under trace:** "Replace (or augment) §6.2's `chatContentContainer.alpha = smoothstep(0.30, 0.50, progress)` with a Z-translation curve on `chatContent.layer.transform` that engages the existing m34 perspective primitive, producing the distance-fading visual as a substrate-true CONSEQUENCE rather than an explicit alpha curve."

### §23.1 — Six-question trace of the root node

**Q1 — What does this rest on? (Structural dependencies)**

- **The m34 = -1/1000 perspective on canvas.layer.sublayerTransform** (TC:174-176). This is the substrate's perspective primitive. It's set ONCE at canvas init. It applies to ALL descendants of canvas.layer.
- **chatContent's position in the sublayer tree:** `canvas.layer → contentHost.layer → cell.layer → chatContentContainer.layer`. Multiple levels deep. The m34 propagates through `sublayerTransform`. As long as no intermediate layer breaks the sublayerTransform chain, m34 reaches chatContent.
- **Core Animation's perspective math:** `apparent_x = x / (1 + z·(-m34))`. With m34 = -1/1000: `apparent_x = x / (1 + z/1000)`. For z > 0: apparent smaller (recedes). For z < 0: apparent larger (advances).
- **A Z-translation primitive on chatContent.layer.transform.** Direct write: `chatContentContainer.layer.transform = CATransform3DMakeTranslation(0, 0, z)`. Or sub-keypath write via KVC.
- **A curve mapping progress to Z.** Decision: linear, smoothstep, or piecewise. And what's the maximum Z?
- **A residual alpha fade** for the deep cell-rest end (z translation alone doesn't bring alpha to 0).
- **The phenomenology's "distance-of-illegibility" interpretation:** at some Z distance, text becomes too small to read, and we read this as "fading-into-illegibility."

**Q2 — Why does this exist? (Causal/historical origin)**

- **Substrate-purity:** the substrate has m34 perspective set. Using it for the distance-fade is the substrate-true mechanism. Not using it is "the substrate is available, we don't engage it."
- **The pinch-commit forward path uses Z-translation** via MorphChoreographer's `unifiedArcZMagnitude = 700` (TC:1392 + MorphChoreographer:73-80). The substrate KNOWS about Z-driven foreshortening. Reverse should engage the same primitive.
- **The user's phenomenology framing:** "consistent with perspective-foreshortening (m34 = -1/1000): distant things become atmospheric, not just small. The fade is the camera reaching its distance-of-illegibility for the chat text."
- **Substrate-vs-propagation framework (per `project_substrate_propagation_pinned`):** the substrate is decided; propagations (surface decisions) must extend the substrate's commitment. Using m34 propagates; alpha-only is substrate-neutral at best.

**Q3 — What assumptions does this encode? (Epistemological substrate)**

- **m34 reaches chatContent.layer.** Verified above: yes, via sublayer chain.
- **Core Animation's interpolation handles Z-translation cleanly.** Core Animation transforms compose multiplicatively. The chain `canvas.layer.sublayerTransform` × `contentHost.layer.transform` × `cell.layer.transform` × `chatContent.layer.transform` all multiply. As long as no intermediate has incompatible state, math is composable.
- **The visual outcome of Z = +N is "appears smaller and farther"** rather than "appears clipped" or "shifted in 3D space awkwardly." This depends on m34 magnitude and the visible bounds. With m34=-1/1000 and bounds.height ~ 844, Z at ~700 produces apparent shrink to ~59% — likely visible but readable as "smaller, recessed."
- **Z-translation does NOT add a tilt or perspective skew.** Z-only translation preserves the X/Y plane orientation. Foreshortening via m34 is purely scale-based at each point.
- **chatContent's interior layout is invariant under Z-translation.** A Z-translation on the container does NOT change its children's relative positions — only their projected screen position via m34.

**Q4 — What would happen if this changed? (Forward propagation)**

(a) **Replace alpha curve with Z-only translation:**

- Curve: `progress=1 → z=0`, `progress=0 → z=Z_MAX` where Z_MAX is calibrated for the desired "recede" feel.
- For Z_MAX = 700 (matching MorphChoreographer's arc magnitude): apparent scale at progress=0 = 1000/1700 ≈ 0.588. chatContent appears 59% size at cell-rest moment, but alpha still =1 — so it's visible-but-shrunk.
- For Z_MAX = 900: apparent scale 1000/1900 ≈ 0.526.
- For Z_MAX = 2000: apparent scale 1000/3000 ≈ 0.333. Smaller but still visible.
- **Z-only never makes chatContent invisible.** It just makes it small. To match the current §6.2 behavior (chatContent fully invisible at progress=0), we need residual alpha too.

(b) **Hybrid: Z-translation + residual alpha curve:**

- Z curve: `progress=1 → z=0`, `progress=0 → z=Z_MAX`.
- Alpha curve: stays at 1 above progress=0.5, fades 0→1 between progress=0 and progress=0.5 (steeper drop near the end).
- Result: as cell shrinks, chatContent recedes via Z (foreshortening) AND fades via alpha near the end. Composite distance-effect.

(c) **Z arc (sin-bell) instead of monotonic curve:**

- Mirrors MorphChoreographer's pinch-commit forward arc: Z peaks during transition, returns to 0 at endpoint.
- For REVERSE: Z=0 at progress=1, peaks at some intermediate (e.g., progress=0.5), Z=Z_FINAL at progress=0.
- This is more dramatic — chatContent "lifts away" then "settles smaller."
- Aesthetically richer but harder to spec; defer.

**Q5 — What would happen if this were removed? (Load-bearing analysis)**

- If we ship with §6.2 alpha-only (no Z): the visual achieves the "chat content fades as cell shrinks" outcome. The PERCEPTUAL goal is met.
- The SUBSTRATE goal (engage m34, propagate the perspective commitment) is NOT met. m34 remains set-once-never-used for the chat content layer.
- The user's phenomenology test ("substrate represents fading-into-illegibility") could be read as: alpha-curve IS the substrate's representation. OR: m34 IS the substrate's representation. Both are defensible.
- **Classification:** the alpha-only mechanism is DECORATIVE in the substrate sense (achieves visual outcome via non-substrate primitive). The hybrid (alpha + Z) is LOAD-BEARING for substrate-consistency.

**Q6 — What's absent? (Negative space analysis)**

- **No existing helper for Z-translation on a layer.** Would need: `chatContent.layer.transform = CATransform3DMakeTranslation(0, 0, z)` or sub-keypath via KVC.
- **No CADisplayLink-driven Z animator.** The Z curve fires per gesture event (setCamera tick) — instant write. No interpolation animator. Acceptable: the Z write happens at the same cadence as the alpha write (per gesture tick).
- **No Z-aware setCamera signature.** Current CV:253 `setCamera(_ camera: Camera, viewport: CGRect)` only carries camera + viewport. Z derivation happens inside setCamera from progress.
- **No interaction tested between Z-translation and chatContent's existing horizontal-inset transition.** CV:272-276 adjusts `leadingC.constant` and `widthC.constant` based on progress. Setting Z on the layer transform doesn't conflict with constraint-driven layout. ✓
- **No interaction tested between Z-translation and the active cell's `bringSubviewToFront`.** Z-order in UIKit's compositing is via the subview array order. Z-translation in 3D space is via m34 perspective. They are INDEPENDENT. Setting Z=700 doesn't change the cell's z-order; it changes its rendered position in 3D space. ✓ No conflict.
- **No fallback for devices that don't support 3D transforms.** All iOS devices since iOS 4 support 3D transforms via CATransform3D. ✓ Not an issue.

### §23.2 — HOT branches identified

| Branch | Heat | What's at stake |
|---|---|---|
| B23.A — **Mechanism choice** (alpha-only vs Z-only vs hybrid) | HOT | Substrate purity vs visual completeness |
| B23.B — **Curve shape** (linear vs smoothstep vs sin-bell arc) | WARM | Aesthetic feel; symmetry with forward paths |
| B23.C — **Z magnitude** (Z_MAX = 700, 900, 1500, 2000) | WARM | Visual intensity of recession |
| B23.D — **Layer to translate** (chatContent.layer vs each subview vs cell.layer) | WARM | Composition with other transforms |

### §23.3 — Trace of HOT branch B23.A (mechanism choice)

**Sub-node:** Should the distance-fade use alpha-only, Z-only, or hybrid?

**A-1: Alpha-only (current §6.2)**
- Implementation: `chatContent.alpha = smoothstep(0.30, 0.50, progress)`.
- m34 unused.
- Visual: chatContent fades visibly as cell shrinks. Clean alpha gradient.
- Substrate: alpha is a fundamental UIKit primitive but does not engage the perspective. The substrate's m34 commitment is irrelevant to this particular fade.

**A-2: Z-only**
- Implementation: `chatContent.layer.transform = CATransform3DMakeTranslation(0, 0, zForProgress(progress))`.
- m34 engaged.
- Visual: chatContent foreshortens (apparent scale shrinks via perspective) as cell shrinks. NEVER fully invisible — at progress=0 still at apparent scale ~0.5-0.6.
- Substrate: full propagation.

**A-3: Hybrid**
- Implementation: BOTH Z-translation (for foreshortening) AND alpha-curve (for full invisibility at cell-rest end).
- m34 engaged.
- Visual: chatContent foreshortens AND fades. Composite effect.
- Substrate: m34 propagation + alpha for clean invisibility threshold.

**Resolution of B23.A (default): A-3 (Hybrid).** Rationale:
- Engages m34 (substrate-pure) AND achieves complete invisibility (visual-clean).
- Curve composition: Z-translation does the "recedes-into-distance" perceptual work; alpha-curve completes the hide near progress=0.
- Curves:
  - `z = lerp(0, Z_MAX, 1 - progress)` (monotonic; at progress=1 z=0, at progress=0 z=Z_MAX)
  - `chatContent.alpha = smoothstep(0.05, 0.35, progress)` (only fades steeply near cell-rest)
- This way: most of the morph shows chatContent receding via m34; only the last 30% drops alpha for final cleanup.
- Reverses the §6.2 default which placed alpha fade at 0.30→0.50. The hybrid shifts alpha to "later in the morph" because Z handles the early-to-mid feel.

### §23.4 — Trace of HOT branch B23.C (Z magnitude)

**Sub-node:** What value should `Z_MAX` take?

Reference values in the codebase:
- `MorphTiming.unifiedArcZMagnitude = 700` (pinch-commit forward's sin-bell peak; chatContent recedes to 1000/1700 ≈ 59% apparent scale at peak)
- `MorphTiming.unifiedArcYMagnitude = 50` (Y arc; not directly relevant to scale)

Candidate Z_MAX values:
- **Z_MAX = 700** — matches forward pinch-commit's peak. Apparent scale at progress=0: 0.588. Visible-but-small.
- **Z_MAX = 900** — slightly deeper. Apparent scale: 0.526.
- **Z_MAX = 1500** — substantially deeper. Apparent scale: 0.400. More dramatic recession.
- **Z_MAX = 2000** — very deep. Apparent scale: 0.333. Cell-rest cells are nearly silhouette-size by perception.

**Phenomenological logic:** the user described chatContent "fading into illegibility." Body text at full width (~16pt rendered at ~360pt wide) becomes hard to read at apparent scale ~0.5 (≈8pt effective). At apparent scale 0.3 (≈5pt effective), text is illegible. Z_MAX should land at the illegibility threshold.

**Resolution of B23.C (default): Z_MAX = 700** for symmetry with forward (pinch-commit's peak magnitude). If empirical testing in Phase 0 finds the recession feels too subtle, escalate to 900 or 1500. Document choice in §14.

### §23.5 — Updated §6.2 setCamera extension (incorporating §23 retrofits)

**Replaces the §6.2 sketch** (which only added alpha). New version engages m34:

```swift
// CellView.setCamera (updated per §23):

func setCamera(_ camera: Camera, viewport: CGRect) {
    guard bounds.height > 0 else { return }
    if morphInProgress { return }

    let naturalH = naturalHeight > 0 ? naturalHeight : bounds.height
    let chatRestFactor = viewport.height / naturalH
    let chatRestRange = chatRestFactor - 1.0
    let extensionFactor = bounds.height / naturalH
    let progress: CGFloat = chatRestRange > 1e-6
        ? min(1.0, max(0.0, (extensionFactor - 1.0) / chatRestRange))
        : 1.0

    let inverseFadeAlpha = 1 - smoothstep(0.05, 0.30, progress)
    labelStack.alpha = inverseFadeAlpha
    pinchGlyph.alpha = inverseFadeAlpha
    chatRestAffordance.alpha = smoothstep(0.05, 0.30, progress)  // per §21

    // NEW per §23 (replaces §6.2 alpha-only):
    if let chatContent = chatContentContainer {
        // Z-translation engages m34 = -1/1000 perspective foreshortening.
        // At progress=1 (chat-rest): Z=0, no foreshortening (chatContent at full size).
        // At progress=0 (cell-rest): Z=Z_MAX, chatContent appears at scale ~0.59 (foreshortened).
        let zMax: CGFloat = MorphTiming.unifiedArcZMagnitude  // = 700
        let z = (1 - progress) * zMax
        chatContent.layer.transform = CATransform3DMakeTranslation(0, 0, z)

        // Alpha residual: fully visible above progress=0.35, fades steeply below.
        // Curve range chosen so Z-foreshortening dominates the perceptual fade in 0.35–1.0,
        // and alpha-cleanup handles the deep-cell-rest end.
        chatContent.alpha = smoothstep(0.05, 0.35, progress)
    }

    layer.sublayerTransform = CATransform3DIdentity

    // Existing horizontal-inset adjustment (CV:272-276) — unchanged:
    if pageWidth > 0, let leadingC = leadingConstraint, let widthC = widthConstraint {
        let currentInset = naturalHorizontalInset * (1 - progress)
        leadingC.constant = currentInset
        widthC.constant = pageWidth - 2 * currentInset
    }
}
```

**Substrate-attestation:** Z-translation propagates the m34 perspective commitment. The alpha residual is the substrate's primitive for visibility (alpha is universal in UIKit). Hybrid is substrate-consistent.

### §23.6 — Concrete tasks for P3

- [ ] **Update `CellView.setCamera`** with the new hybrid Z + alpha logic per §23.5
- [ ] **Verify perspective math empirically:** add temp log printing `chatContent.layer.transform`, take screenshot at progress=0.5; verify apparent scale ≈ 0.74 (= 1000 / (1000 + 350)). Tune Z_MAX if needed.
- [ ] **Audit interactions with active cell's `bringSubviewToFront`:** verify Z-translation does not affect z-order in compositing (per Q6 analysis). Add note to verification doc.
- [ ] **Audit interactions with `contentHost.layer.transform`** during gesture: confirm transform chain math holds. `chatContent.layer.transform` composes with `cell.layer.transform` (identity per CV:122) which composes with `contentHost.layer.transform` (identity post-normalize per §16.10) which composes with `canvas.layer.sublayerTransform` (camera + m34). No conflicts expected; verify in dev.
- [ ] **Test reverse direction visually:** record screen of pinch-back gesture; verify chatContent appears to recede (depth-wise) rather than merely fade. Compare side-by-side with §6.2 alpha-only.
- [ ] **Document decision in §14 D14:** "Use Hybrid Z + alpha for distance-fade. Z_MAX = 700 for forward-symmetry. Alpha steeper near progress=0 for final cleanup."

### §23.7 — Phase 0 empirical verifications for P3

- [ ] **Q10 — m34 propagation depth:** can a Z-translation on `chatContent.layer` (3 levels below canvas) actually engage the canvas's m34? Empirical: set `chatContent.layer.transform = CATransform3DMakeTranslation(0, 0, 700)` while chatContent.alpha=1 and bounds visible; visually confirm chatContent appears smaller via perspective.
- [ ] **Q11 — Z magnitude calibration:** at Z=700, does chatContent's recession feel right for the morph duration the gesture produces? Compare Z=700, 900, 1500 on a real device. Document chosen Z_MAX in §14.
- [ ] **Q12 — Interaction with horizontal-inset adjustment:** does the simultaneous constraint update (CV:272-276) interfere with the layer-transform write? Verify both apply cleanly per tick.

### §23.8 — Acceptance criteria for P3

- [ ] At progress=1 (chat-rest): `chatContent.layer.transform == CATransform3DIdentity`, alpha=1, visible at full scale
- [ ] At progress=0.5: chatContent visibly recedes in Z (apparent scale ≈ 0.74), alpha=1
- [ ] At progress=0.35: chatContent at apparent scale ≈ 0.69, alpha ≈ 0.5 (mid-fade)
- [ ] At progress=0: alpha=0, layer transform may still have Z=Z_MAX but invisible
- [ ] Visual feel matches the user's "distance-of-illegibility" framing (qualitative judgment)
- [ ] No conflicts with active cell z-order
- [ ] No constraint-warning crosstalk with horizontal-inset adjustment

---

## §24 — Element P4: Inverse-symmetry reverse cinematography (full root-cause-trace)

**Default disposition: DESIGN-ONLY SCOPED.** This section traces the design space; the implementation decision is gated on whether the user wants commit-driven cinematography on top of the gesture-driven shrink. Sketch first, decide second.

**Root node under trace:** "Add a `playPinchToCellsMorph(forCellAt:)` cinematography that runs after pinch-commit (at handlePinchEnded → .pinchToCells branch) to mirror the structural richness of `playTapToChatMorph`. Specifically, a multi-stage choreography with chrome staggering, Z arc, possibly blur curtain, leading into the spring-to-cell-rest settle."

### §24.1 — Six-question trace of the root node

**Q1 — What does this rest on? (Structural dependencies)**

- **`MorphChoreographer`** (Conversation/Timeline/MorphChoreographer.swift, 86 LOC). Already implements the forward pinch-commit cinematography. Per-tick driven by `CurveAnimator<CGFloat>` (master CADisplayLink). Could be reused for reverse with an inverted `MorphChoreography` value.
- **`MorphChoreography`** struct (Conversation/Timeline/MorphChoreography.swift). Captures `startCameraY, endCameraY, startHeight, endHeight, unifiedArcYMagnitude, unifiedArcZMagnitude, duration, chatRestFactor`. The struct is symmetric — forward goes start→end, reverse would go end→start. Could be reused.
- **The existing `handlePinchEnded` commit decision** (TC:1097-1164): when `commit = .pinchToCells`, currently calls `springToCellRest` (TC:1158-1163). The hook point for reverse cinematography is here.
- **Gesture velocity at pinch release.** Currently passed to `springToCellRest` as `extensionVel` (TC:1110). Reverse cinematography would consume this velocity at its START so motion feels continuous.
- **The cinematography's end-of-morph handoff to spring.** When cinematography completes, it must hand off cleanly to `springToCellRest` (or settle directly without spring if cinematography lands at exact naturalH).
- **Substrate (per CLAUDE.md 2.1):** master CADisplayLink only. No parallel timers. The MorphChoreographer already honors this.
- **Distance-fading (per §23):** if §23's hybrid Z+alpha lands, cinematography's Z curve must compose with §23's Z. Or §23's Z curve IS the cinematography's Z curve — depending on whether the cinematography supersedes setCamera-driven curves or composes with them.

**Q2 — Why does this exist? (Causal/historical origin)**

- **Forward has cinematography; reverse doesn't.** Forward-via-tap is 2.7s of choreographed motion. Forward-via-pinch-commit is 2.4s. Reverse is gesture-time + 1.1s spring. **Asymmetric in user-visible richness.**
- **The user's reference video** (frames 040-150) shows a multi-stage reverse: chat content fading 040-075, cells materializing 090-110, settled by 150. The framing suggests not just a spring-back but a paced cinematography.
- **Phenomenological symmetry:** if forward is choreographed, reverse should be choreographed (or at least visually rich, even if gesture-driven).
- **However:** the user's gesture IS the cinematographer in the gesture-driven mode. Velocity, timing, even pauses are user-controlled. Adding commit-driven cinematography REPLACES the user's gesture frame-by-frame control with an automated choreography after release.

**Q3 — What assumptions does this encode? (Epistemological substrate)**

- **The user wants commit-driven cinematography over gesture-driven continuous control.** This is a phenomenological judgment about which model is "correct." Both are defensible.
- **The cinematography's duration is reasonable.** If too long, the user feels disconnected from the gesture. If too short, the cinematography is undetectable.
- **The cinematography composes cleanly with the existing spring.** Either: cinematography lands at exact naturalH and skips spring, OR cinematography lands at intermediate height and spring takes over from there.
- **Gesture velocity transfers naturally into cinematography.** A fast pinch should produce faster cinematography (or skip cinematography and go directly to a fast spring). A slow pinch produces slower cinematography.

**Q4 — What would happen if this changed? (Forward propagation)**

(a) **Add a commit-driven `playPinchToCellsMorph`:**

- New method on TimelineCanvas, ~50-100 LOC.
- Mirror `playTapToChatMorph` structurally:
  ```swift
  fileprivate func playPinchToCellsMorph(forCellAt k: Int, carriedExtensionVelocity v: CGFloat) {
      // setActiveCellIndex(k) // already set
      guard let cell = instantiatedCells[k], let heightC = cell.heightConstraint else { return }
      let naturalH = cell.naturalHeight
      let chatRestFactor = bounds.height / naturalH

      let choreo = MorphChoreography(
          activeCellIndex: k,
          startCameraY: camera.translation,
          endCameraY: lastCellRestScrollY + bounds.height / 2,
          startHeight: heightC.constant,
          endHeight: naturalH,
          unifiedArcYMagnitude: MorphTiming.unifiedArcYMagnitude,
          unifiedArcZMagnitude: MorphTiming.unifiedArcZMagnitude,
          duration: MorphTiming.masterTimerDuration,
          chatRestFactor: chatRestFactor
      )
      morphChoreographer.engage(choreo) { [weak self] in
          guard let self else { return }
          CATransaction.withSuppressedActions {
              self.contentHost.layer.transform = CATransform3DIdentity
          }
          self.updateNeighborTranslations()
          self.setActiveCellIndex(nil)
          self.restoreNaturalSiblingOrder()
      }
  }
  ```
- The `handlePinchEnded` `.pinchToCells` branch routes to this instead of `springToCellRest`.

(b) **Keep gesture-driven (current §6 design):**

- `handlePinchEnded` → `springToCellRest` (existing).
- No commit-driven cinematography.
- The gesture itself IS the cinematography frame-by-frame.
- Spring provides the settling motion after release.

(c) **Hybrid — Spring-with-cinematography-flavor:**

- Don't add a separate `playPinchToCellsMorph`. Instead, extend `springToCellRest` to ALSO drive contentHost.layer.transform with a small sin-bell arc during the spring (similar to MorphChoreographer's arc but tied to spring's value rather than CurveAnimator's t).
- Subtler than commit-driven; gesture-driven retains user control during the pinch.
- Adds the Z arc feel during the settle.

**Q5 — What would happen if this were removed? (Load-bearing analysis)**

- If we ship with current §6 design (gesture-driven shrink + spring): reverse direction works mechanically. The "missing cinematography" is felt only in comparison to forward.
- The handoff's load-bearing achievement is independent of cinematography. Cinematography is enrichment.
- **Classification:** DECORATIVE for handoff functionality. **Phenomenologically significant** for inverse-symmetry.

**Q6 — What's absent? (Negative space analysis)**

- **No reverse-direction blur curtain.** Forward has full blur fade-in / crossFade / blur fade-out for ~1.2s. Reverse has no blur. The user's described phenomenology does NOT show a blur curtain on reverse (the bottom cell's dots indicator is visible by frame 110, suggesting no blur). So this may be a deliberate asymmetry: forward has the blur (to hide the ChatVC instantiation handoff); reverse doesn't need it (the cell IS already the chat; no instantiation hidden).
- **No reverse-direction chrome staggers.** Forward via tap has UIView.animate'd date/topic/today/glyph fades. Reverse via gesture has setCamera-driven progress curves (CV:265-267). The user might prefer staggered timing (e.g., date fades in early, topic later, today last) — currently not specified.
- **No "windup" anticipation.** Forward via tap has a 0.78s `windupScale` animation. Reverse has no equivalent anticipation phase. If we add commit-driven cinematography, should it have a windup? (Backwards: a slight scale-up before the recede begins?) Phenomenologically: questionable. The user's gesture-release IS the "release" moment; an anticipation phase delays the response.
- **No "counter-scale" on emerging cell-rest chrome.** Forward applies `chatRestCenterLabel.transform = scale(counterScale)` so the day-marker appears at "true size" despite the cane curve's scale. Reverse would emerge labelStack chrome which is sized naturally already — no counter-scale needed.
- **No reverse direction's interaction with `pinchRecognizer`.** During cinematography (after release), the user can't re-pinch (gesture has ended). If we want re-engageable cinematography (user can re-grab mid-cinematography), the cinematography would need to be interruptible. Probably defer.

### §24.2 — HOT branches identified

| Branch | Heat | What's at stake |
|---|---|---|
| B24.A — **Cinematography vs spring-only** (commit-driven choreography vs gesture-driven + spring) | HOT | Phenomenological symmetry; user control vs auto-paced |
| B24.B — **Z arc shape** (sin-bell mirrors forward; monotonic; flat) | WARM | Aesthetic richness; depth feel |
| B24.C — **Duration** (1.2s symmetry with forward vs 0.7s tighter spring) | WARM | Snap feel; perceived responsiveness |
| B24.D — **Spring at end of cinematography vs cinematography lands at exact naturalH** | WARM | Settle precision |

### §24.3 — Trace of HOT branch B24.A (cinematography vs spring-only)

**Sub-node:** Should reverse-direction commit run a multi-stage choreography (like forward) or rely on the existing gesture-driven shrink + spring?

**The deep question:** in continuous-embodied phenomenology, who is the cinematographer of the reverse?

**Interpretation A: The user IS the cinematographer (gesture-driven).**
- User's pinch velocity determines the morph's pace.
- User can pause mid-pinch and the cell stays at the held heightConstraint.
- On release, a spring settles the remaining distance.
- The cell's motion is the user's motion. Maximum direct manipulation.

**Interpretation B: The world IS the cinematographer (commit-driven).**
- User initiates collapse via pinch; the world takes over after release.
- The cinematography mirrors forward's: a paced curve, possibly with Z arc.
- The cell's motion is the world's response. Less direct, more orchestrated.

**Both interpretations honor continuous-embodied phenomenology in different senses:**
- A: continuity-of-gesture (no automated cuts; the user's gesture is the substrate's input).
- B: continuity-of-world-behavior (the world has consistent cinematic vocabulary; forward and reverse use the same choreography type).

**The user's described video has visible cinematography (specific frames 040, 075, 090, 110, 125, 150), suggesting Interpretation B is the target.** BUT the frame numbers might just be representative of an average-gesture reverse; we don't know if the video is automated or user-played-back.

**Pragmatic recommendation:**
- Ship Interpretation A first (it's the current §6 design; lowest engineering scope).
- Document Interpretation B as design-only in §24 (this section).
- After user sees A live, decide if B is needed.

**Resolution of B24.A (default): KEEP A (gesture-driven + spring), DOCUMENT B in §24.4.** Reversible if A doesn't feel right.

### §24.4 — Sketch of Interpretation B (commit-driven cinematography), preserved for future re-engagement

**Method:** `TimelineCanvas.playPinchToCellsMorph(forCellAt:carriedExtensionVelocity:cameraTranslationVelocity:)`

**Trigger:** `handlePinchEnded` (TC:1097-1164) replaces the `.pinchToCells` case to call this new method instead of `springToCellRest`.

**Choreography parameters (mirror forward's):**

```swift
let choreo = MorphChoreography(
    activeCellIndex: k,
    startCameraY: camera.translation,
    endCameraY: lastCellRestScrollY + bounds.height / 2,   // INVERSE of forward
    startHeight: heightC.constant,                          // current extension
    endHeight: naturalH,                                    // collapse target
    unifiedArcYMagnitude: MorphTiming.unifiedArcYMagnitude, // 50, sin-bell Y
    unifiedArcZMagnitude: MorphTiming.unifiedArcZMagnitude, // 700, sin-bell Z (chatContent recedes peak then returns)
    duration: MorphTiming.masterTimerDuration,              // 1.2s
    chatRestFactor: chatRestFactor
)
```

**Behavior per tick (via existing MorphChoreographer.apply()):**
- Linear interpolation of `heightC.constant` from startHeight to endHeight (= naturalH)
- Linear interpolation of camera.translation from startCameraY to endCameraY
- Sin-bell Y/Z arc on contentHost.layer.transform: Y peaks negative at t=0.35 (within 0..0.7 phase), Z peaks positive at same. At t≥0.7, both 0.
- For reverse: Y arc would feel like "the cell lifts slightly as it shrinks." Z arc would feel like "chatContent recedes deeper then comes back" — composes with §23's distance-fade.

**Setcamera gating during cinematography:**
- `morphInProgress = true` while cinematography runs (because `morphChoreographer.isRunning == true`).
- cell.setCamera early-returns → chrome alphas FROZEN during cinematography (same as forward pinch-commit).
- **CONSEQUENCE:** chrome alphas don't fade IN during the cinematography. At the end of cinematography (when MorphChoreographer completes), morphInProgress=false. setCamera fires (or needs to be triggered) to refresh alphas to cell-rest values.
- **Mitigation:** the cinematography's completion handler must call `cell.setCamera(camera, viewport: bounds)` to refresh alphas. Mirrors §16.10's normalize approach.

**Completion handler:**

```swift
morphChoreographer.engage(choreo) { [weak self] in
    guard let self else { return }
    CATransaction.withSuppressedActions {
        self.contentHost.layer.transform = CATransform3DIdentity
    }
    // Refresh alphas at progress=0 (cell-rest), via cell.setCamera being called.
    self.updateNeighborTranslations()
    self.updateEdgeMaskAlphas()
    // Trigger setCamera write to refresh per-cell chrome alphas now that morphInProgress=false
    self.setCamera(self.camera)
    // Clear active cell + restore z-order
    self.setActiveCellIndex(nil)
    self.restoreNaturalSiblingOrder()
}
```

**Interplay with §23 Z+alpha distance-fade:**
- During cinematography, morphInProgress=true → setCamera early-returns → §23's `chatContent.layer.transform` write is SUPPRESSED.
- BUT the cinematography is writing `contentHost.layer.transform` with sin-bell Y/Z arc. The Z component of THAT transform affects chatContent's apparent scale via m34 (because chatContent.layer is inside contentHost.layer; chain composes).
- So during cinematography, distance-fade IS happening — via contentHost.transform.translation.z, not chatContent.transform.translation.z.
- **At cinematography end:** contentHost.transform = identity. chatContent.layer.transform = ??? (last set by §23's setCamera before pinch began, would be CATransform3DMakeTranslation(0, 0, 0) at progress=1 entering pinch).
- After cinematography, setCamera fires; at progress=0 (cell-rest), §23's code writes `chatContent.layer.transform = CATransform3DMakeTranslation(0, 0, Z_MAX)` (Z=Z_MAX for cell-rest). chatContent appears at apparent scale ~0.59.
- BUT chatContent.alpha = 0 (per §23's alpha curve at progress=0). So foreshortening is invisible due to alpha.

**This works, but it's complex.** The cinematography handles the Y/Z arc on contentHost; §23 handles the residual chatContent.transform after cinematography. Composition is principled but requires careful invariant management.

**Phase planning for Interpretation B (IF in scope):**

- Phase 9a: implement `playPinchToCellsMorph` per the sketch
- Phase 9b: integrate with `handlePinchEnded` routing
- Phase 9c: verify chrome refresh at completion
- Phase 9d: verify composition with §23 Z+alpha
- Phase 9e: empirical test the gesture-velocity → cinematography handoff (does it feel continuous?)

### §24.5 — Decision: Default A, design B preserved

**Current implementation scope:** Interpretation A. Gesture-driven shrink + spring (current §6 design). Reverse direction works without additional cinematography.

**Reverse cinematography (Interpretation B):** sketched above, preserved as §24.4. Implementation gate: user decision after seeing A live.

If user later requests B:
- Add Phase 9a-9e per §24.4
- Update §6 to route .pinchToCells to playPinchToCellsMorph (replaces springToCellRest in the commit branch)
- Update §16 with new finding about Z composition with §23

### §24.6 — Risk acceptance for deferring P4 (cinematography)

**Risk:** The reverse direction's user-visible cinematography is structurally minimal compared to forward. The user's described frames 040-150 may not be reproducible with gesture-driven control alone.

**Acceptance:** The handoff's load-bearing achievement is independent of cinematography. The gesture-driven shrink + setCamera + §23 distance-fade + §21 affordance + spring-to-cell-rest is sufficient for mechanical correctness AND substantial phenomenological matching.

**Reversal path:** §24.4 preserves the full design for `playPinchToCellsMorph`. Enabling it is ~50-100 LOC + integration testing.

---

## §25 — Phenomenological-polish implementation phases (extending §12)

These phases extend §12's 8 implementation phases. Phases 9-12 deliver the phenomenological-polish elements. Phase boundaries respect the defaults set in §20:

### Phase 9 — Inward-arrows affordance (P1, in-scope-now)

**Wave Topology DAG (Phase 9):**

```
PHASE 9
│
├─→ Wave 9.1 (SymbolName + Theme.Symbol exposure)                  ─╮
├─→ Wave 9.2 (CellView.chatRestAffordance property closure-init)   ─┤
├─→ Wave 9.3 (constraints in activateConstraints)                  ─┼─→ [WC Merge Gate 9]
└─→ Wave 9.4 (setCamera curve add — single line)                   ─╯
```

Four small parallel waves; merge gate verifies affordance at chat-rest + invisible at cell-rest.

**Wave assignments:**
- **Wave 9.1** — `[TS]` SymbolName.pinchCollapseAffordance constant
- **Wave 9.2** — `[CA]` chatRestAffordance UIImageView property via closure-init (P1.2) per §21.6
- **Wave 9.3** — `[LE]` top-anchor + leading-anchor constraints
- **Wave 9.4** — `[CA]` `chatRestAffordance.alpha = smoothstep(...)` line in setCamera per §39.2.1
- Retro `[CQR, RCT, SA, DCH, IV, BV, VR]`

Estimated duration: **1-2 days.** Independent of other phenomenology phases.

- [ ] **P9.1** Choose final SF Symbol identifier (Q7 from §17 / §21.7). Default candidate: `"arrow.down.right.and.arrow.up.left"`. If unavailable in iOS 18 SF Symbols, fall back per §21.7.
- [ ] **P9.2** Add `SymbolName.pinchCollapseAffordance` constant in `DesignSystem/SymbolName.swift`
- [ ] **P9.3** Verify `Theme.Symbol.pinchAffordancePointSize` and `Theme.Symbol.pinchAffordanceWeight` are accessible; expose if not
- [ ] **P9.4** Add `chatRestAffordance: UIImageView` property to `CellView` (mirrors `pinchGlyph` init pattern at CV:78-89)
- [ ] **P9.5** Register in `installSubviews` (after `pinchGlyph` so z-order stacks under chatContent which is installed later)
- [ ] **P9.6** Add constraints to `activateConstraints`: top-anchor to safeArea.top + 16, leading-anchor to leading + 20
- [ ] **P9.7** Extend `setCamera` with `chatRestAffordance.alpha = smoothstep(0.05, 0.30, progress)`
- [ ] **P9.8** Add `accessibilityIdentifier = AccessibilityID.chatRestAffordance` (define ID in `AccessibilityID.swift`)
- [ ] **P9.9** Visual verification: side-by-side screenshot of chat-rest (alpha=1) and cell-rest (alpha=0). Verify position is top-left.
- [ ] **P9.10** Pool round-trip test: tap A → pinch back → tap A again. Affordance correct in both states.

**Phase 9 exit gate:** affordance visible at chat-rest; invisible at cell-rest; smooth fade through morph; persists across pool round-trips; no constraint warnings.

**Phase 9 Pillar review sub-gate:**
- [ ] **P1.2** chatRestAffordance property is closure-init at CellView class top (mirrors pinchGlyph pattern at CV:78-89)
- [ ] **P2.11** SF Symbol name extracted to `SymbolName.pinchCollapseAffordance` token
- [ ] **P2.11** affordance alpha curve thresholds via `AlphaCurve` enum (per §39.2.1)
- [ ] **P5.1** chatRestAffordance is `private(set)` (read by setCamera; write only via setCamera)
- [ ] **P10.2** position mirrors labelStack (leading-aligned, top-anchored) for visual rhyme
- [ ] **P11.1** alpha curve added as a single line in setCamera; no separate setup helper
- [ ] **P3.5** affordance's purpose readable from property name + symbol name alone

### Phase 10 — Distance-based fading via m34 (P3, upgrade-path-scoped)

**Wave Topology DAG (Phase 10):**

```
PHASE 10
│
├─→ Wave 10.1 (Z calibration empirical: Q10 + Q11)                  ──╮
└─→ Wave 10.2 (AlphaCurve.chatContentZMax token finalization)        ─╯
                                                                       ├─→ [WC Merge Gate 10.A]
                                                                                │
                                                                                ↓
                                              Wave 10.3 (setCamera: replace P7's chatContent.alpha line with §39.2.1 hybrid Z+alpha)
                                                                                │
                                                                                ↓
                                              Wave 10.4 (visual regression: distance feel)
                                                                                │
                                                                                ↓
                                                                  [WC Merge Gate 10.B] ─→ Phase 10 complete
```

Calibration must complete first; supersession then replaces P7's curve.

**Wave assignments:**
- **Wave 10.1** — `[SE, ER]` Q10 m34 propagation depth + Q11 Z_MAX iterative calibration on real device
- **Wave 10.2** — `[TS, SE]` finalize AlphaCurve.chatContentZMax in DesignSystem/AlphaCurve.swift
- **Wave 10.3** — `[SE, CA, CO]` SUPERSESSION (per §39.3): replace P7's alpha-only line with §39.2.1 hybrid Z + alpha block
- **Wave 10.4** — `[VR, ER]` distance-fade visual check (chatContent recedes, doesn't just fade flat)
- Retro `[CQR, RCT (substrate-purity audit), SA, DCH, IV, BV, VR, PP]`

Estimated duration: **2-3 days.** Depends on Phase 7 (Reverse direction wiring) — needs setCamera-driven curves baseline.

- [ ] **P10.1** Empirical verification of m34 propagation depth (§17 Q10): write a temp Z-translation on `chatContent.layer`, visually confirm foreshortening occurs
- [ ] **P10.2** Calibrate Z_MAX (§17 Q11): test Z=700, 900, 1500 on a real device. Pick magnitude that feels right for the recession.
- [ ] **P10.3** Update `CellView.setCamera` to use hybrid Z + alpha per §23.5:
  - Z curve: `z = (1 - progress) * Z_MAX`
  - Alpha curve: `chatContent.alpha = smoothstep(0.05, 0.35, progress)` (replaces the §6.2 `smoothstep(0.30, 0.50, progress)`)
  - Layer transform write: `chatContent.layer.transform = CATransform3DMakeTranslation(0, 0, z)`
- [ ] **P10.4** Verify composition with cell-internal layer transforms (especially horizontal-inset adjustment in CV:272-276)
- [ ] **P10.5** Verify composition with contentHost.layer.transform (especially during the canvas.alpha=0 window post-cane-curve; transform is held until normalize sets it to identity)
- [ ] **P10.6** Visual verification: reverse direction screen recording. chatContent should appear to "recede in depth" (not just fade flat).
- [ ] **P10.7** Compare with §6.2 alpha-only baseline. Note differences in §14 decision log.
- [ ] **P10.8** Update §6.2 in the checklist to point to §23.5 as the authoritative setCamera extension.

**Phase 10 exit gate:** Z-translation visibly engages m34 perspective; chatContent recedes during reverse; alpha residual completes invisibility at progress=0; substrate-pure mechanism confirmed.

**Phase 10 Pillar review sub-gate:**
- [ ] **P39.2.1 (the canonical setCamera form) supersedes earlier sketches** — verify §6.2 alpha-only line is REPLACED, not augmented
- [ ] **P2.11** Z_MAX token via AlphaCurve.chatContentZMax (not literal 700 inline)
- [ ] **P10.2** Z curve symmetric with forward pinch-commit's unifiedArcZMagnitude — engineer cross-references both at code-review time
- [ ] **P19.3** applyChatContentDistanceFade is idempotent
- [ ] **P6.7** silence on chatContent==nil case has WHY comment ("pre-install window")
- [ ] **P11.1** distance-fade is its own applier method, not folded into setCamera body
- [ ] **P3.5** code documents the substrate-purity rationale inline (m34 engagement)

### Phase 11 — Reverse cinematography (P4, design-only-scoped — gate)

**Wave Topology DAG (Phase 11, only if executed):**

```
PHASE 11 (GATED)
│
├─→ Wave 11.1 (playPinchToCellsMorph implementation)               ─╮
├─→ Wave 11.2 (handlePinchEnded .pinchToCells routing redirect)    ─┤
└─→ Wave 11.3 (completion handler: alpha refresh + cleanup)        ─╯
                                                                    ├─→ [WC Merge Gate 11.A]
                                                                            │
                                                                            ↓
                                              Wave 11.4 (composition verify with §23 Z + §21 affordance)
                                                                            │
                                                                            ↓
                                                                  [WC Merge Gate 11.B] ─→ Phase 11 complete
```

**Wave assignments:**
- **Wave 11.1** — `[CC, RO]` playPinchToCellsMorph per §24.4
- **Wave 11.2** — `[GM, CC]` handlePinchEnded .pinchToCells branch routes to playPinchToCellsMorph
- **Wave 11.3** — `[CC, CA]` completion handler refreshes alphas + cleans state
- **Wave 11.4** — `[VR, ER]` composition check (Z curves from §23 + cinematography compose without snap)
- Retro `[CQR, RCT, SA, DCH, IV, BV, VR, PP]`

Estimated duration: **0 days if deferred / 3-5 days if user enables.**

**Gate question:** after Phases 7-10 ship, user reviews reverse direction live. Decision tree:

- (a) User accepts gesture-driven reverse as-is → **SKIP Phase 11.** §24.4 preserved as future design.
- (b) User requests commit-driven cinematography → **EXECUTE Phase 11** per §24.4 sketch.

If (b):

- [ ] **P11.1** Implement `playPinchToCellsMorph(forCellAt:carriedExtensionVelocity:cameraTranslationVelocity:)` per §24.4
- [ ] **P11.2** Modify `handlePinchEnded` `.pinchToCells` branch (TC:1158) to route to `playPinchToCellsMorph` instead of `springToCellRest`
- [ ] **P11.3** Add completion handler that:
  - Writes `contentHost.layer.transform = CATransform3DIdentity`
  - Calls `setCamera(camera)` to refresh chrome alphas
  - Calls `setActiveCellIndex(nil)`
  - Calls `restoreNaturalSiblingOrder()`
- [ ] **P11.4** Verify gesture velocity transfers continuously into cinematography (no perceived stutter at the release moment)
- [ ] **P11.5** Verify cinematography landing at exact naturalH (no spring residual)
- [ ] **P11.6** Composition verification with §23's chatContent.layer.transform (do both Z curves compose, or does cinematography supersede?)
- [ ] **P11.7** Visual verification against the user's described frames 040-150

**Phase 11 exit gate (if executed):** reverse cinematography mirrors forward's structural richness; gesture velocity continuous into cinematography; lands at exact cell-rest; composes correctly with §21 affordance and §23 distance-fade.

**Phase 11 Pillar review sub-gate (if executed):**
- [ ] **P10.2** playPinchToCellsMorph mirrors playTapToChatMorph structurally (same MorphChoreography + same animator types)
- [ ] **P11.1** new method has ONE concern: reverse-direction cinematography
- [ ] **P12.2** delegates to MorphChoreographer for ticks; doesn't write transform/heightConstraint directly per tick
- [ ] **P2.11** all timing tokens via MorphTiming namespace (matches forward path)
- [ ] **P18.14** [weak self] on completion closure
- [ ] **P19.3** completion handler is idempotent (no double-fire)
- [ ] **P3.5** code documents inverse-symmetry rationale inline

### Phase 12 — Loading-dots indicator (P2, deferred — gated)

**Wave Topology DAG (Phase 12, only if executed):**

```
PHASE 12 (GATED)
│
├─→ Wave 12.1 (ConversationActivityTracker class)        ─╮
├─→ Wave 12.2 (DotsLoadingIndicator UIView)              ─┤
└─→ Wave 12.3 (animator subscribe via AnimatorProviding) ─╯
                                                          ├─→ [WC Merge Gate 12.A]
                                                                  │
                                                                  ↓
                                              Wave 12.4 (cell binding + observation wiring)
                                                                  │
                                                                  ↓
                                              Wave 12.5 (state-change source: demo / backend)
                                                                  │
                                                                  ↓
                                                                  [WC Merge Gate 12.B] ─→ Phase 12 complete
```

**Wave assignments:**
- **Wave 12.1** — `[SM]` ConversationActivityTracker per §22.3 A-2
- **Wave 12.2** — `[CA, LE]` DotsLoadingIndicator UIView with 3 dots, closure-init
- **Wave 12.3** — `[SE]` AnimatorProviding conformance for substrate-consistent loop
- **Wave 12.4** — `[SM, CA]` cell observes tracker; setActive method
- **Wave 12.5** — `[CR]` source of activity (demo timer vs real backend)
- Retro `[CQR, RCT, SA, DCH, IV, CA-conc, BV, VR, PP]`

Estimated duration: **0 days if deferred / 5-8 days if user enables.**

**Default: SKIP.** Documented as design only in §22. Re-engage if user requests AND backend infrastructure exists.

If executed:

- [ ] **P12.1** Decide state-location: ConversationActivityTracker (default per §22.3)
- [ ] **P12.2** Create `Conversation/Data/ConversationActivityTracker.swift`
- [ ] **P12.3** Wire tracker into V2RootViewController; pass to data source / cell config
- [ ] **P12.4** Create `Conversation/Timeline/DotsLoadingIndicator.swift` UIView with 3 dots
- [ ] **P12.5** Subscribe DotsLoadingIndicator to AnimationController (substrate-consistent CADisplayLink-driven loop)
- [ ] **P12.6** Add `dotsIndicator: DotsLoadingIndicator?` property to CellView
- [ ] **P12.7** Add `setActive(_ active: Bool)` method to CellView
- [ ] **P12.8** Wire observation: cell observes ConversationActivityTracker for its conversation's isActive
- [ ] **P12.9** Position constraints (final position is a design decision; default near top-right)
- [ ] **P12.10** Define source of `isActive` toggle (demo mode? real backend?)
- [ ] **P12.11** Visual verification

**Phase 12 exit gate (if executed):** dots indicator visible when conversation is active; persists across cell-rest and chat-state; animates via master CADisplayLink (substrate-consistent); state survives pool round-trips.

**Phase 12 Pillar review sub-gate (if executed):**
- [ ] **P14.6** ConversationActivityTracker is NOT a singleton (owned by V2RootVC; passed via dependency injection per P7.4)
- [ ] **P11.1** Tracker has ONE concern (per-conversation isActive state); no business logic
- [ ] **P4.3** Tracker is `@MainActor @Observable`
- [ ] **P9.1** DotsLoadingIndicator subscribes to master AnimationController via AnimatorProviding (NOT a separate Timer)
- [ ] **P1.2** DotsLoadingIndicator's 3 dot views via closure-init at class top
- [ ] **P2.11** all timing tokens (dot fade, pulse duration) via DesignSystem
- [ ] **P5.1** all new properties `private`; tracker exposes ONLY isActive(_:) and setActive(_:_:) per ISP
- [ ] **P11.4** ISP: tracker's public surface is minimal (2 methods)
- [ ] **P19.3** setActive is idempotent (setting true twice no-ops second call's view-update)

---

## §26 — Decision log additions (D11-D17)

Appended to §14 Decision log.

### 2026-05-25 — D11: Add inward-arrows affordance (P1) — in scope now

- **Decision:** Add `ChatRestAffordanceView`-equivalent (subview of CellView) at top-left with `smoothstep(0.05, 0.30, progress)` alpha curve.
- **Rationale:** Phenomenology requires bidirectional gesture-handle vocabulary. Without it, chat-state lacks visible signal for the very gesture this checklist's work enables. Small implementation, strong value.
- **Alternatives considered:**
  - Repurpose `pinchGlyph` with symbol-swap (rejected per §21.4 — position spec is top-left, not bottom-right)
  - Host in ChatContentContainer (rejected per §21.5 — lifecycle independence preferred)
  - Truly persistent (`alpha=1` always) (rejected per §21.3 — semantic clarity preferred)

### 2026-05-25 — D12: Defer loading-dots indicator (P2)

- **Decision:** Loading dots scoped in §22 as design-only. NOT implemented in current scope.
- **Rationale:** Requires opening up immutable ConversationStore OR adding parallel state container; also requires "Dot" agent infrastructure (message-sending, async response) which doesn't exist yet. Building dots without backend is theater.
- **Reversal path:** §22.5 preserves implementation tasks; re-engage when backend infra exists.
- **Alternatives considered:**
  - Wire dots now with simulated activity (rejected per §22.4 — premature engineering)
  - Open up ConversationStore mutation (rejected per §22.3 — breaks Store invariant; A-2 Tracker is safer when scope opens)

### 2026-05-25 — D13: Use hybrid Z + alpha for distance-fade (P3)

- **Decision:** Replace §6.2's alpha-only curve with hybrid: Z-translation engaging m34 + residual alpha curve for full invisibility.
- **Rationale:** Substrate-purity. m34 = -1/1000 is the substrate's perspective primitive; using it for the distance-fade propagates the substrate commitment. Hybrid accomplishes substrate AND visual completeness.
- **Implementation:** §23.5's setCamera extension.
- **Z_MAX default:** 700 (matches `MorphTiming.unifiedArcZMagnitude`). Calibrate empirically in Phase 10.
- **Alternatives considered:**
  - Alpha-only (rejected per §23.3 — substrate-impure)
  - Z-only (rejected per §23.3 — never reaches full invisibility)
  - Sin-bell Z arc (deferred — adds complexity; not phenomenologically required)

### 2026-05-25 — D14: Default to gesture-driven reverse (Interpretation A); design Interpretation B in §24.4

- **Decision:** Reverse direction uses gesture-driven heightConstraint shrink + spring (current §6 design). NO commit-driven cinematography in V1.
- **Rationale:** Gesture-driven IS substrate-consistent (user's gesture is the substrate's input primitive). Commit-driven cinematography is also substrate-consistent but adds complexity. Default to the simpler primitive; preserve cinematography design for future re-engagement.
- **Gate:** after Phase 7 ships, user reviews live. If insufficient, execute Phase 11 (§24.4 sketch).

### 2026-05-25 — D15: Hosting decision for affordance

- **Decision:** `chatRestAffordance` lives as subview of `CellView` (D-1 in §21.5), NOT subview of `ChatContentContainer`.
- **Rationale:** Mirrors `pinchGlyph` ownership pattern; independent alpha curve; available even before chatContent is installed; persists with cell across pool LRU.

### 2026-05-25 — D16: Identity decision for affordance

- **Decision:** `chatRestAffordance` is a SEPARATE `UIImageView` (C-1 in §21.4), NOT a symbol-swap on `pinchGlyph`.
- **Rationale:** Top-left position is named in the phenomenology; symbol-swap would violate the position spec. Separate view also enables simultaneous crossfade through the morph.

### 2026-05-25 — D17: Alpha curve for affordance

- **Decision:** `chatRestAffordance.alpha = smoothstep(0.05, 0.30, progress)` (B-progress-gated, not B-truly-persistent).
- **Rationale:** Semantic clarity. Cell-rest has no "collapse" affordance role; only chat-rest does. Cleaner UX than dual-affordance display at cell-rest.
- **Note:** the user's described "visible across every frame" is interpretable as "across the morph from chat-rest down to mid-progress" — the smoothstep range (0.30, 1.0 effectively) covers the bulk of the visible morph. If user feedback later prefers truly persistent (constant alpha=1), the curve flips to constant.

---

## §27 — Risk register additions (R17-R22)

Appended to §13 Risk register.

| ID | Risk | Probability | Impact | Mitigation |
|---|---|---|---|---|
| R17 | SF Symbol `"arrow.down.right.and.arrow.up.left"` not available on target iOS version | Low (on iOS 18) | Medium (would need fallback symbol or custom asset) | Phase 0.7 verifies; fallback to alternative symbol or custom asset designed before P9.4 |
| R18 | Inward-arrows affordance dual-display at cell-rest (if D17 reversed) causes UX confusion | Low (default is progress-gated) | Medium | D17 default is progress-gated; document semantics if changed |
| R19 | Hybrid Z + alpha distance-fade produces unexpected visual artifacts (e.g., chatContent visible at progress=0.2 but at apparent scale 0.7 - "ghost") | Medium | Medium | Phase 10.6 visual verification; tune curve overlap if needed |
| R20 | m34 perspective doesn't propagate through 3 sublayer levels (canvas → contentHost → cell → chatContent) | Low (verified architecturally in §16) | High (would invalidate §23) | Phase 0.10 empirical verification before structural code |
| R21 | Gesture-driven reverse feels "too direct" — users want commit-driven cinematography (D14 reversed) | Medium | Medium (would require Phase 11 execution) | Phase 7 user feedback gate; Phase 11 sketched in §24.4 for fast follow-on |
| R22 | Z-translation on chatContent.layer interferes with active-cell `bringSubviewToFront` z-order during cinematography (Phase 11) | Low (per Q6 analysis — independent systems) | Medium | Phase 10.4 / 11.6 verification; document confirmation in §16 |

---

## §28 — Updated section retrofits

Extends §19 R1-R17. New entries:

### Retrofit R18 — §6.2 supersession by §23.5

The setCamera extension sketched in §6.2 (alpha-only curve for chatContent) is **superseded** by §23.5 (hybrid Z + alpha). Implementation should follow §23.5's setCamera extension.

§6.2 remains in the document as historical record of the alpha-only proposal. §23.5 is authoritative.

### Retrofit R19 — §11.1 additions

§11.1 (new files) gains:

- `Conversation/Timeline/(no new file needed for affordance)` — `chatRestAffordance` is a property on existing `CellView`. No new file.

§11.1 should NOT gain a `DotsLoadingIndicator.swift` (per D12 deferred).

### Retrofit R20 — §12 phase reorganization

§12's 8 phases (P0-P8) are followed by §25's phases P9-P12. Total potential phases: 12. Mandatory phases: P0-P10 (P9 = affordance is in-scope, P10 = distance-fade upgrade is in-scope). Gated phases: P11 (cinematography), P12 (dots).

The critical path:
P0 → P1 → P3 → P4 → P5 → P6 → P7 → **P9** → **P10** → P8 → (gate decision on P11/P12).

Phase ordering rationale:
- P9 (affordance) after P7 (reverse direction) because the affordance is most visible at chat-rest, which Phase 7 establishes works.
- P10 (distance-fade upgrade) after P9 because it modifies the same setCamera method that P9 extends.
- P8 (edge cases & polish) AFTER P10 because edge case coverage should test against the final cell.setCamera (with affordance + Z-translation).

### Retrofit R21 — §13 risk register

Risk register grows by 6 rows (R17-R22 per §27). Total: 22 named risks. Mitigations linked to specific phases.

### Retrofit R22 — §14 decision log

Decision log grows by 7 entries (D11-D17 per §26). Total: 17 named decisions. Architectural decisions cluster in D1-D10 (handoff); polish decisions in D11-D17 (phenomenology).

### Retrofit R23 — §17 Phase 0 question additions

§17 grows from 6 questions to 12. New questions Q7-Q12 are added in §21.7 (P1) and §23.7 (P3).

---

## §29 — Updated implementation status table (extending §15)

| Phase | Status | Notes |
|---|---|---|
| P0 — Verification & prototyping | Not started | Includes new Q7-Q12 from §17 |
| P1 — ChatContent components | Not started | |
| P2 — StateController | Not started | |
| P3 — CellView integration | Not started | Includes setCamera baseline (will be extended by P9 and P10) |
| P4 — Parallel layout wiring | Not started | |
| P5 — Normalize wiring | Not started | |
| P6 — Handoff wiring | Not started | |
| P7 — Reverse direction wiring | Not started | Per §6 + §16.10's corrected normalize |
| **P9 — Inward-arrows affordance** | **Not started** | **NEW per §25; mandatory in-scope** |
| **P10 — Distance-fade upgrade (m34 + alpha)** | **Not started** | **NEW per §25; mandatory in-scope** |
| P8 — Edge cases & polish | Not started | After P10 so polish tests against final setCamera |
| **P11 — Reverse cinematography** | **GATED** | **Execute only if user requests after seeing P7 live** |
| **P12 — Loading-dots indicator** | **GATED** | **Execute only if backend infra exists** |

---

## §30 — End-state attestation

After all in-scope phases (P0-P10) complete, the user-visible behavior of pinch-to-cells reverse direction will be:

1. **At chat-rest:** chatContent visible (header, bubbles, composer), inward-arrows affordance visible at top-left (§21), labelStack invisible (alpha=0 via existing curve), pinchGlyph invisible.
2. **User pinches in:** cell.heightConstraint shrinks via `handlePinchChanged` (TC:1056). setCamera fires per gesture event, driving:
   - labelStack.alpha rises from 0 (becomes visible as progress drops below 0.30)
   - pinchGlyph.alpha rises from 0
   - chatRestAffordance.alpha falls from 1 to 0 (as progress crosses 0.30 boundary)
   - chatContent.layer.transform.translation.z grows toward Z_MAX (chatContent recedes via m34 perspective)
   - chatContent.alpha falls from 1 to 0 between progress 0.35 and 0.05
3. **Atmospheric gradient (pageGradientLayer, TC:103) becomes visible** at top/bottom of viewport as cell shrinks (substrate default, no checklist action).
4. **Cell above (previously collapsed) becomes visible** as the active cell shrinks (substrate default via `updateNeighborTranslations` + cellPool).
5. **User releases pinch:** `handlePinchEnded` classifies as `.pinchToCells`. `springToCellRest` engages with carried velocity. Cell springs to naturalH.
6. **Spring settles:** `tryClearActiveCellAtRest` fires; `activeCellIndex = nil`; `panRecognizer.isEnabled = true`; `restoreNaturalSiblingOrder` runs. cell-rest state restored.
7. **Cell-rest chrome fully visible:** labelStack, pinchGlyph, chatRestAffordance (alpha=0 here since progress=0 — only visible at chat-rest), chatContent (alpha=0; transform.translation.z = Z_MAX but invisible).

**Not delivered (per scoped deferrals):**
- Loading-dots indicator on cell-rest (D12 deferred; §22 preserved)
- Commit-driven cinematography on reverse (D14 default A; §24.4 preserved)

**Delivered phenomenology elements:**
- ✅ Inward-arrows affordance (P1 / §21)
- ✅ Atmospheric gradient revealing (substrate default)
- ✅ Distance-based fading via m34 (P3 / §23, hybrid Z + alpha)
- ✅ Cell content materializing (existing setCamera curves)
- ❌ Loading-dots indicator (P2 / §22, deferred)
- ✅ Cell above visibility (substrate default)
- ⚠️ Inverse-symmetry with tap-to-chat (partial — gesture-driven + Z + alpha gives substantial richness; full choreography is §24.4 design preserved)

**End-of-checklist final summary:** the work needed to deliver phenomenological matches up to 6 of 7 elements is now concretely tasked, scoped, and gated. The 7th (commit-driven cinematography) is designed but gated on user direction.

---

---

## §31 — Gap closure scope (the 10 items between "checklist written" and "checklist ready to execute")

The honest audit identified 10 gap categories. This section sets the frame; §§32-40 work each to bedrock and produce concrete code/tasks. Goal: after this batch lands, the checklist is execution-ready end-to-end with no inferred / sketched / undecided items on the critical path.

| ID | Gap | Section | Resolution type | Reaches "ready" |
|---|---|---|---|---|
| A | `completeHandoffIfPending()` recovery handler unsketched | §32 | Sketch code + state machine + observer wiring | Yes after §32 |
| B | `ChatViewController.captureTransientState()` defined but unsketched | §33 | Sketch struct + method + integration with stateController | Yes after §33 |
| C | `ChatBubbleStackView.configure(with:)` referenced but unspecified | §34 | Sketch configure + scrollToBottom | Yes after §34 |
| D | `TimelineCanvas.flushPoolForMemoryPressure()` named but unspecified | §35 | Sketch method + V2RootVC observer | Yes after §35 |
| E | Pinch-commit forward chrome asymmetry with tap-forward | §36 | E1 chrome fade + E2 day-marker emergence; call performMorphChromeTransition from playTapToChatMorph | Yes after §36 |
| F | `keyboardLayoutGuide` decision unrecorded | §37 | D18 explicit acceptance OR upgrade path | Yes after §37 |
| G | Phase 0 questions (Q1-Q12) lack verification methodology + success thresholds | §38 | Per-question playbook with method + threshold + impact | Yes after §38 |
| H | Phase ordering ambiguity (P3 → P9 → P10 setCamera supersession) | §39 | Explicit supersession matrix | Yes after §39 |
| I | Phase estimates optimistic | §39 | Re-baseline P0=3-5d, P10=3-5d, P11=5-8d | Yes after §39 |
| J | Cut-off "Inverse-symmetry with tap-to-chat" specification | §40 | D23 known-unknown; placeholder for user to complete | Mitigated (placeholder + risk) |

After §32-§40 land, execution is unblocked. The remaining gaps are external (user-side completion of J, empirical answers from Phase 0 itself).

---

## §32 — Gap A: `completeHandoffIfPending()` recovery handler (full trace + sketch)

**Root node:** "A recovery handler that detects partial-handoff state at scene-foreground and completes the handoff so the user sees a consistent end state."

### §32.1 — Six-question trace

**Q1 (Rests on):**
- A **detection mechanism** — needs to know whether a present-flow was in progress when scene deactivated. Two options: (i) explicit phase enum tracking each transition, (ii) heuristic ("chatVC exists AND chatVC.view.alpha > 0 AND canvas.alpha == 0").
- **The handoff operation itself** — `performHandoff()` already sketched in §2.4 / §16.10. Recovery calls into the same path.
- **Normalize** — `canvas.normalizeToChatRest(activeCellIndex:)` per §16.10. Required if the partial state stopped BEFORE crossFade completion.
- **A foreground observer** — `UIScene.didActivateNotification` on V2RootViewController. Symmetric with the existing `UIScene.willDeactivateNotification` observer (V2:64-68).
- **The handoff phase state itself** — currently RevealCoordinator has `private var revealState: RevealState` with cases `.idle` and `.active(chat:blur:)`. Insufficient granularity: doesn't distinguish "presenting / crossFade complete / handoff complete." Need a finer state machine.

**Q2 (Why does this exist):**
- §16.9 documented that `cancelInFlight()` calls `finishAnimation(at: .current)` which fires completion handlers with `position == .current`, BUT the existing completion-handler bodies in RevealCoordinator (RC:82-86, RC:93-100) gate cleanup on `if position == .end`. So on cancellation, cleanup is SKIPPED — including the future handoff completion we'd attach.
- The user backgrounds the app mid-reveal (e.g., between T=1.6s and T=2.8s post-reveal-ready). Scene deactivation → cancelInFlight → animators stopped → completion bodies skipped → chatVC stays in V2RootVC's child VCs, alpha=1, isUserInteractionEnabled=true. Canvas may or may not be at alpha=0 depending on when in the choreography deactivation occurred.
- Without recovery, the user returns to a stuck chatVC over a (possibly) hidden canvas. No pinch reaches the canvas. App is jammed.

**Q3 (Assumes):**
- The partial state IS detectable (true with phase enum).
- It's safe to call `performHandoff` from a recovered state (depends on normalize having run; phase enum tracks this).
- ChatVC's transient state is still readable from the recovered position (yes — view tree unchanged during background).
- Normalize is idempotent (yes — repeated calls produce the same end state because every operation is `=`-style write or `removeAnimation` which no-ops if already removed).

**Q4 (If changed — prevent the partial state instead of recovering):**
- Alternative: have `cancelInFlight()` synchronously invoke `performHandoff()` BEFORE stopping animators. Then on deactivation, handoff completes atomically.
- Cost: forces UI updates inside the deactivation handler, which UIKit may not honor (deactivation is mid-transition, app extension might not commit layers).
- Riskier than recovery-on-foreground. Reject.

**Q4 (If changed — drop chatVC immediately on deactivation):**
- Alternative: detach chatVC and snap to chat-state-with-cell-chatContent immediately on deactivation. Skips the handoff dance entirely.
- Requires normalize + handoff to BOTH run in cancelInFlight.
- Higher complexity than recovery-on-foreground.

**Q5 (If removed — no recovery handler):**
- User returns from background to a stuck chatVC over a (possibly) hidden canvas.
- **Classification:** KEYSTONE. Without recovery, common user actions (Control Center swipe, incoming call, app switch) leave the app unusable on this code path.

**Q6 (Absent):**
- No invariant test that asserts handoff atomicity post-foreground.
- No metric / log to detect "we entered recovery N times in production."
- No alternative escape (e.g., "if recovery fails, force-snap to cell-rest").

### §32.2 — HOT branches

- **B32.A — Detection mechanism** (phase enum vs heuristic). Resolved: phase enum (explicit > heuristic).
- **B32.B — Recovery action** (complete handoff vs alternative escape). Resolved: complete handoff (most correct end state).
- **B32.C — Observer location** (V2RootVC vs RevealCoordinator). Resolved: V2RootVC owns scene lifecycle observers (existing pattern at V2:64-69); call RevealCoordinator's completeHandoffIfPending method.

### §32.3 — Concrete sketch

**`RevealCoordinator` additions:**

```swift
// RevealCoordinator.swift, add near top of class:

enum HandoffPhase {
    case idle                  // not presenting
    case presenting            // chatVC instantiated; blurFadeIn in flight
    case crossFadeStarted      // crossFade in flight; canvas.alpha animating to 0
    case crossFadeComplete     // canvas.alpha=0; normalize scheduled / running
    case blurFadeOutStarted    // blurFadeOut in flight
    case handoffComplete       // chatVC removed; chatContent visible; canvas.alpha=1
}

private(set) var handoffPhase: HandoffPhase = .idle

// Phase transitions are written at each milestone in runRevealChoreography:
// - At present() invocation: handoffPhase = .presenting
// - In crossFade.startAnimation callback: handoffPhase = .crossFadeStarted
// - In crossFade.addCompletion (position .end): handoffPhase = .crossFadeComplete
// - In blurFadeOut.startAnimation callback: handoffPhase = .blurFadeOutStarted
// - In blurFadeOut.addCompletion (position .end) AFTER performHandoff: handoffPhase = .handoffComplete

func completeHandoffIfPending() {
    // Only recover if we're in a partial state. .idle = nothing to do. .handoffComplete = done.
    switch handoffPhase {
    case .idle, .handoffComplete:
        return
    case .presenting, .crossFadeStarted:
        // We deactivated before crossFade completed. Canvas may still be at alpha=1.
        // Snap the geometry forward.
        canvas?.alpha = 0
        if let canvas = canvasRef, let activeIdx = canvas.activeCellIndex {
            canvas.normalizeToChatRest(activeCellIndex: activeIdx)
        }
        performHandoff()
        handoffPhase = .handoffComplete
    case .crossFadeComplete, .blurFadeOutStarted:
        // crossFade completed; normalize may or may not have run.
        // Idempotent re-run is safe (per Q3); ensures consistent state.
        if let canvas = canvasRef, let activeIdx = canvas.activeCellIndex {
            canvas.normalizeToChatRest(activeCellIndex: activeIdx)
        }
        performHandoff()
        handoffPhase = .handoffComplete
    }
}
```

**`V2RootViewController` additions:**

```swift
// In viewDidLoad, alongside existing willDeactivate observer (V2:64-69):

NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleSceneDidActivate),
    name: UIScene.didActivateNotification,
    object: nil
)

@objc private func handleSceneDidActivate() {
    revealCoordinator.completeHandoffIfPending()
}
```

### §32.3.1 — Pillar-compliant authoritative sketch (SUPERSEDES §32.3)

§32.3 is the functional sketch; §32.3.1 is the version engineers MUST implement. Differences: pillar-compliant decomposition, comment-on-why, no force-unwraps in optional chains, proper observer cleanup.

**Pillar definitions introduced on first use:**

- **P4.2 — `final` by default.** Every class is `final` unless designed for inheritance.
- **P4.3 — `@MainActor` on UI types.** Explicit, not implicit-via-UIView.
- **P5.1 — `private` by default.** Every property/method starts `private`. Promote only when consumer needs require.
- **P5.5 — `private(set)` for tested-but-not-mutated state.** Read access for tests/observers; write access fenced.
- **P11.4 — ISP.** Many specific protocols > one fat protocol.
- **P17.5 — Argument labels make call sites self-documenting.**
- **P18.14 — Closure capture lists.** `[weak self]` discipline on every escaping closure.

**The pillar-compliant rewrite (`RevealCoordinator.swift`, add near class top):**

```swift
// MARK: - Handoff phase state machine
//
// Tracks the 6-stage reveal lifecycle so that scene-deactivation recovery
// (completeHandoffIfPending) can resume from a partial state on foreground.
// P11.1 SRP: this enum has ONE concern — encoding the lifecycle.
// P19.5 immutability: each case is a let-only state marker; transitions are
// explicit writes to handoffPhase via private setters in named milestones.

enum HandoffPhase {
    case idle                       // P3.5: name carries contract
    case presenting                 // chatVC instantiated; blurFadeIn in flight
    case crossFadeStarted           // crossFade in flight; canvas.alpha → 0
    case crossFadeComplete          // canvas.alpha=0; normalize scheduled / running
    case blurFadeOutStarted         // blurFadeOut in flight
    case handoffComplete            // chatVC removed; chatContent visible; canvas.alpha=1
}

// P5.5 private(set): read-access for V2RootVC + tests; write-access fenced
// to RevealCoordinator's milestone writers.
private(set) var handoffPhase: HandoffPhase = .idle

// MARK: - Handoff recovery (scene-deactivation foreground resume)

/// Resume the handoff from a partial state on scene foreground.
/// Idempotent (P19.3): calling twice when phase ≠ .idle && ≠ .handoffComplete
/// completes once; a second call finds phase == .handoffComplete and no-ops.
///
/// Pillar honors: P11.1 (recovery is one concern), P12.2 (tell-don't-ask
/// internally — recovery delegates to canvas.normalizeToChatRest +
/// performHandoff), P13.4 (≤ 20 LOC), P19.3 (idempotent).
func completeHandoffIfPending() {
    // P1.1 guard-chain + P6.7 silence justified: nothing to recover from idle
    // (no in-flight) or handoffComplete (already done). Silence here is the
    // base case of the recovery state machine, not an error.
    switch handoffPhase {
    case .idle, .handoffComplete:
        return

    case .presenting, .crossFadeStarted:
        // Pre-crossFade-complete deactivation: canvas may still be visible.
        // Snap geometry forward to the canvas.alpha=0 invariant that the rest
        // of the reveal would have produced, then run normalize + handoff.
        recoverFromPreCrossFadeState()

    case .crossFadeComplete, .blurFadeOutStarted:
        // Post-crossFade deactivation: canvas already at alpha=0; normalize
        // may or may not have run yet. Re-running is idempotent (per Q3+§16.10).
        recoverFromPostCrossFadeState()
    }

    handoffPhase = .handoffComplete                       // P19.3 transition recorded
}

// MARK: - Recovery helpers (P11.1 SRP per phase-cluster)

/// Recovery path for deactivation during .presenting or .crossFadeStarted.
/// Forces canvas.alpha=0 (skipping any remaining crossFade animation), then
/// runs normalize + handoff.
/// P6.7 silence justified: if canvasRef or activeCellIndex went away during
/// background (extremely rare; would only happen if reloadData fired), the
/// recovery cannot proceed safely — early return preserves consistency.
private func recoverFromPreCrossFadeState() {
    guard let canvas = canvasRef,
          let activeIdx = canvas.activeCellIndex
    else { return }

    canvas.alpha = 0                                       // snap-forward to crossFade end-state
    canvas.normalizeToChatRest(activeCellIndex: activeIdx)
    performHandoff()
}

/// Recovery path for deactivation during .crossFadeComplete or .blurFadeOutStarted.
/// Canvas is already at alpha=0; normalize may have run, re-running is safe.
private func recoverFromPostCrossFadeState() {
    guard let canvas = canvasRef,
          let activeIdx = canvas.activeCellIndex
    else { return }

    canvas.normalizeToChatRest(activeCellIndex: activeIdx)
    performHandoff()
}
```

**Phase transition writes (added at 5 milestones in `runRevealChoreography`):**

```swift
// Milestone 1: at present() invocation, BEFORE installChatViewController.
handoffPhase = .presenting

// Milestone 2: inside crossFade.startAnimation closure (or its preceding setup).
// CrossFade is started via startAnimation(afterDelay:); we know-when-it-starts
// by capturing the time inside its addAnimations closure (called once at start).
// Cleanest: write the transition just before crossFade.startAnimation(afterDelay:).
handoffPhase = .crossFadeStarted

// Milestone 3: inside crossFade.addCompletion (position == .end branch).
crossFade.addCompletion { [weak self] position in                // P18.14 [weak self]
    guard position == .end else { return }                       // P6.7 silence justified: only end-state cleanup
    self?.handoffPhase = .crossFadeComplete
    self?.chatViewController?.view.isUserInteractionEnabled = true
}

// Milestone 4: just before blurFadeOut.startAnimation(afterDelay:).
handoffPhase = .blurFadeOutStarted

// Milestone 5: inside blurFadeOut.addCompletion (position == .end), AFTER performHandoff.
blurFadeOut.addCompletion { [weak self] position in              // P18.14
    guard position == .end, let self else { return }
    self.performHandoff()
    self.handoffPhase = .handoffComplete
    self.revealAnimators.removeAll { /* ... */ }
}
```

**`V2RootViewController.swift` additions (pillar-compliant):**

```swift
// MARK: - Scene lifecycle (in viewDidLoad, alongside existing willDeactivate)

NotificationCenter.default.addObserver(
    self,                                                         // P18.14 selector target retained by NotificationCenter
    selector: #selector(handleSceneDidActivate),                  // P17.5 labeled args
    name: UIScene.didActivateNotification,
    object: nil
)

// Observer is released in deinit (V2:72-74) via the existing
// removeObserver(self) call — symmetric with willDeactivateNotification setup.

@objc private func handleSceneDidActivate() {                     // P5.1 private by default
    revealCoordinator.completeHandoffIfPending()                  // P12.2 tell-don't-ask
}
```

**Pillar honors footnote:**

| Member | Pillars honored |
|---|---|
| `HandoffPhase` enum | P3.5 (names carry contract), P11.1 (single concern), P19.5 (immutable cases) |
| `handoffPhase` property | P5.5 (private(set) for tested-but-fenced state) |
| `completeHandoffIfPending()` | P11.1, P12.2, P13.4, P19.3, P6.7 (silence in idle/complete cases is base case, not error) |
| `recoverFromPreCrossFadeState()` / `recoverFromPostCrossFadeState()` | P11.1 (one concern per recovery cluster), P1.1 (guard-chain), P6.7 (silence justified for ARC-released refs) |
| Phase-transition writes (5 milestones) | P18.14 ([weak self] on every closure), P6.7 (`guard position == .end` silenced) |
| `handleSceneDidActivate` | P5.1 (private), P12.2 (delegates to coordinator) |

**Pillar violations to verify ABSENT:**

- ❌ No `!` force-unwrap in recovery paths (every optional guard-chained) — **P1.3 enforced**
- ❌ No magic strings/numbers (notification names from UIKit type-safe API) — **P2.11 enforced**
- ❌ No silent return without WHY comment — **P6.7 enforced**
- ❌ No closures without `[weak self]` — **P18.14 enforced**
- ❌ No `public` exposure of `handoffPhase` — **P5.4 (only `private(set)`)**
- ❌ Method length: each ≤20 LOC — **P13.4 enforced**

### §32.4 — Concrete tasks (with per-task Pillar compliance + Agent Ensemble)

**Default Agent Ensemble for §32 tasks (Wave 6.1 + Wave 6.4 + Wave 8.2):** `[RO, CR] | [CQR, RCT, SA, DCH, IV, CA-conc, BV] | [WC]` — implementers RevealOrchestrator + CompositionRoot; reviewers run the standard 5 + concurrency auditor + build validator; WaveCoordinator opens/closes the merge gate. Tasks below specify their wave assignment + override ensembles where the default doesn't fit.

- [ ] **A.1** Add `HandoffPhase` enum to `RevealCoordinator.swift` at MARK section "Handoff phase state machine"
  - **Agent ensemble (Wave 6.1):** `[RO]` | default reviewers | `[WC]`
  - **Pillar compliance:**
    - **P3.5 code-as-documentation:** case names (`presenting`, `crossFadeStarted`, etc.) carry the contract; no docstring needed beyond inline `//` notes
    - **P11.1 SRP:** the enum has one concern — encoding the lifecycle. Don't fold in unrelated state
    - **P19.5 immutability:** each case is a let-only marker; no associated values needed
    - **P20.1 one type per file:** consider whether `HandoffPhase` should live in its own file. Per §32.3.1 it lives in `RevealCoordinator.swift` because it's a private state of the coordinator
- [ ] **A.2** Add `private(set) var handoffPhase: HandoffPhase = .idle`
  - **Agent ensemble (Wave 6.1):** `[RO]` | default reviewers | `[WC]`
  - **Pillar compliance:**
    - **P5.5 private(set):** read access for tests / observers; writes fenced to RevealCoordinator's internals
    - **P8.3 var-justified:** mutability is the property's purpose (state machine transitions)
- [ ] **A.3** Write phase transitions at each milestone in `runRevealChoreography` (5 transition points enumerated above)
  - **Agent ensemble (Wave 6.2):** `[RO]` | default reviewers + `[VR]` | `[WC]` — VR needed because phase ordering affects visible behavior
  - **Pillar compliance:**
    - **P18.14 [weak self]:** every closure in runRevealChoreography uses `[weak self]`; the new transition writes go INSIDE those closures
    - **P6.7 silence justified:** the `guard position == .end` filter is documented per-callsite
    - **P10.2 phase ordering:** transitions write BEFORE the animation kicks off (or in the completion); write order matters for recovery correctness
- [ ] **A.4** Add `completeHandoffIfPending()` per §32.3.1
  - **Agent ensemble (Wave 8.2):** `[RO]` | default reviewers + `[ER]` | `[WC]` — ER verifies scene-deactivation scenarios empirically
  - **Pillar compliance:**
    - **P11.1 SRP:** recovery is one concern; helpers extract per-phase-cluster logic
    - **P12.2 Tell-don't-ask:** delegates to canvas.normalizeToChatRest + performHandoff rather than reaching into canvas internals
    - **P13.4 method length:** main method ≤20 LOC; recovery helpers ≤10 LOC each
    - **P19.3 idempotent:** calling twice when phase==.handoffComplete returns immediately
- [ ] **A.5** Add `recoverFromPreCrossFadeState()` and `recoverFromPostCrossFadeState()` helpers (§32.3.1)
  - **Agent ensemble (Wave 8.2):** `[RO]` | default reviewers | `[WC]`
  - **Pillar compliance:**
    - **P11.1 SRP:** each helper handles one cluster of phase states
    - **P1.1 guard-chain:** both helpers use single multi-binding guard
    - **P6.7 silence justified:** guard-chain return is the only failure path; comment documents why ARC could legitimately release refs mid-background
- [ ] **A.6** In `RevealCoordinator.cancelInFlight()` (RC:135-143), do NOT modify `handoffPhase`. Phase reflects whatever state the in-flight animation was in. Recovery on foreground reads it.
  - **Agent ensemble (Wave 8.2):** `[—]` (no-code: documentation invariant) | `[RCT, SA]` | `[WC]` — RCT runs Q3 deletion test on the explicit non-mutation invariant
  - **Pillar compliance:**
    - **P11.1 SRP:** cancelInFlight stops animations; phase is recovery's concern
    - **P3.3 deletion test:** removing the no-op decision here would not break recovery, BUT modifying phase here WOULD break recovery (forcing .idle would mask the partial state)
- [ ] **A.7** In `V2RootViewController.viewDidLoad`, add `UIScene.didActivateNotification` observer
  - **Agent ensemble (Wave 6.4):** `[CR]` | default reviewers | `[WC]`
  - **Pillar compliance:**
    - **P10.2 symmetry:** mirrors existing willDeactivateNotification setup (V2:64-69)
    - **P17.5 labeled args:** `selector:`, `name:`, `object:` are labeled per Foundation API
    - **P11.1 SRP:** V2RootVC owns scene lifecycle; coordinator owns reveal lifecycle; clean separation
- [ ] **A.8** Implement `@objc private func handleSceneDidActivate()` calling `revealCoordinator.completeHandoffIfPending()`
  - **Agent ensemble (Wave 6.4):** `[CR]` | default reviewers | `[WC]`
  - **Pillar compliance:**
    - **P5.1 private by default:** `private` (only NotificationCenter consumes via selector)
    - **P12.2 Tell-don't-ask:** V2RootVC tells coordinator to recover; doesn't query coordinator state and act
    - **P11.1 SRP:** the method has one line — its purpose is the delegation
- [ ] **A.9** Verify observer release in deinit (V2:72-74 already has `removeObserver(self)` covering all observers via the catch-all signature)
  - **Agent ensemble (Wave 6.4 retro):** `[—]` | `[CA-conc, RCT, DCH]` | `[WC]` — concurrency auditor verifies retain-cycle absence; RCT runs deletion test on the catch-all observer release
  - **Pillar compliance:**
    - **P5.7 lifecycle parity:** every addObserver has a removeObserver in deinit
    - **P18.14 retain cycle check:** NotificationCenter retains `self` (the observer); deinit's removeObserver breaks the cycle
- [ ] **A.10** Test scenarios per §32.4 original A.9 list: deactivate at T+0.1s, T+0.4s, T+0.55s, T+0.8s, T+1.3s. Verify recovery in each.
  - **Agent ensemble (Wave 8.2 + 8.7 retro):** `[ER, VR]` | `[BV, CQR]` | `[WC]` — empirical runner triggers deactivation; visual regressor records foreground state
  - **Pillar compliance:**
    - **P18.20 test coverage:** programmatic deactivation via `UIApplication.shared.perform(Selector("suspend"))` (private API; debug-only) OR simulated via launching Control Center / Home swipe in simulator
    - **P3.2 junior-dev test:** could a junior engineer reading §32.3.1 understand the recovery flow? Code + comments should be sufficient without external context

### §32.5 — Acceptance criteria

- [ ] On foreground after deactivation at ANY point in the reveal sequence: user sees consistent post-handoff state (chatContent visible, canvas.alpha=1, pinchRecognizer enabled, chatVC removed).
- [ ] `completeHandoffIfPending` is idempotent (calling twice does nothing the second time).
- [ ] No retain cycles introduced by the new observer.

---

## §33 — Gap B: `ChatViewController.captureTransientState()` + bind (full trace + sketch)

**Root node:** "A method on `ChatViewController` that returns a snapshot of all transient state the handoff needs to transfer, plus an inverse `bindTransientState` for pre-populating chatVC from a state controller at install time."

### §33.1 — Six-question trace

**Q1 (Rests on):**
- chatVC's private subviews: `composerTextField`, `scrollView` (CVC:10-14)
- A snapshot struct type bundling 4 fields (composerText, scrollOffset, composerWasFirstResponder, selectedTextRange)
- The handoff's capture/apply flow (§0.4)
- The state controller's `captureFromChatVC` and `applyTo` methods (§1.4)
- The state-preservation requirement during cell pool round-trips (§4.8)

**Q2 (Why exists):**
- §16.12 surfaced that chatVC's subviews are private; can't be read from outside.
- A method on chatVC owning the snapshot contract is cleaner than exposing internals.
- Future schema changes to chatVC's internal subviews don't break callers — only the method's return type matters.

**Q3 (Assumes):**
- A one-shot snapshot at handoff time is sufficient (per D6: capture-at-handoff, not continuous sync).
- The four named fields cover all state the user might lose at handoff.
- `UITextRange` is snapshottable (the OBJECT identity persists across the swap, but applying to a different text field requires offset-based remapping per §4.5 `mapTextRange`).

**Q4 (If changed — make subviews `internal` instead of `private`):**
- All callers (RevealCoordinator, ConversationStateController) directly read chatVC's subviews.
- Encapsulation weakened. Multiple code paths read internals; refactor risk.
- Reject; method is cleaner.

**Q4 (If changed — expose a broader getter API):**
- e.g., `chatVC.composerText: String { get }`, `chatVC.scrollOffset: CGPoint { get }`, etc.
- Multiple individual getters vs one snapshot method.
- Snapshot method captures a consistent moment-in-time (all four fields from the same instant); individual getters could race if the state changes between reads.
- Snapshot is preferred.

**Q5 (If removed — no capture):**
- State lost at handoff. User sees composer text reset, scroll position reset, keyboard dismiss+reappear.
- Round-trip preservation broken.
- **Classification:** LOAD-BEARING for round-trip phenomenology.

**Q6 (Absent):**
- No equivalent on `ChatContentContainer` (reverse direction doesn't capture chatContent state because there's no destination at cell-rest — state is already on the cell pool's state controller).
- No `applyTransientState` on chatVC (we DO need this for §4.8 round-trip preservation when user re-taps a cell with preserved state). Add as `bindTransientState`.

### §33.2 — Concrete sketch

**`ChatViewController` additions:**

```swift
// ChatViewController.swift, add at top of class:

struct TransientStateSnapshot {
    let composerText: String
    let scrollOffset: CGPoint
    let composerWasFirstResponder: Bool
    let selectedTextRange: UITextRange?
}

// Add as instance method (CVC:117 area):

func captureTransientState() -> TransientStateSnapshot {
    TransientStateSnapshot(
        composerText: composerTextField.text ?? "",
        scrollOffset: scrollView.contentOffset,
        composerWasFirstResponder: composerTextField.isFirstResponder,
        selectedTextRange: composerTextField.selectedTextRange
    )
}

func bindTransientState(_ snapshot: TransientStateSnapshot) {
    composerTextField.text = snapshot.composerText
    // Defer scroll offset until layout completes (contentSize derived from bubbles)
    DispatchQueue.main.async { [weak self] in
        self?.scrollView.contentOffset = snapshot.scrollOffset
    }
    // First responder + selection range applied post-installation in §4.5's path
    // (becomeFirstResponder fires after the parent crossfade reveals chatVC)
}
```

**`ConversationStateController` updates per R10:**

```swift
// ConversationStateController.swift (referenced in §1.4 sketch):

func captureFromChatVC(_ chatVC: ChatViewController) {
    let snapshot = chatVC.captureTransientState()
    composerText = snapshot.composerText
    scrollOffset = snapshot.scrollOffset
    composerIsFirstResponder = snapshot.composerWasFirstResponder
    selectedTextRange = snapshot.selectedTextRange
}

func bindToChatVCAtInstall(_ chatVC: ChatViewController) {
    let snapshot = TransientStateSnapshot(
        composerText: composerText,
        scrollOffset: scrollOffset,
        composerWasFirstResponder: composerIsFirstResponder,
        selectedTextRange: selectedTextRange
    )
    chatVC.bindTransientState(snapshot)
}
```

**Integration in `RevealCoordinator.installChatViewController` (per D10):**

```swift
// After chatVC.configure(with: conversation):

if let stateController = self.stateController {
    stateController.bindToChatVCAtInstall(chatVC)
}
```

### §33.2.1 — Pillar-compliant authoritative sketch (SUPERSEDES §33.2)

**Pillar definitions introduced on first use:**

- **P9.2 — `Sendable` on value types crossing isolation.** Snapshot bundles primitive types + an opaque `UITextRange?`. Must annotate Sendable conformance per 9S contract.
- **P16.2 — Shorthand syntactic forms.** Prefer `T?` over `Optional<T>`, `[T]` over `Array<T>`.
- **P19.5 — Immutability where possible.** Snapshot is captured-at-a-moment; all fields `let`.
- **P20.1 — One public type per file (mostly).** TransientStateSnapshot is intimately coupled to ChatViewController; can ship in same file.

**The pillar-compliant rewrite (`ChatViewController.swift` additions, at MARK section "Transient state snapshot"):**

```swift
// MARK: - Transient state snapshot (capture/apply for handoff)

/// Snapshot of chatVC state that must survive the handoff to cell.chatContent.
/// All fields are `let`-only — a snapshot represents a moment-in-time; once
/// captured, it does not mutate. Apply (via bindTransientState) writes them
/// into the target view.
///
/// P9.2 Sendable: value type with Sendable-conforming members (String,
/// CGPoint, Bool, UITextRange? — UITextRange is Sendable per ObjC isa).
/// P19.5 immutability: all `let`.
/// P3.5 code-as-documentation: name + field names carry the contract.
struct TransientStateSnapshot: Sendable {
    let composerText: String
    let scrollOffset: CGPoint
    let composerWasFirstResponder: Bool
    let selectedTextRange: UITextRange?
}

/// Capture the current transient state for handoff transfer.
/// Pure read of chatVC's internal subviews; no side effects (P19.1).
///
/// Pillar honors: P11.1 SRP (one concern), P19.1 pure, P3.5 (name carries contract).
func captureTransientState() -> TransientStateSnapshot {
    TransientStateSnapshot(
        composerText: composerTextField.text ?? "",       // P1.3 ?? for value defaults
        scrollOffset: scrollView.contentOffset,
        composerWasFirstResponder: composerTextField.isFirstResponder,
        selectedTextRange: composerTextField.selectedTextRange
    )
}

/// Apply a snapshot to this chatVC at install time (round-trip restoration).
/// Composer text is applied synchronously; scroll offset is deferred to next
/// runloop tick because scrollView.contentSize depends on layout completing.
///
/// First responder + selection range are deferred to post-installation (the
/// reveal sequence's crossFade completion fires becomeFirstResponder if needed
/// — handled in ConversationStateController.bindToChatVCAtInstall's caller).
///
/// Pillar honors: P11.1 SRP, P12.2 tell-don't-ask, P18.14 [weak self].
func bindTransientState(_ snapshot: TransientStateSnapshot) {
    composerTextField.text = snapshot.composerText

    // P1.10 WHY: scrollView.contentSize is computed by Auto Layout from
    // bubbleStack's intrinsic content; setting contentOffset BEFORE layout
    // completes would clamp to (0,0) regardless of intended offset. Defer.
    DispatchQueue.main.async { [weak self] in
        self?.scrollView.contentOffset = snapshot.scrollOffset
    }
}
```

**`ConversationStateController.swift` updates (per R10):**

```swift
// MARK: - ChatVC capture/apply integration

/// Capture chatVC's transient state into this controller. Called at handoff
/// time (T=2.8s) before the atomic alpha swap.
/// P19.3 idempotent: calling twice writes the same values.
func captureFromChatVC(_ chatVC: ChatViewController) {
    let snapshot = chatVC.captureTransientState()
    composerText = snapshot.composerText
    scrollOffset = snapshot.scrollOffset
    composerIsFirstResponder = snapshot.composerWasFirstResponder
    selectedTextRange = snapshot.selectedTextRange
}

/// Bind preserved state into a freshly-instantiated chatVC at install time.
/// Solves the §4.8 round-trip bug where re-presenting a previously-visited
/// conversation would overwrite preserved state with empty chatVC defaults.
///
/// P11.1 SRP, P19.3 idempotent.
func bindToChatVCAtInstall(_ chatVC: ChatViewController) {
    let snapshot = TransientStateSnapshot(
        composerText: composerText,
        scrollOffset: scrollOffset,
        composerWasFirstResponder: composerIsFirstResponder,
        selectedTextRange: selectedTextRange
    )
    chatVC.bindTransientState(snapshot)
}
```

**Pillar honors footnote:**

| Member | Pillars honored |
|---|---|
| `TransientStateSnapshot` struct | P9.2 (Sendable), P19.5 (let-only), P3.5 (name carries contract), P20.1 (co-located with ChatVC per intimacy rule) |
| `captureTransientState()` | P11.1 SRP, P19.1 pure, P1.3 (?? for value default) |
| `bindTransientState(_:)` | P11.1, P12.2 (tells chatVC what to do, doesn't ask), P18.14 [weak self], P1.10 WHY comment |
| `captureFromChatVC(_:)` | P19.3 idempotent |
| `bindToChatVCAtInstall(_:)` | P11.1, P19.3, P12.2 |

**Pillar violations to verify ABSENT:**

- ❌ No force-unwraps — **P1.3 enforced**
- ❌ No silent returns without WHY — **P6.7 N/A (no early returns)**
- ❌ No mutable `var` in TransientStateSnapshot — **P19.5 / P8.3 enforced**
- ❌ No magic strings — **P2.11 enforced (no magic literals)**

### §33.3 — Concrete tasks (with per-task Pillar compliance + Agent Ensemble)

**Default Agent Ensemble for §33 tasks (Wave 2.1 + Wave 2.3 + Wave 4.2 + Wave 6.3):** `[SM, RO] | [CQR, RCT, SA, DCH, IV, BV] | [WC]` — StateMechanic owns the capture/apply seam; RevealOrchestrator integrates at install/handoff time. Task-level overrides where noted.

- [ ] **B.1** Add `TransientStateSnapshot` struct to `ChatViewController.swift` per §33.2.1
  - **Pillar compliance:** P9.2 (Sendable), P19.5 (let-only fields), P20.1 (co-located with ChatVC per intimacy), P3.5 (name carries contract)
- [ ] **B.2** Add `captureTransientState() -> TransientStateSnapshot` method per §33.2.1
  - **Pillar compliance:** P11.1 (one concern: snapshot construction), P19.1 (pure: reads from existing instance state), P1.3 (`??` for value default on `composerTextField.text ?? ""`)
- [ ] **B.3** Add `bindTransientState(_ snapshot: TransientStateSnapshot)` method per §33.2.1
  - **Pillar compliance:** P11.1, P12.2 (tells chatVC what to write; doesn't expose internals), P18.14 ([weak self] in dispatch_async), P1.10 (WHY comment on scrollOffset deferral)
- [ ] **B.4** Update `ConversationStateController.captureFromChatVC(_:)` to use the snapshot per §33.2.1
  - **Pillar compliance:** P11.1 (one concern), P19.3 (idempotent — calling twice writes the same values), P12.2 (controller asks ChatVC for snapshot; doesn't reach into ChatVC's subviews)
- [ ] **B.5** Add `ConversationStateController.bindToChatVCAtInstall(_:)` method per §33.2.1
  - **Pillar compliance:** P11.1, P19.3, P12.2, P10.2 (symmetric to capture: capture/bind pair is the established pattern)
- [ ] **B.6** Wire `bindToChatVCAtInstall` into `RevealCoordinator.installChatViewController` AFTER `configure(with: conversation)` per D10
  - **Pillar compliance:** P10.2 (consistent invocation order: configure → bind → return), P12.2 (RevealCoordinator tells stateController to bind), P18.14 (no closure capture issues; synchronous call)
- [ ] **B.7** Test: tap A → type "hello" → pinch back → tap A → composer shows "hello" (verifies the bind path)
  - **Pillar compliance:** P18.20 (test coverage), P3.2 (junior-dev test: a junior reading this verifies the round-trip semantics from the test alone)
- [ ] **B.8** Test: tap A → scroll to message 5 → pinch back → tap A → scroll position at message 5 (verifies scrollOffset transfer through chatVC bind THEN through handoff capture/apply chain)
  - **Pillar compliance:** P18.20, P19.4 (verifies referential transparency: snapshot → bind → re-capture should produce same value)
- [ ] **B.9** Test: tap A → tap composer (becomes first responder) → pinch back → tap A → composer is first responder again (verifies composerWasFirstResponder roundtrip)
  - **Pillar compliance:** P18.20, P3.2 (junior-dev test verifies edge-case behavior described below)

**Edge case for B.9:** when user pinches back, the composer text field will resign first responder automatically (chatContent.alpha → 0 hides it; before that, the pinch gesture might cause keyboard dismiss). The state controller would capture `composerIsFirstResponder = false`. On re-tap, chatVC is installed; bindTransientState writes `composerTextField.text` but does NOT immediately becomeFirstResponder (because the boolean is false). Correct.

**Edge case clarification for B.9:** if user pinches back WHILE COMPOSER WAS ACTIVE, the keyboard dismisses, the responder resigns. We don't preserve "responder-active" across the round-trip because the gesture itself implies user is going back to cell-list (no editing). This is INTENDED behavior.

### §33.4 — Acceptance criteria

- [ ] `captureTransientState()` returns valid `TransientStateSnapshot` with all four fields
- [ ] `bindTransientState(_:)` writes composerText immediately and scrollOffset on next runloop tick
- [ ] State preserved across round-trip (B.7, B.8 pass)
- [ ] First-responder NOT re-asserted on re-tap (B.9 — false is captured, true is not auto-restored)

---

## §34 — Gap C: `ChatBubbleStackView.configure(with:)` (full trace + sketch)

**Root node:** "A configure method on the new `ChatBubbleStackView` that rebuilds bubbles from a conversation's messages, mirroring `chatVC.rebuildBubbles(from:)` (CVC:119-127) so post-handoff rendering matches pre-handoff."

### §34.1 — Six-question trace (terse — straightforward)

**Q1 (Rests on):** `ChatBubbleView(message:)` initializer (existing, reusable per §16.11); `UIStackView` arrangedSubviews API; `UIScrollView.contentOffset` for scrollToBottom; the conversation's `messages: [Message]` array.

**Q2 (Why):** chatVC's `rebuildBubbles` wipes and re-adds bubbles on every `configure`. cell.chatContent must do the same so the visible bubble state matches at handoff.

**Q3 (Assumes):** ConversationStore is immutable (§16.13) → bubbles are static once built; no diffing or update mechanism needed. Re-create on every configure is acceptable cost (per §8.1 layout profiling).

**Q4 (If changed — diff instead of rebuild):** premature optimization; defer. Diffing would help only for conversations with hundreds of messages plus frequent re-configures, neither of which apply here.

**Q5 (If removed — no configure):** chatContent renders empty bubble stack. User sees header + composer + blank middle. Trivially broken.

**Q6 (Absent):** no per-bubble identity-keyed reuse pool (each configure allocates fresh ChatBubbleView instances); no accessibility identifier per bubble; no scroll-position preservation across configures (handled separately by §4 state transfer).

### §34.2 — Concrete sketch

**`ChatBubbleStackView.swift` (per §11.1):**

```swift
import UIKit

@MainActor
final class ChatBubbleStackView: UIView {

    private(set) var scrollView: UIScrollView
    private(set) var bubbleStack: UIStackView

    override init(frame: CGRect) {
        scrollView = UIScrollView()
        bubbleStack = UIStackView()
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        installSubviews()
        activateConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func installSubviews() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .none
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)

        bubbleStack.axis = .vertical
        bubbleStack.alignment = .fill
        bubbleStack.spacing = 16
        bubbleStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(bubbleStack)
    }

    private func activateConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            bubbleStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            bubbleStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            bubbleStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            bubbleStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            bubbleStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
    }

    func configure(with conversation: Conversation) {
        // Wipe existing
        for bubble in bubbleStack.arrangedSubviews {
            bubbleStack.removeArrangedSubview(bubble)
            bubble.removeFromSuperview()
        }
        // Rebuild
        for message in conversation.messages {
            let bubble = ChatBubbleView(message: message)
            bubbleStack.addArrangedSubview(bubble)
        }
        // Force layout, then scroll to bottom
        layoutIfNeeded()
        DispatchQueue.main.async { [weak self] in
            self?.scrollToBottom(animated: false)
        }
    }

    private func scrollToBottom(animated: Bool) {
        let bottomY = max(0, scrollView.contentSize.height - scrollView.bounds.height)
        scrollView.setContentOffset(CGPoint(x: 0, y: bottomY), animated: animated)
    }
}
```

**Mirrors `ChatViewController`'s structure exactly** (CVC:55-68, 119-135). One-for-one port.

### §34.2.1 — Pillar-compliant authoritative sketch (SUPERSEDES §34.2)

The functional sketch in §34.2 has multiple pillar violations: late-init pattern (`scrollView = UIScrollView()` in init body), no closure-init, separate `installSubviews` + `activateConstraints` setup helpers (Pillar 1.2 explicitly forbids these as Tier-2). The pillar-compliant version uses closure-init at class top.

**Pillar definitions introduced on first use:**

- **P1.2 — Closure-init at class top, NOT in setupX() helpers.** Every property that doesn't need `self` belongs at class-top via `= { ... }()` closure-init. IUOs and setup-X helper methods are Tier-2 patterns; we reject them.

**The pillar-compliant rewrite (`Conversation/ChatBody/ChatBubbleStackView.swift`):**

```swift
import UIKit

// P4.2 final by default | P4.3 @MainActor on UI types | P20.1 one type per file
@MainActor
final class ChatBubbleStackView: UIView {

    // MARK: - Subviews (closure-init at class top per P1.2)

    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.backgroundColor = .clear
        scroll.alwaysBounceVertical = true
        scroll.keyboardDismissMode = .none
        scroll.showsVerticalScrollIndicator = false
        return scroll
    }()

    private let bubbleStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ChatBubbleStackView.bubbleSpacing       // P2.11 named token
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Token (P2.11 magic-number extraction)

    private static let bubbleSpacing: CGFloat = 16

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false       // P10.x always-explicit for programmatic Auto Layout
        installViewHierarchy()
        activateConstraints()
    }

    // P4.2 init?(coder:) refusal — view is code-only, no IB instantiation expected
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("ChatBubbleStackView is code-only; no NSCoder support")
    }

    // MARK: - View hierarchy (single concern; no per-subview setup helpers per P1.2)

    private func installViewHierarchy() {
        addSubview(scrollView)
        scrollView.addSubview(bubbleStack)
    }

    private func activateConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            bubbleStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            bubbleStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            bubbleStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            bubbleStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            bubbleStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
    }

    // MARK: - Configure

    /// Rebuild bubble views from conversation messages.
    /// P19.3 idempotent: calling twice with the same conversation produces
    /// identical view tree (each call wipes-and-rebuilds).
    /// P12.2 tell-don't-ask: caller tells this view to configure; doesn't
    /// reach into bubbleStack to manipulate arrangedSubviews.
    func configure(with conversation: Conversation) {
        wipeBubbles()
        installBubbles(from: conversation.messages)
        layoutIfNeeded()
        scheduleScrollToBottom()
    }

    // MARK: - Configure helpers (P11.1 SRP: each helper has one concern)

    /// Remove all existing bubble views from the stack.
    private func wipeBubbles() {
        for bubble in bubbleStack.arrangedSubviews {
            bubbleStack.removeArrangedSubview(bubble)
            bubble.removeFromSuperview()
        }
    }

    /// Add a `ChatBubbleView` per message.
    private func installBubbles(from messages: [Message]) {           // P16.2 [T] shorthand
        for message in messages {
            bubbleStack.addArrangedSubview(ChatBubbleView(message: message))
        }
    }

    /// Defer scrollToBottom to next runloop tick so contentSize is computed.
    /// P1.10 WHY: scrollView.contentSize is derived from bubbleStack's
    /// intrinsic content, which Auto Layout hasn't computed yet at the moment
    /// configure() returns. Synchronous scroll would clamp to (0,0).
    /// P18.14 [weak self] on escaping closure.
    private func scheduleScrollToBottom() {
        DispatchQueue.main.async { [weak self] in
            self?.scrollToBottom()
        }
    }

    private func scrollToBottom() {
        let bottomY = max(0, scrollView.contentSize.height - scrollView.bounds.height)
        scrollView.setContentOffset(CGPoint(x: 0, y: bottomY), animated: false)
    }

    // MARK: - State controller / handoff access (P5.5 private(set) gating)

    /// Bridge for capture/apply paths. Exposed `private(set)` so external
    /// consumers (state controller, RevealCoordinator handoff) can READ the
    /// scrollView's contentOffset but cannot directly mutate other internals.
    var scrollContentOffset: CGPoint {
        get { scrollView.contentOffset }
        set { scrollView.contentOffset = newValue }       // P8.3 var-justified: round-trip restoration
    }
}
```

**Pillar honors footnote:**

| Member | Pillars honored |
|---|---|
| `scrollView`, `bubbleStack` properties | P1.2 (closure-init at class top), P5.1 (private), P19.5 (let — immutable after init) |
| `bubbleSpacing` token | P2.11 (no literal `16` inline), P5.1 (private), P8.3 (`let`), P20.3 (token in same file, scoped) |
| `init(frame:)` | P11.1 SRP (calls 2 helpers), P10.x (TAMIC=false), P4.2 (final via class declaration) |
| `init?(coder:)` | P4.2 final, P6.5 (`fatalError` for impossible state with WHY message) |
| `installViewHierarchy()` | P11.1 (one concern), P1.2 (not a setupX helper — it's a structural concern) |
| `activateConstraints()` | P11.1, P3.5 (constraints read top-to-bottom following visual order) |
| `configure(with:)` | P19.3 idempotent, P12.2, P11.1 (delegates to 4 helpers) |
| `wipeBubbles()`, `installBubbles(from:)`, `scheduleScrollToBottom()`, `scrollToBottom()` | P11.1 (one concern each), P13.4 (each ≤10 LOC) |
| `scrollContentOffset` computed property | P5.5 (read-via-getter; write via setter; controlled API), P8.3 (var justified) |

**Pillar violations to verify ABSENT:**

- ❌ No IUO (`!`) anywhere — **P1.3 enforced**
- ❌ No `setupX()` helpers that initialize properties — **P1.2 enforced (closure-init at class top)**
- ❌ No magic numbers inline — **P2.11 enforced (bubbleSpacing extracted)**
- ❌ No `var` without justification — **P8.3 enforced (only scrollContentOffset.set, which serves the handoff round-trip contract)**
- ❌ No method >50 LOC — **P13.4 enforced**
- ❌ No silent return without WHY — **P6.7 N/A (no early returns)**

### §34.3 — Concrete tasks (with per-task Pillar compliance + Agent Ensemble)

**Default Agent Ensemble for §34 tasks (Wave 1.2):** `[CO, LE] | [CQR, RCT, SA, DCH, IV, BV] | [WC]` — ContentComposer builds the view; LayoutEngineer owns constraints. Tests dispatched via `[ER]` for empty / N=10 / configure-twice scenarios.

- [ ] **C.1** Create `Conversation/ChatBody/ChatBubbleStackView.swift` per §34.2.1
  - **Pillar compliance:** P4.2 (final), P4.3 (@MainActor), P20.1 (one type per file), P20.2 (file name matches type name), P20.4 (folder = ChatBody concern)
- [ ] **C.2** Implement properties via closure-init at class top per §34.2.1
  - **Pillar compliance:** P1.2 (closure-init, not setupX), P5.1 (private), P19.5 (let where possible — scrollView and bubbleStack are `let`)
- [ ] **C.3** Extract `bubbleSpacing` to a named static constant
  - **Pillar compliance:** P2.11 (magic number extracted), P8.3 (`let`)
- [ ] **C.4** Verify constraints reach `contentLayoutGuide` / `frameLayoutGuide` correctly (Apple's API)
  - **Pillar compliance:** P3.5 (constraint reads top-to-bottom following visual order), P17.5 (anchor labels self-document)
- [ ] **C.5** L3 `@MainActor` concurrency annotation
  - **Pillar compliance:** P9.1 / P4.3 (explicit @MainActor per 9S contract)
- [ ] **C.6** Decompose `configure(with:)` into helpers (`wipeBubbles`, `installBubbles(from:)`, `scheduleScrollToBottom`, `scrollToBottom`) per §34.2.1
  - **Pillar compliance:** P11.1 (each helper one concern), P13.4 (each helper ≤10 LOC), P12.2 (configure tells helpers; helpers act on bubbleStack/scrollView directly)
- [ ] **C.7** Expose `scrollContentOffset` as computed property with get/set per §34.2.1
  - **Pillar compliance:** P5.5 (private(set)-equivalent: getter/setter wraps the private scrollView), P8.3 (var-justified by round-trip contract)
- [ ] **C.8** Test: configure with empty messages array; scrollView.contentOffset stays at (0,0). No crash.
  - **Pillar compliance:** P18.20, P18.10 (boundary case)
- [ ] **C.9** Test: configure with N=10 messages; verify N bubbles in arrangedSubviews after configure.
  - **Pillar compliance:** P18.20, P3.2 (junior-dev test)
- [ ] **C.10** Test: configure twice (same conversation); count of arrangedSubviews equals N (not 2N). Old bubbles correctly removed.
  - **Pillar compliance:** P18.20, P19.3 (verifies idempotency)
- [ ] **C.11** Test: layout completion → scrollToBottom places last bubble visible at viewport bottom.
  - **Pillar compliance:** P18.20, P3.2

### §34.4 — Acceptance criteria

- [ ] `ChatBubbleStackView.configure(with:)` produces bubble count matching `conversation.messages.count`
- [ ] Idempotent across multiple configures (no duplicate bubbles)
- [ ] scrollView.contentOffset at bottom after configure (scrollToBottom)
- [ ] No constraint warnings on layout
- [ ] Build passes after addition

---

## §35 — Gap D: `TimelineCanvas.flushPoolForMemoryPressure()` (full trace + sketch)

**Root node:** "A memory-warning handler on `TimelineCanvas` that evicts non-active cells from `cellPool` + `cellPoolByConversationID` + `poolOrder` to free memory while preserving the currently-active cell and its in-flight state."

### §35.1 — Six-question trace

**Q1 (Rests on):**
- The three pool data structures (TC:47-49): `cellPool: [CellView]`, `cellPoolByConversationID: [UUID: CellView]`, `poolOrder: [UUID]`
- `maxKeyedPoolSize = 20` (TC:51)
- `activeCellIndex` (TC:35) + `instantiatedCells` (TC:39)
- Active-cell-pool-protection (TC:632-636, 800-802) — the invariant that the active cell stays in instantiatedCells regardless of culling
- `UIApplication.didReceiveMemoryWarningNotification` notification
- The eviction sub-routines that already exist for cap-exceeded eviction (TC:843-851)

**Q2 (Why):**
- Per §8.2: 20 cells × ~150-550KB chatContent = up to 11MB committed. Other view-tree state adds more.
- iOS sends memory warning before OOM-killing the app. Responding reduces system stress.
- The user's described scenario (round-trip many conversations, eventually pressure) needs graceful degradation.

**Q3 (Assumes):**
- The active cell MUST NOT be evicted mid-interaction.
- The visible (non-active) cells in `instantiatedCells` MAY be evicted ONLY if they're not currently visible (their re-instantiation cost is paid by `updateVisibleCells` next pan).
- The keyed-pool cells (not currently visible) CAN be aggressively evicted (their re-instantiation pays the configure cost; state is lost).
- Memory warning is a rare event; we don't need it to be cheap.

**Q4 (If changed — evict ALL pool entries including instantiated non-active):**
- Active stays (protected); visible cells removed from instantiatedCells (cells would have to re-instantiate on next pan); state lost across all non-active.
- Aggressive but valid for severe memory pressure.

**Q4 (If changed — selective LRU eviction):**
- Use poolOrder to drop the oldest N keyed entries; keep the most-recent M.
- More surgical; preserves "recently-visited" conversation state.

**Q5 (If removed):**
- App receives memory warning, doesn't respond, system may kill it. User experience: app crashes / restarts.
- **Classification:** DECORATIVE under normal load; LOAD-BEARING under memory pressure.

**Q6 (Absent):**
- No telemetry on actual memory pressure frequency.
- No tunable threshold (current maxKeyedPoolSize=20 is static; could be dynamic based on device class).
- No "second tier" eviction (if memory still high after flush, what next?). UIKit handles by killing the app.

### §35.2 — HOT branches

- **B35.A — Eviction aggressiveness** (evict all non-active vs LRU-bounded eviction). Resolved: aggressive (evict ALL keyed-pool non-active). Memory warning is rare; aggressive response is safer.
- **B35.B — Treatment of unbound cellPool entries** (cells with `activeConversationID == nil`). These have no state to lose. Resolved: evict them all (they're already disposable).
- **B35.C — Treatment of currently-instantiated non-active cells**. These are visible to user (in cell-list pan). Evicting would require re-instantiation on next layoutSubviews. Resolved: KEEP them (more conservative; cells are <100KB without chatContent). chatContent IS on most cells via §1.3; release chatContent ONLY for cells whose conversationID is being evicted from keyed pool.

### §35.3 — Concrete sketch

**`TimelineCanvas.swift` additions:**

```swift
// TimelineCanvas additions (after returnToPool, around TC:852):

/// Respond to memory pressure by aggressively evicting non-active keyed-pool
/// cells. Active cell is protected. Visible (in instantiatedCells) non-active
/// cells are KEPT (their re-instantiation cost on next pan would be visible);
/// pool-resident non-visible cells are evicted along with their chatContent.
///
/// Idempotent: calling under no memory pressure is safe.
func flushPoolForMemoryPressure() {
    let activeID: UUID? = activeCellIndex.flatMap { instantiatedCells[$0]?.activeConversationID }

    // Identify keyed-pool entries to evict (all except active).
    let evictableIDs: [UUID] = poolOrder.filter { $0 != activeID }

    for id in evictableIDs {
        if let cell = cellPoolByConversationID.removeValue(forKey: id) {
            cell.endEditing(true)
            // If chatContent exists on this cell, tear it down (largest memory contribution)
            cell.teardownChatContentForMemoryPressure()
            if let poolIdx = cellPool.firstIndex(where: { $0 === cell }) {
                cellPool.remove(at: poolIdx)
            }
        }
        if let orderIdx = poolOrder.firstIndex(of: id) {
            poolOrder.remove(at: orderIdx)
        }
    }

    // Evict unbound cellPool entries (no state to preserve, no keyed identity)
    cellPool.removeAll { $0.activeConversationID == nil }
}
```

**`CellView.swift` addition (referenced above):**

```swift
// CellView.swift additions:

func teardownChatContentForMemoryPressure() {
    // Distinct from teardownChatContent (which is for cell rebind to different conversation).
    // This is for memory pressure: release the chatContent AND its state controller
    // but keep the cell instance itself in the pool for fast re-bind later.
    chatContentContainer?.teardownCrossViewConstraints()
    chatContentContainer?.removeFromSuperview()
    chatContentContainer = nil
    stateController = nil
}
```

**`V2RootViewController` additions:**

```swift
// In viewDidLoad, alongside other observers (V2:64-69):

NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleMemoryWarning),
    name: UIApplication.didReceiveMemoryWarningNotification,
    object: nil
)

@objc private func handleMemoryWarning() {
    timelineCanvas.flushPoolForMemoryPressure()
}
```

### §35.3.1 — Pillar-compliant authoritative sketch (SUPERSEDES §35.3)

§35.3 functional version uses an intermediate `var toEvict: [UUID]` and inline filter operations. The pillar-compliant rewrite uses pure functional decomposition (P19.1) where possible and clearer SRP boundaries.

**Pillar definitions introduced on first use:**

- **P15.5 — Lava layer.** Multiple generations of patterns coexisting. Cleanup is a substrate concern.
- **P3.3 — Deletion test.** What breaks if I remove this method? "Memory pressure handling" — the answer must be specific.

**The pillar-compliant rewrite (`TimelineCanvas.swift` additions, after `returnToPool`):**

```swift
// MARK: - Memory pressure response

/// Respond to memory pressure by aggressively evicting non-active keyed-pool
/// cells and their attached chatContent containers. Active cell is protected.
/// Currently-instantiated non-active cells are KEPT (their re-instantiation
/// cost on next pan would be visible jank); only pool-resident non-visible
/// cells are released.
///
/// P19.3 idempotent: calling under no memory pressure produces no-op (poolOrder
/// already minimal); calling repeatedly is safe.
/// P11.1 SRP: one concern — memory pressure response.
/// P13.4 ≤30 LOC.
/// P12.2 tell-don't-ask internally — each helper acts on its own concern.
///
/// Pillar honors: P11.1, P12.2, P19.3, P3.3 (deletion test passes: removing
/// breaks memory pressure handling specifically — clean blast radius).
func flushPoolForMemoryPressure() {
    let activeID = activeConversationIDForFlush()
    let evictableIDs = poolOrder.filter { $0 != activeID }    // P19.1 pure transform

    for id in evictableIDs {
        evictKeyedPoolEntry(id: id)
    }

    evictUnboundCellPoolEntries()
}

// MARK: - flushPoolForMemoryPressure helpers (P11.1 SRP per helper)

/// P19.1 pure: derives ID from current activeCellIndex without mutation.
/// P6.6 no sentinel: returns Optional<UUID> rather than a marker value.
private func activeConversationIDForFlush() -> UUID? {
    activeCellIndex.flatMap { instantiatedCells[$0]?.activeConversationID }
}

/// Evict one keyed-pool entry (cell + its chatContent + its stateController).
/// P1.10 WHY: chatContent is the largest memory contribution per cell
/// (~150-550KB); releasing it is the primary memory recovery action.
/// P11.1 SRP: each helper acts on one structure.
private func evictKeyedPoolEntry(id: UUID) {
    guard let cell = cellPoolByConversationID.removeValue(forKey: id) else { return }

    cell.endEditing(true)
    cell.teardownChatContentForMemoryPressure()

    if let poolIdx = cellPool.firstIndex(where: { $0 === cell }) {
        cellPool.remove(at: poolIdx)
    }
    if let orderIdx = poolOrder.firstIndex(of: id) {
        poolOrder.remove(at: orderIdx)
    }
}

/// Evict cellPool entries that have no activeConversationID (no state to preserve).
/// These are "spare" cells the pool was holding pre-emptively.
private func evictUnboundCellPoolEntries() {
    cellPool.removeAll { $0.activeConversationID == nil }
}
```

**`CellView.swift` addition (referenced above):**

```swift
// MARK: - Memory pressure helpers

/// Release chatContent + its state controller to free memory. Distinct from
/// `teardownChatContent` (which is for cell rebind to a different conversation).
/// This is for memory pressure: the cell instance STAYS in the pool for fast
/// re-bind later; only chatContent (the heavy view tree) is released.
///
/// P11.1 SRP, P12.2 (cell mutates its own state).
func teardownChatContentForMemoryPressure() {
    chatContentContainer?.teardownCrossViewConstraints()
    chatContentContainer?.removeFromSuperview()
    chatContentContainer = nil
    stateController = nil
}
```

**`V2RootViewController.swift` additions:**

```swift
// MARK: - Memory pressure observer (in viewDidLoad)

NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleMemoryWarning),                  // P17.5 labeled args
    name: UIApplication.didReceiveMemoryWarningNotification,
    object: nil
)

@objc private func handleMemoryWarning() {                     // P5.1 private
    timelineCanvas.flushPoolForMemoryPressure()                // P12.2 tell-don't-ask
}
```

**Pillar honors footnote:**

| Member | Pillars honored |
|---|---|
| `flushPoolForMemoryPressure()` | P11.1, P12.2, P13.4, P19.3, P3.3 |
| `activeConversationIDForFlush()` | P19.1 pure, P6.6 (Optional return) |
| `evictKeyedPoolEntry(id:)` | P11.1, P1.10 (WHY), P1.1 (guard-with-let) |
| `evictUnboundCellPoolEntries()` | P11.1, P19.1 (closure is pure) |
| `CellView.teardownChatContentForMemoryPressure` | P11.1, P12.2 (cell mutates self), P3.5 (name carries contract) |
| `handleMemoryWarning` | P5.1, P12.2 |

**Pillar violations to verify ABSENT:**

- ❌ No nested loops with side effects mid-iteration — **P13.3 enforced**
- ❌ No silent failure paths — **P6.7 enforced (every guard has explicit fall-through)**
- ❌ No mutation of dict during iteration — **filter pre-builds the eviction set**
- ❌ Method ≤30 LOC each — **P13.4 enforced**

### §35.4 — Concrete tasks (with per-task Pillar compliance + Agent Ensemble)

**Default Agent Ensemble for §35 tasks (Wave 8.3):** `[SE, LS, CR] | [CQR, RCT, SA, DCH, IV, CA-conc, PP] | [WC]` — SubstrateEngineer touches pool internals; LifecycleSurgeon owns the eviction discipline; CompositionRoot wires the observer. PerfProfiler verifies memory reduction post-flush.

- [ ] **D.1** Add `flushPoolForMemoryPressure()` to `TimelineCanvas` per §35.3.1
  - **Pillar compliance:** P11.1 (one concern), P12.2 (delegates to helpers), P13.4 (≤30 LOC), P19.3 (idempotent), P3.3 (deletion test passes)
- [ ] **D.2** Add helpers `activeConversationIDForFlush`, `evictKeyedPoolEntry(id:)`, `evictUnboundCellPoolEntries` per §35.3.1
  - **Pillar compliance:** P11.1 (each helper one concern), P19.1 (activeConversationIDForFlush is pure), P1.1 (guard-chain in evictKeyedPoolEntry), P1.10 (WHY comment on chatContent's memory contribution)
- [ ] **D.3** Add `teardownChatContentForMemoryPressure()` to `CellView`
  - **Pillar compliance:** P11.1 SRP, P12.2 (cell mutates self), P3.5 (name distinguishes from `teardownChatContent` rebind case)
- [ ] **D.4** Wire `UIApplication.didReceiveMemoryWarningNotification` observer in V2RootViewController
  - **Pillar compliance:** P10.2 (mirrors existing willDeactivate observer pattern), P17.5 (labeled API), P5.7 (deinit removeObserver covers it)
- [ ] **D.5** Implement `handleMemoryWarning` to call `flushPoolForMemoryPressure`
  - **Pillar compliance:** P5.1 (private), P12.2 (tells canvas to flush), P11.1 (delegation only)
- [ ] **D.6** Verify active cell is protected: simulate memory warning while activeCellIndex is set; verify the active cell stays in instantiatedCells AND its chatContent remains
  - **Pillar compliance:** P18.20, P18.10 (boundary case: most important invariant — active cell never evicted)
- [ ] **D.7** Verify LRU map / poolOrder remain consistent after eviction (no orphan entries)
  - **Pillar compliance:** P18.20, P3.3 (deletion-test verifier — if orphan exists, downstream lookups fail mysteriously)
- [ ] **D.8** Test on iOS simulator: Hardware → Simulate Memory Warning. Verify cellPool reduces to active-only.
  - **Pillar compliance:** P18.20, P18.16 (app lifecycle / backgrounding-adjacent edge case)
- [ ] **D.9** Verify re-tap on a previously-evicted conversation works (re-instantiation pays configure cost; no crash)
  - **Pillar compliance:** P18.20, P3.2 (junior-dev test: round-trip semantics intuitive from behavior)

### §35.5 — Acceptance criteria

- [ ] After flushPoolForMemoryPressure: cellPoolByConversationID contains AT MOST the active conversation's ID
- [ ] After flushPoolForMemoryPressure: active cell still in instantiatedCells, still has its chatContent + stateController
- [ ] No crashes on simulated memory warning during chat-state or during reverse spring
- [ ] Re-tap on previously-evicted conversation re-instantiates cleanly (no leaked state)

---

## §36 — Gap E: Pinch-commit forward chrome symmetry (full trace + sketch)

**Root node:** "The pinch-commit forward path (`playTapToChatMorph`) currently leaves cell-rest chrome (labelStack, pinchGlyph) frozen at alpha=1 throughout the morph AND does not emerge `chatRestCenterLabel` — asymmetric with tap-forward (`animateCameraToChatRest`) which fades chrome via `performMorphChromeTransition` and emerges the day-marker via `centerLabelOpacity` CABasicAnimation. Resolution: make pinch-commit forward symmetric by invoking `performMorphChromeTransition` from `playTapToChatMorph` with masterTimerDuration as the timing."

### §36.1 — Six-question trace of the root node

**Q1 (Rests on):**
- `MorphChoreographer.apply` (MC:66-85): writes contentHost.transform + heightConstraint + camera. Does NOT touch cell chrome alphas.
- `CellView.setCamera` (CV:253-277): morphInProgress gate (CV:256) early-returns during `MorphChoreographer.isRunning == true`. So per-tick alpha updates are gated off.
- `CellView.performMorphChromeTransition` (CV:317-352): UIView.animate'd chrome fades + CABasicAnimation centerLabelOpacity. Called ONLY from `animateCameraToChatRest` (TC:1307).
- `playTapToChatMorph` (TC:1359-1405): pinch-commit forward path. Sets up cameraAnimator + extensionAnimator (stopped immediately), then engages morphChoreographer. **Does NOT call performMorphChromeTransition.**
- `MorphTiming.masterTimerDuration = 1.2` (DesignSystem/MorphTokens.swift): pinch-commit forward duration.
- `MorphTiming.totalMorphDuration = 1.5` (same file): tap-forward duration.
- `MorphChromeProfile` struct (CV:302-306): `counterScale`, `centerLabelDuration`, `centerLabelBeginTime` — configurable per call.

**Q2 (Why does this asymmetry exist):**
- Historical: pinch-commit was the original forward mechanism. MorphChoreographer was added with the sin-bell Y/Z arc as the cinematography. Chrome fading was NOT included because the cell's chatContent (or whatever rendered post-extension) was expected to dominate.
- Tap-forward was added later with the 4-additive-CABasicAnimation cane curve + `performMorphChromeTransition` for chrome handling.
- The two paths converged on `onMorphRevealReady` → `RevealCoordinator.present`, but the chrome behavior was never unified.
- `morphInProgress` gate in setCamera was added defensively — assumed the choreographer would own chrome — but the choreographer doesn't actually touch chrome. So the gate is OVER-defensive.

**Q3 (Assumes):**
- The user wants visual symmetry between tap-forward and pinch-commit-forward at this level of fidelity.
- The phenomenology described by the user (chrome fading; day-marker emerging during forward) applies to BOTH commit types.
- `performMorphChromeTransition`'s timings (LabelFadeTiming.dateLabelDuration=0.08s, topicSummary=0.17s, todayGlyph=0.20s; total chrome fade ~0.28s) are appropriate for both 1.5s tap and 1.2s pinch-commit durations.

**Q4 (If changed — keep asymmetry):**
- Current behavior: pinch-commit forward leaves cell-rest chrome visible at alpha=1 throughout, no day-marker emerges; chatVC appears via crossFade and its headerLabel is the day-marker.
- User sees DIFFERENT visuals for tap-to-commit vs pinch-to-commit.
- Phenomenologically inconsistent.

**Q4 (If changed — lift morphInProgress gate instead of calling performMorphChromeTransition):**
- Lift the gate (CV:256). setCamera fires per tick during pinch-commit (via applyMorphTickCameraWrite → cell.setCamera). Chrome alphas curve via progress.
- BUT this conflicts with §16.6 / R6 normalize's `setCamera(Camera(translation: cell.frame.midY))` call which refreshes alphas at chat-rest. With gate lifted, alphas curve continuously through pinch-commit; with gate present, they freeze and then jump at handoff. Lifted is smoother.
- BUT this approach does NOT emerge the day-marker — that requires the centerLabelOpacity CABasicAnimation which is only attached by performMorphChromeTransition.
- So lifting the gate solves E1 (chrome fade) but not E2 (day-marker emergence).
- We need BOTH: lift gate (for chrome) AND call performMorphChromeTransition (for day-marker). OR: keep gate and call performMorphChromeTransition (which handles both).
- The latter (keep gate, call PMCT) is more local — only changes playTapToChatMorph.

**Q5 (If removed — accept current asymmetry):**
- Pinch-commit forward visual is poor: cell extends with frozen chrome, no day-marker, then crossFade reveals chatVC.
- Tap-forward visual is the validated reference.
- User-visible difference between the two commits. Inconsistent.
- **Classification:** LOAD-BEARING for phenomenological consistency between forward paths. DECORATIVE for handoff functionality (handoff works either way).

**Q6 (Absent):**
- No timing recalibration for the 1.2s pinch-commit vs 1.5s tap. LabelFadeTiming values are tuned for tap.
- No verification that performMorphChromeTransition is safe to call mid-`playTapToChatMorph` (when MorphChoreographer is already running).
- No CABasicAnimation cleanup if pinch-commit is interrupted mid-morph (e.g., user re-pinches) — though MorphChoreographer.stop() probably handles this indirectly.

### §36.2 — Two sub-traces

**E1 — Should chrome (labelStack, pinchGlyph) fade during pinch-commit?**

Resolution: YES. Two implementation paths:
- (i) Lift `morphInProgress` gate in CellView.setCamera so per-tick alpha curves fire.
- (ii) Call `performMorphChromeTransition` from `playTapToChatMorph`.

Pick (ii): more localized change; mirrors tap-forward pattern.

**E2 — Should chatRestCenterLabel emerge during pinch-commit?**

Resolution: YES. `performMorphChromeTransition` attaches `centerLabelOpacity` CABasicAnimation which animates `chatRestCenterLabel.alpha` 0→1. Calling PMCT from playTapToChatMorph achieves this AS A BYPRODUCT of E1's path.

**Both sub-decisions resolved by ONE change:** call `performMorphChromeTransition` from `playTapToChatMorph`.

### §36.3 — Concrete sketch

**Modification to `playTapToChatMorph` (TC:1359-1405):**

Add the following after `setActiveCellIndex(k)` line and before `morphChoreographer.engage(...)`:

```swift
// In playTapToChatMorph, after `pinchRecognizer.isEnabled = false` (TC:1364) and BEFORE engage:

let chromeProfile = CellView.MorphChromeProfile(
    counterScale: 1.0 / chatRestFactor,           // matches tap-forward's counter-scale
    centerLabelDuration: MorphTiming.masterTimerDuration,  // 1.2s (vs 1.5s for tap)
    centerLabelBeginTime: CACurrentMediaTime()
)
activeCell.performMorphChromeTransition(profile: chromeProfile)
```

Then continue with the existing morphChoreographer.engage call.

**Why this is sufficient:**
- `performMorphChromeTransition` (CV:317-352) starts UIView.animate'd chrome fades (label-stack components fade 1→0 over 0.08s, 0.17s, 0.20s respectively). These fire IN PARALLEL with the morphChoreographer's per-tick updates.
- It attaches the `centerLabelOpacity` CABasicAnimation that drives chatRestCenterLabel.alpha 0→1 over centerLabelDuration (= 1.2s for pinch-commit).
- These animations are INDEPENDENT of the morphInProgress gate — they're UIView.animate/CABasicAnimation, not per-tick setCamera writes.
- After the morph completes at T=1.2s, normalize (per §16.10) will:
  - Remove the held centerLabelOpacity animation (centerLabelOpacity model alpha = 0 already; presentation = 1; removeAnimation → presentation = model = 0). ✓ chatRestCenterLabel disappears in normalize.
  - Drive setCamera (refresh chrome alphas). At progress=1, labelStack.alpha = 0 (already 0 from UIView.animate; no change). pinchGlyph.alpha = 0 (already 0). chatRestAffordance.alpha = 1 (per §21).

**The asymmetry is resolved without changing morphInProgress gate or normalize logic.**

### §36.3.1 — Pillar-compliant authoritative sketch (SUPERSEDES §36.3)

§36.3's sketch is small (one PMCT call inside playTapToChatMorph) — pillar compliance is mostly about WHERE to insert and the surrounding interrupt-reset code from §36.5 E.10-E.15.

**Pillar definitions introduced on first use:**

- **P10.2 — Predictability.** Similar problems solved similarly. Pinch-commit's chrome handling should mirror tap-forward's exactly.

**The pillar-compliant modification (`TimelineCanvas.playTapToChatMorph`, after line ~1364 `pinchRecognizer.isEnabled = false`):**

```swift
// Insert AFTER `pinchRecognizer.isEnabled = false` and BEFORE the cameraAnimator
// setup. Mirrors animateCameraToChatRest's PMCT invocation (TC:1307) for
// chrome-fade + day-marker emergence symmetry between forward paths.
// P10.2 predictability: same problem solved the same way as tap-forward.
// P2.11: centerLabelDuration token from MorphTiming (1.2s for pinch-commit
// vs 1.5s for tap; both come from the same token namespace).

let chromeProfile = CellView.MorphChromeProfile(
    counterScale: 1.0 / chatRestFactor,                          // P17.5 labeled args
    centerLabelDuration: MorphTiming.masterTimerDuration,        // P2.11 named token
    centerLabelBeginTime: CACurrentMediaTime()
)
activeCell.performMorphChromeTransition(profile: chromeProfile)  // P12.2 tell-don't-ask
```

**Interrupt-reset additions (`handlePinchBegan`, after the existing `morphChoreographer.stop() / cameraAnimator.stop() / extensionAnimator.stop()` calls):**

```swift
// Interrupt safety per §36.5 E.12: chrome fades and centerLabelOpacity
// CABasicAnimation from a prior pinch-commit must be cancelled before
// the new pinch's chrome reset takes effect. Without these removeAllAnimations
// calls, the prior animation's "held" final value (alpha=0) would persist
// as the model layer value even after we set alpha=1.
//
// P10.x cancellation discipline | P1.10 WHY comment.
if let anchorIdx = anchorCellIdx, let activeCell = instantiatedCells[anchorIdx] {
    CATransaction.withSuppressedActions {
        // P1.1 guard-chain implicit: only one outer if-let pair
        activeCell.dateLabel.layer.removeAllAnimations()
        activeCell.topicSummaryLabel.layer.removeAllAnimations()
        activeCell.todayLabel.layer.removeAllAnimations()
        activeCell.pinchGlyph.layer.removeAllAnimations()
        activeCell.chatRestCenterLabel.layer.removeAllAnimations()

        activeCell.dateLabel.alpha = 1
        activeCell.topicSummaryLabel.alpha = 1
        activeCell.todayLabel.alpha = 1
        activeCell.pinchGlyph.alpha = 1
        activeCell.chatRestCenterLabel.alpha = 0           // semantic: hidden at cell-rest
        activeCell.chatRestAffordance.alpha = 0            // §21 affordance hidden at cell-rest
    }
}
```

**Pillar honors footnote:**

| Site | Pillars honored |
|---|---|
| PMCT call in `playTapToChatMorph` | P10.2 (predictability with tap-forward), P12.2, P17.5, P2.11 (named tokens), P1.10 (WHY comment) |
| Interrupt-reset in `handlePinchBegan` | P10.x (cancellation discipline), P1.10 (WHY comment), P1.1 (single guard-let), P12.2 (cell sets its own alphas after we explicitly removeAllAnimations) |

**Pillar violations to verify ABSENT:**

- ❌ No magic 1.2 inline — **P2.11 enforced (MorphTiming.masterTimerDuration)**
- ❌ No nested guards in interrupt-reset — **P13.3 enforced**
- ❌ All animation cancellation wrapped in suppressed CATransaction — **CLAUDE.md 2.1 enforced**

### §36.4 — Concrete tasks (with per-task Pillar compliance + Agent Ensemble)

**Default Agent Ensemble for §36 tasks (Wave 8.4 + Wave 8.5):** `[CC, CA, GM] | [CQR, RCT, SA, DCH, IV, BV, VR] | [WC]` — ChoreographyComposer extends playTapToChatMorph with PMCT call; ChromeArtist owns chrome alpha refresh; GestureMechanic handles handlePinchBegan interrupt reset. VR verifies tap vs pinch-commit visual symmetry.

- [ ] **E.1** Modify `TimelineCanvas.playTapToChatMorph` (TC:1359-1405) to call `performMorphChromeTransition` per §36.3 sketch
- [ ] **E.2** Verify the call site: inserted AFTER `setActiveCellIndex(k)` (so cell is identified as active) and BEFORE `morphChoreographer.engage(choreo) { ... }` (so chrome animations start at the same moment as the morph)
- [ ] **E.3** Verify `MorphChromeProfile.centerLabelDuration` parameter: pass `MorphTiming.masterTimerDuration` (1.2s) instead of `MorphTiming.totalMorphDuration` (1.5s) so the day-marker emerges over the pinch-commit's actual duration
- [ ] **E.4** Visual verification: pinch-out commit on a cell. Verify chrome fades AND chatRestCenterLabel emerges during the 1.2s morph (matching tap-forward visual structure).
- [ ] **E.5** Empirical: compare pinch-commit and tap-commit side-by-side via screen recording. Confirm visual symmetry.
- [ ] **E.6** Edge case: pinch-commit interrupted by another pinch begin mid-morph. Verify `MorphChoreographer.stop()` (which is called by handlePinchBegan via cameraAnimator.stop / extensionAnimator.stop / morphChoreographer.stop — TC:1022-1024) does NOT leave the UIView.animate fades or centerLabelOpacity CABasicAnimation orphaned.
  - Specifically: `performMorphChromeTransition` uses UIView.animate with `.allowUserInteraction`. These animations continue independently of morphChoreographer. On interrupt, they continue to their target alpha=0. After interrupt, chrome stays at alpha=0 even though the new pinch may want it back at alpha=1. Could be visible as "chrome briefly invisible during new pinch."
  - **Mitigation:** at handlePinchBegan (TC:1021-1052), after morphChoreographer.stop(), also call `activeCell.resetMorphState()` (CV:281-285) which is currently invoked from returnToPool. NEW: extend resetMorphState to ALSO cancel in-flight UIView.animate chrome fades. UIView.animate doesn't have a per-animation cancel; need `dateLabel.layer.removeAllAnimations()` per chrome element. Or use animator instead of animate.
  - **Alternative simpler mitigation:** at handlePinchBegan, immediately reset chrome alphas to current `setCamera`-driven values (per progress). This is what `lifting the morphInProgress gate` achieves naturally.

  **Recommendation:** lift the `morphInProgress` gate as a SECONDARY mitigation specifically for the pinch-begin interrupt case. After lifting, setCamera fires on next gesture event and resets chrome alphas based on progress. Visible chrome state is then consistent.

  Re-decide E1 path: lift gate AND call PMCT in playTapToChatMorph. Lifting gate handles interrupt case; PMCT handles forward path's day-marker emergence.

- [ ] **E.7** Lift the `morphInProgress` early-return in `CellView.setCamera` (CV:256):
  - Remove the guard `if morphInProgress { return }`.
  - Add justification comment: "Lifted to allow setCamera to track gesture-velocity-driven chrome alpha during pinch-commit forward AND to recover chrome alpha after morph interruption."
- [ ] **E.8** Verify interaction between PMCT-driven UIView.animate'd chrome fades and setCamera-driven progress-based chrome alphas during pinch-commit:
  - PMCT writes chrome alphas via UIView.animate (duration 0.08-0.20s); these go from 1 to 0 over the early morph.
  - setCamera writes chrome alphas via smoothstep curve based on progress; at progress=0 alpha=1, progress=0.30 alpha=0.
  - Both targets converge to 0 (UIView.animate at T=0.20s, setCamera at progress=0.30 which is T=0.36s of pinch-commit's 1.2s).
  - During mid-fade, BOTH are writing alpha. Conflict.
  - **Resolution:** the LAST write wins per frame. setCamera fires on the master CADisplayLink (120Hz); UIView.animate also fires on each frame via Core Animation. UIView.animate writes are model layer; setCamera writes are model layer (per CV:266). Last write wins.
  - At any given frame T:
    - PMCT's UIView.animate is at fraction (T / fadeDuration) of 1→0. UIView.animate sets alpha = 1 - smoothEase(T / 0.08) for dateLabel etc.
    - setCamera computes progress and writes alpha = 1 - smoothstep(0.05, 0.30, progress).
  - At T=0.15s of pinch-commit: progress = 0.15/1.2 ≈ 0.125. smoothstep(0.05, 0.30, 0.125) ≈ 0.3. setCamera writes dateLabel.alpha = 1 - 0.3 = 0.7. UIView.animate has dateLabel.alpha at ~0 (PMCT finished date fade by 0.08s). setCamera OVERWRITES to 0.7. Visible "chrome reappears partially" during the morph.

  **This is bad.** PMCT and setCamera fight each other.

  **Better resolution:** don't lift the gate; rely on PMCT alone for chrome fades during pinch-commit; setCamera doesn't fire during pinch-commit. (Original gated design.)

  But then the INTERRUPT case (Q6 / §36.4 E.6 edge case) isn't handled — chrome stays at alpha=0 after interrupted pinch-commit.

  Alternative resolution: at handlePinchBegan, explicitly reset chrome to alpha=1 if it had been mid-fade. Code:
  ```swift
  // In handlePinchBegan, after morphChoreographer.stop():
  if let activeIdx = anchorCellIdx, let activeCell = instantiatedCells[activeIdx] {
      // Reset chrome alphas to cell-rest values (alpha=1) defensively
      CATransaction.withSuppressedActions {
          activeCell.dateLabel.alpha = 1
          activeCell.topicSummaryLabel.alpha = 1
          activeCell.todayLabel.alpha = 1
          activeCell.pinchGlyph.alpha = 1
          activeCell.chatRestCenterLabel.alpha = 0
          activeCell.chatRestAffordance.alpha = 0  // per §21
      }
  }
  ```
  Plus cancel any in-flight animations on these views' layers:
  ```swift
      activeCell.dateLabel.layer.removeAllAnimations()
      activeCell.topicSummaryLabel.layer.removeAllAnimations()
      activeCell.todayLabel.layer.removeAllAnimations()
      activeCell.pinchGlyph.layer.removeAllAnimations()
      activeCell.chatRestCenterLabel.layer.removeAllAnimations()
  ```

- [ ] **E.9** **Refined approach: KEEP morphInProgress gate. ADD `performMorphChromeTransition` call in playTapToChatMorph. ADD chrome reset on pinch-begin interrupt.** This is the cleanest.

### §36.5 — Refined concrete tasks (replaces E.1-E.8)

- [ ] **E.10** In `TimelineCanvas.playTapToChatMorph` (TC:1359-1405), insert `performMorphChromeTransition` call before `morphChoreographer.engage(...)` per §36.3.1
  - **Pillar compliance:** P10.2 (predictability — mirrors tap-forward's PMCT invocation at TC:1307), P12.2 (canvas tells cell to perform chrome transition), P17.5 (labeled args in profile init), P2.11 (named tokens via MorphTiming)
- [ ] **E.11** Keep `morphInProgress` gate in CellView.setCamera unchanged (CV:256) per D19
  - **Pillar compliance:** P11.1 (one ownership: PMCT owns chrome alphas during pinch-commit; setCamera defers), P10.x (gated mutation discipline), P3.3 (deletion test: removing the gate causes alpha thrashing per §36.4 E.8 analysis)
- [ ] **E.12** In `TimelineCanvas.handlePinchBegan` (TC:1021-1052), AFTER existing animator stops, add defensive chrome reset per §36.3.1 interrupt-reset block
  - **Pillar compliance:** P10.x (cancellation discipline: every removeAllAnimations is the cleanup), P1.1 (single guard-let), P1.10 (WHY comment on the discipline), CLAUDE.md §2.1 (suppressed CATransaction wraps all chrome writes)
- [ ] **E.13** Visual verification: tap-commit and pinch-commit side-by-side — chrome fades identically; day-marker emerges identically (modulo duration: 1.5s for tap vs 1.2s for pinch-commit)
  - **Pillar compliance:** P18.20 (test coverage), P10.2 (verifies symmetry achieved)
- [ ] **E.14** Interrupt verification: trigger pinch mid-pinch-commit; verify chrome resets cleanly with no visible flicker
  - **Pillar compliance:** P18.20, P18.10 (boundary case — gesture interruption is the highest-risk edge)
- [ ] **E.15** Round-trip verification: chat-state → reverse → cell-rest → tap-forward → chat-state. Chrome animations fire cleanly each time. centerLabelOpacity CABasicAnimation re-attaches on second forward (because resetMorphState in returnToPool removed it after reverse).
  - **Pillar compliance:** P18.20, P19.3 (verifies idempotency across round-trips)

### §36.6 — Acceptance criteria

- [ ] Pinch-commit forward visually mirrors tap-forward's chrome behavior (date/topic/today/glyph fade out within 0.28s; day-marker emerges over 1.2s)
- [ ] Tap-commit forward unchanged (already worked; performMorphChromeTransition still called from animateCameraToChatRest)
- [ ] Pinch-begin interrupt resets chrome cleanly (no stuck-at-alpha-0)
- [ ] Round-trip behavior intact (centerLabelOpacity attaches on each new forward)
- [ ] No constraint warnings; no animation orphaning (Instruments leak check)

---

## §37 — Gap F: `keyboardLayoutGuide` decision (full trace + D18)

**Root node:** "ChatVC's composerContainer is anchored to `view.safeAreaLayoutGuide.bottomAnchor - 12` (CVC:108). safeAreaLayoutGuide does NOT auto-track keyboard. When the keyboard appears, the composer is hidden behind it. Decide: accept existing behavior in V1 (matches chatVC's current UX issue but maintains forward-visual-parity at handoff), or upgrade BOTH chatVC and cell.chatContent to use `keyboardLayoutGuide.topAnchor`."

### §37.1 — Six-question trace

**Q1 (Rests on):**
- chatVC.composerContainer.bottomAnchor constraint (CVC:108): `view.safeAreaLayoutGuide.bottomAnchor, constant: -12`
- iOS 15+ `UIView.keyboardLayoutGuide` API (auto-tracks keyboard frame intersection with the view)
- The handoff requirement that cell.chatContent's composer match chatVC.composer position pixel-perfectly at the swap moment

**Q2 (Why):**
- Apple HIG and iOS 15+ convention: interactive elements (composer text fields) should stay visible above the keyboard. The `keyboardLayoutGuide.topAnchor` was added to make this trivial.
- Current chatVC predates this update OR was written without using it; result: composer hidden when keyboard up.
- For cell.chatContent (per §3.5), constraints replicate chatVC's behavior. If chatVC's composer is at safeArea.bottom-12, chatContent's composer is too. Forward-visual-parity ✓ at the swap; but BOTH have the keyboard-overlap UX issue.

**Q3 (Assumes):**
- The user's described phenomenology video doesn't show keyboard active (we have no evidence either way about whether keyboardLayoutGuide-style behavior is required).
- Forward-visual-parity at handoff is the higher priority than keyboard-tracking polish.
- Upgrading both chatVC and cell.chatContent simultaneously is feasible (~5 LOC each).

**Q4 (If changed — upgrade both to keyboardLayoutGuide):**
- chatVC.composerContainer.bottomAnchor → `view.keyboardLayoutGuide.topAnchor - 12`
- cell.chatContent.composer.bottomAnchor → `parentVC.view.keyboardLayoutGuide.topAnchor - 12`
- When keyboard appears, composer rides above keyboard. Better UX.
- Forward-visual-parity at handoff PRESERVED (both views use the same anchor; same position).
- Risk: keyboardLayoutGuide intersects with the view's bounds; if chatVC.view extends below screen edge (it doesn't; pinned-to-superview), keyboard tracking might behave unexpectedly. Low risk.

**Q5 (If removed — accept current behavior):**
- Known UX issue: composer hidden when keyboard up.
- User must manually scroll the bubble stack to see what they're typing (scrollView.keyboardDismissMode = .none per CVC:59, so the keyboard stays up).
- Forward-visual-parity at handoff still holds (both have the issue).
- Defer fix to future iteration when user explicitly notes the keyboard issue.

**Q6 (Absent):**
- No decision-log entry currently records acceptance.
- No empirical test of keyboard behavior (we ASSUME composer is hidden; not empirically verified — possible the existing scrollView's adjustedContentInset or other mechanism handles it).

### §37.2 — D18 decision

**D18: Accept current behavior (`safeAreaLayoutGuide`-anchored composer) in V1.** Defer keyboardLayoutGuide upgrade to a future iteration when:
- (i) user explicitly notes the keyboard-overlap behavior is problematic, OR
- (ii) usability testing surfaces it as a P0 issue, OR
- (iii) the message-sending feature (P2 / §22) lands and active typing becomes a common interaction.

**Rationale:**
- Current behavior is consistent (both chatVC pre-handoff and cell.chatContent post-handoff have the same composer position).
- Forward-visual-parity is preserved.
- Upgrade is non-invasive (~10 LOC across both views) when needed later.
- The user's described phenomenology video does not exhibit keyboard interaction; no evidence the user requires the upgrade now.

### §37.3 — Future upgrade path (preserved for re-engagement)

When user requests the upgrade:

**`ChatViewController.swift` change (CVC:108):**
```swift
// BEFORE:
composerContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),

// AFTER:
composerContainer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -12),
```

**`ChatContentContainer.swift` change (§1.2 sketch):**
```swift
// BEFORE:
composer.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -12)

// AFTER (still uses parentView; switch from safeArea.bottomAnchor to parentView.keyboardLayoutGuide.topAnchor):
composer.bottomAnchor.constraint(equalTo: parentView.keyboardLayoutGuide.topAnchor, constant: -12)
```

Both anchors return the same value when keyboard is dismissed (safeArea.bottom == keyboardLayoutGuide.top); they differ only when keyboard is up. So forward-visual-parity at handoff is preserved either way (both states are equivalent when keyboard is dismissed during the morph; only differ during composer interaction).

### §37.4 — Concrete tasks (V1 — current scope)

- [ ] **F.1** Record D18 in §14 decision log
- [ ] **F.2** Update §3.5 / §3.13 / §16.19 to reference D18 as the canonical decision
- [ ] **F.3** Document the upgrade path (§37.3) in §18 long-term enablement as a future capability

### §37.5 — Acceptance criteria

- [ ] D18 entry in decision log (§14 / §26 / §40)
- [ ] No code changes in V1 (existing chatVC behavior + cell.chatContent matching behavior)
- [ ] User can revisit this decision when relevant

---

## §38 — Gap G: Phase 0 verification playbook

**Root node:** "Phase 0 has 12 empirical questions (Q1-Q12 across §17 / §21.7 / §23.7). Each requires a specific verification method, a success/failure threshold, and a recorded answer. This section is the playbook for actually running Phase 0."

### §38.1 — Six-question trace (terse)

**Q1 (Rests on):** the existing simulator + iPhone hardware testbed; the ability to add temporary logs; the ability to read print output.

**Q2 (Why):** Phase 0 questions block downstream design decisions (e.g., Q1 safe area gates Strategy A/B; Q3 cancelInFlight gates §32 recovery design). Without answers, downstream work proceeds on assumption.

**Q3 (Assumes):** the verifications can be done on iPhone 16 simulator (project default per CLAUDE.md xcodebuild example) AND iPad simulator (for rotation Q if iPad in scope). Each verification takes <30 min if methodology is clear.

**Q4 (If skipped — assume defaults are right):** downstream work proceeds; some downstream tasks may turn out to be wrong-direction; rework cost > Phase 0 cost.

**Q5 (If removed):** see Q4; bad-bet engineering.

**Q6 (Absent):** no automated regression tests for the empirical findings (e.g., if Q1 finds safeAreaInsets match, no test ensures they continue to match in future iOS versions).

### §38.2 — Per-question playbook

Each question has: **method**, **success criterion**, **failure response**, **record location**.

#### Q1 — Safe area divergence (§3.2)

- **Question:** does `cell.safeAreaInsets.top` after normalize match `chatVC.view.safeAreaInsets.top`?
- **Method:** add `print` to `CellView.layoutSubviews` and `ChatViewController.viewDidLayoutSubviews`:
  ```swift
  // In CellView, override layoutSubviews:
  override func layoutSubviews() {
      super.layoutSubviews()
      if let window = window, bounds.height > 800 {  // only at chat-rest
          print("CellView safeAreaInsets:", safeAreaInsets, "frame in window:", convert(bounds, to: window))
      }
  }
  // In ChatViewController, override viewDidLayoutSubviews:
  override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
      print("ChatVC safeAreaInsets:", view.safeAreaInsets, "frame in window:", view.convert(view.bounds, to: view.window))
  }
  ```
- **Trigger:** tap a cell; wait for normalize (T=2.1s); inspect logs at handoff (T=2.8s).
- **Success criterion:** `cell.safeAreaInsets.top` differs from `chatVC.view.safeAreaInsets.top` by ≤1pt.
- **Failure response:** Strategy A (cross-view constraints) is REQUIRED; alternatives (Strategy B additionalSafeAreaInsets) are insufficient. Document divergence amount; potentially additionalSafeAreaInsets correction needed.
- **Record location:** §14 Decision log as "D-Phase0-Q1: safe area divergence empirically = X pt"

#### Q2 — Theme.Page.surface vs Theme.Cell.fill equality (§3.4)

- **Question:** are these two Theme constants the same color value?
- **Method:** add to V2RootVC.viewDidLoad:
  ```swift
  print("Theme.Page.surface:", Theme.Page.surface.cgColor.components ?? [])
  print("Theme.Cell.fill:", Theme.Cell.fill.cgColor.components ?? [])
  ```
- **Trigger:** launch app.
- **Success criterion:** components arrays are equal element-wise.
- **Failure response:** explicitly set `chatContent.backgroundColor = Theme.Page.surface` (matching chatVC.view's background) in ChatContentContainer.init.
- **Record location:** §14 Decision log entry.

#### Q3 — RevealCoordinator.cancelInFlight completion behavior (§16.9)

- **Question:** does `blurFadeOut.addCompletion`'s closure fire when `cancelInFlight` calls `finishAnimation(at: .current)`?
- **Method:** add temporary print to blurFadeOut.addCompletion's closure (RC:93-100):
  ```swift
  blurFadeOut.addCompletion { [weak self] position in
      print("blurFadeOut completion fired with position:", position)
      // ... existing code ...
  }
  ```
- **Trigger:** tap cell, then between T=2.1s and T=2.7s, programmatically trigger scene deactivation (or simulate via Home button on simulator).
- **Success criterion:** print fires with position == .current.
- **Failure response (no completion fires):** §32 recovery design is mandatory; partial state needs reactive handling.
- **Success response (completion fires with .current):** existing code's `if position == .end` filter skips handoff cleanup → recovery still needed.
- **Record location:** §14 Decision log; updates §32's recovery design.

#### Q4 — UIView.hitTest alpha threshold (§16.15)

- **Question:** is the alpha=0.01 threshold for hitTest correct on iOS 18+?
- **Method:** place a tap detector behind an alpha=0.005 view. Tap the area. Verify the detector receives the tap.
- **Trigger:** debug test in app or simple UIKit playground.
- **Success criterion:** alpha=0.005 view does NOT absorb taps; alpha=0.05 view DOES absorb taps.
- **Failure response:** §16.15's hit-test analysis is wrong; some chrome elements (labelStack, pinchGlyph, chatRestCenterLabel) may absorb taps post-handoff. Need to set `isUserInteractionEnabled = false` on each chrome element at chat-rest progress.
- **Record location:** §14.

#### Q5 — pushCameraToVisibleCells during normalize (§17 Q5)

- **Question:** does normalize's `setCamera(Camera(translation: cell.frame.midY))` correctly refresh cell chrome alphas (pinch-commit case from §16.6)?
- **Method:** assert in normalize:
  ```swift
  // At end of normalizeToChatRest:
  assert(!cell.morphInProgress, "normalize fired while morphInProgress=true")
  ```
  AND add log:
  ```swift
  print("Post-normalize chrome:",
        "labelStack.alpha=\(cell.labelStack.alpha)",
        "pinchGlyph.alpha=\(cell.pinchGlyph.alpha)",
        "chatRestCenterLabel.alpha=\(cell.chatRestCenterLabel.alpha)",
        "chatContent.alpha=\(cell.chatContentContainer?.alpha ?? -1)")
  ```
- **Trigger:** pinch-commit forward via gesture; wait for normalize.
- **Success criterion:** labelStack.alpha == 0, pinchGlyph.alpha == 0, chatRestCenterLabel.alpha == 0, chatContent.alpha == 1.
- **Failure response:** investigate which curve in setCamera isn't firing or computing correctly.
- **Record location:** §14.

#### Q6 — Tap recognizer firing under chat-state (§16.8)

- **Question:** does V2RootVC.handleTap fire when user taps composer text field at chat-state?
- **Method:** add log to handleTap:
  ```swift
  @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
      print("V2RootVC.handleTap fired; activeCellIndex=\(timelineCanvas.activeCellIndex.map(String.init) ?? "nil")")
      // ... existing code ...
  }
  ```
- **Trigger:** tap cell, wait for handoff, then tap composer.
- **Success criterion:** handleTap log fires AND `activeCellIndex` is non-nil → the new guard (per §16.8 / Phase 6 / R12) correctly returns early.
- **Failure response:** if handleTap fires AND guard doesn't return early, fix guard. If handleTap doesn't fire at all (touches absorbed elsewhere), confirm assumption is wrong; revisit §16.8.
- **Record location:** §14.

#### Q7 — SF Symbol availability (§21.7)

- **Question:** does `UIImage(systemName: "arrow.down.right.and.arrow.up.left")` return a non-nil image on iOS 18?
- **Method:** add to V2RootVC.viewDidLoad:
  ```swift
  if let symbol = UIImage(systemName: "arrow.down.right.and.arrow.up.left") {
      print("SF Symbol arrow.down.right.and.arrow.up.left: AVAILABLE")
  } else {
      print("SF Symbol arrow.down.right.and.arrow.up.left: NOT AVAILABLE")
  }
  ```
- **Trigger:** launch app on iPhone 16 simulator (iOS 18).
- **Success criterion:** AVAILABLE.
- **Failure response:** test fallbacks `"arrow.up.left.and.arrow.down.right.circle"`, `"arrow.down.forward.and.arrow.up.backward"`, `"rectangle.compress.vertical"`. Pick the first one that's available and matches visual intent.
- **Record location:** §14 + final symbol identifier in SymbolName.swift.

#### Q8 — Visual rhyme check (§21.7)

- **Question:** does the inward affordance at top-left visually balance the outward at bottom-right at mid-morph?
- **Method:** screen recording at chat-rest, cell-rest, and mid-progress. Visual inspection.
- **Success criterion:** subjective — affordances feel balanced / not lopsided.
- **Failure response:** adjust position (e.g., chatRestAffordance to bottom-left instead, mirroring pinchGlyph's diagonal).
- **Record location:** §14 if position changes.

#### Q9 — Discoverability test (§21.7)

- **Question:** do users discover the pinch-to-collapse gesture with the affordance visible?
- **Method:** out-of-scope for V1 verification (requires user research).
- **Resolution:** defer.

#### Q10 — m34 propagation depth (§23.7)

- **Question:** does Z-translation on `chatContent.layer` actually engage m34 perspective foreshortening?
- **Method:** in V2RootVC, immediately after a tap commits to chat-rest (post-handoff), set test transform:
  ```swift
  // Temp test: after tap handoff completes, in handleSceneDidActivate or similar trigger
  if let cell = timelineCanvas.instantiatedCells[0],
     let chatContent = cell.chatContentContainer {
      chatContent.layer.transform = CATransform3DMakeTranslation(0, 0, 500)
  }
  ```
- **Trigger:** post-handoff at chat-state.
- **Success criterion:** chatContent appears SMALLER (foreshortened) — apparent scale ~0.67 (= 1000/1500).
- **Failure response:** m34 isn't propagating; investigate sublayerTransform chain; §23 design may need amendment (e.g., set m34 on each level of sublayerTransform).
- **Record location:** §14.

#### Q11 — Z magnitude calibration (§23.7)

- **Question:** what Z_MAX feels right for the recession effect?
- **Method:** sequentially test Z_MAX = 700, 900, 1500 on a real device via screen recording.
- **Success criterion:** subjective — picks the magnitude that matches user's "fading-into-illegibility" framing.
- **Failure response:** if none feel right, sin-bell Z arc may be needed (per §23.3 option c).
- **Record location:** §14 + the Z_MAX constant in CellView.setCamera.

#### Q12 — Interaction with horizontal-inset adjustment (§23.7)

- **Question:** does the simultaneous constraint update (CV:272-276) plus chatContent.layer.transform.translation.z write produce clean visuals (no flicker, no conflict)?
- **Method:** during reverse direction, log both effects per setCamera tick:
  ```swift
  print("Reverse tick: progress=\(progress), leadingC.constant=\(leadingC.constant), chatContent.transform.z=\(z)")
  ```
- **Trigger:** reverse direction via pinch.
- **Success criterion:** smooth visual progression; no jitter.
- **Failure response:** if jitter, investigate timing; possibly batch both writes in same CATransaction.
- **Record location:** §14.

### §38.3 — Phase 0 sequencing

Recommend running questions in dependency order:
1. **Q7** (SF Symbol availability) — gates P9 affordance work
2. **Q2** (Theme colors) — gates §3.4 / chatContent.backgroundColor decision
3. **Q1** (Safe area) — gates Strategy A/B decision; impacts §3.3, §3.5
4. **Q4** (hitTest alpha) — gates §16.15 confirmation; impacts §6 hit-test analysis
5. **Q10** (m34 propagation) — gates P10 distance-fade upgrade
6. **Q11** (Z magnitude) — comes AFTER Q10 confirms m34 works
7. **Q3** (cancelInFlight completion) — gates §32 recovery design
8. **Q5** (normalize alpha refresh) — verifies §16.6 fix; can run after P5
9. **Q6** (tap recognizer firing) — verifies §16.8 guard works
10. **Q12** (horizontal-inset + Z interaction) — verifies P10 doesn't conflict with existing curve
11. **Q8** (visual rhyme) — needs P9 + P10 implemented to evaluate
12. **Q9** (discoverability) — DEFERRED for user research

Phases 1-7 can mostly run in parallel; 11-12 are gated on later phases.

### §38.4 — Phase 0 estimate

Per-question time:
- Q1-Q7: ~30 min each (simple log + screen recording)
- Q10-Q12: ~45 min each (more complex Z calibration)
- Q8 (visual rhyme): ~30 min
- Total: ~5-6 hours of focused work + iteration time

**Realistic Phase 0 estimate: 1-2 days** (was 1-2 in §12; this confirms; user-facing was upgraded to 3-5 in honest audit due to potential iteration on Q11). Tighter than my earlier 3-5 estimate IF the methodology is clear (which §38.2 now provides). Re-baseline: **2-3 days** (allows for iteration on Q11 + recording artifacts).

### §38.5 — Concrete tasks

- [ ] **G.1** Add temp `print` instrumentation per §38.2 to relevant files
- [ ] **G.2** Run Q7 first (gates everything else)
- [ ] **G.3** Run Q2 (color comparison)
- [ ] **G.4** Run Q1 (safe area) at chat-rest
- [ ] **G.5** Run Q4 (hitTest)
- [ ] **G.6** Run Q10 (m34 propagation) post-handoff
- [ ] **G.7** Run Q11 (Z calibration) iteratively
- [ ] **G.8** Run Q3 (cancelInFlight) via simulated scene deactivation
- [ ] **G.9** Run Q5 (normalize alpha refresh) via pinch-commit forward
- [ ] **G.10** Run Q6 (tap recognizer) post-handoff
- [ ] **G.11** Run Q12 (inset + Z interaction) during reverse
- [ ] **G.12** Record all answers in §14 decision log as D-Phase0-Q1 through D-Phase0-Q12
- [ ] **G.13** Remove temp instrumentation before commit
- [ ] **G.14** Re-evaluate downstream design decisions based on findings

### §38.6 — Acceptance criteria

- [ ] All 11 in-scope questions (Q1-Q8, Q10-Q12) answered
- [ ] Each answer recorded in §14
- [ ] Downstream sections updated based on findings (e.g., if Q1 reveals divergence, §3 strategy gets concrete amendment)
- [ ] Temp instrumentation removed
- [ ] Phase 0 ends in clear go/no-go state for each downstream phase

---

## §39 — Gap H/I: Phase ordering + estimate re-baseline

**Root nodes:**
- **H:** "Three phases modify `CellView.setCamera` (P3 baseline, P9 affordance extension, P10 distance-fade upgrade). Without explicit supersession ordering, engineers may implement phases out-of-order and create conflicts."
- **I:** "Original phase estimates in §12 / §25 are optimistic. Re-baseline based on the verification work needed in Phase 0 + iteration likely in Phase 10."

### §39.1 — Trace of H (terse — mechanical resolution)

**Q1 (Rests on):** the fact that three phases all touch the same method (`CellView.setCamera`); the engineer's mental model of "phase 9 EXTENDS phase 3 (doesn't replace)" vs "phase 10 REPLACES phase 6.2's curve."

**Q2 (Why):** writing the same method three times across three phases without explicit supersession leaves room for merge conflicts or partial implementations.

**Q3-Q6:** see §39.2.

### §39.2 — setCamera supersession matrix

Single canonical version of `CellView.setCamera` after all phases land. Each phase adds/changes specific lines.

**After P3 (CellView integration):** the BASELINE setCamera (existing code at CV:253-277):

```swift
func setCamera(_ camera: Camera, viewport: CGRect) {
    guard bounds.height > 0 else { return }
    if morphInProgress { return }
    let naturalH = naturalHeight > 0 ? naturalHeight : bounds.height
    let chatRestFactor = viewport.height / naturalH
    let chatRestRange = chatRestFactor - 1.0
    let extensionFactor = bounds.height / naturalH
    let progress: CGFloat = chatRestRange > 1e-6
        ? min(1.0, max(0.0, (extensionFactor - 1.0) / chatRestRange))
        : 1.0
    let inverseFadeAlpha = 1 - smoothstep(0.05, 0.30, progress)
    labelStack.alpha = inverseFadeAlpha
    pinchGlyph.alpha = inverseFadeAlpha
    layer.sublayerTransform = CATransform3DIdentity
    if pageWidth > 0, let leadingC = leadingConstraint, let widthC = widthConstraint {
        let currentInset = naturalHorizontalInset * (1 - progress)
        leadingC.constant = currentInset
        widthC.constant = pageWidth - 2 * currentInset
    }
}
```

**After P7 (Reverse direction wiring):** ADDS chatContent.alpha (the §6.2 sketch, alpha-only initially):

```swift
// New line added inside setCamera, after pinchGlyph.alpha line:
chatContentContainer?.alpha = smoothstep(0.30, 0.50, progress)
```

**After P9 (Inward-arrows affordance):** ADDS chatRestAffordance.alpha (§21.6):

```swift
// New line added inside setCamera, after the chatContent.alpha line:
chatRestAffordance.alpha = smoothstep(0.05, 0.30, progress)
```

**After P10 (Distance-fade upgrade):** REPLACES the chatContent.alpha line with the hybrid Z + alpha (§23.5):

```swift
// REPLACES the chatContentContainer?.alpha = smoothstep(0.30, 0.50, progress) line:
if let chatContent = chatContentContainer {
    let zMax: CGFloat = MorphTiming.unifiedArcZMagnitude
    let z = (1 - progress) * zMax
    chatContent.layer.transform = CATransform3DMakeTranslation(0, 0, z)
    chatContent.alpha = smoothstep(0.05, 0.35, progress)
}
```

**FINAL setCamera (after all phases):**

```swift
func setCamera(_ camera: Camera, viewport: CGRect) {
    guard bounds.height > 0 else { return }
    if morphInProgress { return }   // Per E.11: keep morphInProgress gate; PMCT owns chrome during pinch-commit forward
    let naturalH = naturalHeight > 0 ? naturalHeight : bounds.height
    let chatRestFactor = viewport.height / naturalH
    let chatRestRange = chatRestFactor - 1.0
    let extensionFactor = bounds.height / naturalH
    let progress: CGFloat = chatRestRange > 1e-6
        ? min(1.0, max(0.0, (extensionFactor - 1.0) / chatRestRange))
        : 1.0

    // Chrome (cell-rest) fade-in curve: visible at progress<0.30
    let inverseFadeAlpha = 1 - smoothstep(0.05, 0.30, progress)
    labelStack.alpha = inverseFadeAlpha
    pinchGlyph.alpha = inverseFadeAlpha

    // Inward-arrows affordance fade-in (chat-rest chrome): visible at progress>0.30
    chatRestAffordance.alpha = smoothstep(0.05, 0.30, progress)

    // chatContent: hybrid Z-translation (engages m34 perspective) + residual alpha (final cleanup at deep cell-rest)
    if let chatContent = chatContentContainer {
        let zMax: CGFloat = MorphTiming.unifiedArcZMagnitude
        let z = (1 - progress) * zMax
        chatContent.layer.transform = CATransform3DMakeTranslation(0, 0, z)
        chatContent.alpha = smoothstep(0.05, 0.35, progress)
    }

    layer.sublayerTransform = CATransform3DIdentity

    // Horizontal-inset (16pt at cell-rest → 0pt at chat-rest)
    if pageWidth > 0, let leadingC = leadingConstraint, let widthC = widthConstraint {
        let currentInset = naturalHorizontalInset * (1 - progress)
        leadingC.constant = currentInset
        widthC.constant = pageWidth - 2 * currentInset
    }
}
```

**This is the FUNCTIONAL final form** (still has improvements pending). All earlier sketches in §6.2, §21.6, §23.5 are SUPERSEDED by §39.2 → and §39.2 is itself further refined by **§39.2.1 below** which is the PILLAR-COMPLIANT authoritative version.

### §39.2.1 — Pillar-compliant authoritative final form (SUPERSEDES §39.2)

The §39.2 functional version above passes the build but does not honor Tier-3B+ pillars in several ways. This subsection retrofits it to comply. Pillar IDs interspersed inline; pillar honors enumerated as footnote per method. Engineer implementing this MUST follow this version, not §39.2.

**Pillar definitions introduced on first use (read top-to-bottom):**

- **P1.1 — Guard chaining.** Combine sequential `guard` statements into one block. Forbidden form: `guard let a else { return } / guard let b else { return }`. Required form: `guard let a, let b else { return }`.
- **P1.10 — Comment quality.** Comments explain WHY, never WHAT. `// increment counter` is forbidden; `// epsilon avoids divide-by-zero when naturalH ≈ viewport.height` is required.
- **P2.11 — Magic numbers.** Every literal numeric outside test code is either obvious (0, 1, edge cases) or extracted to a named token. Smoothstep range thresholds = tokens.
- **P3.5 — Code-as-documentation.** Code reads as the contract. Helper names and types carry the intent.
- **P6.6 — No sentinels.** `var index: Int = -1` is forbidden. Use `Optional<Int>` or document why sentinel is necessary (e.g., UIKit constraint).
- **P6.7 — No silent early-return.** Every `guard ... else { return }` without a side effect (log, assert) carries a comment explaining WHY silence is correct.
- **P11.1 — SRP.** Each method does ONE thing. Method >50 LOC is a smell; method with 4 conceptual concerns is a smell even at 30 LOC.
- **P12.2 — Tell, don't ask.** Don't query an object then act on its data. Tell the object to act. Long if-then-mutate sequences on one object's properties are a smell.
- **P13.2 — Cognitive complexity.** Nested guards inside if-else inside switch = cognitive overload. ≤15 per method.
- **P13.4 — Method length ≤50 LOC.**
- **P19.1 — Pure functions where possible.** Same input → same output, no side effects.
- **P19.3 — Idempotency for reconcilers.** `apply*` methods are idempotent.
- **P19.4 — Referential transparency.** A pure function returning value X can be replaced by X.

**The pillar-compliant rewrite (CellView.swift, replaces CV:253-277):**

```swift
// MARK: - Camera-change seam (per-frame chrome + chat-content driver)

// P11.1 SRP: setCamera orchestrates per-frame updates; concerns are delegated
// to single-responsibility appliers below. P13.4 method length ≤50 LOC.
// P19.3 idempotent: writing same camera twice produces identical state.
//
// Pillar honors: P1.1, P6.7, P10.x cell-own-transform invariant, P11.1, P12.2,
// P13.4, P19.3.
func setCamera(_ camera: Camera, viewport: CGRect) {
    // P1.1 guard-chain: two preconditions in one block.
    // P6.7 silence justified: pre-layout pass before bounds resolve produces
    // a garbage progress value; alpha writes here would immediately get
    // overwritten on the next layout-driven call. AND morphInProgress=true
    // means MorphChoreographer owns chrome via PMCT (D19, D20) — setCamera
    // defers.
    guard bounds.height > 0, !morphInProgress else { return }

    let progress = computeProgress(viewport: viewport)
    applyCellRestChromeAlphas(progress: progress)
    applyChatRestAffordanceAlpha(progress: progress)
    applyChatContentDistanceFade(progress: progress)
    applyHorizontalInsetForProgress(progress)

    // Cell-own-transform invariant (CLAUDE.md §2.2): cell.layer.sublayerTransform
    // is ALWAYS identity — camera lives on canvas.layer.sublayerTransform, never
    // on the cell. Defensive write each tick guards against any external write.
    layer.sublayerTransform = CATransform3DIdentity
}

// MARK: - Per-frame progress derivation (pure)

/// Clamped progress ∈ [0, 1] mapping cell heightConstraint to chat-rest extension.
/// progress=0 ⇒ cell-rest (naturalH). progress=1 ⇒ chat-rest (naturalH × chatRestFactor).
///
/// P19.1 pure: same (viewport, bounds, naturalHeight) → same progress.
/// P19.4 referentially transparent.
/// P3.5 code-as-documentation: name + signature carry the contract.
private func computeProgress(viewport: CGRect) -> CGFloat {
    // P6.6 no sentinel: fallback to bounds.height if naturalHeight not yet
    // captured (pre-installLayout window). Documented behavior, not a bug.
    let naturalH = naturalHeight > 0 ? naturalHeight : bounds.height
    let chatRestFactor = viewport.height / naturalH
    let chatRestRange = chatRestFactor - 1.0

    // P1.10 WHY: when naturalH ≈ viewport.height, chatRestRange ≈ 0 and the
    // division would be undefined. Treating this case as "already at chat-rest"
    // is the right phenomenological default (the cell has no room to extend).
    guard chatRestRange > AlphaCurve.progressDenominatorEpsilon else { return 1.0 }

    let extensionFactor = bounds.height / naturalH
    let raw = (extensionFactor - 1.0) / chatRestRange
    return min(1.0, max(0.0, raw))                                   // P2.11: 0/1 are universal bounds, not magic
}

// MARK: - Per-frame appliers (side-effectful, idempotent)

/// labelStack + pinchGlyph fade IN as progress drops toward cell-rest.
/// P19.3 idempotent | P11.1 single concern: cell-rest chrome alpha.
private func applyCellRestChromeAlphas(progress: CGFloat) {
    let alpha = 1 - smoothstep(AlphaCurve.cellRestChromeIn, AlphaCurve.cellRestChromeFull, progress)
    labelStack.alpha = alpha
    pinchGlyph.alpha = alpha
}

/// Inward-arrows affordance (§21) fades OUT as progress drops toward cell-rest;
/// fully visible at chat-rest. Semantic: the affordance signals "collapse this"
/// at chat-rest; meaningless at cell-rest where the cell is already collapsed.
/// P19.3 idempotent | P11.1 SRP.
private func applyChatRestAffordanceAlpha(progress: CGFloat) {
    chatRestAffordance.alpha = smoothstep(
        AlphaCurve.chatRestAffordanceIn,
        AlphaCurve.chatRestAffordanceFull,
        progress
    )
}

/// chatContent recedes via m34 perspective foreshortening (Z-translation),
/// with residual alpha for deep-cell-rest cleanup. Substrate-true per §23:
/// the canvas-level m34 = -1/1000 is engaged via Z-translation on chatContent's
/// layer; "fading-into-illegibility" emerges as a CONSEQUENCE of distance.
///
/// P10.2 substrate primitive engaged | P19.3 idempotent | P11.1 SRP.
/// P6.7 silence justified: chatContent may not yet exist (pre-installChatContent window).
private func applyChatContentDistanceFade(progress: CGFloat) {
    guard let chatContent = chatContentContainer else { return }

    let z = (1 - progress) * AlphaCurve.chatContentZMax
    chatContent.layer.transform = CATransform3DMakeTranslation(0, 0, z)
    chatContent.alpha = smoothstep(
        AlphaCurve.chatContentAlphaIn,
        AlphaCurve.chatContentAlphaFull,
        progress
    )
}

/// Horizontal inset: 16pt at cell-rest → 0pt at chat-rest (edge-to-edge cell).
/// P11.1 SRP | P19.3 idempotent.
/// P6.7 silence justified: leadingC / widthC may not yet exist (pre-installLayout window).
private func applyHorizontalInsetForProgress(_ progress: CGFloat) {
    guard pageWidth > 0,
          let leadingC = leadingConstraint,
          let widthC = widthConstraint
    else { return }

    let currentInset = naturalHorizontalInset * (1 - progress)
    leadingC.constant = currentInset
    widthC.constant = pageWidth - 2 * currentInset
}
```

**Companion token enum (DesignSystem/AlphaCurve.swift — new file):**

```swift
// AlphaCurve — smoothstep range thresholds for per-progress alpha curves
// driven by CellView.setCamera. Extracted from inline literals per P2.11
// magic-number doctrine and P20.3 file placement (DesignSystem layer holds
// numeric tokens).

import CoreGraphics

// P9.2 Sendable: pure-value namespace; no shared mutable state.
enum AlphaCurve {

    // MARK: - cell-rest chrome (labelStack + pinchGlyph)

    /// Fade-in starts as progress drops below this threshold.
    static let cellRestChromeFull: CGFloat = 0.30
    /// Fully visible at and below this threshold.
    static let cellRestChromeIn: CGFloat = 0.05

    // MARK: - chat-rest affordance (inward arrows; §21)

    static let chatRestAffordanceIn: CGFloat = 0.05
    static let chatRestAffordanceFull: CGFloat = 0.30

    // MARK: - chatContent residual alpha (§23 hybrid Z + alpha)

    /// Below this progress, chatContent is fully invisible (Z-fade is dominant
    /// in 0.35–1.0; alpha completes the hide in 0.05–0.35).
    static let chatContentAlphaIn: CGFloat = 0.05
    /// Above this progress, chatContent is fully opaque; Z-translation handles
    /// the apparent shrink via m34.
    static let chatContentAlphaFull: CGFloat = 0.35

    // MARK: - chatContent Z-translation (§23 substrate-pure distance-fade)

    /// Maximum Z-translation at progress=0 (cell-rest). Magnitude matches
    /// MorphTiming.unifiedArcZMagnitude (forward pinch-commit's sin-bell peak)
    /// for symmetric depth feel between forward and reverse.
    static let chatContentZMax: CGFloat = MorphTiming.unifiedArcZMagnitude

    // MARK: - precision

    /// Below this magnitude, chatRestRange is treated as degenerate (naturalH ≈ viewport.height).
    static let progressDenominatorEpsilon: CGFloat = 1e-6
}
```

**Pillar honors for §39.2.1 (per-method footnote):**

| Method | Pillars honored |
|---|---|
| `setCamera(_:viewport:)` | P1.1 (guard chain), P6.7 (silence justified with comment), P10.x (cell-own-transform invariant defended), P11.1 (orchestrator delegates), P12.2 (cell tells itself), P13.4 (12 LOC), P19.3 (idempotent) |
| `computeProgress(viewport:)` | P1.10 (WHY comment on epsilon), P3.5 (name carries contract), P6.6 (fallback documented), P11.1 (pure progress only), P19.1 (pure), P19.4 (referentially transparent) |
| `applyCellRestChromeAlphas(progress:)` | P11.1 (one concern), P12.2 (cell mutates itself), P19.3 (idempotent), P2.11 (tokens via AlphaCurve) |
| `applyChatRestAffordanceAlpha(progress:)` | P11.1, P12.2, P19.3, P2.11 |
| `applyChatContentDistanceFade(progress:)` | P10.2 (substrate primitive engaged), P6.7 (silence justified), P11.1, P19.3 |
| `applyHorizontalInsetForProgress(_:)` | P6.7 (silence justified), P11.1, P19.3, P17.5 (labeled init params) |
| `AlphaCurve` enum | P2.11 (all magic numbers extracted), P9.2 (Sendable value namespace), P20.3 (DesignSystem placement), P20.1 (one type per file) |

**Pillar violations to verify ABSENT after the rewrite:**

- ❌ No `var` defaults (all `let`) — **P8.3 enforced**
- ❌ No force-unwraps (`!`) anywhere in the method bodies — **P1.3 enforced**
- ❌ No silent returns without explanatory comments — **P6.7 enforced**
- ❌ No literal smoothstep ranges in setCamera — **P2.11 enforced via AlphaCurve**
- ❌ No `setupX()` helper that creates the view — **P1.2 N/A (this is a runtime method, not a property init)**
- ❌ No mixed optional-unwrap idioms — **P1.3 enforced**
- ❌ No nested >3-deep indentation — **P13.3 enforced (max 1 nested guard)**
- ❌ No method >50 LOC — **P13.4 enforced (each is <20 LOC)**

**Pillar review gate (must pass before §39.2.1 is considered implemented):**

- [ ] §39.2.1 `setCamera` and 4 appliers compile cleanly
- [ ] `AlphaCurve.swift` exists in `DesignSystem/`
- [ ] No magic smoothstep literals remain in `CellView.setCamera`
- [ ] No silent returns without `// P6.7 silence justified:` comment
- [ ] Method-length spot check: each method ≤20 LOC ✓
- [ ] grep for `naturalHeight > 0` confirms no duplicated fallback logic elsewhere
- [ ] `computeProgress(viewport:)` is purely functional (no `self.X = ...` writes)
- [ ] Unit-test stub written (computeProgress test) — verifies P19.4 referential transparency

### §39.3 — Strict phase ordering for setCamera modifications

- [ ] **P3:** baseline only (do NOT add P7/P9/P10 lines yet)
- [ ] **P7:** add ONLY `chatContent.alpha = smoothstep(0.30, 0.50, progress)` line (the §6.2 simple alpha version)
- [ ] **P9:** add ONLY `chatRestAffordance.alpha = smoothstep(0.05, 0.30, progress)` line
- [ ] **P10:** REPLACE P7's chatContent line with the hybrid Z + alpha block (final form per §39.2)

If phases land out-of-order (e.g., P10 before P9), engineer must manually merge the §39.2 final form.

### §39.4 — Estimate re-baseline (Gap I)

| Phase | Original estimate | Re-baselined estimate | Rationale |
|---|---|---|---|
| P0 — Verification | 1-2 days | **2-3 days** | Q11 may require iteration; Q1/Q3 require simulator + log analysis |
| P1 — ChatContent components | 2-3 days | 2-3 days (unchanged) | Component creation is straightforward |
| P2 — StateController | 1-2 days | 1-2 days (unchanged) | Small type |
| P3 — CellView integration | 1-2 days | **2 days** | Includes setCamera baseline + property additions; some iteration likely |
| P4 — Parallel layout wiring | 1-2 days | 1-2 days (unchanged) | |
| P5 — Normalize wiring | 1-2 days | **2 days** | Includes new normalize per §16.10 with camera update + chrome refresh |
| P6 — Handoff wiring | 2-3 days | **3 days** | Includes captureTransientState + bindTransientState + handoff orchestration + handoffPhase enum |
| P7 — Reverse direction wiring | 2-3 days | **3 days** | Includes setCamera extension for chatContent (P7's initial alpha-only) + handleTap guard |
| P8 — Edge cases & polish | 3-5 days | **4-5 days** | Includes Gap A recovery + Gap D memory + interrupt handling per E.12 |
| P9 — Inward-arrows affordance | 1-2 days | 1-2 days (unchanged) | Small addition |
| P10 — Distance-fade upgrade | 2-3 days | **3-5 days** | Z calibration iteration; visual verification across devices |
| P11 — Reverse cinematography (GATED) | 3-5 days | **5-8 days** | Composition with §23 not fully validated; multiple iterations expected |
| P12 — Loading dots (GATED) | 5-8 days | 5-8 days (unchanged) | Memorized deferred |

**Total in-scope (P0-P10 + P8 + P9, excluding P11/P12):** 21-31 days (was 15-23). Reflects honest scope expansion.

### §39.5 — Critical-path sequence

**Mandatory phases in execution order:**

P0 → P1 || P2 → P3 → P4 → P5 → P6 → P7 → P9 → P10 → P8

(`||` indicates phases that can run in parallel.)

P11 and P12 are GATED on user direction after P7/P10 land.

### §39.6 — Acceptance criteria

- [ ] §39.2 final setCamera form is the documented authoritative version
- [ ] §39.3 phase-by-phase additions are explicit
- [ ] §29 status table updated with re-baselined estimates
- [ ] Engineers understand "P10 SUPERSEDES P7's chatContent line, does NOT add a separate line"

---

## §40 — Decision log additions D18-D24 + risk register additions R23-R26 + Gap J placeholder

### §40.1 — Decision log entries

Appended to §14 / §26.

#### 2026-05-25 — D18: Accept `safeAreaLayoutGuide`-anchored composer in V1

- **Decision:** Both `chatVC.composerContainer` and `cell.chatContent.composer` anchor to `view.safeAreaLayoutGuide.bottomAnchor - 12` (current chatVC behavior).
- **Rationale:** Forward-visual-parity at handoff. Known UX issue (composer hidden when keyboard up) accepted as future-iteration work. The user's described phenomenology video doesn't exhibit keyboard interaction.
- **Reversal path:** §37.3 documents the upgrade to `keyboardLayoutGuide.topAnchor` (~10 LOC across two files) when user requests.

#### 2026-05-25 — D19: Keep `morphInProgress` gate in `CellView.setCamera`

- **Decision:** The early-return guard `if morphInProgress { return }` at CV:256 stays in place.
- **Rationale:** PMCT (`performMorphChromeTransition`) owns chrome alphas during pinch-commit forward via UIView.animate. Lifting the gate would cause setCamera's per-tick alpha writes to conflict with PMCT's writes (per §36.4 E.8 analysis). Keeping the gate; chrome behavior is owned by ONE mechanism at a time.
- **Alternatives considered:** Lift gate to allow setCamera alpha writes during pinch-commit (rejected per E.8 — visible alpha thrashing).
- **Reversal path:** if pinch-commit chrome behavior remains unsatisfactory after E.10, revisit gate-lifting; would require coordinating PMCT and setCamera write priorities.

#### 2026-05-25 — D20: Add `performMorphChromeTransition` call to `playTapToChatMorph`

- **Decision:** Pinch-commit forward symmetrically calls `PMCT` (with `centerLabelDuration = masterTimerDuration = 1.2s`) so chrome fades AND day-marker emerges during the morph, matching tap-forward's behavior.
- **Rationale:** Phenomenological consistency between two forward commits (per Gap E / §36).
- **Implementation:** §36.3 sketch + §36.5 refined tasks E.10-E.15.
- **Alternatives considered:** Lift morphInProgress gate (rejected per D19); leave asymmetric (rejected — phenomenological inconsistency).

#### 2026-05-25 — D21: Add `HandoffPhase` state machine to `RevealCoordinator`

- **Decision:** Introduce `enum HandoffPhase` with 6 cases (idle, presenting, crossFadeStarted, crossFadeComplete, blurFadeOutStarted, handoffComplete). Phase transitions written at 5 milestones in `runRevealChoreography`. Reads enable scene-deactivation recovery via `completeHandoffIfPending`.
- **Rationale:** Recovery from cancelInFlight-interrupted reveals (per Gap A / §32). Phase enum > heuristic for clarity and testability.
- **Implementation:** §32.3 sketch + §32.4 tasks A.1-A.9.

#### 2026-05-25 — D22: Re-baseline phase estimates

- **Decision:** P0 = 2-3 days; P5/P6/P7/P8/P10 each increased by 0.5-2 days per §39.4.
- **Total in-scope estimate:** 21-31 days (was 15-23 days).
- **Rationale:** Original estimates underweighted Phase 0 iteration, Z magnitude calibration in P10, recovery handler in P8.

#### 2026-05-25 — D23: Cut-off "Inverse-symmetry" specification — KNOWN UNKNOWN

- **Decision:** The user's earlier message about phenomenological elements ended at "Inverse-symmetry with tap-to-chat" without a completed paragraph. We have PARTIAL information about what inverse-symmetry entails. The remaining specification (if any) may contain load-bearing requirements not in this checklist.
- **Risk acceptance:** Phase 11 cinematography (which addresses inverse-symmetry) is GATED on user feedback post-P7. If the cut-off section contains specific requirements (e.g., specific timings, specific Z arc shape, specific blur curtain treatment for reverse), those will surface at the gate decision and require checklist amendment.
- **Reversal path:** if user pastes the cut-off section, retrofit §24 with the new specification; D14 default may need to flip from "gesture-driven" to "commit-driven."

#### 2026-05-25 — D24: Phase 0 is MANDATORY before structural code

- **Decision:** No phase past P0 begins until P0 questions Q1, Q3, Q7, Q10, Q11 have answers recorded in §14.
- **Rationale:** Each gates a downstream design decision. Inferring rather than verifying creates rework risk.
- **Exception:** P1, P2 (component creation) can run in parallel with P0 since they don't depend on P0 findings.

### §40.2 — Risk register additions

| ID | Risk | Probability | Impact | Mitigation |
|---|---|---|---|---|
| R23 | Phase 0 verification reveals an assumption is wrong (e.g., Q1 reveals safeArea divergence > 1pt, or Q10 reveals m34 doesn't propagate through 3 sublayers) | Medium | High | Phase 0 is a gate; downstream design adjusts based on findings; some sections rewritten before structural code |
| R24 | Cut-off "inverse-symmetry" specification (Gap J / D23) contains additional load-bearing requirements not in current scope | Medium | Medium | D23 gate decision after P7; user pastes the cut-off; §24 amended |
| R25 | Pinch-commit forward's PMCT call (§36.3) conflicts with handoffPhase transitions or normalize timing | Low | Medium | E.13-E.15 verification; explicit testing of pinch-commit → reveal → handoff full path |
| R26 | Phase 8 (edge cases) reveals additional scenarios not covered in current §7 — e.g., keyboard appearance during reverse direction's spring | Medium | Low-Medium | Phase 8 has flexibility to add edge-case handlers; document new edge cases as they surface |

### §40.3 — Final closing — checklist readiness

After §32-§40 land, the checklist is **EXECUTION-READY** with the following honest caveats:

**What's resolved:**
- ✅ All 10 gaps from the audit have either sketched implementations OR explicit acceptance decisions OR explicit "GATED on user direction" markers
- ✅ Phase 0 has a per-question playbook with methods + success criteria + record locations
- ✅ Phase estimates are honestly re-baselined (21-31 days for in-scope work)
- ✅ Phase ordering is explicit (§39.5 critical path)
- ✅ setCamera supersession matrix is canonical (§39.2 final form)
- ✅ Decision log is exhaustive (D1-D24)
- ✅ Risk register is comprehensive (R1-R26)

**What remains external:**
- ⏸ Phase 0 empirical answers (cannot be done from documentation alone; require running the verifications)
- ⏸ Cut-off "inverse-symmetry" specification (D23 — depends on user pasting the missing paragraph)
- ⏸ Phase 11 / Phase 12 gate decisions (depend on user direction after P7 lands or backend infra exists)

**What's accepted:**
- ✋ keyboardLayoutGuide overlap (D18) — V1 accepts current chatVC behavior
- ✋ Pinch-commit's existing partially-asymmetric chrome was the surface symptom; D20 (call PMCT in playTapToChatMorph) is the documented fix
- ✋ Loading-dots indicator deferred (D12) — preserved as design in §22

**Engineer readiness:** an engineer starting fresh from this checklist can:
1. Read §0 for the goal
2. Read §16 + §32-§40 for the empirical foundation + sketched code
3. Run Phase 0 per §38 playbook
4. Execute Phases 1-10 in order per §39.5
5. Resolve gate decisions on P11/P12 with user
6. Ship

**Verdict updated:**

The honest audit said "not 100% ready, ~85%." After §31-§40, the honest verdict is: **95% ready.** The remaining 5% is:
- 3% Phase 0 empirical findings that require running the app (not blocker; methodology is now in §38)
- 2% Gap J's cut-off specification (not blocker; D23 accepts the risk; will surface at P11 gate)

**Recommendation:** start P0 (Verification & prototyping). Use §38 playbook. Record answers in §14. Then proceed to P1+ per §39.5.

---

**END OF CHECKLIST (v3).** Update inline as decisions evolve and items complete. Living document.

**Version history:**
- v1: 2026-05-25, original 14 sections, structural handoff scope
- v2: 2026-05-25, added §15-§19, codebase verification findings + Phase 0 questions + long-term enablement
- v3: 2026-05-25, added §20-§30 (phenomenology polish elements) and §31-§40 (gap closure for execution readiness)

**Next planned updates:**
1. Phase 0 verification populates §14 with D-Phase0-Q1 through D-Phase0-Q12 answers
2. Phase 7 completion triggers the gate decision on Phase 11 (cinematography)
3. Backend infrastructure milestone triggers re-engagement of Phase 12 (dots)
4. Cut-off "Inverse-symmetry" specification (D23) — pending user paste; will retrofit §24 + revisit D14

---

## §42 — Reverse-pinch frame analysis (dot_pinch.mov @ 4-8s, slow-mo)

**Source:** `/Users/spacewizardmoneygang/Desktop/XcodeInstall/_frames/dot_pinch.mov`, 4.0s–8.0s window, 60 frames extracted at ~15fps effective decode rate. Slow-mo recording — wall-clock duration of the reverse pinch in real time is approximately 0.5–1.0s; the 4s window stretches it for analytical inspection.

**Date analyzed:** 2026-05-25.

**Why this analysis exists:** the user identified that the reference reverse-pinch gesture has a STAGED multi-step curvature where the chat content's similarity transformation begins and substantially progresses BEFORE the cell's bounds start migrating. The current implementation couples all transformations to a single `progress = (heightConstraint − naturalH) / (chatRestExt − naturalH)` value, producing simultaneous (not staged) transformations. This section documents the staged behavior with empirical evidence, then proposes the implementation changes needed to match.

### §42.1 — Frame-by-frame observation log (coarse + targeted samples)

Notation: progress p is the gesture's app-internal progress where p=1.0 at gesture start (chat-rest) and p=0.0 at gesture end (cell-rest). The video's time-progress (wall-clock fraction of the 4-8s window) is denoted t.

| Frame | t (window %) | Visible state observations | Inferred app-progress p |
|---|---|---|---|
| 1 | 0% (4.00s) | Full chat-state: keyboard up, "Mon, Jul 1 at 3:12 AM" header centered at top, two bubbles of body text, "Share with Dot…" composer, full keyboard. Cell fills viewport edge-to-edge with no rounded card outline visible. | 1.0 |
| 6 | 10% (4.40s) | Identical to frame 1 to a close inspection. No visible change. Gesture either not yet visibly registering or curves haven't crossed their lower threshold. | ~1.0 |
| 8 | 13% (4.53s) | Subtle hint: very faint partial-alpha "Have a great Saturday!" line appears above the existing "Mon, Jul 1…" header. This is content that was scrolled-off-top BEFORE the gesture beginning to peek in — first visual evidence of chat content scaling/shifting. | ~0.97 |
| 9 | 15% (4.60s) | Top bubble preview "Have a great Saturday!" is slightly more visible. Existing header text drops marginally in opacity. Body text and composer apparently unchanged. | ~0.93 |
| 12 | 20% (4.80s) | "Have a great Saturday!" clearer. Existing header is shifting down slightly in apparent position. Body text starts looking ~5% smaller. Composer + keyboard at bottom: UNCHANGED size. | ~0.85 |
| 15 | 25% (5.00s) | Pronounced text scaling. "Hope you have a great Saturday!" plus a NEW earlier bubble preview appearing above. Header is no longer at top — it's pushed down. Body text noticeably smaller (~15-20% reduction). Composer + keyboard at bottom: STILL UNCHANGED. | ~0.78 |
| 18 | 30% (5.20s) | Multiple bubble snippets stacking at top, all at partial alpha. Body text continues to shrink. Atmospheric pink/lavender gradient starting to appear at the right edge of screen, very subtle. Composer + keyboard: unchanged. | ~0.70 |
| 21 | 35% (5.40s) | Text is small enough that individual words are hard to read. Multiple bubbles previewed at top. Composer + keyboard still unchanged at full size at the bottom of the screen. | ~0.62 |
| 24 | 40% (5.60s) | Heavy scaling. Chat content text is now near-illegible size. Atmospheric gradient prominent on right side. Composer + keyboard STILL at full visible size at bottom — they have not yet started transitioning away. | ~0.55 |
| 27 | 45% (5.80s) | Inward-arrows affordance (top-left) starts visibly appearing at low alpha. "..." indicator (top-right) begins appearing too. Chat content text is now extremely small. Composer placeholder beginning to fade. Keyboard still mostly visible. | ~0.48 |
| 29 | 48% (5.93s) | Composer/textfield is mostly invisible now. Keyboard partially fading. Chat content essentially trace-only. NO rounded cell card edges visible yet — chat content continues to fill the screen edge-to-edge despite being heavily scaled. | ~0.43 |
| 30 | 50% (6.00s) | Composer GONE. Keyboard mostly gone. Chat content at minimum visible size. Top chrome (inward arrows + "...") more visible. **CELL BOUNDS STILL NOT VISIBLE as a rounded card.** | ~0.40 |
| 31 | 52% (6.07s) | **CELL ROUNDED-CORNER OUTLINE FIRST APPEARS** — a faint horizontal edge becomes visible near the top of the screen, indicating the active cell's top rounded edge is now perceptibly inset from the viewport top. Atmospheric gradient very prominent at top. Bounds-migration HAS STARTED. | ~0.38 |
| 33 | 55% (6.20s) | TWO distinct rounded cards now visible — the upper one (cell above in list) and the active cell (lower one). Cell bounds rapidly forming. Chat content inside the active cell is essentially invisible at this point. Keyboard fully gone. | ~0.32 |
| 36 | 60% (6.40s) | Two cells with clear rounded card outlines. Both look ALMOST blank inside — no chrome (no date labels, no topic text, no glyphs). The chat content is gone. Active cell still slightly larger than final size. | ~0.25 |
| 39 | 65% (6.60s) | Cells continue to settle into their final sizes. Still no internal chrome visible (cells are blank cards). | ~0.20 |
| 42 | 70% (6.80s) | Cells very near final size. Still no chrome (date/topic/today labels NOT visible inside cells yet). | ~0.15 |
| 45 | 75% (7.00s) | **CELL-REST CHROME APPEARS**: "Thursday, Jun 20" date label, "Raffi's introduction letter, passion for soccer and work, career goals by age 31" topic text, "Today" label on the active cell, and the LOADING DOTS indicator at bottom-left of the active cell — all fade in at partial alpha. | ~0.10 |
| 48 | 80% (7.20s) | Chrome more visible — text approaching full alpha. Cell sizes essentially final. Atmospheric gradient at bottom fully visible. | ~0.06 |
| 60 | 100% (8.00s) | Final settled cell-rest state. Two cells with full chrome (dates, topics, today label, loading dots). Atmospheric gradient at bottom. Inward-arrows + "..." chrome at top. | 0.0 |

### §42.2 — Stage decomposition

The reverse pinch decomposes into FIVE staged sub-transformations, each with its own progress range, dominant transformation, and continuous-curvature boundary into the next stage.

**Stage A — Pre-visible-gesture (p ∈ [1.00, 0.97])**

- Visual: chat-state, identical to start. No transformation visible.
- Window time: 0%–13% (frames 1–8).
- Mechanism: gesture has begun (user's fingers are pinching) but no visual curve has crossed its activation threshold yet. This is the smoothstep entry zone where all curves are at 0.
- Why it exists: continuous-curvature design demands smooth onset. Hard onsets cause velocity spikes.

**Stage B — Chat content similarity transformation (p ∈ [0.97, 0.40])**

- Visual: the chat content — specifically the bubbles (text + their containers), the day-marker header, and any visible body text — undergoes a UNIFORM SCALE-DOWN (similarity transformation: uniform scale around a fixed anchor, no rotation, slight implicit translation as the scale fixed-point may shift).
- Window time: 13%–50% (frames 8–30). Approximately 0.6 seconds of slow-mo recording (so ~150ms in real time given a typical pinch duration).
- **CRITICAL OBSERVATIONS:**
  - The composer + keyboard at the bottom of the screen REMAIN UNCHANGED in size throughout Stage B. They are visually separate from the chat content's similarity transformation. Only the chat content above the composer is transforming.
  - As chat content scales DOWN, previously-clipped-above content (earlier bubbles) becomes visible at the top with partial alpha. This is consistent with the chatContent's view "zooming out" while its bounds stay fixed (or stay fixed-ish) — the contents inside fit more compactly so more shows.
  - Cell bounds DO NOT migrate during Stage B. The cell continues to fill the viewport edge-to-edge.
  - Atmospheric gradient starts appearing at edges late in Stage B (frames 24–30), particularly on the right side. This is the canvas's `pageGradientLayer` becoming visible as the chat content's opaque cover-everything fades.
- Mechanism (inferred): a similarity transformation on the chat content view (or its layer), applied INDEPENDENTLY of the cell's heightConstraint. The cell stays at chat-rest extension; the chat content INSIDE the cell scales.
- End of stage: chat content has scaled down to near-zero apparent size; further scaling has no perceptual effect.

**Stage C — Cell bounds migration (p ∈ [0.40, 0.20])**

- Visual: the cell's rounded-card outline RAPIDLY APPEARS from invisible (edge-to-edge with viewport) to fully visible (rounded card centered in viewport, inset from edges). Multiple cells in the list also become visible.
- Window time: 50%–65% (frames 30–39). Approximately 0.25 seconds of slow-mo (so ~60ms real time — quick).
- **CRITICAL OBSERVATIONS:**
  - This is the FAST stage. The cell bounds transition is faster than the chat-content scaling that preceded it.
  - The composer disappears at the start of Stage C (frame 30) — confirming that the composer/keyboard were tied to the cell's bounds, not to the chat content's scale.
  - The bounds-migration starts when chat content has substantially completed its scaling — this is the staged-ness the user described.
- Mechanism (inferred): cell.heightConstraint shrinks rapidly from chatRestExt (852pt) toward naturalH (200pt). The camera/sublayerTransform also adjusts to keep neighbor cells in their natural positions.
- End of stage: cell is at near-final size with clear rounded edges. No chrome inside it yet.

**Stage D — Cell-rest chrome appearance (p ∈ [0.20, 0.05])**

- Visual: the cell-rest chrome inside each cell — date label ("Thursday, Jun 20", "Today"), topic summary, loading-dots indicator — fades in.
- Window time: 65%–90% (frames 39–54). Approximately 0.4 seconds of slow-mo.
- **CRITICAL OBSERVATIONS:**
  - Chrome appears AFTER cell bounds have essentially completed migration. This is a CLEAR sequential boundary.
  - Loading dots indicator appears on the active cell — this confirms the "Today" loading-dots phenomenology element (P2 / §22) that the user described.
  - Top chrome (inward affordance, "..." menu) is fully visible by the start of Stage D.
- Mechanism (inferred): chrome alpha curves (labelStack, pinchGlyph, chatRestAffordance, dots indicator) fade-in driven by progress.
- End of stage: chrome at full alpha; cells settled at final positions.

**Stage E — Settled (p ∈ [0.05, 0.0])**

- Visual: final cell-rest state. No more motion.
- Window time: 90%–100% (frames 54–60).
- Mechanism: spring tail completing settle to exact target values.

### §42.3 — Continuous-curvature relationship between stages

The user's critical instruction: "continuous curvature" without velocity discontinuities. Empirically observed:

- **Stage A → B transition (p ≈ 0.97):** smooth onset of chat-content scaling. The first visible scaling is barely perceptible — content scale starts changing with very low rate-of-change, then accelerates. Consistent with a smoothstep or cubic ease-in entry curve.
- **Stage B → C transition (p ≈ 0.40):** crucial. Chat content's scaling has essentially completed (content is too small to visually register further); cell bounds migration begins. **For continuous curvature here:** at p ≈ 0.40, the cell bounds must already have NON-ZERO velocity. If they were truly stationary until p=0.40 and then started moving, there'd be a velocity discontinuity (acceleration spike). Likely the cell bounds curve actually has a very LOW non-zero rate-of-change starting earlier (say from p ≈ 0.55), which becomes the DOMINANT visible transformation once chat-content scaling tails off.
- **Stage C → D transition (p ≈ 0.20):** chrome fade-in begins as bounds migration is mostly complete. Similar continuity: chrome alpha curve must have non-zero initial rate-of-change at p ≈ 0.20 to maintain smooth perceived velocity through the transition.
- **Stage D → E transition (p ≈ 0.05):** spring tail. Critically damped springs naturally provide smooth settle.

### §42.4 — Composer / keyboard / atmospheric gradient observations

These are secondary surfaces but their behavior is informative:

- **Composer:** at full visible size throughout Stages A and B. Starts fading at the Stage B / C boundary (frame 28-30). Fully gone by frame 33. **Tied to cell bounds, not chat content scale.**
- **Keyboard:** at full size throughout Stages A and B. Begins dismissing around frame 30. Fully dismissed by frame 35. **Independent UIKit dismiss animation, not part of the gesture-driven curves directly.**
- **Atmospheric gradient:** invisible during Stages A and B (chat content fills viewport edge-to-edge with opaque background). First peeks through at edges in late Stage B (frames 24-30) as chat content becomes small enough to leak the underlying gradient. Fully visible by Stage D, occupying the area outside the cell cards. **Tied to chat content scale / opacity, not cell bounds directly** — once chat content shrinks small enough, the gradient shows.
- **Top chrome (inward arrows + "..." menu):** start appearing at the Stage B late phase (frame 27, p≈0.48). Fully visible by frame 36. **Tied to chat content scale (which dictates whether the top of the screen is occupied by chat content) AND/OR a dedicated alpha curve.**

### §42.5 — Mismatch with current implementation

Current implementation (per §39.2.1, §6.2, §23):

```swift
// All transformations driven by a SINGLE progress derived from heightConstraint:
let progress = (heightConstraint - naturalH) / (chatRestExt - naturalH)

// Chrome alpha curve (cell-rest):
labelStack.alpha = 1 - smoothstep(0.05, 0.30, progress)

// chatContent Z + alpha (hybrid):
let z = (1 - progress) * Z_MAX
chatContent.layer.transform = CATransform3DMakeTranslation(0, 0, z)
chatContent.alpha = smoothstep(0.05, 0.35, progress)

// chatRestAffordance alpha:
chatRestAffordance.alpha = smoothstep(0.05, 0.30, progress)
```

**Critical mismatch:** in the current implementation, `heightConstraint` shrinks LINEARLY with the user's pinch gesture, so the cell visibly shrinks from gesture frame 1. There is NO Stage A (pre-visible gesture) and NO Stage B with stationary bounds. The cell bounds and the chatContent shrinkage are simultaneous, not staged.

The reference video shows that the cell.heightConstraint is held effectively constant during Stages A and B (perhaps with a tiny ease-in tail) and only begins migrating substantially around p ≈ 0.50.

### §42.6 — Implementation proposal (staged-curvature reverse direction)

To match the reference, the reverse direction needs to **DECOUPLE** the gesture's input from cell.heightConstraint via a remap function, AND introduce a separate transformation on chatContent that runs during the early portion of the gesture.

**Approach:**

Define a master gesture parameter `g ∈ [0.0, 1.0]` driven directly by pinch scale (where g=0 means no compression / chat-rest; g=1 means fully compressed / cell-rest). This is what the user's gesture controls.

Map g to FOUR separate output curves with different timing windows:

```swift
// 1. Chat content similarity transformation (scale 1.0 → ~0.3, runs g ∈ [0.03, 0.55])
let chatContentScaleCurve = smoothstep(0.03, 0.55, g)
let chatContentScale = 1.0 - chatContentScaleCurve * (1.0 - 0.3)  // 1.0 → 0.3

// 2. Cell bounds migration (heightConstraint chatRestExt → naturalH, runs g ∈ [0.50, 0.75])
let boundsCurve = smoothstep(0.50, 0.75, g)
let height = chatRestExt - boundsCurve * (chatRestExt - naturalH)
cell.heightConstraint?.constant = height

// 3. Cell-rest chrome fade-in (alpha 0 → 1, runs g ∈ [0.75, 0.95])
let chromeCurve = smoothstep(0.75, 0.95, g)
labelStack.alpha = chromeCurve
pinchGlyph.alpha = chromeCurve

// 4. Atmospheric gradient revelation (implicit — emerges as chat content shrinks)
// No explicit curve; the canvas pageGradientLayer becomes visible naturally as
// chat content reduces in size below viewport coverage.
```

**Critical: the smoothstep ranges OVERLAP slightly to preserve continuous curvature.** Stage B's curve doesn't end at g=0.50 (where Stage C begins); rather, Stage B continues into 0.55 with diminishing dominance while Stage C ramps up from 0.50. This overlap zone (0.50–0.55) is where the two transformations co-exist with smooth velocity transfer.

**Mechanism for chat content scale (key choice):**

Two options:
- **A) Direct scale transform on chatContent.layer:** `chatContent.layer.transform = CATransform3DMakeScale(s, s, 1)`. Pure similarity transformation. May need translation adjustment to keep the visual fixed-point centered.
- **B) Z-translation engaging m34 (current §23 approach):** the existing hybrid Z + alpha already does this, but the Z magnitude was tied to (1-progress). For staged behavior, Z should be driven by chatContentScaleCurve instead.

The user's emphasis on "similarity transformation" suggests Option A — uniform scaling without the depth-perspective associations of Option B. But Option B (m34) is substrate-purer per §23. **Recommendation:** Option A directly with `CATransform3DMakeScale(s, s, 1)` for explicit similarity transformation. Optionally combine with Option B's residual Z for atmospheric depth.

**Gesture input remap:**

Currently `handlePinchChanged` writes `heightConstraint.constant = clampedExtension` directly from pinch scale (TC:1056-1092). To remap, this becomes:

```swift
// in handlePinchChanged, replace direct heightConstraint write with g-derived staged updates:

let pinchScaleRatio = recognizer.scale / pinchState.initialScale
// rawExtensionFactor is current/initial extension, in [0, 1+] range
let rawExtensionFactor = pinchScaleRatio  // 1.0 at start (no compression), <1.0 as user pinches in
// For reverse direction: g goes from 0 (at start, no compression) to 1 (full compression to cell-rest)
let g = max(0.0, min(1.0, 1.0 - rawExtensionFactor))   // approximate; refine with calibration

cell.applyReverseGestureProgress(g)
```

And on the cell side:

```swift
// CellView.applyReverseGestureProgress(_ g: CGFloat)
// Drives all four staged curves per §42.6 implementation proposal.
func applyReverseGestureProgress(_ g: CGFloat) {
    let g = max(0.0, min(1.0, g))

    // Stage B — chat content similarity transformation
    let chatContentScaleCurve = smoothstep(AlphaCurve.stageB_g_start, AlphaCurve.stageB_g_end, g)
    let chatContentScale = 1.0 - chatContentScaleCurve * (1.0 - AlphaCurve.chatContentMinScale)
    chatContentContainer?.layer.transform = CATransform3DMakeScale(chatContentScale, chatContentScale, 1)
    chatContentContainer?.alpha = 1.0 - chatContentScaleCurve  // tied to scale

    // Stage C — cell bounds migration
    let boundsCurve = smoothstep(AlphaCurve.stageC_g_start, AlphaCurve.stageC_g_end, g)
    let chatRestExt = (viewport.height / naturalHeight) * naturalHeight
    let targetHeight = chatRestExt - boundsCurve * (chatRestExt - naturalHeight)
    heightConstraint?.constant = targetHeight

    // Stage D — cell-rest chrome fade-in
    let chromeCurve = smoothstep(AlphaCurve.stageD_g_start, AlphaCurve.stageD_g_end, g)
    labelStack.alpha = chromeCurve
    pinchGlyph.alpha = chromeCurve
    chatRestAffordance.alpha = 1.0 - chromeCurve  // inverse — affordance fades OUT as chrome fades IN
}
```

With tokens:

```swift
extension AlphaCurve {
    // Stage B: chat content similarity transformation
    static let stageB_g_start: CGFloat = 0.03
    static let stageB_g_end: CGFloat = 0.55
    static let chatContentMinScale: CGFloat = 0.3   // chat content scales 1.0 → 0.3

    // Stage C: cell bounds migration
    static let stageC_g_start: CGFloat = 0.50
    static let stageC_g_end: CGFloat = 0.75

    // Stage D: cell-rest chrome appearance
    static let stageD_g_start: CGFloat = 0.75
    static let stageD_g_end: CGFloat = 0.95
}
```

### §42.7 — Open design questions before implementing §42.6

These are non-trivial decisions that should be made BEFORE committing to the implementation:

- **Q-S1 — Forward direction symmetry.** Should the FORWARD direction (tap → chat-rest) ALSO use this staged decomposition (in reverse: bounds expand first, then chat content materializes)? Or should forward stay as-is (single-progress driven via cane curve / MorphChoreographer)? The current forward via tap path is validated; touching it risks breaking visual identity.
- **Q-S2 — Pinch-commit forward.** The forward-via-pinch-commit path (`playTapToChatMorph` via MorphChoreographer) uses a single arc duration. Should it be re-derived to mirror the staged reverse?
- **Q-S3 — Spring vs. release-snap.** Currently `springToCellRest` engages at pinch release. With staged curves, should the spring drive the GESTURE PARAMETER g (and let the curves derive their own values) or drive heightConstraint directly (current behavior)? Driving g preserves the staged behavior on release; driving heightConstraint short-circuits the staging.
- **Q-S4 — Atmospheric gradient.** Currently the gradient is part of the canvas substrate. With staged reverse, the gradient appears naturally as chat content shrinks. But the top chrome (inward arrows + "..." menu) in the reference video appears tied to a specific curve. Does this menu chrome need its own dedicated alpha curve, or does it fall out of substrate behavior?
- **Q-S5 — "..." menu chrome.** The reference video shows a "..." (three-dot) menu chrome at top-right of the screen during the gesture. **This is NOT in the current implementation.** Adding it would be a new chrome element with its own alpha curve. Out of scope for staged-curvature retrofit but flagged here.
- **Q-S6 — Loading dots correlation.** The reference video shows loading dots appearing in the bottom-left of the just-collapsed active cell at the END of the gesture. Our §22 / Phase 12 design currently has dots as a CONVERSATION-WIDE state, not tied to the most-recently-collapsed cell. Should the dots be auto-triggered after a successful reverse gesture (as if the user just sent a message → the conversation is now "thinking")? This is a different behavior than purely external activity-triggered dots.

### §42.8 — Acceptance criteria for the staged reverse implementation

Once §42.6 is implemented:

- [ ] Single-frame screenshot at g≈0.30: chat content visibly scaled down BUT cell bounds STILL edge-to-edge (no rounded card visible)
- [ ] Single-frame screenshot at g≈0.55: chat content at minimum scale + just-starting cell rounded edges
- [ ] Single-frame screenshot at g≈0.65: cell bounds clearly visible, chrome NOT yet visible
- [ ] Single-frame screenshot at g≈0.85: cell bounds final + chrome fully faded in
- [ ] No velocity discontinuities at stage boundaries (visual smoke test: record the transition; no perceptible "snaps")
- [ ] XCUITest `test_03_pinchInFromChat_revertsToCellList` still passes
- [ ] Maestro flow `02-tap-cell` still passes (no forward regression)
- [ ] InvariantHardeningTests pass

### §42.9 — Implementation phase reference

If the user approves §42.6's proposal, this becomes **Phase 13 — Staged reverse curvature** with these waves:

- Wave 13.1: define AlphaCurve stage tokens (stageB/C/D _g_start/_end constants)
- Wave 13.2: `CellView.applyReverseGestureProgress(_ g: CGFloat)` method per sketch
- Wave 13.3: modify `TimelineCanvas.handlePinchChanged` to derive g from pinch scale and call `cell.applyReverseGestureProgress(g)` instead of directly writing heightConstraint
- Wave 13.4: modify `springToCellRest` to spring on g (or convert g → heightConstraint at spring tick)
- Wave 13.5: visual regression: compare screenshot at multiple g values against §42.1 reference frames
- Wave 13.6: XCUITest + Maestro regression

Estimated duration: 3-5 days with 2-3 iterations on the stage boundary values (Q-S calibration).

### §42.10 — Empirical-confidence caveat

This analysis derives stage boundaries from VISUAL observation of 18 sampled frames out of 60. The boundaries reported (p≈0.40 for Stage B end, p≈0.20 for Stage C end, etc.) are within ±0.05 confidence — they're indicative, not pixel-precise. Phase 13 implementation will need 2-3 calibration passes against side-by-side video comparison to refine the smoothstep ranges.

The user's instruction was "be super analytical and look at all details" — this analysis does that for the 18 sampled frames. The 42 unsampled frames could refine the boundaries further but are unlikely to revise the FIVE-STAGE decomposition or the staged-ness conclusion.



## §43 — Reverse-pinch DEEP retrofit (perceptual-deepening, full 60-frame programmatic trajectory)

**Generated 2026-05-25.** Retrofit driven by user feedback that §42 was "missing alot of granularity and depth" and that bounds/dimensions/spacing/position across the gesture progress vs at rest were under-examined. §43 supersedes §42 where they conflict; §42 remains as the perceptual narrative, §43 is the measured signal underneath it.

**Methodology change vs §42:** §42 sampled 18 frames visually. §43 extracts ALL 60 frames programmatically (PIL + numpy), with reference-pixel signals (chrome darkness, atmospheric gradient distance) sampled per-frame, and the active cell's bounding box detected via center-column scan + horizontal segment scan. Trajectory verdict written to PERCEPTUAL-AUDIT-LOG.md (Phase 0 of /perceptual-deepening — BLOCKING gate satisfied before any verbal motion claim in this §43 was made).

**Source data:** `_frames/dot_pinch.mov` 4-8s window → 60 PNG frames at /tmp/dot_pinch_frames/frame_NNNN.png. Trajectory extractor scripts at /tmp/trajectory_v2.py and /tmp/trajectory_v3.py. Per-frame trajectory JSON at /tmp/dot_pinch_trajectory_v2.json and /tmp/dot_pinch_trajectory_v3.json.


### §43.1 — Calibration finding: cell-fill and page-surface are visually indistinguishable

Pixel calibration at frames 1 and 60 reveals:

| Token | On-disk RGB | Frame-60 rendered RGB | Δ per channel |
|---|---|---|---|
| Theme.Cell.fill `#f6efef` | (246, 239, 239) | (235, 232, 236) | ~11 |
| Theme.Page.surface `#ede9ee` | (237, 233, 238) | (238, 233, 237) — gap pixel | ~1 |
| Theme.Page.bottom `#d8aab4` | (216, 170, 180) | (207, 147, 153) — atmospheric pixel | ~16 |

**Cell.fill rendered vs Page.surface rendered: ~3 units per channel apart. VISUALLY INDISTINGUISHABLE.**

**Phenomenological implication:** the rounded card "cell" we perceive in the reference is NOT distinguished from background by a strong color contrast between two near-white surfaces. It is distinguished by:
1. **Rounded corners** (the edge geometry, not the fill)
2. **The surrounding atmospheric gradient** (Theme.Page.bottom mauve-pink at the bottom of the viewport, fading up)

Our current implementation has the SAME relationship: Cell.fill `#f6efef` and Page.surface `#ede9ee` are nearly identical near-white tones. The cell's visual presence comes from its rounded silhouette set against the gradient atmosphere — not from a foreground/background color contrast.

**Action for implementation:** do NOT introduce a "card lift" via stronger color contrast. The reference deliberately uses near-equal cell-fill and page-surface. Continue with the existing tokens.


### §43.2 — Chrome appearance trajectory (S-curve with rapid-rise at 48-52% gesture progress)

Top-left chrome darkness sampled at pixel (78, 80) — the location where the "inward-arrows" affordance appears as chrome materializes. Higher darkness = chrome more visible.

| Frame | Gesture % | chrome_L | Δ from baseline |
|---|---|---|---|
| 1-11 | 0-18% | 70-73 | 0 (baseline blank) |
| 26 | 43% | 73 | 0 |
| 27 | 45% | 83 | +10 — **chrome onset** |
| 28 | 47% | 96 | +23 |
| 29 | 48% | 108 | +35 |
| 30 | 50% | 150 | +77 — **rapid rise** |
| 31 | 52% | 150 | +77 |
| 33-37 | 55-62% | 111-129 | plateau, noise |
| 39 | 65% | 153 | +80 |
| 40 | 67% | **212** | **+139 — saturated** |
| 41-60 | 68-100% | 212 | constant — chrome final |

**Onset → saturation: 22 frames** (frame 26 → frame 40). Equivalent to 43-67% of gesture progress.
**Rapid-rise zone: frames 28-30** (47-50% gesture progress). Within 3 frames, darkness jumps 96 → 150 (+54).
**Saturation: frame 40** (67% gesture progress). Reaches 212 and holds for remaining 20 frames.

**Pattern classification:** monotonic S-curve OR a smoothstep with delayed onset. Maps cleanly to a `smoothstep(0.43, 0.67, gestureProgress)` driver.

**Implementation primitive implied:**
```swift
let chromeAlpha = smoothstep(0.43, 0.67, gestureProgress)
chromeView.alpha = chromeAlpha
```

This means the inward-arrows / "...""/ etc. affordances should fade in over the gesture window [0.43, 0.67] — they start invisible, ramp through 28% gesture progress, and lock in at 67% gesture progress (one third of the gesture remains AFTER chrome is fully visible).


### §43.3 — Active cell first becomes perceptible as a discrete card at ~52% gesture progress

The center-vertical-column scan detects a card-shaped cell-fill segment for the first time at frame 31 (52% gesture progress). Before this frame, the active cell is still nearly viewport-edge-to-edge and not yet a "discrete card" with visible margin around it.

| Frame | Gesture % | Detection state | Interpretation |
|---|---|---|---|
| 1-30 | 0-50% | No card detected (or unreliable bubble interiors) | Still chat-state: content fills viewport edge-to-edge |
| 31 | 52% | **First clear card detection: 750w × 236h, top=896, bottom=1131** | Card emerges from chat-extent; perception of "this is a contained cell" begins |
| 34 | 57% | 741w × 653h | Card height begins resolving toward final |
| 37 | 62% | 704w × 540h | Card visibly settling |
| 40 | 67% | 691w × 485h | Card width has overshoot (below final 702) |
| 43 | 72% | **687w × 457h — minimum width** | Width spring undershoot apex |
| 49 | 82% | 690w × 439h | Width rebounding |
| 60 | 100% | **702w × 438h — final rest** | Cell-rest dimensions |

**Critical temporal relationship: chrome onset (45%) PRECEDES card-emergence (52%) by ~7% gesture progress.** The chrome affordances begin to fade in ~7% before the user can perceive the active cell as a discrete bounded card.

**Phenomenological reading:** the affordances announce the impending cell-state *before* the cell-state's bounds are physically visible. This is a coordination of perception (chrome appears) and physics (bounds resolve) that creates anticipation — the user sees the chrome before they see the card it's chrome for.

**Action for implementation:** chrome's smoothstep driver `[0.43, 0.67]` must begin slightly before the cell-bounds-migration's driver. Cell-bounds-migration should have its rapid-resolve zone around 52-72% gesture progress (frames 31-43).


### §43.4 — Cell-rest target dimensions (empirically measured from frame 60)

| Property | Value | Fraction of viewport |
|---|---|---|
| Top y | 842 | 50.7% from top |
| Bottom y | 1279 | 76.9% from top |
| Height | **438 px** | 26.4% of 1662 |
| Width | **702 px** | 89.1% of 788 |
| Center y | 1060 | 63.8% from top |
| Center x | 394 | 50.0% (centered) |
| Horizontal inset (per side) | 43 px | 5.45% per side |

**Comparison to current implementation values** (`TimelineCanvas` / `Theme.Layout`):
- `Theme.Layout.cellHorizontalInset` should produce a width of ~702 on a 788 viewport → inset per side = 43 px. Check current value.
- Cell-rest height = 438 px on a 1662 viewport. With status bar + chrome consuming ~150 px from top, the cell occupies ~26% of the viewport vertically. Check `naturalCellHeight`.

**Falsification test for future regressions:** if a screenshot of the cell-rest state shows the cell at substantially different bounds than (left=43, right=745, top=842, bottom=1279) ±5 px, the cell-rest geometry has drifted from the reference.


### §43.5 — Inter-cell spacing CONVERGES from a large gap to 21 px at cell-rest

Spacing between the active cell's top edge and the bottom edge of the cell ABOVE it (the previous-conversation cell in the list):

| Frame | Gesture % | spacing_above (px) | Δ |
|---|---|---|---|
| 31 | 52% | 55 | first measurable |
| 37 | 62% | 120 | +65 (cells far apart) |
| 40 | 67% | 74 | −46 |
| 43 | 72% | 48 | −26 |
| 46 | 77% | 35 | −13 |
| 49 | 82% | 30 | −5 |
| 52 | 87% | 26 | −4 |
| 55 | 92% | 25 | −1 |
| 58 | 97% | 22 | −3 |
| 60 | 100% | **21** | −1 |

**Spacing trajectory: monotonically decreasing from 120 (frame 37) to 21 (frame 60).** Front-loaded — covers ~60% of the convergence in the first 30% of the resolve time.

**Phenomenological reading:** the cells in the list ARE NOT sitting at their final spacing during the gesture. The active cell migrates INTO the inter-cell spacing — the gap between cells closes as the cell-list settles. At the moment chat-state ends and cell-card begins to be perceptible (frame 31, 52% progress), the active cell appears with a noticeable gap above it. By the time the gesture completes (frame 60, 100%), the gap has converged to the cell-list's resting 21 px.

**Implementation primitive implied:** inter-cell spacing is a function of `gestureProgress`, not a static constant during the gesture. At rest, spacing = `Theme.Layout.cellSpacing` (currently 24 in logical points × ~scale = ~21 px observed). During the gesture, spacing ramps from a larger gap (corresponding to the cell list being "spread out" while the active cell is mid-migration) down to the resting value.

Possible implementation:
```swift
let restingSpacing: CGFloat = 24
let expandedSpacing: CGFloat = 120 / scale  // ~60 in logical pts on 2x device
let currentSpacing = mix(expandedSpacing, restingSpacing, smoothstep(0.52, 1.0, gestureProgress))
```

OR equivalently, the cell list's vertical layout is driven by a `listExtension` parameter that goes from 1.0 (extended) to 0.0 (compact) as the gesture completes, and inter-cell spacing = `restingSpacing + listExtension * extraGap`.


### §43.6 — Active cell WIDTH has a spring overshoot signature (under-critically damped)

Width trajectory across the 30 frames after first-detected-as-card:

| Frame | Gesture % | Width (px) | Δ |
|---|---|---|---|
| 31 | 52% | 750 | first |
| 34 | 57% | 741 | −9 |
| 37 | 62% | 704 | −37 |
| 40 | 67% | 691 | −13 |
| 43 | 72% | **687** ← **MINIMUM (overshoot below final)** | −4 |
| 46 | 77% | 689 | +2 |
| 49 | 82% | 690 | +1 |
| 52 | 87% | 698 | +8 |
| 55 | 92% | 700 | +2 |
| 58 | 97% | 703 | +3 |
| 60 | 100% | 702 | −1 |

**WIDTH IS NON-MONOTONIC.** Path: 750 → 687 → 702 = falls below the final value by 15 px (at frame 43), then rebounds.

**This is a SPRING SIGNATURE — specifically, an under-critically damped spring.** Critical damping would settle monotonically; this overshoots, so damping ratio is < 1.0.

**Overshoot magnitude:** 15 px below final / 48 px total displacement (750→702) = 31% relative overshoot. This corresponds to damping ratio approximately ζ ≈ 0.55-0.65 in a standard second-order spring.

**Phenomenological reading:** the cell width does NOT smoothly settle to its final dimension; it briefly tightens past its resting width before relaxing back. This is the "snap" or "tightness" perceived in the reference — the cell isn't slack; it has a physical springiness as it lands.

**Implementation primitive implied:** width settling cannot be a smoothstep or single Bezier curve. It MUST be a spring with under-critical damping. Use `SpringAnimator<CGFloat>` (already exists in our substrate) with:
- response (~natural period): ~0.4s (based on frame timing: undershoot at frame 43 = 72% progress = ~0.4s into the resolve)
- damping ratio: ~0.6 (produces ~30% relative overshoot)

**Falsification test:** if our reverse-direction width animation arrives at 702 monotonically, the implementation has lost the spring signature. Reference clearly shows non-monotonic width.


### §43.7 — Active cell HEIGHT is monotonic (critically-or-over-damped)

Height trajectory:

| Frame | Height (px) | Δ |
|---|---|---|
| 37 | 540 | first reliable |
| 40 | 485 | −55 |
| 43 | 457 | −28 |
| 46 | 444 | −13 |
| 49 | 439 | −5 |
| 52 | 437 | −2 |
| 55 | 436 | −1 |
| 60 | 438 | +2 (final) |

**HEIGHT IS MONOTONIC** (decreasing) with front-loading: covers 75% of displacement in the first 30% of resolve time, then asymptotes.

**This is a CRITICALLY-OR-OVER-DAMPED SPRING.** No overshoot, fast initial decay, asymptotic approach.

**Decoupling from width:** width is under-critically damped (overshoots); height is critically-or-over-damped (no overshoot). **The two springs have different damping ratios.** They are DECOUPLED.

**Implementation primitive implied:** width and height require SEPARATE spring animators with different damping ratios. They cannot share a single `extensionAnimator` if the goal is to match the reference's signature.

Current implementation: `extensionAnimator: SpringAnimator<CGFloat>` drives height extension. Width is derived from horizontal inset which is currently driven by `setCamera(progress:)` per-frame. **This is the right structure for height (spring) but wrong for width (currently progress-driven smoothstep, should be spring with overshoot).**

**Action for implementation:** introduce a separate `widthSpringAnimator` (or repurpose existing structure) with damping ratio ≈ 0.6, so width has its own spring physics independent of progress. On pinch release, both springs engage; height settles monotonically, width overshoots and rebounds.


### §43.8 — Active cell vertical migration: 92 px downward during resolve

Active cell center_y trajectory (post-first-detection):

| Frame | center_y | Δ |
|---|---|---|
| 37 | 968 | first reliable |
| 40 | 1017 | +49 |
| 43 | 1040 | +23 |
| 46 | 1052 | +12 |
| 49 | 1057 | +5 |
| 52 | 1060 | +3 |
| 55 | 1061 | +1 |
| 60 | 1060 | (final) |

**Active cell migrates DOWNWARD by 92 px (968 → 1060) from first card detection to cell-rest.** Monotonic, front-loaded.

**Phenomenological reading:** the active cell does NOT appear at its final list-position. It appears slightly ABOVE its final position and migrates down into it as the cell-list settles. This is consistent with the active cell being "lifted up" during the chat-state (it's the cell that was tapped/expanded, near the center of the viewport) and needing to translate down into its row-in-list position as the cell-list compacts.

**Combined with §43.5 (spacing convergence):** the cells above and the active cell are BOTH MOVING. The space between them is collapsing as both ends contribute. From frame 37 to frame 60:
- Active cell top moved from y=699 → y=842 (down by 143 px)
- Above-cell bottom moved from y=579 → y=821 (down by 242 px) — wait, need to verify this
- Spacing went from 120 → 21

So the cell ABOVE the active is also migrating; the spacing collapse is the COMBINED effect of both cells settling into their positions. This is critical: it's NOT the active cell sliding into a stationary list. The whole list is settling together.

**Implementation primitive implied:** the cell-list's positioning is a function of `gestureProgress`. Each cell's position is computed from the list's layout origin + (cellIndex * (cellHeight + cellSpacing)), and BOTH `cellHeight` and `cellSpacing` are gesture-driven. As the gesture progresses from 0 to 1, the list compacts.


### §43.9 — Atmospheric gradient settles at 67% gesture progress

Bottom-center pixel sampled at (394, 1600) — center of viewport near bottom, where Theme.Page.bottom gradient should appear when the chat-state's content is gone.

Distance from target Theme.Page.bottom RGB (216, 170, 180):

| Frame | Gesture % | grad_distance | Interpretation |
|---|---|---|---|
| 1-24 | 0-40% | 70 (constant) | Pixel covered by chat content; not yet gradient |
| 25 | 42% | 192 | Chat content fading; transient composite color |
| 26-30 | 43-50% | 61, 234, 234, 67, 190 | Oscillating during fade |
| 31-37 | 52-62% | 102, 101, 115, 75 | Approaching gradient color |
| 39 | 65% | 59 | |
| 40 | 67% | **59** | **Locked at final gradient color** |
| 41-60 | 68-100% | 59 (constant) | Atmospheric gradient stable |

**Onset → settling: frames 24-40** (40-67% gesture progress).
**Settled: frame 40 onward** (67% to 100%).

**Co-settling with chrome:** chrome also reaches its final value at frame 40 (see §43.2). **Both the gradient and the chrome lock in at exactly 67% gesture progress.** This is a coordinated "the cell-state is now structurally settled" milestone, with 33% of the gesture remaining for the SPRINGS (width, height, spacing) to settle physically.

**Phenomenological reading:** at 67% gesture progress, the VISUAL SCAFFOLDING of the cell-state is complete — chrome is visible, atmosphere is visible. After 67%, what remains is the PHYSICAL SETTLE — the cell bounds rebounding into place via springs. This is a two-phase resolve:
1. **Phase A — visual scaffolding (0-67% gesture progress):** content fades, chrome appears, gradient resolves
2. **Phase B — physical settle (52-100% gesture progress):** cell bounds spring to rest (overlaps with end of Phase A)

The two phases OVERLAP from 52-67% gesture progress (15% overlap zone, frames 31-40). This overlap is where the cell becomes visible as a card AND the chrome/gradient are still resolving simultaneously — this is the "active emergence" zone.


### §43.10 — Refined implementation proposal (replaces §42.7-§42.8 stage-level guesses)

§42 proposed a 5-stage decomposition with stage boundaries at p≈0.20, 0.40, 0.60, 0.70. §43 supersedes these with empirically-measured drivers.

**Animation driver topology (replaces §42's stage-based mental model):**

```
Reverse-pinch (gesture progress p: 0 → 1, where p = 1 means cell-rest reached)

DRIVER 1: contentAlpha (chat content opacity)
  smoothstep(0.0, 0.45, p)  →  chat content fades from 1.0 to 0.0
  Locked at 0.0 for p > 0.45

DRIVER 2: chromeAlpha (inward arrows, "...", title chrome)
  smoothstep(0.43, 0.67, p)  →  chrome fades from 0.0 to 1.0
  Locked at 1.0 for p > 0.67

DRIVER 3: gradientAlpha (Theme.Page.bottom atmospheric mauve)
  smoothstep(0.42, 0.67, p)  →  atmosphere becomes visible
  Locked at 1.0 for p > 0.67

DRIVER 4: cellHeight  (spring, critically/over-damped)
  Trigger: pinch release (p > some threshold, e.g. 0.30)
  Target: 438 px (Theme.Layout.naturalCellHeight in physical pts)
  SpringAnimator: damping ≈ 1.0, response ≈ 0.35s
  Monotonic settle, no overshoot

DRIVER 5: cellWidth  (spring, UNDER-CRITICALLY damped)
  Trigger: pinch release (p > some threshold, e.g. 0.30)
  Target: 702 px (Theme.Layout viewport width - 2*horizontalInset)
  SpringAnimator: damping ≈ 0.6, response ≈ 0.40s
  Overshoots by ~15px below target, then rebounds

DRIVER 6: cellSpacing (list inter-cell gap)
  smoothstep(0.30, 1.0, p) inverted, mapping from expandedSpacing → restingSpacing
  Or coupled to cellHeight via a spring with matching response

DRIVER 7: activeCellOffset_y (cell migration into list position)
  Spring, critically damped, target = naturalListPosition
  Magnitude: ~92 px translation downward
  Co-engages with cellHeight on pinch release
```

**Two-phase model derived from data:**

```
Phase A — "Visual scaffolding" (0% → 67% gesture progress)
  DRIVER 1: contentAlpha fades out
  DRIVER 2: chromeAlpha fades in
  DRIVER 3: gradientAlpha fades in
  These are gestureProgress-driven (smoothsteps).

Phase B — "Physical settle" (engaged when pinch released; runs to rest)
  DRIVER 4: cellHeight spring (monotonic)
  DRIVER 5: cellWidth spring (overshoot)
  DRIVER 6: cellSpacing collapse
  DRIVER 7: activeCellOffset_y spring (monotonic)
  These are spring-physics-driven, NOT progress-driven.

OVERLAP (52% → 100% gesture progress equivalent):
  Phase A drivers still resolving while Phase B springs are running.
  This produces the "active emergence" zone — card visible while chrome/atmosphere finish materializing AND while bounds spring to rest.
```

**Critical correction to §42:** §42 implied a single progress-driven curve. §43 establishes that the resolve is HYBRID — some drivers are progress-driven (alphas, smoothsteps), others are spring-driven (bounds, spacing, position). The reverse direction is NOT a single curve; it is a coordinated handoff between progress drivers and physics drivers.


### §43.11 — Action items implied by §43 (for Phase 13 implementation)

1. **Add cellWidth spring animator.** Currently width derives from horizontal inset driven per-frame by camera. Needs its own SpringAnimator<CGFloat> with damping ≈ 0.6.
2. **Verify cellHeight spring damping.** Existing extensionAnimator should be ζ ≈ 1.0 (critically damped, monotonic). Confirm or adjust.
3. **Add gesture-progress-driven cellSpacing.** Currently `Theme.Layout.cellSpacing` is constant. During the gesture, spacing should ramp from ~60 logical pts (expanded) to current value.
4. **Verify chrome alpha driver maps to [0.43, 0.67] gesture progress.** If currently mapped to a different window, retune.
5. **Verify gradient alpha driver maps to [0.42, 0.67] gesture progress.** Co-settle with chrome.
6. **Active cell y-translation:** verify the cell migrates ~92 px downward during resolve. If currently snapping to position or migrating with wrong magnitude, fix.
7. **Two-phase mental model:** document in code comments that reverse direction has Phase A (progress-driven alphas) and Phase B (spring-driven bounds). Where they overlap (52-67%), both run simultaneously.
8. **Maestro/visual test:** capture screenshots at gesture progress p=0.0, 0.25, 0.45, 0.52, 0.67, 0.85, 1.0 and verify match reference frames 1, 15, 27, 31, 40, 51, 60.


### §43.12 — Confidence + falsification

**Confidence:** the per-element measurements in §43.2-§43.9 are programmatic; the trajectories are extracted from all 60 frames not just 18. Pattern classifications (smoothstep, under-critically-damped spring, monotonic spring) follow from observed monotonicity + overshoot data and are well-grounded.

**Lower-confidence claims:** specific damping ratios (ζ ≈ 0.6 for width) are estimated from overshoot magnitude alone — frame timing isn't precise enough to derive the natural period exactly. Phase 13 implementation should treat these as starting parameters subject to side-by-side video comparison tuning.

**Falsification tests (concrete, runnable):**
- §43.1: extract pixel at (394, 921) from frame 60 in reference video. If RGB differs from (235, 232, 236) ± 5 per channel, calibration claim is wrong.
- §43.4: cell-rest bounds should be (left≈43, right≈745, top≈842, bottom≈1279). Screenshot the reference cell-rest state; verify within ±5 px.
- §43.6: width must overshoot below its final value during settle. If implementation's width monotonically decreases to 702, signature is wrong.
- §43.7: height must NOT overshoot. If implementation's height oscillates around 438, damping ratio is too low.
- §43.9: gradient color at (394, 1600) should reach distance < 65 from (216, 170, 180) by 67% gesture progress and hold. If our implementation's gradient settles earlier or later, retune the smoothstep range.



## §44 — Reverse-pinch wiring map (file:line citations, derived from §43 + primary-source verification 2026-05-25)

**Premise correction (load-bearing, supersedes prior framing in §43.10–§43.11 wiring proposals):**

The substrate ALREADY reaches chat content via the dual-representation architecture:
- **`ChatContentContainer`** — installed as a CellView subview at `CellView.swift:114` via `installChatContentIfNeeded(...)`. Substrate-reachable (contentHost.sublayerTransform propagates; m34 perspective applies; master display link drives). Persists across cell-pool LRU round-trips (max 20).
- **`ConversationStateController`** — `CellView.swift:119`. Captures composer text, scroll offset, first-responder, selected text range. Survives pool round-trips.
- **`ChatViewController.view`** — transient outside-canvas representation; lives only during forward morph for VC-mediated keyboard/composer interaction. Detached and released post-handoff (`RevealCoordinator.detachAndReleaseChatVC`, line 244). At settled chat-rest, ChatVC has been released; ChatContentContainer is the rendered surface.

**No restructuring of ChatViewController's relationship to V2RootViewController is required.** Reverse-pinch operates entirely on the substrate-reachable surface (ChatContentContainer + CellView's substrate-reachable layers).

**Two existing reverse-pinch paths already shipped:**
1. **V1 default — `springToCellRest(commit:)`** at `TimelineCanvas.swift:1693`. Spring-driven: camera ↦ cell-rest-y via `cameraAnimator`; extension ↦ naturalHeight via `extensionAnimator` (TC:80). Camera and extension SHARE `spring.response` per asserted invariant (TC:1719: "Animator coordination invariant: camera + extension MUST share spring.response"). Gated by per-D14: gesture-driven shrink + spring is the V1 default.
2. **Phase 11 cinematography — `playPinchToCellsMorph(forCellAt:carriedExtensionVelocity:)`** at TC:1646. Gated by `reverseCinematographyEnabled = false` (TC:1636). Uses MorphChoreographer with INVERSE MorphChoreography (`startCameraY → endCameraY = lastCellRestScrollY + bounds.height/2`, `startHeight → endHeight = naturalH`, sin-bell Y/Z arc). Mirrors forward's pinch-commit pattern.

§44 maps §43's 7 drivers to these existing paths and identifies the deltas required to match the reference video's physics.


### §44.1 — Driver-to-existing-infrastructure mapping

| §43 Driver | Target | Existing infrastructure | Present in V1 spring? | Present in Phase 11? | Delta required |
|---|---|---|---|---|---|
| 1. contentAlpha | `cell.chatContentContainer.alpha` | `ChatContentContainer` at `CellView.swift:114`; alpha currently driven by `CellView.setCamera(_:viewport:)` per progress (see CellView:346) | Partial — driven by camera, not by gesture-progress directly | Same — driven by setCamera | Verify smoothstep window `[0.0, 0.45]` matches reference; may need to retune `setCamera`'s progress→alpha mapping for chatContent |
| 2. chromeAlpha (cell-rest labels + chat-rest affordance) | `cell.labelStack.alpha`, `cell.chatRestCenterLabel.alpha`, `cell.chatRestAffordance.alpha`, `cell.pinchGlyph.alpha` | All driven by `CellView.setCamera(_:viewport:)` at CellView:346 per progress | YES | YES | Verify smoothstep windows match §43.2 (chrome enters at `[0.43, 0.67]`; chat-rest affordance fades on opposite curve) |
| 3. gradientAlpha (atmospheric mauve) | Edge mask gradient layer on TimelineCanvas | Configured at `TimelineCanvas.swift:181+` (bottom mask uses `Theme.Page.bottom`); driven by `updateEdgeMaskAlphas()` (TC:1624, 1678) | YES (canvas-level) | YES | Verify alpha curve in `updateEdgeMaskAlphas` matches §43.9's `[0.42, 0.67]` smoothstep |
| 4. cellHeight spring | `cell.heightConstraint.constant` | `extensionAnimator: SpringAnimator<CGFloat>` at TC:80; engaged in `springToCellRest` at TC:1722–1730 | YES — fully wired | NO (MorphChoreography drives height via curve, not spring) | Verify `extensionAnimator.spring` damping ≈ 1.0 (critical) per §43.7. Currently shares response with camera (TC:1719 invariant) |
| 5. cellWidth spring | `cell.widthConstraint.constant` / `cell.leadingConstraint.constant` | NONE. Width currently progress-driven via `setCamera` → `horizontalInset` (CellView:420+); width is NOT independently sprung | NO | NO | **NEW**: add `widthSpringAnimator: SpringAnimator<CGFloat>` to TimelineCanvas; damping ≈ 0.6 per §43.6. NOT subject to the camera-extension shared-response invariant (width axis is independent of camera y-translation) |
| 6. cellSpacing convergence | TimelineCanvas list layout's inter-cell gap | Inter-cell spacing currently derived from per-cell layout in `updateNeighborTranslations()` (TC:1623, 1677); driven by `Theme.Layout.cellSpacing` (constant) | Partial — exists but constant, no gesture drive | Same | **NEW**: introduce gesture-progress-driven `listSpacingExtension: CGFloat ∈ [0, 1]` parameter on TimelineCanvas; layout pass interpolates `cellSpacing` between resting and expanded value |
| 7. activeCellOffset_y | `cameraAnimator` writes to `camera.translation` | `cameraAnimator` at TC (animator infra) → `applyCameraTransform()` at TC:470 mutates `contentHost.layer.sublayerTransform` | YES — fully wired via `cameraAnimator.animate(to:velocity:spring:)` at TC:1712 | YES (via MorphChoreography) | Verify camera target `lastCellRestScrollY + bounds.height/2` (TC:1706) produces the ~92px downward migration observed in §43.8 |

**Summary of deltas:**
- 5 of 7 drivers already wired (Drivers 1, 2, 3, 4, 7) — most need parameter verification, not new code
- 2 of 7 drivers genuinely missing (Drivers 5, 6) — require new substrate pieces
- 1 architectural invariant to navigate: the asserted camera-extension shared-response invariant at TC:1719 — width's spring is on an independent axis and is NOT subject to it


### §44.2 — Driver 1 (contentAlpha) wiring detail

**Target:** `cell.chatContentContainer.alpha`

**Current implementation:** `CellView.setCamera(_:viewport:)` at `CellView.swift:346` derives a per-cell progress value from camera position relative to viewport, then writes `chatContentContainer.alpha = f(progress)` along with chrome alphas. The progress-to-alpha mapping is currently embedded in setCamera.

**§43.1 finding:** chat content fades 1.0 → 0.0 over gesture-progress window `[0.0, 0.45]`. Locked at 0.0 for `p > 0.45`.

**Required change:**
1. Verify the current alpha mapping in setCamera matches `smoothstep(0.0, 0.45, p_reverse)` where `p_reverse` is the gesture-progress of the reverse-pinch.
2. If the mapping is camera-distance-based (not gesture-progress-based), introduce a gesture-progress signal that overrides or supplements the camera-distance signal during reverse-pinch. Likely a new `reverseGestureProgress: CGFloat` on TimelineCanvas, written by `handlePinch(_:)`, read by `setCamera` to bias chatContent alpha.
3. The forward direction's contentAlpha is handled by RevealCoordinator's cross-fade (not CellView.setCamera). Reverse direction MUST use a different mechanism — direct write to `chatContentContainer.alpha` via gesture-progress.

**Falsification test:** at gesture-progress p=0.45, `cell.chatContentContainer.alpha` should equal 0.0 ± 0.05. At p=0.225 (midpoint), alpha should equal 0.5 ± 0.10.


### §44.3 — Driver 2 (chromeAlpha) wiring detail

**Targets:**
- `cell.labelStack.alpha` (cell-rest chrome — date, topic summary, today label): fades 0 → 1 over reverse
- `cell.chatRestCenterLabel.alpha` (chat-rest title): fades 1 → 0 over reverse
- `cell.chatRestAffordance.alpha` (top-right inward-arrows affordance at chat-rest): fades 1 → 0 over reverse
- `cell.pinchGlyph.alpha` (bottom-right cell-rest affordance): fades 0 → 1 over reverse

**Current implementation:** all four alphas are driven by `CellView.setCamera(_:viewport:)` at CellView:346 via per-cell progress.

**§43.2 finding:** cell-rest chrome (labelStack + pinchGlyph) enters via smoothstep `[0.43, 0.67]` — i.e. fully visible at 67% gesture progress, invisible at < 43%. Chat-rest chrome (chatRestCenterLabel + chatRestAffordance) is the inverse — fully visible at 0% (chat-rest), invisible at > 67%.

**Required change:** verify each of the four alpha curves in `setCamera` matches the §43.2 finding. If forward direction's mapping is correct but reverse direction needs different bounds, parameterize the smoothstep bounds by direction.

**Falsification test:** at gesture-progress p=0.43, `cell.labelStack.alpha` should equal 0.0 ± 0.05. At p=0.67, alpha should equal 1.0 ± 0.05.


### §44.4 — Driver 3 (gradientAlpha — atmospheric mauve-pink) wiring detail

**Target:** TimelineCanvas's edge mask gradient layers — specifically the BOTTOM mask which uses `Theme.Page.bottom` (sRGB-locked `#d8aab4`).

**Current implementation:**
- Edge mask layers configured at `TimelineCanvas.swift:181-188` (bottom uses `Theme.Page.bottom.sRGBLockedCGColor`)
- Three-stop sRGB-locked gradient at TC:229-236
- Alpha driven by `updateEdgeMaskAlphas()` (called from `setCamera` at TC:1624, and from morph completion at TC:1678)

**§43.9 finding:** bottom gradient pixel converges to final color over `[0.42, 0.67]` gesture progress. Locked at final from p=0.67 onward.

**Required change:**
1. Verify `updateEdgeMaskAlphas` interpolates bottom-mask alpha over a window equivalent to `[0.42, 0.67]` of gesture progress (currently may be camera-distance-based, not gesture-progress-based — verify and adjust).
2. The mask's BLENDING with chat content (chat content covers the mask when alpha=1; mask shows through when chat content fades) is the mechanism that produces the "gradient settles at 67%" signal in the video. Verify this composition.

**Falsification test:** at gesture-progress p=0.67, sample the on-screen pixel at viewport (W/2, 0.96*H). Color should be within 65 RGB-units of (216, 170, 180). At p=0.42, should be substantially less converged (distance > 100).


### §44.5 — Driver 4 (cellHeight spring) wiring detail

**Target:** `cell.heightConstraint.constant`

**Current implementation:** `extensionAnimator: SpringAnimator<CGFloat>` at TC:80. Engaged by `springToCellRest(commit:)` at TC:1693–1731. Spring profile selected by `springProfile(for: commit)` at TC:1224.

**Asserted invariant (load-bearing):** TC:1719 — `extensionAnimator.spring.response == cameraAnimator.responseForTesting`. Camera and extension MUST share spring.response.

**§43.7 finding:** height is monotonic with front-loading; critically-or-over-damped (no overshoot). Damping ratio ≈ 1.0.

**Required change:**
1. Read `springProfile(for: .pinchToCells)` (TC:1224) and verify damping ratio ≈ 1.0.
2. If damping is lower (e.g. ζ < 0.9), height will overshoot — which contradicts §43.7. Adjust damping to ζ ≈ 1.0.
3. The asserted shared-response invariant is preserved (camera and extension keep shared response; only damping is adjusted).

**Open verification:** read TC:1224's `springProfile(for:)` to see current damping. If it's already ζ ≈ 1.0, no change.

**Falsification test:** during reverse, sample `cell.heightConstraint.constant` per frame. Trajectory should be monotonically decreasing from chat-rest-extension toward `naturalHeight`. If any frame shows height < naturalHeight (overshoot), damping is too low.


### §44.6 — Driver 5 (cellWidth spring — NEW INFRASTRUCTURE) wiring detail

**Target:** `cell.widthConstraint.constant` (and possibly `cell.leadingConstraint.constant` for centering)

**Current implementation:** width is NOT independently sprung. It derives from `horizontalInset` (CellView:225), which is updated by `setCamera`/per-progress writes inside `CellView.setCamera(_:viewport:)` at CellView:346–420+. Width follows the gesture's progress curve, not a spring.

**§43.6 finding:** width has SPRING OVERSHOOT signature — under-critically damped, ζ ≈ 0.6, ~15px relative overshoot (~31% of total displacement).

**Required NEW infrastructure:**
1. Add `widthSpringAnimator: SpringAnimator<CGFloat>` to TimelineCanvas (parallel to existing `extensionAnimator`).
2. NOT subject to the camera-extension shared-response invariant (width axis is independent of camera y-translation).
3. Profile: damping ≈ 0.6, response calibrated to produce the observed overshoot timing (frame 43 minimum = 72% gesture progress).
4. Engaged in `springToCellRest`: target = `bounds.width - 2 * activeCell.naturalHorizontalInset`. Value initialized from current `widthConstraint.constant`. Velocity carried from gesture release.
5. On each `widthSpringAnimator.valueChanged`, write to `activeCell.widthConstraint.constant` (and update `leadingConstraint.constant` to keep cell centered if width changes asymmetrically).

**Coordination concern:** `cell.setCamera(_:viewport:)` currently also writes to horizontal inset via its progress-driven path. During reverse, the spring should OWN width writes; setCamera's horizontal-inset path must NOT compete. Gate setCamera's horizontal-inset write on `widthSpringAnimator.state != .running` OR introduce explicit ownership handoff at gesture release.

**Falsification test:** during reverse settle, sample `cell.widthConstraint.constant` per frame. There MUST be at least one frame where width < final-width (the overshoot frame). If width is monotonic, damping is wrong or progress-curve is still owning width.


### §44.7 — Driver 6 (cellSpacing convergence — NEW INFRASTRUCTURE) wiring detail

**Target:** TimelineCanvas list layout's inter-cell vertical gap.

**Current implementation:** inter-cell spacing is constant — derived from `Theme.Layout.cellSpacing` and applied during per-cell layout in `updateNeighborTranslations()` (TC:1623, 1677) and at list-install time. There is NO gesture-progress-driven mechanism for spacing.

**§43.5 finding:** during reverse, spacing converges from ~120 px (at p=0.62) to 21 px (at p=1.0). Monotonically decreasing, front-loaded. The cell-list COMPACTS as the gesture completes.

**Required NEW infrastructure:**
1. Add `listSpacingExtension: CGFloat ∈ [0, 1]` parameter on TimelineCanvas. 0 = resting spacing; 1 = expanded spacing (~5× resting).
2. Write this parameter from `handlePinch(_:)`'s reverse-direction gesture-progress derivation.
3. Modify `updateNeighborTranslations` (or the equivalent layout pass) to use:
   ```swift
   let effectiveSpacing = Theme.Layout.cellSpacing * (1.0 + listSpacingExtension * (expandedMultiplier - 1.0))
   ```
   where `expandedMultiplier ≈ 5` produces the observed 120px → 21px convergence.
4. On gesture release, the listSpacingExtension parameter should DECAY to 0 — coupled to extensionAnimator's spring response (the spacing settle and the height settle should be co-timed per §43.8's "combined cell-list settle" observation).

**Coordination concern:** if listSpacingExtension is driven by `springToCellRest`'s spring (rather than directly by gesture-progress), it inherits the spring response. If it's driven by an independent gesture-progress smoothstep, it can have a different curve. §43.5's data shows monotonic decrease — either approach can produce that.

**Falsification test:** at p=0.62, measure the rendered vertical gap between the active cell's top edge and the above-cell's bottom edge. Should be ~120 px (within ±15). At p=1.0, should be ~21 px (within ±3).


### §44.8 — Driver 7 (active cell vertical migration) wiring detail

**Target:** `camera.translation` (which writes to `contentHost.layer.sublayerTransform.tx/ty`).

**Current implementation:** `cameraAnimator.animate(to:velocity:spring:)` at TC:1712–1718, engaged by `springToCellRest`. Target = `lastCellRestScrollY + bounds.height / 2` (TC:1706). Spring profile shared with `extensionAnimator` (TC:1719 invariant).

**§43.8 finding:** active cell migrates ~92 px downward (center_y 968 → 1060 in viewport units). Monotonic, front-loaded.

**Required change:**
1. Verify that `lastCellRestScrollY + bounds.height / 2` produces the correct ~92 px downward migration from the chat-rest active-cell position.
2. The migration is the COMBINED effect of (a) camera translation and (b) active cell's height collapsing (which shifts its center y down). Both contribute. §43.8 attributes ~92 px to the combination.
3. No new infrastructure needed; just verify the target geometry matches the reference.

**Falsification test:** capture cell.frame.midY in viewport coordinates at p=0.62 (frame 37 in reference) and at p=1.0 (frame 60). The delta should be ~92 px. If significantly off, recompute `lastCellRestScrollY` or check `cameraTarget` calculation.


### §44.9 — Gesture-progress normalization (raw pinch scale → p ∈ [0, 1])

**Current state:** the codebase uses gesture state directly — `UIPinchGestureRecognizer.scale` and `velocity` — and routes via `handlePinchEnded(...)` (referenced indirectly via TC:1158+). A normalized progress signal is not currently exposed as a single canvas-level property.

**§43 requirement:** all 7 drivers reference `p ∈ [0, 1]` where p=0 is chat-rest and p=1 is cell-rest reached. Each driver's smoothstep/spring window is expressed in this normalized space.

**Required NEW infrastructure:**
1. Add `reverseGestureProgress: CGFloat ∈ [0, 1]` on TimelineCanvas — written during pinch tracking; read by setCamera + the driver-coordination layer.
2. Mapping from raw pinch scale: a pinch starts at some initial scale (≈1.0) and the user contracts it (scale < 1.0 means contracting; reverse direction is when the user is contracting fingers). The "initial pinch scale" captures the chat-rest reference scale; progress = `1 - currentScale / initialScale` clamped to `[0, 1]`.
3. Alternative: derive progress from current cell height vs natural cell height — `p = 1 - (heightConstraint.constant - naturalHeight) / (chatRestHeight - naturalHeight)`. This is geometry-driven and works during both gesture-tracking AND spring-settle phases.
4. The geometry-driven derivation is preferred — it produces a continuous progress signal that smoothly extends from gesture tracking into spring settle. Phase A drivers (alphas) automatically transition from "gesture-driven" to "spring-resolved" using the same signal.

**Decision:** geometry-driven progress = `1 - (currentHeight - naturalHeight) / (chatRestHeight - naturalHeight)`. Source of truth = `cell.heightConstraint.constant`.


### §44.10 — Engagement state machine integration

**Current state:** existing engagement states per CLAUDE.md §2.5:
- `activeCellIndex` (Int?) on TimelineCanvas
- `morphInProgress` (derived: `morphChoreographer?.isRunning ?? false`)
- `isQuiet` (derived: composite predicate)
- `EngagementState` enum: `.idle / .engaged(completion:) / .stopping`

**Reverse-pinch flow:**
1. `handlePinch.began`: user starts a reverse-pinch from chat-rest. Engagement state transitions from `.engaged(completion: ...)` (chat-rest steady state) to a new tracking state. Composer first-responder must resign at this transition (see §44.11).
2. `handlePinch.changed`: per-frame, update `reverseGestureProgress` from cell height. All Phase A drivers read this and adjust alphas. Phase B drivers (springs) are NOT yet engaged.
3. `handlePinch.ended`: classify via `GestureCommit`. If `.pinchToCells` and `reverseCinematographyEnabled`, route to `playPinchToCellsMorph`. Else route to `springToCellRest`. Either way, springs engage and run to settle.
4. Settle completion: `tryClearActiveCellAtRest` (TC:1738) fires when BOTH springs reach target. Transitions engagement state to `.idle`.

**Required change:**
- No new state cases; existing `.engaged(completion:)` / `.stopping` / `.idle` ladder is sufficient.
- The completion ladder must coordinate: width spring + height spring + camera spring + listSpacingExtension all reach target before `setActiveCellIndex(nil)` fires.
- Extend `tryClearActiveCellAtRest` (TC:1738) to also check `widthSpringAnimator.value ≈ target` and `listSpacingExtension ≈ 0`.


### §44.11 — Composer first-responder resign timing

**Current state:** `RevealCoordinator.swift:233` calls `destination.becomeFirstResponder()` during forward handoff. There is NO explicit `resignFirstResponder` call for reverse direction in the codebase (verified via grep).

**Why it matters:** at chat-rest, the composer's text field may be first-responder (keyboard visible). When the user starts a reverse-pinch, the keyboard MUST resign before the chat-content alpha begins fading — otherwise the keyboard's view stays visible while chat-content fades, producing a visual glitch (composer fades while keyboard stays).

**Required change:**
1. In `handlePinch.began` (the gesture handler in TimelineCanvas), if the gesture indicates reverse direction (pinch contracting OR velocity signals reverse intent), call `activeCell.chatContentContainer.composerResignFirstResponderIfNeeded()` (or equivalent) on the active cell's composer.
2. The resign must happen BEFORE Phase A drivers begin moving alphas — otherwise alpha fades and keyboard stays in a desynchronized way.
3. Keyboard dismissal animation is typically driven by UIResponder framework with its own timing. Coordination concern: if the reverse-pinch resolve is faster than the keyboard's natural dismissal, the cell-rest state will be reached before the keyboard is fully gone. Need to verify acceptable visual behavior.

**Falsification test:** start reverse-pinch from chat-rest with keyboard up. By the time gesture-progress reaches 0.2, the keyboard should be visibly dismissing or dismissed. If keyboard stays visible until p > 0.5, resign timing is wrong.


### §44.12 — Cross-driver coordination at the Phase A / Phase B overlap zone (52–67% gesture progress)

**§43.10 finding:** Phase A drivers (smoothsteps on alphas) and Phase B drivers (springs on bounds) OVERLAP during gesture progress p ∈ [0.52, 0.67]. In this zone, both classes of driver are simultaneously writing.

**Concrete coordination cases:**

**Case 1 — width writes during overlap.** Phase A (gesture-progress) wants width to follow a smoothstep. Phase B (widthSpring) is engaged AFTER pinch release and writes the spring's current value. If user pinches partway and releases at p=0.55, the spring engages at width=750 (current); but the gesture-progress curve would put width at smoothstep(0.55) ≈ 700 (already partway). The spring needs to start FROM the current width, NOT from the gesture-progress-derived width.

   **Resolution:** `widthSpringAnimator.value` is initialized to the actual current `cell.widthConstraint.constant` (not derived from gesture-progress). The spring takes over from wherever the user released. Phase A's progress-driven write to width is GATED — it only runs while spring is NOT running (`widthSpringAnimator.state != .running`).

**Case 2 — height writes during overlap.** Same as Case 1, but for height. Existing `extensionAnimator` already handles this (engaged at gesture release, takes value from current heightConstraint at TC:1722).

**Case 3 — alpha writes during overlap.** Phase A's smoothsteps continue running on gesture-progress (which is geometry-derived per §44.9 — keeps updating during spring settle as height changes). Phase B's springs change height/width, which updates gesture-progress, which updates alphas. **The alphas remain continuous across the gesture-release transition because gesture-progress is geometry-derived, not gesture-state-derived.** This is the key design property of the geometry-driven progress.

**Resolution principle:** Phase A drivers ALWAYS read from `reverseGestureProgress` (geometry-derived). Phase B drivers (springs) ALWAYS own their respective bounds (height, width, spacing, camera y) once engaged. The springs' value updates flow into the geometry, which flows into Phase A's progress signal, which flows into alphas. Single source of truth (cell geometry) per axis avoids contention.


### §44.13 — Cancellation behavior (mid-reverse interrupt)

**Cancellation cases:**

**Case A — user release with pinchToCells classification:** triggers `springToCellRest` (or `playPinchToCellsMorph` if cinematography enabled). Springs run to settle. Default success path.

**Case B — user release with `.cancelled` classification:** the gesture didn't meet pinchToCells threshold; springs run BACK to chat-rest. Existing infrastructure handles this via `springProfile(for: .cancelled)` (TC:1224).

**Case C — user release with `.tapToChat` (unlikely in reverse-pinch, but possible if classifier returns this):** treat as cancellation; spring back to chat-rest.

**Case D — scene deactivates mid-spring:** `cancelInFlightAnimations()` is called (existing infrastructure). For reverse-pinch, this must also stop `widthSpringAnimator`. Current cancellation path (TC:1024) stops `extensionAnimator`; widthSpringAnimator needs the same treatment.

**Case E — new pinch-out starts during reverse settle (re-engage):** user changes their mind, pinches back toward chat-rest. Springs must reverse direction. SpringAnimator's velocity continuity handles this — when target changes mid-flight, the spring carries velocity into the new target. Existing infrastructure supports this for `extensionAnimator`; widthSpringAnimator needs to support it too (no special handling — SpringAnimator already does velocity-continuous retargeting).

**Required change:**
1. In `cancelInFlightAnimations()` (TC equivalent), add `widthSpringAnimator.stop(immediately: true)`.
2. In `handlePinch.began` for re-engagement during settle: if `widthSpringAnimator.state == .running`, do NOT stop it; instead update its target on .changed and let velocity continuity carry it.


### §44.14 — Open verification items (3 pending code-reads)

The following items are not blocking §44's wiring map, but must be verified before Phase 13 implementation begins.

**V1 — `springProfile(for: .pinchToCells)` damping ratio.** Read `TimelineCanvas.swift:1224`. If damping ratio < 0.9, height will overshoot — contradicts §43.7. Adjust to ≈ 1.0 if needed.

**V2 — Atmospheric gradient alpha curve.** Read `updateEdgeMaskAlphas()` (referenced TC:1624, TC:1678) and verify the bottom mask alpha curve matches §43.9's `[0.42, 0.67]` smoothstep window. If currently a different curve (e.g. linear over the full gesture, or camera-distance-based), retune.

**V3 — `CellView.setCamera(_:viewport:)` progress derivation.** Read CellView:346–442. Verify the progress signal currently used is geometry-derived (cell height vs natural height) — if so, the §44.9 design works as-is. If camera-distance-derived, introduce a separate `reverseGestureProgress` parameter that overrides during reverse-pinch.


### §44.15 — Test plan

**Unit / integration tests (additions to `InvariantHardeningTests` or a new `ReversePinchTests`):**

1. `test_widthSpring_overshoots_during_reverse` — engage reverse-pinch, sample `cell.widthConstraint.constant` over time; assert there exists a frame where width < final-width (overshoot present).
2. `test_heightSpring_monotonic_during_reverse` — engage reverse-pinch, sample `cell.heightConstraint.constant` over time; assert the sequence is monotonically decreasing.
3. `test_chromeAlpha_reaches_1_at_67_percent_progress` — at gesture-progress p=0.67, assert `cell.labelStack.alpha >= 0.95` and `cell.chatRestAffordance.alpha <= 0.05`.
4. `test_gradientAlpha_locked_after_67_percent` — at p=0.70, sample mask alpha. At p=0.85, alpha should differ by < 0.05 from p=0.70 (locked).
5. `test_cellSpacing_collapses_to_resting_at_completion` — at p=1.0, inter-cell gap between active and above-cell equals `Theme.Layout.cellSpacing × deviceScale` ± 2 px.
6. `test_cameraExtensionSharedResponse_invariant_preserved` — assert TC:1719's invariant still holds after width-spring addition (camera + extension share spring.response; width spring has independent response).
7. `test_widthSpring_velocity_continuous_on_retarget` — start reverse-pinch, mid-settle re-engage forward pinch; assert width does not snap (velocity-continuous transition).

**Maestro flows + visual screenshots (per `feedback_visual_testing_every_wave`):**

1. Reverse-pinch flow from chat-rest with keyboard up → cell-rest. Screenshot at p=0.0, 0.25, 0.45, 0.52, 0.67, 0.85, 1.0. Compare against reference frames 1, 15, 27, 31, 40, 51, 60 from `_frames/dot_pinch.mov`.
2. Reverse-pinch CANCEL flow: pinch partway, release with `.cancelled` classification. Screenshot mid-cancel. Verify cell springs back to chat-rest cleanly.
3. Re-engage flow: reverse-pinch partway, release at p=0.55, immediately re-pinch forward. Screenshot the velocity-continuous transition.
4. Scene-deactivate flow: reverse-pinch in progress, backgrounding the app, foregrounding. Verify recovery via existing `cancelInFlightAnimations` + foreground rehydration.


### §44.16 — Phase 13 implementation action list (ordered by dependency)

1. **Verification reads (V1, V2, V3 from §44.14).** Outcome: confirmed or refined parameter set. Estimated 30 min.
2. **Introduce `reverseGestureProgress: CGFloat` on TimelineCanvas** (geometry-derived per §44.9). Write site: `handlePinch.changed` + spring valueChanged callbacks. Read sites: setCamera, future driver coordination.
3. **Audit + retune `CellView.setCamera`'s alpha curves** (Drivers 1, 2, 3) against §44.2 / §44.3 / §44.4 falsification tests.
4. **Audit + retune `springProfile(for: .pinchToCells)`** damping (Driver 4) per §44.5.
5. **Add `widthSpringAnimator: SpringAnimator<CGFloat>`** to TimelineCanvas (Driver 5). Wire engage in `springToCellRest`. Wire stop in `cancelInFlightAnimations`. Add valueChanged callback that writes to active cell's widthConstraint. Gate setCamera's horizontal-inset path while running.
6. **Add `listSpacingExtension: CGFloat`** parameter to TimelineCanvas (Driver 6). Modify list-layout pass to use it. Wire gesture-progress drive + spring-coupled decay.
7. **Add `composerResignFirstResponderIfNeeded()`** equivalent on ChatContentContainer + invoke from `handlePinch.began` for reverse direction.
8. **Extend `tryClearActiveCellAtRest`** to check all 4 springs (camera, height, width, listSpacing) before clearing activeCellIndex.
9. **Add tests** (§44.15 list).
10. **Maestro + visual screenshot suite** comparing against reference frames.
11. **Iterate parameters** until §43 falsification tests pass with ≤ ±5px / ±0.05 alpha tolerance.


### §44.17 — Confidence + load-bearing constraints

**Confidence:** HIGH for the wiring map. Most drivers map to existing infrastructure; 2 new substrate pieces (widthSpring + listSpacingExtension) are mechanically straightforward. The architectural premise (ChatContentContainer is substrate-reachable; no ChatVC restructuring) is primary-source-verified.

**Load-bearing constraints to preserve (per CLAUDE.md):**
- K1: `contentHost.layer.sublayerTransform` remains the single camera applier — widthSpring writes to widthConstraint (a layout constraint, NOT sublayerTransform), so this is preserved.
- K2: `m34 = -1/1000` — untouched.
- K3: Single `CADisplayLink` — widthSpring registers via AnimationController like all other animators; no parallel display link.
- K4: `cellPoolByConversationID` identity-keyed pool — untouched.
- K5: `CATransaction.withSuppressedActions` discipline — all reverse-pinch writes to alpha and widthConstraint must wrap in this.
- K6: `EngagementState.engaged(completion:)` completion ladder — extended via `tryClearActiveCellAtRest` updates.
- K7: 4 additive `CABasicAnimation`s in `animateCameraToChatRest` — untouched (that's forward direction).
- K8: `MorphChoreographer`'s sin-bell Y/Z arc — untouched unless Phase 11 cinematography is enabled (which would use it for reverse too).

**Asserted invariant to preserve:** TC:1719 — `extensionAnimator.spring.response == cameraAnimator.responseForTesting`. The new widthSpringAnimator does NOT need to share response with camera+extension (different axis). The invariant must continue to assert only between extension and camera.



## §45 — Root-cause tracing of §44 implementation tasks (/root-cause-tracing skill, 2026-05-25)

User invoked /root-cause-tracing comprehensively across each implementation task in §44.16 to surface integration concerns, edge cases, wiring conflicts, and dead-code risks BEFORE Phase 13 implementation begins. Per the skill protocol: orchestrator (this section) does Wave 1 cross-cutting framework + cross-task dependency map; 7 parallel agents do Wave 2 per-task root-cause traces; Wave 3 synthesis cross-references the agent outputs to surface integration-layer blind spots that no individual trace catches.

**Scope:** the 7 implementation tasks from §44.16 (steps 2–8). Verification reads (V1–V3) are research, not implementation, so not traced. Test additions + Maestro flows are downstream of implementation, so traced indirectly via their dependencies on the implementation tasks.

**Trace topology:**

| § | Task | Agent dispatched | Status |
|---|---|---|---|
| §45.1 | Cross-task dependency map (orchestrator) | — | This section |
| §45.2 | Cross-task synthesis themes (orchestrator) | — | This section |
| §45.3 | reverseGestureProgress | T1 | in flight |
| §45.4 | setCamera alpha audit (Drivers 1, 2) | T2 | in flight |
| §45.5 | springProfile damping for height | T3 | in flight |
| §45.6 | widthSpringAnimator | T4 | in flight |
| §45.7 | listSpacingExtension | T5 | in flight |
| §45.8 | composerResignFirstResponderIfNeeded | T6 | in flight |
| §45.9 | tryClearActiveCellAtRest extension | T7 | in flight |
| §45.10 | Wave 3 synthesis — cross-cutting findings | — | pending all traces complete |
| §45.11 | Wave 4 metacognitive audit | — | pending Wave 3 complete |


### §45.1 — Cross-task dependency map (orchestrator Wave 1)

The 7 implementation tasks are NOT independent. Several DEPEND on others; some COLLIDE with others. The order of implementation matters.

**Dependency graph:**

```
T1 (reverseGestureProgress)
   ├── T2 (setCamera alpha audit) — Drivers 1,2,3 read T1's signal
   ├── T4 (widthSpringAnimator) — width spring may consult T1 for gate logic
   ├── T5 (listSpacingExtension) — gesture-progress drive reads T1
   └── T7 (tryClearActiveCellAtRest) — settle predicate reads T1 (progress = 1)

T3 (springProfile damping for height) — INDEPENDENT (parameter retune of existing animator)

T4 (widthSpringAnimator)
   ├── T7 (tryClearActiveCellAtRest) — adds widthSpring.value==target check
   └── T2 (setCamera alpha audit) — must gate width-derived inset writes during widthSpring run

T5 (listSpacingExtension)
   └── T7 (tryClearActiveCellAtRest) — adds listSpacing≈0 check

T6 (composerResignFirstResponderIfNeeded) — DEPENDS on direction-detection in handlePinch
   └── REQUIRES reverse-direction classification at .began (or .changed) — see T1's gesture-progress sign for detection

T7 (tryClearActiveCellAtRest extension)
   └── DEPENDS on T4 + T5 existing (to check their settle states)
```

**Implementation order implied by dependencies:**

1. **T3** first (independent; lowest risk; can be done in isolation). If §43.7 says damping should be 1.0 and existing is different, retune now — no other task depends on this happening first, but doing it first gives early signal on whether retuning is safe.
2. **T1** next (foundation for T2, T4, T5, T7). Introduces reverseGestureProgress; doesn't change existing behavior if no driver reads it yet.
3. **T2** after T1 (audit + retune setCamera to read reverseGestureProgress for reverse-direction alpha curves). Behavior changes here.
4. **T4** after T2 (widthSpringAnimator added; setCamera's horizontal-inset write gated during widthSpring run — gate logic depends on T2 being in place).
5. **T5** parallel to T4 (listSpacingExtension; independent from widthSpring; both can land together).
6. **T6** after T1 (uses reverse direction classification from handlePinch, which T1's geometry-derivation makes well-defined).
7. **T7** last (depends on T4 + T5 existing).


### §45.2 — Cross-task synthesis themes (orchestrator Wave 1)

Themes that emerge across multiple tasks; agents per-task cannot see these because they don't share context. The Wave 3 synthesis (§45.10) will resolve these against agent outputs.

**Theme A — Direction detection at gesture begin.** T6 (composer resign) requires detecting "this gesture is reverse" at .began. T1's geometry-derived progress doesn't help at .began (cell is at chat-rest, progress=0; can't yet distinguish "user is starting a reverse pinch" from "user is starting some other interaction"). Direction at .began is inferred from the gesture's INITIAL VELOCITY (pinch-in vs pinch-out). Question: is there an existing direction classifier at .began? If not, T6 needs to introduce one OR defer resign to first .changed that confirms reverse direction. The latter introduces a 1-frame keyboard-visible-while-alpha-fading window — acceptable?

**Theme B — Source of truth for reverseGestureProgress during settle.** T1 says progress is geometry-derived (1 - (h-naturalH)/(chatRestH-naturalH)). During gesture tracking, height is gesture-driven (user input); progress flows from height. After release, height is spring-driven (extensionAnimator); progress flows from spring's height. This is CONTINUOUS. But: width is sprung SEPARATELY (T4) with DIFFERENT damping. listSpacingExtension is sprung SEPARATELY (T5) or progress-driven (still TBD per agent T5). So Phase A's alphas read from progress (geometry), Phase B's springs (width, listSpacing) DRIVE progress (geometry follows the height spring specifically). This produces a HIERARCHY: height-spring is the master signal; width and listSpacing are slaves. Implication: if width-spring overshoots, width briefly < final, but height is still settling per its own spring — progress signal does NOT see the width overshoot. Consequence: alpha curves don't track width's overshoot. This may be correct (alphas are visual signals tied to gesture progress, not to physical bounds), but verify against §43 reference frames.

**Theme C — The asserted invariant TC:1719 (extensionAnimator.spring.response == cameraAnimator.responseForTesting) and the new widthSpring.** Per §44.5/§44.6, widthSpring is on an independent axis and not subject to the shared-response invariant. But: widthSpring's response affects its settling time. If widthSpring response > camera+extension response, widthSpring is the slowest to settle, and tryClearActiveCellAtRest (T7) waits for widthSpring. The activeCellIndex-clearing thus depends on widthSpring's response. Question: should widthSpring share response too (extending the invariant) for synchrony? Or is independent response a feature (allowing width's tighter motion to settle differently)? §43's data on timing relative to other axes will guide this.

**Theme D — Gating setCamera's horizontal-inset write during widthSpring run.** T2 audit + T4 widthSpring imply that setCamera's current horizontal-inset writing path (which computes width from progress) MUST yield to widthSpring once spring engages. The gate logic is: `if widthSpringAnimator.state == .running { skip horizontal-inset write }`. But: what if widthSpring's state machine is mid-completion (after value reaches target but before state transitions to .ended — see TC:1733-1736 comment about race)? setCamera could miss one frame of write, leaving width at spring's settled value with no further updates — fine. But if setCamera is supposed to ALSO write inset for OTHER reasons (e.g. some auxiliary update path), gating it loses that. Need to verify setCamera's full responsibility for horizontal-inset writes.

**Theme E — Performance: per-frame constraint mutation across multiple cells.** T5 (listSpacingExtension) modifies layout for every cell in the list. T4 (widthSpringAnimator) modifies widthConstraint on the active cell. Both run during gesture tracking + spring settle. Per-frame constraint mutation triggers Auto Layout invalidation which cascades into ChatContentContainer's internal layout (T2 audit area). For 20 cells × 60fps × N frames, this can be heavy. Mitigation: prefer transform.translation.y over constraint changes for inter-cell spacing (CALayer transform is much cheaper than constraint change); reserve constraint changes for the active cell's height/width where geometry must be authoritative.

**Theme F — Phase 11 cinematography path.** playPinchToCellsMorph (TC:1646) uses MorphChoreographer + curve-driven height — it BYPASSES extensionAnimator + widthSpringAnimator entirely. If `reverseCinematographyEnabled = true`, §43's spring overshoot signature (T4) is bypassed, and the Phase 11 curve owns motion instead. §43's analysis was of `dot_pinch.mov`; that video shows spring physics (overshoot, decoupled damping), not the inverse-MorphChoreography curve. So `dot_pinch.mov` represents the V1 spring path's target physics, NOT the Phase 11 cinematography target. Implication: §44's tasks apply ONLY to the V1 spring path (reverseCinematographyEnabled=false). Phase 11 is a separate motion-identity decision. Or: §43's findings should be propagated into Phase 11's MorphChoreography curves too, ensuring both paths share visual motion identity.

**Theme G — Dead code from §44 tasks.** Once §44 tasks land:
- The existing setCamera's per-progress chat-content alpha mapping (if any) becomes redundant for reverse direction — but is still used for forward direction's transition zone. Don't delete; gate by direction.
- The existing setCamera horizontal-inset mapping (if width spring takes over) becomes inactive during widthSpring run. Don't delete; gate.
- `RevealCoordinator.dismiss(completion:)` (RC method, "unused in handoff flow" per primary-source) may become permanently unused if reverse-pinch never invokes it. Risk: dead code accumulation.
- The 2-condition tryClearActiveCellAtRest (current TC:1738) — extended to 4 conditions, not replaced. Old version becomes 4-condition; not dead code per se.

**Theme H — Test coverage gap.** §44.15 lists 7 unit tests. None test the gesture-progress geometry-derivation (T1's core property). None test direction detection (T6's prerequisite). None test the gate logic between setCamera and widthSpring (T2 + T4 collision avoidance). Wave 3 synthesis should add these to the test plan.


### §45.3 — Trace T1: reverseGestureProgress (CRITICAL FINDINGS — supersedes §44.9)

**Verdict: §44.9 as written has a load-bearing duplication. Recommend pivot to pull-based computed property; delete the existing parallel signal.**

**Critical findings:**

1. **REDUNDANCY with `CellView.computeProgress(viewport:)`** at CV:368. The proposed `reverseGestureProgress` formula `1 - (currentH - naturalH) / (chatRestH - naturalH)` is identical (modulo 1−x inversion) to the existing per-cell `computeProgress` formula. **The signal already exists** as per-cell infrastructure. §44.9 didn't catch this.

2. **`MorphChoreographer.apply` at MC:81 writes heightConstraint directly** during Phase 11 cinematography. §44.9's two declared write-sites (`handlePinch.changed` + `extensionAnimator.valueChanged`) MISS this path. Latent only because `reverseCinematographyEnabled = false` (TC:1636) ships disabled — but a flag flip exposes the gap.

3. **Pull-based form is strictly better than stored.** Eliminates write-site enumeration (B2), lifecycle/reset/NaN management (B5), and notification mechanism (B3). Single safe formula evaluated on read.

4. **"Reverse" in the name encodes a falsehood.** Forward pinch uses the same geometric formula. Per CLAUDE.md Part 5 ("no references to tasks/audits in code — they rot"), rename to `extensionProgress` or `gestureProgress`.

5. **Per-cell vs canvas-level signal granularity.** Phase A's chrome drivers are per-cell (each cell has its own height); canvas-level scalar is correct only for `updateEdgeMaskAlphas` (canvas-owned). A single canvas-level scalar collapses both concerns only because the engagement state machine guarantees ONE active cell — an accident, not structure.

**Revised recommendation (replaces §44.9):**

```swift
extension TimelineCanvas {
    var extensionProgress: CGFloat {
        guard let idx = activeCellIndex,
              let cell = instantiatedCells[idx],
              let h = cell.heightConstraint?.constant,
              cell.naturalHeight > 0,
              bounds.height > cell.naturalHeight else { return 1.0 }
        let raw = (h - cell.naturalHeight) / (bounds.height - cell.naturalHeight)
        return max(0, min(1, 1 - raw))
    }
}
```

- **No write sites; no Morph-path integration; no NaN risk.**
- Use this canvas-level signal ONLY in `updateEdgeMaskAlphas` (canvas-owned gradient).
- Per-cell drivers continue to use `CellView.computeProgress` (don't delete it — the per-cell signal is correct for per-cell drivers per phenomenology audit; T2 confirmed neighbor cells must use their OWN progress, not the active cell's).

**Updates to §44.16 implementation order:** T1 collapses from "new substrate piece" to "computed-property accessor + audit existing computeProgress for any remaining gaps". Reduced complexity by 70%.


### §45.4 — Trace T2: setCamera alpha audit (CRITICAL FINDINGS — supersedes §44.2 + §44.3)

**Verdict: Mechanical AlphaCurve constant edits unlock 5 of 6 drivers. Two escalations required: chatRestCenterLabel hole + Driver 3 peak-vs-monotonic intent mismatch.**

**Critical findings:**

1. **The current progress signal IS geometry-derived** via `CellView.computeProgress(viewport:)` (CV:368-380). §44.14's V3 verification item is resolved: the proposed retune is unblocked.

2. **Current AlphaCurve values** (DesignSystem/AlphaCurve.swift:9-45):
   - `cellRestChromeIn=0.05, cellRestChromeFull=0.30` → must move to `0.43, 0.67`
   - `chatRestAffordanceIn=0.05, chatRestAffordanceFull=0.30` → must move to `0.43, 0.67`
   - `chatContentAlphaIn=0.05, chatContentAlphaFull=0.35` → must move to `0.0, 0.45`

3. **CRITICAL HOLE — `chatRestCenterLabel.alpha` is named in §44.3 Driver 2 list but setCamera does NOT write it.** It's mutated only by `performMorphChromeTransition` CABasicAnimation (CV:528-538) with `fillMode=.forwards, isRemovedOnCompletion=false` — a held animation that creates a presentation-layer ghost overriding synchronous writes. To satisfy §44.3, requires:
   - New applier method in setCamera, AND
   - Explicit `layer.removeAnimation(forKey: ...)` of the held animation before write, OR
   - Document chatRestCenterLabel as out-of-scope for §44 (with rationale)
   **ESCALATION:** which path is intended?

4. **CRITICAL DESIGN INTENT MISMATCH — Driver 3 (atmospheric gradient).** `updateEdgeMaskAlphas` (TC:293-319) currently computes a PEAK CURVE (bottomUp × (1-bottomDown)) — visible mid-pinch only. §43.9 wants MONOTONIC 0→1 with lock at p=0.67. The semantics differ — peak-curve says "transient decoration"; monotonic says "atmospheric scaffolding establishes and holds". **ESCALATION:** which design intent is correct? Either (a) §43.9 misreads the reference (peak-curve matches a transient mauve flash, not a hold), or (b) current code is wrong.

5. **Ownership matrix for `chatContentContainer.alpha` has 4 writers, not 3** as §44.2 implied: install-default (CV:114), RevealCoordinator atomic swap (RC:218), setCamera per-tick (CV:354), and lazy install (CV:441). Steady state is conflict-free because the `morphInProgress` gate at CV:351 sequences ownership. Verified by trace.

6. **Phase 11 cinematography (playPinchToCellsMorph TC:1646)** does NOT directly write chrome alphas. After morph completes (TC:1681), setCamera fires at final progress and snaps chrome to final values. §43 retune bypasses Phase 11 entirely. Acceptable because §43 reference is the V1 spring path; Phase 11 ships disabled.

7. **CATransaction suppression concern**: `applyMorphTickCameraWrite` (TC:1618-1626) calls `pushCameraToVisibleCells` (which iterates `cell.setCamera`) WITHOUT wrapping in `CATransaction.withSuppressedActions`. Potential implicit-animation leak during morph. Verify and wrap if needed.

**Action items for §44.16 step 3:**
- Update 6 AlphaCurve constants (mechanical, low-risk)
- Resolve chatRestCenterLabel escalation
- Resolve Driver 3 peak-vs-monotonic escalation
- Audit + fix the missing CATransaction wrap in applyMorphTickCameraWrite


### §45.5 — Trace T3: springProfile damping retune (CRITICAL FINDINGS — supersedes §44.5)

**Verdict: §44.5 names the WRONG knob. Damping is already at 1.0; `springResponse` is the divergent parameter.**

**Critical findings:**

1. **Damping ratio for `.pinchToCells` is ALREADY 1.0.** Per Tuning.swift:17 (`pinchToCellsDamping: CGFloat = 1.0`) → GestureTypes.swift:13 → springProfile(for:) at TC:1224. The §44.5 prescribed value is the existing default. **No change required for damping.**

2. **CRITICAL — Wrong knob in §44.5.** §44.5 says "response ≈ 0.35s" but Tuning.swift:15 sets `springResponse = 1.10s`. **3.14× divergence.** The empirical work (§43.7) points at response, not damping. If the user is asking this retune because the height feels wrong, damping won't help — response is the real lever. **ESCALATION:** the user should be informed that the meaningful retune is `springResponse`, not `pinchToCellsDamping`. Changing response affects BOTH camera + extension (TC:1719 invariant), which is what §44.5 likely intends anyway.

3. **Phantom degree-of-freedom at call site.** TC:1719 invariant says response MUST be shared between camera + extension; damping is permitted to differ. But `springProfile(for: commit)` returns a SINGLE Spring instance, fed to BOTH animators (TC:1710 + TC:1715). The call-site collapses the architectural permission to identity — camera de-facto inherits extension's damping. Future engineer splitting damping per-axis would need to refactor the springProfile signature.

4. **R44 (Per-Direction Profile) is the design rationale** — confirmed by `WaveR44PerDirectionProfileTests.swift`. Decision: damping is per-direction (`.tapToChat=0.62`, `.pinchToCells=1.0`, `.cancelled=0.95`); response is invariant-shared. Mutating damping is permitted; mutating response is invariant-shared and changes camera too.

5. **No behavioral test asserts §43.7's monotonic-descent invariant.** Only parameter-equality tests exist. Add a runtime test asserting `extensionAnimator.value` decreases monotonically between engage and settle.

6. **Carried velocity concern** at TC:1724 — a fast gesture-release with high velocity can produce apparent overshoot even at ζ=1.0 if `velocity * τ_response > displacement`. Untested edge case.

**Action items (revised):**
- **No change to `pinchToCellsDamping`** (already 1.0).
- **Decide on `springResponse`** — currently 1.10s, §44.5 target 0.35s. This changes both camera + extension settle times together. User confirmation needed before changing — it affects shipped phenomenology.
- Add `test_pinchToCells_height_monotonic` to InvariantHardeningTests.
- Annotate TC:1224 with a single-line comment: "ζ per-commit (R44); response invariant-shared (TC:1719)".


### §45.6 — Trace T4: widthSpringAnimator (CRITICAL FINDINGS — supersedes §44.6 + §44.12)

**Verdict: Task is NOT implementable as written. Requires paired CellView change. Performance concern unmeasured. 2 corrections + 1 design decision needed.**

**Critical findings:**

1. **CRITICAL — The gate is unimplementable as specified.** §44.6/§44.12 say "gate setCamera's horizontal-inset write on `widthSpringAnimator.state != .running`" — but **CellView has no back-reference to TimelineCanvas or its animators.** Current data flow is canvas→cell unidirectional. Three implementation options:
   - (a) Change `setCamera` signature to `setCamera(_:viewport:widthOwnedExternally:)`
   - (b) **RECOMMENDED:** Add `widthOwnedExternally: Bool` stored property on CellView, written by canvas at spring engage/disengage
   - (c) Rely on tick ordering — fragile, reject

2. **CRITICAL — Symmetric double-write required.** `cell.leadingConstraint.constant` MUST be co-mutated with `widthConstraint.constant` to preserve centering. §44.6 noted this as "possibly" — it's MANDATORY. Spring's valueChanged callback must do:
   ```swift
   widthC.constant = widthValue
   leadingC.constant = (pageWidth - widthValue) / 2
   ```
   Otherwise the cell shrinks left-edge-pinned (wrong visual).

3. **PERFORMANCE CONCERN — Per-frame layout cascade.** Each frame's `widthConstraint.constant + layoutIfNeeded()` cascades into ChatContentContainer's subtree (CellView:453+). ChatContentContainer is pinned via leading/trailing/top/bottom; its messagesScrollView + composer relayout per frame. At 120Hz, this is the dominant cost for ~50 frames during 0.4s settle. **MITIGATION OPTIONS:**
   - Measure first on iPhone 14+ baseline (frame budget)
   - Or: decouple ChatContentContainer's width from CellView during spring run (pin to fixed `pageWidth - 2 * naturalHorizontalInset`, clip via cell's `masksToBounds`)
   **ESCALATION:** measure before commitment.

4. **Phase 11 (playPinchToCellsMorph TC:1646) does NOT animate width.** During Phase 11, width stuck at whatever value `setCamera` last painted before `morphInProgress` gated CellView writes. **Decision needed:** if `reverseCinematographyEnabled = true`, should widthSpring also engage from playPinchToCellsMorph? §43's overshoot signature is from V1 spring path, not Phase 11 cinematography. ESCALATION.

5. **Forward direction unspecified.** §44.6 doesn't say whether widthSpring engages on forward. Recommendation: forward keeps progress-driven width (preserves shipped motion identity per user's "reverse-only" scope answer); the gate flag must encode direction, not just spring-running.

6. **Width is genuinely independent axis** from camera+height — confirmed by trace. Exclusion from TC:1719 invariant is correct.

7. **Test infrastructure gap.** XCTest + display-link-driven springs require a fake clock or step-mode integrator for deterministic sampling. §44.15's `test_widthSpring_overshoots_during_reverse` needs this infrastructure.

**Action items (revised):**
- **REVISED §44.6 root task:** the task is paired — TimelineCanvas widthSpringAnimator + CellView `widthOwnedExternally` flag are inseparable; commit together.
- Specify symmetric leading+width double-write in valueChanged callback.
- Measure ChatContentContainer layout-cascade cost; fall back to width-decoupling if jank observed.
- Decide Phase 11 policy (engage widthSpring from playPinchToCellsMorph yes/no).
- Add `widthSpringAnimator.stop(immediately: true)` to cancelInFlightAnimations (TC:1024).
- Build deterministic-sample test infrastructure before adding `test_widthSpring_overshoots_during_reverse`.


### §45.7 — Trace T5: listSpacingExtension (CRITICAL FINDINGS — supersedes §44.7)

**Verdict: §44.7 has TWO factual errors (phantom constant; wrong modification site). Should be DERIVED, not stored. Re-architects to a much smaller change.**

**Critical findings:**

1. **CRITICAL — `Theme.Layout.cellSpacing` is a PHANTOM.** It doesn't exist. The actual constant is `TimelineCanvas.cellSpacing` (TC:14, `static let = 24`). §44.7's prescribed formula references a non-existent namespace. Implementer hitting compile error will either invent `Theme.Layout` (collateral public-surface introduction) or inline `TimelineCanvas.cellSpacing`. **Spec correction required.**

2. **CRITICAL — §44.7 misidentifies the modification site.** `updateNeighborTranslations` (TC:734-752) is a gap-PRESERVATION function (it applies `CGAffineTransform(translationX: 0, y: ±growth*0.5)` to keep natural gaps as the active cell extends). It does NOT contain spacing logic. Actual spacing lives in `accumulatedYs()` (TC:579-599) → `pageFrameForCell` → `centerYConstraint.constant` (CV:235-237) at install time. The CORRECT modification site IS still `updateNeighborTranslations` — but composing a NEW spacing transform on top of `followActive`'s growth transform, not replacing.

3. **CRITICAL — Should be DERIVED, not STORED.** §44.9 prescribes geometry-driven progress. If `listSpacingExtension = 1 - currentCanvasProgress` (derived from existing `currentCanvasProgress` at TC:310 — already in use), there is:
   - NO new stored state
   - NO new animator
   - NO new completion-ladder entry in tryClearActiveCellAtRest (T7 extension unnecessary for this driver)
   - The signal works in BOTH directions automatically (forward + reverse share substrate)
   The §44.7 framing as "a parameter" presupposes state-as-storage; the geometry-driven §44.9 implies state-as-derivation. Pick derivation.

4. **The "120 px" measurement is in viewport pixels at chat-rest camera scale**, but implementation interpolates in page coords. The 5× multiplier is approximate. Expect tuning.

5. **§43.8's 92px active migration explicitly excludes spacing contribution** — spacing transforms apply only to NON-active cells (already enforced by `updateNeighborTranslations`'s `if index == activeIdx` branch at TC:745). No double-counting risk; active cell keeps centerY invariant.

6. **Mechanism choice (KEYSTONE):** must use ADDITIVE TRANSFORMS, not constraint mutation. Constraint mutation invalidates `accumulatedYs()` cache → `pageFrameForCell` returns stale values → `cellIndices(in: visiblePageRect)` cull computation breaks → cells flicker mid-gesture. The cell-on-transform-only approach preserves the cache invariant elegantly.

7. **CellView.followActive must accept a tuple** — currently does `transform = CGAffineTransform(...)` replacing not composing. Needs:
   ```swift
   func followActive(growth: CGFloat, spacingOffset: CGFloat, position: NeighborPosition) {
       let ty = direction * (growth * 0.5 + spacingOffset)
       transform = CGAffineTransform(translationX: 0, y: ty)
   }
   ```

**Action items (revised):**
- **REVISED §44.7:** correct `Theme.Layout.cellSpacing` → `TimelineCanvas.cellSpacing`. Reframe `listSpacingExtension` as DERIVED computed property: `var listSpacingExtension: CGFloat { 1 - currentCanvasProgress }`.
- Modify `CellView.followActive` to accept `(growth, spacingOffset, position)` triple; compose transform.
- In `updateNeighborTranslations` for each non-active cell: compute `indexDelta = |index - activeIdx|`; `spacingDelta = indexDelta * Self.cellSpacing * (expandedMultiplier - 1) * listSpacingExtension`; pass to `followActive`.
- **DROP §44.10's listSpacingExtension settle-check extension** in tryClearActiveCellAtRest — automatic (when progress=0, extension=0 by derivation).
- Add Maestro flow + screenshot diff at p=0.62 and p=1.0 (per user memory: visual testing every wave).


### §45.8 — Trace T6: composerResignFirstResponderIfNeeded (CRITICAL FINDINGS — supersedes §44.11)

**Verdict: §44.11's stated problem is PHANTOM. The REAL bug is state corruption in ConversationStateController. The proposed method needs renaming and a different responsibility.**

**Critical findings:**

1. **CRITICAL — §44.11 is factually wrong.** It says "no explicit `resignFirstResponder` call exists for reverse direction." Actually `TimelineCanvas.swift:1030` runs `self.endEditing(true)` **unconditionally at the top of handlePinchBegan**, BEFORE any geometry/camera writes. This recursively walks the responder chain and dismisses the keyboard. **The keyboard dismissal already works.** §44.11 was authored from an incomplete grep (only searched for `resignFirstResponder` literally; `endEditing` doesn't match).

2. **CRITICAL — REAL BUG: state corruption in ConversationStateController.** `ConversationStateController.composerIsFirstResponder` (CSC:23) is written ONLY by `captureFromChatVC` during forward handoff (CSC:57-63). On reverse-pinch, NOTHING clears it. Sequence to reproduce:
   1. User taps cell → forward → keyboard up → `composerIsFirstResponder = true`
   2. User reverse-pinches → `endEditing(true)` dismisses keyboard, BUT flag stays `true`
   3. User taps same cell again → new ChatVC → `bindToChatVCAtInstall` reads `true` → RC:226 restores first-responder
   4. **Keyboard pops up unbidden**, even though user dismissed it via reverse-pinch
   This is a real shipped bug, NOT hypothetical.

3. **The method's STATED purpose (resign keyboard) is redundant** with TC:1030's `endEditing(true)`. The method's UNSTATED necessary purpose is to write `stateController?.composerIsFirstResponder = false`.

4. **Naming is misleading.** `composerResignFirstResponderIfNeeded` suggests one responsibility (resign). It needs TWO (resign + clear state). Suggest renaming to `composerLeaveActiveStateIfNeeded` to reflect the dual responsibility.

5. **Direction gate at .began is UNNECESSARY.** Per the trace, direction is not classifiable at .began (forward vs reverse). But:
   - `endEditing(true)` is idempotent; unconditional call is fine
   - "IfNeeded" suffix handles the no-op case
   - Better architecture: clear the flag in `tryClearActiveCellAtRest` (TC:1738) on settle completion, separating gesture-begin (resign keyboard for visual) from settle-completion (clear state for round-trip correctness)

6. **ChatViewController.composerTextField (CVC:14) is dead code post-handoff.** Pre-existing transitional artifact; not in scope to fix here, but flag as phantom for future cleanup.

7. **Test gap:** §44.15 has no test for round-trip: forward (keyboard up) → reverse → forward → assert keyboard does NOT auto-appear on second forward. Add this test.

**Action items (revised):**
- **REVISED §44.11:** correct the spec to acknowledge `endEditing(true)` at TC:1030 already exists. Reframe the task as "fix ConversationStateController.composerIsFirstResponder state-corruption bug."
- Rename `composerResignFirstResponderIfNeeded` → `composerLeaveActiveStateIfNeeded`.
- Method's responsibility: write `stateController?.composerIsFirstResponder = false` (resign happens via TC:1030 already).
- **PREFERRED LOCUS:** call from `tryClearActiveCellAtRest` on settle completion (TC:1738), NOT from `handlePinchBegan`. Separates concerns: gesture-begin handles visual; settle handles state.
- Add round-trip test in §44.15.
- Drop direction-gate complexity entirely.


### §45.9 — Trace T7: tryClearActiveCellAtRest extension (CRITICAL FINDINGS — supersedes §44.10 step 8 of §44.16)

**Verdict: With T5's Path-A choice (listSpacingExtension derived from progress), the predicate stays at 3 conditions, not 4. Underdamped width spring creates a NEW false-positive risk that needs addressing.**

**Critical findings:**

1. **3-condition predicate, not 4.** With T5's recommendation that `listSpacingExtension` be a DERIVED property of `currentCanvasProgress`, when height reaches `naturalHeight`, progress=0 → listSpacingExtension=0 by definition. The 4th condition is mathematically redundant. **REVISED:** predicate checks (cameraAtTarget, heightAtTarget, widthAtTarget) — 3 conditions.

2. **CRITICAL — False-positive risk from underdamped width spring.** widthSpring ζ≈0.6 produces overshoot — width crosses `target` TWICE: once descending past it (overshoot), once recovering. The current `abs(value - target) < 1.0` check fires on FIRST crossing. tryClearActiveCellAtRest would clear activeCellIndex while width is still in motion (mid-rebound). **MITIGATION OPTIONS:**
   - Tighter tolerance + velocity check: `abs(value - target) < 0.5 && abs(velocity) < epsilon`
   - Check `widthSpringAnimator.state == .ended` (but per TC:1733-1736 comment, state doesn't update until AFTER completion fires)
   - Use `widthSpring.settlingDuration` elapsed instead of value-vs-target check for width specifically (settling time is closed-form per Spring.swift:48)
   **RECOMMENDED:** velocity check (cleanest; SpringAnimator exposes velocity).

3. **Phase 11 cinematography MUST be R1 (MorphChoreographer owns all axes).** `playPinchToCellsMorph` (TC:1646) bypasses tryClearActiveCellAtRest entirely (uses MorphChoreographer.engage completion at TC:1672 → direct `setActiveCellIndex(nil)`). If `reverseCinematographyEnabled = true`, widthSpring + listSpacingExtension MUST NOT be engaged separately — the choreographer's completion is authoritative. Document explicitly to avoid R2 ambiguity.

4. **Hang risk: bounds-resize mid-settle** (iPad Stage Manager, device rotation through scene-resize). Spring target set with old bounds; predicate compares against NEW `cellRestTarget = lastCellRestScrollY + bounds.height/2` (recomputed each call). Mismatch → predicate never holds. Mitigated by scene-deactivation reset (`cancelInFlightAnimations`). Acceptable risk for V1; document as known frontier.

5. **Idempotency confirmed.** Guard at TC:1739 (`activeCellIndex == expectedIdx`) makes the predicate safe under multi-fire from each spring's completion. Adding widthSpring → 3 completion callbacks → 3 calls to predicate → last fires → clears. Existing pattern scales.

6. **No race-safety test exists** in `InvariantHardeningTests`. Adding widthSpring increases call-site count from 2 to 3. Add `test_tryClearActiveCellAtRest_clears_only_when_all_axes_at_target` exercising multi-completion race.

7. **Cancellation path correctness verified.** `.cancelled` GestureCommit routes through `springToCellRest` with cellRestTarget computed against CHAT-REST (not cell-rest). Predicate's `cellRestTarget = lastCellRestScrollY + bounds.height/2` may be WRONG for cancelled path — it's computed for `.pinchToCells`. Verify the cancelled path uses a different target predicate.

8. **Predicate-of-state vs latch-of-events.** At 3 axes the predicate pattern is adequate. At 4+ axes (if a future driver adds a separate animator), refactor to `AnimatorSettleLatch(expecting: N)` for cleaner coordination + natural attachment point for watchdog. Frontier for future, not blocking now.

**Action items (revised):**
- Keep predicate at 3 conditions (camera, height, width) — listSpacingExtension is derived, no explicit check needed.
- **CRITICAL:** Add velocity check to width's settle predicate to avoid false-positive on overshoot rebound.
- Document Phase 11 R1 policy in code comment near `playPinchToCellsMorph`.
- Add multi-completion race test to InvariantHardeningTests.
- Verify cancelled-path target computation matches predicate.



### §45.10 — Wave 3: Cross-cutting synthesis (orchestrator, after all 7 traces complete)

**A. §44 spec has multiple factual errors that primary-source verification caught.**

| § | Error | Primary source contradicting |
|---|---|---|
| §44.5 | Says "retune damping ≈ 1.0" | Tuning.swift:17 — already 1.0. Real issue is `springResponse = 1.10s` vs target 0.35s |
| §44.7 | References `Theme.Layout.cellSpacing` | Phantom — actual is `TimelineCanvas.cellSpacing` (TC:14) |
| §44.7 | Modify `updateNeighborTranslations` for spacing | Misidentified — that function is gap-PRESERVATION, not spacing |
| §44.11 | "no explicit resignFirstResponder call exists for reverse" | Factually wrong — `endEditing(true)` at TC:1030 exists |

**Pattern:** §44 was authored from §43's empirical findings via top-down derivation without grounding in primary source. The user's `feedback_verify_dont_assume.md` memory exactly anticipated this failure mode. /root-cause-tracing was the corrective.

**B. Multiple proposed "new substrate pieces" duplicate existing infrastructure or should be derived, not stored.**

- T1 (`reverseGestureProgress`) → use existing `CellView.computeProgress` (CV:368) + `currentCanvasProgress` (TC:310). Pull-based computed property, not stored.
- T5 (`listSpacingExtension`) → derived from `currentCanvasProgress`, not stored. No new animator. No new completion-ladder entry.
- T6 (`composerResignFirstResponderIfNeeded`) → resign already done by `endEditing(true)`. Real work is state-flag clearing.
- T3 (damping retune) → already at target. Real work is response retune (if at all).

**Result:** ~60% of §44's "new substrate" reduces to "use existing + minor accessor" or "fix a real bug §44 missed."

**C. Width spring (T4) is the ONLY genuinely new substrate piece.** And it has 2 critical issues:
- C1: The gate from setCamera to widthSpring is NOT directly implementable; requires paired CellView change (`widthOwnedExternally: Bool` stored property)
- C2: Per-frame `widthConstraint.constant + layoutIfNeeded()` cascades into ChatContentContainer's subtree. Performance cost unmeasured. May need width-decoupling fallback.

These are blocking concerns for T4 implementation.

**D. Real bugs surfaced that §44 did not catch.**

- D1: **State corruption bug (T6):** `ConversationStateController.composerIsFirstResponder` never cleared on reverse → keyboard pops up unbidden on next forward. Shipped bug, reproducible sequence.
- D2: **chatRestCenterLabel phantom dependency (T2):** held CABasicAnimation with fillMode=.forwards creates presentation-layer ghost. Any synchronous alpha write competes.
- D3: **applyMorphTickCameraWrite missing CATransaction wrap (T2):** TC:1618-1626 doesn't wrap `pushCameraToVisibleCells` in `withSuppressedActions`. Implicit-animation leak risk.
- D4: **False-positive predicate fire (T7):** widthSpring overshoot crosses target twice → tryClearActiveCellAtRest may fire on first crossing while still in motion.

**E. Phase 11 cinematography policy is undefined.** Multiple traces (T2, T4, T7) flagged Phase 11 (`reverseCinematographyEnabled = false`) as bypassing the V1 spring path. **Recommendation: R1 policy** — when cinematography is enabled, MorphChoreographer owns ALL axes; widthSpring + listSpacingExtension are NOT engaged on that path. Document explicitly in code.

**F. Mechanism choice for spacing must be additive transforms, not constraint mutation.** Constraint mutation invalidates `accumulatedYs()` cache → `pageFrameForCell` stale → cull computation breaks. Additive transforms (composed atop `followActive`) preserve cache invariant elegantly. Modify `CellView.followActive` to accept `(growth, spacingOffset, position)` triple.

**G. Visual testing gap repeatedly noted.** Per user memory `feedback_visual_testing_every_wave.md`: every wave's orchestrator gate MUST include Maestro flows + per-state screenshots + manual visual analysis. §44.15 has unit tests but lacks the Maestro + screenshot diff infrastructure that several traces flagged as necessary (e.g., for spacing at p=0.62, width overshoot frame, etc.). Add to test plan.

**H. Single signal unification.** With T1 + T5 corrections, **`currentCanvasProgress` (TC:310) becomes the single substrate signal driving Phase A (alphas) AND part of Phase B (spacing). Width is the only Phase B driver requiring its own spring** (different damping). This is architecturally lean — one signal, one anomaly (widthSpring).



### §45.11 — Wave 4: Metacognitive audit

**What this trace exercise produced:**

- 8 critical findings the §44 spec missed (4 factual spec errors + 4 real bugs / latent risks)
- 60% reduction in scope of "new substrate" through identification of existing infrastructure
- Concrete architectural decisions (R1 Phase 11 policy; additive-transforms for spacing; widthOwnedExternally flag pairing; derived-not-stored for spacing/progress)
- Specific test infrastructure gaps (deterministic spring sampling for width; multi-completion race; round-trip keyboard state)
- Phantom dependencies surfaced (chatRestCenterLabel held animation; ChatVC.composerTextField post-handoff dead code)

**What the trace methodology biased toward:**

- Code-mechanic depth over user-perceptual depth (per several agents' self-assessment)
- Per-task isolation — agents didn't see each other's outputs; cross-cutting patterns emerged only at orchestrator-level Wave 3 synthesis
- Performance untraced in detail (T4's layout-cascade cost is "needs measurement" — frontier)

**Blind spots remaining:**

- Forward direction's interaction with §43 retune is consistently unspecified across traces (T2 noted; T4 noted; T5 noted). User's "reverse-only" scope answer may be tighter than the implementation reality — touching alphas/springs/spacing inevitably touches forward.
- Maestro / visual diff infrastructure does not exist; user memory mandates it. Wave-gate cannot pass without building it.
- The "120 px at p=0.62" measurement (§43.5) is in viewport pixels at chat-rest camera scale; interpolation in page coords. Tuning expected.
- Test infrastructure for deterministic spring sampling (XCTest + display-link springs requires fake clock or step-mode integrator).
- Accessibility (per user memory `feedback_a11y_priority.md`: document but deprioritize).

**Vindication of user memories:**

- `feedback_verify_dont_assume.md` — predicted exactly the §44 spec-vs-primary-source mismatch pattern. Trace exercise vindicated.
- `feedback_visual_testing_every_wave.md` — multiple traces flagged Maestro + screenshots as missing gates.
- `project_chat_substrate_reach.md` (from earlier today) — its claim that ChatContentContainer is substrate-reachable was consistently confirmed in T1, T2, T6 traces.

**Pivot diagnostic (anchor + breadth check):** the traces stayed anchored to concrete code citations (file:line throughout) while exploring broadly across the 6 questions × 7 tasks. The breadth caught cross-cutting patterns that depth-only would have missed. Methodology rating: pivots honored.



### §45.12 — Revised §44.16 implementation action list (incorporating all trace findings)

**Replace §44.16's 11-step list with this revised sequence:**

1. **VERIFICATION READS (V1, V2, V3 from §44.14)** — confirm or refine parameter set. Outcome: V3 resolved (geometry-derived progress confirmed at CV:368). V1 + V2 still pending.

2. **DRIVER PARAMETER UPDATES — mechanical, low-risk** (replaces old steps 3, 4 partially):
   - 2a. Update 6 AlphaCurve constants per §45.4 table:
     - `cellRestChromeIn: 0.05 → 0.43`, `cellRestChromeFull: 0.30 → 0.67`
     - `chatRestAffordanceIn: 0.05 → 0.43`, `chatRestAffordanceFull: 0.30 → 0.67`
     - `chatContentAlphaIn: 0.05 → 0.0`, `chatContentAlphaFull: 0.35 → 0.45`
   - 2b. **NO CHANGE** to `pinchToCellsDamping` (already 1.0)
   - 2c. **DECIDE on `springResponse`** — current 1.10s, §43.7 implies ~0.35s. User confirmation required (changes shipped forward + reverse motion together).

3. **ESCALATIONS — resolve before further work:**
   - 3a. `chatRestCenterLabel` hole: add applier OR document out-of-scope?
   - 3b. Driver 3 (atmospheric gradient) peak-vs-monotonic intent mismatch: redesign `updateEdgeMaskAlphas` curve?
   - 3c. Phase 11 cinematography policy: confirm R1 (MorphChoreographer owns all axes)?
   - 3d. `springResponse` retune Y/N?

4. **ARCHITECTURAL ADDITIONS (revised, smaller scope):**
   - 4a. **`extensionProgress` as computed property** on TimelineCanvas (T1 revised — no stored state, no write sites, no MorphChoreographer integration needed)
   - 4b. **`listSpacingExtension` as derived property** = `1 - currentCanvasProgress` (T5 revised — no stored state)
   - 4c. **`CellView.followActive` signature change** to accept `(growth, spacingOffset, position)` triple — enables spacing transforms
   - 4d. **`updateNeighborTranslations` enhancement** — compute per-cell spacingDelta from listSpacingExtension; pass to followActive

5. **THE ONE GENUINELY NEW SUBSTRATE PIECE: widthSpringAnimator** (T4, paired):
   - 5a. **MEASURE** per-frame layout cascade cost into ChatContentContainer subtree before commitment
   - 5b. If cost acceptable: add `widthSpringAnimator: SpringAnimator<CGFloat>` on TimelineCanvas
   - 5c. Add `widthOwnedExternally: Bool` on CellView (paired requirement)
   - 5d. Symmetric leading+width double-write in widthSpring valueChanged callback
   - 5e. Add `widthSpringAnimator.stop(immediately:true)` to `cancelInFlightAnimations`
   - 5f. If cost UNacceptable: fall back to ChatContentContainer width-decoupling design

6. **REAL BUG FIXES (uncovered by traces):**
   - 6a. **State corruption fix:** in `tryClearActiveCellAtRest` on settle completion, write `stateController?.composerIsFirstResponder = false`. Fixes the unbidden-keyboard bug (T6 D1).
   - 6b. **applyMorphTickCameraWrite CATransaction wrap:** wrap `pushCameraToVisibleCells` invocation in `withSuppressedActions` (T2 D3).
   - 6c. **chatRestCenterLabel held-animation cleanup:** per 3a decision.

7. **PREDICATE EXTENSION:** extend `tryClearActiveCellAtRest` from 2 to 3 conditions (camera + height + width); add velocity check for width to avoid false-positive on overshoot rebound (T7).

8. **TESTS:**
   - Mechanical AlphaCurve verification tests
   - Width overshoot test (requires deterministic spring sampling infrastructure)
   - Height monotonicity test
   - Round-trip keyboard state test (forward → reverse → forward, assert no auto-keyboard)
   - tryClearActiveCellAtRest race-safety test with 3-condition predicate

9. **MAESTRO + VISUAL SCREENSHOT SUITE** — build the infrastructure that user memory mandates. Capture frames at p ∈ {0.0, 0.25, 0.45, 0.52, 0.67, 0.85, 1.0} and compare against `_frames/dot_pinch.mov` frames {1, 15, 27, 31, 40, 51, 60}.

10. **ITERATE** parameters until §43 falsification tests pass with ≤ ±5px / ±0.05 alpha tolerance.



### §45.13 — Outstanding escalations summary (for user decision)

| # | Escalation | Default |
|---|---|---|
| E1 | `springResponse` retune Y/N (currently 1.10s, §43.7 implies ~0.35s; affects shipped forward + reverse motion identity) | NO (preserve shipped phenomenology) |
| E2 | `chatRestCenterLabel` — add applier OR document out-of-scope? | Add applier (it's in the reference video) |
| E3 | Driver 3 (atmospheric gradient) peak-vs-monotonic curve intent | Re-verify against reference frames; current peak-curve may be correct |
| E4 | Phase 11 cinematography policy: R1 (MorphChoreographer owns all axes) or R2 (paired engagement)? | R1 (cleanest, matches existing architectural division) |
| E5 | widthSpring layout-cascade cost: measure first, or accept-then-mitigate-if-jank? | Measure first |
| E6 | Forward direction touch policy: any §43 changes propagate to forward, or strictly reverse-only? | Strictly reverse-only per user's prior answer; revisit if width/spacing changes inevitably touch forward |
























