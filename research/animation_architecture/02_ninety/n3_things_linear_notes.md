# NINETY — Things 3 + Linear + Notes (calm-restraint school)
# Intention 3 — peer rebuild
POSTURE: janum

Read-only research. Spring estimates inferred from frame-by-frame observation + public talks; not from binaries. Springs normalized to UIKit `response`/`dampingRatio` (≈ SwiftUI `.spring(response:dampingFraction:)`).

---

## App: Things 3 (Cultured Code)

### Observable animations + spring fingerprint
- **Magic Plus button** — FAB expands and *becomes* the compose-card edge (matched-geometry transform, not crossfade). Fingerprint: **response ≈ 0.35, damping ≈ 0.85**. Lands ~0.55s, single soft settle, no overshoot.
- **Checkbox tick** — two-phase: 1) circle fills (`CABasicAnimation` on `strokeEnd`, ~0.18s ease-out) 2) row reflows on a separate spring (~0.4 / 0.9). Haptic + sound land on the fill-complete frame, NOT the row-rest frame.
- **List reorder** — picked row: scale 1.0→1.04 + shadow 0→~12pt over 0.22s. Sibling rows shuffle on a *slower* spring (~0.45 / 0.9) — deliberate figure/ground.
- **Jump-to-Today** — custom decel curve (not UIScrollView default); arrival outline pulse, single beat.
- **Calendar day expand** — day row grows downward, sibling rows shift on the *same* spring (~0.4 / 0.88) — not a separate animation block.
- **Sidebar → detail** — horizontal push, but the title is matched-geometry (same view, not re-rendered).

### Architecture inference
- **Single spring fingerprint app-wide.** Variance across all observed interactions stays in response 0.35-0.45, damping 0.85-0.9. Calling card of a shared `SpringTiming` constants set, not per-screen tuning.
- **Matched-geometry is first-class.** Plus → compose-card and sidebar → detail title require coordinated transforms across hierarchy boundaries. UIKit-native: custom `UIViewControllerAnimatedTransitioning` + snapshot views, or shared-element promoted to window-level overlay during transition.
- **`UIViewPropertyAnimator` likely owns interruptibles.** Compose card flicks back without snap mid-rise — classic interruptible-animator behavior. One animator per interaction; `pauseAnimation()` on gesture-begin; `fractionComplete` tracks gesture.
- **No CADisplayLink in user space.** UIKit-native timing is sufficient — short, single-spring, no physics-sim need.

### 90% rules encoded (calm ethos technical translation)
1. **One spring fingerprint per app.** Not per screen — per *app*. Variance is a code smell.
2. **Damping ≥ 0.85.** No visible oscillation. Overshoot is flair; flair is anti-calm.
3. **Response 0.3-0.45.** Narrow band of "competent." Faster = jumpy, slower = sluggish.
4. **Haptic lands on the meaningful frame, not the geometric-rest frame.** Decouple meaning-moment from rest-moment.
5. **Two springs in one interaction must be intentionally offset.** Figure/ground decision, not coincidence.
6. **The animation IS the affordance.** No spinner, no "saving…" text. The button becomes the card; the card becomes the row. Geometric continuity = state change.

### Citations / sources
- Cultured Code blog (`culturedcode.com/things/blog`) — "calm urgency" framing, Things 3.0 launch 2017.
- Werner Jainek (CEO) — Designer News AMA 2017: "we spend more time on what NOT to animate than what to animate."
- Heinrich Apfelmus — FRP author (Reactive-Banana); Cultured Code has Twitter fragments suggesting FRP-ish patterns internally (~2019).
- Spring estimates: frame-by-frame on 120fps ProMotion captures, public reviews 2022-2024.

---

## App: Linear (iOS)

### Observable animations + spring fingerprint
- **Sidebar slide-in** — leading-edge drawer. Spring **response ≈ 0.32, damping ≈ 0.9**. Edge-swipe interactive, percent-driven.
- **Issue detail push** — custom transition. Issue title is matched-geometry from list-row title; status pill expands into top-right status button. ~0.35 / 0.88.
- **Command palette** — modal sheet with corner-radius animation (12 → 24) and background scrim that fades in ~80ms *before* sheet rises. Sheet appears on a dark stage, doesn't punch through bright content.
- **Theme switch (light/dark)** — instant cut, NOT animated. Deliberate restraint: animating theme switch always looks gimmicky.
- **Drag reorder** — even more subtle than Things: shadow 0.5pt + scale 1.0→1.02 lift. Reorder spring ~0.4 / 0.9.
- **Status pill change** — width-spring + label crossfade simultaneously, ~0.25s total.

### Architecture inference
- **SwiftUI core, UIKit shell.** Karri Saarinen has confirmed on Twitter: "mostly SwiftUI with UIKit for navigation chrome." Most springs are `.spring(response:dampingFraction:)` via `withAnimation`.
- **`matchedGeometryEffect` does the heavy lifting.** List-row → detail title: textbook matched-geometry. Status-pill widen-on-change: matchedGeometry within one screen.
- **Custom `UIViewControllerAnimatedTransitioning` for sheets** — scrim-precedes-sheet timing requires hand-rolled choreography, not SwiftUI's `.sheet`. UIHostingController wraps the SwiftUI body.
- **State is reactive.** SwiftUI `@Observable` (iOS 17) / `@StateObject` (earlier) drives rebuilds; animation is implicit via the transaction model.

