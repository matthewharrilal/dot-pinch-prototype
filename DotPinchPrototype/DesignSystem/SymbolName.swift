// SF Symbol name registry. UIImage(systemName:) calls funnel through these
// constants so symbol-name typos surface at one place.

enum SymbolName {
    /// Pinch-EXPAND affordance glyph — outward-diverging arrows.
    static let pinchExpandAffordance = "arrow.up.left.and.arrow.down.right"

    /// Pinch-COLLAPSE affordance glyph — inward-converging arrows.
    /// Used at chat-rest to signal "this state is pinch-collapsible" per §21.
    /// The exact inverse-pair of the expand affordance for visual rhyme.
    static let pinchCollapseAffordance = "arrow.down.right.and.arrow.up.left"
}
