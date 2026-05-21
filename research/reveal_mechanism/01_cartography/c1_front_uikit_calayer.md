# CARTOGRAPHY — Front of 10% — UIKit / CALayer / Core Animation
# Domain: reveal mechanism (morph-end → chat surface with depth)
POSTURE: janum

---

## UIView.animate(withDuration:delay:options:animations:completion:) — UIKit.framework
- What: Block-based implicit animation for UIView-exposed properties (frame, bounds, alpha, backgroundColor, transform, cornerRadius via layer)
- Documentation quality: canonical
- Standalone or compositional: can stand alone; composes trivially with CALayer work
- Reveal-relevance: Drives the "above" view's exit (scale-down, alpha-out) while the chat surface rises beneath; clean choreography anchor for timing synchronization.
- Limitation for our problem: No spring physics without the options variant; can't animate non-view CALayer properties; all timing is curve-based, not physically-grounded.

## UIView.animate(withDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:) — UIKit.framework
- What: Spring-damped animation for UIView properties
- Documentation quality: canonical
- Standalone or compositional: can stand alone
- Reveal-relevance: Gives the revealing chat surface a physically-grounded settle — the slight overshoot and rebound that makes arrival feel weighted, not mechanical.
- Limitation for our problem: Spring model is simplified (damping ratio + velocity scalar); does not expose stiffness/mass independently. CASpringAnimation gives more physical control.

## UIViewPropertyAnimator — UIKit.framework
- What: Interruptible, scrubbable animator for UIView properties; supports addAnimations, addCompletion, pauseAnimation, continueAnimation(withTimingParameters:durationFactor:), fractionComplete
- Documentation quality: canonical (iOS 10+, WWDC 2016 Session 216)
- Standalone or compositional: stands alone; pairs with UIPercentDrivenInteractiveTransition or gesture recognizers for scrubbing
- Reveal-relevance: Allows the reveal to be driven interactively (finger position → fractionComplete) and then released to continue with spring-based completion — exactly the gesture-driven depth model that triple-A apps use.
- Limitation for our problem: fractionComplete scrubbing with spring timing is under-specified pre-iOS 17; spring continuation after pause can feel jerky if paused mid-animation.

## UIView.transition(with:duration:options:animations:completion:) — UIKit.framework
- What: Container-level flip/dissolve transitions using UIViewAnimationOptions (.transitionFlipFromLeft, .transitionCrossDissolve, .transitionCurlUp, etc.)
- Documentation quality: canonical
- Standalone or compositional: standalone
- Reveal-relevance: .transitionCrossDissolve is the simplest layered reveal substrate; .transitionCurlUp delivers the page-curl depth cue natively.
- Limitation for our problem: Transitions are canned — curve and style are not composable with custom CALayer work simultaneously. The curl reads as a page turn, not a spatial reveal.

## UIViewControllerAnimatedTransitioning — UIKit.framework
- What: Protocol for custom view controller transitions; provides transitionDuration and animateTransition(using:UIViewControllerContextTransitioning)
- Documentation quality: canonical (WWDC 2013 Session 218, WWDC 2014 Session 228)
- Standalone or compositional: requires composition — animator + transitionCoordinator + UINavigationController/present
- Reveal-relevance: The substrate for every Apple-grade reveal. Gives a containerView in which both fromView and toView coexist during the animation, enabling true layered depth staging.
- Limitation for our problem: Does not provide built-in spring continuation or scrubbing; must compose with UIViewPropertyAnimator or CASpringAnimation to get those behaviors.

## UIPercentDrivenInteractiveTransition — UIKit.framework
- What: Drives a UIViewControllerAnimatedTransitioning object interactively via update(percentComplete), cancel(), finish()
- Documentation quality: canonical
- Standalone or compositional: requires UIViewControllerAnimatedTransitioning
- Reveal-relevance: Lets a pan gesture scrub the reveal forward/backward, giving the user direct manipulation of the depth transition — the exact model Dot and Halide use.
- Limitation for our problem: Scrubbing is linear by default; the spring continuation on release requires the completionCurve + completionSpeed properties (iOS 10+), which approximate but don't equal a true physical spring mid-gesture.

