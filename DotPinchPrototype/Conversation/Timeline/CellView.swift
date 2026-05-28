// CellView — cell-rest summary tile. Carries cell-rest chrome (date/topic/today
// labels + pinch glyph) plus the centered chat-rest placeholder label. The
// chat surface itself lives in ChatViewController, revealed by the morph after
// the cell expands to fill the viewport.

import UIKit
import QuartzCore

final class CellView: UIView {

    // MARK: - Public API

    /// Data index this cell currently represents. nil before configuration.
    var index: Int?

    /// Conversation this cell is currently bound to. Used as a pool key for
    /// keyed reattachment across round-trips.
    private(set) var activeConversationID: UUID?

    // MARK: - Content subviews (closure-init at class-top)

    private(set) var dateLabel: UILabel = {
        let l = UILabel()
        l.font = Theme.Typography.destinationDate
        l.textColor = Theme.Text.tertiary
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private(set) var topicSummaryLabel: UILabel = {
        let l = UILabel()
        l.font = Theme.Typography.destinationBody
        l.textColor = Theme.Text.serifBody
        l.numberOfLines = 3
        l.lineBreakMode = .byTruncatingTail
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private(set) var todayLabel: UILabel = {
        let l = UILabel()
        l.font = Theme.Typography.destinationDate
        l.textColor = Theme.Text.tertiary
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private(set) lazy var labelStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [dateLabel, topicSummaryLabel, todayLabel])
        s.axis = .vertical
        s.alignment = .leading
        s.spacing = 10
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    /// Centered chat-rest title. Alpha 0 at cell-rest; crossfaded in by the
    /// morph animator as the visible day-marker at chat-rest.
    private(set) var chatRestCenterLabel: UILabel = {
        let l = UILabel()
        l.font = Theme.Typography.destinationBody.withSize(30)
        l.textColor = Theme.Text.primary
        l.textAlignment = .center
        l.numberOfLines = 1
        l.alpha = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    weak var morphChoreographer: MorphChoreographer?

    var morphInProgress: Bool { morphChoreographer?.isRunning ?? false }

    private(set) var pinchGlyph: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(
            pointSize: Theme.Symbol.pinchAffordancePointSize,
            weight: Theme.Symbol.pinchAffordanceWeight
        )
        v.image = UIImage(systemName: SymbolName.pinchExpandAffordance, withConfiguration: config)
        v.tintColor = Theme.Text.glyph
        v.isUserInteractionEnabled = false
        return v
    }()

    /// Inward-arrows affordance (§21). Visible at chat-rest, invisible at
    /// cell-rest, smoothstep transition through morph. Top-left positioned
    /// to rhyme visually with labelStack's leading anchor while pinchGlyph
    /// is bottom-right. P1.2 closure-init at class top.
    private(set) var chatRestAffordance: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(
            pointSize: Theme.Symbol.pinchAffordancePointSize,
            weight: Theme.Symbol.pinchAffordanceWeight
        )
        v.image = UIImage(systemName: SymbolName.pinchCollapseAffordance, withConfiguration: config)
        v.tintColor = Theme.Text.glyph
        v.isUserInteractionEnabled = false
        v.alpha = 0   // hidden at cell-rest; setCamera drives the curve
        return v
    }()

    // MARK: - Chat content + state controller (§1.3, §1.4)

    /// The chat-rest content (header + bubbleStack + composer). Installed
    /// lazily by RevealCoordinator at T=1.6s; persists with cell across pool
    /// LRU; alpha-driven by setCamera per the §23 hybrid Z + alpha curve.
    var chatContentContainer: ChatContentContainer?

    /// Per-conversation transient state. Created lazily on configure(with:);
    /// survives pool round-trips; bound to chatVC at install (per D10) and
    /// to chatContent at handoff.
    var stateController: ConversationStateController?

    // MARK: - Loading dots (§22 / P2 / Phase 12)

    /// 3-dot pulsing indicator. Visible when ConversationActivityTracker
    /// reports this cell's conversation as active. Default-hidden (alpha=0);
    /// `setActiveIndicatorVisible(_:)` toggles + drives the pulse animation.
    private(set) lazy var dotsIndicator: DotsLoadingIndicator = {
        let view = DotsLoadingIndicator()
        view.alpha = 0
        return view
    }()

    private var dotsIndicatorInstalled: Bool = false

    /// Toggle the loading dots visibility. Idempotent. Installs the view on
    /// first call so cells without active conversations never allocate it.
    func setActiveIndicatorVisible(_ visible: Bool) {
        if visible && !dotsIndicatorInstalled {
            installDotsIndicator()
        }
        guard dotsIndicatorInstalled else { return }

        if visible {
            dotsIndicator.alpha = 1
            dotsIndicator.startPulsing()
        } else {
            dotsIndicator.alpha = 0
            dotsIndicator.stopPulsing()
        }
    }

    private func installDotsIndicator() {
        addSubview(dotsIndicator)
        NSLayoutConstraint.activate([
            dotsIndicator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            dotsIndicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20)
        ])
        dotsIndicatorInstalled = true
    }

