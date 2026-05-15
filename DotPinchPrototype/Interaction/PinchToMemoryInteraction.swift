//
//  PinchToMemoryInteraction.swift
//  DotPinchPrototype
//
//  The composition — packaged as a custom UIInteraction adopter so it can be attached
//  to any view via `view.addInteraction(_:)` (conjecture Decision 11).
//
//  This is where all the substrate rules combine:
//
//   • NINETY-pinch-EP2  The gesture is the source of truth, not the animation.
//                       During `.changed`, gesture scale drives state interpolation
//                       directly (no spring physics). Only on `.ended` does the spring
//                       take over with velocity injected.
//
//   • NINETY-pinch-E08  Gesture velocity injection. The pinch's velocity at `.ended` is
//                       mapped to PinchMorphState-space and written directly into the
//                       SpringAnimator's `velocity` property after configure().
//
//   • NINETY-pinch-A03  WWDC 2018 Session 803 velocity normalization formula applied to
//                       compute the per-property initial velocity.
//
//   • NINETY-pinch-E17  Projection-based commit decision: project where momentum carries
//                       progress, commit if projected end > 0.5, else revert.
//
//   • NINETY-pinch-E16  Rubber-band over-pinch with c = 0.55 (Apple-tuned).
//
//  • Conjecture Decision 1 (structural correspondence): the morphing surface is the
//                       conversation view itself; we animate its bounds between the
//                       fullscreen rect and the Today slot rect. No snapshot, no portal.
//
//  • Conjecture Decision 8 (slot-anchored expansion): the anchor is the top-left of the
//                       source slot. UIView's frame-based animation handles this naturally
//                       (the bounds.origin moves; the bounds.size grows from there).
//

