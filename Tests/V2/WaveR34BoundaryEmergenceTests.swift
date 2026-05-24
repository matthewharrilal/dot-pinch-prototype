// WaveR34BoundaryEmergenceTests.swift
//
// Boundary corner visibility emerges from geometry, not animation:
// rounded corners are visible iff cell.bounds.height < contentHost.bounds.height.
// At chat-rest they coincide with viewport edges (invisible). In overshoot,
// contentHost.clipsToBounds clips them.

import XCTest
@testable import DotPinchPrototype

@MainActor
final class WaveR34BoundaryEmergenceTests: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)
    private let cellHeight: CGFloat = 200

    private var retainedDataSource: R34Stub?

    private func makeCanvas() -> TimelineCanvas {
        let canvas = TimelineCanvas(controller: AnimationController(), frame: viewport)
        let ds = R34Stub(count: 5, cellHeight: cellHeight)
        retainedDataSource = ds
        canvas.dataSource = ds
        canvas.reloadData()
        canvas.layoutIfNeeded()
        canvas.contentHost.layoutIfNeeded()
        return canvas
    }

    /// Historical no-op (anticipation animator removed per Task 0.2).
    private func drainAnticipation(_ canvas: TimelineCanvas) {
        _ = canvas
    }

    func testBoundaryEmergenceAtFourExtensionFactors() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 2)
        drainAnticipation(canvas)
        canvas.cameraAnimator.stop(immediately: true)
        canvas.extensionAnimator.stop(immediately: true)
        guard let cell = canvas.instantiatedCells[2],
              let heightC = cell.heightConstraint else { XCTFail(); return }

        let naturalH = cell.naturalHeight
        let contentHostH = canvas.contentHost.bounds.height
        let chatRestFactor = contentHostH / naturalH
        XCTAssertGreaterThan(cell.layer.cornerRadius, 0,
                             "precondition: cornerRadius set at init")

        // F=1.0 (cell-rest) — corners visible.
        heightC.constant = naturalH
        canvas.contentHost.setNeedsLayout()
        canvas.contentHost.layoutIfNeeded()
        XCTAssertLessThan(cell.bounds.height, contentHostH,
                          "F=1.0: cell.bounds.height < contentHost.bounds.height (corners visible)")

        // F=1.5 — still < contentHost.
        heightC.constant = naturalH * 1.5
        canvas.contentHost.setNeedsLayout()
        canvas.contentHost.layoutIfNeeded()
        XCTAssertLessThan(cell.bounds.height, contentHostH,
                          "F=1.5: still < contentHost (corners visible)")

        // chat-rest — corners coincide with viewport edges → invisible.
        heightC.constant = naturalH * chatRestFactor
        canvas.contentHost.setNeedsLayout()
        canvas.contentHost.layoutIfNeeded()
        XCTAssertEqual(cell.bounds.height, contentHostH, accuracy: 2.0,
                       "chat-rest: cell.bounds.height ≈ contentHost.bounds.height; corners at viewport edges (invisible)")

        // Overshoot — cell exceeds contentHost; clipsToBounds clips corners.
        heightC.constant = naturalH * chatRestFactor * 1.05
        canvas.contentHost.setNeedsLayout()
        canvas.contentHost.layoutIfNeeded()
        XCTAssertGreaterThan(cell.bounds.height, contentHostH,
                             "overshoot: cell.bounds.height > contentHost.bounds.height (corners clipped)")
        XCTAssertTrue(canvas.contentHost.clipsToBounds,
                      "contentHost.clipsToBounds must be true so overshoot corners are clipped")
    }
}

@MainActor
private final class R34Stub: @preconcurrency TimelineDataSource {
    let count: Int
    let cellHeight: CGFloat
    init(count: Int, cellHeight: CGFloat) {
        self.count = count
        self.cellHeight = cellHeight
    }
    func numberOfCells(in canvas: TimelineCanvas) -> Int { count }
    func canvas(_ canvas: TimelineCanvas, configureCell cell: CellView, at index: Int) {}
    func canvas(_ canvas: TimelineCanvas, heightForCellAt index: Int) -> CGFloat { cellHeight }
}
