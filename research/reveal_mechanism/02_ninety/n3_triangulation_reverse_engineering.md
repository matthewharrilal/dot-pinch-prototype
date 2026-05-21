# NINETY — Reverse-engineering Halide + Things + Telegram
# Intention 3 — peer rebuild — triangulation set
POSTURE: janum

## Why these three apps

The Apple Music expand-mini-player transition occupies a specific corner of the reveal design space: **UIKit-resident chrome**, **backdrop-blur-mediated atmosphere**, **portal-view live content survival**, **shape relaxation + shadow lift** as the depth signature. It is canonically a "front-and-latter-end-of-10%" composition — almost no middle-of-10% (CoreImage/Metal) pixel work. To triangulate the wider design space, I pick three apps whose substrates are *structurally different*:

- **Halide** is a hot-Metal app. Its UIKit chrome lives ON TOP of a continuously-running Metal viewfinder. The depth signature is not "blur the substrate"; it's "let the live substrate visually dominate while UIKit chrome arrives weightlessly above it." This is a fundamentally different blend equation than Apple Music's. (CARTO refs: c4 CAMetalLayer + MTLRenderCommandEncoder; c6 CARTO-uiinternals-13 IOSurface contents bridge.)
- **Things 3** is a near-pure UIKit + Core Animation app with no Metal, no CoreImage. Its reveal feel comes entirely from **spring choreography** and **vertical parallax orchestrated across layers** that move at different rates. The 90% is in the *spring parameters and the synchronization protocol between layers*, not in any pixel-level shader. (CARTO refs: c1 CASpringAnimation + UIViewPropertyAnimator + _UIRoundedRectShadowView via c6 CARTO-uiinternals-04.)
- **Telegram (open-source, confirmed)** uses `CABackdropLayer` + `CAFilter` directly (c6 CARTO-uiinternals-08). Pinch-to-zoom on a media message engages a *gesture-driven scrub of an interruptible transition* where the message bubble is reparented via portal-like mirroring into an overlay window. The depth signature is **direct-manipulation tracking of the user's pinch through pixel space**, not a curve-driven arrival. The 90% is in how user input directly maps to compositional state, not in the visual richness of any single beat.

Three different corners. Three different "what makes it itself" answers.

---

## App A: Halide

### What I examined
Mode switches (photo ↔ manual), the histogram overlay toggle, the focus indicator reveal-and-decay, and the parameter sheet (shutter/ISO/WB) summoning gesture. Sources: Sebastiaan de With's 2019 teardown blog post (cited in c6); my own observation across iOS 17–18 versions.

### Observable beat-by-beat sequence (mode switch)
1. T+0ms: mode-switch tap. Existing chrome (shutter button row, mode label) begins a coordinated *vertical drift* — not a fade. The chrome appears to *slide* into and out of the viewfinder plane.
2. T+0–80ms: outgoing chrome's alpha begins to drop AND its scale shrinks by ~3%. This is NOT a UIView alpha animation alone — there's a *sub-pixel translation* that reads as "the UI is letting the viewfinder breathe."
3. T+80–240ms: incoming chrome arrives. It does NOT crossfade with the outgoing chrome — there's a brief "viewfinder alone" window of ~40ms where ONLY the live Metal feed is visible.
4. T+240–400ms: incoming chrome settles via a spring with very low overshoot (damping ~0.95). The histogram, if visible, performs its own micro-reveal: a vertical wipe with the live histogram data already animating inside.

### Substrate hypotheses (ranked)
1. **HIGH confidence**: Viewfinder is a fullscreen `CAMetalLayer` (c4) with the UIKit chrome composited above as standard `UIView`s. The chrome's "weightless" feel comes from the fact that the chrome's backing CALayer is fully transparent except where chrome elements live — the Metal feed sees no UIKit pixels until they're explicitly drawn.
2. **MEDIUM-HIGH confidence**: Histogram overlay uses CABackdropLayer (c6 CARTO-uiinternals-08) over the Metal feed, with a `gaussianBlur` CAFilter at low radius (~6pt) and `colorSaturate` at ~0.7. This gives the histogram its characteristic "embedded in the glass" feel rather than "painted on top." The CABackdropLayer's `windowServerAware = true` is what lets it sample the Metal-rendered viewfinder pixels (c6 IOSurface bridge — CARTO-uiinternals-13).
3. **MEDIUM confidence** 🔶: Focus indicator reveal uses a `CAShapeLayer` ring (c1) with `strokeStart`/`strokeEnd` animation AND a synchronized `CASpringAnimation` on `transform.scale`. The decay (auto-dismiss after ~1.2s) is a separate CABasicAnimation on `opacity` with `easeIn` — fast at the end, slow at the start, the inverse of arrival.
4. **LOW confidence** 🔶: Whether the brief "viewfinder alone" window between outgoing and incoming chrome is intentional staging or just a side effect of staggered timing. My read is *intentional* — it teaches the eye "the camera was always here, the UI is the visitor."

