#!/bin/bash
# Notarizes and staples a .app or .dmg via Apple's notary service.
#
# Credentials come from a keychain profile (recommended). Create it once with:
#   xcrun notarytool store-credentials reversobar \
#     --apple-id "you@example.com" --team-id <your-team-id> --password <app-specific-password>
# then export REVERSOBAR_NOTARY_PROFILE=reversobar (or pass nothing — "reversobar" is the default).
set -euo pipefail
cd "$(dirname "$0")/.."

TARGET="${1:-build/Reversobar.app}"
PROFILE="${REVERSOBAR_NOTARY_PROFILE:-reversobar}"

if [[ ! -e "$TARGET" ]]; then echo "❌ not found: $TARGET"; exit 1; fi

submit() {
    echo "▶ Submitting $(basename "$1") to the notary service (this can take a few minutes)…"
    xcrun notarytool submit "$1" --keychain-profile "$PROFILE" --wait
}

case "$TARGET" in
    *.app)
        ZIP="build/$(basename "$TARGET" .app)-notarize.zip"
        echo "▶ Zipping app for submission…"
        ditto -c -k --sequesterRsrc --keepParent "$TARGET" "$ZIP"
        submit "$ZIP"
        echo "▶ Stapling ticket to the app…"
        xcrun stapler staple "$TARGET"
        rm -f "$ZIP"
        ;;
    *.dmg)
        submit "$TARGET"
        echo "▶ Stapling ticket to the disk image…"
        xcrun stapler staple "$TARGET"
        ;;
    *)
        echo "❌ unsupported target (expected .app or .dmg): $TARGET"; exit 1 ;;
esac

echo "▶ Verifying with Gatekeeper…"
if [[ "$TARGET" == *.dmg ]]; then
    spctl --assess --type open --context context:primary-signature --verbose "$TARGET"
else
    spctl --assess --type execute --verbose "$TARGET"
fi
echo "✅ Notarized & stapled: $TARGET"
