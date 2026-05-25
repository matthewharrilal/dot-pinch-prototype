// Accessibility identifier registry. View code looks up identifiers here
// instead of inlining string literals so test selectors stay atomic.

enum AccessibilityID {
    static let conversationSurface = "ConversationSurface"
    static let chatRestAffordance = "cell.chatRestAffordance"
    static let chatContentHeader = "chatContent.header"
    static let chatContentScrollView = "chatContent.scrollView"
    static let chatContentComposer = "chatContent.composer"
}
