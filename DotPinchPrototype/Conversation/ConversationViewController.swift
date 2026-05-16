// Composition root for the Conversation feature. Chrome views are siblings of
// the chat surface, never children (Refusal #3 + #7). The subview hierarchy is
// built once in viewDidLoad and never reordered (Refusal #8). animator.valueChanged
// is the single writer of progress-derived view state.

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

    // MARK: - Interaction substrate

    private lazy var animator: SpringAnimator<PinchMorphState> = {
        let baseline = PinchMorphState(progress: 0)
        let a = SpringAnimator<PinchMorphState>(
            spring: Spring(
                dampingRatio: PinchTuning.springDamping,
                response: PinchTuning.springResponse
            ),
            value: baseline,
            target: baseline
        )
        return a
    }()

    private var pinchInteraction: PinchToMemoryInteraction?

    // MARK: - Geometry

    private var fullscreenRect: CGRect = .zero

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
        destinationCard.layer.cornerRadius = 25
        destinationCard.layer.cornerCurve = .continuous
        destinationCard.alpha = 0
        destinationCard.isUserInteractionEnabled = false
        view.addSubview(destinationCard)

        destinationDate.text = DestinationContent.date
        destinationDate.font = .systemFont(ofSize: 13, weight: .regular)
        destinationDate.textColor = UIColor(white: 0.45, alpha: 1)
        destinationDate.alpha = 0
        destinationDate.translatesAutoresizingMaskIntoConstraints = false
        destinationCard.addSubview(destinationDate)

        let serif: UIFont = {
            let base = UIFont.systemFont(ofSize: 22, weight: .regular)
            return base.fontDescriptor.withDesign(.serif).map { UIFont(descriptor: $0, size: 22) } ?? base
        }()
        destinationBody.font = serif
        destinationBody.textColor = UIColor(red: 60/255, green: 56/255, blue: 60/255, alpha: 1)
        destinationBody.numberOfLines = 0
        destinationBody.alpha = 0
        destinationBody.translatesAutoresizingMaskIntoConstraints = false
        let para = NSMutableParagraphStyle()
        para.minimumLineHeight = 28
        para.maximumLineHeight = 28
        destinationBody.attributedText = NSAttributedString(
            string: DestinationContent.preview,
            attributes: [.font: serif,
                         .foregroundColor: UIColor(red: 60/255, green: 56/255, blue: 60/255, alpha: 1),
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
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .light)
        )
        pinchGlyph.tintColor = UIColor(white: 0.59, alpha: 1)
        pinchGlyph.alpha = 0
        pinchGlyph.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pinchGlyph)

        menuButton.setImage(
            UIImage(systemName: SymbolName.menu,
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)),
            for: .normal
        )
        menuButton.tintColor = UIColor(white: 0.41, alpha: 1)
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
        composerPlaceholder.layer.cornerRadius = 20
        composerPlaceholder.layer.cornerCurve = .continuous
        composerPlaceholder.accessibilityIdentifier = AccessibilityID.composerPlaceholder
        view.addSubview(composerPlaceholder)

        composerLabel.text = DestinationContent.composerHint
        composerLabel.font = .systemFont(ofSize: 16, weight: .regular)
        composerLabel.textColor = UIColor(white: 0.55, alpha: 1)
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
        statusLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        statusLabel.textColor = UIColor(white: 0.2, alpha: 0.7)
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
        guard pinchInteraction == nil, fullscreenRect != .zero else { return }
        #if DEBUG
        assertSurfaceTokenContinuity()
        #endif
        let baseline = PinchMorphState(progress: 0)
        animator.value = baseline
        animator.target = baseline
        handleAnimatorStateChange(baseline)
        let inter = PinchToMemoryInteraction(conversationView: conversationView, animator: animator)
        conversationView.addInteraction(inter)
        self.pinchInteraction = inter

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
        let middle = ((pageGradient?.colors as? [CGColor]) ?? [])
            .indices.contains(1) == true ? ((pageGradient!.colors as! [CGColor])[1].components ?? []) : []
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
                if final.progress >= 0.999 {
                    self.destinationCard.layer.shadowColor = UIColor.black.cgColor
                    self.destinationCard.layer.shadowOffset = CGSize(width: 0, height: 1)
                    self.destinationCard.layer.shadowRadius = 3
                    self.destinationCard.layer.shadowOpacity = 0.04
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
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }
        let p = state.progress
        statusLabel.text = "p: \(String(format: "%.3f", p))"
        conversationView.setTimelineCompression(p)

        // The chat surface's own dissolve (staggered top/bottom mask) is driven
        // inside ConversationContentView. Do NOT also fade conversationView.alpha
        // here — that would double-fade and erase the staggered reveal.
        //
        // Card silhouette emerges first, then label fades in once silhouette has
        // resolved (eye stops looking for glyphs, starts reading the name).
        destinationCard.alpha = rampedFrom(p, start: PinchTuning.cardEmergeStart, end: PinchTuning.cardEmergeEnd)
        let labelAlpha = rampedFrom(p, start: PinchTuning.labelEmergeStart, end: PinchTuning.labelEmergeEnd)
        destinationDate.alpha = labelAlpha
        destinationBody.alpha = labelAlpha

        pinchGlyph.alpha = state.affordanceAlpha
        menuButton.alpha = state.affordanceAlpha
        composerPlaceholder.alpha = 1 - state.progress
    }

    /// Linear ramp from 0 → 1 over [start, end], clamped outside.
    private func rampedFrom(_ p: CGFloat, start: CGFloat, end: CGFloat) -> CGFloat {
        guard p > start else { return 0 }
        guard p < end else { return 1 }
        return (p - start) / (end - start)
    }
}
