# T2 — Synchronous init work blocking first paint

**Role:** TRACE-T2 (read-only). Branch: `V2RootViewController.init` + `TimelineCanvas.init` on cold launch.

**Live entry:** `AppDelegate.didFinishLaunching` → `V2RootViewController()` → `super.init` returns → window key+visible → `loadView` → `viewDidLoad` → first layout pass.

Everything below `V2RootViewController.init` returns runs on the main thread BEFORE the first vsync that could draw anything other than the launch storyboard. The Springboard-to-app handoff already burned its budget on dyld + image load; the window is unhid as soon as `init()` returns. Any synchronous work inside `init` is wall-clock time the white screen is on screen.

---

## Per-node six-question trace + ms estimates

Estimates are order-of-magnitude on iPhone 13/14-class device, cold-launch CPU not yet at peak clock. Caches cold. Tag: `~0.x ms` = sub-ms negligible, `~1-5ms` = visible, `~10ms+` = a frame.

### NODE A — `V2RootViewController.init()` (App/V2RootViewController.swift:18)

Three sequential stored-property initializers all run before `super.init(nibName:bundle:)` (line 26).

#### A1 — `DummyConversationLoader.load()` (line 19)

**What:** Calls 4 factories. Each factory does:
- 1× `Calendar.current` lookup (autoupdating, cached after first access — ~50µs first time, ~5µs subsequent)
- 1× `Calendar.date(byAdding:value:to:)` for non-today factories (3 calls, ~20-50µs each)
- 1× `Calendar.startOfDay(for:)` per factory (~30-80µs first call, gets cheaper)
- N× `minutesAfter(...)` per factory — each is TWO `Calendar.date(byAdding:value:to:)` calls (lines 184-190). Total: today=6, yesterday=4, pastWeek=3, older=2 → **15 messages × 2 calendar adds = 30 calls**.
- Conversation/Message struct construction (cheap, ~5µs each).

**1. What invokes this?** `V2RootViewController.init` direct, line 19. Pre-`super.init`.
**2. What does it touch?** `Calendar.current` (NSCalendar bridge, locale lookup), `Date()`, allocates 4 Conversations + 15 Messages.
**3. What's the failure surface?** Any factory whose `Calendar.date(byAdding:...)` returns nil falls back to an empty-messages Conversation (lines 71-77, 114-120, 152-158). No crash, but: `makeTodayConversation` has NO nil-guard (line 25) — if `Calendar.current.startOfDay` ever returned a weird value, downstream `minutesAfter` returns base on failure, so the today conversation could degrade to all-same-timestamp messages. Not a crash path.
**4. What's the cost?** ~30 Calendar date-add calls + 4 startOfDay + locale lookups. **Estimate: 3-8 ms cold, 1-3 ms warm.** Not huge, but it's a non-trivial chunk of a 16.6ms frame, and it's all pre-super.init so it adds linearly to time-to-window.
**5. What's defer-able?** ENTIRELY. The store can start empty; `TimelineCanvas.reloadData()` already handles zero cells (TimelineCanvas.swift:603-609 — explicit `count > 0` guard that pools all cells and returns). The current code only calls reloadData ONCE (V2RootViewController.swift:58) — so deferring requires reloadData to be called a second time when data arrives.
**6. What's the highest-leverage move?** Replace synchronous load with `Task { @MainActor in ... }` that pushes into the store and then triggers `timelineCanvas.reloadData()`. See recommendation R1.

#### A2 — `ConversationStore(initialConversations: conversations)` (line 20)

**What:** Loops 4 conversations through `insert()` (4× dict set + 4× array append) then `sortByRecency()` (4-element sort, ~16 comparisons on `lastUpdatedAt`).

`Conversation.lastUpdatedAt` — not shown but typical implementation is `messages.last?.timestamp ?? createdAt`. Either way O(1) per comparison.

