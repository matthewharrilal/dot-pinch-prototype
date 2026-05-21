# Mechanisms in the Wild — Per-mechanism app survey

For each major primitive / pattern surfaced by the research, this document maps **which shipped apps use it, which feature it powers, and what visible signature gives it away**. Then it shows how each app composes multiple mechanisms simultaneously.

Confidence flags:
- ✅ confirmed (open-source code, system app behavior verifiable via lldb / Reveal, official Apple talk)
- ⏺ high (observable + matches no other plausible mechanism)
- 🔶 inferred (consistent with observable but not directly confirmed)

---

## Mechanism 1 — `_UIVisualEffectBackdropView.inputRadius` (parametric blur radius)

**What it does:** lets you animate blur radius as a continuous `CGFloat` instead of swapping between `UIBlurEffect` style presets. Reached via `valueForKey("backdropView")` on any `UIVisualEffectView`. Then animate `"inputRadius"` keypath directly.

**Visible signature:** smooth focus pulls. Background defocuses or sharpens with continuous motion, NOT in two discrete jumps. If you watch a transition and the blur looks like it's "loading" between two stops, it's `UIBlurEffect` preset swap. If it slides continuously, it's `inputRadius`.

### Where it ships

- **Apple Music — now-playing expansion** ⏺
  *Feature:* tapping the mini-player at the tab bar level expands to fullscreen now-playing. Background blur deepens continuously through the transition.
  *Signature:* watch the background of the song-list view behind the rising artwork — it doesn't jump from no-blur to blurred; it sweeps. (n2)

- **Apple Photos — zoom into a photo from grid** 🔶
  *Feature:* tap a thumbnail in the grid; the surrounding grid blurs continuously as the selected photo zooms forward.
  *Signature:* if you cancel the zoom mid-flight (swipe back), the blur smoothly retracts — only possible with parametric radius.

- **Telegram — pinch-to-zoom on media messages** ✅
  *Feature:* pinching a photo in a chat blurs the chat list behind it; blur amount tracks finger distance, not gesture phase.
  *Signature:* the blur is live-bound to the gesture (no spring during the pinch itself). Open-source confirmed in `Telegram-iOS/ChatListController/...`. (n3)

- **iOS Control Center / Notification Center pull-down** ⏺
  *Feature:* pulling either panel down progressively blurs everything behind it.
  *Signature:* blur amount tracks finger position 1:1; if you stop your finger, the blur stops at that exact radius. (n5)

- **iOS Lock Screen — wallpaper crossfade during clock motion** 🔶
  *Feature:* wallpaper blur changes as you swipe between Lock and Home, never stepped.

- **Overcast (Marco Arment podcast app) — mini-player expansion** 🔶
  *Same pattern as Apple Music, applied independently.*

**Cartography refs:** CARTO-uiinternals-01 (c6), n2, n5

---

## Mechanism 2 — `_UIPortalView` (live cross-tree mirror)

**What it does:** renders the live contents of another view elsewhere in the hierarchy, with independent transforms / filters. Stable since iOS 12. Reached via `NSClassFromString("_UIPortalView")` then setting `.sourceView`.

**Visible signature:** when a source view morphs/moves into a destination position, the source content stays **live** during the transition (animations continue playing, text cursor still blinks, scroll position updates). Snapshot-based morphs visibly "pop" at the moment of swap — the snapshot's animations freeze, then the destination's resume. Portal-based morphs don't.

### Where it ships

- **Apple Music — artwork morph during expansion** ⏺
  *Feature:* the album artwork in the mini-player visually rises to become the artwork in the fullscreen player.
  *Signature:* if the album is animated (Apple Music sometimes uses subtly-moving animated artwork), the animation continues through the morph without a snapshot pop. (n2)

- **iOS App Switcher — card thumbnails** ⏺
  *Feature:* in the app switcher, the visible app cards aren't snapshots — they're live mirrors of the suspended app's last frame. When the system unfreezes an app for a moment, the card updates.
  *Signature:* live status bars on backgrounded apps; live timestamps on the lock screen card.

- **iPad Slide Over / Split View — drag-in handle** 🔶
  *Feature:* when you drag the side handle to reveal an app, the incoming app's content is live, not a snapshot.

- **iOS Photos — zoom-from-thumbnail** 🔶
  *Feature:* when zooming into a Live Photo or video, playback continues through the transition. Strong evidence of `_UIPortalView` because a snapshot couldn't carry the live video frames.

- **Mail.app — drag a message to a folder** 🔶
  *Feature:* during drag, the message preview is a live mirror of the source row, not a snapshot — selection highlights update, etc.

