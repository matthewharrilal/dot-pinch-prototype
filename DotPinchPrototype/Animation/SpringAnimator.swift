// Generic stateful spring integrator. Wave-style — adapted from jtrivedi/Wave.
//
// Key invariants:
//   • Velocity is preserved across target changes (mid-flight retarget bends the
//     trajectory rather than snapping). The target.didSet only resets startTime
//     and emits .retargeted; it never touches velocity.
//   • The animator knows nothing about UIView/CALayer — valueChanged is the seam.
//   • Settling completes via the spring's closed-form settlingDuration, not a
//     position threshold.

import Foundation
import QuartzCore

/// Type-erased animator handle so AnimationController can hold animators of varied T.
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

    // MARK: - Events

    public enum Event {
        case finished(at: T.ValueType)
        case retargeted(from: T.ValueType, to: T.ValueType)
    }

    // MARK: - Identity & state

    public let id = UUID()

    public private(set) var state: AnimatorState = .inactive {
        didSet {
            if oldValue == .inactive, state == .running {
                startTime = CACurrentMediaTime()
            }
        }
    }

    public var spring: Spring

    /// The current value of the animation. Mutates per frame via spring integration.
    public var value: T.ValueType?

    /// The target value. Mutating in-flight RETARGETS — velocity is preserved,
    /// startTime resets, and `.retargeted` fires.
    public var target: T.ValueType? {
        didSet {
            guard let oldValue, let newValue = target, oldValue != newValue else { return }
            if state == .running {
                startTime = CACurrentMediaTime()
                completion?(.retargeted(from: oldValue, to: newValue))
            }
        }
    }

    /// The current velocity. Publicly settable so a gesture handler can inject
    /// terminal velocity on .ended; used as the next integration step's initial condition.
    public var velocity: T.VelocityType

    public var mode: AnimationMode = .animated

    var startTime: TimeInterval?

    // MARK: - Callbacks

    /// Called once per frame inside the CATransaction.setDisableActions(true) wrapper.
    public var valueChanged: ((T.ValueType) -> Void)?

    public var completion: ((Event) -> Void)?

    // MARK: - Dependencies (injected)

    /// The display-link coordinator that owns the per-frame tick. Held weakly
    /// — the composition root owns the controller; animators never extend its lifetime.
    private weak var controller: AnimationController?

    // MARK: - Init

    public init(controller: AnimationController,
                spring: Spring,
                value: T.ValueType? = nil,
                target: T.ValueType? = nil) {
        self.controller = controller
        self.spring = spring
        self.value = value
        self.target = target
        self.velocity = T.VelocityType.zero
    }

    // MARK: - Lifecycle

    public func start() {
        precondition(value != nil, "Animator requires non-nil `value` before start.")
        precondition(target != nil, "Animator requires non-nil `target` before start.")
        // target.didSet only sets startTime when state==.running. On first start
        // state is .inactive, so set startTime here or the spring never integrates.
        startTime = CACurrentMediaTime()
        controller?.runPropertyAnimation(self)
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

    // MARK: - Integration

    var runningTime: TimeInterval? {
        startTime.map { CACurrentMediaTime() - $0 }
    }

    /// One step of integration, called by AnimationController per display refresh.
    /// CATransaction.setDisableActions(true) is opened in AnimationController, so
    /// implicit animations are already suppressed by the time this runs.
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
            // Non-animated mode still flows through the animator so cleanup runs.
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

// MARK: - Animation mode

public enum AnimationMode {
    case animated
    case nonAnimated
}
