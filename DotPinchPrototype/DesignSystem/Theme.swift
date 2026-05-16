import UIKit

// Design tokens. Theme.Page.surface is the single source of truth for any
// "page material with edges" surface — the page-gradient middle stop, the
// destination card fill, and the composer fill all read from it. Divergence
// breaks the card-as-page-material identity.
enum Theme {

    // MARK: - Page chromatics

    enum Page {
        /// Cool grey — top of the page gradient.       #bab8bb
        static let top = UIColor(red: 186/255, green: 184/255, blue: 187/255, alpha: 1)

        /// Page-material surface (L=92%). Used by gradient middle, card, composer.   #ede9ee
        static let surface = UIColor(red: 237/255, green: 233/255, blue: 238/255, alpha: 1)

        /// Warm pink — bottom of the page gradient.    #caa4a9
        static let bottom = UIColor(red: 202/255, green: 164/255, blue: 169/255, alpha: 1)
    }

    /// Chat surface — a brighter version of the page gradient's middle band,
    /// stretched to cover the viewport with its own cool-top → warm-bottom tint.
    enum Chat {
        /// L=92% cool. Same as Theme.Page.surface.
        static let topTint = Theme.Page.surface

        /// L=95% warm-white.                            #f4eeee
        static let bottomTint = UIColor(red: 244/255, green: 238/255, blue: 238/255, alpha: 1)
    }

    // MARK: - Text colours

    enum Text {
        /// Bubble body — near-black.
        static let primary     = UIColor(white: 0.10, alpha: 1)
        /// Bubble sender name.
        static let secondary   = UIColor(white: 0.35, alpha: 1)
        /// Bubble timestamp, destination date.
        static let tertiary    = UIColor(white: 0.45, alpha: 1)
        /// Composer hint placeholder.
        static let placeholder = UIColor(white: 0.55, alpha: 1)
        /// Pinch affordance glyph.
        static let glyph       = UIColor(white: 0.59, alpha: 1)
        /// Menu affordance glyph (slightly darker).
        static let glyphSubtle = UIColor(white: 0.41, alpha: 1)
        /// Destination card serif body.
        static let serifBody   = UIColor(red: 60/255, green: 56/255, blue: 60/255, alpha: 1)
        /// Debug status overlay.
        static let debug       = UIColor(white: 0.20, alpha: 0.7)
    }

    // MARK: - Typography

    enum Typography {
        static let bubbleSender    = UIFont.systemFont(ofSize: 12, weight: .semibold)
        static let bubbleBody      = UIFont.systemFont(ofSize: 17, weight: .regular)
        static let bubbleTime      = UIFont.systemFont(ofSize: 12, weight: .regular)
        static let composerHint    = UIFont.systemFont(ofSize: 16, weight: .regular)
        static let destinationDate = UIFont.systemFont(ofSize: 13, weight: .regular)
        static let statusLabel     = UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)

        /// Serif body for the destination card; falls back to system if serif
        /// design isn't available on the running OS.
        static let destinationBody: UIFont = {
            let size: CGFloat = 22
            let base = UIFont.systemFont(ofSize: size, weight: .regular)
            return base.fontDescriptor.withDesign(.serif).map { UIFont(descriptor: $0, size: size) } ?? base
        }()

        /// Fixed line-height for the destination body (min == max).
        static let destinationBodyLineHeight: CGFloat = 28
    }

    // MARK: - Shape

    enum Radius {
        static let card: CGFloat     = 25
        static let composer: CGFloat = 20
    }

    // MARK: - Shadow (destination-only, binary flip at .finished)

    enum Shadow {
        static let cardFinalOffset  = CGSize(width: 0, height: 1)
        static let cardFinalRadius: CGFloat = 3
        static let cardFinalOpacity: Float  = 0.04
    }

    // MARK: - Symbol affordances

    enum Symbol {
        static let pinchAffordancePointSize: CGFloat = 18
        static let pinchAffordanceWeight             = UIImage.SymbolWeight.light
        static let menuPointSize: CGFloat            = 16
        static let menuWeight                        = UIImage.SymbolWeight.regular
    }
}
