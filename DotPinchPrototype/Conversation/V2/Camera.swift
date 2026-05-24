// Camera — single page-y scalar that maps page-y at `translation` to viewport-y
// at viewport center. No scale, no x-translation. Multiple cells are visible at
// cell-rest because they render at page-coord heights smaller than the viewport,
// not because of any uniform scale.

import CoreGraphics
import Foundation

struct Camera: Equatable {

    /// Page-y coordinate that maps to viewport center. Finite.
    let translation: CGFloat

    init(translation: CGFloat) {
        precondition(translation.isFinite, "Camera.translation must be finite")
        self.translation = translation
    }

    /// Placeholder camera at translation=0, used until layout runs.
    static let identity = Camera(translation: 0)

    /// Epsilon-aware comparison for arithmetic-derived camera values.
    func isApproximatelyEqual(_ other: Camera, tolerance: CGFloat = 1e-9) -> Bool {
        abs(translation - other.translation) <= tolerance
    }
}
