//
//  SpringAnimator.swift
//  DotPinchPrototype
//
//  Generic stateful spring integrator. The heart of the substrate.
//
//  This is the artifact that encodes the seven most load-bearing Wave rules
//  (see dot-pinch-lens-check/team_findings/wave_philosophy.md):
//
//   • NINETY-pinch-E01  Velocity is sacred — preserve across every target change.
//                       The `target.didSet` setter below does NOT zero velocity; it only
//                       resets startTime and fires the .retargeted event. The velocity
//                       instance variable continues into the next frame's physics integration
//                       unchanged. This is the mechanism that makes mid-flight gesture
//                       reversal bend the trajectory rather than snap.
//
//   • NINETY-pinch-E04  Don't model progress as 0→1. Model absolute values flowing through
//                       physics. The state space is {value, target, velocity} in the
//                       property's native type — there is no `progress` field here.
//
//   • NINETY-pinch-E05  Decouple the animator from the view via a closure boundary.
//                       `valueChanged: (T.ValueType) -> Void` is the seam. The animator
//                       knows nothing about UIView/CALayer; the closure does the painting.
//
//   • NINETY-pinch-E07  One animator per property type (caller-keyed dictionary, see
//                       AnimationController). The animator's identity is the channel.
//
//   • NINETY-pinch-E08  Gesture velocity injection. The `velocity` property is publicly
//                       settable; the gesture handler writes its terminal velocity here
//                       after configure() — see PinchToMemoryInteraction.handlePinch(.ended).
//
//   • NINETY-pinch-E11  Settling time has a derived ground truth. We use the spring's
//                       `settlingDuration` (closed-form physics), not a position threshold.
//
//   • NINETY-pinch-EP1  Animations are state, not effects. This class is a stateful
//                       integrator; the AnimationController holds a reference; the gesture
//                       handler retargets it; physics ticks once per display frame.
//

import Foundation
import QuartzCore

/// A protocol-free type erasure so AnimationController can hold animators of varied T.
protocol AnimatorProviding: AnyObject {
    var id: UUID { get }
    var state: AnimatorState { get }
    func updateAnimation(dt: TimeInterval)
    func reset()
}

public enum AnimatorState: Equatable {
    case inactive
    case running
    case ended
}

public final class SpringAnimator<T: SpringInterpolatable>: AnimatorProviding where T.ValueType == T {

    public enum Event {
        case finished(at: T.ValueType)
        case retargeted(from: T.ValueType, to: T.ValueType)
    }

    public let id = UUID()

    public private(set) var state: AnimatorState = .inactive {
        didSet {
            if case (.inactive, .running) = (oldValue, state) {
                startTime = CACurrentMediaTime()
            }
        }
    }

    public var spring: Spring

    /// The current value of the animation. Mutates per frame via spring integration.
    public var value: T.ValueType?

    /// The target value of the animation. Mutating this in-flight RETARGETS the animation
    /// (per E01) — velocity is preserved; only `startTime` resets and `.retargeted` fires.
    public var target: T.ValueType? {
        didSet {
            guard let oldValue, let newValue = target, oldValue != newValue else { return }
            if state == .running {
                startTime = CACurrentMediaTime()
                completion?(.retargeted(from: oldValue, to: newValue))
            }
        }
    }

    /// The current velocity. Publicly settable so the gesture handler can inject the
    /// gesture's terminal velocity on .ended (per E08). The spring's next integration
    /// step will use this velocity as the initial condition.
    public var velocity: T.VelocityType

    /// The boundary where physics meets the visible world (per E05). Called once per
    /// frame inside the CATransaction.setDisableActions(true) wrapper.
    public var valueChanged: ((T.ValueType) -> Void)?

    public var completion: ((Event) -> Void)?

    public var mode: AnimationMode = .animated

    var startTime: TimeInterval?

    public init(spring: Spring, value: T.ValueType? = nil, target: T.ValueType? = nil) {
        self.spring = spring
        self.value = value
        self.target = target
        self.velocity = T.VelocityType.zero
    }

    /// Start the animation, registering with the AnimationController.
    ///
    /// NINETY-pinch-E14: the first frame ticks at dt=0 synchronously here so the view
    /// is painted at its current value on the same vsync as the start call. No
    /// one-frame-late flash. The AnimationController's runPropertyAnimation handles this.
    public func start() {
        precondition(value != nil, "Animator requires non-nil `value` before start.")
        precondition(target != nil, "Animator requires non-nil `target` before start.")
        AnimationController.shared.runPropertyAnimation(self)
    }

    public func stop(immediately: Bool = true) {
        if immediately {
            state = .ended
            if let value, let completion {
                completion(.finished(at: value))
            }
        } else if let value {
            target = value
        }
    }

    public func reset() {
        startTime = nil
        velocity = T.VelocityType.zero
        state = .inactive
    }

    var runningTime: TimeInterval? {
        startTime.map { CACurrentMediaTime() - $0 }
    }

    /// One step of integration. Called by AnimationController on each display refresh.
    ///
    /// The CATransaction.setDisableActions(true) wrap is in AnimationController — by the
    /// time this runs, implicit animations are already suppressed (E03).
    func updateAnimation(dt: TimeInterval) {
        guard let value, let target else {
            state = .inactive
            return
        }

        state = .running

        guard let runningTime else { return }

        let isAnimated = spring.response > 0 && mode == .animated

        let (newValue, newVelocity): (T.ValueType, T.VelocityType)
        if isAnimated {
            (newValue, newVelocity) = T.updateValue(
                spring: spring,
                value: value,
                target: target,
                velocity: velocity,
                dt: dt
            )
        } else {
            // E15: non-animated mode goes through the animator so cleanup runs.
            newValue = target
            newVelocity = T.VelocityType.zero
        }

        self.value = newValue
        self.velocity = newVelocity

        let finished = (runningTime >= spring.settlingDuration) || !isAnimated
        if finished {
            self.value = target
        }

        valueChanged?(self.value ?? target)

        if finished {
            completion?(.finished(at: target))
            state = .ended
        }
    }
}

public enum AnimationMode {
    case animated
    case nonAnimated
}