## UIPresentationController — UIKit.framework
- What: Manages non-fullscreen presentations; controls chrome (dimmingView, passthrough, framing), persistent across interaction
- Documentation quality: canonical (WWDC 2014 Session 228)
- Standalone or compositional: compositional — used alongside UIViewControllerAnimatedTransitioning
- Reveal-relevance: Hosts an independent dimmingView or blurView beneath the presented surface, allowing atmospheric depth layering (blur + dim) independently of the transition animator.
- Limitation for our problem: The presentation container sits above the presenting view; depth illusion is constrained by the z-ordering of UIWindow layers. True "beneath" effects require snapshot trickery.

## CALayer.mask — QuartzCore.framework
- What: Assigns a CALayer as the alpha mask for another layer; the mask's alpha channel clips the masked layer
- Documentation quality: canonical
- Standalone or compositional: compositional — the mask is itself a layer (CAShapeLayer, CAGradientLayer, or custom)
- Reveal-relevance: Drives radial or soft-edge reveals by animating the mask layer's path, position, or opacity rather than the content layer itself. The softness of the mask edge is the depth lever.
- Limitation for our problem: Mask shape alone doesn't imply depth; pairing with shadow or blur is essential. Animating a CAShapeLayer mask path produces hard edges (rejected). Soft edges require CAGradientLayer mask.

## CALayer.transform (CATransform3D) — QuartzCore.framework
- What: Full 3D affine transform on the layer; animatable; exposes perspective (m34), rotation, scale, translation
- Documentation quality: canonical
- Standalone or compositional: can stand alone; composes with sublayerTransform for scene-wide perspective
- Reveal-relevance: Setting m34 perspective on the containerView's layer enables true 3D depth during the reveal — the outgoing cell can recede in Z while the chat surface advances, producing parallax depth.
- Limitation for our problem: Rendered flat (orthographic) unless m34 is set on a parent layer; getting consistent perspective across fromView and toView requires careful transform hierarchy management.

## CALayer.sublayerTransform — QuartzCore.framework
- What: Transform applied to all sublayers' coordinate spaces — sets a scene-level projection matrix
- Documentation quality: canonical
- Standalone or compositional: standalone on the container layer
- Reveal-relevance: Setting sublayerTransform.m34 on the transition containerView creates a shared vanishing point for all animating children — enables coherent 3D spatial staging of the entire reveal.
- Limitation for our problem: Applies to all sublayers equally; layers that should animate flat must be countered with inverse transforms. Adds coordinate complexity.

## CALayer.opacity — QuartzCore.framework
- What: Layer alpha, animatable via CABasicAnimation; distinct from UIView.alpha (which sets opacity on the backing layer)
- Documentation quality: canonical
- Standalone or compositional: can stand alone
- Reveal-relevance: Granular per-layer opacity control during a reveal; individual sublayers of the cell can fade out at different rates, giving temporal depth to the morph-to-reveal transition.
- Limitation for our problem: Alpha alone produces the "generic crossfade" the user has rejected. Must compose with geometric or blur transforms.

## CALayer.shadowOpacity / shadowRadius / shadowOffset / shadowColor — QuartzCore.framework
- What: Renders a drop shadow behind the layer; all four are independently animatable
- Documentation quality: canonical
- Standalone or compositional: can stand alone
- Reveal-relevance: Animating shadowOpacity 0→1 and shadowRadius 0→20 as the chat surface rises creates a sense of elevation — the shadow implies the surface is physically above the substrate.
- Limitation for our problem: Shadow rasterization is expensive on large layers; shouldRasterize must be toggled carefully. Shadow by itself doesn't provide atmospheric depth.

