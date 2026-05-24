// Wave4aActiveCellIndexTests.swift
//
// Verifies activeCellIndex sets on chat-rest gateway and clears on
// cell-rest after both springs settle. Drives the gateway via tap-to-chat
// API since UIPinchGestureRecognizer isn't injectable in unit tests.

import XCTest
@testable import DotPinchPrototype

@MainActor
final class Wave4aActiveCellIndexTests: XCTestCase {

    func testActiveCellIndexSetByChatRestAndClearedByCellRest() {
        let canvas = TimelineCanvas(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let dataSource = StubDataSource(count: 5, cellHeight: 200)
        canvas.dataSource = dataSource
        canvas.reloadData()
        canvas.layoutIfNeeded()

        // Initial state: no active cell.
        XCTAssertNil(canvas.activeCellIndex,
                     "activeCellIndex should be nil at canvas init / cell-rest")

        // Drive the chat-rest path for cell 2.
        canvas.animateCameraToChatRest(forCellAt: 2)
        XCTAssertEqual(canvas.activeCellIndex, 2,
                       "animateCameraToChatRest(forCellAt: 2) should set activeCellIndex = 2")

        // Clear is deferred until BOTH springs settle (tryClearActiveCellAtRest
        // checks cameraAtTarget && extensionAtTarget). Spin run loop.
        canvas.animateCameraToCellRest()
        let deadline = Date().addingTimeInterval(3.0)
        while Date() < deadline {
            if canvas.activeCellIndex == nil { break }
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        XCTAssertNil(canvas.activeCellIndex,
                     "animateCameraToCellRest should clear activeCellIndex after springs settle")
    }
}

@MainActor
private final class StubDataSource: TimelineDataSource {
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
