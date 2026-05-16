// The Conversation feature's view controller. Wired up by ConversationComposer
// — receives its animator and pinch interaction via init. Chrome views are
// siblings of the chat surface, never children (Refusal #3 + #7). The subview
// hierarchy is built once in viewDidLoad and never reordered (Refusal #8).

import UIKit

final class ConversationViewController: UIViewController {

    // MARK: - Layer hierarchy

    private let conversationView = ConversationContentView()
    private let composerPlaceholder = UIView()
    private let composerLabel = UILabel()
    private let statusLabel = UILabel()
    private let pinchGlyph = UIImageView()
    private let menuButton = UIButton(type: .system)

    // Stage 3+ object: emerges from non-existence (alpha 0→1) once the chat
    // surface has surrendered. Container becomes figure only AFTER text gives up
    // its role. Separate sibling — NOT a scaled version of the chat surface.
    private let destinationCard = UIView()
    private let destinationDate = UILabel()
    private let destinationBody = UILabel()

    // MARK: - Injected dependencies

    private let animator: SpringAnimator<PinchMorphState>
    private let pinchInteraction: PinchToMemoryInteraction
    private var didInstallInteraction = false

    // MARK: - Geometry

    private var fullscreenRect: CGRect = .zero

    // MARK: - Init

    init(animator: SpringAnimator<PinchMorphState>,
         pinchInteraction: PinchToMemoryInteraction) {
        self.animator = animator
        self.pinchInteraction = pinchInteraction
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Page.surface
        view.accessibilityIdentifier = AccessibilityID.demoRoot

        installPageGradient()
        installViewHierarchy()
        wireAnimator()
    }

    // Three-band gradient. Middle stop is Theme.Page.surface — same token as
    // destination card and composer fills. Chromatic continuity at the middle
    // band is what makes the card read as "the page material with edges."
    private var pageGradient: CAGradientLayer?
    private func installPageGradient() {
        let g = CAGradientLayer()
        g.colors = [
            Theme.Page.top.cgColor,
            Theme.Page.surface.cgColor,
            Theme.Page.bottom.cgColor
        ]
        g.locations = [0, 0.5, 1]
        g.startPoint = CGPoint(x: 0.5, y: 0)
        g.endPoint = CGPoint(x: 0.5, y: 1)
        g.frame = view.bounds
        view.layer.insertSublayer(g, at: 0)
        pageGradient = g
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layOutGeometry()
        installInteractionIfNeeded()
    }



    // MARK: - View hierarchy setup

    private func installViewHierarchy() {
        conversationView.translatesAutoresizingMaskIntoConstraints = true
        view.addSubview(conversationView)
        installDestinationCard()
        installChrome()
        installStatusLabel()
        installAffordances()
    }

