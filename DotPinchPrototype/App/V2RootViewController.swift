// Production root view controller. Hosts TimelineCanvas (V2 dual-axis
// mechanics) bound to ConversationStore via TimelineDataSourceAdapter, and
// presents a ChatViewController overlay when a cell reaches morph-reveal.

import UIKit

@MainActor
final class V2RootViewController: UIViewController {

    private let store: ConversationStore
    private let adapter: TimelineDataSourceAdapter
    private let timelineCanvas: TimelineCanvas
    private var activeChatVC: ChatViewController?
    private var activeCellIndex: Int?
    private var revealBlurOverlay: UIVisualEffectView?

    // Pinch-to-dismiss state. The dismiss is driven by a single progress
    // source in [0, 1] (0 = chat-rest, 1 = cell-rest). During .changed the
    // gesture writes progress directly. After .ended, a CADisplayLink
    // interpolates progress toward 0 (cancel) or 1 (commit) with an ease
    // curve. See setDismissProgress(_:) for the per-phase derived properties.
    private var dismissProgress: CGFloat = 0
    private var dismissDisplayLink: CADisplayLink?
    private var dismissAnimStart: CFTimeInterval = 0
    private var dismissAnimDuration: CFTimeInterval = 0
    private var dismissAnimFrom: CGFloat = 0
    private var dismissAnimTo: CGFloat = 0
    private var dismissInProgress: Bool = false
    /// Use a quintic ease-in-out curve (smoother than cubic) for programmatic
    /// dismisses. Reset to false at gesture-initiated dismisses so the spring
    /// settle feels responsive instead of slow.
    private var dismissUseQuinticCurve: Bool = false

    // Blur overlay over the chat content. UIVisualEffectView + paused
    // UIViewPropertyAnimator pattern — scrub via the animator's
    // fractionComplete. Created at beginInteractiveDismiss, torn down at
    // completeDismiss / cancelDismiss.
    private var chatBlurOverlay: UIVisualEffectView?
    private var chatBlurAnimator: UIViewPropertyAnimator?

    // MARK: - Init

    init() {
        let conversations = DummyConversationLoader.load()
        self.store = ConversationStore(initialConversations: conversations)
        self.adapter = TimelineDataSourceAdapter(
            store: self.store,
            naturalCellHeight: 200
        )
        self.timelineCanvas = TimelineCanvas()
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("V2RootViewController does not support NSCoder")
    }

    // MARK: - Lifecycle

    override func loadView() {
        super.loadView()
        // Cell-fill (cream) as the backdrop. During morph, the canvas's
        // pageGradientLayer fades out (1→0 via CABasicAnimation in the
        // forward morph), so this backdrop becomes visible in the "empty
        // area" around the still-scaling cell. Matching the cell fill
        // color eliminates the visible boundary between the cell and the
        // surrounding area — looks like the cell is filling the viewport
        // even when it's only at 50% scale.
        view.backgroundColor = Theme.Cell.fill
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        timelineCanvas.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timelineCanvas)
        NSLayoutConstraint.activate([
            timelineCanvas.topAnchor.constraint(equalTo: view.topAnchor),
            timelineCanvas.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timelineCanvas.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            timelineCanvas.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        timelineCanvas.dataSource = adapter
        timelineCanvas.reloadData()

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.cancelsTouchesInView = false
        timelineCanvas.addGestureRecognizer(tap)

        timelineCanvas.onMorphRevealReady = { [weak self] cellIndex in
            self?.revealChat(forCellAt: cellIndex)
        }
    }

    // MARK: - Tap to morph

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        let viewportPoint = recognizer.location(in: timelineCanvas)
        let pagePoint = timelineCanvas.pagePointFromViewportPoint(viewportPoint)
        guard let idx = timelineCanvas.cellIndex(atPagePoint: pagePoint) else { return }
        guard activeChatVC == nil else { return }
        timelineCanvas.animateCameraToChatRest(forCellAt: idx)
    }

    // MARK: - Reveal chat (after morph)

