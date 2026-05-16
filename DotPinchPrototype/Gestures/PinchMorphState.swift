// One scalar drives the morph. Derived visual properties are pure functions of it.
// Scalar-only state structurally forbids axis decoupling (Refusal #1).

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

    /// One scalar applied to both axes — the uniform similarity scale.
    public var similarityScale: CGFloat {
        let p = max(0, min(1, progress))
        return PinchTuning.baselineSimilarityS
             - (PinchTuning.baselineSimilarityS - PinchTuning.destinationSimilarityS) * p
    }

    /// Affordance alpha — materializes past the affordance threshold.
    public var affordanceAlpha: CGFloat {
        let p = max(0, min(1, progress))
        let start = PinchTuning.affordanceMaterializesAt
        guard p > start else { return 0 }
        return min(1, (p - start) / (1 - start))
    }

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
