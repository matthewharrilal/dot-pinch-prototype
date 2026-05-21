# Audit A6 — Data + Models
ROLE: AUDIT-A6

Scope: `Conversation/Data/ConversationStore.swift`, `Conversation/Data/DummyConversationLoader.swift`, `Conversation/Models/Conversation.swift`, `Conversation/Models/Message.swift`.

Live entry: `AppDelegate → V2RootViewController()`. V2 consumes:
- `DummyConversationLoader.load()` (V2RootViewController:36)
- `ConversationStore.init(initialConversations:)`, `store.conversations` array (V2RootViewController:37,109-110; TimelineDataSourceAdapter:32,36-37,46-47)
- `Conversation.{id, messages, curatedSummary, displayDate, createdAt}` (CellView:383-395; ChatViewController:29-42; TimelineDataSourceAdapter:47)
- `Message.{role, content, timestamp}` (ChatBubbleView:24-41; ChatViewController rebuildBubbles)

V1-only consumers of the data layer mutation API: `ConversationViewController`, `MemoryTimeline`, `ActiveConversationCoordinator`, `ChatBodyView`, `ConversationComposer`. None reachable from V2 root.

---

## File: DotPinchPrototype/Conversation/Data/ConversationStore.swift

### Symbols (with tags)

| Symbol | Lines | Tag | Live consumers (V2 root) |
|---|---|---|---|
| `ConversationStore` (class) | 66 | LIVE_REACHABLE | V2RootViewController, TimelineDataSourceAdapter |
| `conversations` (property) | 85 | LIVE_REACHABLE | V2RootViewController:109-110; TimelineDataSourceAdapter:32,36-37,46-47 |
| `conversationsByID` (private) | 92 | LIVE_REACHABLE | used by `conversation(byID:)` + mutators |
| `init(initialConversations:)` | 102 | LIVE_REACHABLE | V2RootViewController:37 |
| `conversation(byID:)` | 116 | V1_ONLY | only V1 callers (MemoryTimeline:200, ActiveConversationCoordinator:506); ALSO referenced by tests |
| `createConversation(curatedSummary:displayDate:)` | 135-147 | V1_ONLY | only ConversationViewController:890 |
| `appendMessage(_:to:)` | 162-166 | V1_ONLY | ConversationViewController:894, MemoryTimeline:209 |
| `updateSummary(_:for:)` | 175-179 | V1_ONLY | only `Tests/ReactiveBindingsTests.swift:93` (TEST_ONLY in source tree; no V1 production caller) |
| `updateDraftText(_:for:)` | 188-192 | V1_ONLY | MemoryTimeline:215, plus draft tests |
| `deleteConversation(byID:)` | 200-203 | ORPHAN | zero callers in DotPinchPrototype/ or Tests/ |
| `insert(_:)` (private) | 209-212 | LIVE_REACHABLE | init path |
| `sortByRecency()` (private) | 220-222 | LIVE_REACHABLE | init path |

Note: V2's only public-API surface is `init`, the `conversations` array, and the `Conversation` references it yields. All mutation methods are V1_ONLY in production (V2 has no append/edit/delete UI yet).

### Comment-slim

- DELETE lines 2-59 (verbose file-top docstring: P1.T2, observability model, ordering, single-emission invariant, threading invariants, lifetime/DI, vocabulary discipline). Keep a 3-4 line replacement docstring.
- DELETE lines 68-72 (Dependencies MARK + empty-section explainer).
- DELETE lines 76-84 (storage doc verbiage); keep 1-line "Canonical recency-ordered conversations."
- DELETE lines 87-91 (conversationsByID multi-line P10.T2 ref).
- DELETE lines 96-101 (init doc paragraph); keep 1-line.
- DELETE lines 111-115 (P10.T1/W2-G1 reference); keep 1-line.
- DELETE lines 122-134 (createConversation 13-line essay); keep 2-line if kept.
- DELETE lines 149-161 (appendMessage paragraph + P1.T5.S2.A1+A3); keep 2-line.
- DELETE lines 168-174 (updateSummary P1.T2.S2.A5 ref).
- DELETE lines 181-187 (updateDraftText Wave-7b reference).
- DELETE lines 194-199 (deleteConversation P1.T2.S2.A6 + B15 doc) — but symbol is orphan.
- DELETE lines 205, 207-208, 214-219 (Internal Helpers blockcomment + cost-note novella).
- DELETE lines 224-239 (massive "no observation plumbing needed" essay + Combine prophecy).

