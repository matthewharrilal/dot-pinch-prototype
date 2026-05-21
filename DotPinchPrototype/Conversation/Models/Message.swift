// Message — a single utterance within a Conversation.
// Value type, behavior-free. Role is `.user` / `.assistant` matching the
// OpenAI / Anthropic chat-completions vocabulary.

import Foundation

struct Message: Identifiable, Equatable, Hashable, Sendable {

    // MARK: - Role

    enum Role: String, Sendable {
        case user
        case assistant
    }

    // MARK: - Identity

    let id: UUID

    // MARK: - Content

    let role: Role

    let content: String

    // MARK: - Metadata

    let timestamp: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        role: Role,
        content: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}
