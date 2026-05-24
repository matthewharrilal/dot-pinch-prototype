// WaveR35HitTestRegionsTests.swift
//
// Hit-test routing for the active cell: taps in its natural region and
// extended overlap region route to active; taps outside its bounds do
// NOT route to active (over-eager priority guard). Plus TAMIC=false on
// all cells at install.

import XCTest
@testable import DotPinchPrototype

@MainActor
final class WaveR35HitTestRegionsTests: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)
    private let cellHeight: CGFloat = 200

    private var retainedDataSource: R35Stub?

    private func makeCanvas() -> TimelineCanvas {
        let canvas = TimelineCanvas(frame: viewport)
        let ds = R35Stub(count: 5, cellHeight: cellHeight)
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

    /// TAMIC=false on all visible cells; otherwise autoresizing-derived
    /// bounds would conflict with constraint-driven layout.
    func testAllCellsHaveTAMICFalseAtInstall() {
        let canvas = makeCanvas()
        for (idx, cell) in canvas.instantiatedCells {
            XCTAssertFalse(cell.translatesAutoresizingMaskIntoConstraints,
                           "cell \(idx) must have TAMIC=false")
        }
    }

    /// Tap in active cell's natural region at mid-extension F=1.5.
    func testHitTestInActiveCellNaturalRegion() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 2)
        drainAnticipation(canvas)
        canvas.cameraAnimator.stop(immediately: true)
        canvas.extensionAnimator.stop(immediately: true)
        guard let activeCell = canvas.instantiatedCells[2],
              let heightC = activeCell.heightConstraint else { XCTFail(); return }

        heightC.constant = cellHeight * 1.5
        canvas.contentHost.setNeedsLayout()
        canvas.contentHost.layoutIfNeeded()

        // Tap in active cell's natural page-frame region (no overlap).
        let naturalFrame = canvas.pageFrameForCell(at: 2)
        let pagePoint = CGPoint(x: 195, y: naturalFrame.midY)
        let viewportPoint = canvas.viewportPointFromPagePoint(pagePoint)
        let hit = canvas.hitTest(viewportPoint, with: nil)
        XCTAssertTrue(hit?.isDescendant(of: activeCell) ?? false,
                      "tap inside active cell's natural region must hit active cell; got \(String(describing: hit))")
    }

    /// Tap in active cell's extended overlap region (overlaps cell 3's slot).
    func testHitTestInActiveExtendedOverlapRegion() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 2)
        drainAnticipation(canvas)
        canvas.cameraAnimator.stop(immediately: true)
        canvas.extensionAnimator.stop(immediately: true)
        guard let activeCell = canvas.instantiatedCells[2],
              let heightC = activeCell.heightConstraint else { XCTFail(); return }

        // F=2.5 — active cell overlaps cell 3's natural slot downward.
        heightC.constant = cellHeight * 2.5
        canvas.contentHost.setNeedsLayout()
        canvas.contentHost.layoutIfNeeded()

        let cell3Natural = canvas.pageFrameForCell(at: 3)
        let pagePoint = CGPoint(x: 195, y: cell3Natural.origin.y + 10)
        let viewportPoint = canvas.viewportPointFromPagePoint(pagePoint)
        XCTAssertTrue(activeCell.frame.contains(pagePoint),
                      "test sanity: active cell extended bounds must contain probe point")
        XCTAssertTrue(cell3Natural.contains(pagePoint),
                      "test sanity: cell 3 natural frame must contain probe point (overlap region)")

        let hit = canvas.hitTest(viewportPoint, with: nil)
        XCTAssertTrue(hit?.isDescendant(of: activeCell) ?? false,
                      "tap inside overlap region must route to active cell (z-order priority); got \(String(describing: hit))")
    }

    /// Tap outside active cell's bounds must NOT route to active
    /// (over-eager priority guard).
    func testHitTestOutsideActiveBoundsRoutesElsewhere() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 1)
        drainAnticipation(canvas)
        canvas.cameraAnimator.stop(immediately: true)
        canvas.extensionAnimator.stop(immediately: true)
        guard let activeCell = canvas.instantiatedCells[1],
              let heightC = activeCell.heightConstraint else { XCTFail(); return }

        // F=1.5 — active doesn't reach cell 4's slot.
        heightC.constant = cellHeight * 1.5
        canvas.contentHost.setNeedsLayout()
        canvas.contentHost.layoutIfNeeded()

        let cell4Natural = canvas.pageFrameForCell(at: 4)
        let pagePoint = CGPoint(x: 195, y: cell4Natural.midY)
        let viewportPoint = canvas.viewportPointFromPagePoint(pagePoint)
        XCTAssertFalse(activeCell.frame.contains(pagePoint),
                       "test sanity: cell 4 region must be OUTSIDE active cell's extended bounds")

        let hit = canvas.hitTest(viewportPoint, with: nil)
        if let hit = hit {
            XCTAssertFalse(hit.isDescendant(of: activeCell),
                           "tap outside active cell's bounds must NOT route to active cell; got descendant of active")
        }
    }
}

@MainActor
private final class R35Stub: @preconcurrency TimelineDataSource {
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
