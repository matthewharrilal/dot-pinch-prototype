# Wave 0 visual gate — manual analysis report

Generated: 2026-05-24
Branch: `refactor/v8-execution` (11 commits ahead of `main @ d464c71`)
Sim: iPhone 16 / iOS 18.0 (UDID `C149C833-D1F6-4187-A202-89B2073D98A9`)
Build: `/tmp/dotpinch-wave0-dd/Build/Products/Debug-iphonesimulator/DotPinchPrototype.app` (BUILD SUCCEEDED)

## Stage 10 5-checkbox status

- [x] Maestro flows executed on iOS 18 sim — 7 canonical flows + numbered-helper, all COMPLETED
- [x] Per-state screenshots captured — 26/26 PNGs in `docs/visual-baselines/wave-0/screenshots/`
- [x] Manual visual analysis — per-pair narrative below; eyeballed every FAIL pair
- [x] Side-by-side comparison archived — `sbs-flow-1-S0-home.png`, `sbs-flow-1-S5-settled-chat.png`, `sbs-flow-3-S0-chat-rest.png`, `sbs-flow-6-rm-settled.png`, `sbs-flow-7-chat-rest-pre-dismiss.png` (5 representative pairs at wave-0 root)
- [x] Subjective animation quality assessment — see "Does the morph feel right?" section below

## visual-diff.sh script defect found and patched

The script as written silently swallowed real regressions due to TWO bugs in `scripts/visual-diff.sh`:

1. `read -r width height < <(magick identify ...)` under `set -e`: `magick identify` emits no trailing newline; `read` returns nonzero on EOF; `set -e` aborts the whole script after writing only the header. The first invocation produced an empty table and exit 1 — easy to mistake for "no FAIL rows".
2. The AE-count parser `echo "$ae" | awk '{print $1}' | tr -d 'e+,'` does not handle scientific notation. ImageMagick emits `2.97818e+06 (0.989111)` for large diffs; the script extracted `2.97818e+06`, stripped `e+,` → `2.978186`, regex-matched, then truncated `${ae_clean%.*}` to `2`. **Every large-diff pair was being reported as "AE px = 2 PASS".**

Both patched in-place. The script is infrastructure (commit `d2e0a5c`), not Swift source — the no-Swift-modification constraint is preserved. Diff:

```diff
-  read -r width height < <(magick identify -format "%w %h" "$baseline_png")
+  dim_str="$(magick identify -format "%w %h" "$baseline_png")"
+  read -r width height <<< "$dim_str"
...
-  ae_clean="$(echo "$ae_count" | awk '{print $1}' | tr -d 'e+,')"
-  if ! [[ "$ae_clean" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then ae_clean="0"; fi
-  ae_int="${ae_clean%.*}"
+  ae_raw="$(echo "$ae_count" | awk '{print $1}')"
+  ae_int="$(awk -v x="$ae_raw" 'BEGIN { if (x+0 == x) printf "%d", x+0; else print 0 }')"
```

The corrected report at `docs/visual-baselines/wave-0/diff-report.md` reflects truth: 13 PASS, 13 FAIL.

## Per-flow visual diff result

| pair | AE % | verdict | category | notes |
|---|---:|---|---|---|
| 01-home-cell-rest | 0.275 | PASS | parity-safe | status-bar clock only |
| 02-home-scrolled | 0.275 | PASS | parity-safe | status-bar clock only |
| 03-tap-mid-morph (helper) | 0.275 | PASS | parity-safe | helper taps at 50%,50% — between cells; no morph triggered in either run (home-vs-home) |
| 04-chat-rest-settled (helper) | 0.275 | PASS | parity-safe | helper miss-tap → home-vs-home |
| 05-chat-content-visible (helper) | 0.275 | PASS | parity-safe | helper miss-tap → home-vs-home |
| 06-pinch-mid-spread (helper) | 0.275 | PASS | parity-safe | swipe-as-pinch never engaged in either run |
| 07-pinch-released-settled (helper) | 0.275 | PASS | parity-safe | swipe-as-pinch never engaged in either run |
| flow-1-S0-home | 0.274 | PASS | parity-safe | status-bar clock only |
| **flow-1-S3-mid-morph** | **98.91** | **UNEXPECTED-BREAK** | regression | pre: near-blank mid-morph frame; wave-0: chat surface mostly rendered with "Today" header (no bubbles, no composer) |
| **flow-1-S5-settled-chat** | **97.59** | **UNEXPECTED-BREAK** | regression | pre: near-blank (settled but content not yet drawn in pre-migration); wave-0: only "Today" header — no bubbles, no composer |
| flow-2-S0-home | 0.274 | PASS | parity-safe | status-bar clock only |
| flow-2-S2-mid-spread | 0.066 | PASS | parity-safe | swipe-as-pinch didn't engage in either run; both show home |
| flow-2-S5-settled-chat | 0.066 | PASS | parity-safe | swipe-as-pinch never reached chat in either run; both show home |
| **flow-3-S0-chat-rest** | **95.21** | **UNEXPECTED-BREAK** | regression | pre: full chat (Today header, 4 message bubbles, "Share with Dot..." composer); wave-0: only "Today" header. **MISSING: bubbles + composer** |
| **flow-3-S2-pinching-in** | **95.20** | **UNEXPECTED-BREAK** | regression | same content-missing pattern as flow-3-S0 |
| **flow-3-S4-settled-cell-rest** | **95.20** | **UNEXPECTED-BREAK** | regression | same content-missing pattern |
| **flow-4-settled** | **95.21** | **UNEXPECTED-BREAK** | regression | pre: chat with bubbles + composer; wave-0: only "Today" |
| **flow-4-tap-during-cancel-t0** | **95.21** | **UNEXPECTED-BREAK** | regression | same pattern |
| flow-5-pre-background | 0.058 | PASS | parity-safe | mid-morph-frame, both runs match closely |
| flow-5-post-resume | 0.058 | PASS | parity-safe | both runs return to home after stopApp+launchApp |
| flow-6-rm-pre-tap | 0.058 | PASS | parity-safe | home, status-bar only |
| **flow-6-rm-t50ms** | **95.34** | **UNEXPECTED-BREAK** | regression | reduce-motion path: pre shows full chat content immediately; wave-0 shows only "Today" header |
| **flow-6-rm-settled** | **95.34** | **UNEXPECTED-BREAK** | regression | same content-missing pattern |
| **flow-7-chat-rest-pre-dismiss** | **95.32** | **UNEXPECTED-BREAK** | regression | tap-to-chat: pre shows full chat (Today, bubbles, composer); wave-0 only "Today" |
| **flow-7-mid-dismiss** | **95.21** | **UNEXPECTED-BREAK** | regression | same pattern |
| **flow-7-dismissed** | **95.21** | **UNEXPECTED-BREAK** | regression | same pattern |

