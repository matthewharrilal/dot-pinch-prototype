import CoreGraphics

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
