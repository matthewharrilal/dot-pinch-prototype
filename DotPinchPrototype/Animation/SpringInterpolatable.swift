// Spring-interpolation protocol. Any type that conforms can flow through the
// substrate's spring physics. CGFloat is the live conformance; absolute values
// flow through physics with no progress remapping in the substrate.

import Foundation
import CoreGraphics

public protocol VelocityProviding {
    static var zero: Self { get }
    var isFinite: Bool { get }
}

public protocol SpringInterpolatable: Equatable {
    associatedtype ValueType: SpringInterpolatable where ValueType.ValueType == ValueType
    associatedtype VelocityType: VelocityProviding

    var isFinite: Bool { get }

    /// Integrate one timestep of spring physics. Returns (newValue, newVelocity).
    static func updateValue(
        spring: Spring,
        value: ValueType,
        target: ValueType,
        velocity: VelocityType,
        dt: TimeInterval
    ) -> (value: ValueType, velocity: VelocityType)
}

// MARK: - CGFloat

extension CGFloat: SpringInterpolatable, VelocityProviding {
    public typealias ValueType = CGFloat
    public typealias VelocityType = CGFloat

    /// Forward Euler integration of:
    ///     F = -k·x - c·v        (Hooke's law + damping)
    ///     a = F / m
    ///     v' = v + a·dt
    ///     x' = x + v'·dt
    public static func updateValue(
        spring: Spring,
        value: CGFloat,
        target: CGFloat,
        velocity: CGFloat,
        dt: TimeInterval
    ) -> (value: CGFloat, velocity: CGFloat) {
        precondition(spring.response > 0, "Spring physics requires non-zero response.")

        let displacement = value - target
        let springForce = -spring.stiffness * displacement
        let dampingForce = spring.dampingCoefficient * velocity
        let force = springForce - dampingForce
        let acceleration = force / spring.mass

        let newVelocity = velocity + acceleration * CGFloat(dt)
        let newValue = value + newVelocity * CGFloat(dt)

        return (newValue, newVelocity)
    }
}
