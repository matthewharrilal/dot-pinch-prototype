import CoreGraphics
import Foundation

struct MorphChoreography: Sendable, Equatable {
    let activeCellIndex: Int
    let startCameraY: CGFloat
    let endCameraY: CGFloat
    let startHeight: CGFloat
    let endHeight: CGFloat
    let unifiedArcYMagnitude: CGFloat
    let unifiedArcZMagnitude: CGFloat
    let duration: TimeInterval
    let chatRestFactor: CGFloat

    var centerLabelCounterScale: CGFloat { chatRestFactor == 0 ? 1 : 1.0 / chatRestFactor }
}
