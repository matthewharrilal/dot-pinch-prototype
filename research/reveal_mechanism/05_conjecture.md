# Conjecture — The Calibrated Reveal Composition

POSTURE: janum

This is `/conjecture` derived from the cartography + ninety findings. It picks **one** composition as primary, names the alternatives explicitly rejected, and gives a risk-managed implementation order with falsifiable verification.

The reasoning here is downstream of `00_gauge.md`, `01_cartography/_index.md`, `02_ninety/_index.md`, `03_findings_synthesis.md`, and `04_mechanisms_in_the_wild.md`. If any of those change, this conjecture must be re-evaluated.

---

## The composition

A single `UIViewPropertyAnimator` drives the entire reveal via `fractionComplete` 0→1 over ~0.85s. Every visible change is a deterministic function of `fractionComplete`. There are no other animators, no chained `UIView.animate` blocks, no parallel CABasicAnimations with independent timing.

**Layer stack (bottom → top):**

```
┌─ window
│  ├─ TimelineCanvas (morphed cell visible, "Today" centered)
│  └─ Reveal compartment (added on reveal start)
│     ├─ CABackdropLayer "reveal.backdrop"  (full viewport, sits ABOVE canvas)
│     │     backgroundFilters = [
│     │       CAFilter(type: "gaussianBlur",   name: "blur"),
│     │       CAFilter(type: "colorSaturate",  name: "sat"),
│     │     ]
│     │     groupName = "reveal.group"
│     └─ chatVC.view  (initially translated +viewport.height below)
│        ├─ CAGradientLayer mask on chat layer
│        │     alpha 0 at top, alpha 1 at +100pt below top
│        │     (this is the soft-band leading edge — substitutes for variableBlur)
│        └─ chat content sublayer
│              filters = [CAFilter(type: "gaussianBlur", name: "text.blur")]
│              (two-stage detail resolution per n1)
```

**Animation table — every property as a deterministic function of `fractionComplete = fc`:**

| Property | fc=0 | fc=0.6 | fc=1.0 | Curve |
|---|---|---|---|---|
| `chatVC.view.transform.translation.y` | +viewportHeight | -22 (slight overshoot) | 0 | bezier (0.2, 0.0, 0.2, 1.0) |
| `reveal.backdrop.backgroundFilters.blur.inputRadius` | 0 | 18 (peak) | 0 | `pow(symmetric, 0.5)` (n4 √radius) |
| `reveal.backdrop.backgroundFilters.sat.inputAmount` | 1.0 | 1.6 | 1.0 | leads blur by ~100ms (n5) |
| `chat content sublayer.filters.text.blur.inputRadius` | 12 | 8 | 0 | `clamp(fc*1.25 - 0.25, 0, 1) → decay` (last ~200ms only — n1) |
| `activeCell.chatRestCenterLabel.opacity` | 1.0 | 0.0 | 0.0 | curve `clamp(fc * 2.5, 0, 1)` inverted |

**Why the single animator + computed properties pattern:** this is mathematically n1's single-primitive rule. There is **one source of motion** (`fc`), and every visible change is its consequence. The brain reads this as one event with multiple visible manifestations — the same way it reads a real-world physical event (a curtain rising) as one event even though the curtain's velocity, shadow, and the wind it displaces are multiple effects.

---

## Why this composition specifically

Every load-bearing finding from the ninety wave is honored:

| Finding (source) | How honored |
|---|---|
| Single-primitive composition rule (n1) | ONE `UIViewPropertyAnimator`. All other properties are pure functions of its `fractionComplete`. |
| Dot's reveal is bottom-up, not radial (n1) | Chat translates Y from +viewport to 0. No radial mask anywhere. |
| Soft-band boundary, not hard line (n1) | Chat layer has an alpha-gradient mask at its leading edge — produces a feathered 100pt band as the chat passes upward. |
| Two-stage detail resolution (n1) | Chat content sublayer has its own `gaussianBlur` that decays only in the final ~200ms. |
| Parametric blur radius required (n2, n4, n5) | `CAFilter(type: "gaussianBlur").inputRadius` animated directly. No `UIBlurEffect` preset swaps. |
| √radius perceptual scaling (n4) | Blur radius timeline uses `pow(progress, 0.5)`. Avoids the "cliff" feeling. |
| Saturation runs AFTER blur, over-compensating (n5) | `colorSaturate` filter ordered AFTER `gaussianBlur` in the `backgroundFilters` array. Peak amount 1.6x. |
| Material pipeline stages with phase offsets (n5) | Saturation peaks ~100ms before blur peaks. Tint deliberately omitted in v1 (next phase enhancement). |
| `groupName` prevents seams (n4) | The single `reveal.backdrop` carries `groupName = "reveal.group"`. Single layer means no seam risk in v1, but the discipline is established for the (optional) Phase 4 upgrade. |
| Live cross-tree composition (n2 portal pattern) | Deferred to Phase 4 (optional). Chat content is static enough during 0.85s reveal that snapshot risk is low — defer unless empirically needed. |
| Two-animator desync depth (n3 Things pattern) | DELIBERATELY NOT USED. Stacking a second animator would violate n1. The depth instead comes from phase offsets within the single animator's computed properties. |

