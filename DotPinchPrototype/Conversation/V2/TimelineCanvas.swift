// TimelineCanvas.swift — V2 dual-axis substrate.
// Camera is a single page-y scalar (Camera.translation); width is invariant.
// Height extension happens per-active-cell via NSLayoutConstraint. Cells live
// as subviews of contentHost; contentHost.layer.sublayerTransform carries the
// camera (pure y-translation, no scale).

import UIKit
import QuartzCore

final class TimelineCanvas: UIView, UIGestureRecognizerDelegate {

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

    /// UIKit's `.began` scale may be the prior gesture's terminal scale; the
    /// `recognizer.scale / pinchInitialScale` divide in `.changed` cancels.
    private var pinchInitialScale: CGFloat = 1.0
    private var pinchInitialExtension: CGFloat = 0

    /// Page-coord Y of the centroid at `.began`. `.changed` writes camera so
    /// this page-Y stays mapped to the current centroid viewport-Y as the cell
    /// extends. Locked at `.began` only — recomputing during `.changed` would
    /// degenerate the formula to a constant, eliminating finger-tracking.
    private var pinchAnchorPageY: CGFloat = 0

    /// Previous-tick centroid state for translation velocity at `.ended`.
    /// Used ONLY by `.ended`; never read during `.changed`.
    private var pinchPreviousCentroidY: CGFloat = 0
    private var pinchPreviousCentroidTimestamp: CFTimeInterval = 0

    // MARK: - Camera animation

    let animationController = AnimationController()

    /// Fires when the tap-to-chat morph reaches its settled state.
    var onMorphRevealReady: ((Int) -> Void)?

    private(set) var cameraAnimator: CameraAnimator!

    /// Extension animator. Shares Spring params with `cameraAnimator` so the
    /// two springs share natural frequency (coordination invariant).
    private(set) var extensionAnimator: SpringAnimator<CGFloat>!

    /// Deterministic master timer (CADisplayLink-based) for tap-to-chat.
    /// Finite duration + linear master clock + per-property curves — replaces
    /// a spring whose asymptotic settling tail reads as "still animating".
    private var masterTimer: CADisplayLink?
    /// DisplayLink-local accumulator. Sums `link.targetTimestamp - link.timestamp`
    /// per tick rather than subtracting wall-clock `CACurrentMediaTime` —
    /// when backgrounded mid-morph the link pauses, the accumulator pauses
    /// with it, and on foreground resume `rawT` continues from where it
    /// left off instead of snapping to t=1.0.
    private var masterTimerElapsed: TimeInterval = 0
    private var masterTimerDuration: TimeInterval = 5.0
    private var masterTimerCompletion: (() -> Void)?

    // Snapshots captured at tap, frozen for the duration of the master timer.
    private var masterStartHeight: CGFloat = 0
    private var masterEndHeight: CGFloat = 0
    private var masterStartCameraY: CGFloat = 0
    private var masterEndCameraY: CGFloat = 0
    private var masterUnifiedArcMagnitude: CGFloat = 0
    private var masterActiveCellIndex: Int? = nil

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

    override init(frame: CGRect) {
        super.init(frame: frame)
        installViewHierarchy()
        installPageGradient()
        installPanRecognizer()
        installPinchRecognizer()
        // CameraAnimator references self — construct after super.init.
        cameraAnimator = CameraAnimator(canvas: self, controller: animationController)
        extensionAnimator = SpringAnimator<CGFloat>(
            controller: animationController,
            spring: Spring(
                dampingRatio: PinchTuning.springDamping,
                response: PinchTuning.springResponse
            )
        )
        extensionAnimator.valueChanged = { [weak self] _ in
            self?.applyExtensionTick()
        }
        applyCameraTransform()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("TimelineCanvas does not support NSCoder decoding")
    }

