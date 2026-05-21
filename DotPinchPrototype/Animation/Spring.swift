// Spring parameters. Adapted from jtrivedi/Wave.

import Foundation
import CoreGraphics

public struct Spring: Equatable {

    /// Damping ratio: 1.0 = critically damped, <1.0 = underdamped, >1.0 = overdamped.
    public var dampingRatio: CGFloat

    /// Frequency response — settle time (sec) from a unit displacement at rest.
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

    /// Damping coefficient c = 2ζ·sqrt(k·m).
    public var dampingCoefficient: CGFloat {
        2 * dampingRatio * sqrt(stiffness * mass)
    }

    /// Closed-form settling time. Underdamped envelope decays as exp(-ζ·ωn·t);
    /// solve for t where envelope < settlingPercentage.
    public var settlingDuration: TimeInterval {
        guard response > 0 else { return 0 }
        let omegaN = sqrt(stiffness / mass)
        let zeta = dampingRatio

        if zeta < 1.0 {
            let t = -log(Self.settlingPercentage) / (zeta * omegaN)
            return TimeInterval(t)
        } else {
            let criticallyDampedSettlingTime = -log(Self.settlingPercentage) / omegaN
            return TimeInterval(criticallyDampedSettlingTime * Self.overdampedMultiplier)
        }
    }

    private static let settlingPercentage: CGFloat = 0.0001
    private static let overdampedMultiplier: CGFloat = 1.25
}
