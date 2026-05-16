//
//  MinimalPerspectiveTest.swift
//  DotPinchPrototype
//
//  Isolation test for CATransform3D m34 + z-translate. Determines whether
//  perspective recession works fundamentally in this Xcode/SDK/sim environment,
//  independent of the project's UIScrollView / UIStackView / autolayout hierarchy.
//
//  Activation: launched only when AppDelegate detects the
//  USE_MINIMAL_PERSPECTIVE_TEST launch argument or env var. Otherwise inert.
//
//  Variants are selected via launch arg `MIN_PERSP_VARIANT=<name>`:
//      baseline | A | B | C200 | C1000 | C2500 | D
//

import UIKit

final class MinimalPerspectiveTestVC: UIViewController {

    /// Variant identifier picked up from launch args; defaults to "baseline".
    var variant: String = "baseline"

    private let redView = UIView()
    private let statusLabel = UILabel()
    private let variantLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // ---- Parent perspective (most variants set this) ----
        if variant != "A" {  // Variant A: m34 lives on child only, NOT on parent
            var parentPersp = CATransform3DIdentity
            parentPersp.m34 = mForVariant()
            view.layer.sublayerTransform = parentPersp
        }

        // ---- Red view (centered, 200x200, frames only — no autolayout) ----
        let bounds = view.bounds
        let size: CGFloat = 200
        redView.frame = CGRect(
            x: (bounds.width  - size) / 2,
            y: (bounds.height - size) / 2 - 40,
            width:  size,
            height: size
        )
        redView.backgroundColor = .red
        view.addSubview(redView)

        // ---- Apply per-variant transform on child ----
        applyChildTransform()

        // ---- Status label ----
        statusLabel.frame = CGRect(
            x: 16,
            y: redView.frame.maxY + 24,
            width: bounds.width - 32,
            height: 80
        )
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 13, weight: .regular)
        statusLabel.textColor = .black
        statusLabel.text = expectationText()
        view.addSubview(statusLabel)

        // ---- Variant label (top) ----
        variantLabel.frame = CGRect(x: 16, y: 60, width: bounds.width - 32, height: 24)
        variantLabel.textAlignment = .center
        variantLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        variantLabel.textColor = .darkGray
        variantLabel.text = "VARIANT: \(variant)"
        view.addSubview(variantLabel)
    }

    /// m34 magnitude — varies for the C-series variants.
    private func mForVariant() -> CGFloat {
        switch variant {
        case "C200":  return -1.0 / 200.0
        case "C1000": return -1.0 / 1000.0
        case "C2500": return -1.0 / 2500.0
        default:      return -1.0 / 500.0
        }
    }

    private func applyChildTransform() {
        switch variant {
        case "A":
            // Variant A: m34 lives on the child's OWN transform, not parent.
            var t = CATransform3DIdentity
            t.m34 = -1.0 / 500.0
            t = CATransform3DTranslate(t, 0, 0, -300)
            redView.layer.transform = t

        case "B":
            // Variant B: rotate 45° around X — pure rotation, no translate.
            // Parent provides perspective via sublayerTransform.
            redView.layer.transform = CATransform3DMakeRotation(.pi / 4, 1, 0, 0)

        case "D":
            // Variant D: explicit shouldRasterize=false + anchorPointZ=0.
            redView.layer.shouldRasterize = false
            redView.layer.anchorPointZ = 0
            redView.layer.transform = CATransform3DMakeTranslation(0, 0, -300)

        default:
            // baseline / C-series: parent has m34, child translates -300 in Z.
            redView.layer.transform = CATransform3DMakeTranslation(0, 0, -300)
        }
    }

    private func expectationText() -> String {
        switch variant {
        case "baseline":
            return "Expected: red square at ~62% scale\n(m34=-1/500 on parent, child Z=-300)"
        case "A":
            return "Variant A: m34 on child only, child Z=-300\nExpected: ~62% if self-perspective works"
        case "B":
            return "Variant B: child rotated 45°X (no Z), parent m34=-1/500\nExpected: trapezoid foreshortened"
        case "C200":
            return "Variant C: m34=-1/200, Z=-300\nExpected: stronger recession, ~40% scale"
        case "C1000":
            return "Variant C: m34=-1/1000, Z=-300\nExpected: subtle recession, ~77% scale"
        case "C2500":
            return "Variant C: m34=-1/2500, Z=-300\nExpected: barely visible recession, ~89% scale"
        case "D":
            return "Variant D: shouldRasterize=false, anchorPointZ=0\nExpected: ~62% scale"
        default:
            return "Unknown variant: \(variant)"
        }
    }
}
