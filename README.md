# dot-pinch-prototype

Bare-bones Tier-3B iOS prototype testing whether the architectural composition recipe from the [Dot pinch-to-memory `/lens-check`](https://github.com/matthewharrilal/ios-animation-frontier/tree/main/dot-pinch-lens-check) actually produces the intended UX when implemented.

Small feature surface. Maximum engineering depth.

---

## What this tests

The five claims that must demonstrably hold for "we got it down":

| # | Claim | How this prototype demonstrates it |
|---|---|---|
| 1 | **Pinch tracks live** — finger position directly drives morph progress (no canned playback) | `PinchToMemoryInteraction.handlePinch(.changed)` writes `view.frame` directly from the pinch's scale, with no `UIView.animate` block wrapping it |
| 2 | **Mid-flight reverse works** — change pinch direction at 50% → trajectory bends, doesn't snap | `SpringAnimator.target.didSet` preserves the velocity instance variable; new target retargets the same animator (NINETY-pinch-E01) |
| 3 | **Release continuity** — gesture velocity flows into spring; no dead frame between fingers-up and motion settle | `handlePinch(.ended)` extracts `recognizer.velocity`, normalizes via the WWDC 2018 formula, and writes directly into `SpringAnimator.velocity` BEFORE calling `start()` (NINETY-pinch-E08 + A03) |
| 4 | **Slot-anchored expansion** — pivot is top-left of source slot, not screen center | `PinchMorphState.bounds` interpolates between the fullscreen rect and the slot rect; UIView's frame-based geometry naturally anchors at `bounds.origin` |
| 5 | **Identity preserved during morph** — view contents reflow live as bounds change | `ConversationContentView` uses `UIStackView` + `UILabel(numberOfLines: 0)` so autolayout reflows text as the parent's bounds change. Not a snapshot |

Plus the per-frame discipline that distinguishes Tier-3B from Tier-2B:

- **Single shared `CADisplayLink`** (NINETY-pinch-E02) — see `AnimationController.swift`
- **`CATransaction.setDisableActions(true)` wrapping every per-frame write** (NINETY-pinch-E03) — suppresses UIKit implicit animations
- **First frame paints at `dt=0` synchronously** (NINETY-pinch-E14) — no one-frame-late flash on start
- **Closed-form settling-time** (NINETY-pinch-E11) — not position-based completion
- **Custom `PinchMorphState: SpringInterpolatable`** (NINETY-pinch-EP5) — the morph is one motion of one state object, not four parallel animators
- **Presentation-layer hit-testing during morph** (NINETY-pinch-D02) — touches reach the destination, not the model

---

## Architecture

```
DotPinchPrototype/
├── App/
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
├── Substrate/                      ← Wave-derived spring substrate (public-API only, no Wave dependency)
│   ├── Spring.swift                  Spring parameters (ζ, response, closed-form settling time)
│   ├── SpringInterpolatable.swift    Generic protocol + CGFloat/CGPoint/CGSize/CGRect conformances
│   ├── SpringAnimator.swift          The stateful integrator. target.didSet preserves velocity.
│   ├── AnimationController.swift     Singleton: single CADisplayLink, CATransaction discipline, dt=0 first frame
│   └── UIMathUtilities.swift         Rubber-band (c=0.55, Apple-tuned), projection, WWDC 2018 velocity normalization
├── State/
│   └── PinchMorphState.swift       ← The composite state. SpringInterpolatable conformance.
│                                     This is conjecture Decision 5 — the architectural elevation move.
├── Interaction/
│   ├── PinchMorphContainerView.swift  Hit-test override for presentation-layer routing
│   └── PinchToMemoryInteraction.swift The UIInteraction adopter that wires gesture → substrate
└── Demo/
    ├── ConversationContentView.swift  The morphing surface contents (autolayout for live reflow)
    └── DemoViewController.swift       The demo screen
```

### What's NOT in this prototype (deliberately)

- Past-day cards / vertical memory timeline scroll view — bare-bones means one source rect, one slot rect
- Affordance icon (the ↘↖ ↔ ↖ pinch glyph from Soul Piece #3)
- Two-phase reveal staggering (Soul Piece #7) — relevant only with multiple cells
- Haptic feedback at commit threshold — polish, not core
- Reduced-Motion fallback — accessibility, post-prototype concern
- iOS 26 Liquid Glass integration — Dot predates iOS 26

The point is: prove the **substrate** is right. The rest is composition on top.

---

## How to run

### Requirements

- macOS, Xcode 26.4+ (or any Xcode with iOS 17+ SDK)
- For Maestro tests: `openjdk@17` via Homebrew (`brew install --cask temurin@17` or `brew install openjdk@17`)

### Build + run the app

```bash
# Generate the Xcode project from project.yml (XcodeGen required)
xcodegen generate

# Open in Xcode
open DotPinchPrototype.xcodeproj

# OR build from command line for the iOS 18 simulator
xcodebuild -project DotPinchPrototype.xcodeproj -scheme DotPinchPrototype \
  -destination "platform=iOS Simulator,id=C149C833-D1F6-4187-A202-89B2073D98A9" \
  -configuration Debug build
```

In the simulator: two-finger pinch on the colored surface. On a Mac, hold Option to enable two-finger gesture simulation.

### Visual testing with Maestro (AI Insights enabled)

```bash
./scripts/run-maestro.sh
```

What this does:
- Sets `JAVA_HOME=/opt/homebrew/opt/openjdk@17`
- Selects the iOS 18.0 simulator (UDID overridable via `IOS18_SIM_UDID=<udid>`)
- Builds + installs the app
- Runs all `.maestro/*.yaml` flows with `--analyze` (Maestro's AI Insights mode)
- Outputs an HTML-DETAILED report to `.maestro/.report/`

Per the [Maestro 2.5.1 / iOS 26.4 incompatibility](https://github.com/matthewharrilal/ios-animation-frontier/tree/main/dot-pinch-lens-check), the flows specifically target an iOS 18.0 simulator — iOS 26+ sims return an empty accessibility tree to Maestro and assertions silently fail.

For full AI Insights analysis (requires a Maestro Cloud account):
```bash
MAESTRO_API_KEY=<your-key> ./scripts/run-maestro.sh
```

### The Maestro flows

| Flow | What it tests |
|---|---|
| `smoke.yaml` | App launches, shows expected initial state |
| `pinch_in.yaml` | Collapse fullscreen → slot. Criterion 1, 4, 5 |
| `pinch_out.yaml` | Expand slot → fullscreen. Reverse-direction parity |
| `mid_flight_reverse.yaml` | Quick pinch-in → pinch-out. Criterion 2 (visual: bent vs snapped trajectory) |

Take screenshots are saved to the Maestro report directory; compare them frame-by-frame against `dot-pinch-lens-check/trajectory/verdict.md` expectations.

---

## Citation map

Each rule cited in the code traces to one of three sources:

- **`NINETY-pinch-E01` … `E17` and `EP1` … `EP5`** — Wave bottled philosophy. Source: [`dot-pinch-lens-check/team_findings/wave_philosophy.md`](https://github.com/matthewharrilal/ios-animation-frontier/blob/main/dot-pinch-lens-check/team_findings/wave_philosophy.md)
- **`NINETY-pinch-A01` … `A09`, `D01` … `D07`, `B01`** — Apple-shipped internal compositions / behaviors / data. Source: [`dot-pinch-lens-check/ninety/output.md`](https://github.com/matthewharrilal/ios-animation-frontier/blob/main/dot-pinch-lens-check/ninety/output.md)
- **`CARTO-pinch-01` … `CARTO-pinch-45`** — iOS primitive cartography. Source: [`dot-pinch-lens-check/cartography/output.md`](https://github.com/matthewharrilal/ios-animation-frontier/blob/main/dot-pinch-lens-check/cartography/output.md)

Plus **Soul Pieces #1 … #9** from [`dot-pinch-lens-check/deepening/SOUL-DISCOVERIES.md`](https://github.com/matthewharrilal/ios-animation-frontier/blob/main/dot-pinch-lens-check/deepening/SOUL-DISCOVERIES.md) and the **trajectory verdict** at [`dot-pinch-lens-check/trajectory/verdict.md`](https://github.com/matthewharrilal/ios-animation-frontier/blob/main/dot-pinch-lens-check/trajectory/verdict.md).

---

## What "Tier-3B execution" means in this prototype

Read the substrate without the comments. Can a careful reader infer the rules from the structure alone? (Phase 7.5 of the conjecture — implicit-in-structure verification.)

- `SpringAnimator.target.didSet` doesn't reset velocity → implies "velocity sacred"
- `AnimationController` has ONE `displayLink` for all animators → implies "single shared clock"
- The per-frame block has `CATransaction.setDisableActions(true)` around the writes → implies "implicit animations suppressed"
- `PinchMorphState` carries five animatable fields and conforms to `SpringInterpolatable` → implies "composition is one logical thing"
- `runPropertyAnimation` calls `animator.updateAnimation(dt: 0)` synchronously before returning → implies "first frame is sacred"
- `PinchMorphContainerView.hitTest` consults `layer.presentation()` → implies "hit-test follows visual position"

If you have to read the comments to understand WHY the code is shaped this way, the comments are doing the philosophical work and the code is failing the test. If the code's structure forces a reader toward the right rule, the annotations are redundant-but-helpful.

---

## Next steps after this prototype validates

1. Add the second layer — vertical memory timeline scroll view with past-day cells (conjecture Decision 2: three-layer hierarchy)
2. Add the affordance icon morph (Soul Piece #3, conjecture Decision 9)
3. Add two-phase reveal staggering (Soul Piece #7, conjecture Decision 7)
4. Add haptic feedback at commit threshold (cartography blind spot — Apple-craft co-primitive)
5. Add Reduced-Motion fallback (conjecture Decision 10)
6. Frame-step the result against `dot-pinch-lens-check/_dot_pinch_lens/dot_pinch.mov` at 240fps; refine spring parameters per the trajectory verdict's measurements (response ~1.17s active, ~0.83s settle; today_card damping ~0.85+; gradient damping ~0.6–0.7)
7. Bottle the substrate as `PinchToMemoryKit` Swift Package (conjecture's Bottling Destination)
