// ConversationActivityTracker — per-conversation isActive state (P2 / §22).
// Separate from ConversationStore (immutable) per §22.3 option A-2:
// Tracker keeps the Store invariant intact. UUID-keyed; subscribers query
// via isActive(_:) and mutators write via setActive(_:_:).
//
// @Observable so SwiftUI observers can subscribe; UIKit cells subscribe via
// notification or polling on setCamera ticks.

import Foundation
import Observation

@MainActor
@Observable
final class ConversationActivityTracker {

    private var activeIDs: Set<UUID> = []

    /// Notification posted when an ID's activity state changes.
    /// UserInfo: ["id": UUID, "active": Bool]
    static let activityDidChangeNotification = Notification.Name("ConversationActivityTracker.activityDidChange")

    init() {}

    func isActive(_ id: UUID) -> Bool {
        activeIDs.contains(id)
    }

    func setActive(_ id: UUID, _ active: Bool) {
        let wasActive = activeIDs.contains(id)
        guard wasActive != active else { return }

        if active {
            activeIDs.insert(id)
        } else {
            activeIDs.remove(id)
        }

        NotificationCenter.default.post(
            name: Self.activityDidChangeNotification,
            object: self,
            userInfo: ["id": id, "active": active]
        )
    }
}
