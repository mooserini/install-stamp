# install-stamp

One-shot scripts that mint `install.json` — the registration stamp `hermes doctor`
looks for and no Hermes component issues.

## Why this exists

Hermes derives an install's identity from its checkout path
(`pm/environments.py: install_key = sha256(str(Path(project_root).resolve()))[:16]`)
and keys everything to that hash — including the record in `config.yaml`'s
`update.installs` that persists a user's channel choice (`--set-channel`).

`hermes doctor`'s channel-hygiene check (`hermes_cli/update_channel.py:379`)
then judges that record: if `installs/<key>/install.json` does not exist, the
install is declared **"stale — no live install claims it — safe to remove."**
No install flow, onboarding included, ever writes that file. The warning's
advice, followed literally, deletes the user's persisted channel consent and
licenses treating their live install tree as garbage.

The stamp is the owner's registration of their own install: a 2-byte file
containing `{}`. Doctor checks existence only. Minted by hand the first time on
Russet, Nov 13, 2026 — the warning retired, byte-for-byte, from two independent
doctor captures.

## The scripts

One per seat. Each script:

1. **Derives** the seat's live install key from its checkout path and
   **refuses to write** if it doesn't match the key baked into the script —
   a script pasted on the wrong seat, or run after a checkout moved, fails
   loudly instead of stamping a phantom.
2. **Refuses** if the install tree itself doesn't exist.
3. **Idempotent** — an existing `install.json` is reported, never touched.
4. Prints the verification: run `hermes doctor`; the stale warning stays absent.

| script | seat | hermes home | checkout path | install key | key verified |
|---|---|---|---|---|---|
| `stamp-ara.sh` | Ara — Russet (macOS) | `~/.hermes` | `/Users/thomaskenny/.hermes/hermes-agent` | `c69461487891d971` | arithmetic + live tree + doctor, Nov 13 |
| `stamp-kaishi.sh` | Kaishi — Tater Tot (macOS) | `~/.hermes` | `/Users/moosenberg/.hermes/hermes-agent` | `d073beedfa972e86` | arithmetic + installs-dir listing, Nov 13 |
| `stamp-sandy.sh` | Sandy — SBX `hermes-test` (Linux) | `~/.hermes` | `/home/agent/.hermes/hermes-agent` | `08f7d59f9758a75d` | arithmetic; confirm `ls ~/.hermes/installs` on her seat before first run |
| `stamp-echo.ps1` | Echo — Shoestring (Windows) | `%LOCALAPPDATA%\hermes` | `C:\Users\moose\AppData\Local\hermes\hermes-agent` | `b26a2e2ee7c1284d` | arithmetic + installs-dir + config record (`channel: stable`), Nov 13 |

Notes per seat:

- **Ara** is already stamped (Nov 13, 03:56, the original specimen). Her script
  is the restore tool if the file ever disappears.
- **Kaishi** has no `update.installs` record yet, so doctor doesn't warn on her
  seat today; the stamp is pre-registration — inert until the day she sets a
  channel, then it pre-empts the warning.
- **Echo** rides the `stable` channel per her config record; her home is under
  `%LOCALAPPDATA%`, not `~/.hermes`. A second tree (`56f1e3385d1c1d45`) exists
  on her seat and is deliberately not stamped — it holds no config record.
- **Sandy's** key is computed from her known path; her seat is sandbox-walled,
  so the script is delivered as copy-paste and run by the operator there.

## Rollback

Delete `installs/<key>/install.json`. Nothing else is ever modified.

## Provenance

Design: Moose (Thomas Kenny) — registration belongs to the install's owner;
these scripts are the fleet-local form of his onboarding proposal (a model in
the onboarding flow should offer this mint, verify it with the user via
`hermes doctor` in the same conversation, and clarify only when the layout is
ambiguous). Built by Maren Frost, Nov 13, 2026. Sibling to
`message-bubble-bundle` (the Photon voice-identity procedure).
