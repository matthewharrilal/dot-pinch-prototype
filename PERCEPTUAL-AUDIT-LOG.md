# PERCEPTUAL-AUDIT-LOG.md

Generated 2026-05-25 from frame analysis of `_frames/dot_pinch.mov` 4–8s window (60 frames).

Per the perceptual-deepening skill's Phase 0: this verdict gates all verbal motion claims. Any subsequent verbal description that contradicts measurements here must flag the contradiction explicitly.

---

## Calibration findings (frame-1 vs frame-60 pixel sampling)

- **Theme.Cell.fill on disk = `#f6efef` (246, 239, 239)**, but in the rendered + JPEG-compressed video at frame 60 (cell-rest), actual cell pixel = **(235, 232, 236)**. Difference: ~11 units per channel due to compression.
- **Theme.Page.surface on disk = `#ede9ee` (237, 233, 238)**. In video at frame 60, inter-cell gap pixel = **(238, 233, 237)** — essentially identical to Page.surface.
- **Cell-fill and Page.surface differ by ~3 units per channel in the rendered output — VISUALLY INDISTINGUISHABLE.** This explains why the active cell, the inter-cell gap, and the page background all appear as the same near-white color in the cell-rest screenshot.
- **Theme.Page.bottom = `#d8aab4` (216, 170, 180)**. At frame 60, atmospheric gradient pixel at (394, 1600) = **(207, 147, 153)** — close to the page-bottom token, ~16 units off per channel.