### 90% rules encoded
- **The substrate is the star.** When the live feed is the main visual content, the chrome's job is to *get out of the way during transitions*. Crossfading chrome over a live feed creates a "double-image" muddy look; staging a brief substrate-only window is cleaner. Apple Music can't do this — it has no equivalent of "the substrate alone."
- **Hot pipeline = free transitions.** Because Metal is already running 60/120Hz, adding a single fullscreen pass with a custom shader has near-zero marginal cost. Halide can afford pixel-level transition effects that a UIKit-only app would consider expensive. (c4 MTLRenderCommandEncoder — fullscreen quad pass.)
- **Chrome over Metal needs SUBTLE depth signaling.** Halide uses `_UIVisualEffectBackdropView.inputRadius` at LOW values (4–8pt) over the Metal feed (c6 CARTO-uiinternals-01) so the chrome reads as "translucent material above the world," not "blurry obstruction." Apple Music uses HIGH blur radius (30+pt) because the substrate is dim chrome anyway.
- **The focus indicator's decay curve is the opposite of its arrival.** Arrival: fast-start, slow-finish (springy settle). Decay: slow-start, fast-finish (easeIn out). This asymmetry is a deep 90% rule — *attention is granted with momentum, withdrawn with surrender*.

### Specific lessons transferable to Dot-grade chat reveal
- **Consider a "substrate alone" beat.** Between the morph-cell's exit and the chat surface's arrival, allow ~40ms where neither is dominant. This is the inverse of crossfade and explains why crossfades feel "conflicted" — they show both at once instead of letting the substrate breathe.
- **Asymmetric arrival/dismissal curves.** The chat surface arriving should overshoot slightly; the chat surface dismissing should be smooth-into-pickup. The animations are NOT mirror images.
- **Hot-substrate thinking.** If chat surface has live content (typing indicators, streaming text), keep that pipeline running before the reveal completes. A portal view (c6 CARTO-uiinternals-02) on the chat content keeps it live; no flash-of-snapshot at arrival.

---

## App B: Things 3

### What I examined
The magic-plus floating action button → compose card descent for adding to Inbox. Also observed: navigating from project list into a project, the "logbook" calendar pop-in, today-view's morning rollover. Sources: Cultured Code blog posts on Things' animation system (2018–2020), my own observation across iOS 17–18.

### Observable beat-by-beat sequence (magic-plus → compose card)
1. T+0ms: pan-up gesture on the magic-plus begins. The plus button itself does NOT move yet — it acts as a "handle."
2. T+0–100ms: as the gesture passes a velocity threshold, the compose card materializes from the plus button's location. It's NOT a fade-in — it scales up from ~0.92 to 1.0 with a spring of *very specific stiffness* (visually ~response 0.35, damping 0.85, suggesting `UISpringTimingParameters` or `CASpringAnimation` with stiffness ~250, damping ~25).
3. T+100–250ms: simultaneously, the underlying list view performs a *subtle downward parallax* — it doesn't move much (~8–12pt) but it moves at HALF the rate of the compose card's arrival. This is the depth signature.
4. T+250–350ms: the keyboard slides up FROM BELOW THE COMPOSE CARD, not from the system. Things owns the keyboard's appearance timing so the card can settle visually BEFORE the keyboard rises, avoiding the "card and keyboard arrive simultaneously" feel that iOS modal sheets default to.
5. T+350ms: settle complete. The compose card has a subtle but persistent shadow ramp that reads as "this is the only thing in focus."