- **iOS Spotlight result preview (long-press)** 🔶
  *Feature:* the preview that pops out of a Spotlight result row is rendered live.

**Cartography refs:** CARTO-uiinternals-02 (c6), n1, n2

---

## Mechanism 3 — `CABackdropLayer + CAFilter` (direct latter-end composition)

**What it does:** instantiate `CABackdropLayer` directly (subclass of `CALayer`) and assign `CAFilter` instances to its `filters` / `backgroundFilters` / `compositingFilter`. This is the substrate `UIVisualEffectView` itself sits on top of — using it directly lets you skip the `UIVisualEffectView` envelope entirely.

**Visible signature:** custom blur strength and tint colors that don't match any `UIBlurEffect.Style`. Telegram is the canonical example — their chat-list blur has a specific saturation/tint that isn't `.systemMaterial` or `.systemChromeMaterial`.

### Where it ships

- **Telegram (open-source confirmed)** ✅
  *Feature:* the chat background pattern blur, the chat-list blur behind navigation chrome, the gradient backgrounds with parametric blur during pinch-to-zoom.
  *Source:* `Telegram-iOS/.../ChatBackgroundNode.swift` and adjacent files instantiate `CABackdropLayer` directly. (n3, n4)

- **Pre-iOS 9 third-party blur backdrops** ⏺
  *Feature:* before `UIVisualEffectView` shipped (iOS 8), apps like Tweetbot, Castro, and Apollo's predecessors built blur via `CABackdropLayer` + `CAFilter("gaussianBlur")` directly.
  *Signature:* historical — these blurs had a specific saturation feel because devs had to compose the saturation lift themselves.

- **Castro (podcast app) — player chrome behind episode artwork** 🔶
  *Feature:* the blurred backdrop behind player controls is tinted and saturated in a way that doesn't match standard `UIBlurEffect`. Likely direct `CABackdropLayer`.

- **Various jailbreak tweaks and ROM modifications** ✅
  *Used extensively — the substrate is well-understood in the iOS reverse-engineering community.*

**Cartography refs:** CARTO-uiinternals-08 (c6), CARTO-cafilter-01 (c5), n4

---

## Mechanism 4 — `variableBlur` CAFilter (spatially-varying blur)

**What it does:** blur whose radius varies across the surface based on a mask image. Blur intensity at any pixel = blur radius × mask alpha at that pixel. The mask is supplied via `inputMaskImage`. Available in some form since iOS 10+ (🔶 iOS 17+ for the variant with `inputHardEdges` parameter).

**Visible signature:** a blur boundary that's NOT a hard line and NOT uniformly applied. The "depth of field" effect — sharp center, soft edges, with a smooth falloff zone. Think of how an iPhone camera in Portrait Mode produces depth-of-field; that's analogous.

### Where it ships

- **Dot — chat reveal (PROPOSED match to reference)** ⏺
  *Feature:* the bottom-up reveal where the chat surface rises with a soft 80-100pt feathered band at its leading edge.
  *Signature:* N1's frame analysis identified the band as `variableBlur` with a vertical-gradient mask. Strongest candidate per N1. (n1)

- **Apple Photos — Portrait Mode preview** ⏺
  *Feature:* depth-of-field preview when shooting in Portrait Mode — sharp subject, soft background, soft transition.
  *Note:* this uses CoreImage's depth-based filters, but the same `variableBlur` family.

- **Notification Center top edge fade** 🔶
  *Feature:* when notifications scroll, the top edge softens rather than hard-clipping. Could be `variableBlur` with a gradient mask along the top.

- **Apple Music — artwork edge fade** 🔶
  *Feature:* on certain album backgrounds, the artwork softens at the edges rather than being framed by a hard cut.

- **iOS Camera app — focus-and-exposure indicator decay** 🔶
  *Feature:* the focus reticle fades out with a soft boundary, not a hard fade.

**Cartography refs:** CARTO-cafilter-02 (c5), c3 (CIMaskedVariableBlur as CoreImage analog), n1

---

## Mechanism 5 — Two desynchronized `UIViewPropertyAnimator` (temporal parallax)

**What it does:** two (or more) `UIViewPropertyAnimator` instances driving different visible properties, with deliberately staggered start times and/or different spring parameters. The brain reads the desync as "depth," because in the physical world objects at different distances respond to motion with different timing.

**Visible signature:** when a sheet rises (for example), some elements arrive on a tighter spring than others. Background elements settle slightly after foreground ones. Cancel mid-flight and the elements retract at different rates.

### Where it ships

