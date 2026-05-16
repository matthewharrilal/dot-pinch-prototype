// Spring parameters. Adapted from jtrivedi/Wave.

import Foundation
import CoreGraphics

public struct Spring: Equatable {

    /// Damping ratio: 1.0 = critically damped (no overshoot), <1.0 = underdamped
    /// (overshoot + ring), >1.0 = overdamped (slow asymptotic settle). Apple's
    /// stock UI springs cluster around 0.7–0.85.
    public var dampingRatio: CGFloat

    /// Frequency response — roughly the time (in seconds) the spring takes to
    /// settle from a unit displacement with no velocity. Smaller = snappier.
    public var response: CGFloat

    /// Mass. Kept at 1.0; tune feel via dampingRatio + response.
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

    /// Closed-form settling time. For underdamped springs the envelope decays
    /// as exp(-ζ·ωn·t); solve for t where envelope < settlingPercentage.
    /// Completion is the system's energy reaching zero, not a position threshold.
    public var settlingDuration: TimeInterval {
        guard response > 0 else { return 0 }
        let omegaN = sqrt(stiffness / mass)
        let zeta = dampingRatio

        let settlingPercentage: CGFloat = 0.0001

        if zeta < 1.0 {
            let t = -log(settlingPercentage) / (zeta * omegaN)
            return TimeInterval(t)
        } else {
            // Critically/overdamped multiplier matches Wave's empirically-tuned value.
            let criticallyDampedSettlingTime = -log(settlingPercentage) / omegaN
            return TimeInterval(criticallyDampedSettlingTime * 1.25)
        }
    }
}
