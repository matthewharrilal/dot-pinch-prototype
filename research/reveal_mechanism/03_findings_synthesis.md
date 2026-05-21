# Findings Synthesis — Reveal Mechanism Research

This document is the **research deliverable** the user asked for: candidate compositions named, primitives organized by gradient level, 90% manifestations identified, reference apps mapped to patterns. It is **NOT** a conjecture (which composition to pick is deliberately deferred per user direction).

This is a navigation + decision-aid document. The substantive content lives in the 11 per-agent files. Read this to choose where to dig deeper.

---

## How the research is organized

- **Gauge:** [`00_gauge.md`](00_gauge.md) — posture, tier diagnosis, gap
- **Cartography** (6 files, ~1607 lines): [`01_cartography/_index.md`](01_cartography/_index.md)
- **Ninety** (5 files, ~724 lines): [`02_ninety/_index.md`](02_ninety/_index.md)
- **This synthesis** (~180 lines)

Total research footprint: ~2500 lines across 13 bounded files. No file exceeds 320 lines.

---

## The five findings that change the problem

### 1. The single-primitive composition rule (n1 — Dot reverse-engineering)
> "There must be ONE moving primitive whose motion accounts for every visible change."

This rule explains BOTH failed attempts. Blur-mediated alpha crossfade = two animators (blur alpha + chat alpha). Twin-mask radial = two masks + a blur. Both read as "conflicted" because the user's brain registers multiple independent timelines and can't fuse them into a single motion event.

Dot's reveal works because a single variable-blur band moving vertically up the screen is sufficient cause for every visible change (list dissolves, chat appears, gradient rises, text resolves). One cause, one motion, one feel.

### 2. Dot's reveal is bottom-up, not radial (n1)
The reveal is a vertically-traveling feathered band, not a center-out circle. Chat's pink-mauve background gradient IS the curtain — it rises from below. Boundary is a soft 80-100pt blur falloff zone, never a hard line. This invalidates the entire mental model the user has been working under for the last two attempts.

### 3. Parametric blur radius lives outside front-of-10% UIKit (c1, c2, c5, c6, n2, n4)
`UIBlurEffect` styles only swap between presets — there is no public way to animate the blur radius continuously. Every Apple-grade reveal that has a "focus pull" feel uses one of:
- `_UIVisualEffectBackdropView.inputRadius` via `valueForKey("backdropView")` (lowest risk, used by Apple Music)
- `CAFilter(type: "gaussianBlur").inputRadius` on a `CABackdropLayer` (most flexible, used by Telegram)
- SwiftUI `.blur(radius:)` via `UIHostingController` (bridging cost)
- CoreImage / Metal pipelines (most heavyweight)

### 4. Material pipeline is 5 stages, not 1 (n5)
Apple's blur is not "just blur." It's sample → Gaussian blur → saturation lift (1.8x, AFTER blur, compensating for blur-induced desaturation) → tint → vibrancy composite. Skipping saturation produces "gray dead blur." Animating all stages linearly together reads as "filter loading"; staggering them (saturation leads by 150ms, tint trails by 100ms) reads as "material crystallizing."

### 5. Linear blur radius animation feels like a cliff (n4)
Perceived blur scales with √radius. Linearly animating `inputRadius` 0→30 produces a curve that the eye reads as stepped, even with `easeInOut` timing. The Apple-grade approach either animates blur sigma (radius²) or applies a `pow(progress, 0.5)` style curve to the radius timeline so perceived blur changes linearly.

---

## Candidate compositions (NOT a recommendation — for user evaluation)

Each candidate listed with: source agent(s), substrate primitives by CARTO-ID, App Store risk, geometric match to Dot's reference, implementation effort. The user picks one (or a hybrid) for the conjecture phase.

### Composition A — Apple Music pattern (first-party precedent)
**Source:** [n2 Apple Music reverse-engineering](02_ninety/n2_apple_music_reverse_engineering.md)
**Substrate:**
- Custom `UIViewControllerAnimatedTransitioning` + `UIViewPropertyAnimator` (cartography c1)
- `_UIPortalView` for live cell→chat content mirror (CARTO-uiinternals-02)
- `valueForKey("backdropView")` → `_UIVisualEffectBackdropView.inputRadius` animated parametrically (CARTO-uiinternals-01)
- `vibrantColorMatrix` on destination atmosphere (CARTO-cafilter-14)
- Chrome cascade with 20-40ms stagger

**Geometry fit to Dot's reference:** moderate — Apple Music expansion is center-out radial-ish, Dot is bottom-up band. Substrate matches; choreography differs.
**App Store risk:** low — `valueForKey` from public entry point is the recommended mitigation
**Implementation effort:** high (custom transition controller from scratch)

### Composition B — Dot pattern (matches the literal reference)
**Source:** [n1 Dot reverse-engineering](02_ninety/n1_dot_reverse_engineering.md)
**Substrate:**
- `_UIPortalView` mirroring live chat VC (CARTO-uiinternals-02)
- `CAFilter(type: "variableBlur")` on portal's `backgroundFilters` with vertical-gradient `inputMaskImage` (CARTO-cafilter-02)
- Second `gaussianBlur` on chat-content sublayer for two-stage text resolution decay (CARTO-cafilter-01)
- ONE moving primitive: the variable-blur band on Y axis. All visible change is consequence.

