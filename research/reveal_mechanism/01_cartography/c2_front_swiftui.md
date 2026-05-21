# CARTOGRAPHY — Front of 10% — SwiftUI
# Domain: reveal mechanism (morph-end → chat surface with depth)
POSTURE: janum

---

## AnyTransition / .transition modifier — iOS 13+ / SwiftUI 1+
- What: View-level insertion/removal transition; asymmetric variants per insertion/removal direction
- Documentation quality: canonical — https://developer.apple.com/documentation/swiftui/anytransition
- Standalone or compositional: compositional — most meaningful transitions combine .scale + .opacity + .offset + custom ViewModifier
- Reveal-relevance: .transition(.asymmetric(insertion:removal:)) lets morph-in differ from chat-reveal-out, giving the illusion of a one-directional depth push; custom Transition protocol (iOS 17+) can drive arbitrary geometry changes
- Limitation for our problem: transition triggers on view insertion/removal only — cannot drive a continuous gesture-driven reveal; no parametric blur baked in
- UIKit bridging cost: moderate — UIHostingController wrapping the SwiftUI view graph; transition fires on view insertion, not on UIViewController presentation events

---

## Custom Transition protocol — iOS 17+
- What: Adopting `Transition` protocol with `body(content:phase:)` to produce a Transition from a TransitionPhase; replaces the ViewModifier-based AnyTransition extension pattern
- Documentation quality: canonical — https://developer.apple.com/documentation/swiftui/transition; WWDC23 "Animate with springs" (10158) touches phase-based transitions
- Standalone or compositional: standalone — can encode the complete reveal geometry as a single type; composes trivially with .combined and .asymmetric
- Reveal-relevance: TransitionPhase has .willAppear, .identity, .didDisappear — enables three-phase staging (pre-reveal compression → bloom → settle) in a single type; can animate .blur, .scaleEffect, .rotation3DEffect, .offset simultaneously within one body
- Limitation for our problem: still view-level; no access to the transition zone (the edge where cell meets chat surface); blur applied this way is a post-process on the whole view, not spatially varying
- UIKit bridging cost: moderate — same UIHostingController path; transition driven by SwiftUI state mutation, not UIKit animation block

---

## matchedGeometryEffect / Namespace — iOS 14+
- What: Morphs geometry (frame, position, size) of a source view into a destination view when both share a Namespace.ID and matching id; driven by a shared boolean toggle
- Documentation quality: canonical — https://developer.apple.com/documentation/swiftui/view/matchedgeometryeffect(id:in:properties:anchor:issource:); WWDC21 "Add rich graphics to your SwiftUI app" (10021)
- Standalone or compositional: compositional — the geometry morph is automatic; visual content during morph is typically layered with .opacity + .blur for depth effect
- Reveal-relevance: directly models the cell-morphs-to-chat-surface use case; the cell frame blooms to fill screen while content inside it cross-fades; combined with .blur ramp this is the canonical SwiftUI path for Hero reveals
- Limitation for our problem: the morph interpolates frame linearly — no Z-depth push, no perspective warp; complex content during morph can flash or stutter without .drawingGroup; matchedGeometryEffect has known rendering artifacts if source/destination are in different UIWindow layers
- UIKit bridging cost: high — matchedGeometryEffect requires both source (cell) and destination (chat surface) to live in the same SwiftUI view hierarchy; bridging a UICollectionViewCell into the same Namespace as a SwiftUI chat view is architecturally heavy

---

## withAnimation / .animation modifier — iOS 13+ / iOS 17+ new springs
- What: Drives animatable property changes with a specified Animation curve; .spring(response:dampingFraction:), .smooth, .bouncy, .snappy (iOS 17+ named springs)
- Documentation quality: canonical — https://developer.apple.com/documentation/swiftui/animation; WWDC23 "Animate with springs" (10158)
- Standalone or compositional: standalone driver — every SwiftUI animatable property responds to it
- Reveal-relevance: .spring(response:dampingFraction:blendDuration:) with low damping gives physical weight to the bloom; .smooth(duration:extraBounce:) (iOS 17+) gives the Apple-feel overshoot; velocity can be preserved across state retargeting, which UIKit spring animations require explicit UISpringTimingParameters to match
- Limitation for our problem: animation curve only — does not define what is animated; must be paired with property changes on scaleEffect, opacity, blur, etc.
- UIKit bridging cost: trivial — withAnimation wraps any state mutation; bridgeable via @State bindings in UIHostingController

