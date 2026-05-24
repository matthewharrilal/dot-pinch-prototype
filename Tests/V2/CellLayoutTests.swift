// CellLayoutTests.swift
//
// Unit tests for TimelineCanvas's cell layout calculator: pageHeight,
// pageFrameForCell, cellIndices, and memoization invalidation on reloadData.

import XCTest
@testable import DotPinchPrototype

@MainActor
final class CellLayoutTests: XCTestCase {

    // MARK: - Fixtures

    /// Uniform data source: N cells of `height`.
    final class UniformDS: TimelineDataSource {
        let count: Int
        let height: CGFloat
        init(count: Int, height: CGFloat) {
            self.count = count
            self.height = height
        }
        func numberOfCells(in canvas: TimelineCanvas) -> Int { count }
        func canvas(_ canvas: TimelineCanvas, configureCell cell: CellView, at index: Int) {}
        func canvas(_ canvas: TimelineCanvas, heightForCellAt index: Int) -> CGFloat { height }
    }

    /// Variable-height data source: per-index heights from an array.
    final class VariableDS: TimelineDataSource {
        let heights: [CGFloat]
        init(_ heights: [CGFloat]) { self.heights = heights }
        func numberOfCells(in canvas: TimelineCanvas) -> Int { heights.count }
        func canvas(_ canvas: TimelineCanvas, configureCell cell: CellView, at index: Int) {}
        func canvas(_ canvas: TimelineCanvas, heightForCellAt index: Int) -> CGFloat {
            heights[index]
        }
    }

    // Strong references so weakly-held dataSources survive the test method.
    private var _retainedDataSources: [AnyObject] = []

    override func tearDown() {
        _retainedDataSources.removeAll()
        super.tearDown()
    }

