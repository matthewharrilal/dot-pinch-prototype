### Conversation/ChatBody/
Houses `ChatBodyView.swift` (the existing `ConversationContentView.swift` after its wave-2 rename + relocation). Renders the full chat-state content of the active conversation (gradient, scroll view, message bubbles, blur overlay, chat mask). Visible at chat-state (`chatBodyAlpha=1`); alpha=0 at cell-state. Crossfades against `CellSummaryView` driven by the progress scalar. Per `docs/VOCABULARY.md`: this is "chat" content (the canonical settled state); the term "expanded" is forbidden.

Cross-reference: pillar P3.T3 (refactor ConversationContentView → ChatBodyView for cell-hosting) in `MASTER-CHECKLIST.json`.
