// Accessibility identifier registry. Anything UITests / Maestro / runtime
// inspection needs to look up by identifier reads through this enum, not
// through inline string literals.

enum AccessibilityID {
    static let demoRoot            = "DemoRoot"
    static let conversationSurface = "ConversationSurface"
    static let composerPlaceholder = "ComposerPlaceholder"
    static let statusLabel         = "StatusLabel"
}
