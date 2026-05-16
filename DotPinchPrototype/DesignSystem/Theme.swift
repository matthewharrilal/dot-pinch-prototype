import UIKit

// Design tokens. Theme.Page.surface is the single source of truth for any
// "page material with edges" surface — the page-gradient middle stop, the
// destination card fill, and the composer fill all read from it. Divergence
// breaks the card-as-page-material identity.
enum Theme {
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
}
