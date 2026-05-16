// Coordinates all animators via a single shared CADisplayLink.
//
// One display link per app — animators share dt per frame so multi-property
// animations stay in lockstep. Each frame opens a CATransaction with
// setDisableActions(true), suppressing UIKit's implicit 0.25s animations
// underneath any view writes the per-frame valueChanged closures perform.
// On registration the animator ticks once synchronously at dt=0 so the view
// paints at its starting value on the same vsync as the start() call.
//
// Not a singleton. The composition root creates one instance and injects it
// into every SpringAnimator that needs to run.

import Foundation
import QuartzCore
import UIKit

public final class AnimationController {

    private var animations: [UUID: AnimatorProviding] = [:]

    private lazy var displayLink: CADisplayLink = {
        let link = CADisplayLink(target: self, selector: #selector(displayLinkFired(_:)))
        // ProMotion 120Hz on iPhone 16. Default would be 60Hz.
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        link.isPaused = true
        return link
    }()

    public init() {}

    @objc private func displayLinkFired(_ link: CADisplayLink) {
        let dt = link.targetTimestamp - link.timestamp

        CATransaction.withSuppressedActions {
            for animator in animations.values {
                if animator.state == .ended {
                    animator.reset()
                    animations.removeValue(forKey: animator.id)
                } else {
                    animator.updateAnimation(dt: dt)
                }
            }
        }

        if animations.isEmpty {
            displayLink.isPaused = true
        }
    }

    /// Register an animator. The display link starts on first registration and
    /// pauses when the animations dictionary empties.
    func runPropertyAnimation(_ animator: AnimatorProviding) {
        let wasEmpty = animations.isEmpty
        animations[animator.id] = animator

        if wasEmpty {
            displayLink.isPaused = false
        }

        // Tick once synchronously at dt=0 so the view paints at its starting
        // value on the same vsync as the start() call.
        CATransaction.withSuppressedActions {
            animator.updateAnimation(dt: 0)
        }
    }
}
