#!/bin/bash
# Builds a GitHub Release ZIP for QuickHacks.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/QuickHacks.app"
DIST="$ROOT/dist"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Resources/Info.plist")"
ARCHIVE_NAME="QuickHacks-v$VERSION"
STAGING="$DIST/$ARCHIVE_NAME"
ZIP_PATH="$DIST/$ARCHIVE_NAME.zip"

rm -rf "$STAGING"
mkdir -p "$STAGING" "$DIST"

"$ROOT/Scripts/build-app.sh"

cp -R "$APP" "$STAGING/QuickHacks.app"
cat > "$STAGING/README-FIRST.txt" <<EOF
QuickHacks v$VERSION

QuickHacks is a macOS menu bar utility for small everyday system tweaks:
declutter the menu bar, keep the Mac awake, block unwanted Bluetooth devices,
and run quick Finder/Dock toggles.

Install:
1. Move QuickHacks.app to your Applications folder.
2. Open QuickHacks.app.
3. If macOS warns that the app cannot be verified, Control-click the app,
   choose Open, then confirm.

Important:
This GitHub build is ad-hoc signed and is not notarized yet. That means macOS
may show extra security prompts. A notarized Developer ID build is planned.

Permissions:
- Bluetooth: lists paired devices and enforces the blocklist.
- Accessibility: opens other menu bar apps from the QuickHacks panel.
- Finder Automation: ejects disks and empties Trash.

Project:
https://github.com/aslomon/quickhacks
EOF

cat > "$DIST/RELEASE_NOTES.md" <<EOF
QuickHacks v$VERSION

This release includes a macOS app bundle packaged as a ZIP.

Note: This build is ad-hoc signed and not notarized yet. macOS may require
Control-click > Open the first time you launch it.
EOF

(
  cd "$DIST"
  rm -f "$ZIP_PATH"
  COPYFILE_DISABLE=1 ditto -c -k --norsrc --keepParent "$ARCHIVE_NAME" "$ZIP_PATH"
)

echo "Created $ZIP_PATH"
