# DotPinchPrototype

A UIKit prototype exploring "pinch-to-memory" — a gesture that compresses a
fullscreen conversation into a static destination card via a uniform 2D
similarity transform, with staged figure/ground relay, blur, and a staggered
bottom-up colour dissolve.

The mechanic sits on a hand-rolled spring substrate (Wave-derived): a single
shared `CADisplayLink`, velocity preserved across mid-flight target changes,
gesture velocity injected into the spring at release.

---

## Run

```bash
brew install xcodegen          # one-time
xcodegen generate              # regenerate the .xcodeproj
open DotPinchPrototype.xcodeproj
```

Pinch on the chat surface. In the simulator: hold Option for two-finger pinch.

Tested on iPhone 16 / iOS 18.0. Targets iOS 17+.

---

## Architecture

```
DotPinchPrototype/
├── App/                  AppDelegate
├── Conversation/         Chat surface + destination card + chrome
├── Gestures/             Pinch interaction, PinchMorphState, PinchTuning
├── Animation/            Spring kit (Spring, SpringAnimator, AnimationController, …)
├── DesignSystem/         Theme tokens, AccessibilityID, SymbolName
└── Placeholders/         Static chat transcript + destination preview text
```

- **`Animation/`** is feature-independent. It could be a Swift package as-is.
- **`Gestures/PinchTuning.swift`** is the single source of truth for every
  morph-progress threshold and tuning constant.
- **`Theme.Page.surface`** is the structural invariant: the page-gradient
  middle stop, destination card fill, and composer fill all read from it.
  That's what makes the card look like the page material with edges rather
  than a separate object.

---

## The nine depth-cue refusals

The mechanic suppresses every depth cue that would make the morph read as
"3D recession" instead of "in-place compression":

| # | Refusal | Where it lives |
|---|---|---|
| 1 | Uniform scale, no foreshortening | `ConversationContentView.setTimelineCompression` — `sx = sy` from `PinchTuning` |
| 2 | Photometric continuity (card = page material) | `Theme.Page.surface` reused across gradient middle, card, composer |
| 3 | No parallax | chrome views are siblings of the card, never children |
| 4 | Binary shadow | set only at `.finished`, never animated |
| 5 | Uniform blur | one full-bounds `UIVisualEffectView`; no per-region masks |
| 6 | No vanishing point | no `CATransform3D`, no `m34`, no rotation |
| 7 | Camera stays still | page gradient never moves |
| 8 | Stacking preserved | subview hierarchy built once in `viewDidLoad`, never reordered |
| 9 | No specular | no radial gradients, no `CIFilter` on the card subtree |

---

## Tuning

Visual feel is tuned via `Gestures/PinchTuning.swift` — blur ramp, dissolve
windows, alpha ramps, gesture sensitivity, spring response/damping. No
morph-progress numeric literal appears anywhere else in the codebase.

---

## Accessibility

Reduce Motion / VoiceOver / Switch Control / Cross-Fade Transitions all
skip the spring path — the pinch snaps directly to its target. See
`PinchToMemoryInteraction.shouldUseReducedMotion`.

---

## Maestro flows

```bash
./scripts/run-maestro.sh
```

Flows in `.maestro/` — `smoke`, `pinch_in`, `pinch_out`, `mid_flight_reverse`.
iOS 18 simulator only: Maestro 2.5.1 returns an empty accessibility tree on
iOS 26+ sims.

---

## Status

Prototype. The mechanic, staged figure relay, and design-token invariants
are in place. The substrate is reusable but hasn't been factored into a
Swift package. There are no unit tests yet.
