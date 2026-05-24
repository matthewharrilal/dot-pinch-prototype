// Wave4cZOrderTests.swift
//
// Z-order and hit-test priority for the active cell: active is frontmost
// in contentHost.subviews; neighbor cells stay at natural page-y; taps in
// the overlap region route to the active cell.

import XCTest
@testable import DotPinchPrototype

@MainActor
final class Wave4cZOrderTests: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)
    private let cellHeight: CGFloat = 300

    // dataSource is weak on TimelineCanvas; the test must own it.
    private var retainedDataSource: Wave4cStubDataSource?

    private func makeCanvas() -> TimelineCanvas {
        let canvas = TimelineCanvas(controller: AnimationController(), frame: viewport)
        let ds = Wave4cStubDataSource(count: 5, cellHeight: cellHeight)
        retainedDataSource = ds
        canvas.dataSource = ds
        canvas.reloadData()
        canvas.layoutIfNeeded()
        canvas.contentHost.layoutIfNeeded()
        return canvas
    }

    /// Active cell must be the frontmost subview of contentHost.
    func testActiveCellAtFrontOfContentHostSubviews() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 2)
        guard let activeCell = canvas.instantiatedCells[2] else {
            XCTFail("Active cell missing")
            return
        }
        XCTAssertTrue(
            canvas.contentHost.subviews.last === activeCell,
            "active cell must be at the END of contentHost.subviews (frontmost)"
        )
    }

    /// Neighbor cells stay at natural page-y under extended active cell.
    func testNeighborCellsRemainAtNaturalPageY() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 1)
        guard let activeCell = canvas.instantiatedCells[1],
              let heightC = activeCell.heightConstraint else {
            XCTFail("Active cell missing")
            return
        }
        // Extend active cell.
        heightC.constant = cellHeight * 2.5
        canvas.contentHost.setNeedsLayout()
        canvas.contentHost.layoutIfNeeded()

        for (index, cell) in canvas.instantiatedCells where index != 1 {
            let naturalFrame = canvas.pageFrameForCell(at: index)
            XCTAssertEqual(
                cell.frame.origin.y, naturalFrame.origin.y,
                accuracy: 0.5,
                "non-active cell \(index) must stay at natural page-y; got origin.y=\(cell.frame.origin.y), expected \(naturalFrame.origin.y)"
            )
        }
    }

    /// Point in active cell's extended overflow region must route to the
    /// active cell, not the underneath neighbor.
    func testHitTestPrefersActiveCellInOverlapRegion() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 1)
        guard let activeCell = canvas.instantiatedCells[1],
              let heightC = activeCell.heightConstraint else {
            XCTFail("Active cell missing")
            return
        }

        // Extend active cell so its frame overlaps cell 2's natural frame.
        heightC.constant = cellHeight * 2.5
        canvas.contentHost.setNeedsLayout()
        canvas.contentHost.layoutIfNeeded()

        // Cell 2's natural pageFrame is at y=648..948. Active cell 1
        // with extension 750pt centered at midY=474 spans y=99..849,
        // overlapping cell 2's y=648..849 region.
        let cell2NaturalFrame = canvas.pageFrameForCell(at: 2)
        XCTAssertTrue(
            activeCell.frame.maxY > cell2NaturalFrame.origin.y,
            "Test sanity: active cell must extend into cell 2's natural region"
        )

        // Tap a point in the overlap region (active cell's extension over
        // cell 2's natural slot). Convert page point to viewport point.
        let overlapPagePoint = CGPoint(x: 195, y: cell2NaturalFrame.origin.y + 20)
        let overlapViewportPoint = canvas.viewportPointFromPagePoint(overlapPagePoint)

        let hit = canvas.hitTest(overlapViewportPoint, with: nil)
        XCTAssertTrue(
            hit?.isDescendant(of: activeCell) ?? false,
            "Hit at overlap region must route to active cell's descendants, not neighbor; got \(String(describing: hit))"
        )
    }
}

@MainActor
private final class Wave4cStubDataSource: @preconcurrency TimelineDataSource {
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
