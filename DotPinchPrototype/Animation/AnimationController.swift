// Coordinates all animators via a single shared CADisplayLink. One link per
// app — animators share dt per frame so multi-property animations stay in
// lockstep. Each frame opens a CATransaction(setDisableActions: true) to
// suppress UIKit's implicit animations under the per-frame view writes.

import Foundation
import QuartzCore
import UIKit

/// Weak-proxy target for the CADisplayLink. Breaks the runloop → displayLink
/// → target retain cycle so `AnimationController.deinit` actually fires.
@MainActor
private final class DisplayLinkProxy {
    weak var controller: AnimationController?

    init(controller: AnimationController) {
        self.controller = controller
    }

    @objc func displayLinkFired(_ link: CADisplayLink) {
        controller?._displayLinkFired(link)
    }
}

@MainActor
public final class AnimationController {

    private var animations: [UUID: AnimatorProviding] = [:]

    private var displayLink: CADisplayLink?
    private var proxy: DisplayLinkProxy?

    public init() {
        let proxy = DisplayLinkProxy(controller: self)
        let link = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.displayLinkFired(_:)))
        // ProMotion 120Hz on iPhone 16. Default would be 60Hz.
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        link.isPaused = true
        self.proxy = proxy
        self.displayLink = link
    }

    deinit {
        displayLink?.invalidate()
        displayLink = nil
        proxy = nil
        animations.removeAll()
    }

    fileprivate func _displayLinkFired(_ link: CADisplayLink) {
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
            displayLink?.isPaused = true
        }
    }

    /// Register an animator. The display link starts on first registration and
    /// pauses when the animations dictionary empties.
    func runPropertyAnimation(_ animator: AnimatorProviding) {
        let wasEmpty = animations.isEmpty
        animations[animator.id] = animator

        if wasEmpty {
            displayLink?.isPaused = false
        }

        // Tick once synchronously at dt=0 so the view paints at its starting
        // value on the same vsync as the start() call.
        CATransaction.withSuppressedActions {
            animator.updateAnimation(dt: 0)
        }
    }
}
