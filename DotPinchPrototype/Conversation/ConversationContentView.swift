// The chat surface — UIScrollView with N past messages + 1 current message.
// The chat surface (self) holds station; only contentRoot scales via the 2D
// similarity transform. Stage 2 dissolves the surface bottom-first under blur,
// revealing the page's warm-pink before the cool-grey top fades.
//
// Knows nothing about gestures or springs — exposes a single token-driven API.

import UIKit

final class ConversationContentView: UIView {

    // MARK: - Subviews

    /// Chat-surface internal gradient: cool-top (L=92%) → warm-bottom (L=95%).
    /// A brighter version of the page gradient — "the page lit up."
    private let chatGradient = CAGradientLayer()

    /// Stage-2 staggered dissolve mask. Bottom fades first (revealing page's
    /// warm-pink); top fades later (revealing cool-grey). Driven via the
    /// gradient layer's top/bottom alpha animating at different rates.
    private let chatMask = CAGradientLayer()

    private let contentRoot = UIView()
    private let scrollView = UIScrollView()
    private let contentView = UIStackView()

    /// Uniform blur (Refusal #5). UIVisualEffectView covers full bounds.
    private let blurOverlay = UIVisualEffectView(effect: nil)
    private var blurAnimator: UIViewPropertyAnimator?

    /// Captured at first layout — `contentOffset.y` at which the current message
    /// sits at the top of the visible area (past messages offscreen above).
    private var baselineOffsetY: CGFloat = 0
    private var didCaptureBaseline = false

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureChatSurfaceLayers()
        configureSelfAppearance()
        configureContentHierarchy()
        installBlurOverlay()
        activateLayoutConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    // MARK: - Setup

    private func configureChatSurfaceLayers() {
        chatGradient.colors = [Theme.Chat.topTint.cgColor, Theme.Chat.bottomTint.cgColor]
        chatGradient.locations = [0, 1]
        chatGradient.startPoint = CGPoint(x: 0.5, y: 0)
        chatGradient.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(chatGradient, at: 0)

        // Mask colors[0] = top alpha, colors[1] = bottom alpha. Both start opaque.
        chatMask.colors = [UIColor.black.cgColor, UIColor.black.cgColor]
        chatMask.locations = [0, 1]
        chatMask.startPoint = CGPoint(x: 0.5, y: 0)
        chatMask.endPoint = CGPoint(x: 0.5, y: 1)
        layer.mask = chatMask
    }

    private func configureSelfAppearance() {
        overrideUserInterfaceStyle = .light
        accessibilityIgnoresInvertColors = true
        tintAdjustmentMode = .normal
        // No cornerRadius — the chat surface has no edge identity at Stage 1.
        clipsToBounds = true
        accessibilityIdentifier = AccessibilityID.conversationSurface
    }

    private func configureContentHierarchy() {
        contentRoot.translatesAutoresizingMaskIntoConstraints = false
        contentRoot.backgroundColor = .clear
        addSubview(contentRoot)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isScrollEnabled = false
        scrollView.panGestureRecognizer.isEnabled = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.clipsToBounds = true
        scrollView.backgroundColor = .clear
        contentRoot.addSubview(scrollView)

        contentView.axis = .vertical
        contentView.spacing = 16
        contentView.alignment = .fill
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        for past in ChatTranscript.past {
            contentView.addArrangedSubview(ChatBubbleView(message: past))
        }
        contentView.addArrangedSubview(ChatBubbleView(message: ChatTranscript.current))
    }