Comment-slim LOC: ~140 (file shrinks from 241 → ~95-100).

### Hard deletes

- `deleteConversation(byID:)` lines 200-203 — ORPHAN, zero call sites.
- `updateSummary(_:for:)` lines 175-179 — V1_ONLY; sole caller is a test exercising the method (ReactiveBindingsTests:93). Recommend deleting both method and that test assertion since no production code calls it.
- `updateDraftText(_:for:)` lines 188-192 — V1_ONLY; production caller is MemoryTimeline (V1). Pair with `Conversation.draftText` purge.
- `createConversation(curatedSummary:displayDate:)` lines 135-147 — V1_ONLY; sole caller is V1 ConversationViewController:890.
- `appendMessage(_:to:)` lines 162-166 — V1_ONLY; callers are V1 ConversationViewController + V1 MemoryTimeline.
- `conversation(byID:)` lines 116-118 — V1_ONLY (V2 uses index-based `store.conversations[idx]`); callers are V1 MemoryTimeline + V1 ActiveConversationCoordinator.

If V1 retirement (I7) ships, the entire Public Mutation API + `conversation(byID:)` collapse and the store reduces to ~30 lines: storage, init, sortByRecency.

Hard-delete LOC (if V1 retired): ~60 (lines 116-118, 135-147, 162-166, 175-179, 188-192, 200-203 — incl. their docstrings).

### Cross-ref warnings

- Deleting `updateSummary` requires removing `ReactiveBindingsTests.swift:93` (the test exists to exercise it).
- Deleting `updateDraftText` requires removing `Conversation.draftText` + `Conversation.updateDraftText` AND ConversationDraftTextTests.swift + ChatComposerResponderTests.swift draft-restore assertions AND ChatBodyView:698 read.
- Deleting `createConversation` removes the only place a "new conversation" entrypoint exists — V2 has no new-conversation UI, fine.
- Deleting `conversation(byID:)` removes the public sanctioned lookup; V2 already uses `store.conversations[idx]`. Tests use `store.conversations[0].id` (not byID). Safe.
- `private(set) var conversations` access pattern + the `@Observable` macro: untouched.
- `lastUpdatedAt` is used internally by `sortByRecency`. With `appendMessage`/`updateSummary` deleted, `lastUpdatedAt` only changes in init; sortByRecency still works since init populates it from `messages.last?.timestamp`.

---

## File: DotPinchPrototype/Conversation/Data/DummyConversationLoader.swift

### Symbols (with tags)

| Symbol | Lines | Tag | Live consumers |
|---|---|---|---|
| `DummyConversationLoader` (enum) | 25 | LIVE_REACHABLE | V2RootViewController:36, ConversationComposer:83 |
| `load()` | 32-39 | LIVE_REACHABLE | V2RootViewController:36 |
| `makeTodayConversation()` (private) | 46-92 | LIVE_REACHABLE | via load() |
| `makeYesterdayConversation()` (private) | 98-137 | LIVE_REACHABLE | via load() |
| `makePastWeekConversation()` (private) | 142-176 | LIVE_REACHABLE | via load() |
| `makeOlderConversation()` (private) | 182-211 | LIVE_REACHABLE | via load() |
| `minutesAfter(_:hours:minutes:)` (private) | 219-225 | LIVE_REACHABLE | all maker funcs |

All 4 fixtures are live — V2 renders all 4 cells in TimelineCanvas (V2RootViewController:36).

### Comment-slim

