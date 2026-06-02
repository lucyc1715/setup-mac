#!/bin/bash
# Build ~/Library/Scripts/LowBatteryMinion.app — a copy of terminal-notifier
# whose main icon is minions-bob.png and whose bundle id is unique, so the
# low-battery notifications show the minion as their MAIN (left) icon.
#
# macOS blocks terminal-notifier's -appIcon, so the only reliable way to set
# the main icon is to post from an app bundle that *has* that icon. This builds
# such a bundle on the current machine (matching its CPU arch), so it travels
# with the repo without committing a binary.
#
# Idempotent and safe to re-run. No-op (exits 0) if terminal-notifier, the
# image, or codesign is unavailable, so deploy never fails because of it.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ICON_PNG="$SCRIPT_DIR/minions-bob.png"
DST="$HOME/Library/Scripts/LowBatteryMinion.app"
BUNDLE_ID="com.user.lowbattery.minion"

# Locate the installed terminal-notifier.app (Apple Silicon / Intel brew paths).
SRC=""
if command -v brew >/dev/null 2>&1; then
    SRC="$(brew --prefix terminal-notifier 2>/dev/null)/terminal-notifier.app"
fi
[ -d "$SRC" ] || SRC="/opt/homebrew/opt/terminal-notifier/terminal-notifier.app"
[ -d "$SRC" ] || SRC="/usr/local/opt/terminal-notifier/terminal-notifier.app"

[ -d "$SRC" ]      || { echo "（找不到 terminal-notifier.app，略過小小兵 app）"; exit 0; }
[ -f "$ICON_PNG" ] || { echo "（找不到 minions-bob.png，略過小小兵 app）"; exit 0; }
command -v codesign >/dev/null 2>&1 || { echo "（沒有 codesign / Xcode CLT，略過小小兵 app）"; exit 0; }

# Idempotency: if the app already exists and the source image hasn't changed,
# DON'T rebuild. Rebuilding re-signs the bundle, which can make macOS reset the
# user's notification authorization (System Settings > Notifications). Skipping
# keeps that permission stable. To force a rebuild, replace minions-bob.png or
# delete LowBatteryMinion.app first.
EXISTING_ICNS="$(ls "$DST"/Contents/Resources/*.icns 2>/dev/null | head -1)"
if [ -n "$EXISTING_ICNS" ] && [ ! "$ICON_PNG" -nt "$EXISTING_ICNS" ]; then
    echo "小小兵 app 已存在且圖未更新，略過重建（保留通知授權）"
    exit 0
fi

rm -rf "$DST"
cp -R "$SRC" "$DST"

# Overwrite whatever icon the bundle declares (CFBundleIconFile, e.g. "Terminal").
ICON_NAME="$(plutil -extract CFBundleIconFile raw "$DST/Contents/Info.plist" 2>/dev/null || echo Terminal)"
sips -s format icns "$ICON_PNG" --out "$DST/Contents/Resources/${ICON_NAME}.icns" >/dev/null

# Unique bundle id (fresh notification-icon cache) + friendly display name.
plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" "$DST/Contents/Info.plist"
plutil -replace CFBundleName -string "電量提醒" "$DST/Contents/Info.plist"

# Re-sign ad-hoc — required on Apple Silicon after editing a signed bundle,
# otherwise macOS kills it on launch.
codesign --force --deep --sign - "$DST" >/dev/null 2>&1 || true

# Register with Launch Services so the icon resolves immediately.
LSREG="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
[ -x "$LSREG" ] && "$LSREG" -f "$DST" >/dev/null 2>&1 || true

echo "已建立小小兵通知 app：$DST"
