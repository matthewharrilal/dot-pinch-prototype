#!/usr/bin/env bash
# Run Maestro flows against the iOS 18.0 simulator (iPhone 16) with AI Insights enabled.
#
# Why iOS 18 and not 26: Maestro 2.5.1 is incompatible with iOS 26+ simulators
# (a11y tree returns empty). Documented in dot-pinch-lens-check/STATUS.md.
#
# Usage:
#   ./scripts/run-maestro.sh                       # run all flows in .maestro/
#   ./scripts/run-maestro.sh .maestro/smoke.yaml   # run just one flow

set -euo pipefail

# Point JAVA_HOME at the homebrew openjdk@17 install (Maestro requires JRE).
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17}"
export PATH="$JAVA_HOME/bin:$PATH"

# The iOS 18 simulator UDID. If yours differs, override via:
#   IOS18_SIM_UDID=<your-udid> ./scripts/run-maestro.sh
SIM_UDID="${IOS18_SIM_UDID:-C149C833-D1F6-4187-A202-89B2073D98A9}"

# Boot the simulator if not running.
xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
open -a Simulator

# Build + install the app on the sim.
xcodebuild \
  -project DotPinchPrototype.xcodeproj \
  -scheme DotPinchPrototype \
  -destination "platform=iOS Simulator,id=$SIM_UDID" \
  -configuration Debug \
  -derivedDataPath build/ \
  build | tail -3

APP_PATH=$(find build/Build/Products/Debug-iphonesimulator -name "DotPinchPrototype.app" -type d | head -1)
if [[ -z "$APP_PATH" ]]; then
  echo "ERROR: built app not found"
  exit 1
fi
xcrun simctl install "$SIM_UDID" "$APP_PATH"

# Run Maestro flows. The --analyze flag enables AI Insights (Maestro Cloud account
# required if you want full analysis; without an API key the local run still works
# and you get a basic report). To attach an API key:
#   MAESTRO_API_KEY=<your-key> ./scripts/run-maestro.sh
EXTRA_ARGS=()
if [[ -n "${MAESTRO_API_KEY:-}" ]]; then
  EXTRA_ARGS+=("--api-key=$MAESTRO_API_KEY")
fi

FLOWS="${1:-.maestro}"

maestro \
  --udid "$SIM_UDID" \
  test \
  --analyze \
  --format HTML-DETAILED \
  --test-output-dir .maestro/.report \
  "${EXTRA_ARGS[@]}" \
  "$FLOWS"
