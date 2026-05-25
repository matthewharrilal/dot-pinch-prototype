# Automated regression suite for DotPinchPrototype

Combined Maestro + XCUITest coverage of the 12 critical user journeys identified during the handoff implementation. **12/12 passing as of 2026-05-25.**

## Coverage matrix

| ID | Test | Tool | File | Scenario |
|---|---|---|---|---|
| 01 | launch | Maestro | `Maestro/01-launch.yaml` | Cold launch, cell list renders |
| 02 | tap-cell | Maestro | `Maestro/02-tap-cell.yaml` | Tap forward → handoff → chat-state |
| 03 | pinch-in-from-chat | XCUITest | `UITests/PinchGestureUITests.swift::test_03_…` | Reverse from chat-rest to cell-list |
| 04 | pinch-out-at-chat | XCUITest | `…test_04_…` | Pinch outward at chat-rest (no-op / rubberband) |
| 05 | rapid-tap | Maestro | `Maestro/05-rapid-tap.yaml` | 5 rapid taps → guards prevent re-fire |
| 06 | roundtrip-same-cell | XCUITest | `…test_06_…` | Tap A → reverse → tap A again |
| 07 | roundtrip-different-cell | XCUITest | `…test_07_…` | Tap A → reverse → tap B |
| 08 | mid-reveal-tap | Maestro | `Maestro/08-mid-reveal-tap.yaml` | Tap during reveal sequence |
| 09 | composer-text-roundtrip | XCUITest | `…test_09_…` | Type text → reverse → re-tap → text preserved |
| 10 | background-foreground | Maestro | `Maestro/10-background-foreground.yaml` | Kill mid-reveal → relaunch → no crash |
| 11 | pinch-commit-forward | XCUITest | `…test_11_…` | Pinch out from cell-rest → commits to chat-rest |
| 12 | scroll-cell-list | Maestro | `Maestro/12-scroll-cell-list.yaml` | Pan up/down → no layout crashes |

## Why both Maestro AND XCUITest?

- **Maestro 2.5.1** is fast for tap/swipe/scroll flows but has no pinch primitive (`pinchIn`/`pinchOut` not in YAML grammar). Must run against iOS 18 simulator per `project_maestro_ios26_incompat` memory (iOS 26 returns empty a11y tree).
- **XCUITest** has `XCUIElement.pinch(withScale:velocity:)` for true multi-touch pinch. Used for all 6 pinch-required flows.

## Prerequisites

- Maestro 2.5.1 at `~/.maestro/bin/maestro`
- Java 17 at `/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home` (Maestro's runtime)
- iPhone 16 simulator booted with **iOS 18.0** (NOT iOS 26)
- App built and installed on the simulator

## Running the suite

### Maestro flows (6 of 12)

```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# Boot iPhone 16 / iOS 18 simulator
xcrun simctl boot C149C833-D1F6-4187-A202-89B2073D98A9   # adjust UDID

# Build + install the app
xcodebuild -project DotPinchPrototype.xcodeproj -scheme DotPinchPrototype \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' build
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/DotPinchPrototype-* \
  -name "DotPinchPrototype.app" \
  -path "*Build/Products/Debug-iphonesimulator*" \
  ! -path "*Index.noindex*" | head -1)
xcrun simctl install C149C833-D1F6-4187-A202-89B2073D98A9 "$APP_PATH"

# Run all Maestro flows
maestro test Maestro/

# Or a single flow
maestro test Maestro/02-tap-cell.yaml
```

### XCUITests (6 of 12)

```bash
xcodebuild -project DotPinchPrototype.xcodeproj -scheme DotPinchPrototype \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' \
  -only-testing:DotPinchPrototypeUITests test
```

### InvariantHardeningTests (unit-level)

```bash
xcodebuild -project DotPinchPrototype.xcodeproj -scheme DotPinchPrototype \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' \
  -only-testing:DotPinchPrototypeTests/InvariantHardeningTests test
```

## Crash detection

Maestro auto-fails a flow if the app crashes. XCUITest catches crashes via the `app.state` check.

Crash logs land in `~/Library/Logs/DiagnosticReports/`. Run `ls -ltc ~/Library/Logs/DiagnosticReports/DotPinchPrototype*` after a failed run.

## Manual pinch on the Simulator

If you need to test a pinch interactively (not via XCUITest):

1. **Option + click + drag** in the Simulator window
2. Option-modifier creates a two-finger pinch around the cursor
3. Drag direction determines pinch-in (toward center) or pinch-out (away from center)

For automated option-drag, `Maestro/scripts/pinch.sh` uses `cliclick` + AppleScript but **requires macOS Accessibility permissions** granted to your terminal app (System Settings → Privacy & Security → Accessibility). Without permissions, `cliclick` cannot send synthetic mouse events to the Simulator window.

If accessibility setup is blocked, XCUITest is the recommended pinch path (no permission prompts).

## Bug-fix history (this session)

The 12-flow suite caught and helped diagnose three real bugs:

1. **Cross-view constraint crash at chatContent init** — `NSGenericException` "anchors in different view hierarchies." Fixed by deferring `activateCrossViewConstraints` until after `addSubview` connects view trees.
2. **CellView centerY-anchored assertion firing on neighbor transforms** — `frame.midY` includes `cell.transform` translation from `followActive`. Fixed by comparing `layer.position.y` (the constraint-driven center, untransformed) instead.
3. **Composer invisible at chat-rest** — `cell.masksToBounds=true` clipped chatContent's composer because cross-view constraints to V2RootVC.safeAreaLayoutGuide positioned the composer at cell-coord y=1013, outside cell.bounds. Fixed by pinning chatContent's subviews to chatContent's own edges with constants baking in `parentView.safeAreaInsets`.
4. **Round-trip composer text loss** — `stateController.composerText` only updated at handoff time. User text typed into `cell.chatContent.composer` during chat-state was overwritten by stale stateController on re-tap. Fixed by syncing `cell.chatContent`'s state INTO stateController in `V2RootVC.handleMorphRevealReady` before each present.
5. **Test timing** — XCUITest's pinch returns before springs settle; activeCellIndex stays non-nil and blocks the next tap. Fixed by adding 3.5s settle wait in `waitForCellList()`.
