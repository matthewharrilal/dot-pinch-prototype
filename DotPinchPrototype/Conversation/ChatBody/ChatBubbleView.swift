// ChatBubbleView — a single chat-bubble row rendering one Message.
//
// Tier 3B+: this view is hosted inside ChatBodyView, which is hosted inside
// ConversationCell. It knows only how to render a single utterance — no
// awareness of gestures, springs, or sibling messages.
//
// Vocabulary discipline (per docs/VOCABULARY.md):
//   • Authorship reads from `Message.Role` — never "sender", never "you", never "bot".
//   • The view renders a role-derived label string for display; the canonical
//     vocabulary (user / assistant) is preserved at the data layer.

import UIKit

final class ChatBubbleView: UIView {

    // MARK: - Init

    init(message: Message) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        let senderLabel = UILabel()
        senderLabel.text = Self.displayName(for: message.role)
        senderLabel.font = Theme.Typography.bubbleSender
        senderLabel.textColor = Theme.Text.secondary
        senderLabel.numberOfLines = 1
        senderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(senderLabel)

        let bodyLabel = UILabel()
        bodyLabel.text = message.content
        bodyLabel.font = Theme.Typography.bubbleBody
        bodyLabel.textColor = Theme.Text.primary
        bodyLabel.numberOfLines = 0   // live reflow during the morph
        bodyLabel.lineBreakMode = .byWordWrapping
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bodyLabel)

        let timeLabel = UILabel()
        timeLabel.text = Self.timestampFormatter.string(from: message.timestamp)
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

    // MARK: - Role display

    /// Human-readable label for the bubble header. The data layer keeps the
    /// canonical `user` / `assistant` vocabulary; the view layer chooses the
    /// presentation string. Matches the legacy transcript labels (You /
    /// Assistant) so the visual identity is preserved.
    private static func displayName(for role: Message.Role) -> String {
        switch role {
        case .user:      return "You"
        case .assistant: return "Assistant"
        }
    }

    // MARK: - Timestamp formatting

    /// Cached formatter — `DateFormatter` is expensive to construct, and every
    /// bubble would otherwise pay that cost on init. Matches the legacy
    /// transcript style ("Mon, Jul 1 at 3:00 AM").
    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d 'at' h:mm a"
        return f
    }()
}