    private func revealChat(forCellAt index: Int) {
        guard activeChatVC == nil else { return }
        guard index < store.conversations.count else { return }
        let conversation = store.conversations[index]

        let chatVC = ChatViewController()
        addChild(chatVC)
        chatVC.view.translatesAutoresizingMaskIntoConstraints = false
        chatVC.view.alpha = 0
        view.addSubview(chatVC.view)
        NSLayoutConstraint.activate([
            chatVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            chatVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        chatVC.didMove(toParent: self)
        chatVC.configure(with: conversation)
        view.layoutIfNeeded()
        activeChatVC = chatVC
        activeCellIndex = index
        wireDismissGesture(chatVC)

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        blur.translatesAutoresizingMaskIntoConstraints = false
        blur.alpha = 0
        view.addSubview(blur)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: view.topAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        revealBlurOverlay = blur

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
            blur.alpha = 1
        }, completion: nil)

        UIView.animate(withDuration: 0.3, delay: 0.2, options: [.curveEaseInOut, .allowUserInteraction], animations: {
            chatVC.view.alpha = 1
            self.timelineCanvas.alpha = 0
        }, completion: nil)

        UIView.animate(withDuration: 0.7, delay: 0.5, options: [.curveEaseInOut, .allowUserInteraction], animations: {
            blur.alpha = 0
        }, completion: { _ in
            blur.removeFromSuperview()
            if self.revealBlurOverlay === blur { self.revealBlurOverlay = nil }
        })
    }

    // MARK: - Pinch-to-dismiss (single-progress-source orchestrator)

    private func wireDismissGesture(_ chatVC: ChatViewController) {
        chatVC.onPinchBegan = { [weak self] in self?.beginInteractiveDismiss() }
        chatVC.onPinchChanged = { [weak self] scale in self?.updateInteractiveDismiss(scale: scale) }
        chatVC.onPinchEnded = { [weak self] scale, velocity in
            self?.endInteractiveDismiss(scale: scale, velocity: velocity)
        }
        chatVC.onDismissRequested = { [weak self] in self?.triggerProgrammaticDismiss() }
    }

    /// Manual dismiss trigger — invoked by tapping the ↖ expand icon on the
    /// chat. Runs the same sequence as a committed pinch gesture: begin →
    /// animate progress 0→1 via the existing display-link machinery →
    /// completeDismiss. Long duration + cubic ease spreads the motion
    /// uniformly across the duration so the morph reads as deliberate
    /// rather than snappy. Quintic was compressing the middle 40% of motion
    /// into the middle ~40% of duration; cubic spreads it across 70%+.
    private func triggerProgrammaticDismiss() {
        guard !dismissInProgress, activeChatVC != nil, activeCellIndex != nil else { return }
        beginInteractiveDismiss()
        dismissAnimFrom = 0
        dismissAnimTo = 1
        dismissAnimStart = CACurrentMediaTime()
        dismissAnimDuration = 1.6
        dismissUseQuinticCurve = false
        print("[dismiss] triggerProgrammaticDismiss (tap-to-dismiss)")
        startDismissDisplayLink()
    }

    private func beginInteractiveDismiss() {
        guard !dismissInProgress, let chatVC = activeChatVC, let idx = activeCellIndex else { return }
        dismissInProgress = true

        // Tell canvas to capture its chat-rest presentation values and strip
        // the persistent CAAnimations so we can scrub directly via the model.
        timelineCanvas.beginDismiss(forCellAt: idx)

        // Install blur overlay over the chat. Use a paused UIViewPropertyAnimator
        // to scrub the blur effect via fractionComplete — this is the only way
        // to interactively control UIVisualEffectView.effect intensity.
        installChatBlurOverlay()

        // Round the chat's corners + clip so the cornerRadius scrub shows.
        chatVC.view.layer.masksToBounds = true

        setDismissProgress(0)
    }

