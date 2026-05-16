//
//  ConversationContentView.swift
//  DotPinchPrototype
//
//  The morphing surface's contents — promoted from a static UIStackView to a
//  UIScrollView holding `PinchTuning.pastMessageCount` past messages + 1 current
//  message in chronological order (past first, current last).
//
//  Baseline state: the current message sits at the top of the visible viewport;
//  the past messages are laid out ABOVE the viewport (offscreen up).
//  `setTimelineCompression(_:)` drives `contentOffset.y` downward (negative) to
//  scroll the contentView so past messages slide IN from above, while
//  simultaneously fading `contentView.alpha` toward `PinchTuning.contentAlphaFloor`.
//  Both effects are synchronous (PERCEPTUAL-DEEPENING-CYCLE2.md observations 1–3).
//
//  This file does NOT know about gestures or the spring substrate. It exposes a
//  single progress-driven API and is content to be called by anyone.
//

import UIKit

final class ConversationContentView: UIView {

    // MARK: - Public types

    /// Plain data for one message bubble in the timeline.
    struct MessageData {
        let sender: String
        let body: String
        let timestamp: String
    }

    // MARK: - Subviews

    // The chat surface (self) holds station. Its INTERNAL gradient is cool-top
    // (L=92%) → warm-bottom (L=95%) — a brighter version of the page gradient.
    private let chatGradient = CAGradientLayer()

    // Stage 2 staggered dissolve: bottom of chat dissolves FIRST (revealing the
    // page's warm-pink), top dissolves later (revealing cool-grey). Driven by
    // CAGradientLayer mask whose top/bottom alpha animate at different rates.
    private let chatMask = CAGradientLayer()

    private let contentRoot = UIView()
    private let scrollView = UIScrollView()
    private let contentView = UIStackView()

    // REFUSAL #5: uniform blur. UIVisualEffectView covers full bounds.
    private let blurOverlay = UIVisualEffectView(effect: nil)
    private var blurAnimator: UIViewPropertyAnimator?

    /// Captured at first layout — `contentOffset.y` at which the current message
    /// is at the top of the visible area (past messages offscreen above).
    private var baselineOffsetY: CGFloat = 0
    private var didCaptureBaseline = false

    // MARK: - Static data

    /// Five placeholder past messages (chronological, earliest first).
    /// Timestamps precede the current message's "Mon, Jul 1 at 3:12 AM".
    private static let pastMessages: [MessageData] = [
        MessageData(
            sender: "Assistant",
            body: "Hey, hope you slept okay. I'll send a gentle nudge in a bit about today's movement check-in.",
            timestamp: "Mon, Jul 1 at 3:00 AM"
        ),
        MessageData(
            sender: "You",
            body: "Awake. Couldn't sleep again. Mind a little loud tonight.",
            timestamp: "Mon, Jul 1 at 3:02 AM"
        ),
        MessageData(
            sender: "Assistant",
            body: "That sounds rough. Want to try a slow breath together, or just sit with the quiet for a minute first?",
            timestamp: "Mon, Jul 1 at 3:05 AM"
        ),
        MessageData(
            sender: "You",
            body: "Just sit. I'm okay. Maybe I'll try a walk when it gets light.",
            timestamp: "Mon, Jul 1 at 3:08 AM"
        ),
        MessageData(
            sender: "Assistant",
            body: "A short walk at dawn sounds restorative. I'll check in with the daily-movement nudge in a few minutes — feel free to ignore it if the walk feels like enough.",
            timestamp: "Mon, Jul 1 at 3:10 AM"
        )
    ]

