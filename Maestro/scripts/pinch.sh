#!/usr/bin/env bash
# pinch.sh — perform a pinch gesture on the iOS Simulator window using
# cliclick + Option key (the Simulator's secondary-touch modifier).
#
# Usage:
#   ./pinch.sh in      # pinch in (chat-rest → cell-list)
#   ./pinch.sh out     # pinch out (cell-rest → chat-rest)
#
# Mechanism:
#   Option-drag in the Simulator creates a multi-touch pinch gesture pivoting
#   around the cursor's start position. Two touch points appear symmetrically
#   around the cursor and move outward (out) or inward (in) based on drag direction.
#
# Coordinates: relative to the global screen, NOT the Simulator window.
# The Simulator window's content is determined at runtime via window bounds.

set -e

DIRECTION="${1:-in}"

# Get the Simulator window's bounds. AppleScript returns "x, y, w, h" of the
# Simulator app's frontmost window content area.
WINDOW_BOUNDS=$(osascript -e '
tell application "System Events"
    tell process "Simulator"
        if exists window 1 then
            set bnds to position of window 1
            set sz to size of window 1
            return (item 1 of bnds as string) & "," & (item 2 of bnds as string) & "," & (item 1 of sz as string) & "," & (item 2 of sz as string)
        end if
    end tell
end tell
' 2>/dev/null)

if [ -z "$WINDOW_BOUNDS" ]; then
    echo "Error: could not locate Simulator window. Make sure Simulator.app is running."
    exit 1
fi

WX=$(echo "$WINDOW_BOUNDS" | cut -d, -f1)
WY=$(echo "$WINDOW_BOUNDS" | cut -d, -f2)
WW=$(echo "$WINDOW_BOUNDS" | cut -d, -f3)
WH=$(echo "$WINDOW_BOUNDS" | cut -d, -f4)

# Center of the Simulator window
CX=$((WX + WW / 2))
CY=$((WY + WH / 2))

# Drag offsets — pinch IN starts from edges and drags toward center;
# pinch OUT starts at center and drags outward.
DELTA=120

if [ "$DIRECTION" = "in" ]; then
    START_X=$((CX + DELTA))
    START_Y=$((CY + DELTA))
    END_X=$CX
    END_Y=$CY
elif [ "$DIRECTION" = "out" ]; then
    START_X=$CX
    START_Y=$CY
    END_X=$((CX + DELTA))
    END_Y=$((CY + DELTA))
else
    echo "Error: direction must be 'in' or 'out'"
    exit 1
fi

# Move to start, then option+drag to end. cliclick:
#   m:x,y   — move mouse to x,y
#   kd:alt  — key down alt (option)
#   dd:x,y  — drag down (start) at x,y
#   c:x,y   — click at x,y
#   du:x,y  — drag up (end) at x,y
#   ku:alt  — key up alt
#
# Sequence: move to start → option-down → drag-down → drag-update → drag-up → option-up

cliclick m:"${START_X},${START_Y}"
sleep 0.1
cliclick kd:alt
sleep 0.1
cliclick dd:"${START_X},${START_Y}"
sleep 0.1
# Intermediate moves for smoothness
MID_X=$(( (START_X + END_X) / 2 ))
MID_Y=$(( (START_Y + END_Y) / 2 ))
cliclick m:"${MID_X},${MID_Y}"
sleep 0.1
cliclick m:"${END_X},${END_Y}"
sleep 0.1
cliclick du:"${END_X},${END_Y}"
sleep 0.1
cliclick ku:alt

echo "Pinch ${DIRECTION} complete (start=${START_X},${START_Y} end=${END_X},${END_Y})"
