#!/bin/bash
# Runs launch-oriented verification for the local macOS app bundle.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/QuickHacks.app"
PLIST="$APP/Contents/Info.plist"
ICON="$APP/Contents/Resources/QuickHacks.icns"

cd "$ROOT"

echo "==> Strict Swift build"
swift build -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors

echo "==> Unit tests"
swift test

echo "==> App bundle"
"$ROOT/Scripts/build-app.sh"

echo "==> Bundle metadata"
plutil -lint "$ROOT/Resources/Info.plist" "$PLIST"
/usr/libexec/PlistBuddy -c "Print :CFBundleIconFile" "$PLIST" | grep -qx "QuickHacks"
/usr/libexec/PlistBuddy -c "Print :LSUIElement" "$PLIST" | grep -qx "true"

echo "==> Icon asset"
[ -f "$ICON" ] || { echo "Missing icon: $ICON" >&2; exit 1; }
sips -g format "$ICON" >/dev/null

echo "==> Code signature"
codesign --verify --deep --strict --verbose=2 "$APP"

echo "==> Launch verification passed"
