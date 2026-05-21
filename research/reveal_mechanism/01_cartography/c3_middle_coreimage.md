# CARTOGRAPHY — Middle of 10% — CoreImage / CIFilter / CIKernel
# Domain: reveal mechanism (morph-end → chat surface with depth)
POSTURE: janum

---

## BLUR PRIMITIVES

## CIGaussianBlur — CoreImage, iOS 5+
- What: Gaussian convolution; single `inputRadius` (0–100, default 10)
- Documented in: https://developer.apple.com/documentation/coreimage/cigaussianblur
- Undocumented aspects: Edge clamping extends border pixels (not zero-pad), causing fringe at mask edges. Pixel extent grows ~`radius * 3` — must crop output to source extent manually or you render outside bounds.
- Experimentation cost: 2 hours to production-safe with extent handling
- Reveal-relevance: Primary workhorse — animate `inputRadius: 40 → 0` to simulate depth pull from blurred unrevealed background to sharp foreground.
- Real-time animation feasibility: trivial — Metal-backed CIContext renders < 2ms at 390×844 for radius ≤ 40
- Limitation: Spatially uniform; same radius everywhere — need a mask layer for gradient falloff

## CIMaskedVariableBlur — CoreImage, iOS 8+ (reliable iOS 14+)
- What: Blur where radius per-pixel = `inputRadius * maskLuminance`; bright mask = full blur, dark = no blur
- Documented in: https://developer.apple.com/documentation/coreimage/cimaskedvariableblur — thin docs
- Undocumented aspects: 🔶 Mask is NOT pre-blurred internally — hard mask edges produce a stair-step discontinuity in blur radius. Must pre-blur the mask with CIGaussianBlur (radius ~4–8) before feeding it in. `inputRadius` is the *maximum* radius; mapping is linear, not gamma-corrected.
- Experimentation cost: 4–6 hours — mask preparation pipeline is non-trivial; `clampedToExtent` on source must be solved
- Reveal-relevance: HIGHEST. Enables a radial blur gradient where the outer ring stays blurry as the center sharpens — the spatial blur falloff that separates depth-feeling from flat crossfades. Drive the mask with a CIRadialGradient animating its radii outward.
- Real-time animation feasibility: moderate — GPU cost ~4ms at full screen; new mask image each frame or pre-rasterized
- Limitation: Varies blur magnitude only — not direction or bokeh shape

## CIBokehBlur — CoreImage, iOS 11+
- What: Lens aperture bokeh simulation; inputs: `inputRadius` (0–500), `inputRingAmount`, `inputRingSize`, `inputSoftness`
- Documented in: https://developer.apple.com/documentation/coreimage/cibokehblur
- Undocumented aspects: 🔶 Performance is dramatically higher than docs suggest — at `inputRadius > 20` on full-screen this misses 60fps on A15 and below. Ring artifact at `inputRingAmount > 0.3` on near-white backgrounds looks like noise. Best kept below radius 12.
- Experimentation cost: 3 hours aesthetics; 1 day performance-safe at transition scale
- Reveal-relevance: The "photographic" blur for the unrevealed background — animating from `inputRadius: 12, inputRingAmount: 0.15 → 0` reads as genuine lens defocus, not filter blur.
- Real-time animation feasibility: requires Metal pipeline — downsample or tile source for real-time; 120fps essentially not viable at large radii
- Limitation: Expensive; spatially uniform without a separate CIMaskedVariableBlur pass

## CIZoomBlur — CoreImage, iOS 8+
- What: Radial zoom blur from `inputCenter`; `inputAmount` = pixels of radial smear
- Documented in: https://developer.apple.com/documentation/coreimage/cizoomblur
- Undocumented aspects: 🔶 `inputAmount` is absolute pixels, not normalized — docs are ambiguous; `inputAmount: 100` on a 390pt screen produces very aggressive streaks
- Experimentation cost: 2 hours — center must track animated cell geometry each frame
- Reveal-relevance: HIGH at expansion moment — animating `inputAmount: 30 → 0` centered on the expanding cell creates a "burst from depth" kinetic energy cue.
- Real-time animation feasibility: trivial — single-pass shader
- Limitation: Center must be driven per-frame to track UIKit cell geometry; fixed 2D point only

