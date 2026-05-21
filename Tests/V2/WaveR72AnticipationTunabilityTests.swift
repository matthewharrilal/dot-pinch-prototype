// WaveR72AnticipationTunabilityTests.swift
//
// Anticipation tunables: PinchTuning.anticipationMagnitude in [0.95, 0.99]
// and anticipationDuration in [0.05, 0.10] are enforced at the setter.
// Anticipation is TAP-ONLY — the pinch path must not invoke the animator.

import XCTest
@testable import DotPinchPrototype

@MainActor
private final class MockTapR72: UITapGestureRecognizer {
    var mockState: UIGestureRecognizer.State = .recognized
    var mockLocation: CGPoint = .zero
    override var state: UIGestureRecognizer.State {
        get { mockState }
        set { mockState = newValue }
    }
    override func location(in view: UIView?) -> CGPoint { mockLocation }
}

@MainActor
private final class MockPinchR72: UIPinchGestureRecognizer {
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
    override func location(in view: UIView?) -> CGPoint { mockLocation }
}

@MainActor
final class WaveR72AnticipationTunabilityTests: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)
    private var retainedDataSource: R72Stub?

    override func tearDown() {
        // Restore defaults so other suites see baseline values.
        PinchTuning.anticipationMagnitude = 0.97
        PinchTuning.anticipationDuration = 0.08
        super.tearDown()
    }

    private func makeCanvas() -> TimelineCanvas {
        let canvas = TimelineCanvas(frame: viewport)
        let ds = R72Stub(count: 5, cellHeight: 200)
        retainedDataSource = ds
        canvas.dataSource = ds
        canvas.reloadData()
        canvas.layoutIfNeeded()
        canvas.contentHost.layoutIfNeeded()
        return canvas
    }

    /// Setting anticipationMagnitude inside [0.95, 0.99] produces an animator
    /// whose target heightConstraint = naturalHeight × the new magnitude.
    /// Uses finishAnimation(at:) to deterministically advance past the 80ms
    /// ease-in-out without real-time waiting.
    func testTunableMagnitudeAppliesAtNextAnticipation() {
        let canvas = makeCanvas()
        PinchTuning.anticipationMagnitude = 0.96

        guard let cell = canvas.instantiatedCells[1],
              let heightC = cell.heightConstraint else {
            XCTFail("cell 1 not instantiated"); return
        }
        let naturalH = cell.naturalHeight

        canvas.animateCameraToChatRest(forCellAt: 1)

        guard let animator = canvas.anticipationAnimator else {
            XCTFail("anticipation animator must engage on tap-to-chat path"); return
        }
        // finishAnimation(at:) requires a STOPPED animator; stop first.
        animator.stopAnimation(false)
        animator.finishAnimation(at: .end)
        canvas.contentHost.layoutIfNeeded()

        let expected = naturalH * 0.96
        XCTAssertEqual(heightC.constant, expected, accuracy: 0.5,
                       "anticipationMagnitude = 0.96 must produce heightConstraint "
                       + "= naturalH × 0.96. Got \(heightC.constant), expected \(expected).")
    }

    /// Closed-interval bound [0.95, 0.99] — setter precondition uses `>=` / `<=`.
    /// Both endpoints must succeed without crashing.
    func testBoundEndpointsAccepted() {
        PinchTuning.anticipationMagnitude = 0.95
        XCTAssertEqual(PinchTuning.anticipationMagnitude, 0.95, accuracy: 1e-9)

        PinchTuning.anticipationMagnitude = 0.99
        XCTAssertEqual(PinchTuning.anticipationMagnitude, 0.99, accuracy: 1e-9)

        PinchTuning.anticipationDuration = 0.05
        XCTAssertEqual(PinchTuning.anticipationDuration, 0.05, accuracy: 1e-9)

        PinchTuning.anticipationDuration = 0.10
        XCTAssertEqual(PinchTuning.anticipationDuration, 0.10, accuracy: 1e-9)
    }

    /// Anticipation is TAP-ONLY; pinch must NEVER invoke the animator.
    /// Verifies the tunable (set to a non-default value) is not reachable
    /// from the pinch path.
    func testPinchPathDoesNotInvokeAnticipationAnimator() {
        let canvas = makeCanvas()
        PinchTuning.anticipationMagnitude = 0.96  // non-default

        let mock = MockPinchR72()
        mock.mockState = .began
        mock.mockScale = 1.0
        mock.mockLocation = CGPoint(x: viewport.width / 2, y: 400)
        canvas.handlePinchBegan(mock)

        mock.mockState = .changed
        mock.mockScale = 1.5
        canvas.handlePinchChanged(mock)

        mock.mockState = .ended
        canvas.handlePinchEnded(mock)

        XCTAssertNil(canvas.anticipationAnimator,
                     "anticipationAnimator must remain nil throughout pinch lifecycle. "
                     + "Got \(String(describing: canvas.anticipationAnimator)).")

        // If anticipation had fired, heightConstraint would have briefly hit
        // 0.96 × naturalH during contraction. Since pinch goes monotonically
        // out then back, height < naturalH would only occur via anticipation.
        guard let cell = canvas.instantiatedCells[1],
              let heightC = cell.heightConstraint else {
            XCTFail("cell 1 not instantiated"); return
        }
        XCTAssertGreaterThanOrEqual(heightC.constant, cell.naturalHeight * 0.99,
                                    "no contraction below naturalHeight during pinch")
    }
}

@MainActor
private final class R72Stub: @preconcurrency TimelineDataSource {
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
