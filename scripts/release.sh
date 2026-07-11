#!/bin/bash
# Full distribution pipeline: build → notarize app → package ZIP + DMG → notarize DMG.
# Produces a signed, notarized ZIP (the primary download) and a stapled DMG,
# both of which open cleanly on any Mac.
#
# Prerequisites:
#   • A "Developer ID Application" certificate in your keychain (auto-detected,
#     or set REVERSOBAR_SIGN_ID).
#   • A notary keychain profile (see scripts/notarize.sh header), default name "reversobar".
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/common.sh

# Fail fast: an ad-hoc build would only be rejected by the notary service minutes later.
resolve_sign_id
if [[ "$SIGN_ID" == "-" ]]; then
    echo "❌ No Developer ID Application certificate found — a release must be signed."
    echo "   Install one (or set REVERSOBAR_SIGN_ID) and retry."
    exit 1
fi

echo "═══ 1/5  Build & sign universal app ═══"
scripts/build_app.sh

echo; echo "═══ 2/5  Notarize & staple the app ═══"
scripts/notarize.sh build/Reversobar.app

echo; echo "═══ 3/5  Package ZIP (primary download) ═══"
ZIP="build/Reversobar-$VERSION.zip"
rm -f "$ZIP"
ditto -c -k --sequesterRsrc --keepParent build/Reversobar.app "$ZIP"
echo "✅ Created $ZIP ($(du -h "$ZIP" | cut -f1))"

echo; echo "═══ 4/5  Package DMG ═══"
scripts/make_dmg.sh

echo; echo "═══ 5/5  Notarize & staple the DMG ═══"
scripts/notarize.sh "build/Reversobar-$VERSION.dmg"

echo; echo "🎉 Release ready:"
echo "   build/Reversobar-$VERSION.zip  — primary download (stapled app inside)"
echo "   build/Reversobar-$VERSION.dmg  — drag-to-Applications alternative"
