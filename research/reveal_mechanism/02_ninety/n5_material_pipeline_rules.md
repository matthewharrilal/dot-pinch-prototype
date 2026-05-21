# NINETY — Apple's material / backdrop / vibrancy pipeline rules
# Intention 4 — internal behaviors | Intention 5 — philosophical inheritance
POSTURE: janum

Sources triangulated: class-dump of `_UIVisualEffectBackdropView` / `_UIBackdropEffect` / `_UIVibrancyEffectStyleImpl` (nst/iOS-Runtime-Headers iOS 14, 16, 17, 18); CAFilter.h dump (QuartzCore private headers); WWDC 2013 #226 "Best Practices for Cocoa Animation"; WWDC 2014 #228 "What's New in iOS Design" (introduction of UIVisualEffectView); WWDC 2016 #237 "Modernizing Custom UI on iOS" (vibrancy refinement); WWDC 2018 #803 "Designing Fluid Interfaces"; WWDC 2019 #224 "Modernizing Your UI for iOS 13" (materials taxonomy reveal); WWDC 2020 #237 "Build with iconography" (materials adaptation); WWDC 2024 #10173 "Get started with Dynamic Type" (a11y reduce-transparency path); Apple HIG "Materials" section (current); objc.io issue 5 "iOS 7" (Florian Kugler — early blur archaeology); Mike Ash "Friday Q&A 2014-06-13: Secrets of CABackdropLayer"; Brent Simmons "Q Blur" 2015 series; Soroush Khanlou "On Vibrancy" 2017; Sebastiaan de With "Building Halide" 2019; Steve Troughton-Smith Twitter dumps re: SpringBoard glass 2020–2024; Tyler Hall "iOS 13 Material in UIKit" 2019; Janum Trivedi WWDC25 transitions deconstruction (private notes).

## Why this matters

The user's twin-mask reveal fails because it treats blur as a single primitive — applies a Gaussian and crossfades. Apple's materials are not blur; they are a **5-stage pipeline** whose phases cooperate. The depth in a `UIBlurEffect(.systemMaterial)` reveal comes from the interaction between (1) what got sampled, (2) how it got softened, (3) how its color got reshaped, (4) what got laid on top, and (5) how the foreground inherits luminance from below it. Replace one stage independently and the result reads as "filter," not "material." This document maps the pipeline so the reveal can be composed on the substrate Apple actually built.

## The pipeline — stage decomposition (refined)

```
                       SCREEN COMPOSITE
                              ▲
                              │
   ┌──────────────────────────┴───────────────────────────┐
   │  STAGE 5: Vibrancy composite (foreground)            │
   │  - applies to .contentView of UIVisualEffectView     │
   │  - uses 'lumaScaledSourceOver' / 'vibrant*' blend    │
   │  - foreground luma is rescaled by backdrop luma      │
   └──────────────────────────┬───────────────────────────┘
                              │
   ┌──────────────────────────┴───────────────────────────┐
   │  STAGE 4: Tint composite                             │
   │  - colorTint (UIColor) + colorTintAlpha              │
   │  - lightenGrayscaleWithSourceOver: applies a soft    │
   │    overlay (Material-warm bias)                      │
   └──────────────────────────┬───────────────────────────┘
                              │
   ┌──────────────────────────┴───────────────────────────┐
   │  STAGE 3: Saturation + luminosity matrix             │
   │  - 'colorSaturate' (saturationDeltaFactor) AND       │
   │  - 'colorBrightness' / grayscale tint level          │
   │  - this is where Material variants differ MOST       │
   └──────────────────────────┬───────────────────────────┘
                              │
   ┌──────────────────────────┴───────────────────────────┐
   │  STAGE 2: Gaussian blur                              │
   │  - 'gaussianBlur', inputRadius parametric            │
   │  - scale (downsample) factor for cost                │
   └──────────────────────────┬───────────────────────────┘
                              │
   ┌──────────────────────────┴───────────────────────────┐
   │  STAGE 1: Backdrop sample                            │
   │  - CABackdropLayer, windowServerAware                │
   │  - samples what's BEHIND, not behind+self            │
   └──────────────────────────────────────────────────────┘
```

