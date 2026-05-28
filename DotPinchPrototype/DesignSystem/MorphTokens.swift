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
    static let unifiedArcZMagnitude: CGFloat = 0
    static let viewportCoveragePad: CGFloat = 40
    static let chatRestFactorFallback: CGFloat = 4.92
    static let translateYTarget: CGFloat = -50
    static let chatRestMarginFactor: CGFloat = 1.10
}

enum MorphCurves {
    static let zoomLanding: (Float, Float, Float, Float) = (0.7, 0.0, 0.4, 1.0)
    static let translateLanding: (Float, Float, Float, Float) = (0.0, 0.0, 0.2, 1.0)
    static let labelOpacity: (Float, Float, Float, Float) = (0.85, 0.0, 0.5, 1.0)
}

enum MorphAnimationKey: String {
    case windupScale = "windup.scale"
    case zoomScale = "zoom.scale"
    case windupTranslate = "windup.translate"
    case morphCentering = "morph.centering"
    case centerLabelOpacity = "centerLabel.opacity"
}

enum LabelFadeTiming {
    static let dateLabelDuration: TimeInterval = 0.08
    static let dateLabelDelay: TimeInterval = 0.0

    static let topicSummaryDuration: TimeInterval = 0.17
    static let topicSummaryDelay: TimeInterval = 0.03

    static let todayGlyphDuration: TimeInterval = 0.20
    static let todayGlyphDelay: TimeInterval = 0.08
}
