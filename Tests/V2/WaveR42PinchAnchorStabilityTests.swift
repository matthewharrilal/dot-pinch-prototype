// WaveR42PinchAnchorStabilityTests.swift
//
// Pinch anchor stability: during a pinch, the page coordinate under the
// user's fingers at .began must remain mapped to the current centroid
// viewport-y throughout .changed events. Defeats the no-op by driving a
// finger-drift sequence (centroid changes per tick) — under steady fingers
// + symmetric extension, camera.translation is invariant regardless.
// Catches sign-flip bugs by parameterizing both anchor and active-cell
// offsets from viewport center.

import XCTest
@testable import DotPinchPrototype

/// Mock UIPinchGestureRecognizer with overridable state, scale, and centroid.
/// Bypasses @objc dispatch; tests call handlePinchBegan / handlePinchChanged
/// directly to exercise handler internals.
@MainActor
private final class MockPinch: UIPinchGestureRecognizer {
    var mockState: UIGestureRecognizer.State = .possible
    var mockScale: CGFloat = 1.0
    var mockLocation: CGPoint = .zero

    override var state: UIGestureRecognizer.State {
        get { mockState }
        set { mockState = newValue }
    }
    override var scale: CGFloat {
        get { mockScale }
        set { mockScale = newValue }
    }
    override func location(in view: UIView?) -> CGPoint {
        mockLocation
    }
}

