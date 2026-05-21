# CARTOGRAPHY — Middle of 10% — Metal / MetalKit / MPS / MetalFX
# Domain: reveal mechanism (morph-end → chat surface with depth)
POSTURE: janum

Scope reminder: COMPOSITING and POST-PROCESSING for a fullscreen reveal, not 3D scene rendering. Every primitive below is scored against one question: can it contribute pixels CoreAnimation cannot produce, during the ~400–700ms reveal window?

---

## Drawable & layer-binding primitives

### CAMetalLayer — QuartzCore, iOS 8+
- What: CALayer subclass that vends `CAMetalDrawable` (a presentable `MTLTexture`).
- Documented in: https://developer.apple.com/documentation/quartzcore/cametallayer ; WWDC14 "Working with Metal: Fundamentals"; WWDC21 #10136 "Discover Metal debugging, profiling, and asset creation tools".
- Undocumented aspects: tuning `maximumDrawableCount` (2 vs 3) for transition latency; interaction of `presentsWithTransaction` with UIKit `CATransaction` commits during a push; behavior when layer is composited above other CALayers with `allowsGroupOpacity`.
- Experimentation cost: 2–4 hours to wire, half a day to characterise dropped frames around a UIKit push.
- Reveal-relevance: the substrate. Lets us paint a single fullscreen quad with a shader that no CALayer chain can match.
- UIKit integration cost: low — override `+layerClass` on a `UIView` subclass.
- Limitation: `framebufferOnly = true` (default) blocks readback; once set to `false` you pay memory cost. Sub-CALayer compositing of UIKit content ON TOP of the Metal layer is fine; UIKit content UNDER it requires the Metal output to be premultiplied + non-opaque (`isOpaque = false`, `pixelFormat = .bgra8Unorm` or wider).

### CAMetalDisplayLink — QuartzCore, iOS 17+
- What: display-synced callback that hands you a `CAMetalDrawable` already acquired for the next vsync.
- Documented in: https://developer.apple.com/documentation/quartzcore/cametaldisplaylink ; WWDC23 #10123 "Bring your game to Mac, Part 2: Compile your shaders".
- Undocumented aspects: how its `preferredFrameRateRange` cooperates with ProMotion ramps mid-transition; whether it competes with `UIView` animation server for the same vsync slot.
- Experimentation cost: 1 day to validate vs plain `CADisplayLink` driving manual `nextDrawable()`.
- Reveal-relevance: removes the `nextDrawable` stall that historically caused frame hitches at transition start.
- UIKit integration cost: low.
- Limitation: iOS 17+ only — need fallback path for iOS 17.0 below (this project is iOS 17+, OK).

### MTKView — MetalKit, iOS 9+
- What: turn-key `UIView` wrapping `CAMetalLayer` with a delegate render loop.
- Documented in: https://developer.apple.com/documentation/metalkit/mtkview
- Undocumented aspects: `isPaused` + `enableSetNeedsDisplay` interaction during gesture-driven scrubbing of a reveal; behavior of `framebufferOnly` toggles between draws.
- Experimentation cost: <1 hour to stand up.
- Reveal-relevance: fastest path to first pixels; but adds a `UIView` to the hierarchy you may not want during a transition.
- UIKit integration cost: low.
- Limitation: opinionated about its render loop; awkward when the reveal is event-driven (touch, animation curve) rather than continuous. Prefer raw `CAMetalLayer` for transitions.

### Path 3: snapshot pattern — render to `MTLTexture`, set as `CALayer.contents`
- What: render a single still frame to an offscreen texture, wrap via `IOSurface`, hand to CA as `contents`.
- Documented in: https://developer.apple.com/documentation/iosurface ; CALayer `contents` accepts `CGImage` only publicly — `IOSurface`-backed path is via `CAMetalLayer` or via `CVPixelBuffer` → `CGImage` bridge.
- Undocumented aspects: 🔶 whether assigning an `IOSurface`-backed `CVPixelBuffer` directly to `CALayer.contents` is honoured on iOS (it is on macOS; iOS behavior is folklore — needs verification).
- Experimentation cost: half a day.
- Reveal-relevance: hybrid pattern — pre-bake an atmospheric "behind" layer once at reveal start, then animate cheap CA properties on top. Avoids running Metal for the full transition.
- UIKit integration cost: moderate.
- Limitation: static; cannot express time-varying shader effects across the reveal.

