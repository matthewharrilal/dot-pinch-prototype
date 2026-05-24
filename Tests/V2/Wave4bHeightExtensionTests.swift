// Wave4bHeightExtensionTests.swift
//
// Height-extension invariants: extension only on active cell, pool-clean
// height, active-cell-pool-protection, frame tracks constraint, and
// updateVisibleCells doesn't clobber active extension on refresh. Drives
// the pinch handler via direct heightConstraint mutation since
// UIPinchGestureRecognizer isn't injectable.

import XCTest
@testable import DotPinchPrototype

@MainActor
final class Wave4bHeightExtensionTests: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)
    private let cellHeight: CGFloat = 300
    private let cellCount = 5

    private func makeCanvas() -> (TimelineCanvas, Wave4bStubDataSource) {
        let canvas = TimelineCanvas(controller: AnimationController(), frame: viewport)
        let ds = Wave4bStubDataSource(count: cellCount, cellHeight: cellHeight)
        canvas.dataSource = ds
        canvas.reloadData()
        canvas.layoutIfNeeded()
        canvas.contentHost.layoutIfNeeded()
        return (canvas, ds)
    }

    // MARK: - Height extension only on active

    func testHeightExtensionOnlyOnActiveCell() {
        let (canvas, _) = makeCanvas()
        // Set cell 1 active and extend its height.
        canvas.animateCameraToChatRest(forCellAt: 1)
        guard let activeCell = canvas.instantiatedCells[1],
              let activeHeightC = activeCell.heightConstraint else {
            XCTFail("Active cell or heightConstraint missing")
            return
        }
        activeHeightC.constant = cellHeight * 2.5  // extend
        forceLayout(canvas: canvas)

        for (index, cell) in canvas.instantiatedCells where index != 1 {
            let constant = cell.heightConstraint?.constant ?? -1
            XCTAssertEqual(
                constant, cellHeight,
                accuracy: 0.001,
                "non-active cell \(index) must remain at naturalHeight; got \(constant)"
            )
        }
    }

    // MARK: - Pool-clean height

    func testPoolReturnResetsHeightToNatural() {
        let (canvas, ds) = makeCanvas()
        guard let cell0 = canvas.instantiatedCells[0],
              let height0 = cell0.heightConstraint else {
            XCTFail("Cell 0 missing")
            return
        }

        // Simulate a residual extension on cell 0 (non-active, so the
        // active-cell guard doesn't reject).
        height0.constant = cellHeight * 2.0
        canvas.contentHost.layoutIfNeeded()
        XCTAssertEqual(height0.constant, cellHeight * 2.0, accuracy: 0.001)

        // Drop count to 0 so reloadData routes ALL cells through returnToPool
        // and the subsequent updateVisibleCells doesn't re-dequeue anything.
        // Scrolling far doesn't work — dequeue would re-pick the just-pooled
        // cell (pool's LIFO grabs unbound cells eagerly).
        ds.count = 0
        canvas.reloadData()

        XCTAssertNotNil(canvas.cellPool.first { $0 === cell0 },
                        "Cell 0 should be in the pool after reloadData with count=0")
        XCTAssertNil(cell0.heightConstraint,
                     "pool-returned cell's heightConstraint should be deactivated/nil")
        XCTAssertEqual(cell0.naturalHeight, cellHeight, accuracy: 0.001,
                       "naturalHeight preserved across pool round-trip")
    }

    // MARK: - Active-cell pool protection

    func testActiveCellRejectedByPoolReturn() {
        let (canvas, _) = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 2)
        guard let activeCell = canvas.instantiatedCells[2] else {
            XCTFail("Active cell missing")
            return
        }

        // Pan far past cell 2 — the active-cell filter in updateVisibleCells
        // should preserve it. setCamera can still write even though the pan
        // recognizer is disabled while activeCellIndex != nil.
        canvas.setCamera(Camera(translation: viewport.height * 10))
        canvas.contentHost.layoutIfNeeded()

        XCTAssertNotNil(canvas.instantiatedCells[2],
                        "active cell must remain in instantiatedCells even when scrolled out of natural visible range")
        XCTAssertFalse(canvas.cellPool.contains { $0 === activeCell },
                       "active cell must not be in cellPool")
    }

    // MARK: - Symmetric extension (frame tracks constraint)

    func testFrameTracksHeightConstraintSymmetrically() {
        let (canvas, _) = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 1)
        guard let activeCell = canvas.instantiatedCells[1],
              let heightC = activeCell.heightConstraint else {
            XCTFail("Active cell or constraint missing")
            return
        }

        let naturalMidY = activeCell.frame.midY
        let extendedHeight: CGFloat = cellHeight * 2.0

        heightC.constant = extendedHeight
        forceLayout(canvas: canvas)

        XCTAssertEqual(activeCell.frame.size.height, extendedHeight, accuracy: 0.5,
                       "Frame height must track heightConstraint.constant")
        // Symmetric extension preserves midY in page (contentHost) coords.
        XCTAssertEqual(activeCell.frame.midY, naturalMidY, accuracy: 0.5,
                       "cell midY must remain invariant under height extension")
    }

    // MARK: - Helpers

    /// Belt-and-suspenders setNeedsLayout chain. In the windowless test
    /// harness, constraint constant changes don't always propagate
    /// setNeedsLayout up to contentHost reliably.
    private func forceLayout(canvas: TimelineCanvas) {
        canvas.setNeedsLayout()
        canvas.contentHost.setNeedsLayout()
        canvas.contentHost.layoutIfNeeded()
        canvas.layoutIfNeeded()
    }

    // MARK: - updateVisibleCells doesn't clobber active extension

    func testUpdateVisibleCellsPreservesActiveExtension() {
        let (canvas, _) = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 1)
        guard let activeCell = canvas.instantiatedCells[1],
              let heightC = activeCell.heightConstraint else {
            XCTFail("Active cell or constraint missing")
            return
        }

        let extendedHeight: CGFloat = cellHeight * 2.5
        heightC.constant = extendedHeight
        forceLayout(canvas: canvas)
        XCTAssertEqual(heightC.constant, extendedHeight, accuracy: 0.001)

        // Trigger updateVisibleCells via setCamera (nudge translation).
        // The refresh branch must SKIP the active cell to avoid resetting
        // its heightConstraint back to natural.
        canvas.setCamera(Camera(translation: canvas.camera.translation + 1))
        canvas.contentHost.layoutIfNeeded()

        XCTAssertEqual(heightC.constant, extendedHeight, accuracy: 0.001,
                       "updateVisibleCells refresh must NOT clobber active cell's extended height")
    }
}

@MainActor
private final class Wave4bStubDataSource: @preconcurrency TimelineDataSource {
    var count: Int  // mutable so tests can vary cell-count between assertions
    let cellHeight: CGFloat
    init(count: Int, cellHeight: CGFloat) {
        self.count = count
        self.cellHeight = cellHeight
    }
    func numberOfCells(in canvas: TimelineCanvas) -> Int { count }
    func canvas(_ canvas: TimelineCanvas, configureCell cell: CellView, at index: Int) {}
    func canvas(_ canvas: TimelineCanvas, heightForCellAt index: Int) -> CGFloat { cellHeight }
}