- DELETE lines 2-20 (P1.T4 / migration provenance / vocabulary discipline novella). Keep a 2-line file docstring: "DummyConversationLoader — preloads 4 fixture conversations rendered by V2 at launch."
- DELETE lines 27-28 (Static API MARK if no second section sibling).
- DELETE lines 29-31 (load() doc paragraph); keep 1-line.
- DELETE lines 43-45 (makeToday "original prototype" provenance); 1-line.
- DELETE lines 51-52 (Messages 1-5 from ChatTranscript.past notation).
- DELETE line 78 (`// ChatTranscript.current` inline ref).
- DELETE lines 94-97, 96-97 (Yesterday MARK + truncation rationale).
- DELETE lines 139-141 (PastWeek MARK + "Older, shorter summary" tag-line).
- DELETE lines 178-181 (Older MARK + "validate large-N scrolling" rationale).
- DELETE lines 213-218 (Helpers MARK header + minutesAfter doc paragraph w/ G4 reference).

Comment-slim LOC: ~30 (file shrinks from 226 → ~195).

### Hard deletes

None — every fixture and every helper is reachable from V2. The fallback `guard let yesterday/pastWeek/older` branches (lines 99-105, 143-149, 183-189) are defensive but cheap; keep them.

### Cross-ref warnings

- The provenance comments tying content to `Placeholders/ChatTranscript` reference deleted V1 placeholder files. Removing the comment is the right call.
- `DummyConversationLoader.load()` is also called by `ConversationComposer.makeStore()` (V1) — that file is V1_ONLY and will be deleted in V1 retirement. Loader itself unaffected.

---

## File: DotPinchPrototype/Conversation/Models/Conversation.swift

### Symbols (with tags)

| Symbol | Lines | Tag | Live consumers (V2) |
|---|---|---|---|
| `Conversation` (class) | 35 | LIVE_REACHABLE | CellView, ChatViewController, store |
| `id` | 42 | LIVE_REACHABLE | CellView:383, TimelineDataSourceAdapter:47 |
| `messages` | 50 | LIVE_REACHABLE | ChatViewController:30 |
| `createdAt` | 55 | LIVE_REACHABLE | CellView:395, ChatViewController:39 |
| `lastUpdatedAt` | 59 | LIVE_REACHABLE | ConversationStore.sortByRecency only |
| `curatedSummary` | 64 | LIVE_REACHABLE | CellView:385 |
| `displayDate` | 69 | LIVE_REACHABLE | CellView:384,387; ChatViewController:42 |
| `draftText` | 80 | V1_ONLY | only ChatBodyView:698 (V1) + draft tests |
| `init(...)` | 87-100 | LIVE_REACHABLE | DummyConversationLoader + tests |
| `==` (static) | 107-109 | LIVE_REACHABLE | Identifiable/diffable use (Conversation is Hashable consumer) |
| `hash(into:)` | 112-114 | LIVE_REACHABLE | Hashable conformance |
| `appendMessage(_:at:)` | 121-124 | V1_ONLY | only ConversationStore.appendMessage (V1_ONLY) |
| `updateCuratedSummary(_:at:)` | 128-131 | V1_ONLY | only ConversationStore.updateSummary (V1_ONLY) |
| `updateDraftText(_:at:)` | 138-142 | V1_ONLY | only ConversationStore.updateDraftText (V1_ONLY) |

Conformances `Identifiable, Equatable, Hashable` — kept for diffable data source semantics in TimelineCanvas (uses `id`). V2 doesn't put `Conversation` in a `Set`, but Hashable conformance is cheap and harmless.

### Comment-slim

- DELETE lines 2-28 (file-top novella: P1.T1.S1 reference type rationale, Observation macro justification, mutation discipline doc, vocabulary discipline). Keep 3-line.
- DELETE lines 38, 41-42 doc (Identity MARK comment-block on `id` re: SpatialAnchorResolver / MorphState).
- DELETE lines 44-49 (Content MARK + messages doc).
- DELETE lines 52-58 (Metadata MARK + createdAt + lastUpdatedAt doc).
- DELETE lines 61-68 (curatedSummary + displayDate doc — 8 lines of CellSummaryView pre-render rationale).
- DELETE lines 71-79 (draftText W5-G11 essay) — but symbol is hard-delete target.
- DELETE lines 82-86 (Initialization MARK + G4-ceiling doc).
- DELETE lines 102-103 (Conformances MARK + paragraph).
- DELETE lines 104-106, 111 (Equatable / Hashable rationale).
- DELETE lines 116-120 (Store-mediated seam MARK + appendMessage P1.T2 ref).
- DELETE lines 126-127, 133-137, 140 (updateCuratedSummary + updateDraftText doc novellas).