## CALayer.cornerRadius — QuartzCore.framework
- What: Animatable rounded corner radius on the layer
- Documentation quality: canonical
- Standalone or compositional: can stand alone; pairs with maskedCorners
- Reveal-relevance: Morphing cornerRadius from cell's value (e.g., 16pt) to zero as the chat surface expands to fullscreen is a primary geometric cue — the shape relaxation communicates the surface arriving.
- Limitation for our problem: Alone it's a geometry animation, not a depth signal. Pairs with shadow and transform for the full arrival.

## CALayer.maskedCorners — QuartzCore.framework
- What: Bitmask controlling which corners get cornerRadius (CACornerMask: topLeft, topRight, bottomLeft, bottomRight)
- Documentation quality: canonical (iOS 11+)
- Standalone or compositional: requires cornerRadius to be set
- Reveal-relevance: Selectively rounding only top corners during the reveal transition (chat surface arriving from bottom) reads as a natural UI surface, not an artifact.
- Limitation for our problem: Static bitmask — can't animate which corners are rounded mid-flight (only the radius can animate). Must switch maskedCorners at a precise moment if all-corners behavior changes.

## CALayer.allowsGroupOpacity — QuartzCore.framework
- What: Boolean; when YES, the layer composites its subtree as a group before applying its own opacity
- Documentation quality: officially supported
- Standalone or compositional: standalone flag on any layer
- Reveal-relevance: Enables the cell's entire sublayer tree to fade as a unified group — important when the morphing cell has multiple sublayers (avatar, label, background) that should dissolve in unison, not individually.
- Limitation for our problem: Can cause unexpected blending artifacts if child layers have their own compositingFilter set. Off by default for performance reasons.

## CALayer.shouldRasterize / rasterizationScale — QuartzCore.framework
- What: Caches the layer's rendered output as a bitmap; rasterizationScale should match UIScreen.main.scale
- Documentation quality: canonical
- Standalone or compositional: standalone flag
- Reveal-relevance: Dramatically improves animation performance for complex cell sublayer trees during the reveal; the cached bitmap moves and transforms without re-rendering per-frame.
- Limitation for our problem: Rasterized layers don't update their cached bitmap when content changes — must be disabled before the morph begins if cell content is still changing.

## CABasicAnimation — QuartzCore.framework
- What: Interpolates a single CALayer property from/to/by values; explicit animation
- Documentation quality: canonical
- Standalone or compositional: compositional — used in CAAnimationGroup or added directly
- Reveal-relevance: Precise control over any single animatable property (mask position, shadow radius, corner radius) with custom timing functions including CAMediaTimingFunction cubic bezier.
- Limitation for our problem: One property at a time; no interdependency between properties. CAAnimationGroup required for synchronized multi-property reveals.

## CAKeyframeAnimation — QuartzCore.framework
- What: Animates a property through an array of keyframe values with optional timing for each segment; supports path-following
- Documentation quality: canonical
- Standalone or compositional: compositional (in groups or standalone)
- Reveal-relevance: Enables non-linear reveal trajectories — e.g., a transform that overshoots slightly at the 70% mark before settling, or a shadow that peaks and then falls back, creating a sense of physical momentum in the reveal.
- Limitation for our problem: Keyframes must be manually computed; no automatic spring physics. For spring-like motion, CASpringAnimation is simpler.

## CASpringAnimation — QuartzCore.framework
- What: Spring-physics animation for any animatable CALayer property; exposes mass, stiffness, damping, initialVelocity; settlingDuration computed property
- Documentation quality: canonical (iOS 9+)
- Standalone or compositional: compositional (in groups or standalone)
- Reveal-relevance: The correct tool for physically-grounded reveals — animate transform.scale, opacity, or mask position with tuned stiffness/damping to match the weight of the "arriving" surface. settlingDuration ensures the animation runs to full rest.
- Limitation for our problem: Each property gets its own spring; synchronizing two spring animations (e.g., scale + shadow) to settle at the same time requires matching their stiffness/damping manually.