---

## PhaseAnimator — iOS 17+
- What: Cycles a view through a sequence of discrete phases, animating between them; each phase can apply a different combination of modifiers
- Documentation quality: canonical — https://developer.apple.com/documentation/swiftui/phaseanimator; WWDC23 "Animate with springs" (10158)
- Standalone or compositional: standalone — self-contained multi-phase sequence; compositional with any view modifier
- Reveal-relevance: enables sequenced reveal choreography: (1) compress/scale-down cell, (2) bloom outward with blur dissolve, (3) settle chat surface with spring — all in a single declarative type without manual state machines
- Limitation for our problem: phases are discrete, not gesture-continuous; PhaseAnimator advances on trigger, not on UIGestureRecognizer progress; no interruptibility mid-phase without custom logic
- UIKit bridging cost: moderate — requires hosting in UIHostingController; gesture hand-off from UIKit pan recognizer to PhaseAnimator trigger is indirect

---

## KeyframeAnimator — iOS 17+
- What: Drives multiple animatable properties along independent keyframe tracks; KeyframeTrack per property with LinearKeyframe, CubicKeyframe, SpringKeyframe, MoveKeyframe
- Documentation quality: canonical — https://developer.apple.com/documentation/swiftui/keyframeanimator; WWDC23 "Wind your way through advanced animations in SwiftUI" (10157)
- Standalone or compositional: standalone — replaces the need for chained withAnimation calls; compositional with any animatable struct
- Reveal-relevance: independent tracks for .blur, .scale, .opacity, .rotation3DEffect, .offset can be orchestrated on separate timing curves — blur fades out on a different arc than scale blooms, which is exactly what gives depth reveals their quality (defocus leads, geometry follows, or vice versa)
- Limitation for our problem: not interruptible mid-animation by touch without explicit cancel+retarget; no built-in gesture-progress binding; SpringKeyframe provides physical follow-through but only within the declared sequence
- UIKit bridging cost: moderate — same UIHostingController path; KeyframeAnimator value struct must carry all animated properties as a single animatable struct

---

## ViewModifier with animatableData — iOS 13+
- What: Conforming to ViewModifier + Animatable; SwiftUI interpolates animatableData between states, calling body(content:) on every frame
- Documentation quality: canonical — https://developer.apple.com/documentation/swiftui/animatable
- Standalone or compositional: compositional — the workhorse for custom mid-reveal effects (parametric blur ramp, custom mask shape morphing, combined transform + color shift)
- Reveal-relevance: enables a single modifier that simultaneously drives blur radius, scale, opacity, and vertical offset as a function of a single t ∈ [0,1] progress value — one binding drives the whole reveal state; this is the pattern that avoids the "two disjoint mechanisms" failure mode of the rejected UIKit compositions
- Limitation for our problem: animatableData must be VectorArithmetic; complex animations (multi-property) require AnimatablePair / TupleView nesting, which is verbose; still no access to pixel-level compositing
- UIKit bridging cost: trivial — ViewModifier lives inside SwiftUI view; UIKit drives progress via @Binding

---

