// RevealCoordinator — orchestrates the post-morph reveal sequence (blurFadeIn
// → crossFade → blurFadeOut) AND, per §32 / §2.4, performs the handoff from
// chatVC to cell.chatContent at blurFadeOut completion. Tracks the 6-stage
// HandoffPhase lifecycle so scene-deactivation recovery (completeHandoffIfPending)
// can resume from a partial state on foreground.

import UIKit

@MainActor
final class RevealCoordinator {

    // MARK: - State

    private enum RevealState {
        case idle
        case active(chat: ChatViewController, blur: RevealBlurOverlay)
    }

    private var revealState: RevealState = .idle
    private var revealAnimators: [UIViewPropertyAnimator] = []

    // MARK: - Handoff phase state machine (§32.3.1)

    enum HandoffPhase {
        case idle
        case presenting           // chatVC instantiated; blurFadeIn in flight
        case crossFadeStarted     // crossFade in flight; canvas.alpha animating to 0
        case crossFadeComplete    // canvas.alpha=0; normalize scheduled / running
        case blurFadeOutStarted   // blurFadeOut in flight
        case handoffComplete      // chatVC removed; chatContent visible; canvas.alpha=1
    }

    /// P5.5 private(set): read for tests / recovery; writes fenced to RevealCoordinator.
    private(set) var handoffPhase: HandoffPhase = .idle

    // MARK: - Public accessors

    var activeChatVC: ChatViewController? {
        if case .active(let chat, _) = revealState { return chat }
        return nil
    }

    var isPresenting: Bool {
        if case .active = revealState { return true }
        return false
    }

    // MARK: - Dependencies

    private weak var parent: UIViewController?
    private weak var canvas: TimelineCanvas?
    weak var stateController: ConversationStateController?

    init(parent: UIViewController, canvas: TimelineCanvas) {
        self.parent = parent
        self.canvas = canvas
    }

    // MARK: - Present (T=0 of reveal)

    func present(conversation: Conversation, completion: (() -> Void)? = nil) {
        guard case .idle = revealState,
              let parent, let parentView = parent.view, let canvas
        else {
            completion?()
            return
        }

        handoffPhase = .presenting

        let chatVC = installChatViewController(in: parent, parentView: parentView, conversation: conversation)
        let blur = installRevealBlur(in: parentView)
        revealState = .active(chat: chatVC, blur: blur)

        // P19.3 bind preserved state from controller INTO chatVC at install time
        // (per D10) so chatVC starts with the user's previous composer text /
        // scroll offset rather than empty defaults.
        if let stateController {
            stateController.bindToChatVCAtInstall(chatVC)
        }

        runRevealChoreography(chatVC: chatVC, canvas: canvas, blur: blur, completion: completion)
    }

    private func installChatViewController(in parent: UIViewController, parentView: UIView, conversation: Conversation) -> ChatViewController {
        let chatVC = ChatViewController()
        parent.addChild(chatVC)
        chatVC.view.translatesAutoresizingMaskIntoConstraints = false
        chatVC.view.alpha = 0
        chatVC.view.isUserInteractionEnabled = false
        parentView.addSubview(chatVC.view)
        chatVC.view.pinToSuperview(of: parentView)
        chatVC.didMove(toParent: parent)
        chatVC.configure(with: conversation)
        chatVC.view.layoutIfNeeded()
        return chatVC
    }

    private func installRevealBlur(in parentView: UIView) -> RevealBlurOverlay {
        let blur = RevealBlurOverlay(frame: .zero)
        blur.attach(to: parentView)
        return blur
    }

    // MARK: - Reveal choreography (with phase transitions + handoff)