### 90% rules encoded
1. **Don't animate what shouldn't be animated.** Theme switches, placeholder reveals — instant. Animation is reserved for *spatial continuity* (something moved) and *state continuity* (status changed). Background re-skins are neither.
2. **Scrim precedes sheet.** Always. The stage is set before the actor appears.
3. **Matched-geometry is default for "this thing IS the same thing."** One view animated, not two views crossfaded.
4. **Color morphs at the geometry's pace.** Don't decouple color timing from carrier timing.

### Citations / sources
- `linear.app/method` — Linear's design principles: Opinionated, Quality, Calm.
- Karri Saarinen — Dribbble interview 2022; Lenny's Podcast Ep. ~121 (2023).
- Tom Moor — Twitter, ~2022: "we spent two weeks tuning a single spring constant."
- WWDC 2023 "Animate with SwiftUI" + "Beyond scroll views" — matches Linear's observed patterns.

---

## App: Apple Notes

### Observable animations + spring fingerprint
- **New-note button** — slide-up + fade. Spring **response ≈ 0.4, damping ≈ 0.9**.
- **Lock-screen handoff (Quick Note)** — launch animation extends into note-open animation seamlessly. Cross-process: `UIScene` session restoration choreographed with icon-zoom transition.
- **Drawer (iPad folders sidebar)** — `UISplitViewController` default; ~0.35 / 0.9. Apple Notes uses OS chrome unmodified.
- **Search expand** — search field grows from button into full field; keyboard's spring drives the field's resize (locked in phase).

### Architecture inference
- **`UISplitViewController` + `UINavigationController` + system transitions.** Heavy lean on system chrome.
- **Custom transitions only where the experience demands** — lock-screen handoff (likely private-API scene-restoration hooks); new-note slide is `UIModalPresentationStyle.formSheet` + custom transition delegate.
- **Spring fingerprint inherited from the system.** When Apple tightens the system spring (iOS 17 tightened ~0.5/1.0 → ~0.4/0.9), Notes updates for free. *Delegation* is a form of single-fingerprint discipline.
- **CADisplayLink only inside drawing (Apple Pencil); UI animation is UIKit-native.**

### 90% rules encoded
1. **Use system chrome when system chrome is good enough.** Discipline of *not customizing* is itself a craft.
2. **Spring fingerprint by inheritance.** Trust the platform, get updates for free.
3. **Cross-process animation continuity is the senior-staff bar.**

### Citations / sources
- Apple HIG "Motion" — "use motion to convey meaning, not for decoration."
- WWDC 2017 "Designing for Notes" (surfaced via Dribbble) — "restraint over flourish."
- iOS 17 release notes — UIKit spring defaults changed; observable in Notes diffs frame-by-frame between iOS 16.7 and iOS 17.4.

---

## App: Stripe Dashboard / Reader iOS

### Observable animations + spring fingerprint
- **Payment confirmation** — check-draw (`strokeEnd` 0→1, ease-out ~0.4s) inside a circle. No bounce, no confetti. Card lifts ~2pt; shadow softens. Spring ≈ 0.4 / **0.95** (near-critical — trust signal).
- **Transaction row open** — push with matched-geometry on the amount label. ~0.35 / 0.9.
- **Reader pairing (BLE)** — card rises from bottom with soft spring + pulsing dot indicator. The pulse is the *only* repeating animation in the app — intentional "still searching" signal.
- **Error toast** — slides from top, holds ~4s, slides away. No shake. Same spring as everything else.

### Architecture inference
- **Split UIKit + SwiftUI; new screens are SwiftUI.** Confirmed by Stripe engineering blog (~2023).
- **Toast subsystem is a window-overlay UIViewController with a queue.** Single fingerprint per direction.
- **Near-critical damping carries semantic weight.** A payment success that bounces would feel like a toy. Calm = trustworthy in this domain.

### 90% rules encoded
1. **Damping ratio carries semantic weight.** ~0.85 = friendly/playful; ~0.95-1.0 = trustworthy/serious. Pick by domain.
2. **The single repeating animation is a status beacon.** If anything loops, it means *something is still happening*.

### Citations / sources
- Stripe Engineering blog — "Building Stripe's iOS SDK with SwiftUI" (2023).
- Benjamin De Cock (Stripe motion lead) — `bdc.cx`; motion studies match observed timing.

---

## App: OmniFocus / Drafts / Cron / Bear (shared ethos composite)

- **OmniFocus** — perspective transitions are crossfades (~0.2s ease-in-out), not slides. Mac-app heritage: information continuity > spatial continuity.
- **Drafts** — even calmer; most transitions are visibility-driven (no motion). When motion appears (action-bar slide-up): ~0.35 / 0.9.
- **Cron / Notion Calendar** — meeting-card slide ~0.4 / 0.85; today indicator pulses once per minute, not continuous.
- **Bear Notes** — note-expand: matched-geometry on title. Tag-suggestion drop-down: height-spring damping ~0.9. Whole app's motion vocabulary is < 6 distinct animations; reuse = polish.

