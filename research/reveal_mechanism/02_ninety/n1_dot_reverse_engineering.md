# NINETY — Reverse-engineering Dot's reveal transition
# Intention 3 — peer rebuild
POSTURE: janum

## Reference examined

- `/Users/spacewizardmoneygang/Desktop/XcodeInstall/_frames/dot_pinch.mov` — source 788×1662 @ 120fps, 7.5s. Could not extract frames directly (no permission to invoke ffmpeg in this session).
- `/Users/spacewizardmoneygang/Desktop/XcodeInstall/_frames/out_v3/` — 34 frames covering the chat→list **dismissal** direction (reverse of reveal). Played in reverse this IS the reveal segment. Examined f001, f002, f003, f004, f005, f006, f008, f009, f010, f011, f012, f013, f014, f015, f016, f017, f018, f019, f020 closely.
- `out_v1`, `out_v2`, `out_v2_dense`, `responsive_frames` — all unrelated content (Apple Music library, a hand-held phone demo, an unrelated mobile UI). Discarded.
- `00_gauge.md`, `c5_latter_cafilter.md`, `c6_latter_ui_internals.md`, `README.md` for context on user's prior attempts and the prototype's depth-cue posture.

## Observable behavior — beat by beat (reading out_v3 in reverse: forward reveal direction)

**Beat 0 (f019 reverse = beat-start):** "Today" cell fully expanded, centered, occupying ~50% of viewport vertical. Pink-mauve gradient strip begins at very bottom (~5% of screen). List cells above ("Raffi's introduction letter…") are GONE — already faded out by morph end. This is the **handoff state**.

**Beat 1 (f018→f017 reverse, ~50–80ms in):** Pink gradient strip grows from bottom upward, now covering ~20% of screen. Hard top edge of gradient. "Today" cell still centered, sharp. List remains absent. The gradient has a clear color (mauve→peach vertical gradient inside the gradient itself — a 2D gradient, not flat color).

**Beat 2 (f016→f015 reverse, ~100–150ms in):** Pink gradient now covers ~33% of screen. **A new structural element appears**: a faint "Today" cell strip becomes visible just above the gradient (a SECOND, smaller "Today" cell label at lower position) and ABOVE that the previous list ("Thursday, Jun 20 / Raffi's introduction…") starts re-emerging in the top portion. The top of the pink gradient is soft-edged (feathered, not hard).

**Beat 3 (f014→f013 reverse, ~160–230ms in):** Pink gradient covers ~50%. The list at top is now more visible AND slightly blurred. The "Today" cell strip floats just above the pink. Critically: in f013 the pink area is no longer flat — there are subtle text artifacts visible IN the gradient ("Click or press ⌥+1 to polish", a faint white circle) — this is the keyboard ghost / chat content beginning to surface through. The boundary between list-region and chat-region is a **continuous soft blur falloff**, not a line.

**Beat 4 (f012→f011 reverse, ~250–330ms in):** Pink gradient covers ~50–55%. List cells at top are visibly soft / parametric-blurred — text still legible but Gaussian-softened. The Raffi cell is shifting upward (parallax with the rising chat layer below). No hard horizontal line — the list-to-chat boundary IS a wide blur zone (~80–100pt tall).

**Beat 5 (f010→f009 reverse, ~340–420ms in):** Pink area ~55%. List looks sharper again (top half) and "Today" cell rectangle is now an empty pale outline at the chat-frontier — the cell shape is melting into the chat field. Gradient bottom now has a darker mauve concentration.

**Beat 6 (f008→f006 reverse, ~430–550ms in):** Pink occupies ~65–70%. List cells visible at top, but small "Today" cell label has slid up into list position. Chat content (text body) still ABSENT; chat background gradient is what's visible, not the text.

**Beat 7 (f005→f004 reverse, ~560–650ms in):** Pink now ~80% of screen. **The keyboard begins to surface from bottom** — its outline silhouettes appear inside the pink lower band as a darker zone. The chat content area ABOVE the keyboard is still rendering as pure gradient + light blur (no text yet). The "Share with Dot…" input pill is faintly visible at the keyboard's top edge.

**Beat 8 (f003→f002 reverse, ~660–750ms in):** Keyboard fully resolved (sharp, white keys, alphabet visible). Chat content ABOVE the keyboard is rendered but **heavily blurred** — text is illegible smooth-noise gradient, but spatial layout (paragraph blocks) is suggested. Pink gradient still visible at chat-content top portion. This is the moment the chat **architecture** is in place but the chat **text** is still defocused.

