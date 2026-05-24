// Coordinates all animators via a single shared CADisplayLink. One link per
// app — animators share dt per frame so multi-property animations stay in
// lockstep. Each frame opens a CATransaction(setDisableActions: true) to
// suppress UIKit's implicit animations under the per-frame view writes.

import Foundation
import QuartzCore

@MainActor
public final class AnimationController {

    private var animations: [UUID: AnimatorProviding] = [:]
    /// Registration order. Callers depending on cross-animator state
    /// coordination (dual-spring AND-gate in tryClearActiveCellAtRest) must
    /// register the animator that should tick FIRST first.
    private var insertionOrder: [UUID] = []

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
        insertionOrder.removeAll()
    }

    fileprivate func displayLinkFired(_ link: CADisplayLink) {
        let dt = link.targetTimestamp - link.timestamp

        CATransaction.withSuppressedActions {
            for id in insertionOrder {
                guard let animator = animations[id] else { continue }
                if animator.state == .ended {
                    animator.reset()
                    animations.removeValue(forKey: id)
                } else {
                    animator.updateAnimation(dt: dt)
                }
            }
            insertionOrder.removeAll { animations[$0] == nil }
        }

        if animations.isEmpty {
            displayLink?.isPaused = true
        }
    }

    /// Register an animator. The display link starts on first registration and
    /// pauses when the animations dictionary empties.
    func runPropertyAnimation(_ animator: AnimatorProviding) {
        let wasEmpty = animations.isEmpty
        if animations[animator.id] == nil {
            insertionOrder.append(animator.id)
        }
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

// MARK: - Display-link weak-proxy

/// Weak-proxy target for the CADisplayLink. Breaks the runloop → displayLink
/// → target retain cycle so `AnimationController.deinit` actually fires.
@MainActor
private final class DisplayLinkProxy {
    weak var controller: AnimationController?

    init(controller: AnimationController) {
        self.controller = controller
    }

    @objc func displayLinkFired(_ link: CADisplayLink) {
        controller?.displayLinkFired(link)
    }
}