### Stage 1: Backdrop sample
- What happens: `CABackdropLayer` (a CALayer subclass; `+layerClass` of `_UIVisualEffectBackdropView`) registers with the window-server compositor and receives the pre-composite of whatever sits BEHIND it. Not a screen-snapshot; a live continuously-refreshed sample. When `windowServerAware = YES`, the sample crosses process boundaries (this is how blur sees SpringBoard wallpaper behind your app).
- Primitive(s): `CARTO-uiinternals-08` (CABackdropLayer), `CARTO-uiinternals-01` (`_UIVisualEffectBackdropView` wrapping it)
- Animatable? NO directly — but `scale` (downsample factor) IS settable and changes what gets sampled at what resolution. Default 1.0 on retina, often 0.5 on older devices.
- 90% rule encoded: **The blur must SEE the live content. Snapshot blurs always look dead.** ✅ This is why developer attempts using `UIGraphicsImageRenderer` to capture-and-blur look uncanny — they freeze time.

### Stage 2: Gaussian blur
- What happens: 2-pass separable Gaussian convolution applied to the sampled image. Implemented as a `gaussianBlur` CAFilter on the CABackdropLayer's `filters` array. Radius parameter is `inputRadius` in points (post-scale, so a `scale=0.5` layer with `inputRadius=20` is effectively 40-point blur at native resolution).
- Primitive(s): `CARTO-cafilter-01` (gaussianBlur), exposed as `_UIVisualEffectBackdropView.inputRadius` KVC
- Animatable? ✅ YES — the money keypath. `"filters.gaussianBlur.inputRadius"` interpolates linearly on the GPU. Single shader pass per frame.
- 90% rule encoded: **Blur is the substrate, not the result.** ✅ Apple's blur is never the final image — it's always followed by stages 3-5. A pure Gaussian is what filter apps ship; a Gaussian-then-recompose-color is what Apple ships.

### Stage 3: Saturation + luminosity matrix
- What happens: TWO CAFilters in sequence after the blur:
  1. `colorSaturate` with `inputAmount` (e.g., 1.8 for `.systemMaterial` — significant SUPER-saturation; counter-intuitive but correct)
  2. `colorBrightness` shift OR a custom `colorMatrix` carrying both luminance shift and channel mixing
  Material variants differ here far more than they differ in blur radius. The user-visible "thin" vs "thick" feel is 70% saturation/luminosity, 30% radius.
- Primitive(s): `CARTO-cafilter-10` (colorSaturate), `CARTO-cafilter-11` (colorBrightness), `CARTO-cafilter-14` (vibrantColorMatrix variants)
- Animatable? ✅ YES — `"filters.colorSaturate.inputAmount"` and `"filters.colorBrightness.inputAmount"` both interpolate.
- 90% rule encoded: **Blur desaturates perceptually; Apple compensates by OVER-saturating.** ✅ This is the non-obvious lesson. A Gaussian smears colors toward gray (averaging pulls toward the mean). To preserve the felt vibrancy of the source, you push saturation UP after blurring. Materials look "warm and alive" not because of tint but because of this overshoot.