## CAAnimationGroup — QuartzCore.framework
- What: Groups multiple CAAnimation objects, synchronizing them under a single duration and timing
- Documentation quality: canonical
- Standalone or compositional: compositional — wraps CABasicAnimation, CAKeyframeAnimation, CASpringAnimation
- Reveal-relevance: Enables a single add(animation:forKey:) call to drive the entire reveal (scale + cornerRadius + shadow + opacity) in lockstep — critical for depth-consistent reveals where all properties must move together.
- Limitation for our problem: All animations in the group share the group's duration — spring animations' natural settlingDuration is overridden by the group duration if shorter.

## CAGradientLayer (.axial) — QuartzCore.framework
- What: Renders a linear gradient; animatable colors, locations, startPoint, endPoint
- Documentation quality: canonical
- Standalone or compositional: compositional as mask or content layer
- Reveal-relevance: As a mask on the chat surface, an axial gradient (opaque bottom → transparent top) creates a soft-edge wipe reveal — the transparency feathers the leading edge, avoiding hard geometric edges.
- Limitation for our problem: Axial gradients read as wipes/sweeps; they imply directionality more than depth. Radial variant better suggests spatial emanation from a point source.

## CAGradientLayer (.radial) — QuartzCore.framework
- What: Renders a radial gradient from startPoint center outward; animatable
- Documentation quality: officially supported (type: .radial, iOS 12+)
- Standalone or compositional: compositional as mask
- Reveal-relevance: As a mask layer with animated radius (via startPoint/endPoint transform), creates a radial bloom from the tapped cell's origin — suggests the chat surface is expanding outward from a spatial origin point.
- Limitation for our problem: The user has rejected "obvious circle" reveals. The key is softness: opacity rolloff from 1→0 over a wide gradient band prevents hard-circle perception. Slow enough expansion with blur compositing disguises the circle.

## CAGradientLayer (.conic) — QuartzCore.framework
- What: Sweeping angular gradient around a center point (type: .conic, iOS 12+)
- Documentation quality: officially supported
- Standalone or compositional: compositional
- Reveal-relevance: Lower direct relevance for reveals; could contribute to a rotational atmospheric halo effect around a light source during the reveal — decorative depth rather than structural.
- Limitation for our problem: No direct structural role in a reveal mechanism. More useful as atmosphere overlay than as the reveal driver.

## CAShapeLayer — QuartzCore.framework
- What: Renders a CGPath; animatable path, fillColor, strokeColor, lineWidth, strokeStart/End
- Documentation quality: canonical
- Standalone or compositional: can stand alone; powerful as mask
- Reveal-relevance: strokeStart/strokeEnd animation creates line-drawing or stroke-grow effects. As a mask, path morphing (cell-rectangle → screen-rectangle) drives a geometry-expanding reveal.
- Limitation for our problem: Hard path edges produce the "obvious shape" the user has rejected. Requires CAGradientLayer compositing over it to soften edges, adding complexity.

## CATransition — QuartzCore.framework
- What: Legacy layer-level transition animations; types: fade, moveIn, push, reveal; directions: fromLeft/Right/Top/Bottom
- Documentation quality: canonical (legacy, but fully supported)
- Standalone or compositional: can stand alone; added to a layer with add(_:forKey:kCATransition)
- Reveal-relevance: kCATransitionReveal with kCATransitionFromBottom creates a slide-up-reveal where the old layer slides away to reveal new content beneath — has an implicit depth metaphor (content was always there, underneath).
- Limitation for our problem: Canned timing, no spring physics, no perspective. The metaphor is correct but the execution reads as legacy/system-quality without composition with modern spring animators.

