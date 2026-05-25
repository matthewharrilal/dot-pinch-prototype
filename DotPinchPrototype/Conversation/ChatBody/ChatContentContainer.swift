// ChatContentContainer — composes ChatHeaderView + ChatBubbleStackView +
// ChatComposerView into the cell's chat-rest representation. Cross-view
// constraints anchor each subview to parentVC.view.safeAreaLayoutGuide
// (Strategy A per §3.3) so post-handoff visible positions match chatVC's
// pre-handoff positions pixel-for-pixel.

import UIKit

@MainActor
final class ChatContentContainer: UIView {

    // MARK: - Subviews (closure-init at class top per P1.2)

    let header: ChatHeaderView = ChatHeaderView()
    let bubbleStack: ChatBubbleStackView = ChatBubbleStackView()
    let composer: ChatComposerView = ChatComposerView()

    // MARK: - Parent VC reference (weak per retain-cycle audit §3.6)

    // ChatContent is owned by cell which is owned by canvas which is owned by
    // V2RootVC; parentVC IS V2RootVC. Strong reference would close the loop.
    private weak var parentVC: UIViewController?

    // MARK: - Cross-view constraints (per §3.6 retain-cycle audit)

    private var crossViewConstraints: [NSLayoutConstraint] = []

    // MARK: - Layout tokens (P2.11)

    private enum Layout {
        static let headerTop: CGFloat = 24
        static let horizontalInset: CGFloat = 20
        static let bubbleStackTopGap: CGFloat = 24
        static let bubbleHorizontalInset: CGFloat = 20
        static let composerTopGap: CGFloat = 16
        static let composerHorizontalInset: CGFloat = 16
        static let composerBottomInset: CGFloat = 12
        static let composerHeight: CGFloat = 44
    }

    // MARK: - Init

    init(parentVC: UIViewController) {
        self.parentVC = parentVC
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        // Theme.Page.surface (Q2 verified: ≠ Theme.Cell.fill) to match
        // chatVC.view.backgroundColor at CVC:22 for handoff alpha-swap parity.
        backgroundColor = Theme.Page.surface
        isOpaque = true
        installViewHierarchy()
        // NOTE: activateCrossViewConstraints() is NOT called here. At init time,
        // self is not yet a subview of anything — header.topAnchor and
        // parentView.safeAreaLayoutGuide.topAnchor have no common ancestor and
        // NSLayoutConstraint.activate would crash with NSGenericException.
        // Caller (CellView.installChatContentIfNeeded) must call
        // activateCrossViewConstraints() AFTER addSubview connects the trees.
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("ChatContentContainer is code-only; no NSCoder support")
    }

    // MARK: - Configure

    /// Configure all three subviews with the conversation data. Idempotent.
    func configure(with conversation: Conversation) {
        header.configure(with: conversation)
        bubbleStack.configure(with: conversation)
        composer.configure(with: conversation)
    }

    // MARK: - View hierarchy

    private func installViewHierarchy() {
        addSubview(header)
        addSubview(bubbleStack)
        addSubview(composer)
    }

    // MARK: - Cross-view constraint setup

    /// Anchor header / bubbleStack / composer to chatContent's OWN edges with
    /// constants that bake in the parent view's safe-area insets. Cross-view
    /// constraints to parentView.safeAreaLayoutGuide DON'T work here because
    /// the cell hosting chatContent is inside canvas which has a
    /// sublayerTransform applied at render time. Layout-coord constraints
    /// to V2RootVC.safeAreaLayoutGuide compute positions in LAYOUT space, but
    /// the actual render position is offset by sublayerTransform.tY, causing
    /// composer (et al.) to render off-screen / be clipped by cell.masksToBounds.
    ///
    /// Solution: read parentView.safeAreaInsets at activation time, bake the
    /// values into constraint constants. chatContent fills the cell which at
    /// chat-rest exactly fills the viewport (heightConstraint = bounds.height),
    /// so chatContent's local coord system maps 1:1 to the rendered viewport.
    /// Subviews positioned at safeArea-relative chatContent-y values render
    /// at the correct window positions.
    ///
    /// MUST be called AFTER this container has been added as a subview so
    /// parentView.safeAreaInsets reflects the window-resolved safe area.
    func activateCrossViewConstraints() {
        guard let parentView = parentVC?.view else {
            preconditionFailure("ChatContentContainer requires non-nil parentVC at setup time")
        }

        // Read the parent's safe area at activation time. Bake into constants.
        // (Doesn't react to rotation; iPhone is portrait-only per project.yml.)
        let safeTop = parentView.safeAreaInsets.top
        let safeBottom = parentView.safeAreaInsets.bottom

        // Effective top offset from chatContent.top to header.top = safeTop + 24pt gap.
        // Effective bottom offset from chatContent.bottom to composer.bottom = safeBottom + 12pt gap.
        let headerTopFromContentTop = safeTop + Layout.headerTop
        let composerBottomFromContentBottom = safeBottom + Layout.composerBottomInset

        crossViewConstraints = [
            // Header pinned to chatContent.top + safeArea + 24pt (matches chatVC's window position)
            header.topAnchor.constraint(equalTo: topAnchor, constant: headerTopFromContentTop),
            header.leadingAnchor.constraint(
                greaterThanOrEqualTo: leadingAnchor,
                constant: Layout.horizontalInset
            ),
            header.trailingAnchor.constraint(
                lessThanOrEqualTo: trailingAnchor,
                constant: -Layout.horizontalInset
            ),
            header.centerXAnchor.constraint(equalTo: centerXAnchor),

            // Bubble stack between header and composer
            bubbleStack.topAnchor.constraint(equalTo: header.bottomAnchor, constant: Layout.bubbleStackTopGap),
            bubbleStack.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: Layout.bubbleHorizontalInset
            ),
            bubbleStack.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -Layout.bubbleHorizontalInset
            ),
            bubbleStack.bottomAnchor.constraint(equalTo: composer.topAnchor, constant: -Layout.composerTopGap),

            // Composer pinned to chatContent.bottom - (safeArea.bottom + 12pt)
            composer.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: Layout.composerHorizontalInset
            ),
            composer.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -Layout.composerHorizontalInset
            ),
            composer.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -composerBottomFromContentBottom
            ),
            composer.heightAnchor.constraint(equalToConstant: Layout.composerHeight)
        ]
        NSLayoutConstraint.activate(crossViewConstraints)
    }

    /// Deactivate cross-view constraints. Called by cell on rebind / pool eviction
    /// per §3.7 retain-cycle audit.
    func teardownCrossViewConstraints() {
        NSLayoutConstraint.deactivate(crossViewConstraints)
        crossViewConstraints.removeAll()
    }
}
