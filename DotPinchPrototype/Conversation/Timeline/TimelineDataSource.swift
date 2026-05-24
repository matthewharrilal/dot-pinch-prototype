import CoreGraphics
import Foundation

@MainActor
protocol TimelineDataSource: AnyObject {
    func numberOfCells(in canvas: TimelineCanvas) -> Int

    func canvas(_ canvas: TimelineCanvas, configureCell cell: CellView, at index: Int)

    func canvas(_ canvas: TimelineCanvas, heightForCellAt index: Int) -> CGFloat

    func canvas(_ canvas: TimelineCanvas, conversationIDForCellAt index: Int) -> UUID?
}

extension TimelineDataSource {
    func canvas(_ canvas: TimelineCanvas, conversationIDForCellAt index: Int) -> UUID? {
        return nil
    }
}

@MainActor
final class TimelineDataSourceAdapter: TimelineDataSource {

    private let store: ConversationStore
    private let naturalCellHeight: CGFloat

    init(store: ConversationStore, naturalCellHeight: CGFloat) {
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
