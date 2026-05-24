import UIKit

@MainActor
final class RevealBlurOverlay: UIView {

    private let effectView: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = false
        addSubview(effectView)
        effectView.pinToSuperview(of: self)
        effectView.alpha = 0
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var alpha: CGFloat {
        get { effectView.alpha }
        set { effectView.alpha = newValue }
    }

    func attach(to parent: UIView) {
        if superview === parent { return }
        if superview != nil { removeFromSuperview() }
        parent.addSubview(self)
        pinToSuperview(of: parent)
    }

    func detach() { removeFromSuperview() }
}
