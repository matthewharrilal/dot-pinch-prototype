//
//  PinchDemoUITests.swift
//  DotPinchPrototypeUITests
//
//  XCUITest pinch demo — uses XCUIElement.pinch(withScale:velocity:) to drive
//  real multi-touch pinch gestures on the simulator. Watch the simulator window
//  while this runs.
//

import XCTest

final class PinchDemoUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testPinchSequence() throws {
        let app = XCUIApplication()
        app.launch()

        let surface = app.otherElements["ConversationSurface"]
        XCTAssertTrue(surface.waitForExistence(timeout: 5),
                      "ConversationSurface should appear on launch")

        // Let the user see the initial fullscreen state
        sleep(2)

        // Pinch IN — collapse to slot. Scale<1, velocity<0 = inward pinch.
        // Watch for: live morph, content reflow as text bounds narrow,
        // pink gradient exposed as surface shrinks.
        surface.pinch(withScale: 0.35, velocity: -1.8)
        sleep(2)

        // Pinch OUT — expand to fullscreen. Scale>1, velocity>0 = outward pinch.
        // Watch for: slot-anchored expansion (anchor at top-left, not centroid),
        // smooth spring on release with no dead frame.
        surface.pinch(withScale: 2.8, velocity: 1.8)
        sleep(2)

        // Repeat — pinch IN again with stronger velocity
        surface.pinch(withScale: 0.3, velocity: -2.5)
        sleep(2)

        // And OUT again
        surface.pinch(withScale: 3.0, velocity: 2.2)
        sleep(2)
    }
}
