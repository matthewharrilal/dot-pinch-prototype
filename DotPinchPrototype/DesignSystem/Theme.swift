import UIKit

// Design tokens — page chromatics, text colors, typography, shape, symbol
// affordances. Page.surface and Cell.fill are intentionally distinct surface
// tokens; see ConversationCell.apply(_:) for the lerp(Cell.fill → ...) seam.
enum Theme {

    // MARK: - Page chromatics

    enum Page {
        /// Cool grey — top of the page gradient. #bab8bb
        static let top = UIColor(red: 186/255, green: 184/255, blue: 187/255, alpha: 1)

        /// Page-material surface (L=92%). Gradient middle stop. #ede9ee
        static let surface = UIColor(red: 237/255, green: 233/255, blue: 238/255, alpha: 1)

        /// Saturated mauve-pink — bottom of the page gradient. #d8aab4
        static let bottom = UIColor(red: 216/255, green: 170/255, blue: 180/255, alpha: 1)
    }

    enum Cell {
        /// Rest-state cell fill (#f6efef) — brighter than the page's pink lower band
        /// to delineate cells from page at idle.
        static let fill = UIColor(red: 246/255, green: 239/255, blue: 239/255, alpha: 1)
    }

    // MARK: - Text colours

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
