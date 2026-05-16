// Spring-interpolation protocol. Any struct that conforms can flow through the
// substrate's spring physics. Adapted from jtrivedi/Wave.

import Foundation
import CoreGraphics
import QuartzCore

public protocol VelocityProviding {
    static var zero: Self { get }
}

public protocol SpringInterpolatable: Equatable {
    associatedtype ValueType: SpringInterpolatable where ValueType.ValueType == ValueType
    associatedtype VelocityType: VelocityProviding

    /// Integrate one timestep of spring physics. Returns (newValue, newVelocity).
    /// Absolute values flow through physics — no "progress 0→1" remapping in the substrate.
    static func updateValue(
        spring: Spring,
        value: ValueType,
        target: ValueType,
        velocity: VelocityType,
        dt: TimeInterval
    ) -> (value: ValueType, velocity: VelocityType)
}

// MARK: - CGFloat (the base case — the actual Hooke's law lives here)

extension CGFloat: SpringInterpolatable, VelocityProviding {
    public typealias ValueType = CGFloat
    public typealias VelocityType = CGFloat

    /// Forward Euler integration of:
    ///     F = -k·x - c·v        (Hooke's law + damping)
    ///     a = F / m
    ///     v' = v + a·dt
    ///     x' = x + v'·dt
    ///
    /// This is the canonical mass-spring-damper model. Every other SpringInterpolatable
    /// conformance below decomposes to per-component CGFloat updateValue() calls.
    public static func updateValue(
        spring: Spring,
        value: CGFloat,
        target: CGFloat,
        velocity: CGFloat,
        dt: TimeInterval
    ) -> (value: CGFloat, velocity: CGFloat) {
        precondition(spring.response > 0, "Spring physics requires non-zero response. Use mode=.nonAnimated for snap-to-target.")

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

// MARK: - CGPoint, CGSize, CGRect

extension CGPoint: SpringInterpolatable, VelocityProviding {
    public typealias ValueType = CGPoint
    public typealias VelocityType = CGPoint

    public static func updateValue(
        spring: Spring,
        value: CGPoint,
        target: CGPoint,
        velocity: CGPoint,
        dt: TimeInterval
    ) -> (value: CGPoint, velocity: CGPoint) {
        let (x, vx) = CGFloat.updateValue(spring: spring, value: value.x, target: target.x, velocity: velocity.x, dt: dt)
        let (y, vy) = CGFloat.updateValue(spring: spring, value: value.y, target: target.y, velocity: velocity.y, dt: dt)
        return (CGPoint(x: x, y: y), CGPoint(x: vx, y: vy))
    }
}

extension CGSize: SpringInterpolatable, VelocityProviding {
    public typealias ValueType = CGSize
    public typealias VelocityType = CGSize

    // CGSize already conforms `static var zero` from CoreGraphics — no redeclaration needed.

    public static func updateValue(
        spring: Spring,
        value: CGSize,
        target: CGSize,
        velocity: CGSize,
        dt: TimeInterval
    ) -> (value: CGSize, velocity: CGSize) {
        let (w, vw) = CGFloat.updateValue(spring: spring, value: value.width, target: target.width, velocity: velocity.width, dt: dt)
        let (h, vh) = CGFloat.updateValue(spring: spring, value: value.height, target: target.height, velocity: velocity.height, dt: dt)
        return (CGSize(width: w, height: h), CGSize(width: vw, height: vh))
    }
}

extension CGRect: SpringInterpolatable, VelocityProviding {
    public typealias ValueType = CGRect
    public typealias VelocityType = CGRect

    // CGRect already conforms `static var zero` from CoreGraphics — no redeclaration needed.

    public static func updateValue(
        spring: Spring,
        value: CGRect,
        target: CGRect,
        velocity: CGRect,
        dt: TimeInterval
    ) -> (value: CGRect, velocity: CGRect) {
        let (origin, originVelocity) = CGPoint.updateValue(
            spring: spring, value: value.origin, target: target.origin, velocity: velocity.origin, dt: dt
        )
        let (size, sizeVelocity) = CGSize.updateValue(
            spring: spring, value: value.size, target: target.size, velocity: velocity.size, dt: dt
        )
        return (
            CGRect(origin: origin, size: size),
            CGRect(origin: originVelocity, size: sizeVelocity)
        )
    }
}