## CAEmitterLayer — QuartzCore.framework
- What: Particle emitter system; controls emitterShape, emitterPosition, birthRate, lifetime, velocity, color, scale of CAEmitterCell particles
- Documentation quality: well-documented
- Standalone or compositional: can stand alone as an overlay layer
- Reveal-relevance: Atmospheric particles (fine dust/sparkle) emitting from the tapped cell's region during the reveal communicate spatial disturbance — the surface breaking open. Used sparingly, this is the "atmosphere" signal that separates Tier 3 from Tier 2.
- Limitation for our problem: CPU/GPU cost must be monitored. Overuse reads as Tier 1 (particle explosion). The particle system must be subordinate to the structural reveal, not the star of it.

## UIVisualEffectView — UIKit.framework
- What: Hosts UIBlurEffect or UIVibrancyEffect; self-renders the blur/vibrancy pipeline
- Documentation quality: canonical
- Standalone or compositional: can stand alone; alpha animation on UIVisualEffectView itself is unsupported (results in undefined behavior per Apple docs)
- Reveal-relevance: The primary tool for "frosted glass" depth — a UIVisualEffectView behind the chat surface implies the substrate is visible through the surface, communicating depth and atmosphere.
- Limitation for our problem: Cannot animate alpha directly on UIVisualEffectView (Apple explicitly warns against this). Must use UIView.transition or mask-based reveals, not opacity animations, to introduce/remove the blur.

## UIBlurEffect (systemUltraThinMaterial, systemThinMaterial, systemMaterial, systemThickMaterial) — UIKit.framework
- What: Material-based blur styles (iOS 13+); system* variants auto-adapt to light/dark; hierarchical variants for layered surfaces
- Documentation quality: canonical (WWDC 2019 Session 224 — Visual Design and Adaptivity)
- Standalone or compositional: requires UIVisualEffectView
- Reveal-relevance: systemUltraThinMaterial communicates the lightest atmospheric veil over the substrate — using this under the chat surface during the reveal implies the surface is physically elevated and translucent, reinforcing depth.
- Limitation for our problem: Blur style is fixed at creation — cannot animate between blur styles. Must create a new UIVisualEffectView to change effect.

## UIVibrancyEffect — UIKit.framework
- What: Adapts content colors to remain legible through a blur effect; requires a UIVisualEffectView with UIBlurEffect
- Documentation quality: canonical
- Standalone or compositional: requires UIBlurEffect + UIVisualEffectView
- Reveal-relevance: Less directly relevant to the reveal mechanism; more useful for atmospheric UI elements (labels, icons) that live on the blurred surface and should feel embedded in the material rather than painted on top.
- Limitation for our problem: Only valid inside a UIVisualEffectView's contentView; cannot be applied to arbitrary layers.

## UIView.snapshotView(afterScreenUpdates:) — UIKit.framework
- What: Returns a UIView whose layer is a snapshot bitmap of the receiver; fast, GPU-resident
- Documentation quality: canonical
- Standalone or compositional: standalone; used as a stand-in view during transitions
- Reveal-relevance: Critical for reveals — snapshot the presenting view controller before the transition begins, then animate the snapshot independently while the real view controller renders underneath. This is how Apple's own Music app achieves "the real surface was always there" depth.
- Limitation for our problem: Snapshot is static — content changes after snapshotting are not reflected. Must be taken at precisely the right moment. afterScreenUpdates:true requires a runloop pass.

## UIView.drawHierarchy(in:afterScreenUpdates:) — UIKit.framework
- What: Renders the view hierarchy into the current CGContext; slower than snapshotView but works for views not in a window
- Documentation quality: canonical
- Standalone or compositional: standalone
- Reveal-relevance: Enables capturing the "departing" cell as a UIImage for use in a CALayer texture during the morph, independent of the live view hierarchy.
- Limitation for our problem: Synchronous and relatively slow (~2-3ms for complex hierarchies). Not suitable for per-frame use; capture once before animation begins.

