#!/usr/bin/env bash
# Orchestrates every gate that defends the nine refusals.
# Order matters: cheapest checks first, so PRs that violate a grep gate fail
# in seconds rather than waiting on a simulator boot.
#
#   1. static — grep gates (zero forbidden API usage)
#   2. build  — clean build for iPhone 16 simulator (iOS 18, per project_maestro_ios26_incompat)
#   3. ui     — XCUITest target running the nine refusal tests
#
# Any non-zero exit short-circuits the run.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

SCHEME="DotPinchPrototype"
PROJECT="DotPinchPrototype.xcodeproj"
DESTINATION='platform=iOS Simulator,name=iPhone 16,OS=18.2'
DERIVED="$ROOT/build/ci-derived"
RESULT="$ROOT/build/ci-result.xcresult"

echo "──────────────  1/3  grep gates  ──────────────"
bash "$ROOT/scripts/ci/grep_gates.sh"

echo "──────────────  2/3  build         ──────────────"
xcodebuild \
  -project "$PROJECT" \
  -scheme  "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED" \
  -quiet \
  build-for-testing

echo "──────────────  3/3  XCUITest refusals  ────────"
rm -rf "$RESULT"
xcodebuild \
  -project "$PROJECT" \
  -scheme  "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED" \
  -resultBundlePath "$RESULT" \
  -only-testing:DotPinchPrototypeUITests/DepthCueRefusalTests \
  test-without-building

echo
echo "ALL DEPTH-CUE GATES PASSED — 9/9 refusals enforced"
