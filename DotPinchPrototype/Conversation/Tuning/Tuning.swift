import CoreGraphics
import Foundation

struct PhysicsTuning: Sendable, Equatable {

    let springDamping: CGFloat
    let springResponse: CGFloat

    let tapToChatDamping: CGFloat
    let pinchToCellsDamping: CGFloat
    let cancelledDamping: CGFloat

    init(
        springDamping: CGFloat = 0.85,
        springResponse: CGFloat = 1.10,
        tapToChatDamping: CGFloat = 0.62,
        pinchToCellsDamping: CGFloat = 1.0,
        cancelledDamping: CGFloat = 0.95
    ) {
        precondition(springDamping >= 0.5 && springDamping <= 1.5,
                     "springDamping out of bounds: \(springDamping)")
        precondition(springResponse >= 0.1 && springResponse <= 2.0,
                     "springResponse out of bounds: \(springResponse)")
        self.springDamping = springDamping
        self.springResponse = springResponse
        self.tapToChatDamping = tapToChatDamping
        self.pinchToCellsDamping = pinchToCellsDamping
        self.cancelledDamping = cancelledDamping
    }

    static let standard = PhysicsTuning()

    var springDampingRatio: DampingRatio { DampingRatio(springDamping) }
    var tapToChatDampingRatio: DampingRatio { DampingRatio(tapToChatDamping) }
    var pinchToCellsDampingRatio: DampingRatio { DampingRatio(pinchToCellsDamping) }
    var cancelledDampingRatio: DampingRatio { DampingRatio(cancelledDamping) }
}

enum CellLayoutTuning {
    static let naturalCellHeight: CGFloat = 200
}
