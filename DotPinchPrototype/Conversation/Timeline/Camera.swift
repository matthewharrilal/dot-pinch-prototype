import CoreGraphics
import Foundation

struct Camera: Equatable {

    let translation: CGFloat

    init(translation: CGFloat) {
        precondition(translation.isFinite, "Camera.translation must be finite")
        self.translation = translation
    }

    static let identity = Camera(translation: 0)

    func isApproximatelyEqual(_ other: Camera, tolerance: CGFloat = 1e-9) -> Bool {
        abs(translation - other.translation) <= tolerance
    }

    var translationPageY: PageY { PageY(translation) }

    func pagePoint(fromViewport viewportY: ViewportY, viewportCenter: ViewportY) -> PageY {
        PageY(viewportY.raw - viewportCenter.raw + translation)
    }

    func viewportPoint(fromPage pageY: PageY, viewportCenter: ViewportY) -> ViewportY {
        ViewportY(pageY.raw - translation + viewportCenter.raw)
    }
}
