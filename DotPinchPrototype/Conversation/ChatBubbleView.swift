// A single chat-bubble row: sender + body + timestamp. Knows how to render
// itself given a ChatMessage; lays out its own subviews.

import UIKit

final class ChatBubbleView: UIView {

    init(message: ChatMessage) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        let senderLabel = UILabel()
        senderLabel.text = message.sender
        senderLabel.font = Theme.Typography.bubbleSender
        senderLabel.textColor = Theme.Text.secondary
        senderLabel.numberOfLines = 1
        senderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(senderLabel)

        let bodyLabel = UILabel()
        bodyLabel.text = message.body
        bodyLabel.font = Theme.Typography.bubbleBody
        bodyLabel.textColor = Theme.Text.primary
        bodyLabel.numberOfLines = 0   // live reflow during the morph
        bodyLabel.lineBreakMode = .byWordWrapping
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bodyLabel)

        let timeLabel = UILabel()
        timeLabel.text = message.timestamp
        timeLabel.font = Theme.Typography.bubbleTime
        timeLabel.textColor = Theme.Text.tertiary
        timeLabel.numberOfLines = 1
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(timeLabel)

        NSLayoutConstraint.activate([
            senderLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            senderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            senderLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),

            bodyLabel.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: 4),
            bodyLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            bodyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),

            timeLabel.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 4),
            timeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
            timeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}