    private func activateLayoutConstraints() {
        NSLayoutConstraint.activate([
            contentRoot.topAnchor.constraint(equalTo: topAnchor),
            contentRoot.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentRoot.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentRoot.bottomAnchor.constraint(equalTo: bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: contentRoot.topAnchor, constant: 60),
            scrollView.leadingAnchor.constraint(equalTo: contentRoot.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: contentRoot.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: contentRoot.bottomAnchor, constant: -80),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    // MARK: - Blur overlay

    private func installBlurOverlay() {
        blurOverlay.translatesAutoresizingMaskIntoConstraints = false
        blurOverlay.isUserInteractionEnabled = false
        blurOverlay.alpha = 0
        addSubview(blurOverlay)
        NSLayoutConstraint.activate([
            blurOverlay.topAnchor.constraint(equalTo: topAnchor),
            blurOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurOverlay.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Paused animator — fractionComplete drives blur intensity.
        // .systemThickMaterial is the strongest standard blur, used to make text
        // fully unreadable at Stage 2 peak.
        let animator = UIViewPropertyAnimator(duration: 1, curve: .linear) { [weak self] in
            self?.blurOverlay.effect = UIBlurEffect(style: .systemThickMaterial)
        }
        animator.pausesOnCompletion = true
        animator.fractionComplete = 0
        self.blurAnimator = animator
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        chatGradient.frame = bounds
        chatMask.frame = bounds
        captureBaselineOffsetIfNeeded()
    }

    /// On the first valid layout pass, scroll the contentView so the current
    /// message sits at the top of the visible viewport with past messages
    /// laid out above it (offscreen at baseline; revealed by the morph).
    private func captureBaselineOffsetIfNeeded() {
        guard !didCaptureBaseline else { return }
        layoutIfNeeded()

        let pastBubbles = contentView.arrangedSubviews.prefix(ChatTranscript.past.count)
        guard pastBubbles.count == ChatTranscript.past.count else { return }

        let heightAbove = pastBubbles.reduce(into: CGFloat.zero) { sum, bubble in
            sum += bubble.bounds.height + contentView.spacing
        }
        guard heightAbove > 0 else { return }

        baselineOffsetY = heightAbove

        // bounces=false hard-clamps contentOffset.y to [0, contentSize.height - bounds.height].
        // If the current bubble is shorter than the viewport, baselineOffsetY
        // would exceed maxScroll and past content peeks at top. Add bottom inset
        // so baselineOffsetY is always reachable.
        let currentBubbleHeight = contentView.arrangedSubviews.last?.bounds.height ?? 0
        scrollView.contentInset.bottom = max(0, scrollView.bounds.height - currentBubbleHeight)
        scrollView.contentOffset = CGPoint(x: 0, y: baselineOffsetY)
        didCaptureBaseline = true
    }

    // MARK: - Public API

    /// Apply the morph's render-token bundle. Pure projection — no curve math
    /// happens here; tokens carry the already-derived values.
    func apply(_ tokens: ConversationMorphTokens) {
        CATransaction.withSuppressedActions {
            contentRoot.transform = .similarity(
                scale: tokens.similarityScale,
                anchor: effectiveAnchorPoint,
                in: bounds
            )

            blurOverlay.alpha = tokens.blurFraction
            blurAnimator?.fractionComplete = tokens.blurFraction

            chatMask.colors = [
                UIColor.black.withAlphaComponent(tokens.chatTopAlpha).cgColor,
                UIColor.black.withAlphaComponent(tokens.chatBottomAlpha).cgColor
            ]

            #if DEBUG
            assertSimilarity(contentRoot.transform)
            #endif
        }
    }

    /// PinchTuning's anchor flipped along X for right-to-left layouts.
    private var effectiveAnchorPoint: CGPoint {
        let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
        let x = isRTL ? (1 - PinchTuning.anchorPoint.x) : PinchTuning.anchorPoint.x
        return CGPoint(x: x, y: PinchTuning.anchorPoint.y)
    }

    // MARK: - DEBUG invariants

    #if DEBUG
    private func assertSimilarity(_ t: CGAffineTransform) {
        let eps: CGFloat = 1e-6
        precondition(abs(t.b) < eps && abs(t.c) < eps, "shear (b=\(t.b), c=\(t.c))")
        precondition(abs(t.a - t.d) < eps, "anisotropic scale sx=\(t.a) sy=\(t.d)")
    }
    #endif
}
