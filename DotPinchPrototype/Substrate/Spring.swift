//
//  Spring.swift
//  DotPinchPrototype
//
//  Spring parameters struct. Adapted from Wave (jtrivedi/Wave) with citations to the
//  /lens-check report at github.com/matthewharrilal/ios-animation-frontier/tree/main/dot-pinch-lens-check.
//

import Foundation
import CoreGraphics

public struct Spring: Equatable {

    /// Damping ratio: 1.0 = critically damped (no overshoot), <1.0 = underdamped (overshoot + ring),
    /// >1.0 = overdamped (slow asymptotic settle).
    ///
    /// NINETY-pinch-D06: Apple's stock UI springs cluster around 0.7–0.85.
    /// Per the trajectory verdict, today_card primary morph axis ~0.85+ (settled monotonic),
    /// gradient ~0.6–0.7 (visible overshoot). Different springs per property is canonical.
    public var dampingRatio: CGFloat

    /// Frequency response. Roughly the time (in seconds) the spring takes to settle to its target
    /// from a unit displacement with no velocity. Smaller = faster + snappier.
    ///
    /// Trajectory verdict observed ~1.17s active-phase response on IN expansion (gesture-active),
    /// ~0.83s settle on release. For canned spring targets: 0.3–0.4s per Apple stock.
    public var response: CGFloat

    /// Mass. Default 1.0 — changes the dynamics' time constants but is usually kept at 1
    /// and the feel is tuned via stiffness/damping. Wave keeps mass=1; we follow.
    public var mass: CGFloat = 1.0

    public init(dampingRatio: CGFloat, response: CGFloat, mass: CGFloat = 1.0) {
        self.dampingRatio = dampingRatio
        self.response = response
        self.mass = mass
    }

    // MARK: - Derived physics quantities

    /// ωn — undamped natural angular frequency. ωn = 2π / response.
    public var stiffness: CGFloat {
        let omegaN = 2 * .pi / max(response, 0.0001)
        return mass * omegaN * omegaN
    }

    /// Damping coefficient c = 2ζ·sqrt(k·m) where ζ is the damping ratio,
    /// k is stiffness, m is mass.
    public var dampingCoefficient: CGFloat {
        2 * dampingRatio * sqrt(stiffness * mass)
    }

    /// Closed-form settling time. For underdamped springs, the envelope decays as
    /// exp(-ζ · ωn · t); solve for t where envelope < `DefaultSettlingPercentage`.
    ///
    /// NINETY-pinch-E11: completion is a property of the system's energy, not of a
    /// single sample's position. Use settling time, not position threshold.
    public var settlingDuration: TimeInterval {
        guard response > 0 else { return 0 }
        let omegaN = sqrt(stiffness / mass)
        let zeta = dampingRatio

        let settlingPercentage: CGFloat = 0.0001

        if zeta < 1.0 {
            // Underdamped: amplitude envelope is exp(-zeta * omegaN * t)
            let t = -log(settlingPercentage) / (zeta * omegaN)
            return TimeInterval(t)
        } else {
            // Critically damped / overdamped: hand-tuned constant from observation.
            // Wave uses criticallyDampedSettlingTime * 1.25 — we follow.
            let criticallyDampedSettlingTime = -log(settlingPercentage) / omegaN
            return TimeInterval(criticallyDampedSettlingTime * 1.25)
        }
    }

}
