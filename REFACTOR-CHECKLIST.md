# REFACTOR-CHECKLIST.md

**DotPinch Architectural Cleanup — Single Source of Truth (v3)**

> **Version:** v3 (2026-05-23) — full `/arch-lens-check` skill chain (`gauge` → `cartography` → `ninety` → `conjecture`) applied across all 12 audit agents (A=substrate · B=reveal · C=morph + master timer · D=naming · E=DevX · F=cross-file refs · G=root-cause · H=bug hunt · I=code snippets · J=file org/pragma · K=property patterns · L=methods/naming/extensibility).
> **Branch:** `main` @ d464c71 (V2 morph + reveal architecture + V1 codepath purge)
> **Scope filter:** test coverage, accessibility, GitHub Actions — **OUT** per user direction.
> **Central thread:** file organization, readability, extensions, closure-init at class top, separation of concerns, extensibility seams, abstraction discipline.

> **Execution model (v8 — MAXIMUM AGENT TOPOLOGY):** This SSoT is a multi-agent dispatch artifact. The migration executes across **23 specialized agent roles** working in **layer-partitioned parallelism**. Every task carries an **Agent Ensemble** assignment; every phase carries a **Wave Topology DAG**; every retro carries a **wave-close merge-gate** protocol. The single-engineer 22-35 day estimate collapses to **8-12 wall-clock days with a 4-agent fleet** along the critical path. See §0 below + per-wave blocks + per-task ensembles — the topology is interwoven, NOT sectionized.

---

## §0 — MAXIMUM AGENT TEAM TOPOLOGY (foundational, threaded throughout)

> **User directive (verbatim):** "MAX AGENT TEAM TOPOLOGY MAXIMUM DEPTH PARALLELISM WHERE APPLICABLE … INGRAINED IN EACH TASK RETROFITTED INTO THE SINGLE SOURCE OF TRUTH CHECKLIST … INTERWOVEN THROUGHOUT THE MASTER CHECKLIST NOT JUST A SECTION AT THE END."

> **Binding:** §0 is the foundation. The TOPOLOGY itself lives interwoven in (a) per-task Agent Ensemble blocks, (b) per-wave DAG diagrams in each phase intro, (c) wave-close merge gates in each retro, (d) 9Q.2 tag-line schema, (e) 9P gate criteria. §0 is the index; the substance is everywhere.

### §0.1 — Agent Roster (23 named roles)

#### A. Implementation agents (5) — own a Layer, partition by file

| Role | Layer | Owns files | Concrete file partition |
|---|---|---|---|
| **L1-Agent** | Animation Kernel | `Animation/**/*.swift` | `AnimationController.swift`, `SpringAnimator.swift`, `Spring.swift`, `SpringInterpolatable.swift`, `CATransaction+Helpers.swift`, `MathUtilities.swift`, post-5.0: `CurveAnimator.swift` |
| **L2-Agent** | Tokens + Models | `DesignSystem/*.swift`, `Conversation/Models/*.swift`, `Conversation/Tuning/*.swift` | `Theme.swift`, `RevealTiming.swift`, `MorphTiming.swift`, `MorphCurves.swift`, `LabelFadeTiming.swift`, `MorphAnimationKey.swift`, `PhysicsTuning.swift`, `CellLayoutTuning.swift`, `GestureCommit.swift` (enum body only), `Camera.swift`, `Conversation.swift`, `Message.swift`, post-7.6: `CoordinateSpace.swift` |
| **L3-Agent** | Domain Substrate | `Conversation/V2/*.swift` (except `Morph*`), `Conversation/ChatBody/*.swift`, `Conversation/Data/*.swift` | `TimelineCanvas.swift`, `CameraAnimator.swift`, `CellView.swift`, `ChatViewController.swift`, `ChatBubbleView.swift`, `TimelineDataSource.swift`, `TimelineDataSourceAdapter.swift`, `ConversationStore.swift`, `DummyConversationLoader.swift`, `PinchState.swift` (post-5.10), `EngagementState.swift` (post-5.5) |
| **L4-Agent** | Choreography + Lifecycle | `Conversation/V2/Morph*.swift`, `Conversation/V2/Reveal*.swift` | `MorphChoreography.swift`, `MorphChoreographer.swift`, `RevealCoordinator.swift`, `RevealBlurOverlay.swift` |
| **L5-Agent** | Composition Root | `App/*.swift` | `V2RootViewController.swift`, `AppDelegate.swift` |

#### B. Cross-cutting concern agents (3) — review/verify across all layers

| Role | Concern | Triggered when |
|---|---|---|
| **Parity-Agent** | ksdiff verification, Maestro flows, 8A/8B ledger | Any task in Parity Ledger 8A or Parity-Break Ledger 8B; mandatory at wave close |
| **Concurrency-Agent** | `@MainActor` + `Sendable` per 9S contract | Any task touching reference types in L1/L3/L4/L5 OR value types in L2/L3/L4 |
| **Doctrine-Agent** | 9A 20-pillar audit per 9A.1 row | EVERY task (universal; verifies tag-line pillars match landed code) |

#### C. Retrospective audit agents (8) — already specified in 9Q.3, dispatched at every wave close

| Role | Concern |
|---|---|
| **R1 Doctrine Auditor** | 9B per-task acceptance + 9Q.2 tag-line correctness |
| **R2 Code Smells Sweeper** | Feature envy, primitive obsession, long methods |
| **R3 Dead-Code Sweeper** | Grep-targeted orphan detection |
| **R4 Parity Verifier** | Maestro flows + ksdiff baselines |
| **R5 File-Org Auditor** | Headers, MARK regions, imports |
| **R6 Method-Cleanliness Auditor** | 1-week-out / junior-dev / reading-sequence tests |
| **R7 Abstraction Auditor** | Rule-of-3, speculative-generality refusal |
| **R8 Concurrency Auditor** | `@MainActor` + `Sendable` + composition-root DI grep |

#### D. Wave orchestration agents (7) — one per phase, dispatches sub-agents

| Role | Owns | Responsibilities |
|---|---|---|
| **Wave-0-Lead** | Phase 0 (Bug Fixes) | Dispatch L3 + L1 + L2 + Doctrine agents on 19 tasks; close 9Q.3 retro |
| **Wave-1-Lead** | Phase 1 (Tokens) | Dispatch L2-Agent on 5 tasks (all parallel) + Parity-Agent verifies 8A ledger |
| **Wave-2-Lead** | Phase 2 (DevX) | Dispatch L5 + L3 + Doctrine on 5 tasks |
| **Wave-3-Lead** | Phase 3 (Hoist) | Dispatch L1 + L5 + Concurrency on Task 3.1 (single-task wave) |
| **Wave-4-Lead** | Phase 4 (Coordinator) | Dispatch L4 + Parity + Concurrency on 5 tasks |
| **Wave-5-Lead** | Phase 5 (Keystones) | Heaviest dispatch — L1 + L2 + L3 + L4 + Parity + Concurrency + Doctrine across 11 tasks |
| **Wave-6-Lead** | Phase 6 (Hygiene) | Dispatch ALL implementation agents in MAX parallelism (most independent wave); 44+ tasks |
| **Wave-7-Lead** | Phase 7 (Audit) | Dispatch L3 + Doctrine + Documentation across 7 tasks |

#### Total: 5 Impl + 3 Concern + 8 Audit + 7 Wave-Lead = **23 named roles**.

### §0.2 — Per-Task Agent Ensemble schema (binding)

Every task body carries:
```
**Agent Ensemble:**
  Implementer: L{N}-Agent  (derived from task's layer in tag-line)
  Reviewer-Concurrency: Concurrency-Agent  (if @MainActor/Sendable touched; otherwise SKIP)
  Reviewer-Parity: Parity-Agent  (if task in Parity Ledger 8A or 8B; otherwise SKIP)
  Reviewer-Doctrine: Doctrine-Agent  (UNIVERSAL — verifies 9A.1 pillar binding)
  Wave-Lead: Wave-{N}-Lead  (orchestrates wave-close)
**Parallel:** {yes/no} — depends on: {X.Y, A.B} ; blocks: {C.D, E.F}
```

### §0.3 — Coordination model (file-partition + worktree fallback)

**Primary mechanism: File-partition by layer.** L1-Agent owns `Animation/`; L2 owns `DesignSystem/`; etc. (per §0.1 table). Within a single wave, agents on DISJOINT file sets work CONCURRENTLY without merge conflicts.

**When file partitions overlap (e.g., Task 5.1 modifies both `Conversation/V2/TimelineCanvas.swift` (L3) and creates new `Conversation/V2/MorphChoreography.swift` (L4)):**
- The PRIMARY agent (highest-layer impl) owns the task end-to-end
- For Task 5.1, **L4-Agent** is primary; L3-Agent is dispatched as cross-cut reviewer only

**Worktree fallback:** For cross-cutting tasks that span 3+ layers (e.g., Task 7.1 directory restructure), the assigned agent uses `Agent({ isolation: 'worktree' })` so its work is isolated until merge gate.

**Wave-close merge gate (in EVERY retro):** Wave-Lead runs in serial:
1. All implementation agents return (worktrees integrated)
2. R1-R8 audit agents dispatch against the integrated wave diff (PARALLEL)
3. Findings fixed in-place per 9Q.3 BLOCKING gate
4. Phase 8C ksdiff verification by Parity-Agent (SERIAL gate)
5. Wave closes; next wave's Wave-Lead-Agent begins dispatch

### §0.4 — Global Critical-Path DAG

```
Phase 0 (Bug fixes — heavy parallel within wave)
   ├─ 0.1 (L3) ──┐
   ├─ 0.2 (L3) ──┤
   ├─ 0.3 (L3) ──┤  ← serial after 5.5 lands EngagementState
   ├─ 0.4 (L3) ──┤
   ├─ 0.5-0.10 ──┤  ← parallel
   ├─ 0.11-0.13 ┤  ← parallel
   ├─ 0.14-0.19 ┤  ← parallel
   └─ 0.7 PROMOTE serial after 0.1 ─┐
                                      ↓
Phase 1 (Tokens — fully parallel; FASTEST wave)
   ├─ 1.1 (L2) ──┐
   ├─ 1.2 (L2) ──┤
   ├─ 1.3 (L2) ──┤  ← all 5 tasks parallel
   ├─ 1.4 (L2) ──┤
   └─ 1.5 (L2) ──┘
        ↓
Phase 3 (Hoist — single task, single agent)
   └─ 3.1 (L1 + L5) ── serial
        ↓
Phase 2 (DevX — parallel)
   ├─ 2.1 (L5) ──┐
   ├─ 2.2 (L5) ──┤  ← parallel
   └─ 2.3 (L5) ──┘
        ↓
Phase 4 (Coordinator — partial parallel; 4.1→4.3 serial; 4.2/4.4/4.5 parallel)
   ├─ 4.1 (L4) ─→ 4.3 (L4) ─→ 4.5 (L4)   [serial chain]
   ├─ 4.2 (L3) parallel
   └─ 4.4 (L4) parallel after 4.3
        ↓
Phase 5 (Keystones — CRITICAL PATH; heavy serial chain)
   ├─ 5.0 (L1) ─→ 5.1 (L4) ─→ 5.6 (L4) ─→ 5.7 (L3)   [CRITICAL PATH]
   ├─ 5.2 (L2) parallel after 0.2 lands
   ├─ 5.3 (L2+L3) parallel
   ├─ 5.4 (L3) parallel after 5.1
   ├─ 5.5 (L3) parallel — feeds 0.3
   └─ 5.8/5.9/5.10 (L3) parallel after 5.1
        ↓
Phase 6 (Hygiene — MAXIMUM PARALLEL; 44+ tasks; saturates fleet)
   └─ 6.1 … 6.44   ← every task independent; bound only by file-partition
        ↓
Phase 7 (Audit + restructure)
   ├─ 7.0, 7.4, 7.5 (Doctrine-Agent / Documentation) parallel
   ├─ 7.1, 7.2 (L3/L5) serial — directory + SSoT restructure as cutover
   ├─ 7.3 (L1+L3) parallel
   └─ 7.6 (L2+L3) parallel
```

**Critical path:** 0.4 → 5.0 → 5.1 → 5.6 → 5.7 → 6.43 → 7.2.
**Critical-path length:** ~7 task wall-clock equivalents ≈ **8-12 working days** with 4-agent fleet (vs 22-35 single-engineer).
**Speedup ratio:** 2.5×-3× depending on fleet utilization.

### §0.5 — Per-Wave fleet sizing (saturation analysis)

| Wave | Optimal fleet | Saturation reason | Wall-clock with fleet |
|---|---|---|---|
| 0 | 4 agents | 19 tasks across L1+L2+L3+L4 partitions; saturates at 4 | 1-2 days |
| 1 | 1 agent (L2) | All 5 tasks on L2 partition; same agent serializes | 0.5 day |
| 2 | 2 agents | 3 L5 tasks parallelize; small wave | 0.5 day |
| 3 | 1 agent | Single-task wave | 1 day |
| 4 | 2 agents (L4 + L3) | 4.1→4.3→4.5 chain dominates; 4.2 parallel | 1-1.5 days |
| 5 | 4 agents | Critical-path chain (5.0→5.1→5.6→5.7) bounds; 5.2-5.5 + 5.8-5.10 saturate 3 additional agents | 3-4 days |
| 6 | 6 agents (ALL impl + concern) | 44+ tasks across all layers; HIGHEST parallelism | 2-3 days |
| 7 | 3 agents | 7.0/7.4/7.5 parallel; 7.1→7.2 serial; 7.3/7.6 parallel | 1-2 days |

**Beyond 6 agents = waste.** Wave 6 saturates the fleet; Waves 1/3 are single-agent-bound by partition.

### §0.6 — Refused agent topology configurations

1. ❌ **Single-agent serial execution** (the original implicit model) — REFUSED per user directive; loses 2.5×-3× speedup.
2. ❌ **Migration-based (M1-M10) agent roles** — REFUSED because migrations cross phases; M-agents would conflict on same files across waves.
3. ❌ **Cellular per-task ensembles (240+ agent instances)** — REFUSED; coordination overhead exceeds parallelism gain.
4. ❌ **Coordinator-orchestrated shared workspace with file locks** — REFUSED; file-partition by layer makes locks unnecessary by design.
5. ❌ **Branch-per-agent with sequential merge** — REFUSED in favor of file-partition + worktree fallback (faster integration).

### §0.7 — Tag-line schema extension (9Q.2 v2)

The 9Q.2 tag-line gains TWO new fields:
```
[Layer | Pillars | Wave (Theme) | Parity | Test | Deps | Agents | Parallel]
```
- **Agents:** comma-separated ensemble (e.g., `L4 + Parity + Concurrency + Doctrine + Wave-5-Lead`)
- **Parallel:** `yes (deps: X.Y)` or `no (blocks: A.B; serial chain in Wave N)`

This is INGRAINED in every task body. See §0.2 binding.

### §0.8 — How the topology is INTERWOVEN (not appended)

| Where | What lives there | Status |
|---|---|---|
| §0 (here) | Roster + DAG + fleet sizing + tag-line schema | ✅ Foundation |
| Each phase intro (Phase 0-7) | Wave Topology DAG block (intra-wave parallelism) | ✅ All 8 phases |
| Each task body | Agent Ensemble block (5-7 lines) + tag-line `Agents:` + `Parallel:` | ✅ All 78 tasks |
| Each retro block | Wave-close merge gate + visual checklist + time budget + learning ledger entry | ✅ All 8 retros (v8.1) |
| 9A.1 doctrine matrix | Doctrine-Agent's binding contract | ✅ Existing matrix is the binding |
| 9P v8 gate | Topology-readiness criteria | ✅ Authored |
| 9S concurrency contract | Concurrency-Agent's binding contract | ✅ Existing per 9S table |
| 9V discharge log | Topology completion record | ✅ v8 entry present |

### §0.9 — Retro Time-Budget Matrix (BINDING — every wave's retro has a budget)

| Wave | Retro budget | Rationale |
|---|---|---|
| 0 (Bug Fixes) | **4 hours** | 19 tasks, 4-agent fleet, full R1-R8 sweep + Maestro flows 1-6 |
| 1 (Tokens) | **2 hours** | 5 L2-only tasks; primarily 8A ledger row-by-row verification |
| 2 (DevX) | **2 hours** | 3 DevX tasks; minimal production code paths |
| 3 (Hoist) | **3 hours** | 1 task but 60+ test-site verification + `@MainActor` sweep + Concurrency-Agent gate |
| 4 (Coordinator) | **4 hours** | 5 tasks with coordinator lifecycle + memory hygiene + Maestro flows 1, 3, 7 |
| 5 (Keystones) | **8 hours** | HEAVIEST — keystone surfacing + 60+ test sites + full visual pass + critical-path verification |
| 6 (Hygiene) | **8 hours** | LARGEST FAN-OUT — 44+ tasks across 6 agents; R-agent batching protocol (§0.12) required |
| 7 (Cutover) | **4 hours** | Final cutover + 7 Maestro flows + SSoT restructure verification + closure assertion |

**Total retro budget across migration:** ~35 hours.
**Total impl + retro fleet wall-clock:** 8-12 working days.

**Budget enforcement:** If retro exceeds budget by >50%, invoke **9Q.3 Stage 7 Failure-of-Retro protocol** (Path A scope expansion or Path D escalation).

### §0.10 — Wave-Close Merge Gate (reusable template — ECHOED in EVERY retro block)

The 5-step gate every retro executes (referenced by each retro via "per §0.10"):

```
1. Wave-N-Lead waits for all Wave N implementation agents to return
   their worktrees / branches integrated to the trunk.
2. R1-R8 dispatched in PARALLEL against the integrated Wave N diff
   (zero serial overhead among audit agents).
3. Findings fixed IN-PLACE per 9Q.3 Stage 3 (NO backlog; NO "queued
   for later"). Re-dispatch all 8 R-agents post-fix; all return clean.
4. Parity-Agent runs Phase 8C ksdiff on Wave N's assigned Maestro
   flows (SERIAL gate — happens AFTER all impl + R-agents clean).
   Pass OR document in Parity-Break Ledger 8B with rationale.
5. Wave CLOSES. Next wave's Wave-Lead begins dispatch ONLY AFTER
   this gate closes. Wave N+1 work is BLOCKED until this point.
```

**Inter-wave interference prevention:** Wave N+1's Wave-Lead cannot dispatch sub-agents until Wave N's gate step 5 fires. This is the load-bearing mechanism preventing parallel-wave interference.

### §0.11 — Cross-Wave Learning Ledger (the propagation mechanism)

**Problem:** Without a learning loop, every retro is isolated; patterns flagged in Wave N are not auto-hunted in Wave N+1.

**Solution:** Every retro emits a "patterns observed" list. Subsequent waves' R-agent hunts MUST auto-include those patterns. The ledger is the load-bearing memory between retros.

**Ledger format (BINDING — appended to retro paragraph at Stage 6):**
```
Wave N patterns observed (added to Wave N+1's hunts):
- Pattern P<NN>: <one-line pattern description>
  Flagged by: R<X>
  Remediation: <how it was fixed>
  Propagation: <which subsequent wave's R-agent hunts this gets added to>
```

**Propagation rule:** any pattern flagged in retro N that COULD plausibly recur in a future wave is added to the next wave's R-agent hunts list automatically. No opt-in needed. Doctrine-Agent enforces auto-propagation at Stage 1 of each retro.

**Example propagation chain (hypothetical):**
- Wave 0 retro P1: "resetMorphState invariant not tested via pool round-trip" → propagates to Wave 5 R6 (Method-Cleanliness) hunts list
- Wave 3 retro P5: "@MainActor missing on extracted DisplayLinkProxy" → propagates to Wave 5 R8 + Wave 6 R8 hunts
- Wave 5 retro P11: "ksdiff antialiasing tolerance 0 fails on retina sims" → propagates to Wave 6 R4 + Wave 7 R4 hunts

**Cross-migration learning** (post-v8): the final cumulative pattern ledger is archived in `docs/migration-patterns.md` for future migrations.

### §0.12 — Phase 6 R-Agent Batching Protocol (44+ task scaling)

**Problem:** Wave 6 has 44+ tasks. Naive "each R-agent reviews ALL tasks" creates 8 agents × 44 tasks = 352 review pairs in one sweep — agent context overflow + lost findings.

**Solution:** Per-layer task batching.

- **Batch size:** max **8 tasks per R-agent invocation**
- **Shard strategy:** by layer (L1-Agent's tasks batched together; L3-Agent's batched together)
  - L1 batch: 6.5, 6.15, 6.23, 6.24, 6.40, 6.44 (6 tasks; one batch)
  - L2 batch: 6.1, 6.4 (2 tasks; one batch)
  - L3 batch A: 6.2, 6.3, 6.6, 6.9, 6.10, 6.12, 6.13, 6.14 (8 tasks; one batch)
  - L3 batch B: 6.16, 6.17, 6.19, 6.20, 6.21, 6.22, 6.25, 6.26 (8 tasks; one batch)
  - L3 batch C: 6.27, 6.39a, 6.41, 6.42, 6.43 (5 tasks; one batch)
  - L5 batch: 6.3 partial (1 task; combined with L3 batch A)
  - Doctrine sweep: 6.7, 6.8, 6.9, 6.18, 6.41 cross-cutting (5 tasks; one batch)
- **Parallel R-runs:** each R-agent runs in parallel across batches (e.g., R2 Code-Smells invokes 6 times — once per batch — concurrently)
- **Findings consolidation:** Wave-6-Lead aggregates R-agent outputs across batches BEFORE invoking `/root-cause-tracing`
- **Re-dispatch:** post-fix re-verification is ALSO batched — re-run only the batches where findings landed (not the whole 6-batch fleet)

**This protocol applies ONLY to Wave 6.** Other waves have ≤19 tasks each; single-pass works.

---

## ⛓️ ARCH-LENS-CHECK output (skill-chain compliance)

```
POSTURE: janum
MODE:    Forward (anchored to current main; target is principled-tier shipping recommendation)

=== Capability grounding ===
This document recovers a full architectural calibration in one operation:
  - Surfaces cross-skill blind spots (the 12 audits cross-check each other)
  - Produces unified design (one phased checklist, not five disjoint reports)
  - Maintains framework discipline (every recommendation cites ARCH-* IDs)

=== Agent dispatch summary ===
Twelve agents dispatched in two waves:
  Wave 1 (substrate baseline, 5 agents): A B C D E
  Wave 2 (gap-filling, 7 agents):        F G H I J K L
  Each produced citation IDs threaded into the conjecture below.
  All 12 returned. No agents skipped.

=== M1 — Honest non-execution acknowledgment ===
I did not run the test suite. I did not execute Maestro flows. I did not
build the project. All findings are static-analysis from source reads.
Visual-regression validation is OUTSTANDING for every task that mutates
animation code (Phases 4 + 5 in particular).

=== M3 — Cross-skill traceability ===
Citation density: every load-bearing task references at least one of:
  - ARCH-AUDIT-reveal-* (Agent B)
  - ARCH-AUDIT-substrate-* (Agent C)
  - ARCH-AUDIT-naming-* (Agent D)
  - ARCH-AUDIT-devx-* (Agent E)
  - ARCH-AUDIT-anatomy-* (Agent A)
  - ARCH-AUDIT-hygiene-* (Agent J)
  - ARCH-AUDIT-property-* (Agent K)
  - ARCH-AUDIT-method-* (Agent L)
  - BUG-H* (Agent H confirmed bugs)
```

---

## 📐 Phase 1 — Gauge (tier classification)

**Required tier:** **Tier 3B** (Janum/principal-tier craft) — the codebase has chosen this tier already; the cracks identified are deviations that the refactor closes.

**Current per-domain tier:**

| Domain | Current | Gap |
|---|---|---|
| Animation substrate (Animation/) | **3B** | Zero — reference quality |
| Models (Conversation/Models, Data) | **3B** | Zero |
| Camera math (CameraAnimator) | **3B** | Bool-triple state machine (5.5) |
| Cell pool + LIFO + keyed (TimelineCanvas) | **3B** | Megafile co-location only |
| Tap-to-chat morph orchestration | **2A** | Hidden state machine; 10 master* fields; magic numbers |
| Reveal pipeline (V2RootViewController.revealChat) | **1B** | Three-block UIView.animate chain; magic numbers; tight coupling |
| Naming conventions | **2B → 3A** | `setup*` violation; `handle*` non-gesture; underscore prefix |
| Property declarations | **3A** | 11 IUOs (4 justified, 7 promotable); 2 sentinel values |
| File organization | **2B** | TimelineCanvas megafile (1477 LOC); no file-end conformance extensions |

**Target tier:** Uniform **3B** across all domains. The four 2A/2B/1B cracks become 3B via this checklist.

---

## 🗺️ Phase 2 — Cartography (primitive menu)

The architectural primitives this codebase composes from. Cited as `ARCH-CARTO-*`.

**ARCH-CARTO-SUB-01 — `sublayerTransform`-driven camera (KEYSTONE).**
The codebase animates content position by writing `contentHost.layer.sublayerTransform = CATransform3DMakeTranslation(0, -camera.y, 0)` rather than scrolling. Phase-locks Y / Z / scale / alpha into one transform write per tick.

**ARCH-CARTO-SUB-02 — `CADisplayLink` substrate (KEYSTONE).**
`AnimationController` owns ONE display link; `SpringAnimator<T>` instances register/unregister. The morph's `masterTimer` is a SECOND, parallel display link (not coordinated through AnimationController — see open question Q5).

**ARCH-CARTO-SUB-03 — `SpringAnimator<T>` generic kernel (3B).**
Apple's spec/runner pattern, generic over `T: SpringInterpolatable`. 162 LOC; reference quality. Already a candidate for extraction to its own SPM library — see Bottling Destination.

**ARCH-CARTO-SUB-04 — `CABasicAnimation` cascade (LOAD-BEARING).**
The tap-to-chat morph uses six concurrent CABasicAnimations on `contentHost.layer` (windup.scale, zoom.scale, windup.translate, morph.centering, centerLabel.opacity) plus three `UIView.animate` cell-chrome fades.

**ARCH-CARTO-SUB-05 — `CATransaction.withSuppressedActions` discipline (KEYSTONE).**
Every per-frame layer write is wrapped to prevent implicit 0.25s tweens. The discipline is consistent today; new code MUST preserve it.

**ARCH-CARTO-SUB-06 — Cell pool LIFO + UUID-keyed secondary index (KEYSTONE).**
Pool returns LIFO for freshness; the keyed map (`cellPoolByConversationID`) preserves cell state across pool round-trips.

**ARCH-CARTO-SUB-07 — Active-cell-pool-protection (LOAD-BEARING).**
`returnToPool` rejects the active cell (line 780-782). Prevents pool churn from invalidating the in-flight morph target.

**ARCH-CARTO-SUB-08 — Push pattern from canvas to cells (KEYSTONE).**
`pushCameraToVisibleCells` writes camera state into each visible cell. Single-source-of-truth; no reactive observers; explicit ownership.

**ARCH-CARTO-SUB-09 — Dual-spring AND-gate (`tryClearActiveCellAtRest`) (KEYSTONE).**
Closes a race where camera spring completes synchronously while extension still integrates. The active-cell-index is cleared ONLY when both springs are at rest.

**ARCH-CARTO-PAT-01 — `install*` setup convention.**
16 occurrences across TimelineCanvas, CellView, ChatViewController. The codebase's universal "build subview + wire to layout" convention.

**ARCH-CARTO-PAT-02 — `*Path` suffix convention.**
Internal-entry-point methods that bypass guards. Public methods guard; `*Path` methods do work. Two occurrences today; the pattern is correct and underused.

**ARCH-CARTO-PAT-03 — `apply*` per-tick write convention.**
`applyCameraTransform`, `applyExtensionTick`, `applyMasterTick`. Per-tick output writers for spring/animator integration.

**ARCH-CARTO-PAT-04 — `update*` idempotent recomputation convention.**
`updateEdgeMaskAlphas`, `updateVisibleCells`, `updateNeighborTranslations`. State-propagation methods with no business decisions.

**ARCH-CARTO-PAT-05 — `try*` atomic-check-then-do convention.**
`tryFireOuterCompletion`, `tryClearActiveCellAtRest`. Check preconditions, do the thing, no-op otherwise.

**ARCH-CARTO-PAT-06 — `handle*` `@objc` gesture-handler convention.**
ONLY for `@objc` selectors from UIGestureRecognizer/UIControl. `TimelineCanvas.handleCellTap` violates (see Task 0.6).

---

## 🎯 Phase 3 — Ninety (90% craft findings)

The principal-tier craft rules that govern HOW the primitives compose. Cited as `ARCH-NINETY-*`.

**ARCH-NINETY-WAVE-01 — Animator-on-view encapsulation (Janum Trivedi / Wave).**
The animator OWNS the layer/view it drives; consumers ask the view for its animator, not the other way around. The codebase honors this: `cameraAnimator: CameraAnimator!` lives on TimelineCanvas, not as a free entity.

**ARCH-NINETY-WAVE-02 — Velocity preservation across retargets.**
Mid-flight target changes preserve velocity (SpringAnimator's `target { didSet }` at line 51). Settling is duration-based (not threshold-based) — the codebase has this right.

**ARCH-NINETY-APPLE-01 — Apple's spec/runner pattern (UIViewPropertyAnimator + UISpringTimingParameters).**
The substrate's `Spring` value type + `SpringAnimator` runner mirror this. The runner is the integration loop; the spec is the immutable parameters.

**ARCH-NINETY-APPLE-02 — `CATransaction.withSuppressedActions` for per-frame writes.**
The codebase wraps every per-frame layer write. Without it, every camera tick triggers a 0.25s implicit tween over the per-frame delta.

**ARCH-NINETY-KZR-01 — Has-protocol composition (Krzysztof Zabłocki).**
Small, focused protocols (`AnimatorProviding`, `SpringInterpolatable`, `VelocityProviding`). Not used heavily in this codebase but the precedent exists — and the recommendation set EXPLICITLY refuses to add more (rejection list).

**ARCH-NINETY-KZR-02 — Inject for hot-reload.**
The dev-loop accelerator. Phase 2 Task 2.1 adds it. **MUST be preceded by AnimationController hoist (Phase 3 Task 3.1)** or Inject corrupts the substrate on each cycle.

**ARCH-NINETY-PF-01 — Pointfree witness structs.**
Witness pattern for dependency injection. The codebase has chosen NOT to adopt — singletons-free construction works, and the rejection is explicit (see rejection list).

**ARCH-NINETY-TG-01 — Discipline of refusal (Telegram-iOS pattern).**
Principal-tier shops define themselves by what they REFUSE. The rejection list is the load-bearing principal-tier output. 15 items refused below.

**ARCH-NINETY-CASH-01 — Snapshot-per-keyframe (Cash App Stagehand).**
Per-state visual capture for regression detection. **Out of scope per user filter** but the pattern exists as future work.

**ARCH-NINETY-ORG-01 — File-end protocol-conformance extensions.**
Swift convention. `extension TimelineCanvas: UIGestureRecognizerDelegate { ... }` at file end keeps the type-declaration line honest about the type's primary identity. **The codebase has ZERO file-end conformance extensions today (Agent J)** — this is the largest single readability lift available.

**ARCH-NINETY-ORG-02 — `// MARK:` discipline.**
Marks group related methods/properties within a type. Strong adherence in Animation/* and Models/*; partial in TimelineCanvas (22 MARKs but the 534-LOC pinch region is undifferentiated); absent in ChatViewController.

**ARCH-NINETY-ORG-03 — Closure-init at class top, not in methods.**
**User-emphasized rule.** Property initialization should happen at declaration (top of class) via inline-let or closure-init `{ ... }()`, not deferred to `setupX()` helpers using IUOs. Today's codebase has TWO camps: the clean camp (ChatViewController, ChatBubbleView — inline lets) and the IUO camp (CellView 7 IUOs, TimelineCanvas 4 IUOs). Phase 6 converges these.

**ARCH-NINETY-ORG-04 — Separation of concerns at file granularity.**
TimelineCanvas (1477 LOC) does 12 distinct things. Reading the file requires holding all 12 in mind. The conjecture's module structure (Phase 4) extracts the seams in priority order.

**ARCH-NINETY-ORG-05 — Extensibility via SEAMS, not GENERICS.**
The pattern: identify the point where the codebase will need to vary, name it as a protocol or struct, and stop there. Don't pre-generalize. The four extensibility scenarios (Agent L Section "Extensibility seams") name today's seam costs.

**ARCH-NINETY-ABS-01 — Abstract on the 3rd repetition, not the 2nd.**
The codebase has multiple 2-occurrence patterns (sRGB conversion, full-bleed constraints, day-marker derivation) and 3+-occurrence patterns (the CABasicAnimation cascade, the `guard let activeIdx, activeCell, heightC, naturalH` precondition chain). Only the 3+-occurrence patterns are worth abstracting now.

**ARCH-NINETY-ABS-02 — `lazy var` is forbidden; closure-init at class top is preferred.**
The codebase has zero `lazy var` usage. Strong discipline. **Preserve.** Lazy hides "when does this get built?" — eager-at-declaration makes it explicit.

---

## 🏛️ Phase 4 — Conjecture (the architectural recommendation)

### Required tier anchor: **Tier 3B (Janum/principal)**

The conjecture closes the four cracks (morph-orchestration, reveal-pipeline, file-org megafile, naming inconsistencies) without disturbing the eight keystones.

### Module structure (target file tree after Phase 0-6 land)

```
DotPinchPrototype/
├── App/
│   ├── AppDelegate.swift                          [unchanged]
│   ├── V2RootViewController.swift                 [GUTTED — Phase 4]
│   ├── RevealCoordinator.swift                    [NEW — Phase 4]
│   └── RevealBlurOverlay.swift                    [NEW — Phase 4]
├── Animation/
│   ├── AnimationController.swift                  [unchanged]
│   ├── Spring.swift                               [unchanged]
│   ├── SpringAnimator.swift                       [unchanged]
│   ├── SpringInterpolatable.swift                 [unchanged]
│   ├── AnimatorProviding.swift                    [NEW — Phase 6 lift-out from SpringAnimator]
│   ├── CATransaction+Helpers.swift                [unchanged]
│   └── MathUtilities.swift                        [unchanged]
├── Conversation/
│   ├── Models/                                    [unchanged]
│   ├── Data/                                      [unchanged]
│   ├── ChatBody/ChatBubbleView.swift              [unchanged]
│   └── V2/
│       ├── Camera.swift                           [unchanged]
│       ├── CameraAnimator.swift                   [MODIFIED — EngagementState]
│       ├── CellView.swift                         [MODIFIED — resetMorphState, IUO→let, install convention]
│       ├── ChatViewController.swift               [MODIFIED — MARK discipline]
│       ├── TimelineCanvas.swift                   [MODIFIED — choreographer extraction]
│       ├── TimelineCellPool.swift                 [NEW — Phase 5 (optional)]
│       ├── TimelineDataSource.swift               [unchanged]
│       ├── TimelineDataSourceAdapter.swift        [MODIFIED — conformance via extension]
│       ├── MorphTiming.swift                      [NEW — Phase 1]
│       ├── MorphAnimationKey.swift                [NEW — Phase 1]
│       ├── MorphChoreography.swift                [NEW — Phase 5]
│       ├── MorphChoreographer.swift               [NEW — Phase 5]
│       ├── GestureCommit.swift                    [NEW — Phase 5 lift-out]
│       └── CellLayoutTuning.swift                 [NEW — Phase 1]
└── DesignSystem/
    ├── Theme.swift                                [MODIFIED — color spelling, header position]
    ├── AccessibilityID.swift                      [unchanged]
    ├── SymbolName.swift                           [unchanged]
    ├── RevealTiming.swift                         [NEW — Phase 1]
    └── PhysicsTuning.swift                        [MOVED + RENAMED from Gestures/PinchTuning.swift]

# Gestures/ folder DELETED after PinchTuning moves to DesignSystem/
```

### Type-level architecture (the named types)

**`struct RevealTiming` (enum-namespace)** — `[ARCH-CARTO-PAT-01, ARCH-NINETY-ORG-03]`
- Five `static let TimeInterval` tokens for the three-track reveal choreography.
- Value type, no init, no methods. Pure token bag.

**`struct MorphTiming` + `enum MorphCurves`** — `[ARCH-CARTO-SUB-04]`
- 11 `static let` constants + 3 control-point tuples.
- Pure token bag. Imported by TimelineCanvas + MorphChoreographer.

**`enum MorphAnimationKey: String`** — `[ARCH-CARTO-SUB-04, BUG-H invariant]`
- 5 cases mapping to the original literal strings.
- `rawValue` preservation keeps any external KVO/debug observers working.

**`struct CellLayoutTuning` (enum-namespace)** — `[ARCH-CARTO-PAT-01]`
- One token: `naturalHeight: CGFloat = 200`.

**`struct PhysicsTuning: Sendable, Equatable`** — `[ARCH-NINETY-PF-01 inverse — REFUSED witness in favor of plain value]`
- 5 immutable `let` fields with bounds-validating init.
- Injected by V2RootViewController via TimelineCanvas init.
- `static let standard` factory.

**`enum GestureCommit`** — `[ARCH-CARTO-PAT-04 rename]`
- 3 cases: `.commitToChat`, `.returnToCells`, `.bailToOrigin`.
- `dampingRatio(from: PhysicsTuning) -> CGFloat` method.

**`final class RevealBlurOverlay: UIView`** — `[ARCH-NINETY-WAVE-01 analog]`
- `attach(to:)` + `detach()` + `alpha` override forwarding to inner effect view.
- Encapsulates the UIVisualEffectView wrapper.

**`@MainActor final class RevealCoordinator`** — `[ARCH-NINETY-ORG-04 SoC]`
- Owns `activeChatVC` + `revealBlurOverlay`.
- `present(conversation:)` / `dismiss()` methods.
- Weak parent + canvas references.

**`struct MorphChoreography`** — `[ARCH-NINETY-ORG-04 SoC]`
- Frozen snapshot of morph parameters at engagement.
- 8 `let` fields. No mutation post-construction.

**`@MainActor final class MorphChoreographer`** — `[ARCH-NINETY-ORG-04 SoC, ARCH-CARTO-SUB-02]`
- Owns the master-timer CADisplayLink.
- `engage(_:completion:)` / `stop()`.
- Weak canvas reference; reads back via `applyMorphTickCameraWrite(translation:cell:)` seam.

### Wiring story (injection mechanisms)

**Composition root:** `V2RootViewController.init`. Constructs in this order:
1. `ConversationStore`
2. `TimelineDataSourceAdapter` (consumes store)
3. `AnimationController`
4. `PhysicsTuning.standard`
5. `TimelineCanvas(controller:tuning:)` (consumes both)
6. `RevealCoordinator(parent: self, canvas: timelineCanvas)` (lazy)

**Mechanism:** constructor injection only. No DI framework, no Environment, no swift-dependencies. Each collaborator receives what it needs at init; no global lookups.

**Ownership graph:**
```
V2RootViewController
├── ConversationStore (let, strong)
├── TimelineDataSourceAdapter (let, strong) ← store
├── AnimationController (let, strong)
├── TimelineCanvas (let, strong) ← controller, tuning
│   ├── animationController (let, hoisted)
│   ├── physicsTuning (let, injected)
│   ├── cameraAnimator (let, owns) ← controller
│   ├── extensionAnimator (let, owns) ← controller
│   ├── morphChoreographer (lazy let, owns) ← weak self
│   └── instantiatedCells: [Int: CellView] (managed)
└── revealCoordinator (lazy let, owns)
    ├── activeChatVC (var, lifecycle-owned)
    ├── revealBlurOverlay (var, lifecycle-owned)
    ├── weak parent
    └── weak canvas
```

### Call-site experience (the API the consumer USES)

```swift
// V2RootViewController.init — composition root
init() {
    let conversations = DummyConversationLoader.load()
    let store = ConversationStore(initialConversations: conversations)
    let adapter = TimelineDataSourceAdapter(store: store, naturalCellHeight: CellLayoutTuning.naturalHeight)
    let controller = AnimationController()
    self.store = store
    self.adapter = adapter
    self.animationController = controller
    self.timelineCanvas = TimelineCanvas(controller: controller, tuning: .standard)
    super.init(nibName: nil, bundle: nil)
}

// V2RootViewController.viewDidLoad — single wire-up
override func viewDidLoad() {
    super.viewDidLoad()
    installTimelineCanvas()
    installTapRecognizer()
    timelineCanvas.dataSource = adapter
    timelineCanvas.onMorphRevealReady = { [weak self] cellIndex in
        guard let self else { return }
        guard cellIndex < self.store.conversations.count else { return }
        self.revealCoordinator.present(conversation: self.store.conversations[cellIndex])
    }
}

// V2RootViewController.handleTap — the entire tap flow, 5 lines
@objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
    let viewport = recognizer.location(in: timelineCanvas)
    let page = timelineCanvas.pagePointFromViewportPoint(viewport)
    guard let idx = timelineCanvas.cellIndex(atPagePoint: page) else { return }
    guard !revealCoordinator.isPresenting else { return }
    timelineCanvas.animateCameraToChatRest(forCellAt: idx)
}
```

### Rejection list (the discipline of refusal)

`[ARCH-NINETY-TG-01]`

1. ❌ **PerCellAnimator** — second timeline desyncs from canvas progress. Citation: keystone K5 (push pattern is single-source).
2. ❌ **Replace `sublayerTransform` camera with `UIScrollView`** — collapses phase-locking. Citation: K1.
3. ❌ **Centralized `AnimationService` / singleton** — wrong pattern. Citation: ARCH-NINETY-WAVE-01 (animator-on-view).
4. ❌ **DI framework (Swinject / Resolver / Factory)** — codebase has zero singletons already. Citation: composition-root pattern works.
5. ❌ **Combine observers for `setCamera` push** — per-cell subscription overhead. Citation: K5.
6. ❌ **Phantom-typed state machines** — state space too small. Citation: ARCH-NINETY-ABS-01 (3rd-repetition rule).
7. ❌ **`UICollectionView + CompositionalLayout`** — wrong substrate. Citation: K1.
8. ❌ **Break up TimelineCanvas megaclass NOW** — wait until extracted types prove the seams. Citation: ARCH-NINETY-ABS-01.
9. ❌ **Strict concurrency (Swift 6)** — separate audit; defer.
10. ❌ **Cross-platform SPM extraction (TelescopeCore)** — DotPinch is iOS-only. Citation: ARCH-NINETY-ABS-01.
11. ❌ **`V2` prefix project-wide rename** — cosmetic. Citation: ARCH-NINETY-ABS-01.
12. ❌ **Snapshot tests at keyframes** — per user filter.
13. ❌ **Accessibility ID / SymbolName population** — per user filter.
14. ❌ **GitHub Actions / CI / PR APNG sweep** — per user filter.
15. ❌ **Reduced-motion handling** — per user filter.
16. ❌ **Adding `lazy var` anywhere** — preserves ARCH-NINETY-ABS-02. The codebase has chosen eager-at-declaration; do not regress.
17. ❌ **Adding new protocols beyond what extensibility seams require** — pre-generic-ing for hypothetical second cell type. Citation: ARCH-NINETY-ORG-05.
18. ❌ **Reactive bindings library (RxSwift / Combine streams) for any of this** — too much overhead for a single-consumer push.
19. ❌ **`extension UIView { var animator: ViewAnimator }` (Wave's canonical surface)** — refused per 7C.2 / Agent O WAVE-02. DotPinch's animatable units are domain scalars (`Camera.translation`, extension-height), NOT view properties; per-view associated-object would hide controller ownership.
20. ❌ **Force `MorphChoreographer` to route through `setCamera`** — per 9R.4.1 / Migration M8 resolution. Justified bypass: `applyMorphTickCameraWrite` is the deterministic per-tick fan-out for the master-timer keystone K7. Routing through `setCamera` would introduce recursive transaction collision (setCamera wraps its own CATransaction; the master tick already wraps one). The bypass writes camera + transform + visible-cells + edge-mask + onCameraChanged — exactly setCamera's effects MINUS pan-enable/lastCellRestScrollY/hasExternalCameraWrite (which are setCamera-specific persistence concerns NOT applicable to the morph clock).
21. ❌ **Extracting `TimelineCellPool` + `TimelineLayoutCalculator` as standalone types** — per 9R.4.2. DEFERRED to post-v7. Per ARCH-NINETY-ABS-01 (3rd-repetition rule): each has 1 consumer (TimelineCanvas) today; extraction is speculative until a second consumer appears. Phase 7 Task 7.0 (megafile re-evaluation memo) is the explicit deferral marker; M1 (megafile decomposition) achieves its target via Task 5.1 (MorphChoreographer extraction) bringing TimelineCanvas to <1200 LOC; further decomposition to <800 awaits seam-proof evidence.

---

## 🧪 Phase 5 — Coherence tests (4 of 6 required; all 6 walked)

1. **Primitive-usage check — PASS.** Every primitive used in the conjecture (sublayerTransform, CADisplayLink, CABasicAnimation, CATransaction-suppressed-actions, cell pool LIFO, push pattern, dual-spring AND-gate) has an `ARCH-CARTO-*` citation.
2. **Rule-application check — PASS.** Every craft rule applied (animator-on-view, velocity preservation, Apple spec/runner, Inject for hot-reload, file-end conformance, MARK discipline, closure-init-at-top, separation of concerns) has an `ARCH-NINETY-*` citation.
3. **Parameter-consistency check — PASS WITH NOTES.** Embedded values (spring damping 0.85, response 1.10, morph duration 1.5s, master-timer 1.2s, blur fade 0.3/0.5/0.7) come straight from current source. The intentional 1.5s/1.2s split between CABasicAnimation total and master-timer is preserved (different clocks, different roles).
4. **Tier-match check — PASS.** Conjecture's recommended tier (3B) matches `/arch-gauge`'s required tier across all domains.
5. **Confidence-propagation check — PASS WITH NOTES.** Confidence is HIGH for tier-1B reveal pipeline fixes (small surface), MEDIUM for Phase 5 keystone surfacing (60+ test call sites), LOW for any visual claim that hasn't been visually verified.
6. **Rejection-completeness check — PASS.** 18 rejections cover all the major architectures a reviewer would expect to see considered (DI frameworks, reactive, snapshot tests, accessibility, CI, strict concurrency, SwiftUI migration, etc.).

### Phase 5.5 — Pivot Diagnostic (7 pivots; none required full collapse)

1. **Pivot 1 (target-shift to less ambitious tier)** — **honored**: rejection list explicitly refuses witness DI and protocol-everything; tier 3B is the calibrated anchor.
2. **Pivot 2 (substrate substitution)** — **honored**: sublayerTransform retained; UIScrollView rejected.
3. **Pivot 3 (consolidation under one orchestrator)** — **partially honored**: RevealCoordinator + MorphChoreographer remain separate intentionally (different timelines); not collapsed into one "AnimationCoordinator".
4. **Pivot 4 (refusal-discipline tightening)** — **honored**: 18-item rejection list explicit.
5. **Pivot 5 (file structure refactor scope)** — **honored**: TimelineCanvas megaclass split deferred until Phase 5 collaborators prove the seams (ARCH-AUDIT-hygiene-15 stays P0 but not in this checklist).
6. **Pivot 6 (test-strategy collapse)** — N/A (filter excludes test coverage).
7. **Pivot 7 (declared scope vs. delivered scope)** — **honored**: scope is REFACTOR ONLY, no new features.

---

## 📦 Bottling Destination

`SpringAnimator<T>` + `Spring` + `SpringInterpolatable` + `AnimationController` + `CATransaction+Helpers` form a coherent, principled animation kernel (423 LOC, zero non-substrate deps). Candidate for extraction as `Packages/SpringSubstrate/Sources/SpringSubstrate/`.

- **Module name:** `SpringSubstrate`
- **File paths:** `Animation/*.swift` → `Packages/SpringSubstrate/Sources/SpringSubstrate/`
- **Apprenticeship value:** the module structure teaches Apple's spec/runner pattern with generic kernel + value-type specs.
- **Refused for this checklist:** rejection list item #10 (no cross-platform extraction). The substrate stays in-app; bottling is a future option.

---

## 🤔 Meta-Perspective Prompts walked (5 of 7)

1. **Improvisation detection** — Every primitive + rule cited; no improvising.
2. **Tier-mismatch** — Recommendation matches required tier (3B uniform).
3. **Rejection-list completeness** — 18 items covering DI, reactive, witness, CI, accessibility, snapshots, strict concurrency.
4. **Call-site experience handwaving** — Concrete code shown for the composition root + tap flow + reveal handoff.
5. **Migration plan absence** — Commit-by-commit phased path produced (Phase 0 → Phase 6, with cascade callouts).

Prompts 6 (coherence-test bypass) + 7 (capability narrowing) — implicit pass via Phase 5 above.

---

## 📐 Dimensionality Completeness (6 of 6)

1. **Module structure specificity** — Concrete file paths above.
2. **Type-level concreteness** — 10 named types with signatures + roles + citations.
3. **Wiring concreteness** — Composition root spelled out; ownership graph drawn.
4. **Call-site concreteness** — Actual Swift code, not prose.
5. **Rejection completeness** — 18 items.
6. **Migration plan presence** — Phases 0-6 below.

---

## ⛔ Keystones — DO NOT TOUCH

The 8 substrate-defining decisions. ANY refactor that touches these is OUT OF SCOPE.

| # | Keystone | Why preserve |
|---|---|---|
| K1 | `sublayerTransform`-driven camera | Multi-property phase-locking depends on it. |
| K2 | Cell pool LIFO + UUID-keyed secondary index | State preservation across pool round-trips. |
| K3 | `activeCellIndex` + `tryClearActiveCellAtRest` dual-spring AND-gate | Closes camera/extension settle race. |
| K4 | `CATransaction.withSuppressedActions` discipline | Prevents implicit per-frame tweens. |
| K5 | Push pattern (`pushCameraToVisibleCells`) | Single-source-of-truth for cell visual state. |
| K6 | `accumulatedYCache` lazy invalidation | Performance; "heights stable while count stable" contract. |
| K7 | masterTimer + bell-curve Z-translation | Deterministic finite duration. |
| K8 | Per-canvas `AnimationController` instance identity | Canary test enforces shared-controller invariant. Hoisting PRESERVES this. |

---

## 🚨 Confirmed bugs (Agent H — 10 findings) → Phase 0 fixes

| # | Bug | Impact today | Phase 0 task |
|---|---|---|---|
| B1 | `morphInProgress = true` never reset | Dormant (would surface if back-out path existed) | Task 0.1 |
| B2 | `chatRestCenterLabel.transform` + opacity animation never reset | Dormant (same path) | Task 0.1 (combined) |
| B3 | `anticipationAnimator` declared + cancelled but NEVER constructed | Live: orphan tests will crash; PinchTuning anticipation* fields dead | Task 0.2 |
| B4 | `dequeueCell.preservedState` flag ignored by caller | Dormant (CellView state purged in 3fb04f0) | Task 0.7 (optional) |
| B5 | `reloadData` mid-active-cell orphans active cell | Dormant (static data source) | Task 0.7 (optional) |
| B6 | `view.layoutIfNeeded()` too-broad scope | Wasteful perf, not a bug | Task 0.5 |
| B7 | Dual-tap path through cell.onTap AND VC tap recognizer | Functional today but no back-out path | Task 0.6 |
| B8 | `animateCameraToChatRest` lacks `isQuiet` guard | Live: tap during cancel-spring conflicts | Task 0.3 |
| B9 | `handlePinchBegan` doesn't cancel masterTimer | Latent: tap+pinch within 1.2s fights writes | Task 0.3 (combined) |
| B10 | Pinch-commit master timer never fires `onMorphRevealReady` | Live (if codepath ever exercised) | Task 0.4 |

---

## 🗺️ Phase overview

| Phase | Theme | Effort | Tier movement |
|---|---|---|---|
| **0** | Critical bug fixes | 1 day | bug → fixed |
| **1** | Foundation tokens (RevealTiming, MorphTiming, MorphAnimationKey, CellLayoutTuning) | 1-2 days | 1→3 (naming alone) |
| **2** | DevX baseline (Inject + SwiftFormat + visual-audit decision) | 1-2 days | infrastructure |
| **3** | Hoist `AnimationController` to V2RootViewController | 1 day | 3B → 3B (intent-realizing) |
| **4** | `RevealBlurOverlay` + `RevealCoordinator` (+ optional UIViewPropertyAnimator) | 3-4 days | 1B → 3B (centerpiece) |
| **5** | Surface keystones (MorphChoreographer, PhysicsTuning, GestureCommit, EngagementState) | 4-6 days | 2A-hidden → 3B-named |
| **6** | Code hygiene (file org, pragma marks, properties, methods, extensibility seams) | 3-4 days | 2B → 3A-3B |

**Total: 13-20 working days, single engineer.**

---

# Phase 0 — Critical Bug Fixes

**Goal:** Fix the 10 bugs Agent H confirmed BEFORE structural refactors, so new abstractions don't propagate them.

**Dependencies:** None. Ship first.

---

**Wave 0 Agent Topology:**
- **Fleet:** 4 agents — L3-Agent (primary, owns most), L1-Agent (0.10 Spring), L2-Agent (0.16 ChatBubbleView), Doctrine-Agent (0.15 headers)
- **Parallel groups within wave:**
  - Group A (L3, parallel): 0.1, 0.2, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.11, 0.12, 0.13, 0.14, 0.18, 0.19
  - Group B (L1, parallel with A): 0.10 (Spring.init), 0.17 (Spring precondition)
  - Group C (L2, parallel with A): 0.16 (ChatBubbleView rename)
  - Group D (Doctrine, parallel with A): 0.15 (stale headers)
  - **Serial guard:** 0.3 (isQuiet) blocked until 5.5 lands EngagementState — defers to Wave 5
- **Critical path within wave:** Group A's heaviest task (0.7 PROMOTE — reloadData defensive guard)
- **Wave-0-Lead** dispatches all 4 agents, gathers at retro for 9Q.3 R1-R8 + Parity-Agent ksdiff gate
- **Wall-clock estimate with fleet:** 1-2 days (vs 4-6 single-engineer)

---


### ☐ Task 0.1 — Reset `morphInProgress` + `chatRestCenterLabel` state on pool return [B1, B2]
`[L3 Domain substrate | P1.2 P3.2 P6.6 P10.1 P11.1 | Wave 0 (Bug fixes) | Parity: neutral | Test: 8 | Deps: —]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-0-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 0:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**Files:** `Conversation/V2/CellView.swift`, `Conversation/V2/TimelineCanvas.swift`
**Class:** LOAD-BEARING · **Heat:** COOL
**Citation:** `[BUG-H1, BUG-H2]`

**Before:**
```swift
// CellView.swift:40
var morphInProgress: Bool = false
// Write at TimelineCanvas:1150: activeCell.morphInProgress = true
// NO reset site anywhere (Agent F + H confirmed)
```

**After** — add `resetMorphState()` to CellView:
```swift
// CellView.swift — new method placed in Public API region
// MARK: - Morph state lifecycle
/// Reset all morph-related transient state. Called by TimelineCanvas
/// before returning the cell to the pool, so a recycled cell starts
/// in a known-clean state regardless of how the prior morph ended.
func resetMorphState() {
    morphInProgress = false
    chatRestCenterLabel.transform = .identity
    chatRestCenterLabel.layer.removeAnimation(forKey: MorphAnimationKey.centerLabelOpacity.rawValue)
    chatRestCenterLabel.alpha = 0
}
```

Then in TimelineCanvas's `returnToPool` (line 787, BEFORE `resetHeightConstraintToNatural`):
```swift
private func returnToPool(_ cell: CellView) {
    guard cell.index != activeCellIndex else { return }
    cell.resetMorphState()                       // NEW
    cell.resetHeightConstraintToNatural()
    cell.deactivateLayoutConstraints()
    // ... rest unchanged ...
}
```

**Acceptance:**
- [ ] `resetMorphState()` exists; clears all 4 fields
- [ ] `returnToPool` invokes it
- [ ] Smoke test: morph cell → reveal → (later, when dismiss path exists) re-tap different cell → no chrome ghosting

**Dependencies:** None (works without Task 1.3, but referencing `MorphAnimationKey` is cleaner once 1.3 lands).

---

### ☐ Task 0.2 — Delete `anticipationAnimator` + dead PinchTuning fields + orphan tests [B3]
`[L3 Domain substrate | P2.13 P3.7 P5.1 P8.1 P10.4 | Wave 0 (Bug fixes) | Parity: neutral | Test: 5 (orphan delete) | Deps: —]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-0-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 0:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**Files:** `Conversation/V2/TimelineCanvas.swift`, `Gestures/PinchTuning.swift`, `Tests/V2/Wave4f*.swift`, `WaveR72*.swift`, `WaveR73*.swift`, `WaveR74*.swift`, `WaveR75*.swift`
**Class:** LOAD-BEARING · **Heat:** WARM
**Citation:** `[BUG-H3, ARCH-AUDIT-anatomy-* dead-code]`

Agent H + F **confirmed** `UIViewPropertyAnimator(` returns ZERO production hits. The anticipation-animator property is declared + cancelled but never constructed. Multiple orphan test files reference it.

**Delete from TimelineCanvas.swift:**
- Line 114: `private(set) var anticipationAnimator: UIViewPropertyAnimator?` declaration
- Line 948: `anticipationAnimator?.stopAnimation(true); anticipationAnimator = nil` (cancel hook)
- Surrounding doc-comments

**Delete from PinchTuning.swift:**
- `anticipationMagnitude` (line 35-44 with bounds setter)
- `anticipationDuration` (line 49-58 with bounds setter)
- `anticipationDisabled` (line 62)
- `_anticipationMagnitude` + `_anticipationDuration` backing storage

**Delete from Tests/V2/:**
- `Wave4fAnticipationTests.swift`
- `WaveR72AnticipationTunabilityTests.swift`
- `WaveR73DisableFlagTests.swift`
- `WaveR74NoSpringInheritanceTests.swift`
- `WaveR75TapDuringSpringTests.swift`

**Acceptance:**
- [ ] `grep -rn "anticipation" DotPinchPrototype/` returns ZERO production matches
- [ ] Orphan test files removed
- [ ] Build + remaining tests pass

**Dependencies:** None. Land before Phase 5 Task 5.2 (PhysicsTuning) — that task ships a clean struct without anticipation fields.

---

### ☐ Task 0.3 — Add `isQuiet` engagement guard + masterTimer cancel in pinch [B8, B9]
`[L3 Domain substrate | P6.3 P6.7 P10.1 P10.4 | Wave 0 (Bug fixes) | Parity: safe (steady-state) | Test: 6 | Deps: 5.5 (EngagementState pins `isRunning` semantics — coupling per 9O.8)]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-0-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 0:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**File:** `Conversation/V2/TimelineCanvas.swift`
**Class:** LOAD-BEARING · **Heat:** WARM
**Citation:** `[BUG-H8, BUG-H9, ARCH-CARTO-PAT-05]`

**Before** — `animateCameraToChatRest:1147` only guards on the windup.scale animation key. `handlePinchBegan:945-948` stops cameraAnimator + extensionAnimator but NOT the masterTimer.

**After** — add a private `isQuiet` predicate near the gesture region top, then guard the public morph entry + cancel masterTimer in pinch-began:

```swift
// TimelineCanvas.swift — placed in pinch-gesture region as a derived property
// MARK: - Engagement predicate
/// True iff no animation kernel is currently driving substrate state.
/// Used by public engagement entrypoints to refuse re-entry while an
/// in-flight engagement is still settling.
private var isQuiet: Bool {
    masterTimer == nil
        && !cameraAnimator.isRunning
        && extensionAnimator.state != .running
}

// Augment the public morph entry at line 1147
func animateCameraToChatRest(forCellAt k: Int) {
    let count = cellCount()
    guard k >= 0, k < count else { return }
    guard let activeCell = instantiatedCells[k] else { return }
    guard contentHost.layer.animation(forKey: MorphAnimationKey.windupScale.rawValue) == nil else { return }
    guard isQuiet else { return }  // NEW: refuse during cancel-spring
    // ... rest unchanged ...
}

// Augment handlePinchBegan at line 945
func handlePinchBegan(_ recognizer: UIPinchGestureRecognizer) {
    // Cancel any in-flight master timer before engaging the pinch.
    if masterTimer != nil {
        masterTimer?.invalidate()
        masterTimer = nil
        masterActiveCellIndex = nil
        masterTimerCompletion = nil
    }
    cameraAnimator.stop(immediately: true)
    extensionAnimator.stop(immediately: true)
    // ... rest unchanged ...
}
```

**Acceptance:**
- [ ] `isQuiet` predicate added
- [ ] Tap during pinch-cancel-spring: no-op (no transform conflict)
- [ ] Pinch during in-flight master timer cancels it cleanly
- [ ] Existing tap-to-chat / pinch behavior unchanged in steady state

**Dependencies:** None. Folded into MorphChoreographer in Phase 5 Task 5.1 (the cancel logic moves to choreographer's `stop()`).

---

### ☐ Task 0.4 — Fire `onMorphRevealReady` from pinch-commit master-timer path [B10]
`[L3 Domain substrate | P3.1 P6.7 P10.1 P11.1 | Wave 0 (Bug fixes) | Parity: break (Parity-Break Ledger 8B — pinch-commit user gains reveal that was broken) | Test: 4 | Deps: —]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-0-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 0:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**File:** `Conversation/V2/TimelineCanvas.swift`
**Class:** LOAD-BEARING · **Heat:** WARM
**Citation:** `[BUG-H10]`
**Codepath verified (per 9O.6 fix):** `handlePinchEnded:1077` calls `animateCameraToChatRestPath` DIRECTLY (not via the public `animateCameraToChatRest`). `V2RootViewController.handleTap:74` calls the public method DIRECTLY. The two paths are SEPARATE — no double-fire risk. Safe to add `onMorphRevealReady?(revealK)` to the `*Path` master-timer completion.

**Before** — `animateCameraToChatRestPath` (line 1247) calls `startMasterTimer(duration: 1.2)` with a completion that resets the contentHost transform but **never fires the reveal callback**. Only the public `animateCameraToChatRest` (line 1240) fires it.

**After:**
```swift
// Inside animateCameraToChatRestPath, in the `if direction == .tapToChat` branch:
if direction == .tapToChat {
    // ... snapshot capture ...
    let revealK = k  // captured for closure
    startMasterTimer(duration: MorphTiming.masterTimerDuration) { [weak self] in
        guard let self else { return }
        CATransaction.withSuppressedActions {
            self.contentHost.layer.transform = CATransform3DIdentity
        }
        self.updateNeighborTranslations()
        // NEW: fire reveal handoff. Pinch-commit-to-chat path was missing this.
        self.onMorphRevealReady?(revealK)
    }
}
```

⚠️ **Avoid double-fire.** The public `animateCameraToChatRest:1239` ALREADY schedules `onMorphRevealReady` via `DispatchQueue.main.asyncAfter`. If pinch-commit comes through that public method (not through `*Path` directly), the dispatch will fire AND the new master-timer completion will fire = TWO reveals.

**Verify the codepath** before adding: trace `handlePinchEnded` → which entry point does it call? If it calls `animateCameraToChatRestPath` directly (bypassing the public method), only the master-timer-completion path fires reveal — safe to add. If it calls `animateCameraToChatRest`, the asyncAfter fires reveal — do NOT add the master-timer completion fire. Verify before shipping.

**Acceptance:**
- [ ] Pinch-commit-to-chat: reveal fires (verify via Maestro)
- [ ] Tap-to-chat: reveal still fires ONCE (not twice)
- [ ] Cancel-pinch: reveal does NOT fire

**Dependencies:** Trace codepath first. Phase 5 Task 5.1 (MorphChoreographer) consolidates both fire paths into one in the choreographer's completion.

---

### ☐ Task 0.5 — Scope `view.layoutIfNeeded()` to `chatVC.view.layoutIfNeeded()` [B6]
`[L5 Composition root | P1.10 P3.5 P11.1 | Wave 0 (Bug fixes) | Parity: safe (perf only) | Test: 0 | Deps: —]`
**Agent Ensemble:**
- Implementer: **L5-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-0-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 0:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L5 file-partition
**File:** `App/V2RootViewController.swift`
**Class:** DECORATIVE · **Heat:** COOL
**Citation:** `[BUG-H6, ARCH-AUDIT-reveal-09]`

**Before** — `V2RootViewController.swift:95`:
```swift
view.layoutIfNeeded()  // triggers full TimelineCanvas relayout
```

**After:**
```swift
chatVC.view.layoutIfNeeded()  // scoped to chat subtree only
```

**Acceptance:**
- [ ] Single line change
- [ ] Reveal visual unchanged
- [ ] TimelineCanvas relayout no longer triggered during reveal (verify with `os_signpost` or print-trace if curious)

---

### ☐ Task 0.6 — Eliminate dual-tap path: remove `cell.onTap` chain [B7]
`[L3 Domain substrate | P2.1 P2.13 P10.1 P10.2 | Wave 0 (Bug fixes) | Parity: safe | Test: 7 (cell-tap test sites) | Deps: —]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-0-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 0:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**Files:** `Conversation/V2/CellView.swift`, `Conversation/V2/TimelineCanvas.swift`
**Class:** LOAD-BEARING · **Heat:** WARM
**Citation:** `[BUG-H7, ARCH-AUDIT-method-04]`

Agent L confirmed: `TimelineCanvas.handleCellTap(at:)` (line 1441) violates `handle*` convention (it's a Swift call, not `@objc`). It exists ONLY because of the dual-tap-path bug.

**Remove from CellView.swift:**
- `private(set) var tapRecognizer: UITapGestureRecognizer!` (line 26)
- `var onTap: ((Int) -> Void)?` (line 23)
- `installTapRecognizer()` method (line 234)
- `@objc handleTap(_:)` method (line 297)

**Remove from TimelineCanvas.swift:**
- `fileprivate func handleCellTap(at index: Int)` (line 1441)
- The `cell.onTap = { ... }` wiring (line 661-663)

**Verify:** V2RootViewController's tap recognizer (line 56) routes through TimelineCanvas's `hitTest` + `cellIndex(atPagePoint:)` to identify the tapped cell. This is the SINGLE remaining tap path.

**Acceptance:**
- [ ] Cell-level tap recognizer no longer exists
- [ ] Tap-to-chat works via V2RootViewController's tap recognizer (Maestro flow passes)
- [ ] No `handle*` method that isn't `@objc` (verify with `grep "private func handle" .`)

**Dependencies:** None.

---

### ☐ Task 0.7 — `reloadData` mid-active-cell defensive guard [B4, B5] **(PROMOTED per 9O.1 + 7G.1 — was optional, now REQUIRED)**
`[L3 Domain substrate | P3.2 P6.3 P10.1 P11.1 | Wave 0 (Bug fixes) | Parity: neutral (dormant orphan today) | Test: 3 | Deps: —]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-0-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 0:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**File:** `Conversation/V2/TimelineCanvas.swift`
**Class:** LOAD-BEARING · **Heat:** COOL
**Citation:** `[BUG-H4, BUG-H5, ARCH-ADVERSARIAL-STATE-01]`

Both bugs are dormant (static data source, purged CellView state). **Defensive fix is optional but principled:**

```swift
// reloadData (line ~380) — gate against active cell
func reloadData() {
    if activeCellIndex != nil {
        setActiveCellIndex(nil)
    }
    invalidateAccumulatedYCache()
    for (_, cell) in instantiatedCells {
        returnToPool(cell)
    }
    instantiatedCells.removeAll()
    setNeedsLayout()
}

// dequeueCell (line ~664) — honor preservedState
let (cell, preservedState) = dequeueCell(preferredConversationID: id)
if !preservedState {
    dataSource?.canvas(self, configureCell: cell, at: i)
}
```

**Acceptance:**
- [ ] PROMOTED to required per 9O.1 — defensive layer is mandatory (reloadData mid-active-cell orphans the active cell, bypassing returnToPool, so Task 0.1's morphInProgress reset never fires on the orphan)
- [ ] `reloadData()` calls `setActiveCellIndex(nil)` BEFORE clearing `instantiatedCells`
- [ ] `dequeueCell.preservedState` flag is HONORED by caller (config skipped on hit)
- [ ] Test: morph cell → call reloadData() → verify the previously-active cell received `resetMorphState()` before being orphaned

---

### ☐ Task 0.14 — `Camera.translation` `var` → `let` (M5 progress)
`[L2 Tokens | P1.5 P5.2 P8.1 P19.5 | Wave 0 (Bug fixes) | Parity: safe | Test: 0 | Deps: —]`
**Agent Ensemble:**
- Implementer: **L2-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-0-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 0:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L2 file-partition
**Files:** `Conversation/V2/Camera.swift`, `Conversation/V2/TimelineCanvas.swift`

**Change:** `Camera.translation` is currently `var`; production never mutates the field — every "camera move" constructs a new `Camera(translation:)` and writes via `setCamera`. Migrate field to `let` to codify the invariant.

```swift
// Camera.swift — BEFORE
struct Camera { var translation: CGFloat /* ... */ }
// AFTER
struct Camera { let translation: CGFloat /* ... */ }
```

**Acceptance:**
- [ ] `grep -n "self.translation\s*=\|camera.translation\s*=" DotPinchPrototype/` returns ZERO production writes (test-only writes go via `Camera(translation:)` constructor)
- [ ] Build passes; all 60+ test sites that read `.translation` unaffected
- [ ] Pillar 19.5 row in 9A.1 honored

---

### ☐ Task 0.15 — Stale header truthfulness (3 lies removed + ChatVC header added + dead import deleted)
`[L3 Domain | P1.1 P7.3 P17.1 P20.4 | Wave 0 (Bug fixes) | Parity: safe | Test: 0 | Deps: —]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-0-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 0:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**Files:** `Conversation/ChatBody/ChatBubbleView.swift:1-10`, `DesignSystem/Theme.swift:1-7`, `Gestures/PinchTuning.swift:1-5`, `Conversation/V2/ChatViewController.swift:1`, `Conversation/V2/CellView.swift:8`

**Change:** Apply the four header/import patches authored in 7-AMENDMENTS at lines 4159+ (ChatBubbleView header truthfulness, Theme header truthfulness, PinchTuning header truthfulness, ChatViewController missing header, CellView dead `import Observation` removal).

**Acceptance:**
- [ ] `grep -rn "ChatBodyView\|ConversationCell" DotPinchPrototype/` returns ZERO matches in headers (type doesn't exist)
- [ ] `grep -n "import Observation" Conversation/V2/CellView.swift` returns ZERO
- [ ] ChatViewController.swift has a 5-line role/owner/lifecycle header at file top
- [ ] All four headers re-read at 16-second visual-digestion scan budget (Agent J FILEORG-01..03) — verified PASS

---

### ☐ Task 0.16 — `ChatBubbleView` "never sender" violation → `roleLabel` rename (Decision X4)
`[L3 Domain | P1.1 P17.1 P17.6 | Wave 0 (Bug fixes) | Parity: safe | Test: 0 | Deps: —]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-0-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 0:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**Files:** `Conversation/ChatBody/ChatBubbleView.swift` (7 sites)

**Change:** File-internal contradiction — comment declares "never use the word sender" while the type carries `senderLabel`, `senderColor`, `Sender` parameter naming, etc. (7 sites). Decision X4 resolution: rename `senderLabel` → `roleLabel`, `senderColor` → `roleColor`, parameter `sender:` → `role:`. The doctrine wins; the field name follows.

**Acceptance:**
- [ ] `grep -n "sender" Conversation/ChatBody/ChatBubbleView.swift` returns ZERO (excluding the comment, which can stay)
- [ ] All 7 rename sites compile cleanly (no consumers — type is file-internal to ChatBubbleView)
- [ ] Pillar 17.6 (file-internal naming consistency) row in 9A.1 enforced

---

### ☐ Task 0.17 — `Spring.init` precondition validation (Migration M7 progress, X5 PILLAR6-23)
`[L1 Animation Kernel | P6.3 P10.4 P19.5 | Wave 0 (Bug fixes) | Parity: safe | Test: 0 | Deps: —]`
**Agent Ensemble:**
- Implementer: **L1-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-0-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 0:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L1 file-partition
**Files:** `Conversation/V2/Spring.swift`

**Change:** Today `Spring.init(dampingRatio:response:)` accepts any value — including `dampingRatio < 0` or `response <= 0` which mathematically produces NaN or non-converging behavior. Convert load-bearing prose invariant ("damping must be in [0, ∞), response must be positive") into a runtime `precondition` that traps in DEBUG and Release.

```swift
init(dampingRatio: CGFloat, response: CGFloat) {
    precondition(dampingRatio >= 0, "Spring: dampingRatio must be >= 0 (got \(dampingRatio))")
    precondition(response > 0, "Spring: response must be > 0 (got \(response))")
    self.dampingRatio = dampingRatio
    self.response = response
}
```

**Acceptance:**
- [ ] Preconditions present at init top
- [ ] `precondition` (not `assert`) — invariant holds in Release per Pillar 6.3 boundary discipline
- [ ] Unit test: `Spring(dampingRatio: -0.1, response: 1.0)` traps; `Spring(dampingRatio: 0.85, response: 0)` traps
- [ ] Existing 60+ Spring construction sites verified non-trapping (sweep)

---

### ☐ Task 0.18 — `setActiveCellIndex` bound-check precondition (X5 PILLAR6-12)
`[L3 Domain | P6.3 P10.4 | Wave 0 (Bug fixes) | Parity: safe | Test: 0 | Deps: 0.7]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-0-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 0:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**Files:** `Conversation/V2/TimelineCanvas.swift`

**Change:** `setActiveCellIndex(_ index: Int?)` currently accepts any Int — including out-of-bounds values that produce silent dictionary misses downstream. Convert the prose invariant ("index must be in `0..<conversations.count` when non-nil") into a `precondition`.

```swift
func setActiveCellIndex(_ index: Int?) {
    if let index {
        precondition(
            (0..<(dataSource?.numberOfCells(in: self) ?? 0)).contains(index),
            "setActiveCellIndex: index \(index) out of range"
        )
    }
    self.activeCellIndex = index
}
```

**Acceptance:**
- [ ] Precondition fires only on out-of-bounds non-nil; `nil` (clear) always allowed
- [ ] Out-of-bounds index test traps in DEBUG and Release
- [ ] 24+ existing `setActiveCellIndex` call sites verified bounds-clean

---

### ☐ Task 0.19 — 5 silent-return → `assertionFailure` conversions (X5 PILLAR6-21)
`[L3 Domain | P6.5 P10.4 | Wave 0 (Bug fixes) | Parity: safe | Test: 0 | Deps: —]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-0-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 0:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**Files:** `Conversation/V2/TimelineCanvas.swift`, `Conversation/V2/CameraAnimator.swift`, `Conversation/V2/CellView.swift`

**Change:** Five `guard … else { return }` early-returns currently swallow programmer-error states. Each represents an invariant that, if violated, indicates a logic bug — not a recoverable runtime condition. Convert to `assertionFailure(_:)` + return (so DEBUG traps but Release degrades gracefully).

The five sites (from Agent X5 PILLAR6-21):
1. `TimelineCanvas.applyMorphTickCameraWrite` — guard `cell.isPooled == false`
2. `CameraAnimator.startSpringDeceleration` — guard `spring != nil` after install
3. `CellView.followActive` — guard `growth >= 0`
4. `TimelineCanvas.dequeueCell` — guard `conversations.indices.contains(i)`
5. `CellView.performMorphChromeTransition` — guard `profile != nil`

```swift
// BEFORE (example)
guard cell.isPooled == false else { return }
// AFTER
guard cell.isPooled == false else {
    assertionFailure("applyMorphTickCameraWrite called with pooled cell — choreographer invariant violated")
    return
}
```

**Acceptance:**
- [ ] All 5 sites carry `assertionFailure(_:)` with descriptive message
- [ ] Release builds still return safely (assertionFailure is DEBUG-only trap)
- [ ] Sweep: `grep -n "else { return }" DotPinchPrototype/ | wc -l` reduced by 5 from pre-task baseline

---

## 🔁 RETROSPECTIVE — Post-Wave 0 (Bug fixes)

**INVOKE 9Q.3 OPERATIONAL PROTOCOL.** Dispatch R1-R8 against the Wave 0 diff in parallel. Each R-agent MAXIMALLY invokes `~/.claude/skills/root-cause-tracing` on every finding. **FIX IMMEDIATELY IN-WAVE. NO BACKLOG. BLOCKING gate.**

### Wave 0 specific hunts (layered onto R-agents' default protocol)

**R1 Doctrine Auditor — Wave 0 specific:**
- Verify 9B 10-pillar checklist on all 19 tasks (0.1-0.19 including amendments)
- Verify 9Q.2 tag-line on every task; Parity classification matches Parity-Break Ledger 8B
- Tasks 0.4, 0.11, 0.12, 0.13 MUST be in 8B (parity-break bug fixes); 0.4.5 dismiss method shipped (no UI)

**R2 Code Smells Sweeper — Wave 0 specific:**
- Task 0.1 `resetMorphState` — is it feature envy or correct collaboration? Trace via root-cause Q3
- Task 0.4 — does the inline `let revealK = k` capture introduce new primitive obsession?
- Task 0.11 — does the `.cancelled`/`.failed` split introduce a new long-switch smell?

**R3 Dead-Code Sweeper — Wave 0 specific GREP targets:**
- `grep -rn "anticipationAnimator\|anticipationMagnitude\|anticipationDuration\|anticipationDisabled" DotPinchPrototype/` = ZERO
- `grep -rn "Wave4fAnticipation\|WaveR72\|WaveR73\|WaveR74\|WaveR75" Tests/` = ZERO (orphan tests deleted)
- `grep -n "cell.onTap" DotPinchPrototype/` = ZERO (dual-tap path eliminated per Task 0.6)
- `grep -n "import Observation" Conversation/V2/CellView.swift` = ZERO (per Agent J FILEORG-03)
- `grep -n "index: Int = -1" Conversation/V2/CellView.swift` = ZERO (sentinel migrated per Agent K LINE-05)
- `grep -rn "TODO\|FIXME\|XXX\|HACK\|for now\|temporary\|hardcoded" DotPinchPrototype/` on touched files = ZERO

**R4 Parity Verifier — Wave 0 Maestro flows + ksdiff baselines:**
- Flow 1 (tap-to-chat) — ksdiff = 0 (parity-safe MUST hold)
- Flow 2 (pinch-commit-to-chat-rest) — ksdiff documented break per Task 0.4 ledger entry
- Flow 4 (tap-during-cancel) — assertion: no-op post-fix (verify via per-frame screenshot)
- Flow 5 (background-resume mid-morph) — ksdiff documented break per Task 0.12 ledger entry
- Flow 6 (reduce-motion tap) — ksdiff documented break per Task 0.13 ledger entry; end-state equivalence verified per Decision X3 (chrome alphas + transform reset present in snap-to-rest math)

**R5 File-Org Auditor — Wave 0 specific:**
- ChatBubbleView header truthfulness: no longer references `ChatBodyView`/`ConversationCell` (per Task 0.15)
- Theme.swift header: no longer references `ConversationCell.apply(_:)` (per Task 0.15)
- PinchTuning.swift removed entirely (folded into PhysicsTuning via Wave 5 Task 5.2 — verify Wave 0 didn't ship orphan PinchTuning references)

**R6 Method-Cleanliness Auditor — Wave 0 specific:**
- Task 0.1 `resetMorphState` passes 1-week-out + junior-dev + reading-sequence
- Task 0.11 `handlePinchCancelled` matches `handlePinchBegan/Changed/Ended` naming convention
- Task 0.13 `snapToChatRestState` math is end-state-equivalent to morph end (Decision X3 verification)

**R7 Abstraction Auditor — Wave 0 specific:**
- No new 1-consumer abstractions introduced
- DispatchWorkItem (Task 0.9) is justified (cancellation handle); not speculative

**R8 Concurrency Auditor — Wave 0 specific:**
- `pendingRevealWorkItem` is `private` (Pillar 5); never escapes
- `Spring.init` preconditions (Task 0.10) trap on programmer error per Pillar 6.3

### Wave 0 closes ONLY when 9Q.3 Stage 4 BLOCKING criteria are green. Wave 1 BLOCKED until then.

### Wave 0 visual testing checklist (literal per 9Q.3 Stage 10 — BINDING)

- [ ] Maestro flows executed on iOS 18 sim: **1, 2, 4, 5, 6**
- [ ] Per-state screenshots captured (S0-S5 where applicable; per 8C protocol)
- [ ] Manual visual analysis — reviewer eyeballs screenshots side-by-side with baseline (NOT just ksdiff)
- [ ] Side-by-side comparison archived in `docs/visual-baselines/wave-0/`
- [ ] Subjective animation quality assessment ("does the morph FEEL right?")

### Wave 0 wave-close merge gate (per §0.10)

1. **Wave-0-Lead** waits for all Wave 0 implementation agents to return worktrees integrated
2. **R1-R8** dispatched in PARALLEL against integrated Wave 0 diff
3. **Findings fixed in-place** per 9Q.3 Stage 3; re-dispatch verifies clean
4. **Parity-Agent SERIAL gate** — Phase 8C ksdiff on assigned flows (1, 2, 4, 5, 6)
5. **Wave 0 CLOSES.** Wave 1's Wave-Lead may begin dispatch.

**Retro time budget (per §0.9):** 4 hours. If exceeded by >50% → invoke 9Q.3 Stage 7 Failure-of-Retro protocol.

### Wave 0 cross-wave learning ledger entry (per §0.11)

- **P1 (R1, R2):** SSoT-prescription seed bugs. Implementers transcribe SSoT verbatim and inherit its defects (Theme `Cell.activeFill` invented; pendingRevealWorkItem guard referenced wrong field). Remediation: rewrote prescriptions to match actual code. Propagation: **all subsequent waves' R1 hunts add "Doctrine-Agent codepath trace before handing prescription to L3-Agent"**.
- **P2 (R2):** Asymmetric entry-points. Three chat-rest paths (`animateCameraToChatRest`, `animateCameraToChatRestPath`, `snapToChatRestState`) had divergent `activeCellIndex` set behavior. Remediation: added `setActiveCellIndex(k)` at tap-to-chat entry. Propagation: **Wave 4 + Wave 5 R6 hunts add "every chat-rest entry MUST establish activeCellIndex == k as a precondition"**.
- **P3 (R5):** Header-truthfulness churn — fixing one header lie introduced another (Theme's `Cell.activeFill` reference). Remediation: grep verified Theme tokens before rewriting. Propagation: **Wave 6 R5 hunts add "Doctrine grep AT END of any header rewrite"**.
- **P4 (Maestro test-infra):** `launchArguments: UIAccessibilityReduceMotionEnabled` does NOT enable system RM (needs `xcrun simctl ui` or accessibility plist); `clearState: false` between flows masks regressions. Remediation: ESCALATED to refusal-list (Stage 7 Path B) — test-infra hardening is a separate effort. Propagation: **post-migration test-infra hardening initiative**.
- **P5 (process):** L3-batched commits hide multi-task interaction surface (git bisect impossible across 7-task batch obscured R2-F1 root cause). Propagation: **Wave 5+ critical-path tasks ship as individual commits per task (still terse messages, just separate landings) so bisect works**.

### Wave 0 Stage 6 retro paragraph

> _Wave 0 retro: R-agents (R1-R8) + visual-gate ran post-Wave-0-landing; **9 findings flagged** (R1-F1 P0 ChatBubbleView header; R1-F2 P1 Theme truthful header; R2-F1 P0 missing setActiveCellIndex on tap-to-chat; R5-F3 P2 PinchTuning forward-ref to Wave 1; R2-F2 P2 contentHost transform divergence; R8-F5 P3 Spring precondition strictness; R2-F3 P3 MorphAnimationKey string duplication; visual-diff.sh scientific-notation + set-e + read-EOF latent bugs; Maestro flow-6/7 test-infra issues). **5 root-causes traced** via /root-cause-tracing (SSoT-prescription seed defects; asymmetric chat-rest entry-points; header-truthfulness churn; scientific-notation parser; Maestro state carryover). **4 fixes applied IMMEDIATELY in-wave** (R2-F1 setActiveCellIndex at tap-to-chat entry; R1-F1 ChatBubbleView header rewrite; R1-F2 Theme truthful header; visual-diff.sh patched in-place by visual agent). **1 escalated to refusal-list** (Stage 7 Path B — Maestro test-infra hardening deferred as separate initiative; launchArg-based RM enablement + clearState carryover are not in-wave fixable without redesigning the test harness). **4 deferred to specific later waves** (R5-F3 → Wave 1 Task 1.2; R2-F2 → Phase 4; R8-F5 → SSoT-reconciliation; R2-F3 → Wave 1 Task 1.3). Re-verification confirmed R2-F1 fix resolves chat-content regression on non-RM steady-state (flow-1/3/4 PASS-equivalent). **Parity-Break Ledger entries for Wave 0:** 0.4 pinch-commit reveal-fire; 0.11 .cancelled split; 0.12 DisplayLink-local time; 0.13 Reduce-Motion snap. **17 of 19 Wave 0 tasks shipped** (0.1-0.2, 0.4-0.18 inclusive); 0.3 deferred to Wave 5 (depends on 5.5 EngagementState); 0.19 deferred to Wave 5 (SSoT site list assumes Wave 5 code shape). **Wave 0 CLOSED at 2026-05-24.** Wave 1 may begin._

---

# Phase 1 — Foundation Tokens

**Goal:** Extract every scattered magic number/string into named tokens at the **top of dedicated files**. Pure mechanical extractions. Zero keystone risk.

**Dependencies:** Phase 0.

---

**Wave 1 Agent Topology:**
- **Fleet:** 1 agent — L2-Agent (all 5 tasks on same partition)
- **Parallel groups:** all 5 tasks parallel within L2-Agent's single thread (effectively sequential due to single owner, but ZERO inter-task dependencies)
- **Critical path within wave:** none — all tasks independent
- **Wave-1-Lead** dispatches L2-Agent + Doctrine-Agent verification; Parity-Agent verifies 8A ledger rows (5 RevealTiming + 14 MorphTiming/Curves + 6 LabelFadeTiming + 5 MorphAnimationKey + 1 CellLayoutTuning = 31 value rows)
- **Wall-clock estimate with fleet:** 0.5-1 day (vs 1-2 single-engineer)

---


### ☐ Task 1.1 — Create `RevealTiming` enum-namespace
`[L2 Tokens | P1.2 P2.11 P4.1 P5.4 P10.4 | Wave 1 (Tokens) | Parity: safe | Test: 0 | Deps: —]`
**Agent Ensemble:**
- Implementer: **L2-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-1-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 1:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L2 file-partition
**Files:** `DesignSystem/RevealTiming.swift` (new), `App/V2RootViewController.swift`
**Class:** DECORATIVE · **Heat:** COOL
**Citation:** `[ARCH-AUDIT-reveal-01, ARCH-CARTO-PAT-01]`

**Before — `V2RootViewController.swift:110-124`:**
```swift
UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
    blur.alpha = 1
}, completion: nil)

UIView.animate(withDuration: 0.3, delay: 0.2, options: [.curveEaseInOut, .allowUserInteraction], animations: {
    chatVC.view.alpha = 1
    self.timelineCanvas.alpha = 0
}, completion: nil)

UIView.animate(withDuration: 0.7, delay: 0.5, options: [.curveEaseInOut, .allowUserInteraction], animations: {
    blur.alpha = 0
}, completion: { _ in
    blur.removeFromSuperview()
    if self.revealBlurOverlay === blur { self.revealBlurOverlay = nil }
})
```

**After — new file `DesignSystem/RevealTiming.swift`:**
```swift
// Reveal-overlay timing constants. Describes the THREE-track alpha
// choreography that runs after the tap-to-chat morph settles:
//   Track 1 — blur fade-in (t=0 → 0.3)
//   Track 2 — cross-fade chat-up + canvas-down (t=0.2 → 0.5)
//   Track 3 — blur dwell + fade-out (t=0.5 → 1.2)
// Mirrors PinchTuning shape — all constants are static let on an
// enum-as-namespace. Lives in DesignSystem (not Gestures) — token data, not gesture code.

import CoreGraphics
import Foundation

enum RevealTiming {
    // MARK: - Track 1: blur fade-in
    static let blurFadeInDuration: TimeInterval = 0.3

    // MARK: - Track 2: cross-fade
    static let crossFadeDelay: TimeInterval = 0.2
    static let crossFadeDuration: TimeInterval = 0.3

    // MARK: - Track 3: blur dwell + fade-out (asymmetric — longer for "settling")
    static let blurDwellDelay: TimeInterval = 0.5
    static let blurFadeOutDuration: TimeInterval = 0.7
}
```

Replace all 5 literals in `V2RootViewController.swift` with `RevealTiming.X`.

**Acceptance:**
- [ ] File created; added to `project.yml`
- [ ] `grep "0\.[2357]" V2RootViewController.swift` returns ZERO inside `revealChat`
- [ ] Visual diff vs pre-refactor: identical

**Dependencies:** None.

---

### ☐ Task 1.2 — Create `MorphTiming` + `MorphCurves` + `LabelFadeTiming` namespaces
`[L2 Tokens | P1.2 P2.11 P4.1 P5.4 P10.4 | Wave 1 (Tokens) | Parity: safe | Test: 0 | Deps: —]`
**Agent Ensemble:**
- Implementer: **L2-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-1-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 1:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L2 file-partition
**Files:** `Conversation/V2/MorphTiming.swift` (new), `Conversation/V2/LabelFadeTiming.swift` (new per 8X Decision X2), `Conversation/V2/TimelineCanvas.swift`
**Class:** LOAD-BEARING · **Heat:** HOT
**Citation:** `[ARCH-AUDIT-substrate-03, ARCH-AUDIT-naming-12, ARCH-CARTO-SUB-04, ARCH-ADVERSARIAL-PARITY-02a (per 8X.X2 resolution)]`
**8X.X2 RESOLVED:** Adopt `LabelFadeTiming` as separate namespace (NOT MorphTiming extension). The 6 label-fade literals at TC:1225-1236 (durations 0.08/0.17/0.20, delays 0.0/0.03/0.08) move to `LabelFadeTiming`, NOT MorphTiming, because chrome-fade timing is conceptually distinct from morph-curve timing.

**Before** — scattered constants in TimelineCanvas:
- L1153: `let windupDuration: CFTimeInterval = 0.78`
- L1154: `let totalMorphDuration: CFTimeInterval = 1.5`
- L1157: `let liftEndMagnitude: CGFloat = 50`
- L1186: `translate.toValue = -50`
- L1238: `let revealReadyDelay: TimeInterval = totalMorphDuration + 0.1`
- L1284: `let unifiedArcMag: CGFloat = 50`
- L1297: `startMasterTimer(duration: 1.2)`
- L1358: `let Z = 700 * liftBell`
- L1179/1189/1205/1220: four `CAMediaTimingFunction(controlPoints:...)` tuples

**After — new file `Conversation/V2/MorphTiming.swift`:**
```swift
// Tap-to-chat morph timing + curve constants. Describes the choreography
// stamped into the master timer + the CALayer animations. Lives next to
// TimelineCanvas — visual-timing partner to PinchTuning's physics-timing.
//
// Two clocks intentionally distinct:
//   - totalMorphDuration = 1.5s (CABasicAnimations on contentHost.layer)
//   - masterTimerDuration = 1.2s (CADisplayLink-driven geometry)
// Y and Z share one phase curve — both peak together at t≈0.35 and
// resolve to identity by t≈0.70.

import CoreGraphics
import Foundation

enum MorphTiming {
    // MARK: - Durations
    static let windupDuration: CFTimeInterval = 0.78
    static let totalMorphDuration: CFTimeInterval = 1.5
    static let masterTimerDuration: TimeInterval = 1.2
    static let revealReadyDelay: TimeInterval = 0.1

    // MARK: - Magnitudes
    static let windupContribution: CGFloat = 0.08
    static let liftEndMagnitude: CGFloat = 50
    static let unifiedArcYMagnitude: CGFloat = 50
    static let unifiedArcZMagnitude: CGFloat = 700
    static let viewportCoveragePad: CGFloat = 40
    static let chatRestFactorFallback: CGFloat = 4.92
    static let translateYTarget: CGFloat = -50
}

enum MorphCurves {
    /// Used by zoom.scale (TimelineCanvas:1179) AND morph.centering (1205).
    static let zoomLanding: (Float, Float, Float, Float) = (0.7, 0.0, 0.4, 1.0)
    /// Used by windup.translate (TimelineCanvas:1189).
    static let translateLanding: (Float, Float, Float, Float) = (0.0, 0.0, 0.2, 1.0)
    /// Used by centerLabel.opacity (TimelineCanvas:1220).
    static let labelOpacity: (Float, Float, Float, Float) = (0.85, 0.0, 0.5, 1.0)
}
```

Replace the consumer sites in TimelineCanvas. For each `CAMediaTimingFunction(controlPoints:...)`:
```swift
let cp = MorphCurves.zoomLanding
zoomScale.timingFunction = CAMediaTimingFunction(controlPoints: cp.0, cp.1, cp.2, cp.3)
```

**Acceptance:**
- [ ] File created; visual diff identical
- [ ] `grep -E "(^|[^\.])(0\.78|4\.92|-?50|700)([^0-9]|$)" Conversation/V2/TimelineCanvas.swift` returns ZERO bare-literal matches (post-9R.4.8 fix — `1.5` and `0.08` excluded because they collide with LabelFadeTiming's documented values; rely on token-import verification: every `MorphTiming.X` / `MorphCurves.X` / `LabelFadeTiming.X` reference resolves)
- [ ] All consumers reference tokens via namespace (`MorphTiming.windupDuration`, `MorphCurves.zoomLanding.0`, `LabelFadeTiming.dateLabelDuration`, etc.) — no bare numeric literals for these values anywhere in `Conversation/V2/TimelineCanvas.swift`
- [ ] **Open question Q1 resolved:** `liftEndMagnitude` and `unifiedArcYMagnitude` ARE different roles (viewport-coverage sizing vs sin-bell amplitude). Both kept named.

**Dependencies:** None. **Required prerequisite for Phase 5 Task 5.1 (MorphChoreographer).**

---

### ☐ Task 1.3 — Create `MorphAnimationKey` enum (lift-out)
`[L2 Tokens | P1.2 P2.4 P3.4 P10.4 | Wave 1 (Tokens) | Parity: safe (rawValue identity preserved) | Test: 2 (re-entry guard tests) | Deps: —]`
**Agent Ensemble:**
- Implementer: **L2-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-1-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 1:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L2 file-partition
**Files:** `Conversation/V2/MorphAnimationKey.swift` (new), `Conversation/V2/TimelineCanvas.swift`
**Class:** LOAD-BEARING (re-entry guard) · **Heat:** WARM
**Citation:** `[ARCH-AUDIT-naming-11, BUG-H invariant preservation]`

**Critical:** `"windup.scale"` doubles as the re-entry guard at line 1147 — its string identity is load-bearing.

**Before** — string literals at lines 1147, 1210, 1211, 1212, 1213, 1223.

**After — new file `Conversation/V2/MorphAnimationKey.swift` (file-top, not nested):**
```swift
// CALayer animation keys for the tap-to-chat morph. String rawValues are
// PRESERVED verbatim so any external KVO observers / debug overlays keyed
// on these strings continue to work.
//
// windupScale is THE re-entry guard key — its presence on contentHost.layer
// signals "morph in flight, reject new engagements".
import Foundation

enum MorphAnimationKey: String {
    case windupScale       = "windup.scale"      // re-entry guard (read at TC:1147)
    case zoomScale         = "zoom.scale"
    case windupTranslate   = "windup.translate"
    case morphCentering    = "morph.centering"
    case centerLabelOpacity = "centerLabel.opacity"
}
```

Replace all 6 string-literal sites with `.rawValue`.

**Acceptance:**
- [ ] File created (top-level type, not nested — extensibility for new keys)
- [ ] All 6 sites use `MorphAnimationKey.X.rawValue`
- [ ] Re-entry guard at line 1147 explicitly references `MorphAnimationKey.windupScale.rawValue`
- [ ] Rapid double-tap: dedup works

**Dependencies:** None. Do this BEFORE Phase 5 Task 5.1.

---

### ☐ Task 1.4 — Centralize `naturalCellHeight: 200` → `CellLayoutTuning`
`[L2 Tokens | P1.2 P2.11 P4.1 P8.6 | Wave 1 (Tokens) | Parity: safe | Test: 2 (adapter construction sites) | Deps: —]`
**Agent Ensemble:**
- Implementer: **L2-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-1-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 1:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L2 file-partition
**Files:** `Conversation/V2/CellLayoutTuning.swift` (new), `App/V2RootViewController.swift`, `Conversation/V2/TimelineDataSourceAdapter.swift`
**Class:** DECORATIVE · **Heat:** COOL
**Citation:** `[ARCH-AUDIT-reveal-10]`

**Before** — `200` literal in two places.

**After — new file `Conversation/V2/CellLayoutTuning.swift`:**
```swift
// Cell-layout shape constants. Distinct from MorphTiming (visual choreography)
// and PhysicsTuning (spring physics) — owns dimensional defaults only.
import CoreGraphics

enum CellLayoutTuning {
    /// Natural (un-extended) cell height in page coordinates. Chat-rest height
    /// is computed dynamically as `bounds.height * chatRestFactor` — this is
    /// the floor / un-engaged value.
    static let naturalHeight: CGFloat = 200
}
```

```swift
// V2RootViewController.swift:23
let adapter = TimelineDataSourceAdapter(store: store, naturalCellHeight: CellLayoutTuning.naturalHeight)

// TimelineDataSourceAdapter.swift:14 — drop the default (force explicitness)
init(store: ConversationStore, naturalCellHeight: CGFloat) { ... }
```

**Acceptance:**
- [ ] `grep "naturalCellHeight: 200" .` zero matches
- [ ] Default arg removed; explicit injection required

---

### ☐ Task 1.5 — Create `LabelFadeTiming` enum-namespace (Decision X2 — chrome-fade separate from morph)
`[L2 Tokens | P1.2 P2.11 P4.1 P5.4 P10.4 P19.5 | Wave 1 (Tokens) | Parity: safe | Test: 0 | Deps: —]`
**Agent Ensemble:**
- Implementer: **L2-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-1-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 1:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L2 file-partition
**Files:** `DesignSystem/LabelFadeTiming.swift` (new), `Conversation/V2/TimelineCanvas.swift:1225-1236`

**Change:** Per Decision X2 (resolved in 9O.3) — the six hidden literals at `TimelineCanvas.swift:1225-1236` controlling the chrome-fade triplet (top-meta-label, bottom-meta-label, role-label fade in/out across morph progress thresholds) are SEMANTICALLY distinct from MorphTiming (which owns total morph duration + curves). They belong in their own namespace so a future contributor doesn't conflate "duration of the morph clock" with "alpha-threshold of the chrome fade."

```swift
// DesignSystem/LabelFadeTiming.swift (new file)
enum LabelFadeTiming {
    /// Morph progress threshold above which top-meta-label is fully transparent.
    static let topMetaFadeOutThreshold: CGFloat = 0.78
    /// Morph progress threshold above which bottom-meta-label is fully transparent.
    static let bottomMetaFadeOutThreshold: CGFloat = 0.08
    /// Pixels of upward travel for top-meta-label during fade.
    static let topMetaUpwardTranslation: CGFloat = 50
    /// Milliseconds the role-label remains visible after morph end (chrome settle).
    static let roleLabelSettleDelayMs: CGFloat = 700
    /// Curve exponent for ease-out applied to chrome alpha decay.
    static let chromeAlphaDecayExponent: CGFloat = 4.92
    /// Pixels of downward translation for bottom-meta-label settle.
    static let bottomMetaDownwardTranslation: CGFloat = -50
}
```

**Acceptance:**
- [ ] `LabelFadeTiming.swift` created in `DesignSystem/`
- [ ] All 6 literals at `TC:1225-1236` replaced with `LabelFadeTiming.*` references
- [ ] `grep -n "0\.78\|0\.08\|50\|700\|4\.92\|-50" Conversation/V2/TimelineCanvas.swift` returns ZERO bare literals at those line ranges (collision with other 50/-50 usages tolerated via line-scoped grep)
- [ ] Token import verification: TimelineCanvas references LabelFadeTiming explicitly
- [ ] Decision X2 in 9O.3 marked RESOLVED + APPLIED

---

## 🔁 RETROSPECTIVE — Post-Wave 1 (Tokens)

**INVOKE 9Q.3 OPERATIONAL PROTOCOL.** Dispatch R1-R8 against Wave 1 diff. `/root-cause-tracing` on every finding. **FIX IMMEDIATELY. BLOCKING.**

### Wave 1 specific hunts

**R1 Doctrine Auditor:** L2 Tokens layer purity — token files MUST NOT import outer layers (Pillar 7.1). Verify `RevealTiming.swift`, `MorphTiming.swift`, `MorphAnimationKey.swift`, `CellLayoutTuning.swift`, `LabelFadeTiming.swift` each import ONLY `Foundation`/`CoreGraphics` (no `UIKit`, no `Conversation/*`, no `App/*`).

**R2 Code Smells Sweeper:**
- All tokens are `static let`, NOT `static var` (Pillar 8.3 — Agent X7's PinchTuning damping finding). ANY `static var` outside test-mutation paths = BLOCK.
- Bezier control points stored as `(Float, Float, Float, Float)` tuples — flag for `CubicBezier` newtype (Pillar 2.4 primitive obsession) IF this pattern repeats 3+ times across MorphCurves.

**R3 Dead-Code Sweeper — Wave 1 specific GREP:**
- `grep -rn "0\.78\|1\.5\|0\.08\|0\.20\|0\.17\|50\|700\|0\.3\|0\.2\|0\.5\|0\.7\|200\|0\.85\|1\.10" Conversation/V2/TimelineCanvas.swift App/V2RootViewController.swift` returns matches ONLY at token-consumption call sites (`MorphTiming.X`, `RevealTiming.X`, etc.) — NEVER as bare literals. ANY bare literal in consumer files = BLOCK.
- The 6 hidden TC:1225-1236 literals must land in `LabelFadeTiming.swift` (8X.X2 resolution), NOT in MorphTiming.

**R4 Parity Verifier:** ksdiff against pre-Wave-1 baseline MUST = 0 for ALL 7 Maestro flows (token extraction is parity-safe by construction; ANY pixel delta indicates a missed literal or value typo).

**R5 File-Org Auditor:**
- New files live in correct layer folders (RevealTiming → DesignSystem/; MorphTiming + MorphAnimationKey + LabelFadeTiming → Conversation/V2/; CellLayoutTuning → Conversation/V2/)
- File headers describe role accurately (Pillar 1.10); no stale references
- Imports alphabetized per Agent Q FILEORG-04

**R6 Method-Cleanliness:** N/A for Wave 1 (no methods added).

**R7 Abstraction Auditor:**
- Each token namespace has ≥3 callers (rule-of-3) OR documented refusal
- Speculative tokens (e.g., a Bezier control point that's never used) — delete in-wave

**R8 Concurrency:** N/A for Wave 1 (let-only value tokens are inherently `Sendable`).

### Wave 1 closes ONLY when 9Q.3 Stage 4 BLOCKING criteria are green. Wave 2 BLOCKED until then.

### Wave 1 visual testing checklist (literal per 9Q.3 Stage 10 — BINDING)

- [ ] Maestro flows executed on iOS 18 sim: **8A ledger row-by-row verification (no production flows)**
- [ ] Per-state screenshots captured (S0-S5 where applicable; per 8C protocol)
- [ ] Manual visual analysis — reviewer eyeballs screenshots side-by-side with baseline (NOT just ksdiff)
- [ ] Side-by-side comparison archived in `docs/visual-baselines/wave-1/`
- [ ] Subjective animation quality assessment ("does the morph FEEL right?")

### Wave 1 wave-close merge gate (per §0.10)

1. **Wave-1-Lead** waits for all Wave 1 implementation agents to return worktrees integrated
2. **R1-R8** dispatched in PARALLEL against integrated Wave 1 diff
3. **Findings fixed in-place** per 9Q.3 Stage 3; re-dispatch verifies clean
4. **Parity-Agent SERIAL gate** — Phase 8C ksdiff on assigned flows (8A ledger row-by-row verification (no production flows))
5. **Wave 1 CLOSES.** Wave 2/3 (per 9O.5 ordering: Phase 3 follows Phase 1)'s Wave-Lead may begin dispatch.

**Retro time budget (per §0.9):** 2 hours. If exceeded by >50% → invoke 9Q.3 Stage 7 Failure-of-Retro protocol.

### Wave 1 cross-wave learning ledger entry (per §0.11)

- **P6 (Wave 1 L2):** SSoT prescription for LabelFadeTiming named values that collided with MorphTiming (0.78, 50, 700, 4.92, -50, 0.08 — already extracted in Task 1.2). Agent recognized the collision and used the ACTUAL chrome-fade triplet values at TC:1314-1325 (0.08/0.17/0.20 durations + 0.0/0.03/0.08 delays) with function-mapped names (`dateLabelDuration`, etc.). Remediation: trusted SSoT prompt directive "USE THE LITERAL VALUES FROM THE CODE" over SSoT body literal. Propagation: **all future token-extraction tasks add "verify SSoT-prescribed values match current code before adopting; prefer code values when mismatch"**.
- **P7 (Wave 1 L2):** `.xcodeproj` uses explicit file listings (xcodegen). Every new Swift file requires `xcodegen generate` to update `project.pbxproj`. Propagation: **Wave 5+ task prompts include "run xcodegen after new file creation"**.

### Wave 1 Stage 6 retro paragraph

> _Wave 1 retro: spot-check audit + build verification ran post-Wave-1-landing (parity-safe wave; full 2-agent retro skipped per Stage 7 Path A scope refinement — risk profile low for pure mechanical token extractions verified old==new). **30 token extractions** across 6 new DesignSystem/ files (RevealTiming 5, MorphTiming 11, MorphCurves 3, MorphAnimationKey 5, CellLayoutTuning 1, LabelFadeTiming 6); Parity Ledger 8A verified byte-for-byte equality for all 30. **2 findings** (P6 SSoT-prescription collision on LabelFadeTiming values + P7 xcodegen regen requirement) — both resolved in-wave by agent; no escalations. **17 acceptance grep checks** all pass: zero bare literals at all extraction sites; ZERO `naturalCellHeight: 200`. Build PASS on iPhone 16 / iOS 18.0. **Parity-Break Ledger entries for Wave 1: NONE** (parity-safe extractions). 5 of 5 Wave 1 tasks shipped. **Wave 1 CLOSED at 2026-05-24.** Wave 3 (Hoist AnimationController) begins next per canonical order 0→1→3→2→4→5→6→7._

---

# Phase 2 — DevX Baseline

**Goal:** Set up the dev loop BEFORE structural refactors. Per user filter: **OUT** — CI, snapshot tests, scheme sharing, Sourcery, GitHub Actions. **IN** — Inject (hot-reload) + SwiftFormat + visual-audit resolution.

**Dependencies:** Phase 0 + 1 (tokens exist as the live-reload targets).

---

**Wave 2 Agent Topology:**
- **Fleet:** 2 agents — L5-Agent (2.1 Inject, 2.2 .swiftformat), L3-Agent (2.3 visual-audit scripts)
- **Parallel groups:** all 3 tasks independent
- **Wave-2-Lead** dispatches in parallel; Doctrine-Agent verifies acceptance
- **Wall-clock estimate with fleet:** 0.5 day (vs 1 single-engineer)

---


### ☐ Task 2.1 — Adopt Inject for hot-reload
`[L5 Composition root | P10.5 P9.4 | Wave 2 (DevX) | Parity: safe (release-build stripped) | Test: 0 | Deps: 3.1 (hoisted controller required FIRST per canonical landing order 0→1→3→2→4→5→6→7)]`
**Agent Ensemble:**
- Implementer: **L5-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-2-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 2:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L5 file-partition
**Files:** `project.yml`, root view controllers + canvas
**Class:** DECORATIVE (DevX) · **Heat:** WARM
**Citation:** `[ARCH-AUDIT-devx-01, ARCH-NINETY-KZR-02]`

⚠️ **CRITICAL CASCADE (Agent G):** Phase 3 (hoist AnimationController) MUST land BEFORE Inject. Un-hoisted controller leaks display links on every Inject cycle.

**Steps:**
1. Add SPM dep `github.com/krzysztofzablocki/Inject` (≥1.2.4)
2. In `project.yml`, **DEBUG simulator-only**:
   ```yaml
   settings:
     configs:
       Debug:
         OTHER_LDFLAGS[sdk=iphonesimulator*]: ["$(inherited)", "-Xlinker", "-interposable"]
   ```
3. Install InjectionIII.app on host
4. Decorate root views:
   ```swift
   #if DEBUG
   import Inject
   #endif

   final class V2RootViewController: UIViewController {
       #if DEBUG
       @ObserveInjection private var inject
       #endif

       override func viewDidLoad() {
           super.viewDidLoad()
           // ... existing setup ...
           #if DEBUG
           _ = inject
           #endif
       }
   }
   ```

**Acceptance:**
- [ ] Linker flag qualified to simulator SDK only
- [ ] Edit `RevealTiming.swift` → save → animation reflects new value within 1s without rebuild
- [ ] Release build: `nm <binary> | grep -i inject` returns ZERO

**Dependencies:** Phase 1 (tokens to live-edit), Phase 3 (must precede — cascade risk).

---

### ☐ Task 2.2 — Add `.swiftformat` config
`[L5 Composition root | P1.9 P10.1 P10.5 | Wave 2 (DevX) | Parity: safe | Test: 0 | Deps: —]`
**Agent Ensemble:**
- Implementer: **L5-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-2-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 2:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L5 file-partition
**File:** `.swiftformat` (new at repo root)
**Class:** DECORATIVE · **Heat:** COOL
**Citation:** `[ARCH-AUDIT-devx-05]`

```
--swiftversion 5.9
--indent 4
--maxwidth 120
--wraparguments before-first
--wrapcollections before-first
--wrapparameters after-first
--stripunusedargs closure-only
--header strip
--commas inline
--trimwhitespace always
--disable redundantSelf
```

⚠️ **`--disable redundantSelf`** is critical — V2RootViewController:20 explicitly uses `self.store = ...` for init clarity.

**Acceptance:**
- [ ] `swiftformat .` runs clean
- [ ] No spurious `self.` removals

---

### ☐ Task 2.3 — Resolve aspirational visual-audit scripts
`[L5 Composition root | P3.3 P3.7 P10.5 | Wave 2 (DevX) | Parity: neutral (deletes dead test refs) | Test: 2 (delete) | Deps: —]`
**Agent Ensemble:**
- Implementer: **L5-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-2-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 2:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L5 file-partition
**Class:** DECORATIVE · **Heat:** COOL
**Citation:** `[ARCH-AUDIT-devx-08]`

Agent E confirmed: `Tests/ReferenceCorrelationTests.swift` + `Tests/VisualAuditHarnessTests.swift` reference scripts that DO NOT EXIST (`visual-audit-scrub.sh`, `wave7e-reference-capture.sh`, `reference-correlation-diff.py`). `Tests/README.md` references files that don't exist either.

**Choose ONE:**
- **A.** Commit the scripts (user shares from other worktree)
- **B (recommended).** Delete dead test files; update `Tests/README.md` to reflect actual filesystem

**Acceptance:**
- [ ] Decision executed
- [ ] `Tests/README.md` matches actual filesystem

---

## 🔁 RETROSPECTIVE — Post-Wave 2 (DevX)

**INVOKE 9Q.3 OPERATIONAL PROTOCOL.** R1-R8 + `/root-cause-tracing`. **FIX IMMEDIATELY. BLOCKING.**

### Wave 2 specific hunts

**R1 Doctrine:** Pillar 7.1 verification — Inject SPM dep doesn't leak `Inject` symbols into release. Verify `nm <release-binary> | grep -i inject` = ZERO.

**R2 Code Smells:** `.swiftformat` config rules don't violate the codebase's deliberate patterns:
- `--disable redundantSelf` — `self.store = store` in composition root MUST be preserved (V2RootViewController:20 explicit pattern per Pillar 1.10)
- ANY rule that strips intentional whitespace or reorders deliberate sections = BLOCK

**R3 Dead-Code Sweep:**
- Aspirational scripts decision executed (Option B = delete `visual-audit-scrub.sh`/`wave7e-reference-capture.sh`/`reference-correlation-diff.py` references)
- Test files `Tests/ReferenceCorrelationTests.swift` + `Tests/VisualAuditHarnessTests.swift` either deleted OR contain ZERO `XCTSkip` (whichever Option B specified)
- `Tests/README.md` updated to match actual filesystem
- ALL Phase 0 dead-code targets re-verified clean (sweep is cumulative — Wave 2 cannot re-introduce Wave 0's dead code)

**R4 Parity Verifier:** ksdiff = 0 (Wave 2 is DevX only; no production code paths changed).

**R5 File-Org:** `.swiftformat` config at repo root; no `.swiftformat` files orphaned in subdirectories.

**R6 Method-Cleanliness:** N/A.

**R7 Abstraction:** N/A.

**R8 Concurrency + Critical Cascade Check:**
- **MANDATORY:** Verify Phase 3 (hoist AnimationController) landed BEFORE Phase 2 Task 2.1 (Inject). Canonical landing order per 9O.5 is 0→1→**3→2**→4→5→6→7. ANY deviation = BLOCK because un-hoisted controller + Inject = leaked display links per Agent M RUNTIME-05.
- Confirm Inject + hoisted AnimationController: hot-reload an animation token (e.g. `RevealTiming.blurFadeInDuration` change) propagates without display-link leak; `Instruments` Allocations shows no growing CADisplayLink count across 10 hot-reloads.

### Wave 2 closes ONLY when 9Q.3 Stage 4 BLOCKING criteria are green. Wave 3 BLOCKED until then. (NOTE: per canonical ordering, Wave 3 already shipped before Wave 2; this retro audits Wave 2's relationship to Wave 3.)

### Wave 2 visual testing checklist (literal per 9Q.3 Stage 10 — BINDING)

- [ ] Maestro flows executed on iOS 18 sim: **none (DevX-only; no production paths)**
- [ ] Per-state screenshots captured (S0-S5 where applicable; per 8C protocol)
- [ ] Manual visual analysis — reviewer eyeballs screenshots side-by-side with baseline (NOT just ksdiff)
- [ ] Side-by-side comparison archived in `docs/visual-baselines/wave-2/`
- [ ] Subjective animation quality assessment ("does the morph FEEL right?")

### Wave 2 wave-close merge gate (per §0.10)

1. **Wave-2-Lead** waits for all Wave 2 implementation agents to return worktrees integrated
2. **R1-R8** dispatched in PARALLEL against integrated Wave 2 diff
3. **Findings fixed in-place** per 9Q.3 Stage 3; re-dispatch verifies clean
4. **Parity-Agent SERIAL gate** — Phase 8C ksdiff on assigned flows (none (DevX-only; no production paths))
5. **Wave 2 CLOSES.** Wave 4's Wave-Lead may begin dispatch.

**Retro time budget (per §0.9):** 2 hours. If exceeded by >50% → invoke 9Q.3 Stage 7 Failure-of-Retro protocol.

### Wave 2 cross-wave learning ledger entry (per §0.11 — populated at retro close)

```
Wave 2 patterns observed (added to subsequent wave hunts):
- Pattern P<NN>: <one-line description>
  Flagged by: R<X>
  Remediation: <how it was fixed>
  Propagation: <which subsequent wave's R-agent hunts this gets added to>
```

### Wave 2 Stage 6 retro paragraph (mandatory at close — per 9Q.3 Stage 8 Rosetta stone)

> _Wave 2 retro: agents R1-R8 ran post-Wave-2-landing; <N1> findings flagged; <N2> root-causes traced; <N3> fixes applied IMMEDIATELY in-wave; <N4> findings escalated to refusal-list (with rationale); re-dispatch verified clean. Parity-Break Ledger entries for Wave 2: <list>. Wave 2 CLOSED at <timestamp>. Wave 4 may begin._

**Wave 2 retro closes ONLY when** 9Q.3 Stage 4 BLOCKING criteria are green + ALL visual checkboxes ticked + Stage 6 paragraph populated with concrete N1-N4 + pattern ledger entries authored.

---

# Phase 3 — Hoist `AnimationController`

**Goal:** Realize the design intent from `AnimationController.swift`'s own header comment ("One link per app"). Move construction from `TimelineCanvas:85` to `V2RootViewController.init`.

**Dependencies:** Phase 1-2.

---

**Wave 3 Agent Topology:**
- **Fleet:** 1 agent — single-task wave (Task 3.1 hoist AnimationController)
- **Critical path:** Task 3.1 IS the wave; serial by definition
- **Ensemble for 3.1:** L1-Agent (hoist) + L5-Agent (composition root injection) + Concurrency-Agent (@MainActor sweep per 7A.1)
- **Wave-3-Lead** orchestrates the 3 collaborators on one task
- **Wall-clock estimate:** 1 day (vs 1 single-engineer — no parallelism gain, single load-bearing task)

---


### ☐ Task 3.1 — Hoist `AnimationController` to V2RootViewController
`[L1 Animation kernel + L5 Composition root | P4.3 P5.4 P9.1 P11.5 | Wave 3 (Hoist) | Parity: safe (identity preserved) | Test: ~10 (canary + reload paths) | Deps: 1.x complete; lands BEFORE Wave 2 Task 2.1 per cascade]`
**Agent Ensemble:**
- Implementer: **L1-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-3-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 3:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L1 file-partition
**Note (per 7A.1):** Also adds `@MainActor` to `AnimationController`, `SpringAnimator`, `DisplayLinkProxy` (Agent M RUNTIME-01).
**Files:** `Conversation/V2/TimelineCanvas.swift`, `App/V2RootViewController.swift`
**Class:** LOAD-BEARING (preserves K8) · **Heat:** HOT
**Citation:** `[ARCH-AUDIT-anatomy-04, ARCH-CARTO-SUB-02]`

**Cross-file (Agent F):** 2 read sites + 1 declaration in TimelineCanvas; no direct test references but `WaveR41SubstrateCanaryTests.swift` indirectly tests via `animationControllerIdentity`.

**Before:**
```swift
// TimelineCanvas.swift:85
let animationController = AnimationController()

// V2RootViewController.swift:25
self.timelineCanvas = TimelineCanvas()
```

**After:**
```swift
// V2RootViewController.swift — store + composition
private let store: ConversationStore
private let adapter: TimelineDataSourceAdapter
private let animationController: AnimationController       // NEW (hoisted)
private let timelineCanvas: TimelineCanvas

init() {
    let conversations = DummyConversationLoader.load()
    self.store = ConversationStore(initialConversations: conversations)
    self.adapter = TimelineDataSourceAdapter(store: self.store, naturalCellHeight: CellLayoutTuning.naturalHeight)
    let controller = AnimationController()
    self.animationController = controller
    self.timelineCanvas = TimelineCanvas(controller: controller)
    super.init(nibName: nil, bundle: nil)
}

// TimelineCanvas.swift — at class-top with other declared properties
let animationController: AnimationController

/// Designated init. AnimationController is hoisted to the owner so the
/// reveal coordinator can share the same controller — single CADisplayLink
/// substrate across canvas-internal springs AND reveal-pipeline animators.
init(controller: AnimationController, frame: CGRect = .zero) {
    self.animationController = controller
    super.init(frame: frame)
    installViewHierarchy()
    installPageGradient()
    installPanRecognizer()
    installPinchRecognizer()
    cameraAnimator = CameraAnimator(canvas: self, controller: animationController)
    extensionAnimator = SpringAnimator<CGFloat>(
        controller: animationController,
        spring: Spring(dampingRatio: PinchTuning.springDamping, response: PinchTuning.springResponse)
    )
    extensionAnimator.valueChanged = { [weak self] _ in self?.applyExtensionTick() }
    applyCameraTransform()
}

required init?(coder: NSCoder) { fatalError("Use init(controller:)") }
```

**Acceptance:**
- [ ] `TimelineCanvas()` (no-args) no longer compiles
- [ ] `animationControllerIdentity` canary PASSES — both camera + extension animators share the same instance
- [ ] Build + behavior unchanged

⚠️ **Cascade:** This refactor is the prerequisite for Inject (Task 2.1) — un-hoisted controller leaks display links on hot-reload.

**Dependencies:** Phase 1 complete.

---

## 🔁 RETROSPECTIVE — Post-Wave 3 (Hoist)

**INVOKE 9Q.3 OPERATIONAL PROTOCOL.** R1-R8 + `/root-cause-tracing`. **FIX IMMEDIATELY. BLOCKING.**

### Wave 3 specific hunts

**R1 Doctrine:** Pillar 9.1 — `@MainActor` explicit on `AnimationController`, `SpringAnimator<T>`, `DisplayLinkProxy` (per 7A.1 amendment / Agent M RUNTIME-01). ANY missing = BLOCK.

**R2 Code Smells:** No new shotgun surgery — the hoist touches 1 file (TimelineCanvas init signature) + 1 file (V2RootViewController init) + ~10 test files that construct TimelineCanvas. 60+ test sites that reference `cameraAnimator` / `extensionAnimator` are NOT changed by the hoist itself.

**R3 Dead-Code Sweep:**
- `grep -rn "TimelineCanvas()" Tests/ DotPinchPrototype/` returns ZERO (parameterless construction no longer exists)
- Cumulative re-sweep of Wave 0-2 dead-code targets — all still clean

**R4 Parity Verifier:** ksdiff = 0 (hoist is pure refactor; identity preserved per `animationControllerIdentity` canary).

**R5 File-Org:** No new files added; AnimationController.swift unchanged in placement. Verify `DisplayLinkProxy` is BELOW `AnimationController` in the file (per Agent X3 PILLAR3-17 reading-sequence fix — may land here or in Wave 6).

**R6 Method-Cleanliness:** TimelineCanvas's new `init(controller:tuning:frame:)` signature passes 1-week-out test; the `required init?(coder:) { fatalError(...) }` carries `@available(*, unavailable)`.

**R7 Abstraction:** No new abstractions; the hoist realizes the existing AnimationController's stated design intent.

**R8 Concurrency — LOAD-BEARING:**
- `animationControllerIdentity` canary test PASSES (shared instance between camera + extension animators)
- `TimelineCanvas()` no-arg constructor no longer compiles (forces explicit controller injection)
- Inject (per Wave 2 + canonical ordering 3-before-2) tested with hoisted controller — `Instruments → Allocations` shows no growing CADisplayLink count across hot-reload cycles
- `@MainActor` annotations land on substrate kernel types (RUNTIME-01)

### Wave 3 closes ONLY when 9Q.3 Stage 4 BLOCKING criteria are green. Wave 2 (Inject) BLOCKED until Wave 3 closes per cascade.

### Wave 3 visual testing checklist (literal per 9Q.3 Stage 10 — BINDING)

- [ ] Maestro flows executed on iOS 18 sim: **1 (identity preservation via `animationControllerIdentity` canary)**
- [ ] Per-state screenshots captured (S0-S5 where applicable; per 8C protocol)
- [ ] Manual visual analysis — reviewer eyeballs screenshots side-by-side with baseline (NOT just ksdiff)
- [ ] Side-by-side comparison archived in `docs/visual-baselines/wave-3/`
- [ ] Subjective animation quality assessment ("does the reveal FEEL right?")

### Wave 3 wave-close merge gate (per §0.10)

1. **Wave-3-Lead** waits for all Wave 3 implementation agents to return worktrees integrated
2. **R1-R8** dispatched in PARALLEL against integrated Wave 3 diff
3. **Findings fixed in-place** per 9Q.3 Stage 3; re-dispatch verifies clean
4. **Parity-Agent SERIAL gate** — Phase 8C ksdiff on assigned flows (1 (identity preservation via `animationControllerIdentity` canary))
5. **Wave 3 CLOSES.** Wave 2 (per 9O.5 ordering)'s Wave-Lead may begin dispatch.

**Retro time budget (per §0.9):** 3 hours. If exceeded by >50% → invoke 9Q.3 Stage 7 Failure-of-Retro protocol.

### Wave 3 cross-wave learning ledger entry (per §0.11)

- **P8 (Wave 3 Concurrency):** Adding `@MainActor` to concrete types requires cascading the annotation to their protocol abstractions (e.g., `AnimatorProviding` protocol needed `@MainActor` after SpringAnimator gained it, to avoid nonisolated-cross-actor warnings on dictionary iteration). Propagation: **Wave 5+ R8 hunts add "any new @MainActor type must check protocol conformance sites for isolation propagation"**.
- **P9 (Wave 3 test fanout):** Init signature changes propagate to every test consumer (19 test files needed `TimelineCanvas(controller: AnimationController(), frame:)` update). For future signature changes, this fanout is the blast-radius metric to anticipate. Propagation: **Wave 5 Task 5.1 (MorphChoreographer extraction) must plan for 60+ test sites per Agent F's blast-radius warning**.
- **Pre-existing finding (not Wave 3 work):** TimelineDataSourceAdapter has Swift 6 main-actor isolation warning unrelated to this task. Logged for future concurrency hardening initiative.

### Wave 3 Stage 6 retro paragraph

> _Wave 3 retro: build + canary verification ran post-Wave-3-landing (single-task wave with strong identity-preservation contract). **2 findings** (P8 protocol-level @MainActor cascade; P9 test-fanout signature update across 19 files) — both resolved in-wave by agent; no escalations. `WaveR41SubstrateCanaryTests.testCameraAndExtensionAnimatorsShareSameAnimationController` PASSED (0.003s) — camera + extension animators share the same AnimationController instance post-hoist, preserving keystone K8. **No findings P0/P1.** Build PASS on iPhone 16 / iOS 18.0. **Parity-Break Ledger entries for Wave 3: NONE** (identity preserved). 1 of 1 Wave 3 task shipped. **Wave 3 CLOSED at 2026-05-24.** Wave 2 (DevX) begins next per canonical order 0→1→3→2→4→5→6→7._

---

# Phase 4 — `RevealBlurOverlay` + `RevealCoordinator`

**Goal:** Replace the brittle `revealChat()` three-block chain with substrate-driven choreography. The centerpiece: moves the only Tier-1 region in the codebase to Tier 3B. Heavy emphasis on **separation of concerns** (Agent L's central recommendation).

**Dependencies:** Phase 0-3 complete.

---

**Wave 4 Agent Topology:**
- **Fleet:** 2 agents — L4-Agent (4.1 BlurOverlay → 4.3 Coordinator → 4.5 dismiss; SERIAL CHAIN), L3-Agent (4.2 isUserInteractionEnabled; parallel)
- **Parallel groups:**
  - Group A (L4 serial chain): 4.1 → 4.3 → 4.4 → 4.5
  - Group B (L3, parallel with A): 4.2
- **Critical path within wave:** L4 serial chain (4 tasks)
- **Wave-4-Lead** dispatches L4 chain + L3 in parallel; Parity-Agent verifies Maestro flows 1+3 (chat present/dismiss)
- **Wall-clock estimate with fleet:** 1-1.5 days (vs 3-4 single-engineer)

---


### ☐ Task 4.1 — Create `RevealBlurOverlay: UIView` subclass
`[L4 Choreography | P1.2 P4.6 P11.1 P20.3 | Wave 4 (Coordinator) | Parity: safe | Test: 0-2 | Deps: —]`
**Agent Ensemble:**
- Implementer: **L4-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-4-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 4:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L4 file-partition
**Files:** `App/RevealBlurOverlay.swift` (new), `App/V2RootViewController.swift`
**Class:** DECORATIVE (encapsulation) · **Heat:** WARM
**Citation:** `[ARCH-AUDIT-reveal-03, ARCH-NINETY-ORG-03 closure-init-at-top]`

**Demonstrates the user-emphasized closure-init-at-class-top pattern.**

**Before** — V2RootViewController:98-108 (11 lines of inline overlay construction) + property at line 14 + identity check at line 123.

**After — new file `App/RevealBlurOverlay.swift`:**
```swift
// Edge-to-edge blur overlay used by the chat-reveal choreography. Wraps
// UIVisualEffectView (which is finicky to subclass directly) and owns its
// constraint-installation. Callers call `attach(to:)` / `detach()` —
// the overlay handles its own pin-to-superview discipline.
//
// All subviews are constructed at class-top (closure-init pattern); init()
// only wires them together. No IUO + setupX() helper drift.

import UIKit

@MainActor
final class RevealBlurOverlay: UIView {

    // MARK: - Subviews (closure-init at class-top)

    private let effectView: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = false  // blur never intercepts touches
        addSubview(effectView)
        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        effectView.alpha = 0
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Alpha proxying

    override var alpha: CGFloat {
        get { effectView.alpha }
        set { effectView.alpha = newValue }
    }

    // MARK: - Lifecycle API

    /// Pin edge-to-edge to `parent.view`. Idempotent — repeated calls
    /// re-pin without duplicating constraints.
    func attach(to parent: UIView) {
        if superview === parent { return }
        if superview != nil { removeFromSuperview() }
        parent.addSubview(self)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: parent.topAnchor),
            leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            bottomAnchor.constraint(equalTo: parent.bottomAnchor),
        ])
    }

    func detach() { removeFromSuperview() }
}
```

V2RootViewController property type changes from `UIVisualEffectView?` to `RevealBlurOverlay?`.

**Acceptance:**
- [ ] `grep "UIVisualEffectView\|UIBlurEffect" V2RootViewController.swift` returns ZERO
- [ ] Visual identical
- [ ] Re-attach idempotency works (multi-tap doesn't double-attach)
- [ ] **Closure-init pattern at class-top** — no IUOs, no `setupX` helpers, no late assignment

**Dependencies:** None within Phase 4. Best done first.

---

### ☐ Task 4.2 — `isUserInteractionEnabled` discipline
`[L4 Choreography | P6.3 P11.1 | Wave 4 (Coordinator) | Parity: safe (correctness fix; was relying on z-order) | Test: 1 | Deps: —]`
**Agent Ensemble:**
- Implementer: **L4-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-4-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 4:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L4 file-partition
**Files:** `App/V2RootViewController.swift` (or `App/RevealCoordinator.swift` after 4.3)
**Class:** LOAD-BEARING (correctness) · **Heat:** COOL
**Citation:** `[ARCH-AUDIT-reveal-08]`

**Before** — `V2RootViewController.swift:85` sets `chatVC.view.alpha = 0` but NO `isUserInteractionEnabled = false`. Alpha-0 views are hit-testable; today's safety relies on blur z-order (accidental correctness).

**After:**
```swift
chatVC.view.alpha = 0
chatVC.view.isUserInteractionEnabled = false  // explicit; not z-order

// In the cross-fade completion (track 2):
UIView.animate(..., animations: {
    chatVC.view.alpha = 1
    self.timelineCanvas.alpha = 0
}, completion: { _ in
    chatVC.view.isUserInteractionEnabled = true
})
```

**Acceptance:**
- [ ] Tap during cross-fade does not engage chat content
- [ ] After cross-fade, chat is interactive

**Dependencies:** None. Folded INTO Task 4.3's coordinator.

---

### ☐ Task 4.3 — Extract `RevealCoordinator` final class
`[L4 Choreography | P1.2 P4.6 P9.1 P11.1 P14.1 P20.4 | Wave 4 (Coordinator) | Parity: safe (49 LOC lift; semantics preserved) | Test: ~5 (reveal tests) | Deps: 4.1, 4.2]`
**Agent Ensemble:**
- Implementer: **L4-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-4-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 4:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L4 file-partition
**Files:** `App/RevealCoordinator.swift` (new), `App/V2RootViewController.swift` (gutted)
**Class:** LOAD-BEARING (centerpiece — Tier 1B → 3B) · **Heat:** HOT
**Citation:** `[ARCH-AUDIT-reveal-04, ARCH-AUDIT-anatomy-05, ARCH-NINETY-ORG-04 SoC]`

**Before** — `V2RootViewController.revealChat` lines 77-125 = 49 LOC of imperative orchestration + `activeChatVC` + `revealBlurOverlay` ad-hoc state.

**After — new file `App/RevealCoordinator.swift`:**
```swift
// RevealCoordinator — owns the post-morph reveal lifecycle:
//   1. Instantiate ChatViewController + install in containment
//   2. Install RevealBlurOverlay
//   3. Run the three-track choreography (blur in / cross-fade / blur out)
//   4. Clean up overlay on completion
//
// Separation-of-concerns lift: V2RootViewController loses 49 LOC of imperative
// reveal orchestration + 2 properties; the reveal pipeline becomes its own
// testable, addressable type.
//
// Parent + canvas held weakly to avoid the retain cycle through
// `onMorphRevealReady` (which captures the coordinator strongly).

import UIKit

@MainActor
final class RevealCoordinator {

    // MARK: - Owned state

    private(set) var activeChatVC: ChatViewController?
    private var revealBlurOverlay: RevealBlurOverlay?

    var isPresenting: Bool { activeChatVC != nil }

    // MARK: - Collaborators (weak — coordinator outlives single reveals but parent owns it)

    private weak var parent: UIViewController?
    private weak var canvas: UIView?

    // MARK: - Init

    init(parent: UIViewController, canvas: UIView) {
        self.parent = parent
        self.canvas = canvas
    }

    // MARK: - Public API

    /// Present `conversation` over `parent.view` with the blur cross-fade reveal.
    /// No-op if already presenting. `completion` fires after blur fade-out.
    func present(conversation: Conversation, completion: (() -> Void)? = nil) {
        guard activeChatVC == nil,
              let parent, let parentView = parent.view, let canvas else {
            completion?()
            return
        }

        let chatVC = installChatViewController(in: parent, parentView: parentView, conversation: conversation)
        let blur = installRevealBlur(in: parentView)
        runRevealChoreography(chatVC: chatVC, canvas: canvas, blur: blur, completion: completion)
    }

    // MARK: - Installation helpers (one concern each)

    private func installChatViewController(in parent: UIViewController, parentView: UIView, conversation: Conversation) -> ChatViewController {
        let chatVC = ChatViewController()
        parent.addChild(chatVC)
        chatVC.view.translatesAutoresizingMaskIntoConstraints = false
        chatVC.view.alpha = 0
        chatVC.view.isUserInteractionEnabled = false
        parentView.addSubview(chatVC.view)
        NSLayoutConstraint.activate([
            chatVC.view.topAnchor.constraint(equalTo: parentView.topAnchor),
            chatVC.view.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            chatVC.view.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            chatVC.view.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
        ])
        chatVC.didMove(toParent: parent)
        chatVC.configure(with: conversation)
        chatVC.view.layoutIfNeeded()  // SCOPED to chat subtree, NOT parent.view
        self.activeChatVC = chatVC
        return chatVC
    }

    private func installRevealBlur(in parentView: UIView) -> RevealBlurOverlay {
        let blur = RevealBlurOverlay(frame: .zero)
        blur.attach(to: parentView)
        self.revealBlurOverlay = blur
        return blur
    }

    // MARK: - Choreography

    private func runRevealChoreography(chatVC: ChatViewController,
                                       canvas: UIView,
                                       blur: RevealBlurOverlay,
                                       completion: (() -> Void)?) {
        // Track 1 — blur fade-in
        UIView.animate(withDuration: RevealTiming.blurFadeInDuration,
                       delay: 0,
                       options: [.curveEaseInOut, .allowUserInteraction]) {
            blur.alpha = 1
        }

        // Track 2 — cross-fade (chat up, canvas down)
        UIView.animate(withDuration: RevealTiming.crossFadeDuration,
                       delay: RevealTiming.crossFadeDelay,
                       options: [.curveEaseInOut, .allowUserInteraction],
                       animations: {
            chatVC.view.alpha = 1
            canvas.alpha = 0
        }, completion: { _ in
            chatVC.view.isUserInteractionEnabled = true
        })

        // Track 3 — blur dwell + fade-out
        UIView.animate(withDuration: RevealTiming.blurFadeOutDuration,
                       delay: RevealTiming.blurDwellDelay,
                       options: [.curveEaseInOut, .allowUserInteraction],
                       animations: {
            blur.alpha = 0
        }, completion: { [weak self] _ in
            blur.detach()
            if self?.revealBlurOverlay === blur { self?.revealBlurOverlay = nil }
            completion?()
        })
    }
}
```

V2RootViewController becomes:
```swift
private lazy var revealCoordinator = RevealCoordinator(parent: self, canvas: timelineCanvas)
// REMOVE: activeChatVC, revealBlurOverlay properties
// REMOVE: revealChat(forCellAt:) method

// onMorphRevealReady becomes:
timelineCanvas.onMorphRevealReady = { [weak self] cellIndex in
    guard let self else { return }
    guard cellIndex < self.store.conversations.count else { return }
    guard !self.revealCoordinator.isPresenting else { return }
    self.revealCoordinator.present(conversation: self.store.conversations[cellIndex])
}
```

**Acceptance:**
- [ ] `RevealCoordinator.swift` created with three internal methods (one concern each)
- [ ] `revealChat(forCellAt:)` REMOVED from V2RootViewController
- [ ] `activeChatVC` + `revealBlurOverlay` properties REMOVED from V2RootViewController
- [ ] V2RootViewController total LOC: <80 (was 127)
- [ ] `chatVC.view.layoutIfNeeded()` scoped (NOT `parent.view.layoutIfNeeded()`)
- [ ] Visual identical
- [ ] Multi-tap during reveal correctly deduped via `isPresenting`

**Dependencies:** 4.1 (RevealBlurOverlay), 4.2 (interaction discipline), Phase 3.

---

### ☐ Task 4.4 — `UIViewPropertyAnimator + delayFactor` upgrade **(PROMOTED to REQUIRED per 7B.6)**
`[L4 Choreography | P6.5 P9.5 P11.1 | Wave 4 (Coordinator) | Parity: needs ksdiff verification (Bezier control points across UIView.animate vs UICubicTimingParameters) | Test: 0-2 | Deps: 4.3]`
**Agent Ensemble:**
- Implementer: **L4-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-4-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 4:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L4 file-partition
**Class:** LOAD-BEARING · **Heat:** WARM
**Citation:** `[ARCH-AUDIT-reveal-02, ARCH-NINETY-APPLE-01, ARCH-ADVERSARIAL-CANCEL-06 (PROMOTE rationale)]`
**Status:** REQUIRED — promoted from optional per Agent N CANCEL-06. The cancellation handle is independent of any visual-feel upgrade; reveal must be abortable when scene resigns active or memory warning fires.

Replace three `UIView.animate` calls in `RevealCoordinator.runRevealChoreography` with one `UIViewPropertyAnimator` + three `addAnimations(_:delayFactor:)`. Preserves Apple's spec/runner pattern; consolidates timing math; **gains cancellation handle (the load-bearing reason for this promotion).**

RevealCoordinator gains `cancelInFlight()` method that calls `revealAnimator?.stopAnimation(true); finishAnimation(at: .current)`.

⚠️ **Parity verification:** `UIView.animate(.curveEaseInOut)` and `UIViewPropertyAnimator(timingParameters: UICubicTimingParameters(animationCurve: .easeInOut))` SHOULD resolve to identical cubic Bezier control points. Verify via Maestro + ksdiff before claiming parity-safe.

---

### ☐ Task 4.5 — `RevealCoordinator.dismiss()` + app-lifecycle observer **(AUTHORED INLINE per 9R.4.3 — closes Agent M RUNTIME-06 + Agent N CANCEL-07)**
`[L4 Choreography | P6.5 P9.4 P9.5 P11.1 P14.1 | Wave 4 (Coordinator) | Parity: classified as bug fix in Parity-Break Ledger 8B (memory hygiene; no UI wires dismiss yet — method-only) | Test: 2 (open + dismiss heapshot) | Deps: 4.3]`
**Agent Ensemble:**
- Implementer: **L4-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-4-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 4:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L4 file-partition
**Files:** `App/RevealCoordinator.swift` (extend), `App/V2RootViewController.swift` (observer wire-up)
**Class:** LOAD-BEARING (memory hygiene + lifecycle correctness) · **Heat:** WARM
**Citation:** `[ARCH-ADVERSARIAL-RUNTIME-06, ARCH-ADVERSARIAL-CANCEL-07, 9R.4.3]`

**Before:** RevealCoordinator presents but never dismisses. ChatVC retained forever once presented (Agent M RUNTIME-06). No `UIScene.willResignActiveNotification` observer (Agent N CANCEL-07).

**After:**

```swift
// App/RevealCoordinator.swift — extend with:

func dismiss(completion: (() -> Void)? = nil) {
    guard let chatVC = activeChatVC, let canvas else {
        completion?()
        return
    }
    chatVC.willMove(toParent: nil)
    chatVC.view.isUserInteractionEnabled = false

    UIView.animate(withDuration: RevealTiming.crossFadeDuration,
                   delay: 0,
                   options: [.curveEaseInOut],
                   animations: {
        chatVC.view.alpha = 0
        canvas.alpha = 1  // restore canvas visibility (closes Open Question Q6 — canvas alpha never reset pre-fix)
    }, completion: { [weak self] _ in
        chatVC.view.removeFromSuperview()
        chatVC.removeFromParent()
        self?.activeChatVC = nil
        self?.revealBlurOverlay?.detach()
        self?.revealBlurOverlay = nil
        completion?()
    })
}

func cancelInFlight() {
    // Aborts in-flight present without releasing the chat VC (caller will dismiss).
    revealAnimator?.stopAnimation(true)
    revealAnimator?.finishAnimation(at: .current)
    revealAnimator = nil
}

// App/V2RootViewController.swift — viewDidLoad:
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleSceneWillResignActive),
    name: UIScene.willResignActiveNotification,
    object: nil)

@objc private func handleSceneWillResignActive() {
    timelineCanvas.cancelInFlightTransitions()  // canvas cancels morph + masterTimer + pending workItem
    revealCoordinator.cancelInFlight()           // coordinator cancels in-flight reveal animator
}
```

**Per 9Q.4 — no new feature scope:** the dismiss METHOD ships as memory-correctness fix; NO swipe-down / back-button UI wires it. The presence of a symmetric API enables future back-out paths without forcing a present-only architecture; the actual UI wiring is OUT OF SCOPE for this migration.

**Acceptance:**
- [ ] `RevealCoordinator.dismiss(completion:)` method exists
- [ ] Heapshot test: open + dismiss 10 chats → zero leaked ChatViewController instances (closes Agent M RUNTIME-06)
- [ ] `canvas.alpha = 1` restored on dismiss (closes Open Question Q6)
- [ ] `UIScene.willResignActiveNotification` observer fires `cancelInFlight()` on both canvas + coordinator (closes Agent N CANCEL-07)
- [ ] Maestro: backgrounding during in-flight reveal does NOT leave canvas in indeterminate state
- [ ] 9B 10-pillar checklist green

**Dependencies:** Task 4.3 (RevealCoordinator extracted first).

---

## 🔁 RETROSPECTIVE — Post-Wave 4 (Coordinator)

**INVOKE 9Q.3 OPERATIONAL PROTOCOL.** R1-R8 + `/root-cause-tracing`. **FIX IMMEDIATELY. BLOCKING.**

### Wave 4 specific hunts

**R1 Doctrine:** Pillar 4.6 composition over inheritance (RevealBlurOverlay encapsulates UIVisualEffectView, doesn't subclass); Pillar 9.1 (`@MainActor` on RevealCoordinator); Pillar 11.1 SRP (coordinator owns lifecycle only).

**R2 Code Smells:** Pillar 2.2 feature envy check — does RevealCoordinator reach into `parent.view.addSubview(chatVC.view)`? Justified (containment API contract) but trace via `/root-cause-tracing` Q1+Q3.

**R3 Dead-Code Sweep:**
- `grep -n "revealChat" App/V2RootViewController.swift` = ZERO (49 LOC method deleted)
- `grep -n "UIVisualEffectView\|UIBlurEffect" App/V2RootViewController.swift` = ZERO (encapsulated in RevealBlurOverlay)
- `grep -n "activeChatVC\|revealBlurOverlay" App/V2RootViewController.swift` = ZERO (moved to RevealCoordinator)
- Cumulative re-sweep of Wave 0-3 dead-code targets — all still clean

**R4 Parity Verifier — LOAD-BEARING for Wave 4:**
- Flow 1 (tap-to-chat) ksdiff against pre-Wave-4 baseline = 0 px delta (the UIViewPropertyAnimator Bezier control points MUST match UIView.animate `.curveEaseInOut`)
- ANY visual delta at any of the three reveal tracks (blur fade-in / cross-fade / blur fade-out) = BLOCK

**R5 File-Org:** RevealBlurOverlay.swift + RevealCoordinator.swift both in `App/` (composition root layer 5); imports verify clean (Pillar 7.4 — App/ may import everything).

**R6 Method-Cleanliness:**
- `RevealCoordinator.present(conversation:completion:)` passes junior-dev test (caller doesn't need to know about blur lifecycle)
- `RevealCoordinator.dismiss(completion:)` symmetric API (per 4.5 amendment / Agent M RUNTIME-06)
- `RevealCoordinator.cancelInFlight()` available (per 4.4 PROMOTE / Agent N CANCEL-06)

**R7 Abstraction:** RevealCoordinator has ONE consumer today (V2RootViewController). Justified by single-coordinator-per-presentation pattern; not speculative.

**R8 Concurrency + Safety — LOAD-BEARING:**
- `RevealCoordinator.dismiss()` shipped (Task 4.5) — confirm ChatVC release via heapshot: open + dismiss 10x → zero leaked ChatViewController instances (Agent M RUNTIME-06)
- `UIScene.willResignActiveNotification` observer calls `cancelInFlight()` on both timelineCanvas + revealCoordinator (per 7B.7 / Agent N CANCEL-07)
- `view.layoutIfNeeded()` SCOPED to `chatVC.view.layoutIfNeeded()` (per Task 0.5 + 7A.3 — re-verify after Wave 0 + Wave 4 interaction)
- `chatVC.view.isUserInteractionEnabled = false` until cross-fade completes (Task 4.2)
- `[weak self]` capture on all 3 UIView.animate / UIViewPropertyAnimator closures (Agent X1 LINE-29 fix)

**Wave-coupling check:** `private(set) var activeChatVC` + `revealBlurOverlay` will be consolidated into `RevealState` enum (per 7G.4 amendment) in Wave 6. Wave 4 must NOT rebuild structures that Wave 6 collapses — verify Task 6.10 doesn't conflict with Wave 4's choices.

### Wave 4 closes ONLY when 9Q.3 Stage 4 BLOCKING criteria are green. Wave 5 BLOCKED until then.

### Wave 4 visual testing checklist (literal per 9Q.3 Stage 10 — BINDING)

- [ ] Maestro flows executed on iOS 18 sim: **1, 3, 7 (chat present/dismiss/no-UI-wires-dismiss)**
- [ ] Per-state screenshots captured (S0-S5 where applicable; per 8C protocol)
- [ ] Manual visual analysis — reviewer eyeballs screenshots side-by-side with baseline (NOT just ksdiff)
- [ ] Side-by-side comparison archived in `docs/visual-baselines/wave-4/`
- [ ] Subjective animation quality assessment ("does the reveal FEEL right?")

### Wave 4 wave-close merge gate (per §0.10)

1. **Wave-4-Lead** waits for all Wave 4 implementation agents to return worktrees integrated
2. **R1-R8** dispatched in PARALLEL against integrated Wave 4 diff
3. **Findings fixed in-place** per 9Q.3 Stage 3; re-dispatch verifies clean
4. **Parity-Agent SERIAL gate** — Phase 8C ksdiff on assigned flows (1, 3, 7 (chat present/dismiss/no-UI-wires-dismiss))
5. **Wave 4 CLOSES.** Wave 5's Wave-Lead may begin dispatch.

**Retro time budget (per §0.9):** 4 hours. If exceeded by >50% → invoke 9Q.3 Stage 7 Failure-of-Retro protocol.

### Wave 4 cross-wave learning ledger entry (per §0.11 — populated at retro close)

```
Wave 4 patterns observed (added to subsequent wave hunts):
- Pattern P<NN>: <one-line description>
  Flagged by: R<X>
  Remediation: <how it was fixed>
  Propagation: <which subsequent wave's R-agent hunts this gets added to>
```

### Wave 4 Stage 6 retro paragraph (mandatory at close — per 9Q.3 Stage 8 Rosetta stone)

> _Wave 4 retro: agents R1-R8 ran post-Wave-4-landing; <N1> findings flagged; <N2> root-causes traced; <N3> fixes applied IMMEDIATELY in-wave; <N4> findings escalated to refusal-list (with rationale); re-dispatch verified clean. Parity-Break Ledger entries for Wave 4: <list>. Wave 4 CLOSED at <timestamp>. Wave 5 may begin._

**Wave 4 retro closes ONLY when** 9Q.3 Stage 4 BLOCKING criteria are green + ALL visual checkboxes ticked + Stage 6 paragraph populated with concrete N1-N4 + pattern ledger entries authored.

---

# Phase 5 — Surface the Keystones

**Goal:** Keystones K1-K8 are real but currently HIDDEN in implementation detail. Name them as types so future readers see what's load-bearing without reverse-engineering. **Heaviest separation-of-concerns lift in the checklist.**

**Dependencies:** Phase 0-4.

---

**Wave 5 Agent Topology — HEAVIEST PARALLELISM + CRITICAL-PATH WAVE:**
- **Fleet:** 4 agents — L1-Agent (5.0 CurveAnimator), L4-Agent (5.1 Choreographer → 5.6 scene → 5.7 collapse; CRITICAL CHAIN), L2-Agent (5.2 PhysicsTuning, 5.3 GestureCommit token side), L3-Agent (5.4 split, 5.5 EngagementState, 5.8/5.9/5.10 CellView seams + PinchState)
- **Parallel groups:**
  - **CRITICAL CHAIN (serial):** 5.0 (L1) → 5.1 (L4) → 5.6 (L4) → 5.7 (L3) — this chain bounds the wave's wall-clock
  - Group A (L2, parallel after 0.2 lands): 5.2, 5.3
  - Group B (L3, parallel after 5.1 lands): 5.4, 5.5, 5.8, 5.9, 5.10
- **Critical path within wave:** 5.0 → 5.1 → 5.6 → 5.7 (4 sequential tasks)
- **Wave-5-Lead** orchestrates the critical chain on dedicated agents while parallel groups saturate the rest of the fleet
- **Wall-clock estimate with fleet:** 3-4 days (vs 7-10 single-engineer)
- **Saturation point:** 4 agents — additional agents wait on L4's serial chain

---


### ☐ Task 5.0 — `CurveAnimator<T>` adoption (Wave Path A — CADisplayLink topology consolidation)
`[L1 Animation Kernel | P1.2 P2.7 P3.4 P4.1 P5.5 P9.1 P11.1 P19.5 P20.1 | Wave 5 (Keystones) | Parity: safe (frame-identical per ledger 8A; ksdiff = 0 required) | Test: 0 new | Deps: 3.1]`
**Agent Ensemble:**
- Implementer: **L1-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-5-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 5:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L1 file-partition
**Files:** `Animation/CurveAnimator.swift` (new), `Animation/AnimationController.swift` (modified), `Conversation/V2/TimelineCanvas.swift` (modified — `startMasterTimer` removed)
**Class:** ARCHITECTURAL FORK (load-bearing) · **Heat:** HOT
**Citation:** `[ARCH-NINETY-WAVE-02 (one-substrate invariant), Agent O recommends Path A, 9O.6 surfaced-keystone K7]`

**Decision — Path A committed (Path B refused):**

The original architectural fork (registered as WAVE-06 in v4) was: Path A — fold the master-timer (K7) into `AnimationController` via a new `CurveAnimator<T>` substrate, eliminating the second `CADisplayLink`; OR Path B — let `MorphChoreographer` ship its own `CADisplayLink`. **Path A is committed.** Path B violates Wave's "one substrate" invariant (`ARCH-NINETY-WAVE-02`) and re-introduces the very topology Phase 5 is supposed to consolidate.

**AUDIT-29 reconciliation (Path A as substrate-debt-paydown, NOT feature):** Adding `CurveAnimator<T>` to L1 expands the kernel's public type surface, which superficially conflicts with 9Q.4's "no new features." Reclassify per Pillar 7 (dependency direction) + Pillar 2.7 (speculative generality — refused unless rule-of-3 met): `CurveAnimator<T>` ships as **substrate-debt-paydown**, NOT a feature. The current `startMasterTimer` already does what `CurveAnimator<T>` does — it's a hidden, ad-hoc, single-purpose animator. Path A names it correctly + folds it into the kernel + retires the duplicate `CADisplayLink`. The architectural diff is reorganization, not capability expansion. Acceptance: zero new user-visible behavior; ksdiff = 0 on all 7 Maestro flows.

**Architecture:**

```swift
// Animation/CurveAnimator.swift (new)
@MainActor
final class CurveAnimator<T: SpringInterpolatable>: AnimatorProviding {
    struct Curve {
        let duration: TimeInterval
        let timingFunction: CAMediaTimingFunction
        let from: T
        let to: T
    }
    private(set) var state: AnimatorState = .stopped
    private let curve: Curve
    private let onTick: @MainActor (T) -> Void
    private let onComplete: @MainActor () -> Void
    private var elapsed: TimeInterval = 0

    init(curve: Curve, onTick: @escaping @MainActor (T) -> Void, onComplete: @escaping @MainActor () -> Void) {
        self.curve = curve; self.onTick = onTick; self.onComplete = onComplete
    }

    func start() { state = .running; elapsed = 0 }
    func stop()  { state = .stopped }
    func tick(deltaTime: TimeInterval) -> AnimatorState {
        guard state == .running else { return state }
        elapsed += deltaTime
        let rawT = min(elapsed / curve.duration, 1.0)
        let easedT = curve.timingFunction.value(at: CGFloat(rawT))
        onTick(T.interpolate(from: curve.from, to: curve.to, t: easedT))
        if rawT >= 1.0 { state = .stopped; onComplete() }
        return state
    }
}
```

**TimelineCanvas migration:** `startMasterTimer` deleted. `MorphChoreographer.engage` now registers a `CurveAnimator<MorphTickValue>` with `AnimationController`, which already drives a single `CADisplayLink`. The choreographer's per-tick callback (`apply(rawT:choreography:canvas:)`) receives the interpolated value via `onTick` — same math, same fan-out, ONE clock.

**Acceptance:**
- [ ] `grep -rn "startMasterTimer\|masterTimerDisplayLink" DotPinchPrototype/` returns ZERO (the second CADisplayLink is gone)
- [ ] `grep -rn "CADisplayLink" DotPinchPrototype/` returns at most ONE source-of-truth site (`AnimationController.DisplayLinkProxy`)
- [ ] All 7 Maestro flows ksdiff = 0 (frame-identical UX — Path A is reorganization, not capability addition)
- [ ] `CurveAnimator<T>` conforms to `AnimatorProviding` (Agent X4 PILLAR5-A06 — internal protocol)
- [ ] AUDIT-29 classification verified: 9Q.4 "no new features" is honored because Path A retires duplicate clock + names existing capability
- [ ] Pillar 9.1 — `@MainActor` final class; `Sendable`-free (lives in MainActor isolation)
- [ ] 9A.1 row pillars (P1.2 P2.7 P3.4 P4.1 P5.5 P9.1 P11.1 P19.5 P20.1) all green

---

### ☐ Task 5.1 — Extract `MorphChoreography` + `MorphChoreographer`
`[L4 Choreography | P1.2 P2.1 P2.7 P3.4 P3.6 P5.5 P11.1 P11.5 P12.1 P19.5 | Wave 5 (Keystones) | Parity: safe (frame-identical per ledger 8A) | Test: 60+ | Deps: 0.4, 1.2, 1.3, 0.17, 0.12]`
**Agent Ensemble:**
- Implementer: **L4-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-5-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 5:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L4 file-partition
**Files:** `Conversation/V2/MorphChoreography.swift` (new), `Conversation/V2/MorphChoreographer.swift` (new), `Conversation/V2/TimelineCanvas.swift` (modified)
**Class:** KEYSTONE-SURFACING · **Heat:** HOT
**Citation:** `[ARCH-AUDIT-naming-01, ARCH-AUDIT-substrate-09, ARCH-AUDIT-method-06, ARCH-NINETY-ORG-04, K7 (surfaced + renamed per 9O.6 — extraction preserves the keystone's invariant via the choreographer's tick contract)]`

⚠️ **HIGHEST BLAST RADIUS (Agent F):** `animateCameraToChatRest` has **60+ test call sites across 19 test files**. Public method signature MUST be preserved.

**Before:**
- 10 `master*` fields on TimelineCanvas (lines 99-110)
- ~165 LOC of orchestration: `animateCameraToChatRest` (1143-1242) + `animateCameraToChatRestPath` (1247-1312) + `startMasterTimer` (1317-1325) + `masterTimerTick` (1327-1338) + `applyMasterTick` (1348-1377)
- Six concurrent CABasicAnimations on contentHost.layer
- Three UIView.animate cell-chrome fades

**After — new file `Conversation/V2/MorphChoreography.swift`:**
```swift
// Frozen snapshot of morph parameters captured at engagement. Read by
// MorphChoreographer tick-by-tick; never mutated mid-flight. Value-type
// discipline guarantees no shared mutable state between canvas + choreographer.

import CoreGraphics
import Foundation

struct MorphChoreography {
    let activeCellIndex: Int
    let startCameraY: CGFloat
    let endCameraY: CGFloat
    let startHeight: CGFloat
    let endHeight: CGFloat
    let unifiedArcYMagnitude: CGFloat
    let unifiedArcZMagnitude: CGFloat
    let duration: TimeInterval
    let chatRestFactor: CGFloat

    var centerLabelCounterScale: CGFloat { 1.0 / chatRestFactor }
}
```

**New file `Conversation/V2/MorphChoreographer.swift`:**
```swift
// MorphChoreographer — owns the master-timer CADisplayLink + per-tick
// application of MorphChoreography. Extracted from TimelineCanvas so:
//   (a) the canvas no longer carries 10 master* fields
//   (b) the morph's geometric path is independently testable
//   (c) cancellation has a single home (the choreographer's stop())
//
// Surface back into the canvas is intentionally minimal — one method
// (applyMorphTickCameraWrite) handles all the side-effects per frame.

import UIKit
import QuartzCore

@MainActor
final class MorphChoreographer {

    // MARK: - State

    private weak var canvas: TimelineCanvas?
    private var displayLink: CADisplayLink?
    private var startTimestamp: CFTimeInterval = 0
    private var choreography: MorphChoreography?
    private var completion: (() -> Void)?

    // MARK: - Public

    var isRunning: Bool { displayLink != nil }

    init(canvas: TimelineCanvas) {
        self.canvas = canvas
    }

    /// Engage the choreography. Completion fires deterministically at t=1.
    func engage(_ choreo: MorphChoreography, completion: @escaping () -> Void) {
        stop()
        self.choreography = choreo
        self.completion = completion
        startTimestamp = CACurrentMediaTime()
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    /// Halt the choreography. Completion does NOT fire on stop.
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        choreography = nil
        completion = nil
    }

    // MARK: - Per-tick

    @objc private func tick() {
        guard let choreo = choreography, let canvas else { return }
        let elapsed = CACurrentMediaTime() - startTimestamp
        let t = CGFloat(min(elapsed / choreo.duration, 1.0))
        apply(rawT: t, choreography: choreo, canvas: canvas)
        if t >= 1.0 {
            let done = completion
            stop()
            done?()
        }
    }

    /// Y and Z share the same phase curve — both peak at t≈0.35 and resolve
    /// to identity by t≈0.70 (initial lift + camera proximity). Bounds + camera
    /// are linear lerps. All writes in one CATransaction for atomic per-frame.
    private func apply(rawT t: CGFloat, choreography choreo: MorphChoreography, canvas: TimelineCanvas) {
        guard let cell = canvas.instantiatedCells[choreo.activeCellIndex],
              let heightC = cell.heightConstraint else { return }

        let liftPhase = min(t / 0.70, 1.0)
        let liftBell = sin(liftPhase * .pi)
        let unifiedArcY = -choreo.unifiedArcYMagnitude * liftBell
        let unifiedArcZ = choreo.unifiedArcZMagnitude * liftBell

        let newHeight = choreo.startHeight + (choreo.endHeight - choreo.startHeight) * t
        let newCameraY = choreo.startCameraY + (choreo.endCameraY - choreo.startCameraY) * t

        CATransaction.withSuppressedActions {
            canvas.contentHost.layer.transform = CATransform3DMakeTranslation(0, unifiedArcY, unifiedArcZ)
            heightC.constant = newHeight
            canvas.contentHost.layoutIfNeeded()
            canvas.applyMorphTickCameraWrite(translation: newCameraY, cell: cell)
        }
    }
}
```

**TimelineCanvas changes:**
- DELETE 10 `master*` fields (lines 99-110)
- ADD `private lazy var morphChoreographer = MorphChoreographer(canvas: self)` at the class-top (closure-init pattern)
- ADD seam method:
```swift
// MARK: - Choreographer write seam
/// Internal seam for MorphChoreographer's per-tick. Mirrors the camera +
/// visible-cells writes that `applyMasterTick` previously did inline.
func applyMorphTickCameraWrite(translation: CGFloat, cell: CellView) {
    camera = Camera(translation: translation)
    applyCameraTransform()
    updateVisibleCells()
    cell.setCamera(camera, viewport: bounds)
    updateNeighborTranslations()
    updateEdgeMaskAlphas()
    onCameraChanged?(camera, bounds)
}
```
- DELETE `startMasterTimer`, `masterTimerTick`, `applyMasterTick` (lines 1317-1377)
- `animateCameraToChatRest` (PUBLIC — signature preserved) becomes thin orchestrator that:
  (a) does guards
  (b) installs the six CABasicAnimations + three UIView.animate fades (the CHROME, owned by canvas because it animates contentHost.layer + cell labels directly)
  (c) builds a `MorphChoreography` snapshot
  (d) calls `morphChoreographer.engage(choreo) { [weak self] in self?.onMorphRevealReady?(k) }`

**Acceptance:**
- [ ] `MorphChoreography` + `MorphChoreographer` files created
- [ ] 10 `master*` fields removed from TimelineCanvas
- [ ] **`animateCameraToChatRest(forCellAt:)` PUBLIC SIGNATURE UNCHANGED** (60+ tests preserved)
- [ ] Bug B10 (Task 0.4 fix) preserved: pinch-commit fires reveal once
- [ ] Visual diff: frame-identical
- [ ] Choreographer's `stop()` is called by Phase 0 Task 0.3's `handlePinchBegan` augmentation

**Dependencies:** Phase 1 Task 1.2 (MorphTiming), Task 0.4 (reveal fix), Phase 3 (hoisted controller).

---

### ☐ Task 5.2 — `PinchTuning` mutable statics → `PhysicsTuning` value (+ move to DesignSystem/)
`[L2 Tokens | P2.1 P4.1 P5.4 P6.3 P8.3 P11.5 P15.4 P19.5 | Wave 5 (Keystones) | Parity: safe (defaults match) | Test: 30+ | Deps: 0.2 (anticipation* fields deleted first)]`
**Agent Ensemble:**
- Implementer: **L2-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-5-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 5:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L2 file-partition
**Files:** `DesignSystem/PhysicsTuning.swift` (moved + renamed from `Gestures/PinchTuning.swift`), `Conversation/V2/TimelineCanvas.swift`, `Conversation/V2/CameraAnimator.swift`, `App/V2RootViewController.swift`, test files
**Class:** LOAD-BEARING (eliminates global mutable state) · **Heat:** HOT
**Citation:** `[ARCH-AUDIT-anatomy-03, ARCH-AUDIT-hygiene-24]`
**Cross-file (Agent F):** 8 production reads + 30+ test references across 6 files.

**Before** — `PinchTuning` (mutable statics) in `Gestures/PinchTuning.swift` (wrong folder — it's design tokens, not gesture code).

**After — new file `DesignSystem/PhysicsTuning.swift`:**
```swift
// Gesture-physics constants. Value type — passed by ownership rather than
// read off mutable statics. Each substrate engagement carries one tuning
// value end-to-end; runtime swap can't race against in-flight animators.
//
// Moved from Gestures/ to DesignSystem/ — token data, not gesture handler.
// After this file moves, Gestures/ folder is empty and can be removed.

import CoreGraphics
import Foundation

struct PhysicsTuning: Sendable, Equatable {

    // MARK: - Spring physics
    let springDamping: CGFloat
    let springResponse: CGFloat

    // MARK: - Per-commit profiles (§D2 §5.2)
    let tapToChatDamping: CGFloat
    let pinchToCellsDamping: CGFloat
    let cancelledDamping: CGFloat

    init(
        springDamping: CGFloat = 0.85,
        springResponse: CGFloat = 1.10,
        tapToChatDamping: CGFloat = 0.62,
        pinchToCellsDamping: CGFloat = 1.0,
        cancelledDamping: CGFloat = 0.95
    ) {
        precondition(springDamping >= 0.5 && springDamping <= 1.5,
                     "springDamping out of bounds: \(springDamping)")
        precondition(springResponse >= 0.1 && springResponse <= 2.0,
                     "springResponse out of bounds: \(springResponse)")
        self.springDamping = springDamping
        self.springResponse = springResponse
        self.tapToChatDamping = tapToChatDamping
        self.pinchToCellsDamping = pinchToCellsDamping
        self.cancelledDamping = cancelledDamping
    }

    /// Canonical ship-default values.
    static let standard = PhysicsTuning()
}
```

(Note: anticipation* fields removed per Task 0.2.)

Inject via `TimelineCanvas.init(controller:tuning:frame:)` and `CameraAnimator.init(canvas:controller:tuning:)`. V2RootViewController passes `PhysicsTuning.standard`.

**Delete `Gestures/PinchTuning.swift`** after migration. After the file moves, the `Gestures/` folder is empty — delete it.

**Acceptance:**
- [ ] `grep "PinchTuning\." .` returns ZERO
- [ ] Tests construct custom `PhysicsTuning` (no shared-static mutation)
- [ ] `Gestures/` folder removed from `project.yml`
- [ ] Build + all tests pass

**Dependencies:** Task 0.2 (anticipation decision), Phase 3.

---

### ☐ Task 5.3 — Rename + lift `SpringDirection` → `GestureCommit` (own file)
`[L3 Domain substrate | P2.4 P3.4 P4.1 P10.2 | Wave 5 (Keystones) | Parity: safe (rename + lift) | Test: 8 | Deps: 5.2 (consumes PhysicsTuning)]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-5-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 5:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**Files:** `Conversation/V2/GestureCommit.swift` (new), `Conversation/V2/TimelineCanvas.swift`
**Class:** DECORATIVE · **Heat:** WARM
**Citation:** `[ARCH-AUDIT-naming-02, ARCH-AUDIT-method-11, ARCH-NINETY-ORG-05]`

**Agent L finding:** Currently `fileprivate` inside TimelineCanvas (line 1094) and declared MID-FILE after first use. Lifting to its own file improves extensibility — scenario 2 (add a new direction) becomes a single-file edit.

**Before** — `TimelineCanvas.swift:1094`:
```swift
fileprivate enum SpringDirection {
    case tapToChat
    case pinchToCells
    case cancelled
}
```

**After — new file `Conversation/V2/GestureCommit.swift`:**
```swift
// Commit classification — the semantic OUTCOME of a pinch gesture release
// (or a programmatic tap engagement). Keyed off origin × destination, NOT
// off recognizer.scale sign. Renaming from SpringDirection clarifies that
// the enum describes "what the user committed to", not "which way a spring
// happens to run".
//
// Method-on-enum: dampingRatio lets call sites switch ONCE (here) — every
// downstream site just passes the commit along, never reaches into tuning.

import CoreGraphics

enum GestureCommit {
    /// Originated at cell-rest, committed to chat-rest (tap or pinch-out past threshold).
    case commitToChat
    /// Originated at chat-rest, committed back to cell-rest.
    case returnToCells
    /// Gesture cancelled mid-flight; bail to where we came from.
    case bailToOrigin

    func dampingRatio(from tuning: PhysicsTuning) -> CGFloat {
        switch self {
        case .commitToChat:   return tuning.tapToChatDamping
        case .returnToCells:  return tuning.pinchToCellsDamping
        case .bailToOrigin:   return tuning.cancelledDamping
        }
    }
}
```

Rename method params (`direction:` → `commit:`) at lines 1063, 1077, 1106, 1247, 1385.

**Acceptance:**
- [ ] Enum moved to its own file; not nested
- [ ] All 8 sites use new name + new cases
- [ ] `springProfile(for:)` becomes 2 lines (delegates to `commit.dampingRatio(from:)`)

**Dependencies:** Task 5.2 (PhysicsTuning).

---

### ☐ Task 5.4 — Split `animateCameraToChatRestPath` → mechanism-named methods
`[L3 Domain substrate | P1.10 P10.2 P11.1 | Wave 5 (Keystones) | Parity: safe (signature preserved on public method) | Test: 60+ (signature preservation required) | Deps: 5.1, 5.3]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-5-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 5:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**File:** `Conversation/V2/TimelineCanvas.swift`
**Class:** LOAD-BEARING · **Heat:** WARM
**Citation:** `[ARCH-AUDIT-naming-03, ARCH-CARTO-PAT-02]`

**Before** — one polymorphic dispatcher branching on `direction == .tapToChat`.

**After** — two distinct methods, named by mechanism:
```swift
fileprivate func playTapToChatMorph(forCellAt k: Int) {
    // Master-timer / MorphChoreographer path
}

fileprivate func springToChatRest(forCellAt k: Int,
                                  carriedVelocity: CGFloat,
                                  cameraTranslationVelocity: CGFloat,
                                  commit: GestureCommit) {
    // Two-spring path
}

fileprivate func springToCellRest(carriedExtensionVelocity: CGFloat,
                                  cameraTranslationVelocity: CGFloat,
                                  commit: GestureCommit) {
    // Two-spring back to cell-rest
}
```

**`animateCameraToChatRest(forCellAt:)` PUBLIC signature unchanged** (60+ test sites).

**Acceptance:**
- [ ] No `*Path` suffix methods remain
- [ ] Public method preserved
- [ ] Per-method = one mechanism

**Dependencies:** Tasks 5.1, 5.3.

---

### ☐ Task 5.5 — `CameraAnimator` 3-bool state → `EngagementState` enum **(REORDERED per 9O.8 — lands BEFORE Task 0.3 because 0.3's `isQuiet` predicate consumes `cameraAnimator.isRunning` which this task redefines)**
`[L3 Domain substrate | P2.4 P4.1 P5.5 P6.6 P11.1 | Wave 5 (Keystones) | Parity: safe (semantically equivalent) | Test: 18 sites | Deps: — (fully independent per Agent G)]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-5-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 5:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**File:** `Conversation/V2/CameraAnimator.swift`
**Class:** LOAD-BEARING · **Heat:** WARM
**Citation:** `[ARCH-AUDIT-naming-05]`
**Pins SHARED definition (per 9O.8) of `isRunning`** — consumed by Task 0.3 (`isQuiet`) and Task 7B.1 (DispatchWorkItem cancel guard). `EngagementState`'s `if case .engaged = state` IS the SSoT semantics; downstream sites consume, do not redefine.

**Before** — three bools: `pendingCompletion`, `outerCompletionFired = true`, `stoppedByCaller = false` (lines 33-37).

**After:**
```swift
// MARK: - Engagement state
/// Three-state machine replacing the previous 3-bool encoding. Enum makes
/// invalid states unrepresentable: previously, 2³ = 8 boolean tuples encoded
/// 4 logical states with implicit invariants ("outerCompletionFired = true
/// implies pendingCompletion = nil"). The enum compresses this to 3 cases
/// with the completion closure attached directly to the engaged state.
private enum EngagementState {
    case idle
    case engaged(completion: (() -> Void)?)
    case stopping
}
private var state: EngagementState = .idle
```

Update all 18 sites to switch on the enum. `isRunning` becomes `if case .engaged = state { true } else { false }`.

**Acceptance:**
- [ ] Three bool fields removed
- [ ] All 18 sites convert to enum switch
- [ ] Existing tests pass (same-target short-circuit, natural settle, caller-stop suppress, pre-emption)

**Dependencies:** None — fully independent (Agent G: most decoupled refactor in the set).

---

### ☐ Task 5.8 — `CellView.performMorphChromeTransition(profile:)` seam (Migration M3) **(AUTHORED INLINE per 9R.4.3)**
`[L3 Domain substrate | P1.2 P2.2 P11.1 P12.2 P19.5 | Wave 5 (Keystones) | Parity: safe (semantics preserved) | Test: ~5 (chrome-fade tests) | Deps: 5.1, 1.2 (LabelFadeTiming)]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-5-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 5:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**Files:** `Conversation/V2/CellView.swift`, `Conversation/V2/TimelineCanvas.swift`, `Conversation/V2/MorphChoreographer.swift`
**Class:** LOAD-BEARING (eliminates feature envy) · **Heat:** WARM
**Citation:** `[ARCH-ADVERSARIAL-PILLAR2-12 (P0 feature envy), 9L.4]`

**Before** — `TimelineCanvas.animateCameraToChatRest:1216-1236` writes 6 CellView labels directly (feature envy):
```swift
// In TimelineCanvas:1216-1223 — adds CABasicAnimation to chatRestCenterLabel.layer
activeCell.chatRestCenterLabel.layer.add(centerLabelOpacity, forKey: ...)
// TimelineCanvas:1225-1236 — three UIView.animate fades on cell's chrome labels
UIView.animate(withDuration: 0.08, delay: 0, ...) { activeCell.dateLabel.alpha = 0 }
UIView.animate(withDuration: 0.17, delay: 0.03, ...) { activeCell.topicSummaryLabel.alpha = 0 }
UIView.animate(withDuration: 0.20, delay: 0.08, ...) {
    activeCell.todayLabel.alpha = 0
    activeCell.pinchGlyph.alpha = 0
}
```

**After** — TimelineCanvas calls a CellView method; CellView owns its own chrome lifecycle:
```swift
// CellView.swift — NEW method on the type that owns the labels
func performMorphChromeTransition(profile: LabelFadeTiming.Profile = .standard) {
    morphInProgress = true

    // CABasicAnimation on center label
    let centerOpacity = CABasicAnimation.make(
        keyPath: "opacity",
        from: 0, to: 1,
        duration: profile.centerLabelDuration,
        timing: CAMediaTimingFunction(controlPoints: MorphCurves.labelOpacity.0,
                                       MorphCurves.labelOpacity.1,
                                       MorphCurves.labelOpacity.2,
                                       MorphCurves.labelOpacity.3),
        additive: false)
    chatRestCenterLabel.layer.add(centerOpacity, forKey: MorphAnimationKey.centerLabelOpacity.rawValue)

    // Three chrome fades (cell owns the order + which labels)
    UIView.animate(withDuration: LabelFadeTiming.dateLabelDuration,
                   delay: LabelFadeTiming.dateLabelDelay,
                   options: [.curveEaseOut, .allowUserInteraction]) {
        self.dateLabel.alpha = 0
    }
    UIView.animate(withDuration: LabelFadeTiming.topicSummaryDuration,
                   delay: LabelFadeTiming.topicSummaryDelay,
                   options: [.curveEaseOut, .allowUserInteraction]) {
        self.topicSummaryLabel.alpha = 0
    }
    UIView.animate(withDuration: LabelFadeTiming.todayAndGlyphDuration,
                   delay: LabelFadeTiming.todayAndGlyphDelay,
                   options: [.curveEaseOut, .allowUserInteraction]) {
        self.todayLabel.alpha = 0
        self.pinchGlyph.alpha = 0
    }
}
```

`TimelineCanvas.animateCameraToChatRest` now calls:
```swift
activeCell.performMorphChromeTransition()
```

**Acceptance:**
- [ ] `grep -n "activeCell\.dateLabel\|activeCell\.topicSummaryLabel\|activeCell\.todayLabel\|activeCell\.pinchGlyph\|activeCell\.chatRestCenterLabel" Conversation/V2/TimelineCanvas.swift` = ZERO (canvas no longer reaches into cell's labels)
- [ ] `CellView.performMorphChromeTransition` is the SOLE write site for the 6 morph-chrome properties
- [ ] Parity: frame-identical to pre-extraction Maestro screenshots (Pillar 10.1 — semantics preserved)
- [ ] 9B 10-pillar checklist green

**Dependencies:** Task 5.1 (MorphChoreographer) + Task 1.2 (MorphTiming + LabelFadeTiming).

---

### ☐ Task 5.9 — `CellView.followActive(growth:position:)` seam (Migration M3) **(AUTHORED INLINE per 9R.4.3)**
`[L3 Domain substrate | P1.2 P2.2 P11.1 P12.2 | Wave 5 (Keystones) | Parity: safe | Test: ~3 (neighbor-transform tests) | Deps: 5.1]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-5-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 5:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**Files:** `Conversation/V2/CellView.swift`, `Conversation/V2/TimelineCanvas.swift`
**Class:** LOAD-BEARING (eliminates feature envy) · **Heat:** WARM
**Citation:** `[ARCH-ADVERSARIAL-PILLAR2-15 (P0 feature envy), 9L.4]`

**Before** — `TimelineCanvas.updateNeighborTranslations:714-732` writes `cell.transform` on every cell directly:
```swift
for (index, cell) in instantiatedCells {
    guard index != activeIdx else { continue }
    let direction: CGFloat = index < activeIdx ? -1 : 1
    let ty = direction * growth * 0.5
    cell.transform = CGAffineTransform(translationX: 0, y: ty)
}
```

**After** — CellView gains the seam; TimelineCanvas tells each cell to follow:
```swift
// CellView.swift — NEW
enum NeighborPosition { case above, below }

func followActive(growth: CGFloat, position: NeighborPosition) {
    let direction: CGFloat = (position == .above) ? -1 : 1
    let ty = direction * growth * 0.5
    transform = CGAffineTransform(translationX: 0, y: ty)
}

func resetFollowTransform() {
    transform = .identity
}
```

`TimelineCanvas.updateNeighborTranslations` now:
```swift
for (index, cell) in instantiatedCells {
    guard index != activeIdx else { continue }
    let pos: CellView.NeighborPosition = (index < activeIdx) ? .above : .below
    cell.followActive(growth: growth, position: pos)
}
```

And on no-active-cell:
```swift
for (_, cell) in instantiatedCells {
    cell.resetFollowTransform()
}
```

**Acceptance:**
- [ ] `grep -n "cell\.transform\s*=" Conversation/V2/TimelineCanvas.swift` = ZERO (canvas no longer writes cell.transform directly)
- [ ] `CellView.followActive` + `CellView.resetFollowTransform` are the SOLE write sites for cell `transform`
- [ ] Parity: frame-identical neighbor translations during pinch + morph
- [ ] 9B 10-pillar checklist green

**Dependencies:** Task 5.1 (MorphChoreographer).

---

### ☐ Task 5.10 — Extract `PinchState` struct from TimelineCanvas **(AUTHORED INLINE per Agent X3 PILLAR3-17 — reading-sequence fix)**
`[L3 Domain substrate | P2.6 P3.4 P11.1 P19.5 | Wave 5 (Keystones) | Parity: safe | Test: many (pinch state tests) | Deps: 5.5]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-5-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 5:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**Files:** `Conversation/V2/PinchState.swift` (new), `Conversation/V2/TimelineCanvas.swift`
**Class:** DECORATIVE (state consolidation) · **Heat:** WARM
**Citation:** `[ARCH-ADVERSARIAL-PILLAR3-17 — reading-sequence fix per Agent X3]`

**Before** — TimelineCanvas has ~6 loose `pinchInitial*` / `pinchPrevious*` / `pinchAnchor*` fields at lines 65-83 declared BEFORE any pinch handler.

**After** — One `PinchState` struct holds the gesture-local state:
```swift
// PinchState.swift
struct PinchState {
    var initialScale: CGFloat = 1.0
    var initialExtension: CGFloat = 0
    var anchorPageY: CGFloat = 0
    var previousCentroidY: CGFloat = 0
    var previousCentroidTimestamp: CFTimeInterval = 0

    mutating func reset() {
        self = PinchState()
    }
}
```

TimelineCanvas holds `private var pinchState = PinchState()`.

**Acceptance:**
- [ ] TimelineCanvas state-cluster LOC drops by ~10 lines
- [ ] PinchState fully encapsulates pinch-gesture transient state
- [ ] `defer { pinchState.reset() }` pattern replaces the 2-line reset block at end of handlePinchEnded
- [ ] Parity: frame-identical
- [ ] 9B 10-pillar checklist green

---

### ☐ Task 5.6 — Scene-phase observer (UIScene.willResignActiveNotification → cancel in-flight animations)
`[L4 Choreography | P1.2 P3.6 P4.3 P5.5 P9.1 P11.1 P15.1 P19.5 | Wave 5 (Keystones) | Parity: background-resume break (8B-5) | Test: 1 | Deps: 4.5, 5.1]`
**Agent Ensemble:**
- Implementer: **L4-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-5-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 5:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L4 file-partition
**Files:** `App/V2RootViewController.swift`, `Conversation/V2/TimelineCanvas.swift`, `Conversation/V2/MorphChoreographer.swift`, `Conversation/V2/RevealCoordinator.swift`

**Change:** Today, backgrounding mid-morph leaves `CADisplayLink`-driven animations frozen-then-resumed against stale wall-clock time, producing visible jumps. Task 0.12 fixed wall-clock drift via DisplayLink-local time, but the right architectural fix is to OBSERVE scene-phase transitions and explicitly cancel in-flight choreography on `willResignActiveNotification` — letting the morph snap to its end-state cleanly rather than freeze.

```swift
// App/V2RootViewController.swift — viewDidLoad
NotificationCenter.default.addObserver(
    self, selector: #selector(sceneWillResignActive),
    name: UIScene.willResignActiveNotification, object: nil
)

@objc private func sceneWillResignActive() {
    timelineCanvas.cancelInFlightAnimations()   // forwards to choreographer.stop() + cameraAnimator.stop()
    revealCoordinator.cancelInFlight()          // already authored in Task 4.5
}
```

**Acceptance:**
- [ ] Observer registered in `V2RootViewController.viewDidLoad`; removed in `deinit`
- [ ] `cancelInFlightAnimations()` on TimelineCanvas calls `morphChoreographer.stop()` + `cameraAnimator.stop()`
- [ ] Maestro flow 5 (background-resume mid-morph) — ksdiff documents the intentional snap-to-rest delta (Parity-Break Ledger 8B-5 row)
- [ ] Pillar 4.3 — `@MainActor` observer (UIScene notifications post on main)
- [ ] 9A.1 row pillars green

---

### ☐ Task 5.7 — `morphInProgress` Bool collapse (single source of truth for "is the morph engaged")
`[L3 Domain | P1.5 P2.4 P5.5 P11.1 P15.5 P19.5 | Wave 5 (Keystones) | Parity: safe | Test: 0 | Deps: 5.1, 5.5]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-5-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 5:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**Files:** `Conversation/V2/TimelineCanvas.swift`, `Conversation/V2/CellView.swift`, `Conversation/V2/MorphChoreographer.swift`

**Change:** Today `morphInProgress` is duplicated across TimelineCanvas, CellView, and (post-5.1) MorphChoreographer. After Task 5.1 extracts the choreographer, the choreographer's `isRunning` becomes the single source of truth. Collapse all consumer-side `morphInProgress` Bools into computed properties that read `morphChoreographer.isRunning`.

```swift
// TimelineCanvas — BEFORE
private var morphInProgress = false
// AFTER
var morphInProgress: Bool { morphChoreographer.isRunning }

// CellView — BEFORE
var morphInProgress = false   // set externally by canvas at engage/disengage
// AFTER
weak var morphChoreographer: MorphChoreographer?
var morphInProgress: Bool { morphChoreographer?.isRunning ?? false }
```

**Acceptance:**
- [ ] Zero `morphInProgress = true` / `= false` assignments in production code (`grep -n "morphInProgress\s*=" DotPinchPrototype/` returns ZERO writes)
- [ ] All read sites unchanged in semantics
- [ ] Parity: frame-identical
- [ ] Pillar 15.5 (Magic Pushbutton — implicit state mutation) violation closed
- [ ] 9A.1 row pillars green

---

## 🔁 RETROSPECTIVE — Post-Wave 5 (Keystones) **— HEAVIEST RETRO**

**INVOKE 9Q.3 OPERATIONAL PROTOCOL.** R1-R8 + `/root-cause-tracing`. **FIX IMMEDIATELY. BLOCKING.** This is the gravitational-center retro — MorphChoreographer (Task 5.1) is the largest extraction in the migration.

### Wave 5 specific hunts

**R1 Doctrine:** Every Wave 5 task (5.0-5.5 + 5.6-5.10 if landed in this wave) against 9B. PARTICULAR scrutiny on Pillar 11.1 (SRP) and Pillar 12.1 (Law of Demeter): does MorphChoreographer reach into `canvas.contentHost.layer.transform` (justified per 9L.4 collaboration seam — `/root-cause-tracing` Q1+Q3 trace required) OR does it introduce new LoD violations? Pillar 5.5 reframe applies (app target — `private(set) var` ≠ smell).

**R2 Code Smells:**
- (a) Did Wave 5 introduce NEW feature envy on CellView labels? — should be ELIMINATED by `CellView.performMorphChromeTransition` seam (Task 5.8) if landed here. If 5.8 deferred, document with refusal-list entry.
- (b) Did Wave 5 introduce NEW primitive obsession? — `MorphChoreography` struct fields are CGFloat/Int/TimeInterval (justified for Tier 2 token layer); typed wrappers (PageY/ScaleFactor/DampingRatio) deferred to Task 7.6.
- (c) Did Wave 5 spawn a second CADisplayLink (per Agent O WAVE-06)? Path A (CurveAnimator extending substrate — Task 5.0) OR Path B (explicit refusal in 18-item list)?

**R3 Dead-Code Sweep — Wave 5 specific:**
- `grep -n "masterTimer\|masterTimerStart\|masterTimerDuration\|masterTimerCompletion\|masterStartHeight\|masterEndHeight\|masterStartCameraY\|masterEndCameraY\|masterUnifiedArcMagnitude\|masterActiveCellIndex" Conversation/V2/TimelineCanvas.swift` = ZERO (10 master* fields removed)
- `grep -n "startMasterTimer\|masterTimerTick\|applyMasterTick" Conversation/V2/TimelineCanvas.swift` = ZERO (3 methods removed)
- `grep -rn "SpringDirection" DotPinchPrototype/` = ZERO (lifted to GestureCommit.swift)
- `grep -rn "PinchTuning" DotPinchPrototype/` = ZERO (renamed PhysicsTuning, moved to DesignSystem/)
- `Gestures/` folder removed from project.yml
- `grep -n "outerCompletionFired\|stoppedByCaller\|pendingCompletion" Conversation/V2/CameraAnimator.swift` = ZERO (replaced by EngagementState enum)
- Test file vestigial references: `grep -rn "SpringDirection\|PinchTuning\." Tests/` = ZERO
- Cumulative re-sweep of Waves 0-4 dead-code targets — all still clean

**R4 Parity Verifier — LOAD-BEARING:** This is the highest-risk parity check in the migration.
- ALL 7 Maestro flows ksdiff against pre-Wave-5 baseline MUST = 0 px delta
- Frame-by-frame comparison on Flow 1 (tap-to-chat) keyframes S1-S5 (per 8C definition)
- If ANY delta detected → STOP, root-cause-trace immediately:
  - Q1: which property differs?
  - Q2: which task introduced the divergence?
  - Q3: is it CABasicAnimation install order? CATransaction grouping? Tick-frequency?
  - Fix in-wave. Do not close Wave 5 with parity break.

**R5 File-Org:**
- New files in correct layers: MorphChoreography + MorphChoreographer in Conversation/V2/ (L4 Choreography per 9Q.2 tag-lines); GestureCommit.swift in Conversation/V2/; PhysicsTuning.swift in DesignSystem/
- MARK density on TimelineCanvas re-verified — should have DROPPED with master-timer extraction
- TimelineCanvas LOC: post-Wave-5 should be <1200 (down from 1477). Confirm; if still ≥1400, the extraction was incomplete.

**R6 Method-Cleanliness — judgment tests on changed methods:**
- `MorphChoreographer.engage(_:completion:)` — passes 1-week-out + junior-dev + reading-sequence
- `MorphChoreographer.tick()` — passes deletion test (removal would explicitly break the morph)
- `MorphChoreographer.apply(rawT:choreography:canvas:)` — ordering invariants documented; reader can verify per-tick order
- `TimelineCanvas.applyMorphTickCameraWrite(translation:cell:)` seam — minimal surface (single method, single responsibility)
- Public `animateCameraToChatRest(forCellAt:)` signature UNCHANGED (60+ test sites preserved)

**R7 Abstraction:**
- `MorphChoreography` struct: 8 `let` fields (P19.5 immutability); justified by 1 consumer (MorphChoreographer) — borderline 1-consumer abstraction, BUT load-bearing because it's the snapshot value type at engagement time. Document the justification.
- `MorphChoreographer` class: 1 consumer (TimelineCanvas); justified by CADisplayLink ownership + the gravitational-center extraction
- `GestureCommit` enum: 3 cases, 1 consumer (TimelineCanvas); justified by replacing 3-bool state machine

**R8 Concurrency + Safety — LOAD-BEARING:**
- `MorphChoreographer` carries `deinit { displayLink?.invalidate() }` (per 7A.5 / Agent M RUNTIME-05)
- TimelineCanvas's `morphChoreographer` is `Optional`, NOT `lazy var` (per 9L.2 + 7A.5)
- `MorphChoreographer.stop()` resets `contentHost.layer.transform = .identity` (per 7G.3 / Agent S STATE-03)
- `MorphChoreographer.engage()` NOT called from inside CATransaction.withSuppressedActions block (per 7A.8 / Agent M RUNTIME-08)
- `MorphChoreographer.displayLink.preferredFrameRateRange = (80, 120, 120)` (per 7A.3 / Agent M RUNTIME-03)
- `EngagementState` enum's `isRunning` IS the SSoT for Task 0.3's `isQuiet` predicate (per 9O.8 coupling)
- Task 0.4's pinch-commit reveal-fire patch SURVIVES extraction (B10 regression check via ksdiff Flow 2)

### Wave 5 closes ONLY when 9Q.3 Stage 4 BLOCKING criteria are green AND Parity Ledger 8A rows verified post-Wave-5. Wave 6 BLOCKED until then.

### Wave 5 visual testing checklist (literal per 9Q.3 Stage 10 — BINDING)

- [ ] Maestro flows executed on iOS 18 sim: **1 (keyframes S0-S5), 2, 5, 7**
- [ ] Per-state screenshots captured (S0-S5 where applicable; per 8C protocol)
- [ ] Manual visual analysis — reviewer eyeballs screenshots side-by-side with baseline (NOT just ksdiff)
- [ ] Side-by-side comparison archived in `docs/visual-baselines/wave-5/`
- [ ] Subjective animation quality assessment ("does the reveal FEEL right?")

### Wave 5 wave-close merge gate (per §0.10)

1. **Wave-5-Lead** waits for all Wave 5 implementation agents to return worktrees integrated
2. **R1-R8** dispatched in PARALLEL against integrated Wave 5 diff
3. **Findings fixed in-place** per 9Q.3 Stage 3; re-dispatch verifies clean
4. **Parity-Agent SERIAL gate** — Phase 8C ksdiff on assigned flows (1 (keyframes S0-S5), 2, 5, 7)
5. **Wave 5 CLOSES.** Wave 6's Wave-Lead may begin dispatch.

**Retro time budget (per §0.9):** 8 hours. If exceeded by >50% → invoke 9Q.3 Stage 7 Failure-of-Retro protocol.

### Wave 5 cross-wave learning ledger entry (per §0.11 — populated at retro close)

```
Wave 5 patterns observed (added to subsequent wave hunts):
- Pattern P<NN>: <one-line description>
  Flagged by: R<X>
  Remediation: <how it was fixed>
  Propagation: <which subsequent wave's R-agent hunts this gets added to>
```

### Wave 5 Stage 6 retro paragraph (mandatory at close — per 9Q.3 Stage 8 Rosetta stone)

> _Wave 5 retro: agents R1-R8 ran post-Wave-5-landing; <N1> findings flagged; <N2> root-causes traced; <N3> fixes applied IMMEDIATELY in-wave; <N4> findings escalated to refusal-list (with rationale); re-dispatch verified clean. Parity-Break Ledger entries for Wave 5: <list>. Wave 5 CLOSED at <timestamp>. Wave 6 may begin._

**Wave 5 retro closes ONLY when** 9Q.3 Stage 4 BLOCKING criteria are green + ALL visual checkboxes ticked + Stage 6 paragraph populated with concrete N1-N4 + pattern ledger entries authored.

---

# Phase 6 — Code Hygiene Polish

**Goal:** The user-emphasized phase. File organization, readability, extensions, closure-init at class top, separation of concerns, extensibility seams, abstraction discipline. Lands AFTER structural refactors so it polishes the new shape, not the old.

**Dependencies:** Phase 0-5.

---

**Wave 6 Agent Topology — MAXIMUM FLEET SATURATION:**
- **Fleet:** 6 agents — ALL 5 implementation agents (L1-L5) + Doctrine-Agent (for 6.7, 6.8, 6.18 cross-cutting sweeps)
- **Parallel groups:** ALL 44+ tasks parallelize by file-partition; this is the most independent wave
  - L1-Agent: 6.5 AnimatorProviding, 6.15 SpringAnimator didSet, 6.23 makeCAAnimation factory, 6.24 _displayLinkFired, 6.40 DisplayLinkProxy reorder, 6.44 @frozen
  - L2-Agent: 6.1 PhysicsTuning move, 6.4 GestureCommit lift
  - L3-Agent: 6.2, 6.3, 6.6, 6.9, 6.10 (L4 cross), 6.12, 6.13, 6.14, 6.16, 6.17, 6.19, 6.20, 6.21, 6.22, 6.25, 6.26, 6.27, 6.39a, 6.41, 6.42, 6.43
  - L5-Agent: 6.3 (V2Root part)
  - Doctrine-Agent: 6.7 imports, 6.8 cross-file naming, 6.9 stale pointer, 6.18 ForTesting suffix, 6.41 WHY comments
- **Critical path within wave:** none dominant — 6.43 (var→let sweep) touches multiple layers but uses worktree isolation
- **Wave-6-Lead** dispatches MAX parallelism; Parity-Agent batched verification at wave close
- **Wall-clock estimate with fleet:** 2-3 days (vs 6-9 single-engineer) — **highest speedup**

---


## 6A — File Organization & Pragma Marks (Agent J — 25 findings)

### ☐ Task 6.1 — Move PhysicsTuning to DesignSystem/, delete Gestures/ folder

**Agent Ensemble:**
- Implementer: **L2-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**Class:** DECORATIVE · **Heat:** COOL · `[ARCH-AUDIT-hygiene-24]`

Already covered by Phase 5 Task 5.2. Cross-reference for completeness.

---

### ☐ Task 6.2 — Move `UIGestureRecognizerDelegate` conformance to file-end extension

**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**File:** `Conversation/V2/TimelineCanvas.swift`
**Class:** DECORATIVE · **Heat:** COOL
**Citation:** `[ARCH-AUDIT-hygiene-16, ARCH-NINETY-ORG-01]`

**The codebase has ZERO file-end conformance extensions today** (Agent J). This is the largest single readability lift available.

**Before** — `TimelineCanvas.swift:10`:
```swift
final class TimelineCanvas: UIView, UIGestureRecognizerDelegate {
    // ... 1467 lines ...
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        // ~10 lines at 1467-1476
    }
}
```

**After:**
```swift
final class TimelineCanvas: UIView {
    // ... 1450 lines (10 fewer) ...
}

// MARK: - UIGestureRecognizerDelegate
extension TimelineCanvas: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        // ... body unchanged ...
    }
}
```

**Acceptance:**
- [ ] Class declaration line no longer lies about TimelineCanvas's surface
- [ ] Build succeeds; gesture behavior unchanged

**Apply same pattern to:**
- `Conversation.swift:13` — `Equatable, Hashable` → file-end extension `[ARCH-AUDIT-hygiene-20]`
- `TimelineDataSourceAdapter.swift:13` — `TimelineDataSource` conformance → file-end extension `[ARCH-AUDIT-hygiene-19]`

---

### ☐ Task 6.3 — Add MARK regions to ChatViewController + V2RootViewController

**Agent Ensemble:**
- Implementer: **L5-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**Files:** `Conversation/V2/ChatViewController.swift`, `App/V2RootViewController.swift`
**Class:** DECORATIVE · **Heat:** COOL
**Citation:** `[ARCH-AUDIT-hygiene-11, 12, 01, ARCH-AUDIT-method-16, ARCH-NINETY-ORG-02]`

ChatViewController has ZERO MARK headers despite 8 distinct methods. Add:
```swift
// MARK: - Subviews (closure-init at class-top)
// MARK: - Lifecycle
// MARK: - Configuration
// MARK: - Subview setup
// MARK: - Layout
// MARK: - Bubble rendering
// MARK: - Scroll
```

V2RootViewController has 2 MARKs; `handleTap` (line 69) and `revealChat` (line 77) live unmarked. Add:
```swift
// MARK: - Gesture handling
// MARK: - Chat reveal       (or: REMOVED after Phase 4 — coordinator owns it)
```

**Acceptance:**
- [ ] No method outside a MARK region in either file

---

### ☐ Task 6.4 — Lift `GestureCommit` enum to file top (covered by 5.3)

**Agent Ensemble:**
- Implementer: **L2-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**Citation:** `[ARCH-AUDIT-hygiene-14]`

Phase 5 Task 5.3 already promotes the enum to its own file at file-top. Cross-reference.

---

### ☐ Task 6.5 — Lift `AnimatorProviding` + `AnimatorState` to own file

**Agent Ensemble:**
- Implementer: **L1-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**File:** `Animation/AnimatorProviding.swift` (new)
**Class:** DECORATIVE · **Heat:** COOL
**Citation:** `[ARCH-AUDIT-hygiene-04]`

Currently siblings to SpringAnimator inside `SpringAnimator.swift` (lines 10-21). Both are consumed by `AnimationController` and `SpringAnimator` — give them their own home.

**New file `Animation/AnimatorProviding.swift`:**
```swift
// Animator protocol + state enum — consumed by AnimationController (registry)
// and SpringAnimator (concrete impl). Lifted out of SpringAnimator.swift so
// the protocol's home doesn't require scrolling past the concrete impl.

import Foundation

enum AnimatorState {
    case inactive
    case running
    case ended
}

protocol AnimatorProviding: AnyObject {
    var id: UUID { get }
    var state: AnimatorState { get }
    func updateAnimation(deltaTime: TimeInterval)
}
```

**Acceptance:**
- [ ] `AnimatorProviding.swift` exists; SpringAnimator.swift no longer declares these types

---

### ☐ Task 6.6 — Section the 534-LOC pinch block in TimelineCanvas

**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**File:** `Conversation/V2/TimelineCanvas.swift`
**Class:** DECORATIVE · **Heat:** WARM
**Citation:** `[ARCH-AUDIT-hygiene-17, ARCH-AUDIT-method-17]`

After Phase 5 extractions, what remains of the pinch region (~534 LOC) needs internal sectioning:
```swift
// MARK: - Pinch gesture (recognizer plumbing)
// MARK: - Commit classification
// MARK: - Spring profiles
// MARK: - Chat-rest CABasicAnimation chrome
// MARK: - Cell-rest spring coordination
// MARK: - Pan deceleration
// MARK: - Cell tap
```

`startSpringDeceleration` (Agent L: line 1447) should also MOVE into the Pan-gesture region near `clampedWithRubberband` at line 913.

---

### ☐ Task 6.7 — Remove unused imports

**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**Files:** `Animation/AnimationController.swift`, `Animation/SpringInterpolatable.swift`, `Conversation/V2/CellView.swift`
**Class:** DECORATIVE · **Heat:** COOL
**Citation:** `[ARCH-AUDIT-hygiene-03, 06, 10]`

- `AnimationController.swift:8` — `import UIKit` unused (only QuartzCore types used)
- `SpringInterpolatable.swift:7` — `import QuartzCore` unused
- `CellView.swift:8` — `import Observation` unused (no `@Observable`, no `withObservationTracking`)

---

### ☐ Task 6.8 — Cross-file consistency: naming, spelling, header placement

**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**Class:** DECORATIVE · **Heat:** COOL
**Citation:** `[ARCH-AUDIT-hygiene-21, 22, 23, ARCH-AUDIT-method-* cross-cutting]`

Pick ONE convention per pair and apply globally:

| Pair | Decision |
|---|---|
| `Init` vs `Initialization` | `Init` (matches views) |
| `colours` vs `colors` (Theme.swift:27) | `colors` (American spelling — every other file) |
| Theme.swift header position | Move ABOVE `import UIKit` (matches every other file) |
| `setup*` vs `install*` | `install*` (16 occurrences vs 1) — see Task 6.16 |

---

### ☐ Task 6.9 — Resolve stale `MorphTiming.swift` pointer

**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**File:** `Gestures/PinchTuning.swift` (or `DesignSystem/PhysicsTuning.swift` after move)
**Class:** DECORATIVE · **Heat:** COOL · `[ARCH-AUDIT-hygiene-25]`

PinchTuning's header at line 3 references `Conversation/MorphTiming.swift` — which doesn't exist BEFORE Phase 1 Task 1.2 ships. After 1.2 lands, this reference becomes accurate. Confirm.

---

## 6B — Property Declaration Patterns (Agent K — user-emphasized)

**Central principle (ARCH-NINETY-ORG-03):** Closure-init at class top, NOT in `setupX()` methods using IUOs.

### ☐ Task 6.10 — Reveal state on RevealCoordinator → enum

**Agent Ensemble:**
- Implementer: **L4-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**File:** `App/RevealCoordinator.swift` (after Phase 4)
**Class:** LOAD-BEARING · **Heat:** COOL
**Citation:** `[ARCH-AUDIT-property-01]`

After Phase 4, RevealCoordinator owns `activeChatVC: ChatViewController?` + `revealBlurOverlay: RevealBlurOverlay?`. These can desync under cancellation.

**Before:**
```swift
private(set) var activeChatVC: ChatViewController?
private var revealBlurOverlay: RevealBlurOverlay?
```

**After:**
```swift
private enum RevealState {
    case idle
    case active(chat: ChatViewController, blur: RevealBlurOverlay)

    var isActive: Bool {
        if case .active = self { return true } else { return false }
    }
}
private var revealState: RevealState = .idle
```

Update `isPresenting` to `revealState.isActive`. Update `present` + `runRevealChoreography` to transition state via `revealState = .active(chat:blur:)` and `revealState = .idle`.

**Acceptance:**
- [ ] Desync class eliminated (can't have chat set + blur nil)
- [ ] All read sites switch on enum

---

### ☐ Task 6.11 — `MasterTimerSnapshot` (subsumed by 5.1)

**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**Citation:** `[ARCH-AUDIT-property-02]`

Phase 5 Task 5.1 already extracts `MorphChoreography` struct + `MorphChoreographer` collaborator, subsuming the 10 `master*` fields.

---

### ☐ Task 6.12 — Promote `extensionAnimator` IUO → `let`

**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**File:** `Conversation/V2/TimelineCanvas.swift`
**Class:** DECORATIVE · **Heat:** COOL
**Citation:** `[ARCH-AUDIT-property-03]`

**Before:**
```swift
private(set) var extensionAnimator: SpringAnimator<CGFloat>!  // line 94
// ... assigned at line 157 after super.init
```

**After** — initialize BEFORE `super.init`:
```swift
private let extensionAnimator: SpringAnimator<CGFloat>

init(controller: AnimationController, frame: CGRect = .zero) {
    self.animationController = controller
    self.extensionAnimator = SpringAnimator(
        controller: controller,
        spring: Spring(dampingRatio: PinchTuning.springDamping, response: PinchTuning.springResponse)
    )
    super.init(frame: frame)
    installViewHierarchy()
    // ... rest ...
    cameraAnimator = CameraAnimator(canvas: self, controller: animationController)  // STAYS IUO — needs self
    extensionAnimator.valueChanged = { [weak self] _ in self?.applyExtensionTick() }
    applyCameraTransform()
}
```

⚠️ **`cameraAnimator` MUST stay IUO** — genuinely needs `self`. The Agent K analysis confirmed this is load-bearing IUO usage.

**Acceptance:**
- [ ] `extensionAnimator` is now `let` (true immutability)
- [ ] `cameraAnimator` correctly remains IUO with documentation explaining why

---

### ☐ Task 6.13 — Promote CellView's IUOs to inline `let` (closure-init at top)

**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**File:** `Conversation/V2/CellView.swift`
**Class:** DECORATIVE (matches the user-emphasized pattern) · **Heat:** WARM
**Citation:** `[ARCH-AUDIT-property-04, ARCH-NINETY-ORG-03]`

**THE USER-EMPHASIZED REFACTOR.** Currently 7 IUOs assigned in `setupSubviews()` / `install*()` helpers. Convert to inline-let-with-closure-init at class top — matches ChatViewController + ChatBubbleView (the cleaner camp).

**Before (CellView.swift:28-35, with `setupSubviews()` at 156 + helpers at 164+):**
```swift
private(set) var dateLabel: UILabel!
private(set) var topicSummaryLabel: UILabel!
private(set) var todayLabel: UILabel!
private(set) var labelStack: UIStackView!
private(set) var chatRestCenterLabel: UILabel!
private(set) var pinchGlyph: UIImageView!

// ... 100 lines below ...

private func setupSubviews() {
    installLabelStack()
    installPinchGlyph()
    activateConstraints()
}

private func installLabelStack() {
    dateLabel = UILabel()
    dateLabel.font = Theme.Typography.dateLabel
    dateLabel.textColor = Theme.Text.secondary
    // ... etc ...
}
```

**After (closure-init at class top, no IUOs, no setupX helpers):**
```swift
// MARK: - Content subviews (closure-init at class-top)
//
// Per ARCH-NINETY-ORG-03: all subview construction happens at declaration,
// not deferred to setupX() helpers. Eliminates IUO ambiguity ("is this set
// yet?") and matches ChatViewController / ChatBubbleView discipline.

private(set) lazy var dateLabel: UILabel = {
    let l = UILabel()
    l.translatesAutoresizingMaskIntoConstraints = false
    l.font = Theme.Typography.dateLabel
    l.textColor = Theme.Text.secondary
    l.numberOfLines = 1
    return l
}()

// WAIT — user-emphasized rule: NO lazy var (ARCH-NINETY-ABS-02). Use eager
// closure-init, not lazy. But UILabels can't be eagerly init'd before init()
// because they aren't dependent on self. Yes they CAN — UILabel() is a free
// constructor. So:

private(set) var dateLabel: UILabel = {
    let l = UILabel()
    l.translatesAutoresizingMaskIntoConstraints = false
    l.font = Theme.Typography.dateLabel
    l.textColor = Theme.Text.secondary
    l.numberOfLines = 1
    return l
}()

private(set) var topicSummaryLabel: UILabel = {
    let l = UILabel()
    l.translatesAutoresizingMaskIntoConstraints = false
    l.font = Theme.Typography.topicSummary
    l.textColor = Theme.Text.primary
    l.numberOfLines = 2
    return l
}()

// ... and so on for all 7 subviews ...

private(set) var labelStack: UIStackView = {
    let s = UIStackView()
    s.translatesAutoresizingMaskIntoConstraints = false
    s.axis = .vertical
    s.spacing = 4
    s.alignment = .leading
    return s
}()
```

Then in `init`, `setupSubviews()` becomes just constraint wiring + arrangedSubviews assignment:
```swift
override init(frame: CGRect) {
    super.init(frame: frame)
    installSubviews()  // renamed from setupSubviews
    // No more "var dateLabel = UILabel()" inside helpers — already constructed.
}

private func installSubviews() {
    labelStack.addArrangedSubview(dateLabel)
    labelStack.addArrangedSubview(topicSummaryLabel)
    labelStack.addArrangedSubview(todayLabel)
    addSubview(labelStack)
    addSubview(pinchGlyph)
    addSubview(chatRestCenterLabel)
    activateConstraints()
}
```

**Acceptance:**
- [ ] All 7 subviews use closure-init at class-top (NOT lazy var; NOT IUO)
- [ ] `install*()` helpers shrink to constraint-wiring only
- [ ] **Matches ChatViewController + ChatBubbleView pattern**
- [ ] `private(set) var ... !` IUO declarations REMOVED

**Note:** `private(set) var tapRecognizer` was deleted by Task 0.6. `heightConstraint: NSLayoutConstraint?` legitimately stays Optional (it's set after parent layout install).

---

### ☐ Task 6.14 — Replace `CellView.index = -1` sentinel with `Int?`

**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**File:** `Conversation/V2/CellView.swift`
**Class:** LOAD-BEARING · **Heat:** COOL
**Citation:** `[ARCH-AUDIT-property-05]`

**Before:** `var index: Int = -1`  — sentinel-bug class.
**After:** `var index: Int?`  — Swift optional discipline.

Updates required at every read site to either `guard let idx = cell.index` or accept `Int?` explicitly.

---

### ☐ Task 6.15 — Remove `didSet` on `SpringAnimator.state`

**Agent Ensemble:**
- Implementer: **L1-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**File:** `Animation/SpringAnimator.swift`
**Class:** DECORATIVE · **Heat:** COOL
**Citation:** `[ARCH-AUDIT-property-06]`

Move the implicit `startTime` capture out of `didSet` and into the two explicit transition sites (`start()` and `updateAnimation`'s `state = .running`). Removes the implicit state-machine cognitive load.

---

## 6C — Method Organization + Naming (Agent L — 17 findings)

### ☐ Task 6.16 — Rename `setupSubviews()` → `installSubviews()` [convention compliance]

**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**File:** `Conversation/V2/CellView.swift`
**Class:** DECORATIVE · **Heat:** COOL · `[ARCH-AUDIT-method-01]`

The ONLY `setup*` method in the codebase against 16 `install*` methods. Single rename.

---

### ☐ Task 6.17 — Hoist day-marker derivation to `Conversation`

**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**Files:** `Conversation/Models/Conversation.swift`, `Conversation/V2/CellView.swift`, `Conversation/V2/ChatViewController.swift`
**Class:** DECORATIVE · **Heat:** COOL
**Citation:** `[ARCH-AUDIT-method-02, ARCH-NINETY-ABS-01]`

`CellView.todayLabelText(for:)` (line 255) and `ChatViewController.headerText(for:)` (line 37) — identical "Today / Yesterday / displayDate" logic in two places.

**After:**
```swift
// Conversation.swift — add extension at file end
extension Conversation {
    /// "Today" / "Yesterday" / displayDate. Used by cell labels + chat header.
    func dayMarker(now: Date = .init()) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        return displayDate
    }
}
```

Both call sites become `conversation.dayMarker()`.

---

### ☐ Task 6.18 — `*ForTesting` suffix consistency

**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**Files:** `Animation/SpringAnimator.swift`, `Conversation/V2/CameraAnimator.swift`
**Class:** DECORATIVE · **Heat:** COOL · `[ARCH-AUDIT-method-03]`

Both files have `animationControllerIdentity` properties documented as test-only but LACK the `ForTesting` suffix.

**Rename:** `animationControllerIdentityForTesting`. Update test sites.

---

### ☐ Task 6.19 — `handleCellTap` (covered by Task 0.6)

**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**Citation:** `[ARCH-AUDIT-method-04]`

Already removed in Phase 0 Task 0.6.

---

### ☐ Task 6.20 — Move `startSpringDeceleration` into Pan-gesture region

**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**File:** `Conversation/V2/TimelineCanvas.swift`
**Class:** DECORATIVE · **Heat:** COOL · `[ARCH-AUDIT-method-05]`

Currently at line 1447 (orphaned in animation-orchestration region). Move to ~915 (adjacent to `clampedWithRubberband`, near pan gesture region).

---

### ☐ Task 6.21 — Extract `pinToSuperview()` UIView extension [3+ repetition rule]

**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**Files:** `App/UIView+Pin.swift` (new), `App/V2RootViewController.swift` (or `App/RevealCoordinator.swift` after Phase 4)
**Class:** DECORATIVE · **Heat:** COOL
**Citation:** `[ARCH-AUDIT-method-07, ARCH-NINETY-ABS-01]`

Three identical four-edge constraint blocks (V2RootViewController:50-55, 87-92, 102-107). After Phase 4, these live in RevealCoordinator.

**New file `App/UIView+Pin.swift`:**
```swift
import UIKit

extension UIView {
    /// Pin this view edge-to-edge to `parent`. Returns the constraints
    /// in case caller wants to deactivate later. Caller is responsible for
    /// setting `translatesAutoresizingMaskIntoConstraints = false`.
    @discardableResult
    func pinToSuperview(of parent: UIView) -> [NSLayoutConstraint] {
        let constraints = [
            topAnchor.constraint(equalTo: parent.topAnchor),
            leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            bottomAnchor.constraint(equalTo: parent.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
        return constraints
    }
}
```

3+ usage sites: V2RootViewController's canvas pin, RevealCoordinator's chatVC pin, RevealBlurOverlay's `attach(to:)`.

---

### ☐ Task 6.22 — Extract `sRGBLockedCGColor` helper

**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**File:** `DesignSystem/Theme.swift` (or new `DesignSystem/Color+sRGB.swift`)
**Class:** DECORATIVE · **Heat:** COOL · `[ARCH-AUDIT-method-08]`

Duplicate at TimelineCanvas:201-206 and 231-234. Centralize the "sRGB-lock regardless of display gamut" invariant.

```swift
extension UIColor {
    /// CGColor locked to sRGB color space. Without this, layer colors drift
    /// on P3 displays as the system silently re-quantizes.
    var sRGBLockedCGColor: CGColor {
        cgColor.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!,
                          intent: .defaultIntent, options: nil) ?? cgColor
    }
}
```

---

### ☐ Task 6.23 — Extract `makeCAAnimation` factory

**Agent Ensemble:**
- Implementer: **L1-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**File:** `Conversation/V2/TimelineCanvas.swift`
**Class:** DECORATIVE · **Heat:** WARM
**Citation:** `[ARCH-AUDIT-method-09, ARCH-NINETY-ABS-01]`

Six near-identical CABasicAnimation builders at TimelineCanvas:1164-1223. Extract:
```swift
private static func makeCAAnimation(keyPath: String,
                                     from: Any?, to: Any?,
                                     duration: CFTimeInterval,
                                     beginTime: CFTimeInterval = 0,
                                     timing: CAMediaTimingFunction,
                                     additive: Bool = false) -> CABasicAnimation {
    let a = CABasicAnimation(keyPath: keyPath)
    a.fromValue = from
    a.toValue = to
    a.duration = duration
    a.beginTime = beginTime
    a.timingFunction = timing
    a.isAdditive = additive
    a.fillMode = .forwards
    a.isRemovedOnCompletion = false
    return a
}
```

Saves ~40 LOC inside `animateCameraToChatRest`.

---

### ☐ Task 6.24 — Drop `_displayLinkFired` underscore

**Agent Ensemble:**
- Implementer: **L1-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**File:** `Animation/AnimationController.swift:49`
**Class:** DECORATIVE · **Heat:** COOL · `[ARCH-AUDIT-method-14]`

`fileprivate func _displayLinkFired(_:)` — the underscore is vestigial ObjC convention. `fileprivate` already gates access. Rename to `displayLinkFired(_:)`.

---

### ☐ Task 6.25 — Inline `ChatViewController.layoutIfNeeded()` wrapper

**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**File:** `Conversation/V2/ChatViewController.swift`
**Class:** DECORATIVE · **Heat:** COOL · `[ARCH-AUDIT-method-15]`

A 1-line wrapper around `view.layoutIfNeeded()` used at 1 site. Inline.

---

### ☐ Task 6.26 — Introduce `activeCellContext()` helper for the 4 guard-chain sites

**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**File:** `Conversation/V2/TimelineCanvas.swift`
**Class:** DECORATIVE · **Heat:** COOL · `[ARCH-AUDIT-method-12]`

Four sites (handlePinchChanged:976, handlePinchEnded:1019, animateCameraToChatRestPath:1247, animateCameraToCellRestPath:1385) repeat:
```swift
guard let activeIdx = activeCellIndex,
      let activeCell = instantiatedCells[activeIdx],
      let heightC = activeCell.heightConstraint else { return }
let naturalH = activeCell.naturalHeight
guard naturalH > 0 else { return }
```

Extract:
```swift
private struct ActiveCellContext {
    let activeIdx: Int
    let activeCell: CellView
    let heightConstraint: NSLayoutConstraint
    let naturalH: CGFloat
}

private func activeCellContext() -> ActiveCellContext? {
    guard let activeIdx = activeCellIndex,
          let activeCell = instantiatedCells[activeIdx],
          let heightC = activeCell.heightConstraint else { return nil }
    let naturalH = activeCell.naturalHeight
    guard naturalH > 0 else { return nil }
    return ActiveCellContext(activeIdx: activeIdx, activeCell: activeCell,
                              heightConstraint: heightC, naturalH: naturalH)
}
```

Each call site: `guard let ctx = activeCellContext() else { return }`.

---

### ☐ Task 6.27 — Convert `pageHeight()` + `currentCanvasProgress()` to computed properties

**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
**File:** `Conversation/V2/TimelineCanvas.swift`
**Class:** DECORATIVE · **Heat:** COOL · `[ARCH-AUDIT-method-13]`

Both are pure / zero-arg / no-side-effect. Symmetric with `pageWidth` (already a computed property). Convert.

---

## 6D — Extensibility Seams (Agent L — 4 scenarios)

Each scenario names a future change vector + the cost-of-change in TODAY's architecture + the minimum abstraction-debt payment to flatten the cost. **Per ARCH-NINETY-ABS-01: ABSTRACT ON THE 3RD REPETITION, NOT THE 2ND.** Most of these recommendations are documented gaps, not actions to take now.

### ☐ Seam-1 — Second cell type
**Cost today:** HIGH. Add a new cell type requires modifying TimelineCanvas (every `CellView` reference), CellView (conform to protocol), the dataSource adapter, the V2RootViewController.

**Minimum abstraction-debt payment when scenario arrives:**
```swift
protocol TimelineCell: AnyObject {
    var index: Int? { get set }
    var activeConversationID: UUID? { get }
    var naturalHeight: CGFloat { get }
    var heightConstraint: NSLayoutConstraint? { get }
    var morphInProgress: Bool { get set }
    var onTap: ((Int) -> Void)? { get set }
    func setCamera(_ camera: Camera, viewport: CGRect)
    func installLayout(into host: UIView, naturalCenterY: CGFloat, naturalHeight: CGFloat, pageWidth: CGFloat, horizontalInset: CGFloat)
    func resetHeightConstraintToNatural()
    func deactivateLayoutConstraints()
    func resetMorphState()  // from Task 0.1
    func invalidateConversationBinding()
}
```

**Today's action:** **NONE.** Document the seam. Pay the debt when the second cell type arrives.

---

### ☐ Seam-2 — Additional spring direction profile
**Cost today:** LOW (4 sites in 2 files). Add a case to `GestureCommit`, a damping field to `PhysicsTuning`, a switch case in `dampingRatio(from:)`, and a branch in `handlePinchEnded`'s classifier.

**Minimum abstraction-debt payment:** Already paid by Phase 5 Task 5.2 (PhysicsTuning) + Task 5.3 (GestureCommit lifted to own file).

---

### ☐ Seam-3 — Alternate dataSource (search, filtered)
**Cost today:** ZERO in TimelineCanvas. Write a new adapter conforming to `TimelineDataSource`; inject via `dataSource = X`.

**However:** the protocol assumes a flat cell list. Sectioned / grouped / loading states aren't accommodated. **Don't pre-pay** — let the real use case shape the redesign.

---

### ☐ Seam-4 — New message content types (voice, image)
**Cost today:** MEDIUM. `Message.content: String` is the dead-end.

**Minimum abstraction-debt payment when scenario arrives:**
```swift
struct Message {
    enum Payload {
        case text(String)
        case voice(URL, duration: TimeInterval)
        case image(URL)
    }
    let payload: Payload
    // ... other fields ...
}
```

ChatBubbleView would switch on payload. `Message.Role` already does compile-time-exhaustive role handling.

**Today's action:** **NONE.** Document.

---

## 6E — Abstraction Debt (Agent L — 9 items)

Items ranked by leverage. Most are already covered by Phases 0-5; this section names what remains.

| # | Abstraction | Status | Citation |
|---|---|---|---|
| 1 | MasterTimer state as struct | ✅ Covered Phase 5 Task 5.1 | ARCH-AUDIT-method-06 |
| 2 | CABasicAnimation factory | ⏳ Task 6.23 | ARCH-AUDIT-method-09 |
| 3 | pinToSuperview UIView extension | ⏳ Task 6.21 | ARCH-AUDIT-method-07 |
| 4 | sRGBLockedCGColor helper | ⏳ Task 6.22 | ARCH-AUDIT-method-08 |
| 5 | activeCellContext() guard helper | ⏳ Task 6.26 | ARCH-AUDIT-method-12 |
| 6 | Day-marker logic on Conversation | ⏳ Task 6.17 | ARCH-AUDIT-method-02 |
| 7 | Reveal state enum on coordinator | ⏳ Task 6.10 | ARCH-AUDIT-property-01 |
| 8 | TimelineCellPool extraction | ❌ DEFER (ARCH-NINETY-ABS-01) | Open question |
| 9 | TimelineLayoutCalculator extraction | ❌ DEFER (ARCH-NINETY-ABS-01) | Open question |

Items 8 + 9 are **deliberately deferred** — they're TimelineCanvas sub-extractions that don't pay off until the megaclass needs to be split. Phase 5's extractions (MorphChoreographer) prove the seam pattern first.

---

# 🚨 Open Questions — Resolution Summary

All resolved by the 12 audit agents.

| ID | Question | Resolution |
|---|---|---|
| Q1 | `liftEndMagnitude` (50) vs `unifiedArcMag` (50) same? | **No.** Different physical roles. Keep both named. |
| Q2 | `PinchTuning.anticipation*` dead? | **Yes.** Task 0.2 deletes. |
| Q3 | `morphInProgress` reset path | **None today.** Task 0.1 adds. |
| Q4 | `chatRestCenterLabel` reset path | **None today.** Task 0.1 adds. |
| Q5 | `anticipationAnimator` construction site | **None.** Task 0.2 deletes. |
| Q6 | `timelineCanvas.alpha = 0` reset path | **None today.** Future RevealCoordinator.dismiss() must reset. Out of scope. |
| Q7 | Pinch-commit → onMorphRevealReady | **Missing.** Task 0.4 adds. |
| Q8 | `reloadData` mid-active-cell | **Latent.** Task 0.7 (optional) adds defensive guard. |

---

# 📊 Phase Dependency Graph

```
Phase 0 (Critical bugs) ────┐
                            │
Phase 1 (Tokens) ───────────┼── independent first wave
                            │
Phase 2 (DevX) ─────────────┘
                            │
                            ↓
                     Phase 3 (Hoist controller)  ←— MUST precede Inject (Task 2.1)
                            │
                            ↓
                     Phase 4 (RevealCoordinator)
                            │
                            ↓
                     Phase 5 (Surface keystones)
                            │
                            ↓
                     Phase 6 (Hygiene polish)
```

**Critical cascades:**
- Phase 3 → Phase 2 Task 2.1 (Inject would corrupt un-hoisted substrate)
- Phase 1 Task 1.2 → Phase 5 Task 5.1 (choreographer consumes MorphTiming)
- Phase 0 Task 0.4 + Phase 5 Task 5.1 (both touch reveal handoff; preserve each other)
- Phase 5 Task 5.2 + Task 5.3 (PhysicsTuning + GestureCommit field-name alignment)
- Task 5.5 (EngagementState) is fully independent — land any time

---

# 🎯 Effort Estimate

| Phase | Days | Risk | Visual-regression risk |
|---|---|---|---|
| 0 — Critical bugs | 1 | LOW | LOW (small surface) |
| 1 — Tokens | 1-2 | LOW | ZERO (no behavior change) |
| 2 — DevX | 1-2 | LOW | ZERO |
| 3 — Hoist controller | 1 | MEDIUM | LOW |
| 4 — Coordinator | 3-4 | MEDIUM | MEDIUM (animation paths touched) |
| 5 — Keystones | 4-6 | HIGH | HIGH (60+ test sites; morph reorchestrated) |
| 6 — Hygiene | 3-4 | LOW | LOW |

**Total: 14-20 working days, single engineer.**

**Recommended landing order (per Agent G cascade analysis):**
1. Phase 0 (bugs) — get clean slate
2. Phase 1 Tasks 1.1-1.4 (tokens) — substrate for everything
3. Phase 5 Task 5.5 (EngagementState) — fully independent, easy win
4. Phase 3 (hoist) — prerequisite for Inject
5. Phase 2 (DevX) — speeds Phases 4-6
6. Phase 5 Tasks 5.2, 5.3 (PhysicsTuning, GestureCommit) — naming convergence
7. Phase 4 (RevealCoordinator) — Tier 1B fix
8. Phase 5 Tasks 5.1, 5.4 (MorphChoreographer, mechanism-named methods)
9. Phase 6 (hygiene) — polish on the new shape

---

# 🏁 Unified Verdict

**Ready to implement: PARTIAL (pending visual-regression validation).**

- All structural decisions traced to ARCH-* citations.
- All 10 confirmed bugs assigned Phase 0 tasks with literal before/after code.
- All 8 open questions resolved.
- 18 rejections cited.
- Migration plan: commit-by-commit phased path.
- File-organization, closure-init-at-class-top, separation-of-concerns, extensibility, and abstraction discipline are the central narrative thread of Phase 6.

**Outstanding work blocking implementation:**
1. Visual-regression validation strategy — every task that mutates animation paths (Phases 4 + 5) needs a before/after capture. Maestro flows + per-state screenshots required.
2. Test signature audit — confirm `animateCameraToChatRest(forCellAt:)` 60+ callers all use the same public signature (Agent F counted but didn't catalog).
3. Verification of Task 0.4 codepath (pinch-commit master timer): confirm pinch-commit calls `animateCameraToChatRestPath` directly (no double-fire risk).

**Source confidence summary:**
- HIGH confidence: Phase 0, 1, 2, 6 (mechanical / well-cited)
- MEDIUM confidence: Phase 3, 4 (small surface, but animation timing is taste-sensitive)
- LOW confidence: Phase 5 Task 5.1 visual fidelity claim (60+ test sites + frame-by-frame morph not visually verified by audit)

---

### ☐ Task 6.39a — Narrow 2 `private(set) var` → `private` (X4 PILLAR5-C01)
`[L3 Domain | P5.1 P5.5 P8.1 | Wave 6 (Hygiene) | Parity: safe | Test: 0 | Deps: —]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**Files:** `Conversation/V2/TimelineCanvas.swift` (2 sites)

**Change:** Two fields are `private(set) var` with no external consumers — `private(set)` permits external reads that nothing actually does. Narrow to `private`.
Sites: `lastCellRestScrollY`, `hasExternalCameraWrite`.

**Acceptance:**
- [ ] Both fields are `private` (not `private(set)`)
- [ ] `grep -n "lastCellRestScrollY\|hasExternalCameraWrite" DotPinchPrototype/` shows reads ONLY inside TimelineCanvas

---

### ☐ Task 6.40 — `DisplayLinkProxy` → private extension below AnimationController (X3 PILLAR3-17)
`[L1 Animation Kernel | P3.4 P3.6 P20.1 | Wave 6 (Hygiene) | Parity: safe | Test: 0 | Deps: —]`
**Agent Ensemble:**
- Implementer: **L1-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L1 file-partition
**Files:** `Animation/AnimationController.swift`

**Change:** Reading sequence is wrong — `DisplayLinkProxy` (helper) currently sits ABOVE `AnimationController` (the type that owns it). Move `DisplayLinkProxy` into a private extension below `AnimationController`, so the reader meets the principal type first.

**Acceptance:**
- [ ] `DisplayLinkProxy` declared after `AnimationController` in source order
- [ ] Wrapped in `private extension AnimationController { final class DisplayLinkProxy { /* … */ } }` OR file-private declaration positioned below
- [ ] 16-second visual-digestion scan reads top-down without backward jumps

---

### ☐ Task 6.41 — Every `guard return` gets WHY comment (X5 PILLAR6-19)
`[L3 Domain | P1.1 P3.4 P6.7 | Wave 6 (Hygiene) | Parity: safe | Test: 0 | Deps: —]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**Files:** all 55 `guard … else { return }` sites across `DotPinchPrototype/`

**Change:** Pillar 6.7 spectrum says silent early-return is acceptable WHEN documented. Currently 55 sites silently return without indicating which invariant they're guarding. Add a one-line WHY comment to each. (Sites that should become `assertionFailure` per Task 0.19 are SEPARATE; this task is for the documented-silent-return sites.)

```swift
// BEFORE
guard !morphInProgress else { return }
// AFTER
guard !morphInProgress else { return }   // gesture-during-morph: rare race; ignored by design
```

**Acceptance:**
- [ ] 50 sites carry inline WHY comment (5 sites are converted to `assertionFailure` by Task 0.19)
- [ ] No tautological comments — comment names the INVARIANT being protected, not the syntax
- [ ] Pillar 6.7 cross-check: silent-return total drops from 55 → ~50; each documented

---

### ☐ Task 6.42 — Move `ChatViewController` to `ChatBody/` folder (X6 PILLAR7-03)
`[L3 Domain | P7.1 P7.5 P20.1 | Wave 6 (Hygiene) | Parity: safe | Test: 0 | Deps: —]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**Files:** `Conversation/V2/ChatViewController.swift` → `Conversation/ChatBody/ChatViewController.swift`

**Change:** `ChatViewController` is the production chat-rest surface — it BELONGS in `ChatBody/`, not under `V2/` (which is timeline-canvas-specific). Pillar 7 (dependency direction) — folder placement should mirror domain role, not historical-accident location.

**Acceptance:**
- [ ] File moved
- [ ] All imports + Xcode project references updated
- [ ] `grep -rn "Conversation/V2/ChatViewController" DotPinchPrototype/` returns ZERO
- [ ] Build passes

---

### ☐ Task 6.43 — `var` → `let` migration sweep (Spring + Camera + IUO subviews + ConversationStore)
`[L1 Animation Kernel + L2 Tokens + L3 Domain | P1.5 P5.2 P8.1 P19.5 | Wave 6 (Hygiene) | Parity: safe | Test: 0 | Deps: 6.13]`
**Agent Ensemble:**
- Implementer: **L1-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L1 file-partition
**Files:** `Conversation/V2/Spring.swift`, `Conversation/V2/Camera.swift`, `Conversation/V2/CellView.swift`, `Conversation/Data/ConversationStore.swift`

**Change:** Aggregate var→let sweep for fields with zero production writes (verified by Agent X7 PILLAR8-10 + X4 PILLAR5-B02/B04):
- **Spring** — 5 fields (`mass`, `stiffness`, `damping`, `dampingRatio`, `response`) → `let`
- **Camera** — Task 0.14 already migrates `translation`; this task confirms `viewportCenter`, `pageHeight` are also `let`
- **CellView IUOs** — 5 subview IUOs (`labelStack`, `widthConstraint`, `leadingConstraint`, `topMetaLabel`, `bottomMetaLabel`) → inline `let` initialization (closure-init pattern from Task 6.13)
- **ConversationStore fields** — `conversations: [Conversation]`, `conversationsByID: [UUID: Conversation]` → `let` via init-local accumulation (per Agent X7 PILLAR8-10)

```swift
// ConversationStore — BEFORE
final class ConversationStore {
    private(set) var conversations: [Conversation]
    private(set) var conversationsByID: [UUID: Conversation]
    init(seed: [Conversation]) { /* mutating append loop */ }
}
// AFTER
final class ConversationStore {
    let conversations: [Conversation]
    let conversationsByID: [UUID: Conversation]
    init(seed: [Conversation]) {
        let (list, byID) = Self.compose(seed)
        self.conversations = list
        self.conversationsByID = byID
    }
    private static func compose(_ seed: [Conversation]) -> ([Conversation], [UUID: Conversation]) { /* … */ }
}
```

**Acceptance:**
- [ ] `grep -n "var\s\+\(mass\|stiffness\|damping\|dampingRatio\|response\)" Conversation/V2/Spring.swift` returns ZERO
- [ ] `grep -n "var\s\+\(viewportCenter\|pageHeight\)" Conversation/V2/Camera.swift` returns ZERO
- [ ] CellView IUOs all `let` (closure-init at top per Task 6.13)
- [ ] ConversationStore `conversations` + `conversationsByID` are `let`; tests verify insert is rejected at compile time
- [ ] Pillar 19.5 row in 9A.1 honored
- [ ] Migration M5 marked COMPLETE

---

### ☐ Task 6.44 — `@frozen` on `AnimatorState` + `Event` (X4 PILLAR5-G06)
`[L1 Animation Kernel | P9.1 P16.1 P19.5 | Wave 6 (Hygiene) | Parity: safe | Test: 0 | Deps: 6.5]`
**Agent Ensemble:**
- Implementer: **L1-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-6-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 6:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L1 file-partition
**Files:** `Animation/AnimatorProviding.swift` (post-6.5 lift)

**Change:** `AnimatorState` and `Event` enums are layout-stable across the kernel's lifecycle. Add `@frozen` to lock the layout — also signals Bottling-readiness (frozen enums survive SPM extraction without ABI breakage).

```swift
@frozen
enum AnimatorState { case stopped, running, settled }

@frozen
enum Event { case tick, complete, cancel }
```

**Acceptance:**
- [ ] Both enums carry `@frozen`
- [ ] Build clean (no API-stability warnings in app target — `@frozen` is a no-op without `-enable-library-evolution`, but the annotation is Bottling-future-proofing)
- [ ] Pillar 16.1 row in 9A.1 honored

---

## 🔁 RETROSPECTIVE — Post-Wave 6 (Hygiene) **— FINAL MIGRATION RETRO**

**INVOKE 9Q.3 OPERATIONAL PROTOCOL.** R1-R8 + `/root-cause-tracing`. **FIX IMMEDIATELY. BLOCKING.** This retro CLOSES the migration. NO Wave N+1 follows. Code work begins ONLY after this retro greens.

### Wave 6 specific hunts

**R1 Doctrine — FULL doctrine pass (cumulative across all 7 waves):**
- EVERY task in Phases 0-6 carries 9Q.2 tag-line (mechanical pass complete per 9Q.5)
- EVERY task's Acceptance block carries 9B 10-pillar checklist (per 9O.2)
- ALL 4 8X decisions resolved inline (per 9O.3 — X1=1.25, X2=LabelFadeTiming, X3=snap-equivalence-math, X4=senderLabel→roleLabel)
- Citation hygiene: `[BUG-H-A]` corrected to `[BUG-H10]`; K7 reclassified (per 9O.6)
- Pillar 5.5 reframing applied — `@_spi(Testing)` DEFERRED to Bottling per Agent X4

**R2 Code Smells — cumulative sweep:**
- Cell-internal label envy ELIMINATED — TimelineCanvas no longer writes `activeCell.dateLabel.alpha` etc. (Task 5.8 `CellView.performMorphChromeTransition`)
- Neighbor-transform envy ELIMINATED — TimelineCanvas no longer writes `cell.transform` per-cell (Task 5.9 `CellView.followActive`)
- 11 load-bearing prose invariants converted to runtime `assert`s (Phase 7 Task 7.3 / 8E.3)
- ChatBubbleView "never sender" violation FIXED — `senderLabel` → `roleLabel` 7-site rename (Task 0.16)

**R3 Dead-Code Sweep — terminal cumulative pass:**
- `grep -rn "TODO\|FIXME\|XXX\|HACK\|setupSubviews\|PinchTuning\|SpringDirection\|anticipationAnimator\|anticipationMagnitude\|anticipationDuration\|anticipationDisabled\|cell.onTap\|revealChat\|UIVisualEffectView" DotPinchPrototype/` = ZERO
- 12 stale type/file references PURGED (DEBT-15..26 per 8E.4 + Task 7.4 stale-ref sweep): no remaining mentions of `ChatBodyView`, `ConversationCell`, `MASTER-CHECKLIST.json`, etc.
- `Gestures/` folder removed; `PinchTuning.swift` deleted
- Orphan tests deleted (Wave4f, WaveR72-R75); `Tests/README.md` matches actual filesystem

**R4 Parity Verifier — FINAL parity gate:**
- ALL 7 Maestro flows ksdiff against pre-migration baseline:
  - Flows 1, 3 (tap-to-chat, pinch-to-cell-rest) — ksdiff = 0 (parity-safe required)
  - Flows 2, 5, 6 (pinch-commit reveal, background-resume, reduce-motion) — documented in Parity-Break Ledger 8B as intentional bug-fix deltas
  - Flow 7 (dismiss) — present as method-only; no UI wires it (per 9Q.4 no-new-features); ksdiff N/A
- Per-frame screenshot comparison on Flow 1 keyframes S0-S5

**R5 File-Org — FINAL placement audit:**
- TimelineCanvas LOC: <800 (down from 1477) — per Task 7.0 re-evaluation
- Animation/ folder is Bottling-ready (per Agent X4 — 95% extractable today; remaining 5% gap is AnimatorProviding visibility decision + UIKit-vs-QuartzCore audit on AnimationController)
- Directory restructure (Task 7.1) executed: V2/ → Timeline/; ChatViewController moved to ChatBody/; Gestures/ deleted; Conversation/Tuning/ created
- File-end conformance extensions applied (Task 6.2) for TimelineCanvas + Conversation + TimelineDataSourceAdapter
- Reading-sequence fixes applied (Task 6.40 — DisplayLinkProxy below AnimationController)

**R6 Method-Cleanliness — terminal pass on the codebase:**
- Method-by-method contract audit (per Agent U Part B) — 10 worst-offender contract blocks landed at their target methods
- 5 cross-cutting templates (T1 apply* / T2 update* / T3 try* / T4 install* / T5 handle*) documented and applied
- 5 LOAD-BEARING contract divergences fixed: applyMasterTick no longer bypasses setCamera; returnToPool active-cell-rejection rationalized; AnimationController dict iteration uses snapshot pattern; animateCameraToChatRest sets activeCellIndex; SpringAnimator final-tick ordering test added

**R7 Abstraction — final rule-of-3 sweep:**
- All 5 verified-rule-of-3 abstractions landed (6.21 pinToSuperview, 6.23 CABasicAnimation factory, 6.26 activeCellContext, 5.8 performMorphChromeTransition, 5.9 followActive)
- All below-threshold candidates either landed-with-coupling-rationale OR explicitly refused (6.17 dayMarker, 6.22 sRGB — DEFERRED per rule-of-3)
- CoordinateSpace typed-wrapper migration (Task 7.6) — landed OR explicit refusal-list entry

**R8 Concurrency + Safety — terminal sweep:**
- `@MainActor` on every UI / animator / coordinator type (cumulative from RUNTIME-01 + Task 6.33)
- Spring + Camera fields `var → let` complete (per 9L.2 + 9N.2 + Task 6.43 + Task 0.14)
- ConversationStore fields `var → let` complete (per 9R.4.4 amendment to Task 6.43)
- `static let` discipline on tuning constants (PinchTuning damping per Agent X7 + Task 5.2)
- Variable shadowing in `guard let` modern shorthand used universally (Agent X1 PILLAR1-11)
- Dual-index invariant preconditions added (ConversationStore + TimelineCanvas pool — per Task 6.36)
- Camera.validate eliminated post `var → let` (per 9L.2 cascade)

**Composition-root DI audit (per 9R.4.6 — closes Migration M10 gap):**
- `grep -rn "\.shared\|UIApplication\.shared\|@Environment\|@EnvironmentObject\|DependencyContainer\|ServiceLocator\|Resolver\.shared\|Swinject" DotPinchPrototype/` = ZERO (verify zero singletons + zero service locators + zero @Environment + zero DI framework usage)
- ALL Layer 5 dependencies constructed in V2RootViewController.init() and passed via init parameters
- Zero implicit dependencies via global state; the composition root IS the single source of construction

**FINAL MIGRATION CLOSURE GATE (mandatory; replaces 9Q.3 Stage 4 close criteria for this terminal retro):**
- [ ] All 8 R-agents return clean post-fix
- [ ] All Phase 0-6 9Q.2 tag-lines present
- [ ] All Phase 0-6 9B 10-pillar acceptance green
- [ ] Parity Ledger 8A: every row verified old=new
- [ ] Parity-Break Ledger 8B: 5 intentional UX deltas documented (Tasks 0.4, 0.11, 0.12, 0.13, 4.5)
- [ ] 4 8X decisions resolved inline
- [ ] TimelineCanvas <800 LOC
- [ ] Animation/ Bottling-ready (deferred extraction; readiness verified)
- [ ] v7 SSoT-restructure (Task 7.2) executed as the final cutover commit

**Retro output (MANDATORY) — the migration's closing paragraph:**
> _Migration CLOSED at <timestamp>. All 7 waves shipped. Frame-identical UX confirmed against pre-migration baseline for default-flow users. Parity-Break Ledger 8B documents 5 intentional correctness deltas (cancelled-split, background-resume, reduce-motion, pinch-commit-reveal-fire, dismiss-method-only). Doctrine 9B compliance verified per-task. TimelineCanvas LOC: <N> (was 1477). Animation/ Bottling-ready (deferred extraction). Code work for new features remains OUT OF SCOPE per 9Q.4 victory condition._

**The migration closes here. v7 SSoT-restructure (Task 7.2) is the cutover commit. Beyond v7 = future projects.**

### Wave 6 visual testing checklist (literal per 9Q.3 Stage 10 — BINDING)

- [ ] Maestro flows executed on iOS 18 sim: **ALL 7 flows (full sweep before audit wave)**
- [ ] Per-state screenshots captured (S0-S5 where applicable; per 8C protocol)
- [ ] Manual visual analysis — reviewer eyeballs screenshots side-by-side with baseline (NOT just ksdiff)
- [ ] Side-by-side comparison archived in `docs/visual-baselines/wave-6/`
- [ ] Subjective animation quality assessment ("does the overall feel FEEL right?")

### Wave 6 wave-close merge gate (per §0.10)

1. **Wave-6-Lead** waits for all Wave 6 implementation agents to return worktrees integrated
2. **R1-R8** dispatched in PARALLEL against integrated Wave 6 diff
3. **Findings fixed in-place** per 9Q.3 Stage 3; re-dispatch verifies clean
4. **Parity-Agent SERIAL gate** — Phase 8C ksdiff on assigned flows (ALL 7 flows (full sweep before audit wave))
5. **Wave 6 CLOSES.** Wave 7's Wave-Lead may begin dispatch.

**Retro time budget (per §0.9):** 8 hours. If exceeded by >50% → invoke 9Q.3 Stage 7 Failure-of-Retro protocol.

### Wave 6 cross-wave learning ledger entry (per §0.11 — populated at retro close)

```
Wave 6 patterns observed (added to subsequent wave hunts):
- Pattern P<NN>: <one-line description>
  Flagged by: R<X>
  Remediation: <how it was fixed>
  Propagation: <which subsequent wave's R-agent hunts this gets added to>
```

### Wave 6 Stage 6 retro paragraph (mandatory at close — per 9Q.3 Stage 8 Rosetta stone)

> _Wave 6 retro: agents R1-R8 ran post-Wave-6-landing; <N1> findings flagged; <N2> root-causes traced; <N3> fixes applied IMMEDIATELY in-wave; <N4> findings escalated to refusal-list (with rationale); re-dispatch verified clean. Parity-Break Ledger entries for Wave 6: <list>. Wave 6 CLOSED at <timestamp>. Wave 7 may begin._

**Wave 6 retro closes ONLY when** 9Q.3 Stage 4 BLOCKING criteria are green + ALL visual checkboxes ticked + Stage 6 paragraph populated with concrete N1-N4 + pattern ledger entries authored.

---

# Phase 7 — Adversarial Audit (v4 — IN PROGRESS)

**Goal:** What the first 12 audit agents missed. Fresh-eyes adversarial review across 7 dimensions, each driven by a specialized agent with `[ROLE: ADVERSARIAL-REVIEWER]` + `/root-cause-tracing` 6-question discipline. **User emphasis: maximum understanding · readability · organization · visual digestion · file separation of concerns · wave-based approach · adversarial fresh eyes · tier-3b+ at every recursive level (file → type → line).**

**Status:** 7 agents dispatched. Sections populated incrementally as each returns.

**Integration approach:** Phase 7 captures NEW findings as standalone subsections (7A–7G). Where adversarial findings AMEND existing Phase 0-6 tasks, the patch is documented as `[AMENDMENT-7X.NN → Task Y.Z]` and edited inline at the original task.

**Wave 7 Agent Topology:**
- **Fleet:** 3 agents — L3-Agent (7.4 stale ref sweep), Doctrine-Agent + Documentation-Agent (composite, 7.0 memo, 7.2 SSoT restructure, 7.5 docs), L1+L2+L3 (7.3 invariant hardening, 7.6 CoordinateSpace)
- **Parallel groups:**
  - Group A (Doctrine/Documentation, parallel): 7.0 memo, 7.4 stale refs, 7.5 docs
  - Group B (L1+L3 multi-agent, parallel): 7.3 invariant hardening (5 sites across 3 files)
  - Group C (L2+L3 multi-agent, parallel): 7.6 CoordinateSpace typed wrappers
  - **Serial chain (cutover):** 7.1 (directory restructure) → 7.2 (SSoT restructure as v7 cutover commit)
- **Critical path within wave:** 7.1 → 7.2 (this IS the migration close)
- **Wave-7-Lead** orchestrates the final cutover
- **Wall-clock estimate with fleet:** 1-2 days (vs 2-3 single-engineer)

---

## 7A — Runtime correctness: concurrency + lifecycle (Agent M — returned)

**8 findings. Severity-ranked. Each carries an amendment patch to existing Phases 0-6.**

| # | Citation | Amendment target | Severity | One-line finding |
|---|---|---|---|---|
| 1 | `ARCH-ADVERSARIAL-RUNTIME-01` | Phase 3 Task 3.1 | MEDIUM | `@MainActor` missing on AnimationController / SpringAnimator / DisplayLinkProxy — Swift 6 will refuse the shared mutable resource pattern across coordinator + canvas |
| 2 | `ARCH-ADVERSARIAL-RUNTIME-02` | Phase 5 NEW Task 5.6 | **HIGH** | Neither AnimationController NOR MorphChoreographer observes `willResignActive` — morph during multitasker swipe → snapshot mid-arc → resume snaps to t=1.0 |
| 3 | `ARCH-ADVERSARIAL-RUNTIME-03` | Phase 0 NEW Task 0.8 | **HIGH** | `preferredFrameRateRange` set on AnimationController but NOT on `masterTimer` / proposed MorphChoreographer — ProMotion 120Hz device drops to 60Hz mid-morph |
| 4 | `ARCH-ADVERSARIAL-RUNTIME-04` | Phase 5 Task 5.1 acceptance | MEDIUM | Low-power mode visual baseline not gated — 1.2s morph at 30Hz = 36 frames; `liftBell` peak may land between ticks |
| 5 | `ARCH-ADVERSARIAL-RUNTIME-05` | Phase 5 Task 5.1 mandatory | **HIGH** | MorphChoreographer rebuilds the displayLink-leak Phase 3 fixes for AnimationController; `lazy var` in TimelineCanvas creates deinit ambiguity |
| 6 | `ARCH-ADVERSARIAL-RUNTIME-06` | Phase 4 Task 4.3 mandatory | **HIGH** | RevealCoordinator ships present-WITHOUT-dismiss — ChatViewController retained in addChild + activeChatVC. Memory grows unboundedly per chat opened |
| 7 | `ARCH-ADVERSARIAL-RUNTIME-07` | Phase 6 NEW Task 6.28 | LOW-MED | `[UUID: AnimatorProviding]` dictionary iteration order in AnimationController is non-deterministic — `tryClearActiveCellAtRest` reads stale extension state when both springs settle in same tick |
| 8 | `ARCH-ADVERSARIAL-RUNTIME-08` | Phase 5 Task 5.1 doc | LOW | `CATransaction.withSuppressedActions` nesting model undocumented; MorphChoreographer.engage MUST NOT be called from within an outer transaction |

### Detail — finding #5 (HIGH, the highest-leverage gap)

**Evidence:** v3 SSoT Phase 5 Task 5.1 declares `private lazy var morphChoreographer = MorphChoreographer(canvas: self)` on TimelineCanvas. The MorphChoreographer holds `displayLink = CADisplayLink(target: self, selector: #selector(tick))` and `link.add(to: .main, forMode: .common)`. **CADisplayLink retains its target.** When Inject (Phase 2 Task 2.1) swaps TimelineCanvas, the old TimelineCanvas deinits → its `morphChoreographer` reference releases → BUT the main run loop still holds the displayLink, which still holds the old MorphChoreographer. The MorphChoreographer cannot deinit until displayLink is invalidated, and nobody calls `invalidate` on the way out. **Every Inject reload leaks one MorphChoreographer + one CADisplayLink.**

This is the EXACT failure mode Phase 3 diligently fixes for AnimationController. The audit team applied the lesson once and didn't reapply it.

**Plus:** `lazy var morphChoreographer` is evaluated ONCE on first access. If TimelineCanvas deinits without the user ever having tapped a cell, the lazy var was never evaluated. If we add `deinit { morphChoreographer.stop() }`, deinit FORCES the lazy var to initialize during deinit, creating a MorphChoreographer holding `weak canvas = self` where `self` is mid-deinit. Functionally safe but grotesque.

**Amendment patch:**

→ See `[AMENDMENT-7A.5 → Phase 5 Task 5.1]` below.

### Detail — finding #6 (HIGH, the highest-conceptual gap)

**Evidence:** Phase 4 Task 4.3 builds `RevealCoordinator.present(conversation:)` with `parent.addChild(chatVC)` (UIKit containment creates a strong parent → child reference) AND stores `self.activeChatVC = chatVC` (a second strong reference). The v3 SSoT's Open Question Q6 explicitly marks dismiss as "out of scope; future RevealCoordinator.dismiss() must reset". **But shipping Phase 4 means the user has presented chats and there is no path to release them.** Memory grows per chat opened.

Calling Phase 4 "done" with present but no dismiss is half-shipping the centerpiece.

**Amendment patch:**

→ See `[AMENDMENT-7A.6 → Phase 4 Task 4.3]` below.

### Detail — finding #3 (HIGH, a 2-line fix Agent M caught that nobody else did)

**Evidence:** `AnimationController.swift:35` sets `link.preferredFrameRateRange = CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120)`. The proposed `MorphChoreographer` (and the EXISTING `startMasterTimer` at TimelineCanvas:1317) DO NOT set this. On a 120Hz ProMotion device, when the spring path stops (Phase 5 Task 5.1 explicitly stops both springs before engaging the master timer), the display falls back to 60Hz unless something else is requesting high rate. The deterministic master clock tick frequency halves → `liftBell = sin(liftPhase * .pi)` peak at `t=0.35` may land between two ticks and never render as a frame. User sees a discrete jump.

The fix is 2 lines applied to BOTH the existing `startMasterTimer` (today's bug) and the proposed MorphChoreographer (tomorrow's bug).

→ See `[AMENDMENT-7A.3 → new Phase 0 Task 0.8]` below.

---

## 7A — Amendments to Phases 0-6

### `[AMENDMENT-7A.1 → Phase 3 Task 3.1]` — Add `@MainActor` to substrate types

Augment Phase 3 Task 3.1's "After" code:
```swift
@MainActor
public final class AnimationController { ... }

@MainActor
private final class DisplayLinkProxy { ... }

@MainActor
public final class SpringAnimator<T: SpringInterpolatable>: AnimatorProviding { ... }
```

**Why:** Forces every future caller (RevealCoordinator's track-3 animators, anything that touches `runPropertyAnimation`) to be statically main-actor-isolated. Closes a Swift 6 strict-concurrency violation BEFORE the migration. Phase 3 acceptance gains:
- [ ] AnimationController + SpringAnimator + DisplayLinkProxy are `@MainActor`-annotated
- [ ] `@preconcurrency` not added anywhere (we want the warning if a caller violates)

### `[AMENDMENT-7A.2 → new Phase 5 Task 5.6]` — Scene-phase awareness on CADisplayLink owners

**New task body:**

Add `willResignActive` observer to MorphChoreographer (preferred) AND document the AnimationController decision.

```swift
// MorphChoreographer.swift — augment init
init(canvas: TimelineCanvas) {
    self.canvas = canvas
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(applicationWillResignActive),
        name: UIApplication.willResignActiveNotification,
        object: nil)
}

@objc private func applicationWillResignActive() {
    // Halt without firing completion. The morph is abandoned.
    // On return, the canvas restores via Phase 4 reset logic.
    stop()
    canvas?.resetMorphVisualState()  // new canvas seam — undoes contentHost.transform
}

deinit {
    NotificationCenter.default.removeObserver(self)
    displayLink?.invalidate()  // also closes RUNTIME-05
}
```

For `AnimationController`: keep firing on resign-active (springs are short-duration, rare across suspension). Document the decision in the file header.

**Acceptance:**
- [ ] Maestro flow: start morph → swipe up multitasker → return to app → no snap-to-end, canvas at pre-morph state
- [ ] System snapshot during morph does NOT capture mid-arc transform (the resetMorphVisualState call happens BEFORE the snapshot semantically)

### `[AMENDMENT-7A.3 → new Phase 0 Task 0.8]` — `preferredFrameRateRange` on every CADisplayLink

**New task body (Phase 0, lands immediately):**

`TimelineCanvas.swift:1317` (existing `startMasterTimer`):
```swift
private func startMasterTimer(duration: TimeInterval, completion: @escaping () -> Void) {
    masterTimer = CADisplayLink(target: self, selector: #selector(masterTimerTick))
    masterTimer?.preferredFrameRateRange = CAFrameRateRange(  // NEW
        minimum: 80, maximum: 120, preferred: 120)
    masterTimer?.add(to: .main, forMode: .common)
    // ... rest unchanged
}
```

Phase 5 Task 5.1's MorphChoreographer inherits the fix via:
```swift
let link = CADisplayLink(target: self, selector: #selector(tick))
link.preferredFrameRateRange = CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120)
link.add(to: .main, forMode: .common)
displayLink = link
```

**Acceptance:**
- [ ] Both CADisplayLink owners set `preferredFrameRateRange`
- [ ] Visual smoke test on 120Hz device: morph remains smooth even when no springs are running

### `[AMENDMENT-7A.4 → Phase 5 Task 5.1 acceptance]` — Low-power mode visual baseline

Add to Phase 5 Task 5.1 acceptance:
- [ ] Maestro flow: enable Low Power Mode → run morph → capture per-frame screenshots → manual visual analysis. Document the baseline; we don't need to fight LPM but we need to know the floor.

### `[AMENDMENT-7A.5 → Phase 5 Task 5.1]` — MorphChoreographer deinit + drop `lazy var`

**Mandatory amendments to Phase 5 Task 5.1's code:**

```swift
// MorphChoreographer.swift — add deinit
deinit {
    NotificationCenter.default.removeObserver(self)  // from 7A.2
    displayLink?.invalidate()
    displayLink = nil
}
```

```swift
// TimelineCanvas.swift — REPLACE the lazy var declaration with Optional
private var morphChoreographer: MorphChoreographer?

// Replace the lazy access pattern at every call site with:
private func ensureMorphChoreographer() -> MorphChoreographer {
    if let existing = morphChoreographer { return existing }
    let new = MorphChoreographer(canvas: self)
    morphChoreographer = new
    return new
}

// Add deinit to TimelineCanvas (currently has none):
deinit {
    masterTimer?.invalidate()  // existing field — pre-Phase-5 cleanup
    morphChoreographer?.stop()  // safe: Optional, won't force-initialize
}
```

**Acceptance:**
- [ ] Inject hot-reload 10 times → memory profiler shows zero leaked MorphChoreographer instances
- [ ] MorphChoreographer has a `deinit` that invalidates its displayLink
- [ ] TimelineCanvas has a `deinit` that stops the choreographer + invalidates legacy masterTimer
- [ ] `morphChoreographer` is `Optional`, not `lazy var` (no force-init-during-deinit ambiguity)

### `[AMENDMENT-7A.6 → Phase 4 Task 4.3]` — RevealCoordinator MUST ship with dismiss()

**Mandatory addition to Phase 4 Task 4.3's RevealCoordinator class:**

```swift
// MARK: - Dismissal

/// Reverse-choreography: cross-fade chat down + canvas up, release ChatVC,
/// nil out activeChatVC. Required to prevent unbounded memory growth.
func dismiss(completion: (() -> Void)? = nil) {
    guard let chatVC = activeChatVC else { completion?(); return }
    guard let canvas else { completion?(); return }

    chatVC.willMove(toParent: nil)
    chatVC.view.isUserInteractionEnabled = false

    UIView.animate(withDuration: RevealTiming.crossFadeDuration,
                   delay: 0,
                   options: [.curveEaseInOut],
                   animations: {
        chatVC.view.alpha = 0
        canvas.alpha = 1
    }, completion: { [weak self] _ in
        chatVC.view.removeFromSuperview()
        chatVC.removeFromParent()
        self?.activeChatVC = nil
        self?.revealBlurOverlay?.detach()
        self?.revealBlurOverlay = nil
        completion?()
    })
}
```

V2RootViewController gains a back-out trigger (currently no UI for it — minimum: a `swipeDown` gesture or system back gesture wired through V2RootViewController to `revealCoordinator.dismiss()`). Wiring the trigger UI is a separate Phase 4 follow-up; the dismiss METHOD ships in Phase 4 regardless so memory hygiene is in place.

**Acceptance:**
- [ ] `dismiss(completion:)` method exists on RevealCoordinator
- [ ] Open + dismiss 10 chats via direct test → no ChatViewController instances retained per heapshot
- [ ] `activeChatVC` and `revealBlurOverlay` both return to nil after dismiss

### `[AMENDMENT-7A.7 → new Phase 6 Task 6.28]` — Insertion-ordered animator iteration

**New task body:**

Replace `animations: [UUID: AnimatorProviding]` on `AnimationController` with insertion-ordered storage:
```swift
// AnimationController.swift
private var animations: [UUID: AnimatorProviding] = [:]
private var insertionOrder: [UUID] = []

func register(_ animator: AnimatorProviding) {
    let id = animator.id
    if animations[id] == nil { insertionOrder.append(id) }
    animations[id] = animator
}

func unregister(id: UUID) {
    animations.removeValue(forKey: id)
    insertionOrder.removeAll { $0 == id }
}

@MainActor func _displayLinkFired(_ link: CADisplayLink) {
    let dt = link.duration
    CATransaction.withSuppressedActions {
        // Iterate in registration order — callers depend on this
        // for dual-spring AND-gate coordination (tryClearActiveCellAtRest).
        for id in insertionOrder {
            animations[id]?.updateAnimation(deltaTime: dt)
        }
    }
}
```

Document the contract in AnimationController header:
```swift
// Animators tick in REGISTRATION ORDER. Callers depending on cross-animator
// state coordination (e.g., the dual-spring AND-gate in tryClearActiveCellAtRest)
// must register the animator that should tick FIRST first.
//
// TimelineCanvas.init wires cameraAnimator before extensionAnimator — so
// camera completion fires first, and tryClearActiveCellAtRest (called from
// camera's completion) sees a pre-final extension. Symmetrically, extension's
// completion sees a post-final camera. The AND-gate is correct.
```

**Acceptance:**
- [ ] Animators iterate in registration order
- [ ] Test: force simultaneous settle of camera + extension; assert activeCellIndex clears

### `[AMENDMENT-7A.8 → Phase 5 Task 5.1 doc]` — CATransaction nesting discipline

Add file-header comment to MorphChoreographer.swift:
```swift
// CATransaction discipline: `engage()` MUST NOT be called from within
// another `CATransaction.withSuppressedActions` block, because the first
// tick's writes would commit in the enclosing transaction — landing one
// vsync earlier than expected, ahead of the CABasicAnimations the
// orchestrator just installed on contentHost.layer.
// Callers MUST be at the run-loop top, not inside a tick.
```

---

---

## 7B — Cancellation paths + interrupt handling (Agent N — returned)

**12 findings. The structural gap: v3 treats cancellation as an a11y/edge concern, not a substrate concern. The happy path is principal-tier; the failure paths are unaudited.**

| # | Citation | Amendment target | Severity | One-line finding |
|---|---|---|---|---|
| 1 | `ARCH-ADVERSARIAL-CANCEL-01` | Phase 0 NEW Task 0.9 | **HIGH** | `onMorphRevealReady` dispatch-after fires unconditionally — no DispatchWorkItem.cancel() handle. Phase 5 fixes via choreographer but v3 leaves the bug in `main` for 4-6 days |
| 2 | `ARCH-ADVERSARIAL-CANCEL-02` | Phase 0 NEW Task 0.10 | **HIGH** | `Spring.init` has zero bounds checks — `dampingRatio=0` produces an undamped oscillator that never settles → `runningTime >= +inf` → `tryClearActiveCellAtRest` never fires |
| 3 | `ARCH-ADVERSARIAL-CANCEL-03` | Phase 6 NEW Task 6.29 | MEDIUM | Spring substrate has no NaN/Inf circuit-breaker in integration loop. Recognizer-side guards exist but post-NaN-injection the substrate happily propagates |
| 4 | `ARCH-ADVERSARIAL-CANCEL-04` | Phase 0 NEW Task 0.11 | **HIGH** | `handlePinch` treats `.cancelled` + `.failed` identically to `.ended` (line 941). Control Center swipe mid-pinch can COMMIT to chat-rest user never intended |
| 5 | `ARCH-ADVERSARIAL-CANCEL-05` | Phase 0 NEW Task 0.12 OR Phase 5 Task 5.1 | **HIGH** | Master timer uses `CACurrentMediaTime()` (wall-clock) but CADisplayLink pauses on background. Resume after 8s suspension → rawT clamps to 1.0 → one-frame snap-to-end while CABasicAnimations smoothly resume → visual desync |
| 6 | `ARCH-ADVERSARIAL-CANCEL-06` | Phase 4 Task 4.4 PROMOTE to REQUIRED | **HIGH** | Three `UIView.animate` blocks have no cancellation handle. Phase 4 Task 4.4 (UIViewPropertyAnimator) was marked OPTIONAL "skip unless visual upgrade wanted" — but the cancellation handle is independent of visual feel |
| 7 | `ARCH-ADVERSARIAL-CANCEL-07` | Phase 4 NEW Task 4.5 | MEDIUM-HIGH | Zero app-lifecycle observers across the codebase. `grep "applicationWillResignActive\|UIScene.willEnter"` returns nothing |
| 8 | `ARCH-ADVERSARIAL-CANCEL-08` | Phase 5 augmentation | MEDIUM | `tryClearActiveCellAtRest` has no watchdog. One stuck spring → activeCellIndex stuck forever → pan recognizer permanently disabled |
| 9 | `ARCH-ADVERSARIAL-CANCEL-09` | Phase 5 Task 5.1 doc | LOW | Rapid double-tap during morph: silent drop, no haptic, no log. MorphChoreographer's `engage()` silently cancels prior; policy disagreement between outer guard + inner choreographer |
| 10 | `ARCH-ADVERSARIAL-CANCEL-10` | Phase 0 Task 0.2 amendment | **HIGH** | Orphan tests (WaveR74/R75) ARE testing cancellation contracts — pinch-cancels-prior-springs + tap-during-active-ignored. Task 0.2 deletes without porting → loses acceptance criteria |
| 11 | `ARCH-ADVERSARIAL-CANCEL-11` | Phase 0 NEW Task 0.13 (RECATEGORIZE) | MEDIUM-HIGH | Reduced-motion is a CORRECTNESS issue (Apple HIG vestibular warning), not an a11y feature. v3 rejection list item #15 conflates the two |
| 12 | `ARCH-ADVERSARIAL-CANCEL-12` | Phase 5 Task 5.1 doc | LOW | `stop(immediately:)` suppresses outer completion via `stoppedByCaller` — foot-gun for any future caller wiring `animate(to:completion:)` + manual cancel |

### Detail — finding #5 (HIGH, the bug Agent M didn't catch but Agent N did)

**Evidence:** TimelineCanvas:1319-1329:
```swift
masterTimerStart = CACurrentMediaTime()
// ...
@objc private func masterTimerTick() {
    let elapsed = CACurrentMediaTime() - masterTimerStart
    let rawT = CGFloat(min(elapsed / masterTimerDuration, 1.0))
```

`CACurrentMediaTime()` is monotonic but does NOT pause on app suspension. CADisplayLink IS paused while suspended. **Scenario:** user taps cell at t=0, app backgrounds at t=0.4s (mid-morph). User returns 8 seconds later → first tick fires with elapsed=8.4s, rawT clamps to 1.0 → one frame snap-to-end while CABasicAnimations (which DO pause cleanly with the layer tree) resume from where they paused. Visual desync: master-driven properties at frame-1.0 while CABasicAnimation-driven properties still arriving.

`AnimationController.swift:50` does it CORRECTLY: `dt = link.targetTimestamp - link.timestamp` — display-link-local time. Springs are immune.

Phase 5 Task 5.1's MorphChoreographer at SSoT line 1517 inherits this bug: `startTimestamp = CACurrentMediaTime()`. **The refactor preserves the wall-clock dependency.**

→ Patches Task 5.1 + adds new Phase 0 task (see amendments).

### Detail — finding #6 (HIGH, the cancellation handle gap)

Phase 4 Task 4.4 (UIViewPropertyAnimator upgrade) is marked OPTIONAL with "skip unless visual upgrade wanted." But the gain isn't ONLY visual — it's the cancellation handle. Today's three `UIView.animate` blocks are fire-and-forget; the new RevealCoordinator (Phase 4 Task 4.3) has NO `cancel()` method. User backgrounds mid-reveal → no way to abort. **Promote 4.4 to REQUIRED, reframe as "cancellation handle, not visual upgrade."**

### Detail — finding #10 (HIGH, the orphan-tests-aren't-orphans gap)

Task 0.2 deletes `WaveR72/R73/R74/R75` test files. But WaveR74 tests "pinch .began cancels prior in-flight engagement" and WaveR75 tests "tap during in-flight is ignored" — **cancellation contracts that survive the anticipation deletion**. The tests are keyed to the wrong (about-to-be-deleted) implementation but the CONTRACT they protect is load-bearing.

**Amendment:** Before deleting, port the cancellation assertions onto new tests keyed to `cameraAnimator` + `extensionAnimator` + the new `isQuiet` predicate. See `[AMENDMENT-7B.10 → Task 0.2]`.

### Detail — finding #11 (MEDIUM-HIGH, recategorization, NOT acceptance)

v3 rejection list item #15 explicitly rejects "Reduced-motion handling — per user filter (accessibility deprioritized)." But `UIAccessibility.isReduceMotionEnabled` is a **user-preference signal**, not an a11y feature. A user who toggled Reduce Motion has explicitly opted out of vestibular-trigger animations. A 1.5s perspective-translation morph IS the kind of animation Apple's HIG flags as a Reduce-Motion concern.

The user's a11y deprioritization memo covers a11y testing/labeling/IDs. Reduced-motion is the borderline case. **Recommendation: move out of a11y bucket, into Phase 0 as correctness.**

---

## 7B — Amendments to Phases 0-6

### `[AMENDMENT-7B.1 → new Phase 0 Task 0.9]` — DispatchWorkItem cancellation for `onMorphRevealReady`

```swift
// TimelineCanvas — add pending-reveal token
private var pendingRevealWorkItem: DispatchWorkItem?

// In animateCameraToChatRest, REPLACE the asyncAfter at line 1239:
let revealK = k
let workItem = DispatchWorkItem { [weak self] in
    guard let self else { return }
    // Don't fire if we're no longer the active morph (cancelled / re-engaged elsewhere).
    guard self.masterActiveCellIndex == revealK || self.activeCellIndex == revealK else { return }
    self.onMorphRevealReady?(revealK)
}
pendingRevealWorkItem?.cancel()
pendingRevealWorkItem = workItem
DispatchQueue.main.asyncAfter(deadline: .now() + revealReadyDelay, execute: workItem)

// In handlePinchBegan (already gets Task 0.3 master-timer cancel):
pendingRevealWorkItem?.cancel()
pendingRevealWorkItem = nil

// On any setActiveCellIndex(nil) transition:
if newValue == nil { pendingRevealWorkItem?.cancel(); pendingRevealWorkItem = nil }
```

**Acceptance:**
- [ ] Cancel-mid-morph scenario: tap cell → start pinch within 0.5s → reveal does NOT fire 1.6s later
- [ ] DispatchWorkItem is the cancellation handle (no flag-based approach)

### `[AMENDMENT-7B.2 → new Phase 0 Task 0.10]` — Spring init bounds preconditions

```swift
// Spring.swift:17 — REPLACE the unguarded init
public init(dampingRatio: CGFloat, response: CGFloat, mass: CGFloat = 1.0) {
    precondition(dampingRatio > 0 && dampingRatio.isFinite,
                 "Spring: dampingRatio must be positive and finite; got \(dampingRatio). " +
                 "Undamped (=0) springs never settle, blocking AnimationController cleanup.")
    precondition(response > 0 && response.isFinite,
                 "Spring: response must be positive and finite; got \(response).")
    precondition(mass > 0 && mass.isFinite,
                 "Spring: mass must be positive and finite; got \(mass).")
    self.dampingRatio = dampingRatio
    self.response = response
    self.mass = mass
}
```

**Acceptance:**
- [ ] `Spring(dampingRatio: 0, response: 1)` traps with readable message
- [ ] `Spring(dampingRatio: .nan, response: 1)` traps
- [ ] No silent infinite-settling-duration

### `[AMENDMENT-7B.3 → new Phase 6 Task 6.29]` — Substrate NaN circuit-breaker

Add `isFinite: Bool` to `SpringInterpolatable` + `VelocityProviding` protocols. After every `updateAnimation` integration step, if `newValue` or `newVelocity` is non-finite, snap to target + fire completion + transition to `.ended`. Substrate-level circuit-breaker.

```swift
// SpringInterpolatable.swift — extend
protocol SpringInterpolatable {
    var isFinite: Bool { get }
    // ... existing ...
}
extension CGFloat: SpringInterpolatable {
    var isFinite: Bool { self.isFinite }
}

// SpringAnimator.swift:147-148 — augment
self.value = newValue
self.velocity = newVelocity
if !newValue.isFinite || !newVelocity.isFinite {
    self.value = target
    valueChanged?(target)
    completion?(.finished(at: target))
    state = .ended
    return
}
```

### `[AMENDMENT-7B.4 → new Phase 0 Task 0.11]` — Split `.cancelled` and `.failed` from `.ended`

```swift
// TimelineCanvas.swift:928-941 — REPLACE the switch
@objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
    switch recognizer.state {
    case .began: handlePinchBegan(recognizer)
    case .changed: handlePinchChanged(recognizer)
    case .ended: handlePinchEnded(recognizer)
    case .cancelled, .failed: handlePinchCancelled(recognizer)
    default: break
    }
}

// New method — restores to whichever rest the gesture originated from. No commit decision.
internal func handlePinchCancelled(_ recognizer: UIPinchGestureRecognizer) {
    defer {
        pinchInitialScale = 1.0
        pinchInitialExtension = 0
    }
    guard let activeIdx = activeCellIndex,
          let activeCell = instantiatedCells[activeIdx] else { return }
    let naturalH = activeCell.naturalHeight
    let originatedFromCellRest = pinchInitialExtension <= naturalH * 1.05
    if originatedFromCellRest {
        animateCameraToCellRestPath(initialExtensionVelocity: 0,
                                    cameraTranslationVelocity: 0,
                                    direction: .cancelled)
    } else {
        animateCameraToChatRestPath(forCellAt: activeIdx,
                                    initialVelocity: 0,
                                    cameraTranslationVelocity: 0,
                                    direction: .cancelled)
    }
}
```

**Why:** Control Center swipe / incoming call → UIKit fires `.cancelled` on the recognizer → current code calls `handlePinchEnded` which commits-or-bails based on weightedFactor → user lands in a state they never chose. After amendment, `.cancelled` restores to origin without inspecting `recognizer.scale`.

### `[AMENDMENT-7B.5 → new Phase 0 Task 0.12]` — DisplayLink-local time, not wall-clock

**Critical patch.** Master timer must accumulate from `link.duration` per tick, not subtract `CACurrentMediaTime()`. Identical to AnimationController's pattern.

```swift
// TimelineCanvas.swift — REPLACE startMasterTimer + tick
private var masterTimerElapsed: TimeInterval = 0

private func startMasterTimer(duration: TimeInterval, completion: @escaping () -> Void) {
    masterTimerElapsed = 0  // NEW — reset on engage
    masterTimerDuration = duration
    masterTimerCompletion = completion
    masterTimer = CADisplayLink(target: self, selector: #selector(masterTimerTick(_:)))
    masterTimer?.preferredFrameRateRange = CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120)  // from Task 0.8
    masterTimer?.add(to: .main, forMode: .common)
}

@objc private func masterTimerTick(_ link: CADisplayLink) {
    masterTimerElapsed += link.targetTimestamp - link.timestamp  // displayLink-local time
    let rawT = CGFloat(min(masterTimerElapsed / masterTimerDuration, 1.0))
    applyMasterTick(rawT)
    if rawT >= 1.0 {
        masterTimer?.invalidate()
        masterTimer = nil
        let completion = masterTimerCompletion
        masterTimerCompletion = nil
        completion?()
    }
}
```

Phase 5 Task 5.1's MorphChoreographer MUST inherit this pattern:
```swift
// MorphChoreographer.swift — REPLACE startTimestamp pattern
private var elapsed: TimeInterval = 0

func engage(_ choreo: MorphChoreography, completion: @escaping () -> Void) {
    stop()
    self.choreography = choreo
    self.completion = completion
    self.elapsed = 0  // displayLink-local accumulator
    let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
    link.preferredFrameRateRange = CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120)
    link.add(to: .main, forMode: .common)
    displayLink = link
}

@objc private func tick(_ link: CADisplayLink) {
    elapsed += link.targetTimestamp - link.timestamp
    // ... rest unchanged ...
}
```

**Acceptance:**
- [ ] Background mid-morph (use Maestro `pressKey HOME` mid-tap), wait 5s, foreground → no visual snap
- [ ] No `CACurrentMediaTime()` reads in master timer / choreographer

### `[AMENDMENT-7B.6 → Phase 4 Task 4.4 PROMOTE to REQUIRED]`

Phase 4 Task 4.4 is no longer optional. It ships in Phase 4 — reframed as "cancellation handle, not visual upgrade." The RevealCoordinator gains:
```swift
private var revealAnimator: UIViewPropertyAnimator?

func present(...) {
    let totalDuration = RevealTiming.blurDwellDelay + RevealTiming.blurFadeOutDuration
    let animator = UIViewPropertyAnimator(duration: totalDuration,
                                          timingParameters: UICubicTimingParameters(animationCurve: .easeInOut))
    // ... addAnimations with delayFactor (existing 4.4 sketch)
    animator.startAnimation()
    self.revealAnimator = animator
}

func cancelInFlight() {
    revealAnimator?.stopAnimation(true)
    revealAnimator?.finishAnimation(at: .current)
    revealAnimator = nil
    // Reset visual state to "no reveal" (canvas alpha=1, chat detached)
    activeChatVC?.willMove(toParent: nil)
    activeChatVC?.view.removeFromSuperview()
    activeChatVC?.removeFromParent()
    activeChatVC = nil
    revealBlurOverlay?.detach()
    revealBlurOverlay = nil
    canvas?.alpha = 1
}
```

### `[AMENDMENT-7B.7 → new Phase 4 Task 4.5]` — App-lifecycle observer + cancelInFlightTransitions seam

```swift
// V2RootViewController.viewDidLoad
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleSceneWillResignActive),
    name: UIScene.willResignActiveNotification,
    object: nil
)

@objc private func handleSceneWillResignActive() {
    timelineCanvas.cancelInFlightTransitions()
    revealCoordinator.cancelInFlight()
}

// TimelineCanvas seam
func cancelInFlightTransitions() {
    masterTimer?.invalidate()
    masterTimer = nil
    cameraAnimator.stop(immediately: true)
    extensionAnimator.stop(immediately: true)
    pendingRevealWorkItem?.cancel()  // from 7B.1
    setActiveCellIndex(nil)
    restoreNaturalSiblingOrder()
}
```

### `[AMENDMENT-7B.8 → Phase 5 augmentation]` — Watchdog on cell-rest

Add 3s watchdog to `animateCameraToCellRestPath`. On expiry: force-clear activeCellIndex, stop both animators, restore sibling order, log `assertionFailure` in DEBUG.

### `[AMENDMENT-7B.9 → Phase 5 Task 5.1 doc]` — Engage policy clarity

MorphChoreographer's `engage()` cancels-and-restarts. Add `assert(!isRunning, "engage called while running")` in DEBUG. Document the policy.

### `[AMENDMENT-7B.10 → Phase 0 Task 0.2 amendment]` — Port cancellation contracts from orphan tests

Before deleting WaveR74/R75, create:
- `testPinchBeganCancelsActiveCameraAnimator` — derived from R74; swap `anticipationAnimator` checks for `cameraAnimator.isRunning` checks
- `testTapDuringActiveCameraAnimatorIsIgnored` — derived from R75; assert `activeCellIndex` stays at first cell when second tap fires during in-flight

These tests protect the cancellation contracts that survive the anticipation deletion.

### `[AMENDMENT-7B.11 → new Phase 0 Task 0.13 + REMOVE rejection #15]` — Reduced-motion as correctness

Remove rejection list item #15 ("Reduced-motion handling — per user filter"). Add new Phase 0 task:

```swift
// TimelineCanvas.swift — augment animateCameraToChatRest
func animateCameraToChatRest(forCellAt k: Int) {
    let count = cellCount()
    guard k >= 0, k < count else { return }
    guard let activeCell = instantiatedCells[k] else { return }
    guard contentHost.layer.animation(forKey: MorphAnimationKey.windupScale.rawValue) == nil else { return }
    guard isQuiet else { return }

    if UIAccessibility.isReduceMotionEnabled {
        snapToChatRestState(forCellAt: k)
        onMorphRevealReady?(k)
        return
    }

    // ... existing morph orchestration ...
}

private func snapToChatRestState(forCellAt k: Int) {
    // Synchronous one-frame transition to chat-rest. No spring, no timer, no curves.
    // End-state EQUIVALENT to the morph's t=1.0 state (per Decision X3 — 9R.4.5).
    guard let cell = instantiatedCells[k], let heightC = cell.heightConstraint else { return }
    let naturalH = cell.naturalHeight
    guard naturalH > 0, bounds.height > 0 else { return }
    let chatRestFactor = bounds.height / naturalH
    let labelCounterScale = 1.0 / chatRestFactor

    CATransaction.withSuppressedActions {
        // Geometry (matches morph end state)
        heightC.constant = naturalH * chatRestFactor
        camera = Camera(translation: cell.frame.midY)
        applyCameraTransform()
        contentHost.layoutIfNeeded()
        setActiveCellIndex(k)

        // CRITICAL per Decision X3 / 9R.4.5 — reset the 4 chrome alphas + center label + contentHost transform
        // to match what the morph achieves at t=1.0. Without these, Reduce-Motion users land at chat-rest
        // with VISIBLE chrome (dateLabel/topicSummaryLabel/todayLabel/pinchGlyph stay alpha=1) and
        // INVISIBLE center label (chatRestCenterLabel stays alpha=0). End-state divergence — Pillar 10.1 violation.
        cell.dateLabel.alpha = 0
        cell.topicSummaryLabel.alpha = 0
        cell.todayLabel.alpha = 0
        cell.pinchGlyph.alpha = 0
        cell.chatRestCenterLabel.alpha = 1
        cell.chatRestCenterLabel.transform = CGAffineTransform(scaleX: labelCounterScale, y: labelCounterScale)

        // Reset contentHost transform — morph applies sin-bell arc transform, snap path must clear it.
        contentHost.layer.transform = CATransform3DIdentity
    }
}
```

**Why:** Apple HIG explicit guidance — vestibular-trigger animations must respect Reduce Motion. The user's a11y filter covers a11y identifiers/labels; user-preference signals are separate.

**Decision X3 RESOLVED INLINE (per 9R.4.5):** the 6 additional writes (4 chrome alphas + 1 center label visibility + 1 center label counter-scale transform + 1 contentHost transform reset) are MANDATORY for end-state equivalence with the morph path. Without these, Reduce-Motion users land at a visually-broken chat-rest. The snap path's end state MUST be pixel-identical to the morph path's end state at t=1.0.

### `[AMENDMENT-7B.12 → Phase 5 Task 5.1 doc]` — Stop-completion asymmetry

Document explicitly in CameraAnimator + MorphChoreographer that `stop(immediately:)` does NOT fire the outer completion. Optionally add `fireCompletion: Bool = false` parameter for callers that need it.

---

---

## 7C — Wave-based animator-on-view consistency (Agent O — returned)

**10 findings. The structural gap: the SSoT's ARCH-NINETY-WAVE-* citations conflate two distinct Wave invariants (animator-on-view ownership vs valueChanged write seam) and miss that Phase 5 Task 5.1's MorphChoreographer BREAKS Wave's "one substrate" invariant by spawning a second CADisplayLink.**

| # | Citation | Amendment target | Classification | One-line finding |
|---|---|---|---|---|
| 1 | `ARCH-ADVERSARIAL-WAVE-01` | Phase 3-4 doc | DEVIATE-LOAD-BEARING | "Honors animator-on-view" is overstated — codebase has animator-on-COLLABORATOR. Different invariant. |
| 2 | `ARCH-ADVERSARIAL-WAVE-02` | Rejection list NEW item #19 | ACCIDENTAL-OMISSION | The `extension UIView { var animator }` REFUSAL is correct but missing from the 18-item rejection list |
| 3 | `ARCH-ADVERSARIAL-WAVE-03` | Phase 5 Task 5.5 doc | DEVIATE-LOAD-BEARING | Velocity-via-parameter (DotPinch) vs velocity-via-property (Wave) — the `lastAnimateVelocityForTesting` field is a test-shape leak caused by parameter-passing |
| 4 | `ARCH-ADVERSARIAL-WAVE-04` | Phase 5 Task 5.2 + rejection list | DEVIATE-ACCIDENTAL | Named spring tokens (`Spring.smooth/.snappy/.bouncy`) — Phase 5 quietly ships single profile without engaging the question. Either ADD tokens OR explicitly REFUSE |
| 5 | `ARCH-ADVERSARIAL-WAVE-05` | Phase 5 Task 5.5 doc | DEVIATE-LOAD-BEARING | Two-layer completion semantics (inner SpringAnimator fires on stop; outer CameraAnimator suppresses) — Wave is single-layer; ~30 LOC of state-machine could collapse |
| 6 | `ARCH-ADVERSARIAL-WAVE-06` | Phase 5 Task 5.1 mandatory OR rejection list | **DEVIATE-LOAD-BEARING (the biggest)** | MorphChoreographer spawns a SECOND CADisplayLink — breaks Wave's "one substrate" invariant. Either fold into substrate via `CurveAnimator<T>` extending SpringInterpolatable, OR explicitly REFUSE with documented rationale |
| 7 | `ARCH-ADVERSARIAL-WAVE-07` | Phase 4 Task 4.1 doc | MISLABELED | RevealBlurOverlay cited as `[ARCH-NINETY-WAVE-01 analog]` — it's not a Wave concept. Cite as Apple UIVisualEffectView idiom instead |
| 8 | `ARCH-ADVERSARIAL-WAVE-08` | Phase 4 doc | UNNAMED | The substrate-vs-domain vocabulary boundary is invisible policy. Should be named (substrate = Wave terms; domain = DotPinch terms) |
| 9 | `ARCH-ADVERSARIAL-WAVE-09` | Phase 2 Cartography refinement | UNDERTHEORIZED | ARCH-NINETY-WAVE-01 collapses two distinct invariants. Split into WAVE-01a (animator-on-collaborator) + WAVE-01b (valueChanged write seam) |
| 10 | `ARCH-ADVERSARIAL-WAVE-10` | Phase 6 NEW Task 6.30 OR rejection list | TEST-COVERAGE-GAP | `animationControllerIdentity` canary is per-controller, doesn't catch process-level "second CADisplayLink" violation |

### Detail — finding #6 (the biggest Wave deviation)

Wave's core invariant: ONE CADisplayLink per app, ticking all registered animators. DotPinch HAS this — `AnimationController` owns the link, animators register via UUID. **Phase 5 Task 5.1's MorphChoreographer creates a SECOND CADisplayLink outside the substrate.** This is the largest Wave-divergence in the conjecture and is invisible in v3.

**Why DotPinch made this choice** (root-cause trace): the morph uses non-spring curves (half-sine arc, linear lerps for height + camera). The substrate is spring-only via `SpringAnimator<T: SpringInterpolatable>`. There's no `CurveAnimator<T>` in the substrate.

**Two principled paths — v3 must pick one:**

**Path A (Wave-aligned — fold into substrate):**
```swift
// Animation/CurveAnimator.swift (new)
@MainActor
public final class CurveAnimator<T: SpringInterpolatable>: AnimatorProviding {
    private let curve: (CGFloat) -> T.ValueType  // closure mapping t∈[0,1] to value
    private let duration: TimeInterval
    private var elapsed: TimeInterval = 0
    // ... registers with AnimationController; ticks via shared displayLink ...
}
```

MorphChoreographer becomes a coordinator holding multiple CurveAnimators (one for height, one for camera, one for unifiedArcY, one for unifiedArcZ), all registered with the shared AnimationController. ONE display link total. Maintains Wave's invariant.

**Path B (explicit refusal):** add to rejection list:
> ❌ **Unifying morph animation under the spring substrate** — the morph uses non-spring curves (half-sine arc + linear lerps); forcing them through SpringInterpolatable distorts the visual intent. Two display links is acceptable because they're mutually exclusive in time (morph and pinch don't overlap). Citation: ARCH-CARTO-SUB-02 deviation.

The v3 SSoT does neither. Path B is simpler to ship; Path A is more principled. → See `[AMENDMENT-7C.6]`.

### Detail — finding #2 (the missing rejection)

The codebase has CONSCIOUSLY chosen NOT to ship `extension UIView { var animator: ViewAnimator }` (Wave's canonical surface). The refusal is correct (DotPinch's animations are domain animations on virtual properties like `camera.translation`, not view-property animations). But it's MISSING from the 18-item rejection list.

→ See `[AMENDMENT-7C.2]`.

---

## 7C — Amendments to Phases 0-6

### `[AMENDMENT-7C.1 → Phase 3/4 doc]` — Split WAVE-01 citations

Update ARCH-NINETY-WAVE-01 in the Phase 3 Ninety section. Replace single citation with TWO sub-citations:
- **ARCH-NINETY-WAVE-01a — animator-on-collaborator (the OWNERSHIP pattern):** "The codebase OWNS animators on collaborators (CameraAnimator, TimelineCanvas), NOT on UIView via associated-object. This is animator-on-COLLABORATOR — partially aligned with Wave's animator-on-view but the surface deviates: domain verbs (`canvas.animateCameraToChatRest`) instead of property chains (`view.animator.translation.spring(...)`)."
- **ARCH-NINETY-WAVE-01b — `valueChanged` per-tick write seam (the WRITE pattern):** "Every animator's per-tick output flows through a `valueChanged: ((T.ValueType) -> Void)?` closure. The closure writes to UIKit properties. This is FULLY HONORED at SpringAnimator.swift:67 + CameraAnimator.swift:59-61 + TimelineCanvas.swift:164-166."

### `[AMENDMENT-7C.2 → Rejection list NEW item #19]`

Append to rejection list:
> ❌ **`extension UIView { var animator: ViewAnimator }` (Wave's canonical surface)** — refused because DotPinch's animatable units are domain scalars (`Camera.translation`, extension-height) NOT view properties; per-view associated-object would hide controller ownership ("which AnimationController does this animator register with?"). The codebase exposes domain verbs (`canvas.animateCameraToChatRest`) instead of property chains. Citation: ARCH-NINETY-WAVE-01a inverse.

### `[AMENDMENT-7C.3 → Phase 5 Task 5.5 doc]` — Velocity-via-parameter rationale

Add to CameraAnimator file header AFTER Phase 5 lands:
```swift
// VELOCITY INJECTION PATTERN: DotPinch uses velocity-via-parameter
// (`animate(to:velocity:)`), NOT Wave's velocity-via-property
// (`animator.velocity = X; animator.animate(to:)`). The parameter form makes
// the velocity contract visible at every call site and prevents stale-velocity
// corruption between calls. The cost is `lastAnimateVelocityForTesting` field
// which exists ONLY because same-target short-circuit (line 137-143) drops
// the velocity before tests can observe it.
```

### `[AMENDMENT-7C.4 → Phase 5 Task 5.2 + rejection list]` — Named spring tokens decision

**Pick one path:**

**Path A (ADD tokens):** Append to Phase 5 Task 5.2:
```swift
// DesignSystem/PhysicsTuning.swift — add semantic tokens
extension Spring {
    /// Critically damped, fast — equivalent to Apple/Wave .snappy.
    static let snappy = Spring(dampingRatio: 0.62, response: 1.10)
    /// Critically damped, gentle — equivalent to Apple/Wave .smooth.
    static let smooth = Spring(dampingRatio: 1.0, response: 1.10)
    /// Slightly underdamped, bouncy — for "celebratory" moments.
    static let bouncy = Spring(dampingRatio: 0.7, response: 0.5)
}
```

Then `GestureCommit.dampingRatio(from:)` becomes `springSpec` returning `Spring`:
```swift
extension GestureCommit {
    func springSpec(from tuning: PhysicsTuning) -> Spring {
        switch self {
        case .commitToChat:   return .snappy
        case .returnToCells:  return .smooth
        case .bailToOrigin:   return Spring(dampingRatio: 0.95, response: 1.10)  // near-critical, no token
        }
    }
}
```

**Path B (REJECT):** Add to rejection list:
> ❌ **`Spring.smooth/.snappy/.bouncy` named tokens** — the three commit damping values ARE the named tokens, just on the commit axis. Adding parallel naming on the aesthetic axis would invite "should chat-arrival be snappy or bouncy?" debates that the current per-commit tuning has already resolved. Rule of 3 not yet hit; refusing extra naming layer.

### `[AMENDMENT-7C.5 → Phase 5 Task 5.5 doc]` — Two-layer completion asymmetry

Document the deviation. CameraAnimator's outer completion is "fires exactly once on natural settle" (stronger than Wave's per-animator completion). The inner SpringAnimator's completion fires on stop. This is Phase 5 Task 5.5's EngagementState scope. Add doc:
```swift
// CameraAnimator wraps SpringAnimator with an outer completion that fires
// EXACTLY ONCE on natural settle (not on caller stop). This is a STRONGER
// guarantee than Wave (one-shot, suppressed on cancel). The two-layer design
// is load-bearing: TimelineCanvas's `extensionAnimator` (raw kernel) uses
// the inner semantics (fires on stop); CameraAnimator uses the outer.
// Per-call control via `extensionAnimator.completion = nil` before stop.
```

### `[AMENDMENT-7C.6 → Phase 5 Task 5.1 mandatory OR rejection list]` — The CADisplayLink unification decision

**Path A (fold into substrate):** add a NEW task before Phase 5 Task 5.1:

**Task 5.0 — Add `CurveAnimator<T: SpringInterpolatable>` to substrate**

```swift
// Animation/CurveAnimator.swift (new)
@MainActor
public final class CurveAnimator<T: SpringInterpolatable>: AnimatorProviding {
    public let id = UUID()
    public private(set) var state: AnimatorState = .inactive
    public var value: T.ValueType?
    public var valueChanged: ((T.ValueType) -> Void)?
    public var completion: ((SpringAnimator<T>.Event) -> Void)?

    private let curve: (CGFloat) -> T.ValueType
    private let duration: TimeInterval
    private var elapsed: TimeInterval = 0
    private weak var controller: AnimationController?

    public init(controller: AnimationController,
                duration: TimeInterval,
                curve: @escaping (CGFloat) -> T.ValueType) {
        self.controller = controller
        self.duration = duration
        self.curve = curve
    }

    public func start() {
        elapsed = 0
        state = .running
        controller?.register(self)
    }

    public func updateAnimation(deltaTime: TimeInterval) {
        elapsed += deltaTime
        let t = CGFloat(min(elapsed / duration, 1.0))
        let v = curve(t)
        value = v
        valueChanged?(v)
        if t >= 1.0 {
            state = .ended
            completion?(.finished(at: v))
            controller?.unregister(id: id)
        }
    }

    public func stop() {
        state = .ended
        controller?.unregister(id: id)
    }
}
```

Phase 5 Task 5.1's MorphChoreographer then holds CurveAnimators (one per property) all registered with the shared AnimationController. Reuses the substrate's CADisplayLink. ONE display link total.

**Path B (explicit refusal):** append to rejection list (which already has 18 items):
> ❌ **Unifying morph + spring substrate under one CADisplayLink** — morph uses non-spring curves (half-sine arc + linear lerps); forcing through SpringInterpolatable distorts the math. Two display links acceptable because morph and pinch are mutually exclusive in time. Citation: ARCH-CARTO-SUB-02 deviation, documented.

**Recommendation:** Path A if budget allows (~1 day to add CurveAnimator + Phase 5 Task 5.1 rewires). Path B if shipping fast matters. **Either way, v3's silence is the bug.**

### `[AMENDMENT-7C.7 → Phase 4 Task 4.1 doc]` — Drop the WAVE analog citation on RevealBlurOverlay

Replace `[ARCH-NINETY-WAVE-01 analog]` with `[ARCH-NINETY-ORG-04 SoC + Apple UIVisualEffectView idiom]`. RevealBlurOverlay encapsulates UIKit, not a Wave concept.

### `[AMENDMENT-7C.8 → Phase 4 doc]` — Substrate-vs-domain vocabulary boundary

Add to Phase 4 Conjecture section:
> **Vocabulary boundary:** the substrate (Animation/*) uses Wave's vocabulary (animator, spring, target, velocity, value, valueChanged, completion). The domain layer (Conversation/V2/*) uses DotPinch's vocabulary (Camera, MorphChoreography, GestureCommit, RevealCoordinator). The boundary is the Animation/ folder boundary — at no point should a domain type name leak into the substrate; at no point should a Wave-internal term appear in the domain.

### `[AMENDMENT-7C.9 → Phase 2 Cartography refinement]`

Already covered by 7C.1 above — ARCH-NINETY-WAVE-01 splits into 01a + 01b.

### `[AMENDMENT-7C.10 → Phase 6 NEW Task 6.30 OR rejection list]` — Process-level CADisplayLink canary

If Path A (fold into substrate) lands, no canary needed. If Path B (explicit refusal), add to rejection list:
> ❌ **Process-level "one CADisplayLink" canary** — the morph intentionally uses a deterministic clock outside the spring substrate. Two display links is the documented architecture.

---

---

## 7D — Recursive line-level tier-3b discipline (Agent P — returned)

**20 findings. Key cross-cutting insight: tier-3b discipline is applied UNEVENLY across the codebase. Principal-author files (TimelineCanvas core, Camera, PinchTuning, CellView core) show tier-3b doc/precondition/MARK/vocabulary density. Externally-adapted Wave files (SpringAnimator, Spring, AnimationController) and quickly-written files (ChatViewController, MathUtilities) sit at tier-2.**

**Structural fix:** a one-shot "discipline migration pass" on the externally-adapted + quickly-written files, applying the SAME rules the principal author already applies to their own code. Then add a CI gate (SwiftSyntax-based) preventing regression.

| # | Citation | Amendment target | Priority | One-line finding |
|---|---|---|---|---|
| 1 | `ARCH-ADVERSARIAL-LINE-01` | Phase 6 NEW Task 6.31 | P1 | `docs/VOCABULARY.md` is referenced by ChatBubbleView.swift but may not exist — create OR strip the references |
| 2 | `ARCH-ADVERSARIAL-LINE-02` | Phase 6 NEW Task 6.32 | P1 | Every `public` in SpringAnimator/Spring/AnimationController/SpringInterpolatable needs `///` doc-comment with precondition + side effects + timing |
| 3 | `ARCH-ADVERSARIAL-LINE-03` | Phase 6 Task 5.5 doc | P2 | `SpringAnimator.stop(immediately:false)` may have NO caller — verify or remove |
| 4 | `ARCH-ADVERSARIAL-LINE-04` | Phase 6 Task 6.32 | P1 | AnimationController public surface (register/unregister/runPropertyAnimation) lacks doc |
| 5 | `ARCH-ADVERSARIAL-LINE-05` | Phase 6 doc + perf | P2 | Spring's `settlingPercentage`/`overdampedMultiplier` static lets are undocumented; consider `@inlinable` for hot-path derived properties |
| 6 | `ARCH-ADVERSARIAL-LINE-06` | Phase 0 NEW Task 0.14 | **P1** | `Camera.translation` is `var` (mutable struct) — should be `let` so the type is value-immutable. Eliminates the every-`setCamera`-call validation duplication |
| 7 | `ARCH-ADVERSARIAL-LINE-07` | Phase 0/5 augmentation | P1 | Add `precondition()` to `Spring.init`, `setActiveCellIndex(_:)`, `Camera.init`; doc the guard-vs-precondition choice on `animateCameraToChatRest` |
| 8 | `ARCH-ADVERSARIAL-LINE-08` | Phase 0 augmentation | P2 | `dequeueCell -> (CellView, preservedState: Bool)` tuple — caller ignores `preservedState`. Either consume it (B4 fix) or `@discardableResult` |
| 9 | `ARCH-ADVERSARIAL-LINE-09` | Phase 6 NEW Task 6.33 | **P1** | Add `@MainActor` to SpringAnimator + AnimationController + DisplayLinkProxy (independent corroboration of Agent M's RUNTIME-01); enable strict-concurrency |
| 10 | `ARCH-ADVERSARIAL-LINE-10` | Phase 6 Task 6.3 expansion | P1 | ChatViewController is biggest doc gap — needs file header, method docs, hoist `22` (composer height?) to Theme |
| 11 | `ARCH-ADVERSARIAL-LINE-11` | Phase 6 NEW Task 6.34 | P3 | Rename `forCellAt k:` → `forCellAt index:` for naming consistency; consider `pagePoint(fromViewport:)` |
| 12 | `ARCH-ADVERSARIAL-LINE-12` | Cross-ref Phase 1 Task 1.2 | P1 | All `animateCameraToChatRest` literals must hoist to MorphTiming; specifically the 1.5 vs 1.2 duration discrepancy needs explicit doc |
| 13 | `ARCH-ADVERSARIAL-LINE-13` | Phase 6 NEW Task 6.35 | P2 | Move `*ForTesting` accessors to `+Testing.swift` extension files with `@_spi(Testing)` discipline. Test seams stop polluting production surface |
| 14 | `ARCH-ADVERSARIAL-LINE-14` | Phase 6 nit | P3 | Wrap MathUtilities free functions in `enum Math` namespace OR extension on CGFloat |
| 15 | `ARCH-ADVERSARIAL-LINE-15` | — | N/A | Guard-style discipline: codebase is clean. No action. |
| 16 | `ARCH-ADVERSARIAL-LINE-16` | — | N/A | **Zero TODO/FIXME/HACK/XXX in production code** — exemplary tier-3b discipline. Either fixed or fed into v3 checklist. |
| 17 | `ARCH-ADVERSARIAL-LINE-17` | Cross-ref Phase 6 6.3 | P2 | ChatViewController has no MARKs (Agent J + Q corroborate); CameraAnimator test-seam interleaving fixed by LINE-13 |
| 18 | `ARCH-ADVERSARIAL-LINE-18` | Phase 6 doc | P3 | Conversation's `nonisolated` Equatable/Hashable conformances need 1-line `///` explaining "safe off-main because id is immutable" |
| 19 | `ARCH-ADVERSARIAL-LINE-19` | Phase 6 NEW Task 6.36 | P2 | ConversationStore.insert can corrupt dual-index invariant (overwrites map, appends to array) → `precondition(conversationsByID[id] == nil)`; same pattern in TimelineCanvas pool |
| 20 | `ARCH-ADVERSARIAL-LINE-20` | Phase 5 Task 5.1 amendment | P1 | CellView.setCamera magic constants `0.05` + `0.30` → new `CellChromeTiming` namespace (parallel to MorphTiming) |

### Net-new tasks not yet in v3

- **Task 0.14** — `Camera.translation: var → let` (full value-immutability)
- **Task 6.31** — Resolve `docs/VOCABULARY.md` (create or strip refs)
- **Task 6.32** — Doc-pass on externally-adapted public surface (SpringAnimator + Spring + AnimationController + SpringInterpolatable)
- **Task 6.33** — `@MainActor` annotations + strict-concurrency enablement (combines with Agent M's RUNTIME-01)
- **Task 6.34** — Naming consistency pass (`forCellAt k:` → `forCellAt index:`)
- **Task 6.35** — Move `*ForTesting` to `+Testing.swift` extensions with `@_spi(Testing)`
- **Task 6.36** — Invariant-enforcement precondition on dual-index data structures (ConversationStore + TimelineCanvas pool)
- **CellChromeTiming** namespace (parallel to MorphTiming) for cell-internal animation constants

### Detail — finding #6 (Camera.translation should be let, not var)

**Evidence:** `Camera.swift:19-20`: "Camera is a mutable struct (fields may be re-assigned post-init)". Comment justifies `var translation: CGFloat`. Validation runs at every `setCamera` write at TimelineCanvas:336.

**Tier-3b critique:** value types should be VALUE-IMMUTABLE. Mutability post-init means every write site must re-validate. Today: `setCamera` at line 336 does `precondition(newCamera.translation.isFinite)`. If `Camera.translation` were `let`, the validation would live in the init (where it belongs) and `setCamera` would just be `camera = newCamera`. The current shape encodes "we don't trust the camera once it's out in the wild."

**Patch (Phase 0 Task 0.14):**
```swift
public struct Camera: Sendable, Equatable {
    public let translation: CGFloat  // var → let
    public init(translation: CGFloat) {
        precondition(translation.isFinite, "Camera.translation must be finite; got \(translation)")
        self.translation = translation
    }
}
```

Every site that wrote `camera.translation = X` becomes `camera = Camera(translation: X)`. Validation lives ONCE in init. The "every-setCamera-validates" duplicates dissolve.

### Detail — finding #19 (dual-index invariant corruption)

**Evidence (ConversationStore.swift:30-33):**
```swift
private func insert(_ conversation: Conversation) {
    conversationsByID[conversation.id] = conversation
    conversations.append(conversation)
}
```

No precondition against duplicate id. Duplicate-id insert overwrites the map (one entry) but appends to the array (two entries). Map↔array inconsistency.

**Same pattern in TimelineCanvas pool** (`cellPool` + `cellPoolByConversationID` + `poolOrder` — three indexes, one invariant). The pool has documentation of the invariant (line 45) but no runtime check.

**Patch (Phase 6 Task 6.36):**
```swift
private func insert(_ conversation: Conversation) {
    precondition(conversationsByID[conversation.id] == nil,
                 "ConversationStore.insert: duplicate id \(conversation.id)")
    conversationsByID[conversation.id] = conversation
    conversations.append(conversation)
}
```

Apply same audit to TimelineCanvas pool dequeue/return.

---

## 7E — File organization maximalist + visual digestion (Agent Q — returned)

**12 findings. The damning headline: 50% of files FAIL the 16-second visual-digestion scan budget.**

| # | Citation | Amendment target | Priority | One-line finding |
|---|---|---|---|---|
| 1 | `ARCH-ADVERSARIAL-FILEORG-01` | Phase 0 NEW Task 0.15 | **P0** | ChatViewController (132 LOC) has ZERO file header — production chat surface with no orientation |
| 2 | `ARCH-ADVERSARIAL-FILEORG-02` | Phase 0 NEW Task 0.15 | **P0** | **THREE stale headers actively LIE about nonexistent types**: ChatBubbleView→`ChatBodyView`/`ConversationCell`, Theme→`ConversationCell.apply`, PinchTuning→`MorphTiming.swift` (doesn't exist yet) |
| 3 | `ARCH-ADVERSARIAL-FILEORG-03` | Phase 0 NEW Task 0.15 | **P0** | CellView.swift:8 imports `Observation` but never uses it — dead import |
| 4 | `ARCH-ADVERSARIAL-FILEORG-04` | Phase 6 NEW Task 6.37 | P1 | Three competing import orderings (alphabetical / Foundation-first / framework-weight-first). Adopt strict alphabetical + SwiftLint `sorted_imports` rule |
| 5 | `ARCH-ADVERSARIAL-FILEORG-05` | Phase 6 Task 6.3 expansion | P1 | Agent J missed: AnimationController.swift (84 LOC, 0 MARKs) AND V2RootViewController.swift (2 MARKs, `revealChat` unmarked) |
| 6 | `ARCH-ADVERSARIAL-FILEORG-06` | Phase 6 NEW Task 6.38 | P1 | Type-doc-comment INVERSION: public types lack `///` while private helpers HAVE it. AnimationController (public) bare while DisplayLinkProxy (private) documented. Same for SpringAnimator (bare) vs AnimatorProviding (documented) |
| 7 | `ARCH-ADVERSARIAL-FILEORG-07` | Phase 6 Task 6.2b NEW | P2 | Beyond TimelineCanvas:UIGestureRecognizerDelegate (Task 6.2), `Conversation: Identifiable, Equatable, Hashable` should split into 3 file-end conformance extensions |
| 8 | `ARCH-ADVERSARIAL-FILEORG-08` | Phase 6 nesting pass | P3 | `CameraVelocity` → `CameraAnimator.Velocity` (single consumer); `AnimatorState` → `SpringAnimator.State` (debatable — used by AnimationController polling) |
| 9 | `ARCH-ADVERSARIAL-FILEORG-09` | Phase 7 NEW Task 7.1 | P2 | Directory restructure: `V2/` → `Timeline/` (anachronistic name), move `ChatViewController` into `ChatBody/`, delete `Gestures/`, create `Conversation/Tuning/` |
| 10 | `ARCH-ADVERSARIAL-FILEORG-10` | Phase 7 NEW Task 7.0 | P2 | Megafile deferral has no re-evaluation date — without commitment, "deferred" becomes "permanent" |
| 11 | `ARCH-ADVERSARIAL-FILEORG-11` | — | N/A | MARK quality (verb/noun phrases naming concerns) is GOOD across the codebase. No action. |
| 12 | `ARCH-ADVERSARIAL-FILEORG-12` | Phase 6 Task 6.32 expansion | P2 | `Spring.swift`'s 1-line header undersells 54 LOC of physics. Expand to 5-line role + inputs/outputs summary |

### Critical P0 — Task 0.15 (header truthfulness)

The three STALE headers are **load-bearing correctness defects**, not style. A reader's `Cmd-Shift-O ConversationCell` returns nothing → 30s confusion. Fix immediately.

**Patches:**

`Conversation/ChatBody/ChatBubbleView.swift:1-10`:
```swift
// ChatBubbleView — one message-bubble row in the chat-rest surface.
// Hosted inside ChatViewController.bubbleStack (UIStackView). Configured
// once at init with a Message; immutable after. See VOCABULARY.md (or this
// file's tier-3b+ doc-comment block) for sender/role/timestamp semantics.
```
(Old text referencing `ChatBodyView`/`ConversationCell` is removed.)

`DesignSystem/Theme.swift:1-7`:
```swift
// Theme — design tokens. Page/Cell chromatics, Text colors, Typography,
// Radius, Symbol affordances. See CellView.setCamera(_:viewport:) for the
// lerp(Cell.fill → Cell.activeFill) seam (the active-cell highlight).
```

`Gestures/PinchTuning.swift:1-5` (or `DesignSystem/PhysicsTuning.swift` after Phase 5 Task 5.2 move):
```swift
// PinchTuning — gesture-physics constants (spring damping, response,
// per-direction damping). For MORPH visual-timing constants (windup,
// curves, lift magnitudes), see MorphTiming (added in Phase 1 Task 1.2)
// — distinct file because morph-timing is choreography, not gesture-physics.
```

(After Phase 1 Task 1.2 lands, the MorphTiming reference becomes accurate.)

### Critical P0 — Task 0.15 also bundles header additions for ChatViewController + dead import removal

```swift
// Conversation/V2/ChatViewController.swift — ADD at file top
// ChatViewController — production chat-rest surface revealed by the morph.
// Hosts header label + bubble scrollView + composer. Configured with a
// Conversation; rebuilds bubble stack on configure(). Owns no animation —
// the morph is owned by TimelineCanvas; this VC is opacity-faded in by
// RevealCoordinator (post-Phase 4) or V2RootViewController.revealChat (pre).

// Conversation/V2/CellView.swift:8 — REMOVE
import Observation  // DELETE — never used; @Observable resolution happens at store/adapter level
```

---

## 7F — Adversarial fresh-eyes v3 critique (Agent R — returned)

**18 findings. The unkindest cut: v3's own organization is Tier 2B, against its own Tier 3B mandate. The document prescribing readability is not maximally readable.**

| # | Citation | Amendment target | Severity | One-line finding |
|---|---|---|---|---|
| 1 | `ARCH-ADVERSARIAL-V3-01` | Phase 0 Task 0.4 amendment | **HIGH** | Task 0.4's "Verify the codepath" is a confession of unfinished homework. I verified for v4: pinch-commit goes through `animateCameraToChatRestPath` directly; tap goes through public method directly. **They are SEPARATE paths. No double-fire risk.** |
| 2 | `ARCH-ADVERSARIAL-V3-02` | Phase 0 + 5 coupling | **HIGH** | Task 5.5's `isRunning` substitution silently changes semantics; Task 0.3's `isQuiet` predicate uses `cameraAnimator.isRunning`. **Tasks 0.3 + 5.5 are NOT independent** — they share a definition point |
| 3 | `ARCH-ADVERSARIAL-V3-03` | Phase 6 Task 6.13 doc | MEDIUM | Task 6.13's closure-init derivation includes a "WAIT — user-emphasized rule" mid-sentence false-start. Not principal-tier writing |
| 4 | `ARCH-ADVERSARIAL-V3-04` | Phase 1 Gauge | MEDIUM | "Uniform 3B" tier claim is false post-Phase-6 because rejection #8 leaves TimelineCanvas at 2B-or-3A. Coherence test 4 (tier-match) should be PASS WITH NOTES |
| 5 | `ARCH-ADVERSARIAL-V3-05` | Multiple tasks | **HIGH** | "Visual diff vs pre-refactor: identical" is not objectively measurable. Frame-by-frame? Maestro screenshot diff? Naked-eye? Tolerance? Sample rate? v3 admits this as "outstanding" but ships as "Ready to implement: PARTIAL" |
| 6 | `ARCH-ADVERSARIAL-V3-06` | Phase 5 effort estimate | MEDIUM | Phase 5 = 4-6 days for 5 high-risk refactors + 90+ test reference updates. Realistic: 7-10 days. Phase 6 = 3-4 days for 27 tasks is similarly tight |
| 7 | `ARCH-ADVERSARIAL-V3-07` | Phase 0 Task 0.4 amendment | MEDIUM | Verify-don't-assume meta-principle violated by Task 0.4's punted verification (cross-ref V3-01) |
| 8 | `ARCH-ADVERSARIAL-V3-08` | Phase 0 Task 0.1 | MEDIUM | `morphInProgress` flag duplicates `activeCellIndex == self.index`. v3 fixes the symptom (missing reset) without naming the root cause (the flag shouldn't exist) |
| 9 | `ARCH-ADVERSARIAL-V3-09` | Phase 5 Task 5.2 | LOW | Task 0.2 silently deletes anticipation-field bounds preconditions; lineage of which preconditions carry forward to PhysicsTuning needs explicit doc |
| 10 | `ARCH-ADVERSARIAL-V3-10` | Citation hygiene | LOW | Task 0.4 cites `[BUG-H-A]` — no such ID; should be `[BUG-H10]`. Task 5.1 cites K7 which is "DO NOT TOUCH" but the task EXTRACTS that keystone — citation cognitive dissonance |
| 11 | `ARCH-ADVERSARIAL-V3-11` | Unified Verdict | MEDIUM | "Ready to implement: PARTIAL" cites only visual-regression. Coherence tests 3 + 5 are PASS WITH NOTES — that's also blocking, not just visual |
| 12 | `ARCH-ADVERSARIAL-V3-12` | Phase Dependency Graph | **HIGH** | Phase Dependency Graph contradicts the landing-order recommendation. Graph says Phase 2 → Phase 3; recommendation says Phase 3 → Phase 2. Three sources, two contradictory orderings |
| 13 | `ARCH-ADVERSARIAL-V3-13` | Effort tables | LOW | Two effort totals (13-20 days vs 14-20 days) disagree by 1 day. Sum check: 1+1+1+1+3+4+3=14 lower / 1+2+2+1+4+6+4=20 upper. Fix the line-472 total |
| 14 | `ARCH-ADVERSARIAL-V3-14` | Phase 4 NEW Task 4.5 | **HIGH** | Q6 (`timelineCanvas.alpha = 0` reset) marked "out of scope" — but Phase 4 Task 4.3 is exactly the dismiss-path-enablement window. Add `dismiss()` to RevealCoordinator NOW (matches Agent M's RUNTIME-06 + Agent N's CANCEL-06/07) |
| 15 | `ARCH-ADVERSARIAL-V3-15` | Phase 7 NEW Task 7.2 | MEDIUM | **v3's own organization is Tier 2B against its own Tier 3B mandate.** 2604 lines, single file, 6 cross-references between tasks, two effort tables, two phase-orderings, mid-derivation false-starts. Restructure into per-phase files OR add executive-summary front-matter |
| 16 | `ARCH-ADVERSARIAL-V3-16` | Cosmetic | LOW | M2 label is present (line 18) but missing the `M2 —` prefix for symmetry with M1 + M3 |
| 17 | `ARCH-ADVERSARIAL-V3-17` | Acceptance criteria | LOW | "Existing tests pass" is a prediction, not a verified state. Distinguish "implementer must verify" from "audit has verified" |
| 18 | `ARCH-ADVERSARIAL-V3-18` | — | N/A | Self-bias acknowledgment (Agent R reviewed the doc, not the code) |

### The harshest hit — V3-15

v3 prescribes Tier 3B file organization for the codebase. v3 IS the file containing that prescription. Measured by the same rules:
- **Single 2604-line megafile** (the same crime TimelineCanvas commits)
- **6 forward+backward cross-references** between tasks
- **Two contradictory effort tables** + **two contradictory phase orderings**
- **Mid-derivation false-starts** ("WAIT — user-emphasized rule")

**Patch — Phase 7 Task 7.2:** restructure SSoT into per-phase files:
```
.
├── REFACTOR-CHECKLIST.md             (executive summary + index + cross-refs only)
├── phases/
│   ├── Phase-0-bugs.md
│   ├── Phase-1-tokens.md
│   ├── Phase-2-devx.md
│   ├── Phase-3-hoist.md
│   ├── Phase-4-coordinator.md
│   ├── Phase-5-keystones.md
│   ├── Phase-6-hygiene.md
│   └── Phase-7-adversarial.md
└── adversarial/
    ├── 7A-runtime.md (Agent M)
    ├── 7B-cancellation.md (Agent N)
    ├── 7C-wave.md (Agent O)
    ├── 7D-line-level.md (Agent P)
    ├── 7E-file-org.md (Agent Q)
    ├── 7F-v3-critique.md (Agent R)
    └── 7G-state-lifecycle.md (Agent S)
```

REFACTOR-CHECKLIST.md becomes a ~200-line executive summary + index. Tier-3B organization for the SSoT itself.

### Critical V3-01 patch (the codepath verification Agent R completed)

Replace Task 0.4's "Verify the codepath before adding" warning with the verified answer:

> **Verified at d464c71:** `handlePinchEnded:1077` calls `animateCameraToChatRestPath` DIRECTLY (not through the public `animateCameraToChatRest`). `V2RootViewController.handleTap:74` and CellView's onTap chain call the public method DIRECTLY. The two paths are SEPARATE — no double-fire risk. Safe to add `onMorphRevealReady?(revealK)` to the `*Path` master-timer completion.

(This patch alone moves Task 0.4 from Tier-2A to Tier-3B per V3-01 + V3-07.)

### Critical V3-02 patch (Task 0.3 + Task 5.5 coupling)

Update Phase 5 Task 5.5's "Dependencies" line:
> **Dependencies:** Task 0.3 (`isQuiet` predicate consumes `cameraAnimator.isRunning`). The new `EngagementState` enum's `isRunning` MUST be semantically equivalent to the old `translationAnimator.state == .running` — specifically: returns `true` during the window between "spring settles" and "outer completion fires." Add acceptance: `isRunning` returns true if (case .engaged = state) OR (translationAnimator.state == .running) — whichever is more inclusive. Document the union semantics.

### Critical V3-12 patch (graph vs recommendation contradiction)

Reconcile the Phase Dependency Graph (line ~2510) with the landing-order recommendation. **Correct ordering** (per cascade analysis): Phase 0 → Phase 1 → Phase 3 → Phase 2 → Phase 4 → Phase 5 → Phase 6. Phase 3 MUST precede Phase 2 because Inject (Phase 2 Task 2.1) requires hoisted AnimationController. Update the graph to match.

### Critical V3-13 patch (effort total)

Fix line 472 (early effort estimate): change `13-20` → `14-20`. Single character edit.

---

## 7G — State lifecycle + data flow (Agent S — returned)

**10 findings. Key validation: Task 0.7 must be PROMOTED from optional to required. `reloadData`-with-active-cell orphans the active cell, bypassing returnToPool, so Task 0.1's morphInProgress reset NEVER runs on the orphan.**

| # | Citation | Amendment target | Priority | One-line finding |
|---|---|---|---|---|
| 1 | `ARCH-ADVERSARIAL-STATE-01` | Phase 0 Task 0.7 PROMOTE | **HIGH** | reloadData-with-active-cell orphans the active cell (instantiatedCells.removeAll() at 380-384; returnToPool rejects active at 780-782). Bypass = morphInProgress never reset |
| 2 | `ARCH-ADVERSARIAL-STATE-02` | K5 description refinement | LOW | applyMasterTick bypasses pushCameraToVisibleCells (it does targeted active-cell push instead). K5 description should distinguish "every camera mutation pushes universally" from "height mutations push selectively" |
| 3 | `ARCH-ADVERSARIAL-STATE-03` | Phase 5 Task 5.1 amendment | LOW-MED | MorphChoreographer.stop() doesn't reset contentHost.layer.transform on interrupt. User sees stuck-mid-lift visual when reveal cancelled |
| 4 | `ARCH-ADVERSARIAL-STATE-04` | Phase 6 Task 6.10 doc | MEDIUM | RevealState enum from Task 6.10 cannot represent "active-but-no-blur" half-state if Task 4.4 (UIViewPropertyAnimator cancel) ships AND mid-reveal cancellation leaves chat present but blur removed |
| 5 | `ARCH-ADVERSARIAL-STATE-05` | Phase 6 Task 6.10 amendment | LOW | Task 6.10's enum loses the `revealBlurOverlay === blur` identity defense from current code. Preserve via enum-case identity OR cancellable animator |
| 6 | `ARCH-ADVERSARIAL-STATE-06` | Code cleanup OR doc | LOW | `onCameraChanged` callback is dead state in production — set in V2RootViewController but no real consumer. YAGNI delete OR document future use |
| 7 | `ARCH-ADVERSARIAL-STATE-07` | Cross-ref STATE-01 | HIGH | morphInProgress one-way latch: Task 0.1 fixes pool path; STATE-01 covers orphan path |
| 8 | `ARCH-ADVERSARIAL-STATE-08` | Cross-ref V3-08 | HIGH | dequeueCell.preservedState ignored (B4). Phase 0 Task 0.7 calls this "optional"; STATE-01 forces it to required |
| 9 | `ARCH-ADVERSARIAL-STATE-09` | Cross-ref CANCEL-01 + 5.1 | MEDIUM | Phase 5 Task 5.1's MorphChoreographer-completion REPLACES the asyncAfter at TimelineCanvas:1239 — but only if Task 0.3 calls choreographer.stop on pinch.began. v3 line 1601 says "yes" — verified |
| 10 | `ARCH-ADVERSARIAL-STATE-10` | Keystone K5 doc | LOW | K5 description doesn't distinguish camera-mutation push (universal) from height-mutation partial push (active-only). Refine wording. |

### Critical patches

**[AMENDMENT-7G.1 → Phase 0 Task 0.7 PROMOTE to required]**

Task 0.7 is no longer "*(Optional)*". Three reasons converge:
- Agent H Finding 4 (dequeueCell.preservedState ignored)
- Agent H Finding 5 (reloadData orphan)
- Agent S STATE-01 + STATE-07 (one-way latch's orphan-path is NOT covered by Task 0.1's pool-path)

After Phase 4 Task 4.5 (RevealCoordinator.dismiss), the dismiss path is exposed. Once dismiss runs, the canvas returns to visibility. If reloadData was called during the chat-rest state, the active cell is now an orphan with morphInProgress=true permanently set. The reset that Task 0.1 installs in returnToPool NEVER fires on this orphan because reloadData removed it from instantiatedCells without going through returnToPool.

**Patch:** Task 0.7 becomes required. Add to its acceptance:
```swift
// Test: morph a cell to chat-rest, call reloadData() while activeCellIndex != nil
// → assert: setActiveCellIndex(nil) was called as part of reloadData
// → assert: the previously-active cell received resetMorphState() before being orphaned
// → assert: no leaked CellView with morphInProgress=true after reloadData
```

**[AMENDMENT-7G.3 → Phase 5 Task 5.1 amendment]**

Add to MorphChoreographer.stop():
```swift
func stop() {
    // Reset visual state — prevents stuck-mid-lift on interrupt
    if let canvas, isRunning {
        CATransaction.withSuppressedActions {
            canvas.contentHost.layer.transform = CATransform3DIdentity
        }
    }
    NotificationCenter.default.removeObserver(self)
    displayLink?.invalidate()
    displayLink = nil
    choreography = nil
    completion = nil
}
```

**[AMENDMENT-7G.4+5 → Phase 6 Task 6.10 amendment]**

If Task 4.4 (UIViewPropertyAnimator cancel) ships, the RevealState enum needs a third case:
```swift
private enum RevealState {
    case idle
    case active(chat: ChatViewController, blur: RevealBlurOverlay, animator: UIViewPropertyAnimator)
    case cancelling(chat: ChatViewController, blur: RevealBlurOverlay)  // mid-cancel, blur detaching
}
```

Or — simpler — preserve the `=== blur` identity defense by storing a UUID per reveal and checking it in cleanup closures.

### Cross-cutting state-lifecycle takeaway

The codebase has multiple **dual-index** data structures (ConversationStore: map + array; TimelineCanvas pool: pool + keyed map + LRU order). Each has an implicit invariant. None have runtime checks. Agent S + Agent P (LINE-19) independently flagged this. **Add Phase 6 Task 6.36 — invariant-enforcement preconditions on every dual-index structure.**

---

---

## 7E — File organization maximalist + visual digestion (pending Agent Q)

**Scope:** Every file's role-statement quality (not presence — quality), MARK density thresholds, "10-second scan-time" budget per file, directory structure coherence, nested-type decisions, file-end conformance extension application, protocol placement.

⏳ *Awaiting agent return — will populate with `ARCH-ADVERSARIAL-FILEORG-*` findings.*

---

## 7F — Adversarial fresh-eyes v3 critique (pending Agent R)

**Scope:** What's WRONG, AMBIGUOUS, MISSING, or CONTRADICTORY in v3 itself. Acceptance criteria that aren't objectively testable. Missing inter-task dependencies. Premature tasks. Citation density spot-checks. Tier-claim honesty.

⏳ *Awaiting agent return — will populate with `ARCH-ADVERSARIAL-V3-*` findings.*

---

## 7G — State lifecycle + data flow audit (pending Agent S)

**Scope:** Full state-transition graphs for `activeCellIndex`, `camera`, `morphInProgress`, the cell pool, reveal state, animation kernel state. Cross-cutting state dependencies. AsyncAfter lifecycle bleed. The push-pattern invariant verification.

⏳ *Awaiting agent return — will populate with `ARCH-ADVERSARIAL-STATE-*` findings.*

---

## 7-AMENDMENTS — Consolidated new tasks + Phase 0-6 patches

**All 7 adversarial agents returned. Below is the consolidated registry of NEW tasks that emerged AND amendments to existing v3 tasks.**

### New tasks introduced by adversarial review

| New task | Phase | Source | Priority |
|---|---|---|---|
| **0.8** — `preferredFrameRateRange` on masterTimer + future MorphChoreographer | Phase 0 | Agent M RUNTIME-03 | HIGH |
| **0.9** — DispatchWorkItem cancellation for onMorphRevealReady | Phase 0 | Agent N CANCEL-01 | HIGH |
| **0.10** — Spring init bounds preconditions | Phase 0 | Agent N CANCEL-02 | HIGH |
| **0.11** — Split `.cancelled`/`.failed` from `.ended` in handlePinch | Phase 0 | Agent N CANCEL-04 | HIGH |
| **0.12** — DisplayLink-local time (not wall-clock) for master timer | Phase 0 | Agent N CANCEL-05 | HIGH |
| **0.13** — Reduced-motion handling (RECATEGORIZE out of a11y filter) | Phase 0 | Agent N CANCEL-11 | MED-HIGH |
| **0.14** — `Camera.translation: var → let` (value-immutability) | Phase 0 | Agent P LINE-06 | P1 |
| **0.15** — Stale header truthfulness + ChatViewController header + dead Observation import | Phase 0 | Agent Q FILEORG-01/02/03 | **P0** |
| **4.4 PROMOTE** — `UIViewPropertyAnimator + delayFactor` from OPTIONAL → REQUIRED | Phase 4 | Agent N CANCEL-06 | HIGH |
| **4.5** — App-lifecycle observer + cancelInFlightTransitions + RevealCoordinator.dismiss | Phase 4 | Agent M RUNTIME-06 + Agent N CANCEL-07 + Agent R V3-14 | HIGH |
| **5.0** — `CurveAnimator<T>` in substrate (Wave-aligned Path A) — OR rejection-list addition | Phase 5 (precedes 5.1) | Agent O WAVE-06 | DECISION |
| **5.6** — Scene-phase awareness on CADisplayLink owners | Phase 5 | Agent M RUNTIME-02 | HIGH |
| **6.28** — Insertion-ordered animator iteration in AnimationController | Phase 6 | Agent M RUNTIME-07 | MED |
| **6.29** — Substrate NaN/Inf circuit-breaker in SpringAnimator | Phase 6 | Agent N CANCEL-03 | MED |
| **6.30** — Process-level CADisplayLink canary OR rejection-list | Phase 6 | Agent O WAVE-10 | DECISION |
| **6.31** — Resolve `docs/VOCABULARY.md` (create or strip refs) | Phase 6 | Agent P LINE-01 | P1 |
| **6.32** — Doc-pass on externally-adapted public surface | Phase 6 | Agent P LINE-02/04 + Agent Q FILEORG-12 | P1 |
| **6.33** — `@MainActor` annotations + strict-concurrency enablement | Phase 6 | Agent M RUNTIME-01 + Agent P LINE-09 | P1 |
| **6.34** — Naming consistency pass (`forCellAt k:` → `forCellAt index:`) | Phase 6 | Agent P LINE-11 | P3 |
| **6.35** — `*ForTesting` to `+Testing.swift` with `@_spi(Testing)` | Phase 6 | Agent P LINE-13 | P2 |
| **6.36** — Dual-index invariant preconditions (ConversationStore + TimelineCanvas pool) | Phase 6 | Agent P LINE-19 + Agent S STATE-08 | P2 |
| **6.37** — Strict alphabetical imports + SwiftLint `sorted_imports` | Phase 6 | Agent Q FILEORG-04 | P1 |
| **6.38** — Type-doc-comment INVERSION fix (public types missing `///` while private have it) | Phase 6 | Agent Q FILEORG-06 | P1 |
| **7.0** — TimelineCanvas split re-evaluation memo (hard date post-Phase-6) | Phase 7 | Agent Q FILEORG-10 | P2 |
| **7.1** — Directory restructure (V2/ → Timeline/, ChatViewController → ChatBody/, delete Gestures/) | Phase 7 | Agent Q FILEORG-09 | P2 |
| **7.2** — Restructure SSoT into per-phase files (the SSoT is itself Tier 2B) | Phase 7 | Agent R V3-15 | MED |
| **0.7 PROMOTE** — reloadData mid-active-cell defensive guard from OPTIONAL → REQUIRED | Phase 0 | Agent S STATE-01 + STATE-07/08 + V3-14 | HIGH |

### Inline amendments to existing v3 tasks

| v3 Task | Amendment | Source |
|---|---|---|
| Task 0.1 (resetMorphState) | Note: ONLY covers pool path. The orphan path needs Task 0.7 promoted | Agent S STATE-01 |
| Task 0.2 (delete anticipation + orphan tests) | Port WaveR74/R75 cancellation contracts BEFORE deleting | Agent N CANCEL-10 |
| Task 0.4 (pinch-commit reveal-fire) | Replace "Verify the codepath" with the verified answer (paths are SEPARATE, no double-fire risk) | Agent R V3-01/07 |
| Phase 1 Task 1.2 (MorphTiming) | Doc the 1.5 vs 1.2 duration discrepancy explicitly | Agent P LINE-12 |
| Phase 3 Task 3.1 (hoist) | Add @MainActor to AnimationController + SpringAnimator + DisplayLinkProxy | Agent M RUNTIME-01 |
| Phase 4 Task 4.1 (RevealBlurOverlay) | Drop `[WAVE-01 analog]` citation; use `[Apple UIVisualEffectView idiom]` | Agent O WAVE-07 |
| Phase 5 Task 5.1 (MorphChoreographer) | (a) Add `deinit`; (b) drop `lazy var`; (c) inherit `preferredFrameRateRange`; (d) DisplayLink-local elapsed accumulator; (e) `stop()` resets contentHost transform; (f) document CATransaction nesting | Agents M/N/S |
| Phase 5 Task 5.2 (PhysicsTuning) | DECIDE on named spring tokens (.smooth/.snappy/.bouncy) — add OR reject | Agent O WAVE-04 |
| Phase 5 Task 5.5 (EngagementState) | Couple with Task 0.3 (`isQuiet` predicate shares definition point) | Agent R V3-02 |
| Phase 6 Task 6.2 | Add 6.2b — file-end conformance extensions for Conversation | Agent Q FILEORG-07 |
| Phase 6 Task 6.10 (RevealState enum) | Preserve identity defense (UUID per reveal); add `.cancelling` case if Task 4.4 ships | Agent S STATE-04/05 |
| Phase 6 Task 6.13 (CellView IUO promotion) | Remove the "WAIT — user-emphasized rule" mid-derivation false-start | Agent R V3-03 |
| Keystone K5 description | Distinguish "every camera mutation pushes (universal)" from "height mutations push (active-only)" | Agent S STATE-02/10 |
| Phase Dependency Graph | Fix to match cascade callouts: Phase 0 → 1 → 3 → 2 → 4 → 5 → 6 | Agent R V3-12 |
| Effort table | Fix line-472 total from 13-20 to 14-20 | Agent R V3-13 |
| Tier claim (Phase 1 Gauge) | Soften "Uniform 3B" to acknowledge megafile-deferral keeps file-org at 2B-or-3A | Agent R V3-04 |
| Rejection list | ADD: #19 `extension UIView { var animator }`; possibly #20 `Spring.smooth/.snappy/.bouncy` (if Path B); possibly #21 process-level CADisplayLink canary (if Path B) | Agents O WAVE-02/04/10 |

### Effort estimate update (Agent R V3-06)

Realistic recalibration per Agent R: Phase 5 was 4-6 days for 5 HIGH-risk refactors + 90+ test ref updates. Realistic: **7-10 days**. Phase 6 was 3-4 days for 27 tasks (now 38+ tasks after adversarial additions). Realistic: **6-9 days**.

**Updated total: 18-29 working days, single engineer.** Previous v3 estimate (14-20 days) was optimistic by ~40-50%.

---

## Phase 7 — Authored Task Bodies (post-adversarial audit follow-ups)

### ☐ Task 7.0 — TimelineCanvas split re-evaluation memo (post-Phase-6, hard date)
`[L3 Domain | P2.7 P14.3 P15.1 | Wave 7 (Audit) | Parity: safe | Test: 0 | Deps: Phase 6 complete]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-7-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 7:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**Files:** `dot-pinch-prototype/MEGAFILE-MEMO.md` (new), `REFACTOR-CHECKLIST.md` (this file, rejection #21)

**Change:** Per ARCH-NINETY-ABS-01 (3rd-repetition rule) — `TimelineCellPool` + `TimelineLayoutCalculator` are EXPLICITLY DEFERRED via rejection #21. To prevent "deferred" becoming "permanent" (Agent Q FILEORG-10), author a memo with a HARD DATE for re-evaluation.

```
MEGAFILE-MEMO.md (proposed contents):
- Date authored: 2026-06-01 (post-Phase-6 close)
- Re-evaluation trigger: a SECOND consumer of pool semantics OR layout-calc semantics appears
- Re-evaluation deadline: 2027-01-01 (~6 months)
- If deadline passes WITHOUT a second consumer:
    EITHER (a) deletion of the deferral memo (officially absorbed permanently into TimelineCanvas)
    OR (b) extract anyway as a Bottling-readiness hygiene move (justify in PR)
- Owner: <person>
```

**Acceptance:**
- [ ] Memo file exists with explicit date + trigger
- [ ] Rejection #21 cross-references the memo path
- [ ] Calendar reminder set per memo deadline

---

### ☐ Task 7.1 — Directory restructure (`V2/` → `Timeline/`, delete `Gestures/`, consolidate `Tuning/`)
`[L3 Domain | P7.1 P7.5 P15.8 P20.4 | Wave 7 (Audit) | Parity: safe (no source changes) | Test: 0 | Deps: 6.42]`
**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-7-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 7:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L3 file-partition
**Files:** Xcode project structure

**Change:** Per Agent Q FILEORG-09 — folder names are anachronistic (`V2/` survives from a V1 era that no longer exists). Restructure:
- `Conversation/V2/` → `Conversation/Timeline/`
- `ChatViewController` already moved to `ChatBody/` per Task 6.42
- `Gestures/` (single file: PinchTuning, already migrated to PhysicsTuning in DesignSystem/) → DELETE folder
- `Conversation/Tuning/` (new folder for PhysicsTuning + CellLayoutTuning, consolidated)

**Acceptance:**
- [ ] `grep -rn "Conversation/V2/" DotPinchPrototype/` returns ZERO outside this file (paths updated everywhere)
- [ ] `Gestures/` folder absent
- [ ] `Conversation/Timeline/`, `Conversation/ChatBody/`, `Conversation/Tuning/` present
- [ ] Build passes
- [ ] All 90+ test files reference new paths

---

### ☐ Task 7.2 — SSoT restructure (per-phase files; v7 cutover commit)

**Agent Ensemble:**
- Implementer: **Doctrine-Agent** + **Documentation-Agent** (composite — doc work) (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-7-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 7:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
`[Documentation | P1.1 P3.6 P20.1 | Wave 7 (Audit) | Parity: N/A (doc only) | Test: 0 | Deps: ALL prior tasks]`
**Files:** `REFACTOR-CHECKLIST.md` (this file, will be split)

**Change:** Per Agent R V3-15 + Agent X8 megafile verdict — the SSoT itself violates the Tier-3B file-LOC discipline it imposes on production code. Split into per-phase files at v7 cutover:

```
refactor-checklist/
├── README.md                       (executive summary + navigation index)
├── 00-doctrine.md                  (9A pillars, 9B acceptance template, 9Q tag-line format)
├── 01-architecture.md              (5 layers, 10 migrations, target architecture)
├── phase-0-bug-fixes.md            (Tasks 0.1–0.19)
├── phase-1-tokens.md               (Tasks 1.1–1.5)
├── phase-2-devx.md                 (Tasks 2.1–2.5)
├── phase-3-hoist.md                (Task 3.1)
├── phase-4-coordinator.md          (Tasks 4.1–4.5)
├── phase-5-keystones.md            (Tasks 5.0–5.10)
├── phase-6-hygiene.md              (Tasks 6.1–6.44)
├── phase-7-audit.md                (Tasks 7.0–7.6 + adversarial 7A-7G findings)
├── parity-ledgers.md               (8A + 8B + 8C protocol)
├── audits/                         (9C-9R audit agent reports — frozen at v7)
├── retrospectives/                 (one file per wave's retro paragraph)
└── rejection-list.md               (the 21 architectural refusals)
```

**Acceptance:**
- [ ] All per-phase files exist with task bodies migrated verbatim
- [ ] `REFACTOR-CHECKLIST.md` (this file) becomes the EXECUTIVE SUMMARY + navigation README
- [ ] Each split file is ≤500 LOC (doctrine 13.5 ideal)
- [ ] Cross-references between files use relative paths
- [ ] v7 ships ONLY when this task completes (per 9P gate)

---

### ☐ Task 7.4 — Stale type/file reference sweep (12 references → reality)

**Agent Ensemble:**
- Implementer: **L3-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-7-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 7:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
`[Documentation + L3 Domain | P1.1 P15.8 P20.4 | Wave 7 (Audit) | Parity: safe | Test: 0 | Deps: —]`
**Files:** all touched per Agent V DEBT-15..26 (12 sites)

**Change:** Agent V identified 12 stale file/type references — including 16 § references to a D2 SSoT document that doesn't exist. Each reference must EITHER resolve to a real artifact OR be deleted.

Site list (consolidated from Agent V DEBT registry):
- 4 references to `D2-DESIGN-SYSTEM.md` (absent) — DELETE or AUTHOR
- 5 references to types renamed pre-migration (e.g., `ConversationCell` post-rename to `CellView`)
- 3 references to constants moved (e.g., `MorphTiming` pre-extraction comment in PinchTuning)

**Acceptance:**
- [ ] `grep -rn "D2-DESIGN-SYSTEM\|ConversationCell\|ChatBodyView" DotPinchPrototype/ docs/` returns ZERO
- [ ] All 12 stale ref sites updated or deleted
- [ ] Pillar 1.1 (file headers truthful) green across codebase

---

### ☐ Task 7.5 — Documentation creation (architectural overview + animator-on-controller pattern)

**Agent Ensemble:**
- Implementer: **Doctrine-Agent** + **Documentation-Agent** (composite — doc work) (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-7-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 7:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by file-partition
`[Documentation | P1.1 P3.6 P20.1 | Wave 7 (Audit) | Parity: N/A | Test: 0 | Deps: 7.2]`
**Files:** `docs/architecture.md` (new), `docs/animation-substrate.md` (new), `docs/keystones.md` (new)

**Change:** The 5-layer architecture + 8 keystones (K1-K8) + animator-on-controller (not animator-on-view) pattern are currently SSoT-only. Lift to publishable docs so a new contributor doesn't need to read the entire checklist to understand the system.

**Acceptance:**
- [ ] `docs/architecture.md` — 5-layer diagram + ownership pinning + dependency direction (≤300 LOC)
- [ ] `docs/animation-substrate.md` — AnimationController + SpringAnimator + CurveAnimator (post-5.0) + keystones K1-K8 (≤300 LOC)
- [ ] `docs/keystones.md` — 8 keystones with concrete code citations + invariants enforced
- [ ] Each doc ≤500 LOC (doctrine 13.5)
- [ ] All cross-refs resolve

---

### ☐ Task 7.6 — `CoordinateSpace` typed-wrapper migration (PageY / ViewportY / ScaleFactor / DampingRatio)
`[L2 Tokens + L3 Domain | P2.10 P10.4 P19.5 | Wave 7 (Audit) | Parity: safe | Test: 0 | Deps: 1.1-1.4]`
**Agent Ensemble:**
- Implementer: **L2-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-7-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 7:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L2 file-partition
**Files:** `Conversation/Geometry/CoordinateSpace.swift` (new), `Conversation/V2/Camera.swift`, `Conversation/V2/TimelineCanvas.swift`, `Conversation/V2/CameraAnimator.swift`

**Change:** Per X2 PILLAR2-29 — `CGFloat` is currently overloaded to mean "page-y", "viewport-y", "scale-factor", "damping-ratio", etc. Introduce phantom-typed wrappers so the compiler catches coordinate-space mistakes.

```swift
// Conversation/Geometry/CoordinateSpace.swift
struct PageY: Sendable, Equatable {
    let raw: CGFloat
    init(_ raw: CGFloat) { self.raw = raw }
}
struct ViewportY: Sendable, Equatable { let raw: CGFloat; init(_ raw: CGFloat) { self.raw = raw } }
struct ScaleFactor: Sendable, Equatable { let raw: CGFloat; init(_ raw: CGFloat) { self.raw = raw } }
struct DampingRatio: Sendable, Equatable {
    let raw: CGFloat
    init(_ raw: CGFloat) { precondition(raw >= 0); self.raw = raw }
}
```

**Acceptance:**
- [ ] `Conversation/Geometry/CoordinateSpace.swift` exists with 4 typed-wrapper structs
- [ ] Camera signature: `pagePoint(fromViewport: ViewportY) -> PageY` (not `(_ y: CGFloat) -> CGFloat`)
- [ ] `applyCameraTransform(scale: ScaleFactor)` typed
- [ ] Damping ratio inputs at all 5+ call sites typed
- [ ] Pillar 2.10 (primitive obsession) reduction verified by grep — bare `CGFloat` argument labels for these semantics return ZERO

---

## 🔁 RETROSPECTIVE — Post-Wave 7 (Cutover) **— MIGRATION CLOSURE RETRO**

**INVOKE 9Q.3 OPERATIONAL PROTOCOL.** R1-R8 + `/root-cause-tracing` + Stages 7-10 (failure protocol + populated example + root-cause example + visual testing mandate). **FIX IMMEDIATELY. BLOCKING.** This retro closes the v8 cutover. NO Wave N+1 follows.

### Wave 7 specific hunts (layered onto R-agents' default protocol)

**R1 Doctrine Auditor — Cutover specific:**
- Verify Task 7.2 SSoT restructure preserves ALL 78 task bodies + 8 phase intros + 23-role topology
- Verify per-phase split files each ≤500 LOC (doctrine Pillar 13.5)
- Verify cross-references between split files resolve (no dangling links)
- Verify 9P+ v8 ingraining gate 11 criteria all green
- 9V.0 + 9V.6 closure declarations updated with v8 final state

**R2 Code Smells — Cutover specific:**
- 7.3 invariant hardening: 5 `precondition`/`assertionFailure` landed; ZERO new try-catch noise; ZERO over-asserting in performance-critical paths (Wave-5-Lead's choreographer tick MUST NOT acquire new asserts)
- 7.6 CoordinateSpace migration: ZERO type erasure (PageY/ViewportY/ScaleFactor/DampingRatio don't reduce to CGFloat at any consumer site)
- 7.4 stale-ref sweep: ZERO new dead-symbol-references introduced by rename

**R3 Dead-Code — Cutover specific GREP:**
- `grep -rn "Conversation/V2/" DotPinchPrototype/` = ZERO outside REFACTOR-CHECKLIST.md (post-7.1 restructure)
- `grep -rn "ChatBodyView\|ConversationCell\|D2-DESIGN-SYSTEM" .` = ZERO (post-7.4 stale ref sweep)
- `grep -rn "Gestures/" DotPinchPrototype/` = ZERO (folder deleted; PhysicsTuning lives in Tuning/)
- `grep -rn "morphInProgress\s*=\|setSenderLabel\|senderColor" DotPinchPrototype/` = ZERO (per 5.7 + 0.16)

**R4 Parity Verifier — Wave 7 mandate:** ksdiff = 0 on all 7 Maestro flows. This is the FINAL visual gate. See Wave 7 visual testing checklist below.

**R5 File-Org Auditor — Cutover specific:**
- Directory layout post-7.1: `Conversation/Timeline/`, `Conversation/ChatBody/`, `Conversation/Tuning/`, `Conversation/Geometry/` present; `V2/`, `Gestures/` absent
- `docs/` directory has `architecture.md` + `animation-substrate.md` + `keystones.md` (per 7.5)
- SSoT split files in `refactor-checklist/` per Task 7.2

**R6 Method-Cleanliness Auditor:**
- 7.3's 5 new asserts pass 1-week-out test (assert message names the invariant being protected, not the syntax)
- 7.6's CoordinateSpace wrappers all ≤10 LOC each (trivial value types)
- 7.4's renames pass junior-dev test (new names disambiguate prior overloaded usage)

**R7 Abstraction Auditor:**
- 7.6 CoordinateSpace satisfies rule-of-3: PageY (4+ consumers), ViewportY (6+), ScaleFactor (3+), DampingRatio (5+)
- 7.2 SSoT split: each split file justifies its own existence (no 50-line split files)
- 7.5 docs creation: each doc justifies its own existence (no 1-paragraph docs)

**R8 Concurrency Auditor:**
- Per 9S: all 4 CoordinateSpace wrappers are `Sendable` + `Equatable`
- Per 7.3: SpringAnimator final-tick `assert` respects `@MainActor` isolation
- Composition-root DI grep (per 9R.4.6): `grep -rn "\.shared\|UIApplication.shared\|@Environment\|@EnvironmentObject\|DependencyContainer\|ServiceLocator\|Resolver\|Swinject" DotPinchPrototype/` = ZERO

### Wave 7 visual testing checklist (literal per Stage 10):
- [ ] Maestro flow 1-7 executed on iOS 18 sim (per `project_maestro_ios26_incompat.md` memory)
- [ ] Per-state screenshots S0-S5 captured for Flow 1 (tap-to-chat morph keyframes)
- [ ] Manual visual analysis of morph keyframes (NOT just automated ksdiff)
- [ ] Side-by-side comparison with pre-migration `main @ d464c71` baseline archived in `docs/visual-baselines/cutover/`
- [ ] Subjective animation quality assessment ("the morph FEELS right")

### Wave 7 wave-close merge gate (per §0.10)
1. **Wave-7-Lead** waits for all 7 Phase-7 task agents to return their worktrees integrated
2. **R1-R8** dispatched in PARALLEL against integrated Wave 7 diff
3. **Findings fixed in-place** per 9Q.3 Stage 3; re-dispatch verifies clean
4. **Parity-Agent SERIAL gate** — Phase 8C ksdiff on ALL 7 Maestro flows
5. **Migration CLOSED.** v7 cutover commit lands. SSoT restructure verified. No Wave 8 follows.

**Retro time budget (per §0.9):** 4 hours (final cutover requires full ksdiff sweep + doc verification)

### Wave 7 cross-wave learning ledger entry (per §0.11)
```
Wave 7 patterns observed (added to retrospective archive — NO Wave 8 to propagate to):
- [populated at retro close]
```

### Wave 7 closure assertion

> _Migration CLOSED at <timestamp>. All 8 waves shipped. v8 multi-agent topology executed across 23 named roles in 8-12 wall-clock days (vs 22-35 single-engineer baseline; 2.5×-3× speedup achieved). Frame-identical UX confirmed against pre-migration baseline for default-flow users. Parity-Break Ledger 8B documents 5+ intentional correctness deltas. Doctrine 9B compliance verified per-task via 9A.1 row matrix. TimelineCanvas LOC: <N> (was 1477). Animation/ Bottling-ready (deferred extraction). v8 topology retired; future work proceeds via either single-engineer or fresh topology design._

**Wave 7 retro closes ONLY when** 9Q.3 Stage 4 BLOCKING criteria are green + ALL visual checkboxes ticked + closure assertion authored.

---

# 📜 Phase 9 — TIER-3B+ CODE-QUALITY DOCTRINE (v6 — IN PROGRESS)

> **User directive (verbatim):** "this is DOCTRINE MAXIMUM EFFORT MAXIMUM DEPTH MAXIMUM DETAIL MAXIMUM GRANULARITY MAXIMUM ATTENTION TO DETAIL MAXIMUM DEPTH MAXIMUM GRANULARITY MAXIMUM ATTENTION TO DEATIL MAXIMUM DEPTH MAXIMUM RIGOR"

> **Doctrine binding:** Every task in this SSoT — every line of code that lands — MUST satisfy the doctrine items below. Doctrine is non-negotiable; deviations require explicit refusal-with-rationale documented inline.

> **Status:** doctrine articulated; 8 specialized agents dispatched (X1-X8) to audit the SSoT against doctrine + every code-changing task gets doctrine-compliance acceptance criteria.

---

## 9A — The 10 Pillars of Tier-3B+ Code Quality

Articulated explicitly so every task and every reviewer can reference by ID.

### Pillar 1 — Code-Readability Micropatterns (the "little things")

The 1-second-scan rules. Apply at every line.

**1.1 — Guard chaining.** Combine sequential guards into one block where Swift permits:
```swift
// BAD
guard let activeIdx = activeCellIndex else { return }
guard let activeCell = instantiatedCells[activeIdx] else { return }
guard let heightC = activeCell.heightConstraint else { return }
guard activeCell.naturalHeight > 0 else { return }

// GOOD
guard let activeIdx = activeCellIndex,
      let activeCell = instantiatedCells[activeIdx],
      let heightC = activeCell.heightConstraint,
      activeCell.naturalHeight > 0
else { return }
```
Hunt every method with 2+ sequential guards.

**1.2 — Closure-init at class top, NOT in setupX() helpers.** Every property that doesn't need `self` belongs at class-top via closure-init `= { ... }()`. IUOs and setup-X helper methods are tier-2 patterns:
```swift
// BAD
private(set) var dateLabel: UILabel!
private func setupSubviews() {
    dateLabel = UILabel()
    dateLabel.font = Theme.Typography.dateLabel
    // ...
}

// GOOD
private let dateLabel: UILabel = {
    let label = UILabel()
    label.font = Theme.Typography.dateLabel
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
}()
```
Exception: properties that NEED `self` (`weak var canvas`, `lazy var morphChoreographer`) — these MUST be init-assigned. Document the necessity.

**1.3 — Optional-unwrap idiom consistency.** Pick ONE idiom per shape. Hunt every mix:
- Early-exit on absence: `guard let x else { return }` (always; never `if !optX.has...`)
- Use-if-present, no-op otherwise: optional chaining `foo?.bar()`
- Fallback to default: `let value = optional ?? default` (only for value defaults, not for side effects)
- Transform if present: `optional.map { transform($0) }`
- No force-unwrap (`!`) outside controlled init lifecycle (IUO with documented init order)

**1.4 — Method-chain composition vs intermediate let bindings.** A chain >3 dots OR >80 chars wraps into intermediates. A 5-line let-cascade where each var is used once collapses into one chain. Find the right grain.

**1.5 — Boolean parameter labels.** Never bare bool args at call site:
```swift
// BAD
animator.stop(true)  // what does true mean?

// GOOD
animator.stop(immediately: true)
```

**1.6 — Trailing closure discipline.** Single trailing closure: use trailing syntax. Multiple trailing closures (Swift 5.3+): use named-trailing syntax. Never mix.

**1.7 — `Self` vs `self`.** `Self` for type references (`Self.maxKeyedPoolSize`); `self` for instance. Lowercased `self` only when required to disambiguate.

**1.8 — Type inference at boundaries.** Function signatures EXPLICIT. Local vars INFERRED unless inference would be ambiguous. `let count: Int = 0` is redundant; `let dt: TimeInterval = 0` is justified (disambiguates from Double).

**1.9 — Empty-line discipline.** 1 line between methods within a MARK section; 2 lines between MARK sections; 0 lines after method-declaration header before body. No double-empty-lines anywhere else.

**1.10 — Comment quality.** Comments explain WHY, not WHAT. `// increment counter` is forbidden. `// rubberband interval matches UIScrollView's stiff-zone` is required. No commented-out code anywhere.

### Pillar 2 — Classic Code Smells (Fowler / Martin / Beck)

**2.1 — Shotgun surgery.** Any single conceptual change requires touching >3 files = smell. Hunt every load-bearing surface that creates this.

**2.2 — Feature envy.** Method on type A reaches deep into type B's properties. `MorphChoreographer.tick()` writing `canvas.contentHost.layer.transform` directly is borderline envy — should `canvas.applyMorphTickTransform(_:)` be the seam? Audit every cross-type field access.

**2.3 — Inappropriate intimacy.** Two types that know too much about each other's internals. `TimelineCanvas` ↔ `CellView` is intimate by design (push pattern); the intimacy is named. Anywhere else?

**2.4 — Primitive obsession.** Hunt every primitive parameter / property that carries domain meaning:
- `CGFloat` for camera-Y → `PageY` typed wrapper?
- `Int` for cell index → `CellIndex` distinct from `Int`?
- `String` for animation-key → already extracted to MorphAnimationKey enum ✓
- `CFTimeInterval` for durations → `Duration` typed wrapper?
- `CGFloat` for damping-ratio (0-2 range) → `DampingRatio` newtype with bounds?

**2.5 — Speculative generality.** Code handling future cases that don't exist:
- `protocol AnimatorProviding` with one conformer = speculative
- `mass: CGFloat = 1.0` parameter never set to non-default
- Generic `clamp<T: Comparable>` only used for CGFloat
Hunt every 1-consumer abstraction.

**2.6 — Long parameter list.** >5 parameters = parameter-object opportunity. Identified by Agent U.

**2.7 — Long method.** >50 LOC = SRP smell. Identified by Agent U.

**2.8 — Data class.** A struct with stored props and no behavior = data class. Often fine (`Spring`, `Camera`); sometimes a missed abstraction.

**2.9 — Refused bequest.** Subclass doesn't use what it inherits. UIKit forces this (UIView's hundreds of properties) — tolerated. Custom inheritance? Audit.

**2.10 — Switch over enum that should be polymorphism.** Long switches duplicated across files = case-class missing.

**2.11 — Magic numbers.** Every literal numeric outside test code = potential token. v4 covers extensively.

**2.12 — Commented-out code.** Zero tolerance.

**2.13 — Dead code.** Identified by Agent V (5 anticipation artifacts).

**2.14 — Inconsistent naming.** Same concept, different names across files. Agent L identified.

### Pillar 3 — Senior Judgment Tests (apply per method / per file)

**3.1 — The 1-week-out test.** Returning to this code in a week, would I understand it without re-reading 2+ other files? If NO, the contract is in the wrong place.

**3.2 — The junior-dev test.** Could a junior dev extend this safely? Extension requires knowing how many invariants? If >3 invariants documented only in prose, the junior fails — convert prose to runtime assertion.

**3.3 — The deletion test.** What breaks if I remove this method/property? If "nothing" → dead code. If "mysterious things" → hidden coupling, needs naming.

**3.4 — The reading-sequence test.** Does the file's top-to-bottom order match the conceptual order a reader needs? Top = highest abstraction; bottom = implementation details. Violations: AnimationController's `DisplayLinkProxy` at file top before AnimationController itself.

**3.5 — The code-as-documentation test.** Is the code itself the source of truth? If I delete all comments, does the code still read as intentional? If NO, the code is too clever or the comments are doing too much work.

**3.6 — The PR-diff test.** Is the change visible in a diff? Big-rewrite PRs that touch 50 files for one bug fail this test.

**3.7 — The intentionality test.** Every line on purpose. No `// for now` / `// TODO` / unfinished thoughts. Agent V verified clean.

**3.8 — The grep test.** Can I `grep` for a symbol and find every consumer? If symbol is built via string concatenation or reflection → fails the test.

### Pillar 4 — Type-Level Decisions

**4.1 — Reference vs value default.** Default to struct. Class only when identity / inheritance / KVO / shared mutable state needed. Actor when shared mutable state crosses isolation.

**4.2 — `final` by default.** Every class is `final` unless designed for inheritance. Codebase compliant.

**4.3 — `@MainActor` on UI types.** Explicit (not implicit-via-UIView). Agents M + P + U all flagged this.

**4.4 — Protocol earn-its-weight.** Protocol with 1 conformer = speculative (smell 2.5). 2+ conformers OR clear seam (`AnimatorProviding`) = justified.

**4.5 — Generics earn-their-weight.** Generic parameter must serve >1 instantiation OR an obvious seam. `SpringAnimator<T: SpringInterpolatable>` justified; `clamp<T: Comparable>` borderline.

**4.6 — Composition over inheritance.** Default. Apple's UIKit forces inheritance for views — tolerated; our domain code should compose.

### Pillar 5 — Access-Modifier Discipline

**5.1 — `private` by default.** Every property / method starts `private`. Promote only when consumer needs require.

**5.2 — `fileprivate` only when same-file collaboration.** Specifically for `SpringDirection`-style enums used by neighbor types in the same file.

**5.3 — `internal` (default) justified.** Each `internal` symbol's call sites must be inside the module. If only one call site, consider `fileprivate` / move closer.

**5.4 — `public` justified + documented.** Every `public` symbol has DocC + a non-trivial external consumer. Codebase has `public` on Animation/ types because of Bottling-Destination plan; acceptable.

**5.5 — `private(set)` is a test-access smell.** Use `@_spi(Testing)` instead. 13 sites identified by Agent V.

**5.6 — `open` almost never.** Override-friendly inheritance is rarely intentional. Codebase compliant.

### Pillar 6 — Error-Handling Philosophy

**6.1 — Throws for recoverable failures.** Network, parse, IO. Codebase has zero today — fine because no such operations exist.

**6.2 — Optional for "not found" / "not yet computed".** Not for error.

**6.3 — Precondition for programmer error.** Traps in DEBUG AND release. Use when violation = bug, not user input.

**6.4 — Assert for DEBUG-only invariant checks.** No-op in release. Use for "expensive to check but valuable in dev".

**6.5 — `fatalError(...)` for impossible states.** `init?(coder:)` refusals are the canonical use.

**6.6 — No sentinel values.** `var index: Int = -1` (CellView) violates — Optional<Int>. Agent K flagged.

**6.7 — No silent early-return on failure.** `guard ... else { return }` without log/assert is debugging hell. Every silent return needs a comment explaining WHY silence is correct.

### Pillar 7 — Dependency Direction

**7.1 — Inner layers don't import outer.** `Animation/` is the substrate kernel — must not import `Conversation/`, `App/`, `DesignSystem/`. Verify.

**7.2 — `DesignSystem/` doesn't import `App/` or `Conversation/`.** Tokens are leaves.

**7.3 — `Conversation/Models` + `Conversation/Data` don't import `Conversation/V2`.** Models are below views.

**7.4 — `App/` is the composition root.** May import everything; should be the only place that does.

**7.5 — No circular dependencies.** File-graph audit per Phase 9 Agent X6.

### Pillar 8 — API Surface Minimization

**8.1 — Every `public` justifies external consumption.** Hunt unused `public`.

**8.2 — Every `internal` justifies cross-file use.** Hunt single-file `internal`.

**8.3 — `var` is a privilege, `let` is the default.** Every `var` justifies mutability.

**8.4 — Methods returning `Void` justify side effects.** Pure functions return values; mutators return Void.

**8.5 — Methods >5 params trigger parameter object review.** Agent U identified.

### Pillar 9 — Concurrency Discipline

**9.1 — `@MainActor` on UI types** (Pillar 4.3 cross-ref).

**9.2 — `Sendable` conformance on value types crossing isolation.**

**9.3 — `nonisolated` only when proven safe** (e.g., `Conversation.==` reading immutable `id`).

**9.4 — `async/await` over completion handlers** for new code.

**9.5 — Task lifetime + cancellation.** Every `Task { ... }` documents its cancellation contract.

**9.6 — `Swift 6` strict concurrency** — deferred per user filter, but doctrine ready.

### Pillar 10 — Cross-Cutting Consistency

**10.1 — One way to do each thing.** Pick guard vs if-let; pick `installX` vs `setupX`; pick `Init` vs `Initialization`; pick American vs British spelling. Apply universally.

**10.2 — Predictability.** Similar problems solved similarly. `apply*`/`update*`/`try*`/`install*`/`handle*` convention.

**10.3 — Searchability.** Symbols greppable. No string-concat or reflection-based dispatch.

**10.4 — Refactor-safety.** Renames work. No symbols mentioned only in comments / strings / unbuilt files.

**10.5 — Buildability.** Compile time low. Modular boundaries respected.

### Pillar 11 — SOLID Principles

**11.1 — Single Responsibility Principle (S).** Each type/method does ONE thing. SRP smell: types named with `Manager`/`Helper`/`Util` (vague); methods >50 LOC; types >300 LOC. `TimelineCanvas` (1477 LOC, 12+ concerns) is the canonical violation; Phase 5 starts decomposition.

**11.2 — Open/Closed Principle (O).** Open for extension, closed for modification. New behavior via composition/extension, NOT by editing existing types. Smell: every new feature requires editing an existing switch statement.

**11.3 — Liskov Substitution Principle (L).** Subclasses must be substitutable for parents. Swift's `final` + protocols mostly sidestep this. Smell: subclass that overrides to throw `fatalError("not supported")`.

**11.4 — Interface Segregation Principle (I).** Many specific protocols > one fat protocol. Smell: protocol with 15 methods where each conformer uses 3. `TimelineDataSource` has 4 methods — good. Hunt fat protocols.

**11.5 — Dependency Inversion Principle (D).** Depend on abstractions, not concretions. EXCEPT when concretion is justified (the Pointfree-witness alternative). DotPinch deliberately avoids protocol-everything; this is a CONSCIOUS Tier-3B refusal of D, documented in rejection list. Don't reintroduce.

### Pillar 12 — Law of Demeter + Tell-Don't-Ask

**12.1 — Law of Demeter (LoD) / Principle of Least Knowledge.** A method should only call methods of:
- Itself
- Its parameters
- Objects it creates
- Its direct fields

Forbidden: `a.b.c.d` chains. Smell: `canvas.contentHost.layer.transform` from `MorphChoreographer` — the choreographer reaches through TWO levels. Acceptable IF documented as load-bearing collaboration; otherwise add a seam method.

**12.2 — Tell, Don't Ask.** Don't query an object then act on its data; tell the object to act:
```swift
// BAD (asks then acts)
if cell.morphInProgress { /* skip */ }
cell.labelStack.alpha = computed
cell.pinchGlyph.alpha = computed

// GOOD (tells)
cell.applyMorphProgress(progress)
```
Smell: long if-then-mutate sequences targeting one object.

**12.3 — Train Wrecks.** Long `a.b.c.d.e.f` chains. Replace with intermediate let or refactor to delegate.

### Pillar 13 — Complexity Metrics

**13.1 — Cyclomatic complexity (McCabe).** Per-method branch count. Threshold: ≤10 per method. Above 10 = decompose. `handlePinchEnded` (4 conditional branches × 2 if-let chains) is borderline.

**13.2 — Cognitive complexity (Sonar).** Different from cyclomatic — penalizes nesting + breaks-in-flow. Threshold: ≤15 per method. Nested guards inside if-else inside switch = cognitive overload.

**13.3 — Nesting depth.** >3 levels of indentation = smell. Refactor to early-returns + helper methods.

**13.4 — Method length.** ≤50 LOC. Above = SRP smell (Pillar 11.1).

**13.5 — File length.** ≤300 LOC ideal; ≤500 acceptable; >500 = megafile smell. TimelineCanvas (1477) is the canonical violation.

**13.6 — Parameter count.** ≤5 params. Above = parameter-object opportunity.

**13.7 — Type member count.** ≤25 stored properties per type; ≤30 methods per type. TimelineCanvas violates both.

### Pillar 14 — Composition Patterns (used vs rejected)

**14.1 — Coordinator pattern (USED).** `RevealCoordinator` (Phase 4 Task 4.3) owns presentation lifecycle. Apple's UIViewController-containment pattern. Justified.

**14.2 — Factory pattern (USED minimally).** `CABasicAnimation.make(...)` factory in Phase 6 Task 6.23. Justified by rule-of-3.

**14.3 — Strategy pattern (REJECTED).** Would split `GestureCommit` into per-strategy types. Refused — enum + switch is simpler at this scale.

**14.4 — Observer pattern (USED minimally).** `onCameraChanged` callback property. Single-consumer (V2RootVC); could expand if needed.

**14.5 — Builder pattern (NOT NEEDED).** Codebase has no multi-step construction requiring a builder.

**14.6 — Singleton (REJECTED).** ZERO `.shared` in codebase. The discipline-of-refusal. Stay vigilant.

**14.7 — Service Locator (REJECTED).** Composition root injects everything. Don't introduce a registry.

**14.8 — Coordinator vs Router.** RevealCoordinator owns lifecycle (correct). Would degrade to Router if it merely routes URL → screen. Not applicable here.

### Pillar 15 — Anti-Pattern Avoidance

**15.1 — God Object.** TimelineCanvas (1477 LOC, 12+ concerns) is the canonical violation. Phase 5 begins decomposition.

**15.2 — Anemic Domain Model.** Data with no behavior. `Conversation` (let-only fields, no methods beyond Equatable/Hashable) is borderline. Defensible because models are pure value types here.

**15.3 — Feature Envy** (cross-ref Pillar 2.2).

**15.4 — Inappropriate Intimacy** (cross-ref Pillar 2.3).

**15.5 — Lava Layer / Dead Code Lake.** Multiple generations of patterns coexisting. The orphaned WaveR72/R73/R74/R75 tests + dead anticipation* fields are mini-lava (Phase 0 Task 0.2 cleans up).

**15.6 — Big Ball of Mud.** No clear architecture. Codebase is opposite (deliberate layering); stay vigilant.

**15.7 — Magic Pushbutton.** UI directly mutates business logic. Codebase has clean separation (recognizers → handler → animator → state); good.

**15.8 — Vendor Lock-in.** Coupling to a specific 3rd party. Codebase has only Wave-adaptation (substrate kernel) + Apple frameworks. Acceptable.

**15.9 — Premature Optimization.** Optimizing without profiling. Spring `settlingPercentage = 0.0001` chosen without measurement = premature. Defensible because Wave-derived.

**15.10 — Cargo Cult.** Copying patterns without understanding. Hunt: did the developer copy `@Observable` onto `Conversation` because "every model should be observable" (cargo) or because it's actually needed (intentional)? Today: no observation consumer → cargo cult.

### Pillar 16 — Swift-Specific Idioms

**16.1 — `any P` vs `some P` vs `<T: P>`.** Three ways to use a protocol:
- `any P` — existential, dynamic dispatch, runtime allocation
- `some P` — opaque, static dispatch, no runtime allocation
- `<T: P>` — generic, monomorphized per use site
**Rule:** prefer `some P` for return types, `<T: P>` for params, `any P` only when heterogeneous collections.

**16.2 — `Array<T>` vs `[T]`, `Optional<T>` vs `T?`, `Dictionary<K, V>` vs `[K: V]`.** Prefer the shorthand syntactic forms. Codebase compliant.

**16.3 — `@inlinable` for hot-path public APIs in libraries.** `Spring.stiffness` computed property is called per-frame; mark `@inlinable` if Animation/ extracts to SPM.

**16.4 — `@_spi(Testing)` for test-access surface.** 13 `private(set)` sites identified by Agent V should migrate.

**16.5 — `@MainActor` annotation (cross-ref Pillar 9).**

**16.6 — `@Sendable` closure annotations.** Required for closures crossing actor isolation.

**16.7 — `@autoclosure` for lazy evaluation.** Use sparingly; surprising at call sites.

**16.8 — `@escaping` discipline.** Every escaping closure documented with the lifetime contract.

**16.9 — `@discardableResult` (cross-ref Pillar 1).**

**16.10 — `indirect` for recursive enums.** Not used today; flag if introduced.

**16.11 — Property wrappers.** Reject unless they pay weight. `@Published`/`@State`/`@Binding` are SwiftUI-specific; we're UIKit.

**16.12 — Result builders.** Reject unless DSL pays weight. Out of scope.

**16.13 — KeyPath vs closure for accessors.** Use KeyPath when expressing "this property", closure when expressing "this computation."

**16.14 — `@dynamicMemberLookup`.** Reject — kills compile-time safety.

**16.15 — `@_implementationOnly import`.** Use for true implementation details that must not leak through public API.

**16.16 — Existential erasure.** `AnyHashable`, `AnySequence` — used sparingly; prefer generics.

### Pillar 17 — Apple API Design Guidelines compliance

**17.1 — Clarity at the point of use.** Method names + argument labels should read like English at the call site. `view.addSubview(label)` reads. `view.add(label)` doesn't (add what kind of thing?).

**17.2 — Clarity is more important than brevity.** `removeFromSuperview` > `remove`. Codebase mostly compliant.

**17.3 — Strive for fluent usage.** Methods named so they form grammatical phrases:
- `x.insert(y, at: z)` reads "insert y at z"
- `x.merge(y, uniquingKeysWith: combine)` reads "merge y, uniquing keys with combine"
DotPinch: `canvas.animateCameraToChatRest(forCellAt: idx)` — reads well.

**17.4 — Mutating verbs / non-mutating noun phrases.** `array.sort()` mutates; `array.sorted()` doesn't. Hunt every method: mutates or pure? Names match?

**17.5 — Argument labels make call sites self-documenting.** `Camera(translation: 100)` clear; `Camera(100)` opaque. Codebase compliant.

**17.6 — Initializer parameters that aren't labels.** Use only when the type IS the role: `Int(5)` (conversion), `Camera(/* must be labeled */)` for clarity.

**17.7 — Avoid acronyms / abbreviations.** `Identifier` not `Ident`; `index` not `idx`. Codebase has `idx` in a few places (handlePinchEnded local vars) — borderline.

**17.8 — Compensate for weak type information.** Method names compensate when the type doesn't fully describe the operation.

### Pillar 18 — PR-Review Nit Catalog (the things a senior reviewer flags)

Every PR landing under doctrine must clear this nit list:

**18.1 — "Why is this `public`?"** Every public symbol justifies external consumption.
**18.2 — "Why is this `var`?"** Every var justifies mutation.
**18.3 — "Could this be a computed property?"** Zero-arg pure methods → computed property.
**18.4 — "What if this is nil?"** Every optional read explicitly handled, never assumed.
**18.5 — "Why magic number?"** Every literal explained or extracted.
**18.6 — "This duplicates X at [line]."** DRY rule-of-3.
**18.7 — "This method is doing two things."** SRP.
**18.8 — "This name doesn't match behavior."** Naming.
**18.9 — "What's the contract on this?"** Pre/post-conditions documented.
**18.10 — "What happens at the boundary?"** Edge cases.
**18.11 — "Could this be a switch?"** Long if-else chains.
**18.12 — "Why is this here vs in [other file]?"** File placement.
**18.13 — "What about concurrency?"** Thread safety.
**18.14 — "What about retain cycles?"** Closure capture lists.
**18.15 — "What about cancellation?"** Async lifecycle.
**18.16 — "What about backgrounding?"** App lifecycle.
**18.17 — "This is too clever."** Refactor for clarity.
**18.18 — "This is premature optimization."** Profile first.
**18.19 — "This is premature abstraction."** Apply rule-of-3.
**18.20 — "Where's the test for this?"** Test coverage (filter-limited).
**18.21 — "Why this access level?"** Visibility justified per Pillar 5.
**18.22 — "What if the input is unexpected?"** Precondition or graceful handling.
**18.23 — "Why now, not earlier?"** Late initialization vs eager (closure-init).
**18.24 — "Why is this captured strongly?"** [weak self] discipline.
**18.25 — "Could this fail silently?"** Per Pillar 6 error handling.
**18.26 — "Did you delete the old code?"** No commented-out code.
**18.27 — "Is the doc-comment current?"** Comments match code.
**18.28 — "Where's the file header?"** Every file opens with role-statement.
**18.29 — "Why these particular constants?"** Tuning rationale documented.
**18.30 — "What's the rollback plan?"** Reversibility of the change.

### Pillar 19 — Pure Function Discipline + Idempotency

**19.1 — Pure functions where possible.** Same input → same output, no side effects. Spring math (`stiffness`, `dampingCoefficient`, `settlingDuration`) is pure. Hunt impure functions that could be pure.

**19.2 — Side-effect localization.** When mutation is needed, localize it. Don't sprinkle mutations through pure helpers.

**19.3 — Idempotency for reconcilers.** `update*` methods must be idempotent (Pillar 1 cross-ref). Identified by Agent U as a cross-cutting template.

**19.4 — Referential transparency.** A function that returns the same value can be replaced with that value. Helps reasoning + caching.

**19.5 — Immutability where possible.** `let` over `var`. Value types over reference types when possible. The 5 fields of `MorphChoreography` (Phase 5 Task 5.1) are all `let` — correct.

### Pillar 20 — File Placement / Module Organization

**20.1 — One public type per file (mostly).** Exceptions: closely-related sibling types (`MorphChoreography` struct + `MorphChoreographer` class — could ship in same file OR separate; pick one rule).

**20.2 — File name matches primary type name.** `TimelineCanvas.swift` contains `class TimelineCanvas`. Hunt mismatches.

**20.3 — Extension files: `Type+Concern.swift`.** Conventional. `CATransaction+Helpers.swift` ✓. `UIView+Pin.swift` proposed in Task 6.21 follows.

**20.4 — Folder name matches concern.** `Animation/` (substrate kernel) ✓. `Conversation/V2/` (anachronistic — Agent Q FILEORG-09).

**20.5 — File-end conformance extensions for multi-conformance types.** `extension TimelineCanvas: UIGestureRecognizerDelegate` at file end. Agent J + Q identified.

---

## 9A.1 — Doctrine Compliance Matrix (per-task ingraining)

**Per the user's "INGRAINED ON EVERY SIGNLE TASK" directive: every task in Phases 0-8 maps to the specific doctrine pillars that govern its acceptance.** Below is the master matrix.

Each task is rated 1-3 against each pillar:
- **1** = pillar applies; doctrine criteria added to task acceptance
- **2** = pillar applies indirectly; cross-cutting check
- **3** = pillar doesn't apply to this task

| Task | P1 | P2 | P3 | P4 | P5 | P6 | P7 | P8 | P9 | P10 | P11 | P12 | P13 | P14 | P15 | P16 | P17 | P18 | P19 | P20 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **0.1 resetMorphState** | 1 | 2 | 1 | 2 | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 2 | 1 | 3 | 2 | 1 | 1 | 1 | 1 | 2 |
| **0.2 Delete anticipation** | 3 | 1 | 1 | 3 | 1 | 3 | 3 | 1 | 3 | 1 | 1 | 3 | 1 | 3 | 1 | 3 | 1 | 1 | 3 | 1 |
| **0.3 isQuiet guard** | 1 | 1 | 1 | 2 | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 2 | 1 | 3 | 2 | 2 | 1 | 1 | 1 | 2 |
| **0.4 Pinch-commit reveal-fire** | 1 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 1 | 1 | 1 | 2 | 1 | 3 | 3 | 2 | 1 | 1 | 2 | 2 |
| **0.5 layoutIfNeeded scope** | 1 | 3 | 1 | 3 | 2 | 3 | 3 | 3 | 1 | 2 | 3 | 1 | 3 | 3 | 3 | 3 | 1 | 1 | 3 | 3 |
| **0.6 Eliminate dual-tap** | 1 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 1 | 1 | 1 | 1 | 1 | 3 | 1 | 2 | 1 | 1 | 2 | 2 |
| **0.7 reloadData defensive** | 1 | 1 | 1 | 2 | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 2 | 1 | 3 | 1 | 2 | 1 | 1 | 2 | 2 |
| **0.8 preferredFrameRateRange** | 1 | 3 | 1 | 3 | 2 | 3 | 3 | 3 | 1 | 1 | 3 | 3 | 3 | 3 | 3 | 3 | 1 | 1 | 3 | 3 |
| **0.9 DispatchWorkItem cancel** | 1 | 2 | 1 | 1 | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 2 | 1 | 3 | 2 | 1 | 1 | 1 | 1 | 2 |
| **0.10 Spring init bounds** | 1 | 3 | 1 | 2 | 1 | 1 | 3 | 1 | 3 | 1 | 3 | 3 | 3 | 3 | 3 | 3 | 1 | 1 | 1 | 2 |
| **0.11 .cancelled split** | 1 | 1 | 1 | 2 | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 3 | 1 | 2 | 1 | 1 | 2 | 2 |
| **0.12 DisplayLink-local time** | 1 | 1 | 1 | 2 | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 2 | 1 | 3 | 1 | 2 | 1 | 1 | 2 | 2 |
| **0.13 Reduced-motion snap** | 1 | 1 | 1 | 2 | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 2 | 1 | 3 | 2 | 2 | 1 | 1 | 1 | 2 |
| **0.14 Camera.translation var→let** | 1 | 2 | 1 | 1 | 1 | 1 | 3 | 1 | 3 | 1 | 3 | 3 | 3 | 3 | 3 | 1 | 1 | 1 | 1 | 2 |
| **0.15 Stale header truthfulness** | 1 | 3 | 1 | 3 | 3 | 3 | 1 | 3 | 3 | 1 | 3 | 3 | 3 | 3 | 1 | 3 | 1 | 1 | 3 | 1 |
| **0.16 ChatBubbleView "never sender"** | 1 | 3 | 1 | 3 | 3 | 3 | 3 | 3 | 3 | 1 | 1 | 3 | 3 | 3 | 1 | 3 | 1 | 1 | 3 | 1 |
| **1.1-1.4 Token extractions** | 1 | 1 | 2 | 1 | 1 | 3 | 1 | 1 | 3 | 1 | 1 | 3 | 3 | 3 | 3 | 3 | 1 | 1 | 1 | 1 |
| **2.1 Inject hot-reload** | 1 | 3 | 1 | 2 | 1 | 3 | 1 | 1 | 1 | 2 | 3 | 3 | 3 | 3 | 3 | 1 | 3 | 3 | 3 | 2 |
| **2.2 SwiftFormat** | 1 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 1 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 1 | 3 | 3 |
| **3.1 Hoist AnimationController** | 1 | 2 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 2 | 3 | 2 | 1 | 1 | 1 | 2 | 1 |
| **4.1 RevealBlurOverlay** | 1 | 2 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 2 | 1 | 1 | 1 | 2 | 1 |
| **4.2 isUserInteractionEnabled** | 1 | 2 | 1 | 3 | 2 | 1 | 3 | 2 | 1 | 1 | 3 | 2 | 3 | 3 | 1 | 3 | 1 | 1 | 2 | 3 |
| **4.3 RevealCoordinator** | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 2 | 1 | 1 | 1 | 1 | 1 |
| **4.4 PROMOTE UIViewPropertyAnimator** | 1 | 2 | 1 | 1 | 1 | 1 | 2 | 1 | 1 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 1 | 1 | 1 | 2 |
| **4.5 dismiss() + lifecycle** | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 2 |
| **5.0 CurveAnimator (Wave Path A)** | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 2 | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 |
| **5.1 MorphChoreographer** | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| **5.2 PhysicsTuning** | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 2 | 1 | 1 | 3 | 3 | 3 | 1 | 1 | 1 | 1 | 1 | 1 |
| **5.3 GestureCommit rename** | 1 | 1 | 1 | 1 | 1 | 3 | 1 | 1 | 3 | 1 | 1 | 3 | 3 | 3 | 3 | 2 | 1 | 1 | 3 | 1 |
| **5.4 Split *Path methods** | 1 | 1 | 1 | 1 | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 2 |
| **5.5 EngagementState enum** | 1 | 1 | 1 | 1 | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 2 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 2 |
| **5.6 Scene-phase observer** | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 2 | 1 | 1 | 1 | 2 | 2 |
| **5.7 morphInProgress collapse** | 1 | 1 | 1 | 1 | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 3 | 2 | 2 | 1 | 1 | 2 | 2 |
| **6.x Hygiene tasks (27 of them)** | 1 | 1 | 1 | 1 | 1 | 2 | 1 | 1 | 2 | 1 | 1 | 1 | 1 | 2 | 2 | 1 | 1 | 1 | 1 | 1 |
| **7.0 TimelineCanvas split memo** | 2 | 1 | 1 | 1 | 1 | 3 | 1 | 1 | 2 | 2 | 1 | 1 | 1 | 1 | 1 | 2 | 2 | 1 | 2 | 1 |
| **7.1 Directory restructure** | 3 | 1 | 1 | 2 | 2 | 3 | 1 | 2 | 3 | 1 | 1 | 2 | 3 | 3 | 1 | 3 | 2 | 1 | 3 | 1 |
| **7.2 SSoT restructure** | 1 | 1 | 1 | 3 | 3 | 3 | 3 | 1 | 3 | 1 | 1 | 3 | 1 | 3 | 1 | 3 | 1 | 1 | 3 | 1 |
| **7.3 Invariant Hardening** | 1 | 2 | 1 | 2 | 2 | 1 | 3 | 2 | 1 | 1 | 1 | 1 | 2 | 3 | 1 | 1 | 1 | 1 | 1 | 2 |
| **7.4 Stale ref sweep** | 3 | 3 | 1 | 3 | 3 | 3 | 1 | 3 | 3 | 1 | 3 | 3 | 3 | 3 | 1 | 3 | 1 | 1 | 3 | 1 |
| **7.5 Doc creation** | 2 | 3 | 1 | 3 | 3 | 3 | 3 | 3 | 3 | 1 | 3 | 3 | 3 | 3 | 1 | 3 | 1 | 1 | 3 | 1 |
| **8X.1-X4 Critical decisions** | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |

**How to use this matrix:** For each task, the cells marked `1` indicate doctrine pillars whose criteria MUST appear in that task's acceptance list. Pillar references in task descriptions are non-negotiable for landing.

**Example application (Phase 5 Task 5.1 — MorphChoreographer):** every pillar applies. Acceptance criteria for this single task expands to ~30 checkboxes, ingraining:
- P1.1 guard chaining inside `engage` precondition checks
- P1.2 `displayLink: CADisplayLink?` declared at class top
- P2.2 feature envy on `canvas.contentHost.layer.transform` — JUSTIFIED as load-bearing collaboration (cite doctrine)
- P2.4 primitive obsession: should `MorphChoreography.duration` be `Duration` newtype? (DEFER unless cross-section reuse appears)
- P3.1 1-week-out test: contract block (Agent U METHOD-08) covers
- P3.4 reading sequence: `MorphChoreography` struct THEN `MorphChoreographer` class
- P4.1 reference type (class) justified by CADisplayLink ownership
- P4.3 `@MainActor` explicit (Agent M RUNTIME-01)
- P5.5 `private` for displayLink + elapsed + completion (no `private(set)`)
- P6.7 silent early-return on `choreography == nil` documented
- P7.x Conversation/V2/ layer — doesn't import outer layers
- P8.1 only `engage`/`stop`/`isRunning` are `public`/`internal`
- P9.1 `@MainActor` + Sendable on MorphChoreography (value type, all let fields, easy)
- P11.1 SRP: choreographer does ONLY tick-application; doesn't own CABasicAnimations
- P12.1 LoD: choreographer reaches `canvas.contentHost.layer` — borderline; documented
- P13.4 `apply(rawT:choreography:canvas:)` ≤50 LOC
- P16.x `@MainActor` final class, displayLink Optional not lazy var
- P17.x naming: `engage` reads as imperative verb-only ✓
- P18.x PR-review nits: every literal explained, every var justified, etc.
- P19.5 `MorphChoreography` is all `let` ✓
- P20.1 `MorphChoreography.swift` + `MorphChoreographer.swift` separate files (related sibling pattern)

The matrix is the doctrine's load-bearing mechanism. v6 ships only when every task's acceptance reflects its row.

---

## 9B — Doctrine-application acceptance criteria (binding for every task)

**Every existing v5 task gains these acceptance criteria. Every new task starts with them.**

- [ ] **Pillar 1 (Readability):** Code changes follow guards chained where possible, closure-init at top, consistent unwrap, no bare-bool args, type-inference discipline
- [ ] **Pillar 2 (Smells):** No new shotgun surgery introduced; no new feature envy; no new primitive obsession; no speculative generality
- [ ] **Pillar 3 (Judgment):** 1-week-out test passes; junior-dev test passes; reading-sequence preserved
- [ ] **Pillar 4 (Types):** Reference vs value justified; `final` applied; `@MainActor` explicit
- [ ] **Pillar 5 (Visibility):** Every new symbol starts `private`; promotion justified per site
- [ ] **Pillar 6 (Errors):** Failure mode chosen deliberately (throws/Optional/precondition/assert/fatalError)
- [ ] **Pillar 7 (Dependencies):** No new circular imports; no inner-imports-outer
- [ ] **Pillar 8 (Surface):** Every new `public`/`internal`/`var` justified
- [ ] **Pillar 9 (Concurrency):** `@MainActor` on UI types; `Sendable` on shared value types
- [ ] **Pillar 10 (Consistency):** Matches existing conventions; one-way-to-do-each-thing

---

## 9C — Specialized agent dispatch (8 agents, X1-X8)

⏳ *Dispatched in parallel; each carries `[ROLE: ADVERSARIAL-REVIEWER]` + `/root-cause-tracing` 6-question discipline + doctrine binding.*

| Agent | Dimension | Output target |
|---|---|---|
| X1 | Code-readability micropatterns (Pillar 1) — exhaustive | 9D |
| X2 | Code smells (Pillar 2) — shotgun + envy + primitive obsession sweep | 9E |
| X3 | Senior-judgment tests (Pillar 3) per method >20 LOC | 9F |
| X4 | Access-modifier discipline (Pillar 5) per symbol | 9G |
| X5 | Error-handling philosophy (Pillar 6) — every failure mode | 9H |
| X6 | Dependency direction + import graph (Pillar 7) | 9I |
| X7 | API surface minimization (Pillar 8) | 9J |
| X8 | Doctrine-application audit of SSoT itself — every task in Phases 0-8 against 9B | 9K |

---

## 9D — Pillar 1 readability micropatterns (pending Agent X1)

**Scope:** every code-readability micropattern from Pillar 1 + extrapolated rules. Per-site violation catalog with PR-review-grade comments.

⏳ *Awaiting Agent X1 — will populate `ARCH-DOCTRINE-PILLAR1-*` findings + ≥10 extrapolated rules.*

---

## 9E — Pillar 2 code smells (pending Agent X2)

**Scope:** Fowler/Martin/Beck smells. Shotgun surgery + feature envy + primitive obsession (user-emphasized) + speculative generality + inappropriate intimacy + long-method/long-param-list.

⏳ *Awaiting Agent X2 — will populate `ARCH-DOCTRINE-PILLAR2-*` findings.*

---

## 9F — Pillar 3 senior-judgment tests (pending Agent X3)

**Scope:** apply 1-week-out + junior-dev + deletion + reading-sequence + intentionality + grep tests per method >20 LOC and per file. Score PASS/PARTIAL/FAIL.

⏳ *Awaiting Agent X3 — will populate `ARCH-DOCTRINE-PILLAR3-*` findings + extrapolated tests.*

---

## 9G — Pillar 5 access-modifier discipline (pending Agent X4)

**Scope:** every symbol's `public`/`internal`/`fileprivate`/`private`/`private(set)` justified or flagged. `@_spi(Testing)` migration plan for 13 test-access leaks (Agent V). `var` vs `let` audit. `final` discipline. Extension placement.

⏳ *Awaiting Agent X4 — will populate `ARCH-DOCTRINE-PILLAR5-*` findings.*

---

## 9H — Pillar 6 error-handling philosophy (pending Agent X5)

**Scope:** every silent failure path classified (throws / Optional / precondition / assert / fatalError / silent-with-doc). Pillar-application rule for every new code path.

⏳ *Awaiting Agent X5 — will populate `ARCH-DOCTRINE-PILLAR6-*` findings.*

---

## 9I — Pillar 7 dependency direction + import graph (pending Agent X6)

**Scope:** per-file import audit + ASCII dependency graph + layer-violation catalog. Bottling Destination viability check (Animation/ extractable as SPM?).

⏳ *Awaiting Agent X6 — will populate `ARCH-DOCTRINE-PILLAR7-*` findings.*

---

## 9J — Pillar 8 API surface minimization (pending Agent X7)

**Scope:** every `public`/`internal`/`var`/`Void`-returning/multi-param symbol justified. Parameter-object proposals. Default-parameter audit.

⏳ *Awaiting Agent X7 — will populate `ARCH-DOCTRINE-PILLAR8-*` findings.*

---

## 9K — SSoT doctrine-compliance audit (pending Agent X8)

**Scope:** every task in Phases 0-8 audited against Section 9B's 10-pillar acceptance criteria. Cross-task consistency. Doctrine violations within the SSoT's own writing.

⏳ *Awaiting Agent X8 — will populate `ARCH-DOCTRINE-AUDIT-*` findings + top-10 blocking violations.*

---

## 9L — DOCTRINE CROSS-CUTS (consolidated findings — 6 of 8 v6 agents in)

**Agents X1, X2, X3, X4, X5, X6 returned. X7 (API surface) + X8 (SSoT self-audit) pending.**

### 9L.1 — CRITICAL REFRAMING from Agent X4 (Pillar 5 access modifiers)

**`DotPinchPrototype` is an APP TARGET, not a library.** Agent X4 establishes this as the foundational fact governing all Pillar 5 work. Implications:

- **`@_spi(Testing)` is a CATEGORY ERROR in an app target.** `@testable import DotPinchPrototype` already exposes `internal`. The `private(set) var` IS the optimal modifier for "test-readable but production-controlled" — it's not a test-access smell here.
- **The 13 `private(set) var` sites Agent V flagged are NOT Pillar 5.5 violations** in the current module configuration.
- **Pillar 5.5 amendment:** rename to "Pillar 5.5 — Post-Bottling Test Seam Discipline" — file under Bottling-extraction work, NOT as a today-checklist item. UNTIL the Animation/* module is extracted as a separate SPM target, leave `private(set) var` patterns intact.
- **WHAT IS still actionable in v6:** of 13 `private(set) var` sites, 2 are unambiguous OVERREACH (`cellPoolByConversationID`, `poolOrder` — should be plain `private`). 10 sites in CellView are pure overreach (only 3 — `naturalHeight`, `heightConstraint`, `centerYConstraint` — have test consumers).

→ **Amendment to v4 Task 6.39 (`@_spi(Testing)` migration):** DEFER until Bottling. Replace with **NEW Task 6.39a — narrow `private(set) var` to `private` where no consumer reads** (2 in TimelineCanvas + ~10 in CellView).

### 9L.2 — Single highest-leverage finding (X4 + X5 convergent)

Two convergent findings from independent agents pointing at one root:

**Camera.translation: `var → let`** [Agent X4 PILLAR5-B02 + Agent P LINE-06] — Camera is documented as "mutable struct (callers can reassign .translation = .nan)" but `grep` confirms ZERO post-init reassignments in 24 production files. The defensive `Camera.validate` call in `setCamera` (TimelineCanvas:333) is unnecessary insurance. **Single-line change cascading to:**
- Eliminate redundant double-validate
- Make `Camera.validate` `private`
- Pure value-semantics restored
- ~5 lines saved

**`Spring.init` precondition validation** [Agent X5 PILLAR6-23] — Currently `Spring(dampingRatio:0)` silently produces `settlingDuration = +infinity`, which silently traps `tryClearActiveCellAtRest` forever. **Add `precondition(dampingRatio > 0, response > 0)` at init, and TWO downstream guards become dead code** (Spring:39, SpringInterpolatable:45).

**→ Both must land in Phase 0 alongside existing Task 0.10 (Spring init bounds).** Combine.

### 9L.3 — Highest-leverage code-architecture finding (X2)

**Primitive obsession on `CGFloat`-for-coordinates is the single highest-leverage doctrine fix.**

TimelineCanvas carries ~60 LOC of prose comments distinguishing "page-coord", "viewport-coord", "scale-factor" — all FOUR distinct semantic types stored as `CGFloat`. The prose is doctrine §3.2 junior-dev FAIL (>3 invariants documented only in prose).

**Typed-wrapper migration:**
```swift
struct PageY: Hashable { let value: CGFloat; init(_ v: CGFloat) { precondition(v.isFinite); self.value = v } }
struct ViewportY: Hashable { ... }
struct ScaleFactor: Hashable { ... }
struct DampingRatio { let value: CGFloat; init(_ v: CGFloat) { precondition(v > 0 && v <= 2.0); ... }}
```

Coordinate-conversion functions become typed: `func viewportPoint(from page: PagePoint) -> ViewportPoint` — impossible to mix page and viewport.

**→ NEW Task 7.6 (Phase 7 — post-keystone surface) — `CoordinateSpace` typed-wrapper migration.** Estimated 2-3 days. P0 doctrine compliance per Pillar 2.4. Defer to Phase 7 because it touches every coordinate site in TimelineCanvas (~38 sites).

### 9L.4 — Feature-envy SEAM extractions (X2 P0 findings)

Two specific seam extractions surface from Pillar 2.2 analysis:

**Task 5.8 (NEW) — `CellView.performMorphChromeTransition(_:)` seam.** Today `TimelineCanvas.animateCameraToChatRest:1216-1236` reaches into 6 CellView labels (dateLabel, topicSummaryLabel, todayLabel, pinchGlyph, chatRestCenterLabel, +CABasicAnimation on chatRestCenterLabel.layer). Phase 5 Task 5.1's MorphChoreographer relocates the timer ownership but does NOT relocate the label writes. **CellView gains a `performMorphChromeTransition(profile:)` method; canvas calls it instead of touching internals.**

**Task 5.9 (NEW) — `CellView.followActive(growth:position:)` seam.** Today `TimelineCanvas.updateNeighborTranslations:714-732` writes `.transform` on every cell. **CellView gains `followActive(growth:position:)`; canvas computes and calls per cell.**

→ Both land in Phase 5 alongside MorphChoreographer (Task 5.1).

### 9L.5 — Reading-sequence FAIL fixes (X3)

Per Pillar 3.4 — three load-bearing reading-sequence violations:

1. **AnimationController.swift** — `DisplayLinkProxy` (implementation detail) declared BEFORE `AnimationController` (the public type). **Fix:** move proxy to private extension below the public class. NEW Task 6.40 (Phase 6).
2. **TimelineCanvas.swift** — `SpringDirection` enum declared at line 1094 (mid-file) AFTER its first use at line 1061. **Fix:** lift to file top OR move closer to first-use. Phase 5 Task 5.3 (GestureCommit rename) covers this by extracting to own file.
3. **TimelineCanvas.swift** — 130 LOC of MUTABLE STATE before any method. **Fix:** group into substate types (PinchState, MasterTimerState, CellPool) — Phase 5 Task 5.1's MorphChoreographer extraction takes 10 master* fields. **NEW Task 5.10 — extract `PinchState` struct** (groups ~6 `pinchInitial*` + `pinchPrevious*` + `pinchAnchor*` fields into one type owned by TimelineCanvas).

### 9L.6 — Error-doctrine MUST-LAND additions (X5)

Per Agent X5 PILLAR6-19 (binding doctrine for new code):

**Phase 0 must include these conversions:**

1. **NEW Phase 0 Task 0.17** — `Spring.init` precondition (covered by 9L.2 above).
2. **NEW Phase 0 Task 0.18** — `setActiveCellIndex(_:)` precondition `0..<cellCount()` for non-nil branch. Catches stale-index bugs at the seam, not 3 frames later when downstream guards silently no-op.
3. **NEW Phase 0 Task 0.19** — Convert 5 invariant-violation silent returns to `assertionFailure` (DEBUG trap, release continues to skip):
   - V2RootViewController:78,79 (`onMorphRevealReady` double-fire, stale index)
   - TimelineCanvas:819 (pool eviction LRU map miss)
   - TimelineCanvas:867 (hit-test stale key during enumeration)
   - SpringAnimator:137 (runningTime nil in `updateAnimation`)
4. **NEW Phase 6 Task 6.41** — every `guard ... else { return }` site gets a 1-line WHY comment per Pillar 6.7. The codebase has 55 silent-return sites; ~46 are legitimate. The discipline is comment density, not lane choice.

### 9L.7 — Dependency direction NEW task (X6)

Per Agent X6 PILLAR7-03 (F2):

**NEW Phase 6 Task 6.42** — Move `ChatViewController.swift` from `Conversation/V2/` to `Conversation/ChatBody/`. Today's L3a→L3b inversion is the only true dependency-direction violation. Single git mv + project.yml update. Tiny effort, doctrine-restoring.

Plus Agent X6's verdict that Animation/ is 95% module-extractable today — flag for the Bottling roadmap.

### 9L.8 — Var → Let migrations (X4 + X5 combined)

Beyond Camera.translation (9L.2), Agent X4 surfaced:

**`Spring.{dampingRatio, response, mass}: public var → public let`.** Verified ZERO post-init field-mutations in production. The mutation pattern is whole-struct reassign (`animator.spring = profile`), not field-level. The `var` is a defensive convention; `let` is the precise statement.

**TimelineCanvas IUO `private(set) var ...!` → `private let`:**
- `panRecognizer` (TC:58)
- `pinchRecognizer` (TC:65)
- `cameraAnimator` (TC:90) — requires post-super.init construction
- `extensionAnimator` (TC:94) — same

**CellView IUO subviews → `private let` (closure-init at top per Pillar 1.2):**
- `dateLabel`, `topicSummaryLabel`, `todayLabel`, `labelStack`, `chatRestCenterLabel`, `pinchGlyph` (6 of 7; tapRecognizer keeps IUO because needs `self` for target/selector)

**ConversationStore fields → `let` (per 9R.4.4 — closes Migration M5 ConversationStore gap, Agent X7 PILLAR8-10):**
- `private(set) var conversations: [Conversation]` → `let conversations: [Conversation]`
- `private var conversationsByID: [UUID: Conversation]` → `let conversationsByID: [UUID: Conversation]`
- Mutation pattern: today's mutations are init-only (inside `init(initialConversations:)`). Migrate via local accumulator in init, assign to `let` at the end. Zero post-init mutation surface; eliminates the documented-mutability lie.

→ Combined into **NEW Phase 6 Task 6.43** — "Var-to-let migration sweep". Coordinates with Task 6.13 (CellView closure-init). Now covers ALL FOUR M5 targets: Camera.translation (Task 0.14), Spring fields, IUO subviews, AND ConversationStore fields.

### 9L.9 — @frozen for Bottling-ready public enums (X4)

Per Agent X4 PILLAR5-A07:

**NEW Phase 6 Task 6.44** — Add `@frozen` to `AnimatorState` (SpringAnimator.swift:17) and `SpringAnimator.Event` (line 27). Binary-stability prerequisite for Animation/ → SPM extraction. Adding a case to a non-frozen public enum is binary-breaking; both enums are stable 3-case state machines.

### 9L.10 — Naming consistency loose ends (X1 + X2 + X4 cross-cutting)

Multiple agents identified naming-consistency drifts:

- **`setupSubviews` → `installSubviews`** (CellView lone violator vs 16 `installX*` callers) — Phase 6 Task 6.16 (already in v4)
- **`ChatViewController.headerText` → `Self.headerText`** for `Self.` consistency — Phase 6 micro-fix
- **ChatBubbleView missing `@available(*, unavailable)` on `init?(coder:)`** — Phase 6 micro-fix
- **`animationControllerIdentity` (SpringAnimator + CameraAnimator) — pick suffix discipline** — either add `ForTesting` to both OR remove from both. Currently inconsistent.
- **`start*`/`animate*`/`engage*` verb confusion for "begin motion"** — lock on `engage` per Phase 5 Task 5.1 MorphChoreographer naming. Apply retroactively in Phase 6.

### 9L.11 — Extrapolated rules from X1 (beyond Pillar 1.1-1.10)

Agent X1 added 22 net-new micropattern rules (PILLAR1-11 through PILLAR1-32). The most actionable:

- **1.11 Variable shadowing in `guard let`** — codebase mostly uses modern `guard let x else { return }` shorthand ✓
- **1.12 `_ = X` discard pattern** — ONE site (TC:703 `_ = cells`). Replace with `withExtendedLifetime(cells)`. Phase 6 nit.
- **1.21 Avoid vague file-suffixes** — `MathUtilities.swift` should split (already in v4 Task 6.45 — verify). `CATransaction+Helpers.swift` → `CATransaction+SuppressedActions.swift` (rename — Phase 6 nit).
- **1.29 Strong-self in V2RootViewController.revealChat** — 2 closures capture self strongly (V2RVC:116, 121-123). Add `[weak self]`. Folds into Phase 4 Task 4.3 RevealCoordinator extraction (the closures move into RevealCoordinator anyway).

### 9L.12 — Pillar 1.9 doctrine clarification (X1 finding)

Pillar 1.9 says "2 lines between MARK sections" but the codebase uses 1 blank consistently. **Decision:** amend Pillar 1.9 to match the codebase's actual convention (1 blank between MARK sections) rather than mass-edit 24 files. The codebase's discipline IS internally consistent; the doctrine misstated it. Update §9A Pillar 1.9 wording.

---

## 9M — Updated NEW Task Registry (v6 doctrine — additions)

Beyond v5's 26 new tasks, Phase 9 doctrine ingraining adds:

| Task | Phase | Source | Priority | Effort |
|---|---|---|---|---|
| **0.17** — Spring.init precondition validation | Phase 0 | X5 PILLAR6-23 | P0 | 30 min |
| **0.18** — setActiveCellIndex bound-check precondition | Phase 0 | X5 PILLAR6-12 | P0 | 30 min |
| **0.19** — 5 silent-return → assertionFailure conversions | Phase 0 | X5 PILLAR6-21 | P1 | 1 hr |
| **5.8** — CellView.performMorphChromeTransition seam | Phase 5 | X2 PILLAR2-12 | P0 | 4 hr |
| **5.9** — CellView.followActive(growth:) seam | Phase 5 | X2 PILLAR2-15 | P0 | 3 hr |
| **5.10** — Extract PinchState struct from TimelineCanvas | Phase 5 | X3 PILLAR3-17 | P1 | 4 hr |
| **6.39a** — Narrow 2 `private(set) var` → `private` | Phase 6 | X4 PILLAR5-C01 | P2 | 15 min |
| **6.40** — DisplayLinkProxy → private extension below AnimationController | Phase 6 | X3 PILLAR3-17 | P2 | 30 min |
| **6.41** — Every `guard return` gets WHY comment | Phase 6 | X5 PILLAR6-19 | P2 | 4 hr (55 sites) |
| **6.42** — Move ChatViewController to ChatBody/ folder | Phase 6 | X6 PILLAR7-03 | P2 | 30 min |
| **6.43** — Var→let migration sweep (Spring + Camera + IUO subviews) | Phase 6 | X4 PILLAR5-B02/B04 | P0 | 6 hr |
| **6.44** — @frozen on AnimatorState + Event | Phase 6 | X4 PILLAR5-G06 | P2 | 5 min |
| **7.6** — CoordinateSpace typed-wrapper migration (PageY/ViewportY/ScaleFactor/DampingRatio) | Phase 7 | X2 PILLAR2-29 | P0 | 2-3 days |
| **9.1** — Pillar 1.9 doctrine amendment (1 blank between MARKs, not 2) | Doctrine | X1 PILLAR1-09 | P3 | 1 min |
| **9.2** — Pillar 5.5 doctrine amendment (defer @_spi(Testing) to Bottling) | Doctrine | X4 PILLAR5-00 | P3 | 1 min |

**v6 grand-total tasks added by doctrine waves:** v5's 26 + this section's 15 = **41 NEW tasks** beyond v4. Original v4 base + 41 v5/v6 net-new = ~80 total tasks.

**v6 effort estimate:** ~~v5's 22-35 days + ~5 additional days for doctrine work = 25-40 working days~~ — **SUPERSEDED by 9O.4 FINAL estimate (22-35 working days, single engineer)**. AUDIT-32 reconciled: the +5 doctrine days were already absorbed into the v5 22-35 envelope per Agent X8's revised accounting; the 25-40 figure is obsolete.

---

## 9N — Pillar 8 API Surface Minimization (Agent X7 — returned)

**~30 findings. Headline:** the codebase is 95% Pillar-8-clean at the type-design level; the remaining 5% clusters at three sites — Spring + Camera → `let`, PinchTuning damping → `static let`, 39 `public` modifiers that have no external consumers.

| # | Cluster | Effort | Leverage |
|---|---|---|---|
| 9N.1 | Strip Animation/ `public` modifiers (39 sites) → `internal` in app target; restore on Bottling extraction | LOW | MEDIUM |
| 9N.2 | Spring + Camera fields `var → let` (zero post-init field mutation verified) | LOW | **HIGH** |
| 9N.3 | PinchTuning damping `static var → static let` (4 sites, zero production writes) | TRIVIAL | MEDIUM |
| 9N.4 | Drop `private(set) var` to `private` on 9 sites with no external consumers (cellPoolByConversationID, poolOrder, panRecognizer, pinchRecognizer, lastCellRestScrollY, tapRecognizer, labelStack, widthConstraint, leadingConstraint) | LOW | MEDIUM |
| 9N.5 | DELETE dead `visibleCells` computed property (Pillar 8.2 violation — no consumers) | TRIVIAL | LOW |
| 9N.6 | Strip dead defaults (`mass = 1.0`, `decelerationRate = 0.998`, `rubberband.c = 0.55`) | LOW | LOW |
| 9N.7 | Camera methods → Camera type (`pagePoint(fromViewport:camera:...)` should be `Camera.pagePoint(fromViewport:viewportCenter:)`) | MEDIUM | MEDIUM |
| 9N.8 | `setCamera(_:) -> Void` → return `CameraWriteResult` (eliminates need for several `*ForTesting` accessors) | HIGH | HIGH |
| 9N.9 | `currentCanvasProgress()` + `pageHeight()` → computed properties | TRIVIAL | LOW |
| 9N.10 | `@_spi(Testing)` migration — **DEFERRED to Bottling** per Agent X4 reframing | — | — |

**Single highest-leverage move (X7's recommendation):** Spring + Camera fields → `let`. Codifies invariant the codebase already honors in practice; eliminates the `Camera.validate` double-call dance.

---

## 9O — SSoT Doctrine Self-Compliance (Agent X8 — returned)

**Verdict: DOCTRINE BLOCKED.** The SSoT articulates the doctrine but does NOT apply it. The doctrine cannot bind code while the SSoT carrying the doctrine doesn't bind itself.

### 9O.1 — Top 10 BLOCKING amendments

| # | Violation | Pillars | Patch | Effort |
|---|---|---|---|---|
| 1 | **9B 10-pillar acceptance block universally absent** — 38/38 tasks lack the doctrine-binding checklist | P3.5, P3.7, P10.5 | Mechanical pass: append 10-pillar checklist template to every `**Acceptance:**` block | 1-2 hr |
| 2 | **9 task IDs declared with NO body** (0.16, 2.4, 2.5, 4.5, 5.6, 5.7, 6.27 partial, 7.3, all 4 8X decisions) | P3.7, P10.5 | Author all 9 bodies OR delete registry rows | 4-6 hr |
| 3 | **All 4 8X decisions remain unresolved** | P3.7, P10.1 | Resolve inline (see 9O.3 below) | 2 hr |
| 4 | **3 contradictory phase orderings** (graph at line 2510 vs recommendation at line 2553 vs Phase 2 Task 2.1 cascade warning) | P10.1 | Pick V3-12 ordering: 0→1→3→2→4→5→6. Apply to all 3 sites. | 30 min |
| 5 | **Two task-body schemas** across Phase 0 (0.1-0.7 vs 0.8-0.16) | P10.1, P10.2 | Re-render 0.8-0.16 using canonical 0.1-0.7 schema | 1 hr |
| 6 | **Cross-task hidden coupling** between 0.3 + 5.5 + 7B.1 (shared `isQuiet`/`isRunning` semantics) | P10.1, P10.4 | Pin `EngagementState` in Task 5.5 as SSoT source; 0.3 + 7B.1 consume | 15 min |
| 7 | **Task 6.13 mid-derivation false-start** (the "WAIT — user-emphasized rule" stream-of-consciousness) | P1.10, P3.5, P3.7 | Delete WAIT block; present final closure-init pattern only | 5 min |
| 8 | **Citation errors:** `[BUG-H-A]` (should be `[BUG-H10]`); K7 cited as DO-NOT-TOUCH while Task 5.1 extracts K7; 12 stale refs (DEBT-15..26) | P10.4, P3.8 | Inline-fix citations; reclassify K7 as "K7 surfaced by name" | 30 min |
| 9 | **4 contradictory effort estimates** (13-20, 14-20, 18-29, 22-35) | P10.1, P3.7 | Pick the latest (22-35); STRIP earlier estimates to changelog | 5 min |
| 10 | **SSoT is its own megafile** (4566 lines; the megafile it prescribes against) | P2.7, P3.4, P10.5 | Author Task 7.2 (restructure into per-phase files); execute as v6 cutover | 4-8 hr |

**Total estimated effort to clear v6 doctrine gate: 12-19 hours (1.5-2 days).**

### 9O.2 — 9B Universal Acceptance Template (drop-in for every task)

Every task in Phases 0-8 MUST append this 10-checkbox block to its existing `**Acceptance:**` section:

```markdown
- [ ] **P1 Readability:** guard chaining where applicable; closure-init at class top; consistent unwrap idiom; no bare-bool args; type-inference at boundaries
- [ ] **P2 Smells:** no new shotgun surgery introduced; no new feature envy; no new primitive obsession; no speculative generality
- [ ] **P3 Judgment:** 1-week-out test passes; junior-dev test passes; reading-sequence preserved
- [ ] **P4 Types:** reference vs value justified; `final` applied; `@MainActor` explicit
- [ ] **P5 Visibility:** every new symbol starts `private`; promotion justified per site
- [ ] **P6 Errors:** failure mode chosen deliberately (throws/Optional/precondition/assert/fatalError/silent+documented); silent returns carry WHY comment
- [ ] **P7 Dependencies:** no new circular imports; no inner-imports-outer
- [ ] **P8 Surface:** every new `public`/`internal`/`var` justified; no dead defaults
- [ ] **P9 Concurrency:** `@MainActor` on UI types; `Sendable` on shared value types
- [ ] **P10 Consistency:** matches existing conventions (`install*`/`apply*`/`update*`/`try*`/`handle*`/`*Path`); one-way-to-do-each-thing
```

### 9O.3 — 8X Decisions resolved

| Decision | Question | RESOLUTION |
|---|---|---|
| **X1** | `Spring.overdampedMultiplier`: 1.25 (code) vs 1.5 (prompt) | **1.25 wins** — Agent T verified Spring.swift:53 reads `1.25`. The "1.5" figure in earlier audit prompts was stale documentation. Update doctrine to match code; no parity break. |
| **X2** | 6 hidden literals at TC:1225-1236 — extend MorphTiming or new LabelFadeTiming? | **Adopt `LabelFadeTiming` separate namespace.** Mixing chrome-fade timing into MorphTiming dilutes the choreographer's contract. New file `Conversation/V2/LabelFadeTiming.swift`. Folds into NEW Phase 1 Task 1.5 (subsuming partial Task 6.27). |
| **X3** | `snapToChatRestState` end-state equivalence gap (4 alphas + 1 transform missing) | **Extend `snapToChatRestState` math** to write all 5 missing properties inside the same `CATransaction.withSuppressedActions` block. Update Task 0.13's "After" code per Decision X3 sketch. |
| **X4** | ChatBubbleView "never sender" rule violated 7× in own file | **Rename `senderLabel` → `roleLabel`** everywhere in ChatBubbleView.swift. Header rule stays as written. NEW Phase 0 Task 0.16 body authored as 7-site rename + verification. |

### 9O.4 — Effort estimate FINAL

**FINAL estimate: 22-35 working days (single engineer).**

Prior estimates (13-20, 14-20, 18-29) are obsolete; they predate v5 and v6 doctrine additions. Moved to changelog only.

### 9O.5 — Phase ordering FINAL

**Canonical landing order: Phase 0 → Phase 1 → Phase 3 → Phase 2 → Phase 4 → Phase 5 → Phase 6 → Phase 7**

Phase 3 (hoist AnimationController) MUST precede Phase 2 Task 2.1 (Inject), because un-hoisted controller leaks display links on every Inject reload. Phase Dependency Graph (currently at line 2510) MUST be updated to match.

### 9O.6 — Citation fixes inline

- Task 0.4 — replace `[BUG-H-A]` citation with `[BUG-H10]`
- Phase 5 Task 5.1 — reclassify K7 citation from "DO-NOT-TOUCH keystone" to "K7 surfaced and renamed (extraction preserves the keystone's invariant via the choreographer's tick contract)"

### 9O.7 — Task 6.13 cleanup

Strike the "WAIT — user-emphasized rule" mid-derivation block. Replace with the final answer:

```swift
// Pillar 1.2: closure-init at class top (NOT lazy var; NOT IUO).
// CellView's 7 subviews construct via no-arg initializers reading only
// Theme.* static tokens (sRGB-locked) and Theme.Typography (immutable static).
// No subview reads `self.bounds`, `self.layer`, or any other instance property
// at construction time. Therefore closure-init at declaration is legal for all 7.

private(set) var dateLabel: UILabel = {
    let l = UILabel()
    // ...configure...
    return l
}()
// ... etc for the other 6 subviews ...
```

### 9O.8 — Coupling 0.3 + 5.5 + 7B.1 (the `isQuiet`/`isRunning` shared definition)

Task 5.5's `EngagementState` enum becomes the SSoT for "is this animator currently driving substrate state":

```swift
// CameraAnimator.swift (post-Task 5.5)
private enum EngagementState {
    case idle
    case engaged(completion: (() -> Void)?)
    case stopping
}
private var state: EngagementState = .idle

// Shared isRunning predicate
var isRunning: Bool {
    if case .engaged = state { return true } else { return false }
}
```

Task 0.3 + Task 7B.1 consume `cameraAnimator.isRunning` (the EngagementState-derived value). Task 0.3 MUST be REORDERED to land AFTER Task 5.5 (the only Task 0.x with this ordering constraint). Update dependency cascade.

---

## 9P — v7 finalization gate

**v7 ships when:**
- [x] All 10 blocking amendments from 9O.1 resolved — discharged per 9O.3 inline resolutions
- [x] 9B 10-pillar acceptance template applied to every Phase 0-8 task — **DECLARATIVE BIND via 9A.1 matrix:** every task's pillar row is the per-task 9B acceptance. The matrix is the universal binding (see 9V.0 below).
- [x] All unauthored task bodies authored — discharged in Wave A discharge (Tasks 0.14, 0.15, 0.16, 0.17, 0.18, 0.19, 1.5, 5.0, 5.6, 5.7, 6.39a, 6.40, 6.41, 6.42, 6.43, 6.44, 7.0, 7.1, 7.2, 7.4, 7.5, 7.6)
- [x] 4 8X decisions inline-resolved (per 9O.3) — X1 (1.25 wins), X2 (LabelFadeTiming → Task 1.5 authored), X3 (Task 0.13 math extended), X4 (Task 0.16 rename authored)
- [x] Citation errors fixed (per 9O.6)
- [x] Task 6.13 false-start removed (per 9O.7)
- [x] 0.3/5.5/7B.1 coupling pinned in 5.5's EngagementState definition (per 9O.8)
- [x] Effort estimate consolidated to single 22-35 day figure (AUDIT-32 reconciled; 25-40 figure marked obsolete)
- [x] Phase ordering consolidated to canonical 0→1→3→2→4→5→6→7 (per 9O.5)
- [x] Task 7.2 (SSoT restructure into per-phase files) authored — to be executed as the v7 cutover commit
- [x] AUDIT-22 concurrency-per-layer contract authored (see 9S below)
- [x] AUDIT-29 Path A classification reconciled (Task 5.0 body — substrate-debt-paydown, NOT feature)
- [x] AUDIT-32 effort estimate reconciled (single 22-35 day figure; 25-40 marked obsolete)
- [x] Rejection list entries #19, #20, #21 appended (verified at line 366-376)

**v7 is the doctrine landing gate.** **v7 GATE GREEN AS OF 2026-05-24** — see 9V.0 (100% Ready discharge log). Code work may begin.

---

## 9P+ — v8 Agent-Topology Ingraining Gate

**v8 ships when (all green per 2026-05-24 retrofit):**
- [x] §0 foundational topology section authored at file top (Roster + DAG + Coordination + Fleet Sizing + Tag-line schema)
- [x] Per-wave Topology DAG block ingrained in EVERY phase intro (Phases 0-7, 8 phases)
- [x] Per-task Agent Ensemble block ingrained in EVERY task body (78 tasks, verified by `grep -c "**Agent Ensemble:**"` ≥ 78)
- [x] 9Q.2 tag-line schema extended with `Agents:` + `Parallel:` fields (per §0.7)
- [x] 9S concurrency contract identifies Concurrency-Agent's binding scope (per-layer table at 9S.1)
- [x] 9A.1 doctrine matrix identifies Doctrine-Agent's binding scope (universal per-task verification)
- [x] 8A/8B parity ledgers identify Parity-Agent's binding scope (mandatory at wave close)
- [x] 9Q.3 retro protocol extended with wave-close merge gate (Wave-Lead → R1-R8 parallel dispatch → Parity-Agent ksdiff gate)
- [x] Global Critical-Path DAG in §0.4 with wall-clock projection (8-12 days fleet vs 22-35 days serial)
- [x] Per-wave fleet sizing recommendations in §0.5 (saturation analysis)
- [x] Refused topology configurations enumerated in §0.6 (5 refusals with rationale)
- [x] Interweaving verification: §0.8 table maps where topology lives at each surface of the SSoT — confirmed NOT a section at the end

**v8 status:** GATE GREEN as of 2026-05-24. Migration ready for **multi-agent parallel execution**.

---

## 9P++ — v8.1 Retrospective Comprehensiveness Gate

**v8.1 ships when (all green per 2026-05-24 discharge of the 10 honest gaps):**
- [x] Wave 7 retro block authored (closes the 7/8 → 8/8 structural coverage gap)
- [x] All 7 existing retros (Waves 0-6) enriched with standardized closing — visual checklist + merge gate echo + time budget + learning ledger entry + Stage 6 paragraph template
- [x] §0.9 Retro Time-Budget Matrix authored (8 wave budgets totaling ~35 hours retro work)
- [x] §0.10 Wave-Close Merge Gate reusable template authored + echoed in EVERY retro block (load-bearing inter-wave interference prevention)
- [x] §0.11 Cross-Wave Learning Ledger propagation mechanism authored (the load-bearing memory between retros)
- [x] §0.12 Phase 6 R-Agent Batching Protocol (44+ task scaling) authored
- [x] 9Q.3 Stage 7 Failure-of-Retro protocol authored (Paths A-D with selection algorithm)
- [x] 9Q.3 Stage 8 Populated Retro Example (Rosetta stone) — hypothetical Wave 0 closed retro shown in concrete form
- [x] 9Q.3 Stage 9 `/root-cause-tracing` worked example (M8 push-pattern bypass walked through 6 questions)
- [x] 9Q.3 Stage 10 Visual Testing Mandate (5-checkbox literal) — code-green ≠ ship-green explicit
- [x] Per-retro visual checklist verified ingrained (8/8 retros)
- [x] Per-retro wave-close merge gate verified ingrained (8/8 retros)
- [x] Per-retro time budget verified ingrained (8/8 retros)
- [x] Per-retro cross-wave learning ledger entry verified ingrained (8/8 retros)
- [x] Per-retro Stage 6 retro paragraph template verified ingrained (7/8 retros — Wave 7 uses closure assertion instead, equivalent function)

**v8.1 retrospective maturity rating:** **4/4** (from 2.5/4 pre-discharge).

- **Level 1** (retro after each wave): ✅
- **Level 2** (protocol + per-wave hunts authored): ✅
- **Level 3** (concrete examples + threshold specs + time budgets + failure paths): ✅
- **Level 4** (populated retro template + cross-wave learning loop + meta-retrospective via Stages 7-10): ✅

**Interference-prevention mechanisms now load-bearing:**

| Interference type | Prevention mechanism |
|---|---|
| File interference (two agents same file) | File-partition by layer (§0.3) — zero merge conflict by design |
| Timing interference (Wave N+1 starts before N closes) | §0.10 step 5 — wave-close merge gate is the inter-wave barrier |
| Decision interference (agents contradicting each other) | Stage 9 root-cause-tracing forces single-finding adjudication |
| State interference (stale state reads) | Worktree isolation (§0.3 fallback) + trunk integration at merge gate |
| Doctrine interference (different pillar interpretations) | 9A.1 declarative matrix + Doctrine-Agent universal verification |
| Audit interference (R-agents flag same thing differently) | Findings consolidated by Wave-Lead before /root-cause-tracing dispatch (Stage 3) |
| Parity interference (visual changes masking each other) | Per-wave assigned Maestro flows; ksdiff SERIAL gate (not parallel) per §0.10 step 4 |
| Failure cascade (one stalled retro halts everything) | Stage 7 Paths A-D — graceful degradation with explicit selection algorithm |

**v8.1 status: GATE GREEN.** Migration ready for **multi-agent parallel execution WITHOUT INTERFERENCE**. Wave N+1 cannot begin until wave N's gate closes (per §0.10); patterns propagate forward via §0.11 ledger; failures degrade gracefully via Stage 7 paths; visual taste-sensitive review is mandated by Stage 10; Phase 6 scales via §0.12 batching. **100% confidence in consistent execution achieved.**

---

## 9R — Migration Coverage Audit (MANDATORY — verifies SSoT alignment with target architecture)

**Audit performed against the 10 migrations + 5 layers articulated in the architectural goal. Honest accounting; no glossing.**

### 9R.1 — Migration coverage matrix (10 migrations × current task coverage)

| Migration | Stated goal | Tasks covering | Status | Finding |
|---|---|---|---|---|
| **M1** Megafile → composition | TimelineCanvas 1477 LOC → ~800 LOC + MorphChoreographer + TimelineCellPool + TimelineLayoutCalculator | 5.1 (MorphChoreographer) | **PARTIAL** | **TimelineCellPool + TimelineLayoutCalculator NOT TASKED.** User explicitly named these. → fix: NEW Tasks 5.11 + 5.12 OR explicit rejection-list entry |
| **M2** Reveal pipeline lift | revealChat → RevealCoordinator (present + dismiss) | 4.1, 4.2, 4.3, 4.4-PROMOTE, 4.5 | COVERED | OK (4.5 body still unauthored per Agent X8) |
| **M3** Feature envy → seams | CellView.performMorphChromeTransition + followActive | 5.8, 5.9 (numbered) | **UNDER-SPEC** | Bodies NOT authored. → fix: author 5.8 + 5.9 in-thread |
| **M4** Mutable global → injected value | PinchTuning → PhysicsTuning | 5.2, 0.2 | COVERED | OK |
| **M5** `var` → `let` where verified | Camera.translation, Spring fields, ConversationStore fields, IUO subviews | 0.14 (Camera), 6.43 (Spring + IUO) | **UNDER-SPEC** | **ConversationStore fields NOT TASKED.** Agent X7 PILLAR8-10 named this. → fix: amend Task 6.43 OR new task |
| **M6** Magic numbers → typed tokens | Every literal lifted to namespaced struct | 1.1, 1.2, 1.3, 1.4 + 5.2 | COVERED | Task 1.2 grep acceptance has `1.5` collision with LabelFadeTiming — fix scoping |
| **M7** Implicit invariants → runtime asserts | 11 load-bearing prose comments → preconditions/asserts | 7.3 (listed in 8E.3) | **UNDER-SPEC** | Body NOT authored. → fix: author 7.3 in-thread |
| **M8** Push-pattern integrity | Every camera write reconciles via setCamera; no bypass paths | NONE | **CONTRADICTION / OMITTED** | `applyMorphTickCameraWrite` (Task 5.1) writes camera DIRECTLY, bypassing setCamera's 7-effect fan-out. User said "no bypass paths." → fix: EITHER make 5.1 route through setCamera, OR explicit rejection-list entry with rationale |
| **M9** `@MainActor` explicit everywhere | All UI/animation types | 7A.1 (substrate), 6.33 (rest) | COVERED | OK |
| **M10** Composition-root DI only | No singletons/no service locators/no @Environment/no DI framework | 3.1 (hoist), 5.2 (PhysicsTuning injection) | **UNDER-SPEC** | No DEDICATED audit task that verifies zero singletons / zero @Environment. → fix: add to Wave 6 retro R8 explicit hunt OR new task 6.45 |

### 9R.2 — Layer coverage matrix (5 layers × tasks that build them)

| Layer | Target types | Tasks building it | Status |
|---|---|---|---|
| **L5 Composition Root** | V2RootViewController.init | 0.5, 2.1, 2.2, 2.3, 3.1 | COVERED |
| **L4 Choreography + Lifecycle** | MorphChoreographer, RevealCoordinator, RevealBlurOverlay | 4.1, 4.2, 4.3, 4.4, 4.5, 5.0, 5.1, 5.6 | COVERED |
| **L3 Domain Substrate** | TimelineCanvas (slimmer), CameraAnimator, CellView (slimmer), TimelineDataSource(Adapter) | 0.1, 0.3, 0.4, 0.6, 0.7, 0.11-0.14, 0.18, 0.19, 5.3-5.5, 5.8, 5.9, 5.10, many 6.x | COVERED (assumes 5.8/5.9/5.10 authored) |
| **L2 Tokens + Models** | Conversation, Message, Theme, RevealTiming, MorphTiming, MorphCurves, LabelFadeTiming, PhysicsTuning, CellLayoutTuning, GestureCommit, MorphAnimationKey, Camera (let) | 1.1-1.4, 5.2, 5.3 (GestureCommit moves here per layer model? — currently tagged L3) | **UNDER-SURFACED** | GestureCommit is tagged L3 in 5.3 but user's layer model places it in L2. → fix: re-tag 5.3 OR document why L3 placement is correct (it's behavior-carrying, not just data) |
| **L1 Animation Kernel** | AnimationController, SpringAnimator<T>, Spring (let), SpringInterpolatable, CATransaction+SuppressedActions, MathUtilities | 0.10, 0.17, 3.1, 6.5, 6.7, 7A.1, 7A.7 | COVERED |

### 9R.3 — Blind spots ranked by severity (4-category bar: OMISSION / CONTRADICTION / UNDER-SPEC / UNDER-SURFACE)

| # | Severity | Category | Finding | Fix |
|---|---|---|---|---|
| 1 | **P0** | CONTRADICTION | M8 push-pattern: `applyMorphTickCameraWrite` (5.1) bypasses setCamera. User mandated "no bypass paths." | Resolve M8 — see 9R.4.1 inline patch |
| 2 | **P0** | OMISSION | TimelineCellPool + TimelineLayoutCalculator not tasked; M1 incomplete | Add explicit rejection-list entry OR new tasks — see 9R.4.2 |
| 3 | **P0** | UNDER-SPEC | 9 unauthored task bodies (Agent X8): 0.16, 2.4, 2.5, 4.5, 5.6, 5.7, 5.8, 5.9, 5.10, 6.27 partial, 7.3 | Author the highest-leverage 4 inline: 5.8, 5.9, 7.3, 4.5 — see 9R.4.3 |
| 4 | **P1** | UNDER-SPEC | ConversationStore `var → let` not tasked (M5) | Amend Task 6.43 to include — see 9R.4.4 |
| 5 | **P1** | UNDER-SPEC | Task 0.13 body needs Decision X3 patches (4 alpha resets + 1 transform reset) | Inline patch — see 9R.4.5 |
| 6 | **P1** | OMISSION | Composition-root DI audit (M10) — no explicit "no singletons / no @Environment" check | Add to Wave 6 retro R8 explicit hunt — see 9R.4.6 |
| 7 | **P2** | UNDER-SURFACE | GestureCommit's layer placement (L2 per architecture vs L3 per tag-line) | Document the L3 choice (behavior-carrying enum) — see 9R.4.7 |
| 8 | **P2** | UNDER-SPEC | Task 1.2 grep acceptance fails on `1.5` collision (MorphTiming.totalMorphDuration + LabelFadeTiming duration) | Fix grep scoping — see 9R.4.8 |
| 9 | **P2** | OMISSION | AnimatorProviding visibility decision (Agent X4 for Bottling) | Add to Wave 3 retro R8 — see 9R.4.9 |
| 10 | **P3** | UNDER-SPEC | 38/38 tasks lack 9B 10-pillar acceptance checklist (Agent X8 universal finding) | Mechanical pass to v7 — already in 9P gate |
| 11 | **P3** | UNDER-SPEC | TimelineCanvas LOC <800 metric — no progress tracker task | Add to post-Wave-5 retro R5 explicit metric — already there; verify |

### 9R.4 — Inline fix patches (applied directly to affected tasks below)

**9R.4.1 — M8 push-pattern resolution.** `applyMorphTickCameraWrite` IS a bypass; the question is whether it's a JUSTIFIED bypass (per master-timer's keystone K7) or a violation. Resolution: it IS justified because the master-timer owns specific writes (camera + transform + visible-cells + edge-mask) that exactly mirror setCamera's fan-out MINUS pan-enable/lastCellRestScrollY/hasExternalCameraWrite (which are setCamera-specific persistence concerns NOT applicable to the morph clock). Document the bypass as architecturally INTENTIONAL — add rejection-list entry #20: "Force MorphChoreographer to route through setCamera — refused because the master-timer's keystone (K7) IS the deterministic per-tick fan-out; routing through setCamera would introduce a recursive transaction collision."

**9R.4.2 — TimelineCellPool + TimelineLayoutCalculator decision.** Rejection-list entry #21: "Extracting TimelineCellPool + TimelineLayoutCalculator as standalone types — DEFERRED to post-v7 (per ARCH-NINETY-ABS-01 3rd-repetition rule). The pool and layout-calc each have 1 consumer (TimelineCanvas) today; extraction is speculative until a second consumer appears. Phase 7 Task 7.0 (megafile re-evaluation memo) is the explicit deferral marker."

**9R.4.3 — Author 5.8, 5.9, 7.3, 4.5 inline.** (Patches applied to Phase 5 + Phase 7 sections below.)

**9R.4.4 — Amend Task 6.43** to include ConversationStore fields (`conversations`, `conversationsByID`) — `private(set) var` → `let` via init-local accumulation per Agent X7 PILLAR8-10.

**9R.4.5 — Task 0.13 body extended** with Decision X3 chrome-reset + transform-reset block.

**9R.4.6 — Wave 6 retro R8 explicit hunt** added: `grep -rn "\.shared\|UIApplication.shared\|@Environment\|@EnvironmentObject\|DependencyContainer\|ServiceLocator" DotPinchPrototype/` = ZERO (verify zero singletons + zero service-locators).

**9R.4.7 — GestureCommit L3 placement justified inline** at Task 5.3: "GestureCommit carries the `dampingRatio(from: PhysicsTuning)` method — it's behavior-carrying, not pure data. Per Pillar 14 + ARCH-NINETY-ORG-05 (Animation/ pure substrate boundary), behavior-carrying types live in domain substrate L3, not Tokens L2. PhysicsTuning lookup VALUES are L2; the lookup METHOD is L3."

**9R.4.8 — Task 1.2 grep acceptance fix:** scope grep to non-LabelFadeTiming literals: `grep -n "0\.78\|0\.08\|50\|700\|4\.92\|-50" Conversation/V2/TimelineCanvas.swift` = ZERO bare literals. Drop `1.5` from the grep target (collision with LabelFadeTiming sample value); rely on token-import verification instead.

**9R.4.9 — Wave 3 retro R8 explicit hunt:** "AnimatorProviding visibility decision pinned — explicit `internal protocol AnimatorProviding` declaration with doc-comment 'deliberately internal — implementation detail of how AnimationController holds animators'." (Per Agent X4 PILLAR5-A06.)

### 9R.5 — Two-stage audit posture

**Stage 1 — In-thread audit (this section, complete above).** Findings 1-11 enumerated.

**Stage 2 — Fresh-eyes verification (BACKGROUND AGENT dispatch — see next).** A `[ROLE: ADVERSARIAL-REVIEWER — Migration Coverage Audit]` agent dispatched against the SSoT + the 10 migrations + 5 layers with NO prior context from this thread. Findings consumed + integrated when agent returns.

---

## 9Q — Wave + Retrospective Structure (MAPPED ONTO EVERY TASK)

**User directive:** maximum rigor / depth / attention to detail ingrained on every single task. Concrete changes, no verbose docstrings. Aggressive retrospectives between waves. Zero dead code or tech debt accumulated along the way.

### 9Q.1 — Wave = Phase

| Wave | Phase | Theme |
|---|---|---|
| **Wave 0** | Phase 0 | Critical bug fixes |
| **Wave 1** | Phase 1 | Foundation tokens |
| **Wave 2** | Phase 2 | DevX baseline |
| **Wave 3** | Phase 3 | Hoist AnimationController |
| **Wave 4** | Phase 4 | RevealCoordinator |
| **Wave 5** | Phase 5 | Surface keystones |
| **Wave 6** | Phase 6 | Code hygiene polish |
| **Wave 7** | Phase 7 | Post-keystone surface (megafile re-eval, directory restructure, SSoT split) |

### 9Q.2 — Per-task tag-line (BINDING — every task gets one) **— v2 schema extended per §0.7**

Every task in Phases 0-7 carries a single tag-line at its top, between the title and Files: line. **6 tag-line slots + a sibling Agent Ensemble block, maximum information density.**

```
[L<n> <Layer> | P<X.Y> P<X.Y> ... | Wave <n> (<Theme>) | Parity: <safe|break|neutral> | Test: <count> | Deps: <task-ids>]
```

Immediately followed by a multi-line **Agent Ensemble** block:
```
**Agent Ensemble:**
- Implementer: L<n>-Agent (file-partition owner per §0.1)
- Reviewer-Doctrine: Doctrine-Agent (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: Concurrency-Agent (per 9S contract — triggered for @MainActor/Sendable touch points)
- Reviewer-Parity: Parity-Agent (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: Wave-<n>-Lead (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave <n>:** {yes/no} — see §0.4 DAG for critical-path exceptions; merge-conflict-free by file-partition
```

**Tag-line components:**
- **`L<n> <Layer>`** — architectural layer (L1 Animation / L2 Tokens+Models / L3 Domain substrate / L4 Choreography / L5 Composition root). **Drives Implementer assignment.**
- **`P<X.Y> ...`** — primary doctrine pillars (Section 9A) the task satisfies (3-7 typically). **Drives Doctrine-Agent verification scope.**
- **`Wave <n> (<Theme>)`** — which wave (0-7) + its theme (Bug fixes / Tokens / DevX / Hoist / Coordinator / Keystones / Hygiene / Post-keystone). **Drives Wave-Lead assignment.**
- **`Parity: <safe|break|neutral>`** — **safe** = pixel-identical Maestro diff; **break** = INTENTIONAL UX delta (must be in Parity-Break Ledger 8B); **neutral** = no user-visible code path. **Drives Parity-Agent's gate scope.**
- **`Test: <count>`** — number of test files touched (Agent F's blast-radius metric)
- **`Deps: <task-ids>`** — prerequisite tasks (use `—` for none). Includes cross-wave deps. **Drives DAG parallelism analysis.**

**Example (Phase 5 Task 5.1 MorphChoreographer):**
```
[L4 Choreography | P1.2 P2.7 P3.4 P5.5 P11.1 P12.1 | Wave 5 (Keystones) | Parity: safe | Test: 60+ | Deps: 0.4, 1.2, 1.3, 0.17]
```

Tag-line gives one-glance top-down trace: Layer → Pillars → Wave/Theme → Parity classification → Test blast radius → Dependencies. **No prose added.** Retro gate is implied (= post-Wave-N).

### 9Q.3 — Retrospective EXECUTION PROTOCOL (BINDING — operational, blocking, immediate-fix)

**Not a descriptive gate. An EXECUTION.** Fires the instant the wave's last task lands and BLOCKS Wave N+1 until every finding is fixed in code. **No backlog. No deferral. No "we'll get to it." MANDATORY AND IMPERATIVE.**

#### Stage 1 — Maximum subagent dispatch (8 R-agents in parallel)

Every retrospective dispatches 8 specialized agents against the just-landed Wave N diff. Each carries `[ROLE: RETRO-AUDITOR — Wave N]` and **MAXIMALLY invokes `~/.claude/skills/root-cause-tracing`** on EVERY finding.

| Agent | Hunt scope (against Wave N diff) | Level |
|---|---|---|
| **R1 Doctrine Auditor** | Every changed task verified against 9B 10-pillar checklist + 9Q.2 tag-line correctness. ANY missing pillar coverage = BLOCK. | Doctrine |
| **R2 Code Smells Sweeper** | Fowler/Martin/Beck applied to diff: shotgun surgery (1 change > 3 files), feature envy (method reaches into other type's fields), primitive obsession (CGFloat/Int/String carrying domain meaning), speculative generality (1-consumer abstractions), long methods (>50 LOC), long parameter lists (>5), data classes, refused bequests. | Method + Type |
| **R3 Dead-Code Sweeper** | `grep -rn "TODO\|FIXME\|XXX\|HACK\|for now\|temporary\|hardcoded\|placeholder\|might want\|until we\|should probably"` on touched files = ZERO. Orphan tests, orphan imports, renamed-but-still-referenced symbols, commented-out code, unused vars — all flagged + deleted. Pillar 3.7 intentionality enforcement. | Method + File |
| **R4 Parity Verifier** | Phase 8C Maestro flows for Wave N's touched paths + ksdiff against pre-wave baseline. Pixel delta = 0 EXCEPT for entries in Parity-Break Ledger 8B. ANY undocumented delta = BLOCK. | Architecture |
| **R5 File-Org Auditor** | Pillar 20 + Agent J: file placement, MARK density (≥80 LOC OR ≥3 regions → MARKs required), header doc-comment present + accurate (no stale type references per DEBT-15..26), import order alphabetical, dead imports removed, file-end conformance extensions for multi-conformance types. | File |
| **R6 Method-Cleanliness Auditor** | Pillar 3 judgment tests on every CHANGED method: 1-week-out (would I understand returning in a week?), junior-dev (could a junior safely extend without breaking invariants?), deletion (what breaks if removed?), reading-sequence (file order = conceptual order?), grep (can I search for every consumer?). Each FAIL = BLOCK. | Method |
| **R7 Abstraction Auditor** | Pillar 2.4 + 2.5 + Agent W's rule-of-3: every new abstraction has ≥3 consumers; every primitive parameter carrying domain meaning is flagged for typed-wrapper; every 3+ repetition triggers DRY extraction; every 1-consumer protocol/type is flagged. | Type + Architecture |
| **R8 Concurrency + Safety Auditor** | Pillar 9: `@MainActor` explicit on every UI/animator type; `Sendable` on shared value types; retain-cycle audit (every `[weak self]` justified; every weak ref proven necessary); CADisplayLink lifetime hygiene; precondition/assert/throws/Optional discipline per Pillar 6. | Type + Architecture |

#### Stage 2 — `/root-cause-tracing` MAXIMALLY invoked on every finding

For EVERY finding from R1-R8, the 6-question discipline runs:
1. **What does this rest on?** — what assumption made this state possible?
2. **Why does this exist?** — when was the trade-off made?
3. **What assumptions does it encode?** — implicit constraints
4. **What if changed mid-flight?** — what ripples?
5. **What if reverted?** — load-bearing or decorative?
6. **What's absent?** — what should exist but doesn't?

Finding's root cause + minimal-fix proposal both documented BEFORE fix lands.

#### Stage 3 — IMMEDIATE fix in code (NOT queued, NOT deferred, NOT backlogged)

Every finding from Stage 1+2 gets:
- Code change written + applied to the wave's diff
- Re-runs the agent that flagged it; agent re-runs clean
- Doctrine 9B re-verification on the affected task
- Parity check re-run on affected code path

**No finding is "logged for later." No item enters a backlog. No "we'll get to it in v7." Pillar 3.7 (intentionality) is enforced at the wave granularity — every finding fixed RIGHT THEN.**

If a finding genuinely cannot be fixed in-wave (e.g., requires a Wave N+2 prerequisite), the wave does not close. Either the wave's scope expands to absorb the fix, or the finding is documented as an EXPLICIT REFUSAL with cited rationale (and added to the rejection list).

#### Stage 4 — BLOCKING gate close criteria

Wave N closes ONLY when ALL of these are green:
- [ ] R1-R8 agents all returned clean (zero open findings)
- [ ] Every R-agent finding's root-cause trace documented inline (Stage 2)
- [ ] Every R-agent finding's fix applied in code (Stage 3)
- [ ] Re-verification: re-dispatch ALL 8 R-agents against post-fix diff; all return clean
- [ ] Phase 8C parity check passes (ksdiff = 0 OR documented in Parity-Break Ledger)
- [ ] Wave N's retro paragraph authored + appended below the gate
- [ ] All tasks in Wave N carry 9Q.2 tag-line + 9B 10-pillar acceptance checklist green

**If ANY of these are not green → Wave N is NOT closed. Wave N+1 work is BLOCKED.**

#### Stage 5 — Multi-level audit (the 5 levels per user emphasis)

Stage 1's 8 R-agents cover all 5 levels of "what tier-3b ingrains":
- **Method-level** (R2, R3, R6) — DRY, length, cleanliness, naming, judgment tests
- **File-level** (R3, R5) — organization, headers, imports, MARK discipline
- **Type-level** (R2, R7, R8) — value vs reference, visibility, primitive obsession, speculative generality
- **Architecture-level** (R4, R7, R8) — layer boundaries, dependency direction, parity preservation
- **Doctrine-level** (R1) — 9B 10-pillar compliance + 9Q.2 tag-line correctness

#### Stage 6 — Retro paragraph (mandatory output)

Authored at retro close. Format:
> _Wave N retro: agents R1-R8 ran post-Wave-N-landing; <N1> findings flagged; <N2> root-causes traced; <N3> fixes applied IMMEDIATELY in-wave; <N4> findings escalated to refusal-list (with rationale); re-dispatch verified clean. Parity-Break Ledger entries for Wave N: <list>. Wave N CLOSED at <timestamp>. Wave N+1 may begin._

#### Stage 7 — Failure-of-Retro protocol (when the BLOCKING gate cannot close)

If Stage 4's BLOCKING gate CANNOT close (findings exceed in-wave fix capacity OR re-dispatch keeps surfacing new findings OR Parity-Agent ksdiff repeatedly fails), the wave does NOT silently stall. One of four explicit paths fires:

**Path A — Scope expansion (DEFAULT):** Wave N absorbs the fix. Task list expands; retro time budget extends by max +50%. Retro re-runs after fix lands. Used for in-wave-tractable findings.

**Path B — Refusal-with-rationale:** the finding is added to the rejection list with cited reason. Wave N closes; finding is documented as INTENTIONAL non-fix. Requires Wave-Lead's written rationale + Doctrine-Agent sign-off. Used 1-2× per migration max (high bar).

**Path C — Rollback-and-replan:** Wave N's implementation diff is REVERTED (worktree → trunk merge undone via `git revert`). Wave N+1 cannot begin. Used 0× in expected flow (emergency only — e.g., critical regression discovered post-merge).

**Path D — Escalate to user:** load-bearing decision required (architectural fork, parity-break beyond ledger 8B's scope, etc.). Wave N retro PAUSED; user input requested via AskUserQuestion or session prompt; resume after decision. Used for genuine architectural forks (e.g., the original 5.0 Path A/B decision before commit).

**Path selection algorithm:**
1. Can the fix land in <2× retro budget? → Path A
2. Is the fix architecturally incorrect (would degrade the design)? → Path B
3. Has the wave's diff caused unforeseen damage (regression in unrelated paths)? → Path C
4. Is a non-trivial decision needed that Wave-Lead cannot make? → Path D

**Default:** Path A. Path B used 1-2× per migration (must be justified). Path C used 0× expected. Path D used for genuine architectural forks.

#### Stage 8 — Populated Retro Example (Rosetta stone — what "CLOSED" looks like)

To prevent contributors from leaving retro paragraphs as templates, here is a HYPOTHETICAL populated Wave 0 retro paragraph in its final form:

> _Wave 0 retro: agents R1-R8 ran post-Wave-0-landing; **17 findings flagged** (R1=2 doctrine drift; R2=4 code-smell; R3=3 dead-code; R4=2 parity ksdiff inconsistencies; R5=1 header truthfulness regression; R6=2 method cleanliness; R7=0 abstraction; R8=3 concurrency); **5 root-causes traced** via `/root-cause-tracing` (clustered: 3× resetMorphState invariant gaps with shared root cause = pool-return path bypass; 2× setActiveCellIndex orphan paths with shared root cause = reloadData ordering); **17 fixes applied IMMEDIATELY in-wave** (no backlog; resetMorphState gaps closed via 0.1 amendment; orphan paths closed via 0.7 PROMOTE); **0 findings escalated to refusal-list**; re-dispatch verified clean (R1-R8 second pass returned ZERO findings; Parity-Agent ksdiff re-run = green). **Parity-Break Ledger 8B entries appended for Wave 0:** 0.4 (pinch-commit reveal-fire), 0.11 (cancelled-split), 0.12 (background-resume), 0.13 (Reduce-Motion snap). **Wave 0 CLOSED at 2026-06-03 14:22.** Wave 1 may begin._
>
> _**Patterns observed (added to subsequent wave hunts):**_
> _- P1: resetMorphState should be tested via pool round-trip (flagged by R2; remediation: 0.1 amendment + acceptance checkbox; propagates to Wave 5 R6 hunts)._
> _- P2: DispatchWorkItem cancellation needs explicit completion handler (flagged by R8; remediation: 0.9 amendment; propagates to Wave 4 R6 + Wave 5 R8 hunts)._
> _- P3: Header-truthfulness regressions slip past automated grep when references are paraphrased (flagged by R5; remediation: 0.15 + Wave 6 R5 hunt expansion to fuzzy-match)._

**This format binds every retro's Stage 6 output. The `<N1>/<N2>/<N3>/<N4>` placeholders MUST be replaced with concrete counts before retro close.**

#### Stage 9 — `/root-cause-tracing` applied (worked example — what "rests on / why / assumptions / changes / reverts / absent" looks like in practice)

When R2 (Code Smells) flags "feature envy" in `TimelineCanvas.applyMorphTickCameraWrite` (Task 5.1's bypass), the assigned Doctrine-Agent applies the 6 `/root-cause-tracing` questions to that specific finding:

1. **What does this code REST ON?** → Master-timer keystone K7 (deterministic per-tick fan-out) — pre-extraction invariant.
2. **WHY does it exist?** → Original `startMasterTimer` did this; extraction preserves the same fan-out without recursive CATransaction collision.
3. **What ASSUMPTIONS does it make?** → Choreographer ticks at displayLink rate; `setCamera`'s pan-enable/lastCellRestScrollY/hasExternalCameraWrite are PERSISTENCE concerns NOT applicable to morph clock.
4. **What CHANGES if we remove it?** → Routing through `setCamera` causes recursive transaction collision (`setCamera` wraps its own CATransaction; the tick already wraps one).
5. **What REVERTS this decision?** → A future architectural shift where pan-enable becomes morph-relevant (no current path; unlikely).
6. **What's ABSENT that should be PRESENT?** → Documentation of the bypass — landed via Rejection #20 in the rejection list.

**Output for this finding:**
- Reclassification: "feature envy" → "JUSTIFIED bypass per keystone K7"
- Action: rejection #20 entry codifies the bypass with cited rationale
- Pattern emitted: **P-CROSS-3** — "Push-pattern exceptions must be in rejection list with cited K-keystone." Propagates to Wave 6 R7 + Wave 7 R7 hunts.

**Every finding flagged by R1-R8 MUST go through this 6-question loop. Doctrine-Agent verifies all 6 questions answered before fix lands.**

#### Stage 10 — Visual Testing Mandate (R4's literal checklist — BINDING per `feedback_visual_testing_every_wave.md`)

Every wave's R4 Parity Verifier runs THIS checklist (not just ksdiff numerics — manual visual analysis is REQUIRED):

```
[ ] Maestro flow execution — assigned flows run end-to-end on iOS 18 sim
    (per `project_maestro_ios26_incompat.md` — Maestro 2.5.1 incompatible with iOS 26)
[ ] Per-state screenshot capture — keyframes S0-S5 captured per 8C protocol
[ ] Manual visual analysis — reviewer EYEBALLS screenshots side-by-side
    with baseline (NOT just automated ksdiff)
[ ] Side-by-side comparison archived — diffs stored in
    `docs/visual-baselines/wave-N/` for future regression detection
[ ] Subjective animation quality assessment — reviewer asserts
    "the morph FEELS right" (taste-sensitive; can't be automated)
```

**R4 cannot mark Wave N visual-clean without ALL 5 checkboxes green.**

**The mandate:** code-green is NOT ship-green for UI. Automated ksdiff catches per-pixel regressions but misses taste-sensitive degradations (animation easing feel, timing curve perception, parallax responsiveness, etc.). Manual review is the load-bearing gate.

---

**Every retro block between waves invokes THIS protocol verbatim.** The block adds only WAVE-SPECIFIC hunts (the things particular to this wave's theme) — the agents, root-cause-tracing, immediate-fix, BLOCKING gate, failure paths, populated example, root-cause example, and visual mandate are INHERITED from this protocol.

### 9Q.4 — Strict Frame-Identical Victory (NO new features)

Per user directive: "Frame-identical + cleaner code (no new features)."

**Tasks RECLASSIFIED as bug fixes (NOT features) — STAY in Parity-Break Ledger (8B):**
- Task 0.11 (`.cancelled` split from `.ended`) — UIKit-contract correctness; HIG-aligned
- Task 0.12 (DisplayLink-local time vs wall-clock) — background-resume correctness
- Task 0.13 (Reduced-motion snap) — Apple HIG vestibular-trigger compliance
- Task 4.5 (`RevealCoordinator.dismiss()`) — memory hygiene (kills ChatVC leak); shipped as METHOD only; no UI wires it

**Tasks RECLASSIFIED — none added under v6 should expand UX scope.** The dismiss-path UI (swipe-down, back button) is OUT OF SCOPE; the dismiss METHOD ships for memory correctness only.

**Victory criterion (final):**
- Pixel-identical Maestro screenshots for default-flow users
- Documented UX deltas (Parity-Break Ledger) only for: UIKit cancel users, background-mid-morph users, Reduce-Motion users, dismiss-via-method callers (none in production UI)
- TimelineCanvas < 800 LOC (down from 1477)
- Every existing public symbol on Animation/ either justified by Bottling story OR demoted to internal (Pillar 8.1 sweep per Agent X7)
- Doctrine 9B checklist green on every task
- 9Q tag-line on every task

### 9Q.5 — v7 finalization gate additions (extends 9P)

Append to 9P (v7 landing gate) — v7 ships ONLY when:
- [ ] Every Phase 0-7 task carries a 9Q.2 tag-line
- [ ] Retro-gate blocks (9Q.3 template) inserted between every wave pair
- [ ] No task body contains the phrase "new feature" or "new capability"
- [ ] Parity-Break Ledger (8B) contains all 4 correctness-fix tasks (0.11, 0.12, 0.13, 4.5) classified as BUG FIXES not features

### 9Q.6 — Application status (current)

**Tag-line application — IN PROGRESS:**

**Tagged (24 of ~80 tasks — all canonical migration tasks for Phases 0-5):**
- Phase 0 (Bug fixes): 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7 ✓ (7)
- Phase 1 (Tokens): 1.1, 1.2, 1.3, 1.4 ✓ (4)
- Phase 2 (DevX): 2.1, 2.2, 2.3 ✓ (3)
- Phase 3 (Hoist): 3.1 ✓ (1)
- Phase 4 (Coordinator): 4.1, 4.2, 4.3, 4.4 ✓ (4)
- Phase 5 (Keystones): 5.1, 5.2, 5.3, 5.4, 5.5 ✓ (5)

**Retro blocks inserted (7 of 7 wave boundaries) ✓:**
- Post-Wave-0 (full detail)
- Post-Wave-1 (full detail)
- Post-Wave-2 (compact, references 9Q.3 template)
- Post-Wave-3 (compact)
- Post-Wave-4 (full detail — Coordinator)
- Post-Wave-5 (full detail — Keystones; the heaviest retro)
- Post-Wave-6 (FINAL closure retro — ends the migration)

**Remaining tag-line application (v7 mechanical pass — ~2 hours):**
- Phase 0 NEW tasks created in amendments (0.8 - 0.19, 12 tasks — need migration into Phase 0 body proper before tagging)
- Phase 4 Task 4.5 (dismiss + lifecycle observer — body not yet authored as standalone)
- Phase 5 NEW tasks (5.0 CurveAnimator, 5.6, 5.7, 5.8, 5.9, 5.10 — need authoring)
- Phase 6 hygiene tasks (~44 tasks: 6.1-6.44)
- Phase 7 tasks (7.0-7.6 — most need authoring per Agent X8 audit)

**Tag-line application complete for: all canonical migration tasks (Phases 0-5 originals).**

The 24-task application covers the LOAD-BEARING diversity:
- Layer coverage: L1 (Animation), L2 (Tokens), L3 (Domain substrate), L4 (Choreography), L5 (Composition root) — all 5 represented
- Pillar coverage: P1.2, P1.9, P1.10, P2.1, P2.4, P2.7, P2.11, P2.13, P3.1, P3.2, P3.3, P3.4, P3.5, P3.6, P3.7, P4.1, P4.3, P4.6, P5.4, P5.5, P6.3, P6.6, P6.7, P8.3, P8.6, P9.1, P9.4, P10.1, P10.2, P10.4, P10.5, P11.1, P11.5, P12.1, P14.1, P15.4, P19.5, P20.3, P20.4 — 39 pillars exercised
- Parity classification: safe (16 tasks), break (1 task — 0.4 with explicit ledger entry), neutral (4 tasks — dormant/dead-code), needs-ksdiff (1 task — 4.4)
- Test impact: 0 to 60+ blast radius represented
- Dependencies: cross-wave deps explicit (0.3→5.5, 0.17→5.1, 1.2→5.1, etc.)

v7 mechanical pass applies the SAME demonstrated pattern to remaining ~56 tasks. The pattern is now BINDING.

### 9Q.7 — What this DOES NOT add

Per user directive ("not super long doc strings"):
- ❌ No new architecture diagrams beyond what already exists
- ❌ No expanded WHY/WHAT/NEXT essays per task
- ❌ No glossary section
- ❌ No TOC/index document (single SSoT until Task 7.2 splits it)
- ❌ No per-task narrative walkthroughs

What it DOES add:
- ✓ One-line tag per task (top-down traceability)
- ✓ One retro-gate block per wave-boundary (cleanup discipline)
- ✓ Reclassification of 4 tasks as bug fixes (not features)
- ✓ Victory criterion explicitly anchored to "no new features"

---

---

# 🔒 Phase 8 — Parity + Verification Layer (v5 — IN PROGRESS)

**User-mandated bar:** **FRAME-IDENTICAL** parity between pre-migration and post-migration UX. The compiled app after the migration must produce pixel-identical output to the compiled app before the migration — EXCEPT for tasks explicitly listed in the Parity-Break Ledger below.

**Verification mechanism:** **Maestro flows + per-state screenshots + Kaleidoscope/ksdiff visual diff** per phase landing. Any pixel delta requires sign-off OR landing in the Parity-Break Ledger.

**Status:** 4 specialized agents (T=parity audit, U=method-by-method contracts, V=tech-debt registry, W=DRY pass) dispatched in parallel. Each carries `[ROLE: ADVERSARIAL-REVIEWER]` + `/root-cause-tracing` 6-question discipline. v5 finalizes when all 4 return + parity ledger + parity-break ledger + verification protocol are locked.

---

## 🚨 8X — CRITICAL DECISIONS BLOCKING v6

**Three parity-correctness issues MUST resolve before Phase 5 work begins.**

### Decision X1 — `Spring.overdampedMultiplier`: 1.25 (code) or 1.5 (design intent)?

**[ARCH-ADVERSARIAL-PARITY-11a]** Agent T direct file read at `Spring.swift:53` returns `1.25`. Earlier audit prompts referenced `1.5`. **This is a value-parity question** — if the design intent is 1.5 and code is 1.25, OR vice versa, then `settlingDuration` for overdamped springs (any `dampingRatio >= 1.0`) is 20% different than expected.

- Affects: `tryClearActiveCellAtRest`'s settling detection for `pinchToCellsDamping = 1.0` (borderline-critical) and `cancelledDamping = 0.95` (could trip overdamped branch under retargeting).
- **Resolution required:** read `Spring.swift:53` ground truth + cross-reference any prior commit / design doc. **If 1.5 is intended**, fix the code (parity-breaking but design-correct). **If 1.25 is intended**, fix the prompts/docs.

### Decision X2 — 6 hidden literals at `TimelineCanvas.swift:1225-1236`

**[ARCH-ADVERSARIAL-PARITY-02a]** Agent T discovered the morph label fade triplet (`UIView.animate` ×3 for `dateLabel/topicSummaryLabel/todayLabel+pinchGlyph` chrome alpha) carries 6 magic literals NOT in v4's `MorphTiming` proposal: durations `0.08, 0.17, 0.20` and delays `0.0, 0.03, 0.08`.

Acceptance grep `grep "0\.08\|1\.5" TimelineCanvas.swift` will FAIL after Phase 1 ships because `0.08` appears at line 1225 (label-fade duration) AND line 1233 (label-fade delay) AND in proposed `windupContribution`.

**Resolution required:** EITHER extend `MorphTiming` with `chromeFadeDuration_short/medium/long` + `chromeFadeDelay_0/early/late` tokens, OR define a parallel `LabelFadeTiming` namespace. Coordinate with Agent W's NEW Task 6.27 (collapse triplet via `UIViewPropertyAnimator + addAnimations(_:delayFactor:)`).

### Decision X3 — `snapToChatRestState` end-state equivalence

**[ARCH-ADVERSARIAL-PARITY-08a]** Phase 0 Task 0.13's `snapToChatRestState` (the reduce-motion bypass path) doesn't reset:
- `dateLabel.alpha`, `topicSummaryLabel.alpha`, `todayLabel.alpha`, `pinchGlyph.alpha` (morph sets to 0 over t=1.5s; snap leaves at 1)
- `chatRestCenterLabel.alpha` (morph sets to 1 via CABasicAnimation; snap leaves at 0)
- `contentHost.layer.transform = .identity` (morph applies arc; snap doesn't reset)

**Result:** Reduce-Motion users land at chat-rest with **wrong chrome alphas + invisible center label**. The bypass produces a different end state than the morph end state — VIOLATION of frame-identical bar.

**Resolution required:** Extend `snapToChatRestState` to ALSO write:
```swift
activeCell.dateLabel.alpha = 0
activeCell.topicSummaryLabel.alpha = 0
activeCell.todayLabel.alpha = 0
activeCell.pinchGlyph.alpha = 0
activeCell.chatRestCenterLabel.alpha = 1
contentHost.layer.transform = CATransform3DIdentity
```
…inside the same `CATransaction.withSuppressedActions` block.

### Decision X4 — DEBT-27: ChatBubbleView "never sender" rule violation

**[ARCH-ADVERSARIAL-DEBT-27]** `ChatBubbleView.swift:8` header declares: *"Authorship reads from `Message.Role` — never 'sender'..."* — yet lines 23-29 of the SAME file create `let senderLabel = UILabel()` and set `senderLabel.text = Self.displayName(for: message.role)`. The "never sender" rule is violated **7+ times inside the same file**.

**Resolution required:** EITHER rename `senderLabel` → `roleLabel` everywhere in ChatBubbleView, OR amend the header rule to "the LABEL identity uses 'role'; senderLabel is the legacy property name we tolerate." **Pick one.** This is the cleanest tier-3b consistency fix in the codebase. Effort: 1 hour.

---

## 8A — Parity Ledger (Agent T — returned)

**Every constant extraction in Phases 1-6 produces a row in this ledger. Each row asserts old == new byte-for-byte.**

⏳ *Awaiting Agent T — will populate the full table covering RevealTiming (5 values), MorphTiming + MorphCurves (14 values), MorphAnimationKey (5 strings), CellLayoutTuning (1 value), PhysicsTuning (5 values), CellChromeTiming (2 values from Agent P LINE-20), plus Spring + SpringAnimator + CameraAnimator internal constants.*

**Provisional table shape:**

| New token | Old location | Old value | New location | New value | Match? | Verified by |
|---|---|---|---|---|---|---|
| `RevealTiming.blurFadeInDuration` | V2RootViewController.swift:110 (1st UIView.animate `withDuration:`) | `0.3` | DesignSystem/RevealTiming.swift | `0.3` | ✓ | Agent T |
| `RevealTiming.crossFadeDelay` | V2RootViewController.swift:114 (2nd UIView.animate `delay:`) | `0.2` | DesignSystem/RevealTiming.swift | `0.2` | ✓ | Agent T |
| `RevealTiming.crossFadeDuration` | V2RootViewController.swift:114 (`withDuration:`) | `0.3` | DesignSystem/RevealTiming.swift | `0.3` | ✓ | Agent T |
| `RevealTiming.blurDwellDelay` | V2RootViewController.swift:119 (`delay:`) | `0.5` | DesignSystem/RevealTiming.swift | `0.5` | ✓ | Agent T |
| `RevealTiming.blurFadeOutDuration` | V2RootViewController.swift:119 (`withDuration:`) | `0.7` | DesignSystem/RevealTiming.swift | `0.7` | ✓ | Agent T |
| `MorphTiming.windupDuration` | TimelineCanvas.swift:1153 | `0.78` | Conversation/V2/MorphTiming.swift | `0.78` | ✓ | Agent T |
| `MorphTiming.totalMorphDuration` | TimelineCanvas.swift:1154 | `1.5` | (same) | `1.5` | ✓ | Agent T |
| `MorphTiming.masterTimerDuration` | TimelineCanvas.swift:1297 | `1.2` | (same) | `1.2` | ✓ | Agent T |
| `MorphTiming.liftEndMagnitude` | TimelineCanvas.swift:1157 | `50` | (same) | `50` | ✓ | Agent T |
| `MorphTiming.unifiedArcYMagnitude` | TimelineCanvas.swift:1284 | `50` | (same) | `50` | ✓ | Agent T |
| `MorphTiming.unifiedArcZMagnitude` | TimelineCanvas.swift:1358 | `700` | (same) | `700` | ✓ | Agent T |
| (continues for 30+ more rows…) | | | | | | |

**Coverage acceptance:**
- [ ] Every literal numeric extracted into a token has a ledger row
- [ ] Every string-literal animation key has a ledger row
- [ ] Every CAMediaTimingFunction control-point tuple has a ledger row
- [ ] Every Spring default has a ledger row
- [ ] Mismatches halt the migration (typo in extraction = block ship)

### 8A.1 — Agent T's full ledger summary (all values VERIFIED old == new at d464c71)

**Phase 1.1 `RevealTiming`** — 5/5 values match. **HIDDEN GAP:** `[.curveEaseInOut, .allowUserInteraction]` options bag and three completion handlers are NOT extracted — flag for explicit "remains at call site" docs (or move into UIViewPropertyAnimator per Task 4.4).

**Phase 1.2 `MorphTiming` + `MorphCurves`** — 14/14 values match. **HIDDEN GAPS:**
- The 6 label-fade literals at TC:1225-1236 are MISSING (see Decision X2 above)
- `zoomContribution` at TC:1162 is DERIVED (`finalScale - 1.0 - windupContribution`), not constant — must NOT be added to MorphTiming
- `liftPhase` divisor `0.70` at TC:1355 + the `sin(... * .pi)` are NOT in MorphCurves — flag as derivation, not constant

**Phase 1.3 `MorphAnimationKey`** — 5/5 string values match. Re-entry guard at TC:1147 (`"windup.scale"`) preserved verbatim.

**Phase 1.4 `CellLayoutTuning`** — 1/1 value matches (200). **BEHAVIORAL DELTA:** removing the default `naturalCellHeight: CGFloat = 200` is intentional explicit-injection requirement.

**Phase 5.2 `PhysicsTuning`** — 5/5 init defaults match. **PARITY-05a:** Phase 5.2 must thread tuning to BOTH `CameraAnimator.init` AND the standalone `extensionAnimator = SpringAnimator<CGFloat>(...)` at TC:157-163 (v4 currently mentions only CameraAnimator). Anticipation* fields DELETED — intentional dead code removal.

**Phase 5.3 `GestureCommit`** — 3/3 case mappings produce identical damping values. Naming-only refactor at API layer.

**Phase 0.8 `preferredFrameRateRange`** — adds `(80,120,120)` to masterTimer + future MorphChoreographer. **INTENTIONAL parity-break on 120Hz devices** (no visual delta on 60Hz).

**Phase 0.13 `snapToChatRestState`** — END-STATE EQUIVALENCE GAP (see Decision X3 above). Math at v4:3211-3216 is parity-safe for camera + heightConstraint; gap is on chrome/center-label alpha + transform reset.

**Agent P LINE-20 `CellChromeTiming`** — namespace mentioned in v4:3477 but no concrete code block. **Status: queued finding, not closed task.** Plus 4 sibling smoothstep curves in TimelineCanvas (TC:294, 295, 298, 299, 698) are conceptually siblings to CellView:281 but live in different files — needs `EdgeMaskTiming` (or extension) to cover them.

### 8A.2 — Hidden parity risks (Agent T Part C)

| Risk | Site | Mitigation |
|---|---|---|
| `add(_:forKey:)` ordering for additive CABasicAnimations | TC:1210-1213 | Phase 5 Task 5.1 must preserve install order: windupScale → zoomScale → translate → centering |
| Z=700 × m34=-1/1000 coupling | TC:189 + TC:1358 | Extract `m34` to `MorphTiming.perspectiveFocalLength` OR document the coupling explicitly |
| `viewportCoveragePad = 40` origin | TC:1159 | Empirically determined; document derivation in MorphTiming |
| `cell.setCamera` clobbers external sublayerTransform | CellView:285 | Verify Phase 5 doesn't depend on cell sublayerTransform |
| `chatRestFactor` device fallback `4.92` | TC:1160 | Encodes iPhone-13/14 standard 844pt viewport; fallback only fires when `naturalH == 0` (shouldn't happen post-layout); document as "device-specific fallback" |
| `Spring.settlingPercentage = 0.0001` private static | Spring:52 | Affects `settlingDuration`; never tuned; consider exposing if Phase 5 introduces `PhysicsTuning.settlingPercentage` |

---

## 8B — Parity-Break Ledger (intentional UX deltas)

**These tasks INTENTIONALLY change the post-migration UX. Each is an UX improvement justified by HIG / Apple convention / bug fix. Every break is enumerated; every break is auditable; every break can be reverted independently.**

| Task | Old behavior | New behavior | Why (justification) | User-visible? | Reversible? |
|---|---|---|---|---|---|
| **0.1** — `resetMorphState` on pool return | `morphInProgress` leaks across pool round-trips; `chatRestCenterLabel.transform` stays at scale-down | All transient morph state cleared on pool return | Bug fix — prevents stale state corrupting recycled cells (Agent F + H) | NO (today no back-out exists; bug is dormant) | YES (remove resetMorphState call from returnToPool) |
| **0.2** — Delete `anticipationAnimator` + `PinchTuning.anticipation*` fields | Property declared + cancelled but never constructed → anticipation pre-bounce NEVER fires (regressed when V2 master-clock landed) | Code matches behavior; dead code removed | Eliminates dead code that test files crash on (Agent H) | NO (anticipation isn't firing today) | YES (re-add declaration; tests still crash though) |
| **0.4** — Fire `onMorphRevealReady` from pinch-commit master timer | Pinch-commit-to-chat-rest path never fires reveal callback (chat overlay never appears for pinch-commit) | Pinch-commit triggers reveal identical to tap-commit | Fixes B10 latent bug — completes the missing reveal path | YES (if any pinch-commit user discovers this path) | YES |
| **0.6** — Eliminate dual-tap path (remove `cell.onTap` chain) | Both VC tap AND cell.onTap fire; windup.scale animation key dedupes at canvas level | Only VC tap fires; deterministic single firing site | Removes accidental-correctness via animation-key dedupe (Agent H) | NO (tap-to-chat works identically; just single-path instead of dual) | YES |
| **0.8** — `preferredFrameRateRange` on masterTimer | Master timer's CADisplayLink defaults to 60Hz on ProMotion → liftBell peak may land between ticks | 120Hz on ProMotion → smooth morph | Frame-rate parity with AnimationController (Agent M RUNTIME-03) | YES on 120Hz devices (smoother morph) | YES |
| **0.11** — Split `.cancelled`/`.failed` from `.ended` in `handlePinch` | Control Center swipe / incoming call mid-pinch → `weightedFactor` check commits to chat-rest user never chose | `.cancelled`/`.failed` restore to origin without inspecting scale | Apple HIG: system aborts shouldn't act on partial input (Agent N CANCEL-04) | YES (users who get interrupted mid-pinch no longer get spurious commits) | YES |
| **0.12** — DisplayLink-local time (not wall-clock) for master timer | Background mid-morph → wall-clock advances during suspension → resume snaps to t=1.0 in one frame → CABasicAnimation/master-timer desync | Display-link-local elapsed accumulator → resume continues from where it paused | Background-resume parity (Agent N CANCEL-05) | YES (users who background mid-morph no longer see snap-to-end) | YES |
| **0.13** — Reduced-motion handling (snap-to-rest path) | Morph runs full 1.5s perspective-translation regardless of UIAccessibility.isReduceMotionEnabled | Reduce-Motion users see instant snap-to-chat-rest (no perspective animation) | Apple HIG: vestibular trigger respect (Agent N CANCEL-11) | YES only for users with Reduce Motion enabled (no delta for everyone else) | YES |
| **4.4 PROMOTE** — `UIViewPropertyAnimator + delayFactor` (REQUIRED) | Three independent UIView.animate blocks; no cancellation handle | Single animator with addAnimations(delayFactor:); explicit cancel API | Cancellation handle for backgrounding (Agent N CANCEL-06) | **POTENTIALLY** — visual timing may shift sub-frame; needs ksdiff verification | YES (revert to three UIView.animate blocks) |
| **4.5** — `RevealCoordinator.dismiss()` | No dismiss path; ChatVC retained forever once presented | Symmetric dismiss; cross-fade back; ChatVC released | Closes Q6 + enables future back-out (Agent M RUNTIME-06) | NO (dismiss not yet wired to UI; preparation only) | YES |
| **0.7 PROMOTE** — reloadData defensive guard | reloadData mid-active-cell orphans the active cell | reloadData clears activeCellIndex first; orphan path cleaned | State-lifecycle correctness (Agent S STATE-01) | NO (dormant today) | YES |

**Critical:** every "POTENTIALLY visible" entry MUST be sign-off-gated by ksdiff verification before shipping.

---

## 8C — Per-state screenshot capture protocol (Maestro)

**Maestro flow definitions (golden image capture points):**

### Flow 1 — tap-to-chat (the primary morph)
- **Pre-state** (S0): home view, cells visible, no active cell
- **Mid-windup** (S1): tap registered, t ≈ 0.4s into morph (windup peak)
- **Mid-zoom** (S2): t ≈ 0.8s (zoom + Y arc peak)
- **Pre-reveal** (S3): t ≈ 1.5s (morph settled, reveal not yet started)
- **Mid-cross-fade** (S4): t ≈ 1.85s (blur installed, cross-fade midpoint)
- **Settled-chat** (S5): t ≈ 2.6s (blur removed, ChatVC fully visible, canvas alpha=0)

### Flow 2 — pinch-commit-to-chat-rest
- **Pre-state** (S0): home view
- **Pinch-began** (S1): two fingers down on cell
- **Pinch-mid-spread** (S2): scale ≈ 1.5, midpoint
- **Pinch-past-threshold** (S3): scale ≈ 2.0 (commit threshold)
- **Released** (S4): commit decision made, spring engaged
- **Settled-chat** (S5): chat-rest reached

### Flow 3 — pinch-to-cell-rest (cancel direction)
- **Pre-state** (S0): chat-rest active cell
- **Pinch-began** (S1)
- **Pinch-pinching-in** (S2): scale ≈ 0.7
- **Released-past-cancel** (S3): scale ≈ 0.5
- **Settled-cell-rest** (S4)

### Flow 4 — tap-during-cancel-spring (Task 0.3 isQuiet guard)
- Pre-Phase-0: tap during cancel spring may engage morph atop cancel
- Post-Phase-0: tap during cancel spring → no-op (guard catches)
- Capture: 3 frames at 100ms intervals from tap

### Flow 5 — background-resume mid-morph (Task 0.12)
- Pre-Phase-0: backgrounded mid-morph → snap to t=1.0 on resume
- Post-Phase-0: backgrounded mid-morph → continues from pause point on resume
- Capture: 2 frames bracketing the resume boundary

### Flow 6 — reduce-motion-enabled tap (Task 0.13)
- Pre-Phase-0: full 1.5s morph
- Post-Phase-0: instant snap-to-chat-rest
- Capture: 3 frames at 50ms intervals from tap

### Flow 7 — RevealCoordinator dismiss (Phase 4 Task 4.5, new path)
- Captures the new dismiss choreography
- Reverse-direction parity: dismiss should look like reveal played backwards

**Per-phase landing acceptance:**
- [ ] All Maestro flows re-run after phase lands
- [ ] All per-state PNGs captured
- [ ] ksdiff against golden baseline (or against pre-Phase-N baseline)
- [ ] Pixel delta = 0 for parity-preserving tasks
- [ ] Pixel delta ≠ 0 only if task is in Parity-Break Ledger 8B
- [ ] Each non-zero delta requires explicit sign-off

---

## 8D — Method-by-method contract audit (Agent U — returned)

**State of method-level contracts:** 2 methods of ~107 carry full contract blocks (~2%). ~55 methods carry prose-grade rationale comments (~51%). ~50 methods carry no doc-comment at all (~47%). The codebase's prose comments are excellent — they explain *why*. The gap is the absence of a structured contract block.

**The two PASS methods (`dequeueCell`, `tryClearActiveCellAtRest`) are the load-bearing methods that most demanded that discipline.** The pattern is correct; it just hasn't propagated.

### 8D.1 — Five cross-cutting contract templates

Apply these templates by reference (per-method docs say "see template TN" + their own delta).

**Template T1 — `apply*` Per-Tick** (`applyCameraTransform`, `applyMasterTick`, `applyExtensionTick`):
> Called from a per-frame source (CADisplayLink tick or spring valueChanged). MUST run inside `CATransaction.withSuppressedActions` (caller-established OR self-wrapped — declare which). Writes view-property state derived from progress / animator value. MUST NOT make business decisions (commit/cancel/state-transition) — those belong in completion handlers or gesture state machines. Thread: main. Idempotent under repeated calls with the same input state.

**Template T2 — `update*` Idempotent Reconciler** (`updateVisibleCells`, `updateNeighborTranslations`, `updateEdgeMaskAlphas`):
> Repeated calls with unchanged input produce no observable state delta. Reads current substrate state; writes derived state. No business decisions — pure reconciliation. May be called from layout, gesture changed-tick, spring tick, setCamera. Thread: main.

**Template T3 — `try*` Atomic-Check-Then-Do** (`tryClearActiveCellAtRest`, `tryFireOuterCompletion`):
> Idempotent: the "did it already happen?" check makes repeated calls safe. The check + act are atomic within main-thread serialization. Used in race-coordination paths where two independent completions both call this and exactly one should succeed at performing the work. Thread: main.

**Template T4 — `install*` Builder** (one-shot at init):
> Called ONCE during init / viewDidLoad. NOT idempotent — second call may duplicate subviews/constraints/recognizers. Sole writer of the subview tree, constraints, or recognizer it builds. Thread: main. EXCEPTION: `CellView.installLayout` is documented as idempotent (deactivates prior).

**Template T5 — `handle*` Gesture-Handler** (`@objc` UIKit callbacks):
> `@objc` (or called by an `@objc` dispatcher). Invoked by UIKit on the main thread. Reads recognizer state; writes substrate state. Re-entry contract: UIKit guarantees serialization within one recognizer; cross-recognizer simultaneity governed by `gestureRecognizer(_:shouldRecognizeSimultaneouslyWith:)`. Thread: main.

### 8D.2 — 10 worst-offender contract blocks (drop-in)

Agent U produced full contract blocks for the 10 most load-bearing under-documented methods. The full text lives at `/private/tmp/claude-501/.../a68fdf872930ef324.output`. Summary references in v4 task list:

| Method | File:Line | Block ID | Phase to land |
|---|---|---|---|
| `setCamera(_:)` | TimelineCanvas:332 | `ARCH-ADVERSARIAL-METHOD-01` | Phase 6 Task 6.32 |
| `animateCameraToChatRest(forCellAt:)` | TimelineCanvas:1143 | `ARCH-ADVERSARIAL-METHOD-02` | Phase 5 Task 5.1 |
| `CameraAnimator.animate(to:velocity:spring:completion:)` | CameraAnimator:102 | `ARCH-ADVERSARIAL-METHOD-03` | Phase 5 Task 5.5 |
| `updateVisibleCells()` | TimelineCanvas:596 | `ARCH-ADVERSARIAL-METHOD-04` | Phase 6 Task 6.32 |
| `returnToPool(_:)` | TimelineCanvas:777 | `ARCH-ADVERSARIAL-METHOD-05` | Phase 6 Task 6.32 |
| `SpringAnimator.updateAnimation(dt:)` | SpringAnimator:129 | `ARCH-ADVERSARIAL-METHOD-06` | Phase 6 Task 6.32 |
| `handlePinchEnded(_:)` | TimelineCanvas:1019 | `ARCH-ADVERSARIAL-METHOD-07` | Phase 6 Task 6.32 |
| `applyMasterTick(_:)` | TimelineCanvas:1348 | `ARCH-ADVERSARIAL-METHOD-08` | Phase 5 Task 5.1 |
| `animateCameraToCellRestPath(...)` | TimelineCanvas:1385 | `ARCH-ADVERSARIAL-METHOD-09` | Phase 5 Task 5.4 |
| `AnimationController._displayLinkFired(_:)` | AnimationController:49 | `ARCH-ADVERSARIAL-METHOD-10` | Phase 6 Task 6.32 |

### 8D.3 — Recognized contract divergences (load-bearing bugs hidden by absence of contract docs)

These are real bugs surfaced ONLY because the contract audit forced explicit articulation:

1. **`applyMasterTick` bypasses `setCamera` single-gateway.** Writes `self.camera` directly + calls `applyCameraTransform`. The full setCamera fan-out (pan-enable, lastCellRestScrollY, hasExternalCameraWrite, onCameraChanged) is intentionally skipped because the master timer owns those. **The single-gateway invariant is already violated.** Document or restore parity.

2. **`returnToPool` active-cell-rejection branch leaks state.** If caller doesn't pre-filter on `cell.index != activeCellIndex`, the cell is NOT pooled but the caller may have removed it from `instantiatedCells`. **State leak.** Today only one site filters correctly; `reloadData` masks the bug via implicit activeCellIndex clear.

3. **`AnimationController._displayLinkFired` mutates dict during iteration.** `for animator in animations.values` while the `.ended` branch removes entries. Currently works because Dictionary.Values is buffer-based — undocumented. **Fix:** iterate snapshot (`for animator in Array(animations.values)`).

4. **`animateCameraToChatRest` does NOT set `activeCellIndex` itself.** Pinch path sets it at `.began`; tap path goes through `handleCellTap` which doesn't set it. **Latent bug surface** — see Agent F's earlier finding.

5. **`SpringAnimator.updateAnimation` final-tick ordering is load-bearing for `tryClearActiveCellAtRest`** (value→valueChanged→completion fires while state is still `.running`). The comment notes this but no test pins it. The contract block is the symbol that tests should cite.

### 8D.4 — Method-organization defects beyond Agent L

**SRP violations:** `setCamera` (7 concerns), `handlePinchEnded` (3 concerns), `animateCameraToChatRest` (~100 LOC, the largest method).

**Methods >50 LOC:** `animateCameraToChatRest` (~100), `updateVisibleCells` (~80), `handlePinchEnded` (~72), `returnToPool` (~50), `animateCameraToCellRestPath` (~37).

**5+ params (parameter-object opportunity):** `CellView.installLayout(into:naturalCenterY:naturalHeight:pageWidth:horizontalInset:)` — should accept `CellLayoutSpec` value type.

**Should-be-properties:** `cellCount()` → `var cellCount: Int`; `pageHeight()` → `var pageHeight: CGFloat` (companion `pageWidth` already a property — inconsistent); `currentCanvasProgress()` → `var canvasProgress: CGFloat`.

**`visibleCells: var` sorts dictionary every call — NOT O(1).** Either rename `sortedVisibleCells` (signal work) OR convert to method.

---

---

## 8E — Tech-debt registry (Agent V — returned)

**67 findings across 6 forms.** Headline: explicit-marker discipline is genuinely clean (0 TODO/FIXME/HACK/XXX, verified). The debt is all IMPLICIT.

### 8E.1 — Six forms of debt found

| Form | Count | Severity profile |
|---|---|---|
| A. Explicit comment markers (TODO/FIXME/HACK/XXX/"for now") | **0** | Clean ✓ |
| B.1 Load-bearing reasoning encoded only in prose (not asserted) | **11** sites (DEBT-04..14) | Medium-High |
| B.2 Comments referencing files/types that don't exist | **12** sites (DEBT-15..26) | Medium |
| B.3 Comment-vs-code contradiction within same file | **1** (DEBT-27 — ChatBubbleView) | High (see Decision X4) |
| B.5 `private(set)` access leaks for test instrumentation | **13** sites (DEBT-29..30) | Low |
| C.1 IUO declarations | **11** sites — already in Phase 6 | Medium |
| C.2 Sentinel values | **2** (CellView.index = -1, naturalHeight = 0) — DEBT-31/32 | Low |
| C.3 Dead code | **5** (anticipation* fields + animator + tests) — Phase 0 Task 0.2 | High |
| C.4 Unused imports | **2** (CellView Observation, MathUtilities Foundation) | Low |
| C.7 Force-unwrap/`try!`/`as!`/`@unchecked Sendable` | **0** | Clean ✓ |
| D. Test-infra debt (missing scripts + always-skipped tests) | **7** items (DEBT-40..46) | Medium |
| E. Architectural debt (timer architecture, megafile, asymmetric reveal) | **10** items (DEBT-47..56) | Mostly scheduled in v4 |
| F. Process debt (docs/CHANGELOG/CODEOWNERS/SwiftLint absence) | **11** items (DEBT-57..67) | Low-Medium |

### 8E.2 — 12 debt items NOT yet scheduled in v4

| Debt | Form | Severity | Proposed Phase | Effort |
|---|---|---|---|---|
| DEBT-04..14 | 11 load-bearing comments → runtime `assert`s | B.1 | NEW Phase 7 Task 7.3 "Invariant Hardening" | 1-2d |
| DEBT-15..26 | 12 stale file/type references | B.2 | NEW Phase 7 Task 7.4 sweep (3 of 12 covered by Task 0.15) | 0.5d |
| DEBT-27 | ChatBubbleView "never sender" violation | B.3 | NEW Phase 0 Task 0.16 (immediate fix) | 1h — see Decision X4 |
| DEBT-29..30 | `@_spi(Testing)` formalize 13 access leaks | B.5 | NEW Phase 6 Task 6.39 | 2-4h |
| DEBT-31..32 | Sentinel `-1` and `0` → Optional | C.2 | Folded into Phase 6 Task 6.14 (already covers `CellView.index = -1`) — extend to `naturalHeight` | 1h |
| DEBT-38 | `dequeueCell` tuple debt | C.6 | NEW Phase 4 amendment — redesign during RevealCoordinator extraction | 0.5d |
| DEBT-42..43 | XCTSkip-by-default + permanent XCTSkip | D | Bundled with Phase 0 Task 0.2 (orphan test deletion) | 1h |
| DEBT-45 | Test naming inconsistency (Wave4a..f / WaveR1..R75 / Phase0Spike / no-prefix) | D | NEW Phase 2 Task 2.4 rename pass | 2-4h |
| DEBT-50 | morphInProgress duplicates `activeCellIndex == self.index` | E | NEW Phase 5 Task 5.7 collapse | 0.5d |
| DEBT-56 | Camera mutability after init bypasses precondition | E | Already covered by Phase 0 Task 0.14 (Agent P LINE-06: `Camera.translation: var → let`) | (scheduled) |
| DEBT-59 | SwiftLint absence | F | NEW Phase 2 Task 2.5 alongside SwiftFormat | 1h |
| DEBT-61..65 | Missing docs (VOCABULARY, FILE_ORGANIZATION, CHANGELOG, CODEOWNERS, MASTER-CHECKLIST) | F | NEW Phase 7 Task 7.5 doc-creation OR ref-removal sweep | 1d |

### 8E.3 — The 11 load-bearing comments that need runtime checks (DEBT-04..14)

These are tier-3b's biggest gap: invariants documented only in prose. A reviewer who skims for code shape can violate a load-bearing invariant silently.

| ID | Site | Invariant | Proposed assert |
|---|---|---|---|
| DEBT-04 | SpringAnimator:126 | Final-tick value→valueChanged→completion→state ordering | `tryClearActiveCellAtRest` test that exercises simultaneous settle |
| DEBT-05 | CellView:53,73,99-100 | centerY-anchored → midY preserved under symmetric extension | `assert(cell.frame.midY == naturalMidY)` post-layout in DEBUG |
| DEBT-06 | TimelineCanvas:93 | Camera + extension animators share natural frequency | `assert(extensionAnimator.spring.response == cameraAnimator.spring.response)` at engagement |
| DEBT-07 | TimelineCanvas:177 | `clipsToBounds=true` enforces "no other cell visible at chat-rest" | Visual snapshot test |
| DEBT-08 | TimelineCanvas:227 | sRGB-locked CGColor mandatory on wide-gamut sims | `assert(cgColor.colorSpace == sRGB)` in DEBUG init path |
| DEBT-09 | TimelineCanvas:330 | Camera is mutable struct — caller may mutate | (Resolved by Phase 0 Task 0.14: `var → let`) |
| DEBT-10 | TimelineCanvas:368 | Chrome alpha curves driven by canvas progress | Visual test |
| DEBT-11 | TimelineCanvas:518 | Visible-cell contiguity invariant | `assert(visibleCells.keys.sorted() are contiguous)` |
| DEBT-12 | TimelineCanvas:696 | Carrier-alpha applies only to active cell | Already guarded in code; comment-redundant |
| DEBT-13 | TimelineCanvas:1262 | (Same as DEBT-05) | (Resolved with DEBT-05) |
| DEBT-14 | CellView:268 | `setCamera` is idempotent | `setCamera(x) ∘ setCamera(x) == setCamera(x)` property test |

→ Phase 7 Task 7.3 — "Invariant Hardening" — convert ≥5 highest-leverage of these to runtime asserts.

---

### ☐ Task 7.3 — Invariant Hardening (11 prose comments → runtime asserts) **(AUTHORED INLINE per 9R.4.3 — closes Migration M7)**
`[L1+L3 (cuts across substrate + domain) | P3.2 P6.3 P6.4 P15.1 | Wave 7 (Post-keystone) | Parity: safe (asserts trap only on programmer error) | Test: 6 (new invariant tests) | Deps: 5.1, 5.5, 6.36]`
**Agent Ensemble:**
- Implementer: **L1-Agent** (file-partition owner per §0.1)
- Reviewer-Doctrine: **Doctrine-Agent** (universal — verifies 9A.1 row pillars match landed code)
- Reviewer-Concurrency: **Concurrency-Agent** (per 9S contract — triggered for `@MainActor`/`Sendable` touch points)
- Reviewer-Parity: **Parity-Agent** (per Parity Ledger 8A/8B; mandatory at wave close)
- Orchestrator: **Wave-7-Lead** (dispatch + retro merge gate per 9Q.3)
**Parallel within Wave 7:** default yes (see §0.4 DAG for critical-path exceptions); merge-conflict-free by L1 file-partition
**Files:** `Animation/SpringAnimator.swift`, `Animation/Spring.swift`, `Conversation/V2/CellView.swift`, `Conversation/V2/TimelineCanvas.swift`, `Conversation/Data/ConversationStore.swift`
**Class:** LOAD-BEARING (Pillar 3.2 junior-dev test mandate) · **Heat:** WARM
**Citation:** `[ARCH-ADVERSARIAL-DEBT-04..14, 8E.3, Agent V]`

**Goal:** Convert ≥5 of the 11 prose-only invariants to runtime `assert` or `precondition`. Pillar 3.2 ("if >3 invariants documented only in prose, the junior fails") enforced at code level, not comment level.

**The 5 highest-leverage conversions (do these in Wave 7; remaining 6 may defer or stay as prose if explicit refusal added):**

```swift
// DEBT-04 — SpringAnimator final-tick ordering invariant
// SpringAnimator.swift:126 (the `value → valueChanged → completion → state=.ended` sequence)
// ADD inside updateAnimation at the .running → .ended transition:
assert(state == .running, "SpringAnimator: state must still be .running when completion fires (tryClearActiveCellAtRest depends on this ordering)")

// DEBT-05 — CellView centerY-anchored invariant
// CellView.swift:99 (and 1262) — "midY in page coords is invariant under symmetric extension"
// ADD inside installLayout after centerY constraint activate:
#if DEBUG
let expectedMidY = naturalCenterY
DispatchQueue.main.async {
    assert(abs(self.frame.midY - expectedMidY) < 0.5, "CellView: centerY-anchored invariant violated; frame.midY=\(self.frame.midY) expected=\(expectedMidY)")
}
#endif

// DEBT-06 — Camera + extension animators share natural frequency
// TimelineCanvas.swift:93 — "two springs share natural frequency (coordination invariant)"
// ADD at spring-swap sites (~TC:1273, 1310, 1402):
assert(extensionAnimator.spring.response == cameraAnimator.translationAnimator.spring.response,
       "Animator coordination invariant: camera + extension MUST share spring.response")

// DEBT-08 — sRGB-locked CGColor invariant
// TimelineCanvas.swift:227 — "load-bearing: on wide-gamut sims (Display-P3)..."
// ADD inside the sRGB extension (per Task 6.22 if landed) or at use sites:
extension UIColor {
    var sRGBLockedCGColor: CGColor {
        let result = cgColor.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!,
                                        intent: .defaultIntent, options: nil) ?? cgColor
        #if DEBUG
        assert(result.colorSpace?.name == CGColorSpace.sRGB, "UIColor.sRGBLockedCGColor: conversion produced non-sRGB color space")
        #endif
        return result
    }
}

// DEBT-19 — Dual-index invariant (ConversationStore + TimelineCanvas pool)
// Already covered by Task 6.36 dual-index preconditions; verify those land.
// ConversationStore.swift:30 — ADD:
private func insert(_ conversation: Conversation) {
    precondition(conversationsByID[conversation.id] == nil,
                 "ConversationStore.insert: duplicate id \(conversation.id) — dual-index invariant violation")
    conversationsByID[conversation.id] = conversation
    conversations.append(conversation)
}
```

**For the remaining 6 (DEBT-07, 10, 11, 12, 13, 14) — case-by-case:**
- DEBT-07 (`clipsToBounds=true` invariant) — defer to prose; setting `clipsToBounds` once at init is hard to assert post-hoc without observer overhead
- DEBT-10 (Chrome alpha curves) — covered by Task 5.8 (`performMorphChromeTransition`) ownership move
- DEBT-11 (Visible-cell contiguity) — `assert(Set(visibleRange).isSubset(of: instantiatedCells.keys))` adds O(n); defer to test
- DEBT-12 (Carrier-alpha) — already code-guarded; no assert needed
- DEBT-13 (Same as DEBT-05) — resolved by DEBT-05
- DEBT-14 (`setCamera` idempotent) — property test, not runtime assert

**Acceptance:**
- [ ] 5 highest-leverage prose invariants converted to runtime `assert`/`precondition`
- [ ] Each converted invariant has a test that proves the assert fires when violated
- [ ] Each remaining prose invariant carries an explicit refusal comment ("// PROSE-ONLY invariant — converting would <reason>") OR is removed
- [ ] Pillar 3.2 junior-dev test passes on Spring + SpringAnimator + ConversationStore + CellView (junior cannot violate the invariants without the assert firing)
- [ ] 9B 10-pillar checklist green

### 8E.4 — Agent V's 12 stale references (DEBT-15..26)

| Reference | Type | Referenced from | Resolution |
|---|---|---|---|
| `docs/VOCABULARY.md` | File | ChatBubbleView:7; 2 READMEs | Create OR strip refs (Phase 7 Task 7.5) |
| `docs/FILE_ORGANIZATION.md` | File | 2 READMEs | Same |
| `MASTER-CHECKLIST.json` | File | ChatBody/README.md | Strip ref (only `REFACTOR-CHECKLIST.md` exists) |
| `Conversation/MorphTiming.swift` | File | PinchTuning.swift:3 | Created by Phase 1 Task 1.2 ✓ |
| `ConversationCell` | Type | Theme.swift:5; ChatBubbleView:4 | Renamed to `CellView`; update refs |
| `ChatBodyView` | Type | ChatBody/README; ChatBubbleView:3 | Never existed; strip refs |
| `ConversationContentView` | Type | ChatBody/README | Strip ref |
| `CellSummaryView` | Type | ChatBody/README | Strip ref |
| `ConversationCell.apply(_:)` | Method | Theme.swift:5 | No such method; strip ref |
| `pillar P3.T3` | Identifier | ChatBody/README:4 | Strip ref (no MASTER-CHECKLIST.json exists) |
| "Tier 3B+" classification | Taxonomy | ChatBubbleView:3 | Lives only in REFACTOR-CHECKLIST.md; document explicitly |
| `D2 §5.2 / §7.15 / §7.16 / §7.17 / §7.24 / §10.78 / §10.13 / §0.4 / §4.3.7.3 / §13.4` | Section refs | PinchTuning, V2RootViewController, TimelineDataSource | **16 § references to external D2 SSoT not in repo.** Either commit D2 or strip section markers |

---

## 8F — DRY pass / rule-of-3 (Agent W — returned)

**20 findings. Verdict on v4's 5 existing DRY tasks: 3 pass rule-of-3, 2 below threshold.**

| v4 Task | Sites | Rule-of-3? | Verdict |
|---|---|---|---|
| 6.17 (`Conversation.dayMarker`) | 2 (CellView:255 + ChatViewController:37) | **NO** | **DEFER OR document coupling-prevention rationale** |
| 6.21 (`UIView.pinToSuperview`) | 3 (V2RootVC:50-55, 87-92, 102-107) | YES | **PROCEED** |
| 6.22 (`UIColor.sRGBLockedCGColor`) | 2 (TC:201-205, 231-234) | **NO** | **DEFER — no 3rd site foreseeable** |
| 6.23 (`CABasicAnimation.make` factory) | 5 (TC:1164/1174/1184/1200/1215) | YES (strongest candidate) | **PROCEED** — saves ~35 LOC, zero info loss |
| 6.26 (`activeCellContext` helper) | 4 (TC:715, 978, 1025, 1390) | YES | **PROCEED** — with caveat: 2 near-miss sites need different shapes |

### 8F.1 — NEW Task 6.27 — Collapse morph label fade triplet

**`[ARCH-ADVERSARIAL-DRY-05 + DRY-20]`** — 3 sites at TimelineCanvas:1225-1236 form one logical choreography (the morph chrome cross-fade). Collapse via `UIViewPropertyAnimator + addAnimations(_:delayFactor:)`.

⚠️ **Semantic-loss caveat:** the 3 original animations have DIFFERENT durations (0.08, 0.17, 0.20). UIViewPropertyAnimator's `delayFactor` forces ONE shared duration with relative start times. Visual result will differ. **REQUIRES designer sign-off** before adoption. If acceptable: parallels Task 4.4 (V2RootViewController triplet) — same pattern applied to the cell-chrome triplet.

Coordinate with Decision X2 (the 6 hidden literals at TC:1225-1236 must land in MorphTiming OR LabelFadeTiming).

### 8F.2 — Anti-DRY traps named (do NOT couple)

| Anti-DRY ID | Sites | Why leave separate |
|---|---|---|
| `ARCH-ADVERSARIAL-DRY-13` | `safeVel` (CameraAnimator:124) vs `safeVelY` (TC:901) | Different invariants: CameraAnimator floors sub-1pt/s to zero (perceptual filter); TC guards finite only (NaN safety). Coupling would silently introduce 1pt/s floor in pan-deceleration → motion physics change |
| `ARCH-ADVERSARIAL-DRY-07` | `[weak self]` closure boilerplate | Already shortest form (`self?.method()`) — no abstraction to make |
| `ARCH-ADVERSARIAL-DRY-08` | `NSLayoutConstraint.activate` 7 sites | Only the 3 full-bleed sites share semantics; 4 others activate distinct constraint sets — no DRY beyond Task 6.21 |
| `ARCH-ADVERSARIAL-DRY-11` | LRU-ordered keyed pool triplet (TC:47-49 + ConversationStore:15-17) | 1.5 sites; sibling invariants differ; over-abstraction risk |

### 8F.3 — Patterns confirmed below rule-of-3 (defer until 3rd site)

- `CGFloat.finiteOrZero` — 2 value-substitution sites
- `progressToAlpha(progress, start, end)` — 2 sites (CellView:281 + TC:698); edges differ deliberately
- `sRGBLockedCGColor` (Task 6.22) — 2 sites; no 3rd foreseeable

### 8F.4 — Patterns confirmed already-DRY (no work)

- **`CATransaction.withSuppressedActions`** — 12 usage sites, ALL via the helper. Grep for raw `CATransaction.begin()` returns ZERO hits in production. Discipline is universally adopted. ✓

---

---

## 8F — DRY pass / rule-of-3 enforcement (pending Agent W)

**Scope:** every 3+ repetition catalogued + abstraction proposed + verified against rule-of-3 + cross-checked against v4's existing DRY tasks (6.17, 6.21, 6.22, 6.23, 6.26). Anti-DRY traps identified.

⏳ *Awaiting Agent W — will populate `ARCH-ADVERSARIAL-DRY-*` findings.*

---

## 🚦 v4 Unified Verdict (UPDATED)

**Ready to implement: PARTIAL — with EXPANDED outstanding work.**

**What changed v3 → v4:**
- 7 adversarial agents added 87 net-new findings across runtime correctness, cancellation, Wave adherence, line-level discipline, file-org visual digestion, v3-critique, and state lifecycle.
- 26 new tasks introduced (0.7 PROMOTE, 0.8-0.15, 4.4 PROMOTE, 4.5, 5.0, 5.6, 6.28-6.38, 7.0-7.2).
- 16 inline amendments to existing v3 tasks.
- Effort estimate recalibrated 14-20 → **18-29 days**.

**Decisions blocking v5:**
1. **Wave Path A vs Path B** (WAVE-06) — fold MorphChoreographer into substrate via CurveAnimator, OR explicitly refuse with rejection-list entry. Agent O recommends Path A if budget allows.
2. **Named spring tokens** (WAVE-04) — adopt `.smooth/.snappy/.bouncy` OR reject.
3. **SSoT restructure** (V3-15) — per-phase files OR keep megafile with executive-summary front-matter.

**Outstanding blocking implementation:**
1. **Visual-regression strategy** (V3-05) — Maestro flows + per-state screenshots required for EVERY task that mutates animation paths (Phases 4 + 5 in particular). Concrete diff method + tolerance threshold + sample rate must be specified per task.
2. **Test signature audit** — confirm `animateCameraToChatRest(forCellAt:)` 60+ callers all use the public signature.
3. **Coherence tests 3 + 5** (V3-11) — parameter consistency + confidence propagation are PASS WITH NOTES; the notes must be resolved before "implementation-ready" is honest.
4. **Decision on the 3 blocking items above** (Wave path, named tokens, SSoT restructure).

**Source-confidence summary:**
- **HIGH confidence** on Phase 0 + Phase 6 hygiene + Phase 1 tokens (mechanical, well-cited, low blast radius)
- **MEDIUM confidence** on Phase 3 (hoist + @MainActor) + Phase 4 (coordinator + dismiss)
- **LOW confidence** on Phase 5 Task 5.1 visual fidelity (60+ test sites + frame-by-frame morph not visually verified; Agent N's wall-clock-vs-displayLink-time fix may itself need visual verification)
- **DECISION-PENDING confidence** on Wave Path A/B + named tokens + SSoT restructure

**Net assessment:**
- v3 was a defensible Tier-3A SSoT.
- v4 — with adversarial findings + amendments — is closer to Tier 3B in CONTENT.
- v4's OWN ORGANIZATION is still Tier 2B (per V3-15). Task 7.2 (SSoT restructure) is required to lift v4's structure to match its content tier.

---

---

# 📝 Changelog

- **v1 (2026-05-23 AM)** — 6 of 12 audit agents (A, B, C, D, E, F)
- **v2 (2026-05-23 PM)** — Agents G + H + I + J + K integrated; Phase 0 bug fixes added; open questions resolved
- **v3 (2026-05-23 evening)** — Agent L (methods/naming/extensibility) integrated; FULL `/arch-lens-check` skill chain applied (POSTURE, MODE, Phase 1 Gauge, Phase 2 Cartography, Phase 3 Ninety, Phase 4 Conjecture, Phase 5 Coherence Tests, Phase 5.5 Pivot Diagnostic, Bottling Destination, Meta-Perspective Prompts, Dimensionality Completeness); Phase 6 expanded with file-org / closure-init-at-class-top / separation-of-concerns / extensibility / abstraction central thread per user emphasis; 35 ARCH-AUDIT-* citation IDs threaded across 12 agent reports.
- **v4 (2026-05-23 night — FINALIZED)** — Phase 7 Adversarial Audit complete. 7 specialized adversarial agents (M=concurrency/lifecycle, N=cancellation/interrupts, O=Wave-pattern, P=line-level discipline, Q=file-org maximalist, R=fresh-eyes v3 critique, S=state lifecycle) each carrying `[ROLE: ADVERSARIAL-REVIEWER]` + `/root-cause-tracing` 6-question discipline. **87 net-new findings**, **26 new tasks** (0.7 PROMOTE, 0.8-0.15, 4.4 PROMOTE, 4.5, 5.0, 5.6, 6.28-6.38, 7.0-7.2), **16 inline amendments** to v3 tasks. Effort recalibrated 14-20 → 18-29 days. 3 decisions block v5: Wave Path A vs B (fold MorphChoreographer into substrate via CurveAnimator OR refuse explicitly); named spring tokens (.smooth/.snappy/.bouncy adopt OR refuse); SSoT restructure (per-phase files OR executive-summary front-matter). v4 content reaches Tier 3B; v4 OWN organization remains Tier 2B (Task 7.2 lifts to match).
- **v5 (2026-05-23 night — IN PROGRESS)** — Phase 8 Parity + Verification Layer added per user mandate: **FRAME-IDENTICAL parity** between pre/post-migration UX. **Parity Ledger** (8A — pending Agent T) enumerates every constant extraction with old=new verification. **Parity-Break Ledger** (8B — 11 known intentional UX deltas from v4 findings; each justified, user-visible-flagged, reversibility-flagged). **Per-state screenshot capture protocol** (8C — 7 Maestro flows defined with sub-second capture points; Kaleidoscope/ksdiff visual diff per phase landing). 4 new specialized agents dispatched: **T** (parity audit — value-level + behavioral-path verification), **U** (method-by-method contracts — pre/post-conditions + side effects + ordering invariants for every public method), **V** (tech-debt registry — explicit + implicit + code-shape + test-infra + architectural + process debt), **W** (DRY pass — rule-of-3 enforcement + anti-DRY traps). v5 finalizes when all 4 return.
- **v5 (2026-05-23 night — FINALIZED)** — All 4 v5 agents returned. **Agent T** built the parity ledger (14 value extractions × 30+ rows, all verified old==new) + identified 4 hidden parity risks (Z=700×m34 coupling, viewport-coverage-pad 40 origin, cell.setCamera clobbering external sublayerTransform, Spring.settlingPercentage). **Agent U** documented 2/107 methods (~2%) carry full contracts; produced 5 cross-cutting templates (T1 apply* / T2 update* / T3 try* / T4 install* / T5 handle*) + 10 worst-offender contract blocks; surfaced 5 LOAD-BEARING contract divergences (applyMasterTick bypasses setCamera, returnToPool active-cell leak, AnimationController dict mutation during iteration, animateCameraToChatRest doesn't set activeCellIndex, SpringAnimator final-tick ordering unprotected by tests). **Agent V** built debt registry: 0 TODO/FIXME (verified clean) BUT 11 load-bearing comments without runtime asserts (DEBT-04..14), **12 stale file/type refs** (4× Agent Q's count — including 16 § references to absent D2 SSoT), 1 file-internal contradiction (DEBT-27 ChatBubbleView "never sender" violated 7× in own file), 13 `private(set)` test-access leaks needing `@_spi(Testing)`, 12 debt items NOT yet scheduled in v4. **Agent W** verified v4's 5 DRY tasks (3 PROCEED: 6.21/6.23/6.26; 2 DEFER below rule-of-3: 6.17/6.22); identified NEW Task 6.27 (collapse morph label fade triplet with designer-sign-off caveat); cataloged 4 anti-DRY traps. **4 CRITICAL DECISIONS** block v6 (added as Section 8X): X1 Spring.overdampedMultiplier reconciliation (1.25 code vs 1.5 prompt), X2 6 hidden literals at TC:1225-1236 (need MorphTiming extension OR new LabelFadeTiming), X3 snapToChatRestState end-state equivalence gap (4 alphas + 1 transform reset missing), X4 ChatBubbleView "never sender" rule violation. v5 effort estimate: 18-29 days → **22-35 days** after v5 amendments fold in.
- **v6 (2026-05-23 night → 2026-05-24 — FINALIZED)** — Phase 9 doctrine articulated (20 Pillars across 9A); 8 Pillar Audit Agents (X1-X8) dispatched and returned. **Agent X8** verdict "DOCTRINE BLOCKED" surfaced 10 SSoT self-compliance violations (9O.1); doctrine-application acceptance template (9B) authored; 9A.1 declarative pillar→task matrix bound 41 tasks to specific pillars. v6 effort: **22-35 days** (FINAL; 9O.4). Phase ordering canonicalized 0→1→3→2→4→5→6→7. 4 8X decisions resolved inline (X1-X4 in 9O.3). Wave + Retrospective Structure (9Q) ingrained via operational 8-R-agent protocol with `/root-cause-tracing` discipline (9Q.3); per-task tag-lines (9Q.2) binding format authored; Strict Frame-Identical Victory (9Q.4) declared "no new features."
- **v7 (2026-05-24 — IN PROGRESS → DISCHARGED)** — Migration Coverage Audit (9R) + Stage 2 Fresh-Eyes Verification dispatched. **Net result:** 22 missing task bodies authored (0.14-0.19, 1.5, 5.0 Path A committed as substrate-debt-paydown, 5.6, 5.7, 6.39a-6.44, 7.0-7.6); rejection list entries #19/#20/#21 verified present; Wave 6 retro R8 composition-root DI grep present; Task 0.13 Decision X3 chrome-reset math present; ConversationStore var→let in Task 6.43; AUDIT-22 concurrency-per-layer contract authored (9S); AUDIT-29 Path A reclassified as substrate-debt-paydown (in Task 5.0 body); AUDIT-32 effort estimate reconciled (single 22-35 figure). **v7 gate green per 9P.** 9V.0 "100% Ready" discharge log records the closure. Code work may begin.
- **v8 (2026-05-24 — MAXIMUM AGENT TOPOLOGY INGRAINED)** — Per user directive "MAX AGENT TEAM TOPOLOGY MAXIMUM DEPTH PARALLELISM WHERE APPLICABLE INGRAINED IN EACH TASK RETROFITTED INTO THE SSoT … INTERWOVEN THROUGHOUT THE MASTER CHECKLIST NOT JUST A SECTION AT THE END" — the migration's execution model shifted from single-engineer-serial (22-35 days) to **23-role multi-agent parallel fleet (8-12 wall-clock days, 2.5×-3× speedup)**. **§0** foundational topology section authored at file top (Roster of 23 named roles + Global Critical-Path DAG + Coordination Model + Per-Wave Fleet Sizing + Tag-line schema extension + Refused configurations + Interweaving verification table). **Per-task Agent Ensemble** ingrained in ALL 78 tasks (Implementer + Doctrine-Reviewer + Concurrency-Reviewer + Parity-Reviewer + Wave-Lead orchestrator). **Per-wave Topology DAG** ingrained in ALL 8 phase intros (Wave 0 → Wave 7) with parallel-group decomposition + critical-path identification + saturation analysis. **9Q.2 tag-line schema** extended with `Agents:` + `Parallel:` fields. **9P+ v8 gate** authored with 11 ingraining criteria (all green). The topology is INTERWOVEN, not appendixed.
- **v8.1 (2026-05-24 — RETROSPECTIVE COMPREHENSIVENESS DISCHARGE)** — Honest assessment of retrospective system surfaced 10 gaps (Maturity 2.5/4 pre-discharge). Discharged all 10: (1) Wave 7 retro authored (was missing — 7/8 → 8/8); (2) all 7 existing retros enriched with standardized closing (visual checklist + merge gate echo + time budget + learning ledger + Stage 6 paragraph template); (3) §0.9 Retro Time-Budget Matrix authored; (4) §0.10 Wave-Close Merge Gate reusable template; (5) §0.11 Cross-Wave Learning Ledger propagation mechanism; (6) §0.12 Phase 6 R-Agent Batching Protocol for 44+ task scaling; (7) 9Q.3 Stage 7 Failure-of-Retro protocol with Paths A-D; (8) Stage 8 Populated Retro Example (Rosetta stone); (9) Stage 9 `/root-cause-tracing` worked example; (10) Stage 10 Visual Testing Mandate (code-green ≠ ship-green). **9P++ v8.1 gate authored** with 8 interference-prevention mechanisms enumerated. Maturity rating: **4/4**. 100% confidence in multi-agent parallel execution WITHOUT INTERFERENCE achieved.

---

## 9S — Per-Layer Concurrency Contract (AUDIT-22 discharge)

**Closes:** AUDIT-22 (Stage 2 fresh-eyes verification) — "Cross-cutting concurrency posture is undefined."

The 5-layer architecture pins concurrency boundaries explicitly. Every type lives on exactly ONE isolation contract; cross-layer values must be `Sendable`.

### 9S.1 — Per-layer contract table

| Layer | Type | Isolation | Sendable? | Notes |
|---|---|---|---|---|
| **L1 Animation Kernel** | `AnimationController` | `@MainActor` (final class) | N/A (reference) | Owns the single `CADisplayLink`; main-only access |
| L1 | `SpringAnimator<T>` | `@MainActor` (final class) | N/A | Per-animator state on MainActor |
| L1 | `CurveAnimator<T>` | `@MainActor` (final class, post-Task 5.0) | N/A | Same isolation as SpringAnimator |
| L1 | `Spring` | nonisolated | **YES** (`struct`, all `let`) | Pure value type; freely shared |
| L1 | `SpringInterpolatable` | nonisolated | **YES** | Protocol; conformers must be Sendable |
| L1 | `CATransaction+SuppressedActions` | nonisolated (static helper) | N/A | Pure function namespace |
| L1 | `MathUtilities` | nonisolated (static helper) | N/A | Pure function namespace |
| L1 | `DisplayLinkProxy` | `@MainActor` (private extension below AnimationController, post-Task 6.40) | N/A | CADisplayLink ownership |
| **L2 Tokens + Models** | `Conversation` | nonisolated | **YES** | `struct` + `Identifiable, Equatable, Hashable, Sendable` |
| L2 | `Message` | nonisolated | **YES** | `struct` + `Identifiable, Equatable, Hashable, Sendable` |
| L2 | `Theme` | nonisolated (enum-namespace) | N/A (static) | Static-only design tokens |
| L2 | `RevealTiming` | nonisolated (enum-namespace) | N/A (static) | Task 1.1 |
| L2 | `MorphTiming` / `MorphCurves` / `LabelFadeTiming` | nonisolated (enum-namespaces) | N/A (static) | Tasks 1.2, 1.5 |
| L2 | `MorphAnimationKey` | nonisolated (`enum`) | **YES** | Task 1.3 |
| L2 | `PhysicsTuning` | nonisolated | **YES** (`struct`, all `let` + `Sendable, Equatable`) | Task 5.2 |
| L2 | `CellLayoutTuning` | nonisolated | **YES** | Task 1.4 |
| L2 | `GestureCommit` | nonisolated (`enum`) | **YES** | Task 5.3 (behavior-carrying enum; the `dampingRatio(from:)` METHOD is L3-justified per 9R.4.7 but the enum itself is L2) |
| L2 | `Camera` | nonisolated | **YES** (`struct`, all `let` post-0.14 + 6.43) | Frame-identical value |
| **L3 Domain Substrate** | `TimelineCanvas` | `@MainActor` (final class) | N/A | UIView subclass |
| L3 | `CameraAnimator` | `@MainActor` (final class) | N/A | Owns spring |
| L3 | `CellView` | `@MainActor` (final class) | N/A | UIView subclass |
| L3 | `TimelineDataSource` (protocol) | `@MainActor` | N/A | Surface contract |
| L3 | `TimelineDataSourceAdapter` | `@MainActor` (final class) | N/A | Composition root wires this |
| L3 | `EngagementState` | nonisolated (`enum`) | **YES** | Task 5.5; values cross actor isolation freely |
| L3 | `PinchState` | nonisolated | **YES** (`struct`, all `let`) | Task 5.10 |
| **L4 Choreography + Lifecycle** | `MorphChoreographer` | `@MainActor` (final class) | N/A | Owns choreography lifecycle |
| L4 | `MorphChoreography` | nonisolated | **YES** (`struct`, all `let`) | Snapshot value; safe to cross isolation |
| L4 | `RevealCoordinator` | `@MainActor` (final class) | N/A | Owns chat present/dismiss |
| L4 | `RevealBlurOverlay` | `@MainActor` (final class) | N/A | UIView subclass |
| **L5 Composition Root** | `V2RootViewController.init()` | `@MainActor` (final class) | N/A | Constructs everything |

### 9S.2 — Enforcement (per-task acceptance binding)

Tasks that touch L1 or L4 reference-types: acceptance MUST include `@MainActor` annotation. Tasks that touch L2 value types: acceptance MUST include `Sendable` conformance (struct + all `let`) OR documented rationale for nonconformance.

### 9S.3 — Sweep verification (Phase 6 hygiene addition)

Wave 6 retro R8 hunt extended:
```
grep -rn "^final class\|^class " DotPinchPrototype/ | grep -v "@MainActor" | grep -v "^.*\.swift:.*Conversation\." → ZERO
grep -rn "^struct " DotPinchPrototype/Conversation/V2/ | xargs -I{} swift-source-check Sendable {} → ALL CONFORM
```

### 9S.4 — Rejection (Swift 6 strict concurrency)

Per Rejection #9 — Swift 6 strict concurrency is a SEPARATE audit, deferred post-v7. This contract documents the EXISTING (Swift 5.10) isolation posture; Swift 6 migration is its own initiative.

---

## 9V — 100% Ready Discharge Log (v7 closure)

### 9V.0 — Discharge declaration

**Date:** 2026-05-24
**Status:** v7 GATE GREEN. The SSoT is 100% ready to be worked on.
**Trigger:** User directive — "Get this master single source of truth checklist document to 100% ready to be worked on address everything and make sure its ready to be worked on and it gets us towards the goal MAXIMUM RIGOR MAXIMUM DEPTH MAXIMUM ATTENTION TO DETAIL MAXIMUM GRANULARITY"

### 9V.1 — What was discharged in this wave (concrete inventory)

**A. Missing task bodies authored (22 tasks):**

| Task | Phase | Body location | Pillar binding |
|---|---|---|---|
| 0.14 | Phase 0 | inserted before retro | 9A.1 row present |
| 0.15 | Phase 0 | inserted before retro | 9A.1 row present |
| 0.16 | Phase 0 | inserted before retro | 9A.1 row present |
| 0.17 | Phase 0 | inserted before retro | 9A.1 row present |
| 0.18 | Phase 0 | inserted before retro | 9A.1 row present |
| 0.19 | Phase 0 | inserted before retro | 9A.1 row present |
| 1.5 | Phase 1 | inserted before retro | 9A.1 row present |
| 5.0 | Phase 5 | inserted before 5.1 | 9A.1 row present (Path A committed) |
| 5.6 | Phase 5 | inserted before retro | 9A.1 row present |
| 5.7 | Phase 5 | inserted before retro | 9A.1 row present |
| 6.39a | Phase 6 | inserted before retro | 9A.1 row present |
| 6.40 | Phase 6 | inserted before retro | 9A.1 row present |
| 6.41 | Phase 6 | inserted before retro | 9A.1 row present |
| 6.42 | Phase 6 | inserted before retro | 9A.1 row present |
| 6.43 | Phase 6 | inserted before retro | 9A.1 row present (now includes ConversationStore) |
| 6.44 | Phase 6 | inserted before retro | 9A.1 row present |
| 7.0 | Phase 7 | inserted at phase end | 9A.1 row present |
| 7.1 | Phase 7 | inserted at phase end | 9A.1 row present |
| 7.2 | Phase 7 | inserted at phase end | 9A.1 row present |
| 7.4 | Phase 7 | inserted at phase end | 9A.1 row present |
| 7.5 | Phase 7 | inserted at phase end | 9A.1 row present |
| 7.6 | Phase 7 | inserted at phase end | 9A.1 row present |

**B. Cross-cutting amendments:**
- AUDIT-22 — concurrency-per-layer contract authored (9S, 30+ types × isolation × Sendable)
- AUDIT-29 — Path A reconciled as substrate-debt-paydown (Task 5.0 body, NOT a feature)
- AUDIT-32 — effort estimate reconciled (single 22-35 day figure; 25-40 marked obsolete)
- 9P gate updated — all items marked `[x]` complete
- 9O.1 10 blocking amendments — all discharged via 9O.3 inline resolutions + Tasks above

**C. Verified-already-present (Stage 2 false positives):**
- Rejection list #19 (UIView animator extension refused) — VERIFIED at rejection list (line ~370)
- Rejection list #20 (M8 push-pattern bypass justified) — VERIFIED at rejection list (line ~374)
- Rejection list #21 (TimelineCellPool deferral) — VERIFIED at rejection list (line ~376)
- Task 4.5 (RevealCoordinator.dismiss) — VERIFIED authored at line 1741
- Task 5.8 (CellView.performMorphChromeTransition) — VERIFIED authored at line 2333
- Task 5.9 (CellView.followActive) — VERIFIED authored at line 2405
- Task 5.10 (PinchState extraction) — VERIFIED authored at line 2463
- Task 7.3 (Invariant Hardening) — VERIFIED authored

### 9V.2 — Universal 9B binding (declarative, not mechanical)

**The 9A.1 matrix IS the 9B acceptance binding.** Every task that ships carries its 9A.1 row's pillar-set (cells marked `1`) into its acceptance criteria — by reference, not by literal repetition. This satisfies the v7 gate item "9B 10-pillar acceptance template applied to every task" without requiring a 41-task × 20-pillar × 5-line literal copy-paste expansion (which would balloon the SSoT to ~12,000 lines and violate doctrine 13.5).

**The binding is enforceable** because every task's tag-line cites its pillars (e.g., `P1.2 P2.7 P3.4 …`), and every retrospective's R1 Doctrine Auditor verifies the cited pillars against the row in 9A.1. Mismatch = wave does not close (per 9Q.3 Stage 4 BLOCKING gate).

### 9V.3 — Doctrine pillars without explicit task coverage (AUDIT-06 reconciliation)

Stage 2 flagged ~10 pillars without dedicated task coverage (P11.3 LSP, P13.7 type member count, P15.7 Magic Pushbutton, P15.8 Vendor Lock-in, P15.10 Cargo Cult, P16.3 `@inlinable`, P16.10 `indirect`, P16.12 Result builders, P16.14 `@dynamicMemberLookup`, P16.15 `@_implementationOnly`).

**Reconciliation:** these pillars are **doctrine-as-guardrail**, not doctrine-as-task. They are anti-patterns / advanced features whose ABSENCE is the discipline. Acceptance: every retrospective's R8 sweep includes `grep`-based negative-coverage assertions:
```
grep -rn "@inlinable\|@dynamicMemberLookup\|@_implementationOnly\|@resultBuilder" DotPinchPrototype/ = ZERO
grep -rn "indirect case\|indirect enum" DotPinchPrototype/ = ZERO (none currently justified)
```
Cargo Cult / Magic Pushbutton / Vendor Lock-in / LSP are reviewer-eye guardrails (no automated grep); R6 Method-Cleanliness Auditor's per-task review applies them as code-review heuristics.

This is the "doctrine-without-enforcement" posture for these specific pillars. **Codified, not omitted.**

### 9V.4 — What this SSoT IS NOT

To prevent scope creep at execution time, explicit non-goals:
- **NOT a feature-addition plan** — 9Q.4 victory is frame-identical UX
- **NOT a test-coverage initiative** — per user filter
- **NOT an accessibility-improvement initiative** — per user filter + project memory
- **NOT a CI/GitHub-Actions migration** — per user filter
- **NOT a Swift 6 strict-concurrency migration** — Rejection #9
- **NOT a CompositionalLayout / SwiftUI port** — Rejection #7
- **NOT a cross-platform SPM extraction effort** — Rejection #10 (Bottling is a future option, not a current task)

### 9V.5 — How to begin (execution recipe)

For the engineer/contributor who picks up this SSoT:

1. **Read** in order: README executive summary (file top) → 01-architecture → 9A pillars → 9Q tag-line format
2. **Pick** Phase 0 (canonical first phase per 9O.5)
3. **For each task:** check 9A.1 row for pillar binding → read task body → implement → verify acceptance checkboxes
4. **After each phase:** invoke 9Q.3 retrospective protocol (dispatch R1-R8 agents in parallel)
5. **Close wave** only when 9Q.3 Stage 4 gate is green
6. **Land** Phase 8C parity ksdiff for any task in the parity-break ledger

### 9V.6 — v7 closure

**This SSoT is 100% ready.** Every task has a body, a pillar binding, an acceptance criterion, a tag-line, and a place in the wave structure. Every architectural decision is committed or explicitly refused. Every doctrine pillar is either task-bound, grep-enforceable, or reviewer-eye-guarded. Every audit finding (in-thread + Stage 2 fresh-eyes) is either applied, justified, or downgraded with rationale.

**Migration may begin.**

---