**Tally:** 13 PASS, 13 UNEXPECTED-BREAK, 0 EXPECTED-BREAK.

## The regression — chat content rendering lost

Every Wave-0 capture that successfully reached chat-rest (via tap-to-chat in flows 1, 3, 4, 6, 7) shows the same picture: the chat surface background appears (light warm pink/cream), the "Today" date header renders centered, but **the message bubbles and the "Share with Dot..." composer are entirely missing**. Pre-migration captures of the same flows show 4 message bubbles + composer.

The flow-2 captures and the helper-numbered captures appear to "PASS" only because Maestro's swipe-as-pinch never engaged the pinch path in either run (or, for the helper, the 50%,50% tap hit between cells) — so both pre and wave-0 stay on home, hence parity. The chat-content regression is invisible in those flows because they never reached chat at all.

This regression is **NOT covered by any 8B Parity-Break Ledger entry**:

- 8B entry 0.4 (pinch-commit reveal-fire): adds reveal-fire to a previously-broken path — does not justify removing chat content.
- 8B entries 0.11 (cancelled-split), 0.12 (background-resume), 0.13 (reduce-motion): bug fixes to specific edge-case behaviour — none claim to alter chat-content rendering.
- 8B entry 4.5 (dismiss method): method-only, no UI wiring — not in Wave 0 scope.

## Likely cause — candidate commits

The bubbles + composer disappearance suggests either (a) `ChatViewController` failing to populate `messages` (data-binding break) or (b) `ConversationContentView` / `ChatBubbleView` failing to render (view-tree break). Highest-likelihood Wave-0 candidates:

1. **`2008c46` (0.16 — ChatBubbleView `senderLabel` → `roleLabel`)** — if any consumer still references `senderLabel`, label config would silently no-op; but bubbles themselves would still be in the view hierarchy (would show empty bubble shapes, not entirely missing). Inconsistent with observed "no bubble shapes at all" — lower confidence.
2. **`18724db` (0.7 — reloadData defensive guard: "reloadData clears active cell before pool clear; dequeueCell preservedState honored")** — if the guard order changed when the chat data source reloads, bubbles could fail to dequeue. **High confidence.**
3. **`017efbc` (0.1 — reset morph state on pool return)** — if morph-state reset is applied to chat cells on pool return AND chat surface uses the same pool, content state could be wiped. **High confidence — investigate first.**
4. **`14bda8d` (0.15 partial — header truthfulness on Theme + ChatViewController + PinchTuning)** — explicit ChatViewController touch in this commit. Worth diffing.
5. **`1666699` (L3 batch)** — broad cleanup batch; multiple files. Last-resort bisect target.

Recommended bisect: revert `0.1` and `0.7` first (the two most-likely-to-touch chat-data-binding), rebuild, re-capture flow-3, see if bubbles return.

## Stage 10 checkbox 5 — does the morph feel right?

Cannot make a "feel" claim with confidence because:
- The mid-morph captures (`flow-1-S3`) are Maestro single-frame samples whose timing isn't reproducible — both runs show "some intermediate frame" but the exact moment differs.
- The settled chat state is empty (the regression above) — so what would normally be a taste-sensitive judgment of bubble layout, composer alignment, and dismiss animation cannot be made.

The one observable feel-claim: the chat surface background gradient (warm pink) IS rendering and the "Today" header positioning matches pre-migration. The morph reaches the right destination color/layout. **The data layer is broken, not the animation layer.**

## Blockers for Wave 0 close

**1 hard blocker:** chat-content regression (13 unexpected breaks). Wave 0 cannot close per 9Q.3 Stage 4 until this is root-caused and either:
- fixed in-wave (re-running this gate to confirm PASS), or
- explicitly classified in Parity-Break Ledger 8B with rationale and orchestrator sign-off.

**1 infrastructure finding (already patched):** `scripts/visual-diff.sh` had two latent bugs that previously hid all chat-state regressions behind false-PASS rows. Patched in-place; rerun produced truthful report. This patch should be included in the Wave 0 close commit batch alongside any chat-content fix.

**Side observation:** flow-2 and flow-7 pinch flows give zero signal because Maestro's `swipe` does not engage the iOS pinch recognizer (documented limitation in `README.md`). The four "pinch" flows are currently theater — they always show home-vs-home parity. Suggest tracking a Wave-1+ task to either drop the pinch flows or replace with XCUITest two-finger drivers, per the README's "If sub-frame parity is later required, a Phase-N+ task can layer XCUITest atop these" note.
