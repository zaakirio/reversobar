#!/bin/bash
# Packages build/Reversobar.app into a distributable, signed DMG with an /Applications shortcut.
set -euo pipefail
cd "$(dirname "$0")/.."

APP="build/Reversobar.app"
VERSION="${REVERSOBAR_VERSION:-1.0.0}"
DMG="build/Reversobar-$VERSION.dmg"

if [[ ! -d "$APP" ]]; then echo "❌ $APP not found — run scripts/build_app.sh first"; exit 1; fi

STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

echo "▶ Creating ${DMG}…"
rm -f "$DMG"
hdiutil create -volname "Reversobar" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

# Sign the DMG with the same identity used for the app (if not ad-hoc).
SIGN_ID="${REVERSOBAR_SIGN_ID:-$(security find-identity -v -p codesigning 2>/dev/null \
    | grep -m1 'Developer ID Application' | sed -E 's/.*"(.*)"/\1/' || true)}"
if [[ -n "$SIGN_ID" && "$SIGN_ID" != "-" ]]; then
    echo "▶ Signing DMG…"
    codesign --force --sign "$SIGN_ID" --timestamp "$DMG"
fi

echo "✅ Created $(pwd)/$DMG ($(du -h "$DMG" | cut -f1))"
