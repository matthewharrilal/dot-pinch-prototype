// Per-frame discipline: every place that writes view properties from
// progress-derived state runs inside a CATransaction with setDisableActions(true)
// so UIKit's default implicit animations don't compound with the spring drive.

import QuartzCore

extension CATransaction {

    /// Run `body` inside a CATransaction that suppresses every implicit
    /// animation triggered by the writes inside it.
    public static func withSuppressedActions(_ body: () -> Void) {
        begin()
        setDisableActions(true)
        defer { commit() }
        body()
    }
}
