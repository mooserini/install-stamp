# apply-gws-fix-echo.ps1 — apply the GWS OAuth redirect fix to THIS seat's Hermes checkout (Echo / Shoestring).
# The fix: upstream setup.py hardcodes REDIRECT_URI = http://localhost:1, unusable with a stored
# web OAuth client. The fix resolves the redirect from env / the stored client secret instead.
# Fleet-local (author: Sandy, SBX, Nov 2026), not upstream. `hermes update` treats it as a tracked
# edit and may stash or discard it — re-run this script after an update to restore it.
# Idempotent: an already-fixed setup.py is reported, never re-patched.
# Refuses loudly if the patch does not apply cleanly (this seat's setup.py has drifted from base).
$ErrorActionPreference = 'Stop'
$Seat = 'echo (Shoestring)'
$HermesHome = Join-Path $env:LOCALAPPDATA 'hermes'
$Checkout = Join-Path $HermesHome 'hermes-agent'
$Target = Join-Path $Checkout 'skills\productivity\google-workspace\scripts\setup.py'
$Patch = Join-Path (Join-Path $PSScriptRoot 'payload') 'gws-redirect-fix.patch'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Host 'REFUSING: git not found on PATH. Nothing changed.'; exit 1 }
if (-not (Test-Path $Target)) { Write-Host "REFUSING: no setup.py at $Target (wrong seat or moved checkout). Nothing changed."; exit 1 }
if (-not (Test-Path $Patch)) { Write-Host "REFUSING: payload missing at $Patch. Run from the install-stamp repo clone. Nothing changed."; exit 1 }

$Count = ([regex]::Matches((Get-Content $Target -Raw), '_resolve_redirect_uri')).Count
if ($Count -ge 3) { Write-Host "Already applied on $Seat`: _resolve_redirect_uri x$Count in setup.py. Nothing to do."; exit 0 }

git -C $Checkout apply --check $Patch 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "REFUSING: patch does not apply cleanly — this seat's setup.py has drifted from the payload base (upstream 995181a8db). Nothing changed."
    Write-Host 'Re-cut the payload from a current tree (git diff of the fixed setup.py) and update the repo.'
    exit 1
}
git -C $Checkout apply $Patch
$NewCount = ([regex]::Matches((Get-Content $Target -Raw), '_resolve_redirect_uri')).Count
$Size = (Get-Item $Target).Length
Write-Host "Applied on $Seat`: _resolve_redirect_uri x$NewCount (expect 3); setup.py $Size bytes (expect 19375 on an un-drifted base)."
Write-Host 'Note: a future hermes update may stash or discard this edit — re-run this script to restore the fix.'
