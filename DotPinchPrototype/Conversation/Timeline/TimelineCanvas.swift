// TimelineCanvas.swift — V2 dual-axis substrate.
// Camera is a single page-y scalar (Camera.translation); width is invariant.
// Height extension happens per-active-cell via NSLayoutConstraint. Cells live
// as subviews of contentHost; contentHost.layer.sublayerTransform carries the
// camera (pure y-translation, no scale).

import UIKit
import QuartzCore

final class TimelineCanvas: UIView {

    // MARK: - Page layout constants

    static let cellSpacing: CGFloat = 24

    /// Two cells beyond the visible page-rect on each side. Load-bearing for
    /// hit-test edge cases — cells whose page-frame intersects the viewport
    /// even partially must NOT cull.
    static let cullMargin: Int = 2

    static let cellHorizontalInset: CGFloat = 16

    // MARK: - Camera state

    private(set) var camera: Camera = .identity

    /// While false, layoutSubviews re-anchors to the initial scroll position
    /// once bounds become valid.
    private var hasExternalCameraWrite: Bool = false

    // MARK: - Active cell identity

    /// Cell currently being interacted with, or nil at no-active-cell-rest.
    /// Set on gesture .began; cleared when camera settles at cell-rest.
    private(set) var activeCellIndex: Int?

    // MARK: - Cell management

    private(set) var instantiatedCells: [Int: CellView] = [:]

    /// LIFO pool. Every pool-resident cell is in `cellPool`; cells with a
    /// non-nil `activeConversationID` also appear in `cellPoolByConversationID`
    /// (keyed dequeue tries this first, falls through to LIFO on miss).
    /// `poolOrder` is the LRU ordering of conversation IDs, bounded by
    /// `maxKeyedPoolSize`. Invariant: every cell in the keyed map is also in
    /// `cellPool`.
    private(set) var cellPool: [CellView] = []
    private(set) var cellPoolByConversationID: [UUID: CellView] = [:]
    private(set) var poolOrder: [UUID] = []

    static let maxKeyedPoolSize: Int = 20

    /// Class-bound; avoids the VC↔canvas retain cycle.
    weak var dataSource: TimelineDataSource?

    // MARK: - Gesture state

    private(set) var panRecognizer: UIPanGestureRecognizer!

    /// Sign convention: finger DOWN → pan.y > 0 → camera.translation DECREASES.
    private var panInitialCameraTranslationY: CGFloat = 0

    // MARK: - Pinch gesture state

    private(set) var pinchRecognizer: UIPinchGestureRecognizer!

    private var pinchState = PinchState()

    // MARK: - Camera animation

    let animationController: AnimationController

    /// Fires when the tap-to-chat morph reaches its settled state.
    var onMorphRevealReady: ((Int) -> Void)?

    private(set) var cameraAnimator: CameraAnimator!

    /// Extension animator. Shares Spring params with `cameraAnimator` so the
    /// two springs share natural frequency (coordination invariant).
    let extensionAnimator: SpringAnimator<CGFloat>

    private(set) lazy var morphChoreographer: MorphChoreographer = MorphChoreographer(
        canvas: self,
        controller: animationController
    )

    /// Cancellation handle for the deferred `onMorphRevealReady` fire that
    /// follows the tap-to-chat asyncAfter path. Cancelled on pinch .began,
    /// `setActiveCellIndex(nil)`, `reloadData`, and `deinit` so a cell that
    /// engages a new gesture after tap does not get retroactively revealed.
    private var pendingRevealWorkItem: DispatchWorkItem?

    // MARK: - Cell-rest scroll-Y persistence

    /// Most recent scroll-Y at no-active-cell-rest. Persisted so
    /// collapse-from-chat-rest can restore the pre-pinch scroll position.
    private(set) var lastCellRestScrollY: CGFloat = 0

    // MARK: - Layer hierarchy

    /// Direct sublayer of `TimelineCanvas.layer`, NOT inside contentHost —
    /// sublayerTransform does not apply to it.
    let pageGradientLayer = CAGradientLayer()

    /// Camera-transformed sub-host. Cells are subviews of it.
    let contentHost = UIView()

    /// Staggered edge masks. Two CAGradientLayer overlays at top and bottom of
    /// the viewport that paint over the geometric co-scaling of neighbor cells
    /// during mid-pinch with the page-surface gradient color. Both layers are
    /// siblings of contentHost (NOT inside it — sublayerTransform doesn't
    /// reach them). Drawn above contentHost so they overlay cells.
    let topRevealMask = CAGradientLayer()
    let bottomRevealMask = CAGradientLayer()

    // MARK: - Cell layout memoization

    /// Cached accumulated-Y positions. Length = cellCount + 1. Invariant:
    /// nil iff layout needs recomputation. Reset on `reloadData`.
    private var accumulatedYCache: [CGFloat]?

    private var cachedCellCount: Int = 0

    // MARK: - Init

    let physicsTuning: PhysicsTuning

    init(controller: AnimationController,
         tuning: PhysicsTuning = .standard,
         frame: CGRect = .zero) {
        self.animationController = controller
        self.physicsTuning = tuning
        self.extensionAnimator = SpringAnimator<CGFloat>(
            controller: controller,
            spring: Spring(
                dampingRatio: tuning.springDamping,
                response: tuning.springResponse
            )
        )
        super.init(frame: frame)
        installViewHierarchy()
        installPageGradient()
        installPanRecognizer()
        installPinchRecognizer()
        cameraAnimator = CameraAnimator(canvas: self, controller: animationController, tuning: tuning)
        extensionAnimator.valueChanged = { [weak self] _ in
            self?.applyExtensionTick()
        }
        applyCameraTransform()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(controller:frame:)")
    }

    deinit {
        pendingRevealWorkItem?.cancel()
    }

    private func installViewHierarchy() {
        layer.addSublayer(pageGradientLayer)
        // clipsToBounds=true enforces invariant: at chat-rest, no other cell
        // is visible. Off-canvas cells must NOT leak past contentHost bounds.
        contentHost.clipsToBounds = true
        contentHost.translatesAutoresizingMaskIntoConstraints = true
        addSubview(contentHost)

        // Canvas-level clipping + 3D perspective. The perspective is applied
        // via canvas.layer.sublayerTransform.m34 so a child layer with non-zero
        // z-translation gets projected with depth foreshortening — apparent
        // scale = focal/(focal - z).
        clipsToBounds = true
        var perspective = CATransform3DIdentity
        perspective.m34 = -1.0 / 1000  // focal length 1000pt
        layer.sublayerTransform = perspective

        installEdgeMasks()
    }

    /// Configure the staggered edge mask gradient layers. Top mask uses
    /// `Theme.Page.top`, bottom uses `Theme.Page.bottom` — using the matching
    /// gradient endpoint stop blends seamlessly with the underlying
    /// pageGradientLayer. ALWAYS-visible (opacity=1) kills the
    /// cell-on-gradient clash at rest states.
    private func installEdgeMasks() {
        let topColor = Theme.Page.top.sRGBLockedCGColor
        let bottomColor = Theme.Page.bottom.sRGBLockedCGColor
        let clearColor = UIColor.clear.cgColor

        topRevealMask.colors = [topColor, clearColor]
        topRevealMask.locations = [0, 1]
        topRevealMask.startPoint = CGPoint(x: 0.5, y: 0.0)
        topRevealMask.endPoint = CGPoint(x: 0.5, y: 1.0)
        topRevealMask.opacity = 1.0

        bottomRevealMask.colors = [clearColor, bottomColor]
        bottomRevealMask.locations = [0, 1]
        bottomRevealMask.startPoint = CGPoint(x: 0.5, y: 0.0)
        bottomRevealMask.endPoint = CGPoint(x: 0.5, y: 1.0)
        bottomRevealMask.opacity = 1.0

        layer.addSublayer(topRevealMask)
        layer.addSublayer(bottomRevealMask)
    }

    static let edgeMaskHeight: CGFloat = 80

    /// Shared CABasicAnimation factory. Defaults match the morph chrome's
    /// fillMode/removed contract (forwards, not removed on completion).
    private static func makeCAAnimation(keyPath: String,
                                         from: Any?, to: Any?,
                                         duration: CFTimeInterval,
                                         beginTime: CFTimeInterval = 0,
                                         timing: CAMediaTimingFunction,
                                         additive: Bool = false) -> CABasicAnimation {
        let a = CABasicAnimation(keyPath: keyPath)
        a.fromValue = from
        a.toValue = to
        a.duration = duration
        a.beginTime = beginTime
        a.timingFunction = timing
        a.isAdditive = additive
        a.fillMode = .forwards
        a.isRemovedOnCompletion = false
        return a
    }

    /// Three-stop sRGB-locked gradient. The sRGB CGColorSpace lock is
    /// load-bearing: on wide-gamut sims (Display-P3), unlocked CGColors
    /// desaturate warm pinks. CAGradientLayer interpolates in sRGB regardless
    /// of the device's native display gamut.
    private func installPageGradient() {
        let topColor = Theme.Page.top.sRGBLockedCGColor
        let midColor = Theme.Page.surface.sRGBLockedCGColor
        let bottomColor = Theme.Page.bottom.sRGBLockedCGColor
        pageGradientLayer.colors = [topColor, midColor, bottomColor]
        pageGradientLayer.locations = [0, 0.5, 1]
        pageGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        pageGradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
    }

