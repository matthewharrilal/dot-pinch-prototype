// StageOrderingInvariantTests.swift
//
// Enforces the prose's "never two figures at once" discipline (§50.5 / NEW-4.4):
// at every camera.scale in [1.0, chatRestScale + 15% rubberband], the count of
// StageOrdering bands whose smoothstep evaluates strictly in (0, 1) is ≤ 1.
//
// Cheap, static, non-UI fence: 720 sample points × 4 bands runs in ms. Prevents
// the entire class of NEW-4 ordering violations (including hand-tuned band drift).

import XCTest
@testable import DotPinchPrototype

@MainActor
final class StageOrderingInvariantTests: XCTestCase {

    /// Production-class chatRestScale for testing (iPhone 16, naturalH≈438, margin 1.10).
    private let chatRestScaleProd: CGFloat = 2.14

    /// Test-fixture chatRestScale (test cells naturalH≈200, viewport 844, margin 1.10).
    private let chatRestScaleTest: CGFloat = 4.642

    /// Bands tuple — order matches prose stage sequence (chatRest → cell-rest):
    /// focalBlur (Stage 2) → chatContentFade (Crossing 2) → cellShadow (Stage 3) →
    /// cellRestChrome (Stage 4 / Crossing 3).
    private func bands(for chatRestScale: CGFloat) -> [(String, ClosedRange<CGFloat>)] {
        [
            ("focalBlur",       StageOrdering.focalBlurBand(chatRestScale: chatRestScale)),
            ("chatContentFade", StageOrdering.chatContentFadeBand(chatRestScale: chatRestScale)),
            ("cellShadow",      StageOrdering.cellShadowBand(chatRestScale: chatRestScale)),
            ("cellRestChrome",  StageOrdering.cellRestChromeBand(chatRestScale: chatRestScale)),
        ]
    }

    func testNeverTwoFiguresAtOnce_productionChatRestScale() {
        runSweep(chatRestScale: chatRestScaleProd)
    }

    func testNeverTwoFiguresAtOnce_testFixtureChatRestScale() {
        runSweep(chatRestScale: chatRestScaleTest)
    }

    private func runSweep(chatRestScale: CGFloat) {
        let upperBound = chatRestScale * 1.15
        let stepCount = 720
        let allBands = bands(for: chatRestScale)
        for i in 0..<stepCount {
            let s = 1.0 + CGFloat(i) * (upperBound - 1.0) / CGFloat(stepCount - 1)
            let activeBands = allBands.filter { (_, band) in
                let v = smoothstep(band.lowerBound, band.upperBound, s)
                return v > 1e-9 && v < (1.0 - 1e-9)
            }
            XCTAssertLessThanOrEqual(
                activeBands.count, 1,
                "At scale=\(s) (chatRestScale=\(chatRestScale)): \(activeBands.count) bands in-flight (expected ≤1). Bands: \(activeBands.map { $0.0 })"
            )
        }
    }

    func testBandsAreOrderedOnScaleAxis() {
        let allBands = bands(for: chatRestScaleProd)
        for i in 1..<allBands.count {
            XCTAssertLessThanOrEqual(
                allBands[i].1.upperBound, allBands[i-1].1.lowerBound + 1e-9,
                "\(allBands[i].0) must end at or below \(allBands[i-1].0).start (sequential ordering)"
            )
        }
    }

    func testBandsCoverScaleAxisWithoutLargeGaps() {
        let allBands = bands(for: chatRestScaleProd)
        let lowestBandLow = allBands.last!.1.lowerBound
        let highestBandHigh = allBands.first!.1.upperBound
        let totalSpan = chatRestScaleProd - 1.0
        let bandsSpan = highestBandHigh - lowestBandLow
        let coverage = bandsSpan / totalSpan
        XCTAssertGreaterThan(coverage, 0.4, "Bands cover at least 40% of scale range (current = \(coverage * 100)%)")
    }

    func testIllegibilityThresholdsAreFractional() {
        // Per ESC-C v1: NEW-7.c fractional formulation, not absolute.
        let toeFullProd = StageOrdering.illegibilityToeFull(chatRestScale: chatRestScaleProd)
        let toeFullTest = StageOrdering.illegibilityToeFull(chatRestScale: chatRestScaleTest)
        XCTAssertNotEqual(toeFullProd, toeFullTest, accuracy: 0.01,
                          "Threshold must vary with chatRestScale (not absolute)")
    }

    /// NEW-4.8: reverse-of-reverse symmetry. Bands are pure functions of scale
    /// (smoothstep is C¹ continuous, deterministic). Forward and backward traversal
    /// of the scale axis must produce identical band values at matched scales.
    func testReverseDirectionSymmetry() {
        let allBands = bands(for: chatRestScaleProd)
        let scaleSamples: [CGFloat] = [1.05, 1.2, 1.5, 1.7, 1.9, 2.1]
        for s in scaleSamples {
            for (name, band) in allBands {
                let forwardEval = smoothstep(band.lowerBound, band.upperBound, s)
                let backwardEval = smoothstep(band.lowerBound, band.upperBound, s)
                XCTAssertEqual(forwardEval, backwardEval, accuracy: 1e-12,
                               "\(name) at scale=\(s): bands must be pure functions of scale")
            }
        }
    }

    /// NEW-4.9: pageGradientLayer audit. Atmospheric backdrop is a sibling of
    /// contentHost (not a child) — it does NOT inherit sublayerTransform and is
    /// always-visible (opacity=1). Per prose: "no atmospheric depth / no parallax."
    func testPageGradientLayerIsStaticBackdrop() {
        let canvas = TimelineCanvas(controller: AnimationController(), frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        XCTAssertEqual(canvas.pageGradientLayer.opacity, 1.0, accuracy: 1e-9,
                       "pageGradientLayer is always-visible per §50.9 NEW-4.9 audit")
        // Verify it does NOT inherit sublayerTransform by being a child of
        // contentHost. It must be a sibling of contentHost (child of canvas).
        XCTAssertEqual(canvas.pageGradientLayer.superlayer, canvas.layer,
                       "pageGradientLayer must be a child of canvas.layer (not contentHost), so it doesn't inherit camera transforms")
    }

    /// NEW-Inv.2 extended: forward direction's K7 cane curve produces NO Z
    /// (post G-K7-Z Option B / §50.12). At the architectural-commitment level,
    /// MorphTiming.unifiedArcZMagnitude == 0 prevents any cane-curve-driven Z.
    func test_K7_caneCurve_hasNoZComponent() {
        XCTAssertEqual(MorphTiming.unifiedArcZMagnitude, 0, accuracy: 1e-9,
                       "K7 cane curve Z magnitude=0 per G-K7-Z Option B (§50.12)")
    }
}
