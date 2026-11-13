# gws-redirect-fix

Per-seat one-shots that apply Sandy's Google Workspace OAuth redirect fix to a
Hermes checkout — and re-apply it after any `hermes update` stashes or discards
it (the updater treats the fix as a tracked local edit; it will not survive
updates on its own).

## The defect

The bundled `skills/productivity/google-workspace/scripts/setup.py` hardcodes
`REDIRECT_URI = "http://localhost:1"` at authorize and exchange time, even when
the stored web OAuth client secret declares a different registered redirect.
Result: exchange failures and state confusion with any stored web client.

## The fix

`payload/gws-redirect-fix.patch`, authored by **Sandy** in her SBX worktree
(Nov 11–13, 2026): adds `_resolve_redirect_uri()` — env override
`GOOGLE_WORKSPACE_REDIRECT_URI` wins, else the first `redirect_uris` entry from
the stored client secret JSON, else the loopback default — used byte-identically
at authorize and exchange, with full-callback-URL state validation and provider
error payloads printed on exchange failure.

- Cut against upstream `995181a8db` (Sandy's post-update HEAD), posted to
  #agents-with-souls 2026-11-13 06:49 EST.
- Patch sha256: `fc781bf61db7de5fa55b6dfa8841982948028e449814291c80082254f3839d97`
- Verified by Maren before packaging: applies cleanly to the pristine base
  file; result is **19,375 bytes**, **`_resolve_redirect_uri` ×3**, diffstat
  **49 insertions / 8 deletions** — matching Sandy's writeup receipts exactly.

## The scripts

`apply-gws-fix-ara.sh` · `apply-gws-fix-kaishi.sh` · `apply-gws-fix-sandy.sh` ·
`apply-gws-fix-echo.ps1`

Run from a clone of this repo on the seat (the script finds its payload beside
itself). Each script: refuses if the seat's `setup.py` is missing or the patch
fails `git apply --check` (drifted base — re-cut the payload instead of
forcing); reports and exits if the fix is already applied (resolver count ≥ 3);
applies, then prints the resulting count and byte size as the receipt.

Per-seat state at packaging (Nov 13, 2026):

- **Ara (Russet):** her checkout already carries this fix as a tracked edit
  (applied Nov 11) — the script is her post-update restore path.
- **Sandy (SBX):** the fix's home tree; her script is for re-applying after her
  own future updates discard it.
- **Kaishi (Tater), Echo (Shoestring):** apply when wanted; their seats update
  on their own schedules.

Rollback: `git -C <checkout> checkout -- skills/productivity/google-workspace/scripts/setup.py`
restores the upstream file.
