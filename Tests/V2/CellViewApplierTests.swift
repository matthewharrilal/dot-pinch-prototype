// CellViewApplierTests.swift
//
// Unit tests for the scale-driven appliers landed in §50.15:
//   NEW-1.g — blur fraction curve (bump-shaped, peaks mid-fade)
//   NEW-2.l — shadow opacity gating (narrow band near cell-rest)
//   NEW-6.e — labelStack alpha (smoothstep over labelAppearScale band)
//
// All tests use synthetic camera writes + currentScale-equivalent derivation
// via StageOrdering bands. They verify the prose's "never two figures at once"
// at the per-applier level: endpoints exact, mid-curve smoothness, fade direction.

import XCTest
@testable import DotPinchPrototype

@MainActor
final class CellViewApplierTests: XCTestCase {

    private let chatRestScale: CGFloat = 2.2

    // MARK: - NEW-1.g blur fraction bump curve

    func testIllegibilityBlurFractionPeaksMid_zeroAtEndpoints() {
        let band = StageOrdering.focalBlurBand(chatRestScale: chatRestScale)
        let mid = (band.lowerBound + band.upperBound) / 2

        let atLowerEnd = bumpAt(scale: band.lowerBound, band: band)
        let atUpperEnd = bumpAt(scale: band.upperBound, band: band)
        let atMid = bumpAt(scale: mid, band: band)

        XCTAssertEqual(atLowerEnd, 0, accuracy: 1e-9, "blur=0 at band lower end")
        XCTAssertEqual(atUpperEnd, 0, accuracy: 1e-9, "blur=0 at band upper end")
        XCTAssertEqual(atMid, 1.0, accuracy: 0.01, "blur peaks ≈1 at band midpoint")
    }

    func testIllegibilityBlurFractionZeroAtChatRestAndCellRest() {
        // Stage 1 (chat-rest): chatContent fully legible, blur OFF.
        let atChatRest = bumpAt(scale: chatRestScale, band: StageOrdering.focalBlurBand(chatRestScale: chatRestScale))
        XCTAssertLessThan(atChatRest, 0.01, "blur fraction ≈ 0 at chat-rest scale (text still legible)")

        // Stage 4 (cell-rest): chatContent gone, blur OFF.
        let atCellRest = bumpAt(scale: 1.0, band: StageOrdering.focalBlurBand(chatRestScale: chatRestScale))
        XCTAssertLessThan(atCellRest, 0.01, "blur fraction ≈ 0 at cell-rest scale (chatContent already faded)")
    }

    private func bumpAt(scale: CGFloat, band: ClosedRange<CGFloat>) -> CGFloat {
        let mid = (band.lowerBound + band.upperBound) / 2
        let rising = smoothstep(band.lowerBound, mid, scale)
        let falling = 1 - smoothstep(mid, band.upperBound, scale)
        return rising * falling
    }

    // MARK: - NEW-2.l shadow opacity gating

    func testShadowOpacityFullAtCellRest() {
        let band = StageOrdering.cellShadowBand(chatRestScale: chatRestScale)
        let alpha = 1 - smoothstep(band.lowerBound, band.upperBound, 1.0)
        XCTAssertEqual(alpha, 1.0, accuracy: 1e-9, "shadow alpha=1 at scale=1.0 (cell-rest)")
    }

    func testShadowOpacityZeroAtChatRest() {
        let band = StageOrdering.cellShadowBand(chatRestScale: chatRestScale)
        let alpha = 1 - smoothstep(band.lowerBound, band.upperBound, chatRestScale)
        XCTAssertEqual(alpha, 0.0, accuracy: 1e-9, "shadow alpha=0 at chat-rest")
    }

    func testShadowOpacityBandIsNarrow() {
        // Prose: "binary state ... announces type, not depth." Narrow band
        // means shadow APPEARS rather than GROWS — discrete percept.
        let band = StageOrdering.cellShadowBand(chatRestScale: chatRestScale)
        let bandWidth = band.upperBound - band.lowerBound
        let totalSpan = chatRestScale - 1.0
        let fraction = bandWidth / totalSpan
        XCTAssertLessThan(fraction, 0.30, "shadow band must occupy < 30% of scale axis (current=\(fraction * 100)%)")
    }

    // MARK: - NEW-6.e labelStack alpha

    func testLabelStackAlphaFullAtCellRest() {
        let band = StageOrdering.cellRestChromeBand(chatRestScale: chatRestScale)
        let alpha = 1 - smoothstep(band.lowerBound, band.upperBound, 1.0)
        XCTAssertEqual(alpha, 1.0, accuracy: 1e-9, "labelStack alpha=1 at cell-rest")
    }

    func testLabelStackAlphaZeroAtChatRest() {
        let band = StageOrdering.cellRestChromeBand(chatRestScale: chatRestScale)
        let alpha = 1 - smoothstep(band.lowerBound, band.upperBound, chatRestScale)
        XCTAssertEqual(alpha, 0.0, accuracy: 1e-9, "labelStack alpha=0 at chat-rest")
    }

    func testLabelStackCrossesAlpha50AtBandMidpoint() {
        let band = StageOrdering.cellRestChromeBand(chatRestScale: chatRestScale)
        let mid = (band.lowerBound + band.upperBound) / 2
        let alpha = 1 - smoothstep(band.lowerBound, band.upperBound, mid)
        XCTAssertEqual(alpha, 0.5, accuracy: 0.01, "labelStack crosses alpha=0.5 at band midpoint (= scale \(mid))")
    }

    // MARK: - Cross-applier: order verification

    func testLabelAppearsAfterShadow_inScaleAxis_decreasing() {
        // Prose Stage 3 → Stage 4: shadow appears BEFORE labelStack
        // (in scale-decreasing direction during reverse pinch).
        let shadowBand = StageOrdering.cellShadowBand(chatRestScale: chatRestScale)
        let labelBand = StageOrdering.cellRestChromeBand(chatRestScale: chatRestScale)
        // labelBand's upper end must be ≤ shadowBand's lower end (labels appear AFTER
        // shadow in the scale-decreasing direction).
        XCTAssertLessThanOrEqual(labelBand.upperBound, shadowBand.lowerBound + 1e-9,
                                 "labelBand upper (\(labelBand.upperBound)) must be ≤ shadowBand lower (\(shadowBand.lowerBound)) — labels arrive after shadow per prose Stage 3 → Stage 4")
    }
}
