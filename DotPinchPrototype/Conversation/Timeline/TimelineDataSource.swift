import CoreGraphics
import Foundation

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