import UIKit

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
        if let container = view.superview as? PinchMorphContainerView {
            self.container = container
        }
    }

    // MARK: - Configuration

    /// The fullscreen state — bounds occupies the entire host's view.
    private let fullscreenState: PinchMorphState

    /// The collapsed state — bounds match the Today slot rect.
    private let collapsedState: PinchMorphState

    /// Whether we're currently in the fullscreen (false) or collapsed (true) steady state.
    private var isCollapsed = false

    private weak var container: PinchMorphContainerView?

    // MARK: - Animation substrate (Wave-style)

    /// The single composite-state animator that drives the entire morph as one motion.
    /// Created lazily on the first gesture; lives for the interaction's lifetime; gets
    /// retargeted on each gesture-end.
    private var animator: SpringAnimator<PinchMorphState>?

    // MARK: - Gesture

    private let pinch: UIPinchGestureRecognizer = {
        let g = UIPinchGestureRecognizer()
        return g
    }()

    /// Initial pinch scale at the start of the gesture (captured at .began). All later
    /// scales are relative to this — establishes the gesture's "anchor scale."
    private var anchorScale: CGFloat = 1.0

    /// State at the moment the gesture began. Becomes the "from" for the interactive
    /// interpolation; the target endpoint is the opposite of `isCollapsed`.
    private var gestureStartState: PinchMorphState?

    // MARK: - Init

    init(fullscreen: CGRect, collapsedSlot: CGRect) {
        self.fullscreenState = PinchMorphState(
            bounds: fullscreen,
            cornerRadius: 0,
            chromeOpacity: 1,
            affordanceProgress: 0,
            contentOffsetY: 0
        )
        self.collapsedState = PinchMorphState(
            bounds: collapsedSlot,
            cornerRadius: 16,
            chromeOpacity: 0,
            affordanceProgress: 1,
            contentOffsetY: 0
        )
        super.init()
        pinch.addTarget(self, action: #selector(handlePinch(_:)))
    }

    // MARK: - Gesture handling

    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .began:
            beginInteractive(at: recognizer)

        case .changed:
            updateInteractive(with: recognizer)

        case .ended, .cancelled, .failed:
            endInteractive(with: recognizer)

        default:
            break
        }
    }

    private func beginInteractive(at recognizer: UIPinchGestureRecognizer) {
        // Capture the gesture's starting scale and the current morph state.
        anchorScale = recognizer.scale
        let from = isCollapsed ? collapsedState : fullscreenState
        gestureStartState = from

        // Enable presentation-layer hit-testing (D02) for the duration of the morph.
        container?.routesHitTestThroughPresentationLayer = true

        // If an animator is currently running, stop it cleanly — the gesture now leads.
        animator?.stop(immediately: true)
        animator = nil
    }

    private func updateInteractive(with recognizer: UIPinchGestureRecognizer) {
        guard let from = gestureStartState, let view = view else { return }

        let to = (from == fullscreenState) ? collapsedState : fullscreenState

        // Map pinch scale → progress (0…1, where 0 = at `from`, 1 = at `to`).
        // Pinch-IN (collapse) reduces scale; pinch-OUT (expand) increases it.
        let scale = recognizer.scale / anchorScale
        let rawProgress: CGFloat
        if from == fullscreenState {
            // Pinching IN from fullscreen → collapsed. scale<1 = more progress.
            rawProgress = clamp(1 - scale, -0.2, 1.2)
        } else {
            // Pinching OUT from collapsed → fullscreen. scale>1 = more progress.
            rawProgress = clamp(scale - 1, -0.2, 1.2)
        }

        // Apply rubber-band damping past the 0…1 range.
        let progress = rubberband(value: rawProgress, range: 0...1, interval: 0.2, c: 0.55)

        // Interpolate the composite state. While the finger is down, the morph is
        // gesture-driven (no spring physics) — per NINETY-pinch-EP2.
        let currentState = PinchMorphState.interpolate(from: from, to: to, t: progress)
        applyState(currentState, to: view)
    }

    private func endInteractive(with recognizer: UIPinchGestureRecognizer) {
        guard let from = gestureStartState, let view = view else { return }
        let to = (from == fullscreenState) ? collapsedState : fullscreenState

        // Current state at release — read from the visible state (could be derived from
        // the presentation layer, but since we wrote model state directly during .changed
        // we have authoritative truth here).
        let currentBounds = view.frame
        let currentProgress = progressFromBounds(
            currentBounds, from: from.bounds, to: to.bounds
        )

        // Map pinch velocity (scale units / sec) → progress velocity (progress / sec).
        let pinchVelocity = recognizer.velocity
        let progressVelocityMagnitude = abs(pinchVelocity) / 2.0  // empirical mapping factor
        let progressVelocity: CGFloat
        if from == fullscreenState {
            // For collapse direction, pinching IN faster → faster collapse progress.
            progressVelocity = pinchVelocity < 0 ? progressVelocityMagnitude : -progressVelocityMagnitude
        } else {
            progressVelocity = pinchVelocity > 0 ? progressVelocityMagnitude : -progressVelocityMagnitude
        }

        // E17: project where momentum will carry progress, commit if past 0.5.
        let projectedRest = currentProgress + project(initialVelocity: progressVelocity, decelerationRate: 0.998)
        let shouldCommit = projectedRest > 0.5

        let targetState = shouldCommit ? to : from

        // Construct a composite-state velocity from the progress velocity. Each field's
        // velocity is the progress velocity times the field's displacement (A03 — WWDC
        // 2018 velocity normalization). This is the moment we ship the gesture's energy
        // into the spring (E08).
        let fieldDisplacement = PinchMorphState(
            bounds: CGRect(
                x: targetState.bounds.minX - from.bounds.minX,
                y: targetState.bounds.minY - from.bounds.minY,
                width: targetState.bounds.width - from.bounds.width,
                height: targetState.bounds.height - from.bounds.height
            ),
            cornerRadius: targetState.cornerRadius - from.cornerRadius,
            chromeOpacity: targetState.chromeOpacity - from.chromeOpacity,
            affordanceProgress: targetState.affordanceProgress - from.affordanceProgress
        )
        let velocity = PinchMorphState(
            bounds: CGRect(
                x: fieldDisplacement.bounds.minX * progressVelocity,
                y: fieldDisplacement.bounds.minY * progressVelocity,
                width: fieldDisplacement.bounds.width * progressVelocity,
                height: fieldDisplacement.bounds.height * progressVelocity
            ),
            cornerRadius: fieldDisplacement.cornerRadius * progressVelocity,
            chromeOpacity: fieldDisplacement.chromeOpacity * progressVelocity,
            affordanceProgress: fieldDisplacement.affordanceProgress * progressVelocity
        )

        let currentState = PinchMorphState.interpolate(from: from, to: to, t: currentProgress)

        // Start (or retarget) the spring animator with the current state, the target,
        // and the injected gesture velocity. Wave-style: animation is state; this is
        // the state object the gesture handler hands off to physics.
        let animator = SpringAnimator<PinchMorphState>(
            spring: .defaultUI,
            value: currentState,
            target: targetState
        )
        animator.velocity = velocity                                    // E08
        animator.valueChanged = { [weak self, weak view] state in       // E05
            guard let self, let view else { return }
            self.applyState(state, to: view)
        }
        animator.completion = { [weak self] event in
            if case .finished = event {
                self?.container?.routesHitTestThroughPresentationLayer = false
                self?.isCollapsed = (targetState == self?.collapsedState)
                self?.animator = nil
            }
        }
        self.animator = animator
        animator.start()

        gestureStartState = nil
    }

    // MARK: - Apply state to view

    /// Write a PinchMorphState to the world. Called from BOTH the gesture handler
    /// (during .changed) AND the SpringAnimator's valueChanged closure (during settle).
    /// One write path; one composition.
    private func applyState(_ state: PinchMorphState, to view: UIView) {
        view.frame = state.bounds
        view.layer.cornerRadius = state.cornerRadius
        view.layer.cornerCurve = .continuous

        // Chrome elements live in the demo's view hierarchy — they observe the state
        // via the host's onStateChange hook. The interaction itself is responsible only
        // for the morphing surface's geometry.
        onStateChange?(state)
    }

    /// Hook for the host VC to observe state changes (e.g., to update chrome views,
    /// affordance icons, page gradient position).
    var onStateChange: ((PinchMorphState) -> Void)?

    // MARK: - Helpers

    private func progressFromBounds(_ current: CGRect, from: CGRect, to: CGRect) -> CGFloat {
        let fromHeight = from.height
        let toHeight = to.height
        let span = toHeight - fromHeight
        guard abs(span) > 0.0001 else { return 0 }
        return (current.height - fromHeight) / span
    }
}
