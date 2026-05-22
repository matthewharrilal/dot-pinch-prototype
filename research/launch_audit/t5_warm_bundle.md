# T5 — WARM Branch Audit: Theme Statics + Cold-Start dyld

**Agent:** TRACE-T5 | **Date:** 2026-05-21 | **Mode:** Read-only

---

## Branch E — Theme Statics

**File:** `DotPinchPrototype/DesignSystem/Theme.swift`

### What it contains

- `Theme.Page` / `Theme.Cell` / `Theme.Text`: all `UIColor(red:green:blue:alpha:)` or `UIColor(white:alpha:)` literals — pure inline arithmetic, no disk I/O.
- `Theme.Typography`: five `UIFont.systemFont(ofSize:weight:)` calls + one lazy closure (`destinationBody`).
- `Theme.Radius` / `Theme.Symbol`: `CGFloat` and `UIImage.SymbolWeight` scalars — zero cost.

### `destinationBody` — the only non-trivial initializer

```swift
static let destinationBody: UIFont = {
    let size: CGFloat = 22
    let base = UIFont.systemFont(ofSize: size, weight: .regular)
    return base.fontDescriptor.withDesign(.serif).map { UIFont(descriptor: $0, size: size) } ?? base
}()
```

This is a Swift `static let` stored property with a closure — it runs on first access (lazy, thread-safe via `dispatch_once`). The call chain: `systemFont` → `fontDescriptor` → `withDesign(.serif)` → conditional `UIFont(descriptor:size:)`. All system-font descriptor work; no disk I/O, no custom font file. Cost is CoreText descriptor lookup, estimated <1ms on device. Not hot.

### Six Questions — Branch E

1. **What does this rest on?** UIKit's `UIColor` struct initializers (pure math) and CoreText's system font registry (already loaded by UIKit init). No custom font files, no bundle resources, no file I/O.

2. **Why does this exist?** Centralised design tokens to avoid magic literals across 24 source files. Also serves as the first touch-point in `AppDelegate` — `window.backgroundColor = Theme.Page.surface` is called before `rootViewController` is set.

3. **What assumptions does this encode?** (a) System fonts are available at all times — safe assumption for UIKit apps. (b) `.serif` font design variant exists on iOS 17+ — the closure handles the nil case correctly with `?? base`. (c) All statics are accessed on the main thread after UIKit is initialised — true for the `AppDelegate` path.

4. **What would happen if this changed?** If a custom `.ttf`/`.otf` were added and referenced here, first access would hit disk. Currently no risk. If `UIFont.systemFont` were replaced with `UIFont(name:size:)` for a bundled font without `UIAppFonts` registration, it would silently return `nil` and fall back, not crash.

5. **What would happen if this were removed?** Magic literals would scatter across call sites; no launch-time effect. The `window.backgroundColor` line in `AppDelegate` would need a fallback color.

6. **What's absent?** No `UIAppFonts` key in the generated Info.plist (XcodeGen uses `GENERATE_INFOPLIST_FILE: YES` with no font entries in `project.yml`). No `.ttf`/`.otf` files found anywhere in the source tree. No `CTFontManagerRegisterFonts` call. **Custom font loading is entirely absent** — this is a system-font-only project.

### Branch E Verdict

**COLD.** Theme statics are ~5 UIColor struct inits + 5 systemFont calls + 1 CoreText descriptor lookup. Total cost: negligible (<2ms). No disk I/O pathway. No custom fonts. The `window.backgroundColor = Theme.Page.surface` call in AppDelegate is sound — it executes before `rootViewController` is set, which is the correct ordering to suppress launch-screen flash.

---

## Branch F — Cold-Start dyld / Swift Module Loading

**Files:** all 24 `.swift` sources; `project.yml`

### Import inventory (unique modules)