### SwiftUI `.drawingGroup()` — SwiftUI, iOS 13+
- What: forces a subtree to render offscreen via Metal (Core Animation `shouldRasterize` on steroids), enabling blend modes and filters that CA composition won't honour.
- Documented in: https://developer.apple.com/documentation/swiftui/view/drawinggroup(opaque:colormode:)
- Undocumented aspects: which underlying compositor is used (Metal vs CoreImage); whether `colorMode: .extendedLinear` engages wide-gamut compositing.
- Experimentation cost: 1 hour.
- Reveal-relevance: low for this project (UIKit substrate) — note only as escape hatch.
- UIKit integration cost: high (requires SwiftUI host).
- Limitation: no shader injection; you get SwiftUI's predefined effects only.

---

## Render & compute encoders

### MTLRenderCommandEncoder — fullscreen quad pass — Metal, iOS 8+
- What: encode draw calls for a 2-triangle fullscreen quad with a fragment shader that does the reveal compositing.
- Documented in: https://developer.apple.com/documentation/metal/mtlrendercommandencoder ; WWDC20 #10602 "Optimize Metal Performance for Apple silicon Macs".
- Undocumented aspects: when Apple's tile-based deferred renderer (TBDR) fuses multiple fullscreen passes into one tile pass vs spilling to memory; load/store action choices that prevent unnecessary tile flushes.
- Experimentation cost: 1 day for a clean two-pass (blur + composite) reveal.
- Reveal-relevance: the workhorse. Single fragment shader = full creative control.
- UIKit integration cost: low (once CAMetalLayer is wired).
- Limitation: cost of touching every pixel at 120Hz on Pro devices is real but small for a 2-second transition.

### MTLComputeCommandEncoder — Metal, iOS 8+
- What: dispatch threadgroups against textures for image-to-image transforms outside the rasterizer.
- Documented in: https://developer.apple.com/documentation/metal/mtlcomputecommandencoder
- Undocumented aspects: threadgroup size sweet-spots per Apple GPU family for fullscreen ops (32×32 typical, 16×16 sometimes wins on A17+).
- Experimentation cost: 1 day.
- Reveal-relevance: preferred for separable blurs, downsamples, mipmap pyramid builds — atmospheric depth scaffolding.
- UIKit integration cost: low.
- Limitation: more verbose than MPS; redundant when MPS has the kernel you need.

### MTLBlendMode / MTLRenderPipelineColorAttachmentDescriptor — Metal, iOS 8+
- What: blend equations on the pipeline state (sourceRGB/destRGB factors, separate alpha).
- Documented in: https://developer.apple.com/documentation/metal/mtlrenderpipelinecolorattachmentdescriptor
- Undocumented aspects: behavior with `bgra10_xr` and EDR targets — whether blending happens in extended-linear space.
- Experimentation cost: a few hours.
- Reveal-relevance: enables additive bloom layers, screen-blend lift, premultiplied composite with explicit alpha math impossible in CoreAnimation.
- UIKit integration cost: low.
- Limitation: still a fixed-function blend equation; non-linear blends require fragment-shader compositing.

### MTLDepthStencilState — Metal, iOS 8+
- What: depth/stencil test config.
- Reveal-relevance: low. Useful only if you treat the reveal as layered 3D planes — possible but heavyweight for 2D compositing.
- Limitation: requires depth attachment, threads work into a 3D framing the rest of UIKit isn't.

---

## MetalPerformanceShaders (MPS) — image kernels

### MPSImageGaussianBlur — MPS, iOS 9+
- What: optimized separable Gaussian.
- Documented in: https://developer.apple.com/documentation/metalperformanceshaders/mpsimagegaussianblur
- Undocumented aspects: how `sigma` maps to internal kernel radius (Apple clamps for performance — extremely large sigmas saturate).
- Experimentation cost: <1 hour.
- Reveal-relevance: core atmospheric primitive. **Animated sigma per frame** is fine — recreate the kernel each frame or keep a pool.
- UIKit integration cost: low.
- Limitation: cannot vary sigma per pixel; for that you need MPSImageGaussianPyramid + shader-side lerp.

