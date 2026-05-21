// PageGradientFixTests.swift
//
// Tests TimelineCanvas.installPageGradient: three-stop gradient with
// Theme.Page.surface middle stop at 0.5, sRGB-locked to prevent
// iOS 26.4 Display-P3 desaturation.

import XCTest
@testable import DotPinchPrototype

@MainActor
final class PageGradientFixTests: XCTestCase {

    private var _retainedWindows: [UIWindow] = []
    private var _retainedDataSources: [AnyObject] = []

    override func tearDown() {
        _retainedWindows.removeAll()
        _retainedDataSources.removeAll()
        super.tearDown()
    }

    private final class FiveCellsDS: TimelineDataSource {
        func numberOfCells(in canvas: TimelineCanvas) -> Int { 5 }
        func canvas(_ canvas: TimelineCanvas, configureCell cell: CellView, at index: Int) {}
        func canvas(_ canvas: TimelineCanvas, heightForCellAt index: Int) -> CGFloat { 200 }
    }

    private func makeCanvas() -> TimelineCanvas {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let canvas = TimelineCanvas(frame: window.bounds)
        let ds = FiveCellsDS()
        canvas.dataSource = ds
        window.addSubview(canvas)
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        _retainedDataSources.append(ds)
        _retainedWindows.append(window)
        return canvas
    }

    // MARK: - Three-stop gradient

    func testPageGradientHasThreeStops() {
        let canvas = makeCanvas()
        let count = canvas.pageGradientLayer.colors?.count ?? 0
        XCTAssertEqual(count, 3,
            "page gradient must have THREE stops (top, surface, bottom)")
    }

    /// Locations must be explicitly `[0, 0.5, 1]` — omitting `locations`
    /// works by default but the explicit assignment is load-bearing.
    func testPageGradientLocationsAreExplicit() {
        let canvas = makeCanvas()
        let locations = canvas.pageGradientLayer.locations
        XCTAssertNotNil(locations,
            "page gradient locations must be explicitly assigned, not nil-default")
        XCTAssertEqual(locations?.count, 3,
            "page gradient must declare 3 locations matching the 3 stops")
        if let locations, locations.count == 3 {
            XCTAssertEqual(locations[0].doubleValue, 0.0, accuracy: 1e-9)
            XCTAssertEqual(locations[1].doubleValue, 0.5, accuracy: 1e-9,
                "middle stop must be at location 0.5")
            XCTAssertEqual(locations[2].doubleValue, 1.0, accuracy: 1e-9)
        }
    }

    /// Middle stop must come from `Theme.Page.surface`. Compares within
    /// tolerance to allow for sRGB-conversion numeric drift.
    func testPageGradientMiddleStopIsThemeSurface() {
        let canvas = makeCanvas()
        guard let colors = canvas.pageGradientLayer.colors as? [CGColor], colors.count == 3 else {
            XCTFail("gradient colors not as expected: \(canvas.pageGradientLayer.colors ?? [])")
            return
        }
        let middle = colors[1]
        let surfaceCG = Theme.Page.surface.cgColor
        // Compare RGBA components within 2/255 tolerance (covers sRGB
        // conversion rounding).
        let mComps = middle.components ?? []
        let sComps = surfaceCG.components ?? []
        XCTAssertEqual(mComps.count, sComps.count,
            "middle and surface component counts must match")
        guard mComps.count == sComps.count else { return }
        for i in 0..<mComps.count {
            XCTAssertEqual(mComps[i], sComps[i], accuracy: 2.0 / 255.0,
                "middle stop component[\(i)] must match Theme.Page.surface")
        }
    }

    // MARK: - sRGB colorspace lock

    func testPageGradientStopsAreSRGBLocked() {
        let canvas = makeCanvas()
        guard let colors = canvas.pageGradientLayer.colors as? [CGColor], colors.count == 3 else {
            XCTFail("gradient colors not as expected")
            return
        }
        for (i, color) in colors.enumerated() {
            let colorSpaceName = color.colorSpace?.name
            XCTAssertEqual(colorSpaceName, CGColorSpace.sRGB,
                "gradient stop[\(i)] must be sRGB-locked — got \(String(describing: colorSpaceName))")
        }
    }

    func testPageGradientStillFillsViewportAfterFix() {
        let canvas = makeCanvas()
        XCTAssertEqual(canvas.pageGradientLayer.frame, canvas.bounds,
            "pageGradientLayer.frame must equal canvas.bounds after layoutSubviews (regression guard)")
    }

    /// pageGradient remains a direct sublayer of TimelineCanvas.layer
    /// (not contentHost) — regression guard on layer hierarchy.
    func testPageGradientLayerHierarchyUnchanged() {
        let canvas = makeCanvas()
        XCTAssertTrue(canvas.pageGradientLayer.superlayer === canvas.layer,
            "pageGradient must remain direct sublayer of TimelineCanvas.layer (regression guard)")
    }
}