## GeometryEffect / ProjectionTransform — iOS 13+
- What: GeometryEffect returns a ProjectionTransform (CATransform3D wrapper) applied as a layer transform; animatable; used for perspective-correct 3D transforms without UIKit CATransform3D boilerplate
- Documentation quality: canonical — https://developer.apple.com/documentation/swiftui/geometryeffect; https://developer.apple.com/documentation/swiftui/projectiontransform
- Standalone or compositional: compositional — typically paired with .modifier(MyGeometryEffect(t: progress))
- Reveal-relevance: enables perspective camera simulation during the reveal — cell can appear to recede in Z (m34 perspective transform) as the chat surface advances; this is the primitive that separates a 2D scale bloom from a genuine Z-depth push
- Limitation for our problem: perspective transform is applied on the view's layer, not across the view hierarchy; no cross-view Z-compositing (sibling views don't occlude correctly based on their 3D positions without manual zIndex management)
- UIKit bridging cost: moderate — ProjectionTransform maps directly to CATransform3D so comparison to UIKit path is straightforward; bridging via UIHostingController is clean

---

## .rotation3DEffect — iOS 13+
- What: Applies a CATransform3D rotation around an arbitrary axis; takes angle, axis (x,y,z), anchor, anchorZ, perspective
- Documentation quality: canonical — https://developer.apple.com/documentation/swiftui/view/rotation3deffect(_:axis:anchor:anchorz:perspective:)
- Standalone or compositional: compositional — meaningful paired with .scaleEffect and .opacity for flip or peel reveals
- Reveal-relevance: the perspective parameter directly controls m34 foreshortening; an animated rotation around the Y axis with perspective gives a "card flipping open" depth cue that reads as spatial, not flat; at small rotation angles (0° → 5° → 0°) it creates a subtle parallax bounce at reveal completion
- Limitation for our problem: rotation is around the view's own axis; does not produce true Z separation from siblings; at large angles aliasing is visible without .drawingGroup
- UIKit bridging cost: trivial — maps 1:1 to CATransform3DRotate

---

## .blur(radius:opaque:) — iOS 13+
- What: Gaussian blur of the view content; radius is a continuous CGFloat — fully parametric, unlike UIBlurEffect presets
- Documentation quality: canonical — https://developer.apple.com/documentation/swiftui/view/blur(radius:opaque:)
- Standalone or compositional: standalone for simple defocus; compositional with .scaleEffect + .opacity for "focus bloom" effect
- Reveal-relevance: THIS is the key SwiftUI capability UIKit front-of-10% lacks — parametric blur radius animatable as a CGFloat. Animating blur from 24→0 as the chat surface reveals gives the defocus-pull that reads as Z-depth advance, and it is continuous (no stepped presets). Combined with a ViewModifier driving blur + scale + opacity from a single progress binding, this is the front-of-10% path closest to what triple-A apps achieve
- Limitation for our problem: .blur is a post-process on the view's rendered content — it does not blur what is BEHIND the view (no backdrop/frosted glass effect); opaque:false leaves alpha premultiplication visible at edges; performance degrades at large radii on complex views without .drawingGroup
- UIKit bridging cost: trivial — no UIKit equivalent at front-of-10% (UIBlurEffect is preset-only); this is a genuine SwiftUI advantage worth bridging

---

## .visualEffect modifier — iOS 17+
- What: Reads GeometryProxy and applies effects (blur, opacity, scaleEffect, rotation3DEffect, offset, colorEffect, etc.) without affecting layout; the view's layout frame is fixed, only rendering is modified
- Documentation quality: canonical — https://developer.apple.com/documentation/swiftui/view/visualeffect(_:); WWDC23 "What's new in SwiftUI" (10148)
- Standalone or compositional: standalone — the closure provides GeometryProxy so effects can be driven by the view's own size/position in the coordinate space
- Reveal-relevance: enables scroll-position-driven blur and scale effects (parallax, depth-from-scroll); for a gesture-driven reveal, .visualEffect can read the view's position relative to the screen center and apply proportional blur/scale — the "it reads like physics" quality
- Limitation for our problem: effects are still post-process on view content, not cross-layer; requires the source view to be in a SwiftUI hierarchy to supply GeometryProxy
- UIKit bridging cost: moderate — UIHostingController required; geometry must be propagated from UIKit gesture state into SwiftUI preference values or @Binding

---