### MPSImageGaussianPyramid — MPS, iOS 10+
- What: builds multi-level mipmap of Gaussian-blurred copies of source.
- Documented in: https://developer.apple.com/documentation/metalperformanceshaders/mpsimagegaussianpyramid
- Reveal-relevance: HIGH. Per-pixel depth-of-field by sampling pyramid level driven by a "depth" mask = atmospheric perspective for free. This is likely how Procreate gallery dissolves achieve their soft-falloff feel.
- UIKit integration cost: low.
- Limitation: discrete levels — need shader-side trilinear interpolation between two levels for smoothness.

### MPSImageTent / MPSImageBox — MPS, iOS 9+
- What: cheaper box/tent blurs (constant time vs radius).
- Reveal-relevance: useful for the wide-radius outer haze where Gaussian quality is wasted.

### MPSImageBilateralFilter — MPS, iOS 11.3+
- What: edge-preserving smoothing.
- Documented in: https://developer.apple.com/documentation/metalperformanceshaders/mpsimagebilateralfilter
- Reveal-relevance: 🔶 moderate — could be used to soften the chat-surface backdrop while preserving high-frequency type that's becoming visible. More relevant when revealing typographic content beneath.

### MPSImageMorphology (Dilate / Erode) — MPS, iOS 9+
- What: morphological ops on a mask.
- Documented in: https://developer.apple.com/documentation/metalperformanceshaders/mpsimagedilate
- Reveal-relevance: dilating the radial reveal mask before blurring it produces softer, more organic edges than blurring alone — the "halo" feel.
- Limitation: structuring element is fixed per dispatch.

### MPSImageConvolution / Sobel / Laplacian — MPS, iOS 9+
- What: arbitrary 2D convolution, edge detectors.
- Reveal-relevance: Sobel of the source can drive a rim-light pass; arbitrary convolution lets you implement custom kernels (e.g., chromatic-aberration-style 3-tap with per-channel offsets).

### MPSImageThresholdBinary / ThresholdToZero — MPS, iOS 9+
- What: pixel-wise threshold ops.
- Reveal-relevance: low directly; used to build masks from luminance for bloom seed.

### MPSImageReduceColumnMax / RowMax — MPS, iOS 11.3+
- What: row/column max reductions.
- Reveal-relevance: low for compositing.

### MPSImageHistogramEqualization — MPS, iOS 9+
- Reveal-relevance: low; mentioning only to dismiss — wrong tool here.

---

## MetalFX

### MTLFXSpatialScaler / MTLFXTemporalScaler — MetalFX, iOS 16+
- What: ML-assisted spatial/temporal upscalers.
- Documented in: https://developer.apple.com/documentation/metalfx ; WWDC22 #10103 "Boost performance with MetalFX Upscaling".
- Undocumented aspects: behavior when input/output sizes match (degenerate identity case); whether it can act as a denoiser on noise-textured composites.
- Experimentation cost: 1 day.
- Reveal-relevance: low-direct. Niche use: render the heavy effect pass at 0.5× and upscale temporally — extra headroom for richer shaders on older devices. Not a reveal primitive in itself.
- Limitation: temporal scaler wants motion vectors — synthetic for a 2D reveal; spatial scaler is the realistic choice.

---

## Resource & sharing primitives

### MTLHeap (transient) — Metal, iOS 10+
- What: pre-allocated pool of transient textures/buffers.
- Documented in: https://developer.apple.com/documentation/metal/mtlheap
- Reveal-relevance: allocate the blur pyramid + intermediate textures once at reveal-prep, recycle through frames. Removes alloc jitter at transition start.
- UIKit integration cost: low.

### MTLSharedTextureHandle — Metal, iOS 13+
- What: cross-process texture handles.
- Documented in: https://developer.apple.com/documentation/metal/mtlsharedtexturehandle
- Reveal-relevance: likely how Apple first-party apps share rendered content with `SpringBoard` for cross-app transitions. Not applicable to in-app reveals.
- Limitation: overkill for this problem.

