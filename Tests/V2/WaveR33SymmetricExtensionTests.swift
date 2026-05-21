// WaveR33SymmetricExtensionTests.swift
//
// Cell midY page-coord invariant under any extensionFactor. Asserts
// constraint identity (centerYAnchor, not topAnchor — a refactor to
// top-anchored would silently break extension symmetry) plus midY
// invariance across 5 extensionFactor values including fractional heights.

import XCTest
@testable import DotPinchPrototype

@MainActor
final class WaveR33SymmetricExtensionTests: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)
    private let cellHeight: CGFloat = 200

    private var retainedDataSource: R33Stub?

    private func makeCanvas() -> TimelineCanvas {
        let canvas = TimelineCanvas(frame: viewport)
        let ds = R33Stub(count: 5, cellHeight: cellHeight)
        retainedDataSource = ds
        canvas.dataSource = ds
        canvas.reloadData()
        canvas.layoutIfNeeded()
        canvas.contentHost.layoutIfNeeded()
        return canvas
    }

    private func drainAnticipation(_ canvas: TimelineCanvas) {
        canvas.anticipationAnimator?.stopAnimation(false)
        canvas.anticipationAnimator?.finishAnimation(at: .end)
    }

    func testSymmetricExtensionAtMultipleFactors() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 2)
        drainAnticipation(canvas)
        canvas.cameraAnimator.stop(immediately: true)
        canvas.extensionAnimator.stop(immediately: true)
        guard let cell = canvas.instantiatedCells[2],
              let heightC = cell.heightConstraint,
              let centerYC = cell.centerYConstraint else {
            XCTFail("active cell constraints missing")
            return
        }

        // Assert constraint identity before testing behavior — a swap to
        // topAnchor would silently flip extension to asymmetric.
        XCTAssertEqual(centerYC.firstAttribute, .centerY,
                       "active cell's anchor must be centerY (topAnchor produces asymmetric extension)")
        XCTAssertEqual(centerYC.firstItem as? CellView, cell,
                       "centerYC's firstItem must be the cell")

        let naturalMidY = cell.frame.midY
        let naturalH = cell.naturalHeight

        // Includes fractional heights to avoid the integer-rounding regime.
        let factors: [CGFloat] = [1.0, 1.5, 1.7, 2.3, viewport.height / naturalH]

        // Tolerance accounts for display scale (3x → 1/3 ≈ 0.33pt).
        let screenScale = UIScreen.main.scale
        let tolerance: CGFloat = 1.0 / screenScale + 0.5

        for f in factors {
            let extendedHeight = naturalH * f
            heightC.constant = extendedHeight
            canvas.contentHost.setNeedsLayout()
            canvas.contentHost.layoutIfNeeded()
            XCTAssertEqual(cell.frame.midY, naturalMidY, accuracy: tolerance,
                           "midY drift at F=\(f) (h=\(extendedHeight)): got \(cell.frame.midY), expected \(naturalMidY) ±\(tolerance)")
            let expectedTop = naturalMidY - extendedHeight / 2
            let expectedBottom = naturalMidY + extendedHeight / 2
            XCTAssertEqual(cell.frame.origin.y, expectedTop, accuracy: tolerance,
                           "top at F=\(f): got \(cell.frame.origin.y), expected \(expectedTop)")
            XCTAssertEqual(cell.frame.maxY, expectedBottom, accuracy: tolerance,
                           "bottom at F=\(f): got \(cell.frame.maxY), expected \(expectedBottom)")
        }
    }
}

@MainActor
private final class R33Stub: @preconcurrency TimelineDataSource {
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
