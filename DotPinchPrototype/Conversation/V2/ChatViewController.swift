import UIKit

@MainActor
final class ChatViewController: UIViewController {

    private let headerLabel = UILabel()
    private let scrollView = UIScrollView()
    private let bubbleStack = UIStackView()
    private let composerContainer = UIView()
    private let composerTextField = UITextField()
    private let expandButton = UIButton(type: .system)
    private var pinchRecognizer: UIPinchGestureRecognizer!

    private var conversation: Conversation?

    /// Fires when the user begins a pinch on the chat surface (dismiss intent).
    var onPinchBegan: (() -> Void)?
    /// Fires on every pinch change. `scale` is the recognizer's current scale
    /// (1.0 = no change; <1 = pinch-in; >1 = pinch-out).
    var onPinchChanged: ((CGFloat) -> Void)?
    /// Fires when pinch ends. Caller decides commit vs cancel using scale + velocity.
    var onPinchEnded: ((CGFloat, CGFloat) -> Void)?
    /// Fires when the user taps the ↖ expand icon — a manual trigger for
    /// the same dismiss sequence the pinch gesture invokes. V2RootVC drives
    /// progress 0→1 via the existing display-link machinery (no scale or
    /// velocity required).
    var onDismissRequested: (() -> Void)?

    override func loadView() {
        view = UIView()
        view.backgroundColor = Theme.Page.surface
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        installHeader()
        installScrollView()
        installComposer()
        installExpandButton()
        activateConstraints()
        installPinchRecognizer()
    }

    private func installExpandButton() {
        let icon = UIImage(systemName: "arrow.up.left.and.arrow.down.right")
        expandButton.setImage(icon, for: .normal)
        expandButton.tintColor = Theme.Text.tertiary
        expandButton.translatesAutoresizingMaskIntoConstraints = false
        expandButton.addTarget(self, action: #selector(handleExpandTap), for: .touchUpInside)
        view.addSubview(expandButton)
        NSLayoutConstraint.activate([
            expandButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            expandButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            expandButton.widthAnchor.constraint(equalToConstant: 32),
            expandButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    @objc private func handleExpandTap() {
        onDismissRequested?()
    }

    private func installPinchRecognizer() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinch)
        pinchRecognizer = pinch
    }

    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .began:
            onPinchBegan?()
        case .changed:
            onPinchChanged?(recognizer.scale)
        case .ended, .cancelled, .failed:
            onPinchEnded?(recognizer.scale, recognizer.velocity)
            recognizer.scale = 1.0
        default:
            break
        }
    }

    /// Called by V2RootViewController per-frame while a pinch-to-dismiss is
    /// active. `progress` is 0 (chat-rest) → 1 (fully dismissed). Drives the
    /// chat's internal-content exits: composer slides down + fades, header
    /// + scroll content fade as the dismiss completes. Counterpart to the
    /// reference dot_pinch video's frames 5.3–5.7s where the composer +
    /// keyboard slide off-screen ahead of the chat-card resolution.
    func setDismissProgress(_ progress: CGFloat) {
        let p = max(0, min(1, progress))

        let composerP = smoothstep(0.3, 0.7, p)
        let exitDistance = view.bounds.height * 0.4
        composerContainer.transform = CGAffineTransform(translationX: 0, y: exitDistance * composerP)
        composerContainer.alpha = 1 - composerP

        let headerP = smoothstep(0.5, 0.9, p)
        headerLabel.alpha = 1 - headerP

        let bubbleP = smoothstep(0.55, 0.9, p)
        scrollView.alpha = 1 - bubbleP
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
        // Block taps from reaching the text field → never becomes first
        // responder → keyboard never appears on the chat interface. The
        // placeholder stays visible (visual-only composer). Pinch-to-
        // dismiss and ↖ button remain interactive because they're on
        // the chat view itself, not the composer.
        composerTextField.isUserInteractionEnabled = false
        composerContainer.isUserInteractionEnabled = false
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
