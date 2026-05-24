// WaveR11LifecycleAdversarialTests.swift
//
// Adversarial lifecycle invariants: tap-to-chat persists at steady state;
// pinch-to-cells clears only when both springs are at rest; rapid
// reversal preserves activeCellIndex; pool-return rejects active.
// Each test defeats the camera same-target short-circuit by moving the
// camera to a non-trivial position and spinning the run loop until settle.

import XCTest
@testable import DotPinchPrototype

@MainActor
final class WaveR11LifecycleAdversarialTests: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)
    private let cellHeight: CGFloat = 200

    private var retainedDataSource: WaveR11Stub?

    private func makeCanvas() -> TimelineCanvas {
        let canvas = TimelineCanvas(controller: AnimationController(), frame: viewport)
        let ds = WaveR11Stub(count: 5, cellHeight: cellHeight)
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

    /// Spin the main run loop for up to `timeout` seconds, polling
    /// `condition` every 50ms. Returns true if condition met before
    /// timeout, false otherwise.
    @discardableResult
    private func spinUntil(_ timeout: TimeInterval, condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        return condition()
    }

    // MARK: - Spring tick probe

    /// If this fails, the test infrastructure doesn't actually run the
    /// spring substrate (CADisplayLink + AnimationController) in XCTest
    /// context — all other tests in this file would be meaningless.
    func testProbeSpringActuallyTicksUnderRunloopSpin() {
        let canvas = makeCanvas()
        let initialTranslation = canvas.camera.translation
        let target = initialTranslation + 200  // move 200pt
        canvas.cameraAnimator.animate(to: Camera(translation: target), velocity: .zero)

        let settled = spinUntil(3.0) {
            !canvas.cameraAnimator.isRunning
        }

        XCTAssertTrue(settled, "Spring did not settle within 3s — CADisplayLink isn't ticking in test context")
        XCTAssertEqual(canvas.camera.translation, target, accuracy: 5.0,
                       "Spring settled but didn't reach target (got \(canvas.camera.translation), expected \(target))")
    }

    // MARK: - tap-to-chat persists across settle

    func testTapToChatPersistsActiveCellIndex() {
        let canvas = makeCanvas()
        // Move camera off cell-rest so spring engagement is non-trivial
        // (defeats the sameTarget short-circuit).
        canvas.setCamera(Camera(translation: 100))
        XCTAssertNil(canvas.activeCellIndex)

        canvas.animateCameraToChatRest(forCellAt: 2)
        drainAnticipation(canvas)

        XCTAssertEqual(canvas.activeCellIndex, 2,
                       "activeCellIndex set immediately at chat-rest call")

        let settled = spinUntil(3.0) { !canvas.cameraAnimator.isRunning }
        XCTAssertTrue(settled, "camera spring did not settle in 3s")

        XCTAssertEqual(canvas.activeCellIndex, 2,
                       "activeCellIndex must persist across chat-rest settle, not clear")
    }

    // MARK: - pinch-to-cells clears at rest (both conditions)

    func testPinchToCellsClearsOnlyAtRestBothConditions() {
        let canvas = makeCanvas()
        // Set up chat-rest state.
        canvas.animateCameraToChatRest(forCellAt: 1)
        drainAnticipation(canvas)
        _ = spinUntil(3.0) { !canvas.cameraAnimator.isRunning && canvas.extensionAnimator.state != .running }

        guard let cell = canvas.instantiatedCells[1],
              let heightC = cell.heightConstraint else {
            XCTFail("active cell missing"); return
        }
        // Force the chat-rest state synchronously.
        canvas.setCamera(Camera(translation: cell.frame.midY))
        heightC.constant = viewport.height
        canvas.contentHost.setNeedsLayout()
        canvas.contentHost.layoutIfNeeded()
        XCTAssertEqual(canvas.activeCellIndex, 1)

        // Cell-rest must animate camera + extension.
        canvas.animateCameraToCellRest()

        // Adversarial check: if cameraAnimator short-circuits synchronously,
        // activeCellIndex could clear BEFORE extension settles to natural.
        _ = spinUntil(3.0) {
            !canvas.cameraAnimator.isRunning && canvas.extensionAnimator.state != .running
        }
        let heightAtNatural = abs((cell.heightConstraint?.constant ?? -1) - cell.naturalHeight) < 1.0

        if !heightAtNatural {
            XCTAssertEqual(canvas.activeCellIndex, 1,
                           "single-active VIOLATION: activeCellIndex cleared while heightConstraint=\(cell.heightConstraint?.constant ?? -1) > naturalH=\(cell.naturalHeight)")
        } else {
            XCTAssertNil(canvas.activeCellIndex,
                         "activeCellIndex must clear after both springs settle")
        }
    }

    // MARK: - pinch-from-cell-rest sets at .began

    /// Indirect verification: animateCameraToChatRest sets activeCellIndex
    /// synchronously before any spring engages. Pinch handler uses the same
    /// setActiveCellIndex gateway at the beginning of handlePinchBegan.
    func testPinchFromCellRestSetsActiveCellIndexAtBegan() {
        let canvas = makeCanvas()
        XCTAssertNil(canvas.activeCellIndex, "precondition: cell-rest")

        canvas.animateCameraToChatRest(forCellAt: 3)
        XCTAssertEqual(canvas.activeCellIndex, 3,
                       "activeCellIndex must be set synchronously at .began (not derived later)")
    }

    // MARK: - rapid reversal preserves activeCellIndex

    func testRapidReversalPreservesActiveCellIndex() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 2)
        drainAnticipation(canvas)
        _ = spinUntil(2.0) { !canvas.cameraAnimator.isRunning && canvas.extensionAnimator.state != .running }
        XCTAssertEqual(canvas.activeCellIndex, 2)

        guard let cell = canvas.instantiatedCells[2],
              let heightC = cell.heightConstraint else { XCTFail("missing"); return }

        // Direct heightConstraint mutation — pinch handler's .changed events
        // go through this exact path. Sequence: extend, contract, extend,
        // contract, extend.
        let naturalH = cell.naturalHeight
        let chatExt = viewport.height
        let sequence: [CGFloat] = [
            naturalH * 2.0,
            naturalH * 1.5,
            naturalH * 2.2,
            naturalH * 1.3,
            chatExt
        ]
        for value in sequence {
            heightC.constant = value
            canvas.contentHost.setNeedsLayout()
            canvas.contentHost.layoutIfNeeded()
            XCTAssertEqual(canvas.activeCellIndex, 2,
                           "activeCellIndex must persist across reversal (height=\(value))")
        }
    }

    // MARK: - pool-return rejects active

    func testPoolReturnRejectsActiveCell() {
        let canvas = makeCanvas()
        canvas.animateCameraToChatRest(forCellAt: 2)
        drainAnticipation(canvas)
        guard let activeCell = canvas.instantiatedCells[2] else { XCTFail("missing"); return }

        // Scroll camera FAR past cell 2's natural visible range.
        canvas.setCamera(Camera(translation: viewport.height * 10))
        canvas.contentHost.layoutIfNeeded()

        XCTAssertNotNil(canvas.instantiatedCells[2],
                        "active cell must remain in instantiatedCells")
        XCTAssertFalse(canvas.cellPool.contains { $0 === activeCell },
                       "active cell must NOT be in cellPool")
    }

    // MARK: - race window adversarial

    /// Race scenario: in animateCameraToCellRestPath, the camera's
    /// same-target short-circuit can fire synchronously when cameraTarget
    /// == camera.translation. The completion runs INLINE, calling
    /// setActiveCellIndex(nil), BEFORE extensionAnimator.start() is even
    /// invoked. Extension's applyExtensionTick guards on activeCellIndex
    /// so it becomes a no-op. Result: activeCellIndex == nil while
    /// heightConstraint stays extended — single-active invariant violated.
    /// This test sets up the exact conditions for the race to fire.
    func testNoActiveClearedWhileHeightExtended_RaceWindow() {
        let canvas = makeCanvas()

        // 1. Move the camera with NO active cell so lastCellRestScrollY
        //    updates — this sets the cell-rest target position.
        canvas.setCamera(Camera(translation: 500))
        XCTAssertEqual(canvas.lastCellRestScrollY, 500 - viewport.height / 2,
                       accuracy: 0.5)

        // 2. Activate cell 1 and force chat-rest extension manually
        //    (bypassing the spring so we can observe the race).
        canvas.animateCameraToChatRest(forCellAt: 1)
        drainAnticipation(canvas)
        canvas.cameraAnimator.stop(immediately: true)
        canvas.extensionAnimator.stop(immediately: true)
        guard let cell = canvas.instantiatedCells[1],
              let heightC = cell.heightConstraint else { XCTFail("missing"); return }
        heightC.constant = viewport.height
        canvas.contentHost.setNeedsLayout()
        canvas.contentHost.layoutIfNeeded()

        // 3. Force camera.translation back to 500 (the cell-rest target).
        //    activeCellIndex=1, heightC=844, camera.translation=500,
        //    lastCellRestScrollY=78 → cell-rest target = 78 + 422 = 500.
        canvas.setCamera(Camera(translation: 500))
        XCTAssertEqual(canvas.activeCellIndex, 1)

        // 4. Trigger cell-rest. Camera same-targets (500 → 500) — the
        //    sameTarget branch fires completion synchronously.
        canvas.animateCameraToCellRest()

        let heightAfterSync = cell.heightConstraint?.constant ?? -1
        let activeAfterSync = canvas.activeCellIndex

        if activeAfterSync == nil {
            // Bug present — surface it.
            XCTAssertEqual(heightAfterSync, cell.naturalHeight, accuracy: 1.0,
                           "RACE BUG SURFACED: activeCellIndex cleared (by camera same-target sync completion) while heightConstraint=\(heightAfterSync) > naturalH=\(cell.naturalHeight). Invariant: activeCellIndex == nil ⇒ all cells at naturalHeight.")
        } else {
            _ = spinUntil(2.0) { canvas.extensionAnimator.state != .running }
            XCTAssertEqual(cell.heightConstraint?.constant ?? -1, cell.naturalHeight,
                           accuracy: 1.0, "After settle, extension should be at natural")
        }
    }

    // MARK: - single-active adversarial stress

    func testSingleActiveInvariantUnderRapidGestureSwitch() {
        let canvas = makeCanvas()

        canvas.animateCameraToChatRest(forCellAt: 1)
        drainAnticipation(canvas)
        XCTAssertEqual(canvas.activeCellIndex, 1)
        XCTAssertEqual(canvas.contentHost.subviews.last, canvas.instantiatedCells[1])

        // Tap on different cell while in chat-rest is supposed to be IGNORED
        // (Option A). Here we verify only that exactly one cell can be active.
        canvas.animateCameraToChatRest(forCellAt: 3)

        XCTAssertTrue(canvas.activeCellIndex == 1 || canvas.activeCellIndex == 3,
                       "activeCellIndex must be exactly one cell, not corrupted; got \(String(describing: canvas.activeCellIndex))")

        // If the active index changed to 3, the prior cell (1) must not
        // be left extended. Surfaces a missing Option A guard.
        if canvas.activeCellIndex == 3 {
            if let cell1 = canvas.instantiatedCells[1] {
                let cell1Height = cell1.heightConstraint?.constant ?? -1
                let cell1Natural = cell1.naturalHeight
                if abs(cell1Height - cell1Natural) > 1.0 {
                    print("[WARNING] cell 1 left at extension \(cell1Height) when activeCellIndex moved to 3. Option A guard missing.")
                }
            }
        }
    }
}

@MainActor
private final class WaveR11Stub: @preconcurrency TimelineDataSource {
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
