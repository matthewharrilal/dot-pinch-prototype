// WaveR43TranslationVelocityCaptureTests.swift
//
// Pinch translation velocity at .ended is computed from centroid samples
// across .changed → .ended and passed to the camera spring. Sign convention:
// camera = const - centroidY ⇒ d(translation)/dt = -d(centroidY)/dt.
// Covers: finger down (negative velocity), finger up (positive), stationary
// (floors to 0), and the .began → .ended with no .changed path (dt-collapse).

import XCTest
@testable import DotPinchPrototype

@MainActor
private final class MockPinchR43: UIPinchGestureRecognizer {
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
final class WaveR43TranslationVelocityCaptureTests: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)

    private var retainedDataSource: R43Stub?

    private func makeCanvas() -> TimelineCanvas {
        let canvas = TimelineCanvas(controller: AnimationController(), frame: viewport)
        let ds = R43Stub(count: 5, cellHeight: 200)
        retainedDataSource = ds
        canvas.dataSource = ds
        canvas.reloadData()
        canvas.layoutIfNeeded()
        canvas.contentHost.layoutIfNeeded()
        return canvas
    }

    /// Drive a synthetic pinch with real elapsed time between events —
    /// CACurrentMediaTime-based velocity computation needs non-zero dt.
    private func runPinch(
        canvas: TimelineCanvas,
        startCentroidY: CGFloat,
        endCentroidY: CGFloat,
        sleepBetweenChangedAndEnded: TimeInterval = 0.050,
        sleepBetweenBeganAndChanged: TimeInterval = 0.050
    ) {
        let mock = MockPinchR43()
        mock.mockState = .began
        mock.mockScale = 1.0
        mock.mockLocation = CGPoint(x: viewport.width / 2, y: startCentroidY)
        canvas.handlePinchBegan(mock)

        // .changed at startCentroidY (no drift yet), so velocity is computed
        // from the .changed → .ended interval that follows.
        Thread.sleep(forTimeInterval: sleepBetweenBeganAndChanged)
        mock.mockState = .changed
        mock.mockScale = 1.2
        mock.mockLocation = CGPoint(x: viewport.width / 2, y: startCentroidY)
        canvas.handlePinchChanged(mock)

        // Drift to endCentroidY over `sleepBetweenChangedAndEnded`, then .ended.
        Thread.sleep(forTimeInterval: sleepBetweenChangedAndEnded)
        mock.mockState = .ended
        mock.mockLocation = CGPoint(x: viewport.width / 2, y: endCentroidY)
        canvas.handlePinchEnded(mock)
    }

    /// .began → .ended with NO .changed (dt-collapse path).
    private func runPinchNoChanged(canvas: TimelineCanvas, centroidY: CGFloat) {
        let mock = MockPinchR43()
        mock.mockState = .began
        mock.mockScale = 1.0
        mock.mockLocation = CGPoint(x: viewport.width / 2, y: centroidY)
        canvas.handlePinchBegan(mock)
        mock.mockState = .ended
        canvas.handlePinchEnded(mock)
    }

    /// Finger DOWN drift → NEGATIVE translation velocity on cameraAnimator.
    func testFingerDownDriftProducesNegativeTranslationVelocity() {
        let canvas = makeCanvas()
        let startY: CGFloat = 400
        let driftPx: CGFloat = 30  // finger drifts DOWN 30pt
        let dt: TimeInterval = 0.050  // over 50ms

        runPinch(
            canvas: canvas,
            startCentroidY: startY,
            endCentroidY: startY + driftPx,
            sleepBetweenChangedAndEnded: dt
        )

        let captured = canvas.cameraAnimator.lastAnimateVelocityForTesting
        XCTAssertLessThan(captured, 0,
                          "finger drift DOWN must produce NEGATIVE translationVelocity. "
                          + "Got \(captured).")

        // Expected ≈ -drift/dt = -30/0.050 = -600 pt/s; loose tolerance for
        // clock variance. Floor is 1.0 pt/s; upper bound for jitter ≈ 2000.
        XCTAssertGreaterThan(abs(captured), 100,
                             "translationVelocity magnitude must be non-trivial under known drift. "
                             + "Got |v|=\(abs(captured)) pt/s.")
        XCTAssertLessThan(abs(captured), 2000,
                          "translationVelocity magnitude bounded by clock variance. "
                          + "Got |v|=\(abs(captured)) pt/s.")
    }

    func testFingerUpDriftProducesPositiveTranslationVelocity() {
        let canvas = makeCanvas()
        let startY: CGFloat = 600
        let driftPx: CGFloat = 30  // finger drifts UP 30pt (y decreases)

        runPinch(
            canvas: canvas,
            startCentroidY: startY,
            endCentroidY: startY - driftPx,
            sleepBetweenChangedAndEnded: 0.050
        )

        let captured = canvas.cameraAnimator.lastAnimateVelocityForTesting
        XCTAssertGreaterThan(captured, 0,
                             "finger drift UP must produce POSITIVE translationVelocity. "
                             + "Got \(captured).")
    }

    /// Stationary fingers → velocity floors to 0 via CameraAnimator.safeVel.
    func testStationaryFingersProduceZeroTranslationVelocity() {
        let canvas = makeCanvas()
        runPinch(
            canvas: canvas,
            startCentroidY: 500,
            endCentroidY: 500,
            sleepBetweenChangedAndEnded: 0.050
        )

        let captured = canvas.cameraAnimator.lastAnimateVelocityForTesting
        // safeVel floors |v| < 1pt/s to 0.
        XCTAssertEqual(captured, 0, accuracy: 1.0,
                       "stationary fingers must floor velocity to 0. Got \(captured).")
    }

    /// .began → .ended with no .changed → velocity floors to 0 (via dt-guard
    /// or safeVel floor downstream).
    func testNoChangedTickProducesZeroVelocity() {
        let canvas = makeCanvas()
        runPinchNoChanged(canvas: canvas, centroidY: 500)

        let captured = canvas.cameraAnimator.lastAnimateVelocityForTesting
        XCTAssertEqual(captured, 0, accuracy: 1.0,
                       ".began → .ended with no .changed must produce 0 velocity. "
                       + "Got \(captured).")
    }
}

@MainActor
private final class R43Stub: @preconcurrency TimelineDataSource {
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
