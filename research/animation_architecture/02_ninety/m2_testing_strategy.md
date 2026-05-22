# METACOGNITIVE — Animation testing strategy
POSTURE: janum

Senior-staff animation code is testable code. The litmus: can you refactor a chained `UIView.animate(delay:)` into a coordinator without a 20-minute hand-QA cycle per commit? Below: the patterns shipping shops use, scored against this project's existing test infrastructure.

## 1. State-machine unit tests (controller-not-view)
### Canonical form
```swift
@MainActor
func testReveal_FromIdle_OnTap_EntersBlurFadeIn() {
    let fx = makeRevealFixture()        // pure model, no UIView
    fx.coordinator.handle(.tapCommitted(cellIndex: 2))
    XCTAssertEqual(fx.coordinator.state, .blurFadingIn(progress: 0))
}
func testReveal_AtContentFadeProgress1_EntersBlurFadingOut() {
    let fx = makeRevealFixture()
    fx.coordinator.force(state: .contentFadingIn(progress: 1.0))
    fx.coordinator.tick(progress: 1.0)
    XCTAssertEqual(fx.coordinator.state, .blurFadingOut(progress: 0))
}
```
### What it catches
Off-by-one transitions; missing edges (idle→idle on duplicate tap); boundary events at `progress == 1.0`. The anticipation→main→reveal chain reduces to a Mealy machine — assert `(state, event) → state` without CoreAnimation.
### Cost (CI / maintenance)
Cheap. <50ms per test, zero flake. Maintenance scales with vocabulary, not implementation churn.
### Shipping evidence
Pointfree `swift-composable-architecture` Reducer testing; Airbnb Epoxy item-model diff tests; Square coordinator pattern. Apple internal: `_UIViewControllerTransitionContext` IS an FSM.
### Tradeoff
FSM and render must stay in lockstep. If rendering reads anything besides FSM output mid-block, tests pass while pixels lie. Mitigation: rendering is pure `(State) → ViewWrites`.

## 2. Snapshot testing (pixel golden)
### Canonical form
```swift
import SnapshotTesting  // pointfreeco/swift-snapshot-testing
func testChatRest_FrameAt_p0_5() {
    let canvas = makeWindowedCanvas(); canvas.driveProgress(0.5)
    assertSnapshot(of: canvas, as: .image(precision: 0.995))
}
```
### What it catches
Visual regressions invisible to numeric assertions: gradient blending wrong, z-order flip, sub-pixel misalignment that breaks the infinite-cell illusion. Addresses "code-green ≠ ship-green" (memory: `feedback_visual_testing_every_wave`).
### Cost (CI / maintenance)
Mid-high. Snapshots re-record across iOS + sim changes (real problem here — `VisualAuditHarnessTests` runs both ios18/ios26). ~50KB × N × P storage.
### Shipping evidence
pointfreeco/swift-snapshot-testing (de facto standard); Uber iOS; Square (FBSnapshotTestCase lineage); Airbnb Epoxy.
### Tradeoff
Brittle to font/sim version. Solution: pin to iOS 18 sim (per memory `project_maestro_ios26_incompat`), gate behind `RUN_SNAPSHOT=1`.

## 3. Mocked clocks / display links
### Canonical form
```swift
protocol DisplayLinkDriving: AnyObject {
    var isPaused: Bool { get set }
    func tick(dt: CFTimeInterval)
}
final class MockDisplayLink: DisplayLinkDriving { /* trivial */ }
func testSpringSettles_DeterministicallyAtFrame120() {
    let clock = MockDisplayLink()
    let controller = AnimationController(driver: clock)   // DI seam needed
    let a = SpringAnimator<CGFloat>(controller: controller, spring: .init(0.8, 0.4))
    a.value = 0; a.target = 100; a.start()
    for _ in 0..<120 { clock.tick(dt: 1.0/120.0) }
    XCTAssertEqual(a.value!, 100, accuracy: 0.5)
}
```
### What it catches
Frame-exact assertions. Removes the `RunLoop.main.run(until:)` polling pervasive in `WaveR*Tests` (each eats 2-4s wall). CADisplayLink hard-coded `AnimationController.swift:33` — needs DI seam.
### Cost (CI / maintenance)
One-time refactor of `AnimationController.init` to inject driver. Saves CI minutes as test count grows.
### Shipping evidence
Pointfree `swift-clocks` (`TestClock`, `ImmediateClock`); Robinhood iOS infra; Apple `XCTClockMetric`.
### Tradeoff
Mocked clocks pass tests real-jank CADisplayLink would fail. The probe `testProbeSpringActuallyTicksUnderRunloopSpin` is the right answer — keep ≥1 real-displaylink canary; mock elsewhere.

