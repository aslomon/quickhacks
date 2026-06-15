#!/bin/bash
# Generates the macOS app icon from the SVG master asset.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/Resources/AppIcon.svg"
ICONSET="$ROOT/.build/generated-icons/QuickHacks.iconset"
OUTPUT="$ROOT/Resources/QuickHacks.icns"

[ -f "$SOURCE" ] || { echo "Icon source not found: $SOURCE" >&2; exit 1; }

rm -rf "$ICONSET"
mkdir -p "$ICONSET"

generate_png() {
  local points="$1"
  local scale="$2"
  local pixels=$((points * scale))
  local suffix=""
  if [ "$scale" -eq 2 ]; then
    suffix="@2x"
  fi

  sips -s format png -z "$pixels" "$pixels" "$SOURCE" \
    --out "$ICONSET/icon_${points}x${points}${suffix}.png" >/dev/null
}

for points in 16 32 128 256 512; do
  generate_png "$points" 1
  generate_png "$points" 2
done

iconutil -c icns -o "$OUTPUT" "$ICONSET"
echo "Generated $OUTPUT"
