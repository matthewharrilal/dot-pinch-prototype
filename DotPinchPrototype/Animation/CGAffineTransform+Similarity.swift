// Uniform similarity transform — pure 2D scale around a normalized anchor.
// Used by ConversationContentView to scale the chat content toward the
// fixed anchor point without rotation, shear, or perspective (Refusal #1).

import CoreGraphics

extension CGAffineTransform {

    /// Build a uniform similarity transform that scales `bounds` toward the
    /// `anchor` (a unit-square point in [0, 1] × [0, 1]) by `scale`.
    /// Same scalar on both axes; the anchor is the fixed point.
    public static func similarity(
        scale: CGFloat,
        anchor: CGPoint,
        in bounds: CGRect
    ) -> CGAffineTransform {
        let tx = (anchor.x - 0.5) * bounds.width  * (1 - scale)
        let ty = (anchor.y - 0.5) * bounds.height * (1 - scale)
        return CGAffineTransform(translationX: tx, y: ty).scaledBy(x: scale, y: scale)
    }
}