    /// The single current message — preserved verbatim from the previous implementation.
    private static let currentMessage = MessageData(
        sender: "Assistant",
        body: "Good morning! Just a quick check-in about your daily exercise goal. I know it's early, but a 20-minute workout can really kickstart your Monday. Whether it's a brisk walk, some stretching, or a quick home workout, it's a great way to energize yourself for the week ahead.",
        timestamp: "Mon, Jul 1 at 3:12 AM"
    )

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setUp() {
        // Chat surface internal gradient: cool top (Theme.Page.surface, L=92%)
        // → warm bottom (Theme.Chat.bottomTint, L=95%). Brighter than page
        // gradient at same Y — "the page lit up." Replaces flat backgroundColor.
        chatGradient.colors = [Theme.Chat.topTint.cgColor, Theme.Chat.bottomTint.cgColor]
        chatGradient.locations = [0, 1]
        chatGradient.startPoint = CGPoint(x: 0.5, y: 0)
        chatGradient.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(chatGradient, at: 0)

        // Dissolve mask. colors[0] = top alpha, colors[1] = bottom alpha.
        // Both start opaque; bottom alpha fades first in Stage 2.
        chatMask.colors = [UIColor.black.cgColor, UIColor.black.cgColor]
        chatMask.locations = [0, 1]
        chatMask.startPoint = CGPoint(x: 0.5, y: 0)
        chatMask.endPoint = CGPoint(x: 0.5, y: 1)
        layer.mask = chatMask

        overrideUserInterfaceStyle = .light
        accessibilityIgnoresInvertColors = true
        tintAdjustmentMode = .normal

        // No cornerRadius on the chat surface — has no edge identity at Stage 1.
        clipsToBounds = true
        accessibilityIdentifier = "ConversationSurface"

        // contentRoot holds the scrollView. It receives the similarity transform.
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

        for past in Self.pastMessages {
            contentView.addArrangedSubview(Self.makeBubble(for: past))
        }
        contentView.addArrangedSubview(Self.makeBubble(for: Self.currentMessage))

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

    // MARK: - Blur overlay (REFUSAL #5)

    private func installBlurOverlay() {
        // Single UIVisualEffectView covering full bounds. Uniform sigma across
        // the card surface — no per-region masks, no radial gradients.
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

        // Paused animator scrubber — fractionComplete drives blur intensity.
        // Stage 2 demands TRUE illegibility (text becomes texture, not content).
        // .systemThickMaterial is the strongest standard blur — text fully
        // unreadable at peak.
        let animator = UIViewPropertyAnimator(duration: 1, curve: .linear) { [weak self] in
            self?.blurOverlay.effect = UIBlurEffect(style: .systemThickMaterial)
        }
        animator.pausesOnCompletion = true
        animator.fractionComplete = 0
        self.blurAnimator = animator
    }

    // MARK: - Bubble factory

    private static func makeBubble(for message: MessageData) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .clear

        let senderLabel = UILabel()
        senderLabel.text = message.sender
        senderLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        senderLabel.textColor = UIColor(white: 0.35, alpha: 1)
        senderLabel.numberOfLines = 1
        senderLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(senderLabel)

        let bodyLabel = UILabel()
        bodyLabel.text = message.body
        bodyLabel.font = .systemFont(ofSize: 17, weight: .regular)
        bodyLabel.textColor = UIColor(white: 0.1, alpha: 1)
        bodyLabel.numberOfLines = 0   // live reflow during morph
        bodyLabel.lineBreakMode = .byWordWrapping
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bodyLabel)

