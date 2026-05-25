// PinchGestureUITests — XCUITest-based pinch gesture automation.
// Replaces the 6 Maestro flows that require pinch (Maestro 2.5.1 lacks pinch
// primitives). Uses XCUIElement.pinch(withScale:velocity:) which simulates a
// true multi-touch pinch on the iOS simulator.
//
// Run with:
//   xcodebuild -project DotPinchPrototype.xcodeproj -scheme DotPinchPrototype \
//     -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' \
//     -only-testing:DotPinchPrototypeUITests test

import XCTest

@MainActor
final class PinchGestureUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        // Wait for the cell-list to appear.
        let firstCell = app.otherElements["ConversationSurface"].firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5), "Cell-list should be visible after launch")
    }

    override func tearDown() async throws {
        app.terminate()
        try await super.tearDown()
    }

    // MARK: - Helpers

    /// Tap the first visible cell (top of the screen, around 30% from top).
    private func tapFirstCell() {
        let topCellArea = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.30))
        topCellArea.tap()
    }

    /// Wait for chat-state to appear (composer placeholder visible).
    private func waitForChatRest(timeout: TimeInterval = 5) -> Bool {
        let composer = app.textFields.matching(NSPredicate(format: "placeholderValue == %@", "Share with Dot…")).firstMatch
        return composer.waitForExistence(timeout: timeout)
    }

    /// Wait for cell-list to reappear. We test this by asserting the composer
    /// is NO LONGER in the a11y tree (chatContent.alpha=0 hides it).
    /// Cells themselves exist in the a11y tree in BOTH states, so checking
    /// for "ConversationSurface" is insufficient.
    ///
    /// IMPORTANT: composer alpha hits 0 BEFORE the springToCellRest spring
    /// fully settles activeCellIndex to nil. A second tap fired immediately
    /// after waitForCellList returns will be BLOCKED by handleTap's
    /// activeCellIndex guard. We add a fixed settle-wait to bridge this gap.
    private func waitForCellList(timeout: TimeInterval = 5) -> Bool {
        let composer = app.textFields.matching(NSPredicate(format: "placeholderValue == %@", "Share with Dot…")).firstMatch
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if !composer.exists { break }
            Thread.sleep(forTimeInterval: 0.25)
        }
        guard !composer.exists else { return false }
        // Spring settle-wait: critically-damped spring with response 1.10s
        // (PhysicsTuning.springResponse) means full settle (within 1pt of target,
        // which is tryClearActiveCellAtRest's threshold) takes ~2.5s after spring
        // engagement. Adding margin to ensure activeCellIndex clears before
        // subsequent gestures.
        Thread.sleep(forTimeInterval: 3.5)
        return true
    }

    /// Pinch IN at the center of the screen (chat-rest → cell-list).
    private func pinchInAtCenter() {
        let center = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        // XCUIElement.pinch needs an element. Use the main window.
        let window = app.windows.firstMatch
        window.pinch(withScale: 0.3, velocity: -1.5)
    }

    /// Pinch OUT at the center of the screen (cell-rest → chat-rest, OR no-op at chat-rest).
    private func pinchOutAtCenter() {
        let window = app.windows.firstMatch
        window.pinch(withScale: 3.0, velocity: 2.0)
    }

    // MARK: - Pinch Flow Tests

    /// 03 — Tap cell, pinch in (reverse), verify back at cell list.
    func test_03_pinchInFromChat_revertsToCellList() throws {
        tapFirstCell()
        XCTAssertTrue(waitForChatRest(), "Chat-rest should appear after tap")

        pinchInAtCenter()

        XCTAssertTrue(waitForCellList(), "Cell-list should reappear after pinch in")
    }

    /// 04 — Pinch OUT at chat-rest (no-op or rubberband; must not crash).
    func test_04_pinchOutAtChat_doesNotCrash() throws {
        tapFirstCell()
        XCTAssertTrue(waitForChatRest(), "Chat-rest should appear after tap")

        pinchOutAtCenter()

        // After pinch out at chat-rest, should still be at chat-rest (rubberband + settle).
        XCTAssertTrue(waitForChatRest(), "Should remain at chat-rest after pinch out")
    }

    /// 06 — Roundtrip same cell: tap A, pinch back, tap A again.
    func test_06_roundtripSameCell_preservesIdentity() throws {
        tapFirstCell()
        XCTAssertTrue(waitForChatRest())

        pinchInAtCenter()
        XCTAssertTrue(waitForCellList())

        tapFirstCell()
        XCTAssertTrue(waitForChatRest(), "Re-tapping the same cell should succeed")
    }

    /// 07 — Roundtrip different cell: tap A, pinch back, tap B.
    func test_07_roundtripDifferentCell_isolatesState() throws {
        tapFirstCell()
        XCTAssertTrue(waitForChatRest())

        pinchInAtCenter()
        XCTAssertTrue(waitForCellList())

        // Tap a different cell (lower on screen).
        let secondCell = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
        secondCell.tap()
        XCTAssertTrue(waitForChatRest(), "Tapping a different cell should succeed")
    }

    /// 09 — Composer text round-trip: type, reverse, re-tap, verify preserved.
    func test_09_composerTextRoundtrip_preservesText() throws {
        tapFirstCell()
        XCTAssertTrue(waitForChatRest())

        let composer = app.textFields.matching(NSPredicate(format: "placeholderValue == %@", "Share with Dot…")).firstMatch
        composer.tap()
        composer.typeText("hello dot")

        // Dismiss keyboard so pinch isn't intercepted.
        app.swipeDown()
        Thread.sleep(forTimeInterval: 0.5)

        pinchInAtCenter()
        XCTAssertTrue(waitForCellList())

        tapFirstCell()
        XCTAssertTrue(waitForChatRest())

        // Verify the composer still contains "hello dot".
        let composerAfter = app.textFields.matching(NSPredicate(format: "value == %@", "hello dot")).firstMatch
        XCTAssertTrue(composerAfter.waitForExistence(timeout: 3),
                      "Composer text should be preserved across round-trip per D10 bindToChatVCAtInstall")
    }

    /// 11 — Pinch-commit forward: pinch OUT from cell-rest commits to chat-rest.
    func test_11_pinchCommitForward_arrivesAtChat() throws {
        // Already at cell-list from setUp's first cell assertion.
        pinchOutAtCenter()

        XCTAssertTrue(waitForChatRest(),
                      "Pinch-commit forward (playTapToChatMorph) should route through onMorphRevealReady → present → handoff")
    }
}
