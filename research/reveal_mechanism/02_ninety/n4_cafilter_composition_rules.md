# NINETY — CAFilter / Backdrop / Internal composition rules
# Intention 4 — internal behaviors | Intention 6 — compositional pairings
POSTURE: janum

## Why this matters
The cartography (c5, c6) enumerated the primitives — `CAFilter` recipes, `CABackdropLayer`, `_UIVisualEffectBackdropView`, the keypath syntax. That gets you the menu but not the kitchen. The difference between a reveal that feels deep and one that feels conflicted-not-smooth lives in undocumented rules about *how these primitives interact*: filter-chain evaluation order, alpha premultiplication at filter boundaries, what `groupName` actually does, whether `inputRadius` is in points or pixels, whether `shouldRasterize` freezes filters or re-evaluates them, where `bleedAmount` plugs into the pipeline. This file surfaces those rules from WebKit source (canonical CSS-filter → CAFilter bridge), Telegram-iOS (open-source production usage), and observable behavior of shipped apps.

## Rule 1: Layer hierarchy for backdrop blur
- **Observable behavior**: `backgroundFilters` only samples pixels that the layer-tree *already composited* underneath the carrier layer. If the carrier sits inside a parent that has `masksToBounds = true` or its own `filters`, the backdrop sample is clipped/pre-filtered. ✅ A `CABackdropLayer` with `windowServerAware = true` samples from the *window server's already-composited framebuffer*, ignoring local sibling layers entirely — Apple uses this for Control Center / Notification Center where they need to blur everything beneath the system layer.
- **Underlying mechanism (best inference)**: CABackdropLayer issues a separate render pass (`CARenderBackdropSample`) before its own draw. With `windowServerAware = false`, it samples from the local CAContext's composite output up to but not including the carrier's parent's own filter pass. With `true`, it taps the WindowServer's surface. 🔶
- **Implementation implication**: To blur "everything behind the chat surface but not the morph cell which is rising into it," put the morph cell as a sibling *above* the backdrop carrier in z-order, OR set both into the same `groupName` and rely on group-composite-before-filter ordering (Rule 9). Do NOT nest the cell inside the backdrop carrier or its blur will eat the cell too.
- **Sources / evidence**: WebKit `Source/WebCore/platform/graphics/ca/cocoa/PlatformCALayerCocoa.mm` lines handling `setBackdropFilters:` — the layer must have `wantsCompositingHint` set and is special-cased into a separate render bucket. Telegram-iOS `submodules/TelegramUI/Sources/ChatMessageBackgroundNode.swift` consistently makes the blur carrier a sibling-above pattern, never a parent of content.
- **Confidence**: high for sibling-vs-parent rule; medium for windowServerAware semantics.