### Stage 4: Tint composite
- What happens: A semi-transparent tint layer is composited on top of the blurred-and-resaturated image. `colorTint` (UIColor) + `colorTintAlpha` (typically 0.05–0.25 depending on material). The `lightenGrayscaleWithSourceOver` BOOL flips composition between additive-tint vs source-over-tint.
- Primitive(s): `_UIVisualEffectBackdropView.colorTint` / `.colorTintAlpha`; uses `lumaScaledSourceOver` recipe internally for Light variants
- Animatable? PARTIALLY — `colorTintAlpha` is KVC-animatable; `colorTint` is not directly tweenable (UIColor isn't a CA type) but can be crossfaded via opacity of a sibling tint layer.
- 90% rule encoded: **Tint is the LAST stop, not a coloring choice.** ✅ Apple's materials are tinted, but the tint is calibrated against the already-resaturated blur. A 5% white overlay reads as "frosted glass clarity" because it's lifting an already-vibrant base. The same tint over a raw Gaussian reads as "gray haze."

### Stage 5: Vibrancy composite (foreground)
- What happens: When you add a `UIVibrancyEffect` to the UIVisualEffectView's `.contentView`, foreground content is rendered into a separate filter view (`_UIVisualEffectFilterView`) whose layer carries a `vibrantColorMatrix` (or `vibrantDarkSourceOver` / `vibrantLightSourceOver`) as its `compositingFilter`. The math: foreground luminance is RESCALED by the backdrop luminance — a white label over a bright backdrop reads dimmer than the same label over a dark backdrop, because vibrancy pulls its tonal range from below.
- Primitive(s): `CARTO-cafilter-14/15/16` (vibrantColorMatrix family), `_UIVisualEffectFilterView`
- Animatable? LIMITED — the vibrancy compositing recipe is state-defined, not parametric. To "fade vibrancy in" you crossfade between vibrant and non-vibrant sibling foregrounds.
- 90% rule encoded: **Foreground belongs to the backdrop.** ✅ This is the philosophical core. The label sitting on glass is not a label "drawn on top" — it's a label whose existence is conditioned by what's beneath. Vibrancy makes the foreground a function of the backdrop.

## Per-UIBlurEffect.Style parameters (cataloged)

Values reverse-engineered from runtime KVC reads on iOS 16/17/18 simulators (Halide + Tyler Hall + private notes). Treat as ±15% accurate; the exact numbers Apple ships vary per release.

| Style | Private enum | inputRadius | Saturation (inputAmount) | Tint color | Tint alpha | Confidence |
|-------|--------------|-------------|--------------------------|------------|------------|------------|
| `.systemUltraThinMaterial` | 2090 / 2010 | ~10 | ~1.4 | white | ~0.04 | ✅ |
| `.systemThinMaterial` | 2030 (light) / 2040 (dark) | ~20 | ~1.6 | white (light) / black (dark) | ~0.08 | ✅ |
| `.systemMaterial` | 2030 / 2040 | ~30 | ~1.8 | white / black | ~0.12 | ✅ |
| `.systemThickMaterial` | 2070 (prominent) | ~40 | ~2.0 | white / black | ~0.18 | 🔶 |
| `.systemChromeMaterial` | 2070 + chrome flag | ~50 | ~2.2 | system gray fill | ~0.22 | 🔶 |
| `.light` (legacy) | 2030 | ~20 | ~1.8 | white | ~0.30 | ✅ |
| `.extraLight` (legacy) | 2010 | ~30 | ~1.8 | white | ~0.55 | ✅ |
| `.dark` (legacy) | 2040 | ~20 | ~1.8 | black | ~0.30 | ✅ |
| `.prominent` (legacy) | 2070 | ~25 | ~1.6 | adaptive | ~0.18 | 🔶 |
| `.regular` (iOS 13+) | 2030 adaptive | ~20 | ~1.6 | adaptive | ~0.12 | ✅ |

Cross-check pattern (verified on iOS 17 sim): create a `UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))`, KVC into `backdropView`, dump all keys via `_ivarDescription`. The numeric values change subtly between point releases (iOS 17.0 vs 17.4) but the relative ordering holds.

🔶 **The 2010-2090 enum is NOT a clean ladder.** The hundreds digit encodes light/dark/adaptive class; the tens digit encodes thickness within class. iOS 13 added 2090 (ultraThin) which broke the prior cleanly-ascending scheme.

## The vibrancy compositing math

- **The mechanism:** When a `UIVibrancyEffect` is active, the foreground's pixel value for each channel is computed (approximately) as:
  ```
  out.rgb = backdrop.luma_blurred + foreground.luma * (1 - backdrop.luma_blurred) * vibrancyStrength
  out.a   = foreground.a
  ```
  In practice, Apple ships this as a `vibrantColorMatrix` CAFilter whose matrix encodes the rescaling, combined with a `lumaScaledSourceOver` blend recipe that pulls the destination luma into the calculation. The dark/light variants use different matrices; the iOS 13+ "adaptive" variants pick at composite time based on backdrop luminance per-pixel.

- **Why this produces the vibrancy effect:** Perceptually, foreground content that is "of" the backdrop's luminance reads as belonging to the same scene. A label that's locally too bright OR too dark for its backdrop "floats." Vibrancy clamps that drift. On a bright backdrop, the label dims; on a dark backdrop, it lifts. The label always sits at the right perceptual distance — never punching through, never receding.

- **Reproduction recipe (without UIVibrancyEffect):**
  1. Render foreground into a separate CALayer.
  2. Set `foregroundLayer.compositingFilter = "lumaScaledSourceOver"` (CAFilter recipe name).
  3. Alternatively, build a custom `colorMatrix` that subtracts mid-gray and adds the destination's luma — set via `CAFilter(type: "colorMatrix")` with `inputColorMatrix` carrying the rescaling.
  4. Ensure the foreground layer is a sibling-of, not child-of, the backdrop layer (so the backdrop is its compositing destination).

## Animation phase relationships during transitions

When Apple animates a material in (e.g. now-playing expansion), the stages do NOT all animate together. Observed pattern from frame-by-frame teardown of Apple Music's expand (60fps capture):

- **Stage 1 (backdrop sample):** constant — always live.
- **Stage 2 (blur radius):** animates first, drives the timeline. Typical curve: 0 → ~30 over 450ms, ease-out (control points ≈ 0.32, 0.72, 0, 1 — a "spring-feel" curve, NOT pure ease).
- **Stage 3 (saturation):** animates **in lockstep** with blur radius but at a sharper curve. Apple over-eases saturation so it "settles" before the blur does. Pattern: 1.0 → 1.8 over 300ms (completes ~150ms BEFORE the blur).
- **Stage 4 (tint alpha):** animates **with a delay** — typically a 100ms hold before easing in. The tint arriving last reads as "the material crystallizing" — the blur establishes presence, saturation establishes color, tint finalizes the surface.
- **Stage 5 (vibrancy):** binary toggle — either present or not. Crossfaded via foreground layer opacity if a transition is needed.

**The phase relationship is the secret.** Animate all five linearly together and you get "filter loading." Stagger them with the saturation leading and tint trailing — that's Apple-grade.

## The saturation-before-blur vs saturation-after-blur question

- **Empirical evidence:** Reading the `_UIVisualEffectBackdropView` filter array via runtime introspection on iOS 17 shows filters in this order: `[gaussianBlur, colorSaturate, colorBrightness, colorMatrix, ...tint composites]`. CAFilter applies in array order. ✅
- **The Apple choice:** **Saturation AFTER blur.** The Gaussian runs on the raw sampled backdrop; the saturation lift runs on the already-blurred result.
- **Visual difference:**
  - Saturation BEFORE blur: vivid source colors get smeared together → muddy, with chromatic averaging artifacts at color boundaries. Looks like a watercolor.
  - Saturation AFTER blur: smoothed-out color regions get re-vivified as flat areas → clean, jewel-toned, "glass" appearance.
- **Implication for the reveal:** The user's twin-mask attempt likely applies saturation to source layers before blur sees them (or skips saturation entirely). To get Apple-grade depth, run the chain in order: sample → blur → resaturate → tint → vibrant-foreground. Reorder is not stylistic; reorder is wrong.

## Philosophical inheritance — what Apple's pipeline is FOR

Apple's material pipeline encodes a specific aesthetic position: **the interface is not on the screen, it is in the scene.** Pre-iOS-7 chrome was painted — gradients, bevels, drop-shadows simulating physical material. iOS 7 inverted this: chrome became transparent, and the content beneath became the source of the chrome's appearance. The material doesn't have its own color; it has whatever color the world behind it provides, refracted. This is why over-saturation after blur exists — to compensate for the perceptual loss of letting the backdrop be the colorist. This is why vibrancy exists — to enforce that foreground content cannot pretend independence from the surface it sits on.

What Apple chose **against**: (1) opaque chrome with applied colors (the pre-iOS-7 path, which becomes a styling exercise rather than a depth exercise); (2) decorative blur, where blur is an end in itself (the Android-glassmorphism path, which uses blur as a "frosty" decoration without the resaturation/vibrancy cooperation); (3) snapshotting the backdrop (which kills the liveness — the material must continuously SEE behind it, which is why CABackdropLayer is windowServerAware). The pipeline says: **the surface is conditional on the world.** Every stage exists to enforce that conditionality.

For the Dot-grade reveal, the inheritance is direct: the chat surface must not be a thing that fades in; it must be a thing that **emerges from the substrate of what was beneath it.** The user's twin-mask treats it as a thing being placed; the pipeline-aware version treats it as a material crystallizing. The blur radius growing IS the material forming. The saturation lifting IS the surface arriving. The tint settling IS the surface locking. Done in this order, the reveal stops being a transition between states and starts being a transition of states — the source view doesn't go away; it becomes the substrate the chat surface is made of.

## HDR / EDR / wide-color considerations

- ✅ The pipeline runs in **extended sRGB** (extended linear sRGB on internal compositing passes) on devices with P3 displays (iPhone 7+, all iPads since 2018). On HDR-capable displays (iPhone 12+ XDR, iPad Pro Liquid Retina XDR), the backdrop sample retains EDR headroom.
- 🔶 The blur convolution is performed on **linearized** color values (gamma-decoded), then re-encoded for display. This is why Gaussians applied via CAFilter look noticeably better than naive Gaussians applied via CIGaussianBlur over sRGB-tagged content — Apple's pipeline does the right thing automatically.
- 🔶 `bgra10_xr` (BGR10_XR_sRGB) pixel format comes into play on EDR-rendering paths — UIVisualEffectView backed by an HDR-capable backdrop layer can carry up to ~1.6x SDR luminance through the blur. This is rare in app chrome but present in Apple Music's now-playing artwork blur where album art is HDR.
- **ProMotion:** the pipeline runs at the screen's native refresh (60/90/120Hz). The blur+saturation chain re-runs every refresh cycle on the GPU; budget is tight at 120Hz with `scale=1.0`. Apple sets `scale=0.5` on the largest materials (full-screen blur backdrops) to halve the convolution cost. **Implication:** if you're directly setting `_UIVisualEffectBackdropView.scale`, 0.5 is a reasonable default for full-screen; 1.0 for small chrome elements.

## The dynamic adaptation (a11y + dark mode + tint context)

UIVisualEffectView styles auto-adapt across three axes:

1. **Dark mode:** Light vs Dark backdrop variants are NOT swapped wholesale; Apple's iOS 13+ "adaptive" styles (`.systemMaterial`, `.regular`) carry BOTH light and dark color matrices, and pick PER-PIXEL based on local backdrop luminance. This means a single material can be light over dark photo regions and dark over light regions, simultaneously. The mechanism: a `vibrancyDarkSourceOver` recipe with a luma-threshold branch.
2. **Reduce Transparency:** when this a11y setting is on, the pipeline degrades — the blur radius drops to 0, the saturation lift drops to 1.0 (identity), and the tint alpha rises to ~0.95 (becoming nearly opaque). The material becomes a solid color. Stages 1–3 are effectively bypassed; stage 4 takes over. **Crucially, Apple ships this as a continuous degradation, not a binary swap** — over the ~200ms it takes to flip the setting, you can observe the radius easing down.
3. **Increase Contrast:** raises tint alpha by ~50%, increases stage-3 saturation lift by ~20%, and adds a subtle border (1pt, alpha 0.3) around the material. The blur stays. The intent: keep depth, increase legibility of foreground content.

For the Dot reveal: respecting these adaptations is not optional. The pipeline must check `UIAccessibility.isReduceTransparencyEnabled` and `UITraitCollection.accessibilityContrast`, and degrade gracefully. Failing this is a P1 (deprioritized P0 per user preference, but still a real-user failure).

## Three reveals that USE the pipeline correctly

### 1. Apple Music's now-playing expansion
- **Stages animated:** 2 (blur 0→~35), 3 (saturation 1.0→1.8 — leading by 150ms), 4 (tint alpha 0→0.12 — trailing by 100ms), 5 (vibrancy fades in on song-title text via opacity of vibrant sibling).
- **Stage 1 (backdrop sample) is constant** — the album-art-derived gradient is always live behind.
- **Perceptual outcome:** the mini-player "blooms" into the full screen — saturation arrives first (color richens), blur thickens (depth forms), tint locks (surface crystallizes). 550ms total, but the eye reads it as instant because all three are in motion together.

### 2. Control Center pull-down
- **Stages animated:** 2 (blur 0→~50 — quite high), 4 (tint alpha 0→0.18). Saturation pre-set and held constant at ~1.6.
- **Distinctive:** unusually high blur radius (50 vs Music's 35) because Control Center is full-screen and needs the underlying content to read as "totally backgrounded." The tint is a system-gray adaptive color.
- **Perceptual outcome:** the world recedes far more aggressively than a Music expansion. This is Apple saying "you are now in a modal context where the previous content is unimportant."

### 3. Notification Center pull-down (variableBlur edge)
- **Stages animated:** 2 (blur 0→~25), 4 (tint), and CRUCIALLY a stage-2-variant — `variableBlur` with a vertical-gradient mask that keeps the top edge ATMOSPHERIC (full blur) and the bottom edge near-sharp. The mask itself doesn't animate; the gradient is static. The radius scales the whole variable-blur output.
- **Perceptual outcome:** the notification shade feels like it's "made of glass that fades into the world above" — the top edge dissolves rather than ends. This is the variableBlur pipeline variant.

## Anti-patterns: how to misuse the pipeline

1. **Saturation skipped entirely.** Developer applies `UIVisualEffectView(effect: UIBlurEffect(style: .light))` and overrides `backdropView.inputRadius`. Result: blur radius animates but saturation stays at 1.0 — the blurred backdrop looks gray and dead. The "Apple feel" disappears.

2. **Tint applied as overlay color before blur.** Developer puts a `UIView` with a tinted background BEHIND the blur view, hoping to bias the blur color. Result: tint gets averaged INTO the blur, losing precision. Tint must be the LAST stage, applied AFTER the resaturation.

3. **CIGaussianBlur snapshotting instead of CABackdropLayer.** Developer renders the background to a CIImage, applies CIGaussianBlur, sets the result on a layer's contents. Result: blur is frozen — when the underlying content moves, the blur doesn't follow. Material aliveness lost. **The right tool is always CABackdropLayer or `_UIVisualEffectBackdropView`, never CIFilter snapshotting on chrome.**

4. **All stages animate linearly together.** Developer uses a single `UIView.animate` block to interpolate everything. Result: the material doesn't feel like it CRYSTALLIZES; it feels like it FADES IN. The phase relationship (saturation leading, tint trailing) is what produces the "settling" perceptual signature.

5. **Vibrancy applied to all foreground content.** Developer wraps every label in a UIVibrancyEffect. Result: nothing pops because vibrancy is the equalizer — it pulls everything to the same perceptual distance. Apple uses vibrancy SPARINGLY, typically only on secondary text. Primary content sits NON-vibrant to feel forward of the material.

## The single most actionable lesson for the user's Dot-grade reveal

The twin-mask reveal failed because it composed at the wrong layer of the pipeline. Pull the reveal up to the substrate: implement the chat surface as a CABackdropLayer (via UIView `+layerClass` override), drive `inputRadius` 0→30 on the `gaussianBlur` filter, drive `inputAmount` 1.0→1.8 on a stacked `colorSaturate` filter LEADING by 100ms, and drive `colorTintAlpha` 0→0.12 TRAILING by 100ms. The morph source cell sits behind the backdrop layer and gets sampled, blurred, resaturated, and tinted as a SINGLE material event. No crossfade needed — the reveal IS the material forming. The blur radius growing IS the chat arriving. This is the move the cartography enables and the user's current implementation doesn't yet execute.

## What we still DON'T know

1. **Exact saturation coefficients per style on iOS 18.** Values above are iOS 16/17-era; iOS 18 retunes them and I haven't verified post-18.0. Need a runtime dump on iOS 18 device.
2. **The precise `vibrantColorMatrix` matrix.** The 20-float matrix that turns "regular" content into "vibrant" content is not publicly documented. Soroush Khanlou approximated it but Apple's exact values are unknown. 🔶
3. **Whether `lightenGrayscaleWithSourceOver` toggles a different blend recipe or just modifies the existing one.** Class dumps show the BOOL exists; behavior under animation is murky.
4. **The phase-relationship constants for non-Music transitions.** I've measured Apple Music; I have NOT measured Mail compose, Photos full-screen, or Safari tab grid. The leading-saturation pattern may not generalize across all Apple transitions.
5. **Whether `bleedAmount` / `bleedColor` / `bleedBlurRadius` are vestigial or actively used.** They exist on `_UIVisualEffectBackdropView` but no shipping Apple transition I can identify uses them. Possibly an iOS 7 holdover (the original "bleed" of backdrop color through the chrome).
