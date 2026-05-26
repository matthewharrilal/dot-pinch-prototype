// NavSubstrateInvariantTests.swift
//
// Runtime canaries for the navigation substrate keystones K9-K14.
// Companion to CLAUDE.md Part 4 and HANDOFF-CHECKLIST.md §47.13 WAVE A.
//
// These tests enforce the substrate-level commitments introduced by the
// navigation pivot. Many are XCTSkip until WAVE A lands the prerequisites
// (Camera.scale field; ManualAnimationDriver; renamed cameraScaleAnimator).
//
// Test-file plan:
//   K9 (Camera value type)         — testable today via Camera.swift inspection
//   K10 (sublayerTransform sole)   — testable today via KVO canary
//   K11 (cell.height == naturalH)  — skip pending WAVE A (4 violation sites)
//   K12 (atomic handoff)           — skip pending CF-5 refactor
//   K13 (camera.scale = 1.0 fwd)   — skip pending Camera.scale field
//   K14 (pivot matrix order)       — skip pending applyCameraTransform refactor

import XCTest
import QuartzCore
@testable import DotPinchPrototype

@MainActor
final class NavSubstrateInvariantTests: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)

    // MARK: - K9: Camera value type carries (translation, scale)

    func test_K9_camera_carriesBothTranslationAndScale() throws {
        throw XCTSkip("Camera.scale field not yet added — pending WAVE A N20")
        // let c = Camera(translation: 100, scale: 2.5)
        // XCTAssertEqual(c.translation, 100)
        // XCTAssertEqual(c.scale, 2.5)
    }

    func test_K9_camera_identityIsTranslationZeroScaleOne() throws {
        throw XCTSkip("Camera.scale field not yet added — pending WAVE A N20")
        // XCTAssertEqual(Camera.identity.translation, 0)
        // XCTAssertEqual(Camera.identity.scale, 1)
    }

    func test_K9_camera_traps_onZeroScale() throws {
        throw XCTSkip("Requires PreconditionFailureCapture harness + Camera.scale field")
    }

    func test_K9_camera_traps_onNegativeScale() throws {
        throw XCTSkip("Requires PreconditionFailureCapture harness + Camera.scale field")
    }

    func test_K9_camera_traps_onNonFiniteScale() throws {
        throw XCTSkip("Requires PreconditionFailureCapture harness + Camera.scale field")
    }

    // MARK: - K10: sublayerTransform sole writer

    func test_K10_sublayerTransform_writtenOnlyByApplyCameraTransform() throws {
        throw XCTSkip("Requires setCamera-fanout instrumentation — pending WAVE A")
        // Will use KVO on contentHost.layer.sublayerTransform to count writes;
        // assert observed-write-count matches setCamera-call-count.
    }

    // MARK: - K11: cell.heightConstraint.constant == cell.naturalHeight

    func test_K11_cellHeight_constantThroughoutPinchSimulation() throws {
        throw XCTSkip("Pending WAVE A: 4 current main violation sites (TC:1246, 1373, 1556, MC:81) + ManualAnimationDriver")
    }

    func test_K11_normalizeStep_doesNotMutateCellHeight() throws {
        throw XCTSkip("Pending WAVE E: normalizeToChatRest still calls extendCellToChatRest in current main")
    }

    // MARK: - K12: Normalize-step substrate handoff is atomic

    func test_K12_normalizeHandoff_runsInSingleCATransaction() throws {
        throw XCTSkip("Requires CATransaction-boundary-capture harness + CF-5 refactor (N43)")
    }

    func test_K12_afterNormalize_transformIsIdentity_andSublayerTransformCarriesScale() throws {
        throw XCTSkip("Requires Camera.scale field + CF-5 refactor (N43)")
    }

    // MARK: - K13: Forward direction camera.scale = 1.0

    func test_K13_cameraScale_staysAt1DuringForwardMorph() throws {
        throw XCTSkip("Requires ManualAnimationDriver (N11) + Camera.scale field (N20)")
    }

    func test_K13_cameraScaleAnimator_isIdleDuringForwardMorph() throws {
        throw XCTSkip("Requires cameraScaleAnimator field (post-N1a rename)")
    }

    // MARK: - K14: Pivot matrix order

    func test_K14_matrixAtIdentityScale_reducesToTranslationOnly() throws {
        throw XCTSkip("Requires applyCameraTransform refactor (N1e) + Camera.scale field (N20)")
    }

    func test_K14_matrixAtScale2_pivotsAroundViewportCenter() throws {
        throw XCTSkip("Requires applyCameraTransform refactor (N1e) + Camera.scale field (N20)")
    }

    func test_K14_pagePoint_atCameraTranslation_mapsToViewportCenter() throws {
        throw XCTSkip("Requires scale-aware pagePoint(fromViewport:) helper (N5/N6) + Camera.scale field (N20)")
    }
}