        let timeLabel = UILabel()
        timeLabel.text = message.timestamp
        timeLabel.font = .systemFont(ofSize: 12, weight: .regular)
        timeLabel.textColor = UIColor(white: 0.45, alpha: 1)
        timeLabel.numberOfLines = 1
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            senderLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            senderLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            senderLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -4),

            bodyLabel.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: 4),
            bodyLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            bodyLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),

            timeLabel.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 4),
            timeLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -4),
            timeLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])

        return container
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
        let pastBubbles = contentView.arrangedSubviews.prefix(PinchTuning.pastMessageCount)
        let currentBubble = contentView.arrangedSubviews.last
        if pastBubbles.count == PinchTuning.pastMessageCount, !didCaptureBaseline {
            // Sum the heights of the past bubbles plus the inter-bubble spacing
            // between them and the current message. Each gap contributes
            // `contentView.spacing`.
            var heightAbove: CGFloat = 0
            for bubble in pastBubbles {
                heightAbove += bubble.bounds.height + contentView.spacing
            }
            if heightAbove > 0 {
                baselineOffsetY = heightAbove

                // CRITICAL FIX: UIScrollView clamps contentOffset.y to
                // [0, contentSize.height - bounds.height]. With `bounces=false`
                // (R-4) the clamp is hard. If the current bubble is shorter
                // than the viewport, scrolling to baselineOffsetY (≈ past
                // heights) exceeds maxScroll → scroll clamps short → past
                // content peeks at the top of the viewport. Add a bottom
                // contentInset large enough that baselineOffsetY is always
                // reachable. Inset = viewport - currentBubble + safety margin.
                let currentH = currentBubble?.bounds.height ?? 0
                let viewportH = scrollView.bounds.height
                scrollView.contentInset.bottom = max(0, viewportH - currentH)

                scrollView.contentOffset = CGPoint(x: 0, y: baselineOffsetY)
                didCaptureBaseline = true
            }
        }
    }

    // MARK: - Public API — CANONICAL pinch-to-memory mechanic

    /// Slot rect in superview coordinates. Set by DemoViewController so the
    /// transform animation knows where to anchor the shrinking conversation.
    var slotRect: CGRect = .zero

    /// Drives the canonical pinch-to-memory mechanic per the lens-check:
    ///   • Soul #1: the conversation surface IS the chip — same view scales in place.
    ///   • Soul #6: as the surface scales down, MORE content appears via apparent
    ///     reflow (text rendered smaller per unit area).
    ///   • Soul #8: slot-anchored — scales toward slot center, not screen center.
    ///
    /// Implementation: CGAffineTransform applies scale + translation so the
    /// conversation appears to shrink toward slotRect. At `progress = 0` the view
    /// renders at full size in its original position. At `progress = 1` the view
    /// renders shrunk into slotRect.
    ///
    /// Writes wrapped in `CATransaction.setDisableActions(true)` (INV-2).
    // The chat surface (self) does NOT scale — it holds station (Stage 1 of relay).
    // Only contentRoot scales via similarity transform. The chat surface's alpha
    // and the destination card's appearance are driven by DemoVC (the single writer).
    func setTimelineCompression(_ progress: CGFloat) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        let p = max(0, min(1, progress))
        let s = PinchTuning.baselineSimilarityS
              - (PinchTuning.baselineSimilarityS - PinchTuning.destinationSimilarityS) * p

        let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
        let anchorX = isRTL ? (1 - PinchTuning.anchorPoint.x) : PinchTuning.anchorPoint.x
        let anchorY = PinchTuning.anchorPoint.y
        let tx = (anchorX - 0.5) * bounds.width  * (1 - s)
        let ty = (anchorY - 0.5) * bounds.height * (1 - s)

        // Transform on contentRoot, NOT self. Chat surface holds station.
        contentRoot.transform = CGAffineTransform(translationX: tx, y: ty).scaledBy(x: s, y: s)

        // REFUSAL #5: uniform blur driven by scalar plateau curve.
        let blurFraction = blurFractionForProgress(p)
        blurOverlay.alpha = blurFraction
        blurAnimator?.fractionComplete = blurFraction

        // Stage 2: staggered bottom-up dissolve. Bottom alpha fades early
        // (revealing the page's warm-pink), top alpha fades later (revealing
        // cool-grey). Overlap leaves a brief banded transition under blur.
        let fadeStart: CGFloat = 0.60
        let fadeEnd: CGFloat = 0.75
        let phase = max(0, min(1, (p - fadeStart) / (fadeEnd - fadeStart)))
        let bottomFade = clamp01(phase / 0.7)               // bottom fades phase 0 → 0.7
        let topFade    = clamp01((phase - 0.3) / 0.7)        // top fades phase 0.3 → 1.0
        let topAlpha    = 1 - topFade
        let bottomAlpha = 1 - bottomFade
        chatMask.colors = [
            UIColor.black.withAlphaComponent(topAlpha).cgColor,
            UIColor.black.withAlphaComponent(bottomAlpha).cgColor
        ]

        #if DEBUG
        assertSimilarity(contentRoot.transform)
        #endif
    }

    private func clamp01(_ x: CGFloat) -> CGFloat { max(0, min(1, x)) }

    // Register 1: blur = 0 (text fully legible, tracked motion).
    // Register 2 onset (~p=0.30): SHARP ramp to peak by p=0.40 — this is the
    // illegibility threshold; blur narrativizes the loss of tracking.
    // After p=0.40: blur stays at peak; conversationView.alpha fade hides it
    // in Register 3.
    private func blurFractionForProgress(_ p: CGFloat) -> CGFloat {
        let illegibilityStart: CGFloat = 0.30
        let illegibilityComplete: CGFloat = 0.40
        if p < illegibilityStart { return 0 }
        if p < illegibilityComplete {
            return (p - illegibilityStart) / (illegibilityComplete - illegibilityStart)
        }
        return 1
    }

    #if DEBUG
    private func assertSimilarity(_ t: CGAffineTransform) {
        let eps: CGFloat = 1e-6
        precondition(abs(t.b) < eps && abs(t.c) < eps, "REFUSAL #1: shear (b=\(t.b), c=\(t.c))")
        precondition(abs(t.a - t.d) < eps, "REFUSAL #1: anisotropic scale sx=\(t.a) sy=\(t.d)")
    }
    #endif
}

// MARK: - TimelineCompressible conformance
// Per IMPL-SPEC §0.4: the protocol abstraction prevents PinchToMemoryInteraction
// (Interaction layer) from depending on this concrete Demo-layer class. The
// conformance is empty because setTimelineCompression(_:) already exists above
// with the matching signature. This declaration lives in the Demo layer (legal
// upward dependency on Interaction's protocol).
extension ConversationContentView: TimelineCompressible {}
