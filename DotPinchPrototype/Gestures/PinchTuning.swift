// Gesture-physics constants for the pinch-to-memory mechanic. Describes HOW
// gesture progress maps to spring physics — visual-timing lives in
// Conversation/MorphTiming.swift.

import CoreGraphics
import Foundation

enum PinchTuning {

    // MARK: - Spring physics

    static let springResponse: CGFloat = 1.10

    /// Fallback damping for non-gesture-driven engagements only (e.g. programmatic
    /// `animateCameraToCellRest()` with no originating gesture). Gesture paths
    /// select among the per-direction profiles below.
    static let springDamping: CGFloat = 0.85

    // MARK: - Per-direction spring profiles (D2 §5.2)

    /// §7.15 tap-to-chat damping — underdamped, ~10% arrival overshoot.
    static var tapToChatDamping: CGFloat = 0.62

    /// §7.16 pinch-to-cells damping — critically damped, monotonic settle.
    static var pinchToCellsDamping: CGFloat = 1.0

    /// §7.17 cancelled damping — gesture returns to its originating rest.
    static var cancelledDamping: CGFloat = 0.95

    // MARK: - Anticipation (D2 §7.24 + §10.78)

    /// §7.24 anticipation magnitude. Bound: [0.95, 0.99]. Read once at
    /// animator construction — changes don't apply to in-flight anticipation.
    private static var _anticipationMagnitude: CGFloat = 0.97
    static var anticipationMagnitude: CGFloat {
        get { _anticipationMagnitude }
        set {
            precondition(
                newValue >= 0.95 && newValue <= 0.99,
                "§7.24: anticipationMagnitude must be in [0.95, 0.99]; got \(newValue)"
            )
            _anticipationMagnitude = newValue
        }
    }

    /// §10.78 anticipation duration in seconds. Bound: [0.05, 0.10]. Read once
    /// at animator construction.
    private static var _anticipationDuration: TimeInterval = 0.08
    static var anticipationDuration: TimeInterval {
        get { _anticipationDuration }
        set {
            precondition(
                newValue >= 0.05 && newValue <= 0.10,
                "§10.78: anticipationDuration must be in [0.05, 0.10]; got \(newValue)"
            )
            _anticipationDuration = newValue
        }
    }

    /// Phase 5 A/B testing flag (§7.8.4 + §10.76). When true, tap-to-chat skips
    /// anticipation (Π''' fallback). Ships `false`. Read at engagement only.
    static var anticipationDisabled: Bool = false
}
