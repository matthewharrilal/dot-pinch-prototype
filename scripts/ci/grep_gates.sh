#!/usr/bin/env bash
# Grep gates — static enforcement of the nine refusals from /tmp/depth_cue_audit.md.
# Any positive match in the watched scopes fails the gate. Comments are stripped
# before matching so that doc strings referencing forbidden APIs (e.g. "we refuse
# CATransform3DRotate") do not trigger false positives.
#
# Each gate prints PASS/FAIL with the refusal number and a brief rationale. The
# script exits non-zero on the first failure (set -e) so CI surfaces the gate.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DEMO="$ROOT/DotPinchPrototype/Demo"
INTER="$ROOT/DotPinchPrototype/Interaction"
SRC="$DEMO $INTER"

FAIL=0
pass() { printf "  PASS  refusal #%s — %s\n" "$1" "$2"; }
fail() { printf "  FAIL  refusal #%s — %s\n" "$1" "$2"; FAIL=1; }

# Strip // line comments and /* ... */ block comments before grepping. Forbidden
# tokens are allowed in commentary (the code must be legible AS the audit) but
# not in executable source.
strip_comments() {
  # shellcheck disable=SC2016
  perl -0777 -pe 's{//[^\n]*}{}g; s{/\*.*?\*/}{}gs' "$1"
}

scan() {  # scan <pattern> <scope> -> 0 if clean, 1 if any hit
  local pattern="$1"; shift
  local hit=0
  for dir in "$@"; do
    while IFS= read -r -d '' f; do
      if strip_comments "$f" | grep -nE "$pattern" >/dev/null; then
        hit=1
        printf "    %s\n" "$f"
        strip_comments "$f" | grep -nE "$pattern" | sed 's/^/      /'
      fi
    done < <(find "$dir" -name '*.swift' -print0)
  done
  return $hit
}

echo "Depth-cue refusal grep gates"
echo "scope: $SRC"
echo

# Refusal #1 (foreshortening) and #6 (vanishing point): no 3D matrix anywhere.
# m34, CATransform3DRotate, and sublayerTransform all open the door to
# perspective. The transform must be a 2D affine uniform scale.
scan '\bm34\b|CATransform3DRotate|sublayerTransform' $SRC \
  && pass 1+6 "no m34/CATransform3DRotate/sublayerTransform" \
  || fail 1+6 "3D perspective primitive present in Demo/Interaction"

# Refusal #2 (atmospheric depth): no animation of backgroundColor or alpha along
# the transition path. Photometric properties are locked.
scan 'UIView\.animate[^}]{0,400}\b(backgroundColor|alpha)\b' $SRC \
  && pass 2 "no UIView.animate of backgroundColor/alpha in transition path" \
  || fail 2 "photometric animation found in transition path"

# Refusal #3 (parallax) and #7 (camera pull-back): chrome (the surround) is
# stationary. Frame/transform/center may only be written from init or layout
# methods; never from gesture/animation callbacks.
chrome_assign='\b(chromeView|surroundView|backgroundView)\b\.(frame|transform|center|bounds)\s*='
for dir in $SRC; do
  while IFS= read -r -d '' f; do
    # Walk the file and gather chrome assignments NOT inside init/layout scopes.
    # Heuristic: flag any chrome assignment whose nearest preceding `func` is
    # not init/layoutSubviews/updateConstraints.
    awk -v file="$f" '
      /func[[:space:]]+(init|layoutSubviews|updateConstraints|viewDidLayoutSubviews)\b/ { ok=1; next }
      /^[[:space:]]*(init|deinit)\b/ { ok=1; next }
      /func[[:space:]]+[a-zA-Z_]/ { ok=0 }
      /'"$chrome_assign"'/ {
        if (!ok) { printf "    %s:%d: %s\n", file, NR, $0; found=1 }
      }
      END { exit found?1:0 }
    ' "$f" || { fail 3+7 "chrome frame/transform assigned outside init/layout in $f"; }
  done < <(find "$dir" -name '*.swift' -print0)
done
[ $FAIL -eq 0 ] && pass 3+7 "chrome geometry only written from init/layout"

# Refusal #4 (shadow as binary state): setTimelineCompression must not assign
# shadowOpacity. Shadow is a destination-only signal, not a continuous function
# of progress.
for f in $(find $SRC -name '*.swift'); do
  awk '
    /func[[:space:]]+setTimelineCompression\b/ { in=1; depth=0; next }
    in { for(i=1;i<=length($0);i++){c=substr($0,i,1); if(c=="{")depth++; else if(c=="}"){depth--; if(depth<0){in=0}}}
         if (match($0, /shadowOpacity[[:space:]]*=/)) { print FILENAME":"NR": "$0; bad=1 } }
    END { exit bad?1:0 }
  ' "$f" || fail 4 "shadowOpacity assigned inside setTimelineCompression in $f"
done
[ $FAIL -eq 0 ] && pass 4 "shadowOpacity not driven by setTimelineCompression"

# Refusal #5 (edge-priority blur): card files use no CIFilter, no CALayer mask,
# no radial gradient. The only blur permitted is a uniform full-field UIBlurEffect.
scan 'CIFilter|\.mask\s*=|radialGradient|CAGradientLayer.*type.*radial' \
  "$DEMO/ConversationContentView.swift" \
  && pass 5 "no CIFilter/mask/radialGradient in card files" \
  || fail 5 "edge-priority blur primitive found in card subtree"

# Refusal #8 (z-order preserved): no view-hierarchy reordering inside gesture
# handlers. zPosition writes are also banned in gesture paths.
gesture_z='\b(bringSubviewToFront|sendSubviewToBack|insertSubview|exchangeSubview)|\bzPosition\s*='
for f in $(find $SRC -name '*.swift'); do
  awk '
    /func[[:space:]]+handle.*Gesture|@objc[[:space:]]+func[[:space:]]+pinch|func[[:space:]]+(began|changed|ended)\b/ { g=1; depth=0; next }
    g { for(i=1;i<=length($0);i++){c=substr($0,i,1); if(c=="{")depth++; else if(c=="}"){depth--; if(depth<0){g=0}}}
        if (match($0, /'"$gesture_z"'/)) { print FILENAME":"NR": "$0; bad=1 } }
    END { exit bad?1:0 }
  ' "$f" || fail 8 "z-order mutation in gesture path of $f"
done
[ $FAIL -eq 0 ] && pass 8 "stacking order untouched by gesture handlers"

# Refusal #9 (no specular): card subtree contains no CAGradientLayer at all.
# A gradient on the card surface is the only realistic way to fake a specular
# highlight in UIKit; banning the primitive bans the cue.
scan 'CAGradientLayer' "$DEMO/ConversationContentView.swift" \
  && pass 9 "no CAGradientLayer in card subtree" \
  || fail 9 "CAGradientLayer present in card subtree"

echo
if [ $FAIL -ne 0 ]; then
  echo "GREP GATES FAILED"
  exit 1
fi
echo "GREP GATES PASSED"