**1. Invokes:** init line 20, after A1.
**2. Touches:** allocates `[UUID: Conversation]` dict + `[Conversation]` array, both with 4 entries.
**3. Failure:** none for this size. `@Observable` registers tracking; first access initializes observation registrar (~50µs one-time).
**4. Cost:** **~0.1-0.5 ms.** Negligible.
**5. Defer-able:** trivially — if conversations is empty at init, this is a no-op.
**6. Leverage:** Folds into R1 (defer A1). Not a standalone target.

#### A3 — `TimelineDataSourceAdapter(store:naturalCellHeight:)` (lines 21-24)

Not in scope (other agent's branch likely), but cost is bounded by the adapter's init — typically just stores references. **~0.05 ms.**

#### A4 — `TimelineCanvas()` (line 25)

See NODE B. **This is the biggest single cost in init.**

---

### NODE B — `TimelineCanvas.init(frame:)` (TimelineCanvas.swift:149-168)

Called with `frame: .zero` via the parameterless `TimelineCanvas()` convenience. All install methods run before `super.init` returns to the VC.

#### B1 — `installViewHierarchy()` (line 151 / 175-193)

**What:**
- `layer.addSublayer(pageGradientLayer)` — adds a freshly-allocated CAGradientLayer (line 126 stored property already initialized at field-init time)
- `contentHost.clipsToBounds = true`, `translatesAutoresizingMaskIntoConstraints = true`, `addSubview(contentHost)` — UIView allocation already happened at field init (line 129)
- Sets `clipsToBounds = true` on canvas
- Builds `CATransform3DIdentity`, sets `m34 = -1/1000`, assigns `layer.sublayerTransform = perspective` (lines 188-190)
- Calls `installEdgeMasks()`

**1. Invokes:** TimelineCanvas.init line 151.
**2. Touches:** CALayer hierarchy mutation, sublayerTransform write (Core Animation transaction commit on next runloop turn).
**3. Failure:** none.
**4. Cost:** **~0.5-1.5 ms.** CALayer/UIView allocations and addSubview are cheap individually but each crosses the ObjC bridge.
**5. Defer-able:** The `pageGradientLayer.addSublayer` and `addSubview(contentHost)` are STRUCTURALLY required for first paint to render the page gradient background. Cannot meaningfully defer.
**6. Leverage:** Low. Keep here.

#### B2 — `installEdgeMasks()` (line 192 / 200-222)

**What:**
- `CGColorSpace(name: CGColorSpace.sRGB)` — one CFGetTypeID + dyld lookup of constant + CG retained ref. **First call is ~0.2-0.5 ms cold (color space registry hit).** Subsequent calls hit cache.
- 2× `UIColor.cgColor.converted(to:intent:options:)` — color space conversion: a Core Graphics color-matching call. **~0.1-0.3 ms each cold.**
- 2× `CAGradientLayer.colors` array property write (NSArray bridge from `[CGColor]`)
- 2× `addSublayer` (lines 220-221)

**1. Invokes:** B1 → line 192.
**2. Touches:** ColorSync, CGColorSpace, CALayer.
**3. Failure:** `CGColorSpace(name:)` can fail; line 201 falls back to `DeviceRGB` which is a different gamut — purely a graceful-degrade path, but the fallback shouldn't be hit on real devices.
**4. Cost:** **~1-2 ms cold** (ColorSync first-touch dominates), **~0.2 ms warm.**
**5. Defer-able:** Yes. The edge masks are only visible during mid-pinch (opacity stays 0 at rest until `updateEdgeMaskAlphas` runs against active progress). The CAGradientLayers can be lazy-instantiated on the first `updateEdgeMaskAlphas` call where alpha > 0, or eagerly built off-main with the CGColor objects (safe — CGColor is immutable & threadsafe) and then attached on main. But the simpler win is to fold these into a single sRGB lookup with the page gradient (B3) since both pay for the same ColorSync hit.
**6. Leverage:** Medium-low individually. **Combining B2+B3 into a single sRGB-lookup pass saves the duplicate ColorSync first-touch (~0.5 ms).** See R3.

#### B3 — `installPageGradient()` (line 152 / 230-239)

**What:**
- Another `CGColorSpace(name: CGColorSpace.sRGB)` — second call, now warm (~50µs).
- 3× `UIColor.cgColor.converted(to:intent:options:)` for top/mid/bottom (lines 232-234). ~0.3-0.5 ms total.
- `pageGradientLayer.colors`, `.locations`, `.startPoint`, `.endPoint` writes.

**1. Invokes:** TimelineCanvas.init line 152.
**2. Touches:** Same as B2.
**3. Failure:** Same fallback path as B2.
**4. Cost:** **~0.5-1 ms** (warm sRGB lookup, 3 conversions).
**5. Defer-able:** This IS the page gradient — it's the first paint background. The cheapest gate to "non-white screen" is exactly this layer. Cannot defer without showing white longer.
**6. Leverage:** Combine the color-conversion pass with B2 (R3).

#### B4 — `installPanRecognizer()` + `installPinchRecognizer()` (lines 153-154)

UIPanGestureRecognizer + UIPinchGestureRecognizer allocations, `addGestureRecognizer`. **~0.2 ms total.** Not deferrable in any meaningful way. Cheap.

#### B5 — `AnimationController()` — EAGER PROPERTY INIT (line 85)

**This is the critical one.** `let animationController = AnimationController()` at the property declaration runs BEFORE `init(frame:)` body executes (Swift initializes stored properties before the designated init body runs, per IPI rules).

Inside `AnimationController.init` (AnimationController.swift:31-40):
- `DisplayLinkProxy(controller:)` allocation
- `CADisplayLink(target:selector:)` allocation
- `CAFrameRateRange(minimum: 80, maximum: 120, preferred: 120)` construction
- `link.preferredFrameRateRange = ...` write
- **`link.add(to: .main, forMode: .common)` — registers with the main runloop.** This is the heaviest single call here.
- `link.isPaused = true`

**1. Invokes:** Property init of `TimelineCanvas.animationController`, fires before `super.init(frame:)` returns.
**2. Touches:** CADisplayLink subsystem, main RunLoop source registration, ProMotion rate negotiation.
**3. Failure:** none.
**4. Cost:** **~0.5-2 ms.** The CADisplayLink registration is the most expensive single op in the init chain; it touches Core Animation server, runloop source plumbing, and (on ProMotion) the variable-rate scheduler.
**5. Defer-able:** **YES — high-value.** The display link is paused immediately (line 37), so it consumes nothing per-frame until `runPropertyAnimation` flips `isPaused = false` (line 76). The registration could lazy-fire on first `runPropertyAnimation`. **This saves 0.5-2ms of init cost.** No animations run on initial appearance — the canvas is at rest, awaiting input.

   Concretely: `AnimationController` could hold a `var displayLink: CADisplayLink?` that's nil until first use:
   ```swift
   private func ensureDisplayLink() {
       if displayLink == nil {
           let proxy = DisplayLinkProxy(controller: self)
           let link = CADisplayLink(target: proxy, selector: ...)
           link.preferredFrameRateRange = ...
           link.add(to: .main, forMode: .common)
           link.isPaused = true
           self.proxy = proxy
           self.displayLink = link
       }
   }
   ```
   Called from `runPropertyAnimation` before `displayLink?.isPaused = false`.
**6. Leverage:** **HIGH.** See R2.

#### B6 — `cameraAnimator = CameraAnimator(...)` (line 156)

Allocates a `SpringAnimator<CGFloat>` (no integration runs — UUID generation, weak ref to controller, spring struct copy). **~0.05 ms.** Not deferrable since `cameraAnimator` is an IUO that callers will use synchronously on first gesture, but cost is negligible.

#### B7 — `extensionAnimator = SpringAnimator<CGFloat>(...)` + `valueChanged` closure (lines 157-166)

Same shape as B6. **~0.05 ms.**

#### B8 — `applyCameraTransform()` (line 167)

`bounds.midX/midY` are both 0 (frame: .zero passed in). Constructs `CATransform3DMakeTranslation(0, 0 - 0, 0) = identity`, writes `contentHost.layer.sublayerTransform`. **~0.01 ms.** This write is structurally a no-op pre-bounds but the call still occurs.

---

### NODE C — `loadView()` (V2RootViewController.swift:36-39)

Runs after `super.init` returns and the window is shown — this is the FIRST work that happens with a window on screen. Just sets `view.backgroundColor = Theme.Page.surface`. **~0.05 ms.** The white screen is gone the instant this view's backing layer flushes — IF `Theme.Page.surface` is light enough that the user perceives it as "not white". Theme.Page.surface = `#ede9ee` (lavender-grey), close to white. The white-screen symptom is partially a perceptual artifact: white storyboard → near-white VC.view background → gradient layer fills later.

### NODE D — `viewDidLoad()` (lines 41-67)

- `addSubview(timelineCanvas)` + 4× NSLayoutConstraint construction + activate
- `timelineCanvas.dataSource = adapter` (weak ref write)
- `timelineCanvas.reloadData()` — re-pools cells (none yet), invalidates layout cache, calls `updateVisibleCells` which gates on `bounds.width > 0` (TimelineCanvas.swift:601) — returns early because the canvas hasn't had its first layout pass yet
- UITapGestureRecognizer alloc + add
- `onMorphRevealReady` closure assign

**Cost: ~1-2 ms.** All structural. Mostly Auto Layout constraint setup.

---

## Total cold-init wall-clock budget (estimate)

| Stage | Cold (ms) | Warm (ms) |
|---|---|---|
| A1 DummyConversationLoader.load | 3-8 | 1-3 |
| A2 ConversationStore.init | 0.1-0.5 | 0.1 |
| A3 TimelineDataSourceAdapter | 0.05 | 0.05 |
| B1 installViewHierarchy | 0.5-1.5 | 0.3 |
| B2 installEdgeMasks | 1-2 | 0.2 |
| B3 installPageGradient | 0.5-1 | 0.3 |
| B4 gesture recognizers | 0.2 | 0.2 |
| B5 AnimationController (eager CADisplayLink) | 0.5-2 | 0.5 |
| B6+B7 animators | 0.1 | 0.1 |
| B8 applyCameraTransform | 0.01 | 0.01 |
| C loadView | 0.05 | 0.05 |
| D viewDidLoad | 1-2 | 0.5 |
| **Total synchronous init** | **~7-18 ms** | **~3-5 ms** |

Plus the first layout pass + first CA commit, which adds another vsync (~16ms) before pixels actually change on screen.

**~7-18ms of synchronous main-thread work doesn't explain a 1-3 second white screen on its own.** It's a contributor, not the cause — but the cause is almost certainly orthogonal (font/asset/storyboard work, or the first CA commit being delayed by the dyld+launch tail). See T1/T3 branches.

---

## Counterfactual analysis

### REMOVAL: `DummyConversationLoader.load() → []` + populate via `Task`

**Saves:** 3-8ms cold off pre-super.init. Cells appear empty for ~1 vsync after `Task { ... }` reaches MainActor and triggers `reloadData()`. Visible artifact: gradient background paints first (good — proves non-white screen instantly), then cells fade in.

**Tradeoff:** A tiny flash of "zero cells" between first paint and data arrival. Mitigated by Task starting BEFORE `super.init` returns conceptually — actually, `Task { @MainActor in ... }` started in viewDidLoad is hop-back-to-main, which won't run until current runloop pass exits. So the empty-state window is ~1 frame.

**Verdict:** WORTH IT. The gradient-first paint is the unblock; an empty canvas for 1-2 frames is invisible to users.

### MUTATION: `AnimationController` defers `CADisplayLink` creation until first `runPropertyAnimation`

**Saves:** 0.5-2ms cold off pre-super.init (B5).

**Tradeoff:** First gesture pays for displayLink registration cost on `.began`. That's bad — first pinch/pan would have a ~1-2ms hitch. BUT: deinit/proxy lifecycle stays correct since the lazy-create branch only runs once.

**Mitigation:** Lazy-create the displayLink at the END of `viewDidLoad` via a `Task { @MainActor in animationController.warmUp() }` — defers cost off the critical init path but pays it before the user can touch the screen.

**Verdict:** WORTH IT with the warm-up hop.

### SUBSTITUTION: 2-phase VC init (Phase 1: gradient background; Phase 2: data + animators)

**Phase 1:** `V2RootViewController.init()` constructs ONLY the canvas with view hierarchy + page gradient. Store is empty. Animators are nil. `viewDidLoad` constraints the canvas.

**Phase 2:** A `Task { @MainActor in ... }` kicked off at end of `viewDidLoad`:
1. Load conversations (`DummyConversationLoader.load()`)
2. `store.replaceAll(conversations)` (new method)
3. `timelineCanvas.attachAnimationController(...)` (or lazy-create internally)
4. `timelineCanvas.reloadData()`

**Saves:** All of A1, A2, B5, B6, B7 off the critical path. **~4-12ms cold off pre-super.init.**

**Tradeoff:** Gestures arriving in the ~1-frame window before Phase 2 completes need to be either ignored OR queued. Easiest: gesture recognizers stay installed but `handlePan`/`handlePinch` guard on `cameraAnimator != nil`. Since UIKit doesn't dispatch gestures until after first layout commits, this is largely theoretical.

**Verdict:** Maximum saving but most invasive. See R4.

---

## Single highest-leverage fix

**R1 (DO THIS FIRST): Defer `DummyConversationLoader.load()` to a `Task`.**

Replace the synchronous load with an async hop. Three lines change in `V2RootViewController`:

```swift
init() {
    self.store = ConversationStore()                            // empty
    self.adapter = TimelineDataSourceAdapter(
        store: self.store, naturalCellHeight: 200
    )
    self.timelineCanvas = TimelineCanvas()
    super.init(nibName: nil, bundle: nil)
}

override func viewDidLoad() {
    super.viewDidLoad()
    // ... existing setup ...
    timelineCanvas.dataSource = adapter
    timelineCanvas.reloadData()                                 // shows 0 cells, just gradient

    Task { @MainActor in
        let conversations = DummyConversationLoader.load()
        store.replaceAll(conversations)                         // new ConversationStore method
        timelineCanvas.reloadData()
    }
    // ...
}
```

Requires adding `func replaceAll(_ conversations: [Conversation])` to `ConversationStore`:

```swift
func replaceAll(_ new: [Conversation]) {
    conversations.removeAll(keepingCapacity: true)
    conversationsByID.removeAll(keepingCapacity: true)
    for c in new { insert(c) }
    sortByRecency()
}
```

**Wins:**
- Pre-super.init shrinks by 3-8ms cold.
- The user sees the page gradient on the first paint after viewDidLoad, then cells materialize one frame later.
- Aligns with the user's stated bias toward Swift Concurrency.
- Composes with R2 (lazy displayLink) and R3 (combined sRGB pass) for compounded savings.

**Why this over R2 alone:** A1 is the largest single contributor (3-8ms vs 0.5-2ms for B5), and the change is the smallest. R2 is the natural second move.

---

## Compounding moves (post-R1)

- **R2:** `AnimationController` lazy-creates the CADisplayLink on first `runPropertyAnimation`, optionally warmed by a `Task { @MainActor in animationController.warmUp() }` at end of `viewDidLoad`. Saves 0.5-2ms.
- **R3:** Fold `installEdgeMasks` + `installPageGradient` into ONE method that creates the sRGB color space once and converts all 5 colors in a single pass. Saves ~0.5ms cold (the duplicate ColorSync first-touch).
- **R4 (max):** Full 2-phase VC init as described in SUBSTITUTION above. Worth measuring with Instruments first to confirm the white screen is actually init-bound rather than CA-commit-bound or launch-tail-bound.

## Caveat on the symptom

7-18ms of synchronous init does NOT explain a 1-3 second white screen by itself. Likely the dominant white-screen contributor is one of:
- Launch storyboard → first VC swap timing (AppDelegate / window setup branch)
- First CA commit being deferred by image/font asset registration
- Animation server (`backboardd`) handshake on cold launch

The init work documented here is real and worth deferring (R1+R2 are both clean Swift Concurrency wins), but the **1-3 second** figure points to T1/T3's branches as the dominant cause. T2's branch contribution is bounded at ~15ms of the symptom.