### Pixel formats — `.bgra10_xr`, `.rgba16Float`, `.bgra8Unorm_srgb`
- Documented in: https://developer.apple.com/documentation/metal/mtlpixelformat
- Undocumented aspects: `.bgra10_xr` on CAMetalLayer enables EDR/HDR-capable compositing — useful for highlight bloom that retains energy through blending.
- Reveal-relevance: `.rgba16Float` for all intermediate passes preserves headroom for bloom/atmosphere math; final present in `.bgra10_xr` on supported devices for genuine highlight lift.
- Limitation: doubles bandwidth — measure.

### `colorspace` / `wantsExtendedDynamicRangeContent` on `CAMetalLayer`
- Documented in: https://developer.apple.com/documentation/quartzcore/cametallayer/2887087-wantsextendeddynamicrangecontent
- Reveal-relevance: 🔶 iOS support varies (firmer on iPadOS / macOS). On iPhone Pro displays with EDR, set this for a genuine luminous quality on the chat surface emerging.

---

## Three concrete shader-driven reveal patterns

### Pattern 1 — Displacement-driven reveal
Sample a low-freq noise texture; use it to warp UV of a radial mask. The boundary becomes organic instead of geometric.

```metal
fragment float4 displacedReveal(
    VertexOut v [[stage_in]],
    texture2d<float> below [[texture(0)]],     // chat surface
    texture2d<float> above [[texture(1)]],     // morphed-cell snapshot
    texture2d<float> noise [[texture(2)]],     // tileable fbm noise
    constant Uniforms& u [[buffer(0)]])
{
    constexpr sampler s(filter::linear, address::clamp_to_edge);
    constexpr sampler n(filter::linear, address::repeat);
    float2 uv = v.uv;
    // displacement vector from noise, attenuated by progress
    float2 disp = (noise.sample(n, uv * 1.7 + u.time * 0.05).xy - 0.5)
                  * 0.06 * (1.0 - u.progress);
    float2 dUV = uv + disp;
    // radial distance from morph origin, in pixel-space-normalised units
    float d = distance(dUV, u.origin) / u.maxRadius;
    // soft front edge: width shrinks as progress grows for a snappy finish
    float edge = 0.18 * (1.0 - u.progress * 0.6);
    float m = smoothstep(u.progress - edge, u.progress + edge, d);
    float4 a = above.sample(s, uv);
    float4 b = below.sample(s, dUV);          // sample below using displaced uv
    return mix(b, a, m);
}
```
Integration: noise authored offline (or generated once at app start via compute). `u.progress` driven by `UIViewPropertyAnimator` `fractionComplete`. Single-pass.

### Pattern 2 — Soft radial reveal with time-varying noise edge
A *masked dissolve*: instead of a sharp `step`, threshold a per-pixel noise value against `progress`. Edge is inherently organic, no displacement needed.

```metal
fragment float4 noisyDissolve(
    VertexOut v [[stage_in]],
    texture2d<float> below [[texture(0)]],
    texture2d<float> above [[texture(1)]],
    texture2d<float> bluredBelowPyramid [[texture(2)]], // MPSImageGaussianPyramid output
    constant Uniforms& u [[buffer(0)]])
{
    constexpr sampler s(filter::linear, address::clamp_to_edge);
    float2 uv = v.uv;
    float r = distance(uv, u.origin) / u.maxRadius;
    // base radial threshold + animated low-freq noise jitter
    float n = fbm(uv * 3.0 + float2(u.time * 0.08, -u.time * 0.05));
    float threshold = r + (n - 0.5) * 0.12;
    float reveal = smoothstep(u.progress - 0.02, u.progress + 0.02, threshold);
    // depth: as `above` recedes, sample blurrier pyramid level of `below`
    float lod = mix(3.0, 0.0, u.progress);    // 3 → 0 over the reveal
    float4 b = bluredBelowPyramid.sample(s, uv, level(lod));
    float4 a = above.sample(s, uv);
    return mix(b, a, reveal);
}
```
Integration: pre-build `bluredBelowPyramid` once per frame via `MPSImageGaussianPyramid`. Two-pass: pyramid then composite. The pyramid sampling at varying LOD is the depth feel.

