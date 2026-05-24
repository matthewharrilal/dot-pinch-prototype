# TimelineCanvas Megafile — Deferred-Extraction Memo

**Authored:** 2026-05-24 (Wave 7 cutover)
**Owner:** <project owner — to be assigned>
**Re-evaluation deadline:** 2026-12-01

## Status

`TimelineCanvas.swift` contains two cohesive but un-extracted concerns:

1. **`TimelineCellPool` semantics** — LIFO dequeue + UUID-keyed secondary index for state preservation across pool round-trips (Keystone K2).
2. **`TimelineLayoutCalculator` semantics** — `accumulatedYCache` + height-stable invariant (Keystone K6).

Both are real types in spirit, but each currently has **one consumer (TimelineCanvas itself)**. Extracting them today would be a speculative abstraction.

## Why not extract now

Per `ARCH-NINETY-ABS-01` (3rd-repetition rule, codified in `REFACTOR-CHECKLIST.md` rejection #21):

> "Each has 1 consumer (TimelineCanvas) today; extraction is speculative until a second consumer appears."

Phase 5 (Keystone surfacing) already brought TimelineCanvas under 1200 LOC via `MorphChoreographer` extraction. The remaining decomposition to <800 LOC awaits seam-proof evidence — i.e. a real second consumer.

## Re-evaluation trigger

Extract `TimelineCellPool` and/or `TimelineLayoutCalculator` as standalone types **when EITHER condition holds:**

- A **SECOND consumer of pool semantics** appears (e.g. a draft-message buffer view, an inbox preview list, a search-result strip — any UI that needs LIFO cell recycling with state preservation).
- A **SECOND consumer of layout-calculator semantics** appears (e.g. a peek view, a thumbnail strip, an off-screen layout solver — anything that needs `accumulatedYCache`-style height stacking).

## Deadline

**2026-12-01.** If the deadline passes WITHOUT a second consumer:

- **EITHER (a)** delete this memo and absorb the deferral permanently into TimelineCanvas (officially: "one-consumer concerns stay inline forever").
- **OR (b)** extract anyway as a Bottling-readiness hygiene move (justify in the PR description with a forward-looking second-consumer pointer, even if speculative).

The point of the deadline is to **force a decision**. "Deferred" must not silently become "permanent" through inattention.

## Cross-references

- `REFACTOR-CHECKLIST.md` rejection #21 (TimelineCellPool/TimelineLayoutCalculator deferral)
- Migration M1 (megafile decomposition) — achieved its target via Task 5.1 (MorphChoreographer extraction)
- Keystones K2 (cell pool LIFO + UUID-keyed) and K6 (`accumulatedYCache` lazy invalidation)