    deinit {
        masterTimer?.invalidate()
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
        let sRGB = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let topColor = Theme.Page.top.cgColor.converted(
            to: sRGB, intent: .defaultIntent, options: nil) ?? Theme.Page.top.cgColor
        let bottomColor = Theme.Page.bottom.cgColor.converted(
            to: sRGB, intent: .defaultIntent, options: nil) ?? Theme.Page.bottom.cgColor
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

    /// Three-stop sRGB-locked gradient. The sRGB CGColorSpace lock is
    /// load-bearing: on wide-gamut sims (Display-P3), unlocked CGColors
    /// desaturate warm pinks. CAGradientLayer interpolates in sRGB regardless
    /// of the device's native display gamut.
    private func installPageGradient() {
        let sRGB = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let topColor = Theme.Page.top.cgColor.converted(to: sRGB, intent: .defaultIntent, options: nil) ?? Theme.Page.top.cgColor
        let midColor = Theme.Page.surface.cgColor.converted(to: sRGB, intent: .defaultIntent, options: nil) ?? Theme.Page.surface.cgColor
        let bottomColor = Theme.Page.bottom.cgColor.converted(to: sRGB, intent: .defaultIntent, options: nil) ?? Theme.Page.bottom.cgColor
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
        let p = currentCanvasProgress()

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
    func currentCanvasProgress() -> CGFloat {
        guard let idx = activeCellIndex, let activeCell = instantiatedCells[idx] else { return 0 }
        let naturalH = activeCell.naturalHeight
        guard naturalH > 0, bounds.height > 0 else { return 0 }
        let chatRestFactor = bounds.height / naturalH
        let chatRestRange = chatRestFactor - 1.0
        guard chatRestRange > 1e-6 else { return 0 }
        let extensionFactor = activeCell.bounds.height / naturalH
        return min(1.0, max(0.0, (extensionFactor - 1.0) / chatRestRange))
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

    static func viewportPoint(fromPage pagePoint: CGPoint, camera: Camera, viewportCenter: CGPoint) -> CGPoint {
        CGPoint(
            x: pagePoint.x,
            y: pagePoint.y - camera.translation + viewportCenter.y
        )
    }

    static func pagePoint(fromViewport viewportPoint: CGPoint, camera: Camera, viewportCenter: CGPoint) -> CGPoint {
        CGPoint(
            x: viewportPoint.x,
            y: viewportPoint.y - viewportCenter.y + camera.translation
        )
    }

    // MARK: - Cell layout calculator

    /// Single-column; equals viewport width. Recomputed on layout to reflect
    /// the latest viewport size after rotation/resize.
    var pageWidth: CGFloat {
        bounds.width
    }

    /// Sum of cell heights + interior gaps. No trailing spacing past the last cell.
    func pageHeight() -> CGFloat {
        let ys = accumulatedYs()
        return ys.last ?? 0
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

        let visibleRange = cellIndices(in: visiblePageRect, plusMargin: Self.cullMargin)

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
            .sorted { $0.index < $1.index }
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
        let progress = currentCanvasProgress()
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
                cell.transform = .identity
            }
            return
        }
        let halfGrowth = (activeCell.bounds.height - activeCell.naturalHeight) / 2
        for (index, cell) in instantiatedCells {
            if index == activeIdx {
                cell.transform = .identity
            } else {
                let ty: CGFloat = (index < activeIdx) ? -halfGrowth : +halfGrowth
                cell.transform = CGAffineTransform(translationX: 0, y: ty)
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
        let pageH = pageHeight()
        let minT = viewportH / 2
        let maxT = max(minT, pageH - viewportH / 2)
        return rubberband(
            value: rawT,
            range: minT...maxT,
            interval: viewportH,
            c: 0.55
        )
    }

    // MARK: - Pinch gesture

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

        pinchAnchorPageY = anchorPage.y

        // Unconditional overwrite so a prior gesture's stale state cannot leak in.
        pinchPreviousCentroidY = screenCenter.y
        pinchPreviousCentroidTimestamp = CACurrentMediaTime()

        pinchInitialScale = recognizer.scale

        if let idx = anchorCellIdx, let activeCell = instantiatedCells[idx] {
            pinchInitialExtension = activeCell.heightConstraint?.constant ?? activeCell.naturalHeight
            // Raise the active cell so its extension renders ABOVE neighbors.
            contentHost.bringSubviewToFront(activeCell)
        } else {
            pinchInitialExtension = 0
        }
    }

    /// layoutIfNeeded forces the solve so cell.frame tracks the new height
    /// before subsequent reads (hit-test timing).
    internal func handlePinchChanged(_ recognizer: UIPinchGestureRecognizer) {
        guard pinchInitialScale > 1e-6 else { return }
        guard let activeIdx = activeCellIndex,
              let activeCell = instantiatedCells[activeIdx],
              let heightC = activeCell.heightConstraint else { return }
        let naturalH = activeCell.naturalHeight
        guard naturalH > 0, bounds.height > 0 else { return }

        let scaleFactor = recognizer.scale / pinchInitialScale
        let rawNewExtension = pinchInitialExtension * scaleFactor

        // Clamp to [naturalHeight, naturalHeight × chatRestFactor × 1.15].
        // The 1.15 headroom is the rubberband budget for over-pinch.
        let chatRestExtensionFactor = bounds.height / naturalH
        let ceiling = naturalH * chatRestExtensionFactor * 1.15
        let clampedExtension = min(ceiling, max(naturalH, rawNewExtension))

        // layoutIfNeeded forces cell.bounds.height to track before the camera
        // update propagates to cell.setCamera (alpha curves read bounds).
        CATransaction.withSuppressedActions {
            heightC.constant = clampedExtension
            contentHost.layoutIfNeeded()
        }

        // Pinch anchor stability: write camera so the page-coord captured at
        // .began (pinchAnchorPageY) stays mapped to the current centroid
        // viewport-y. Derived by inverting viewportPoint(fromPage:...):
        // `camera.translation = y_page + viewport.height/2 - y_viewport`.
        let currentCentroidViewportY = recognizer.location(in: self).y
        let newTranslation = pinchAnchorPageY + bounds.height / 2 - currentCentroidViewportY
        guard newTranslation.isFinite else { return }
        setCamera(Camera(translation: newTranslation))

        // Update AFTER setCamera so observers reading inside onCameraChanged
        // see consistent state. Reuse the captured centroid Y — do NOT call
        // recognizer.location again (UIKit could return a different value).
        pinchPreviousCentroidY = currentCentroidViewportY
        pinchPreviousCentroidTimestamp = CACurrentMediaTime()
    }

    /// Commit decision: extensionFactor-vs-threshold with velocity bias so a
    /// fast release past midpoint commits even at modest extension. Both
    /// springs (camera + extension) use matched `PinchTuning` params.
    internal func handlePinchEnded(_ recognizer: UIPinchGestureRecognizer) {
        defer {
            pinchInitialScale = 1.0
            pinchInitialExtension = 0
        }

        guard let activeIdx = activeCellIndex,
              let activeCell = instantiatedCells[activeIdx],
              let heightC = activeCell.heightConstraint else { return }
        let naturalH = activeCell.naturalHeight
        guard naturalH > 0, bounds.height > 0 else { return }

        let chatRestFactor = bounds.height / naturalH
        let currentFactor = heightC.constant / naturalH
        let commitThreshold: CGFloat = (1.0 + chatRestFactor) / 2.0

        let pinchVel = recognizer.velocity.isFinite ? recognizer.velocity : 0
        let extensionVel = pinchInitialExtension * pinchVel
        let velocityBias = (extensionVel / naturalH) * 0.15
        let weightedFactor = currentFactor + velocityBias

        let commitToChatRest = weightedFactor > commitThreshold

        // Translation velocity from centroid samples. Derived from the anchor
        // formula: d(translation)/dt = -d(centroidY)/dt. Finger DOWN
        // (centroidY increasing) ⇒ negative translation velocity.
        let currentCentroidY = recognizer.location(in: self).y
        let nowTimestamp = CACurrentMediaTime()
        let dt = nowTimestamp - pinchPreviousCentroidTimestamp
        let cameraTranslationVelocity: CGFloat
        if dt > 1e-6 && dt.isFinite
            && currentCentroidY.isFinite && pinchPreviousCentroidY.isFinite {
            let centroidVelocity = (currentCentroidY - pinchPreviousCentroidY) / dt
            cameraTranslationVelocity = -centroidVelocity
        } else {
            cameraTranslationVelocity = 0
        }

        // Classify direction by ORIGIN × DESTINATION (NOT by recognizer scale
        // sign). Origin = pinchInitialExtension at .began (within 5% of
        // naturalH = cell-rest origin).
        let originatedFromCellRest = pinchInitialExtension <= naturalH * 1.05
        let direction: SpringDirection
        if commitToChatRest && originatedFromCellRest {
            direction = .tapToChat
        } else if commitToChatRest && !originatedFromCellRest {
            // Originated at chat-rest, partial pinch-in, released past
            // threshold → returns to chat-rest. Cancelled gesture.
            direction = .cancelled
        } else if !commitToChatRest && !originatedFromCellRest {
            direction = .pinchToCells
        } else {
            // Originated at cell-rest, released below threshold → returns
            // to cell-rest. Cancelled gesture.
            direction = .cancelled
        }

        if commitToChatRest {
            animateCameraToChatRestPath(
                forCellAt: activeIdx,
                initialVelocity: extensionVel,
                cameraTranslationVelocity: cameraTranslationVelocity,
                direction: direction
            )
        } else {
            animateCameraToCellRestPath(
                initialExtensionVelocity: extensionVel,
                cameraTranslationVelocity: cameraTranslationVelocity,
                direction: direction
            )
        }
    }

    /// UIKit-cancellation path. Distinct from `.ended` so the commit-or-bail
    /// decision does NOT run on involuntary cancellation (Control Center
    /// swipe / incoming call). Restores to whichever rest the gesture
    /// originated from with zero velocity — recognizer.scale at .cancelled
    /// is unreliable, so origin classification (pinchInitialExtension) is
    /// the only sound signal.
    internal func handlePinchCancelled(_ recognizer: UIPinchGestureRecognizer) {
        defer {
            pinchInitialScale = 1.0
            pinchInitialExtension = 0
        }
        guard let activeIdx = activeCellIndex,
              let activeCell = instantiatedCells[activeIdx] else {
            return
        }
        let naturalH = activeCell.naturalHeight
        let originatedFromCellRest = pinchInitialExtension <= naturalH * 1.05
        if originatedFromCellRest {
            animateCameraToCellRestPath(
                initialExtensionVelocity: 0,
                cameraTranslationVelocity: 0,
                direction: .cancelled
            )
        } else {
            animateCameraToChatRestPath(
                forCellAt: activeIdx,
                initialVelocity: 0,
                cameraTranslationVelocity: 0,
                direction: .cancelled
            )
        }
    }

    /// Direction classification keyed off destination + origin, NOT off
    /// recognizer.scale sign.
    fileprivate enum SpringDirection {
        case tapToChat
        case pinchToCells
        case cancelled
    }

    /// Returns a fresh `Spring` per call so callers apply the same value to
    /// both extensionAnimator and cameraAnimator (within-animation parameter
    /// identity). Response shared across all profiles.
    fileprivate func springProfile(for direction: SpringDirection) -> Spring {
        let damping: CGFloat
        switch direction {
        case .tapToChat:    damping = PinchTuning.tapToChatDamping
        case .pinchToCells: damping = PinchTuning.pinchToCellsDamping
        case .cancelled:    damping = PinchTuning.cancelledDamping
        }
        return Spring(dampingRatio: damping, response: PinchTuning.springResponse)
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
        animateCameraToCellRestPath(initialExtensionVelocity: 0)
    }

    /// Public entry — tap-to-chat. Guarded against re-entry (in-flight morph)
    /// and tap-during-active-cell. The internal Path called by pinch .ended
    /// commit is unguarded so pinch-to-chat commits still work with
    /// activeCellIndex pre-set at .began.
    func animateCameraToChatRest(forCellAt k: Int) {
        let count = cellCount()
        guard k >= 0, k < count else { return }
        guard let activeCell = instantiatedCells[k] else { return }
        guard contentHost.layer.animation(forKey: "windup.scale") == nil else { return }

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
        activeCell.morphInProgress = true

        let now = CACurrentMediaTime()
        let windupDuration: CFTimeInterval = 0.78
        let totalMorphDuration: CFTimeInterval = 1.5

        let windupContribution: CGFloat = 0.08
        let liftEndMagnitude: CGFloat = 50
        let naturalH = activeCell.naturalHeight
        let viewportCoverageHeight = bounds.height + 2 * liftEndMagnitude + 40
        let chatRestFactor: CGFloat = naturalH > 0 ? viewportCoverageHeight / naturalH : 4.92
        let finalScale = chatRestFactor
        let zoomContribution = finalScale - 1.0 - windupContribution

        let windupScale = CABasicAnimation(keyPath: "transform.scale")
        windupScale.fromValue = 0
        windupScale.toValue = windupContribution
        windupScale.duration = windupDuration
        windupScale.beginTime = now
        windupScale.timingFunction = CAMediaTimingFunction(name: .easeOut)
        windupScale.fillMode = .forwards
        windupScale.isRemovedOnCompletion = false
        windupScale.isAdditive = true

        let zoomScale = CABasicAnimation(keyPath: "transform.scale")
        zoomScale.fromValue = 0
        zoomScale.toValue = zoomContribution
        zoomScale.duration = totalMorphDuration
        zoomScale.beginTime = now
        zoomScale.timingFunction = CAMediaTimingFunction(controlPoints: 0.7, 0.0, 0.4, 1.0)
        zoomScale.fillMode = .forwards
        zoomScale.isRemovedOnCompletion = false
        zoomScale.isAdditive = true

        let translate = CABasicAnimation(keyPath: "transform.translation.y")
        translate.fromValue = 0
        translate.toValue = -50
        translate.duration = totalMorphDuration
        translate.beginTime = now
        translate.timingFunction = CAMediaTimingFunction(controlPoints: 0.0, 0.0, 0.2, 1.0)
        translate.fillMode = .forwards
        translate.isRemovedOnCompletion = false
        translate.isAdditive = true

        let cellOffsetFromViewportCenter = activeCell.frame.midY - camera.translation
        let centeringTranslate = -cellOffsetFromViewportCenter * finalScale

        let labelCounterScale = 1.0 / finalScale
        activeCell.chatRestCenterLabel.transform = CGAffineTransform(scaleX: labelCounterScale, y: labelCounterScale)

        let centering = CABasicAnimation(keyPath: "transform.translation.y")
        centering.fromValue = 0
        centering.toValue = centeringTranslate
        centering.duration = totalMorphDuration
        centering.beginTime = now
        centering.timingFunction = CAMediaTimingFunction(controlPoints: 0.7, 0.0, 0.4, 1.0)
        centering.fillMode = .forwards
        centering.isRemovedOnCompletion = false
        centering.isAdditive = true

        contentHost.layer.add(windupScale, forKey: "windup.scale")
        contentHost.layer.add(zoomScale, forKey: "zoom.scale")
        contentHost.layer.add(translate, forKey: "windup.translate")
        contentHost.layer.add(centering, forKey: "morph.centering")

        let centerLabelOpacity = CABasicAnimation(keyPath: "opacity")
        centerLabelOpacity.fromValue = 0
        centerLabelOpacity.toValue = 1
        centerLabelOpacity.duration = totalMorphDuration
        centerLabelOpacity.beginTime = now
        centerLabelOpacity.timingFunction = CAMediaTimingFunction(controlPoints: 0.85, 0.0, 0.5, 1.0)
        centerLabelOpacity.fillMode = .forwards
        centerLabelOpacity.isRemovedOnCompletion = false
        activeCell.chatRestCenterLabel.layer.add(centerLabelOpacity, forKey: "centerLabel.opacity")

        UIView.animate(withDuration: 0.08, delay: 0.0, options: [.curveEaseOut, .allowUserInteraction], animations: {
            activeCell.dateLabel.alpha = 0
        }, completion: nil)

        UIView.animate(withDuration: 0.17, delay: 0.03, options: [.curveEaseOut, .allowUserInteraction], animations: {
            activeCell.topicSummaryLabel.alpha = 0
        }, completion: nil)

        UIView.animate(withDuration: 0.20, delay: 0.08, options: [.curveEaseOut, .allowUserInteraction], animations: {
            activeCell.todayLabel.alpha = 0
            activeCell.pinchGlyph.alpha = 0
        }, completion: nil)

        let revealReadyDelay: TimeInterval = totalMorphDuration + 0.1
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
        let chatRestFactor = bounds.height / naturalH
        let labelCounterScale = 1.0 / chatRestFactor

        CATransaction.withSuppressedActions {
            // Geometry — match the morph's t=1.0 destination.
            heightC.constant = naturalH * chatRestFactor
            camera = Camera(translation: cell.frame.midY)
            applyCameraTransform()
            contentHost.layoutIfNeeded()
            setActiveCellIndex(k)

            // Chrome end-state (Decision X3 — without these the snap lands
            // visually-broken vs the morph endpoint).
            cell.dateLabel.alpha = 0
            cell.topicSummaryLabel.alpha = 0
            cell.todayLabel.alpha = 0
            cell.pinchGlyph.alpha = 0
            cell.chatRestCenterLabel.alpha = 1
            cell.chatRestCenterLabel.transform = CGAffineTransform(scaleX: labelCounterScale, y: labelCounterScale)

            // contentHost transform reset — the morph applies a sin-bell arc
            // transform mid-flight; the snap path must clear it explicitly
            // so the final state equals identity.
            contentHost.layer.transform = CATransform3DIdentity
        }
    }

    /// Internal chat-rest path. Called by `animateCameraToChatRest` (tap)
    /// and `handlePinchEnded` commit branch (with carried velocity).
    /// Sub-1pt/s velocities floor to 0 via `CameraAnimator.safeVel`.
    fileprivate func animateCameraToChatRestPath(
        forCellAt k: Int,
        initialVelocity: CGFloat,
        cameraTranslationVelocity: CGFloat = 0,
        direction: SpringDirection = .tapToChat
    ) {
        setActiveCellIndex(k)
        guard let activeCell = instantiatedCells[k],
              let heightC = activeCell.heightConstraint else { return }
        contentHost.bringSubviewToFront(activeCell)

        let naturalH = activeCell.naturalHeight
        guard naturalH > 0, bounds.height > 0 else { return }
        let chatRestFactor = bounds.height / naturalH

        // centerY-anchored cells: frame.midY is page-coord invariant under
        // extension, so it's the chat-rest camera target.
        let cameraTarget = activeCell.frame.midY
        let extensionTarget = naturalH * chatRestFactor

        // Reset extension completion to avoid a stale tryClearActiveCellAtRest
        // closure from a prior cell-rest engagement.
        let profile = springProfile(for: direction)
        extensionAnimator.spring = profile
        extensionAnimator.completion = nil

        cameraAnimator.animate(
            to: Camera(translation: cameraTarget),
            velocity: CameraVelocity(translationVelocity: cameraTranslationVelocity),
            spring: profile
        )

        if direction == .tapToChat {
            // Master-clock path. All visual properties (height, camera, Y/Z
            // arc) derive from t in `applyMasterTick`. CADisplayLink with
            // finite duration ends deterministically at t=1 — no spring
            // asymptotic tail.
            let unifiedArcMag: CGFloat = 50

            masterStartHeight = heightC.constant
            masterEndHeight = extensionTarget
            masterStartCameraY = camera.translation
            masterEndCameraY = cameraTarget
            masterUnifiedArcMagnitude = unifiedArcMag
            masterActiveCellIndex = k

            // Stop the per-direction animators that would otherwise fight us.
            cameraAnimator.stop(immediately: true)
            extensionAnimator.stop(immediately: true)

            let revealK = k
            startMasterTimer(duration: 1.2) { [weak self] in
                guard let self else { return }
                CATransaction.withSuppressedActions {
                    self.contentHost.layer.transform = CATransform3DIdentity
                }
                self.masterActiveCellIndex = nil
                self.updateNeighborTranslations()
                // Parity-Break Ledger 8B (intentional UX delta): pinch-commit
                // path now fires reveal at master-timer completion. Tap-to-chat
                // fires via the asyncAfter in animateCameraToChatRest; the two
                // entry points do not overlap (verified per 9O.6 codepath
                // trace — public method and *Path are disjoint).
                self.onMorphRevealReady?(revealK)
            }
        } else {
            // pinch-to-cells / cancelled — two-spring path (camera + extension).
            extensionAnimator.value = heightC.constant
            extensionAnimator.target = extensionTarget
            extensionAnimator.velocity = initialVelocity
            extensionAnimator.start()
        }
    }

    /// Deterministic CADisplayLink master timer. Linear raw t — outer easing
    /// stacked on per-property curves caused weird normalization. Per-property
    /// curves in applyMasterTick do their own shaping. ProMotion 120Hz is
    /// requested so the morph remains smooth even when no springs are running
    /// (otherwise the link silently drops to 60Hz mid-morph).
    private func startMasterTimer(duration: TimeInterval, completion: @escaping () -> Void) {
        masterTimer?.invalidate()
        masterTimerElapsed = 0
        masterTimerDuration = duration
        masterTimerCompletion = completion
        let link = CADisplayLink(target: self, selector: #selector(masterTimerTick(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        masterTimer = link
    }

    @objc private func masterTimerTick(_ link: CADisplayLink) {
        // DisplayLink-local time accumulator — pauses with the link when
        // backgrounded, resumes from where it left off. Wall-clock subtraction
        // would clamp to 1.0 on resume and produce a one-frame snap-to-end.
        masterTimerElapsed += link.targetTimestamp - link.timestamp
        let rawT = CGFloat(min(masterTimerElapsed / masterTimerDuration, 1.0))
        applyMasterTick(rawT)
        if rawT >= 1.0 {
            masterTimer?.invalidate()
            masterTimer = nil
            let completion = masterTimerCompletion
            masterTimerCompletion = nil
            completion?()
        }
    }

    /// Master tick. Y and Z share the same phase curve — both peak together
    /// at t≈0.35 and resolve to identity by t≈0.70 (the "initial lift" and
    /// "camera proximity" happen simultaneously, then decouple from the
    /// continuing bounds expansion in the latter 30%). Z=700 with focal=1000
    /// projects to apparent scale ~3.33 at peak — the cell visibly exceeds
    /// the viewport via perspective rather than 2D scale. Bounds + camera
    /// are linear lerps on t. All properties written atomically in one
    /// CATransaction so they share one render pass (no inter-property tearing).
    private func applyMasterTick(_ t: CGFloat) {
        guard let k = masterActiveCellIndex,
              let cell = instantiatedCells[k],
              let heightC = cell.heightConstraint else { return }

        let tClamped = max(0, min(1, t))

        let liftPhase = min(tClamped / 0.70, 1.0)
        let liftBell = sin(liftPhase * .pi)
        let unifiedArcY = -masterUnifiedArcMagnitude * liftBell
        let unifiedArcZ = 700.0 * liftBell

        let boundsRamp = tClamped
        let newHeight = masterStartHeight + (masterEndHeight - masterStartHeight) * boundsRamp
        let newCameraY = masterStartCameraY + (masterEndCameraY - masterStartCameraY) * boundsRamp

        CATransaction.withSuppressedActions {
            contentHost.layer.transform = CATransform3DMakeTranslation(0, unifiedArcY, unifiedArcZ)

            heightC.constant = newHeight
            contentHost.layoutIfNeeded()
            camera = Camera(translation: newCameraY)
            applyCameraTransform()
            updateVisibleCells()
            cell.setCamera(camera, viewport: bounds)
            updateNeighborTranslations()
            updateEdgeMaskAlphas()
            onCameraChanged?(camera, bounds)
        }
    }

    /// Internal cell-rest path. activeCellIndex clears only when BOTH springs
    /// settle AND heightConstraint reaches naturalHeight. The
    /// `tryClearActiveCellAtRest` coordination makes the clear robust under
    /// camera same-target short-circuit (the prior camera-completion-only
    /// version fired synchronously under same-target and left
    /// heightConstraint extended with activeCellIndex=nil).
    fileprivate func animateCameraToCellRestPath(
        initialExtensionVelocity: CGFloat,
        cameraTranslationVelocity: CGFloat = 0,
        direction: SpringDirection = .pinchToCells
    ) {
        guard let activeIdx = activeCellIndex,
              let activeCell = instantiatedCells[activeIdx],
              let heightC = activeCell.heightConstraint else {
            setActiveCellIndex(nil)
            restoreNaturalSiblingOrder()
            return
        }

        let cameraTarget = lastCellRestScrollY + bounds.height / 2
        let activeIdxCaptured = activeIdx

        let profile = springProfile(for: direction)
        extensionAnimator.spring = profile

        cameraAnimator.animate(
            to: Camera(translation: cameraTarget),
            velocity: CameraVelocity(translationVelocity: cameraTranslationVelocity),
            spring: profile
        ) { [weak self] in
            self?.tryClearActiveCellAtRest(expectedIdx: activeIdxCaptured)
        }

        extensionAnimator.value = heightC.constant
        extensionAnimator.target = activeCell.naturalHeight
        extensionAnimator.velocity = initialExtensionVelocity
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
            setActiveCellIndex(nil)
            restoreNaturalSiblingOrder()
        }
    }

    /// Pan-end deceleration. Single-axis translation spring; valid range
    /// matches `clampedWithRubberband`.
    private func startSpringDeceleration(initialVelocityY: CGFloat) {
        let viewportH = bounds.height
        let pageH = pageHeight()
        let minT = viewportH / 2
        let maxT = max(minT, pageH - viewportH / 2)

        let projected = project(initialVelocity: initialVelocityY, decelerationRate: 0.998)
        let rawTarget = camera.translation + projected
        let clampedTarget = clamp(rawTarget, minT, maxT)

        let targetCamera = Camera(translation: clampedTarget)
        let velocity = CameraVelocity(translationVelocity: initialVelocityY)
        cameraAnimator.animate(to: targetCamera, velocity: velocity)
    }

    // MARK: - UIGestureRecognizerDelegate

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