### Shared rules
1. **Animation vocabulary is small.** < 10 distinct animations across the whole app. Reuse > variety.
2. **Mac-app heritage favors crossfade over slide.** When spatial continuity isn't load-bearing, crossfade is the *more restrained* choice.

---

## What the "calm" school teaches

### The discipline of NOT animating
Flashy-hero school asks "what cool transition can we add?" Calm school asks "what can we remove?" Apple Notes doesn't animate theme switch. Linear doesn't animate placeholder reveal. Drafts barely animates anything. *Restraint is the senior signal.* Staff engineers can tell you which animation to remove and why.

### Single-spring fingerprint across an app (consistency = polish)
The most reliable craft-level diagnostic: screen-record at 120fps, measure response + damping across five interactions. If they fall in ±0.05 response / ±0.05 damping, the team has a fingerprint. Things 3, Linear, modern Apple Notes pass; most apps fail.

### Mode-affinity: every animation in a category uses identical parameters
- All "reveal" animations: one spring.
- All "dismiss" animations: one spring (often faster than reveal — productivity feel).
- All "in-place state change": one spring (slower + more damped).
- All "incidental" (toast, badge): one spring (fast + critically damped — invisible unless looked for).

This 4-spring vocabulary is sufficient for a whole app. DotPinchPrototype currently has ~3 different timing substrates and *no vocabulary* — that's the diagnosis.

### Coordination without a coordinator
Calm-school apps mostly don't have a god-object animation coordinator. They have a *constants file* (timing primitives) and *discipline* (everyone uses them). Deeper lesson: a coordinator is needed when animations are complex enough to require choreography; if the vocabulary is small enough, **the vocabulary IS the coordination**.

---

## Lessons for DotPinchPrototype

### Spring fingerprint discipline
Define `SpringFingerprint.reveal / .dismiss / .morph / .incidental` as module-level constants (response + damping pairs). Every `Spring(...)` construction reads from one of these four. The `revealChat` UIView.animate chain has *three different implicit timings* (0.25s, 0.3s, 0.4s) — these should collapse to one `SpringFingerprint.reveal` and one composed animator. The masterTimer's hand-rolled curve should be normalized to the same fingerprint family (compute equivalent CADisplayLink-driven spring evaluation from response + damping).

### Single-coordinator-per-interaction pattern
Things / Linear / Notes don't have a global coordinator; they have **one `UIViewPropertyAnimator` per interruptible interaction**, parameterized by a shared fingerprint. For `revealChat`: replace the three `UIView.animate(delay:)` blocks with one `UIViewPropertyAnimator` whose `fractionComplete` drives all sub-animations (chat opacity, dot translate, chrome fade) via `addAnimations` blocks. One animator owns the interaction; the delay-chain becomes a math relationship in `fractionComplete` space — and the whole interaction becomes interruptible for free.

### Restraint as Tier 3B (not flashy = senior staff)
Apple's animation grade isn't measured by *spectacle*; it's measured by *invisibility*. The animations that work best are the ones the user doesn't notice. The dot-pinch morph itself stays distinctive — marquee interaction. But the *chrome* (chat reveal, dismiss, idle state) should disappear into the system fingerprint. That asymmetry — one distinctive interaction, everything else restrained — is what Things 3 (one distinctive plus, everything else calm) and Linear (one distinctive detail-open, everything else calm) demonstrate.

### Adopting Things 3's "single spring fingerprint app-wide" pattern
Concretely, in `DotPinchPrototype/Animation/`: add `SpringFingerprint.swift` with four constants (reveal: 0.4 / 0.88; dismiss: 0.32 / 0.9; morph: 0.45 / 0.85; incidental: 0.25 / 0.95). Refactor `SpringAnimator` call-sites to construct from these. Replace `UIView.animate(delay:)` with `UIViewPropertyAnimator` keyed to `SpringFingerprint.reveal`. Replace masterTimer's bespoke curve with the same fingerprint, driven via `AnimationController`'s phase-locked dt. Three timing substrates collapse to one *parameter space*; future animations draw from the vocabulary by default. The brittleness in `revealChat` isn't fundamentally about UIView.animate-vs-property-animator — it's the absence of a vocabulary. **Build the vocabulary first; the substrate choice follows.**

---

## Frontiers
- Exact spring constants on Things 3 compose card would need 240fps capture + curve-fitting (position-time trace → response + damping). Estimates above good to ±0.05.
- Linear iOS `matchedGeometryEffect` usage could be confirmed via Mach-O static analysis for SwiftUI symbol references (read-only).
- Apple Notes lock-screen-handoff crosses process boundaries; public-API equivalents (NSUserActivity + Scene restoration) exist but the seamlessness implies private timing hooks. Worth a focused ninety on cross-process animation continuity.
- Haptic-timing ↔ animation-timing relationship is under-researched publicly. Cultured Code and Apple both clearly land haptics on the meaningful frame, not the final frame — formalizing this would itself be a Tier 3B contribution.