**Beat 9 (f001 reverse, ~800ms+):** Chat text crisp and legible. Pink gradient still tints the top (the chat surface's own background gradient — this is the page material). Full chat surface, including the message thread, is now sharp.

**Total reveal arc duration:** approximately 700–850ms (estimating from frame spacing assuming source playback rate is roughly 30–40fps for the frame set).

## Substrate hypotheses (ranked by confidence)

### Hypothesis A: Vertical variable-blur traveling band over a portal-mirrored chat surface

- **Confidence:** HIGH
- **Visible evidence:**
  - The boundary between revealed-chat-region and not-yet-revealed-list-region is **never a hard line** — it's always a soft, feathered transition ~60–100pt tall (f011, f012, f013, f014 all show this).
  - The list at top stays **partially blurred** even when not directly under the chat surface (f011, f012) — its blur radius decreases as the band passes over it.
  - The chat surface's pink-mauve background gradient is **revealed as a continuous tint**, not as a circular or radial expansion — it propagates **bottom-up** along a single axis.
  - The "Today" cell label DOESN'T disappear via alpha — it slides upward through the blur zone and is consumed by the rising chat-background (f015→f013 shows the cell label dimming as the gradient overtakes it).
  - The keyboard surfaces from the bottom AFTER the chat-surface gradient has filled most of the screen — implying it's a separate (real, live, system) layer below the chat content.
- **Cartography primitives:**
  - `CARTO-uiinternals-02` `_UIPortalView` to mirror the chat ViewController (already preloaded offscreen) into the reveal stack so the keyboard, gradient, and content all render live, not as a snapshot.
  - `CARTO-cafilter-02` `variableBlur` on the **chat surface layer's `backgroundFilters`**, with a vertical-gradient `inputMaskImage`: white at top (full blur) → black at bottom (sharp). The mask CGImage is RE-GENERATED each frame as the chat surface rises, OR equivalently the mask stays fixed and the chat surface's frame.y animates from bottom → top. Both produce the same observable result.
  - `CARTO-cafilter-01` `gaussianBlur` ALSO running on the chat surface (constant low-radius) for the always-present soft pink edge.
  - `CARTO-uiinternals-01` `_UIVisualEffectBackdropView.inputRadius` animated 20 → 0 over the LAST 200ms specifically on the chat-content portion (the defocus pull at beat 8→9 — text resolves from blurred to sharp).
- **90% rules implied:**
  1. The reveal is a **single moving primitive** (a vertically-traveling feathered band), not a composition of two disjoint mechanisms. The list-blur, the gradient-rise, the cell-dissolve, and the chat-emergence are all consequences of one moving variable-blur mask.
  2. The chat content is **rendered live the entire time** — only its visibility is gated by the moving mask. No snapshot, no crossfade.
  3. The chat's pink-mauve background gradient is **itself the curtain** — it IS what rises, not "an opacity that increases."
  4. The text content surfaces AFTER the geometric surface — a two-stage reveal where structure resolves first, detail second.
- **Falsifiable test:**
  - Stop the reveal mid-animation. If the blur zone has a hard top edge (clean line) → not this hypothesis. If it has a feathered ~60pt vertical falloff → confirmed.
  - Check whether the "Today" cell label fades by alpha or is occluded by the rising gradient. If you can scrub the gradient up/down independently and see the cell label appear/disappear in sync with where the gradient covers it → confirmed.

### Hypothesis B: CABackdropLayer host with animated `backgroundFilters.variableBlur.inputRadius` + sliding gradient-fill content layer

- **Confidence:** MEDIUM-HIGH (mechanically equivalent to A, distinguished only by which API was reached)
- **Visible evidence:** identical to A.
- **Cartography primitives:**
  - `CARTO-uiinternals-08` direct `CABackdropLayer` via `+layerClass` override, sitting at the top of the reveal stack with `groupName = "revealGroup"` so the layer composites with siblings before sampling.
  - `CARTO-cafilter-02` `variableBlur` with a vertical-gradient mask, OR `CARTO-cafilter-01` `gaussianBlur` with `inputRadius` animated AND a separate CAGradientLayer sibling that physically slides upward (the "content" half).
  - `CARTO-cafilter-43` `luminanceToAlpha` on the CAGradientLayer to produce silky-soft alpha falloff for the boundary, used as the chat layer's mask.
- **90% rules implied:** same as A.
- **Falsifiable test:** check the IPA's class strings for "CABackdropLayer" or "_UIPortalView". Dot likely uses both — backdrop for the blur, portal for the live chat handoff.

### Hypothesis C: Coordinated `_UIVisualEffectBackdropView.inputRadius` decay + alpha-masked color layer rise (no variableBlur)

- **Confidence:** MEDIUM (plausible Tier-2B fallback path that produces similar appearance with less exotic primitives)
- **Visible evidence:** the blur on the list IS uniform across the visible list-band, not strictly spatial — could be a global blur whose radius decreases over time rather than a spatial gradient.
- **Cartography primitives:**
  - `CARTO-uiinternals-01` `_UIVisualEffectBackdropView` with `inputRadius` animated 24 → 0 over 600ms.
  - `CARTO-cafilter-43` `luminanceToAlpha` on a sibling CAGradientLayer to produce the rising pink curtain with a soft top edge.
  - `CARTO-cafilter-19` `screenBlendMode` as `compositingFilter` on the rising gradient layer so the pink lifts through (rather than over) the list.
- **90% rules implied:**
  1. Blur is **temporal**, not spatial — radius is the same everywhere, just animated globally.
  2. The pink curtain is a separate compositing-blended layer that rises in parallel.
- **Falsifiable test:** look at f011 vs f014 — does the BLUR RADIUS on the visible list at the top of the screen CHANGE during the reveal (Hypothesis C), or does it stay roughly the same per-pixel while the blur-affected REGION shifts (Hypothesis A/B)? My read on f011 vs f014 is that the affected region shifts, not the radius — favoring A/B over C — but I cannot do per-pixel measurement from JPEG frames at this resolution.

## 90% rules Dot's reveal encodes (best-guess synthesis)

1. **Directional, axis-aligned, single-primitive reveal.** The reveal has ONE moving primitive — a vertical band — not two composed mechanisms. Pure-10% compositions read as "conflicted" because they layer a mask animation AND a blur animation AND a crossfade — Dot reads as smooth because all visible change is the consequence of one moving thing.

2. **The chat's own background gradient IS the curtain.** There is no separate "reveal overlay." The pink-mauve gradient that the chat surface uses as its page-material in the final state is the same gradient that you see rising during the reveal. Photometric continuity: the curtain becomes the page. (User's prototype already encodes "photometric continuity (card = page material)" as Refusal #2 — Dot extends this rule to the reveal itself.)

3. **Soft boundary that is wider than it looks.** The blur falloff zone at the band's leading edge is wide — roughly 80–100pt vertically. This wide falloff is what kills the "circle expanding" or "edge sweeping across" reads. The eye can't fixate on the boundary because there isn't one — only a gradient of focus.

4. **Two-stage detail resolution.** Geometric structure (chat surface, keyboard, input pill, message-block layout) resolves first; textual detail (readable message text) resolves LAST, in the final ~150–200ms. This is a parametric blur radius decay (`inputRadius` 20 → 0) applied selectively to the chat-content portion AFTER the surface has arrived. The user perceives: "first the room appears, then the writing on the wall becomes readable." This is why the reveal feels deep — depth = different things resolving at different times.

5. **Live composition end-to-end (no snapshots).** The keyboard, the chat content, and the gradient all render live through the entire reveal. Snapshots produce a tell at start (frozen instant) and end (re-layout pop). Dot has neither. This implies `_UIPortalView` or `CAContext`/`CALayerHost` pairing for cross-tree handoff.

6. **The list-side blur is the consequence of the curtain, not a separate effect.** As the chat surface (with its own `backgroundFilters = [variableBlur, ...]`) rises, the list it occludes is sampled and blurred by the backdrop layer. There's no separate "blur the list" animation. The list blur and the chat rise are the SAME mechanical event.

7. **The transition zone moves at a slower velocity than the curtain's leading bottom edge.** The wide falloff means the visible "active blurring region" is a band, not a point — and that band's center-of-blur moves up at maybe 60–70% of the chat surface's anchor velocity. This decoupling of "what's moving" from "where the work is happening" is what gives the reveal physical weight.

8. **Color carries the depth — not blur alone.** The pink-mauve gradient itself has internal verticality (warmer-darker at top of the gradient region, cooler-lighter at bottom). This gradient-within-the-gradient gives the rising curtain its own internal depth, so the reveal reads as 3-dimensional volume entering, not a 2D color wash.

## Specific recommendation for reproduction

- **Primary substrate path: variable-blur band over live portal.**
  - `CARTO-uiinternals-02` `_UIPortalView` instance, `sourceView = chatViewController.view` (preloaded offscreen, fully laid out including keyboard), `hidesSourceView = true`, `allowsBackdropGroups = true`.
  - On the portal's layer set `backgroundFilters = [CAFilter(type:"variableBlur")]` with a vertical-gradient `inputMaskImage` (white top → black bottom, 60–100pt feathered transition zone) and `inputRadius = 24`.
  - Animate the portal view's `frame.y` from below-screen → 0 over ~550ms with `UISpringTimingParameters(mass: 1, stiffness: 200, damping: 22, initialVelocity: .zero)` or the Wave-derived spring already in the prototype.
  - SEPARATE animation: on the chat-content sublayer (the text region of the portal, NOT the keyboard, NOT the gradient background), apply `CARTO-cafilter-01` `gaussianBlur` with `inputRadius` animated 18 → 0 over the FINAL 220ms of the reveal (delay 330ms, duration 220ms, ease-out). This is the two-stage detail resolution.
  - List layer behind the portal: nothing special needed. The portal's `backgroundFilters` will sample and blur it automatically. The "list-blur is a consequence" rule is then satisfied by construction.

- **Secondary/fallback path: parametric backdrop + sliding luminance-to-alpha gradient (no variableBlur).**
  - `CARTO-uiinternals-01` `_UIVisualEffectBackdropView` reached via KVC `view.value(forKey: "backdropView")` on a public UIVisualEffectView. Animate `inputRadius` 20 → 0 over 550ms.
  - Above it: a CAGradientLayer with pink-mauve vertical gradient + `CARTO-cafilter-43` `luminanceToAlpha` as its mask (so the gradient's own luminance creates the soft alpha falloff at top). Animate its `frame.y` bottom → 0 in parallel.
  - This is mechanically simpler but loses the "blur and curtain are the same mechanism" property — has slightly higher risk of reading as two composed effects, exactly the failure mode the user has already encountered. Use only if portal+variableBlur proves App Store-risky.

- **The single most important rule the reproduction must encode:** there must be **one moving primitive whose motion accounts for every visible change** in the reveal — including the list blur, the cell label dissolve, the gradient rise, and the chat appearing. If any visible change has its own animator independent of the main reveal animator, the reveal will fragment into "layered mechanisms" and the user will perceive it as conflicted. This is the structural rule the twin-mask radial reveal violated.

## Critical: what we DON'T know about Dot's reveal

1. **The exact width and shape of the variable-blur mask's falloff.** Linear? Smoothstep? Exponential? We can see it's soft but not how soft. A 40pt smoothstep vs 100pt linear will read materially different. Resolving requires per-pixel frame analysis on the iPhone-recorded source video (out_v3 at 922×540 is too downsampled for this) — extract from `dot_pinch.mov` at native 788×1662 and sample column intensities.

2. **The exact timing of the two-stage detail-resolution blur.** When does the chat-content-text blur start decaying — at the moment the chat surface fully arrives, or starting partway through the reveal? Beat 8→9 transition is ~150–200ms of frames; we can't pin down sub-frame timing. Frame-accurate extraction at native fps would close this.

3. **Whether Dot uses `_UIPortalView` or `CAContext`/`CALayerHost`.** Both produce the same external behavior. Tells would be in symbolicated crash logs or class-string analysis of the Dot IPA. Practically — `_UIPortalView` is the lower-risk choice and matches SwiftUI's choice for `matchedGeometryEffect`, so it's the default recommendation regardless.

4. **What the keyboard handoff actually is.** Is the keyboard the system keyboard rendered live underneath the portal, or a snapshot of the system keyboard captured at chat-VC load? In f004 the keyboard looks too crisp and "live" (with the cursor circle visible in f013) to be a snapshot. But this could also be a portal of UIInputWindow — would require runtime introspection on the live Dot app to verify.

5. **What color space the gradient interpolation uses.** The pink-mauve gradient doesn't pass through muddy mid-tones — it stays warm-clean across its full range. This suggests OKLab or HSB linear interpolation rather than sRGB-linear, but we can't verify from compressed JPEGs. Could be tested by sampling the gradient's mid-point color and checking whether it's a clean mauve or a sRGB-interpolated grey-purple muddy color.
