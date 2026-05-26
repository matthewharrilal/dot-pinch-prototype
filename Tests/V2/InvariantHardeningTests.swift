import XCTest
@testable import DotPinchPrototype

@MainActor
final class InvariantHardeningTests: XCTestCase {

    func test_conversationStore_acceptsUniqueIDs() {
        let a = Conversation(curatedSummary: "alpha", displayDate: "Today")
        let b = Conversation(curatedSummary: "beta", displayDate: "Today")
        let store = ConversationStore(initialConversations: [a, b])
        XCTAssertEqual(store.conversations.count, 2)
        XCTAssertEqual(Set(store.conversations.map(\.id)), Set([a.id, b.id]))
    }

    func test_conversationStore_emptyInitIsEmpty() {
        let store = ConversationStore(initialConversations: [])
        XCTAssertTrue(store.conversations.isEmpty)
    }

    func test_conversationStore_recencyOrdered() {
        let old = Conversation(createdAt: Date(timeIntervalSince1970: 100),
                               curatedSummary: "old",
                               displayDate: "Mon")
        let new = Conversation(createdAt: Date(timeIntervalSince1970: 200),
                               curatedSummary: "new",
                               displayDate: "Tue")
        let store = ConversationStore(initialConversations: [old, new])
        XCTAssertEqual(store.conversations.first?.id, new.id)
        XCTAssertEqual(store.conversations.last?.id, old.id)
    }

    func test_sRGBLockedCGColor_isSRGB() {
        let red = UIColor.red.sRGBLockedCGColor
        XCTAssertEqual(red.colorSpace?.name, CGColorSpace.sRGB)
        let p3 = UIColor(displayP3Red: 1.0, green: 0, blue: 0, alpha: 1).sRGBLockedCGColor
        XCTAssertEqual(p3.colorSpace?.name, CGColorSpace.sRGB)
    }

    /// K2 keystone canary: `canvas.layer.sublayerTransform.m34 = -1/1000`
    /// set once at init, never mutated. Verifies the focal length survives
    /// multiple setCamera calls — distinct from `contentHost.layer.sublayerTransform`
    /// which is the camera-write target.
    func test_m34_invariant_acrossCameraOps() {
        let controller = AnimationController()
        let canvas = TimelineCanvas(
            controller: controller,
            frame: CGRect(x: 0, y: 0, width: 390, height: 844)
        )
        let expectedM34: CGFloat = -1.0 / 1000.0
        let baseline = canvas.layer.sublayerTransform.m34
        XCTAssertEqual(baseline, expectedM34, accuracy: 1e-9, "K2: m34 must be -1/1000 at init")

        canvas.setCamera(Camera(translation: 100))
        XCTAssertEqual(canvas.layer.sublayerTransform.m34, expectedM34, accuracy: 1e-9, "K2: m34 must survive first setCamera write")

        canvas.setCamera(Camera(translation: -50))
        XCTAssertEqual(canvas.layer.sublayerTransform.m34, expectedM34, accuracy: 1e-9, "K2: m34 must survive subsequent setCamera writes")

        canvas.setCamera(Camera(translation: 0))
        XCTAssertEqual(canvas.layer.sublayerTransform.m34, expectedM34, accuracy: 1e-9, "K2: m34 must survive identity-camera write")
    }
}
