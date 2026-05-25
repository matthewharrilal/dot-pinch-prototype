// ChatBubbleStackView — UIScrollView + vertical UIStackView holding bubble
// views. Mirrors chatVC.scrollView + chatVC.bubbleStack at CVC:55-68 with
// the same constraints + scroll behavior so post-handoff visual is identical
// to pre-handoff. Reuses existing ChatBubbleView per §16.11.

import UIKit

@MainActor
final class ChatBubbleStackView: UIView {

    // MARK: - Subviews (closure-init at class top per P1.2)

    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.backgroundColor = .clear
        scroll.alwaysBounceVertical = true
        scroll.keyboardDismissMode = .none
        scroll.showsVerticalScrollIndicator = false
        return scroll
    }()

    private let bubbleStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = Layout.bubbleSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Token (P2.11)

    private enum Layout {
        static let bubbleSpacing: CGFloat = 16
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        installViewHierarchy()
        activateConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("ChatBubbleStackView is code-only; no NSCoder support")
    }

    // MARK: - View hierarchy

    private func installViewHierarchy() {
        addSubview(scrollView)
        scrollView.addSubview(bubbleStack)
    }

    private func activateConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            bubbleStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            bubbleStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            bubbleStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            bubbleStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            bubbleStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    // MARK: - Configure

    /// Rebuild bubble views from conversation messages.
    /// P19.3 idempotent: same conversation produces identical view tree.
    func configure(with conversation: Conversation) {
        wipeBubbles()
        installBubbles(from: conversation.messages)
        layoutIfNeeded()
        scheduleScrollToBottom()
    }

    // MARK: - Configure helpers (P11.1 SRP)

    private func wipeBubbles() {
        for bubble in bubbleStack.arrangedSubviews {
            bubbleStack.removeArrangedSubview(bubble)
            bubble.removeFromSuperview()
        }
    }

    private func installBubbles(from messages: [Message]) {
        for message in messages {
            bubbleStack.addArrangedSubview(ChatBubbleView(message: message))
        }
    }

    private func scheduleScrollToBottom() {
        // scrollView.contentSize is derived from bubbleStack's intrinsic content,
        // which Auto Layout hasn't computed yet at the moment configure() returns.
        // Synchronous scroll would clamp to (0,0). Defer to next runloop tick.
        DispatchQueue.main.async { [weak self] in
            self?.scrollToBottom()
        }
    }

    private func scrollToBottom() {
        let bottomY = max(0, scrollView.contentSize.height - scrollView.bounds.height)
        scrollView.setContentOffset(CGPoint(x: 0, y: bottomY), animated: false)
    }

    // MARK: - State controller / handoff seam (P5.5)

    /// Read/write the scrollView's contentOffset. Used by the state controller
    /// and handoff capture/apply paths.
    var scrollContentOffset: CGPoint {
        get { scrollView.contentOffset }
        set { scrollView.contentOffset = newValue }
    }
}
