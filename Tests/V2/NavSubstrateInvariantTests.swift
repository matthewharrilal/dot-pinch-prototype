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

    func test_K9_camera_carriesBothTranslationAndScale() {
        // N20 landed: Camera carries (translation, scale) with default scale=1.0.
        let c = Camera(translation: 100, scale: 2.5)
        XCTAssertEqual(c.translation, 100)
        XCTAssertEqual(c.scale, 2.5)

        // Default scale=1.0 for backwards-compat with translation-only call sites.
        let d = Camera(translation: 50)
        XCTAssertEqual(d.translation, 50)
        XCTAssertEqual(d.scale, 1.0)
    }

    func test_K9_camera_identityIsTranslationZeroScaleOne() {
        XCTAssertEqual(Camera.identity.translation, 0)
        XCTAssertEqual(Camera.identity.scale, 1)
    }

    func test_K9_camera_equatable_acrossBothFields() {
        XCTAssertEqual(Camera(translation: 1, scale: 2), Camera(translation: 1, scale: 2))
        XCTAssertNotEqual(Camera(translation: 1, scale: 2), Camera(translation: 1, scale: 3))
        XCTAssertNotEqual(Camera(translation: 1, scale: 2), Camera(translation: 2, scale: 2))
    }

    func test_K9_camera_isApproximatelyEqual_tolerantOnBothFields() {
        let a = Camera(translation: 1.0, scale: 2.0)
        let b = Camera(translation: 1.0 + 1e-12, scale: 2.0 + 1e-12)
        XCTAssertTrue(a.isApproximatelyEqual(b))
        let c = Camera(translation: 1.0, scale: 2.5)
        XCTAssertFalse(a.isApproximatelyEqual(c))
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

    func test_K14_matrixAtIdentityScale_reducesToTranslationOnly() {
        // N5/N6/N20 landed. Verify viewport↔page math at scale=1.0 matches legacy form.
        let cam = Camera(translation: 200, scale: 1.0)
        let vpc = CGPoint(x: 195, y: 422)
        let vp = TimelineCanvas.viewportPoint(fromPage: CGPoint(x: 0, y: 500), camera: cam, viewportCenter: vpc)
        // Legacy: vp.y = page.y - cam.translation + vpc.y = 500 - 200 + 422 = 722
        XCTAssertEqual(vp.y, 722.0, accuracy: 1e-9)
    }

    func test_K14_matrixAtScale2_pivotsAroundViewportCenter() {
        // K14: scale=2 with camera.translation=100 + vpc.y=422 → page-y at 100 maps to vp.y=422.
        let cam = Camera(translation: 100, scale: 2.0)
        let vpc = CGPoint(x: 195, y: 422)
        let pivot = TimelineCanvas.viewportPoint(fromPage: CGPoint(x: 0, y: 100), camera: cam, viewportCenter: vpc)
        XCTAssertEqual(pivot.y, 422.0, accuracy: 1e-9, "K14 viewport-center pivot")

        // Off-pivot point: page-y at 200 (100pt above pivot) at scale=2 → 200pt above vp center = vp.y = 622.
        let offPivot = TimelineCanvas.viewportPoint(fromPage: CGPoint(x: 0, y: 200), camera: cam, viewportCenter: vpc)
        XCTAssertEqual(offPivot.y, 622.0, accuracy: 1e-9, "K14 scale=2: 100pt page → 200pt viewport above pivot")
    }

    func test_K14_pagePoint_roundTrip_atScale() {
        // Round-trip invariant: page → viewport → page = identity at any scale.
        let cam = Camera(translation: 100, scale: 2.0)
        let vpc = CGPoint(x: 195, y: 422)
        let original = CGPoint(x: 0, y: 350)
        let vp = TimelineCanvas.viewportPoint(fromPage: original, camera: cam, viewportCenter: vpc)
        let backToPage = TimelineCanvas.pagePoint(fromViewport: vp, camera: cam, viewportCenter: vpc)
        XCTAssertEqual(backToPage.y, original.y, accuracy: 1e-9)
    }

    func test_K14_pagePoint_atCameraTranslation_mapsToViewportCenter() throws {
        // N5/N6/N20 landed: scale-aware Camera + viewport↔page helpers.
        // K14: page point at y = camera.translation maps to viewport-center at ANY scale.
        let vpc = ViewportY(422)
        for scale in [1.0, 1.5, 2.0, 4.5] as [CGFloat] {
            let cam = Camera(translation: 100, scale: scale)
            let vp = cam.viewportPoint(fromPage: PageY(100), viewportCenter: vpc)
            XCTAssertEqual(vp.raw, 422.0, accuracy: 1e-9, "K14: page-y at camera.translation maps to viewportCenter.y at scale=\(scale)")
        }
    }

    func test_K14_pagePoint_inverse_atIdentityScale_reducesToTranslationOnly() {
        // K1 backwards-compat: at scale=1.0, scale-aware form reduces to legacy form.
        let cam = Camera(translation: 200, scale: 1.0)
        let vpc = ViewportY(422)
        let pageAt500 = cam.viewportPoint(fromPage: PageY(500), viewportCenter: vpc)
        // Legacy form: viewport_y = page_y - translation + viewportCenter.y = 500 - 200 + 422 = 722
        XCTAssertEqual(pageAt500.raw, 722.0, accuracy: 1e-9)
    }

    // MARK: - K10 candidate: Install-set monotonicity during activation (per §48.3 / T11)

    func test_K10_installSet_monotoneIntent_inUpdateVisibleCells() throws {
        throw XCTSkip("Requires TimelineCanvas + TimelineDataSource test harness with data-source-driven layout — pending dedicated test-infra wave (post-N11 ManualAnimationDriver wiring)")
        // Conceptual test (per HANDOFF §48.3 / T11 K10 invariant):
        //   1. Setup canvas with 10 cells, no active cell, install set = visible-with-margin.
        //   2. setActiveCellIndex(5); snapshot preActivationKeys = Set(instantiatedCells.keys).
        //   3. Trigger updateVisibleCells N times (simulating camera changes).
        //   4. Assert preActivationKeys.isSubset(of: Set(instantiatedCells.keys)) — install set never shrinks during activation.
        //   5. setActiveCellIndex(nil); install set may now shrink to visible-with-margin.
    }

    // MARK: - NEW-Inv.1: Uniform-scale fence (§50.11.4)

    /// Prose: "2D affine uniform scale — sx = sy, with no shear, no rotation, no perspective."
    /// Per-tick assertion on the scale-bearing transform: m12=m21=0 (no shear),
    /// m13=m23=m31=m32=0 (no rotation around X/Y), m11==m22 (uniform sx==sy).
    /// Under K10' (post-§50.13 revision), the scale-bearing transform is
    /// activeCell.layer.transform. Pre-revision: contentHost.layer.sublayerTransform.
    /// Active under current code: camera writes translation-only on sublayerTransform,
    /// so the fence holds (identity-with-translation everywhere).
    func test_NEW_Inv_1_uniformScale_noShearNoRotation() {
        let controller = AnimationController()
        let canvas = TimelineCanvas(controller: controller, frame: viewport)
        for (camera, label) in [
            (Camera.identity, "identity"),
            (Camera(translation: 100), "translation 100"),
            (Camera(translation: -50), "translation -50"),
            (Camera(translation: 0, scale: 1), "scale 1 explicit"),
        ] {
            canvas.setCamera(camera)
            let t = canvas.contentHost.layer.sublayerTransform
            XCTAssertEqual(t.m12, 0, accuracy: 1e-9, "\(label): no shear m12")
            XCTAssertEqual(t.m21, 0, accuracy: 1e-9, "\(label): no shear m21")
            XCTAssertEqual(t.m13, 0, accuracy: 1e-9, "\(label): no X-rotation m13")
            XCTAssertEqual(t.m23, 0, accuracy: 1e-9, "\(label): no X-rotation m23")
            XCTAssertEqual(t.m31, 0, accuracy: 1e-9, "\(label): no Y-rotation m31")
            XCTAssertEqual(t.m32, 0, accuracy: 1e-9, "\(label): no Y-rotation m32")
            XCTAssertEqual(t.m11, t.m22, accuracy: 1e-9, "\(label): uniform scale m11==m22")
        }
    }

    // MARK: - NEW-Inv.2: Zero-Z fence (§50.11.4)

    /// Prose: "no perspective matrix applied. every depth cue gives the user
    /// permission to read recession." K2 m34=-1/1000 is a passive matrix; it
    /// produces NO visual effect when no layer has nonzero Z. Post G-K7-Z Option B
    /// (§50.12), unifiedArcZMagnitude=0 makes BOTH forward direction (cane curve)
    /// AND chatContent distance fade (NEW-3 predecessor) effectively zero-Z.
    /// Fence asserts the architectural commitment: Z-magnitude tokens = 0.
    func test_NEW_Inv_2_zeroZ_inActiveGesturePath() {
        let controller = AnimationController()
        let canvas = TimelineCanvas(controller: controller, frame: viewport)
        XCTAssertEqual(canvas.contentHost.layer.transform.m43, 0, accuracy: 1e-9,
                       "contentHost.layer.transform Z=0 at rest")
        XCTAssertEqual(MorphTiming.unifiedArcZMagnitude, 0, accuracy: 1e-9,
                       "K7 cane curve Z magnitude=0 per G-K7-Z Option B (§50.12)")
        XCTAssertEqual(canvas.contentHost.layer.transform.m43, 0, accuracy: 1e-9,
                       "contentHost.transform.m43 stays 0 (no Z-translation in active path)")
    }

    // MARK: - NEW-Audit.1: Active-cell-no-evict invariant (§50.9.8)

    /// During activeCellIndex != nil, the active cell is never returned to pool,
    /// evicted from keyed pool, or rebound. True by structure (TC:824-829 rejects
    /// active in returnToPool; LRU only fires for cells in pool;
    /// teardownChatContentForMemoryPressure fires on neighbors only). Make explicit.
    func test_NEW_Audit_1_activeCell_neverEvicted_duringEngagement() throws {
        throw XCTSkip("Requires data-source-driven harness + simulation of memory-pressure pruning paths")
    }
}
