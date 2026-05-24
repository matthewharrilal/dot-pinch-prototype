// WaveR36OverlapSignatureTests.swift
//
// Overlap visual signature (not cascade fade): all cells stay at
// alpha=1.0 throughout the gesture (no animated fade); neighbor
// visibility transitions are driven purely by geometric occlusion —
// active.frame.intersects/contains(neighbor's natural frame).

import XCTest
@testable import DotPinchPrototype

@MainActor
final class WaveR36OverlapSignatureTests: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)
    private let cellHeight: CGFloat = 200

    private var retainedDataSource: R36Stub?

    private func makeCanvas() -> TimelineCanvas {
        let canvas = TimelineCanvas(frame: viewport)
        let ds = R36Stub(count: 5, cellHeight: cellHeight)
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

    /// Carrier alpha (cell.alpha == 1.0) holds for ALL cells at ALL
    /// extension factor values — overlap signature comes from geometric
    /// occlusion, not alpha animation.
    func testCellCarrierAlphaInvariantAtAllExtensionFactors() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 2)
        drainAnticipation(canvas)
        canvas.cameraAnimator.stop(immediately: true)
        canvas.extensionAnimator.stop(immediately: true)

        guard let active = canvas.instantiatedCells[2],
              let heightC = active.heightConstraint else { XCTFail(); return }

        let naturalH = active.naturalHeight
        let chatRest = canvas.contentHost.bounds.height / naturalH
        let factors: [CGFloat] = [
            1.0,
            1.2,
            1.5,
            1.8,
            2.0,
            2.5,
            3.5,
            chatRest
        ]
        for f in factors {
            heightC.constant = naturalH * f
            canvas.contentHost.setNeedsLayout()
            canvas.contentHost.layoutIfNeeded()
            for (idx, cell) in canvas.instantiatedCells {
                XCTAssertEqual(cell.alpha, 1.0, accuracy: 1e-9,
                               "@ F=\(f): cell \(idx) carrier alpha must be 1.0 (no animated fade — geometric occlusion only)")
            }
        }
    }

    /// At F such that active.frame fully covers a neighbor's natural
    /// page-rect, the neighbor is geometrically hidden behind active.
    /// At lower F, neighbor is partially or fully visible. Discrete per
    /// neighbor — the overlap signature.
    func testGeometricOcclusionFollowsDiscreteThresholdPerNeighbor() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 2)
        drainAnticipation(canvas)
        canvas.cameraAnimator.stop(immediately: true)
        canvas.extensionAnimator.stop(immediately: true)

        guard let active = canvas.instantiatedCells[2],
              let heightC = active.heightConstraint else { XCTFail(); return }

        let naturalH = active.naturalHeight
        // F=1.0: active.frame=[448,648]. Cell 1 natural=[224,424]. No overlap.
        heightC.constant = naturalH * 1.0
        canvas.contentHost.setNeedsLayout()
        canvas.contentHost.layoutIfNeeded()
        let cell1Natural = canvas.pageFrameForCell(at: 1)
        XCTAssertFalse(active.frame.intersects(cell1Natural),
                       "F=1.0: active frame doesn't overlap cell 1's natural range")

        // F=2.5: active.frame=[298,798]. Partial overlap with cell 1.
        heightC.constant = naturalH * 2.5
        canvas.contentHost.setNeedsLayout()
        canvas.contentHost.layoutIfNeeded()
        XCTAssertTrue(active.frame.intersects(cell1Natural),
                      "F=2.5: active frame overlaps cell 1's natural range (overlap region exists)")
        XCTAssertFalse(active.frame.contains(cell1Natural),
                       "F=2.5: active does NOT fully contain cell 1; cell 1 partially visible")

        // F=4.0: active spans cell 1 entirely (active.top <= 224 requires
        // F >= (548-224)/100 = 3.24).
        heightC.constant = naturalH * 4.0
        canvas.contentHost.setNeedsLayout()
        canvas.contentHost.layoutIfNeeded()
        XCTAssertTrue(active.frame.contains(cell1Natural),
                      "F=4.0: active fully occludes cell 1 (full bounds-containment)")
    }
}

@MainActor
private final class R36Stub: @preconcurrency TimelineDataSource {
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
