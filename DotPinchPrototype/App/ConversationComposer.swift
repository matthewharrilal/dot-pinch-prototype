// Composition root for the Conversation feature. AppDelegate calls .make()
// to receive a wired-up view controller; nothing else in the app needs to
// know how the AnimationController, spring, animator, and pinch interaction
// are assembled. Every dependency flows through this graph — no singletons.

import UIKit

enum ConversationComposer {

    static func make() -> UIViewController {
        let animationController = AnimationController()
        let spring = Spring(
            dampingRatio: PinchTuning.springDamping,
            response: PinchTuning.springResponse
        )
        let animator = SpringAnimator<PinchMorphState>(
            controller: animationController,
            spring: spring,
            value: .zero,
            target: .zero
        )
        let interaction = PinchToMemoryInteraction(animator: animator)
        return ConversationViewController(
            animationController: animationController,
            animator: animator,
            pinchInteraction: interaction
        )
    }
}
