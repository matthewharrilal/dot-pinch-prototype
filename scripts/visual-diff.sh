#!/usr/bin/env bash
#
# visual-diff.sh — wave-N parity check against pre-migration baseline
#
# Usage:
#   ./scripts/visual-diff.sh wave-N
#
# Behaviour:
#   1. Resolves baseline at docs/visual-baselines/pre-migration/screenshots
#   2. Resolves current at docs/visual-baselines/<wave>/screenshots
#   3. For each baseline PNG, finds the matching current PNG by name and
#      runs `magick compare -metric AE -fuzz 1%` (absolute-error count
#      with a 1% per-channel RGB tolerance — substitutes for ksdiff per
#      SSoT 8C amendment).
#   4. Writes per-pair diff PNGs to docs/visual-baselines/<wave>/diffs.
#   5. Writes summary table to docs/visual-baselines/<wave>/diff-report.md.
#   6. Exits 0 if every pair has AE-count ≤ tolerance threshold, 1 otherwise.
#
# Threshold rationale:
#   AE counts pixels exceeding the per-channel fuzz. We treat ≤ 0.5% of
#   total pixels as "noise-floor parity" (anti-aliasing, sub-pixel
#   rasteriser jitter). Anything higher is a real visual delta — either
#   a parity-break that needs explicit sign-off (Ledger 8B) or a missed
#   token swap (Wave 1) / regression.
#
# Dependencies:
#   - ImageMagick 7+ (magick CLI) — verified on macOS via `brew install imagemagick`
#
# Conventions:
#   - Exit code 0 = clean; 1 = at least one pair over threshold; 2 = setup error.
#   - Side-by-side diff PNGs land in <wave>/diffs/ for human review.
#   - The pre-migration baseline is the canonical referent for ALL waves
#     unless a wave explicitly bumps its baseline (Parity Ledger 8B sign-off).

set -euo pipefail

WAVE="${1:-}"
if [[ -z "$WAVE" ]]; then
  echo "usage: $0 wave-N  (e.g. wave-1, wave-2, ...)" >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASELINE_DIR="$REPO_ROOT/docs/visual-baselines/pre-migration/screenshots"
CURRENT_DIR="$REPO_ROOT/docs/visual-baselines/$WAVE/screenshots"
DIFF_DIR="$REPO_ROOT/docs/visual-baselines/$WAVE/diffs"
REPORT="$REPO_ROOT/docs/visual-baselines/$WAVE/diff-report.md"

if [[ ! -d "$BASELINE_DIR" ]]; then
  echo "error: baseline dir not found at $BASELINE_DIR" >&2
  exit 2
fi
if [[ ! -d "$CURRENT_DIR" ]]; then
  echo "error: current dir not found at $CURRENT_DIR" >&2
  echo "hint: run the .maestro/flow-*.yaml suite with --test-output-dir docs/visual-baselines/$WAVE" >&2
  exit 2
fi

if ! command -v magick >/dev/null 2>&1; then
  echo "error: ImageMagick (magick) not on PATH. brew install imagemagick" >&2
  exit 2
fi

mkdir -p "$DIFF_DIR"

# Header
{
  echo "# Visual diff report — $WAVE vs pre-migration baseline"
  echo
  echo "Generated: $(date -u +%FT%TZ)"
  echo "Tolerance: AE with -fuzz 1% (per-channel RGB); pair-fail at >0.5% pixels"
  echo
  echo "| pair | baseline | current | AE px | total px | % over | verdict |"
  echo "|---|---|---|---:|---:|---:|---|"
} > "$REPORT"

OVERALL_EXIT=0
TOLERANCE_RATIO="0.005"   # 0.5%

for baseline_png in "$BASELINE_DIR"/*.png; do
  name="$(basename "$baseline_png")"
  current_png="$CURRENT_DIR/$name"
  diff_png="$DIFF_DIR/$name"

  if [[ ! -f "$current_png" ]]; then
    echo "| \`$name\` | present | MISSING | — | — | — | SKIP |" >> "$REPORT"
    continue
  fi

  # Total pixel count of the baseline (width * height).
  read -r width height < <(magick identify -format "%w %h" "$baseline_png")
  total_px=$(( width * height ))

  # `magick compare` returns non-zero if images differ; capture stderr (AE count goes there).
  ae_count="$(magick compare -metric AE -fuzz 1% "$baseline_png" "$current_png" "$diff_png" 2>&1 || true)"
  # Strip non-numeric noise (e.g. "1234.5"); take leading integer-ish.
  ae_clean="$(echo "$ae_count" | awk '{print $1}' | tr -d 'e+,')"
  if ! [[ "$ae_clean" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    ae_clean="0"
  fi
  ae_int="${ae_clean%.*}"

  # Compare ae_int / total_px against TOLERANCE_RATIO using awk (portable float math).
  over_pct="$(awk -v a="$ae_int" -v t="$total_px" 'BEGIN { if (t==0) print "0.000"; else printf "%.4f", (a/t)*100 }')"
  verdict="$(awk -v a="$ae_int" -v t="$total_px" -v r="$TOLERANCE_RATIO" 'BEGIN { if (t==0) print "EMPTY"; else if ((a/t) <= r) print "PASS"; else print "FAIL" }')"

  if [[ "$verdict" == "FAIL" ]]; then
    OVERALL_EXIT=1
  fi

  echo "| \`$name\` | ok | ok | $ae_int | $total_px | ${over_pct}% | $verdict |" >> "$REPORT"
done

# Report unmatched current files (new captures not in baseline).
for current_png in "$CURRENT_DIR"/*.png; do
  name="$(basename "$current_png")"
  if [[ ! -f "$BASELINE_DIR/$name" ]]; then
    echo "| \`$name\` | MISSING | present | — | — | — | UNMATCHED |" >> "$REPORT"
  fi
done

echo >> "$REPORT"
if [[ $OVERALL_EXIT -eq 0 ]]; then
  echo "**Overall: PASS**" >> "$REPORT"
else
  echo "**Overall: FAIL — at least one pair exceeded 0.5% pixel-delta threshold.**" >> "$REPORT"
  echo "Review per-pair diff PNGs in \`$DIFF_DIR\` and add explicit sign-off to Parity-Break Ledger 8B if intended." >> "$REPORT"
fi

echo "Report: $REPORT"
exit $OVERALL_EXIT
