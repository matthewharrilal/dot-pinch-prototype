// Data-source contract for TimelineCanvas. Cell count, per-cell content
// binding, per-cell page-coord height, and optional conversation identity for
// the pool's identity-keyed dequeue (§4.3.7.3).

import CoreGraphics
import Foundation

/// Class-bound — TimelineCanvas holds the dataSource weakly to avoid the
/// VC → canvas → dataSource → VC retain cycle.
protocol TimelineDataSource: AnyObject {
    func numberOfCells(in canvas: TimelineCanvas) -> Int

    func canvas(_ canvas: TimelineCanvas, configureCell cell: CellView, at index: Int)

    func canvas(_ canvas: TimelineCanvas, heightForCellAt index: Int) -> CGFloat

    /// Identity of the conversation at `index`, used by the §4.3.7.3 pool
    /// dequeue: returning a UUID lets the pool prefer the cell instance
    /// previously bound to this conversation, preserving cell-internal state
    /// (scroll offset, draft text, cursor) across pool round-trips (§13.4).
    /// Default `nil` falls back to generic LIFO dequeue.
    func canvas(_ canvas: TimelineCanvas, conversationIDForCellAt index: Int) -> UUID?
}

extension TimelineDataSource {
    func canvas(_ canvas: TimelineCanvas, conversationIDForCellAt index: Int) -> UUID? {
        return nil
    }
}
