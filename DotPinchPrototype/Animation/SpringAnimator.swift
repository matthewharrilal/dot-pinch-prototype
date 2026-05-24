// Generic stateful spring integrator. Wave-style — adapted from jtrivedi/Wave.
// Velocity is preserved across target changes (mid-flight retarget bends the
// trajectory); valueChanged is the seam to UIKit/CALayer. Settling completes
// via the spring's closed-form settlingDuration, not a position threshold.

import Foundation
import QuartzCore

@MainActor
public final class SpringAnimator<T: SpringInterpolatable>: AnimatorProviding where T.ValueType == T {

    // MARK: - Events

    @frozen
    public enum Event {
        case finished(at: T.ValueType)
        case retargeted(from: T.ValueType, to: T.ValueType)
    }

    // MARK: - Identity & state

    public let id = UUID()

    public private(set) var state: AnimatorState = .inactive

    public var spring: Spring

    public var value: T.ValueType?

    /// Mutating in-flight RETARGETS — velocity is preserved, startTime resets,
    /// and `.retargeted` fires.
    public var target: T.ValueType? {
        didSet {
            guard let oldValue, let newValue = target, oldValue != newValue else { return }
            if state == .running {
                startTime = CACurrentMediaTime()
                completion?(.retargeted(from: oldValue, to: newValue))
            }
        }
    }

    /// Publicly settable so a gesture handler can inject terminal velocity on .ended.
    public var velocity: T.VelocityType

    var startTime: TimeInterval?

    // MARK: - Callbacks

    public var valueChanged: ((T.ValueType) -> Void)?

    public var completion: ((Event) -> Void)?

    // MARK: - Dependencies (injected)

    private weak var controller: AnimationController?

    /// Identity accessor for the canary test that asserts camera + extension
    /// animators share the same AnimationController instance.
    internal var animationControllerIdentityForTesting: AnyObject? { controller }

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
        // target.didSet only sets startTime when state==.running; on first start
        // state is .inactive, so set it here or the spring never integrates.
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

    /// One step of integration. Final-tick ordering contract (load-bearing):
    /// value → valueChanged → completion → state=.ended. `tryClearActiveCellAtRest`
    /// depends on completion firing while state is still .running.
    func updateAnimation(dt: TimeInterval) {
        guard let value, let target else {
            state = .inactive
            return
        }

        if state != .running {
            state = .running
            if startTime == nil { startTime = CACurrentMediaTime() }
        }

        guard let runningTime else { return }

        let (newValue, newVelocity) = T.updateValue(
            spring: spring,
            value: value,
            target: target,
            velocity: velocity,
            dt: dt
        )

        self.value = newValue
        self.velocity = newVelocity

        if !newValue.isFinite || !newVelocity.isFinite {
            self.value = target
            self.velocity = T.VelocityType.zero
            valueChanged?(target)
            completion?(.finished(at: target))
            state = .ended
            return
        }

        let finished = runningTime >= spring.settlingDuration
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
