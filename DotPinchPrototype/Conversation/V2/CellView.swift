// CellView — cell-rest summary tile. Carries cell-rest chrome (date/topic/today
// labels + pinch glyph) plus the centered chat-rest placeholder label. The
// chat surface itself lives in ChatViewController, revealed by the morph after
// the cell expands to fill the viewport.

import UIKit
import QuartzCore
import Observation

final class CellView: UIView {

    // MARK: - Public API

    /// Data index this cell currently represents. -1 sentinel before configuration.
    var index: Int = -1

    /// Tap callback. Reads `self.index` at fire time (not a captured value).
    var onTap: ((Int) -> Void)?

    private(set) var tapRecognizer: UITapGestureRecognizer!

    // Press-feedback state. UILongPressGestureRecognizer with
    // minimumPressDuration=0 fires immediately on touch-down, lets us drive
    // a time-based scale-down via CADisplayLink (the gesture itself doesn't
    // fire .changed). Lives on `cell.transform` — composes multiplicatively
    // under contentHost's morph windup transform, so no conflict.
    private var pressGesture: UILongPressGestureRecognizer!
    private var pressDisplayLink: CADisplayLink?
    private var pressStartTime: CFTimeInterval = 0
    private var longPressHapticFired = false
    private let pressDownHaptic = UIImpactFeedbackGenerator(style: .light)
    private let longPressHaptic = UIImpactFeedbackGenerator(style: .rigid)
    /// Scale floor on long press. Orthodox iOS range (0.94–0.97 for buttons,
    /// 0.85 for icon long-press). 0.94 is a compromise: visible but gentle.
    private static let pressMinScale: CGFloat = 0.94
    /// Time to reach `pressMinScale` from identity. After this the scale
    /// holds at floor.
    private static let pressRampDuration: CFTimeInterval = 0.4
    /// Long-press threshold for the secondary `.rigid` haptic. Fires once
    /// per press.
    private static let longPressThreshold: CFTimeInterval = 0.3

    /// Conversation this cell is currently bound to. Used as a pool key for
    /// keyed reattachment across round-trips.
    private(set) var activeConversationID: UUID?

    // MARK: - Content subviews

    private(set) var dateLabel: UILabel!
    private(set) var topicSummaryLabel: UILabel!
    private(set) var todayLabel: UILabel!
    private(set) var labelStack: UIStackView!

    /// Centered chat-rest title. Alpha 0 at cell-rest; crossfaded in by the
    /// morph animator as the visible day-marker at chat-rest.
    private(set) var chatRestCenterLabel: UILabel!

    /// When true, `setCamera(_:viewport:)` skips alpha/chrome writes because
    /// an external morph animator owns those properties for the duration of
    /// the morph.
    var morphInProgress: Bool = false

    private(set) var pinchGlyph: UIImageView!

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

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        // Suppressed CATransaction prevents UIKit's implicit 0.25s tween on
        // initial layer-property writes (cornerRadius, transform).
        CATransaction.withSuppressedActions {
            layer.cornerRadius = Theme.Radius.card
            layer.masksToBounds = true
            backgroundColor = Theme.Cell.fill
            // Cell-own-transform invariant: identity always. The camera lives
            // on contentHost.layer.sublayerTransform, never on the cell itself.
            layer.transform = CATransform3DIdentity
            preservesSuperviewLayoutMargins = false
            accessibilityIdentifier = AccessibilityID.conversationSurface
        }

        setupSubviews()
        installTapRecognizer()
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

    // MARK: - Subview setup

    /// Build the cell-rest content hierarchy ONCE at init. Subviews are
    /// NEVER re-added in `configure(with:)` — mid-gesture sublayer-count
    /// changes are forbidden.
    private func setupSubviews() {
        CATransaction.withSuppressedActions {
            installLabelStack()
            installPinchGlyph()
        }
        activateConstraints()
    }

