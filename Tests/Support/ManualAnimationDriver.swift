// ManualAnimationDriver.swift — PLACEHOLDER for deterministic spring sampling.
//
// Per HANDOFF-CHECKLIST.md §47.6 N11 and T12 deliverable: tests need a way
// to advance the animation clock deterministically per tick so they can
// assert on per-frame trajectory values (e.g., "at gesture-progress 0.5,
// camera.scale should be X ± epsilon").
//
// Current state: PLACEHOLDER. AnimationController owns a CADisplayLink
// directly (DotPinchPrototype/Animation/AnimationController.swift:18-29).
// Injecting a manual driver requires refactoring AnimationController to
// take a Ticker protocol — a non-trivial change that touches the K3
// keystone (single CADisplayLink discipline per CLAUDE.md Part 4).
//
// Plan once unblocked:
//   1. Extract `Ticker` protocol: `func subscribe(_:Tickable)`, `pause()`, `resume()`
//   2. AnimationController.init takes `Ticker = CADisplayLinkTicker()`
//   3. ManualAnimationDriver.advance(dt:) steps all subscribed animators by dt
//   4. NavSubstrateInvariantTests inject ManualAnimationDriver for deterministic asserts
//
// Until then, tests calling for ManualAnimationDriver XCTSkip with this file
// path as the rationale.

import Foundation
import QuartzCore

#if DEBUG

@MainActor
public protocol Tickable: AnyObject {
    func advance(dt: TimeInterval)
}

@MainActor
public final class ManualAnimationDriver {
    private var subscribers: [Tickable] = []
    private(set) var totalElapsed: TimeInterval = 0

    public init() {}

    public func subscribe(_ tickable: Tickable) {
        subscribers.append(tickable)
    }

    public func unsubscribe(_ tickable: Tickable) {
        subscribers.removeAll { $0 === tickable }
    }

    public func advance(dt: TimeInterval) {
        totalElapsed += dt
        for subscriber in subscribers {
            subscriber.advance(dt: dt)
        }
    }

    public func advance(toTime t: TimeInterval, stepSize: TimeInterval = 1.0 / 120.0) {
        let target = t
        while totalElapsed < target - stepSize {
            advance(dt: stepSize)
        }
        let remainder = target - totalElapsed
        if remainder > 0 {
            advance(dt: remainder)
        }
    }
}

#endif