| Module | Count | Notes |
|---|---|---|
| `Foundation` | ~14 files | Always loaded, zero marginal cost |
| `UIKit` | 6 files | Loaded at app start unconditionally |
| `QuartzCore` | 5 files | Subset of UIKit's own dependency; pre-loaded |
| `CoreGraphics` | 6 files | Same — pre-loaded with UIKit |
| `Observation` | 3 files | `ConversationStore`, `Conversation`, `CellView` |

No `@_exported import`. No third-party frameworks. No SPM packages. No binary XCFrameworks.

### `Observation` module note

`Observation` (Swift 5.9 macro-based) is a small Apple system framework. On iOS 17+ it is part of the OS image and loaded by dyld from the shared cache — no per-app overhead beyond symbol binding. Not hot.

### Global static initializers outside Theme

Only two non-trivial statics found outside Theme:

1. **`ChatBubbleView.timestampFormatter`** — `static let` with a `DateFormatter` closure. `DateFormatter` init is known to be ~1-5ms (locale/calendar setup). However, this runs on first bubble render, not at launch — `ChatBubbleView` is not in the `AppDelegate → V2RootViewController` init path unless a cell is immediately rendered on screen.

2. **`Camera.identity`** / **`CameraAnimator.velocityFloor`** / **`TimelineCanvas.cellSpacing` etc.** — all are scalar `CGFloat` or struct value types. Zero init cost.

### Cold vs warm launch delta

- **24 Swift source files**, all compiled into a single module (no binary frameworks, no dynamic libraries). dyld4 on iOS 17+ handles this as one Mach-O image. Expected cold-launch overhead from module loading: 50–150ms (typical for a single-target pure-Swift app with no SPM deps).
- **Warm launch** (process killed, relaunched): dyld shared cache and VM pages for UIKit/QuartzCore/Observation are already hot in the OS page cache. Delta between cold and warm is mainly the app's own `.o` code pages — probably 10–30ms.
- Neither figure accounts for `TimelineCanvas` and `V2RootViewController` init work (HOT branches T1–T4 territory).

### Six Questions — Branch F

1. **What does this rest on?** dyld4 shared cache (iOS 17+), the OS image for Foundation/UIKit/QuartzCore/CoreGraphics/Observation, and the app's own single Mach-O binary.

2. **Why does this exist?** Standard UIKit app structure. Import spread (Foundation in 14 files, UIKit in 6) is normal — CoreGraphics/QuartzCore are already loaded as UIKit sub-dependencies.

3. **What assumptions does this encode?** No binary frameworks = no additional dyld image loads. All modules are OS-resident. Swift 5.9 strict-concurrency is set to `minimal` — no async actors that could cause initialisation re-entry.

4. **What would happen if this changed?** Adding a single SPM binary framework (e.g. a charting lib) would add one dyld image and ~5-20ms cold-launch cost. Currently nothing to worry about.

5. **What would happen if this were removed?** N/A — this is the module graph itself, not an opt-in feature.

6. **What's absent?** No pre-main hooks (`+load`, `__attribute__((constructor))`). No Objective-C classes (no `+load` risk). No `@NSApplicationMain`-style bridging. The `@main` entry point is clean Swift. **No expensive global `static let` at file scope** (all heavy statics are inside types, so they're lazy by default).

### Branch F Verdict

**COLD.** Import graph is lean — 5 OS modules, all pre-cached on iOS 17+. No third-party binary frameworks. No `@_exported import`. No file-scope global initializers. The one potentially warm cost (`DateFormatter` in `ChatBubbleView`) is deferred to first render, not launch. Cold-start dyld overhead is expected-normal for this app profile and is not a contributor to the 1–3s white screen.

---

## HOT Escalation Flags

None triggered. Both branches stayed cold throughout the trace. No Theme static cascades into layout or view hierarchy. No import or global init runs on the main thread before `didFinishLaunching` returns.

The 1–3s white-screen window is not attributable to Theme statics or module loading. Root cause is upstream in the HOT branches (T1–T4): likely `V2RootViewController` init, `TimelineCanvas` setup, or the launch screen→window transition timing.
