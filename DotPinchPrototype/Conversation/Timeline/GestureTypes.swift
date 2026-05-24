import CoreGraphics
import Foundation
import QuartzCore

enum GestureCommit: Sendable {
    case tapToChat
    case pinchToCells
    case cancelled

    func dampingRatio(from tuning: PhysicsTuning) -> CGFloat {
        switch self {
        case .tapToChat:    return tuning.tapToChatDamping
        case .pinchToCells: return tuning.pinchToCellsDamping
        case .cancelled:    return tuning.cancelledDamping
        }
    }
}

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