    private func installChatBlurOverlay() {
        guard let chatVC = activeChatVC else { return }
        let blur = UIVisualEffectView(effect: nil)
        blur.isUserInteractionEnabled = false
        blur.translatesAutoresizingMaskIntoConstraints = false
        chatVC.view.addSubview(blur)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: chatVC.view.topAnchor),
            blur.leadingAnchor.constraint(equalTo: chatVC.view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: chatVC.view.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: chatVC.view.bottomAnchor)
        ])
        chatBlurOverlay = blur

        let animator = UIViewPropertyAnimator(duration: 1, curve: .linear)
        animator.addAnimations {
            blur.effect = UIBlurEffect(style: .systemThickMaterial)
        }
        animator.startAnimation()
        animator.pauseAnimation()
        chatBlurAnimator = animator
    }

    private func updateInteractiveDismiss(scale: CGFloat) {
        guard dismissInProgress else { return }
        let progress = max(0, min(1, (1.0 - scale) * 2))
        setDismissProgress(progress)
    }

    /// Single source of truth for the dismiss morph. Maps `progress ∈ [0, 1]`
    /// to ~10 derived visual properties via offset smoothstep curves.
    /// PRIMARY effect is the §10.83 similarity transform shrink — chat tree
    /// (header + bubbles + composer) scales as one unit and translates
    /// toward the cell's cell-rest position so the chat lands ON the cell.
    /// Blur, cornerRadius, chrome fade, and content reversal are secondary
    /// effects layered around the primary shrink.
    private func setDismissProgress(_ progress: CGFloat) {
        let p = max(0, min(1, progress))
        dismissProgress = p

        // Phase 1 (PRIMARY): chat similarity-transform shrink + land on cell.
        // Uniform scale + translate to cell-rest viewport position. Internal
        // content (header, bubbles, composer) shrinks as one unit — the §10.83
        // pattern. Leads the dismiss (smoothstep 0.0–0.85).
        let shrinkP = smoothstep(0.0, 0.85, p)
        let target = dismissTargetTransform()
        activeChatVC?.view.transform = lerpTransform(.identity, to: target, by: shrinkP)

        // Phase 2: composer + header + scroll content fades (delegated).
        activeChatVC?.setDismissProgress(p)

        // Phase 3 (SECONDARY): VERY light blur tinting the shrink. Capped
        // at 0.25 so it's just a subtle softening, not the primary signal.
        // Fades with the chat alpha — by the time chat is invisible, blur
        // is gone too.
        let blurP = smoothstep(0.4, 0.7, p)
        chatBlurAnimator?.fractionComplete = blurP * 0.25

        // Phase 4: cornerRadius animation 0→25 (Theme.Radius.card) so the
        // chat visually becomes a cell card as it lands. Smoothstep 0.4–0.75.
        let cardP = smoothstep(0.4, 0.75, p)
        activeChatVC?.view.layer.cornerRadius = Theme.Radius.card * cardP

        // Phase 6: page gradient cross-fade IN (smoothstep 0.55–0.95). As
        // the chat fades out, cells fade in. Overlapping cross-fade so the
        // user sees a smooth handoff from chat-card to cell at the same
        // viewport position.
        let bgP = smoothstep(0.55, 0.95, p)
        timelineCanvas.alpha = bgP

        // Phase 7: chat alpha fade-out concurrent with shrink. Starts at
        // p=0.45, fully transparent by p=0.85 — so the user never sees the
        // lingering "tiny white rectangle" artifact at the end of the
        // shrink. The chat visibly shrinks for the first half then fades
        // away into the cells.
        let chatAlphaP = smoothstep(0.45, 0.85, p)
        activeChatVC?.view.alpha = 1 - chatAlphaP

        // Phase 8: contentHost transform reversal + cell content fade-in.
        timelineCanvas.setDismissProgress(p)
    }

    /// Compute the CGAffineTransform that maps the chat (full viewport) to
    /// the active cell's cell-rest position + dimensions. Uniform scale
    /// targeting the cell's natural height ratio (preserves similarity for
    /// the text shrink). Translation centers the chat on the cell's
    /// projected viewport position at cell-rest.
    private func dismissTargetTransform() -> CGAffineTransform {
        guard let idx = activeCellIndex,
              let cellCenterPageY = timelineCanvas.cellNaturalCenterY(at: idx) else {
            return .identity
        }
        let viewportH = view.bounds.height
        let cellNaturalHeight: CGFloat = 200

        let scale = cellNaturalHeight / viewportH

        // Cell-rest camera center is `lastCellRestScrollY + viewportH/2`. The
        // cell's center in viewport coords at cell-rest is therefore:
        let cellCenterInViewport = cellCenterPageY - timelineCanvas.lastCellRestScrollY

        let dy = cellCenterInViewport - viewportH / 2

        return CGAffineTransform(translationX: 0, y: dy).scaledBy(x: scale, y: scale)
    }

    /// Linear interpolation between two CGAffineTransforms by t ∈ [0, 1].
    /// Components blended independently — works for similarity transforms
    /// (uniform scale + translate). For non-uniform or rotated transforms,
    /// the intermediate states are still valid affine transforms.
    private func lerpTransform(_ from: CGAffineTransform, to: CGAffineTransform, by t: CGFloat) -> CGAffineTransform {
        return CGAffineTransform(
            a: from.a + (to.a - from.a) * t,
            b: from.b + (to.b - from.b) * t,
            c: from.c + (to.c - from.c) * t,
            d: from.d + (to.d - from.d) * t,
            tx: from.tx + (to.tx - from.tx) * t,
            ty: from.ty + (to.ty - from.ty) * t
        )
    }

    private func endInteractiveDismiss(scale: CGFloat, velocity: CGFloat) {
        guard dismissInProgress else { return }
        let shouldDismiss = dismissProgress > 0.4 || velocity < -1.0
        dismissAnimFrom = dismissProgress
        dismissAnimTo = shouldDismiss ? 1.0 : 0.0
        dismissAnimStart = CACurrentMediaTime()
        dismissUseQuinticCurve = false
        // Duration scales with remaining distance — full traversal ~0.55s,
        // shorter for near-edge releases. Matches reference dot_pinch.mov
        // total dismiss duration of ~2.5–3s but compressed (gesture phase
        // already consumed time; this is just the settle).
        let remainingDistance = abs(dismissAnimTo - dismissAnimFrom)
        dismissAnimDuration = max(0.25, 0.55 * Double(remainingDistance))
        print("[dismiss] .ended fc=\(dismissProgress) velocity=\(velocity) shouldDismiss=\(shouldDismiss) duration=\(dismissAnimDuration)")
        startDismissDisplayLink()
    }

    private func startDismissDisplayLink() {
        dismissDisplayLink?.invalidate()
        let link = CADisplayLink(target: self, selector: #selector(dismissTick(_:)))
        link.add(to: .main, forMode: .common)
        dismissDisplayLink = link
    }

    private func stopDismissDisplayLink() {
        dismissDisplayLink?.invalidate()
        dismissDisplayLink = nil
    }

    @objc private func dismissTick(_ link: CADisplayLink) {
        let elapsed = CACurrentMediaTime() - dismissAnimStart
        let t = min(1, max(0, elapsed / dismissAnimDuration))
        let eased = dismissUseQuinticCurve ? easeInOutQuintic(CGFloat(t)) : easeInOutCubic(CGFloat(t))
        let p = dismissAnimFrom + (dismissAnimTo - dismissAnimFrom) * eased
        setDismissProgress(p)
        if t >= 1 {
            stopDismissDisplayLink()
            if dismissAnimTo >= 1 {
                completeDismiss()
            } else {
                cancelDismiss()
            }
        }
    }

    private func easeInOutCubic(_ t: CGFloat) -> CGFloat {
        return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }

    /// Quintic ease-in-out — flatter at endpoints, gentler entry/exit than
    /// cubic. Used for the tap-to-dismiss path where the morph has time to
    /// breathe and a slower start/finish feels more deliberate.
    private func easeInOutQuintic(_ t: CGFloat) -> CGFloat {
        return t < 0.5 ? 16 * t * t * t * t * t : 1 - pow(-2 * t + 2, 5) / 2
    }

    private func completeDismiss() {
        guard let chatVC = activeChatVC, let idx = activeCellIndex else {
            print("[dismiss] completeDismiss EARLY-RETURN missing chatVC or idx")
            return
        }
        print("[dismiss] completeDismiss entered idx=\(idx)")

        // Snap canvas to cell-rest (reset transform to identity, restore
        // camera, re-dequeue neighbors via setCamera).
        timelineCanvas.completeDismiss(at: idx)

        chatVC.willMove(toParent: nil)
        chatVC.view.removeFromSuperview()
        chatVC.removeFromParent()

        tearDownBlurOverlay()

        activeChatVC = nil
        activeCellIndex = nil
        dismissInProgress = false
        print("[dismiss] completeDismiss done")
    }

    private func cancelDismiss() {
        guard let chatVC = activeChatVC, let idx = activeCellIndex else { return }
        print("[dismiss] cancelDismiss entered idx=\(idx)")

        // Restore canvas to chat-rest visual state.
        timelineCanvas.cancelDismiss(at: idx)
        timelineCanvas.alpha = 0

        // Restore chat to chat-rest state.
        chatVC.view.alpha = 1
        chatVC.view.transform = .identity
        chatVC.view.layer.cornerRadius = 0
        chatVC.view.layer.masksToBounds = false
        chatVC.setDismissProgress(0)

        tearDownBlurOverlay()
        dismissInProgress = false
    }

    private func tearDownBlurOverlay() {
        chatBlurAnimator?.stopAnimation(true)
        chatBlurAnimator?.finishAnimation(at: .current)
        chatBlurAnimator = nil
        chatBlurOverlay?.removeFromSuperview()
        chatBlurOverlay = nil
    }
}
