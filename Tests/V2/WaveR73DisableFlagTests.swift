// WaveR73DisableFlagTests.swift
//
// PinchTuning.anticipationDisabled A/B flag: when true, tap-to-chat skips
// the anticipation animator; when false (default), anticipation engages
// before the main spring.

import XCTest
@testable import DotPinchPrototype

@MainActor
final class WaveR73DisableFlagTests: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)
    private var retainedDataSource: R73Stub?

    override func tearDown() {
        PinchTuning.anticipationDisabled = false
        super.tearDown()
    }

    private func makeCanvas() -> TimelineCanvas {
        let canvas = TimelineCanvas(frame: viewport)
        let ds = R73Stub(count: 5, cellHeight: 200)
        retainedDataSource = ds
        canvas.dataSource = ds
        canvas.reloadData()
        canvas.layoutIfNeeded()
        canvas.contentHost.layoutIfNeeded()
        return canvas
    }

    /// Flag = true → tap-to-chat skips anticipation entirely; main spring
    /// engages directly.
    func testFlagTrueSkipsAnticipation() {
        PinchTuning.anticipationDisabled = true
        let canvas = makeCanvas()

        canvas.animateCameraToChatRest(forCellAt: 1)

        XCTAssertNil(canvas.anticipationAnimator,
                     "anticipationDisabled = true must skip the anticipation animator.")
        XCTAssertEqual(canvas.activeCellIndex, 1,
                       "main spring engaged: activeCellIndex set")
    }

    /// Flag = false (default) → anticipation engages.
    func testFlagFalseEngagesAnticipation() {
        PinchTuning.anticipationDisabled = false
        let canvas = makeCanvas()

        canvas.animateCameraToChatRest(forCellAt: 1)

        XCTAssertNotNil(canvas.anticipationAnimator,
                        "anticipation animator must engage on tap-to-chat when flag is false.")
    }
}

@MainActor
private final class R73Stub: @preconcurrency TimelineDataSource {
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