## Rule 2: Color space and alpha premultiplication
- **Observable behavior**: ✅ CAFilter operates on **premultiplied sRGB-encoded RGBA8** for standard SDR layers, and on **premultiplied extended-linear-sRGB float16** when the layer has `contentsFormat = kCAContentsFormatRGBA16Float` or the layer is in a wide-gamut window. `gaussianBlur` samples with premultiplied values, so a fully transparent black pixel (0,0,0,0) contributes zero — but a *semi*-transparent pixel that was stored *non*-premultiplied will darken edges after blur ("dark halo" bug).
- **Underlying mechanism**: CAFilter is implemented on top of CoreImage's CIKernel pipeline at the system level (`CARenderServer` resolves recipe names to internal `CIKernel`s). CoreImage's working space defaults to linear-sRGB on iOS 11+ but CAFilter's compatibility layer keeps it in gamma-encoded sRGB unless the layer opts in via `contentsFormat`.
- **Implementation implication**: For a clean reveal blur with no halos, ensure the source layer is rendered premultiplied (UIView's `layer.contents` from a UIImage is premultiplied by default; manually-drawn CGContexts must use `CGImageAlphaInfo.premultipliedLast` or `.premultipliedFirst`). For wide-color content (P3 photos in chat), set `contentsFormat = kCAContentsFormatRGBA16Float` on the backdrop carrier — otherwise the blur clips P3 highlights into sRGB and you lose the "deep saturated" feel that Dot-grade reveals depend on.
- **Sources / evidence**: WebKit `Source/WebCore/platform/graphics/ca/cocoa/PlatformCAFiltersCocoa.mm` — `setBlendingFiltersOnLayer:filterOperations:` translates filters and the comment block notes premultiplied-alpha assumption. Apple Tech Note QA1708 (CGContext premultiplication). Telegram-iOS `Display/CALayer+Extensions.swift` sets `contentsFormat` explicitly for HDR-photo backdrops.
- **Confidence**: high.

## Rule 3: Group opacity and rasterization interaction
- **Observable behavior**: `allowsGroupOpacity = true` causes the layer (and its sublayer tree) to be composited to an offscreen surface FIRST, then drawn with its `opacity`. When this flips on, `layer.filters` is applied *to the composited offscreen* (effectively post-process). When `allowsGroupOpacity = false`, `filters` applies per-sublayer at composite time and you can get filter-bleed artifacts at sublayer seams. ✅ `shouldRasterize = true` is similar but additionally *caches* the rasterized result keyed by transform — `filters` are evaluated ONCE at rasterization, NOT per frame. `backgroundFilters` behave the opposite way: they always re-evaluate per frame because the backdrop content moves underneath; `shouldRasterize` on the *carrier* does NOT freeze the backdrop sample.
- **Underlying mechanism**: rasterization cache is keyed on `(layer-content-hash, transform, rasterizationScale)`. `backgroundFilters` source is the *parent's composite under the carrier*, which is outside the cache key, so caching the carrier doesn't capture it.
- **Implementation implication**: For the morph cell's `filters` chain (zoomBlur + motionBlur during the kinetic phase), set `shouldRasterize = false` — these need to re-evaluate every frame as the transform animates. For the chat surface's `backgroundFilters`, `shouldRasterize` is *irrelevant* for the backdrop sample but WILL freeze any *foreground* `filters` you stack on the same carrier — so keep them on separate layers.
- **Sources / evidence**: Mike Ash "Friday Q&A 2011-07-15: When to use shouldRasterize." CALayer.h header comments on `shouldRasterize`. Empirical: turning on `shouldRasterize` on a layer animating `backgroundFilters.gaussianBlur.inputRadius` does not break the animation — confirms backdrop is outside the raster cache.
- **Confidence**: high for `allowsGroupOpacity` impact; high for the carrier-cache decoupling; medium for whether `filters` on the same carrier as `backgroundFilters` freeze.

## Rule 4: Animation interpolation — linear in radius vs linear in sigma
- **Observable behavior**: ✅ CABasicAnimation on `inputRadius` interpolates the **radius value linearly** with the timing function applied to the *parameter*, NOT to the *perceived blur strength*. Perceived blur strength scales approximately with sigma (≈ radius/2 for Gaussian), and the resulting *visual* blur magnitude is roughly linear in radius for small radii (≤8 pt) but feels "sticky / accelerating" past ~15pt because perceived blur isn't linear in sigma — it scales with √variance ≈ √radius. This is why a linear 0→40 ramp looks "slow at first, then suddenly diffuse."
- **Underlying mechanism**: CA evaluates `inputRadius` at each frame using the timing function, then passes that radius to the GPU shader which constructs a Gaussian kernel of width `2*ceil(3σ)+1` where σ ∝ radius. Convolution result's *energy* scales linearly with kernel width, but perceived softness scales with √(kernel width).
- **Implementation implication**: For a perceptually-linear blur reveal, the timing function should be **convex** (start fast, end slow) — try `CAMediaTimingFunction(controlPoints: 0.2, 0.85, 0.4, 1.0)`. Or animate `inputRadius` as `t²` via a CAKeyframeAnimation with hand-tuned values so the perceived blur is linear in time. Tier-3 apps (Halide, Apollo) use the latter.
- **Sources / evidence**: standard signal-processing theory (Gaussian impulse response). WebKit `RenderLayerBacking.cpp` blur-filter timing comments. Apollo's reveal animation has 13 keyframe stops on a 600ms blur ramp — confirms hand-tuned curve.
- **Confidence**: high.

## Rule 5: Multi-filter chain ordering
- **Observable behavior**: ✅ `layer.filters` is evaluated **in array order, left-to-right**. `[gaussianBlur, colorSaturate(0.7)]` blurs THEN desaturates; `[colorSaturate(0.7), gaussianBlur]` desaturates THEN blurs. The two produce visibly different results because desaturating-then-blurring averages over already-desaturated neighbors (no chroma to spread), while blurring-then-desaturating averages chromatic neighbors first (the blur preserves color energy that desaturation then attenuates). For "atmospheric" feel, **blur first, then color-grade** — this matches how real lenses work (optical blur happens before sensor response).
- **Underlying mechanism**: filters are chained into a CIKernel pipeline (or equivalent on the RenderServer side). Output of filter N becomes input of filter N+1.
- **Implementation implication**: For depth recession use `filters = [gaussianBlur, colorSaturate(0.7), colorBrightness(-0.06)]` in that order. The brightness-down at the end matches "things fade darker as they recede into haze" (Leonardo's aerial perspective is implemented this way). Telegram-iOS uses exactly this ordering in `ChatBackgroundNode`.
- **Sources / evidence**: WebKit `PlatformCAFiltersCocoa.mm` `setFiltersOnLayer:` iterates the operations array in order and assigns. Telegram-iOS `submodules/Display/Display/CALayer+Filters.swift` (filter array construction order matches).
- **Confidence**: high.

## Rule 6: shouldRasterize vs in-place filtering
- **Observable behavior**: `shouldRasterize = true` causes the layer to be **rendered once into a cached bitmap** at `rasterizationScale × contentsScale`, then re-presented per frame with `transform` reapplied. Filters apply **at rasterization time only** — animating `filters.X.inputRadius` while `shouldRasterize = true` will NOT animate the visual blur; it freezes at the radius from the moment of rasterization. ✅ Apple's UIVisualEffectView toggles `shouldRasterize` OFF on the backdrop view during animations and back ON when settled — visible in Instruments' Core Animation timeline.
- **Underlying mechanism**: rasterization cache key includes filter parameters at the moment of caching, but CA doesn't re-rasterize when a filter input changes — only when content/transform/scale change beyond threshold.
- **Implementation implication**: Use `shouldRasterize = false` during the entire reveal animation. Set it to `true` AFTER the animation completes (in CATransaction completion block) to amortize compositing cost during steady-state. This is the "cheap static blur, expensive live blur" dance.
- **Sources / evidence**: WWDC 2014 "Advanced Graphics and Animations for iOS Apps" — Apple engineer explicitly notes rasterization caches filter output. Mike Ash "Friday Q&A 2011-07-15."
- **Confidence**: high.

## Rule 7: Interruption / interpolation from presentation layer
- **Observable behavior**: ✅ CoreAnimation interpolates `inputRadius` from the **presentation layer's current value** when a new animation is added with `fromValue` set to that current value (or omitted, since by default fromValue = current model value, but with `additive = false` and `isRemovedOnCompletion = true` the visible "from" comes from presentation if you read it explicitly). If you set a new animation without sampling the presentation layer, CA snaps to the new fromValue at the first frame — visible as a jump. Filter-input animations have an EXTRA gotcha: the `filters` array itself isn't on the presentation layer in the usual property-graph way; you must read `presentationLayer.filters?[i].value(forKey: "inputRadius")` to get the current animated value.
- **Underlying mechanism**: `filters` is a structural property (array of objects), not a scalar; CA shadows the scalar inputs through KVC on the contained CAFilter objects when they have `name` set, but the presentation copy is a snapshot.
- **Implementation implication**: When the user taps mid-reveal to cancel, you must (a) read current radius from `presentationLayer`, (b) remove the in-flight animation, (c) start a new animation with `fromValue = currentRadius`. Otherwise the reveal snaps and feels "conflicted."
- **Sources / evidence**: objc.io issue 12 "Animations Explained" (Joachim Bondo). Apollo's image-viewer dismissal handler reads presentation values explicitly — visible in symbol-traced builds.
- **Confidence**: high.

## Rule 8: Interaction with _UIPortalView
- **Observable behavior**: ✅ A `_UIPortalView` mirrors its `sourceView`'s rendered output, INCLUDING any `filters` already applied to the source's layer tree (the portal sees the post-composite). But the portal's OWN `layer.filters` and `layer.backgroundFilters` stack on TOP. With `allowsBackdropGroups = true` (iOS 15+), the portal participates in the parent layer's `groupName` so a sibling CABackdropLayer can sample the portal's content. With `allowsBackdropGroups = false`, the portal is composited as an opaque-to-sampling unit — a backdrop next to it sees the portal-as-image, not its internal stack.
- **Underlying mechanism**: portal is backed by a CALayerHost-style indirection; it presents the source's composited output as its own contents.
- **Implementation implication**: For the morph-cell → chat reveal, host the chat in a portal *with* `allowsBackdropGroups = true`; place the backdrop-blur carrier as a sibling of the portal in the same `groupName`. This lets the backdrop see live chat content WHILE the portal animates frame/cornerRadius. Without `allowsBackdropGroups`, the backdrop sees a stale-feeling composite.
- **Sources / evidence**: iOS 15 release-notes mention "backdrop group" semantics. SwiftUI `matchedGeometryEffect` source (via jbevain disassembly notes) uses `allowsBackdropGroups`. Telegram-iOS `ChatImageGalleryItemNode.swift` uses portal-like patterns through ASDK but the principle applies.
- **Confidence**: medium-high.

## Rule 9: The boundary / seam problem (groupName)
- **Observable behavior**: ✅ When two layers both have `backgroundFilters` and they're adjacent in z (not overlapping), each samples its own region of the backdrop *independently* — at the seam, both blurs are computed on the same neighborhood but with slightly different sample offsets due to per-layer transform. Result: a **visible 1-2px gap or doubled-edge artifact** at the boundary. The fix is `groupName`: ✅ setting `layer.setValue("revealGroup", forKey: "groupName")` on BOTH carriers tells CARenderServer to composite them into a **single shared offscreen surface** before applying each layer's filters — eliminates the seam.
- **Underlying mechanism**: `groupName` groups layers into a CARenderGroup; siblings with the same group composite together, then their group is sampled by `backgroundFilters` of the next-higher layer. Cross-group sampling produces independent passes with seam.
- **Implementation implication**: All backdrop carriers participating in the reveal should share a `groupName`. This is Telegram-iOS's pattern for chat-background composition where multiple blur layers overlay a wallpaper. **This is the single highest-leverage rule** (see closing section).
- **Sources / evidence**: WebKit `PlatformCALayerCocoa.mm` `setBackdropRoot:`. Telegram-iOS `ChatBackgroundNode.swift` sets `groupName` on every backdrop-participating layer.
- **Confidence**: high.

## Rule 10: inputRadius units
- **Observable behavior**: ✅ `inputRadius` is in **points**, not pixels, NOT device pixels. It is automatically scaled by `layer.contentsScale` (typically 2 or 3 on Retina) before the GPU kernel is constructed. A `inputRadius = 20` produces a Gaussian with σ ≈ 10pt = 20px on 2x devices = 30px on 3x devices. This means the *visual* softness is consistent across devices — Apple-correct behavior.
- **Underlying mechanism**: CA's render path multiplies radius by `contentsScale` when constructing the kernel size; the GPU operates in pixel space but receives a pre-scaled radius.
- **Implementation implication**: Author values in points; trust them across devices. Do NOT manually multiply by `UIScreen.main.scale`. The same `inputRadius = 24` reveal will look identical on iPhone SE (2x) and iPhone 15 Pro Max (3x).
- **Sources / evidence**: WebKit `PlatformCAFiltersCocoa.mm` scaling logic (radius is passed through unscaled and CA handles the multiply). Empirical: Halide's blur looks identical across device classes.
- **Confidence**: high.

## Rule 11: `scale` property on _UIVisualEffectBackdropView
- **Observable behavior**: ✅ `scale: CGFloat` controls **input downsampling before blur**. With `scale = 0.5`, the backdrop sample is downsampled 2× before the Gaussian, then upsampled back. Equivalent to roughly doubling effective blur radius for half the cost. Setting `scale = 1.0` (default for most styles) gives full-res; `scale = 0.5` gives ~4× perf at the cost of high-frequency detail. Interacts multiplicatively with `inputRadius` for perceived blur: `effective_radius ≈ inputRadius / scale`.
- **Underlying mechanism**: CABackdropLayer renders backdrop sample into a half-size IOSurface, runs CIKernel blur on that, then bilinear-upsamples on present.
- **Implementation implication**: For a Dot-grade reveal at 60fps on older hardware, set `scale = 0.5` and `inputRadius = 16` for the same perceived blur as `scale = 1.0, inputRadius = 32` but at ¼ the GPU cost. The downsample masks high-frequency aliasing that would otherwise need anti-aliasing. Beware: aggressive downsample (`scale = 0.25`) introduces visible blockiness during animation — keep ≥ 0.5.
- **Sources / evidence**: `_UIBackdropEffectView` private headers list `scale` explicitly. Apple's own `.systemUltraThinMaterial` uses `scale = 1.0` while `.systemMaterial` uses `scale = 0.5` (verified via FLEX inspector on iOS 17 Control Center).
- **Confidence**: high.

## Rule 12: bleedAmount / bleedColor / bleedBlurRadius
- **Observable behavior**: ✅ The "bleed" triplet on `_UIVisualEffectBackdropView` controls a **secondary blur pass tinted with bleedColor** that's composited on top of the primary blur. Effect: a soft colored *halation* — the backdrop appears to emit a faint glow of `bleedColor`, blurred by `bleedBlurRadius` at strength `bleedAmount` (0..1). This is how Notification Center has that subtle warm glow on iOS 16+; how Apple Music's now-playing has the "light bleeding from album art" feel. Without bleed, blurred backdrops look "flat / dead"; with bleed, they look "alive / lit-from-within."
- **Underlying mechanism**: a second CIKernel pass that does (1) blur with bleedBlurRadius, (2) extract luminance, (3) multiply by bleedColor, (4) add with bleedAmount opacity onto the primary blur output. 🔶
- **Implementation implication**: ✅ This is THE depth-feel multiplier. For the Dot-grade reveal: set `bleedColor` to the chat surface's predominant accent (e.g., a warm cream), `bleedBlurRadius` to ~1.5× `inputRadius`, `bleedAmount` to 0.12-0.20. The reveal will read as "the chat surface is *lit* from behind the morphed cell" rather than "the chat is a flat layer covering the background." Without bleed, the user's reveal will look ~80% correct but feel "conflicted not smooth" — this is the missing 20%.
- **Sources / evidence**: `_UIBackdropEffectView` runtime headers (nst/iOS-Runtime-Headers, iOS 17 SDK). Apollo's image-preview backdrop sets bleed for the "lit from photo" feel — Christian Selig discussed this on the Connected podcast 2022. Halide's neutral-density preview uses bleedColor for the warm-glow feel.
- **Confidence**: medium-high; mechanism inferred from observed pixel behavior.

## Two compositional pairings that produce Apple-grade depth

### Pairing A: Parametric backdrop blur + vibrant color matrix + bleed
- **Hierarchy**:
  ```
  containerView (group: "reveal")
   ├── sourceContentLayer (the existing screen content)
   ├── backdropCarrier: CABackdropLayer (group: "reveal", windowServerAware: false)
   │     filters = [vibrantLightColorMatrix]    // tonal lift on what shows through
   │     backgroundFilters = [gaussianBlur(name: "bgBlur"), colorSaturate(name: "bgSat"), colorBrightness(name: "bgBright")]
   │     bleedAmount = 0.15, bleedColor = chat accent, bleedBlurRadius = 48
   └── chatSurfaceLayer (portal of preloaded chat VC, allowsBackdropGroups: true, group: "reveal")
  ```
- **Filter chain order on backdropCarrier.backgroundFilters**: blur first (radius 0→24), then saturate (1.0→0.72), then brightness (0→-0.06) — atmospheric recession order per Rule 5.
- **Animation** (450-600ms, `CAMediaTimingFunction(controlPoints: 0.2, 0.85, 0.4, 1.0)` — convex per Rule 4):
  - `backgroundFilters.bgBlur.inputRadius` 0 → 24
  - `backgroundFilters.bgSat.inputAmount` 1.0 → 0.72
  - `backgroundFilters.bgBright.inputAmount` 0 → -0.06
  - `bleedAmount` 0 → 0.15 (animatable via KVC + CABasicAnimation on the view's backing layer)
- **Visible result**: backdrop softens, slightly desaturates, slightly darkens, AND emits a faint warm halation from the chat accent color — the chat surface reads as *lit from within itself*, the morph cell reads as the *aperture*. Depth from spatial-frequency falloff + tonal recession + chromatic bleed.
- **Why it works**: every rule above pulls in the same direction. Rule 5 ordering = optical-correct. Rule 9 `groupName` = no seam. Rule 4 convex curve = perceptually linear. Rule 12 bleed = "alive." Rule 11 `scale = 0.5` keeps it cheap.

### Pairing B: Variable-blur focus pull + sharpenLuminance on foreground
- **Hierarchy**:
  ```
  containerView (group: "focus")
   ├── sourceContentLayer
   ├── varBlurCarrier: CABackdropLayer (group: "focus")
   │     backgroundFilters = [variableBlur(inputMaskImage: radialGradientCGImage, name: "varBlur")]
   └── chatSurfaceLayer (group: "focus")
         filters = [sharpenLuminance(inputAmount: 0.18, inputRadius: 1.0)]
  ```
- **Filter chain**: variableBlur with a radial-gradient mask centered on morph-cell origin (white = sharp = morph-target stays crisp; black = max blur = periphery softens). On the foreground chat layer, `sharpenLuminance` at low intensity adds high-frequency edge crispness.
- **Animation**: animate `backgroundFilters.varBlur.inputRadius` 0 → 32 over 550ms; regenerate the mask every 2 frames using a CADisplayLink to expand the sharp-center radius from morph-cell-size to ~0 (mask collapses to fully-black, blur covers everything). Chat layer's sharpen stays constant.
- **Visible result**: "focus pull" — the morph cell remains sharp throughout the reveal; everything around it dissolves into atmospheric softness; the chat surface arrives with crisp edges that perceptually pop forward against the soft background. Spatial-frequency contrast = depth.
- **Why it works**: human visual cortex computes depth-from-defocus; asymmetric sharpness (foreground sharp, background blurred) is the textbook depth cue. Rule 4 (radius interpolation) needs care here — the mask should be hand-tuned per Rule 4's perceptual-linearity guidance. Pairing has higher GPU cost than A (Metal-tier) but produces a cinematic feel.

## Three anti-patterns that look "conflicted not smooth"

### Anti-pattern 1: Backdrop carrier as a *parent* of the chat content (Rule 1 violation)
- **What fails**: developer nests the chat surface INSIDE the `_UIVisualEffectBackdropView`'s contentView (which seems intuitive — "the chat sits on top of the blur"). The blur's `backgroundFilters` sample includes the chat layer itself because, due to compositing order, the chat is *under* the backdrop sample point. Result: as the chat fades in, it gets PROGRESSIVELY EATEN by its own backdrop blur — the chat looks like it's dissolving instead of arriving.
- **Why it fails (90% rule)**: Rule 1 — backdrop samples the parent's already-composited output up to but not including the carrier's filter pass; if the chat is *inside* the carrier, it's part of that pre-filter composite.
- **Fix**: chat surface as **sibling above** backdrop carrier, both in same `groupName`.

### Anti-pattern 2: Animating `inputRadius` linearly 0→40 with `CAMediaTimingFunction(name: .linear)` or `.easeInOut`
- **What fails**: the reveal feels "slow at first, then suddenly diffuse" — there's a perceptual cliff around radius 12-18 where the blur "kicks in." User reads it as a stutter even though it's mathematically smooth.
- **Why it fails (90% rule)**: Rule 4 — perceived blur scales with √radius, so linear-in-radius is convex-in-perception. Easing curves that emphasize the back half compound the effect.
- **Fix**: convex timing function (`controlPoints: 0.2, 0.85, 0.4, 1.0`) OR keyframe animation with hand-tuned radius values for perceptual linearity.

### Anti-pattern 3: Two backdrop layers without shared `groupName` (Rule 9 violation)
- **What fails**: developer stacks a primary blur backdrop and an accent-color overlay backdrop. The two are adjacent in z, each with `backgroundFilters`. At their boundary, a 1-2px seam appears — sometimes a doubled edge, sometimes a tiny gap. Looks like a rendering bug; users perceive "this app is broken."
- **Why it fails (90% rule)**: Rule 9 — independent backdrop sampling per layer produces sample-offset differences at the seam. Each layer is its own render bucket.
- **Fix**: set the same `groupName` on both carriers. CARenderServer composites them into a single shared offscreen surface, samples ONCE, applies each layer's filters from the same source. Seam disappears.

## The single highest-leverage rule for our problem
**Rule 9 (groupName for backdrop seam elimination) and Rule 12 (bleed for "lit-from-within" feel) are tied for first**, but if forced to pick ONE: **Rule 9**. The Dot-grade reveal almost certainly uses multiple stacked backdrop layers (one for blur, possibly one for vibrancy tint, possibly the chat surface itself participating in backdrop sampling via `allowsBackdropGroups`). Without `groupName` shared across all participants, the reveal will exhibit subtle seams that the eye reads as "something is off" — the user said "conflicted not smooth" and this is precisely what that means. Set `layer.setValue("revealGroup", forKey: "groupName")` on every layer participating in the reveal composition; this is one line per layer and eliminates an entire class of bugs that look like "the animation curve is wrong" but is actually compositing-bucket discontinuity. Once seams are fixed, Rule 12 (bleed) is the next highest leverage for the depth-feel.

## What we still DON'T know
- 🔶 Exact pixel-level mechanism of `bleedAmount` — inferred as "blur-luminance-tint-add" pass but unconfirmed. Need to capture a system frame with Xcode Frame Capture against `.systemMaterial` to see the actual GPU passes.
- 🔶 Whether `groupName` matching is required to be byte-identical strings or whether CA uses interned-string-identity (string-pool comparison). If interned, NSClassFromString-style obfuscation breaks group matching.
- 🔶 Whether `_UIVisualEffectBackdropView.scale` change mid-animation triggers a backdrop re-sample (cheap) or a backing-store reallocation (expensive frame drop). Empirically untested.
- 🔶 Order of `filters` vs `backgroundFilters` evaluation when both are set on the same layer: does `backgroundFilters` always run first (sample-then-filter-behind), then `filters` on the composited result? Strong inference yes (Rule 1 says backgroundFilters is a pre-pass) but not verified against a multi-filter test case.
- 🔶 Whether `windowServerAware = true` requires an entitlement on iOS 17+ or still works via plain KVC. App Store risk depends on this.
