import CoreGraphics
import Foundation

enum MorphTiming {
    static let windupDuration: CFTimeInterval = 0.78
    static let totalMorphDuration: CFTimeInterval = 1.5
    static let masterTimerDuration: TimeInterval = 1.2
    static let revealReadyDelay: TimeInterval = 0.1

    static let windupContribution: CGFloat = 0.08
    static let liftEndMagnitude: CGFloat = 50
    static let unifiedArcYMagnitude: CGFloat = 50
    static let unifiedArcZMagnitude: CGFloat = 700
    static let viewportCoveragePad: CGFloat = 40
    static let chatRestFactorFallback: CGFloat = 4.92
    static let translateYTarget: CGFloat = -50
}