    private func runRevealChoreography(chatVC: ChatViewController,
                                       canvas: TimelineCanvas,
                                       blur: RevealBlurOverlay,
                                       completion: (() -> Void)?) {
        let easeInOut = UICubicTimingParameters(animationCurve: .easeInOut)

        let blurFadeIn = UIViewPropertyAnimator(duration: RevealTiming.blurFadeInDuration, timingParameters: easeInOut)
        blurFadeIn.addAnimations {
            blur.alpha = 1
        }
        blurFadeIn.startAnimation()

        let crossFade = UIViewPropertyAnimator(duration: RevealTiming.crossFadeDuration, timingParameters: easeInOut)
        crossFade.addAnimations {
            chatVC.view.alpha = 1
            canvas.alpha = 0
        }
        crossFade.addCompletion { [weak self, weak canvas] position in
            guard position == .end, let self else { return }
            chatVC.view.isUserInteractionEnabled = true
            self.handoffPhase = .crossFadeComplete
            // Schedule normalize on next runloop tick so crossFade's writes commit first.
            DispatchQueue.main.async { [weak canvas] in
                guard let canvas, let activeIdx = canvas.activeCellIndex else { return }
                canvas.normalizeToChatRest(activeCellIndex: activeIdx)
            }
        }
        crossFade.startAnimation(afterDelay: RevealTiming.crossFadeDelay)

        // Schedule phase transition writes to fire at the actual animation
        // start moments. Writing synchronously here would mark handoffPhase
        // as e.g. .blurFadeOutStarted BEFORE crossFade has even kicked off,
        // which breaks the recovery state machine (completeHandoffIfPending
        // would skip normalize when normalize hadn't run yet).
        DispatchQueue.main.asyncAfter(deadline: .now() + RevealTiming.crossFadeDelay) { [weak self] in
            guard let self, self.handoffPhase == .presenting else { return }
            self.handoffPhase = .crossFadeStarted
        }

        let blurFadeOut = UIViewPropertyAnimator(duration: RevealTiming.blurFadeOutDuration, timingParameters: easeInOut)
        blurFadeOut.addAnimations {
            blur.alpha = 0
        }
        blurFadeOut.addCompletion { [weak self] position in
            guard let self else { return }
            if position == .end {
                self.performHandoff()
                self.handoffPhase = .handoffComplete
                blur.detach()
                completion?()
            }
            self.revealAnimators.removeAll { $0 === blurFadeIn || $0 === crossFade || $0 === blurFadeOut }
        }
        blurFadeOut.startAnimation(afterDelay: RevealTiming.blurDwellDelay)

        DispatchQueue.main.asyncAfter(deadline: .now() + RevealTiming.blurDwellDelay) { [weak self] in
            guard let self else { return }
            // Only transition if we haven't already advanced past this phase.
            if self.handoffPhase == .crossFadeComplete || self.handoffPhase == .crossFadeStarted {
                self.handoffPhase = .blurFadeOutStarted
            }
        }

        revealAnimators = [blurFadeIn, crossFade, blurFadeOut]
    }

    // MARK: - Handoff (§2.4.1)

    /// Execute the four-part handoff at blurFadeOut completion.
    /// Per §0.4: state capture → state apply → atomic alpha swap → post-cleanup.
    /// Pillar honors: P11.1, P12.2, P13.4, P19.3, P6.7, P1.1.
    private func performHandoff() {
        guard case .active(let chatVC, _) = revealState,
              let canvas,
              let activeIdx = canvas.activeCellIndex,
              let cell = canvas.instantiatedCells[activeIdx],
              let chatContent = cell.chatContentContainer,
              let stateController = self.stateController
        else {
            assertionFailure("performHandoff called with missing references")
            return
        }

        transferState(from: chatVC, to: chatContent, via: stateController)
        performAtomicAlphaSwap(chatVC: chatVC, canvas: canvas, chatContent: chatContent)
        restoreFirstResponderIfNeeded(chatVC: chatVC, chatContent: chatContent, via: stateController)
        detachAndReleaseChatVC(chatVC)
    }

    /// Step 1+2: capture state from chatVC, apply to chatContent.
    private func transferState(
        from chatVC: ChatViewController,
        to chatContent: ChatContentContainer,
        via stateController: ConversationStateController
    ) {
        stateController.captureFromChatVC(chatVC)
        chatContent.composer.composerTextField.text = stateController.composerText
        chatContent.bubbleStack.scrollContentOffset = stateController.scrollOffset
    }

    /// Step 3: atomic alpha swap inside one suppressed CATransaction.
    /// All 5 writes commit in one render pass — user sees no intermediate state.
    private func performAtomicAlphaSwap(
        chatVC: ChatViewController,
        canvas: TimelineCanvas,
        chatContent: ChatContentContainer
    ) {
        CATransaction.withSuppressedActions {
            chatVC.view.alpha = 0
            chatVC.view.isUserInteractionEnabled = false
            canvas.alpha = 1
            chatContent.alpha = 1
            canvas.pinchRecognizer.isEnabled = true
        }
    }