## CIMotionBlur — CoreImage, iOS 8+
- What: Linear directional blur; `inputRadius`, `inputAngle` (radians, CCW from +X)
- Reveal-relevance: Brief high-radius vertical motion blur mid-transition implies kinetic snap. Low priority aesthetic choice.
- Real-time animation feasibility: trivial
- Limitation: Unidirectional; cannot smear radially for a circular reveal

## CIDepthOfField — CoreImage, iOS 9+
- What: Lens DoF simulation with a focal band between `inputPoint0` and `inputPoint1`; auto-applies saturation reduction outside focal band
- Documented in: https://developer.apple.com/documentation/coreimage/cidepthoffield
- Undocumented aspects: 🔶 Focal plane is a LINE between two points — cannot define a circular focal zone without layering. Blur applied outside focal band is Gaussian, not bokeh, despite the name.
- Experimentation cost: 3 hours to understand geometry
- Reveal-relevance: Moderate — linear focal model fits a top-to-bottom reveal; awkward for circular.
- Real-time animation feasibility: moderate — chains 3+ sub-filters internally
- Limitation: Linear focal zone only; geometry mismatch for radial cell reveal

## CIMorphologyGradient — CoreImage, iOS 11+
- What: Edge-detection via morphological dilation–erosion difference; outputs grayscale edge image
- Reveal-relevance: Derives an edge mask for the transition zone. Feed into CIBlendWithMask or CIMaskedVariableBlur to concentrate atmosphere along the reveal boundary — the "glass edge" effect.
- Real-time animation feasibility: trivial
- Limitation: Grayscale edge mask only; must be composited

---

## COMPOSITING PRIMITIVES

## CIBlendWithMask — CoreImage, iOS 6+
- What: Three-input composite — foreground, background, mask; mask luminance drives blend: white = foreground, black = background
- Documented in: https://developer.apple.com/documentation/coreimage/ciblendwithmask
- Undocumented aspects: Blend is linear lerp, not premultiplied alpha — transparent foreground pixels produce color fringes near mask edges if source has premultiplied alpha
- Experimentation cost: 2 hours including alpha handling
- Reveal-relevance: HIGHEST. The primary compositing primitive — mask defines revealed zone. Animate via CIRadialGradient expanding each frame.
- Real-time animation feasibility: trivial — CIRadialGradient mask is analytically computed, near-zero cost
- Limitation: No per-pixel blur control in the mask; combine with CIMaskedVariableBlur for that

## CIBlendWithAlphaMask — CoreImage, iOS 8+
- What: Same as CIBlendWithMask but reads the alpha channel of the mask image
- Reveal-relevance: Useful when the mask source is a UIView snapshot (premultiplied alpha) rather than a procedural CIRadialGradient
- Real-time animation feasibility: trivial

## CIBlendKernel — CoreImage, iOS 11+
- What: Custom Metal Shading Language blend ops; `float4 blend(sample_t s, sample_t d)`
- Documented in: https://developer.apple.com/documentation/coreimage/ciblendkernel  
  WWDC 2017 session 510: "Core Image: Performance, Prototyping, and Python"
- Undocumented aspects: 🔶 MSL dialect is a subset of full Metal — texture sampling and loops work, but many Metal stdlib functions are unavailable. No published list; compile errors return opaque generic strings.
- Experimentation cost: 1–2 days to build a reliable kernel authoring/debug workflow
- Reveal-relevance: HIGH — enables custom blend modes for the transition zone (luminance boost + hue shift at mask edge; frosted glass specular contribution). This is how triple-A apps avoid the "generic crossfade."
- Real-time animation feasibility: trivial once compiled
- Limitation: Cannot sample textures other than the two blend inputs — use CIKernel for multi-texture reads

## CIKernel / CIColorKernel / CIWarpKernel — CoreImage, iOS 8+ (Metal-based iOS 12+)
- What: Custom GPU kernels via Metal shading language subset. CIColorKernel: per-pixel color transform (no coord reads). CIWarpKernel: per-pixel coordinate remap (no color reads). CIKernel: full access.
- Documented in: https://developer.apple.com/documentation/coreimage/cikernel  
  https://developer.apple.com/metal/CoreImageKernelLanguageReference3.pdf (sparse)
