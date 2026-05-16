// Per-frame discipline helpers for the spring substrate. Every place that
// writes view properties from progress-derived state opens a CATransaction
// with setDisableActions(true) so UIKit's default 0.25s implicit animations
// don't compound with the explicit spring drive — this extension is the
// single way to express that pattern.

import QuartzCore

extension CATransaction {

    /// Run `body` inside a CATransaction that suppresses every implicit
    /// animation triggered by the writes inside it. The commit happens
    /// regardless of how `body` returns (including early `return`).
    public static func withSuppressedActions(_ body: () -> Void) {
        begin()
        setDisableActions(true)
        defer { commit() }
        body()
    }
}
