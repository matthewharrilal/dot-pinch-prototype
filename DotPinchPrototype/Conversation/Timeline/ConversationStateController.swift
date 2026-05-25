// ConversationStateController — transient UI state per conversation (composer
// text, scroll offset, first-responder flag, selected text range). Owned by
// the cell; lifetime matches cell pool LRU; survives chatVC dismissal so
// state continuity holds across tap → handoff → reverse → re-tap round-trips.
//
// Per D4 / §5.3: cell owns one controller per active conversation. Per D6:
// capture-at-handoff (not continuous sync). Per D10: stateController binds
// state into chatVC at install time to fix the §4.8 round-trip bug.

import UIKit

@MainActor
final class ConversationStateController: NSObject {

    // MARK: - Identity

    let conversationID: UUID

    // MARK: - Transient state (P8.3 var-justified — mutates as user interacts)

    var composerText: String = ""
    var scrollOffset: CGPoint = .zero
    var composerIsFirstResponder: Bool = false
    var selectedTextRange: UITextRange?

    // MARK: - Bound view (weak, allows pool eviction to release)

    private weak var boundChatContent: ChatContentContainer?

    // MARK: - Init

    init(conversationID: UUID) {
        self.conversationID = conversationID
        super.init()
    }

    // MARK: - Bind / unbind

    /// Bind to a chatContent view; subsequent capture/apply calls target it.
    /// P19.3 idempotent: rebinding to the same view is a no-op.
    /// P12.2 tell-don't-ask: writes via chatContent's public accessors only.
    func bind(to chatContent: ChatContentContainer) {
        boundChatContent = chatContent
        chatContent.composer.composerTextField.text = composerText
        chatContent.bubbleStack.scrollContentOffset = scrollOffset
        // First responder is deferred to handoff-completion handling.
    }

    func unbind() {
        boundChatContent = nil
    }

    // MARK: - Capture from ChatVC

    /// Read transient state from chatVC into this controller.
    /// P19.3 idempotent.
    func captureFromChatVC(_ chatVC: ChatViewController) {
        let snapshot = chatVC.captureTransientState()
        composerText = snapshot.composerText
        scrollOffset = snapshot.scrollOffset
        composerIsFirstResponder = snapshot.composerWasFirstResponder
        selectedTextRange = snapshot.selectedTextRange
    }

    /// Write preserved state into a freshly-instantiated chatVC at install time.
    /// Solves the §4.8 round-trip bug per D10.
    /// P19.3 idempotent.
    func bindToChatVCAtInstall(_ chatVC: ChatViewController) {
        let snapshot = ChatViewController.TransientStateSnapshot(
            composerText: composerText,
            scrollOffset: scrollOffset,
            composerWasFirstResponder: composerIsFirstResponder,
            selectedTextRange: selectedTextRange
        )
        chatVC.bindTransientState(snapshot)
    }

    /// Write captured state into the currently-bound chatContent.
    /// P19.3 idempotent.
    func applyToBoundChatContent() {
        // The bound chatContent may be nil if cell pool evicted before apply.
        // Silent return here is the documented base case.
        guard let chatContent = boundChatContent else { return }
        chatContent.composer.composerTextField.text = composerText
        chatContent.bubbleStack.scrollContentOffset = scrollOffset
    }
}
