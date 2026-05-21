// CameraAnimator — wraps a single SpringAnimator<CGFloat> that drives the
// camera's page-y translation. Public surface is animate / stop / isRunning.

import CoreGraphics
import Foundation
import QuartzCore

/// Velocity carrier for the camera animator. Single scalar (page-coord/sec).
public struct CameraVelocity: Equatable {
    public var translationVelocity: CGFloat  // page-coord per second

    public static let zero = CameraVelocity(translationVelocity: 0)

    public init(translationVelocity: CGFloat) {
        self.translationVelocity = translationVelocity
    }
}

@MainActor
final class CameraAnimator {

    // MARK: - Tuning

    /// Velocity floor (page-coord/sec). Below this magnitude, engagement
    /// velocity is treated as zero so the spring settles unforced.
    static let velocityFloor: CGFloat = 1.0

    // MARK: - Collaborators

    private weak var canvas: TimelineCanvas?
    private let translationAnimator: SpringAnimator<CGFloat>

    // MARK: - Outer completion state

    private var pendingCompletion: (() -> Void)?
    private var outerCompletionFired: Bool = true  // true => not engaged
    private var stoppedByCaller: Bool = false

    // MARK: - Init

    init(
        canvas: TimelineCanvas,
        controller: AnimationController,
        spring: Spring = Spring(
            dampingRatio: PinchTuning.springDamping,
            response: PinchTuning.springResponse
        )
    ) {
        self.canvas = canvas
        self.translationAnimator = SpringAnimator<CGFloat>(
            controller: controller,
            spring: spring
        )

        wireValueChangedAndCompletion()
    }

    private func wireValueChangedAndCompletion() {
        translationAnimator.valueChanged = { [weak self] _ in
            self?.writeCameraFromInnerValue()
        }
        translationAnimator.completion = { [weak self] event in
            guard case .finished = event else { return }
            self?.tryFireOuterCompletion()
        }
    }

    // MARK: - Public API

    var isRunning: Bool {
        translationAnimator.state == .running
    }

    /// Exposed for a canary test asserting camera + extension animators share
    /// the same AnimationController instance.
    internal var animationControllerIdentity: AnyObject? {
        translationAnimator.animationControllerIdentity
    }

    /// Current velocity of the inner translation animator (for tests).
    /// NOTE: when `animate(to:velocity:)` short-circuits via same-target,
    /// velocity is NOT written to the inner animator — use
    /// `lastAnimateVelocityForTesting` for the post-floor value as passed in.
    internal var translationVelocityForTesting: CGFloat {
        translationAnimator.velocity
    }

    /// The velocity value (post-floor) passed to the most recent `animate`
    /// call. Set before the same-target short-circuit so tests can verify
    /// velocity capture even when the spring doesn't engage.
    internal private(set) var lastAnimateVelocityForTesting: CGFloat = 0

    /// Engage motion toward `target` from the canvas's current camera. Outer
    /// `completion` fires exactly once when the spring settles. If `target`
    /// equals the current camera within 1e-9, the call is a no-op and
    /// `completion` fires synchronously.
    ///
    /// When `spring` is non-nil, swaps the inner translationAnimator's spring
    /// before engagement (per-direction profile selection). Callers must apply
    /// the SAME Spring to the paired extension animator for within-animation
    /// identity.
    func animate(
        to target: Camera,
        velocity: CameraVelocity = .zero,
        spring: Spring? = nil,
        completion: (() -> Void)? = nil
    ) {
        guard let canvas else {
            completion?()
            return
        }

        if !outerCompletionFired {
            stoppedByCaller = true
            translationAnimator.stop(immediately: true)
        }

        if let spring {
            translationAnimator.spring = spring
        }

        let current = canvas.camera
        let rawVel = velocity.translationVelocity
        let safeVel: CGFloat = {
            guard rawVel.isFinite else { return 0 }
            if abs(rawVel) < Self.velocityFloor { return 0 }
            return rawVel
        }()
        // Record post-floor velocity BEFORE same-target short-circuit.
        lastAnimateVelocityForTesting = safeVel

        outerCompletionFired = false
        stoppedByCaller = false
        pendingCompletion = completion

        let sameTarget = current.isApproximatelyEqual(target, tolerance: 1e-9)
        if sameTarget {
            outerCompletionFired = true
            let pending = pendingCompletion
            pendingCompletion = nil
            pending?()
            return
        }

        translationAnimator.value = current.translation
        translationAnimator.target = target.translation
        translationAnimator.velocity = safeVel
        translationAnimator.start()
    }

    internal var dampingRatioForTesting: CGFloat {
        translationAnimator.spring.dampingRatio
    }

    internal var responseForTesting: CGFloat {
        translationAnimator.spring.response
    }

    /// Halt the animator. Outer completion does NOT fire on caller-initiated
    /// stops — callers needing confirmation use natural settle.
    func stop(immediately: Bool = true) {
        stoppedByCaller = true
        pendingCompletion = nil
        outerCompletionFired = true
        translationAnimator.stop(immediately: immediately)
    }

    // MARK: - Per-tick application

    private func writeCameraFromInnerValue() {
        guard let canvas, let translation = translationAnimator.value else { return }
        let safe = translation.isFinite ? translation : 0
        canvas.setCamera(Camera(translation: safe))
    }

    // MARK: - Outer completion gating

    private func tryFireOuterCompletion() {
        guard !outerCompletionFired else { return }
        outerCompletionFired = true
        let suppress = stoppedByCaller
        let pending = pendingCompletion
        pendingCompletion = nil
        if !suppress {
            // Final-frame flush so observers see the fully-settled camera.
            writeCameraFromInnerValue()
            pending?()
        }
    }
}
