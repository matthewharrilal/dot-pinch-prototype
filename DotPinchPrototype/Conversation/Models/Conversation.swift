// Conversation — the unit of identity in the prototype.
// Reference type (@Observable class) so reactive bindings have stable identity
// and per-conversation reads can be tracked at property granularity.
// All fields are immutable after init.

import Foundation
import Observation

@MainActor
@Observable
final class Conversation: Identifiable, Equatable, Hashable {

    // MARK: - Identity

    let id: UUID

    // MARK: - Content

    let messages: [Message]

    // MARK: - Metadata

    let createdAt: Date

    let lastUpdatedAt: Date

    let curatedSummary: String

    let displayDate: String

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        messages: [Message] = [],
        curatedSummary: String,
        displayDate: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.messages = messages
        self.lastUpdatedAt = messages.last?.timestamp ?? createdAt
        self.curatedSummary = curatedSummary
        self.displayDate = displayDate
    }

    // MARK: - Conformances

    nonisolated static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.id == rhs.id
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
