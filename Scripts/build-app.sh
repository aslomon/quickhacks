#!/bin/bash
# Builds QuickHacks.app from the Swift package (release config, ad-hoc signed).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/QuickHacks.app"

echo "==> swift build (release)"
swift build -c release --package-path "$ROOT"

BINARY="$ROOT/.build/release/QuickHacks"
[ -f "$BINARY" ] || { echo "Binary not found: $BINARY" >&2; exit 1; }

echo "==> Generating app icon"
"$ROOT/Scripts/generate-icons.sh"

echo "==> Assembling app bundle"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BINARY" "$APP/Contents/MacOS/QuickHacks"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Resources/QuickHacks.icns" "$APP/Contents/Resources/QuickHacks.icns"

echo "==> Code signing (ad-hoc)"
codesign --force --options runtime --sign - "$APP"

echo "==> Done: $APP"
