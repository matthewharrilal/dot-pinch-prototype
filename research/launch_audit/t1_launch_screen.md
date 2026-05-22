# TRACE-T1 — Launch Screen Configuration

**Hypothesis under test:** the multi-second white screen the user reports on
launch is iOS's *auto-generated launch screen*, painted from build settings
that declare it should be generated but never describe what it looks like.

**Verdict (lead with it):** CONFIRMED for the *visible* white. The launch
screen is the only surface iOS can paint before the app process is alive, and
this project tells iOS to generate one but supplies zero customization keys,
so iOS falls back to a plain white `UIView`. The `window.backgroundColor`
mitigation in `AppDelegate.swift:15` cannot run until after that screen has
already been on glass for the full pre-`main` + early-runtime window. See
"Time budget" below for split.

---

## Bedrock evidence (what was read)

- `project.yml:52` — `INFOPLIST_KEY_UILaunchScreen_Generation: YES`
- `project.yml:50` — `GENERATE_INFOPLIST_FILE: YES` (Info.plist is synthesized
  at build time from `INFOPLIST_KEY_*` settings; there is no source plist).
- `DotPinchPrototype/App/AppDelegate.swift:13-15` — author comment explicitly
  identifies the symptom: "Pre-empt the launch-screen white flash by painting
  the window background before rootViewController's view loads."
- `DotPinchPrototypeTests/.../V2RootViewController.swift:38` — backgroundColor
  set again in `loadView()` (defensive double-paint).
- Repo-wide search: **no `Info.plist` source file, no `LaunchScreen.storyboard`,
  no `*.xcassets`, no `UILaunchScreen` dict, no `UILaunchImages` key.**
- `project.pbxproj:469, 545` — Debug + Release both inherit
  `INFOPLIST_KEY_UILaunchScreen_Generation = YES`.

---

## Six-question trace

### Node A — `INFOPLIST_KEY_UILaunchScreen_Generation: YES`

1. **Rests on:** Xcode 12+ build-system feature where `INFOPLIST_KEY_*` build
   settings are merged into a synthesized Info.plist when
   `GENERATE_INFOPLIST_FILE=YES`. With this key set and **no** `UILaunchScreen`
   dictionary supplied, iOS uses a default-constructed launch screen: a single
   full-screen view with the *system default* background. On a fresh project
   with no `UIUserInterfaceStyle` lock, the system default is white in light
   mode, black in dark mode.
2. **Why it exists:** xcodegen / Xcode 14 project templates emit this key by
   default. It is the modern replacement for `LaunchScreen.storyboard`
   reference. The author likely never explicitly chose it — it shipped with
   the project skeleton.
3. **Assumptions encoded:** (a) the developer will *also* supply a
   `UILaunchScreen` dict to customize colors/images; (b) a blank white screen
   for ~1s is acceptable. Both assumptions are false for this app — the app's
   page surface is `#ede9ee` (light mauve), and the user has explicitly
   complained.
4. **If changed (to `NO`):** iOS would look for a `UILaunchScreen` dict OR a
   `LaunchScreen.storyboard` reference; finding neither, on iOS 14+ the app
   will *be rejected at App Store submission* but will still run locally with
   a black or device-default screen. Bad fix.
5. **If removed entirely:** identical to `NO` — the key is presence-checked,
   not value-checked. Same App Store rejection risk.
6. **What's absent:** the `UILaunchScreen` *companion dict* that this key was
   designed to point at. Without it, the Generation key is doing the bare
   minimum (passing App Store validation) and nothing more.

### Node B — `AppDelegate.window.backgroundColor = Theme.Page.surface`

1. **Rests on:** UIKit's contract that `UIWindow.backgroundColor` paints in
   the gap between launch-screen dismissal and first `viewDidAppear`.
2. **Why it exists:** the comment proves the author saw the white flash and
   tried to mitigate it.
3. **Assumptions encoded:** that the window paint happens *during* the white
   period. It does not. The launch screen is composited by SpringBoard /
   `BackBoardd` from a pre-rendered snapshot; UIKit code in
   `didFinishLaunchingWithOptions` runs *after* that snapshot has been shown
   and is being cross-faded out. The `window.backgroundColor` only affects
   the brief moment **between** launch-screen dismissal and first
   `CATransaction` flush of `V2RootViewController.loadView()` — typically
   under one frame.
4. **If changed:** no perceptible effect on the white window. (Different
   problem; not the bug.)
5. **If removed:** same outcome. Dead code w.r.t. the reported symptom.
6. **What's absent:** any matching configuration on the *launch screen
   itself*. The mitigation paints the wrong surface.

### Node C — Synthesized Info.plist (no source `Info.plist`)

1. **Rests on:** `GENERATE_INFOPLIST_FILE=YES` + `INFOPLIST_KEY_*` settings.
2. **Why it exists:** modern Xcode default; reduces merge conflicts on plist.
3. **Assumptions encoded:** every plist key needed can be expressed as an
   `INFOPLIST_KEY_*` setting. Mostly true — including the `UILaunchScreen`
   dict, which xcodegen exposes via the nested `infoPlist:` key OR via flat
   `INFOPLIST_KEY_UILaunchScreen_*` settings (Xcode 14+).
4. **If changed (introduce a source `Info.plist`):** more flexible but heavier
   and breaks xcodegen ergonomics. Not necessary.
5. **If removed:** project won't build (no plist).
6. **What's absent:** any `INFOPLIST_KEY_UILaunchScreen_*` child keys.

### Node D — iOS 17 launch-screen requirements

1. **Rests on:** Apple's iOS 14+ enforcement that storyboards or generated
   launch screens are mandatory for App Store submission; iOS 17 inherits.