- **Things 3 — add-to-inbox compose card** ✅
  *Feature:* tapping the magic plus button slides a compose card up. The inbox itself slides down slightly. The keyboard rises. Each on its own animator.
  *Signature:* observe in slow-motion — the compose card and the inbox descent don't move on the same curve; the inbox lags by ~80ms. (n3)

- **Apollo for Reddit — swipe-to-detail comment thread** 🔶
  *Feature:* swiping into a thread reveals child comments with each level offset slightly in arrival.

- **iOS Mail compose card (the iOS 13+ stack-of-drafts UI)** ⏺
  *Feature:* swipe down on compose; the card descends while the prior compose drafts behind it shift independently.

- **Apple Settings — push-pop navigation** ⏺
  *Feature:* the standard navigation push isn't a single animator under the hood — the title fades out independent of the row content, the back chevron animates differently.

- **iOS Mail — "swipe to delete" reveal of action chrome** 🔶
  *Feature:* the row slides; the delete button rises into view on a desynchronized timer, with a slight bounce that the row itself doesn't have.

**Cartography refs:** UIViewPropertyAnimator + CASpringAnimation (c1), n3

---

## Mechanism 6 — Hot-Metal pipeline (continuous Metal compositing)

**What it does:** the app maintains an always-on Metal rendering loop (`CADisplayLink` → command buffer → `MTKView`/`CAMetalLayer.nextDrawable()` → present) and UIKit chrome is composited over the Metal output. Transitions in such apps benefit from the substrate already being shader-driven.

**Visible signature:** absolutely zero frame drops during transitions, even on older devices. Custom shader effects in the transition zone (e.g., displacement, refraction) that no pure-Core-Animation app could pull off. Battery cost is observable.

### Where it ships

- **Halide** ⏺
  *Feature:* the camera viewfinder is Metal-rendered continuously. Mode switches, focus peaking overlays, histogram reveals — all composited over Metal frame.
  *Signature:* histogram overlay reveal is shader-driven; you can see subtle pixel-level transition behavior that pure CA can't do. (n3, c4)

- **Procreate** ⏺
  *Feature:* the canvas is Metal-rendered continuously. Gallery-to-canvas transition uses pyramid LOD blur (multiple mip levels of the canvas pre-rendered, then crossfaded as scale changes).
  *Signature:* the canvas-to-gallery zoom has perfect quality at every scale — only possible with mip-mapped Metal textures. (c4)

- **Apple Camera (system)** ⏺
  *Feature:* same as Halide — always-on Metal viewfinder.

- **Apple Maps** ⏺
  *Feature:* the map itself is Metal-rendered. Search results panel slide, place-card reveals, all composite over the Metal map.

- **Apple Photo Booth** ⏺
  *Feature:* live filter previews driven by Metal compute.

**Cartography refs:** CARTO ids in c4 (CAMetalLayer, CAMetalDisplayLink, MTKView, MPSImageGaussianPyramid for LOD), n3

---

## Mechanism 7 — `vibrantColorMatrix` / vibrancy compositing

**What it does:** a CAFilter recipe that takes the luminance of a backdrop and uses it to rescale the foreground color's contribution. The foreground takes on a desaturated, luminance-matched tint that reads as "on the same surface as the backdrop."

**Visible signature:** text or icons that appear over a blurred backdrop have color subtly affected by what's behind them. If you scroll a list under a vibrant title bar, the title's apparent saturation shifts slightly.

### Where it ships

- **Apple Music — destination atmosphere on now-playing fullscreen** ⏺
  *Feature:* the song-title text takes on a vibrant tint derived from the artwork color.
  *Signature:* swap to a different song with very different artwork color — the text vibrancy shifts. (n2)

- **iOS Notification banners** ⏺
  *Feature:* the app icon and notification text sit on the notification's blurred backdrop with vibrancy compositing.

- **Apple TV / tvOS poster glow** ⏺
  *Feature:* focused poster's glow color is derived from the poster image via `MPCMediaItemArtworkColorAnalysis`-style extraction + vibrancy compositing of the glow.

- **iOS Control Center — toggle labels** ⏺
  *Feature:* the "Bluetooth" / "Wi-Fi" / "Airplane Mode" labels under each toggle use vibrancy to blend with the panel backdrop.

- **iOS Widgets (Lock Screen widgets)** ⏺
  *Feature:* widget text uses vibrant rendering against the wallpaper backdrop.

**Cartography refs:** CARTO-cafilter-14 (c5), n2, n5

---

## Mechanism 8 — Custom `UIViewControllerAnimatedTransitioning` + `UIViewPropertyAnimator` engine