## UIView.resizableSnapshotView(from:afterScreenUpdates:withCapInsets:) — UIKit.framework
- What: Snapshot with edge-preserving stretchable region defined by capInsets
- Documentation quality: canonical
- Standalone or compositional: standalone
- Reveal-relevance: Allows the cell snapshot to stretch toward fullscreen during the reveal without distorting rounded corners — the cell's corner regions are preserved while the center stretches.
- Limitation for our problem: Stretchable region is rectangular; complex cell layouts may look wrong when stretched. Use CALayer.cornerRadius animation on the real layer instead.

---

## Notable compositional pairings within front-of-10%

- **UIViewControllerAnimatedTransitioning + UIViewPropertyAnimator + CASpringAnimation**: The gold-standard reveal substrate. The transition protocol owns the containerView; UIViewPropertyAnimator drives UIView properties interactively; CASpringAnimation simultaneously drives layer-level properties (shadow, cornerRadius, transform) with physical spring curves. settlingDuration ensures the CASpringAnimation completes even if UIViewPropertyAnimator finishes early.

- **snapshotView + CALayer.transform (m34 perspective) + CASpringAnimation on transform.scale**: Snapshot the departing cell, place it in the 3D-perspective container, animate it receding in Z (scale + Z translation) while the real chat surface view animates up from below. The depth separation is perceptual, not just geometric — the snapshot visually "falls away" behind the arriving surface.

- **UIVisualEffectView (systemUltraThinMaterial) + mask-based reveal**: Use a CAGradientLayer (radial) as the mask on a UIVisualEffectView, animating mask scale from cell-size to fullscreen. This reveals the blur/material surface with a soft bloom, avoiding hard edges while communicating atmospheric depth via the material itself.

- **CAAnimationGroup (CASpringAnimation×3) on cornerRadius + shadowOpacity + shadowRadius**: Synchronize the three shadow/shape animations in a group, all with matched stiffness/damping so they settle together. The shadow growing as the corner relaxes reads as a single physical event (a surface arriving), not three separate property changes.

- **CAEmitterLayer (particle atmosphere) + UIViewPropertyAnimator**: Spawn the emitter at the tapped-cell location at transition start; drive emitter birthRate from 1.0 to 0 over the first 40% of the UIViewPropertyAnimator's fractionComplete. Particles briefly appear at the spatial origin of the reveal, then fade — atmosphere without spectacle.

- **UIPercentDrivenInteractiveTransition + UIViewControllerAnimatedTransitioning + CALayer.mask animation**: The interaction drives the transition percent; the animator interprets percent as mask scale (0→1). The user's finger position directly controls how much of the chat surface is revealed — extremely high perceived-depth because the content resistance matches the gesture.

---

## What front-of-10% CANNOT do for this problem

- **Variable-radius soft-edge masking without CIFilter**: CAGradientLayer masks can approximate soft edges, but the rolloff profile is a fixed linear/Gaussian blend. Truly adaptive edge softness that responds to velocity (faster gesture = harder edge, slower = softer) requires CIFilter-based masking, which is middle-of-10% territory.

- **Real-time background content deformation**: All front-of-10% tools treat the underlying content as a static or rigid plane. Depth cues like barrel/pincushion distortion of the substrate as the surface arrives (parallax warp) require CIFilter or Metal, not CALayer.

- **Per-pixel motion blur on fast reveal gestures**: CALayer transforms are rendered frame-by-frame without motion blur. The smear of fast-moving geometry that communicates velocity-of-arrival requires Metal or CIMotionBlur (middle of 10%).

- **Continuous material morphing between blur radii**: UIBlurEffect's blurRadius cannot be animated or interpolated at the UIKit layer. Going from a heavy blur to zero blur during a reveal (the "surface crystallizing into focus" effect) requires private API or a CIFilter workaround.

- **Depth-of-field atmospheric bokeh on the substrate**: Blurring only the background while the foreground surface arrives in focus — true depth-of-field — cannot be done with UIBlurEffect alone (it blurs everything in the UIVisualEffectView's background). Selective per-region variable blur requires CIFilter or Metal.