- Undocumented aspects: 🔶 GLSL-based CIKL and Metal-based kernels are fully incompatible — `destCoord()` in old CIKL becomes a `float2` parameter in Metal. Migration guide is thin. `sample_t` type for texture sampling has no direct Metal equivalent outside CIKernel context.
- Experimentation cost: 2–3 days to build and debug non-trivial kernels end-to-end
- Reveal-relevance: HIGHEST potential — CIWarpKernel implements displacement/refraction at the reveal boundary; CIColorKernel implements per-pixel atmosphere desaturation + luminance curve; CIKernel combines both.
- Real-time animation feasibility: moderate to requires Metal pipeline — must pre-compile to .metallib; use `CIKernel(functionName:fromMetalLibrary:)`; no JIT on animation hot path
- Limitation: Kernel recompilation cannot happen at animation time; Metal GPU Frame Capture has limited CIKernel inspection support

---

## DISTORTION PRIMITIVES

## CIDisplacementDistortion — CoreImage, iOS 9+
- What: Warps pixels using `inputDisplacementImage`; displacement vector = (R−0.5, G−0.5) × `inputScale`
- Documented in: https://developer.apple.com/documentation/coreimage/cidisplacementdistortion
- Undocumented aspects: 🔶 Displacement image is sampled at *destination* coordinates, not source — opposite of what most developers expect; produces inverted-warp artifacts until mental model is corrected. `inputScale` is in points, not normalized.
- Experimentation cost: 3 hours including the inverted-sampling correction
- Reveal-relevance: HIGH — feed a CIRadialGradient or animated noise as displacement map to create a lens-refraction reveal at the boundary. Reads as "glass" or "water surface" separating layers.
- Real-time animation feasibility: trivial — procedural displacement map
- Limitation: Single-layer distortion; cannot simultaneously distort foreground and background in opposite directions without two separate passes

## CIGlassDistortion — CoreImage, iOS 8+
- What: Glass-lensing distortion using a texture as surface; inputs: `inputTexture`, `inputCenter`, `inputScale`, `inputDispersion`
- Undocumented aspects: 🔶 `inputDispersion` produces chromatic aberration (R/G/B channel separation) — not mentioned in main docs but is the key to the "Apple-grade glass" look. Using CIRandomGenerator as texture produces frosted-glass appearance.
- Experimentation cost: 4 hours — "premium glass" vs "frosted window" aesthetic is trial-and-error
- Reveal-relevance: HIGHEST aesthetic fit. Applied to the transition zone (masked to reveal boundary), creates the glass edge effect seen in Halide and Apple photo modals.
- Real-time animation feasibility: moderate — texture is static; animate `inputScale` and `inputCenter`; full-screen ~3ms on A16+
- Limitation: Applied to full image extent unless pre-masked with CIBlendWithMask; compositing only at edge requires multiple passes

## CIBumpDistortion — CoreImage, iOS 6+
- What: Convex/concave lens distortion at center point; negative `inputScale` = concave
- Reveal-relevance: Low-moderate — brief "punch through" depth cue at reveal start (negative scale creates a concave effect). Mostly a flourish.
- Real-time animation feasibility: trivial

## CIHoleDistortion — CoreImage, iOS 6+
- What: Pulls pixels toward the edge of a hole radius; pixels inside are not discarded, they are ring-folded
- Reveal-relevance: Animating radius 0→large creates a "tearing open" feel. Aesthetic is physical deformation, not depth — use carefully.
- Real-time animation feasibility: trivial

---

## COLOR / ATMOSPHERE PRIMITIVES

## CIVignetteEffect — CoreImage, iOS 7+
- What: Radial luminance falloff; `inputCenter`, `inputRadius`, `inputIntensity`, `inputFalloff`; `inputColor` on iOS 13+
- Undocumented aspects: `inputFalloff > 0.5` produces atmospheric fog rather than lens vignette. `inputColor` allows tinted (not just black) vignettes — not prominently documented.
- Reveal-relevance: Animate `inputIntensity` and `inputRadius` outward as reveal expands — background darkens and atmospherically recedes. Half of the "depth formula" alongside CIMaskedVariableBlur.
- Real-time animation feasibility: trivial

## CIColorControls — CoreImage, iOS 5+
- What: `inputSaturation`, `inputBrightness`, `inputContrast`
- Reveal-relevance: Drive `inputSaturation: 0 → 1` as reveal completes — "color blooming" where the revealed surface comes alive. Desaturated-to-saturated transition is the Halide-style reveal signature.
- Real-time animation feasibility: trivial; apply via CIBlendWithMask to confine to revealed layer

