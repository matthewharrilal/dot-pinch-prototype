// Adapts ConversationStore → TimelineDataSource. Surfaces Conversation.id as
// the cell-pool identity key (§4.3.7.3) so pool round-trips reattach the same
// cell instance, preserving cell-internal state (§13.4).

import CoreGraphics
import Foundation

@MainActor
final class TimelineDataSourceAdapter: TimelineDataSource {

    private let store: ConversationStore
    private let naturalCellHeight: CGFloat

    init(store: ConversationStore, naturalCellHeight: CGFloat = 200) {
        self.store = store
        self.naturalCellHeight = naturalCellHeight
    }

    // MARK: - TimelineDataSource

    func numberOfCells(in canvas: TimelineCanvas) -> Int {
        store.conversations.count
    }

    func canvas(_ canvas: TimelineCanvas, configureCell cell: CellView, at index: Int) {
        guard index < store.conversations.count else { return }
        let conversation = store.conversations[index]
        cell.configure(with: conversation)
    }

    func canvas(_ canvas: TimelineCanvas, heightForCellAt index: Int) -> CGFloat {
        naturalCellHeight
    }

    func canvas(_ canvas: TimelineCanvas, conversationIDForCellAt index: Int) -> UUID? {
        guard index < store.conversations.count else { return nil }
        return store.conversations[index].id
    }
}