**Geometry fit to Dot's reference:** high — this IS the reference
**App Store risk:** medium — `variableBlur` reachability uncertain pre-iOS 17 (🔶 flagged in c5)
**Implementation effort:** moderate (requires portal-view KVC plumbing + variableBlur experimentation)

### Composition C — Material crystallization (pipeline-aware)
**Source:** [n5 material pipeline rules](02_ninety/n5_material_pipeline_rules.md)
**Substrate:**
- Re-implement chat surface as `CABackdropLayer` via `+layerClass` override (CARTO-uiinternals-06)
- Drive three keypaths in phase:
  - `backgroundFilters.gaussianBlur.inputRadius` 0→30 (CARTO-cafilter-01)
  - `backgroundFilters.colorSaturate.inputAmount` 1.0→1.8 (CARTO-cafilter-08, lead 100ms)
  - `backgroundFilters.colorTint.color.alpha` 0→0.12 (CARTO-cafilter-15, trail 100ms)
- The reveal IS the material forming — no crossfade

**Geometry fit to Dot's reference:** low — this is fundamentally a different visual model (material forming, not band travelling)
**App Store risk:** medium — direct `CABackdropLayer` instantiation; Telegram-iOS open-source confirms shipping precedent
**Implementation effort:** moderate (most of the work is in keypath setup + phase tuning)

### Composition D — Things temporal-parallax (cheapest Tier-3 upgrade)
**Source:** [n3 triangulation](02_ninety/n3_triangulation_reverse_engineering.md)
**Substrate:**
- Pure UIKit / Core Animation — no private APIs, no Metal, no portal views
- Two `UIViewPropertyAnimator` instances with deliberately desynchronized springs (response 0.35, damping 0.85)
- Layer-stack with depth carried by motion phase, not transform

**Geometry fit to Dot's reference:** low — Things' depth is parallax via desync, Dot is band-rising
**App Store risk:** none — public API only
**Implementation effort:** low (two animators + tuning)

### Composition E (rejected for first pass) — Metal compositing
**Source:** [c4 Metal cartography](01_cartography/c4_middle_metal.md)
**Why rejected for first pass:** N1 + N2 + N4 + N5 converge on `_UIVisualEffectBackdropView` + `CAFilter` as sufficient substrate for Dot-grade. Metal becomes warranted only if the latter-end UI internals approach hits a specific wall (e.g., shader-driven boundary effects that no CAFilter combination achieves). Keep in reserve.

---

## Reference app → pattern mapping

| App | Pattern | Likely substrate | Confidence | Source |
|---|---|---|---|---|
| **Dot** | Bottom-up variable-blur band, single primitive | `_UIPortalView` + `variableBlur` CAFilter on `backgroundFilters` | high (frame-analysis grounded) | n1 |
| **Apple Music** | Cross-tree portal morph + parametric backdrop blur | `_UIPortalView` + `_UIVisualEffectBackdropView.inputRadius` | high (system-app precedent) | n2 |
| **Halide** | Hot-Metal substrate, chrome staging | `CAMetalLayer` always-on + `_UIRoundedRectShadowView` chrome | medium | n3 |
| **Things 3** | Pure Core Animation + temporal parallax | Two `UIViewPropertyAnimator` with desync | high (observable, no private APIs) | n3 |
| **Telegram** | Direct CABackdropLayer instantiation, gesture-bound parametric blur | `CABackdropLayer` + `CAFilter(gaussianBlur)` + CADisplayLink | high (open-source confirmed) | n3, c6 |

---

## What we still don't know (blind spots, weighted by importance)

1. **Whether `CAFilter(type: "variableBlur")` is reachable on iOS 17 / iOS 18** (🔶 in c5, central to Composition B). Empirical test needed: instantiate `CAFilter(type: "variableBlur")`, set `inputRadius` + `inputMaskImage`, observe behavior. ~2 hours.
2. **Exact `bleedAmount` / `bleedColor` / `bleedBlurRadius` semantics on `_UIVisualEffectBackdropView`** (🔶 in c6, n5). May be the closest-to-Dot polish gap. Empirical test + class-dump cross-reference.
3. **Dot's exact mask falloff shape and timing** (n1 blind spot). Would require ffmpeg frame extraction at native resolution (was blocked in this session — bash permission denied for ffmpeg).
4. **Whether Dot uses `_UIPortalView` vs `CAContext`/`CALayerHost` for the chat-content live render** (n1 blind spot). Runtime introspection on the live Dot app would close this.
5. **Per-style private enum integer → parameter mapping completeness** (n5 — `.systemMaterial` ≈ 2030 confirmed; upper-tier styles 🔶 flagged).
6. **Whether `_UIPortalView` source-view continues to animate during the portal-presented transition** (n1 affects all portal-based compositions).

The first two are the highest-leverage to resolve before picking a composition.

---

## Suggested next step (when the user is ready)

The user explicitly said "Stop after `/cartography` + `/ninety`. Research deliverable only. You review before any further direction."

When ready to proceed:
- For composition selection + buildable spec: `/conjecture` on the four candidates above, scoring each on geometry fit, risk, effort, and resolvability of the named blind spots
- For empirical closure of blind spots #1 and #2 before committing: a small **probe script** (Swift Playground or throwaway Xcode target) that instantiates the candidate primitives and inspects behavior. ~3-4 hours of focused experimentation
- For implementation directly off Composition B (the highest-fit-to-Dot path): subagent-driven-development wave on the implementation plan

No automatic next step is taken. Research is the deliverable.
