# Makes PowerToys run as administrator (so remaps also work in admin windows) and stops it
# from downloading updates on its own (an update restarts PowerToys, which can leave a
# modifier key stuck). Backs up your PowerToys settings first.
#
# This restarts PowerToys once, as administrator: expect a UAC prompt and keep your hands
# off the keyboard until it finishes.

$ErrorActionPreference = 'Stop'
$settings = Join-Path $env:LOCALAPPDATA 'Microsoft\PowerToys\settings.json'
$exe = Join-Path $env:LOCALAPPDATA 'PowerToys\PowerToys.exe'
if (-not (Test-Path $exe)) { $exe = Join-Path $env:ProgramFiles 'PowerToys\PowerToys.exe' }
if (-not (Test-Path $exe)) { throw 'PowerToys not found. Install it first: winget install Microsoft.PowerToys' }
if (-not (Test-Path $settings)) { throw "PowerToys settings not found at $settings. Open PowerToys once first." }

$backup = "$settings.backup-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
Copy-Item $settings $backup
Write-Host "Backed up PowerToys settings to $backup"

Write-Host 'Restarting PowerToys as administrator (hands off the keyboard)...'
Get-Process | Where-Object Name -like 'PowerToys*' | Stop-Process -Force
Start-Sleep -Seconds 2

# Edit the JSON text directly (keeps PowerToys' formatting) and write it back as UTF-8 without a BOM.
$text = [IO.File]::ReadAllText($settings)
$text = $text -replace '"download_updates_automatically"\s*:\s*true', '"download_updates_automatically":false'
$text = $text -replace '"show_whats_new_after_updates"\s*:\s*true', '"show_whats_new_after_updates":false'
$text = $text -replace '"run_elevated"\s*:\s*false', '"run_elevated":true'
$null = $text | ConvertFrom-Json   # refuse to write broken JSON
[IO.File]::WriteAllText($settings, $text, (New-Object Text.UTF8Encoding $false))

Start-Process $exe -Verb RunAs
Start-Sleep -Seconds 10
& (Join-Path $PSScriptRoot 'release-stuck-keys.ps1')

$now = Get-Content $settings -Raw | ConvertFrom-Json
Write-Host "run_elevated = $($now.run_elevated), download_updates_automatically = $($now.download_updates_automatically)"
Write-Host 'PowerToys now starts as administrator at login and only updates when you choose to.'