## CIToneCurve — CoreImage, iOS 5+
- What: Five control-point tone curve
- Reveal-relevance: Animate from compressed-contrast "behind glass" curve toward neutral full-range as reveal completes. The luminance complement to the saturation bloom.
- Real-time animation feasibility: trivial

## CIColorMatrix — CoreImage, iOS 5+
- What: Full 4×4 + offset color matrix
- Reveal-relevance: Custom atmospheric color grade — slight cyan haze on background, warm tint on foreground during transition. More expressive than CIColorControls for nuanced atmosphere.
- Real-time animation feasibility: trivial

---

## GENERATOR PRIMITIVES

## CIRadialGradient — CoreImage, iOS 5+
- What: Procedural radial gradient; `inputCenter`, `inputRadius0` (inner), `inputRadius1` (outer), `inputColor0`, `inputColor1`
- Undocumented aspects: Gradient is linear (not gamma-corrected) in display P3 — can produce perceptually non-linear ramps on P3 content unless color space is explicitly managed
- Reveal-relevance: HIGHEST. Animate `inputRadius0: 0 → fullscreen-diagonal` to drive CIBlendWithMask and CIMaskedVariableBlur simultaneously. White inner / black outer = perfect circular reveal mask. Zero texture reads.
- Real-time animation feasibility: trivial

## CIRandomGenerator — CoreImage, iOS 6+
- What: Pseudorandom noise image (seamlessly tileable); no inputs; deterministic seed not user-controllable
- Reveal-relevance: Texture input to CIGlassDistortion for frosted-glass appearance. Generate once; reuse as static texture.
- Real-time animation feasibility: trivial

## CISunbeamsGenerator — CoreImage, iOS 6+
- What: Radial light rays from center; `inputTime` animates the striation pattern
- Undocumented aspects: `inputTime` wraps at ~10; combine via CIScreenBlendMode for natural light blending (not CISourceOverCompositing)
- Reveal-relevance: Subtle low-opacity (≤ 0.15) sunbeams composited via CIScreenBlendMode at reveal moment adds "light entering the room." Must stay very subtle to remain Apple-grade.
- Real-time animation feasibility: trivial — drive `inputTime` via CADisplayLink timestamp

## CIUnsharpMask — CoreImage, iOS 6+
- What: Sharpening via unsharp mask; `inputRadius`, `inputIntensity`
- Reveal-relevance: Apply at reveal completion — brief oversharpening snap (`inputIntensity: 0.8 → 0.4` over 150ms) reads as "focus lock." The perceptual punctuation of a depth-pull completing.
- Real-time animation feasibility: trivial

---

## Notable Compositional Pairings

- **CIGaussianBlur + CIMaskedVariableBlur**: Gaussian for the gross background blur; MaskedVariable for spatial falloff at the transition ring — two focal planes, genuine depth.
- **CIDisplacementDistortion + CIRadialGradient**: Radial gradient as the displacement map drives a "lens warp" expanding from cell center — reads as a physical lens moving toward viewer.
- **CIGlassDistortion + CIRandomGenerator + CIBlendWithMask**: Random noise → frosted glass; blend mask limits it to the transition ring — the Halide-style edge material.
- **CIZoomBlur + CIBokehBlur**: ZoomBlur for the burst kinetic at expansion start; BokehBlur for the settled unrevealed background — two distinct blur characters across the timeline.
- **CIMorphologyGradient + CISunbeamsGenerator (CIScreenBlendMode)**: Morphology extracts the mask edge; sunbeams composited there create a "light seam" at the reveal boundary.
- **CIUnsharpMask timed at t=0.9**: Snap oversharpening during the final 10% of animation — a focus-lock punctuation landing.
- **CIVignetteEffect (animated) + CIColorControls (animated)**: Background darkens + desaturates as reveal expands; foreground stays sharp + saturated — two-layer depth contrast from a single conceptual move.

---

## How to Integrate CoreImage with CALayer for Real-Time Animated Reveals