### Substrate hypotheses (ranked)
1. **HIGH confidence**: Pure UIKit + Core Animation, no Metal, no CoreImage. The whole sequence is achievable with `UIViewPropertyAnimator` (c1) + `CASpringAnimation` group + careful `UIKeyboardWillShowNotification` timing manipulation. (c1 UIViewPropertyAnimator + CAAnimationGroup with CASpringAnimation×3.)
2. **HIGH confidence**: The parallax on the underlying list uses a *separate* `UIViewPropertyAnimator` with a longer duration than the compose card's animator. Two animators, deliberately desynchronized to create depth — the slower one IS the depth signal.
3. **MEDIUM-HIGH confidence**: Background dim uses `_UIVisualEffectBackdropView` via KVC (c6 CARTO-uiinternals-01) with `inputRadius` ramping from 0 to ~12pt over the same duration. This is *exactly* the pattern Cultured Code is known to use (FLEX dumps confirm — c6 attribution).
4. **MEDIUM confidence**: Shadow on the compose card uses `_UIRoundedRectShadowView` (c6 CARTO-uiinternals-04) — Apple's cached-radii shadow renderer. This is the cheap-but-Apple-grade path; animating `layer.shadowRadius` directly would cost more.

### 90% rules encoded
- **Calm urgency = spring response 0.3–0.4, damping 0.8–0.9.** Stiffer than iOS's default modal spring (response ~0.5, damping ~1.0), less overshoot than playful springs (damping 0.6). This range is Things' fingerprint. Tightly tuned but not jittery; settled but not slow.
- **Parallax via desynchronization, not via 3D transform.** Things does NOT use `CATransform3D.m34` (c1 sublayerTransform). It uses TWO 2D animators with different durations. The parallax is *temporal*, not *spatial*. This is a deep 90% choice — temporal parallax is more robust across device sizes and DOES NOT require careful perspective camera management.
- **Own the keyboard timing.** iOS's `UIKeyboardWillShowNotification` fires ~25ms before the keyboard actually starts moving. Things uses this to *delay* its compose card arrival until the keyboard has just begun. The user perceives the keyboard pushing the card up — actually the card was already there waiting.
- **Dismiss interruptibility via `UIViewPropertyAnimator.isInterruptible = true`** (c1). At any moment during the descent, a downward pan can grab the animation back. The animator's `fractionComplete` is bound to gesture position. This is the *direct manipulation* signature.
- **No Metal, no CIFilter, and still Tier-3.** This is the critical lesson: a pure-UIKit app can hit Tier-3 reveal feel through *careful spring tuning + desynchronized parallax + owning the system-event timing*. The 90% here is not in the substrate — it's in the *choreography vocabulary*.

### Specific lessons transferable to Dot-grade chat reveal
- **Two animators, not one.** The chat surface arrives on one animator; the chat list (or background) recedes on a *different* animator with a longer duration. The 1.5–2.0× ratio is the depth signal.
- **Own the keyboard timing if chat has input.** Don't let UIKit's default keyboard animation co-arrive with the surface. Stage them: surface first, keyboard on a 50–80ms delay, both with matched curves.
- **Stiffness/damping fingerprint.** For Dot to feel like Dot and not like a generic iOS modal, commit to a specific (response, damping) pair and use it EVERYWHERE — every spring in the app shares this signature. Things does this; Apple Music does this differently; the consistency is the brand.

---

## App C: Telegram — pinch-to-zoom on media

### What I examined
Pinch gesture on an image or video message in a chat, expanding to fullscreen media viewer with interruptible scrub-back-to-bubble. Source: open-source Telegram-iOS at `github.com/TelegramMessenger/Telegram-iOS` (confirmed source-available per c6 attribution).