## .mask / .compositingGroup / .drawingGroup — iOS 13+
- What: .mask applies another view as an alpha mask; .compositingGroup renders the view subtree into an offscreen texture before compositing (enables opacity on groups, not individual views); .drawingGroup renders the subtree to a Metal-backed offscreen texture
- Documentation quality: canonical — https://developer.apple.com/documentation/swiftui/view/mask(alignment:_:); https://developer.apple.com/documentation/swiftui/view/compositinggroup(); https://developer.apple.com/documentation/swiftui/view/drawinggroup(opaque:colorrenderingmode:)
- Standalone or compositional: compositional — .mask alone creates hard alpha cutouts; combined with a gradient mask view + animated scaleEffect on the mask it produces soft-edge radial reveals; .drawingGroup is a performance wrapper
- Reveal-relevance: animating the mask view (radial gradient scaling from 0→fullscreen) reproduces the rejected "twin radial mask" approach — but inside SwiftUI, .mask can receive any view including one with animated .blur applied to it, producing a soft-edge bloom mask that is itself defocused — a qualitative step above CAGradientLayer masks
- Limitation for our problem: .mask with an animated blurred gradient view is expensive; .drawingGroup is necessary for acceptable performance; still a mask-driven visibility cutout, which the user has noted reads as "a circle expanding"
- UIKit bridging cost: moderate — .drawingGroup produces a CAMetalLayer-backed offscreen; bridging into UIKit rendering tree has layer-ordering implications

---

## Material types — iOS 15+
- What: .ultraThinMaterial, .thinMaterial, .regularMaterial, .thickMaterial, .ultraThickMaterial, .bar; applied via .background(Material) or .overlay; produces adaptive frosted glass from whatever is behind the view in the rendering tree
- Documentation quality: canonical — https://developer.apple.com/documentation/swiftui/material; WWDC21 "Add rich graphics to your SwiftUI app" (10021)
- Standalone or compositional: compositional — materials adapt to light/dark mode and the content behind them automatically; paired with .opacity animation for a "frost forming / clearing" reveal
- Reveal-relevance: .background(.ultraThinMaterial) on the incoming chat surface gives it a frosted-glass entry quality — it appears to rise out of the blur field, reading as spatially closer than the receding source. Animating .opacity from 0→1 on a material view is perceptually richer than animating .opacity on an opaque view because the material is live-sampling its backdrop throughout
- Limitation for our problem: materials in SwiftUI blur what is behind the view in the same render pass — they require the underlying content to be in the same rendering tree (or at least the same UIWindow layer); in a UIKit app with UIHostingController, the material samples the UIKit hierarchy behind it correctly, but only if the hosting view is composited above it, not in a separate window
- UIKit bridging cost: moderate — material views work correctly in UIHostingController placed above a UIKit view hierarchy; requires correct layer ordering

---

## .colorMultiply / .saturation / .contrast / .brightness / .hueRotation — iOS 13+
- What: Per-channel color transformations applied as rendering effects; all animatable as CGFloat parameters
- Documentation quality: canonical — https://developer.apple.com/documentation/swiftui/view
- Standalone or compositional: compositional — most useful as part of a reveal sequence (desaturate source, saturate destination as reveal progresses)
- Reveal-relevance: animating .saturation(0→1) on the incoming chat surface during reveal gives a "color blooms in" effect that reinforces the depth metaphor — the surface is arriving from a desaturated "behind" space into the colored "in front" space; combined with .brightness and .blur ramps this is a low-cost atmospheric staging tool
- Limitation for our problem: these are post-process on view content only; .colorMultiply can produce banding at extreme values; no spatial variation
- UIKit bridging cost: trivial — maps to CIColorMatrix or CALayer filters if needed in UIKit

---

