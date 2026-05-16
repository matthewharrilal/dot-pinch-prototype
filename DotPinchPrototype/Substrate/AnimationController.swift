//
//  AnimationController.swift
//  DotPinchPrototype
//
//  Singleton coordinating ALL animators via a single shared CADisplayLink.
//
//  Rules encoded here:
//
//   • NINETY-pinch-E02  One display link, never per-animation timers. All animators on the
//                       same frame share the same dt — eliminating sub-millisecond skew
//                       between properties that would otherwise compound into visible
//                       shimmer. The callback iterates `animations.values` and ticks each
//                       with the same dt.
//
//   • NINETY-pinch-E03  Suppress every implicit animation underneath the explicit one.
//                       The per-frame block opens CATransaction.begin() + setDisableActions(true),
//                       runs all updateAnimation(dt:) calls (which fire valueChanged closures
//                       that write to view properties), then commits. UIKit's default 0.25s
//                       implicit animations on CALayer properties are thus suppressed —
//                       Wave-style discipline.
//
//   • NINETY-pinch-E14  First frame ticks at dt=0 synchronously when an animation is
//                       registered. The view paints at its animation-state position on the
//                       same vsync as the start call. No one-frame-late flash.
//
//   • The dictionary is keyed by UUID for this generic controller — at the PinchToMemoryInteraction
//     level, we maintain a single composite animator (PinchMorphState) rather than per-property
//     animators, which is the conjecture's Decision 5 elevation move (NINETY-pinch-EP5).
//

import Foundation
import QuartzCore
import UIKit

final class AnimationController {

    static let shared = AnimationController()

    private var animations: [UUID: AnimatorProviding] = [:]

    private lazy var displayLink: CADisplayLink = {
        let link = CADisplayLink(target: self, selector: #selector(displayLinkFired(_:)))
        // ProMotion 120Hz on iPhone 16. Default would be 60Hz.
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        link.isPaused = true
        return link
    }()

    private init() {}

    @objc private func displayLinkFired(_ link: CADisplayLink) {
        // dt = wall-clock seconds between the previous frame's target timestamp and the
        // current frame's target timestamp. Per Wave: a single dt broadcast to all animators.
        let dt = link.targetTimestamp - link.timestamp

        // E03: open the suppression window BEFORE any animator's valueChanged fires.
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        for animator in animations.values {
            if animator.state == .ended {
                animator.reset()
                animations.removeValue(forKey: animator.id)
            } else {
                animator.updateAnimation(dt: dt)
            }
        }

        CATransaction.commit()

        if animations.isEmpty {
            displayLink.isPaused = true
        }
    }

    /// Register an animator. The display link starts on first registration; stops when
    /// the animations dictionary empties (per E02 — no point burning vsync callbacks if
    /// nothing's animating).
    func runPropertyAnimation(_ animator: AnimatorProviding) {
        let wasEmpty = animations.isEmpty
        animations[animator.id] = animator

        if wasEmpty {
            displayLink.isPaused = false
        }

        // E14: tick once synchronously at dt=0 so the view paints at its starting value
        // on the same vsync as the start() call. Without this, the view shows its
        // pre-animation state for one frame (~16.7ms on 60Hz, ~8.3ms on 120Hz ProMotion).
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        animator.updateAnimation(dt: 0)
        CATransaction.commit()
    }
}
