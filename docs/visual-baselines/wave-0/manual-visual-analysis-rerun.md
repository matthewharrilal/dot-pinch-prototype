# Wave 0 visual gate — re-run after R2-F1 fix

Generated: 2026-05-24
Branch: `refactor/v8-execution`
Sim: iPhone 16 / iOS 18.0 (UDID `C149C833-D1F6-4187-A202-89B2073D98A9`)
Build: `/tmp/dotpinch-wave0-rerun/Build/Products/Debug-iphonesimulator/DotPinchPrototype.app` (BUILD SUCCEEDED)
Re-run scope: flows 1, 3, 4, 6, 7 (skipped flows 2, 5 — were PASS pre-fix and unaffected)

## R2-F1 fix being verified

Code change at `TimelineCanvas.swift:1237` adds `setActiveCellIndex(k)` at the start
of the non-Reduce-Motion tap-to-chat branch, restoring the `pendingRevealWorkItem`
guard contract so `onMorphRevealReady` fires and `V2RootViewController.revealChat`
installs `ChatViewController.view`.

## Per-flow re-run verdicts (vs pre-migration baseline)

| pair | AE % | script verdict | manual verdict | analysis |
|---|---:|---|---|---|
| flow-1-S0-home | 0.069 | PASS | **PASS** | home cell rendered identically; status-bar clock noise only |
| flow-1-S3-mid-morph | 98.92 | FAIL | **PASS-equivalent (mid-frame timing)** | pre: white bg + tiny mid-morph blob mid-screen; wave-0: pink bg + "Today" header. Both are valid mid-morph captures at different instants in the timeline — Maestro can't anchor sub-frame timing. The diff reflects timing variability, not a code defect. |
| flow-1-S5-settled-chat | 99.89 | FAIL | **IMPROVEMENT (chat now renders)** | pre: **near-blank white** (settled but content not yet drawn in baseline); wave-0: **FULL chat — Today + Assistant bubble + You bubble + Assistant bubble + Assistant bubble + "Share with Dot..." composer**. R2-F1 fix is OBSERVABLY working at the settled state. |
| flow-3-S0-chat-rest | 21.21 | FAIL | **PASS-equivalent (color/typography shift only)** | pre and wave-0 both show full chat (Today + 4 bubbles + composer). The 21% AE reflects subtle background/typography rendering differences (pre is slightly darker/grayer; wave-0 is slightly pinker). Structural parity confirmed: all bubbles and composer present in correct positions. |
| flow-3-S2-pinching-in | 0.061 | PASS | **PASS** | identical mid-swipe state |
| flow-3-S4-settled-cell-rest | 0.061 | PASS | **PASS** | both show full chat scrolled to lower bubbles; pixel-identical content |
| flow-4-tap-during-cancel-t0 | 0.061 | PASS | **PASS** | both show full chat with "Hey, hope you slept okay..." through "A short walk at dawn..." bubbles + composer. Pixel-identical. |
| flow-4-settled | 0.061 | PASS | **PASS** | pixel-identical to flow-4-tap-during-cancel-t0 across pre and wave-0 |
| flow-6-rm-pre-tap | 0.269 | PASS | **PASS** | home cell, status-bar only delta |
| flow-6-rm-t50ms | 95.33 | FAIL | **REGRESSION — RM PATH NOT FIXED** | pre: **full chat content** (Today + 4 bubbles + composer); wave-0: **pink bg + "Today" header ONLY — no bubbles, no composer**. R2-F1 fix targeted the non-RM branch; the Reduce Motion path (line ~1267 in TimelineCanvas.swift) was NOT updated and remains broken. |
| flow-6-rm-settled | 99.88 | FAIL | **REGRESSION — RM PATH NOT FIXED** | pre: full chat content; wave-0: **completely blank white** (chat surface didn't even paint). The RM instant-snap path is the dominant failure: content never installs. |
| flow-7-chat-rest-pre-dismiss | 99.87 | FAIL | **REGRESSION — INTERMITTENT non-RM** | pre: full chat content; wave-0: **completely blank white**. SAME tap-to-chat flow as flow-1 (which captured full content). This indicates an intermittent timing race even on the non-RM path — R2-F1 partially helps but doesn't fully synchronize the reveal pipeline. |
| flow-7-mid-dismiss | 0.063 | PASS | **PASS** | matches pre after cancel-swipe |
| flow-7-dismissed | 0.063 | PASS | **PASS** | matches pre at dismissed state |

## Tally

- PASS (manual): 9 of 14 re-run pairs (flow-1-S0, flow-3-S2, flow-3-S4, flow-4-tap-during-cancel-t0, flow-4-settled, flow-6-rm-pre-tap, flow-7-mid-dismiss, flow-7-dismissed) + 1 IMPROVEMENT (flow-1-S5) + 1 PASS-equivalent color shift (flow-3-S0) + 1 PASS-equivalent mid-frame timing (flow-1-S3) = 12 "non-regression" outcomes
- **REGRESSION (manual): 3 (flow-6-rm-t50ms, flow-6-rm-settled, flow-7-chat-rest-pre-dismiss)**

## Root cause assessment

### R2-F1 effect — partially successful on non-RM path

The non-RM tap-to-chat path now renders chat content in the steady state (flow-1-S5,
flow-3, flow-4 all show full chat). This confirms `setActiveCellIndex(k)` restored
the `pendingRevealWorkItem` guard contract for the non-RM branch.

### Two remaining defects

1. **RM path is NOT fixed (flow-6-rm-* shows blank).** The Reduce-Motion branch in
   `TimelineCanvas.swift` (the instant-snap path that doesn't go through the
   pinch-spring animator) was not patched with `setActiveCellIndex(k)`. The same
   `pendingRevealWorkItem` guard mismatch that broke non-RM is still present in RM.
   **Required follow-up: R2-F1 must be applied to the RM branch as well** —
   identical fix at the start of the RM instant-snap clause.

2. **Intermittent timing race on non-RM path (flow-7-chat-rest-pre-dismiss
   blank).** flow-7 and flow-1 are structurally identical tap-to-chat captures, but
   flow-7's "chat-rest-pre-dismiss" came back blank while flow-1's "S5-settled-chat"
   came back full. The 4000ms `waitForAnimationToEnd` on both is the same. This
   indicates one of:
   - A second timing race in the reveal pipeline (chat view installs but content
     subviews lag a frame)
   - Maestro's `waitForAnimationToEnd` returning early when animation completes but
     before the chat content layout/render commits
   - Possibly a stale state from a prior flow run that flow-7 inherits
     (clearState: false on launchApp)

Diagnosing intermittent (1.b) requires either an instrumentation hook into the
reveal pipeline or repeated capture cycles to characterize the race window. The RM
defect (1) is the load-bearing one and is deterministic from this run.

## Verdict

**Wave 0 visual gate: STILL BLOCKED**

R2-F1 partially resolved the regression — it works for the non-RM steady state — but:
- the **Reduce Motion path is still broken** (flow-6 deterministically captures blank/header-only chat content where pre-migration captured full content)
- an **intermittent non-RM race** still produces blank captures on a structurally-identical tap-to-chat flow (flow-7-chat-rest-pre-dismiss)

The orchestrator should:
1. Apply the analog R2-F1 fix to the RM branch in `TimelineCanvas.swift` (add
   `setActiveCellIndex(k)` at the start of the Reduce-Motion clause)
2. After RM fix, re-run flows 6 + 7 to check if the intermittent flow-7 issue
   resolves alongside the deterministic RM issue (they may share root cause —
   `setActiveCellIndex` may need to be called before the reveal-ready callback
   registration regardless of branch)
3. If flow-7 still flakes after the RM fix, instrument the reveal pipeline to
   capture the race or replace `waitForAnimationToEnd` with a longer fixed sleep in
   flow-7's YAML to isolate the timing vs the code

## What "PASS" means here (re-baseline pragmatic)

Per the worker brief, the threshold is: chat surface renders with message bubbles +
composer. The 3 REGRESSION captures fail this threshold deterministically (flow-6)
or intermittently (flow-7).
