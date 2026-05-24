import UIKit

extension UIView {
    @discardableResult
    func pinToSuperview(of parent: UIView) -> [NSLayoutConstraint] {
        let constraints = [
            topAnchor.constraint(equalTo: parent.topAnchor),
            leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            bottomAnchor.constraint(equalTo: parent.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
        return constraints
    }
}
