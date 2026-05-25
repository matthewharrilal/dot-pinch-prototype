// ChatComposerView — composer container holding the text field for outgoing
// messages. Mirrors chatVC.composerContainer + chatVC.composerTextField at
// CVC:70-84 + CVC:106-113. Pinned externally via ChatContentContainer's
// cross-view constraints to parentVC.view.safeAreaLayoutGuide.bottomAnchor.

import UIKit

@MainActor
final class ChatComposerView: UIView {

    // MARK: - Subviews (closure-init at class top per P1.2)

    private(set) var composerTextField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.font = Theme.Typography.composerHint
        field.textColor = Theme.Text.primary
        field.placeholder = "Share with Dot…"
        field.borderStyle = .none
        field.backgroundColor = .clear
        return field
    }()

    // MARK: - Token (P2.11)

    private enum Layout {
        static let cornerRadius: CGFloat = 22
        static let textFieldHorizontalInset: CGFloat = 16
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = Theme.Cell.fill
        layer.cornerRadius = Layout.cornerRadius
        layer.cornerCurve = .continuous
        installViewHierarchy()
        activateConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("ChatComposerView is code-only; no NSCoder support")
    }

    // MARK: - View hierarchy

    private func installViewHierarchy() {
        addSubview(composerTextField)
    }

    private func activateConstraints() {
        NSLayoutConstraint.activate([
            composerTextField.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: Layout.textFieldHorizontalInset
            ),
            composerTextField.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -Layout.textFieldHorizontalInset
            ),
            composerTextField.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    // MARK: - Configure

    /// Configure with a conversation. Currently a no-op (composer doesn't bind
    /// to conversation data — its content is user input). Reserved for future
    /// per-conversation composer state (e.g., draft persistence).
    func configure(with conversation: Conversation) {
        // Reserved for future per-conversation composer state.
    }
}
