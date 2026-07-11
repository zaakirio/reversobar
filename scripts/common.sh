# Shared helpers for the packaging scripts. Source this — do not execute it.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Single source of truth for the release version: the VERSION file at the repo root,
# overridable per-invocation with REVERSOBAR_VERSION.
VERSION="${REVERSOBAR_VERSION:-$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")}"
BUILD="${REVERSOBAR_BUILD:-1}"

# Resolves the codesigning identity into SIGN_ID.
# Precedence: REVERSOBAR_SIGN_ID, else the sole "Developer ID Application" certificate
# in the keychain, else "-" (ad-hoc). More than one matching certificate is ambiguous —
# picking one silently could sign with the wrong team, so it is a hard error.
resolve_sign_id() {
    if [[ -n "${REVERSOBAR_SIGN_ID:-}" ]]; then
        SIGN_ID="$REVERSOBAR_SIGN_ID"
        return
    fi
    local matches
    matches="$(security find-identity -v -p codesigning 2>/dev/null \
        | grep 'Developer ID Application' | sed -E 's/.*"(.*)"/\1/' || true)"
    if [[ "$(printf '%s\n' "$matches" | grep -c .)" -gt 1 ]]; then
        echo "❌ Multiple Developer ID Application certificates found — set REVERSOBAR_SIGN_ID to one of:" >&2
        printf '%s\n' "$matches" | sed 's/^/   /' >&2
        exit 1
    fi
    SIGN_ID="${matches:--}"   # ad-hoc fallback when no Developer ID cert exists
}
