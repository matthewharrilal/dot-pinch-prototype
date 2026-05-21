# Ninety Index — Reveal Mechanism

Five per-target 90% dips. Each stands alone; this index is navigation only.

## Files
- [`n1_dot_reverse_engineering.md`](n1_dot_reverse_engineering.md) — Reverse-engineering Dot's reveal (the literal target, 129 lines) — **most load-bearing of the wave**
- [`n2_apple_music_reverse_engineering.md`](n2_apple_music_reverse_engineering.md) — Apple Music's now-playing expansion (93 lines, first-party precedent)
- [`n3_triangulation_reverse_engineering.md`](n3_triangulation_reverse_engineering.md) — Halide + Things + Telegram (142 lines, divergence-by-design)
- [`n4_cafilter_composition_rules.md`](n4_cafilter_composition_rules.md) — CAFilter / backdrop composition rules (154 lines, Intentions 4+6)
- [`n5_material_pipeline_rules.md`](n5_material_pipeline_rules.md) — Apple's material pipeline as a whole (206 lines, Intentions 4+5)

## Cross-cutting 90% findings (cited from per-file analyses)

### The single-primitive composition rule (n1)
There must be ONE moving primitive whose motion accounts for every visible change. Both failed attempts (blur+alpha crossfade; twin-mask radial) violated this — they composed multiple animators driving separate visible properties. This is the load-bearing rule that explains the "conflicted not smooth" verdict.

### Dot's reveal is NOT radial (n1)
It's a bottom-up vertically-traveling feathered band. Chat's pink-mauve background IS the curtain. List-blur and chat-rise are the same mechanical event (`backgroundFilters` sampling). Two-stage detail resolution: structure first, text last.

### Parametric blur radius is non-negotiable (n1, n2, n3, n4, n5)
`UIBlurEffect` preset swaps are stepped, not continuous. The Apple-grade path is `_UIVisualEffectBackdropView.inputRadius` reached via `valueForKey("backdropView")` (n2 + cartography c6), OR `CAFilter(type: "gaussianBlur").inputRadius` on a `CABackdropLayer` (n4, n5 + cartography c5).

### Linear blur radius animation feels like a cliff (n4)
Perceived blur scales with √radius. Linear interpolation of `inputRadius` reads as stepped. Animate with a curve that compensates (or animate sigma, not radius).

### Saturation after blur, over-compensating (n5)
Apple's material pipeline applies saturation AFTER blur and over-saturates (1.8x for `.systemMaterial`) to compensate for blur-induced desaturation. The user's compositions skipped this entirely — gray dead blur is the result.

### `groupName` prevents stacked-backdrop seams (n4)
Stacked backdrop layers without shared `groupName` produce 1-2px seams. This + `bleedAmount`/`bleedColor`/`bleedBlurRadius` likely account for most of the Dot-grade gap.

### Live cross-tree composition requires `_UIPortalView` (n1, n2)
Snapshot-based morphs "pop" at start/end. `_UIPortalView` mirrors live content. Used by Apple Music for artwork; recommended by n1 for the chat layer in Dot's reveal.

### Two animators with deliberate desync = cheapest Tier-3 upgrade (n3, Things pattern)
Temporal parallax via desynchronized animators (NOT 3D transforms) is what gives Things its trademark depth. Cheaper than Metal, cheaper than `_UIPortalView`.
