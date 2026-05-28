// Design tokens — page chromatics, text colors, typography, shape, symbol affordances.

import UIKit

enum Theme {

    // MARK: - Page chromatics

    enum Page {
        /// Cool grey — top of the page gradient. #bab8bb
        static let top = UIColor(red: 186/255, green: 184/255, blue: 187/255, alpha: 1)

        /// Page-material surface (L=92%). Gradient middle stop. #ede9ee
        static let surface = UIColor(red: 237/255, green: 233/255, blue: 238/255, alpha: 1)

        /// Warm pink — bottom of the page gradient. #cc9194 (RGB 204,145,148).
        /// Sampled from cell-rest reference frames (frame_0055..0060) at the very-
        /// bottom field region; median of multiple frames. HSV H=357° S=29% V=80%.
        /// (Spec said S~71 but measured value is S~29 — sampled values are the
        /// rigorous ground truth; updating to match reference, not the spec value.)
        /// Item E1.
        static let bottom = UIColor(red: 204/255, green: 145/255, blue: 148/255, alpha: 1)

        /// Mid-grey intermediate gradient stop. Item E1' (gradient distribution).
        /// Used at gradient location 0.50 (just above the cell-rest cell.top at
        /// 50.6% of viewport) so the area above the contracted card carries
        /// visible grey character (V≈85, delta from cell-surface V=93 by 8 →
        /// perceptible top-edge contrast).
        /// (Sampled approximately at V=85 between top.V=73 and surface.V=93.)
        static let gradientGreyMid = UIColor(red: 217/255, green: 213/255, blue: 218/255, alpha: 1)

        /// Light-pink intermediate gradient stop. Item E1' (gradient distribution).
        /// Used at gradient location 0.85; sampled from reference frame_0060 at
        /// the corresponding y position where saturation reaches S≈16%.
        /// Enables non-linear pink saturation climb (S 11→16→24→29) across the
        /// pink band, matching the reference's measured vertical pink profile.
        static let gradientPinkLight = UIColor(red: 197/255, green: 166/255, blue: 168/255, alpha: 1)
    }

    enum Cell {
        /// Rest-state cell fill (#f6efef) — brighter than the page's pink lower band
        /// to delineate cells from page at idle.
        static let fill = UIColor(red: 246/255, green: 239/255, blue: 239/255, alpha: 1)

        /// Drop shadow — §50.4 NEW-2: appears in Stage 4 to assert "object-ness."
        /// Per prose "drop shadow asserts type, not depth" — binary near cell-rest,
        /// not a graduated depth fade.
        static let shadowColor: CGColor = UIColor.black.cgColor
        static let shadowOpacityCellRest: CGFloat = 0.06
        static let shadowOffset = CGSize(width: 0, height: 4)
        static let shadowRadius: CGFloat = 8
    }

    // MARK: - Text colors

    enum Text {
        static let primary   = UIColor(white: 0.10, alpha: 1)
        static let secondary = UIColor(white: 0.35, alpha: 1)
        static let tertiary  = UIColor(white: 0.45, alpha: 1)
        static let glyph     = UIColor(white: 0.59, alpha: 1)
        static let serifBody = UIColor(red: 60/255, green: 56/255, blue: 60/255, alpha: 1)
    }

    // MARK: - Typography

    enum Typography {
        static let bubbleRole      = UIFont.systemFont(ofSize: 12, weight: .semibold)
        static let bubbleBody      = UIFont.systemFont(ofSize: 17, weight: .regular)
        static let bubbleTime      = UIFont.systemFont(ofSize: 12, weight: .regular)
        static let composerHint    = UIFont.systemFont(ofSize: 16, weight: .regular)
        static let destinationDate = UIFont.systemFont(ofSize: 13, weight: .regular)

        /// Serif body for the destination card; falls back to system if serif
        /// design isn't available on the running OS.
        static let destinationBody: UIFont = {
            let size: CGFloat = 22
            let base = UIFont.systemFont(ofSize: size, weight: .regular)
            return base.fontDescriptor.withDesign(.serif).map { UIFont(descriptor: $0, size: size) } ?? base
        }()
    }

    // MARK: - Shape

    enum Radius {
        static let card: CGFloat = 25
    }

    // MARK: - Symbol affordances

    enum Symbol {
        static let pinchAffordancePointSize: CGFloat = 18
        static let pinchAffordanceWeight             = UIImage.SymbolWeight.light
    }
}