    /// Step 4a: re-assert first responder on chatContent's composer if chatVC's
    /// was a responder pre-swap. Called AFTER the CATransaction so UIKit's
    /// keyboard tracking sees the new responder as live.
    private func restoreFirstResponderIfNeeded(
        chatVC: ChatViewController,
        chatContent: ChatContentContainer,
        via stateController: ConversationStateController
    ) {
        guard stateController.composerIsFirstResponder else { return }
        let destination = chatContent.composer.composerTextField
        destination.becomeFirstResponder()
        if let savedRange = stateController.selectedTextRange {
            destination.selectedTextRange = mapTextRange(
                from: chatVC.composerTextField,
                to: destination,
                range: savedRange
            )
        }
    }

    /// Step 4b: remove chatVC from parent's child VCs and release strong reference.
    private func detachAndReleaseChatVC(_ chatVC: ChatViewController) {
        chatVC.willMove(toParent: nil)
        chatVC.view.removeFromSuperview()
        chatVC.removeFromParent()
        // Release strong reference by transitioning revealState back to .idle.
        revealState = .idle
    }

    /// Map a UITextRange from one text field to the equivalent range in another.
    /// UITextRange instances are bound to their source text field's internals;
    /// offset-based remap is the only correct approach.
    /// P19.1 pure.
    private func mapTextRange(
        from source: UITextField,
        to dest: UITextField,
        range: UITextRange
    ) -> UITextRange? {
        let startOffset = source.offset(from: source.beginningOfDocument, to: range.start)
        let endOffset = source.offset(from: source.beginningOfDocument, to: range.end)
        guard let destStart = dest.position(from: dest.beginningOfDocument, offset: startOffset),
              let destEnd = dest.position(from: dest.beginningOfDocument, offset: endOffset)
        else { return nil }
        return dest.textRange(from: destStart, to: destEnd)
    }

    // MARK: - Recovery (§32.3.1)

    /// Resume the handoff from a partial state on scene foreground.
    /// Idempotent: calling twice when phase ≠ partial completes once.
    func completeHandoffIfPending() {
        switch handoffPhase {
        case .idle, .handoffComplete:
            return

        case .presenting, .crossFadeStarted:
            recoverFromPreCrossFadeState()

        case .crossFadeComplete, .blurFadeOutStarted:
            recoverFromPostCrossFadeState()
        }

        handoffPhase = .handoffComplete
    }

    /// Pre-crossFade-complete deactivation: canvas may still be visible.
    /// Snap geometry forward to canvas.alpha=0 invariant, then run normalize + handoff.
    private func recoverFromPreCrossFadeState() {
        guard let canvas, let activeIdx = canvas.activeCellIndex else { return }
        canvas.alpha = 0
        canvas.normalizeToChatRest(activeCellIndex: activeIdx)
        performHandoff()
    }

    /// Post-crossFade-complete deactivation: canvas already at alpha=0.
    /// Normalize may have run; re-running is idempotent.
    private func recoverFromPostCrossFadeState() {
        guard let canvas, let activeIdx = canvas.activeCellIndex else { return }
        canvas.normalizeToChatRest(activeCellIndex: activeIdx)
        performHandoff()
    }

    // MARK: - Dismiss (unused in handoff flow; kept for orphan-path completeness)

    func dismiss(completion: (() -> Void)? = nil) {
        guard case .active(let chatVC, let blur) = revealState, let canvas else {
            completion?()
            return
        }
        chatVC.willMove(toParent: nil)
        chatVC.view.isUserInteractionEnabled = false

        let easeInOut = UICubicTimingParameters(animationCurve: .easeInOut)
        let dismissAnimator = UIViewPropertyAnimator(duration: RevealTiming.crossFadeDuration, timingParameters: easeInOut)
        dismissAnimator.addAnimations {
            chatVC.view.alpha = 0
            canvas.alpha = 1
        }
        dismissAnimator.addCompletion { [weak self] position in
            guard let self else { return }
            if position == .end {
                chatVC.view.removeFromSuperview()
                chatVC.removeFromParent()
                blur.detach()
                self.revealState = .idle
                self.handoffPhase = .idle
                completion?()
            }
            self.revealAnimators.removeAll { $0 === dismissAnimator }
        }
        dismissAnimator.startAnimation()
        revealAnimators.append(dismissAnimator)
    }

    // MARK: - Cancel in flight (scene deactivation)

    func cancelInFlight() {
        for animator in revealAnimators {
            if animator.state == .active {
                animator.stopAnimation(false)
                animator.finishAnimation(at: .current)
            }
        }
        revealAnimators.removeAll()
        // handoffPhase is NOT modified here per D-A.6: it reflects whatever
        // state the in-flight animation was in. Recovery on foreground reads it.
    }
}
