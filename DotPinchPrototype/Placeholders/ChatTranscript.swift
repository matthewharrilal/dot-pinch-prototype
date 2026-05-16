// Static chat transcript placeholder. Lives outside the view layer so the
// view stays focused on rendering and the content is trivially swappable.

import Foundation

struct ChatMessage {
    let sender: String
    let body: String
    let timestamp: String
}

enum ChatTranscript {

    /// Past messages, chronological — earliest first. Laid out above the
    /// viewport at baseline; revealed during the morph.
    static let past: [ChatMessage] = [
        ChatMessage(
            sender: "Assistant",
            body: "Hey, hope you slept okay. I'll send a gentle nudge in a bit about today's movement check-in.",
            timestamp: "Mon, Jul 1 at 3:00 AM"
        ),
        ChatMessage(
            sender: "You",
            body: "Awake. Couldn't sleep again. Mind a little loud tonight.",
            timestamp: "Mon, Jul 1 at 3:02 AM"
        ),
        ChatMessage(
            sender: "Assistant",
            body: "That sounds rough. Want to try a slow breath together, or just sit with the quiet for a minute first?",
            timestamp: "Mon, Jul 1 at 3:05 AM"
        ),
        ChatMessage(
            sender: "You",
            body: "Just sit. I'm okay. Maybe I'll try a walk when it gets light.",
            timestamp: "Mon, Jul 1 at 3:08 AM"
        ),
        ChatMessage(
            sender: "Assistant",
            body: "A short walk at dawn sounds restorative. I'll check in with the daily-movement nudge in a few minutes — feel free to ignore it if the walk feels like enough.",
            timestamp: "Mon, Jul 1 at 3:10 AM"
        )
    ]

    /// The currently-visible message at baseline.
    static let current = ChatMessage(
        sender: "Assistant",
        body: "Good morning! Just a quick check-in about your daily exercise goal. I know it's early, but a 20-minute workout can really kickstart your Monday. Whether it's a brisk walk, some stretching, or a quick home workout, it's a great way to energize yourself for the week ahead.",
        timestamp: "Mon, Jul 1 at 3:12 AM"
    )
}
