// WaveR32NeighborPositionTests.swift
//
// Neighbor cells stay at natural page-y throughout the gesture: during
// real continuous spring ticks (display link), and during rapid
// reversal (alternating heightConstraint writes).

import XCTest
@testable import DotPinchPrototype

@MainActor
final class WaveR32NeighborPositionTests: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)
    private let cellHeight: CGFloat = 200

    private var retainedDataSource: R32Stub?

    private func makeCanvas() -> TimelineCanvas {
        let canvas = TimelineCanvas(frame: viewport)
        let ds = R32Stub(count: 5, cellHeight: cellHeight)
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

    private func assertNeighborsAtNaturalPageY(_ canvas: TimelineCanvas,
                                                activeIdx: Int,
                                                sampleLabel: String,
                                                file: StaticString = #file, line: UInt = #line) {
        for (idx, cell) in canvas.instantiatedCells where idx != activeIdx {
            let naturalFrame = canvas.pageFrameForCell(at: idx)
            XCTAssertEqual(cell.frame.origin.y, naturalFrame.origin.y,
                           accuracy: 0.5,
                           "@ \(sampleLabel): neighbor cell \(idx) must stay at natural page-y; got origin.y=\(cell.frame.origin.y), expected \(naturalFrame.origin.y)",
                           file: file, line: line)
        }
    }

    func testNeighborPositionsDuringContinuousSpring() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 2)
        drainAnticipation(canvas)
        assertNeighborsAtNaturalPageY(canvas, activeIdx: 2, sampleLabel: "post-anticipation")

        // Spin runloop in short bursts, sampling between bursts.
        let deadline = Date().addingTimeInterval(2.5)
        var sampleCount = 0
        while Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
            sampleCount += 1
            assertNeighborsAtNaturalPageY(canvas, activeIdx: 2,
                                           sampleLabel: "mid-spring sample \(sampleCount)")
            if !canvas.cameraAnimator.isRunning && canvas.extensionAnimator.state != .running {
                break
            }
        }
        XCTAssertGreaterThan(sampleCount, 3,
                             "expected at least 4 samples during spring; got \(sampleCount)")

        assertNeighborsAtNaturalPageY(canvas, activeIdx: 2, sampleLabel: "post-settle")
    }

    func testNeighborPositionsDuringRapidReversal() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 1)
        drainAnticipation(canvas)
        canvas.cameraAnimator.stop(immediately: true)
        canvas.extensionAnimator.stop(immediately: true)
        guard let cell = canvas.instantiatedCells[1],
              let heightC = cell.heightConstraint else { XCTFail(); return }

        let naturalH = cell.naturalHeight
        let chatExt = viewport.height
        // 7 alternating writes simulating rapid reversal
        let sequence: [CGFloat] = [
            naturalH * 1.5,
            naturalH * 2.5,
            naturalH * 1.8,
            chatExt,
            naturalH * 2.0,
            naturalH * 1.2,
            chatExt
        ]
        for (i, value) in sequence.enumerated() {
            heightC.constant = value
            canvas.contentHost.setNeedsLayout()
            canvas.contentHost.layoutIfNeeded()
            // Tick the same seam the spring would: cell.setCamera.
            cell.setCamera(canvas.camera, viewport: canvas.bounds)
            assertNeighborsAtNaturalPageY(canvas, activeIdx: 1,
                                           sampleLabel: "reversal step \(i+1) (value=\(value))")
        }
    }
}

@MainActor
private final class R32Stub: @preconcurrency TimelineDataSource {
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
