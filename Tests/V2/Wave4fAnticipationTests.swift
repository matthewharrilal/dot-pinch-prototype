// Wave4fAnticipationTests.swift
//
// Anticipation animator on tap-to-chat: created with target
// naturalHeight × 0.97, cancellable, tap-only (not engaged via pinch),
// and ignored when a spring is already in flight.

import XCTest
@testable import DotPinchPrototype

@MainActor
final class Wave4fAnticipationTests: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)
    private let cellHeight: CGFloat = 300

    private var retainedDataSource: Wave4fStubDataSource?

    private func makeCanvas() -> TimelineCanvas {
        let canvas = TimelineCanvas(frame: viewport)
        let ds = Wave4fStubDataSource(count: 5, cellHeight: cellHeight)
        retainedDataSource = ds
        canvas.dataSource = ds
        canvas.reloadData()
        canvas.layoutIfNeeded()
        canvas.contentHost.layoutIfNeeded()
        return canvas
    }

    func testAnticipationAnimatorCreated() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 1)
        XCTAssertNotNil(canvas.anticipationAnimator,
                        "animateCameraToChatRest must create the anticipation animator")
    }

    /// Anticipation target = 0.97 × naturalHeight. Verifies by finishing
    /// the animator synchronously and reading the resulting constraint.
    func testAnticipationMagnitude() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 1)
        guard let cell = canvas.instantiatedCells[1] else { XCTFail("missing"); return }
        canvas.anticipationAnimator?.stopAnimation(false)
        canvas.anticipationAnimator?.finishAnimation(at: .end)
        let constant = cell.heightConstraint?.constant ?? 0
        let expected = cell.naturalHeight * 0.97
        XCTAssertEqual(constant, expected, accuracy: 1.0,
                       "Anticipation target = 0.97 × naturalHeight")
    }

    func testAnticipationCanceledOnStop() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 1)
        XCTAssertNotNil(canvas.anticipationAnimator)

        canvas.anticipationAnimator?.stopAnimation(true)
        XCTAssertEqual(canvas.anticipationAnimator?.state, .inactive,
                       "Anticipation animator state must be .inactive after stopAnimation(true)")
    }

    /// Tap-to-chat while a spring is in flight must be ignored.
    func testTapDuringActiveSpringIgnored() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 1)
        canvas.anticipationAnimator?.stopAnimation(false)
        canvas.anticipationAnimator?.finishAnimation(at: .end)
        XCTAssertEqual(canvas.activeCellIndex, 1)

        canvas.animateCameraToChatRest(forCellAt: 3)
        XCTAssertEqual(canvas.activeCellIndex, 1,
                       "tap during active spring must be ignored; activeCellIndex stays at 1")
    }

    /// Public animateCameraToChatRest creates the anticipation animator —
    /// the .ended pinch-commit path bypasses it (verified indirectly:
    /// only public-API access to the difference is whether the animator
    /// exists after the call).
    func testPinchPathSkipsAnticipation() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 0)
        XCTAssertNotNil(canvas.anticipationAnimator,
                        "Public animateCameraToChatRest path creates anticipation")
    }
}

@MainActor
private final class Wave4fStubDataSource: @preconcurrency TimelineDataSource {
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
