// The gesture's integrated state — just a scalar. Spring-interpolable so it can
// flow through SpringAnimator<PinchMorphState>. Derived visual tokens are not
// computed here; see Conversation/ConversationMorphTokens.swift for the
// pure-function projection that drives the view layer.

import Foundation
import CoreGraphics

public struct PinchMorphState: SpringInterpolatable, VelocityProviding, Equatable {
    public typealias ValueType = PinchMorphState
    public typealias VelocityType = PinchMorphState

    /// progress ∈ [0, 1] (rubberband-extended to [-0.2, 1.2]).
    /// 0 = baseline (fullscreen). 1 = settled (destination).
    public var progress: CGFloat

    public init(progress: CGFloat = 0) { self.progress = progress }
    public static var zero: PinchMorphState { PinchMorphState(progress: 0) }

    public static func updateValue(
        spring: Spring,
        value: PinchMorphState,
        target: PinchMorphState,
        velocity: PinchMorphState,
        dt: TimeInterval
    ) -> (value: PinchMorphState, velocity: PinchMorphState) {
        let (newProgress, newVelocity) = CGFloat.updateValue(
            spring: spring,
            value: value.progress,
            target: target.progress,
            velocity: velocity.progress,
            dt: dt
        )
        return (PinchMorphState(progress: newProgress), PinchMorphState(progress: newVelocity))
    }
}