## NavigationStack zoom transition — iOS 18+
- What: .navigationTransition(.zoom(sourceID:in:)) combined with .matchedTransitionSource(id:in:) on the source view; system-provided zoom-from-source transition used in Photos, Contacts
- Documentation quality: canonical — https://developer.apple.com/documentation/swiftui/view/navigationtransition(_:); WWDC24 "Enhance your UI animations and transitions" (10145)
- Standalone or compositional: standalone for NavigationStack pushes; not applicable to modal or custom presentation paths
- Reveal-relevance: this IS the Apple-grade zoom bloom from a source cell — the system interpolates geometry, applies matched blur during the transition, and provides spring physics. It is the closest front-of-10% primitive to what Dot likely uses for its chat reveal if the app is built on NavigationStack
- Limitation for our problem: requires NavigationStack; source must be a SwiftUI view with .matchedTransitionSource; not available for UIKit-driven presentations or custom overlay reveals; iOS 18+ only
- UIKit bridging cost: high — requires full NavigationStack adoption; bridging a UIKit collection view cell as the source is not directly supported

---

## ContentTransition (.interpolate, .symbolEffect, .opacity) — iOS 16+
- What: Controls how a view's content changes when it updates in-place; .interpolate morphs between two states of the same view; distinct from AnyTransition (which fires on insertion/removal)
- Documentation quality: canonical — https://developer.apple.com/documentation/swiftui/contenttransition
- Standalone or compositional: compositional — drives text, images, SF Symbols morphing in-place; not a full view transition
- Reveal-relevance: useful for chat header text morphing in-place (cell title → chat title) as the reveal proceeds; .numericText gives counter animations; less relevant to the spatial reveal itself
- Limitation for our problem: operates on content within a stable view frame, not on the view's presence or geometry
- UIKit bridging cost: trivial — text/label content only

---

## SymbolEffect (SF Symbols transitions) — iOS 17+
- What: .symbolEffect(.bounce), .symbolEffect(.pulse), .symbolEffect(.variableColor), .symbolEffect(.disappear), .symbolEffect(.appear); discrete and indefinite variants
- Documentation quality: canonical — https://developer.apple.com/documentation/symbols/sfSymbolEffect; WWDC23 "Animate symbols in your app" (10257)
- Standalone or compositional: compositional — decorative accent to reveal moments (send button, microphone icon state change)
- Reveal-relevance: peripheral — can punctuate the moment the chat surface settles (mic icon "appears" with a bounce), reinforcing the depth/arrival feeling through micro-animation
- Limitation for our problem: limited to SF Symbol views; not a spatial reveal primitive
- UIKit bridging cost: trivial — UIImageView also supports addSymbolEffect in iOS 17+

---

## Sensory feedback / haptics — iOS 17+ (SwiftUI .sensoryFeedback)
- What: .sensoryFeedback(.impact(weight:intensity:), trigger:), .sensoryFeedback(.selection, trigger:), etc.; declarative haptic trigger tied to state change
- Documentation quality: canonical — https://developer.apple.com/documentation/swiftui/view/sensoryfeedback(_:trigger:); WWDC23 "What's new in SwiftUI" (10148)
- Standalone or compositional: compositional — attaches to any view as a side effect of state change
- Reveal-relevance: a single .impact(weight:.medium, intensity:0.7) at the moment the chat surface settles is the difference between a reveal that feels physical and one that feels like an animation; timing the haptic to the spring's resting point (not its start) is the craft detail triple-A apps get right
- Limitation for our problem: trigger is binary (state change); cannot be driven continuously along gesture progress (that requires CHHapticEngine / CoreHaptics directly)
- UIKit bridging cost: trivial — UIImpactFeedbackGenerator is the UIKit equivalent and is already accessible

---

## Notable compositional pairings within SwiftUI

- **matchedGeometryEffect + .blur(radius:) + .spring(response:dampingFraction:)**: The cell frame morphs to fullscreen while blur on the destination animates 20→0; a single withAnimation block drives both. This is the canonical Hero-reveal pattern and the strongest front-of-10% candidate.

- **KeyframeAnimator + parametric .blur + .rotation3DEffect(perspective:)**: Independent keyframe tracks — blur on its own arc (fast-decay), 3D rotation on a separate arc (slight Z-rock at arrival) — avoids the "two disjoint mechanisms" feel by keeping both inside a single animator.