    /// Attached to `self`, not `contentHost`. `recognizer.translation(in: self)`
    /// gives viewport-local translation — the load-bearing frame of reference.
    private func installPanRecognizer() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        addGestureRecognizer(pan)
        panRecognizer = pan
    }

    /// Attached to `self`, not `contentHost` — `pinch.view === canvas`.
    private func installPinchRecognizer() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinch.delegate = self
        addGestureRecognizer(pinch)
        pinchRecognizer = pinch
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        // Suppress implicit layer-property animations on frame writes.
        CATransaction.withSuppressedActions {
            pageGradientLayer.frame = bounds
            contentHost.frame = bounds
            let maskHeight = Self.edgeMaskHeight
            topRevealMask.frame = CGRect(x: 0, y: 0, width: bounds.width, height: maskHeight)
            bottomRevealMask.frame = CGRect(
                x: 0,
                y: bounds.height - maskHeight,
                width: bounds.width,
                height: maskHeight
            )
            // Re-anchor to viewport-aware cell-rest now that bounds are valid
            // (until an external setCamera writes).
            anchorToCellRestIfAtInitialState()
            applyCameraTransform()
            updateVisibleCells()
            // Push (possibly recomputed) camera state so cell-internal alpha
            // curves track viewport-derived chatRestScale after rotation/resize.
            pushCameraToVisibleCells()
            // Layout-driven paths (e.g. rotation) don't go through setCamera.
            updateEdgeMaskAlphas()
        }
    }

    /// Stagger the edge mask alphas off the current canvas progress. Two
    /// smoothstep "peak" curves with different centers: bottom mask peaks
    /// earlier in pinch-out, top mask peaks later. At both rest states the
    /// alphas are 0 — masks are visible only during mid-pinch.
    private func updateEdgeMaskAlphas() {
        let p = currentCanvasProgress

        let bottomUp = smoothstep(0.30, 0.70, p)
        let bottomDown = smoothstep(0.70, 1.00, p)
        let bottomAlpha = bottomUp * (1.0 - bottomDown)

        let topUp = smoothstep(0.10, 0.50, p)
        let topDown = smoothstep(0.50, 0.80, p)
        let topAlpha = topUp * (1.0 - topDown)

        topRevealMask.opacity = Float(min(max(topAlpha, 0), 0.99))
        bottomRevealMask.opacity = Float(min(max(bottomAlpha, 0), 0.99))
    }

    /// Canvas-level progress for chrome / edge-mask curves. At
    /// no-active-cell-rest → 0; at chat-rest → 1.
    var currentCanvasProgress: CGFloat {
        guard let idx = activeCellIndex, let activeCell = instantiatedCells[idx] else { return 0 }
        let naturalH = activeCell.naturalHeight
        guard naturalH > 0, bounds.height > 0 else { return 0 }
        let chatRestFactor = chatRestScale(for: activeCell)
        let chatRestRange = chatRestFactor - 1.0
        guard chatRestRange > 1e-6 else { return 0 }
        let extensionFactor = activeCell.bounds.height / naturalH
        return min(1.0, max(0.0, (extensionFactor - 1.0) / chatRestRange))
    }

    /// Inter-cell spacing extension ∈ [0, 1]. 0 = resting (Self.cellSpacing);
    /// 1 = expanded (~5× resting per §43.5 empirical peak at gesture p≈0.62).
    /// Tracks currentCanvasProgress: chat-rest → 1 (expanded); cell-rest → 0 (resting).
    var listSpacingExtension: CGFloat {
        currentCanvasProgress
    }

    /// If no external `setCamera` write has occurred yet, re-anchor to the
    /// initial scroll position once bounds become valid.
    private func anchorToCellRestIfAtInitialState() {
        guard !hasExternalCameraWrite, bounds.width > 0, bounds.height > 0 else { return }
        camera = Camera(translation: lastCellRestScrollY + bounds.height / 2)
    }

    // MARK: - Public API

    /// Apply a new camera. Stores, writes the CATransform3D, updates visible
    /// cells, fires the change callback. With `Camera.translation` now `let`
    /// (Task 0.14), the only entry point is `Camera.init`, which carries the
    /// finite precondition — boundary re-validation is unrepresentable.
    func setCamera(_ newCamera: Camera) {
        camera = newCamera
        hasExternalCameraWrite = true
        CATransaction.withSuppressedActions {
            applyCameraTransform()
            updateVisibleCells()
            pushCameraToVisibleCells()
            updateEdgeMaskAlphas()
        }
        // Pan is suppressed while a cell is active.
        panRecognizer.isEnabled = (activeCellIndex == nil)
        if activeCellIndex == nil {
            lastCellRestScrollY = camera.translation - bounds.height / 2
        }
        CATransaction.withSuppressedActions {
            onCameraChanged?(camera, bounds)
        }
    }

    /// Update `activeCellIndex` and reconcile dependent state. Single
    /// gateway so pan-enablement and any future invariants stay coherent.
    /// Out-of-bounds non-nil indices trap immediately — silent dictionary
    /// misses downstream would surface as no-op state 3 frames later.
    private func setActiveCellIndex(_ newValue: Int?) {
        if let newValue {
            precondition(
                (0..<(dataSource?.numberOfCells(in: self) ?? 0)).contains(newValue),
                "setActiveCellIndex: index \(newValue) out of range"
            )
        }
        activeCellIndex = newValue
        panRecognizer.isEnabled = (newValue == nil)
        // When transitioning to no-active-cell-rest, reset neighbor
        // translations so all cells return to natural page positions and
        // cancel any deferred reveal targeting the cleared cell.
        if newValue == nil {
            pendingRevealWorkItem?.cancel()
            pendingRevealWorkItem = nil
            updateNeighborTranslations()
            pinchRecognizer.isEnabled = true
        }
    }

    // MARK: - Camera-change subscription

    /// Fires at the END of every `setCamera` call, AFTER `applyCameraTransform`,
    /// `updateVisibleCells`, and `pushCameraToVisibleCells`. The fire point is
    /// load-bearing — chrome alpha curves driven by this must reflect a state
    /// consistent with the visible cells, not one frame ahead.
    /// Callers MUST capture `self` weakly to avoid a canvas←VC retain cycle.
    var onCameraChanged: ((Camera, CGRect) -> Void)?

    /// Re-query the data source and lay out cells. Live cells route through
    /// `returnToPool` so the keyed-pool secondary index + LRU order stay in
    /// sync. The conversation-ID-keyed pool is cleared so post-reload dequeues
    /// take the LIFO/miss path (preserving state across a data-source reload
    /// would resurrect data that no longer makes sense).
    func reloadData() {
        // Defensive: clear active-cell BEFORE pool-clear so the active cell
        // routes through returnToPool (and thus resetMorphState) instead of
        // being orphaned mid-engagement. Without this guard, reloadData mid-
        // active-cell would leave the active cell's morph state un-reset.
        if activeCellIndex != nil {
            setActiveCellIndex(nil)
        }
        invalidateLayout()
        for (_, cell) in instantiatedCells {
            returnToPool(cell)
        }
        instantiatedCells.removeAll(keepingCapacity: true)
        cellPoolByConversationID.removeAll(keepingCapacity: true)
        poolOrder.removeAll(keepingCapacity: true)
        for cell in cellPool {
            cell.invalidateConversationBinding()
        }
        // Reset hasExternalCameraWrite so the next layout pass re-anchors —
        // the prior camera state may reference page coords that no longer
        // correspond to any cell.
        hasExternalCameraWrite = false
        lastCellRestScrollY = 0
        CATransaction.withSuppressedActions {
            updateVisibleCells()
        }
    }

    /// Inverse-camera applied to bounds.
    var visiblePageRect: CGRect {
        pageRectFromViewportRect(bounds)
    }

    // MARK: - Page / viewport coordinate helpers

    /// Use `bounds.mid`, NOT `frame.mid` — if the canvas is embedded with
    /// `frame.origin != .zero`, `bounds.mid` is correct and `frame.mid` is wrong.
    private var viewportCenter: CGPoint {
        CGPoint(x: bounds.midX, y: bounds.midY)
    }

    func pagePointFromViewportPoint(_ point: CGPoint) -> CGPoint {
        Self.pagePoint(fromViewport: point, camera: camera, viewportCenter: viewportCenter)
    }

    func viewportPointFromPagePoint(_ point: CGPoint) -> CGPoint {
        Self.viewportPoint(fromPage: point, camera: camera, viewportCenter: viewportCenter)
    }

    /// Convert a viewport-coord rect to page coordinates by mapping each
    /// corner independently. Computing width/height via direct inverse is
    /// wrong at non-zero translation — write the rect from mapped corners.
    func pageRectFromViewportRect(_ rect: CGRect) -> CGRect {
        let vc = viewportCenter
        let topLeft = Self.pagePoint(
            fromViewport: CGPoint(x: rect.minX, y: rect.minY),
            camera: camera,
            viewportCenter: vc
        )
        let bottomRight = Self.pagePoint(
            fromViewport: CGPoint(x: rect.maxX, y: rect.maxY),
            camera: camera,
            viewportCenter: vc
        )
        return CGRect(
            x: topLeft.x,
            y: topLeft.y,
            width: bottomRight.x - topLeft.x,
            height: bottomRight.y - topLeft.y
        )
    }

    // MARK: - Camera transform application

    /// Compute and apply the CATransform3D for the current camera. Callers
    /// must wrap in a CATransaction with setDisableActions(true).
    private func applyCameraTransform() {
        let viewportCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        let t = Self.transform3D(for: camera, viewportCenter: viewportCenter)
        contentHost.layer.sublayerTransform = t
    }

    /// Dual-axis: y-only translation, x identity. Under Apple's
    /// sublayerTransform pivoting, T(vp - cam) yields the effective
    /// `p_viewport = p_page - cam + viewportCenter`.
    static func transform3D(for camera: Camera, viewportCenter: CGPoint) -> CATransform3D {
        CATransform3DMakeTranslation(0, viewportCenter.y - camera.translation, 0)
    }

    /// Scale-aware page→viewport mapping (N5/N6 + K14 pivot-at-viewport-center).
    /// At camera.scale=1.0 reduces to the legacy translation-only form (K1 backwards-compat).
    static func viewportPoint(fromPage pagePoint: CGPoint, camera: Camera, viewportCenter: CGPoint) -> CGPoint {
        CGPoint(
            x: pagePoint.x,
            y: (pagePoint.y - camera.translation) * camera.scale + viewportCenter.y
        )
    }

    /// Scale-aware viewport→page mapping (inverse of viewportPoint(fromPage:)).
    /// At camera.scale=1.0 reduces to the legacy translation-only form.
    static func pagePoint(fromViewport viewportPoint: CGPoint, camera: Camera, viewportCenter: CGPoint) -> CGPoint {
        CGPoint(
            x: viewportPoint.x,
            y: (viewportPoint.y - viewportCenter.y) / camera.scale + camera.translation
        )
    }

    // MARK: - Cell layout calculator

    /// Single-column; equals viewport width. Recomputed on layout to reflect
    /// the latest viewport size after rotation/resize.
    var pageWidth: CGFloat {
        bounds.width
    }

    /// Sum of cell heights + interior gaps. No trailing spacing past the last cell.
    var pageHeight: CGFloat {
        accumulatedYs().last ?? 0
    }

    /// Page-coord frame of cell at `index`. Origin x = 0 (single-column).
    /// Out-of-range traps via precondition; `.null` would hide bugs.
    func pageFrameForCell(at index: Int) -> CGRect {
        let count = cellCount()
        precondition(index >= 0 && index < count,
                     "pageFrameForCell out of range: \(index) not in 0..<\(count)")
        let ys = accumulatedYs()
        let top = ys[index]
        let height = heightForCell(at: index)
        return CGRect(x: 0, y: top, width: pageWidth, height: height)
    }

    /// Cell index whose page-frame contains `pagePoint`, or nil for inter-cell
    /// gap / outside points. Uses cell-by-cell containment because a degenerate
    /// (zero-area) rect query returns empty intersections.
    func cellIndex(atPagePoint pagePoint: CGPoint) -> Int? {
        let count = cellCount()
        guard count > 0 else { return nil }
        let candidates = cellIndices(in: CGRect(origin: pagePoint, size: .zero), plusMargin: 0)
        for i in candidates {
            if pageFrameForCell(at: i).contains(pagePoint) {
                return i
            }
        }
        return nil
    }

    /// Range of cell indices whose page-frames INTERSECT `pageRect`, widened
    /// by `margin` cells on each side. Intersection (not containment) so
    /// partially-visible cells are included. Returns a contiguous Range (no
    /// holes — visible-cell contiguity invariant).
    func cellIndices(in pageRect: CGRect, plusMargin margin: Int) -> Range<Int> {
        let count = cellCount()
        guard count > 0 else { return 0..<0 }
        precondition(margin >= 0, "cellIndices margin must be >= 0; got \(margin)")

        let ys = accumulatedYs()
        // First cell whose bottom is > pageRect.minY.
        var first = 0
        for i in 0..<count {
            let cellBottom = ys[i] + heightForCell(at: i)
            if cellBottom > pageRect.minY {
                first = i
                break
            }
            first = i + 1
        }

        // Last cell whose top is < pageRect.maxY.
        var lastExclusive = first
        for i in first..<count {
            if ys[i] >= pageRect.maxY {
                break
            }
            lastExclusive = i + 1
        }

        let widenedFirst = max(0, first - margin)
        let widenedLast = min(count, lastExclusive + margin)
        guard widenedFirst < widenedLast else { return 0..<0 }
        return widenedFirst..<widenedLast
    }

    // MARK: - Cell layout cache

    private func invalidateLayout() {
        accumulatedYCache = nil
    }

    /// Lazily build the accumulated-Y cache. Length = cellCount + 1.
    /// accumulatedYs()[i] = page-coord top of cell at i; [count] = total
    /// page height. Invalidated by `reloadData` and by cellCount mismatch.
    private func accumulatedYs() -> [CGFloat] {
        let count = cellCount()
        if let cached = accumulatedYCache, cachedCellCount == count {
            return cached
        }
        var ys: [CGFloat] = []
        ys.reserveCapacity(count + 1)
        var acc: CGFloat = safeAreaInsets.top + Self.cellSpacing
        for i in 0..<count {
            ys.append(acc)
            let h = heightForCell(at: i)
            acc += h
            if i < count - 1 {
                acc += Self.cellSpacing
            }
        }
        ys.append(acc)
        accumulatedYCache = ys
        cachedCellCount = count
        return ys
    }

    private func cellCount() -> Int {
        dataSource?.numberOfCells(in: self) ?? 0
    }

    private func heightForCell(at index: Int) -> CGFloat {
        dataSource?.canvas(self, heightForCellAt: index) ?? 0
    }

    // MARK: - Visible cells

    /// Compute the visible page-rect, expand by `cullMargin`, return cells
    /// outside the range to the pool, dequeue/configure newly-visible cells.
    /// Idempotent — if the visible range is unchanged, dequeue/return loops
    /// are no-ops (non-idempotent culling would thrash the pool every frame).
    private func updateVisibleCells() {
        guard dataSource != nil else { return }
        // Gate on valid bounds — before constraints resolve, heightForCellAt
        // returns 0 and cells would instantiate with zero-size frames that
        // never recover.
        guard bounds.width > 0, bounds.height > 0 else { return }
        let count = cellCount()
        guard count > 0 else {
            for (_, cell) in instantiatedCells {
                returnToPool(cell)
            }
            instantiatedCells.removeAll(keepingCapacity: true)
            return
        }

        let newRange = cellIndices(in: visiblePageRect, plusMargin: Self.cullMargin)

        // N50 — Install-set monotonicity during activation (K10 candidate per
        // HANDOFF §48.3 / T11). When activeCellIndex != nil, never SHRINK the
        // install set — only grow it via union with prior range. Prevents the
        // "uncovered not created" phenomenology violation under future camera-
        // scale animation where visiblePageRect shrinks as scale grows.
        // Under current main (no camera.scale), newRange typically already
        // contains existing instantiated cells, so the union is a no-op.
        let visibleRange: Range<Int>
        if activeCellIndex != nil, let existingMin = instantiatedCells.keys.min(), let existingMax = instantiatedCells.keys.max() {
            let lower = min(newRange.lowerBound, existingMin)
            let upper = max(newRange.upperBound, existingMax + 1)
            visibleRange = lower..<upper
        } else {
            visibleRange = newRange
        }

        // Active-cell-pool-protection: the active cell stays in
        // `instantiatedCells` even when its page-frame falls outside the range.
        var removed: [Int] = []
        for (index, _) in instantiatedCells where
            index != activeCellIndex &&
            (!visibleRange.contains(index) || index >= count) {
            removed.append(index)
        }
        for index in removed {
            if let cell = instantiatedCells.removeValue(forKey: index) {
                returnToPool(cell)
            }
        }

        for i in visibleRange {
            let pageFrame = pageFrameForCell(at: i)
            let naturalCenterY = pageFrame.midY
            let naturalHeight = pageFrame.height
            if let existing = instantiatedCells[i] {
                // Re-install layout to update pageWidth / naturalCenterY on
                // bounds change. CRITICAL: skip the active cell so we don't
                // overwrite its extended heightConstraint.constant.
                if i != activeCellIndex {
                    existing.installLayout(
                        into: contentHost,
                        naturalCenterY: naturalCenterY,
                        naturalHeight: naturalHeight,
                        pageWidth: pageWidth,
                        horizontalInset: Self.cellHorizontalInset
                    )
                }
            } else {
                let desiredID = dataSource?.canvas(self, conversationIDForCellAt: i)
                let (cell, preservedState) = dequeueCell(preferredConversationID: desiredID)
                cell.index = i
                cell.morphChoreographer = morphChoreographer
                // Set TAMIC=false BEFORE addSubview so UIKit doesn't synthesize
                // autoresizing constraints that conflict with explicit ones.
                cell.translatesAutoresizingMaskIntoConstraints = false
                contentHost.addSubview(cell)
                cell.installLayout(
                    into: contentHost,
                    naturalCenterY: naturalCenterY,
                    naturalHeight: naturalHeight,
                    pageWidth: pageWidth,
                    horizontalInset: Self.cellHorizontalInset
                )
                instantiatedCells[i] = cell
                // State-preservation seam: skip configure on a keyed-pool hit so
                // scroll offset / composer text survive the round-trip.
                if !preservedState {
                    dataSource?.canvas(self, configureCell: cell, at: i)
                }
            }
        }

        // Trailing re-assert of active-cell z-order. addSubview during dequeue
        // appends to contentHost.subviews; without this, a mid-gesture dequeue
        // can displace activeCell from frontmost.
        if let activeIdx = activeCellIndex, let activeCell = instantiatedCells[activeIdx] {
            contentHost.bringSubviewToFront(activeCell)
        }
    }

    /// Restore natural sibling order on activeCellIndex k → nil transition.
    /// Idempotent.
    private func restoreNaturalSiblingOrder() {
        let sortedCells = contentHost.subviews
            .compactMap { $0 as? CellView }
            .sorted { ($0.index ?? .max) < ($1.index ?? .max) }
        for cell in sortedCells {
            contentHost.bringSubviewToFront(cell)
        }
    }

    /// Push the camera state into each visible cell's `setCamera(_:viewport:)`
    /// so cell-internal alpha curves and the transcript scrollView enable-gate
    /// can update. One call per visible cell per canvas `setCamera`. The cell
    /// seam is forbidden to mutate canvas state; we iterate a snapshot
    /// defensively.
    private func pushCameraToVisibleCells() {
        let viewport = bounds
        let cells = Array(instantiatedCells.values)
        let progress = currentCanvasProgress
        // Carrier-alpha invariant: applies only to ACTIVE cell; neighbors fade
        // during mid-progress.
        let neighborAlpha = 1 - smoothstep(0.30, 0.70, progress)
        for (index, cell) in instantiatedCells {
            let isActive = (index == activeCellIndex)
            cell.alpha = isActive ? 1.0 : neighborAlpha
            cell.setCamera(camera, viewport: viewport)
            _ = cells  // keep snapshot reference alive for dict-mutation defense
        }
        updateNeighborTranslations()
    }

    /// Neighbor follow-positioning. As the active cell grows/shrinks around
    /// its fixed centerY, its edges move ±halfGrowth from natural; neighbors
    /// above translate up by halfGrowth, neighbors below by halfGrowth, so
    /// the natural cellSpacing gap is preserved frame-by-frame. Active cell
    /// itself stays at identity (extension is via heightConstraint, not
    /// transform).
    private func updateNeighborTranslations() {
        guard let activeIdx = activeCellIndex,
              let activeCell = instantiatedCells[activeIdx],
              activeCell.naturalHeight > 0 else {
            for (_, cell) in instantiatedCells {
                cell.resetFollowTransform()
            }
            return
        }
        let growth = activeCell.bounds.height - activeCell.naturalHeight
        for (index, cell) in instantiatedCells {
            if index == activeIdx {
                cell.resetFollowTransform()
            } else {
                let position: CellView.NeighborPosition = (index < activeIdx) ? .above : .below
                cell.followActive(growth: growth, position: position)
            }
        }
    }

    /// Dequeue a cell from the pool. Routing:
    ///   1. Keyed-pool hit on `preferredConversationID`: remove from both
    ///      structures, return with `preservedState: true` (caller MUST skip
    ///      configure — scroll offset / composer text survive).
    ///   2. Otherwise prefer an unbound cell (no state to lose).
    ///   3. Otherwise, if keyed pool is at cap, evict LRU-oldest and reuse.
    ///   4. Otherwise instantiate fresh — keeps the round-trip contract for
    ///      pool-resident cells under cap.
    /// `preservedState=true` is the state-preservation seam — skip configure.
    private func dequeueCell(preferredConversationID: UUID?) -> (cell: CellView, preservedState: Bool) {
        if let id = preferredConversationID, let cell = cellPoolByConversationID.removeValue(forKey: id) {
            if let idx = cellPool.firstIndex(where: { $0 === cell }) {
                cellPool.remove(at: idx)
            }
            if let orderIdx = poolOrder.firstIndex(of: id) {
                poolOrder.remove(at: orderIdx)
            }
            return (cell, true)
        }

        if let idx = cellPool.firstIndex(where: { $0.activeConversationID == nil }) {
            let cell = cellPool.remove(at: idx)
            return (cell, false)
        }

        if poolOrder.count >= Self.maxKeyedPoolSize, let oldestID = poolOrder.first {
            cellPoolByConversationID.removeValue(forKey: oldestID)
            poolOrder.removeFirst()
            if let idx = cellPool.firstIndex(where: { $0.activeConversationID == oldestID }) {
                let cell = cellPool.remove(at: idx)
                return (cell, false)
            }
        }

        return (CellView(frame: .zero), false)
    }

    /// Return a cell to the pool. NO destructive reset: scroll offset,
    /// composer text, in-flight animations survive the round-trip.
    /// `removeFromSuperview` is mandatory — without it, pool-resident cells
    /// render invisibly and accumulate. Cell goes into LIFO and (if it has
    /// an activeConversationID) the keyed index. LRU eviction bounds the
    /// keyed pool at `maxKeyedPoolSize`.
    private func returnToPool(_ cell: CellView) {
        // Active-cell-pool-protection: reject the active cell. The guard
        // lives here so all call sites honor it without per-site guards.
        if let activeIdx = activeCellIndex, cell.index == activeIdx {
            return
        }

        // Pool-clean-morph: clear morph-related transient state (morphInProgress
        // flag + chatRestCenterLabel transform/opacity) so a recycled cell does
        // not carry chrome ghosting into its next binding regardless of how
        // the prior morph ended.
        cell.resetMorphState()

        // Pool-clean-height: reset heightConstraint and deactivate
        // contentHost-targeted constraints before removeFromSuperview to keep
        // Auto Layout coherent.
        cell.resetHeightConstraintToNatural()
        cell.deactivateLayoutConstraints()

        cell.removeFromSuperview()
        cellPool.append(cell)

        guard let id = cell.activeConversationID else {
            return
        }

        // If the same conversation already has a cell in the keyed pool, tear
        // down the displaced cell's active state explicitly: endEditing +
        // invalidateConversationBinding dismiss its keyboard and clear its
        // keyboardLayoutGuide constraint — otherwise the displaced cell is
        // orphaned with `activeConversationID = id` still set until ARC
        // releases.
        if let existing = cellPoolByConversationID[id], existing !== cell {
            existing.endEditing(true)
            existing.invalidateConversationBinding()
            if let idx = cellPool.firstIndex(where: { $0 === existing }) {
                cellPool.remove(at: idx)
            }
        }
        cellPoolByConversationID[id] = cell

        if let existingIdx = poolOrder.firstIndex(of: id) {
            poolOrder.remove(at: existingIdx)
        }
        poolOrder.append(id)

        while poolOrder.count > Self.maxKeyedPoolSize {
            let evictID = poolOrder.removeFirst()
            guard let evictCell = cellPoolByConversationID.removeValue(forKey: evictID) else { continue }
            // Dismiss any active keyboard before the cell drops out of the pool.
            evictCell.endEditing(true)
            if let idx = cellPool.firstIndex(where: { $0 === evictCell }) {
                cellPool.remove(at: idx)
            }
        }
    }

    // MARK: - Internal accessors (for tests)

    var visibleCells: [CellView] {
        instantiatedCells
            .sorted { $0.key < $1.key }
            .map { $0.value }
    }

    // MARK: - Hit-test routing

    /// Manual override. UIKit's default `hitTest` uses `convert(_:from:)` which
    /// accounts for sublayerTransform, but `UIView.frame` does NOT — so we route
    /// through page-coord helpers. Discipline: page-coord helpers (not
    /// `UIView.convert`), iterate `instantiatedCells` (not
    /// `contentHost.subviews` — subview order is insertion order, not z-order),
    /// forward CELL-LOCAL coords to `cell.hitTest`, return nil for non-cell
    /// taps (do NOT fall through to `super.hitTest` — that re-enters the
    /// broken convert-based path).
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let pagePoint = pagePointFromViewportPoint(point)

        // Active cell takes hit-test priority. Under dual-axis extension the
        // active cell's frame extends past its natural slot and overlaps
        // neighbor cells' frames; index-descending alone doesn't capture
        // z-order under overlap.
        if let activeIdx = activeCellIndex, let activeCell = instantiatedCells[activeIdx],
           activeCell.frame.contains(pagePoint) {
            let cellLocal = CGPoint(
                x: pagePoint.x - activeCell.frame.origin.x,
                y: pagePoint.y - activeCell.frame.origin.y
            )
            if let result = activeCell.hitTest(cellLocal, with: event) {
                return result
            }
        }

        // Non-active cells iterate index-descending for z-order traversal.
        let indicesDescending = instantiatedCells.keys.sorted(by: >)
        for index in indicesDescending where index != activeCellIndex {
            guard let cell = instantiatedCells[index] else { continue }
            if cell.frame.contains(pagePoint) {
                let cellLocal = CGPoint(
                    x: pagePoint.x - cell.frame.origin.x,
                    y: pagePoint.y - cell.frame.origin.y
                )
                if let result = cell.hitTest(cellLocal, with: event) {
                    return result
                }
            }
        }
        return nil
    }

    // MARK: - Pan gesture

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        // Defensive guard against the race where pan's first `.began` fires
        // between two setCamera calls.
        guard activeCellIndex == nil else { return }

        switch recognizer.state {
        case .began:
            panInitialCameraTranslationY = camera.translation
            cameraAnimator.stop(immediately: true)

        case .changed:
            let pan = recognizer.translation(in: self)
            let rawT = panInitialCameraTranslationY - pan.y
            let clamped = clampedWithRubberband(rawT)
            setCamera(Camera(translation: clamped))

        case .ended, .cancelled:
            let rawVelY = recognizer.velocity(in: self).y
            guard rawVelY.isFinite else { return }
            startSpringDeceleration(initialVelocityY: -rawVelY)

        case .failed, .possible:
            break
        @unknown default:
            break
        }
    }

    /// Apply rubber-band damping. Valid translation range:
    /// `[viewport.height/2, pageH - viewport.height/2]`.
    private func clampedWithRubberband(_ rawT: CGFloat) -> CGFloat {
        let viewportH = bounds.height
        let pageH = pageHeight
        let minT = viewportH / 2
        let maxT = max(minT, pageH - viewportH / 2)
        return rubberband(
            value: rawT,
            range: minT...maxT,
            interval: viewportH,
            c: 0.55
        )
    }

    /// Pan-end deceleration. Single-axis translation spring; valid range
    /// matches `clampedWithRubberband`.
    private func startSpringDeceleration(initialVelocityY: CGFloat) {
        let viewportH = bounds.height
        let pageH = pageHeight
        let minT = viewportH / 2
        let maxT = max(minT, pageH - viewportH / 2)

        let projected = project(initialVelocity: initialVelocityY, decelerationRate: 0.998)
        let rawTarget = camera.translation + projected
        let clampedTarget = clamp(rawTarget, minT, maxT)

        let targetCamera = Camera(translation: clampedTarget)
        let velocity = CameraVelocity(translationVelocity: initialVelocityY)
        cameraAnimator.animate(to: targetCamera, velocity: velocity)
    }

    // MARK: - Active-cell context

    private struct ActiveCellContext {
        let activeIdx: Int
        let activeCell: CellView
        let heightConstraint: NSLayoutConstraint
        let naturalH: CGFloat
    }

    private func activeCellContext() -> ActiveCellContext? {
        guard let activeIdx = activeCellIndex,
              let activeCell = instantiatedCells[activeIdx],
              let heightC = activeCell.heightConstraint else { return nil }
        let naturalH = activeCell.naturalHeight
        guard naturalH > 0 else { return nil }
        return ActiveCellContext(activeIdx: activeIdx, activeCell: activeCell,
                                  heightConstraint: heightC, naturalH: naturalH)
    }

    // MARK: - Engagement predicate

    private var isQuiet: Bool {
        !morphChoreographer.isRunning
            && !cameraAnimator.isRunning
            && extensionAnimator.state != .running
            && contentHost.layer.animation(forKey: MorphAnimationKey.windupScale.rawValue) == nil
    }

    /// Standard chat-rest scale derivation `bounds.height / naturalH`. Used at
    /// 6 cell-rest spring/snap sites. K7 cane curve uses a DIFFERENT formula
    /// (viewportCoverageHeight / naturalH) at TC:1298 — NOT this helper.
    private func chatRestScale(for cell: CellView) -> CGFloat {
        chatRestScale(naturalHeight: cell.naturalHeight)
    }

    /// Overload for sites with a captured `naturalH` local (handlePinchChanged,
    /// handlePinchEnded via activeCellContext) where the cell reference isn't
    /// in scope.
    private func chatRestScale(naturalHeight: CGFloat) -> CGFloat {
        guard naturalHeight > 0, bounds.height > 0 else { return 1.0 }
        return (bounds.height / naturalHeight) * MorphTiming.chatRestMarginFactor
    }

    // MARK: - Pinch gesture (recognizer plumbing)

    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .began:
            handlePinchBegan(recognizer)
        case .changed:
            handlePinchChanged(recognizer)
        case .ended:
            handlePinchEnded(recognizer)
        case .cancelled, .failed:
            // UIKit-contract correctness: Control Center swipe / incoming
            // call → recognizer goes to .cancelled. .ended's commit-or-bail
            // would land the user in a state they never chose. Cancelled
            // restores to whichever rest the gesture originated from.
            handlePinchCancelled(recognizer)
        case .possible:
            break
        @unknown default:
            break
        }
    }

    /// Internal (not private) so adversarial tests can drive the handler
    /// with a mock recognizer subclass overriding state/scale/location.
    internal func handlePinchBegan(_ recognizer: UIPinchGestureRecognizer) {
        morphChoreographer.stop()
        cameraAnimator.stop(immediately: true)
        extensionAnimator.stop(immediately: true)
        // Cancel any in-flight reveal from a prior tap-to-chat — a fresh
        // pinch begins a new interaction; the previous deferred reveal must
        // not retroactively fire mid-pinch.
        pendingRevealWorkItem?.cancel()
        pendingRevealWorkItem = nil
        self.endEditing(true)

        let screenCenter = recognizer.location(in: self)
        let anchorPage = pagePointFromViewportPoint(screenCenter)
        let anchorCellIdx = cellIndex(atPagePoint: anchorPage)
        setActiveCellIndex(anchorCellIdx)

        // §36.3.1 defensive chrome reset: if a prior pinch-commit's chrome
        // fades or centerLabelOpacity CABasicAnimation are still attached,
        // cancel them and reset alphas to cell-rest values BEFORE the new
        // pinch's setCamera ticks drive alphas based on progress. Without
        // this, chrome could be stuck at alpha=0 if the prior pinch-commit
        // was interrupted mid-fade.
        if let idx = anchorCellIdx, let activeCell = instantiatedCells[idx] {
            activeCell.chatContentContainer?.bubbleStack.stopDeceleration()
            activeCell.chatContentContainer?.setIllegibilityFraction(0)
            CATransaction.withSuppressedActions {
                activeCell.dateLabel.layer.removeAllAnimations()
                activeCell.topicSummaryLabel.layer.removeAllAnimations()
                activeCell.todayLabel.layer.removeAllAnimations()
                activeCell.pinchGlyph.layer.removeAllAnimations()
                activeCell.chatRestCenterLabel.layer.removeAllAnimations()

                activeCell.dateLabel.alpha = 1
                activeCell.topicSummaryLabel.alpha = 1
                activeCell.todayLabel.alpha = 1
                activeCell.pinchGlyph.alpha = 1
                activeCell.chatRestCenterLabel.alpha = 0
                activeCell.chatRestAffordance.alpha = 0
                activeCell.chatRestCenterLabel.transform = .identity
            }
        }

        pinchState.anchorPageY = anchorPage.y

        // Unconditional overwrite so a prior gesture's stale state cannot leak in.
        pinchState.previousCentroidY = screenCenter.y
        pinchState.previousCentroidTimestamp = CACurrentMediaTime()

        pinchState.initialScale = recognizer.scale

        if let idx = anchorCellIdx, let activeCell = instantiatedCells[idx] {
            pinchState.initialExtension = activeCell.heightConstraint?.constant ?? activeCell.naturalHeight
            // Raise the active cell so its extension renders ABOVE neighbors.
            contentHost.bringSubviewToFront(activeCell)
        } else {
            pinchState.initialExtension = 0
        }
    }

    /// layoutIfNeeded forces the solve so cell.frame tracks the new height
    /// before subsequent reads (hit-test timing).
    internal func handlePinchChanged(_ recognizer: UIPinchGestureRecognizer) {
        guard pinchState.initialScale > 1e-6 else { return }
        guard let ctx = activeCellContext(), bounds.height > 0 else { return }
        let heightC = ctx.heightConstraint
        let naturalH = ctx.naturalH

        let scaleFactor = recognizer.scale / pinchState.initialScale
        let rawNewExtension = pinchState.initialExtension * scaleFactor

        // Clamp to [naturalHeight, naturalHeight × chatRestFactor × 1.15].
        // The 1.15 headroom is the rubberband budget for over-pinch.
        let chatRestExtensionFactor = chatRestScale(naturalHeight: naturalH)
        let ceiling = naturalH * chatRestExtensionFactor * 1.15
        let clampedExtension = min(ceiling, max(naturalH, rawNewExtension))

        // layoutIfNeeded forces cell.bounds.height to track before the camera
        // update propagates to cell.setCamera (alpha curves read bounds).
        CATransaction.withSuppressedActions {
            heightC.constant = clampedExtension
            contentHost.layoutIfNeeded()
        }

        // Pinch anchor stability: write camera so the page-coord captured at
        // .began (pinchState.anchorPageY) stays mapped to the current centroid
        // viewport-y. Derived by inverting viewportPoint(fromPage:...):
        // `camera.translation = y_page + viewport.height/2 - y_viewport`.
        let currentCentroidViewportY = recognizer.location(in: self).y
        let newTranslation = pinchState.anchorPageY + bounds.height / 2 - currentCentroidViewportY
        guard newTranslation.isFinite else { return }
        setCamera(Camera(translation: newTranslation))

        // Update AFTER setCamera so observers reading inside onCameraChanged
        // see consistent state. Reuse the captured centroid Y — do NOT call
        // recognizer.location again (UIKit could return a different value).
        pinchState.previousCentroidY = currentCentroidViewportY
        pinchState.previousCentroidTimestamp = CACurrentMediaTime()
    }

    /// Commit decision: extensionFactor-vs-threshold with velocity bias so a
    /// fast release past midpoint commits even at modest extension. Both
    /// springs (camera + extension) use matched `PhysicsTuning` params.
    internal func handlePinchEnded(_ recognizer: UIPinchGestureRecognizer) {
        defer { pinchState.reset() }

        guard let ctx = activeCellContext(), bounds.height > 0 else { return }
        let activeIdx = ctx.activeIdx
        let heightC = ctx.heightConstraint
        let naturalH = ctx.naturalH

        let chatRestFactor = chatRestScale(naturalHeight: naturalH)
        let currentFactor = heightC.constant / naturalH
        let commitThreshold: CGFloat = StageOrdering.illegibilityToeFull(chatRestScale: chatRestFactor)

        let pinchVel = recognizer.velocity.isFinite ? recognizer.velocity : 0
        let extensionVel = pinchState.initialExtension * pinchVel
        let velocityBias = (extensionVel / naturalH) * 0.15
        let weightedFactor = currentFactor + velocityBias

        let commitToChatRest = weightedFactor > commitThreshold

        // Translation velocity from centroid samples. Derived from the anchor
        // formula: d(translation)/dt = -d(centroidY)/dt. Finger DOWN
        // (centroidY increasing) ⇒ negative translation velocity.
        let currentCentroidY = recognizer.location(in: self).y
        let nowTimestamp = CACurrentMediaTime()
        let dt = nowTimestamp - pinchState.previousCentroidTimestamp
        let cameraTranslationVelocity: CGFloat
        if dt > 1e-6 && dt.isFinite
            && currentCentroidY.isFinite && pinchState.previousCentroidY.isFinite {
            let centroidVelocity = (currentCentroidY - pinchState.previousCentroidY) / dt
            cameraTranslationVelocity = -centroidVelocity
        } else {
            cameraTranslationVelocity = 0
        }

        // Classify direction by ORIGIN × DESTINATION (NOT by recognizer scale
        // sign). Origin = pinchState.initialExtension at .began (within 5% of
        // naturalH = cell-rest origin).
        let originatedFromCellRest = pinchState.initialExtension <= naturalH * 1.05
        let commit: GestureCommit
        if commitToChatRest && originatedFromCellRest {
            commit = .tapToChat
        } else if commitToChatRest && !originatedFromCellRest {
            commit = .cancelled
        } else if !commitToChatRest && !originatedFromCellRest {
            commit = .pinchToCells
        } else {
            commit = .cancelled
        }

        if commitToChatRest {
            if commit == .tapToChat {
                playTapToChatMorph(forCellAt: activeIdx)
            } else {
                springToChatRest(
                    forCellAt: activeIdx,
                    carriedExtensionVelocity: extensionVel,
                    cameraTranslationVelocity: cameraTranslationVelocity,
                    commit: commit
                )
            }
        } else if commit == .pinchToCells && Self.reverseCinematographyEnabled {
            // §24.4 commit-driven reverse cinematography (Phase 11, opt-in).
            playPinchToCellsMorph(forCellAt: activeIdx, carriedExtensionVelocity: extensionVel)
        } else {
            springToCellRest(
                carriedExtensionVelocity: extensionVel,
                cameraTranslationVelocity: cameraTranslationVelocity,
                commit: commit
            )
        }
    }

    /// UIKit-cancellation path. Distinct from `.ended` so the commit-or-bail
    /// decision does NOT run on involuntary cancellation (Control Center
    /// swipe / incoming call). Restores to whichever rest the gesture
    /// originated from with zero velocity — recognizer.scale at .cancelled
    /// is unreliable, so origin classification (pinchState.initialExtension) is
    /// the only sound signal.
    internal func handlePinchCancelled(_ recognizer: UIPinchGestureRecognizer) {
        defer { pinchState.reset() }
        guard let activeIdx = activeCellIndex,
              let activeCell = instantiatedCells[activeIdx] else {
            return
        }
        let naturalH = activeCell.naturalHeight
        let originatedFromCellRest = pinchState.initialExtension <= naturalH * 1.05
        if originatedFromCellRest {
            springToCellRest(
                carriedExtensionVelocity: 0,
                cameraTranslationVelocity: 0,
                commit: .cancelled
            )
        } else {
            springToChatRest(
                forCellAt: activeIdx,
                carriedExtensionVelocity: 0,
                cameraTranslationVelocity: 0,
                commit: .cancelled
            )
        }
    }

    // MARK: - Spring profiles

    fileprivate func springProfile(for commit: GestureCommit) -> Spring {
        Spring(dampingRatio: commit.dampingRatio(from: physicsTuning),
               response: physicsTuning.springResponse)
    }

    /// Write `activeCell.heightConstraint.constant` per-tick. Suppressed
    /// CATransaction avoids implicit animation fighting the spring's
    /// per-frame writes; pushes new extension state into the cell's setCamera
    /// so alpha curves track the spring.
    private func applyExtensionTick() {
        guard let value = extensionAnimator.value,
              let idx = activeCellIndex,
              let cell = instantiatedCells[idx],
              let heightC = cell.heightConstraint else { return }
        CATransaction.withSuppressedActions {
            heightC.constant = value
            contentHost.layoutIfNeeded()
            cell.setCamera(camera, viewport: bounds)
            updateNeighborTranslations()
            updateEdgeMaskAlphas()
            onCameraChanged?(camera, bounds)
        }
    }

    /// Engages both springs: camera translation collapses to pre-pinch scroll,
    /// extension collapses to naturalHeight. activeCellIndex clears at spring
    /// completion (active-cell-pool-protection holds throughout).
    func animateCameraToCellRest() {
        springToCellRest(carriedExtensionVelocity: 0)
    }

    // MARK: - Chat-rest CABasicAnimation chrome

    /// Public entry — tap-to-chat. Guarded against re-entry (in-flight morph)
    /// and tap-during-active-cell. The internal Path called by pinch .ended
    /// commit is unguarded so pinch-to-chat commits still work with
    /// activeCellIndex pre-set at .began.
    func animateCameraToChatRest(forCellAt k: Int) {
        let count = cellCount()
        guard k >= 0, k < count else { return }
        guard let activeCell = instantiatedCells[k] else { return }
        guard contentHost.layer.animation(forKey: MorphAnimationKey.windupScale.rawValue) == nil else { return }
        guard isQuiet else { return }

        // Apple HIG vestibular-trigger compliance: when Reduce Motion is on,
        // snap to chat-rest end-state synchronously instead of running the
        // 1.5s arc morph. The snap is end-state-equivalent (Decision X3 /
        // 9R.4.5) — chrome alphas + counter-scale + contentHost transform
        // all match the morph's t=1.0 state.
        if UIAccessibility.isReduceMotionEnabled {
            snapToChatRestState(forCellAt: k)
            onMorphRevealReady?(k)
            return
        }

        setActiveCellIndex(k)
        contentHost.bringSubviewToFront(activeCell)
        pinchRecognizer.isEnabled = false

        let now = CACurrentMediaTime()
        let windupDuration: CFTimeInterval = MorphTiming.windupDuration
        let totalMorphDuration: CFTimeInterval = MorphTiming.totalMorphDuration

        let windupContribution: CGFloat = MorphTiming.windupContribution
        let liftEndMagnitude: CGFloat = MorphTiming.liftEndMagnitude
        let naturalH = activeCell.naturalHeight
        let viewportCoverageHeight = bounds.height + 2 * liftEndMagnitude + MorphTiming.viewportCoveragePad
        let chatRestFactor: CGFloat = naturalH > 0 ? viewportCoverageHeight / naturalH : MorphTiming.chatRestFactorFallback
        let finalScale = chatRestFactor
        let zoomContribution = finalScale - 1.0 - windupContribution

        let zoomLandingCP = MorphCurves.zoomLanding
        let zoomLandingTiming = CAMediaTimingFunction(controlPoints: zoomLandingCP.0, zoomLandingCP.1, zoomLandingCP.2, zoomLandingCP.3)
        let translateLandingCP = MorphCurves.translateLanding
        let translateLandingTiming = CAMediaTimingFunction(controlPoints: translateLandingCP.0, translateLandingCP.1, translateLandingCP.2, translateLandingCP.3)

        let windupScale = Self.makeCAAnimation(
            keyPath: "transform.scale", from: 0, to: windupContribution,
            duration: windupDuration, beginTime: now,
            timing: CAMediaTimingFunction(name: .easeOut), additive: true)

        let zoomScale = Self.makeCAAnimation(
            keyPath: "transform.scale", from: 0, to: zoomContribution,
            duration: totalMorphDuration, beginTime: now,
            timing: zoomLandingTiming, additive: true)

        let translate = Self.makeCAAnimation(
            keyPath: "transform.translation.y", from: 0, to: MorphTiming.translateYTarget,
            duration: totalMorphDuration, beginTime: now,
            timing: translateLandingTiming, additive: true)

        let cellOffsetFromViewportCenter = activeCell.frame.midY - camera.translation
        let centeringTranslate = -cellOffsetFromViewportCenter * finalScale

        let centering = Self.makeCAAnimation(
            keyPath: "transform.translation.y", from: 0, to: centeringTranslate,
            duration: totalMorphDuration, beginTime: now,
            timing: zoomLandingTiming, additive: true)

        contentHost.layer.add(windupScale, forKey: MorphAnimationKey.windupScale.rawValue)
        contentHost.layer.add(zoomScale, forKey: MorphAnimationKey.zoomScale.rawValue)
        contentHost.layer.add(translate, forKey: MorphAnimationKey.windupTranslate.rawValue)
        contentHost.layer.add(centering, forKey: MorphAnimationKey.morphCentering.rawValue)

        let chromeProfile = CellView.MorphChromeProfile(
            counterScale: 1.0 / finalScale,
            centerLabelDuration: totalMorphDuration,
            centerLabelBeginTime: now
        )
        activeCell.performMorphChromeTransition(profile: chromeProfile)

        let revealReadyDelay: TimeInterval = totalMorphDuration + MorphTiming.revealReadyDelay
        let revealK = k
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            // Suppress fire if the morph was abandoned mid-flight (pinch
            // .began on another cell, reloadData, or activeCell cleared).
            guard self.activeCellIndex == revealK else { return }
            self.onMorphRevealReady?(revealK)
            self.pendingRevealWorkItem = nil
        }
        pendingRevealWorkItem?.cancel()
        pendingRevealWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + revealReadyDelay, execute: workItem)
    }

    /// Reduce-Motion bypass for the tap-to-chat morph. Synchronous one-frame
    /// transition to the chat-rest end-state. Math is end-state-equivalent
    /// to the morph's t=1.0 state per Decision X3 / 9R.4.5 — geometry +
    /// 4 chrome alphas + center label visibility + center label counter-scale
    /// + contentHost transform reset all written in one suppressed CATransaction.
    /// Without the full reset, Reduce-Motion users would land at chat-rest
    /// with visible chrome and invisible center label (Pillar 10.1 violation).
    private func snapToChatRestState(forCellAt k: Int) {
        guard let cell = instantiatedCells[k], let heightC = cell.heightConstraint else { return }
        let naturalH = cell.naturalHeight
        guard naturalH > 0, bounds.height > 0 else { return }
        let chatRestFactor = chatRestScale(naturalHeight: naturalH)
        let labelCounterScale = 1.0 / chatRestFactor

        CATransaction.withSuppressedActions {
            // Geometry — match the morph's t=1.0 destination.
            heightC.constant = naturalH * chatRestFactor
            camera = Camera(translation: cell.frame.midY)
            applyCameraTransform()
            contentHost.layoutIfNeeded()
            setActiveCellIndex(k)

            cell.snapToChatRestChromeEndState(counterScale: labelCounterScale)

            // contentHost transform reset — the morph applies a sin-bell arc
            // transform mid-flight; the snap path must clear it explicitly
            // so the final state equals identity.
            contentHost.layer.transform = CATransform3DIdentity
        }
        pinchRecognizer.isEnabled = false
    }

    /// Reduce-Motion bypass for the reverse-pinch settle. Synchronous snap to
    /// the cell-rest end-state. End-state-equivalent to springToCellRest's
    /// terminal state — camera at lastCellRestScrollY + bounds.height/2,
    /// cell at naturalHeight, activeCellIndex cleared, sibling order restored.
    private func snapToCellRestState(activeCell: CellView, heightC: NSLayoutConstraint) {
        CATransaction.withSuppressedActions {
            heightC.constant = activeCell.naturalHeight
            camera = Camera(translation: lastCellRestScrollY + bounds.height / 2)
            applyCameraTransform()
            contentHost.layer.transform = CATransform3DIdentity
            activeCell.stateController?.composerIsFirstResponder = false
        }
        setActiveCellIndex(nil)
        restoreNaturalSiblingOrder()
    }

    /// Internal chat-rest path. Called by `animateCameraToChatRest` (tap)
    /// and `handlePinchEnded` commit branch (with carried velocity).
    /// Sub-1pt/s velocities floor to 0 via `CameraAnimator.safeVel`.
    fileprivate func playTapToChatMorph(forCellAt k: Int) {
        // Apple HIG vestibular-trigger compliance: when Reduce Motion is on,
        // snap to chat-rest end-state synchronously (mirror animateCameraToChatRest
        // TC:1280). The snap is end-state-equivalent to the morph's t=1.0 state.
        if UIAccessibility.isReduceMotionEnabled {
            snapToChatRestState(forCellAt: k)
            onMorphRevealReady?(k)
            return
        }
        setActiveCellIndex(k)
        guard let activeCell = instantiatedCells[k],
              let heightC = activeCell.heightConstraint else { return }
        contentHost.bringSubviewToFront(activeCell)
        pinchRecognizer.isEnabled = false

        let naturalH = activeCell.naturalHeight
        guard naturalH > 0, bounds.height > 0 else { return }
        let chatRestFactor = chatRestScale(naturalHeight: naturalH)
        let cameraTarget = activeCell.frame.midY
        let extensionTarget = naturalH * chatRestFactor

        // §36.3.1 — pinch-commit chrome symmetry with tap-forward. Without
        // this call, pinch-commit forward leaves cell-rest chrome at alpha=1
        // throughout the 1.2s morph AND no day-marker emerges (only chatVC's
        // headerLabel appears via crossFade). Calling performMorphChromeTransition
        // here mirrors animateCameraToChatRest's call at TC:1307 with
        // masterTimerDuration (1.2s) as the centerLabelDuration.
        let chromeProfile = CellView.MorphChromeProfile(
            counterScale: 1.0 / chatRestFactor,
            centerLabelDuration: MorphTiming.masterTimerDuration,
            centerLabelBeginTime: CACurrentMediaTime()
        )
        activeCell.performMorphChromeTransition(profile: chromeProfile)

        let profile = springProfile(for: .tapToChat)
        extensionAnimator.spring = profile
        extensionAnimator.completion = nil
        cameraAnimator.animate(
            to: Camera(translation: cameraTarget),
            velocity: .zero,
            spring: profile
        )
        assert(extensionAnimator.spring.response == cameraAnimator.responseForTesting,
               "Animator coordination invariant: camera + extension MUST share spring.response")
        cameraAnimator.stop(immediately: true)
        extensionAnimator.stop(immediately: true)

        let choreo = MorphChoreography(
            activeCellIndex: k,
            startCameraY: camera.translation,
            endCameraY: cameraTarget,
            startHeight: heightC.constant,
            endHeight: extensionTarget,
            unifiedArcYMagnitude: MorphTiming.unifiedArcYMagnitude,
            unifiedArcZMagnitude: MorphTiming.unifiedArcZMagnitude,
            duration: MorphTiming.masterTimerDuration,
            chatRestFactor: chatRestFactor
        )
        let revealK = k
        morphChoreographer.engage(choreo) { [weak self] in
            guard let self else { return }
            CATransaction.withSuppressedActions {
                self.contentHost.layer.transform = CATransform3DIdentity
            }
            self.updateNeighborTranslations()
            self.onMorphRevealReady?(revealK)
        }
    }

    fileprivate func springToChatRest(
        forCellAt k: Int,
        carriedExtensionVelocity: CGFloat,
        cameraTranslationVelocity: CGFloat,
        commit: GestureCommit
    ) {
        setActiveCellIndex(k)
        guard let activeCell = instantiatedCells[k],
              let heightC = activeCell.heightConstraint else { return }
        contentHost.bringSubviewToFront(activeCell)
        pinchRecognizer.isEnabled = false

        let naturalH = activeCell.naturalHeight
        guard naturalH > 0, bounds.height > 0 else { return }
        let chatRestFactor = chatRestScale(naturalHeight: naturalH)
        let cameraTarget = activeCell.frame.midY
        let extensionTarget = naturalH * chatRestFactor

        let profile = springProfile(for: commit)
        extensionAnimator.spring = profile
        extensionAnimator.completion = nil

        cameraAnimator.animate(
            to: Camera(translation: cameraTarget),
            velocity: CameraVelocity(translationVelocity: cameraTranslationVelocity),
            spring: profile
        )
        assert(extensionAnimator.spring.response == cameraAnimator.responseForTesting,
               "Animator coordination invariant: camera + extension MUST share spring.response")

        extensionAnimator.value = heightC.constant
        extensionAnimator.target = extensionTarget
        extensionAnimator.velocity = carriedExtensionVelocity
        extensionAnimator.start()
    }

    func cancelInFlightAnimations() {
        morphChoreographer.stop()
        cameraAnimator.stop(immediately: true)
        extensionAnimator.stop(immediately: true)
        pendingRevealWorkItem?.cancel()
        pendingRevealWorkItem = nil
        // K7 held CABasicAnimations are attached directly to contentHost.layer
        // (isRemovedOnCompletion=false) and survive scene deactivation. Clear
        // them here so reactivation doesn't see a stuck cane-curve transform.
        CATransaction.withSuppressedActions {
            contentHost.layer.removeAnimation(forKey: MorphAnimationKey.windupScale.rawValue)
            contentHost.layer.removeAnimation(forKey: MorphAnimationKey.zoomScale.rawValue)
            contentHost.layer.removeAnimation(forKey: MorphAnimationKey.windupTranslate.rawValue)
            contentHost.layer.removeAnimation(forKey: MorphAnimationKey.morphCentering.rawValue)
            contentHost.layer.transform = CATransform3DIdentity
        }
    }

    // MARK: - Normalize to chat-rest (post-cane-curve / post-pinch-commit cleanup)

    /// Reset canvas to the clean chat-rest end-state in the canvas.alpha=0 window.
    /// Runs once between crossFade completion and blurFadeOut completion.
    /// Idempotent (P19.3).
    ///
    /// Path differences handled by single normalize:
    /// - Tap path: removes 4 held cane-curve CABasicAnimations; resets transform;
    ///   updates camera to center the cell (cane curve never updated camera).
    /// - Pinch-commit path: most steps are no-ops because MorphChoreographer
    ///   already left state clean. The setCamera call refreshes chrome alphas
    ///   that pinch-commit's morphInProgress gate prevented setCamera from
    ///   updating during the morph.
    func normalizeToChatRest(activeCellIndex: Int) {
        guard let cell = instantiatedCells[activeCellIndex] else {
            assertionFailure("normalizeToChatRest called with invalid activeCellIndex \(activeCellIndex)")
            return
        }
        // N43 — K12 atomic handoff (CF-5 fix). All writes — K7 animation
        // removal, contentHost.transform reset, height extension, AND camera
        // recentering (which writes sublayerTransform) — must be ONE
        // CATransaction.commit so no intermediate render frame surfaces.
        // Under the nav pivot, this becomes the moment scale transfers from
        // .transform (K7) to .sublayerTransform (camera); without atomicity
        // there's a frame where both are at chat-rest values (compound-scale)
        // or both are at identity (visible cell-rest snap). Nested CATransaction
        // is reentrant-safe in CoreAnimation; centerCameraOnActiveCell's inner
        // suppression composes into the outer boundary.
        CATransaction.withSuppressedActions {
            clearCaneCurveAnimations()
            resetContentHostTransform()
            clearChatRestCenterLabelTransientState(on: cell)
            extendCellToChatRest(cell: cell)
            centerCameraOnActiveCell(cell: cell)
        }
    }

    // MARK: - Normalize helpers (P11.1 SRP per helper)

    /// Remove the 4 held cane-curve CABasicAnimations from contentHost.layer.
    /// No-op for pinch-commit path (MorphChoreographer doesn't attach these).
    private func clearCaneCurveAnimations() {
        contentHost.layer.removeAnimation(forKey: MorphAnimationKey.windupScale.rawValue)
        contentHost.layer.removeAnimation(forKey: MorphAnimationKey.zoomScale.rawValue)
        contentHost.layer.removeAnimation(forKey: MorphAnimationKey.windupTranslate.rawValue)
        contentHost.layer.removeAnimation(forKey: MorphAnimationKey.morphCentering.rawValue)
    }

    /// Reset contentHost.layer.transform to identity.
    /// Tap path: undoes the held cane-curve transform composition.
    /// Pinch-commit path: idempotent (already identity).
    private func resetContentHostTransform() {
        contentHost.layer.transform = CATransform3DIdentity
    }

    /// Clear chatRestCenterLabel's transient state from a forward morph.
    private func clearChatRestCenterLabelTransientState(on cell: CellView) {
        cell.chatRestCenterLabel.layer.removeAnimation(forKey: MorphAnimationKey.centerLabelOpacity.rawValue)
        cell.chatRestCenterLabel.transform = .identity
        cell.chatRestCenterLabel.alpha = 0
    }

    /// Extend cell.heightConstraint to chat-rest extension (bounds.height).
    /// Tap path: corrects from naturalH=200 baseline (cane curve doesn't extend).
    /// Pinch-commit path: no-op (heightConstraint already at chatRestExt).
    private func extendCellToChatRest(cell: CellView) {
        cell.heightConstraint?.constant = bounds.height
        contentHost.layoutIfNeeded()
    }

    /// Center the canvas camera on the active cell (per §16.5 camera position fix).
    /// Refreshes chrome alphas on the active cell at progress=1 (the §16.6
    /// pinch-commit chrome fix).
    ///
    /// IMPORTANT: bypasses setCamera deliberately. setCamera's
    /// updateVisibleCells call would trigger installLayout on every neighbor,
    /// which schedules the centerY-anchored DEBUG assertion (CV:248-253) via
    /// dispatch_async. By the time the async assert fires, updateNeighborTranslations
    /// has applied followActive transforms of ±half-growth (±322pt at chat-rest
    /// extension), so frame.midY ≠ naturalCenterY and the assert fails. The
    /// assertion isn't wrong; it just doesn't account for transforms. Avoiding
    /// updateVisibleCells here side-steps the crash without modifying the
    /// pre-existing invariant check.
    private func centerCameraOnActiveCell(cell: CellView) {
        camera = Camera(translation: cell.frame.midY)
        hasExternalCameraWrite = true
        CATransaction.withSuppressedActions {
            applyCameraTransform()
            // Refresh chrome alphas on the active cell at progress=1 (chat-rest).
            cell.setCamera(camera, viewport: bounds)
            updateNeighborTranslations()
            updateEdgeMaskAlphas()
        }
        onCameraChanged?(camera, bounds)
    }

    // MARK: - Memory pressure (§35.3.1)

    /// Respond to memory pressure by aggressively evicting non-active keyed-pool
    /// cells and their attached chatContent containers. Active cell is protected.
    /// Currently-instantiated non-active cells are KEPT.
    /// P19.3 idempotent.
    func flushPoolForMemoryPressure() {
        let activeID = activeConversationIDForFlush()
        let evictableIDs = poolOrder.filter { $0 != activeID }

        for id in evictableIDs {
            evictKeyedPoolEntry(id: id)
        }

        evictUnboundCellPoolEntries()
    }

    private func activeConversationIDForFlush() -> UUID? {
        activeCellIndex.flatMap { instantiatedCells[$0]?.activeConversationID }
    }

    private func evictKeyedPoolEntry(id: UUID) {
        guard let cell = cellPoolByConversationID.removeValue(forKey: id) else { return }

        cell.endEditing(true)
        cell.teardownChatContentForMemoryPressure()

        if let poolIdx = cellPool.firstIndex(where: { $0 === cell }) {
            cellPool.remove(at: poolIdx)
        }
        if let orderIdx = poolOrder.firstIndex(of: id) {
            poolOrder.remove(at: orderIdx)
        }
    }

    private func evictUnboundCellPoolEntries() {
        cellPool.removeAll { $0.activeConversationID == nil }
    }

    func applyMorphTickCameraWrite(translation: CGFloat, cell: CellView) {
        CATransaction.withSuppressedActions {
            camera = Camera(translation: translation)
            applyCameraTransform()
            updateVisibleCells()
            cell.setCamera(camera, viewport: bounds)
            updateNeighborTranslations()
            updateEdgeMaskAlphas()
            onCameraChanged?(camera, bounds)
        }
    }

    // MARK: - Cell-rest spring coordination

    // MARK: - Reverse cinematography (§24 / Phase 11)

    /// Feature flag for commit-driven reverse cinematography per §24.4.
    /// Default: false (gesture-driven shrink + spring is the V1 default per D14).
    /// When true, handlePinchEnded routes `.pinchToCells` to playPinchToCellsMorph
    /// instead of springToCellRest, mirroring forward pinch-commit's MorphChoreographer.
    static var reverseCinematographyEnabled: Bool = false

    /// Commit-driven reverse cinematography (§24.4). Engages MorphChoreographer
    /// with an INVERSE choreography: cell collapses from chat-rest to cell-rest,
    /// camera animates from activeCell.frame.midY to lastCellRestScrollY origin,
    /// contentHost.layer.transform does a sin-bell Y/Z arc.
    ///
    /// At completion: chrome alphas refresh via setCamera (gate released because
    /// morphChoreographer.isRunning becomes false). activeCellIndex clears via
    /// setActiveCellIndex(nil); restoreNaturalSiblingOrder runs.
    fileprivate func playPinchToCellsMorph(
        forCellAt k: Int,
        carriedExtensionVelocity: CGFloat
    ) {
        guard let activeCell = instantiatedCells[k],
              let heightC = activeCell.heightConstraint else { return }

        let naturalH = activeCell.naturalHeight
        guard naturalH > 0, bounds.height > 0 else { return }
        let chatRestFactor = chatRestScale(naturalHeight: naturalH)

        let cameraStart = camera.translation
        let cameraEnd = lastCellRestScrollY + bounds.height / 2

        let choreo = MorphChoreography(
            activeCellIndex: k,
            startCameraY: cameraStart,
            endCameraY: cameraEnd,
            startHeight: heightC.constant,
            endHeight: naturalH,
            unifiedArcYMagnitude: MorphTiming.unifiedArcYMagnitude,
            unifiedArcZMagnitude: MorphTiming.unifiedArcZMagnitude,
            duration: MorphTiming.masterTimerDuration,
            chatRestFactor: chatRestFactor
        )

        morphChoreographer.engage(choreo) { [weak self] in
            guard let self else { return }
            CATransaction.withSuppressedActions {
                self.contentHost.layer.transform = CATransform3DIdentity
            }
            self.updateNeighborTranslations()
            self.updateEdgeMaskAlphas()
            // setCamera fires cell.setCamera which now (morphInProgress=false)
            // refreshes chrome alphas to cell-rest values per the smoothstep curves.
            self.setCamera(self.camera)
            self.setActiveCellIndex(nil)
            self.restoreNaturalSiblingOrder()
        }
    }

    /// Internal cell-rest path. activeCellIndex clears only when BOTH springs
    /// settle AND heightConstraint reaches naturalHeight. The
    /// `tryClearActiveCellAtRest` coordination makes the clear robust under
    /// camera same-target short-circuit (the prior camera-completion-only
    /// version fired synchronously under same-target and left
    /// heightConstraint extended with activeCellIndex=nil).
    fileprivate func springToCellRest(
        carriedExtensionVelocity: CGFloat,
        cameraTranslationVelocity: CGFloat = 0,
        commit: GestureCommit = .pinchToCells
    ) {
        guard let activeIdx = activeCellIndex,
              let activeCell = instantiatedCells[activeIdx],
              let heightC = activeCell.heightConstraint else {
            setActiveCellIndex(nil)
            restoreNaturalSiblingOrder()
            return
        }

        // Apple HIG vestibular-trigger compliance for reverse direction:
        // snap to cell-rest end-state synchronously instead of running a
        // ~0.4s spring animation through scale = chatRestFactor → 1.0.
        if UIAccessibility.isReduceMotionEnabled {
            snapToCellRestState(activeCell: activeCell, heightC: heightC)
            return
        }

        let cameraTarget = lastCellRestScrollY + bounds.height / 2
        let activeIdxCaptured = activeIdx

        let profile = springProfile(for: commit)
        extensionAnimator.spring = profile

        cameraAnimator.animate(
            to: Camera(translation: cameraTarget),
            velocity: CameraVelocity(translationVelocity: cameraTranslationVelocity),
            spring: profile
        ) { [weak self] in
            self?.tryClearActiveCellAtRest(expectedIdx: activeIdxCaptured)
        }
        assert(extensionAnimator.spring.response == cameraAnimator.responseForTesting,
               "Animator coordination invariant: camera + extension MUST share spring.response")

        extensionAnimator.value = heightC.constant
        extensionAnimator.target = activeCell.naturalHeight
        extensionAnimator.velocity = carriedExtensionVelocity
        extensionAnimator.completion = { [weak self] event in
            if case .finished = event {
                self?.tryClearActiveCellAtRest(expectedIdx: activeIdxCaptured)
            }
        }
        extensionAnimator.start()
    }

    /// Clear activeCellIndex only when BOTH springs reach their target values.
    /// Checks VALUE vs TARGET rather than animator state, because
    /// SpringAnimator fires completion BEFORE updating its state to `.ended`
    /// — inside the completion the animator's own state is still `.running`.
    /// Race-safe against camera same-target sync completion.
    private func tryClearActiveCellAtRest(expectedIdx: Int) {
        guard activeCellIndex == expectedIdx else { return }
        guard let cell = instantiatedCells[expectedIdx] else { return }
        let cellRestTarget = lastCellRestScrollY + bounds.height / 2
        let cameraAtTarget = abs(camera.translation - cellRestTarget) < 1.0
        let extensionValue = extensionAnimator.value ?? 0
        let extensionAtTarget = abs(extensionValue - cell.naturalHeight) < 1.0
        if cameraAtTarget && extensionAtTarget {
            // Clear stale first-responder flag — the keyboard was dismissed at
            // gesture begin via endEditing(true) but composerIsFirstResponder
            // stays true until cleared. Without this, a subsequent forward
            // re-engagement reads the stale true and pops the keyboard unbidden.
            cell.stateController?.composerIsFirstResponder = false
            setActiveCellIndex(nil)
            restoreNaturalSiblingOrder()
        }
    }

}

// MARK: - UIGestureRecognizerDelegate

extension TimelineCanvas: UIGestureRecognizerDelegate {

    /// Pan ↔ pinch only. Returning `true` for all pairs would let future tap
    /// or accessibility recognizers fire simultaneously with pan in subtle
    /// ways. Match by type, not instance.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        let panPinchPair = (gestureRecognizer is UIPanGestureRecognizer
                            && otherGestureRecognizer is UIPinchGestureRecognizer)
                        || (gestureRecognizer is UIPinchGestureRecognizer
                            && otherGestureRecognizer is UIPanGestureRecognizer)
        return panPinchPair
    }
}
