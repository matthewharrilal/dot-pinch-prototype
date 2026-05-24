import CoreGraphics
import Foundation
import QuartzCore

struct PinchState {
    var initialScale: CGFloat = 1.0
    var initialExtension: CGFloat = 0
    var anchorPageY: CGFloat = 0
    var previousCentroidY: CGFloat = 0
    var previousCentroidTimestamp: CFTimeInterval = 0

    mutating func reset() {
        self = PinchState()
    }
}