### Pattern 3 — Refraction-style reveal (chat pushes through)
Treat the boundary as a lens. The chat surface is sampled with a refraction offset derived from the gradient of the reveal field.

```metal
fragment float4 refractiveReveal(
    VertexOut v [[stage_in]],
    texture2d<float> below [[texture(0)]],
    texture2d<float> above [[texture(1)]],
    constant Uniforms& u [[buffer(0)]])
{
    constexpr sampler s(filter::linear, address::clamp_to_edge);
    float2 uv = v.uv;
    float r = distance(uv, u.origin);
    float field = smoothstep(u.progress + 0.08, u.progress - 0.08, r / u.maxRadius);
    // gradient of the field = lens normal direction
    float2 grad;
    grad.x = dpdx(field) * 18.0;
    grad.y = dpdy(field) * 18.0;
    float strength = (1.0 - field) * field * 4.0;   // peaks at the edge
    float2 refr = grad * strength * 0.04;
    // chromatic split for glass feel
    float4 b;
    b.r = below.sample(s, uv + refr * 1.1).r;
    b.g = below.sample(s, uv + refr * 1.0).g;
    b.b = below.sample(s, uv + refr * 0.9).b;
    b.a = 1.0;
    float4 a = above.sample(s, uv);
    return mix(a, b, field);
}
```
Integration: single-pass; `dpdx/dpdy` only valid in fragment shaders. The chromatic split is the "expensive-looking" detail that signals tier-3.

---

## How triple-A apps likely use Metal for reveals

- **Procreate gallery → canvas:** likely a multi-scale blur pyramid (`MPSImageGaussianPyramid` or hand-rolled equivalent) of the gallery thumbnails grid, sampled at a per-pixel LOD driven by a radial field — gives the focus-pulling depth feel without 3D. The canvas is composited on top as it grows. Confidence: medium-high based on visible defocus characteristics matching pyramid LOD interpolation rather than uniform blur.
- **Halide mode switches:** appears to render UI to an offscreen MTLTexture and composite under a custom shader that does a brief curtain-with-noise dissolve. The viewfinder feed underneath is real-time Metal anyway, so the Metal pipeline is already hot — adding a reveal pass is essentially free.
- **Apollo / Christian Selig's interactive transitions:** less likely full Metal — these read like UIView snapshots + interactive view animator + clever masking. Tier 2.5, not 3. Useful as a counter-example.
- **Apple Music / Now Playing card lift:** subtle backdrop blur ramp + scale + corner-radius animation. Backdrop blur is probably `UIVisualEffectView`, NOT Metal. The "depth" comes from physically-correct shadow + corner-radius easing. Counter-example for "tier 3 always = Metal".
- **Dot / first-party Apple Sports score reveals / Photos memories transitions:** the long, slow, atmospheric reveals with directional light sweeps almost certainly use Metal compositing with `.rgba16Float` intermediates — the highlights retain energy through blends in a way `UIView` `compositingFilter` cannot achieve.

---

## What middle-of-10% Metal CANNOT do for this problem

- **Cannot reach UIKit content directly as a texture without an explicit snapshot step.** You must `drawHierarchy(in:afterScreenUpdates:)` or use `CARenderServerRender*` private API to get UIKit pixels into an `MTLTexture`. Each snapshot is a frame's worth of work; this is the bottleneck, not the shader.
- **Cannot composite live UIKit hit-testable content through a Metal shader.** Once you render via Metal, the result is opaque to UIKit gesture/hit-test. Live interactivity during the reveal forces a hybrid (Metal for the visual zone only, UIKit underneath taking touches).
- **Cannot guarantee perfect frame-locked sync with concurrent UIView animations** without `CAMetalLayer.presentsWithTransaction = true` and committing inside a `CATransaction` — and even then the contract is best-effort, not strict.
- **Cannot exceed display-referred dynamic range on non-EDR-capable devices.** The "luminous" feel of EDR highlights silently flattens on older iPhones — design must degrade gracefully.
- **Cannot solve the "where does the morphed-cell pixel content come from" problem.** Metal renders only what you give it; getting a high-quality snapshot of the source cell mid-morph is a CoreAnimation / UIKit problem, not a Metal one. Garbage in, expensive-looking garbage out.