    // MARK: - Cell-against-contentHost layout

    /// Natural page-coord height (data source's `heightForCellAt(:)`). Persistent
    /// across pool round-trips so the pool-return path can restore the
    /// heightConstraint deterministically.
    private(set) var naturalHeight: CGFloat = 0

    /// Mutable height constraint. Mutated by the pinch handler during `.changed`.
    /// Extension is symmetric around `centerYConstraint` — top and bottom move
    /// equally so cell midY in page coords is invariant.
    private(set) var heightConstraint: NSLayoutConstraint?

    private(set) var widthConstraint: NSLayoutConstraint?
    private(set) var centerYConstraint: NSLayoutConstraint?
    private(set) var leadingConstraint: NSLayoutConstraint?

    private var naturalHorizontalInset: CGFloat = 0
    private var pageWidth: CGFloat = 0

    static let cellTransformAnchor = CGPoint(x: 0.4, y: 0.85)

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        // Suppressed CATransaction prevents UIKit's implicit 0.25s tween on
        // initial layer-property writes (cornerRadius, transform).
        CATransaction.withSuppressedActions {
            layer.cornerRadius = Theme.Radius.card
            layer.masksToBounds = true
            backgroundColor = Theme.Cell.fill
            layer.shadowColor = Theme.Cell.shadowColor
            layer.shadowOffset = Theme.Cell.shadowOffset
            layer.shadowRadius = Theme.Cell.shadowRadius
            layer.shadowOpacity = 0
            layer.transform = CATransform3DIdentity
            preservesSuperviewLayoutMargins = false
            accessibilityIdentifier = AccessibilityID.conversationSurface
        }

