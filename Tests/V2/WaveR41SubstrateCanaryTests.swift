// WaveR41SubstrateCanaryTests.swift
//
// Substrate canary: cameraAnimator and extensionAnimator MUST share the
// same AnimationController instance. Shared controller → both animators
// tick from the same CADisplayLink callback → progress is synchronous by
// construction. Splitting the controllers breaks the sync guarantee.

import XCTest
@testable import DotPinchPrototype

@MainActor
final class WaveR41SubstrateCanaryTests: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)

    func testCameraAndExtensionAnimatorsShareSameAnimationController() {
        let canvas = TimelineCanvas(controller: AnimationController(), frame: viewport)

        let cameraController = canvas.cameraAnimator.animationControllerIdentityForTesting
        let extensionController = canvas.extensionAnimator.animationControllerIdentityForTesting

        XCTAssertNotNil(cameraController,
                        "cameraAnimator must have a live AnimationController reference")
        XCTAssertNotNil(extensionController,
                        "extensionAnimator must have a live AnimationController reference")
        XCTAssertTrue(cameraController === extensionController,
                      "cameraAnimator.controller (\(String(describing: cameraController))) "
                      + "MUST be the same instance as extensionAnimator.controller "
                      + "(\(String(describing: extensionController))). Progress sync depends on "
                      + "both animators ticking from the same CADisplayLink callback.")
    }
}
