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
├── App/                  AppDelegate + ConversationComposer (composition root)
├── Conversation/         Feature UI + render-token derivation
│   ├── ConversationViewController.swift
│   ├── ConversationContentView.swift
│   ├── ChatBubbleView.swift
│   ├── ConversationMorphTokens.swift   ← single source of every progress-derived render value
│   └── MorphTiming.swift               ← visual-timing constants
├── Gestures/             Pinch interaction
│   ├── PinchToMemoryInteraction.swift
│   ├── PinchMorphState.swift           ← just `progress` (spring-interpolable)
│   └── PinchTuning.swift               ← gesture-physics constants
├── Animation/            Reusable spring kit (Wave-derived)
│   ├── Spring.swift / SpringAnimator.swift / SpringInterpolatable.swift
│   ├── AnimationController.swift
│   └── MathUtilities.swift
├── DesignSystem/         Theme tokens, AccessibilityID, SymbolName
└── Placeholders/         Static chat transcript + destination preview text
```

The shape of the data flow:

```
UIPinchGestureRecognizer
        │
        ▼
PinchToMemoryInteraction  (writes scalar progress)
        │
        ▼
SpringAnimator<PinchMorphState>  (integrates progress through spring physics)
        │
        ▼  animator.valueChanged
ConversationViewController
        │
        ▼
ConversationMorphTokens(state:)   ← derives every visual property in one place
        │
        ▼
[ ConversationContentView, destinationCard, affordances, composer ]   ← pure projection
```

`ConversationMorphTokens` is the lens: every progress-derived visual property
(blur fraction, chat mask alphas, card emergence, label emergence, affordance
alpha, composer fade) is computed in one pure function with zero UIKit
dependency. The view layer reads tokens off the bundle and writes them to
view properties. No curve math lives in views.

---

## The nine depth-cue refusals

The mechanic suppresses every depth cue that would make the morph read as
"3D recession" instead of "in-place compression":

| # | Refusal | Where it lives |
|---|---|---|
| 1 | Uniform scale, no foreshortening | `ConversationMorphTokens.similarityScale` — `sx = sy` |
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

Two cohesion-aligned files:

- **`Gestures/PinchTuning.swift`** — gesture physics (sensitivity, rubber-band,
  spring response/damping, commit threshold). Reusable across morphs.
- **`Conversation/MorphTiming.swift`** — visual choreography (blur ramps,
  dissolve windows, alpha emergence ranges). This feature's feel.

No morph-progress numeric literal appears inline in the rest of the codebase.

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

Prototype. The mechanic, staged figure relay, render-token bundle, and
design-token invariants are in place. There are no unit tests yet.

### Future considerations

- **`Animation/` as a Swift package.** The folder is fully feature-independent
  (imports only Foundation / QuartzCore / CoreGraphics / UIKit). When this UX
  is ready to ship as a reusable component, the natural next step is
  `swift package init`-ing it as e.g. `PinchSpringKit` so consumers can
  depend on the substrate without the demo feature.
