#!/usr/bin/env bash
# stamp-sandy.sh — mint install.json for THIS seat's Hermes install (Sandy / SBX hermes-test).
# Idempotent: safe to re-run; an existing stamp is never touched.
# Refuses to write if this machine's live install key is not Sandy's —
# a stamp script pasted on the wrong seat fails loudly instead of minting a phantom.
set -euo pipefail
SEAT="sandy (SBX hermes-test)"
EXPECTED_KEY="08f7d59f9758a75d"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
CHECKOUT="$HERMES_HOME/hermes-agent"
command -v python3 >/dev/null || { echo "python3 not found — cannot derive the install key. Nothing written."; exit 1; }
ACTUAL_KEY=$(python3 -c 'import hashlib,pathlib,sys; print(hashlib.sha256(str(pathlib.Path(sys.argv[1]).resolve()).encode()).hexdigest()[:16])' "$CHECKOUT")
if [ "$ACTUAL_KEY" != "$EXPECTED_KEY" ]; then
  echo "REFUSING: this seat's install key is $ACTUAL_KEY, not $EXPECTED_KEY ($SEAT)."
  echo "Wrong script for this machine, or the checkout moved. Nothing written."
  exit 1
fi
TREE="$HERMES_HOME/installs/$EXPECTED_KEY"
[ -d "$TREE" ] || { echo "REFUSING: no install tree at $TREE. Nothing written."; exit 1; }
if [ -e "$TREE/install.json" ]; then
  echo "Already stamped: $TREE/install.json (left untouched)"
else
  printf '{}' > "$TREE/install.json"
  echo "Minted: $TREE/install.json"
fi
ls -l "$TREE/install.json"
echo "Verify: hermes doctor — the 'Stale channel record' warning should be absent."
