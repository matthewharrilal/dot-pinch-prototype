// Wave4dSpringSettleTests.swift
//
// Spring engagement and cancellation: chat-rest / cell-rest gateways
// engage both camera + extension animators with the correct targets; a
// new pinch cancels in-flight springs.

import XCTest
@testable import DotPinchPrototype

@MainActor
final class Wave4dSpringSettleTests: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)
    private let cellHeight: CGFloat = 300

    private var retainedDataSource: Wave4dStubDataSource?

    private func makeCanvas() -> TimelineCanvas {
        let canvas = TimelineCanvas(frame: viewport)
        let ds = Wave4dStubDataSource(count: 5, cellHeight: cellHeight)
        retainedDataSource = ds
        canvas.dataSource = ds
        canvas.reloadData()
        canvas.layoutIfNeeded()
        canvas.contentHost.layoutIfNeeded()
        return canvas
    }

    /// Anticipation runs BEFORE the main spring on tap-to-chat. Tests
    /// inspecting main-spring state must drain it first.
    private func drainAnticipation(_ canvas: TimelineCanvas) {
        canvas.anticipationAnimator?.stopAnimation(false)
        canvas.anticipationAnimator?.finishAnimation(at: .end)
    }

    func testAnimateCameraToChatRestEngagesBothSprings() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 1)
        drainAnticipation(canvas)

        XCTAssertEqual(canvas.activeCellIndex, 1,
                       "activeCellIndex set immediately at chat-rest call")
        XCTAssertTrue(
            canvas.cameraAnimator.isRunning,
            "cameraAnimator must be running after animateCameraToChatRest"
        )
        XCTAssertEqual(
            canvas.extensionAnimator.state, .running,
            "extensionAnimator must be running after animateCameraToChatRest"
        )
    }

    /// Cell-rest ALWAYS engages the extension spring (heightConstraint must
    /// collapse). Camera spring engagement depends on whether the camera
    /// needs to move — same-target short-circuit fires if chat-rest position
    /// equals cell-rest target. Test forces non-trivial camera gap.
    func testAnimateCameraToCellRestEngagesExtensionSpring() {
        let canvas = makeCanvas()
        // Get into chat-rest first.
        canvas.animateCameraToChatRest(forCellAt: 2)
        drainAnticipation(canvas)
        // Synchronously bring the camera to its chat-rest position so the
        // subsequent cell-rest call sees a real translation gap.
        if let cell = canvas.instantiatedCells[2] {
            canvas.setCamera(Camera(translation: cell.frame.midY))
        }
        // Now collapse.
        canvas.animateCameraToCellRest()

        XCTAssertEqual(
            canvas.extensionAnimator.state, .running,
            "extensionAnimator must be running after animateCameraToCellRest"
        )
        XCTAssertTrue(
            canvas.cameraAnimator.isRunning,
            "cameraAnimator must be running after animateCameraToCellRest (camera at chat-rest position must move to cell-rest)"
        )
    }

    /// New pinch .began must stop in-flight springs. UIKit event injection
    /// isn't available; this exercises the public stop disciplines that
    /// .began calls.
    func testNewPinchStopsInFlightSprings() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 1)
        drainAnticipation(canvas)
        XCTAssertTrue(canvas.cameraAnimator.isRunning)
        XCTAssertEqual(canvas.extensionAnimator.state, .running)

        canvas.cameraAnimator.stop(immediately: true)
        canvas.extensionAnimator.stop(immediately: true)

        XCTAssertFalse(canvas.cameraAnimator.isRunning,
                       "cameraAnimator must be stopped after spring cancellation")
        XCTAssertNotEqual(canvas.extensionAnimator.state, .running,
                          "extensionAnimator must NOT be running after spring cancellation")
    }

    func testExtensionTargetIsChatRestHeight() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 1)
        drainAnticipation(canvas)
        guard let cell = canvas.instantiatedCells[1] else {
            XCTFail("cell missing"); return
        }
        let expected = cell.naturalHeight * (viewport.height / cell.naturalHeight)
        XCTAssertEqual(
            canvas.extensionAnimator.target ?? -1, expected,
            accuracy: 0.5,
            "Extension animator target must be naturalHeight × chatRestExtensionFactor (= viewport.height)"
        )
    }

    func testExtensionTargetIsNaturalHeightOnCellRest() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 1)
        drainAnticipation(canvas)
        canvas.animateCameraToCellRest()
        guard let cell = canvas.instantiatedCells[1] else {
            XCTFail("cell missing"); return
        }
        XCTAssertEqual(
            canvas.extensionAnimator.target ?? -1, cell.naturalHeight,
            accuracy: 0.5,
            "Extension animator target must be naturalHeight after cell-rest call"
        )
    }
}

@MainActor
private final class Wave4dStubDataSource: @preconcurrency TimelineDataSource {
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