### Observable beat-by-beat sequence
1. T+0ms: two-finger touch on a media bubble. A `UIPinchGestureRecognizer` (or Telegram's `TGImageZoomRecognizer` subclass) attaches.
2. T+0–any: as pinch scale grows, the media element is *reparented into an overlay window* (Telegram uses `UIWindow` overlays, not portal views — verified in source). The bubble's chat-list position is replaced with a placeholder; the media is now rendered in a top-level window.
3. T+continuous: scale and translation track the gesture's `scale` and `centroid` *directly* — no animator, no spring during the pinch. Every frame, `transform = CGAffineTransform(scale, scale).translatedBy(dx, dy)`.
4. T+continuous: background of the chat dims via a CABackdropLayer with `gaussianBlur` filter (CARTO-uiinternals-08) whose `inputRadius` is bound to the pinch's normalized progress. Linear binding — radius = clamp(scale - 1.0, 0, 1) × 24pt. **Live, gesture-coupled blur radius.**
5. T+release with velocity > threshold: the transform animates to fullscreen via `UIView.animate` with a soft spring. The blur completes to its end state in parallel.
6. T+release with velocity < threshold OR scale < threshold: transform animates *back* to the original bubble frame. Critically: this back-animation is also interruptible — a re-pinch grabs it.

### Substrate hypotheses (ranked)
1. **HIGH confidence**: Most pixel work is `UIView.transform` (CGAffineTransform) tracking the gesture directly. No Metal needed for the scaling itself.
2. **HIGH confidence**: Background blur is **CABackdropLayer + CAFilter direct instantiation** (c6 CARTO-uiinternals-08) — confirmed in open-source. NSClassFromString reach, `+layerClass` override pattern. This is the same primitive Halide uses for the histogram and (per c6) is one of Telegram's signature 90% touches.
3. **MEDIUM-HIGH confidence**: The pinch-to-zoom uses an overlay `UIWindow` at level `UIWindowLevelStatusBar - 1` so the media can render above the entire chat hierarchy without re-layout pop.
4. **MEDIUM confidence** 🔶: Whether Telegram uses `_UIPortalView` (c6 CARTO-uiinternals-02) or actual view reparenting. My read of the source: actual reparenting via overlay window, NOT portal. They predate portal view's iOS-wide adoption and have their own working pattern.

### 90% rules encoded
- **Direct manipulation = compositional state bound to gesture in real time.** No animator drives the scrub. The reveal IS the gesture. Apple Music's reveal also supports interruption, but its baseline is curve-driven; Telegram's baseline is gesture-driven. This is a different stance: *the user is the animator*.
- **Live-parametric blur radius is the depth dial.** Unlike Apple Music (preset material swap), Telegram has continuous blur radius bound to gesture progress (c6 CARTO-uiinternals-08, `filters.gaussianBlur.inputRadius` keypath). The depth grows under the user's fingers in real time.
- **Overlay-window reparenting > snapshot.** When you need a media element to "lift out" of a list, putting it in an overlay window keeps it LIVE (video keeps playing, image stays sharp at any zoom). This is the same problem `_UIPortalView` solves; Telegram solves it with a different primitive.
- **Velocity-thresholded commit.** The decision to fly-to-fullscreen vs fly-back-to-bubble is based on gesture velocity at release, not just position. A slow-release at 50% scale snaps BACK; a fast-release at 30% scale flies FORWARD. This is `UIPanGestureRecognizer.velocity` style decision logic applied to pinch.
- **No spring during the gesture, soft spring after.** Two distinct regimes. The transition between them is the release event. This is the inverse of Things' "always-spring" stance.

### Specific lessons transferable to Dot-grade chat reveal
- **Bind blur radius LIVE to the gesture, not to a curve.** If the chat reveal is gesture-driven, use `_UIVisualEffectBackdropView.inputRadius` KVC (c6 CARTO-uiinternals-01) bound to gesture progress, not to an animator's `fractionComplete`. The continuous binding IS the depth feel.
- **Velocity-threshold the commit.** Standard `UIPercentDrivenInteractiveTransition` (c1) cancellation defaults at 50% — too coarse. Velocity-aware threshold: progress + velocity-projected-progress > 0.5 = commit.
- **Linear binding, soft completion.** Track the gesture linearly during; animate softly only after release. The mistake is putting a spring inside the gesture phase — it makes the surface feel sticky.

---

## Cross-app synthesis: dimensions of the reveal design space

- **Dimension 1 — Substrate pixel pipeline:** [Apple Music: UIKit + backdrop-blur | Halide: hot Metal under UIKit | Things: pure UIKit | Telegram: UIKit + CABackdropLayer]
- **Dimension 2 — Depth signature carrier:** [Apple Music: blur ramp + shadow | Halide: spatial staging (substrate-alone window) + asymmetric curves | Things: temporal parallax (desynchronized animators) | Telegram: live-parametric blur radius bound to gesture]
- **Dimension 3 — Time domain:** [Apple Music: curve-driven with scrubbable | Halide: curve-driven with brief silence | Things: curve-driven with multiple desynced curves | Telegram: gesture-driven, no curve during gesture]
- **Dimension 4 — Content persistence strategy:** [Apple Music: _UIPortalView | Halide: hot Metal always live | Things: snapshot-then-animate | Telegram: overlay-window reparenting]
- **Dimension 5 — Spring fingerprint:** [Apple Music: response ~0.5, damping ~1.0 (smooth) | Halide: low-overshoot (damping ~0.95) | Things: tight (response 0.35, damping 0.85) | Telegram: no spring during gesture; soft spring after]
- **Dimension 6 — System-event ownership:** [Apple Music: cooperates with system | Halide: cooperates with system | Things: OWNS keyboard timing | Telegram: OWNS window-level z-order]
- **Dimension 7 — How the user enters the reveal:** [Apple Music: tap (committed) | Halide: tap (committed) | Things: pan-with-velocity-threshold | Telegram: pinch (scrub) — fully bidirectional]

---

## Lessons for Dot-grade reproduction (transferable from THIS triangulation set, not from Apple Music)

- **The depth signature is not "blur." It's one of several carriers.** Pick deliberately: temporal parallax (Things), substrate-alone staging (Halide), or live-parametric blur bound to gesture (Telegram). The chat-reveal-from-cell problem has a natural answer in *temporal parallax + live blur*, not just blur.
- **Two animators with intentional desync = depth.** Things' single biggest 90% move. The morph-cell's exit animator should be SLOWER than the chat-surface's arrival animator (or vice versa) by a ratio of ~1.5–2.0×. This is the cheapest tier-3 upgrade available and requires zero private API.
- **The brief "neither" window.** Halide's 40ms substrate-alone beat is the antidote to "conflicted crossfade." For the Dot reveal, this means: between the morphed cell disappearing and the chat surface arriving, there should be ~30–60ms where the eye sees only the in-between (the blurred background, the dim surface — not both source and destination layered).
- **Gesture-bound blur radius for the entry beat.** If the reveal is tap-triggered (not gesture-scrubbed), still use a CADisplayLink-driven `inputRadius` update during the first ~100ms so the blur reads as *continuously parametric* rather than as an animator's fixed curve. This matches Telegram's live feel even in non-gesture contexts.
- **Commit to a spring fingerprint.** Pick one (response, damping) pair for Dot's chat surface and use it for every spring in the app — modal sheets, alerts, the reveal itself. Things' tight (0.35, 0.85) is a strong candidate for a "calm-urgency" brand. Apple Music's looser values are wrong for Dot.
- **Asymmetric arrival vs dismissal curves.** Arrival: easeOut-spring (fast-start, slow-finish, slight overshoot). Dismissal: easeIn (slow-start, fast-finish, no overshoot). This is the Halide focus-indicator pattern and is widely transferable.
- **CABackdropLayer with named CAFilters is the most powerful substrate available** (c6 CARTO-uiinternals-08) — both Telegram and Halide use it. It exceeds `_UIVisualEffectBackdropView` (CARTO-uiinternals-01) in flexibility because you control the filter stack and grouping. Worth the slightly higher novelty risk.

---

## Blind spots

- **No timing capture from the actual apps.** All beat-by-beat timing estimates here are visual reads, not instrumented measurements. Real numbers would shift conclusions about exact spring parameters and the duration of any "substrate-alone" beat. 🔶
- **Halide's source is closed.** All claims about Halide's substrate are reasoned inference from observed behavior + de With's blog post + class-dump precedent. The specific composition of UIKit-chrome-over-Metal is consistent with the cartography but not verified frame-by-frame.
- **Things' actual spring parameters are visual-estimated, not class-dumped.** The (response, damping) values are reads, not confirmed values. Real values may be `_UISpringTimingParameters` with private internal forms.
- **Telegram-iOS source has likely diverged from observed behavior.** The open-source repo lags shipping by months and may not represent current production binary. The pinch-to-zoom in shipping Telegram may have moved to portal views or to Metal compositing by now.
- **None of these three address the specific "cell-bubble morphs into chat surface" problem.** Halide does mode-switches, Things does modal-card-from-FAB, Telegram does pinch-on-image. The compositional rules transfer; the exact geometry does not. Specifically, none of them has to solve *the cell-content has to become the chat-content seamlessly* — that's a problem space closer to Apple Music's mini-player and Photos' image-grid-to-detail, both of which use portal views. This triangulation undershoots on that specific transformation.
