// PinchTuning — gesture-physics constants (spring damping, response,
// per-direction damping). For MORPH visual-timing constants (windup,
// curves, lift magnitudes), see MorphTiming (added in Phase 1 Task 1.2)
// — distinct file because morph-timing is choreography, not gesture-physics.

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
}
