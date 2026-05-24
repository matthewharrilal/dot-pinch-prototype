import UIKit

@MainActor
final class RevealCoordinator {

    private(set) var activeChatVC: ChatViewController?
    private var revealBlurOverlay: RevealBlurOverlay?
    private var revealAnimators: [UIViewPropertyAnimator] = []

    var isPresenting: Bool { activeChatVC != nil }

    private weak var parent: UIViewController?
    private weak var canvas: UIView?

    init(parent: UIViewController, canvas: UIView) {
        self.parent = parent
        self.canvas = canvas
    }

    func present(conversation: Conversation, completion: (() -> Void)? = nil) {
        guard activeChatVC == nil,
              let parent, let parentView = parent.view, let canvas else {
            completion?()
            return
        }

        let chatVC = installChatViewController(in: parent, parentView: parentView, conversation: conversation)
        let blur = installRevealBlur(in: parentView)
        runRevealChoreography(chatVC: chatVC, canvas: canvas, blur: blur, completion: completion)
    }

    private func installChatViewController(in parent: UIViewController, parentView: UIView, conversation: Conversation) -> ChatViewController {
        let chatVC = ChatViewController()
        parent.addChild(chatVC)
        chatVC.view.translatesAutoresizingMaskIntoConstraints = false
        chatVC.view.alpha = 0
        chatVC.view.isUserInteractionEnabled = false
        parentView.addSubview(chatVC.view)
        NSLayoutConstraint.activate([
            chatVC.view.topAnchor.constraint(equalTo: parentView.topAnchor),
            chatVC.view.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            chatVC.view.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            chatVC.view.bottomAnchor.constraint(equalTo: parentView.bottomAnchor)
        ])
        chatVC.didMove(toParent: parent)
        chatVC.configure(with: conversation)
        chatVC.view.layoutIfNeeded()
        self.activeChatVC = chatVC
        return chatVC
    }

    private func installRevealBlur(in parentView: UIView) -> RevealBlurOverlay {
        let blur = RevealBlurOverlay(frame: .zero)
        blur.attach(to: parentView)
        self.revealBlurOverlay = blur
        return blur
    }

    private func runRevealChoreography(chatVC: ChatViewController,
                                       canvas: UIView,
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
        crossFade.addCompletion { position in
            if position == .end {
                chatVC.view.isUserInteractionEnabled = true
            }
        }
        crossFade.startAnimation(afterDelay: RevealTiming.crossFadeDelay)

        let blurFadeOut = UIViewPropertyAnimator(duration: RevealTiming.blurFadeOutDuration, timingParameters: easeInOut)
        blurFadeOut.addAnimations {
            blur.alpha = 0
        }
        blurFadeOut.addCompletion { [weak self] position in
            guard let self else { return }
            if position == .end {
                blur.detach()
                if self.revealBlurOverlay === blur { self.revealBlurOverlay = nil }
                completion?()
            }
            self.revealAnimators.removeAll { $0 === blurFadeIn || $0 === crossFade || $0 === blurFadeOut }
        }
        blurFadeOut.startAnimation(afterDelay: RevealTiming.blurDwellDelay)

        revealAnimators = [blurFadeIn, crossFade, blurFadeOut]
    }

    func dismiss(completion: (() -> Void)? = nil) {
        guard let chatVC = activeChatVC, let canvas else {
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
                self.activeChatVC = nil
                self.revealBlurOverlay?.detach()
                self.revealBlurOverlay = nil
                completion?()
            }
            self.revealAnimators.removeAll { $0 === dismissAnimator }
        }
        dismissAnimator.startAnimation()
        revealAnimators.append(dismissAnimator)
    }

    func cancelInFlight() {
        for animator in revealAnimators {
            if animator.state == .active {
                animator.stopAnimation(false)
                animator.finishAnimation(at: .current)
            }
        }
        revealAnimators.removeAll()
    }
}
