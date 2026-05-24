import Foundation
import Observation

@MainActor
@Observable
final class ConversationStore {

    let conversations: [Conversation]

    private let conversationsByID: [UUID: Conversation]

    init(initialConversations: [Conversation] = []) {
        var byID: [UUID: Conversation] = [:]
        for conversation in initialConversations {
            Self.insert(conversation, into: &byID)
        }
        self.conversationsByID = byID
        self.conversations = initialConversations.sorted { $0.lastUpdatedAt > $1.lastUpdatedAt }
    }

    private static func insert(_ conversation: Conversation,
                               into byID: inout [UUID: Conversation]) {
        precondition(byID[conversation.id] == nil,
                     "ConversationStore.insert: duplicate id \(conversation.id) — dual-index invariant violation")
        byID[conversation.id] = conversation
    }
}