    /// Make a canvas with a uniform data source and call reloadData.
    private func makeCanvas(count: Int, height: CGFloat = 200) -> (TimelineCanvas, UniformDS) {
        let canvas = TimelineCanvas(controller: AnimationController(), frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let ds = UniformDS(count: count, height: height)
        canvas.dataSource = ds
        canvas.reloadData()
        _retainedDataSources.append(ds)
        return (canvas, ds)
    }

    // MARK: - pageHeight

    /// 5 cells × 200pt + 4 gaps × 24pt = 1000 + 96 = 1096pt.
    func testPageHeightWithFiveCells() {
        let (canvas, ds) = makeCanvas(count: 5, height: 200)
        XCTAssertEqual(canvas.pageHeight(), 1096)
        _ = ds  // keep ds alive: dataSource is weak
    }

    func testPageHeightWithOneCell() {
        let (canvas, ds) = makeCanvas(count: 1, height: 200)
        XCTAssertEqual(canvas.pageHeight(), 200, "single cell: no spacing")
        _ = ds
    }

    func testPageHeightWithZeroCells() {
        let (canvas, ds) = makeCanvas(count: 0, height: 200)
        XCTAssertEqual(canvas.pageHeight(), 0)
        _ = ds
    }

    func testPageHeightNoTrailingSpacing() {
        // 3 × 200 + 2 × 24 = 648. NOT 3 × (200+24) = 672.
        let (canvas, ds) = makeCanvas(count: 3, height: 200)
        XCTAssertEqual(canvas.pageHeight(), 648)
        _ = ds
    }

    // MARK: - pageFrameForCell

    /// At index 2 with 200pt cells + 24pt spacing: y = 2 × (200 + 24) = 448.
    func testPageFrameForCellAtIndex2() {
        let (canvas, ds) = makeCanvas(count: 5, height: 200)
        let frame = canvas.pageFrameForCell(at: 2)
        XCTAssertEqual(frame.origin.x, 0)
        XCTAssertEqual(frame.origin.y, 448)
        XCTAssertEqual(frame.size.width, canvas.pageWidth)
        XCTAssertEqual(frame.size.height, 200)
        _ = ds
    }

    func testPageFrameForCellAtIndex0() {
        let (canvas, ds) = makeCanvas(count: 5, height: 200)
        let frame = canvas.pageFrameForCell(at: 0)
        XCTAssertEqual(frame.origin, .zero)
        _ = ds
    }

    /// Variable heights: [200, 300, 200] → tops at 0, 224, 548.
    func testPageFrameVariableHeights() {
        let canvas = TimelineCanvas(controller: AnimationController(), frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let ds = VariableDS([200, 300, 200])
        canvas.dataSource = ds
        canvas.reloadData()
        _retainedDataSources.append(ds)
        XCTAssertEqual(canvas.pageFrameForCell(at: 0).origin.y, 0)
        XCTAssertEqual(canvas.pageFrameForCell(at: 1).origin.y, 224, "200 + 24")
        XCTAssertEqual(canvas.pageFrameForCell(at: 2).origin.y, 548, "200 + 24 + 300 + 24")
    }

    // MARK: - cellIndices

    /// cellIndices(in: CGRect(0, 200, pw, 400), plusMargin: 0) = 1..<3
    /// Cells at: 0..200 (idx 0), 224..424 (idx 1), 448..648 (idx 2), 672..872 (idx 3), 896..1096 (idx 4).
    /// Query rect 200..600 intersects 224..424 (1), 448..648 (2). Result: 1..<3.
    func testCellIndicesInVisibleRect() {
        let (canvas, ds) = makeCanvas(count: 5, height: 200)
        let rect = CGRect(x: 0, y: 200, width: canvas.pageWidth, height: 400)
        let range = canvas.cellIndices(in: rect, plusMargin: 0)
        XCTAssertEqual(range, 1..<3)
        _ = ds
    }

    func testCellIndicesContiguous() {
        let (canvas, ds) = makeCanvas(count: 5, height: 200)
        let rect = CGRect(x: 0, y: 100, width: canvas.pageWidth, height: 700)
        let range = canvas.cellIndices(in: rect, plusMargin: 0)
        XCTAssertEqual(range.upperBound - range.lowerBound, range.count)
        _ = ds
    }

    func testCellIndicesWithMargin2() {
        // Same rect → 1..<3 unwidened. With margin 2: widen by 2 each side,
        // clamp to [0, 5). → 0..<5 (would be -1..<5 unclamped).
        let (canvas, ds) = makeCanvas(count: 5, height: 200)
        let rect = CGRect(x: 0, y: 200, width: canvas.pageWidth, height: 400)
        let range = canvas.cellIndices(in: rect, plusMargin: 2)
        XCTAssertEqual(range, 0..<5)
        _ = ds
    }

    func testCellIndicesEmptyRect() {
        let (canvas, ds) = makeCanvas(count: 5, height: 200)
        let range = canvas.cellIndices(in: .zero, plusMargin: 0)
        XCTAssertTrue(range.isEmpty)
        _ = ds
    }

    func testCellIndicesRectAbovePage() {
        let (canvas, ds) = makeCanvas(count: 5, height: 200)
        let rect = CGRect(x: 0, y: -1000, width: canvas.pageWidth, height: 500)
        let range = canvas.cellIndices(in: rect, plusMargin: 0)
        XCTAssertTrue(range.isEmpty, "rect entirely above page → empty")
        _ = ds
    }

    func testCellIndicesRectBelowPage() {
        let (canvas, ds) = makeCanvas(count: 5, height: 200)
        let rect = CGRect(x: 0, y: 5000, width: canvas.pageWidth, height: 500)
        let range = canvas.cellIndices(in: rect, plusMargin: 0)
        XCTAssertTrue(range.isEmpty, "rect entirely below page → empty")
        _ = ds
    }

    func testCellIndicesRectSpansEntirePage() {
        let (canvas, ds) = makeCanvas(count: 5, height: 200)
        let rect = CGRect(x: 0, y: 0, width: canvas.pageWidth, height: 2000)
        let range = canvas.cellIndices(in: rect, plusMargin: 0)
        XCTAssertEqual(range, 0..<5)
        _ = ds
    }

    func testCellIndicesPartialOverlapIncluded() {
        // Rect grazes cell 1 by 1pt: includes it.
        let (canvas, ds) = makeCanvas(count: 5, height: 200)
        // Cell 1 spans y in [224, 424]. Rect grazes at y=423..500 → includes 1.
        let rect = CGRect(x: 0, y: 423, width: canvas.pageWidth, height: 77)
        let range = canvas.cellIndices(in: rect, plusMargin: 0)
        XCTAssertTrue(range.contains(1), "1pt overlap should include cell")
        _ = ds
    }

    // MARK: - Memoization invalidation

    func testMemoizationInvalidatesOnReloadData() {
        let canvas = TimelineCanvas(controller: AnimationController(), frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let ds1 = UniformDS(count: 5, height: 200)
        canvas.dataSource = ds1
        canvas.reloadData()
        _retainedDataSources.append(ds1)
        XCTAssertEqual(canvas.pageHeight(), 1096)

        // Swap to a 3-cell × 300pt DS: pageHeight = 3 × 300 + 2 × 24 = 948.
        let ds2 = UniformDS(count: 3, height: 300)
        canvas.dataSource = ds2
        canvas.reloadData()
        _retainedDataSources.append(ds2)
        XCTAssertEqual(canvas.pageHeight(), 948, "cache must invalidate on reloadData")
        XCTAssertEqual(canvas.pageFrameForCell(at: 1).origin.y, 324, "300 + 24")
    }
}
