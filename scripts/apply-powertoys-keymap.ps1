# Installs the Mac-style PowerToys Keyboard Manager config (powertoys\default.json).
# Backs up your current config first, then restarts PowerToys so it loads.
#
# Don't hold any keys while this runs: restarting PowerToys mid-keypress can leave
# a modifier stuck. If typing goes weird afterwards, run release-stuck-keys.ps1.

$ErrorActionPreference = 'Stop'
$kbm = Join-Path $env:LOCALAPPDATA 'Microsoft\PowerToys\Keyboard Manager'
$exe = Join-Path $env:LOCALAPPDATA 'PowerToys\PowerToys.exe'
if (-not (Test-Path $exe)) { $exe = Join-Path $env:ProgramFiles 'PowerToys\PowerToys.exe' }
if (-not (Test-Path $exe)) { throw 'PowerToys not found. Install it first: winget install Microsoft.PowerToys' }

New-Item -ItemType Directory -Force $kbm | Out-Null
$current = Join-Path $kbm 'default.json'
if (Test-Path $current) {
    $backup = Join-Path $kbm ('default.backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json')
    Copy-Item $current $backup
    Write-Host "Backed up current keymap to $backup"
}
Copy-Item (Join-Path $PSScriptRoot '..\powertoys\default.json') $current -Force

Write-Host 'Restarting PowerToys (hands off the keyboard)...'
Get-Process | Where-Object Name -like 'PowerToys*' | Stop-Process -Force
Start-Sleep -Seconds 2
Start-Process $exe
Start-Sleep -Seconds 8
& (Join-Path $PSScriptRoot 'release-stuck-keys.ps1')

Write-Host 'Done. Make sure Keyboard Manager is turned on in PowerToys settings.'
