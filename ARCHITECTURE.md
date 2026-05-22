# DotPinchPrototype — Architecture

A pinch-to-memory interaction prototype: a vertical timeline of conversation cells that morph into a chat view on tap, and dismiss back to the list via pinch or an explicit `↖` button.

**Reference inspiration**: [Dot's pinch-to-memory interaction on X / @spottedinprod](https://x.com/spottedinprod/status/1812905594388463794?s=20). The forward morph in this prototype mirrors the reference closely. The reverse direction (chat → cells) is the one I'm least satisfied with and have flagged below as the immediate next thing to refine — see [Section: The reverse direction isn't quite right yet](#the-reverse-direction-isnt-quite-right-yet).

This document is structured to answer four questions directly: **what patterns I chose**, **why**, **how they scale**, and **where they'd start to break down**. Before any of that, it covers the process — because the patterns only make sense in the context of how they were arrived at.

---

## The problem

The brief was to take inspiration from a reference UI and bring it to life as a native iOS app, with attention to fine details over breadth. The inspiration was Dot's pinch-to-memory interaction — a video where you can see a chat conversation collapse back into a card on the timeline through a multi-second, multi-property morph.

Calling this "build a screen that opens another screen" understates the work. The actual job is:
- Reproduce a gesture-driven multi-property morph that runs at 60–120 Hz
- Make the gesture feel right at the level of perception, not the level of "does it work"
- Handle edge cases (first cell, last cell, partial pinches, mid-flight interruption) without breaking visual continuity
- Do it on iOS with no off-the-shelf component that does this — Apple's UIKit and SwiftUI both stop short

Animation work has a property other engineering doesn't: a bug isn't "wrong output." A bug is "the user can tell something feels off but can't articulate why." Diagnosing that requires a different kind of effort than diagnosing a stack trace. You have to slow the world down.

---

## The process: how the decisions got made

Two methodological choices made the difference between a prototype that compiles and one whose decisions can be defended in writing.

### 1. Frame-by-frame analysis of the reference

The reference dismiss is a ~3-second animation. At 60 fps that's 180 distinct frames, each potentially showing a different combination of visual properties at different stages of their respective curves. Watching the video at normal speed, you can tell something good is happening. You cannot tell which thing is happening when.

I extracted frames using ffmpeg at 12 fps across the 3-second dismiss window (seconds 5–8 of the reference video) and stepped through them one at a time:

```bash
ffmpeg -ss 5 -t 3 -i _frames/dot_pinch.mov -vf "fps=12,scale=400:-1" \
       /tmp/dense_%02d.png
```

This produced 36 dense frames. I then asked Claude to look at each frame in sequence and describe what was changing — specifically which visual property was at what stage of its animation. The output of that pass is documented in `research/animation_architecture/00_gauge.md` and downstream files.

What that frame-by-frame revealed was the **phase map**: seven distinct visual primitives that move in carefully staggered sequence, not in parallel.

| Phase | Window in dismiss | Primitive |
|---|---|---|
| 1 | 0.0–0.4s | Chat content gaussian blur ramps up |
| 2 | 0.3–0.7s | Keyboard slides down, composer fades |
| 3 | 0.4–0.9s | Page chrome icons (`↖`, `⋯`) fade in |
| 4 | 0.5–1.4s | Page gradient cross-fades into view |
| 5 | 0.8–1.6s | Chat card resolves (cornerRadius, slight inset) |
| 6 | 1.4–2.2s | Camera scrolls, neighbor cells slide in |
| 7 | 2.0–3.0s | Cell content materializes (date, body, glyph) |

Notice that phases overlap. The keyboard is still exiting when the chrome icons start fading in. The chat card is still resolving when the camera starts scrolling. **Each property has its own curve, and the orchestration is offset timing across a shared progress source.**

This finding — that staggered timing across a single progress source is the convergent industry pattern — became the central architectural decision (see Pattern #2 below). It was not knowable from reading documentation. It was visible only frame-by-frame.

### 2. The `/lens-check` skill chain

Before writing any code for the morph, I ran a multi-stage research protocol — what I call the `/lens-check` chain — to map the full landscape of how this kind of animation is done across the iOS ecosystem, not just how I'd happen to do it.

The chain has four phases:

**`/gauge`** — calibrate the current state. What tier am I operating at? What primitives am I reaching for by default? What blind spots am I bringing in? Result: documented in `research/animation_architecture/00_gauge.md`. Concluded the project was operating at Tier 2B (well-built UIKit) and needed to reach Tier 3 (Apple-grade feel) — a meaningful jump in technique, not just polish.

**`/cartography`** — enumerate every public iOS primitive that could plausibly address the problem. UIKit / Core Animation primitives, SwiftUI primitives, open-source libraries, coordinator patterns. Result: `research/animation_architecture/01_cartography/` (4 files, surveying UIKit/CA, SwiftUI, open-source libs, and orchestration patterns). The goal was to choose primitives from the full menu rather than from default reach.

**`/ninety`** — survey premium consumer apps to understand how the highest-quality iOS animations are actually built. Apple Music, Apple Notes, Things 3, Linear, Cash App, Airbnb, Instagram, Telegram-iOS. Result: `research/animation_architecture/02_ninety/` (10 files), plus a metacognitive review of cross-app patterns. The key finding from this phase was the convergent pattern: every premium app uses **one progress source driving N derived properties** for multi-property morphs. Things 3, Linear, Apple Music's track-change crossfade, Telegram-iOS message transitions — they all converge on this same shape, with different specific curves but the same architecture.

**`/conjecture`** — synthesize a calibrated approach. Given the cartography of available primitives AND the patterns observed in premium apps, what specific composition fits THIS app's problem?

This was the inverse of "just start coding." It was three days of mapping the landscape before committing to any particular implementation. The patterns documented below are not the first thing I thought of — they are what survived the research.

---

## The four core patterns

### Pattern 1: Transform-not-frame morph

**What it is.** The cells in the timeline have a fixed natural height (200 points). When a cell "expands" into the chat-rest visual that fills the viewport, the cell's actual frame **does not change**. Instead, the cell's parent (a UIView called `contentHost`) gets a CALayer transform applied — scale ~4.92x and translate-Y — which makes the cell visually fill the viewport without anything resizing in the layout system.

**Why.** Two reasons.

The first is performance. If you grew the cell's height from 200pt to 992pt directly (by animating an Auto Layout height constraint), you'd trigger a full Auto Layout pass for every frame of the animation — 60 to 120 times per second. Auto Layout is expensive. Transforms are not — they are composited on the GPU. The difference shows up as "smooth" vs "drops frames on a 4-year-old phone."

The second is independence. The cell has internal subviews (date label, summary text, day marker, pinch glyph). If the cell's frame were changing, every subview would re-layout. By keeping the frame fixed and applying transforms at the parent layer, the cell's internal world doesn't know the morph is happening. Cell code stays decoupled from morph timing. You can change the morph's duration without touching cell code.

**Non-technical version.** Imagine you want to make a small Polaroid photo appear to grow into a poster on the wall. You could redraw the Polaroid at every intermediate size, paying for paper and ink each step. Or you could leave the Polaroid alone and use a magnifying glass — same visual effect, almost zero cost. The transform approach is the magnifying glass. The Auto Layout approach is redrawing the Polaroid 120 times.

**How it scales.** A timeline of 4 cells, 40 cells, or 4000 cells has the same per-frame cost during morph: one transform on one parent layer. The cost scales with visible cells (for camera scroll), not with morph itself.

**Where it'd break down.** Two places. First, the chat-rest visual is held by **four persistent CABasicAnimations** that accumulate additively on the contentHost's transform. They use `fillMode: .forwards` and `isRemovedOnCompletion: false` — meaning they stay attached to the layer indefinitely, holding the layer at its final value. If a developer accidentally triggers the forward morph twice in a row without an intervening dismiss (which strips those animations), the additive scale compounds — 4.92 + 4.92 = 9.84, and the cell would scale to twice the intended size. This is guarded by a single `if animation == nil { return }` check, which is fail-open: a new code path could miss the guard. A more robust version would model the morph as an explicit state machine with `idle / morphing / chat-rest / dismissing` states.

Second, the rounded corner radius on cells (locked at 25pt by design) scales with the transform — at chat-rest it visually renders as 25 × 4.92 = 124pt of curve. For boundary cells (first cell, last cell), this rounded corner cuts into the viewport and exposes the layer behind. Section "Where it'd break down" below discusses how this is mitigated and where the mitigation is cosmetic vs principled.

---

### Pattern 2: Single progress source driving N derived properties

**What it is.** The pinch-to-dismiss morph has approximately ten visual properties moving at the same time — chat scale, chat alpha, blur intensity, cornerRadius, page gradient opacity, chrome icon opacity, cell content opacity, centered label opacity, camera position, contentHost transform. Rather than animating each one independently with its own duration and easing, the entire morph is driven by a **single floating-point number** called `dismissProgress`, ranging from 0 (chat-rest, fully expanded) to 1 (cell-rest, fully dismissed).

Each derived property is computed from `dismissProgress` via a `smoothstep` function with its own active window. For example: chat alpha fades during the window `[0.45, 0.85]`, blur during `[0.4, 0.85]`, cornerRadius during `[0.5, 0.9]`, page gradient cross-fade during `[0.55, 0.95]`, cell content fade-in during `[0.7, 1.0]`. The fact that the windows overlap and are offset is what produces the staggered choreography from the frame-by-frame analysis.

**Why.** This is the convergent pattern from the `/ninety` survey. Apple Music's track-change, Things 3's add-to-inbox, Linear's transitions, Telegram-iOS's message bubble morphs — they all use this shape. The alternative (independent animations per property) was tried first by the iOS ecosystem and abandoned because of two failure modes:

1. **Animations drift in timing.** Multiple `UIView.animate(delay:)` calls with different durations look synchronized in the simulator but drift on device because VSync misses and main-thread contention affect each animation independently. A single progress source can't drift relative to itself.

2. **Cancellation is impossible.** If a user starts to dismiss, then changes their mind mid-gesture, you need every property to reverse direction simultaneously and continue from where it currently is. Independent animations would each "snap" to a new target. A single progress source just decreases instead of increasing — same code path, same orchestration, no special-case logic.

The `setDismissProgress(_:)` function is called by **two different drivers**: during the pinch gesture (`progress = (1 - recognizer.scale) × 2`, clamped) and during the spring resolution after release (a CADisplayLink interpolating from the current progress toward 0 or 1 via cubic ease-in-out). The function doesn't know which one is calling it — it just maps progress to properties.

**Non-technical version.** Imagine conducting an orchestra. The bad way is to tell every musician their own tempo and trust them to keep time. The good way is to hold a baton — every musician follows the baton. If the baton speeds up, everyone speeds up together. If you stop the baton in the middle of the bar, the orchestra stops in lock-step. The single progress source is the baton. The visual properties are the musicians.

**How it scales.** Adding a new visual property to the morph means writing one line: `someProperty = smoothstep(start, end, p)`. The orchestration cost is constant per property. Going from 10 properties to 50 doesn't change the architecture, just lengthens the function.

**Where it'd break down.** Three places.

First, the curves are hand-tuned smoothstep windows. The values `(0.45, 0.85)` for chat alpha, `(0.55, 0.95)` for gradient cross-fade — these came from iterating against the reference video frame-by-frame. A redesign of the morph (different reference, different feel) would require re-tuning all the windows. There's no abstraction layer for "what does this morph feel like" — only the curves themselves. A more mature system might have named feel profiles ("settle", "snap", "drift") that compose multiple curves.

Second, the progress source is one-dimensional. What if the user starts pinching, releases briefly, then pinches again? Today the display link interpolates to 0, and the next pinch starts from progress 0. A more sophisticated state machine could preserve momentum across micro-gestures, but this prototype doesn't.

Third, accessibility. The morph doesn't respect `UIAccessibility.isReduceMotionEnabled`. The right behavior would be: when reduce-motion is on, skip the staggered morph entirely and crossfade between cell-rest and chat-rest in 0.2s. Not implemented.

---

### Pattern 3: Captured state + animation stripping

**What it is.** The chat-rest visual state is held in place by four persistent CABasicAnimations on the parent layer. These animations have `fillMode: .forwards` and `isRemovedOnCompletion: false` — they don't disappear after their duration; they sit on the layer forever, holding it at its final value. This is what makes the chat-rest visual stable when no other animation is running.

To **reverse** the morph, you cannot just remove those animations. Removing them would snap the layer back to its identity transform — instantly cell-rest, no animation. The model layer's value is identity; only the presentation layer (what's on screen) shows the chat-rest state.

The pattern: at the start of a dismiss, **read the presentation layer's current transform** (where the layer actually is on screen right now), **strip the persistent animations**, **set the model layer to the captured presentation value** (so the layer doesn't jump), then **drive the model layer to identity** through the dismiss progress.

```swift
let presentation = contentHost.layer.presentation()?.transform
                                                ?? contentHost.layer.transform
contentHost.layer.removeAnimation(forKey: "windup.scale")
contentHost.layer.removeAnimation(forKey: "zoom.scale")
contentHost.layer.removeAnimation(forKey: "windup.translate")
contentHost.layer.removeAnimation(forKey: "morph.centering")
contentHost.layer.transform = presentation  // pin model to where presentation is
// Now we can animate the model freely
```

**Why.** Because Core Animation has two layers per layer: the model layer (what your code reads and writes) and the presentation layer (what the GPU actually renders). They diverge during animation. Code that ignores this distinction reads the model layer (which says "identity, scale 1") and concludes the animation never happened, even though the screen shows the chat-rest state.

This is one of the genuinely tricky things about Core Animation — the documentation mentions it in passing but doesn't surface the pattern for reversing a persistent animation. The pattern is folklore: you learn it by getting bitten.

**Non-technical version.** Imagine writing a number on a piece of glass with a marker, then holding a colored gel over it. The gel makes the number look red. To remove the red without losing the number, you can't just pull off the gel (that would reset the visual). You first record what color the visual currently shows, write THAT color onto the glass with the marker, then remove the gel. The visual stays continuous because the marker now matches what the gel was showing. Now you can change the marker color smoothly to whatever you want.

**How it scales.** The pattern is the same regardless of how many animations are on the layer. The capture step reads the current presentation; the strip step removes by key; the pin step writes the captured value back to the model. Three lines of additional code per dismissed morph.

**Where it'd break down.** Single layers. If a future version of the morph distributes the chat-rest state across multiple layers (say, contentHost transform, page gradient opacity, edge mask opacities, all set via persistent animations), each one needs its own capture-strip-pin sequence. The bookkeeping grows linearly. Right now the prototype has this dispersion for the page gradient already, and it works, but each addition costs.

Second: relying on the presentation layer being available. `contentHost.layer.presentation()` can return `nil` if the layer is offscreen or in a pending state. The pattern handles this via a fallback (`?? contentHost.layer.transform`), but the fallback is the model layer — which is identity — which would snap. In practice this never fires because the layer is on screen when dismiss begins, but it's a latent risk if the dismiss could ever fire from off-screen state.

---

### Pattern 4: UILongPressGestureRecognizer-as-tap for press feedback

**What it is.** Every cell in the timeline gives press-feedback on touch-down: a subtle scale dimple from 100% to 94% over 0.4 seconds with a cubic easeOut curve, accompanied by a light haptic. If the user holds the press past 0.3 seconds, a second `.rigid` haptic fires — escalation cue. On release, the scale springs back to identity and the same tap action fires as before (open the chat).

The natural choice would be a `UITapGestureRecognizer` that fires on touch-up. But UITap doesn't fire on touch-down — it waits for the full touch-up + criteria check (no movement, within tap timeout). That delay is too long for press feedback — by the time UITap fires, the user has already lifted their finger.

The alternative is `UILongPressGestureRecognizer` with `minimumPressDuration: 0`. This fires `.began` immediately on touch-down. We use that as the start signal for the scale ramp + haptic. On `.ended` (touch-up), we **manually fire the tap action** by calling `onTap?(index)` — the same callback the UITapGestureRecognizer would have fired.

**Why.** Two cascading reasons.

First, latency. UITap takes ~50–100ms minimum to recognize a tap (it has to wait through the tap timeout window to make sure it's not the first tap of a double-tap, etc.). Press feedback at 50ms is "delayed and laggy." Press feedback at 0ms is "responsive and crisp." Apple's own apps use the 0ms touch-down approach for buttons.

Second, gesture cascade conflict. iOS has implicit rules about which gestures can recognize when other gestures are active. When the cell-level LongPress enters `.began`, the cell-level UITapGestureRecognizer transitions to `.failed` (same-view conflict — they can't both fire), and the canvas-level UITapGestureRecognizer (which V2RootViewController had for click-detection) is held off waiting for the descendant gesture to fail. But LongPress doesn't fail — it succeeds via `.began → .ended`. The canvas tap never gets to fire either.

You can fight this with `gestureRecognizer(_:shouldRecognizeSimultaneouslyWith:)` delegates, but the cleaner solution is: **the LongPress takes over the tap responsibility**. It fires the tap action manually on `.ended`. No more conflict because there's only one gesture in the chain that's relevant — the LongPress.

**Non-technical version.** A doorbell with two buttons. The right button rings the bell, but it has a 1-second delay before the bell actually rings. The left button doesn't have a delay, but it doesn't ring the bell — it just plays a click sound when pressed. We want both behaviors: instant click (press feedback) AND ringing bell (action). The solution: wire up the left button (instant click) to also ring the bell when released. Disconnect the right button entirely. Same end result, faster front end.

**How it scales.** Each cell has its own LongPress + display link + haptic generators. Pool-based cell recycling means there are at most ~10-15 cells alive at once. Each press feedback session uses exactly one display link, only while the press is active. Memory and CPU are bounded.

**Where it'd break down.** Edge cases in gesture lifecycle. If the user starts a press, then drags their finger off the cell by more than 10 points (UILongPressGestureRecognizer's `allowableMovement`), the gesture transitions to `.cancelled` — no tap fires. This is correct (drag-off-cell aborts the tap), but it can feel surprising if the user just slightly twitches.

Worse: if the user starts a press DURING the forward morph (cell already scaling up), the cell-level LongPress still fires `.began` because gestures don't pause for animations. The press feedback's scale composes with the morph's scale, briefly producing a stutter as both transforms run. This is barely visible, but a more refined version would disable the gesture on the active cell during morph.

---

## The reverse direction isn't quite right yet

To be honest about where the prototype lands relative to the reference: **the forward morph (cell → chat) is the closest to the reference. The reverse morph (chat → cells) is the one I'm not yet satisfied with**, and it's the immediate next thing I'd work on.

Specifically:

- **The chat doesn't shrink-and-land on the cell with the same physicality as the reference**. In the reference, the chat collapses back to a cell-shaped card that visibly "becomes" the cell at its position in the list — you can feel it landing. In this prototype, the chat shrinks via a similarity transform that targets the cell's projected viewport position, but the landing reads as more of a fade-out than a settle. The similarity transform is uniform scale, which preserves text legibility during the shrink but can't reshape into the cell's specific aspect ratio (chat is portrait-tall, cell is wider-than-tall). The reference appears to handle this by also changing the chat's bounds (not just scale), so the chat actually reshapes into a card. Implementing that is on the next-up list.

- **Mid-dismiss, when the chat is shrunk small and partially transparent, the underlying cell list is still in an in-between state visually**. The page gradient is mid-fade, neighbor cells are appearing, the active cell's content is just starting to materialize. The reference handles this with a more orchestrated cross-fade where the chat-card transformation lines up more precisely with the cell-card materialization. There's specifically a moment in the reference where you can tell that ONE THING is happening (a chat-card becoming a cell-card), whereas in this prototype it reads as TWO things happening (chat fading + cell list appearing). They're close in time but they're not unified.

- **The reverse spring damping doesn't yet match the reference's settle feel**. The cubic ease-in-out on the dismiss progress is functional but doesn't have the "weighted" quality of the reference's resolution. A spring-physics resolution with a specific damping ratio (probably ~0.75–0.85) would feel closer.

I documented this honestly because:

1. Animation work is iterative. The forward morph took multiple passes against the frame-by-frame reference to land. The reverse direction needed similar iteration time, which I ran out of.

2. The patterns covered above (single progress source, captured state + animation stripping, transform-not-frame) all hold for the reverse direction. The gap isn't architectural — it's tuning and the matchedGeometry-style cross-fade hookup. The work to close it is bounded.

3. The honest comparison against the reference is more useful than a polished claim of completion. You can see the gap by toggling between the prototype's dismiss and the reference video — they're close but not the same animation yet.

---

## How they scale (the whole system)

| Dimension | Today's load | Estimated limit | Why |
|---|---|---|---|
| Cells in dataset | 4 | thousands | Pool-based recycling, only visible-range cells instantiated |
| Cells alive at once | ~10 | ~50 | Bounded by visible viewport + cullMargin |
| Forward morph frame cost | 1 GPU transform | unbounded | Single transform on contentHost.layer |
| Dismiss orchestration cost | ~10 model writes / frame | ~50 properties | Each smoothstep is O(1) |
| Press feedback per cell | 1 gesture + 1 display link (active only) | per-cell | Display link only during press |
| Memory per cell | ~100 KB (subviews + layer) | bounded by pool | Recycling |

The single architectural decision that determines scale is **Pattern 1 (transform-not-frame morph)**. Because cells don't change frame during chat-rest, you can have 10,000 cells in the data source and the morph cost is constant. Scrolling is the only operation that scales with cell count, and scrolling is mature in UIKit.

---

## Where they'd start to break down

Honest accounting of failure modes the prototype does not solve.

### Boundary cells (first / last)

When the active cell is at the top or bottom of the page, the parent transform must translate the contentHost a long way (1000+ points) to center the cell in the viewport, while simultaneously scaling 4.92x. Mid-morph, the cell occupies only part of the viewport, and there are no neighbor cells beyond the page edge to fill the gap. The rounded corner radius (124pt at chat-rest scale) cuts into the visible area, exposing whatever is behind contentHost.

Mitigations applied:
- `V2RootViewController.view.backgroundColor = Theme.Cell.fill` so the exposed area matches the cell color (no visible boundary)
- `pageGradientLayer.opacity` fades out during the morph so the mauve-pink gradient bottom doesn't bleed through corner cutouts
- `chatRestFactor` is set slightly above what would just fill viewport, ensuring corners are off-screen for cells that ARE properly centered

These are cosmetic — they hide the seam rather than eliminate it. A principled fix would pre-animate the camera so the cell is at viewport center BEFORE the scale begins. The cell would scale around its own already-centered position, never needing the long translation, never producing the gap.

### Interruptibility during forward morph

The forward morph is a sequence of CABasicAnimations that runs for 1.5 seconds. During that window, the cell is between cell-rest and chat-rest. If the user taps a different cell mid-morph, the second tap is blocked by a guard (`if windup.scale animation exists, return`). This is correct in that it prevents conflicting morphs, but it's also unforgiving — the user has to wait for the morph to complete before they can do anything else.

Apple-grade interruptibility would let mid-flight morphs reverse or redirect. Cancel the in-flight morph, capture its current presentation state via Pattern 3, then animate to the new target. Not implemented.

### Device + viewport variance

`chatRestFactor = (viewportH + 100 + 40) / naturalH ≈ 4.92` on iPhone 17 (852pt viewport). On older devices with shorter viewports, this factor decreases — and so does the visual "punch" of the morph. On iPad (1366pt viewport), it would increase to ~6.83, which might feel too aggressive. The animation feel is tied to viewport size; it's not independent.

A more robust system would tune the morph duration and curves per device class, treating "feel" as something that varies with screen geometry. Currently the prototype targets iPhone portrait only.

### Reduce Motion + Dynamic Type compliance

Not implemented. For ship-quality, the morph should degrade to a 200ms crossfade under Reduce Motion, and all text labels should respect Dynamic Type scaling. Both are accessibility table-stakes that this prototype skips. They would not require architectural change, just additional code.

### Composer non-interactivity

The composer text field's interaction is disabled to prevent the keyboard from appearing (since this prototype has no message-send logic). The placeholder "Share with Dot…" still suggests interactivity. A real version would either implement the composer or visually mark it as disabled — neither is done.

### Animation timing values are inline magic numbers

The smoothstep windows (`(0.45, 0.85)` for chat alpha, etc.) live as literal numbers in `setDismissProgress(_:)`. They were chosen by iterating against the reference video. There's no design-token layer for animation timing — no `MotionTokens.swift` with named profiles like `MotionTokens.dismiss.chatAlpha = .smoothstep(0.45, 0.85)`. As the number of morphs grows, this becomes unsustainable.

---

## What I'd build next (with two more weeks)

In priority order:

1. **Close the reverse-morph gap** — this is the single biggest thing. As documented above, the chat → cells direction doesn't yet match the reference's landing-physicality. The fix is a combination of (a) animating chat bounds in addition to scale, so the chat actually reshapes into a card rather than just shrinking uniformly, (b) a matchedGeometry-style cross-fade where chat-content elements interpolate to their cell-content counterparts (header → date label, first bubble → topic summary), and (c) replacing the cubic ease-in-out with a spring resolution. Each is incremental work against the existing single-progress-source orchestrator; no architectural change required.

2. **Pre-camera-animation for boundary cells** — eliminate the mid-morph gap by centering the camera before the scale begins. Removes the cosmetic mitigations.

3. **Reduce Motion + Dynamic Type compliance** — non-negotiable for ship.

4. **Interactive forward morph** — pinch-to-expand from the cell, mirroring the pinch-to-dismiss. Reuses Pattern 2 (single progress source). Forward and reverse become a single bidirectional state machine. The biggest architectural win for "feels Apple-grade."

5. **Animation design tokens** — extract the smoothstep windows + spring profiles into a `Motion.swift` token file. Same pattern as `Theme.swift` for colors. Makes future morphs composable from named primitives.

6. **Snapshot regression tests** — for animation-heavy code, golden-image diffs on key frames catch regressions early. Not implemented; would be the first thing I add for production.

7. **Live data integration** — currently dummy conversations. A real version would integrate with a backend, paginate, handle empty/loading/error states.

---

## File map

| Concern | File |
|---|---|
| Root coordinator, dismiss orchestrator | `DotPinchPrototype/App/V2RootViewController.swift` |
| Canvas, cell pool, forward morph, gradient | `DotPinchPrototype/Conversation/V2/TimelineCanvas.swift` |
| Cell visual + press feedback | `DotPinchPrototype/Conversation/V2/CellView.swift` |
| Chat interface, expand button, composer | `DotPinchPrototype/Conversation/V2/ChatViewController.swift` |
| Springs + animation timing primitives | `DotPinchPrototype/Animation/` |
| Theme tokens (colors, radii, typography) | `DotPinchPrototype/DesignSystem/Theme.swift` |

## Research artifacts

| Phase | Output |
|---|---|
| `/gauge` | `research/animation_architecture/00_gauge.md` |
| `/cartography` | `research/animation_architecture/01_cartography/c1-c4.md` (4 files: UIKit/CA, SwiftUI, open source, coordinators) |
| `/ninety` (premium apps survey) | `research/animation_architecture/02_ninety/n1-n5.md` (Airbnb, Apple system, Things/Linear/Notes, Telegram-iOS, industry frameworks) |
| `/ninety` (metacognitive) | `research/animation_architecture/02_ninety/m1-m5.md` (type architecture, testing, DI, design tokens, warm bundle) |
| Reference video analysis | `_frames/dot_pinch.mov` + frame extractions described above |

---

## What's hard about this and why it takes time

Writing this section explicitly because animation work tends to look like "should be easy" from outside.

A static UI is a static problem. There is a correct layout; you build it; it's done.

An animated UI is a perception problem. There is a target FEEL, which is not a number. You can describe it ("smooth, deliberate, weighty") but you cannot specify it. You arrive at it by iterating against a reference, frame by frame, comparing what you have to what you want, adjusting curves and durations and offsets, watching the difference shrink.

This is why the frame-by-frame analysis matters. Without it, you cannot tell where the difference is — only that there is one. With it, you can say "the blur is too fast" or "the camera scrolls too late" specifically, and adjust specifically.

This is also why the `/lens-check` skill chain matters. Animation work has a deep tradition in iOS that doesn't have one canonical reference. Apple's own documentation covers individual primitives but not how they're composed at the level Apple's own apps compose them. Premium third-party apps (Things, Linear, Apple Music) have their own conventions. To choose primitives well, you have to map the landscape first — otherwise you're choosing from a truncated menu.

Two days of mapping + analyzing. Three days of building. One day of polish. Each phase compounds: skipping the mapping phase means the building phase produces working code that doesn't compose with the patterns the industry has converged on. Skipping the analysis phase means the polish phase has nothing concrete to iterate against — you're polishing toward a feel you can't articulate.

The work in this repo is small in scope (one screen, one transition, one gesture) but the technique it demonstrates scales. The same patterns — frame-by-frame analysis, single progress source, captured state + animation stripping, transform-not-frame composition — underpin every premium animation in the iOS ecosystem.

---

*Built as a take-home prototype. Targets iOS 17, iPhone portrait only. Single-target Xcode project (no SPM/CocoaPods dependencies). XcodeGen for project generation.*
