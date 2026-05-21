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

    private(set) var conversations: [Conversation] = []

    private var conversationsByID: [UUID: Conversation] = [:]

    // MARK: - Initialization

    init(initialConversations: [Conversation] = []) {
        for conversation in initialConversations {
            insert(conversation)
        }
        sortByRecency()
    }

    // MARK: - Internal Helpers

    private func insert(_ conversation: Conversation) {
        conversationsByID[conversation.id] = conversation
        conversations.append(conversation)
    }

    private func sortByRecency() {
        conversations.sort { $0.lastUpdatedAt > $1.lastUpdatedAt }
    }
}
