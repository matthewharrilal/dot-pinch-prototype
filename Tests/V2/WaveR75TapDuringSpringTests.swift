// WaveR75TapDuringSpringTests.swift
//
// Tap during an active spring (anticipation, main spring, or settle) is
// IGNORED. Single-active invariant preserved via the guard in
// animateCameraToChatRest's prologue.

import XCTest
@testable import DotPinchPrototype

@MainActor
final class WaveR75TapDuringSpringTests: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)
    private var retainedDataSource: R75Stub?

    private func makeCanvas() -> TimelineCanvas {
        let canvas = TimelineCanvas(frame: viewport)
        let ds = R75Stub(count: 5, cellHeight: 200)
        retainedDataSource = ds
        canvas.dataSource = ds
        canvas.reloadData()
        canvas.layoutIfNeeded()
        canvas.contentHost.layoutIfNeeded()
        return canvas
    }

    /// Tap during anticipation phase is ignored — guard catches via
    /// anticipationAnimator?.state == .active.
    func testTapDuringAnticipationIsIgnored() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 1)
        XCTAssertEqual(canvas.activeCellIndex, 1, "tap-1 engaged on cell 1")
        XCTAssertNotNil(canvas.anticipationAnimator, "anticipation active")

        // Tap on DIFFERENT cell during anticipation — must be ignored.
        canvas.animateCameraToChatRest(forCellAt: 3)

        XCTAssertEqual(canvas.activeCellIndex, 1,
                       "tap during anticipation ignored — activeCellIndex stays at 1, not 3.")
    }

    /// Tap during main spring phase is ignored — guard catches via
    /// isRunning. Anticipation's addCompletion engages camera+extension on drain.
    func testTapDuringMainSpringIsIgnored() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 1)

        canvas.anticipationAnimator?.stopAnimation(false)
        canvas.anticipationAnimator?.finishAnimation(at: .end)

        XCTAssertEqual(canvas.activeCellIndex, 1)
        XCTAssertTrue(canvas.cameraAnimator.isRunning
                      || canvas.extensionAnimator.state == .running,
                      "main spring engaged after anticipation drain")

        canvas.animateCameraToChatRest(forCellAt: 3)
        XCTAssertEqual(canvas.activeCellIndex, 1,
                       "tap during main spring ignored — activeCellIndex stays at 1.")
    }

    /// Tap on the same active cell mid-anticipation is no-op — the existing
    /// animator instance must remain unchanged.
    func testTapOnSameCellDuringSpringIsNoOp() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 1)

        let preStateRefId = ObjectIdentifier(canvas.anticipationAnimator!)
        canvas.animateCameraToChatRest(forCellAt: 1)

        guard let postAnimator = canvas.anticipationAnimator else {
            XCTFail("anticipation animator vanished — guard didn't short-circuit"); return
        }
        XCTAssertEqual(ObjectIdentifier(postAnimator), preStateRefId,
                       "tap on same active cell mid-anticipation must leave animator instance unchanged.")
    }

    /// Regression: after full spring settle (activeCellIndex cleared),
    /// subsequent tap engages normally.
    func testTapAfterSettleEngagesNormally() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 1)

        // Drain everything to clear activeCellIndex.
        canvas.anticipationAnimator?.stopAnimation(false)
        canvas.anticipationAnimator?.finishAnimation(at: .end)
        canvas.cameraAnimator.stop(immediately: true)
        canvas.extensionAnimator.stop(immediately: true)

        if let cell = canvas.instantiatedCells[1], let heightC = cell.heightConstraint {
            heightC.constant = cell.naturalHeight
            canvas.contentHost.layoutIfNeeded()
        }
        canvas.animateCameraToCellRest()
        canvas.cameraAnimator.stop(immediately: true)
        canvas.extensionAnimator.stop(immediately: true)

        // If activeCellIndex didn't clear, the quiet condition isn't met
        // and the guard at the prologue would (correctly) reject.
        if canvas.activeCellIndex == nil
            && !canvas.cameraAnimator.isRunning
            && canvas.extensionAnimator.state != .running
            && canvas.anticipationAnimator?.state != .active {
            canvas.animateCameraToChatRest(forCellAt: 3)
            XCTAssertEqual(canvas.activeCellIndex, 3,
                           "regression: tap after settle engages normally")
        }
    }
}

@MainActor
private final class R75Stub: @preconcurrency TimelineDataSource {
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