    private func installLabelStack() {
        dateLabel = UILabel()
        dateLabel.font = Theme.Typography.destinationDate
        dateLabel.textColor = Theme.Text.tertiary
        dateLabel.numberOfLines = 1
        dateLabel.lineBreakMode = .byTruncatingTail
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        topicSummaryLabel = UILabel()
        topicSummaryLabel.font = Theme.Typography.destinationBody
        topicSummaryLabel.textColor = Theme.Text.serifBody
        topicSummaryLabel.numberOfLines = 3
        topicSummaryLabel.lineBreakMode = .byTruncatingTail
        topicSummaryLabel.translatesAutoresizingMaskIntoConstraints = false

        todayLabel = UILabel()
        todayLabel.font = Theme.Typography.destinationDate
        todayLabel.textColor = Theme.Text.tertiary
        todayLabel.numberOfLines = 1
        todayLabel.lineBreakMode = .byTruncatingTail
        todayLabel.translatesAutoresizingMaskIntoConstraints = false

        labelStack = UIStackView(arrangedSubviews: [dateLabel, topicSummaryLabel, todayLabel])
        labelStack.axis = .vertical
        labelStack.alignment = .leading
        labelStack.spacing = 10
        labelStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(labelStack)

        chatRestCenterLabel = UILabel()
        chatRestCenterLabel.font = Theme.Typography.destinationBody.withSize(30)
        chatRestCenterLabel.textColor = Theme.Text.primary
        chatRestCenterLabel.textAlignment = .center
        chatRestCenterLabel.numberOfLines = 1
        chatRestCenterLabel.alpha = 0
        chatRestCenterLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(chatRestCenterLabel)
    }

