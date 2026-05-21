// DummyConversationLoader — preloads sample Conversation fixtures for the
// prototype. Returns conversations in author order (today → older); the store
// re-sorts by recency via `lastUpdatedAt`.

import Foundation

@MainActor
enum DummyConversationLoader {

    // MARK: - Static API

    static func load() -> [Conversation] {
        return [
            makeTodayConversation(),
            makeYesterdayConversation(),
            makePastWeekConversation(),
            makeOlderConversation()
        ]
    }

    // MARK: - Dummy Content — Today

    private static func makeTodayConversation() -> Conversation {
        let now = Date()
        let base = Calendar.current.startOfDay(for: now)

        let messages: [Message] = [
            Message(
                role: .assistant,
                content: "Hey, hope you slept okay. I'll send a gentle nudge in a bit about today's movement check-in.",
                timestamp: minutesAfter(base, hours: 3, minutes: 0)
            ),
            Message(
                role: .user,
                content: "Awake. Couldn't sleep again. Mind a little loud tonight.",
                timestamp: minutesAfter(base, hours: 3, minutes: 2)
            ),
            Message(
                role: .assistant,
                content: "That sounds rough. Want to try a slow breath together, or just sit with the quiet for a minute first?",
                timestamp: minutesAfter(base, hours: 3, minutes: 5)
            ),
            Message(
                role: .user,
                content: "Just sit. I'm okay. Maybe I'll try a walk when it gets light.",
                timestamp: minutesAfter(base, hours: 3, minutes: 8)
            ),
            Message(
                role: .assistant,
                content: "A short walk at dawn sounds restorative. I'll check in with the daily-movement nudge in a few minutes — feel free to ignore it if the walk feels like enough.",
                timestamp: minutesAfter(base, hours: 3, minutes: 10)
            ),
            Message(
                role: .assistant,
                content: "Good morning! Just a quick check-in about your daily exercise goal. I know it's early, but a 20-minute workout can really kickstart your Monday. Whether it's a brisk walk, some stretching, or a quick home workout, it's a great way to energize yourself for the week ahead.",
                timestamp: minutesAfter(base, hours: 3, minutes: 12)
            )
        ]

        return Conversation(
            createdAt: messages.first?.timestamp ?? now,
            messages: messages,
            curatedSummary: "Good morning check-in, daily exercise nudge, 20-minute workout suggestions",
            displayDate: "Mon, Jul 1"
        )
    }

    // MARK: - Dummy Content — Yesterday

    private static func makeYesterdayConversation() -> Conversation {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else {
            return Conversation(
                messages: [],
                curatedSummary: "Evening reflection on a long workday",
                displayDate: "Yesterday"
            )
        }
        let base = Calendar.current.startOfDay(for: yesterday)

        let messages: [Message] = [
            Message(
                role: .user,
                content: "Long day. Back-to-back meetings and I still haven't eaten.",
                timestamp: minutesAfter(base, hours: 19, minutes: 0)
            ),
            Message(
                role: .assistant,
                content: "That's a lot to carry. Want to step away from the screen for ten minutes and grab something simple first, then we can debrief the day after?",
                timestamp: minutesAfter(base, hours: 19, minutes: 2)
            ),
            Message(
                role: .user,
                content: "Yeah, leftover pasta in the fridge. Back in a bit.",
                timestamp: minutesAfter(base, hours: 19, minutes: 4)
            ),
            Message(
                role: .assistant,
                content: "Take your time. I'll be here when you're ready to unwind.",
                timestamp: minutesAfter(base, hours: 19, minutes: 5)
            )
        ]

        return Conversation(
            createdAt: messages.first?.timestamp ?? yesterday,
            messages: messages,
            curatedSummary: "Evening reflection on a long workday — meals, meetings, and decompression",
            displayDate: "Yesterday"
        )
    }

    // MARK: - Dummy Content — Past-Week

    private static func makePastWeekConversation() -> Conversation {
        guard let pastWeek = Calendar.current.date(byAdding: .day, value: -5, to: Date()) else {
            return Conversation(
                messages: [],
                curatedSummary: "Weekend trip planning",
                displayDate: "Last week"
            )
        }
        let base = Calendar.current.startOfDay(for: pastWeek)

        let messages: [Message] = [
            Message(
                role: .user,
                content: "Thinking about a quick weekend trip. Somewhere quiet.",
                timestamp: minutesAfter(base, hours: 10, minutes: 0)
            ),
            Message(
                role: .assistant,
                content: "How far would you want to drive, and is this a solo recharge or with someone?",
                timestamp: minutesAfter(base, hours: 10, minutes: 1)
            ),
            Message(
                role: .user,
                content: "Solo. Two hours max.",
                timestamp: minutesAfter(base, hours: 10, minutes: 2)
            )
        ]

        return Conversation(
            createdAt: messages.first?.timestamp ?? pastWeek,
            messages: messages,
            curatedSummary: "Weekend trip planning",
            displayDate: "Last week"
        )
    }

    // MARK: - Dummy Content — Older

    private static func makeOlderConversation() -> Conversation {
        guard let older = Calendar.current.date(byAdding: .month, value: -2, to: Date()) else {
            return Conversation(
                messages: [],
                curatedSummary: "Brief note",
                displayDate: "Older"
            )
        }
        let base = Calendar.current.startOfDay(for: older)

        let messages: [Message] = [
            Message(
                role: .user,
                content: "Quick note to self — pick up the book from the library.",
                timestamp: minutesAfter(base, hours: 14, minutes: 30)
            ),
            Message(
                role: .assistant,
                content: "Saved.",
                timestamp: minutesAfter(base, hours: 14, minutes: 30)
            )
        ]

        return Conversation(
            createdAt: messages.first?.timestamp ?? older,
            messages: messages,
            curatedSummary: "Library reminder",
            displayDate: "Older"
        )
    }

    // MARK: - Helpers

    private static func minutesAfter(_ base: Date, hours: Int, minutes: Int) -> Date {
        let calendar = Calendar.current
        guard let withHours = calendar.date(byAdding: .hour, value: hours, to: base) else {
            return base
        }
        return calendar.date(byAdding: .minute, value: minutes, to: withHours) ?? withHours
    }
}