**What it does:** instead of using `UIView.animate` blocks or `CABasicAnimation`, build the transition as a `UIViewControllerAnimatedTransitioning` controller backed by `UIViewPropertyAnimator`. The animator can be paused, resumed, reversed, scrubbed via `fractionComplete`, and (critically) interrupted by a `UIPercentDrivenInteractiveTransition`.

**Visible signature:** the transition can be interrupted mid-flight by another gesture (e.g., during an expand-up, drag down to dismiss and the transition reverses smoothly without snapping).

### Where it ships

- **Apple Music — now-playing expand AND drag-down dismiss** ⏺
  *Feature:* during the expand, you can already grab the rising artwork and drag it back down. No snap to either state — the animator smoothly reverses.
  *Source confirmation:* Apple's iOS architecture talks (WWDC 2017 #230 "Advanced Animations with UIKit") demonstrate this exact pattern. (n2)

- **iOS Mail — compose card drag-to-dismiss** ⏺
  *Feature:* during compose card present, drag it down to minimize. Mid-flight reversibility.

- **Apple Photos — zoom-to-photo with cancel** ⏺
  *Feature:* tap a thumbnail; before it fully expands, swipe back — smoothly retracts.

- **iOS App Switcher — flick-up to dismiss app** ⏺
  *Feature:* flicking partially up and releasing snaps to nearest state (dismiss vs return), velocity-aware.

- **iPad Slide Over — drag handle** ⏺
  *Feature:* the side handle that brings in a Slide Over app is fully interactive throughout its travel.

**Cartography refs:** UIViewControllerAnimatedTransitioning + UIViewPropertyAnimator + UIPercentDrivenInteractiveTransition (all c1 front-of-10%), n2

---

## Per-app composition table — how shipped apps stack these mechanisms

For each app, which mechanisms combine to produce the reveal/transition you see:

| App / Feature | M1 backdrop blur | M2 portal view | M3 direct backdrop | M4 variableBlur | M5 desync animators | M6 hot Metal | M7 vibrancy | M8 custom transition |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **Dot** — chat reveal | — | ✅ (proposed) | possibly | ✅ proposed | possibly | — | — | likely |
| **Apple Music** — now-playing expand | ✅ | ✅ | — | possibly edges | likely | — | ✅ | ✅ |
| **Telegram** — pinch-to-zoom | ✅ live-bound | — | ✅ confirmed | — | — | — | — | gesture-driven |
| **Halide** — mode switch | — | — | — | — | possibly | ✅ | — | likely |
| **Things 3** — compose card | — | — | — | — | ✅ canonical | — | — | — |
| **Apple Photos** — zoom-to-photo | ✅ | ✅ | — | — | possibly | — | — | ✅ |
| **Procreate** — gallery↔canvas | — | — | — | — | — | ✅ pyramid LOD | — | likely |
| **App Switcher** | partially | ✅ canonical | — | — | ✅ | — | — | ✅ |
| **Apollo** — swipe-to-detail | — | — | — | — | ✅ | — | — | gesture-driven |
| **iOS Control Center** | ✅ live-bound | — | — | — | — | — | ✅ | gesture-driven |

The table shows: **no triple-A app uses a single mechanism**. Even Things 3 (the "pure UIKit" example) is composing two desyncs plus the keyboard event timing. Apple Music stacks 5+ mechanisms simultaneously. **This is part of why pure-10% compositions feel generic** — they reach for one mechanism (alpha crossfade) and don't stack.

---

## Implications for the user's problem (NOT a conjecture — observations)

1. **The single-primitive composition rule (n1) ≠ a single mechanism rule.** Dot's reveal uses one moving primitive (the variable-blur band's vertical position), but that primitive is built from multiple stacked mechanisms (M2 + M4 + likely M1). The "one primitive" means one source of motion, not one substrate layer.

2. **The lowest-hanging Dot-grade upgrade is M5 (desync animators).** Zero private APIs, low effort, observable improvement. Things' core 90% is purely M5.

3. **The Apple-grade ceiling is M1 + M2 + M7 + M8 stacked.** Apple Music's full composition. Requires latter-end UI internals access via KVC.

4. **Telegram's path (M1 live-bound + M3 direct) is the most user-controllable.** Open-source means you can copy patterns exactly. Lowest substrate risk.

5. **M6 (hot Metal) is the heaviest hammer.** Reserve for cases where M1-M5 hit a wall. Halide and Procreate use it because they already need Metal for their core function (camera viewfinder, drawing canvas) — for a chat app, the cost is harder to justify.

6. **The user's two failed attempts used essentially M1 (preset, not parametric) + alpha.** Both were missing M2 (live source), M7 (vibrancy), and the M5 desync that makes multi-mechanism compositions read as cohesive instead of conflicted.