### Pattern 1: CADisplayLink → CIFilter chain → CALayer.contents
```swift
// Pre-warm at app launch — never at transition start
let ctx = CIContext(options: [.useSoftwareRenderer: false])

func displayLinkFired(_ link: CADisplayLink) {
    let t: CGFloat = /* eased 0→1 progress */
    let blurRadius = (1 - t) * 40.0
    let maskRadiusInner = t * maxRadius

    // Procedural mask — near-zero cost
    let mask = CIFilter(name: "CIRadialGradient", parameters: [
        "inputRadius0": maskRadiusInner,
        "inputRadius1": maskRadiusInner + 60,
        "inputColor0": CIColor.white, "inputColor1": CIColor.black,
        "inputCenter": CIVector(cgPoint: center)
    ])!.outputImage!.cropped(to: screenExtent)

    // Spatially-varying blur on background (blur outside the reveal zone)
    let blurredBG = CIFilter(name: "CIMaskedVariableBlur", parameters: [
        kCIInputImageKey: backgroundCI.clampedToExtent(),
        kCIInputMaskImageKey: invertedMask,   // pre-blur mask before this
        kCIInputRadiusKey: blurRadius
    ])!.outputImage!.cropped(to: screenExtent)

    // Composite revealed foreground over blurred background
    let result = CIFilter(name: "CIBlendWithMask", parameters: [
        kCIInputImageKey: foregroundCI,
        kCIInputBackgroundImageKey: blurredBG,
        kCIInputMaskImageKey: mask
    ])!.outputImage!

    revealLayer.contents = ctx.createCGImage(result, from: screenExtent)
    // Note: createCGImage forces CPU readback — ~1ms; upgrade to CIRenderDestination for ProMotion
}
```

### Pattern 2: CALayer.filters keypath (Core Animation drives interpolation, no CADisplayLink)
```swift
let blur = CIFilter(name: "CIGaussianBlur")!
blur.setValue(40.0, forKey: kCIInputRadiusKey)
backgroundLayer.filters = [blur]

let anim = CABasicAnimation(keyPath: "filters.CIGaussianBlur.inputRadius")
anim.fromValue = 40.0; anim.toValue = 0.0; anim.duration = 0.5
anim.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1.0)
backgroundLayer.add(anim, forKey: "blurReveal")
```
- Core Animation interpolates `inputRadius` on GPU — zero CADisplayLink overhead
- 🔶 Behavior of `CALayer.filters` in the render tree (interaction with sublayers, `shouldRasterize`, UIScrollView) is poorly documented and frequently surprising — test exhaustively
- Cannot drive `CIMaskedVariableBlur`'s mask image this way; spatial variation requires Pattern 1

### Pattern 3: CIRenderDestination + CAMetalLayer (zero CPU readback)
```swift
// For ProMotion — eliminates CGImage CPU roundtrip
let renderDest = CIRenderDestination(mtlTexture: destTexture, commandBuffer: commandBuffer)
try! ctx.startTask(toRender: filteredCI, to: renderDest)
commandBuffer.commit()  // result in destTexture, bound to CAMetalLayer directly
```
- Requires managing MTLCommandBuffer lifecycle alongside UIKit animation
- Required for 120fps ProMotion budget with non-trivial filter chains

**Performance note:** Pre-warm CIContext at app launch — first-use compilation costs 50–200ms. Never instantiate CIContext on the animation hot path.

---

## What Middle-of-10% CoreImage CANNOT Do for This Problem

1. **Drive geometry (the cell morph itself)**: CIFilter operates on rasterized pixel grids only. Cell-to-fullscreen shape animation lives in UIKit/Core Animation. CoreImage enters after geometry is rasterized.

2. **Animate a CIKernel's Metal source at runtime**: Custom kernels must be compiled to a .metallib at build time. Parametric variation must be exposed via `setValue` inputs — you cannot hot-patch kernel logic mid-animation.

3. **Provide circular focal zones in CIDepthOfField**: The focal plane is always a line segment between two points. A circular reveal requires either multiple passes or a different primitive (CIMaskedVariableBlur).

4. **Provide smooth GPU-only frames at 120fps via CALayer.contents**: The `createCGImage` CPU readback in Pattern 1 costs ~1ms and can break ProMotion frame budget with complex filter chains. Zero-copy requires CIRenderDestination + CAMetalLayer, which requires substantial Metal plumbing.

5. **Filter live interactive UIKit content in real-time**: CIFilter operates on snapshots (`UIGraphicsImageRenderer`, `drawHierarchy`). Live UIKit content (scrolling table beneath the reveal) cannot be filtered mid-interaction without re-snapshotting every frame — expensive and visually laggy. Real "live content beneath a filter" requires Metal/CAMetalLayer compositing, outside CoreImage's practical scope.
