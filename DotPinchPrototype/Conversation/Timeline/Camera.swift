import CoreGraphics
import Foundation

struct Camera: Equatable {

    let translation: CGFloat
    let scale: CGFloat

    init(translation: CGFloat, scale: CGFloat = 1) {
        precondition(translation.isFinite, "Camera.translation must be finite")
        precondition(scale.isFinite && scale > 0, "Camera.scale must be finite and > 0")
        self.translation = translation
        self.scale = scale
    }

    static let identity = Camera(translation: 0, scale: 1)

    func isApproximatelyEqual(_ other: Camera, tolerance: CGFloat = 1e-9) -> Bool {
        abs(translation - other.translation) <= tolerance
            && abs(scale - other.scale) <= tolerance
    }

    var translationPageY: PageY { PageY(translation) }

    /// Scale-aware page→viewport mapping. With pivot at viewport-center
    /// (per K14 / HANDOFF §47.8): viewport_y = (page_y − cam.translation) × scale + vpC.
    /// At scale=1.0 reduces to the legacy translation-only form (K1 backwards-compat).
    func pagePoint(fromViewport viewportY: ViewportY, viewportCenter: ViewportY) -> PageY {
        PageY((viewportY.raw - viewportCenter.raw) / scale + translation)
    }

    func viewportPoint(fromPage pageY: PageY, viewportCenter: ViewportY) -> ViewportY {
        ViewportY((pageY.raw - translation) * scale + viewportCenter.raw)
    }
}