        installSubviews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("CellView does not support NSCoder decoding")
    }

    /// Clear this cell's pool identity so it becomes eligible for any
    /// conversation on next dequeue.
    func invalidateConversationBinding() {
        activeConversationID = nil
    }

    // MARK: - Layout in contentHost

    /// Install the four cell-against-contentHost constraints. Idempotent —
    /// re-calling deactivates prior constraints and installs fresh ones.
    /// centerY-anchored is load-bearing: extension is symmetric (top and
    /// bottom move equally) so cell midY in page coords stays invariant.
    func installLayout(
        into contentHost: UIView,
        naturalCenterY: CGFloat,
        naturalHeight: CGFloat,
        pageWidth: CGFloat,
        horizontalInset: CGFloat = 0
    ) {
        translatesAutoresizingMaskIntoConstraints = false
        self.naturalHeight = naturalHeight
        self.naturalHorizontalInset = horizontalInset
        self.pageWidth = pageWidth

        deactivateLayoutConstraints()

        let leadingC = leadingAnchor.constraint(
            equalTo: contentHost.leadingAnchor,
            constant: horizontalInset
        )
        let widthC = widthAnchor.constraint(equalToConstant: pageWidth - 2 * horizontalInset)
        let centerYC = centerYAnchor.constraint(
            equalTo: contentHost.topAnchor, constant: naturalCenterY
        )
        let heightC = heightAnchor.constraint(equalToConstant: naturalHeight)

        NSLayoutConstraint.activate([leadingC, widthC, centerYC, heightC])

        leadingConstraint = leadingC
        widthConstraint = widthC
        centerYConstraint = centerYC
        heightConstraint = heightC

        #if DEBUG
        let expectedMidY = naturalCenterY
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            assert(abs(self.layer.position.y - expectedMidY) < 0.5,
                   "CellView: centerY-anchored invariant violated; layer.position.y=\(self.layer.position.y) expected=\(expectedMidY)")
        }
        #endif
    }

    func deactivateLayoutConstraints() {
        let constraints = [leadingConstraint, widthConstraint, centerYConstraint, heightConstraint]
            .compactMap { $0 }
        if !constraints.isEmpty {
            NSLayoutConstraint.deactivate(constraints)
        }
        leadingConstraint = nil
        widthConstraint = nil
        centerYConstraint = nil
        heightConstraint = nil
    }

    /// Reset heightConstraint to `naturalHeight` so a pooled cell does not
    /// carry residual extension. No-op if heightConstraint is nil.
    func resetHeightConstraintToNatural() {
        heightConstraint?.constant = naturalHeight
    }

    // MARK: - Subview install

    private func installSubviews() {
        CATransaction.withSuppressedActions {
            addSubview(labelStack)
            addSubview(chatRestCenterLabel)
            addSubview(pinchGlyph)
            addSubview(chatRestAffordance)
        }
        activateConstraints()
    }

    private func activateConstraints() {
        NSLayoutConstraint.activate([
            // labelStack pinned to safeAreaLayoutGuide.top (not plain topAnchor)
            // so labels sit below the status bar when the cell extends edge-to-edge.
            labelStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            labelStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            labelStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),

            pinchGlyph.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            pinchGlyph.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),

            chatRestCenterLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            chatRestCenterLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            chatRestCenterLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            chatRestCenterLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),

            // chatRestAffordance: top-right (mirrors pinchGlyph diagonally;
            // top-left would conflict with labelStack at progress transition).
            chatRestAffordance.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            chatRestAffordance.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16)
        ])
    }

    // MARK: - Data binding

    func configure(with conversation: Conversation) {
        // If rebinding to a different conversation, tear down chatContent so
        // the new conversation's state doesn't leak into the old chatContent.
        // Identity-keyed pool's invariant: same UUID → same cell instance.
        if let existing = stateController, existing.conversationID != conversation.id {
            teardownChatContent()
        }

        activeConversationID = conversation.id
        dateLabel.text = conversation.displayDate
        topicSummaryLabel.text = conversation.curatedSummary
        let marker = conversation.dayMarker()
        let isRelative = (marker == "Today" || marker == "Yesterday")
        todayLabel.text = isRelative ? marker : nil
        chatRestCenterLabel.text = marker
    }

    // MARK: - Camera-change seam (per-frame chrome + chat-content driver)

    /// Push-from-canvas camera update. Drives the progress-based alpha curves
    /// for cell-rest chrome (labelStack + pinchGlyph), the chat-rest affordance
    /// (inward arrows per §21), the chatContent distance-fade (Z-translation
    /// engaging m34 + residual alpha per §23 hybrid). NEVER writes cell.alpha
    /// or cell.layer.transform (carrier invariants). Idempotent (P19.3).
    ///
    /// Pillar honors: P1.1 guard-chain, P6.7 silence justified, P11.1 SRP
    /// (delegates to single-concern appliers), P12.2 tell-don't-ask,
    /// P13.4 ≤15 LOC, P19.3 idempotent.
    func setCamera(_ camera: Camera, viewport: CGRect) {
        guard bounds.height > 0, !morphInProgress else { return }

        let naturalH = naturalHeight > 0 ? naturalHeight : bounds.height
        let chatRestScale = (viewport.height / naturalH) * MorphTiming.chatRestMarginFactor

        applyCellRestChromeAlphasFromScale(chatRestScale: chatRestScale)
        applyChatRestAffordanceFromScale(chatRestScale: chatRestScale)
        applyHorizontalInsetFromScale(chatRestScale: chatRestScale)
        applyShadowGate(chatRestScale: chatRestScale)
        applyIllegibilityBlur(chatRestScale: chatRestScale)
        applyChatContentScaleFade(chatRestScale: chatRestScale)

        layer.sublayerTransform = CATransform3DIdentity
    }

    var currentScale: CGFloat {
        guard naturalHeight > 0 else { return 1.0 }
        return bounds.height / naturalHeight
    }

    // MARK: - Per-frame progress derivation (pure)

    /// Clamped progress ∈ [0, 1] mapping cell heightConstraint to chat-rest extension.
    /// P19.1 pure | P19.4 referentially transparent | P6.6 no sentinel.
    private func computeProgress(viewport: CGRect) -> CGFloat {
        let naturalH = naturalHeight > 0 ? naturalHeight : bounds.height
        let chatRestFactor = (viewport.height / naturalH) * MorphTiming.chatRestMarginFactor
        let chatRestRange = chatRestFactor - 1.0

        // When naturalH ≈ viewport.height, chatRestRange ≈ 0 — division
        // would be undefined. Treat as "already at chat-rest".
        guard chatRestRange > AlphaCurve.progressDenominatorEpsilon else { return 1.0 }

        let extensionFactor = bounds.height / naturalH
        let raw = (extensionFactor - 1.0) / chatRestRange
        return min(1.0, max(0.0, raw))
    }

    // MARK: - Per-frame appliers (side-effectful, idempotent)

    private func applyCellRestChromeAlphasFromScale(chatRestScale: CGFloat) {
        let band = StageOrdering.cellRestChromeBand(chatRestScale: chatRestScale)
        let alpha = 1 - smoothstep(band.lowerBound, band.upperBound, currentScale)
        labelStack.alpha = alpha
        pinchGlyph.alpha = alpha
    }

    private func applyChatRestAffordanceFromScale(chatRestScale: CGFloat) {
        let lowScale = 1.0 + AlphaCurve.chatRestAffordanceIn * (chatRestScale - 1.0)
        let highScale = 1.0 + AlphaCurve.chatRestAffordanceFull * (chatRestScale - 1.0)
        chatRestAffordance.alpha = smoothstep(lowScale, highScale, currentScale)
    }

    private func applyChatContentScaleFade(chatRestScale: CGFloat) {
        guard let chatContent = chatContentContainer else { return }
        let band = StageOrdering.chatContentFadeBand(chatRestScale: chatRestScale)
        chatContent.alpha = smoothstep(band.lowerBound, band.upperBound, currentScale)
        chatContent.layer.transform = CATransform3DIdentity
    }

    private func applyHorizontalInsetFromScale(chatRestScale: CGFloat) {
        guard pageWidth > 0,
              let leadingC = leadingConstraint,
              let widthC = widthConstraint
        else { return }

        let range = max(chatRestScale - 1.0, AlphaCurve.progressDenominatorEpsilon)
        let scaleProgress = min(1.0, max(0.0, (currentScale - 1.0) / range))
        let currentInset = naturalHorizontalInset * (1 - scaleProgress)
        leadingC.constant = currentInset
        widthC.constant = pageWidth - 2 * currentInset
    }

    private func applyShadowGate(chatRestScale: CGFloat) {
        let band = StageOrdering.cellShadowBand(chatRestScale: chatRestScale)
        let alpha = 1 - smoothstep(band.lowerBound, band.upperBound, currentScale)
        layer.shadowOpacity = Float(alpha * Theme.Cell.shadowOpacityCellRest)
    }

    private func applyIllegibilityBlur(chatRestScale: CGFloat) {
        guard let chatContent = chatContentContainer else { return }
        let band = StageOrdering.focalBlurBand(chatRestScale: chatRestScale)
        let mid = (band.lowerBound + band.upperBound) / 2
        let rising = smoothstep(band.lowerBound, mid, currentScale)
        let falling = 1 - smoothstep(mid, band.upperBound, currentScale)
        chatContent.setIllegibilityFraction(rising * falling)
    }

    // MARK: - ChatContent install / teardown (§1.3)

    /// Install chatContent + bind state controller. Idempotent — if already
    /// installed, no-op (state controller's bind is idempotent too).
    /// P11.1 SRP | P12.2 tell-don't-ask (delegates to container's configure).
    func installChatContentIfNeeded(
        conversation: Conversation,
        parentVC: UIViewController,
        stateController: ConversationStateController
    ) {
        guard chatContentContainer == nil else { return }

        let container = ChatContentContainer(parentVC: parentVC)
        container.alpha = 0
        container.configure(with: conversation)

        // CRITICAL ordering: addSubview FIRST so the container is in the cell's
        // view tree (cell → contentHost → canvas → parentVC.view). Then activate
        // cell-container intra-constraints. Then call activateCrossViewConstraints
        // which references parentView.safeAreaLayoutGuide — now reachable via
        // the now-connected view tree. Init-time activation would crash with
        // NSGenericException (anchors in disconnected hierarchies).
        addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        container.activateCrossViewConstraints()

        stateController.bind(to: container)
        chatContentContainer = container
        self.stateController = stateController

        layoutIfNeeded()
    }

    /// Teardown chatContent (called when cell rebinds to a different conversation).
    func teardownChatContent() {
        chatContentContainer?.teardownCrossViewConstraints()
        chatContentContainer?.removeFromSuperview()
        chatContentContainer = nil
        stateController?.unbind()
        stateController = nil
    }

    /// Distinct from teardownChatContent: this is for memory pressure response
    /// per §35. The cell instance STAYS in the pool for fast re-bind later;
    /// only the heavy chatContent + stateController are released.
    func teardownChatContentForMemoryPressure() {
        chatContentContainer?.teardownCrossViewConstraints()
        chatContentContainer?.removeFromSuperview()
        chatContentContainer = nil
        stateController = nil
    }

    // MARK: - Morph state lifecycle

    func resetMorphState() {
        chatRestCenterLabel.transform = .identity
        chatRestCenterLabel.layer.removeAnimation(forKey: MorphAnimationKey.centerLabelOpacity.rawValue)
        chatRestCenterLabel.alpha = 0
    }

    enum NeighborPosition {
        case above
        case below
    }

    func followActive(growth: CGFloat, position: NeighborPosition) {
        let direction: CGFloat = (position == .above) ? -1 : 1
        let ty = direction * growth * 0.5
        transform = CGAffineTransform(translationX: 0, y: ty)
    }

    func resetFollowTransform() {
        transform = .identity
    }

    struct MorphChromeProfile {
        let counterScale: CGFloat
        let centerLabelDuration: TimeInterval
        let centerLabelBeginTime: CFTimeInterval
    }

    func snapToChatRestChromeEndState(counterScale: CGFloat) {
        dateLabel.alpha = 0
        topicSummaryLabel.alpha = 0
        todayLabel.alpha = 0
        pinchGlyph.alpha = 0
        chatRestCenterLabel.alpha = 1
        chatRestCenterLabel.transform = CGAffineTransform(scaleX: counterScale, y: counterScale)
        layer.shadowOpacity = 0
        chatContentContainer?.setIllegibilityFraction(0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: Theme.Radius.card).cgPath
    }

    func performMorphChromeTransition(profile: MorphChromeProfile) {
        chatRestCenterLabel.transform = CGAffineTransform(scaleX: profile.counterScale, y: profile.counterScale)

        let centerOpacity = CABasicAnimation(keyPath: "opacity")
        centerOpacity.fromValue = 0
        centerOpacity.toValue = 1
        centerOpacity.duration = profile.centerLabelDuration
        centerOpacity.beginTime = profile.centerLabelBeginTime
        let labelOpacityCP = MorphCurves.labelOpacity
        centerOpacity.timingFunction = CAMediaTimingFunction(
            controlPoints: labelOpacityCP.0, labelOpacityCP.1, labelOpacityCP.2, labelOpacityCP.3)
        centerOpacity.fillMode = .forwards
        centerOpacity.isRemovedOnCompletion = false
        chatRestCenterLabel.layer.add(centerOpacity, forKey: MorphAnimationKey.centerLabelOpacity.rawValue)

        UIView.animate(withDuration: LabelFadeTiming.dateLabelDuration,
                       delay: LabelFadeTiming.dateLabelDelay,
                       options: [.curveEaseOut, .allowUserInteraction],
                       animations: { self.dateLabel.alpha = 0 },
                       completion: nil)

        UIView.animate(withDuration: LabelFadeTiming.topicSummaryDuration,
                       delay: LabelFadeTiming.topicSummaryDelay,
                       options: [.curveEaseOut, .allowUserInteraction],
                       animations: { self.topicSummaryLabel.alpha = 0 },
                       completion: nil)

        UIView.animate(withDuration: LabelFadeTiming.todayGlyphDuration,
                       delay: LabelFadeTiming.todayGlyphDelay,
                       options: [.curveEaseOut, .allowUserInteraction],
                       animations: {
                           self.todayLabel.alpha = 0
                           self.pinchGlyph.alpha = 0
                       },
                       completion: nil)

        let shadowFade = CABasicAnimation(keyPath: "shadowOpacity")
        shadowFade.fromValue = layer.shadowOpacity
        shadowFade.toValue = 0
        shadowFade.duration = LabelFadeTiming.dateLabelDuration
        shadowFade.beginTime = profile.centerLabelBeginTime + LabelFadeTiming.dateLabelDelay
        shadowFade.fillMode = .forwards
        shadowFade.isRemovedOnCompletion = false
        layer.add(shadowFade, forKey: "morph.shadow")
        layer.shadowOpacity = 0
    }
}
