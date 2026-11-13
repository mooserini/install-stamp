#!/usr/bin/env bash
# apply-gws-fix-kaishi.sh — apply the GWS OAuth redirect fix to THIS seat's Hermes checkout (Kaishi / Tater Tot).
# The fix: upstream setup.py hardcodes REDIRECT_URI = http://localhost:1, unusable with a stored
# web OAuth client. The fix resolves the redirect from env / the stored client secret instead.
# Fleet-local (author: Sandy, SBX, Nov 2026), not upstream. `hermes update` treats it as a tracked
# edit and may stash or discard it — re-run this script after an update to restore it.
# Idempotent: an already-fixed setup.py is reported, never re-patched.
# Refuses loudly if the patch does not apply cleanly (this seat's setup.py has drifted from base).
set -euo pipefail
SEAT="kaishi (Tater Tot)"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
CHECKOUT="$HERMES_HOME/hermes-agent"
TARGET="$CHECKOUT/skills/productivity/google-workspace/scripts/setup.py"
PATCH="$(cd "$(dirname "$0")" && pwd)/payload/gws-redirect-fix.patch"
[ -f "$TARGET" ] || { echo "REFUSING: no setup.py at $TARGET (wrong seat or moved checkout). Nothing changed."; exit 1; }
[ -f "$PATCH" ] || { echo "REFUSING: payload missing at $PATCH. Run from the install-stamp repo clone. Nothing changed."; exit 1; }
COUNT=$(grep -c "_resolve_redirect_uri" "$TARGET" || true)
if [ "$COUNT" -ge 3 ]; then
  echo "Already applied on $SEAT: _resolve_redirect_uri x$COUNT in setup.py. Nothing to do."
  exit 0
fi
if ! git -C "$CHECKOUT" apply --check "$PATCH" 2>/dev/null; then
  echo "REFUSING: patch does not apply cleanly — this seat's setup.py has drifted from the payload base (upstream 995181a8db). Nothing changed."
  echo "Re-cut the payload from a current tree (git diff of the fixed setup.py) and update the repo."
  exit 1
fi
git -C "$CHECKOUT" apply "$PATCH"
NEWCOUNT=$(grep -c "_resolve_redirect_uri" "$TARGET" || true)
echo "Applied on $SEAT: _resolve_redirect_uri x$NEWCOUNT (expect 3); setup.py $(wc -c < "$TARGET") bytes (expect 19375 on an un-drifted base)."
echo "Note: a future hermes update may stash or discard this edit — re-run this script to restore the fix."