Comment-slim LOC: ~70 (file shrinks from 143 → ~73 before any symbol deletes).

### Hard deletes

- `draftText` property lines 71-80 — V1_ONLY. Only production reader is ChatBodyView:698 (V1).
- `updateDraftText(_:at:)` lines 133-142 — V1_ONLY (paired with draftText).
- `appendMessage(_:at:)` lines 118-124 — V1_ONLY if store's `appendMessage` is deleted.
- `updateCuratedSummary(_:at:)` lines 126-131 — V1_ONLY if store's `updateSummary` is deleted.

If V1 retired: `messages` and `curatedSummary` can become `let` (no mutation API needed); `lastUpdatedAt` likewise becomes `let` set once in init. The whole "Store-mediated mutation seam" section disappears.

Hard-delete LOC (with V1 retired): ~30 (lines 71-80 draftText, 118-124, 126-131, 133-142, plus their dosctrings).

### Cross-ref warnings

- Removing `draftText`: must remove `ConversationStore.updateDraftText`, `ChatBodyView:698`, `ConversationDraftTextTests.swift` (entire file), `ChatComposerResponderTests.swift` draft restore assertions (lines 5, 70, 82, 88, 96, 105).
- Removing `updateCuratedSummary`: must remove `ConversationStore.updateSummary` + `ReactiveBindingsTests.swift:93`.
- Removing `appendMessage(at:)`: must remove `ConversationStore.appendMessage` + V1 callers (ConversationViewController:894, MemoryTimeline:209).
- `private(set)` → `let` migration is safe IF V1 mutation paths are all dead — V2 never mutates a Conversation after construction.

---

## File: DotPinchPrototype/Conversation/Models/Message.swift

### Symbols (with tags)

| Symbol | Lines | Tag | Live consumers (V2) |
|---|---|---|---|
| `Message` (struct) | 20 | LIVE_REACHABLE | ChatBubbleView, ChatViewController, DummyLoader |
| `Role` enum (.user / .assistant) | 26-29 | LIVE_REACHABLE | ChatBubbleView:24,72; DummyLoader fixtures |
| `id` | 34 | LIVE_REACHABLE | Identifiable conformance |
| `role` | 39 | LIVE_REACHABLE | ChatBubbleView:24 |
| `content` | 44 | LIVE_REACHABLE | ChatBubbleView:32 |
| `timestamp` | 50 | LIVE_REACHABLE | ChatBubbleView:41; Conversation.init computes lastUpdatedAt |
| `init(id:role:content:timestamp:)` | 56-66 | LIVE_REACHABLE | DummyLoader (all 4 fixtures) |
| Conformance `Identifiable` | 20 | LIVE_REACHABLE | UI display |
| Conformance `Equatable` | 20 | AMBIGUOUS | no in-tree `==` use found; synthesized; harmless |
| Conformance `Hashable` | 20 | AMBIGUOUS | no `Set<Message>` / `[Message:_]` found; harmless |
| Conformance `Codable` | 20 | ORPHAN | no encode/decode in tree |
| Conformance `Sendable` | 20 | AMBIGUOUS | no actor-hop site found; cheap to keep |

### Comment-slim

- DELETE lines 2-16 (file-top novella: value-type rationale, conformance enumeration, vocabulary discipline). Keep 2-line: "Message — single utterance in a Conversation. Value type, immutable."
- DELETE lines 22-23 (Role MARK + paragraph re: OpenAI/Anthropic vocab).
- DELETE lines 31-32 (Identity MARK + immutability essay on id).
- DELETE lines 36-37 (Content MARK).
- DELETE lines 38, 42-43 (role + content multi-line doc).
- DELETE lines 46-50 (Metadata MARK + timestamp doc).
- DELETE lines 52-55 (Initialization MARK + doc).

