import Foundation
import CoreGraphics
import QuartzCore

public protocol CurveInterpolatable {
    static func interpolate(from: Self, to: Self, t: CGFloat) -> Self
}

extension CGFloat: CurveInterpolatable {
    public static func interpolate(from: CGFloat, to: CGFloat, t: CGFloat) -> CGFloat {
        from + (to - from) * t
    }
}

@MainActor
public final class CurveAnimator<T: CurveInterpolatable>: AnimatorProviding {

    public struct Curve {
        public let duration: TimeInterval
        public let timingFunction: CAMediaTimingFunction
        public let from: T
        public let to: T

        public init(duration: TimeInterval,
                    timingFunction: CAMediaTimingFunction,
                    from: T,
                    to: T) {
            precondition(duration > 0, "CurveAnimator.Curve.duration must be > 0; got \(duration)")
            self.duration = duration
            self.timingFunction = timingFunction
            self.from = from
            self.to = to
        }
    }

    public let id = UUID()
    public private(set) var state: AnimatorState = .inactive

    private let curve: Curve
    private let onTick: (T) -> Void
    private let onComplete: () -> Void
    private var elapsed: TimeInterval = 0

    private weak var controller: AnimationController?

    public init(controller: AnimationController,
                curve: Curve,
                onTick: @escaping (T) -> Void,
                onComplete: @escaping () -> Void) {
        self.controller = controller
        self.curve = curve
        self.onTick = onTick
        self.onComplete = onComplete
    }

    public func start() {
        elapsed = 0
        state = .running
        controller?.runPropertyAnimation(self)
    }

    public func stop(immediately: Bool = true) {
        if immediately {
            state = .ended
        }
    }

    public func reset() {
        elapsed = 0
        state = .inactive
    }

    public func updateAnimation(dt: TimeInterval) {
        guard state == .running else { return }
        elapsed += dt
        let rawT = curve.duration > 0 ? min(elapsed / curve.duration, 1.0) : 1.0
        let easedT = curve.timingFunction.cubicBezierValue(at: CGFloat(rawT))
        let value = T.interpolate(from: curve.from, to: curve.to, t: easedT)
        onTick(value)
        if rawT >= 1.0 {
            state = .ended
            onComplete()
        }
    }
}

extension CAMediaTimingFunction {

    func cubicBezierValue(at t: CGFloat) -> CGFloat {
        var c1 = [Float](repeating: 0, count: 2)
        var c2 = [Float](repeating: 0, count: 2)
        var p1 = [Float](repeating: 0, count: 2)
        var p2 = [Float](repeating: 0, count: 2)
        getControlPoint(at: 0, values: &p1)
        getControlPoint(at: 1, values: &c1)
        getControlPoint(at: 2, values: &c2)
        getControlPoint(at: 3, values: &p2)

        let cx = CGFloat(3 * c1[0])
        let bx = CGFloat(3 * (c2[0] - c1[0])) - cx
        let ax = 1.0 - cx - bx

        let cy = CGFloat(3 * c1[1])
        let by = CGFloat(3 * (c2[1] - c1[1])) - cy
        let ay = 1.0 - cy - by

        var u = t
        for _ in 0..<8 {
            let x = ((ax * u + bx) * u + cx) * u - t
            let dx = (3 * ax * u + 2 * bx) * u + cx
            if abs(dx) < 1e-6 { break }
            u -= x / dx
            u = max(0, min(1, u))
        }
        return ((ay * u + by) * u + cy) * u
    }
}
