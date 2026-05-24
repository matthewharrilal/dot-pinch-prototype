# Visual diff report — wave-0 vs pre-migration baseline

Generated: 2026-05-24T06:25:24Z
Tolerance: AE with -fuzz 1% (per-channel RGB); pair-fail at >0.5% pixels

| pair | baseline | current | AE px | total px | % over | verdict |
|---|---|---|---:|---:|---:|---|
| `01-home-cell-rest.png` | ok | ok | 8279 | 3010968 | 0.2750% | PASS |
| `02-home-scrolled.png` | ok | ok | 8270 | 3010968 | 0.2747% | PASS |
| `03-tap-mid-morph.png` | ok | ok | 8270 | 3010968 | 0.2747% | PASS |
| `04-chat-rest-settled.png` | ok | ok | 8270 | 3010968 | 0.2747% | PASS |
| `05-chat-content-visible.png` | ok | ok | 8270 | 3010968 | 0.2747% | PASS |
| `06-pinch-mid-spread.png` | ok | ok | 8270 | 3010968 | 0.2747% | PASS |
| `07-pinch-released-settled.png` | ok | ok | 8270 | 3010968 | 0.2747% | PASS |
| `flow-1-S0-home.png` | ok | ok | 2079 | 3010968 | 0.0690% | PASS |
| `flow-1-S3-mid-morph.png` | ok | ok | 2978360 | 3010968 | 98.9170% | FAIL |
| `flow-1-S5-settled-chat.png` | ok | ok | 3007570 | 3010968 | 99.8871% | FAIL |
| `flow-2-S0-home.png` | ok | ok | 8246 | 3010968 | 0.2739% | PASS |
| `flow-2-S2-mid-spread.png` | ok | ok | 1972 | 3010968 | 0.0655% | PASS |
| `flow-2-S5-settled-chat.png` | ok | ok | 1972 | 3010968 | 0.0655% | PASS |
| `flow-3-S0-chat-rest.png` | ok | ok | 638583 | 3010968 | 21.2086% | FAIL |
| `flow-3-S2-pinching-in.png` | ok | ok | 1835 | 3010968 | 0.0609% | PASS |
| `flow-3-S4-settled-cell-rest.png` | ok | ok | 1835 | 3010968 | 0.0609% | PASS |
| `flow-4-settled.png` | ok | ok | 1835 | 3010968 | 0.0609% | PASS |
| `flow-4-tap-during-cancel-t0.png` | ok | ok | 1835 | 3010968 | 0.0609% | PASS |
| `flow-5-post-resume.png` | ok | ok | 1733 | 3010968 | 0.0576% | PASS |
| `flow-5-pre-background.png` | ok | ok | 1747 | 3010968 | 0.0580% | PASS |
| `flow-6-rm-pre-tap.png` | ok | ok | 8095 | 3010968 | 0.2689% | PASS |
| `flow-6-rm-settled.png` | ok | ok | 3007470 | 3010968 | 99.8838% | FAIL |
| `flow-6-rm-t50ms.png` | ok | ok | 2870430 | 3010968 | 95.3325% | FAIL |
| `flow-7-chat-rest-pre-dismiss.png` | ok | ok | 3007000 | 3010968 | 99.8682% | FAIL |
| `flow-7-dismissed.png` | ok | ok | 1887 | 3010968 | 0.0627% | PASS |
| `flow-7-mid-dismiss.png` | ok | ok | 1887 | 3010968 | 0.0627% | PASS |

**Overall: FAIL — at least one pair exceeded 0.5% pixel-delta threshold.**
Review per-pair diff PNGs in `/Users/spacewizardmoneygang/Desktop/XcodeInstall/dot-pinch-prototype/docs/visual-baselines/wave-0/diffs` and add explicit sign-off to Parity-Break Ledger 8B if intended.