Comment-slim LOC: ~30 (file shrinks from 67 → ~38).

### Hard deletes

- `Codable` conformance — ORPHAN. No JSONEncoder/Decoder in tree. Safe to drop. Also drop `Codable` from `Role`.
- Consider dropping `Sendable` if no cross-actor hop exists; the struct is trivially Sendable (all `let` value-type members) so synth is free — keep for clarity.
- `Hashable` and `Equatable`: synthesized, no consumer found in production or tests; could drop, but they're free given all fields conform. Recommend KEEP.

Hard-delete LOC: ~2 (Codable removal from struct + Role).

### Cross-ref warnings

- Removing `Codable` from `Role` and `Message`: no in-tree consumer found. Safe.
- `Message.Role` is referenced by `ChatBubbleView.displayName(for: Message.Role)` at line 72 — fine, unaffected.

---

## Summary

### Tag counts (symbols across all 4 files)

| Tag | Count | Notes |
|---|---|---|
| LIVE_REACHABLE | 25 | All of Message, most of Conversation/Loader, store init+conversations |
| V1_ONLY | 9 | Store mutation API + Conversation mutation seam + draftText |
| ORPHAN | 2 | `deleteConversation`, `Codable` conformance on Message/Role |
| TEST_ONLY | 0 | (updateSummary is V1_ONLY since only a test calls it, but classified as V1 surface) |
| AMBIGUOUS | 3 | Message Equatable/Hashable/Sendable conformances — synthesized, no consumer found, but cheap and idiomatic |

### Hard-delete LOC

| Scope | LOC |
|---|---|
| Pure orphans (no V1 retirement needed) | ~10 (`deleteConversation` 4 + Codable 2 + supporting docstrings 4) |
| Plus draftText cleanup (recommended — V1 reads only) | ~30 (Conversation.draftText 10, Conversation.updateDraftText 10, store.updateDraftText 5, plus delete tests external to this scope) |
| Plus full V1 retirement (with I7) | ~95 (entire mutation API on store + Conversation seam) |

### Comment-slim LOC

| File | Verbose LOC removed |
|---|---|
| ConversationStore.swift | ~140 (241 → ~100) |
| DummyConversationLoader.swift | ~30 (226 → ~195) |
| Conversation.swift | ~70 (143 → ~73 pre-symbol-purge) |
| Message.swift | ~30 (67 → ~38) |
| **Total** | **~270 LOC of verbose comments** |

### Whole-file deletes

None. All four files contain LIVE_REACHABLE V2 surface. The data layer is the most reusable layer in the codebase; pure shrink, no deletion.

### Recommended action ordering

1. Hard-delete `deleteConversation` (zero-risk orphan).
2. Drop `Codable` from `Message` + `Role` (zero-risk orphan).
3. Comment-slim all 4 files (~270 LOC).
4. After V1 retirement (I7), purge: store's `createConversation`/`appendMessage`/`updateSummary`/`updateDraftText`/`conversation(byID:)`, Conversation's `appendMessage`/`updateCuratedSummary`/`updateDraftText`/`draftText`. Migrate `messages`/`curatedSummary`/`lastUpdatedAt` to `let`.
5. Step 4 unlocks ~95 more LOC and converts Conversation into an immutable record.

### Cross-audit handoffs

- **A2 (ChatBody)**: confirm ChatBodyView:698 (`conversation.draftText`) gets purged together with this audit's draftText recommendation.
- **A?? (Tests)**: `ConversationDraftTextTests.swift` (entire file), `ChatComposerResponderTests.swift` draft-restore assertions, `ReactiveBindingsTests.swift:93` `updateSummary` test — all should be removed if their V1 production paths are.
- **A?? (V1 retirement / I7)**: when V1 ConversationViewController + MemoryTimeline + ActiveConversationCoordinator + ConversationComposer + ChatBodyView are deleted, this audit's "V1_ONLY" symbols become hard-deletable per step 4.
- `lastUpdatedAt` remains useful even after V1 retirement (DummyLoader fixtures use it implicitly via sortByRecency on init), so do not drop the property.