## 4. Property-based testing
### Canonical form
```swift
import SwiftCheck
func testLerpInvariant() {
    property("lerp(a,b,t) ∈ [min(a,b), max(a,b)] for t∈[0,1]") <- forAll { (a: Float, b: Float, t: Float) in
        let r = lerp(a, b, max(0, min(1, t)))
        return r >= min(a, b) - 1e-3 && r <= max(a, b) + 1e-3
    }
}
```
### What it catches
Boundary bugs + NaN propagation. `safeVel` floor in `CameraAnimator.animate:124-128` is the shape — has one `isFinite` test, no `forAll velocity in [-∞, +∞]` sweep.
### Cost (CI / maintenance)
Low for pure functions (Spring math). High for stateful animation — valid-state generators are non-trivial.
### Shipping evidence
SwiftCheck (typelift); Pointfree `swift-parsing`; Apple `swift-collections` invariants.
### Tradeoff
Discovers unknown unknowns, but minimal counterexamples lack context.

## 5. Frame-by-frame visual verification
### Canonical form
```swift
// Already scaffolded: WaveR1ProgressPointCaptures.swift.
func testCaptureFiveProgressPoints() {
    let (canvas, _) = makeCanvas()
    canvas.animateCameraToChatRest(forCellAt: 1)
    canvas.cameraAnimator.stop(immediately: true)
    for p: CGFloat in [0.0, 0.25, 0.5, 0.75, 1.0] {
        canvas.driveProgress(p); render(canvas, to: "/tmp/p_\(p).png")
    }
}
```
### What it catches
"What should I see at frame N?" — the question designers ask. The reveal chain has defined moments (0.0=blur in, 0.3=content fade, 0.5=blur out, 1.0=committed).
### Cost (CI / maintenance)
High setup, low per-test cost. Needs reference-correlation pipeline (`scripts/reference-correlation-diff.py` exists).
### Shipping evidence
Apple WWDC reference videos; Halide shutter-timing tests; this project's `captured-frames/wave-7e-scrub/`.
### Tradeoff
Orthogonal to unit testing — different bug class.

## 6. Performance regression (XCTMeasure)
### Canonical form
```swift
// Already shipping: Phase0Spike07AutoLayoutSolverCost.swift.
let opts = XCTMeasureOptions(); opts.iterationCount = 10
measure(metrics: [XCTClockMetric()], options: opts) {
    for _ in 0..<120 { heightConstraint.constant = naturalH * factor; window.layoutIfNeeded() }
}
```
### What it catches
Frame-budget regressions. Substrate hinges on `<2ms/tick`; a refactor introducing 5ms layout passes functional tests, ships 24fps.
### Cost (CI / maintenance)
Brittle baselines (per-machine). Best on dedicated CI box. False positives on shared infra.
### Shipping evidence
Apple WWDC 2019 "Improving Battery Life"; this codebase; LinkedIn `XCTClockMetric`.
### Tradeoff
Tells you something regressed, not what. Pair with Instruments traces.

## 7. Invariant tests
### Canonical form
```swift
// Already shipping: WaveR31ZOrderInvariantTests.
private func assertActiveAtFront(_ canvas: TimelineCanvas, moment: String) {
    guard let idx = canvas.activeCellIndex,
          let active = canvas.instantiatedCells[idx] else { return }
    XCTAssertTrue(canvas.contentHost.subviews.last === active,
                  "@ \(moment): active must be frontmost")
}
```
### What it catches
Cross-cutting state-shape: "`activeCellIndex == nil` ⟹ all cells at naturalHeight" (per `WaveR11.testNoActiveClearedWhileHeightExtended_RaceWindow`). Reveal equivalent: `revealBlurOverlay != nil ⟹ activeChatVC != nil`.
### Cost (CI / maintenance)
Multi-moment assertions — low marginal cost. Invariants stable.
### Shipping evidence
`WaveR31`, `WaveR11`, `WaveR41SubstrateCanaryTests`. Pop (FB) uses the same shape.
### Tradeoff
Silent on bugs that don't violate them. Necessary but not sufficient.

