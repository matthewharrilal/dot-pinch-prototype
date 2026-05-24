// ConversationStore — single source of truth for all Conversation instances.
// Owns the canonical recency-ordered collection and an O(1) ID-addressed
// index. MainActor-isolated; @Observable so consumers can bind to the
// `conversations` array directly.

import Foundation
import Observation

@MainActor
@Observable
final class ConversationStore {

    // MARK: - Storage

    let conversations: [Conversation]

    private let conversationsByID: [UUID: Conversation]

    // MARK: - Initialization

    init(initialConversations: [Conversation] = []) {
        var byID: [UUID: Conversation] = [:]
        for conversation in initialConversations {
            precondition(byID[conversation.id] == nil,
                         "ConversationStore: duplicate id \(conversation.id)")
            byID[conversation.id] = conversation
        }
        self.conversationsByID = byID
        self.conversations = initialConversations.sorted { $0.lastUpdatedAt > $1.lastUpdatedAt }
    }
}
