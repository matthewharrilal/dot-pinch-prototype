// ChatHeaderView — chat-rest day-marker label. Mirrors chatVC.headerLabel
// styling at CVC:47-53 + CVC:90-93 constraints. Hosted inside
// ChatContentContainer; pinned to parentVC.view.safeAreaLayoutGuide.topAnchor
// via the container's cross-view constraints (Strategy A per §3.3).

import UIKit

@MainActor
final class ChatHeaderView: UIView {

    // MARK: - Subviews (closure-init at class top per P1.2)

    private let label: UILabel = {
        let label = UILabel()
        label.font = Theme.Typography.destinationBody.withSize(Layout.headerFontSize)
        label.textColor = Theme.Text.primary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Token (P2.11)

    private enum Layout {
        static let headerFontSize: CGFloat = 28
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        installViewHierarchy()
        activateConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("ChatHeaderView is code-only; no NSCoder support")
    }

    // MARK: - View hierarchy

    private func installViewHierarchy() {
        addSubview(label)
    }

    private func activateConstraints() {
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Configure

    /// Set day-marker text from conversation. Idempotent.
    func configure(with conversation: Conversation) {
        label.text = conversation.dayMarker()
    }
}
