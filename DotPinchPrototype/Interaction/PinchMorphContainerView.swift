//
//  PinchMorphContainerView.swift
//  DotPinchPrototype
//
//  The UIView subclass that hosts the morphing surface. Its sole architectural
//  responsibility is presentation-layer hit-testing during the morph.
//
//   • NINETY-pinch-D02  Hit-test reflects destination during continuous gestures.
//                       The user must be able to interact with the destination's visual
//                       position mid-gesture, not the model position. Override
//                       hitTest(_:with:) to consult presentationLayer for the touch.
//
//   • NINETY-pinch-CARTO-pinch-39  Direct CAAnimation on presentationLayer via
//                       setValue(_:forKeyPath:) for hit-testing routing. Public API;
//                       sparsely documented; folklore-canonical pattern.
//

import UIKit

final class PinchMorphContainerView: UIView {

    /// When `true`, hitTest consults the presentation layer for live frame data.
    /// Set to true during an active morph; false in the steady state to avoid
    /// the per-touch presentation-layer query overhead.
    var routesHitTestThroughPresentationLayer = false

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard routesHitTestThroughPresentationLayer else {
            return super.hitTest(point, with: event)
        }

        // Walk subviews in reverse Z-order (top to bottom). For each, consult its
        // presentation layer's frame — the layer's current visual position, not
        // the model's frame. The touch lands on whichever subview's *visible*
        // position contains the point.
        for subview in subviews.reversed() {
            let presentationFrame = subview.layer.presentation()?.frame ?? subview.frame
            if presentationFrame.contains(point) {
                let localPoint = layer.convert(point, to: subview.layer)
                return subview.hitTest(localPoint, with: event)
            }
        }

        return super.hitTest(point, with: event)
    }
}
