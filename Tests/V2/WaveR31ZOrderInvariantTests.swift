// WaveR31ZOrderInvariantTests.swift
//
// Active cell z-order invariant across the full gesture lifecycle:
// during continuous gesture, mid-gesture displacement (updateVisibleCells
// trailing re-assert), and restoration to natural sibling order at cell-rest.

import XCTest
@testable import DotPinchPrototype

@MainActor
final class WaveR31ZOrderInvariantTests: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)
    private let cellHeight: CGFloat = 200

    private var retainedDataSource: R31Stub?

    private func makeCanvas() -> TimelineCanvas {
        let canvas = TimelineCanvas(controller: AnimationController(), frame: viewport)
        let ds = R31Stub(count: 5, cellHeight: cellHeight)
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

    @discardableResult
    private func spinUntil(_ timeout: TimeInterval, condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        return condition()
    }

    private func assertActiveAtFront(_ canvas: TimelineCanvas, moment: String,
                                     file: StaticString = #file, line: UInt = #line) {
        guard let idx = canvas.activeCellIndex,
              let activeCell = canvas.instantiatedCells[idx] else {
            XCTFail("\(moment): no active cell to verify", file: file, line: line)
            return
        }
        XCTAssertTrue(canvas.contentHost.subviews.last === activeCell,
                      "@ \(moment): active cell must be last (frontmost) in contentHost.subviews",
                      file: file, line: line)
    }

    /// Invariant at multiple gesture moments: begin, anticipation,
    /// mid-spring, post-settle.
    func testZOrderInvariantThroughoutContinuousGesture() {
        let canvas = makeCanvas()

        canvas.animateCameraToChatRest(forCellAt: 1)
        assertActiveAtFront(canvas, moment: ".began + anticipation start")

        drainAnticipation(canvas)
        assertActiveAtFront(canvas, moment: "anticipation finished, main spring engaged")

        _ = spinUntil(0.3) { false }
        assertActiveAtFront(canvas, moment: "mid-spring")

        _ = spinUntil(3.0) {
            !canvas.cameraAnimator.isRunning &&
            canvas.extensionAnimator.state != .running
        }
        assertActiveAtFront(canvas, moment: "post-spring-settle (chat-rest)")
    }

    /// Simulates the displacement that updateVisibleCells.addSubview would
    /// cause mid-gesture by re-adding a non-active cell (moves to end of
    /// subviews). The trailing re-assert in updateVisibleCells must restore
    /// active to front.
    func testZOrderRestoredAfterMidGestureDisplacement() {
        let canvas = makeCanvas()

        canvas.animateCameraToChatRest(forCellAt: 1)
        drainAnticipation(canvas)
        XCTAssertEqual(canvas.activeCellIndex, 1)
        // Precondition: cell 1 at end of subviews.
        XCTAssertTrue(canvas.contentHost.subviews.last === canvas.instantiatedCells[1])

        if let cell3 = canvas.instantiatedCells[3] {
            canvas.contentHost.addSubview(cell3)  // moves to end
        }
        XCTAssertFalse(canvas.contentHost.subviews.last === canvas.instantiatedCells[1],
                       "displacement precondition: cell 1 no longer frontmost")

        canvas.setCamera(canvas.camera)
        canvas.contentHost.layoutIfNeeded()

        XCTAssertTrue(canvas.contentHost.subviews.last === canvas.instantiatedCells[1],
                      "updateVisibleCells must trailing-re-assert bringSubviewToFront(activeCell)")
    }

    /// At cell-rest, contentHost.subviews must be in natural index order
    /// (cell 0 before cell 1 before cell 2 ...).
    func testZOrderRestoredAtCellRestTransition() {
        let canvas = makeCanvas()

        // Reach chat-rest of cell 2.
        canvas.animateCameraToChatRest(forCellAt: 2)
        drainAnticipation(canvas)
        _ = spinUntil(3.0) {
            !canvas.cameraAnimator.isRunning &&
            canvas.extensionAnimator.state != .running
        }
        XCTAssertEqual(canvas.activeCellIndex, 2)
        XCTAssertTrue(canvas.contentHost.subviews.last === canvas.instantiatedCells[2])

        canvas.animateCameraToCellRest()
        let cleared = spinUntil(3.0) { canvas.activeCellIndex == nil }
        XCTAssertTrue(cleared, "activeCellIndex should clear after settle")

        let subviewIndices = canvas.contentHost.subviews.compactMap { ($0 as? CellView)?.index }
        let expectedIndices = subviewIndices.sorted()
        XCTAssertEqual(subviewIndices, expectedIndices,
                       "at cell-rest, contentHost.subviews must be in natural index order; got \(subviewIndices), expected \(expectedIndices)")
    }
}

@MainActor
private final class R31Stub: @preconcurrency TimelineDataSource {
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
