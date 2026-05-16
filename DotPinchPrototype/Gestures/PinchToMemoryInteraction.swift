// Pinch gesture → scalar progress on the SpringAnimator.
// Gesture-direct during .changed; spring-driven from .ended with velocity injection.

import UIKit
import CoreGraphics
import Foundation

final class PinchToMemoryInteraction: NSObject, UIInteraction {

    // MARK: - UIInteraction conformance

    weak var view: UIView?

    func willMove(to view: UIView?) {
        if let view = self.view {
            view.removeGestureRecognizer(pinch)
        }
        self.view = view
    }

    func didMove(to view: UIView?) {
        guard let view else { return }
        view.addGestureRecognizer(pinch)
    }

    private weak var animator: SpringAnimator<PinchMorphState>?

    private let pinch = UIPinchGestureRecognizer()
    private var anchorScale: CGFloat = 1.0
    /// Origin state at .began. Determines polarity: 0 → forward, 1 → reverse.
    private var origin: PinchMorphState = .zero

    // MARK: - Init

    init(animator: SpringAnimator<PinchMorphState>) {
        self.animator = animator
        super.init()
        pinch.addTarget(self, action: #selector(handlePinch(_:)))
    }

    // MARK: - Gesture handling

    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .began:
            handlePinchBegan(recognizer)
        case .changed:
            handlePinchChanged(recognizer)
        case .ended, .cancelled, .failed:
            handlePinchEnded(recognizer)
        default:
            break
        }
    }

    private func handlePinchBegan(_ recognizer: UIPinchGestureRecognizer) {
        // Reduce Motion: skip the spring path, snap directly to target.
        if shouldUseReducedMotion() {
            // Toggle between baseline and destination on each pinch attempt.
            guard let animator else { return }
            let current = animator.value?.progress ?? 0
            let target: CGFloat = current < 0.5 ? 1 : 0
            animator.value = PinchMorphState(progress: target)
            animator.target = PinchMorphState(progress: target)
            animator.valueChanged?(PinchMorphState(progress: target))
            recognizer.state = .cancelled
            return
        }
        anchorScale = recognizer.scale
        origin = animator?.value ?? .zero
        if let animator {
            animator.target = origin
            animator.velocity = .zero
            animator.stop(immediately: true)
        }
    }

    private func shouldUseReducedMotion() -> Bool {
        UIAccessibility.isReduceMotionEnabled
        || UIAccessibility.prefersCrossFadeTransitions
        || UIAccessibility.isVoiceOverRunning
        || UIAccessibility.isSwitchControlRunning
    }

    private func handlePinchChanged(_ recognizer: UIPinchGestureRecognizer) {
        guard let animator else { return }
        let newState = PinchMorphState(progress: gestureProgress(scale: recognizer.scale))
        animator.value = newState
        animator.valueChanged?(newState)
    }

    private func handlePinchEnded(_ recognizer: UIPinchGestureRecognizer) {
        guard let animator else { return }
        let currentProgress = gestureProgress(scale: recognizer.scale)
        let progressVel = progressVelocity(for: recognizer)
        let projectedRest = currentProgress + project(initialVelocity: progressVel)
        // Commit threshold aligns with the illegibility onset — past that point
        // the eye has already left the chat, so releasing means going forward.
        let shouldCommit = projectedRest > PinchTuning.commitProjectionThreshold
        let targetProgress: CGFloat = shouldCommit ? 1.0 : 0.0
        let vNorm = normalizedVelocity(gestureVelocity: progressVel, target: targetProgress, current: currentProgress)
        let injected: CGFloat = (abs(vNorm) < PinchTuning.velocityHandoffFloorPerSecond) ? 0 : vNorm
        animator.value = PinchMorphState(progress: currentProgress)
        animator.target = PinchMorphState(progress: targetProgress)
        animator.velocity = PinchMorphState(progress: injected)
        animator.start()
    }

    /// Scalar in, scalar out. Direction-respecting via origin polarity.
    private func gestureProgress(scale: CGFloat) -> CGFloat {
        let s = scale / anchorScale
        let isFromBaseline = origin.progress < 0.5
        let signed: CGFloat = isFromBaseline
            ? (1 - s) * PinchTuning.pinchSensitivity
            : (s - 1) * PinchTuning.pinchSensitivity
        let clamped = clamp(signed, PinchTuning.gestureClampLowerBound, PinchTuning.gestureClampUpperBound)
        let progress01 = rubberband(
            value: clamped,
            range: 0...1,
            interval: PinchTuning.rubberBandInterval,
            c: PinchTuning.rubberBandDampingC
        )
        return isFromBaseline ? progress01 : (1 - progress01)
    }

    private func progressVelocity(for recognizer: UIPinchGestureRecognizer) -> CGFloat {
        let magnitude = abs(recognizer.velocity) * PinchTuning.pinchSensitivity / 2.0
        let isFromBaseline = origin.progress < 0.5
        if isFromBaseline {
            return recognizer.velocity < 0 ? magnitude : -magnitude
        } else {
            return recognizer.velocity > 0 ? -magnitude : magnitude
        }
    }
}
