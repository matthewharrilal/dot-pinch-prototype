# Cartography Index — Reveal Mechanism

Six per-gradient × per-framework cartography files. Each stands alone; this index is navigation only, not synthesis.

## Files
- [`c1_front_uikit_calayer.md`](c1_front_uikit_calayer.md) — Front of 10%, UIKit / CALayer / Core Animation (259 lines)
- [`c2_front_swiftui.md`](c2_front_swiftui.md) — Front of 10%, SwiftUI transitions / animations / materials (227 lines)
- [`c3_middle_coreimage.md`](c3_middle_coreimage.md) — Middle of 10%, CoreImage / CIFilter / CIKernel (278 lines)
- [`c4_middle_metal.md`](c4_middle_metal.md) — Middle of 10%, Metal / MetalKit / MPS / MetalFX (291 lines)
- [`c5_latter_cafilter.md`](c5_latter_cafilter.md) — Latter end of 10%, CAFilter named recipes (250 lines, 47 CARTO IDs)
- [`c6_latter_ui_internals.md`](c6_latter_ui_internals.md) — Latter end of 10%, `_UI*` / CA private layer classes (302 lines, 16 CARTO IDs)

## Cross-cutting findings (cited from the per-file analyses)

### Parametric blur radius — the single most missing capability
- **NOT available** in front-of-10% UIKit (only preset swaps via `UIBlurEffect`)
- **IS available** in front-of-10% SwiftUI via `.blur(radius:)` — but requires `UIHostingController` bridge
- **IS available** in middle-of-10% CoreImage via `CIGaussianBlur.inputRadius`
- **IS available** in middle-of-10% Metal via `MPSImageGaussianBlur`
- **IS available** in latter-end via `CAFilter(type: "gaussianBlur").inputRadius` (keypath: `"backgroundFilters.<name>.inputRadius"`)
- **LOWEST-RISK PATH:** `valueForKey("backdropView")` on a public `UIVisualEffectView` to reach `_UIVisualEffectBackdropView`, then animate its `inputRadius` directly (c6, CARTO-uiinternals)

### Live cross-tree composition
- **Only `_UIPortalView`** lets one view render the live contents of another with independent transforms/filters — c6
- Snapshot-then-blur creates "pop" at start/end; portals avoid it

### Transition-zone shader composition
- Front-of-10% cannot express continuous per-pixel transition-zone shading
- CoreImage `CIBlendKernel` and Metal fragment shaders can — c3, c4
- Apple-grade glass requires `CIGlassDistortion.inputDispersion` (undoc) or custom Metal shader — c3

### Apps the cartography surfaces by name
- **Telegram (open-source)** — confirmed `CABackdropLayer + CAFilter` direct instantiation
- **Halide** — hot Metal pipeline always running; uses MetalFX
- **Procreate** — Metal compositing, likely pyramid LOD for gallery↔canvas
- **Apollo, Tweetbot, Overcast, Castro** — `CAFilter` recipes
- **Apple Music, Apple Photos, SpringBoard** — `_UIVisualEffectBackdropView` direct manipulation

These names are the seed list for the ninety wave reverse-engineering dips.
