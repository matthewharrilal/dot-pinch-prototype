# Visual baselines — the wave parity referent

This tree carries the pre-migration screenshot baselines that every wave of the
refactor (per `REFACTOR-CHECKLIST.md` §8C) is diffed against. It exists because
code-green is not ship-green for a UI codebase — token swaps, layout
refactors, and coordinator extractions are all theoretically parity-safe and
all empirically risky. The baseline is the only object that catches the
asymmetry.

The baseline tree, the Maestro flows under `.maestro/`, and the diff script
under `scripts/visual-diff.sh` together form the wave-0 infrastructure layer.
No app behaviour is modified by any of these files — they only observe.

## Layout

```
docs/visual-baselines/
├── README.md                              # this file
├── pre-migration/
│   ├── 01-home-cell-rest.png              # raw simctl capture (kept for
│   │                                      #   spec compatibility with the
│   │                                      #   wave-0 mission's 01..07 names)
│   └── screenshots/                       # Maestro-captured baselines
│       ├── 01..07-*.png                   # numbered (wave-0 mission spec)
│       ├── flow-1-S{0,3,5}-*.png          # per 8C flow 1 anchor states
│       ├── flow-2-S{0,2,5}-*.png          # per 8C flow 2
│       ├── flow-3-S{0,2,4}-*.png          # per 8C flow 3
│       ├── flow-4-*.png                   # per 8C flow 4 (isQuiet guard)
│       ├── flow-5-*.png                   # per 8C flow 5 (background-resume)
│       ├── flow-6-rm-*.png                # per 8C flow 6 (reduce-motion)
│       └── flow-7-*.png                   # per 8C flow 7 (RevealCoordinator
│                                          #   dismiss — expected delta once
│                                          #   Phase 4 lands)
└── wave-<N>/                              # created per-wave by visual-diff.sh
    ├── screenshots/                       # current-wave Maestro captures
    ├── diffs/                             # per-pair PNG diffs (magick output)
    └── diff-report.md                     # PASS/FAIL summary table
```

## How the baselines were captured

1. **Sim:** iPhone 16, iOS 18.0 (UDID `C149C833-D1F6-4187-A202-89B2073D98A9`).
   iOS 18 is mandatory — Maestro 2.5.1 is incompatible with iOS 26.4
   (per project memory: empty a11y tree on iOS 26 returns).
2. **Build:** `xcodebuild -project DotPinchPrototype.xcodeproj
   -scheme DotPinchPrototype
   -destination "platform=iOS Simulator,id=C149C833-D1F6-4187-A202-89B2073D98A9"
   -configuration Debug -derivedDataPath /tmp/dotpinch-wave0-dd build`
3. **Install:** `xcrun simctl install <UDID> <DerivedData>/Build/Products/Debug-iphonesimulator/DotPinchPrototype.app`
4. **Maestro flows:** Run each `flow-N.yaml` with
   `--test-output-dir docs/visual-baselines/pre-migration --flatten-debug-output`.
   Screenshots land in `screenshots/` under that dir.

Maestro requires a JVM. The system Java is absent on this machine; use the
Homebrew openjdk:

```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home
~/.maestro/bin/maestro --device <UDID> test --test-output-dir <out> --flatten-debug-output .maestro/flow-N.yaml
```

## Pragmatic adaptations vs SSoT 8C — the documented gap

SSoT 8C specifies six per-state anchors per flow (S0–S5) at precise
sub-second timestamps (e.g. t=0.4s, t=0.8s, t=1.85s). Maestro 2.5.1 does not
provide sub-frame screenshot timing — `waitForAnimationToEnd` returns when
the layout settles, which is later than the canonical mid-frame anchors.
Two adaptations:

1. **Three anchors per flow instead of six.** Each `flow-N.yaml` captures the
   observable state transitions: pre-action (S0), post-action-pre-settle (Sk
   mid), and settled (final). The intermediate S1/S2/S4 frames from SSoT 8C
   are not captured. If sub-frame parity is later required, a Phase-N+ task
   can layer XCUITest atop these (which DOES expose frame-precise
   instrumentation via `XCUIScreen.main.screenshot()` in a test hook).
2. **Pinch is approximated via `swipe`.** Maestro 2.5.1's pinch primitive
   requires a two-finger driver path that the iOS XCUITest runner doesn't
   expose cleanly; we use diagonal `swipe` actions instead. The pinch flows
   (2, 3, 4, 7) should be treated as "the closest gesture approximation",
   not as canonical pinch fidelity. Reviewers MUST manually verify pinch
   behaviour on-device per the 9Q.3 Stage 10 visual-analysis mandate.