## 8. Adversarial / hostile tests
### Canonical form
```swift
// WaveR11LifecycleAdversarialTests. Sets up EXACT conditions for
// cameraAnimator's same-target short-circuit to fire completion
// synchronously BEFORE extension engages — surfaces single-active race.
```
### What it catches
Mid-flight retarget, dataSource swap, NaN injection, gesture-during-spring, rapid reversal. Bugs in brief windows where assumptions are temporarily false.
### Cost (CI / maintenance)
Highest per-test write cost, lowest count needed (1 per race). High value-per-test.
### Shipping evidence
Square iOS chaos suite; Pointfree TCA `.cancel` events; six in this project (`WaveR11`, `WaveR75`, `WaveR43`, `WaveR12`).
### Tradeoff
Encodes races the author imagined. Unimagined ones ship. Mitigation: combine with §4.

## 9. Cross-VC transition tests
### Canonical form
```swift
final class MockTransitionContext: NSObject, UIViewControllerContextTransitioning {
    var containerView: UIView
    func completeTransition(_ done: Bool) { completionCalled = true }
    // ~15 protocol methods to mock
}
func testRevealAnimator_Completes_didComplete_true() {
    let ctx = MockTransitionContext(...)
    RevealTransitionAnimator().animateTransition(using: ctx)
    spinUntil(1.0) { ctx.completionCalled }; XCTAssertTrue(ctx.didComplete)
}
```
### What it catches
The exact bug class `revealChat` risks: completion never fires, VC hierarchy leaks, `didMove(toParent:)` sequencing.
### Cost (CI / maintenance)
High up-front (~50-line mock). Pays back IF `revealChat` extracts to `UIViewControllerAnimatedTransitioning` (c4 recommends).
### Shipping evidence
Hero (HeroTransitions/Hero); Airbnb hero transitions; Apple sample "CustomTransitions".
### Tradeoff
Dead infrastructure if `revealChat` stays as imperative `UIView.animate`.

## 10. Visual audit harness (existing scaffold intent)

`Tests/VisualAuditHarnessTests.swift` — env-gated (`RUN_VISUAL_AUDIT_HARNESS=1`) macOS-host integration. Invokes `scripts/visual-audit-scrub.sh` per `{platform, direction}` to render 30 frames into `captured-frames/wave-7e-scrub/<platform>/<direction>/p_*.png`; counts PNGs (120 total); runs `scripts/reference-correlation-diff.py` to produce CSV correlating captures vs reference video; asserts CSV structure. **Intent:** integration smoke for the visual pipeline, not pixel diff. Defers visual judgement to manual review. Aligns with `feedback_visual_testing_every_wave`.

## 11. Mocking SpringAnimator
### Canonical form
```swift
protocol SpringAnimating: AnyObject {
    var value: CGFloat? { get set }; var target: CGFloat? { get set }
    var state: AnimatorState { get }
    func start(); func stop(immediately: Bool)
}
extension SpringAnimator: SpringAnimating where T == CGFloat {}
```
### What it catches
Consumer wiring: does `CameraAnimator.animate(to:velocity:)` honor the velocity floor even when the spring is a no-op? Tests wiring without paying physics cost.
### Cost (CI / maintenance)
Wiring tests fast and stable. Cost is protocol-extracting one concrete class.
### Shipping evidence
Pop (FB); SwiftUI's `Animation` is protocol-typed for this reason; Robinhood/Lyft talks.
### Tradeoff
Mocks don't exercise integration. Current `spinUntil(3.0)` is integration-flavored unit testing — slower but tests reality. Both needed.

## What DotPinchPrototype's existing Tests/V2 currently does

