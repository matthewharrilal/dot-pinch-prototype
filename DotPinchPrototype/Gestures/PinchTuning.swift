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
}
