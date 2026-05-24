import UIKit
import QuartzCore

@MainActor
final class MorphChoreographer {

    private weak var canvas: TimelineCanvas?
    private let controller: AnimationController
    private var curveAnimator: CurveAnimator<CGFloat>?
    private var choreography: MorphChoreography?
    private var completion: (() -> Void)?

    var isRunning: Bool { curveAnimator != nil }

    init(canvas: TimelineCanvas, controller: AnimationController) {
        self.canvas = canvas
        self.controller = controller
    }

    func engage(_ choreo: MorphChoreography, completion: @escaping () -> Void) {
        stop()
        self.choreography = choreo
        self.completion = completion

        let timing = CAMediaTimingFunction(name: .linear)
        let curve = CurveAnimator<CGFloat>.Curve(
            duration: choreo.duration,
            timingFunction: timing,
            from: 0,
            to: 1
        )
        let animator = CurveAnimator<CGFloat>(
            controller: controller,
            curve: curve,
            onTick: { [weak self] rawT in
                self?.handleTick(rawT: rawT)
            },
            onComplete: { [weak self] in
                self?.handleComplete()
            }
        )
        curveAnimator = animator
        animator.start()
    }

    func stop() {
        curveAnimator?.stop(immediately: true)
        curveAnimator = nil
        choreography = nil
        completion = nil
    }

    private func handleTick(rawT: CGFloat) {
        guard let choreo = choreography, let canvas else { return }
        apply(rawT: rawT, choreography: choreo, canvas: canvas)
    }

    private func handleComplete() {
        let done = completion
        curveAnimator = nil
        choreography = nil
        completion = nil
        done?()
    }

    private func apply(rawT t: CGFloat, choreography choreo: MorphChoreography, canvas: TimelineCanvas) {
        guard let cell = canvas.instantiatedCells[choreo.activeCellIndex],
              let heightC = cell.heightConstraint else { return }

        let tClamped = max(0, min(1, t))
        let liftPhase = min(tClamped / 0.70, 1.0)
        let liftBell = sin(liftPhase * .pi)
        let unifiedArcY = -choreo.unifiedArcYMagnitude * liftBell
        let unifiedArcZ = choreo.unifiedArcZMagnitude * liftBell

        let newHeight = choreo.startHeight + (choreo.endHeight - choreo.startHeight) * tClamped
        let newCameraY = choreo.startCameraY + (choreo.endCameraY - choreo.startCameraY) * tClamped

        CATransaction.withSuppressedActions {
            canvas.contentHost.layer.transform = CATransform3DMakeTranslation(0, unifiedArcY, unifiedArcZ)
            heightC.constant = newHeight
            canvas.contentHost.layoutIfNeeded()
            canvas.applyMorphTickCameraWrite(translation: newCameraY, cell: cell)
        }
    }
}
