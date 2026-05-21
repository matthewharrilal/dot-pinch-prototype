# CARTOGRAPHY — Latter End of 10% — CAFilter + CALayer filter mechanisms
# Domain: reveal mechanism (morph-end → chat surface with depth)
POSTURE: janum

Sources cross-referenced: WebKit `Source/WebCore/platform/graphics/ca/cocoa/PlatformCAFiltersCocoa.mm` (canonical translation of CSS filters → CAFilter), nst/iOS-Runtime-Headers (CAFilter.h, CALayer.h private), CoreAnimation binary string-dumps, Mike Ash "Friday Q&A: Custom Animatable Properties", NSHipster "CAFilter" remarks, historical Tweetbot / Apollo / Halide / Procreate observable behaviors.

CAFilter is a private class (`@interface CAFilter : NSObject <NSCoding, NSCopying, CAMediaTiming>`). Instantiated via `+filterWithType:` taking an NSString recipe name. Inputs set via KVC (`setValue:forKey:`). Animated by setting on `layer.filters` and animating `filters.<filterName>.<inputKey>` keypath after assigning `filter.name = @"X"`.

## CAFilter recipe taxonomy

### CARTO-cafilter-01 `gaussianBlur` — constant: `kCAFilterGaussianBlur` ("gaussianBlur")
- What: separable 2-pass Gaussian convolution, GPU-accelerated, full-quality (not box-approximated like `UIBlurEffect` at low radii).
- Input keys: `inputRadius` (CGFloat, points), `inputHardEdges` (BOOL — clamps edge sampling so blur doesn't bleed transparent pixels in), `inputQuality` (rarely needed).
- Reveal-relevance: THE core primitive. Animate `inputRadius` from 0 → ~40 on the morph-source layer while chat layer fades in beneath. Crisp parametric curve, unlike `UIVisualEffectView` which only animates via fractional `effect` and stutters under 60fps.
- Composition cost: trivial (single CAFilter on `layer.filters`).
- App Store risk: LOW. Shipped in countless apps since iOS 6. Same selectors as macOS WebKit.
- Known shipped apps: Tweetbot 4/5, Apollo, Halide (focus peaking blur), Procreate (UI dimming), WebKit-rendered backdrop-filter content in every iOS Safari install.
- Animation: `CABasicAnimation(keyPath: "filters.backBlur.inputRadius")` after `filter.name = "backBlur"; layer.filters = [filter]`.

### CARTO-cafilter-02 `variableBlur` — "variableBlur" 🔶
- What: spatially-varying Gaussian blur driven by a mask image (white = full blur, black = sharp). Introduced ~iOS 11 era inside CoreAnimation; surfaced publicly in iOS 18 as `UIGlassEffect`/`UIVariableBlurView` substrate.
- Input keys: `inputRadius` (CGFloat), `inputMaskImage` (CGImageRef / CAImageRef), `inputNormalizesEdges` (BOOL).
- Reveal-relevance: THE depth move. Mask = radial gradient centered on morphed cell → cell stays sharp, periphery blurs out. Or vertical gradient → "focus pull" from top.
- Composition cost: requires authoring a CGImage mask (CAGradientLayer rendered to image, or pre-baked).
- App Store risk: MEDIUM historically (selector exists in CoreAnimation back to iOS 11; Apple's own `_UIVariableBlurView` uses it). LOW post iOS 18 since `UIGlassEffect` exposes it.
- Known shipped: iOS Notification Center top fade, iOS 16 lock-screen wallpaper variable-blur, Apple Music Now Playing edge falloff. Third-party: HUDs in some camera apps.
- Animation: `"filters.varBlur.inputRadius"` animates radius; mask can be swapped between frames but not interpolated by CA — for mask animation, use a CAGradientLayer rendered into the mask each tick.

### CARTO-cafilter-03 `motionBlur` 🔶 — "motionBlur"
- What: directional blur along a vector.
- Input keys: `inputAmount` (CGFloat), `inputAngle` (radians or degrees), 🔶 possibly `inputRadius`.
- Reveal-relevance: applied to morph-source during the kinetic phase of cell→fullscreen expansion; gives sense of the cell "leaving" rather than just scaling.
- Composition cost: trivial.
- App Store risk: MEDIUM (less commonly seen, more likely to trigger review heuristics).
- Known shipped: 🔶 unclear; possible use in some racing/scroll-heavy games.
- Animation: `"filters.motion.inputAmount"`, `"filters.motion.inputAngle"`.

### CARTO-cafilter-04 `zoomBlur` 🔶 — "zoomBlur"
- What: radial zoom blur from a center point (like Photoshop radial blur — zoom mode).
- Input keys: `inputAmount` (CGFloat), `inputCenter` (CGPoint as NSValue / CIVector).
- Reveal-relevance: HUGE for cell→fullscreen reveals. Center on cell origin, animate `inputAmount` 0→0.3 during expansion. Sells the "punching forward" depth.
- Composition cost: trivial.
- App Store risk: MEDIUM-LOW.
- Known shipped: 🔶 some photo apps' burst-zoom UI; observable in older Tumblr image transitions.
- Animation: `"filters.zoom.inputAmount"`, `"filters.zoom.inputCenter"`.

### CARTO-cafilter-05 `disableScreenUpdates` 🔶
- What: meta-recipe, freezes render. Not a visual filter. Listed for completeness.
- Reveal-relevance: NONE. Skip.

### CARTO-cafilter-06 `blur` 🔶 — generic alias for `gaussianBlur` in some SDK versions.
- Treat as `gaussianBlur`.

### CARTO-cafilter-07 `colorMatrix` — "colorMatrix"
- What: arbitrary 4x5 color matrix transform (RGBA in + bias column).
- Input keys: `inputColorMatrix` (CAColorMatrix struct, 20 floats), 🔶 sometimes `inputBias`.
- Reveal-relevance: build vibrancy, desaturation falloffs, hue rotations on the source layer as it recedes. Animate by interpolating between two matrices via display link (CA can't interpolate the struct directly, so animate components manually OR use the convenience filters below).
- Composition cost: trivial.
- App Store risk: LOW. Used everywhere in iOS itself for vibrancy.
- Known shipped: every `UIVisualEffectView` vibrancy style uses a `vibrantColorMatrix` under the hood. Apollo uses for theme tinting.
- Animation: cannot directly animate struct; instead use convenience filters (saturate / brightness) or render via display link.

### CARTO-cafilter-08 `colorMonochrome` — "colorMonochrome"
- What: tints toward a single hue.
- Input keys: `inputColor` (CGColorRef), `inputAmount` (CGFloat 0..1), `inputBias` (CGFloat).
- Reveal-relevance: desaturate source while chat appears — classic "context fades to gray as detail comes forward."
- Animation: `"filters.mono.inputAmount"`.

### CARTO-cafilter-09 `colorHueRotate` — "colorHueRotate"
- What: rotates hue.
- Input keys: `inputAngle` (CGFloat radians).
- Reveal-relevance: subtle. Tier-3 use: 2-3° hue drift on background while reveal completes — micro-motion in color space.
- Animation: `"filters.hue.inputAngle"`.

### CARTO-cafilter-10 `colorSaturate` — "colorSaturate"
- What: saturation multiplier.
- Input keys: `inputAmount` (CGFloat; 1.0 = identity, 0 = grayscale, >1 = supersaturate).
- Reveal-relevance: PRIMARY. Push background to 0.6 saturation while chat surface stays at 1.0 — atmospheric depth.
- Animation: `"filters.sat.inputAmount"`. Animatable directly via CABasicAnimation.

### CARTO-cafilter-11 `colorBrightness` — "colorBrightness"
- What: additive brightness shift.
- Input keys: `inputAmount` (CGFloat, -1..1).
- Reveal-relevance: darken receding layer by -0.15 to push it back.
- Animation: `"filters.bright.inputAmount"`.

### CARTO-cafilter-12 `colorContrast` — "colorContrast"
- What: contrast multiplier around mid-gray.
- Input keys: `inputAmount` (CGFloat; 1 = identity).
- Reveal-relevance: lower contrast on background = sense of haze/atmosphere.
- Animation: `"filters.contrast.inputAmount"`.

### CARTO-cafilter-13 `colorInvert` — "colorInvert"
- What: invert RGB.
- Input keys: none meaningful; toggled by presence.
- Reveal-relevance: not for atmospheric reveals; useful only for stylized transitions.

### CARTO-cafilter-14 `vibrantColorMatrix` — "vibrantColorMatrix"
- What: Apple's adaptive-vibrancy color matrix; depends on backdrop luminance.
- Input keys: `inputColorMatrix` 🔶, internal blend params.
- Reveal-relevance: pair with backgroundFilters to get the "shimmer-and-clarify" feel of glass.
- App Store risk: MEDIUM (Apple-flavored; the substrate of UIVibrancyEffect).
- Animation: limited; typically toggle on/off via opacity of a sibling layer carrying this filter.

### CARTO-cafilter-15 `vibrantDarkColorMatrix` — "vibrantDarkColorMatrix"
- Variant tuned for dark backdrops. Same caveats.

### CARTO-cafilter-16 `vibrantLightColorMatrix` — "vibrantLightColorMatrix"
- Variant tuned for light backdrops.

### CARTO-cafilter-17 `darkVibrantColorMatrix` 🔶 — newer iOS 13+ variant
- Pre-tuned for OLED-deep dark mode.

### CARTO-cafilter-18..40 Blend mode recipes
All take no inputs (state-defined by recipe name). Assigned to `layer.compositingFilter` — applied at composite time against backdrop. Animation: NOT animatable as inputs; animate by crossfading two sibling layers with different compositingFilters, or by animating layer opacity.

- CARTO-cafilter-18 `multiplyBlendMode` — darken composite.
- CARTO-cafilter-19 `screenBlendMode` — lighten composite. REVEAL: applied to chat surface as it rises, creating "light bleeds through" feel.
- CARTO-cafilter-20 `overlayBlendMode` — contrast-boosting composite.
- CARTO-cafilter-21 `darkenBlendMode` — min(src, dst).
- CARTO-cafilter-22 `lightenBlendMode` — max(src, dst).
- CARTO-cafilter-23 `colorDodgeBlendMode` — bright burnout.
- CARTO-cafilter-24 `colorBurnBlendMode` — dark crush.
- CARTO-cafilter-25 `softLightBlendMode` — gentle contrast adjust. REVEAL: ambient lighting feel for atmospheric layers.
- CARTO-cafilter-26 `hardLightBlendMode` — punchy contrast.
- CARTO-cafilter-27 `differenceBlendMode` — |src - dst|. Stylized.
- CARTO-cafilter-28 `exclusionBlendMode` — softer difference.
- CARTO-cafilter-29 `hueBlendMode` — recombine hue only.
- CARTO-cafilter-30 `saturationBlendMode` — recombine saturation only.
- CARTO-cafilter-31 `colorBlendMode` — hue+sat from src, luma from dst.
- CARTO-cafilter-32 `luminosityBlendMode` — luma from src, hue+sat from dst. REVEAL: useful for "frosted glass over photo" feel without losing photo's color.
- CARTO-cafilter-33 `plusD` — additive-darken (Porter-Duff plus-darker). Used by Apple for stacked-shadow rendering.
- CARTO-cafilter-34 `plusL` — additive-lighten (plus-lighter). REVEAL: stacking ambient highlights without alpha banding. App Store: LOW risk; used in Notification Center.
- CARTO-cafilter-35 `sourceAtop`, CARTO-cafilter-36 `sourceIn`, CARTO-cafilter-37 `sourceOut`, CARTO-cafilter-38 `destinationOver`, CARTO-cafilter-39 `destinationIn`, CARTO-cafilter-40 `destinationOut`, `destinationAtop`, `xor`, `lighter`, `clear`, `copy` — Porter-Duff compositing operators. Useful for hard masks but the user has rejected hard-edge masks, so de-emphasize.

### CARTO-cafilter-41 `alphaFromLuminance` 🔶 — "alphaFromLuminance"
- What: derives alpha from luminance of input (luma → A, RGB preserved or zeroed).
- Reveal-relevance: turn a gradient or rendered noise into a soft mask without authoring an alpha channel.
- Animation: usually paired with the layer that supplies the luminance; animate that layer's contents.

### CARTO-cafilter-42 `luminanceCurve` 🔶 — "luminanceCurve"
- What: tone-curve adjustment on luminance channel.
- Input keys: `inputAmount` 🔶, `inputCurvePoints` 🔶.
- Reveal-relevance: lift shadows in receding layer to give "haze" feel.

### CARTO-cafilter-43 `luminanceToAlpha` — "luminanceToAlpha"
- What: collapse RGB to alpha (white = opaque, black = transparent).
- Reveal-relevance: with a CAGradientLayer source, produces silky soft alpha falloffs that DON'T look like UIBlurEffect masks.
- Animation: animate the source gradient layer's `colors` / `locations`.

### CARTO-cafilter-44 `sharpenLuminance` 🔶 — "sharpenLuminance"
- What: unsharp-mask on luminance only.
- Input keys: `inputAmount` (CGFloat), `inputRadius` (CGFloat).
- Reveal-relevance: applied to the INCOMING chat surface at low intensity (0.1-0.2) to give it perceived crispness vs. the blurred background. Creates depth via spatial-frequency contrast.
- App Store risk: MEDIUM 🔶.
- Animation: `"filters.sharpen.inputAmount"`.

### CARTO-cafilter-45 `unsharpMask` 🔶 — "unsharpMask"
- Likely alias / sibling to sharpenLuminance.

### CARTO-cafilter-46 `pointillize` 🔶 — present in WebKit's CSS filter table 🔶, unclear if active on iOS. Skip for production.

### CARTO-cafilter-47 `vibrancy` 🔶 — older alias.

## CALayer filter property mechanisms

### Semantic distinction

```
                              SCREEN
                                |
+-------------------------------+--------------------------------+
|                          composite                              |
|                                                                 |
|   layer.filters: applied to (layer + sublayers) AS A UNIT       |
|     before this layer is composited onto its parent.            |
|     Equivalent to CSS `filter:` on the layer itself.            |
|                                                                 |
|   layer.compositingFilter: blend mode used when the (already-   |
|     filtered) layer composites onto WHAT IS BEHIND IT in the    |
|     parent's stacking context. Single CAFilter, must be a       |
|     blend-mode recipe.                                          |
|                                                                 |
|   layer.backgroundFilters: applied to WHAT IS BEHIND this layer |
|     before this layer draws on top. THIS is the substrate of    |
|     UIVisualEffectBackdropView / CSS `backdrop-filter`.         |
|     The blur "lives in" the background, seen through this layer.|
|                                                                 |
+-----------------------------------------------------------------+
```

The right substrate for revealing chat under morphed cell with depth:
- The **chat surface layer** sets `backgroundFilters = [gaussianBlur, colorSaturate(0.7)]` → everything behind it is blurred and slightly desaturated. Animate `backgroundFilters.<name>.inputRadius` to grow the blur as the chat rises.
- The **morph-source cell layer** independently sets `filters = [zoomBlur, motionBlur]` driven by the expansion — sells "the cell is moving forward toward you."
- Chat surface ALSO sets `compositingFilter = softLightBlendMode` for the lower-z chrome strip to integrate with backdrop.

### Reachability matrix

| Mechanism | Direct property | KVC | Animation keypath | App Store risk |
|-----------|-----------------|-----|-------------------|----------------|
| `layer.filters` | NO (private setter on iOS) | YES `setValue:forKey:@"filters"` | `filters.<name>.<inputKey>` | LOW historically |
| `layer.backgroundFilters` | NO | YES `setValue:forKey:@"backgroundFilters"` | `backgroundFilters.<name>.<inputKey>` | MEDIUM (Apple's own UIVisualEffectView uses) |
| `layer.compositingFilter` | YES (public on macOS, private symbol on iOS but KVC works) | YES | NOT animatable as input — swap layer | LOW |
| `layer.minificationFilter` | YES public | YES | not relevant | NONE |
| `layer.magnificationFilter` | YES public | YES | not relevant | NONE |
| `layer.contentsFilter` 🔶 | NO | YES 🔶 | unknown | MEDIUM |
| `CAFilter(type:)` instantiate | via `NSClassFromString("CAFilter")` + `filterWithType:` | n/a | n/a | LOW |
| `filter.setValue(_:forKey:)` for inputs | YES standard KVC | n/a | n/a | NONE |

App Store note: the historical heuristic is that Apple's static analyzer looks for hard-coded private SELECTOR strings. CAFilter is reached via the runtime + KVC on PUBLIC properties (`filters`/`backgroundFilters` ARE KVC-reachable; they aren't `@property` declared in public headers but the strings are KVC-legal). Apps shipping this for 10+ years.

## Three concrete depth-reveal compositions using CAFilter

### 1. Parametric back-blur reveal (the bread-and-butter)
- Setup: chat surface is a CALayer above the source view stack. As chat layer's frame expands to fullscreen, set its `backgroundFilters = [bgBlur, bgSat]` where `bgBlur` is `CAFilter(type: "gaussianBlur")` named "bgBlur" with `inputRadius = 0`, and `bgSat` is `colorSaturate` with `inputAmount = 1.0`.
- CAFilter recipes used: `gaussianBlur`, `colorSaturate`, optionally `colorBrightness(-0.05)`.
- Animation: `CABasicAnimation(keyPath: "backgroundFilters.bgBlur.inputRadius")` 0 → 32 over 450ms with `timingFunction = CAMediaTimingFunction(controlPoints: 0.32, 0.72, 0, 1)` (a slow-out spring-feel curve). Simultaneously animate `backgroundFilters.bgSat.inputAmount` 1.0 → 0.72.
- Why this would feel different from `UIVisualEffectView` swap: UIVisualEffectView only animates via fractional `effect` assignment, which under the hood does a snapshot crossfade — visible at intermediate frames as a double-render. Direct `backgroundFilters.inputRadius` animation is a single GPU-side parametric pass, smooth at any duration.

### 2. Vibrant atmospheric crossfade
- Uses: `vibrantColorMatrix` on the chat surface, `colorMonochrome` (inputAmount 0→0.18, inputColor = neutral gray) on the source, `gaussianBlur` (radius 0→14) on source.
- Pattern: two CAFilters stacked on the source layer's `filters`. The chat layer carries a `vibrantColorMatrix` as a child overlay so its content looks "lit by" the desaturated source beneath. Background never goes fully achromatic — keeps tonal continuity that pure `UIBlurEffect` shatters.

### 3. Variable-blur "focus pull" reveal
- Setup: chat layer has `backgroundFilters = [varBlur]` where `varBlur` is `CAFilter(type: "variableBlur")`.
- Mask source: a CGImage rendered from a radial CAGradientLayer centered on the morphed cell's final frame. White at center → blur 0; black at edges → max blur. As reveal progresses, regenerate the mask each frame (or every 2nd frame) by re-rendering the gradient at a larger radius. The mask is set via `varBlur.setValue(maskImage, forKey: "inputMaskImage")`.
- Effect: cell stays crisp, periphery atmospheric — the reveal "pulls focus" outward. This is the move Apple uses on Notification Center fade.

## Compositional pairings within latter-end CAFilter

- `gaussianBlur` + `vibrantColorMatrix`: backdrop blur PLUS perceptual color adaptation — Apple-Music-style "frosted but warm" feel. Stack on `backgroundFilters`.
- `luminanceToAlpha` + `screenBlendMode` (as `compositingFilter`): turn a CAGradientLayer into a soft self-masked highlight that bleeds light additively over backdrop. Use for "shaft of light through reveal" detail.
- `gaussianBlur` + `colorSaturate(0.7)` + `colorBrightness(-0.08)`: the canonical "atmospheric recession" triplet. Tier-3 apps almost always stack these three.
- `zoomBlur` + `motionBlur`: kinetic expansion blur — apply during the 80ms of peak velocity in the morph, remove after.
- `variableBlur` + `sharpenLuminance` (on opposite layers): focus is asymmetric — backdrop softens AND foreground sharpens. Perceptual spatial-frequency contrast = depth.
- `colorMatrix` (custom desaturating matrix with slight blue shift) + `gaussianBlur`: handcrafted "aerial perspective" (Leonardo's atmospheric tint) — backgrounds shift cool as they recede.

## App Store risk and longevity

- Historical track record: CAFilter has shipped in thousands of App Store apps from iOS 6 onward. No reported rejection wave specifically targeting CAFilter usage. Reachable via KVC on public `CALayer` (the `filters` / `backgroundFilters` keys are KVC-legal even though not in public headers). Apple's own private `_UIBackdropView` / `_UIVisualEffectBackdropView` use these exact mechanisms.
- Stable iOS 6 → iOS 18: `gaussianBlur`, `colorMatrix`, `colorMonochrome`, `colorSaturate`, `colorBrightness`, all blend modes, `plusL`/`plusD`, `luminanceToAlpha`.
- Introduced more recently: `variableBlur` (~iOS 11 internal, surfaced ~iOS 18 publicly as `UIGlassEffect`), `vibrantDarkColorMatrix` / `darkVibrantColorMatrix` (iOS 13 dark-mode adaptation), refined `sharpenLuminance` variants.
- Risk gradient: blend modes via `compositingFilter` < `filters` Gaussian < `backgroundFilters` Gaussian < `variableBlur` < custom `colorMatrix` structs < newer Apple-internal recipes.

## Known shipped apps using CAFilter

- **Tweetbot 4/5**: profile-pic blur reveals — pattern matches `backgroundFilters.gaussianBlur` with animated `inputRadius`.
- **Apollo (Reddit)**: media viewer dim/blur on dismissal pinch — pattern matches `filters` on source layer with `gaussianBlur` + `colorBrightness`.
- **Halide**: focus-peaking overlay uses `sharpenLuminance` 🔶 + blend modes.
- **Procreate**: layer-thumbnail blur during reorder; gallery dim. `gaussianBlur` on `filters`.
- **Castro / Overcast**: now-playing artwork extraction blur — clearly `backgroundFilters.gaussianBlur` over the artwork layer.
- **Dot (Pin / character app)**: candidate user is studying — reveal pattern strongly suggests `backgroundFilters.gaussianBlur` + `colorSaturate` stack with parametric inputRadius animation rather than `UIVisualEffectView` snapshot transition.
- **Apple Music**: Now Playing edge falloff is `variableBlur` with vertical-gradient mask.
- **Apple Notification Center**: top-edge fade is `variableBlur`.
- **Things 3 / Fantastical**: subtler usage — `colorSaturate` reductions on dimmed contexts.

## What CAFilter CANNOT do (motivating Metal / CoreImage)

1. **Per-pixel custom logic / parametric shaders.** No way to write arbitrary fragment programs. You get the menu of recipes; you cannot author new ones. If the desired depth-feel requires a hand-tuned shader (e.g., chromatic-aberration falloff coupled with vignette and Perlin noise), Metal / `CIFilter` (or `MTLBinaryArchive` shaders via `SCNTechnique`/CAMetalLayer) is required.
2. **Interpolating colorMatrix struct natively.** CABasicAnimation cannot animate the 20-float `inputColorMatrix` struct as a single curve — must drive via display link or use convenience saturate/brightness/contrast filters which DO animate.
3. **True depth/perspective (z-aware) blur.** No depth-of-field with per-pixel-depth weighting. CAFilter blurs are 2D image-space only. Requires Metal + a depth texture (typically from SceneKit/RealityKit) for true DoF.
4. **Mask interpolation for variableBlur.** `inputMaskImage` can be swapped but not tweened — must re-render the mask per frame for smooth focus pulls, or use a Metal compute pass to interpolate.
5. **Per-region distinct recipes.** Cannot say "this rect uses gaussianBlur radius=20, this rect uses radius=5." Single recipe set applies to entire layer. Requires sibling layers or Metal compositing.
6. **Cross-layer photo-realistic refraction / lensing.** No glass-bending, chromatic dispersion, caustics. Requires Metal shader or RealityKit material.

The decision tree: stay in CAFilter for parametric blur + color + vibrancy depth reveals; cross into Metal/CoreImage only when (a) interpolating mask spatial maps smoothly, (b) needing depth-of-field with a real depth source, or (c) authoring effects beyond Apple's recipe menu.