    private func installDestinationCard() {
        // Sibling of conversationView. alpha 0 at baseline → 1 at destination
        // after the chat surface dissolves. Container emerges from non-existence,
        // not from being-bigger.
        destinationCard.translatesAutoresizingMaskIntoConstraints = false
        destinationCard.backgroundColor = Theme.Page.surface
        destinationCard.layer.cornerRadius = Theme.Radius.card
        destinationCard.layer.cornerCurve = .continuous
        destinationCard.alpha = 0
        destinationCard.isUserInteractionEnabled = false
        view.addSubview(destinationCard)

        destinationDate.text = DestinationContent.date
        destinationDate.font = Theme.Typography.destinationDate
        destinationDate.textColor = Theme.Text.tertiary
        destinationDate.alpha = 0
        destinationDate.translatesAutoresizingMaskIntoConstraints = false
        destinationCard.addSubview(destinationDate)

        destinationBody.font = Theme.Typography.destinationBody
        destinationBody.textColor = Theme.Text.serifBody
        destinationBody.numberOfLines = 0
        destinationBody.alpha = 0
        destinationBody.translatesAutoresizingMaskIntoConstraints = false
        let para = NSMutableParagraphStyle()
        para.minimumLineHeight = Theme.Typography.destinationBodyLineHeight
        para.maximumLineHeight = Theme.Typography.destinationBodyLineHeight
        destinationBody.attributedText = NSAttributedString(
            string: DestinationContent.preview,
            attributes: [.font: Theme.Typography.destinationBody,
                         .foregroundColor: Theme.Text.serifBody,
                         .paragraphStyle: para]
        )
        destinationCard.addSubview(destinationBody)

        NSLayoutConstraint.activate([
            destinationCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 23),
            destinationCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -23),
            destinationCard.topAnchor.constraint(equalTo: view.topAnchor, constant: 188),
            destinationCard.heightAnchor.constraint(equalToConstant: 221),

            destinationDate.topAnchor.constraint(equalTo: destinationCard.topAnchor, constant: 20),
            destinationDate.leadingAnchor.constraint(equalTo: destinationCard.leadingAnchor, constant: 24),

            destinationBody.topAnchor.constraint(equalTo: destinationDate.bottomAnchor, constant: 8),
            destinationBody.leadingAnchor.constraint(equalTo: destinationCard.leadingAnchor, constant: 24),
            destinationBody.trailingAnchor.constraint(equalTo: destinationCard.trailingAnchor, constant: -32)
        ])
    }

    // Affordance icons — siblings of the card; alpha rides on state.affordanceAlpha.
    private func installAffordances() {
        pinchGlyph.image = UIImage(
            systemName: SymbolName.pinchAffordance,
            withConfiguration: UIImage.SymbolConfiguration(
                pointSize: Theme.Symbol.pinchAffordancePointSize,
                weight: Theme.Symbol.pinchAffordanceWeight
            )
        )
        pinchGlyph.tintColor = Theme.Text.glyph
        pinchGlyph.alpha = 0
        pinchGlyph.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pinchGlyph)

        menuButton.setImage(
            UIImage(
                systemName: SymbolName.menu,
                withConfiguration: UIImage.SymbolConfiguration(
                    pointSize: Theme.Symbol.menuPointSize,
                    weight: Theme.Symbol.menuWeight
                )
            ),
            for: .normal
        )
        menuButton.tintColor = Theme.Text.glyphSubtle
        menuButton.alpha = 0
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(menuButton)

        NSLayoutConstraint.activate([
            pinchGlyph.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            pinchGlyph.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            menuButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            menuButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 14)
        ])
    }

    private func installChrome() {
        composerPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        composerPlaceholder.backgroundColor = Theme.Page.surface
        composerPlaceholder.layer.cornerRadius = Theme.Radius.composer
        composerPlaceholder.layer.cornerCurve = .continuous
        composerPlaceholder.accessibilityIdentifier = AccessibilityID.composerPlaceholder
        view.addSubview(composerPlaceholder)

        composerLabel.text = DestinationContent.composerHint
        composerLabel.font = Theme.Typography.composerHint
        composerLabel.textColor = Theme.Text.placeholder
        composerLabel.translatesAutoresizingMaskIntoConstraints = false
        composerPlaceholder.addSubview(composerLabel)

        NSLayoutConstraint.activate([
            composerPlaceholder.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            composerPlaceholder.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            composerPlaceholder.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            composerPlaceholder.heightAnchor.constraint(equalToConstant: 44),

            composerLabel.leadingAnchor.constraint(equalTo: composerPlaceholder.leadingAnchor, constant: 16),
            composerLabel.trailingAnchor.constraint(lessThanOrEqualTo: composerPlaceholder.trailingAnchor, constant: -16),
            composerLabel.centerYAnchor.constraint(equalTo: composerPlaceholder.centerYAnchor)
        ])
    }

    private func installStatusLabel() {
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = Theme.Typography.statusLabel
        statusLabel.textColor = Theme.Text.debug
        statusLabel.numberOfLines = 2
        statusLabel.accessibilityIdentifier = AccessibilityID.statusLabel
        statusLabel.isHidden = true  // dev-only debug surface
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Geometry layout

    private func layOutGeometry() {
        fullscreenRect = view.bounds
        pageGradient?.frame = view.bounds
        if conversationView.transform == .identity &&
           CATransform3DIsIdentity(conversationView.layer.transform) {
            conversationView.frame = fullscreenRect
        }
    }

    // MARK: - Interaction install

    private func installInteractionIfNeeded() {
        guard !didInstallInteraction, fullscreenRect != .zero else { return }
        #if DEBUG
        assertSurfaceTokenContinuity()
        #endif
        let baseline = PinchMorphState(progress: 0)
        animator.value = baseline
        animator.target = baseline
        handleAnimatorStateChange(baseline)
        conversationView.addInteraction(pinchInteraction)
        didInstallInteraction = true

        // Tap-to-expand at destination.
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapToExpand))
        conversationView.addGestureRecognizer(tap)
    }

    #if DEBUG
    // Invariant: destination card, composer, and page-gradient middle stop all
    // read Theme.Page.surface — divergence breaks card-as-page-material identity.
    private func assertSurfaceTokenContinuity() {
        let surface = Theme.Page.surface.cgColor.components ?? []
        let card = (destinationCard.backgroundColor ?? .clear).cgColor.components ?? []
        let composer = (composerPlaceholder.backgroundColor ?? .clear).cgColor.components ?? []

        let gradientStops = (pageGradient?.colors as? [CGColor]) ?? []
        let middle = gradientStops.dropFirst().first?.components ?? []

        assert(card == surface,     "Destination card surface diverged from Theme.Page.surface")
        assert(composer == surface, "Composer surface diverged from Theme.Page.surface")
        assert(middle == surface,   "Gradient middle stop diverged from Theme.Page.surface")
    }
    #endif

    @objc private func handleTapToExpand() {
        guard (animator.value?.progress ?? 0) >= PinchTuning.tapToExpandReadyThreshold else { return }
        animator.value = PinchMorphState(progress: 1)
        animator.target = PinchMorphState(progress: 0)
        animator.velocity = PinchMorphState(progress: PinchTuning.tapToExpandKickVelocity)
        animator.start()
    }

    private func wireAnimator() {
        animator.valueChanged = { [weak self] state in
            self?.handleAnimatorStateChange(state)
        }
        // Shadow is binary, not a function of progress — set only at .finished.
        // Announces object-ness ("card-shaped object"), not depth.
        animator.completion = { [weak self] event in
            guard let self else { return }
            if case .finished(let final) = event {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                if final.progress >= MorphTiming.completionEpsilon {
                    self.destinationCard.layer.shadowColor = UIColor.black.cgColor
                    self.destinationCard.layer.shadowOffset = Theme.Shadow.cardFinalOffset
                    self.destinationCard.layer.shadowRadius = Theme.Shadow.cardFinalRadius
                    self.destinationCard.layer.shadowOpacity = Theme.Shadow.cardFinalOpacity
                    self.destinationCard.layer.shadowPath = UIBezierPath(
                        roundedRect: self.destinationCard.bounds,
                        cornerRadius: self.destinationCard.layer.cornerRadius
                    ).cgPath
                } else {
                    self.destinationCard.layer.shadowOpacity = 0
                    self.destinationCard.layer.shadowPath = nil
                }
                CATransaction.commit()
            }
        }
    }

    private func handleAnimatorStateChange(_ state: PinchMorphState) {
        let tokens = ConversationMorphTokens(state: state)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        statusLabel.text = "p: \(String(format: "%.3f", state.progress))"

        // Single token bundle drives both surfaces — chat content + chrome.
        conversationView.apply(tokens)

        destinationCard.alpha = tokens.destinationCardAlpha
        destinationDate.alpha = tokens.destinationLabelAlpha
        destinationBody.alpha = tokens.destinationLabelAlpha
        pinchGlyph.alpha          = tokens.affordanceAlpha
        menuButton.alpha          = tokens.affordanceAlpha
        composerPlaceholder.alpha = tokens.composerAlpha
    }
}
