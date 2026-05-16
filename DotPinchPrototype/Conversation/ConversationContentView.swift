// The chat surface — UIScrollView with N past messages + 1 current message.
// The chat surface (self) holds station; only contentRoot scales via the 2D
// similarity transform. Stage 2 dissolves the surface bottom-first under blur,
// revealing the page's warm-pink before the cool-grey top fades.
//
// Knows nothing about gestures or springs — exposes a single progress-driven API.

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
    /// is at the top of the visible area (past messages offscreen above).
    private var baselineOffsetY: CGFloat = 0
    private var didCaptureBaseline = false

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setUp() {
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

        overrideUserInterfaceStyle = .light
        accessibilityIgnoresInvertColors = true
        tintAdjustmentMode = .normal

        // No cornerRadius — the chat surface has no edge identity at Stage 1.
        clipsToBounds = true
        accessibilityIdentifier = AccessibilityID.conversationSurface

        contentRoot.translatesAutoresizingMaskIntoConstraints = false
        contentRoot.backgroundColor = .clear
        addSubview(contentRoot)

        installBlurOverlay()

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

        // Capture baseline contentOffset.y on first valid layout. The baseline is
        // the offset at which the CURRENT message sits at the top of the visible
        // viewport — i.e., the height occupied by the past messages above it.
        // After this, the past messages exist in the contentView but live offscreen
        // above the viewport at baseline.
        layoutIfNeeded()
        let pastCount = ChatTranscript.past.count
        let pastBubbles = contentView.arrangedSubviews.prefix(pastCount)
        let currentBubble = contentView.arrangedSubviews.last
        if pastBubbles.count == pastCount, !didCaptureBaseline {
            var heightAbove: CGFloat = 0
            for bubble in pastBubbles {
                heightAbove += bubble.bounds.height + contentView.spacing
            }
            if heightAbove > 0 {
                baselineOffsetY = heightAbove

                // bounces=false hard-clamps contentOffset.y to
                // [0, contentSize.height - bounds.height]. If the current
                // bubble is shorter than the viewport, baselineOffsetY would
                // exceed maxScroll and past content peeks at top. Add bottom
                // inset so baselineOffsetY is always reachable.
                let currentH = currentBubble?.bounds.height ?? 0
                let viewportH = scrollView.bounds.height
                scrollView.contentInset.bottom = max(0, viewportH - currentH)

                scrollView.contentOffset = CGPoint(x: 0, y: baselineOffsetY)
                didCaptureBaseline = true
            }
        }
    }

    // MARK: - Public API

    /// Apply the morph's render-token bundle. Pure projection — no curve math
    /// happens here; tokens carry the already-derived values.
    func apply(_ tokens: ConversationMorphTokens) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        // Geometry — only contentRoot scales; chat surface (self) holds station.
        let s = tokens.similarityScale
        let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
        let anchorX = isRTL ? (1 - PinchTuning.anchorPoint.x) : PinchTuning.anchorPoint.x
        let anchorY = PinchTuning.anchorPoint.y
        let tx = (anchorX - 0.5) * bounds.width  * (1 - s)
        let ty = (anchorY - 0.5) * bounds.height * (1 - s)
        contentRoot.transform = CGAffineTransform(translationX: tx, y: ty).scaledBy(x: s, y: s)

        // Blur
        blurOverlay.alpha = tokens.blurFraction
        blurAnimator?.fractionComplete = tokens.blurFraction

        // Staggered chat dissolve (top + bottom of the mask).
        chatMask.colors = [
            UIColor.black.withAlphaComponent(tokens.chatTopAlpha).cgColor,
            UIColor.black.withAlphaComponent(tokens.chatBottomAlpha).cgColor
        ]

        #if DEBUG
        assertSimilarity(contentRoot.transform)
        #endif
    }

    #if DEBUG
    private func assertSimilarity(_ t: CGAffineTransform) {
        let eps: CGFloat = 1e-6
        precondition(abs(t.b) < eps && abs(t.c) < eps, "shear (b=\(t.b), c=\(t.c))")
        precondition(abs(t.a - t.d) < eps, "anisotropic scale sx=\(t.a) sy=\(t.d)")
    }
    #endif
}
