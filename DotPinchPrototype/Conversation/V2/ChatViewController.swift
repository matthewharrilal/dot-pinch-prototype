import UIKit

@MainActor
final class ChatViewController: UIViewController {

    private let headerLabel = UILabel()
    private let scrollView = UIScrollView()
    private let bubbleStack = UIStackView()
    private let composerContainer = UIView()
    private let composerTextField = UITextField()

    private var conversation: Conversation?

    override func loadView() {
        view = UIView()
        view.backgroundColor = Theme.Page.surface
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        installHeader()
        installScrollView()
        installComposer()
        activateConstraints()
    }

    func configure(with conversation: Conversation) {
        self.conversation = conversation
        headerLabel.text = ChatViewController.headerText(for: conversation)
        rebuildBubbles(from: conversation.messages)
        view.layoutIfNeeded()
        DispatchQueue.main.async { [weak self] in
            self?.scrollToBottom(animated: false)
        }
    }

    private static func headerText(for conversation: Conversation) -> String {
        let calendar = Calendar.current
        let date = conversation.createdAt
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return conversation.displayDate
    }

    private func installHeader() {
        headerLabel.font = Theme.Typography.destinationBody.withSize(28)
        headerLabel.textColor = Theme.Text.primary
        headerLabel.textAlignment = .center
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerLabel)
    }

    private func installScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .none
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        bubbleStack.axis = .vertical
        bubbleStack.alignment = .fill
        bubbleStack.spacing = 16
        bubbleStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(bubbleStack)
    }

    private func installComposer() {
        composerContainer.translatesAutoresizingMaskIntoConstraints = false
        composerContainer.backgroundColor = Theme.Cell.fill
        composerContainer.layer.cornerRadius = 22
        composerContainer.layer.cornerCurve = .continuous
        view.addSubview(composerContainer)

        composerTextField.translatesAutoresizingMaskIntoConstraints = false
        composerTextField.font = Theme.Typography.composerHint
        composerTextField.textColor = Theme.Text.primary
        composerTextField.placeholder = "Share with Dot…"
        composerTextField.borderStyle = .none
        composerTextField.backgroundColor = .clear
        composerContainer.addSubview(composerTextField)
    }

    private func activateConstraints() {
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            headerLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            headerLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            scrollView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 24),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: composerContainer.topAnchor, constant: -16),

            bubbleStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            bubbleStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            bubbleStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            bubbleStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            bubbleStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            composerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            composerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            composerContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            composerContainer.heightAnchor.constraint(equalToConstant: 44),

            composerTextField.leadingAnchor.constraint(equalTo: composerContainer.leadingAnchor, constant: 16),
            composerTextField.trailingAnchor.constraint(equalTo: composerContainer.trailingAnchor, constant: -16),
            composerTextField.centerYAnchor.constraint(equalTo: composerContainer.centerYAnchor)
        ])
    }

    private func rebuildBubbles(from messages: [Message]) {
        for bubble in bubbleStack.arrangedSubviews {
            bubbleStack.removeArrangedSubview(bubble)
            bubble.removeFromSuperview()
        }
        for message in messages {
            bubbleStack.addArrangedSubview(ChatBubbleView(message: message))
        }
    }

    private func scrollToBottom(animated: Bool) {
        layoutIfNeeded()
        let bottomY = max(0, scrollView.contentSize.height - scrollView.bounds.height)
        scrollView.setContentOffset(CGPoint(x: 0, y: bottomY), animated: animated)
    }

    private func layoutIfNeeded() {
        view.layoutIfNeeded()
    }
}