    private func installPinchGlyph() {
        pinchGlyph = UIImageView()
        pinchGlyph.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(
            pointSize: Theme.Symbol.pinchAffordancePointSize,
            weight: Theme.Symbol.pinchAffordanceWeight
        )
        pinchGlyph.image = UIImage(systemName: SymbolName.pinchExpandAffordance, withConfiguration: config)
        pinchGlyph.tintColor = Theme.Text.glyph
        pinchGlyph.isUserInteractionEnabled = false
        addSubview(pinchGlyph)
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
            chatRestCenterLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20)
        ])
    }

    private func installTapRecognizer() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        // cancelsTouchesInView=false so cell.onTap doesn't swallow taps the
        // textfield or sendButton would otherwise handle at chat-rest.
        tap.cancelsTouchesInView = false
        addGestureRecognizer(tap)
        tapRecognizer = tap

        installPressFeedback()
    }

    /// Install the press-feedback gesture. `UILongPressGestureRecognizer`
    /// with `minimumPressDuration=0` fires `.began` immediately on touch-
    /// down (faster than UIControl events, doesn't compete with the tap
    /// recognizer because gestures coexist on UIView). `cancelsTouchesInView
    /// = false` so the tap recognizer still fires on release.
    private func installPressFeedback() {
        let press = UILongPressGestureRecognizer(target: self, action: #selector(handlePressFeedback(_:)))
        press.minimumPressDuration = 0
        press.cancelsTouchesInView = false
        addGestureRecognizer(press)
        pressGesture = press
    }

    @objc private func handlePressFeedback(_ recognizer: UILongPressGestureRecognizer) {
        switch recognizer.state {
        case .began:
            pressStartTime = CACurrentMediaTime()
            longPressHapticFired = false
            // Prepare both generators ahead — `impactOccurred` after `prepare`
            // has lower latency. Light fires immediately (touch-down feedback).
            pressDownHaptic.prepare()
            longPressHaptic.prepare()
            pressDownHaptic.impactOccurred(intensity: 0.7)
            startPressDisplayLink()
        case .ended:
            stopPressDisplayLink()
            // Spring back to identity. Runs in parallel with the morph
            // windup (contentHost.scale 0→0.08) that fires from onTap —
            // they compose multiplicatively (cell.transform * contentHost
            // .layer.transform), creating a slight extra bounce as the
            // cell expands. No conflict.
            UIView.animate(
                withDuration: 0.22,
                delay: 0,
                usingSpringWithDamping: 0.62,
                initialSpringVelocity: 0,
                options: [.allowUserInteraction, .beginFromCurrentState]
            ) {
                self.transform = .identity
            }
            // Fire the tap action. UILongPressGestureRecognizer with
            // minimumPressDuration=0 enters .began on touch-down, which
            // by default blocks the cell-level UITapGestureRecognizer
            // (same-view conflict) AND the canvas-level tap recognizer
            // in V2RootVC (descendant-gestures-take-priority rule —
            // ancestor recognizers wait for descendants to FAIL before
            // they can recognize; this LongPress recognizes successfully
            // and never fails, so the ancestor Tap stays blocked). So we
            // bypass both and fire onTap directly here.
            onTap?(index)
        case .cancelled, .failed:
            stopPressDisplayLink()
            // Spring back, no tap, no haptic (user dragged off).
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0,
                options: [.allowUserInteraction, .beginFromCurrentState]
            ) {
                self.transform = .identity
            }
        default:
            break
        }
    }

    private func startPressDisplayLink() {
        pressDisplayLink?.invalidate()
        let link = CADisplayLink(target: self, selector: #selector(pressTick(_:)))
        link.add(to: .main, forMode: .common)
        pressDisplayLink = link
    }

    private func stopPressDisplayLink() {
        pressDisplayLink?.invalidate()
        pressDisplayLink = nil
    }

    @objc private func pressTick(_ link: CADisplayLink) {
        let elapsed = CACurrentMediaTime() - pressStartTime

        // Cubic ease-out from 1.0 toward `pressMinScale` over `pressRampDuration`.
        // After ramp duration, holds at the floor (no further movement).
        let t = min(1.0, elapsed / Self.pressRampDuration)
        let easedT = 1.0 - pow(1.0 - CGFloat(t), 3)
        let scale = 1.0 - (1.0 - Self.pressMinScale) * easedT
        transform = CGAffineTransform(scaleX: scale, y: scale)

        // Long-press threshold haptic — escalation cue. Only fires once.
        if !longPressHapticFired && elapsed >= Self.longPressThreshold {
            longPressHapticFired = true
            longPressHaptic.impactOccurred(intensity: 0.55)
        }
    }

    // MARK: - Data binding

    func configure(with conversation: Conversation) {
        activeConversationID = conversation.id
        dateLabel.text = conversation.displayDate
        topicSummaryLabel.text = conversation.curatedSummary
        todayLabel.text = Self.todayLabelText(for: conversation)
        chatRestCenterLabel.text = Self.todayLabelText(for: conversation) ?? conversation.displayDate
    }

    private static func todayLabelText(for conversation: Conversation) -> String? {
        let calendar = Calendar.current
        let date = conversation.createdAt
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return nil
    }

    // MARK: - Camera-change seam

    /// Push-from-canvas camera update. Drives the progress-based alpha curves
    /// for cell-rest chrome (labelStack + pinchGlyph) so they fade out as the
    /// cell expands toward chat-rest. NEVER writes cell.alpha or
    /// cell.layer.transform (carrier invariants). Idempotent.
    func setCamera(_ camera: Camera, viewport: CGRect) {
        guard bounds.height > 0 else { return }
        // Morph gate: external animator owns alpha + chrome during morph.
        if morphInProgress { return }
        let naturalH = naturalHeight > 0 ? naturalHeight : bounds.height
        let chatRestFactor = viewport.height / naturalH
        let chatRestRange = chatRestFactor - 1.0
        let extensionFactor = bounds.height / naturalH
        let progress: CGFloat = chatRestRange > 1e-6
            ? min(1.0, max(0.0, (extensionFactor - 1.0) / chatRestRange))
            : 1.0

        let inverseFadeAlpha = 1 - smoothstep(0.05, 0.30, progress)
        labelStack.alpha = inverseFadeAlpha
        pinchGlyph.alpha = inverseFadeAlpha

        layer.sublayerTransform = CATransform3DIdentity

        // Horizontal inset: 16pt at cell-rest → 0 at chat-rest (edge-to-edge).
        if pageWidth > 0, let leadingC = leadingConstraint, let widthC = widthConstraint {
            let currentInset = naturalHorizontalInset * (1 - progress)
            leadingC.constant = currentInset
            widthC.constant = pageWidth - 2 * currentInset
        }
    }

    // MARK: - Tap

    @objc private func handleTap() {
        onTap?(index)
    }
}
