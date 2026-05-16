// SF Symbol name registry. View code calls UIImage(systemName:) through these
// constants so symbol-name typos surface at one place and renames stay atomic.

enum SymbolName {
    /// Pinch affordance glyph (top-leading) — "two arrows converging".
    static let pinchAffordance = "arrow.down.right.and.arrow.up.left"

    /// Overflow menu glyph (top-trailing).
    static let menu = "ellipsis"
}
