# Tests/

Wave-4 introduced this directory + the `DotPinchPrototypeTests` target (`project.yml`). Three suites live here:

- `MorphStateTests.swift` — covers `ActiveConversationCoordinator` + `MorphState` (P4 state machine).
- `ReactiveBindingsTests.swift` — covers `CellSummaryView` re-arm cycles (wave-3 reactive bindings).
- `SpatialAnchorResolverTests.swift` — covers `SpatialAnchorResolver` (P6 spatial anchor lookup, wave-5 W5-G2).

## Animation/-collaborator retention pattern (load-bearing)

The coordinator holds `animator`, `animationController`, and `store` **weakly** (W2-G2 — the VC owns them strongly in production). Unit tests have no VC, so the test target itself must retain those collaborators for the lifetime of each test method. Otherwise the weak references nil immediately and `coordinator.requestActivate(...)`'s `guard let animator else { return }` bails silently — tests pass-but-don't-assert (or fail with confusing equality errors).

### Current pattern: `TestFixture` (wave-5 W5-G6)

Wave-5 retired the prior `_retainedAnimator` workaround in favor of a value-type bundle. A single `let fx = makeFixture()` binding holds all four collaborators by composition; ARC keeps them alive for the full test method scope. No instance-level retention slots, no `tearDown` body to zero them out.

```swift
@MainActor
struct TestFixture {
    let coordinator: ActiveConversationCoordinator
    let animator: SpringAnimator<PinchMorphState>
    let store: ConversationStore
    let controller: AnimationController
}

@MainActor
final class MyCoordinatorTests: XCTestCase {

    private func makeFixture() -> TestFixture {
        let controller = AnimationController()
        let animator = SpringAnimator<PinchMorphState>(...)
        let store = ConversationStore(...)
        let coordinator = ActiveConversationCoordinator(
            animator: animator, store: store
        )
        return TestFixture(
            coordinator: coordinator,
            animator: animator,
            store: store,
            controller: controller
        )
    }

    func testSomething() {
        let fx = makeFixture()
        fx.coordinator.requestActivate(fx.store.conversations[0].id)
        // ... `fx` retains all four collaborators by composition.
    }
}
```

## Driving the coordinator deterministically

The coordinator subscribes to `animator.valueChanged` + `animator.completion`. Tests drive transitions WITHOUT waiting for real spring physics by invoking the completion closure directly:

```swift
private func settle(_ animator: SpringAnimator<PinchMorphState>, at progress: CGFloat) {
    animator.completion?(.finished(at: PinchMorphState(progress: progress)))
}

private func retarget(_ animator: SpringAnimator<PinchMorphState>, from oldP: CGFloat, to newP: CGFloat) {
    animator.completion?(.retargeted(
        from: PinchMorphState(progress: oldP),
        to: PinchMorphState(progress: newP)
    ))
}
```

Note: these helpers BYPASS `animator.stop(immediately:)` — they only exercise the bridge translation, not the stop path. Per wave-4 retro S-4/S-11, tests that need to verify gesture-takeover safety (`stop(immediately:)` firing mid-flight `.finished`) call `coordinator.handleBackgrounding()` OR invoke the completion closure with a non-terminal progress value.

## Running tests

```bash
xcodebuild -scheme DotPinchPrototype \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' \
  test
```

All tests (25 + new `SpatialAnchorResolverTests`) must pass.
