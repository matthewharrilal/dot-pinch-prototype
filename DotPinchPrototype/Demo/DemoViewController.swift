// DemoViewController — composition root.
// REFUSAL #3 + #7: chrome views are SIBLINGS of the card, never children.
// REFUSAL #8: subview hierarchy built once in viewDidLoad, never reordered.
// The animator's valueChanged is the single writer; writes to ONE target (card).

import UIKit

final class DemoViewController: UIViewController {

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
        // Token: any page-material surface uses Theme.Page.surface (no literals).
        view.backgroundColor = Theme.Page.surface
        view.accessibilityIdentifier = "DemoRoot"

        installPageGradient()
        installViewHierarchy()
        wireAnimator()
    }

    // Three-band gradient. Middle stop uses Theme.Page.surface — same token as
    // conversationView.backgroundColor and composerPlaceholder.backgroundColor.
    // The card is the gradient's middle band given edges; chromatic continuity
    // is the structural invariant that produces "card-is-page" identity.
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
        // Sibling of conversationView. Alpha 0 at baseline; alpha 1 at destination
        // (after the chat surface has faded). Container emerges from non-existence,
        // not from being-bigger.
        destinationCard.translatesAutoresizingMaskIntoConstraints = false
        destinationCard.backgroundColor = Theme.Page.surface
        destinationCard.layer.cornerRadius = 25
        destinationCard.layer.cornerCurve = .continuous
        destinationCard.alpha = 0
        destinationCard.isUserInteractionEnabled = false
        view.addSubview(destinationCard)

        destinationDate.text = "Mon, Jul 1"
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
            string: "Good morning check-in, daily exercise nudge, 20-minute workout suggestions",
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

    // Affordance icons — siblings of the card (REFUSAL #3 + #7).
    // alpha 0→1 ride on state.affordanceAlpha.
    private func installAffordances() {
        pinchGlyph.image = UIImage(
            systemName: "arrow.down.right.and.arrow.up.left",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .light)
        )
        pinchGlyph.tintColor = UIColor(white: 0.59, alpha: 1)
        pinchGlyph.alpha = 0
        pinchGlyph.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pinchGlyph)

        menuButton.setImage(
            UIImage(systemName: "ellipsis",
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
        // Composer is another page-material surface with edges — same token as card.
        composerPlaceholder.backgroundColor = Theme.Page.surface
        composerPlaceholder.layer.cornerRadius = 20
        composerPlaceholder.layer.cornerCurve = .continuous
        composerPlaceholder.accessibilityIdentifier = "ComposerPlaceholder"
        view.addSubview(composerPlaceholder)

        composerLabel.text = "Share with Dot…"
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
        statusLabel.accessibilityIdentifier = "StatusLabel"
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
    // Invariant: destination card, composer, and page gradient middle stop all
    // read Theme.Page.surface. The chat surface is a gradient (different shape)
    // but its TOP stop must equal Theme.Page.surface so the card-as-page-material
    // identity holds when the chat dissolves to reveal the card at that brightness.
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
        guard (animator.value?.progress ?? 0) >= 0.9 else { return }
        animator.value = PinchMorphState(progress: 1)
        animator.target = PinchMorphState(progress: 0)
        animator.velocity = PinchMorphState(progress: -2.0)
        animator.start()
    }

    private func wireAnimator() {
        animator.valueChanged = { [weak self] state in
            self?.handleAnimatorStateChange(state)
        }
        // REFUSAL #4: shadow is BINARY, not a function of progress. Set only at
        // .finished, never animated. Announces type ("card-shaped object"), not depth.
        animator.completion = { [weak self] event in
            guard let self else { return }
            if case .finished(let final) = event {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                // REFUSAL #4 + Stage 4: shadow announces object-ness on destinationCard
                // ONLY at settled destination. Binary flip, never animated.
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

        // Stage 3 chat surface dissolve is handled INSIDE conversationView via
        // a staggered mask (bottom-up). DO NOT also fade conversationView.alpha
        // here — that would double-fade and erase the staggered reveal.
        // Stage 3: card silhouette emerges — slight overlap with chat fade
        // leaves a brief no-figure window.
        destinationCard.alpha = rampedFrom(p, start: 0.72, end: 0.85)
        // Stage 4: label fades in AFTER silhouette resolves — eye stops looking
        // for glyphs, starts reading the name.
        let labelAlpha = rampedFrom(p, start: 0.85, end: 1.0)
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
