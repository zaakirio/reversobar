#!/bin/bash
# Builds Reversobar.app: a universal (arm64 + x86_64), menu-bar-only macOS app bundle,
# code-signed with hardened runtime. Uses a Developer ID identity when available
# (override with REVERSOBAR_SIGN_ID), otherwise falls back to an ad-hoc signature.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/common.sh

APP="build/Reversobar.app"
BUNDLE_ID="com.zaakir.reversobar"

resolve_sign_id
echo "▶ Signing identity: $SIGN_ID"

# --- Build a universal release binary ------------------------------------------
# (Build each slice separately and lipo them — SwiftPM's combined multi-arch build
#  is buggy and emits "duplicate output file" errors.)
echo "▶ Building arm64…"
swift build -c release --arch arm64
ARM_DIR="$(swift build -c release --arch arm64 --show-bin-path)"
echo "▶ Building x86_64…"
swift build -c release --arch x86_64
X86_DIR="$(swift build -c release --arch x86_64 --show-bin-path)"

# --- Assemble the .app bundle ---------------------------------------------------
echo "▶ Assembling ${APP}…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
lipo -create "$ARM_DIR/Reversobar" "$X86_DIR/Reversobar" -output "$APP/Contents/MacOS/Reversobar"

# SwiftPM resource bundle (flags, architecture-independent) — required for Bundle.module.
for bundle in "$ARM_DIR"/*.bundle; do
    [[ -e "$bundle" ]] && cp -R "$bundle" "$APP/Contents/Resources/"
done

# App icon
[[ -f tools/assets/AppIcon.icns ]] && cp tools/assets/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Reversobar</string>
    <key>CFBundleDisplayName</key><string>Reversobar</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key><string>$BUILD</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleExecutable</key><string>Reversobar</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
    <key>NSHumanReadableCopyright</key><string>© 2026 Reversobar. Translations by Reverso.</string>
</dict>
</plist>
PLIST

# --- Code sign (inner-to-outer; no entitlements needed — not sandboxed) ---------
SIGN_ARGS=(--force --sign "$SIGN_ID")
if [[ "$SIGN_ID" != "-" ]]; then
    SIGN_ARGS+=(--options runtime --timestamp)   # hardened runtime, required for notarization
fi
# The SwiftPM resource bundle holds only PNGs (no Mach-O), so it isn't signed separately —
# it's sealed into the app's signature as a resource.
echo "▶ Signing…"
codesign "${SIGN_ARGS[@]}" "$APP"

echo "▶ Verifying signature…"
codesign --verify --strict --verbose=2 "$APP"
echo
echo "✅ Built $(pwd)/$APP  (v$VERSION build $BUILD)"
file "$APP/Contents/MacOS/Reversobar" | sed 's/^/   /'
# (Plain `[[ ... ]] && echo` as the last command would make the script exit 1 when signed.)
if [[ "$SIGN_ID" == "-" ]]; then
    echo "   ⚠️  ad-hoc signed — for distribution set REVERSOBAR_SIGN_ID and run scripts/release.sh"
fi
