#!/bin/bash
# Force-quit emulator apps when on battery power and charge is at/below THRESHOLD.
# Invoked periodically by the LaunchAgent com.user.lowbattery.emulator.

THRESHOLD=20
LOG="$HOME/Library/Logs/low-battery-quit-emulator.log"

batt="$(/usr/bin/pmset -g batt)"

# Only act when actually running on battery (not charging / on AC).
echo "$batt" | grep -q "Battery Power" || exit 0

# Extract the integer percentage (e.g. "65%").
pct="$(echo "$batt" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')"
[ -z "$pct" ] && exit 0

# Confirm we're discharging, not plugged in.
echo "$batt" | grep -q "discharging" || exit 0

if [ "$pct" -le "$THRESHOLD" ]; then
    quit=""

    # iOS Simulator (Xcode)
    if /usr/bin/pgrep -x Simulator >/dev/null 2>&1; then
        /usr/bin/osascript -e 'tell application "Simulator" to quit' 2>/dev/null
        /usr/bin/pkill -x Simulator 2>/dev/null
        quit="$quit iOS-Simulator"
    fi

    # Android Emulator (Android Studio / AVD): emulator launcher + qemu backend
    if /usr/bin/pgrep -fl 'qemu-system|/emulator|Android Emulator' >/dev/null 2>&1; then
        /usr/bin/pkill -f 'qemu-system' 2>/dev/null
        /usr/bin/pkill -f '/emulator' 2>/dev/null
        /usr/bin/pkill -f 'Android Emulator' 2>/dev/null
        quit="$quit Android-Emulator"
    fi

    if [ -n "$quit" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') battery ${pct}% (<=${THRESHOLD}%) — quit:${quit}" >> "$LOG"
    fi
fi