**30 V2 test files. Inventory:**
- **`spinUntil(timeout:condition:)`** in `WaveR11/12/31/75` — polls run loop every 50ms, max ~3s. Real CADisplayLink ticks; tests pay wall time.
- **Substrate canary** — `WaveR41SubstrateCanaryTests`, `testProbeSpringActuallyTicksUnderRunloopSpin` verify CADisplayLink fires in XCTest; otherwise all settle-based tests are meaningless.
- **`drainAnticipation(_:)`** — synchronously finishes the anticipation `UIViewPropertyAnimator` so main-spring tests don't race anticipation.
- **Adversarial race-window** — `WaveR11.testNoActiveClearedWhileHeightExtended_RaceWindow` sets up exact conditions for the same-target short-circuit race.
- **Multi-moment invariants** — `WaveR31` asserts z-order at `.began`, anticipation drained, mid-spring, post-settle.
- **`XCTMeasure` + `XCTClockMetric`** — `Phase0Spike07AutoLayoutSolverCost` measures `<2ms/tick` Auto Layout solver cost.
- **Probe-and-skip historical** — `Phase0Spike08SpringTimingCoordination` retains disproved hypothesis as `XCTSkip` for documentation.
- **Visual capture (no diff)** — `WaveR1ProgressPointCaptures` emits 5 PNGs to `/tmp/`; manual review.
- **TestFixture composition** — `Tests/README.md` documents value-type bundle to keep weak-held collaborators alive across test methods (W5-G6).
- **Env-gated integration** — `VisualAuditHarnessTests` gated on `RUN_VISUAL_AUDIT_HARNESS=1`.
- **Direct-completion bypass** — `Tests/README.md` documents invoking `animator.completion?(.finished(at:))` to drive state machines without spring physics.

**Missing:** snapshot tests, mocked clock (CADisplayLink hard-coded `AnimationController:33`), property-based tests, protocol-extracted SpringAnimator, `UIViewControllerContextTransitioning` mock.

## Recommended testing stack for the refactor

1. **Extract `DisplayLinkDriving` seam in `AnimationController.init`** — inject driver, default to real CADisplayLink. Enables frame-stepping without retiring substrate canary.
2. **Keep `spinUntil` + canary as integration tier.**
3. **Adopt `swift-snapshot-testing` for reveal goldens** — env-gated, pinned iOS 18 sim. 5 progress points × {expand, collapse} = 10 goldens.
4. **Extract reveal as state machine FIRST, test pure, THEN render.** Chained `UIView.animate(delay:)` becomes data: `[(0.0, .blurIn), (0.2, .contentFade), (0.5, .blurOut)]`.
5. **Protocol-extract SpringAnimator + CameraAnimator** for consumer-side mock tests.
6. **Adversarial tests are non-negotiable** — only tier catching race-window bugs.
7. **`XCTMeasure` gate on reveal-chain composition.**

## What we'd write FIRST before touching the chained-animate refactor

Michael Feathers's **characterization tests**: the current `revealChat` chain IS the spec. Lock observable behavior before refactoring.

1. **State snapshot at t = {0.0, 0.3, 0.5, 0.7, 1.2}** — `blur.alpha`, `chatVC.view.alpha`, `timelineCanvas.alpha`, `revealBlurOverlay != nil`, `chatVC.parent != nil`.
2. **Pixel snapshot at same 5 timepoints** (env-gated, iOS 18 only).
3. **Single-VC invariant** — `activeChatVC != nil ⟹ all subsequent taps no-op` (implicit guard `V2RootViewController:78`; no test asserts it).
4. **Completion invariant** — `revealBlurOverlay` removed from superview and nil'd after final completion.
5. **Adversarial interrupt** — call `revealChat(forCellAt: 2)`, then synchronously `forCellAt: 3`. Assert exactly one `chatVC` in `view.subviews`.
6. **Memory invariant** — weak-capture chat VC; assert dealloc on dismiss.
7. **`UIView.animate` substrate canary** — verify block-based animation drives `chatVC.view.alpha` toward 1.0 inside XCTest (different driver than CADisplayLink).
8. **`XCTMeasure` first-frame cost** of `revealChat()` including layout pass. Currently unknown; senior-staff refactor must not regress it.

These use only public surface (`tap → revealChat → final state`). Internal restructuring (extract `RevealCoordinator`, replace chain with single `UIViewPropertyAnimator.fractionComplete`, or migrate to `UIViewControllerAnimatedTransitioning`) becomes safe — characterization tests prove the new implementation matches.

## Frontiers

- **Maestro frame-count assertions** — flows assert post-state only; could assert intermediate via screenshot diff. Limited by iOS 26 a11y breakage.
- **`MetricKit` GPU frame-time telemetry** — production observability informs which tests matter.
- **Generative sequencing** — combine §4 with §8: `forAll seq in validActionSequences { invariants hold }`. Closest shipping example: Pointfree TCA `TestStore` exhaustive testing.
- **Hot-reload snapshot recording** — Inject + swift-snapshot-testing so designers iterate without re-running tests.
- **Close the `RUN_VISUAL_AUDIT_HARNESS` loop** — scripts exist; missing piece is CI posting CSV correlation as PR status check.
