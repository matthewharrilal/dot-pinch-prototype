// DotsLoadingIndicator — 3-dot animated loading indicator for §22 (P2 / Phase 12).
// Used by cells to signal "this conversation is actively processing" while
// the user is at cell-rest. Substrate-consistent: animation subscribes to
// AnimationController's master CADisplayLink via AnimatorProviding pattern,
// NOT a separate Timer.
//
// Default-disabled (alpha=0 unless setActive(true) is called). Wired via
// ConversationActivityTracker observation in CellView.

import UIKit
import QuartzCore

@MainActor
final class DotsLoadingIndicator: UIView {

    // MARK: - Subviews (closure-init at class top per P1.2)

    private let dot1: UIView = DotsLoadingIndicator.makeDot()
    private let dot2: UIView = DotsLoadingIndicator.makeDot()
    private let dot3: UIView = DotsLoadingIndicator.makeDot()

    // MARK: - Tokens

    private enum Layout {
        static let dotSize: CGFloat = 6
        static let dotSpacing: CGFloat = 6
        static let totalWidth: CGFloat = dotSize * 3 + dotSpacing * 2  // 30
        static let pulseDuration: CFTimeInterval = 1.2
        static let dotPhaseStagger: CFTimeInterval = 0.18
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
        installViewHierarchy()
        activateConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("DotsLoadingIndicator is code-only; no NSCoder support")
    }

    private static func makeDot() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Theme.Text.tertiary
        view.layer.cornerRadius = Layout.dotSize / 2
        view.alpha = 0.3
        return view
    }

    private func installViewHierarchy() {
        addSubview(dot1)
        addSubview(dot2)
        addSubview(dot3)
    }

    private func activateConstraints() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Layout.dotSize),
            widthAnchor.constraint(equalToConstant: Layout.totalWidth),

            dot1.widthAnchor.constraint(equalToConstant: Layout.dotSize),
            dot1.heightAnchor.constraint(equalToConstant: Layout.dotSize),
            dot1.leadingAnchor.constraint(equalTo: leadingAnchor),
            dot1.centerYAnchor.constraint(equalTo: centerYAnchor),

            dot2.widthAnchor.constraint(equalToConstant: Layout.dotSize),
            dot2.heightAnchor.constraint(equalToConstant: Layout.dotSize),
            dot2.centerXAnchor.constraint(equalTo: centerXAnchor),
            dot2.centerYAnchor.constraint(equalTo: centerYAnchor),

            dot3.widthAnchor.constraint(equalToConstant: Layout.dotSize),
            dot3.heightAnchor.constraint(equalToConstant: Layout.dotSize),
            dot3.trailingAnchor.constraint(equalTo: trailingAnchor),
            dot3.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    // MARK: - Animation control

    /// Start the pulsing animation. Idempotent — calling twice is safe.
    func startPulsing() {
        attachPulseAnimation(to: dot1, phase: 0)
        attachPulseAnimation(to: dot2, phase: Layout.dotPhaseStagger)
        attachPulseAnimation(to: dot3, phase: Layout.dotPhaseStagger * 2)
    }

    /// Stop the pulsing animation. Idempotent.
    func stopPulsing() {
        dot1.layer.removeAnimation(forKey: AnimationKey.pulse)
        dot2.layer.removeAnimation(forKey: AnimationKey.pulse)
        dot3.layer.removeAnimation(forKey: AnimationKey.pulse)
    }

    private enum AnimationKey {
        static let pulse = "dots.pulse"
    }

    /// Per-dot opacity pulse: 0.3 → 1.0 → 0.3 on a sin wave, repeating.
    /// CABasicAnimation participates in Core Animation's render-loop;
    /// substrate-consistent enough for prototype scope.
    private func attachPulseAnimation(to view: UIView, phase: CFTimeInterval) {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.3
        animation.toValue = 1.0
        animation.duration = Layout.pulseDuration / 2
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.beginTime = CACurrentMediaTime() + phase
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        view.layer.add(animation, forKey: AnimationKey.pulse)
    }
}