---

## What was rejected, and why

### Rejected — `variableBlur` CAFilter (CARTO-cafilter-02) as primary substrate
**The most aggressive Dot-exact match.** Rejected for v1 because:
- Reachability on iOS 17/18 is `🔶` flagged in c5 (untested in this codebase)
- The alpha-gradient mask on the chat's top edge produces visually equivalent boundary feathering with confirmed-reachable substrate
- Probe in Phase 5 (optional) — if `variableBlur` works, the alpha-mask approximation can be replaced for a slight quality lift

### Rejected — `_UIPortalView` (CARTO-uiinternals-02) for v1
**The Apple Music pattern.** Rejected for v1 because:
- During a 0.85s reveal of static chat content (history bubbles + dormant composer), the snapshot vs live distinction is imperceptible
- KVC plumbing for portal source-view binding adds complexity without proven payoff for THIS reveal
- Reserve as Phase 4 upgrade if user reports "feels snapshot-popped" empirically

### Rejected — `_UIVisualEffectBackdropView` via `valueForKey("backdropView")` (CARTO-uiinternals-01)
**The lowest-risk parametric blur path per c6.** Rejected because:
- Direct `CABackdropLayer + CAFilter` (Telegram-iOS open-source confirmed) gives the same parametric blur with cleaner code and zero KVC dance
- We control the layer entirely; no fighting with `UIVisualEffectView`'s opinions about its own private style enum

### Rejected — Things' two-desync-animators (M5)
**The "cheapest Tier-3 upgrade" per n3.** Rejected because:
- Two animators with independent timing is structurally the n1 anti-pattern
- The single-animator + computed-property-phase-offsets pattern delivers the same perceptual depth without violating n1
- Things' app uses M5 because they don't have a backdrop pipeline — we do

### Rejected — Apple Music's full M1+M2+M7+M8 stack
**The Apple-grade ceiling.** Rejected because:
- Apple Music's center-out radial geometry is wrong-shape for Dot's bottom-up band
- The custom `UIViewControllerAnimatedTransitioning` controller is multi-day effort with no geometry match
- Smaller substrate gives same compositional principles for this specific transition

### Rejected — Metal hot-pipeline (M6, Halide/Procreate pattern)
**The heaviest hammer.** Rejected because:
- Chat is not a game / camera / canvas — no justification for always-on Metal
- Battery cost is observable; users will notice
- Reserve only if M1–M5 hit a wall on a specific visual effect we can't reproduce otherwise

---

## Anti-patterns to actively avoid during implementation

Drawn from the ninety wave's anti-pattern catalogs:

1. **Adding a second `UIViewPropertyAnimator`** — violates n1's single-primitive rule. If you find yourself reaching for it, the property you want to animate should instead become a computed function of the existing `fc`.
2. **Animating blur radius linearly** — violates n4's √radius perceptual rule. The "smooth easeInOut" timing in CABasicAnimation is applied to `inputRadius` directly; the eye sees stepped because perceived blur scales with sigma not radius.
3. **`UIBlurEffect` preset swap** — won't be parametric; will look stepped. Use `CAFilter` directly.
4. **Stacking multiple CABackdropLayers without shared `groupName`** — n4 Rule 9, produces 1-2px seams at boundaries. Single backdrop in v1 sidesteps; if Phase 4 stacks them, share the name.
5. **Saturation lift before blur in the filter array** — n5 inverts the natural order. The pipeline is `[gaussianBlur, colorSaturate]` not `[colorSaturate, gaussianBlur]`.
6. **Reaching for radial geometry** — n1 invalidated this for Dot. Don't even start with a radial mask; commit to translation.y as the single motion.
7. **Hard-edge mask at the chat's top edge** — Dot's edge is feathered. Use alpha gradient, not hard clip.
8. **Nesting the chat content INSIDE the backdrop carrier** — n4 anti-pattern A ("chat eats itself"). Backdrop is a sibling/ancestor, chat is a separate sibling.
9. **Animating `fc` non-monotonically during normal forward play** — `UIViewPropertyAnimator` supports it, but it'll desync the computed properties from any timing the user perceives. Save non-monotonic for interruptibility (Phase 4).

