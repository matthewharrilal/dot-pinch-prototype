import UIKit

// Page color tokens. The three-band gradient and the card surface share the
// same middle-band value — the card IS the page material with edges, not a
// separate object on top. `Theme.Page.surface` is the single source of truth
// for any "page material with edges" surface (card, composer, gradient middle).
// Divergence between these uses breaks the "card is page" identity and
// violates Refusal #2 (photometric continuity).
enum Theme {
    enum Page {
        /// Cool grey — upper chromatic frame of the page gradient.
        static let top = UIColor(red: 186/255, green: 184/255, blue: 187/255, alpha: 1)      // #bab8bb

        /// Near-white L=92%. Used by: page gradient middle, destination card, composer.
        /// The structural invariant: card-as-page-material reads from this token.
        static let surface = UIColor(red: 237/255, green: 233/255, blue: 238/255, alpha: 1)  // #ede9ee

        /// Warm pink — lower chromatic frame of the page gradient.
        static let bottom = UIColor(red: 202/255, green: 164/255, blue: 169/255, alpha: 1)   // #caa4a9
    }

    /// Chat surface tokens. The chat surface is the page's middle band stretched
    /// to cover the whole viewport — brighter than the page gradient at the same
    /// Y, with its own subtle internal gradient cool-top → warm-bottom.
    enum Chat {
        /// L=92% cool. SAME as Theme.Page.surface — chat top tint matches cards.
        static let topTint = Theme.Page.surface

        /// L=95% warm-white. Slight warm pink emerging at the bottom of the chat surface.
        static let bottomTint = UIColor(red: 244/255, green: 238/255, blue: 238/255, alpha: 1)  // #f4eeee
    }
}
