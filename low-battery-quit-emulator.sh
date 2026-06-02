#!/bin/bash
# Low-battery helper, invoked every 60s by the LaunchAgent
# com.user.lowbattery.emulator. While running on battery and discharging:
#   - at <= WARN_THRESHOLD : notify "remember to plug in" (once per discharge)
#   - at <= CRIT_THRESHOLD : quit emulators + notify (once per discharge)
# Flags live in STATE_DIR and are cleared whenever power is reconnected, so
# each fresh discharge cycle notifies again. Never sleeps the Mac.

WARN_THRESHOLD=30
CRIT_THRESHOLD=20

LOG="$HOME/Library/Logs/low-battery-quit-emulator.log"
STATE_DIR="$HOME/Library/Caches/com.user.lowbattery.emulator"
WARN_FLAG="$STATE_DIR/warned-${WARN_THRESHOLD}"
CRIT_FLAG="$STATE_DIR/warned-${CRIT_THRESHOLD}"

mkdir -p "$STATE_DIR"

# Notification backend, best first:
#   1. LowBatteryMinion.app  — terminal-notifier copy whose MAIN icon is the
#      minion (built by build-minion-notifier.sh during deploy).
#   2. plain terminal-notifier — minion shown as a side image (-contentImage).
#   3. osascript            — built-in fallback, no custom image.
SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
ICON="$SCRIPT_DIR/minions-bob.png"
APP_BIN="$HOME/Library/Scripts/LowBatteryMinion.app/Contents/MacOS/terminal-notifier"

TN=""
for p in "$APP_BIN" /opt/homebrew/bin/terminal-notifier /usr/local/bin/terminal-notifier; do
    [ -x "$p" ] && TN="$p" && break
done

notify() {
    # $1 = title, $2 = subtitle, $3 = message
    if [ -n "$TN" ]; then
        img_args=()
        # Only add a side image when NOT using the minion app (which already
        # shows the minion as its main icon — no need to show it twice).
        [ "$TN" != "$APP_BIN" ] && [ -f "$ICON" ] && img_args=(-contentImage "$ICON")
        "$TN" -title "$1" -subtitle "$2" -message "$3" \
              -sound Glass -group com.user.lowbattery.emulator \
              "${img_args[@]}" >/dev/null 2>&1
    else
        /usr/bin/osascript -e "display notification \"$3\" with title \"$1\" subtitle \"$2\" sound name \"Glass\"" 2>/dev/null
    fi
}

batt="$(/usr/bin/pmset -g batt)"

# Reset state whenever we're NOT discharging on battery (AC / charging / charged),
# so the next time we drop onto battery the reminders fire again.
if ! echo "$batt" | grep -q "Battery Power" || ! echo "$batt" | grep -q "discharging"; then
    rm -f "$WARN_FLAG" "$CRIT_FLAG"
    exit 0
fi

# Extract the integer percentage (e.g. "65%").
pct="$(echo "$batt" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')"
[ -z "$pct" ] && exit 0

if [ "$pct" -le "$CRIT_THRESHOLD" ]; then
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
        echo "$(date '+%Y-%m-%d %H:%M:%S') battery ${pct}% (<=${CRIT_THRESHOLD}%) — quit:${quit}" >> "$LOG"
    fi

    # Notify once per discharge cycle.
    if [ ! -f "$CRIT_FLAG" ]; then
        if [ -n "$quit" ]; then
            notify "🔋 電量過低" "目前 ${pct}%" "已自動關閉模擬器：${quit}。請盡快接上電源。"
        else
            notify "🔋 電量過低" "目前 ${pct}%" "請盡快接上電源。"
        fi
        touch "$CRIT_FLAG"
    fi

elif [ "$pct" -le "$WARN_THRESHOLD" ]; then
    # Early heads-up, once per discharge cycle.
    if [ ! -f "$WARN_FLAG" ]; then
        notify "🔋 電量偏低" "目前 ${pct}%" "記得接上電源。低於 ${CRIT_THRESHOLD}% 時會自動關閉模擬器。"
        touch "$WARN_FLAG"
    fi
fi