---

## Risk-managed implementation order

### Phase 1 — Single-animator structural backbone (1-2 hours)
Build the `UIViewPropertyAnimator` with `fractionComplete` driving:
- chat translation.y (the visible motion)
- backdrop `gaussianBlur.inputRadius` with √radius curve
- chat top-edge alpha gradient (static mask, no animation; the band emerges from chat motion)
- "Today" label opacity fade

**Verification:** does the reveal already feel less "conflicted" than the prior two attempts? If yes, the n1 single-primitive rule is doing structural work. If no, audit — there's a hidden independent timeline somewhere.

### Phase 2 — Two-stage text resolution (0.5-1 hour)
Add the chat content sublayer `gaussianBlur` that decays only in the final ~200ms.

**Verification:** structure (bubble shapes, composer pill) arrives in the first 600ms; readable text appears in the last 200ms. If the text is already readable mid-reveal, the decay curve is too eager.

### Phase 3 — Saturation lift (0.5-1 hour)
Add `colorSaturate` to the backdrop filter chain (AFTER `gaussianBlur` in the array). Peak amount 1.6x at fc≈0.5, settling back to 1.0x by fc=1.0. Lead the blur peak by ~100ms.

**Verification:** the canvas behind the rising chat momentarily looks more vibrant/saturated, then settles. If it stays over-saturated at the end, the curve doesn't return to 1.0x. If you can't see any saturation change, the filter is being applied before blur (check array order).

### Phase 4 — Live source via `_UIPortalView` (OPTIONAL — 2-3 hours, only if Phase 1-3 feels "snapshot popped")
Mirror chat VC via `_UIPortalView` instead of direct mount. Source binding via KVC.

**Skip this phase entirely** if Phase 1-3 already lands convincing.

### Phase 5 — `variableBlur` upgrade (OPTIONAL — 2-3 hours, only if you want to push Dot-exact)
Probe `CAFilter(type: "variableBlur")` reachability on iOS 17/18. If it works, replace the alpha-gradient mask with a true `variableBlur` at the chat's leading edge. Visual difference is subtle but more "Dot-feeling."

### Phase 6 — Interruptibility (OPTIONAL — 3-4 hours, only if user wants drag-down-to-dismiss)
Add `UIPercentDrivenInteractiveTransition` driving the animator's `fractionComplete` via pan gesture. The animator already supports this — wire up gesture handling.

---

## Falsifiable predictions

If the conjecture is correct:
- The reveal should feel cohesive (not "conflicted") immediately upon Phase 1 completion
- The blur should feel continuous, not stepped (verifies √radius curve)
- The saturation lift should feel like "material settling," not "filter loading" (verifies stage phase offsets)

If any of these fail:
- **Cohesion fails:** there's a hidden independent timeline. Audit for stray `UIView.animate` blocks, CABasicAnimations not bound to the single animator, layout-driven implicit animations
- **Blur stepping persists:** the curve isn't being applied. Verify `fc` is being read and √ applied, then written to `inputRadius`
- **Saturation feels wrong:** filter order issue or curve issue. Print the filter array order at runtime; verify `colorSaturate` follows `gaussianBlur`

---

## Sufficiency check

This conjecture closes the gap from gauge's Tier 2A → required Tier 3 by composing:
- One latter-end CAFilter substrate (replaces front-of-10% `UIVisualEffectView` preset swap)
- One alpha-gradient mask trick (substrate-equivalent for variableBlur)
- Three computed-property phase offsets within the single animator (the "depth" that triple-A apps stack via multiple mechanisms)
- The full 5-stage material pipeline awareness in the filter chain ordering

This is the minimum substrate for Tier-3 on the user's specific reveal geometry. Adding portal (Phase 4) and variableBlur (Phase 5) pushes toward Tier-3B; without them, Phase 1-3 should already exit Tier 2A territory.

If empirical Phase 1 verification fails the cohesion test, the conjecture is wrong somewhere and this file needs revision before continuing.
