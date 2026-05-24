// WaveR44PerDirectionProfileTests.swift
//
// Per-direction spring profile selection (destination-matched, not
// gesture-direction): tapToChat (~0.87 damping), pinchToCells (~1.0),
// cancelled (~0.95). Both camera and extension animators must share
// identical Spring parameters within any animation. Verifies the
// SELECTION mechanism + parameter identity, not perceptual shape.

import XCTest
@testable import DotPinchPrototype

@MainActor
private final class MockPinchR44: UIPinchGestureRecognizer {
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
    override var velocity: CGFloat {
        mockVelocity
    }
    override func location(in view: UIView?) -> CGPoint {
        mockLocation
    }
}

@MainActor
final class WaveR44PerDirectionProfileTests: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)
    private var retainedDataSource: R44Stub?

    private func makeCanvas() -> TimelineCanvas {
        let canvas = TimelineCanvas(controller: AnimationController(), frame: viewport)
        let ds = R44Stub(count: 5, cellHeight: 200)
        retainedDataSource = ds
        canvas.dataSource = ds
        canvas.reloadData()
        canvas.layoutIfNeeded()
        canvas.contentHost.layoutIfNeeded()
        return canvas
    }

    /// Drive a pinch with explicit origin and endpoint extension factors:
    /// origin sets pinchInitialExtension via .began on a pre-set cell;
    /// endpoint sets currentFactor via heightConstraint.constant before .ended.
    private func runPinch(
        canvas: TimelineCanvas,
        anchorCellIndex: Int,
        originExtensionFactor: CGFloat,
        endExtensionFactor: CGFloat,
        centroidViewportY: CGFloat = 400,
        pinchVelocityScale: CGFloat = 0
    ) {
        guard let activeCell = canvas.instantiatedCells[anchorCellIndex],
              let heightC = activeCell.heightConstraint else {
            XCTFail("anchorCellIndex \(anchorCellIndex) not instantiated")
            return
        }
        let naturalH = activeCell.naturalHeight

        // Set origin height BEFORE .began so pinchInitialExtension captures it.
        heightC.constant = naturalH * originExtensionFactor
        canvas.contentHost.layoutIfNeeded()

        let mock = MockPinchR44()
        mock.mockState = .began
        mock.mockScale = 1.0
        mock.mockLocation = CGPoint(x: viewport.width / 2, y: centroidViewportY)
        canvas.handlePinchBegan(mock)

        // .changed at same centroid — no anchor-drift isolates the profile
        // selection from anchor-stability / velocity-capture effects.
        mock.mockState = .changed
        mock.mockScale = endExtensionFactor / originExtensionFactor
        mock.mockLocation = CGPoint(x: viewport.width / 2, y: centroidViewportY)
        canvas.handlePinchChanged(mock)
        // Force heightConstraint to the end factor (more robust than relying
        // on mockScale arithmetic through pinchInitialScale ratio).
        heightC.constant = naturalH * endExtensionFactor
        canvas.contentHost.layoutIfNeeded()

        mock.mockState = .ended
        mock.mockVelocity = pinchVelocityScale
        canvas.handlePinchEnded(mock)
    }

    /// Outward pinch from cell-rest committing to chat-rest — profile must
    /// be tapToChat (~0.87), NOT pinchToCells (~1.0). Catches the
    /// gesture-direction misclassification.
    func testPinchFromCellRestCommittingToChatRestUsesTapToChatProfile() {
        let canvas = makeCanvas()
        let chatRestFactor = canvas.bounds.height / 200  // ≈ 4.22

        // Origin: cell-rest (extensionFactor 1.0). Commit: above threshold
        // (chatRestFactor * 0.7 ≈ 2.95, comfortably above commitThreshold of
        // (1 + 4.22)/2 ≈ 2.61).
        runPinch(
            canvas: canvas,
            anchorCellIndex: 1,
            originExtensionFactor: 1.0,
            endExtensionFactor: chatRestFactor * 0.7
        )

        XCTAssertEqual(canvas.extensionAnimator.spring.dampingRatio,
                       PhysicsTuning.standard.tapToChatDamping, accuracy: 1e-9,
                       "pinch-from-cell-rest committing to chat-rest must use tapToChat profile, "
                       + "not pinchToCells.")
        XCTAssertEqual(canvas.cameraAnimator.dampingRatioForTesting,
                       PhysicsTuning.standard.tapToChatDamping, accuracy: 1e-9,
                       "camera animator must receive the same tapToChat profile as extension.")
    }

    /// Pinch from chat-rest committed inward to cell-rest → critically
    /// damped (~1.0).
    func testPinchFromChatRestCommittingToCellRestUsesPinchToCellsProfile() {
        let canvas = makeCanvas()
        let chatRestFactor = canvas.bounds.height / 200

        runPinch(
            canvas: canvas,
            anchorCellIndex: 1,
            originExtensionFactor: chatRestFactor,   // chat-rest origin
            endExtensionFactor: 1.5                  // below commit threshold → cellRest
        )

        XCTAssertEqual(canvas.extensionAnimator.spring.dampingRatio,
                       PhysicsTuning.standard.pinchToCellsDamping, accuracy: 1e-9,
                       "chat-rest → cell-rest commit uses critically-damped profile.")
        XCTAssertEqual(canvas.cameraAnimator.dampingRatioForTesting,
                       PhysicsTuning.standard.pinchToCellsDamping, accuracy: 1e-9,
                       "camera animator matches extension profile.")
    }

    /// Cancelled from cell-rest: partial pinch out, released below
    /// threshold → returns to cell-rest. Cancelled profile (~0.95).
    func testCancelledFromCellRestUsesCancelledProfile() {
        let canvas = makeCanvas()

        runPinch(
            canvas: canvas,
            anchorCellIndex: 1,
            originExtensionFactor: 1.0,
            endExtensionFactor: 1.5  // below threshold ≈ 2.61
        )

        XCTAssertEqual(canvas.extensionAnimator.spring.dampingRatio,
                       PhysicsTuning.standard.cancelledDamping, accuracy: 1e-9,
                       "cell-rest → partial → cell-rest uses cancelled profile (~0.95), "
                       + "NOT pinchToCells.")
        XCTAssertEqual(canvas.cameraAnimator.dampingRatioForTesting,
                       PhysicsTuning.standard.cancelledDamping, accuracy: 1e-9,
                       "camera animator matches extension profile.")
    }

    /// Cancelled applies to BOTH directions of return: partial pinch in
    /// from chat-rest, released above threshold → returns to chat-rest
    /// with cancelled profile (NOT tapToChat).
    func testCancelledFromChatRestUsesCancelledProfile() {
        let canvas = makeCanvas()
        let chatRestFactor = canvas.bounds.height / 200

        runPinch(
            canvas: canvas,
            anchorCellIndex: 1,
            originExtensionFactor: chatRestFactor,        // chat-rest origin
            endExtensionFactor: chatRestFactor * 0.8     // partial pinch in, still above threshold
        )

        XCTAssertEqual(canvas.extensionAnimator.spring.dampingRatio,
                       PhysicsTuning.standard.cancelledDamping, accuracy: 1e-9,
                       "chat-rest → partial → chat-rest uses cancelled (NOT tapToChat); "
                       + "cancelled is keyed off cancel-return, not destination identity.")
        XCTAssertEqual(canvas.cameraAnimator.dampingRatioForTesting,
                       PhysicsTuning.standard.cancelledDamping, accuracy: 1e-9,
                       "camera animator matches extension profile.")
    }

    /// For every direction, BOTH animators receive identical dampingRatio
    /// AND response. Split call sites would silently leave the two on
    /// different profiles.
    func testWithinAnimationParameterIdentityAcrossAllDirections() {
        let canvas = makeCanvas()
        let chatRestFactor = canvas.bounds.height / 200

        // tapToChat: cell-rest → chat-rest commit
        runPinch(canvas: canvas, anchorCellIndex: 1,
                 originExtensionFactor: 1.0,
                 endExtensionFactor: chatRestFactor * 0.7)
        XCTAssertEqual(canvas.extensionAnimator.spring.dampingRatio,
                       canvas.cameraAnimator.dampingRatioForTesting,
                       accuracy: 1e-9,
                       "tapToChat: both animators identical dampingRatio")
        XCTAssertEqual(canvas.extensionAnimator.spring.response,
                       canvas.cameraAnimator.responseForTesting,
                       accuracy: 1e-9,
                       "tapToChat: both animators identical response")

        // pinchToCells: chat-rest → cell-rest commit
        let canvas2 = makeCanvas()
        runPinch(canvas: canvas2, anchorCellIndex: 1,
                 originExtensionFactor: chatRestFactor,
                 endExtensionFactor: 1.5)
        XCTAssertEqual(canvas2.extensionAnimator.spring.dampingRatio,
                       canvas2.cameraAnimator.dampingRatioForTesting,
                       accuracy: 1e-9,
                       "pinchToCells: both animators identical dampingRatio")

        // cancelled
        let canvas3 = makeCanvas()
        runPinch(canvas: canvas3, anchorCellIndex: 1,
                 originExtensionFactor: 1.0,
                 endExtensionFactor: 1.5)
        XCTAssertEqual(canvas3.extensionAnimator.spring.dampingRatio,
                       canvas3.cameraAnimator.dampingRatioForTesting,
                       accuracy: 1e-9,
                       "cancelled: both animators identical dampingRatio")
    }

    /// Positive velocity at extension below the geometric midpoint must
    /// commit to chat-rest via velocity bias → tapToChat profile.
    /// velocityBias formula: (pinchInitialExtension × pinchVel / naturalH) × 0.15.
    /// At origin=1.0, naturalH=200, pinchVel=5 → bias = 0.75. weightedFactor =
    /// 2.4 + 0.75 = 3.15 > midpoint 2.61 → commit. Sign-flip would cancel.
    func testVelocityBiasCommitsAtBelowMidpoint() {
        let canvas = makeCanvas()
        let chatRestFactor = canvas.bounds.height / 200
        let commitMidpoint = (1.0 + chatRestFactor) / 2  // ≈ 2.61
        runPinch(
            canvas: canvas,
            anchorCellIndex: 1,
            originExtensionFactor: 1.0,
            endExtensionFactor: commitMidpoint - 0.21,  // 2.4
            pinchVelocityScale: 5.0
        )

        XCTAssertEqual(canvas.extensionAnimator.spring.dampingRatio,
                       PhysicsTuning.standard.tapToChatDamping, accuracy: 1e-9,
                       "positive velocity at below-midpoint extension must trigger velocity "
                       + "bias → commit → tapToChat profile. Sign-flip would cancel.")
    }
}

@MainActor
private final class R44Stub: @preconcurrency TimelineDataSource {
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
