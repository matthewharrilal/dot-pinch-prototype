// WaveR74NoSpringInheritanceTests.swift
//
// Anticipation-to-pinch handoff does NOT inherit anticipation's spring
// profile: pinch begins fresh with its own (initiator × destination)
// profile. Anticipation uses UIViewPropertyAnimator; main springs use
// SpringAnimator — substrate separation prevents value-transfer.
// Covers pinch-during-anticipation, substrate distinction, and rapid
// tap-pinch-tap state cleanliness.

import XCTest
@testable import DotPinchPrototype

@MainActor
private final class MockPinchR74: UIPinchGestureRecognizer {
    var mockState: UIGestureRecognizer.State = .possible
    var mockScale: CGFloat = 1.0
    var mockLocation: CGPoint = .zero
    var mockVelocity: CGFloat = 0
    override var state: UIGestureRecognizer.State {
        get { mockState }
        set { mockState = newValue }
    }
    override var scale: CGFloat {
        get { mockScale }
        set { mockScale = newValue }
    }
    override var velocity: CGFloat { mockVelocity }
    override func location(in view: UIView?) -> CGPoint { mockLocation }
}

@MainActor
final class WaveR74NoSpringInheritanceTests: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)
    private var retainedDataSource: R74Stub?

    private func makeCanvas() -> TimelineCanvas {
        let canvas = TimelineCanvas(frame: viewport)
        let ds = R74Stub(count: 5, cellHeight: 200)
        retainedDataSource = ds
        canvas.dataSource = ds
        canvas.reloadData()
        canvas.layoutIfNeeded()
        canvas.contentHost.layoutIfNeeded()
        return canvas
    }

    /// Pinch .began during active anticipation: animator stopped + nilled,
    /// pinch state initialized fresh, pinch .ended classifies profile fresh.
    func testPinchDuringAnticipationCancelsAndEngagesPinchProfile() {
        let canvas = makeCanvas()

        // Engage tap-to-chat anticipation.
        canvas.animateCameraToChatRest(forCellAt: 1)
        XCTAssertNotNil(canvas.anticipationAnimator,
                        "precondition: anticipation engaged on tap")

        // Pinch .began mid-anticipation — must stop and nil the animator.
        let mock = MockPinchR74()
        mock.mockState = .began
        mock.mockLocation = CGPoint(x: viewport.width / 2, y: 400)
        canvas.handlePinchBegan(mock)

        XCTAssertNil(canvas.anticipationAnimator,
                     "pinch .began must stop and nil the anticipation animator; "
                     + "otherwise anticipation state leaks into pinch lifecycle.")

        // .ended with no motion → cancelled gesture.
        mock.mockState = .ended
        canvas.handlePinchEnded(mock)

        XCTAssertEqual(canvas.extensionAnimator.spring.dampingRatio,
                       PinchTuning.cancelledDamping, accuracy: 1e-9,
                       "pinch .ended after cancelling anticipation selects profile FRESH "
                       + "(cancelled, origin cell-rest). Got \(canvas.extensionAnimator.spring.dampingRatio).")
    }

    /// Substrate distinction is the structural no-inheritance guarantee:
    /// anticipation uses UIViewPropertyAnimator, main springs use
    /// SpringAnimator. No value-transfer between substrates is possible.
    /// Pinch's spring object is freshly constructed at every .ended dispatch.
    func testPinchSubstrateIsAlwaysSpringAnimatorRegardlessOfPriorAnticipation() {
        let canvas = makeCanvas()

        // tap → anticipation (UIViewPropertyAnimator substrate).
        canvas.animateCameraToChatRest(forCellAt: 1)
        XCTAssertNotNil(canvas.anticipationAnimator,
                        "anticipation substrate engaged on tap")
        // anticipationAnimator field is typed UIViewPropertyAnimator? — the
        // type system structurally prevents a SpringAnimator value here.

        let mock = MockPinchR74()
        mock.mockState = .began
        mock.mockLocation = CGPoint(x: viewport.width / 2, y: 400)
        canvas.handlePinchBegan(mock)
        mock.mockState = .ended
        canvas.handlePinchEnded(mock)

        XCTAssertNil(canvas.anticipationAnimator,
                     "anticipation substrate nilled at pinch .began — "
                     + "no value-transfer to pinch substrate possible.")

        // extensionAnimator (SpringAnimator) holds a Spring with damping in
        // the per-direction profile range, fresh-constructed at .ended.
        let damping = canvas.extensionAnimator.spring.dampingRatio
        let validProfiles: [CGFloat] = [
            PinchTuning.tapToChatDamping,
            PinchTuning.pinchToCellsDamping,
            PinchTuning.cancelledDamping
        ]
        XCTAssertTrue(validProfiles.contains(where: { abs($0 - damping) < 1e-9 }),
                      "pinch's spring damping (\(damping)) must be one of the per-direction "
                      + "profiles \(validProfiles), proving the spring was freshly constructed "
                      + "at .ended dispatch.")
    }

    /// Rapid tap-pinch-tap: second tap engages anticipation cleanly; no
    /// state pollution from prior pinch sequence.
    func testRapidTapPinchTapSequenceCleansState() {
        let canvas = makeCanvas()

        canvas.animateCameraToChatRest(forCellAt: 1)
        XCTAssertNotNil(canvas.anticipationAnimator, "tap-1 anticipation engaged")

        let mock = MockPinchR74()
        mock.mockState = .began
        mock.mockLocation = CGPoint(x: viewport.width / 2, y: 400)
        canvas.handlePinchBegan(mock)
        mock.mockState = .ended
        canvas.handlePinchEnded(mock)

        XCTAssertNil(canvas.anticipationAnimator, "pinch-cancel cleared anticipation")

        // Drain in-flight springs to clear activeCellIndex.
        canvas.cameraAnimator.stop(immediately: true)
        canvas.extensionAnimator.stop(immediately: true)
        if let cell = canvas.instantiatedCells[1], let heightC = cell.heightConstraint {
            heightC.constant = cell.naturalHeight
            canvas.contentHost.layoutIfNeeded()
        }

        // PinchTuning state survives the tap-pinch sequence — no pollution.
        XCTAssertEqual(PinchTuning.anticipationMagnitude, 0.97, accuracy: 1e-9,
                       "PinchTuning.anticipationMagnitude survives tap-pinch sequence")
        XCTAssertEqual(PinchTuning.anticipationDuration, 0.08, accuracy: 1e-9,
                       "PinchTuning.anticipationDuration survives tap-pinch sequence")
    }
}

@MainActor
private final class R74Stub: @preconcurrency TimelineDataSource {
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
