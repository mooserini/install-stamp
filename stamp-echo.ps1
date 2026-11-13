# stamp-echo.ps1 — mint install.json for THIS seat's Hermes install (Echo / Shoestring).
# Idempotent: safe to re-run; an existing stamp is never touched.
# Refuses to write if this machine's live install key is not Echo's —
# a stamp script pasted on the wrong seat fails loudly instead of minting a phantom.
$ErrorActionPreference = 'Stop'
$Seat = 'echo (Shoestring)'
$ExpectedKey = 'b26a2e2ee7c1284d'
$HermesHome = Join-Path $env:LOCALAPPDATA 'hermes'
$Checkout = Join-Path $HermesHome 'hermes-agent'

$sha = [System.Security.Cryptography.SHA256]::Create()
$hashBytes = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Checkout))
$ActualKey = (($hashBytes | ForEach-Object { $_.ToString('x2') }) -join '').Substring(0, 16)

if ($ActualKey -ne $ExpectedKey) {
    Write-Host "REFUSING: this seat's install key is $ActualKey, not $ExpectedKey ($Seat)."
    Write-Host "Wrong script for this machine, or the checkout moved. Nothing written."
    exit 1
}
$Tree = Join-Path (Join-Path $HermesHome 'installs') $ExpectedKey
if (-not (Test-Path $Tree)) {
    Write-Host "REFUSING: no install tree at $Tree. Nothing written."
    exit 1
}
$Stamp = Join-Path $Tree 'install.json'
if (Test-Path $Stamp) {
    Write-Host "Already stamped: $Stamp (left untouched)"
} else {
    [System.IO.File]::WriteAllBytes($Stamp, [System.Text.Encoding]::ASCII.GetBytes('{}'))
    Write-Host "Minted: $Stamp"
}
Get-Item $Stamp | ForEach-Object { "$($_.Length) bytes  $($_.FullName)" }
Write-Host "Verify: hermes doctor — the 'Stale channel record' warning should be absent."