@MainActor
final class WaveR42PinchAnchorStabilityTests: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)

    private var retainedDataSource: R42Stub?

    private func makeCanvas(cellCount: Int = 5, cellHeight: CGFloat = 200) -> TimelineCanvas {
        let canvas = TimelineCanvas(controller: AnimationController(), frame: viewport)
        let ds = R42Stub(count: cellCount, cellHeight: cellHeight)
        retainedDataSource = ds
        canvas.dataSource = ds
        canvas.reloadData()
        canvas.layoutIfNeeded()
        canvas.contentHost.layoutIfNeeded()
        return canvas
    }

    /// Sweep extensionFactor for `activeCell` while driving the canvas's
    /// pinch handlers with `MockPinch`. Returns viewport-y of the page
    /// anchor at each step.
    private func sweepAnchorViewportY(
        canvas: TimelineCanvas,
        anchorViewportY: CGFloat,
        extensionFactors: [CGFloat],
        centroidDriftPerStep: CGFloat = 0
    ) -> [(extensionFactor: CGFloat, centroidViewportY: CGFloat, anchorViewportY: CGFloat, cameraTranslation: CGFloat)] {
        let mock = MockPinch()
        mock.mockState = .began
        mock.mockScale = 1.0
        mock.mockLocation = CGPoint(x: viewport.width / 2, y: anchorViewportY)
        canvas.handlePinchBegan(mock)

        // Capture the anchor's page-y (what canvas captured at .began).
        let viewportCenter = CGPoint(x: canvas.bounds.midX, y: canvas.bounds.midY)
        let pageAnchorAtBegan = TimelineCanvas.pagePoint(
            fromViewport: CGPoint(x: viewport.width / 2, y: anchorViewportY),
            camera: canvas.camera,
            viewportCenter: viewportCenter
        )

        var samples: [(CGFloat, CGFloat, CGFloat, CGFloat)] = []
        var currentCentroid = anchorViewportY

        guard let activeIdx = canvas.activeCellIndex,
              let activeCell = canvas.instantiatedCells[activeIdx],
              let heightC = activeCell.heightConstraint else {
            return []
        }
        let naturalH = activeCell.naturalHeight

        mock.mockState = .changed
        for f in extensionFactors {
            currentCentroid += centroidDriftPerStep
            mock.mockLocation = CGPoint(x: viewport.width / 2, y: currentCentroid)
            // Drive height directly — bypassing scale arithmetic isolates
            // the camera-write under test.
            heightC.constant = naturalH * f
            canvas.contentHost.layoutIfNeeded()
            canvas.handlePinchChanged(mock)

            let anchorViewport = TimelineCanvas.viewportPoint(
                fromPage: CGPoint(x: 0, y: pageAnchorAtBegan.y),
                camera: canvas.camera,
                viewportCenter: viewportCenter
            )
            samples.append((f, currentCentroid, anchorViewport.y, canvas.camera.translation))
        }
        return samples
    }

    /// After each .changed write, viewportPointFromPagePoint(pinchAnchorPageY)
    /// must equal the current centroid viewport-y. Anchor + active cell are
    /// both offset from viewport center to defeat the symmetric blind spot.
    /// Anchor at viewport-y=600 sits 178pt below viewport center (422);
    /// active cell 2 midY (page-y=548) sits 126pt below.
    func testAnchorViewportPositionStableUnderFingerDrift() {
        let canvas = makeCanvas(cellCount: 5, cellHeight: 200)
        let anchorY: CGFloat = 600

        let extensionFactors: [CGFloat] = [1.0, 1.25, 1.50, 2.0, 3.0]
        let driftPerStep: CGFloat = 5.0  // finger drifts 5pt down per .changed.

        let samples = sweepAnchorViewportY(
            canvas: canvas,
            anchorViewportY: anchorY,
            extensionFactors: extensionFactors,
            centroidDriftPerStep: driftPerStep
        )

        XCTAssertEqual(samples.count, extensionFactors.count, "all samples produced")

        // Anchor viewport-y must equal the current centroid viewport-y.
        for s in samples {
            XCTAssertEqual(s.anchorViewportY, s.centroidViewportY, accuracy: 1.0,
                           "anchor invariant @ extensionFactor=\(s.extensionFactor): "
                           + "anchor viewport-y (\(s.anchorViewportY)) must equal current centroid "
                           + "viewport-y (\(s.centroidViewportY)) within 1pt. Drift indicates "
                           + "sign-flip or formula error.")
        }
    }

    /// Camera.translation must follow centroid drift. The no-op (camera not
    /// written) would freeze translation; this test fails the no-op by
    /// asserting translation changes proportionally with centroid drift.
    func testCameraTranslationFollowsCentroidDrift() {
        let canvas = makeCanvas(cellCount: 5, cellHeight: 200)
        let anchorY: CGFloat = 600
        let extensionFactors: [CGFloat] = [1.0, 1.5, 2.0]
        let driftPerStep: CGFloat = 10.0  // drift 10pt per .changed

        let samples = sweepAnchorViewportY(
            canvas: canvas,
            anchorViewportY: anchorY,
            extensionFactors: extensionFactors,
            centroidDriftPerStep: driftPerStep
        )

        XCTAssertEqual(samples.count, extensionFactors.count)

        // camera = pinchAnchorPageY + viewport.height/2 - currentCentroidY,
        // so ΔcameraTranslation between consecutive samples ≈ -driftPerStep.
        for i in 1..<samples.count {
            let dCamera = samples[i].cameraTranslation - samples[i - 1].cameraTranslation
            XCTAssertEqual(dCamera, -driftPerStep, accuracy: 0.5,
                           "camera.translation must follow centroid drift. "
                           + "Between extensionFactor=\(samples[i-1].extensionFactor) and "
                           + "\(samples[i].extensionFactor): expected ΔcameraTranslation ≈ "
                           + "\(-driftPerStep), got \(dCamera). Zero delta = no-op.")
        }
    }

    /// With steady fingers, camera.translation is invariant across the
    /// extensionFactor sweep — symmetric extension + constant centroid →
    /// formula is constant. Verifies the write doesn't INTRODUCE drift.
    func testCameraTranslationConstantUnderSteadyFingers() {
        let canvas = makeCanvas(cellCount: 5, cellHeight: 200)
        let anchorY: CGFloat = 600
        let extensionFactors: [CGFloat] = [1.0, 1.25, 1.50, 2.0]

        let samples = sweepAnchorViewportY(
            canvas: canvas,
            anchorViewportY: anchorY,
            extensionFactors: extensionFactors,
            centroidDriftPerStep: 0.0
        )

        XCTAssertGreaterThan(samples.count, 1)
        let firstCamera = samples[0].cameraTranslation
        for s in samples {
            XCTAssertEqual(s.cameraTranslation, firstCamera, accuracy: 0.5,
                           "with steady fingers, camera.translation is invariant across "
                           + "extensionFactor sweep. Got \(s.cameraTranslation) at f=\(s.extensionFactor) "
                           + "vs first \(firstCamera).")
        }
    }

    /// lastCellRestScrollY must NOT be poisoned by .changed camera writes
    /// during pinch — guarded by activeCellIndex == nil check.
    func testLastCellRestScrollYUnchangedDuringPinch() {
        let canvas = makeCanvas(cellCount: 5, cellHeight: 200)
        // Non-zero scrollY so the guard's effect is observable.
        canvas.setCamera(Camera(translation: 500.0))
        let preScrollY = canvas.lastCellRestScrollY

        _ = sweepAnchorViewportY(
            canvas: canvas,
            anchorViewportY: 600,
            extensionFactors: [1.0, 1.5, 2.0, 3.0],
            centroidDriftPerStep: 15.0
        )

        XCTAssertEqual(canvas.lastCellRestScrollY, preScrollY,
                       "lastCellRestScrollY must NOT be modified by camera writes during pinch. "
                       + "Got \(canvas.lastCellRestScrollY); expected unchanged from pre-pinch \(preScrollY).")
    }
}

@MainActor
private final class R42Stub: @preconcurrency TimelineDataSource {
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