- **Custom Transition (Transition protocol, iOS 17+) + .compositingGroup + .drawingGroup**: Encode the entire reveal as a single Transition type; wrap the destination in .drawingGroup for Metal-backed offscreen rendering; use TransitionPhase for three-phase staging.

- **ViewModifier(animatableData: t) + .blur + .scaleEffect + .opacity + .colorMultiply**: One progress binding from a UIKit gesture recognizer drives all visual properties simultaneously through a single VectorArithmetic-conforming struct — prevents the desynchronization that caused the "conflicted" verdict on previous UIKit compositions.

- **.visualEffect + GeometryProxy + .blur**: Scroll- or gesture-position drives blur proportionally; reads as physically grounded rather than triggered.

- **Material(.ultraThinMaterial) + .opacity animation + matchedGeometryEffect**: Chat surface arrives as frosted glass (sampling content behind it) and solidifies as opacity reaches 1.0; gives the "rising through a surface" depth metaphor.

---

## SwiftUI capabilities UIKit lacks (front-of-10%)

- **Parametric .blur(radius:)**: UIKit has no animatable Gaussian blur radius at front-of-10%; UIBlurEffect is preset-only. SwiftUI's .blur is continuously animatable as CGFloat. This alone may be worth a UIHostingController bridge for the chat surface and/or the transitioning cell if defocus-pull is the chosen depth mechanism.

- **matchedGeometryEffect automatic frame interpolation**: UIKit requires manual CABasicAnimation on frame/position/bounds plus a snapshot layer; matchedGeometryEffect handles the cross-hierarchy interpolation declaratively with correct spring physics.

- **NavigationStack .zoom transition (iOS 18+)**: No UIKit equivalent that is documented and public. The system-provided zoom uses private rendering paths (likely CATransition with custom filter) not accessible at UIKit front-of-10%.

- **KeyframeAnimator with independent property tracks**: UIKit requires UIViewPropertyAnimator + addAnimations:delayFactor: or CAKeyframeAnimation per property; KeyframeAnimator co-locates all tracks with spring/cubic/linear interpolation modes per keyframe.

- **Declarative haptics via .sensoryFeedback tied to spring settlement**: UIKit requires manual timing of UIImpactFeedbackGenerator.impactOccurred() relative to animation completion; SwiftUI state-binding ensures haptic fires precisely when the state settles.

---

## What front-of-10% SwiftUI CANNOT do for this problem

- **Backdrop/behind-the-view parametric blur**: SwiftUI .blur blurs the view's own rendered content only. Blurring what is visually behind the incoming surface (the frosted-glass defocus-pull from Z-depth) requires either Material types (preset vibrancy levels, not parametric radius) or access to _UIVisualEffectBackdropView / CAFilter gaussianBlur — both latter-end. This is the same limitation as UIKit front-of-10%.

- **Spatially-varying (masked) blur**: CIMaskedVariableBlur applies different blur radii at different screen positions — creating a sharp center with blurred periphery, or a directional blur gradient. SwiftUI .blur applies uniform radius across the entire view. No front-of-10% SwiftUI primitive provides spatial blur variation.

- **Pixel-level compositing at the transition zone**: The edge where cell morphs into chat surface is where the depth illusion is made or broken. Front-of-10% SwiftUI produces this edge via alpha compositing only (mask cutout or opacity blend). Shader-driven edge compositing (refraction, light bloom, luminosity blend) is not accessible at this level.

- **Gesture-continuous interruptible reveal with spring retargeting**: PhaseAnimator and KeyframeAnimator are sequence-driven, not gesture-driven. withAnimation with a @GestureState binding can drive progress, but mid-animation retargeting (user reverses the gesture mid-reveal) requires UIKit gesture recognizer integration via @GestureState + UIViewRepresentable, losing the declarative simplicity.

- **Cross-hierarchy Z-compositing**: matchedGeometryEffect morphs geometry but does not establish true Z-depth ordering between views that are architectural peers. A cell in a List and a chat surface in a NavigationStack cannot share a Z-compositor without NavigationStack zoom transition (iOS 18+, NavigationStack only) or Metal.