The 01..07 numbered captures (`01-home-cell-rest` through
`07-pinch-released-settled`) match the wave-0 mission spec's request and
were captured in a single helper flow (`.maestro/_helper-numbered-captures.yaml`).
They are redundant with the `flow-N-Sk-*` captures by state but use the
spec-mandated naming; either set may be used as the diff referent for a
given wave.

## ImageMagick substitution for ksdiff — the SSoT 8C amendment

SSoT 8C names `ksdiff` (Kaleidoscope) as the canonical diff tool. ksdiff is
not installed on this machine and is not free; ImageMagick's `magick compare`
with `-metric AE -fuzz 1%` is the local substitute. The semantics map:

| ksdiff concept | ImageMagick equivalent |
|---|---|
| "no perceptible difference" | AE count where `<= 0.5%` of total pixels exceed the fuzz threshold |
| per-channel tolerance | `-fuzz 1%` (1% per-channel RGB delta tolerated before a pixel counts as different) |
| side-by-side review UI | per-pair PNG diff written to `diffs/`, plus aggregate table in `diff-report.md` |
| pass/fail | script exit 0 / 1 |

**This is a documented amendment to SSoT 8C.** Any wave-close that asserts
"ksdiff passed" is, in this repo, asserting that `scripts/visual-diff.sh
wave-N` exited 0 AND a human reviewed the per-pair PNG diffs and the
aggregate report. The substitution loses ksdiff's perceptual-distance
metric and gains a portable, hermetic, scriptable comparison. The tolerance
constants (1% fuzz, 0.5% pixel threshold) are chosen to absorb anti-alias
jitter without masking real visual deltas; revisit if false-positive rate
proves high in early waves.

## The per-wave diff process

For wave N (post-implementation, pre-merge):

1. **Re-run all 7 Maestro flows** against the wave-N build of the app,
   writing to `docs/visual-baselines/wave-N/`:
   ```bash
   for flow in .maestro/flow-*.yaml; do
     JAVA_HOME=/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home \
       ~/.maestro/bin/maestro --device <UDID> test \
       --test-output-dir docs/visual-baselines/wave-N --flatten-debug-output \
       "$flow"
   done
   ```
2. **Run the diff:**
   ```bash
   ./scripts/visual-diff.sh wave-N
   ```
3. **Read the report** at `docs/visual-baselines/wave-N/diff-report.md`.
4. **For every FAIL row:** human reviewer opens
   `docs/visual-baselines/wave-N/diffs/<pair>.png` and decides:
   - intentional change → log in Parity-Break Ledger 8B with sign-off
   - regression → block wave-N merge until fix lands
   - flake (e.g. status-bar clock) → adjust mask region in flow + re-run

## The manual visual analysis requirement (9Q.3 Stage 10)

Per project memory `feedback_visual_testing_every_wave.md`: code-green is
not ship-green for UI. Every wave's orchestrator gate MUST include:

- Maestro flows executed against the wave-N build on the iOS 18 sim
- Per-state screenshots captured (the 01..07 numbered set AND the
  flow-N-Sk-* per-anchor set)
- `scripts/visual-diff.sh wave-N` run and report reviewed
- Manual visual analysis: a human opens at least the FAIL pairs (and a
  random sample of PASS pairs to verify the captures actually show the
  state they claim) and signs off

This is a binding gate per the wave-close merge protocol (§0.10 in
REFACTOR-CHECKLIST.md).

## Limitations of this baseline (what the diff cannot catch)

- **Timing-only regressions.** If a wave makes the morph faster or slower
  but settles at the same final state, the settled-state captures will
  match. Time-based regressions need a separate frame-counting hook.
- **Gesture-fidelity drift.** Maestro's `swipe`-based pinch approximation
  may not trigger the exact pinch code path on every run; pinch flows
  carry a higher false-pass risk.
- **Status-bar clock.** The simulator clock can change between baseline
  and current; status-bar regions occasionally show non-zero deltas
  even on parity-safe changes. Treat sub-pixel-row deltas in the top
  status-bar band as flake unless the count is large.
- **Sub-pixel anti-alias jitter.** The 1% fuzz / 0.5% pixel threshold
  absorbs typical jitter; if a real regression hides under the
  threshold, the manual-review step is the catch.

The infrastructure is necessary but not sufficient. The human is the gate.