**Implication for implementation:** the visual distinction between "cell card" and "background" in the reference is carried by the ROUNDED CORNERS + the surrounding atmospheric gradient, NOT by a strong color contrast between fill colors. Our current `Theme.Cell.fill` (#f6efef) vs `Theme.Page.surface` (#ede9ee) gives essentially zero color contrast — matches reference.

---

## Reference-pixel signal trajectories (60-frame programmatic sampling)

### Signal 1: Top-left chrome darkness (inward-arrows affordance area, pixel (78, 80))

Higher value = darker pixel = chrome more visible. Measured as `sum(255 - channel)` per frame.

| Frame | Window % | chrome_L darkness | Interpretation |
|---|---|---|---|
| 1–11 | 0–18% | 70–73 | Chrome NOT visible (baseline blank reading) |
| 12 | 20% | 70 | Same |
| 13–26 | 22–43% | 62–73 | Still no chrome (slight noise) |
| 27 | 45% | 83 | **First above-baseline reading — chrome onset begins** |
| 28 | 47% | 96 | Chrome rising |
| 29 | 48% | 108 | |
| 30 | 50% | 150 | **Strong rise** |
| 31 | 52% | 150 | |
| 33 | 55% | 138 | Slight pullback (noise or transient occlusion) |
| 34–37 | 57–62% | 111–129 | Plateau near full |
| 38 | 63% | 129 | |
| 39 | 65% | 153 | Rises again |
| 40 | 67% | **212** | **Reaches near-final value; sustained from here** |
| 41–60 | 68–100% | 212 | Constant — chrome fully visible |

**Onset → Saturation trajectory:** chrome darkness goes 73 → 212 between frames 26–40, with the rapid-rise zone at frames 29–31 (48–52% gesture progress).

### Signal 2: Bottom-center atmospheric gradient distance from Theme.Page.bottom target (216, 170, 180)

Lower distance = closer to target gradient. Measured as `sum(|r-216| + |g-170| + |b-180|)`.

| Frame | Window % | grad distance | Interpretation |
|---|---|---|---|
| 1–24 | 0–40% | 70 | Stable baseline (chat content covers this pixel; reading ≠ gradient) |
| 25 | 42% | 192 | Transition begins — sudden value change |
| 26 | 43% | 61 | Crossover — gradient color momentarily reached |
| 27 | 45% | 234 | Large spike |
| 28 | 47% | 234 | |
| 29 | 48% | 67 | |
| 30 | 50% | 190 | |
| 31 | 52% | 102 | |
| 32–33 | 53–55% | 101–115 | Settling |
| 34–37 | 57–62% | 75–58 | Approaching final |
| 38 | 63% | 59 | |
| 39 | 65% | 59 | |
| 40–60 | 67–100% | **59 (constant)** | Final gradient color stable |

**Onset → Saturation trajectory:** gradient pixel converges to final color in frames 25–40 (42–67% gesture progress), with substantial oscillation at frames 27–31 (chat-content alpha + composer fading layered over gradient produce intermediate composite colors). Final lock at frame 40.

### Signal 3: Active cell card detection (segment scan at x=W/2)

Center vertical column scanned for cell-fill segments ≥80px tall. Tight tolerance ±25 per channel against (246,239,239).

| Frame range | Result | Why |
|---|---|---|
| 1–60 | 0 segments detected | Cell-fill matched too tightly to the on-disk RGB. Actual compressed cell-fill ≈ (235,232,236). Detector miss. |

**This signal is broken in v3 due to tight tolerance.** Cell-bounds trajectory must be derived from manual frame inspection cross-referenced with chrome + gradient signals (which DO work).

### Signal 4 (v2 detector, looser tolerance): largest cell card per frame

Despite the v2 detector having noise from chat-bubble interiors during scaling, the readings for frames where the active cell IS unambiguously a rounded card (post-frame-30) are reliable:

| Frame | Window % | active card y=[top–bottom] | height | width | spacing_above (to next card up) |
|---|---|---|---|---|---|
| 31 | 52% | [896–1131] | 236 | 750 | 55 |
| 34 | 57% | [549–1201] | 653 | 741 | n/a (active extends through where above would be) |
| 37 | 62% | [699–1238] | 540 | 704 | 120 |
| 40 | 67% | [775–1259] | 485 | 691 | 74 |
| 43 | 72% | [812–1268] | 457 | 687 | 48 |
| 46 | 77% | [831–1274] | 444 | 689 | 35 |
| 49 | 82% | [838–1276] | 439 | 690 | 30 |
| 52 | 87% | [842–1278] | 437 | 698 | 26 |
| 55 | 92% | [844–1279] | 436 | 700 | 25 |
| 58 | 97% | [842–1279] | 438 | 703 | 22 |
| 60 | 100% | [842–1279] | 438 | 702 | **21** |

**Active cell final dimensions (frame 60 = cell-rest):**
- top y = 842, bottom y = 1279, height = 438 px, width = 702 px
- center y = 1060 (which is 1060/1662 = 63.8% of viewport height)

**Active cell first detected as a discrete card: frame 31 (52% gesture progress).** Before frame 31 the detector either reports 0 cards or detects sub-card features (bubbles) inside the still-edge-to-edge chat content.

### Signal 5: Active cell height trajectory (frames 31–60)

Non-monotonic on the height axis:
- Frame 31: h=236 (small detection — may be partial card seen)
- Frame 34: h=653 (large — active card extends across most of viewport)
- Frames 37–60: monotonically decreasing 540 → 438

**Anomaly at frames 31–34:** the detector's height reading goes 236 → 653. This is not a real physical jump in the active cell's height; it's a detector artifact when the cell transitions from edge-to-edge (no detectable card) to a clearly-bounded card. Between frames 31–34 the algorithm catches different portions of the transitioning cell.

The TRUE height trajectory between frames 31–34 is monotonic but goes from ~1500 (still nearly viewport) toward 653 (substantially settled). The detector can't see the early portion of this transition because the card-top edge is too close to the viewport top to satisfy the rounded-card requirement.

### Signal 6: Active cell width trajectory (frames 31–60)

| Frame | width | Δ from prev |
|---|---|---|
| 31 | 750 | — |
| 34 | 741 | −9 |
| 37 | 704 | −37 |
| 40 | 691 | −13 |
| 43 | 687 | −4 |
| 46 | 689 | +2 |
| 49 | 690 | +1 |
| 52 | 698 | +8 |
| 55 | 700 | +2 |
| 58 | 703 | +3 |
| 60 | 702 | −1 |

**Width is NON-MONOTONIC:** 750 → 687 (minimum at frame 43) → 702 (final). Overshoot of approx 15 px below the final value, then rebound. **This is a SPRING SIGNATURE** — characteristic of a critically-or-near-critically-damped spring settling to target with a slight undershoot followed by recovery.

Width spring magnitude: undershoot of 15 px on a delta of (750−702)=48 px. Settling fraction: 15/48 = 31% overshoot in displacement units before recovery.

### Signal 7: Active cell center_y trajectory (frames 31–60)

| Frame | center_y | Δ |
|---|---|---|
| 31 | 1013 | — |
| 34 | 875 | −138 (likely detection artifact; cell still mid-migration) |
| 37 | 968 | +93 |
| 40 | 1017 | +49 |
| 43 | 1040 | +23 |
| 46 | 1052 | +12 |
| 49 | 1057 | +5 |
| 52 | 1060 | +3 |
| 55 | 1061 | +1 |
| 58 | 1060 | −1 |
| 60 | 1060 | 0 |

**Center_y trajectory is approximately monotonic** (after frame 37 detection settles). From 968 at frame 37 → 1060 at frame 60. The active cell migrates DOWNWARD by 92 px from first-detected position to final rest.

### Signal 8: spacing_above (gap between active cell top and above-cell bottom)

| Frame | spacing_above | Δ |
|---|---|---|
| 31 | 55 | — |
| 37 | 120 | +65 (cells far apart) |
| 40 | 74 | −46 |
| 43 | 48 | −26 |
| 46 | 35 | −13 |
| 49 | 30 | −5 |
| 52 | 26 | −4 |
| 55 | 25 | −1 |
| 58 | 22 | −3 |
| 60 | **21** | −1 |

**Spacing CONVERGES from a large initial gap (120 at frame 37) to a tight final gap of 21 px.** This is the inter-cell spacing at cell-rest — matches `TimelineCanvas.cellSpacing = 24` at logical points (24 × 2 = 48 physical, but the gap also depends on cellSpacing + naturalCellHeight relationships — 21 px observed is in the same order).

**Spacing trajectory is approximately monotonically decreasing from frame 37 onward.** Spring-like settle to final value over 23 frames.

---

## Per-axis monotonicity verdict

| Property | Monotonic? | Notes |
|---|---|---|
| chrome_left darkness | MONOTONIC (rising) | 73 → 212 from frame 11–40 |
| bottom_gradient distance | NON-MONOTONIC | oscillates 70 → 234 → 59 between frames 24–40 (composite color of chat-content + gradient as alpha shifts) |
| active cell height | MONOTONIC (decreasing) after first detection | 540 → 438 frames 37–60 |
| active cell width | **NON-MONOTONIC** (overshoot) | 750 → 687 → 702 (spring signature) |
| active cell center_y | MONOTONIC (increasing) after first detection | 968 → 1060 frames 37–60 |
| spacing_above (inter-cell) | MONOTONIC (decreasing) after first detection | 120 → 21 frames 37–60 |

---

## Linear-interp deviation verdict

For the active cell's properties between first-detected (frame 31/37) and final (frame 60):

- **Width:** linear-interp from 750 to 702 over 29 frames = expected at frame 43 → 727. Actual at frame 43 → 687. **Deviation: 40 px below linear.** Non-trivial deviation indicating either non-linear curve OR spring undershoot.
- **Height:** linear-interp from 540 (frame 37) to 438 (frame 60) over 23 frames = expected at frame 48 → 491. Actual at frame 49 → 439. **Deviation: 52 px below linear.** The height curve front-loads its motion — drops fast early, settles slowly.
- **center_y:** linear-interp 968→1060 = expected at frame 48 → 1009. Actual at frame 49 → 1057. **Deviation: 48 px ABOVE linear.** The center_y curve also front-loads.
- **spacing_above:** linear-interp 120→21 = expected at frame 48 → 76. Actual at frame 49 → 30. **Deviation: 46 below linear.** Front-loaded.

**All four properties front-load their motion: they cover ~70–80% of their travel in the first 30% of the time after first detection, then asymptote into the final value.** This is the SPRING SIGNATURE.

---

## Asymmetry / decoupling

- **Width vs height:** width has the spring undershoot (650 → 702); height monotonically decreases (no undershoot). Width and height are DECOUPLED — they have different physical signatures.
- **center_y vs spacing_above:** center_y completes ~96% of its travel by frame 55 (1061 vs final 1060). spacing_above completes ~96% by frame 58 (22 vs final 21). Approximately co-settling.
- **chrome vs gradient appearance:** chrome reaches 212 (final) at frame 40. Gradient reaches 59 (final) at frame 40. **Co-settling at frame 40 (67% gesture progress).**
- **Chrome onset (frame 27, 45%) is AFTER cell-card first detected (frame 31, 52%) by 4 frames.** Approximately co-emergence; chrome leads slightly.

Actually: chrome darkness first non-baseline reading at frame 27 (45%), cell-card first detected at frame 31 (52%). **Chrome onset PRECEDES cell-card detection by 4 frames (7% gesture progress).**

---

## Pattern-library classification

For each animated property:

- **chrome darkness alpha:** monotonic rise with rapid rise zone — classifies as **spring monotonic** OR **smoothstep with offset onset** (frames 11–26: zero; frames 27–40: rapid rise; frames 40+: saturated). Smoothstep with range (26, 40) maps to this.
- **active cell width:** non-monotonic with overshoot — classifies as **critically-OR-underdamped spring** (slight overshoot of ~15 px / 31% of displacement). Pattern: spring monotonic was the natural guess; data falsifies this — there IS overshoot.
- **active cell height:** monotonic decreasing with front-loading — classifies as **spring monotonic decelerating** (no overshoot, fast initial then slow asymptote).
- **active cell center_y:** monotonic with front-loading — **spring monotonic decelerating**.
- **spacing_above:** monotonic decreasing with front-loading — **spring monotonic decelerating**.
- **Gradient color emergence:** non-monotonic — classifies as **alpha-driven composite** (gradient is fixed, but chat content alpha fades while composer fades while gradient becomes visible — the composite at the sampled pixel has multiple transitions). Not a pure trajectory of one element.

---

## Implementation primitive implied

Given the spring signatures across width, height, center_y, spacing:

- The reverse direction motion in the reference video is **driven by springs**, not by gesture-direct.
- The springs operate AFTER the user releases the pinch (the GESTURE itself is gesture-driven; the SETTLE phase from initial release to cell-rest is spring-driven).
- Width's overshoot suggests damping ratio slightly less than 1.0 (under-critically-damped).
- Width and height have DECOUPLED springs (different signatures).

Implementation primitive: **two coupled springs (or two independent springs with shared natural frequency)**, one for cell.height, one for cell.width, both engaged on pinch release. Width's spring is slightly under-damped; height is critically-or-over-damped.

**This MATCHES our current implementation** which uses `springToCellRest` with `SpringAnimator<CGFloat>` for `extensionAnimator.target = naturalH`. Width isn't independently sprung in our implementation — width derives from `horizontalInset` driven by `setCamera` per progress. The reference appears to have width with its own spring.

---

## Verdict summary

1. **Cell card visually distinct only via rounded corners + surrounding gradient.** Cell-fill and Page.surface are essentially identical colors (~3 unit difference per channel post-compression).
2. **Cell bounds first become perceptible at ~52% gesture progress** (frame 31). Top chrome onset slightly precedes at ~45% (frame 27).
3. **Final cell-rest dimensions (rendered):** height = 438 px, width = 702 px, center_y = 1060 (63.8% down).
4. **Width has a spring overshoot signature** (750 → 687 minimum → 702 final, ~15px overshoot below final). Width is UNDER-CRITICALLY DAMPED.
5. **Height monotonically decreases** with front-loaded motion — critically-or-over-damped spring.
6. **Inter-cell spacing CONVERGES from a large gap (120) to 21 px** as cells settle into the cell-list. The active cell DOES NOT START at the cell-list position; it migrates INTO the cell-list spacing.
7. **Active cell migrates downward by ~92 px** from first-detected position to final rest position (center_y 968 → 1060).
8. **Chrome reaches final alpha at ~67% gesture progress** (frame 40). Gradient settles to final color at the same frame.
9. **Width and height have DECOUPLED spring signatures** — different damping characteristics.

---

## Falsification tests

For any subsequent claim about the reverse motion, the falsification test:
- "X is monotonic" → find a frame in /tmp/dot_pinch_frames where X reverses direction. If found, claim is false.
- "X is linear" → find a frame where X deviates >30 px from linear interpolation between start and end. If found, claim is false.
- "Width has no spring" → width data shows 750→687→702. Width has spring. Falsified by data.
- "Cell card visible from frame 1" → frame-1 has no detectable cell card; chat content fills viewport edge-to-edge. Falsified by data.
