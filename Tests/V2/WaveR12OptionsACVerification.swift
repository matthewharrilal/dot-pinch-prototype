// WaveR12OptionsACVerification.swift
//
// Tap on a different cell during chat-rest is IGNORED; chat-rest endpoint
// settles within ±50pt of activeCell.naturalMidY under non-trivial release
// velocity.

import XCTest
@testable import DotPinchPrototype

@MainActor
final class WaveR12OptionsACVerification: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)
    private let cellHeight: CGFloat = 200

    private var retainedDataSource: R12Stub?

    private func makeCanvas() -> TimelineCanvas {
        let canvas = TimelineCanvas(frame: viewport)
        let ds = R12Stub(count: 5, cellHeight: cellHeight)
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

    /// Tap on a different cell during chat-rest is ignored.
    func testOptionA_TapOnDifferentCellDuringChatRestIgnored() {
        let canvas = makeCanvas()

        // Reach steady-state chat-rest of cell 1.
        canvas.animateCameraToChatRest(forCellAt: 1)
        drainAnticipation(canvas)
        _ = spinUntil(3.0) {
            !canvas.cameraAnimator.isRunning &&
            canvas.extensionAnimator.state != .running
        }
        XCTAssertEqual(canvas.activeCellIndex, 1,
                       "precondition: activeCellIndex=1 after settle")
        guard let cell1 = canvas.instantiatedCells[1],
              let cell1Height = cell1.heightConstraint else { XCTFail(); return }
        let cell1ExtBefore = cell1Height.constant

        canvas.animateCameraToChatRest(forCellAt: 3)

        XCTAssertEqual(canvas.activeCellIndex, 1,
                       "activeCellIndex must stay 1; tap on cell 3 ignored")
        XCTAssertEqual(cell1.heightConstraint?.constant ?? -1, cell1ExtBefore,
                       accuracy: 0.5,
                       "cell 1's extension must not change (no spring engagement on j)")
    }

    /// chat-rest endpoint settles within ±50pt of target under non-trivial
    /// release velocity. target=548 corresponds to chat-rest of cell 2
    /// (cellHeight=200, ys[2]=448, midY=448+100=548). Start at translation
    /// 200 with velocity 500pt/s to simulate gesture release.
    func testOptionC_ChatRestSettlesWithin50ptOfTargetUnderVelocity() {
        let canvas = makeCanvas()

        let target: CGFloat = 548
        canvas.setCamera(Camera(translation: 200))
        let velocityPtsPerSec: CGFloat = 500
        canvas.cameraAnimator.animate(
            to: Camera(translation: target),
            velocity: CameraVelocity(translationVelocity: velocityPtsPerSec)
        )

        let settled = spinUntil(4.0) {
            !canvas.cameraAnimator.isRunning
        }
        XCTAssertTrue(settled, "camera spring must settle within 4s")

        let finalDelta = abs(canvas.camera.translation - target)
        XCTAssertLessThan(finalDelta, 50.0,
                          "final settled position must be within ±50pt of activeCell.naturalMidY. Got delta=\(finalDelta) (camera=\(canvas.camera.translation), target=\(target))")
    }
}

@MainActor
private final class R12Stub: @preconcurrency TimelineDataSource {
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
