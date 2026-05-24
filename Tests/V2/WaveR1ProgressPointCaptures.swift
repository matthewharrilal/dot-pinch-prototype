// WaveR1ProgressPointCaptures.swift
//
// Visual capture run (not a correctness test): emits PNGs of the
// TimelineCanvas at 5 progress points {0.0, 0.25, 0.5, 0.75, 1.0} to /tmp/
// for side-by-side reference diff.

import XCTest
import UIKit
@testable import DotPinchPrototype

@MainActor
final class WaveR1ProgressPointCaptures: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)
    private let cellHeight: CGFloat = 300

    private var retainedDataSource: WaveR1StubDataSource?

    private func makeCanvas() -> (TimelineCanvas, UIWindow) {
        let window = UIWindow(frame: viewport)
        let canvas = TimelineCanvas(frame: viewport)
        let ds = WaveR1StubDataSource(count: 5, cellHeight: cellHeight)
        retainedDataSource = ds
        canvas.dataSource = ds
        window.addSubview(canvas)
        window.makeKeyAndVisible()
        canvas.reloadData()
        canvas.layoutIfNeeded()
        canvas.contentHost.layoutIfNeeded()
        return (canvas, window)
    }

    /// Render the canvas to a PNG at /tmp/<filename>.
    private func render(_ view: UIView, to path: String) {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 2.0
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds, format: format)
        let image = renderer.image { ctx in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        if let data = image.pngData() {
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }

    /// Emits 5 PNGs to /tmp/wave-r1-prototype-progress-{X}.png.
    func testCaptureFiveProgressPoints() {
        let (canvas, _) = makeCanvas()
        let activeCellIdx = 1
        canvas.animateCameraToChatRest(forCellAt: activeCellIdx)
        // Stop main springs so they don't tick during manual writes.
        canvas.cameraAnimator.stop(immediately: true)
        canvas.extensionAnimator.stop(immediately: true)

        guard let activeCell = canvas.instantiatedCells[activeCellIdx],
              let heightC = activeCell.heightConstraint else {
            XCTFail("active cell missing"); return
        }

        let naturalH = activeCell.naturalHeight
        let chatRestExt = viewport.height / naturalH  // ≈ 2.813
        let chatRestRange = chatRestExt - 1.0

        let progressPoints: [CGFloat] = [0.0, 0.25, 0.5, 0.75, 1.0]
        for p in progressPoints {
            let extFactor = 1.0 + p * chatRestRange
            let targetHeight = naturalH * extFactor
            heightC.constant = targetHeight
            canvas.setCamera(Camera(translation: activeCell.frame.midY))
            canvas.contentHost.setNeedsLayout()
            canvas.contentHost.layoutIfNeeded()
            canvas.layoutIfNeeded()
            activeCell.setCamera(canvas.camera, viewport: viewport)
            let path = String(format: "/tmp/wave-r1-prototype-progress-%.2f.png", Double(p))
            render(canvas, to: path)
            print("[capture] progress=\(p) extFactor=\(extFactor) heightConstraint=\(targetHeight) → \(path)")
        }
    }
}

@MainActor
private final class WaveR1StubDataSource: @preconcurrency TimelineDataSource {
    let count: Int
    let cellHeight: CGFloat
    init(count: Int, cellHeight: CGFloat) {
        self.count = count
        self.cellHeight = cellHeight
    }
    func numberOfCells(in canvas: TimelineCanvas) -> Int { count }
    func canvas(_ canvas: TimelineCanvas, configureCell cell: CellView, at index: Int) {
        cell.backgroundColor = .systemBackground
    }
    func canvas(_ canvas: TimelineCanvas, heightForCellAt index: Int) -> CGFloat { cellHeight }
}
