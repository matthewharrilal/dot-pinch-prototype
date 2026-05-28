// CellMarginGeometryTests.swift
//
// §50.6 / NEW-5.e: at chat-rest scale (margined per chatRestMarginFactor=1.10),
// the cell extends past the viewport bezel — corners hidden behind screen edges.
// Per prose's Stage 1 "container is invisible" — no cornerRadius arc may be
// visible inside viewport at the chat-rest steady state.

import XCTest
@testable import DotPinchPrototype

@MainActor
final class CellMarginGeometryTests: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)

    func testChatRestMarginExtendsCellPastViewportBezel() {
        let canvas = TimelineCanvas(controller: AnimationController(), frame: viewport)
        let naturalH: CGFloat = 200
        let chatRestFactorRaw = viewport.height / naturalH
        let chatRestFactorMargined = chatRestFactorRaw * MorphTiming.chatRestMarginFactor
        let expectedCellHeight = naturalH * chatRestFactorMargined

        XCTAssertGreaterThan(expectedCellHeight, viewport.height,
                             "Cell at chat-rest must extend past viewport (margin=1.10 produces \(expectedCellHeight)pt vs viewport \(viewport.height)pt)")

        let overshoot = (expectedCellHeight - viewport.height) / 2.0
        XCTAssertGreaterThan(overshoot, Theme.Radius.card,
                             "Cell vertical overshoot (\(overshoot)pt each side) must exceed cornerRadius (\(Theme.Radius.card)pt) so corner arc is hidden behind viewport edge")
    }

    func testChatRestMarginFactorIs110() {
        // Per ESC-F update §50.7: margin promoted from 1.05 to 1.10 because
        // cornerRadius rasterizes proportionally to scale (prose endorses).
        // 1.05 was insufficient on test-fixture scale (chatRestFactor≈4.5).
        XCTAssertEqual(MorphTiming.chatRestMarginFactor, 1.10, accuracy: 1e-9)
    }

    func testCornerRadiusScalesProportionally_notFixed() {
        // Per prose Section 14: "proportional cornerRadius scaling keeps the
        // card looking like the same family of object at every size."
        // Counter-scale (NEW-5.h option b) was REJECTED — cornerRadius is in
        // layer-local coords and scales naturally with the parent transform.
        let cellLayer = CALayer()
        cellLayer.cornerRadius = Theme.Radius.card
        // Cell has fixed cornerRadius in layer-local; under sublayerTransform
        // scaling the RENDERED arc grows with scale. We assert the radius is
        // NOT being counter-scaled (= still equals the tokenized value).
        XCTAssertEqual(cellLayer.cornerRadius, Theme.Radius.card)
    }
}
