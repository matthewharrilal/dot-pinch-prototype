//
//  ConversationContentView.swift
//  DotPinchPrototype
//
//  The morphing surface's contents. Lives inside the conversation view that
//  PinchToMemoryInteraction animates.
//
//  The contents are deliberately autolayout-driven (UIStackView + UILabels with
//  numberOfLines = 0) so that as the parent's bounds change during the morph, the
//  labels REFLOW LIVE — proving Soul Piece #6's claim that identity is preserved
//  by structural correspondence, not snapshot-and-tween.
//

import UIKit

final class ConversationContentView: UIView {

    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    private let dateLabel = UILabel()
    private let messages: [String] = [
        "Good morning! Just a quick check-in about your daily exercise goal. I know it's early, but a 20-minute workout can really kickstart your Monday. Whether it's a brisk walk, some stretching, or a quick home workout, it's a great way to energize yourself for the week ahead.",
        "I've noticed you haven't been responding to these reminders lately. If they're not helpful or if you'd prefer a different approach, just let me know. I'm here to support you in a way that works best for you."
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setUp() {
        // Page background gradient — peach/rose persistent substrate (Soul Piece #2).
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.white.cgColor,
            UIColor(red: 1.0, green: 0.93, blue: 0.93, alpha: 1).cgColor,
            UIColor(red: 0.95, green: 0.78, blue: 0.85, alpha: 1).cgColor
        ]
        gradient.locations = [0, 0.65, 1]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        gradient.frame = bounds
        layer.insertSublayer(gradient, at: 0)
        self.gradientLayer = gradient

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)

        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        dateLabel.text = "Mon, Jul 1 at 3:12 AM"
        dateLabel.font = .systemFont(ofSize: 13, weight: .regular)
        dateLabel.textColor = UIColor(white: 0.45, alpha: 1)
        dateLabel.textAlignment = .center
        dateLabel.numberOfLines = 1
        stack.addArrangedSubview(dateLabel)

        for message in messages {
            let label = UILabel()
            label.text = message
            label.font = .systemFont(ofSize: 17, weight: .regular)
            label.textColor = UIColor(white: 0.1, alpha: 1)
            label.numberOfLines = 0  // critical for live reflow during morph
            label.lineBreakMode = .byWordWrapping
            stack.addArrangedSubview(label)
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 60),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -80),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        clipsToBounds = true
        accessibilityIdentifier = "ConversationSurface"
    }

    private weak var gradientLayer: CAGradientLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = bounds
    }
}