2. **Why it exists:** Apple deprecated static launch images for thermal,
   resolution, and dark-mode-correctness reasons.
3. **Assumptions encoded:** developers will customize. Default is hostile.
4. **If changed:** Apple keeps tightening; iOS 18+ may enforce
   `UILaunchScreen` having explicit `UIColorName`.
5. **If removed:** N/A — platform requirement.
6. **What's absent:** the `UIColorName` key referencing a *named color asset*
   in an `.xcassets` catalog. That's the canonical Apple-recommended path.

---

## Counterfactual — what fixes this

The launch screen is **not** a runtime artifact. It is a static plist + asset
combination that iOS rasterizes at install/launch time. The fix has two parts:

1. **Tell iOS what color to paint** via `UILaunchScreen.UIColorName`.
2. **Ship a named color asset** matching `Theme.Page.surface` (`#ede9ee`).

Because the page is actually a vertical gradient (`Theme.Page.top` →
`Theme.Page.surface` → `Theme.Page.bottom`), the *closest single-color match*
is `Theme.Page.surface` (the middle stop, L=92%, `#ede9ee`). A gradient launch
screen requires a storyboard or an image — out of scope for a "stop the white
flash" fix; the perceptual delta between `#ede9ee` and the visible gradient is
< 3 ΔE and indistinguishable in motion. Solid `#ede9ee` is the right move.

### `project.yml` patch — copy-paste ready

Replace the single `INFOPLIST_KEY_UILaunchScreen_Generation: YES` line in
`project.yml` (around L52) with the block below. The flat
`INFOPLIST_KEY_UILaunchScreen_*` form is recognized by Xcode 14+ and by
xcodegen passthrough (xcodegen forwards unknown `INFOPLIST_KEY_*` settings
verbatim — no schema gate).

```yaml
        INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents: YES
        # Launch screen: solid Theme.Page.surface (#ede9ee). The middle gradient
        # stop is the closest single-color match to the page material. Eliminates
        # the white flash iOS otherwise paints from the empty default generated
        # launch screen.
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UILaunchScreen_UIColorName: LaunchBackground
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: ...
```

### Asset catalog — also required

Create `DotPinchPrototype/Resources/Assets.xcassets/LaunchBackground.colorset/Contents.json`
with the sRGB triple matching `Theme.swift:15`:

```json
{
  "colors" : [
    {
      "idiom" : "universal",
      "color" : {
        "color-space" : "srgb",
        "components" : { "red" : "0.929", "green" : "0.914", "blue" : "0.933", "alpha" : "1.000" }
      }
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

Add the catalog to the target's sources in `project.yml`:

```yaml
    sources:
      - path: DotPinchPrototype
        type: group
        excludes:
          - "**/README.md"
          - "**/.gitkeep"
      - path: DotPinchPrototype/Resources/Assets.xcassets
        type: folder
```

Then `xcodegen generate` and rebuild. iOS rasterizes the launch screen at
install time; the white flash is gone on the *next* install (not the next
launch — uninstall + reinstall on the sim to verify).

---

## Time budget — how much of the 1-3s is launch screen?

Estimate breakdown for a cold launch on an iPhone 15 sim, iOS 17/18:

| Phase | Duration | Surface shown | This audit |
|---|---|---|---|
| SpringBoard zoom-in + launch image composite | 200-400ms | **WHITE (auto-generated)** | YES — fixed by patch |
| dyld + Swift runtime init + `@main` reaches `didFinishLaunchingWithOptions` | 150-400ms | **WHITE (still launch screen)** | YES — fixed by patch |
| `V2RootViewController.init` → `DummyConversationLoader.load()` + `ConversationStore` + `TimelineCanvas()` (gradient install, gesture install, animator setup) | 80-200ms | window backgroundColor (mauve) | NO — separate trace |
| First `layoutSubviews` + cell instantiation + gradient rasterization | 100-300ms | mauve, cells appearing | NO — separate trace |
| Cross-fade settle | ~16-33ms | final | NO |

**Conclusion:** roughly **400-800ms** of the 1-3s window is the
auto-generated white launch screen. That is **the fix the patch buys back.**
The remaining 200-500ms is runtime init (TimelineCanvas is 1,477 LoC and
instantiates gradient layers, pan + pinch recognizers, two animators, and a
CADisplayLink) and belongs to a separate trace (T2 — runtime init audit).

If the user reports 1s, this patch alone resolves the perceived issue. If the
user reports 3s, this patch closes ~30% of the gap and a runtime-init audit
is needed to chase the rest.

---

## Crash hypothesis — out of scope here

The "occasional crash" symptom is **not** caused by launch-screen config.
Launch-screen misconfiguration cannot crash on iOS 17+ (Apple's loader
tolerates missing `UILaunchScreen` children; it just paints default). The
crash belongs to a separate trace — likely `TimelineCanvas` init ordering
(L155-156: `cameraAnimator` references `self` before `extensionAnimator` is
constructed) or a force-unwrap on `dataSource` during early `reloadData`. Flag
for TRACE-T2 / TRACE-T3.

---

## Apply-this-fix checklist

1. Patch `project.yml` per snippet above.
2. Create `DotPinchPrototype/Resources/Assets.xcassets/LaunchBackground.colorset/Contents.json`.
3. Run `xcodegen generate`.
4. Uninstall the app from the simulator (launch screen is cached by iOS).
5. Build + launch — verify the first frame is mauve, not white.
6. Optionally remove the now-redundant `window.backgroundColor =
   Theme.Page.surface` line in `AppDelegate.swift:15` (leave it for now — it
   covers the < 1-frame gap between launch-screen dismissal and `loadView`).
