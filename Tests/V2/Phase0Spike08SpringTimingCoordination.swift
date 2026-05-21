// Phase0Spike08SpringTimingCoordination.swift
//
// Probes whether two UIViewPropertyAnimator instances initialized with
// identical UISpringTimingParameters evolve with identical fractionComplete.
// The first test verifies the shared-params guarantee. The second proves
// empirically that DIFFERENT initialVelocity breaks fractionComplete
// identity — that result is retained as historical record (XCTSkip) since
// the production substrate (SpringAnimator's shared AnimationController)
// supersedes the original fractionComplete-identity hypothesis.

import XCTest
@testable import DotPinchPrototype

@MainActor
final class Phase0Spike08SpringTimingCoordination: XCTestCase {

    /// Same params, same initial velocity, different absolute ranges →
    /// fractionComplete identical at every sample.
    func testSharedParamsIdenticalFractionComplete() {
        let timing = UISpringTimingParameters(
            mass: 1.0,
            stiffness: 200,
            damping: 25,
            initialVelocity: .zero
        )
        let animatorA = UIViewPropertyAnimator(duration: 0, timingParameters: timing)
        let animatorB = UIViewPropertyAnimator(duration: 0, timingParameters: timing)

        // Real UIViews with animatable properties so animators have something
        // to drive (otherwise they complete immediately).
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let viewA = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        let viewB = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        window.addSubview(viewA)
        window.addSubview(viewB)
        window.makeKeyAndVisible()

        // Different target ranges — small for A, 10x for B.
        animatorA.addAnimations { viewA.frame.origin.y = 100 }
        animatorB.addAnimations { viewB.frame.origin.y = 1000 }

        animatorA.startAnimation()
        animatorB.startAnimation()

        // Sample fractionComplete at 16ms intervals (60Hz approximation).
        var maxDifference: CGFloat = 0
        let expectation = expectation(description: "both animators settle")
        var sampleCount = 0

        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            let fa = CGFloat(animatorA.fractionComplete)
            let fb = CGFloat(animatorB.fractionComplete)
            let diff = abs(fa - fb)
            if diff > maxDifference { maxDifference = diff }
            sampleCount += 1

            if animatorA.state != .active && animatorB.state != .active {
                timer.invalidate()
                expectation.fulfill()
            }
            if sampleCount > 300 {  // safety: ~5 seconds max
                timer.invalidate()
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 6.0)

        XCTAssertGreaterThan(sampleCount, 10,
            "Sample count should be > 10 across animation duration")
        XCTAssertLessThan(maxDifference, 1e-3,
            "max |fractionComplete_a - fractionComplete_b| must be < 1e-3; observed \(maxDifference)")
    }

    /// Same params, DIFFERENT initial velocities. Empirically disproves
    /// the original fractionComplete-identity hypothesis: springs with
    /// the same dampingRatio/response but different initialVelocity have
    /// different settle times. Retained as historical record via XCTSkip.
    func testSharedParamsDifferentVelocities() throws {
        let timingA = UISpringTimingParameters(
            mass: 1.0,
            stiffness: 200,
            damping: 25,
            initialVelocity: CGVector(dx: 0, dy: 5)
        )
        let timingB = UISpringTimingParameters(
            mass: 1.0,
            stiffness: 200,
            damping: 25,
            initialVelocity: CGVector(dx: 0, dy: -2)
        )
        let animatorA = UIViewPropertyAnimator(duration: 0, timingParameters: timingA)
        let animatorB = UIViewPropertyAnimator(duration: 0, timingParameters: timingB)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let viewA = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        let viewB = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        window.addSubview(viewA)
        window.addSubview(viewB)
        window.makeKeyAndVisible()

        animatorA.addAnimations { viewA.frame.origin.y = 100 }
        animatorB.addAnimations { viewB.frame.origin.y = 100 }

        animatorA.startAnimation()
        animatorB.startAnimation()

        var maxDifference: CGFloat = 0
        let expectation = expectation(description: "settle")
        var sampleCount = 0

        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            let fa = CGFloat(animatorA.fractionComplete)
            let fb = CGFloat(animatorB.fractionComplete)
            let diff = abs(fa - fb)
            if diff > maxDifference { maxDifference = diff }
            sampleCount += 1

            if animatorA.state != .active && animatorB.state != .active {
                timer.invalidate()
                expectation.fulfill()
            }
            if sampleCount > 300 {
                timer.invalidate()
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 6.0)

        print("[spike] testSharedParamsDifferentVelocities maxDifference: \(maxDifference) across \(sampleCount) samples")

        XCTAssertGreaterThan(sampleCount, 10)
        // Original fractionComplete-identity invariant proven empirically
        // false here. The production substrate (shared AnimationController
        // in SpringAnimator) is the actual sync guarantee — see
        // WaveR41SubstrateCanaryTests.
        throw XCTSkip("Original fractionComplete-identity invariant proven "
                      + "empirically false (maxDifference: \(maxDifference)). "
                      + "See WaveR41SubstrateCanaryTests for the substrate canary.")
    }
}
