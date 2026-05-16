// Composition root for the Conversation feature. AppDelegate calls .make()
// to receive a wired-up view controller; nothing else in the app needs to
// know how the animator, spring, and pinch interaction are assembled.

import UIKit

enum ConversationComposer {

    static func make() -> UIViewController {
        let spring = Spring(
            dampingRatio: PinchTuning.springDamping,
            response: PinchTuning.springResponse
        )
        let animator = SpringAnimator<PinchMorphState>(
            spring: spring,
            value: .zero,
            target: .zero
        )
        let interaction = PinchToMemoryInteraction(animator: animator)
        return ConversationViewController(animator: animator, pinchInteraction: interaction)
    }
}
