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
}
