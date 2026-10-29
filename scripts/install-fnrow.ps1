# Builds FnRow from source with the C# compiler that ships with Windows,
# installs it to %LOCALAPPDATA%\FnRow, starts it, and runs it at every login. No downloads.
#
#   .\install-fnrow.ps1          start at login as your normal user (no admin needed)
#   .\install-fnrow.ps1 -Admin   start at login as administrator via a scheduled task, so the
#                                top row also works while an admin window is focused.
#                                Run this one from an elevated PowerShell.

param([switch]$Admin)

$ErrorActionPreference = 'Stop'
$src = Join-Path $PSScriptRoot '..\fnrow\FnRow.cs'
$dest = Join-Path $env:LOCALAPPDATA 'FnRow'
$exe = Join-Path $dest 'FnRow.exe'
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'

if (-not (Test-Path $csc)) { throw "C# compiler not found at $csc (.NET Framework 4.x is part of Windows 10/11)." }
if ($Admin) {
    $elevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrators')
    if (-not $elevated) { throw 'Run from an elevated PowerShell (Run as administrator) when using -Admin.' }
}

New-Item -ItemType Directory -Force $dest | Out-Null
Copy-Item $src (Join-Path $dest 'FnRow.cs') -Force

& $csc /nologo /target:winexe /optimize /out:"$dest\FnRow.new.exe" `
    /r:System.Windows.Forms.dll /r:System.Drawing.dll "$dest\FnRow.cs"
if ($LASTEXITCODE -ne 0) { throw 'Compile failed.' }

Get-Process FnRow -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500
Move-Item "$dest\FnRow.new.exe" $exe -Force

if ($Admin) {
    $user = "$env:USERDOMAIN\$env:USERNAME"
    $action = New-ScheduledTaskAction -Execute $exe
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $user
    $principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
    Register-ScheduledTask -TaskName 'FnRow' -Action $action -Trigger $trigger -Principal $principal -Settings $settings `
        -Description 'Magic Keyboard top-row helper (runs elevated so it works in admin windows)' -Force | Out-Null
    Remove-ItemProperty $runKey -Name FnRow -ErrorAction SilentlyContinue
    Start-ScheduledTask -TaskName 'FnRow'
    Write-Host "FnRow installed to $dest and set to start at login as administrator (Task Scheduler: FnRow)."
} else {
    if (Get-ScheduledTask -TaskName 'FnRow' -ErrorAction SilentlyContinue) {
        Write-Host 'Note: an admin FnRow task already exists; it will keep starting FnRow as admin.'
        Start-ScheduledTask -TaskName 'FnRow'
    } else {
        Set-ItemProperty $runKey -Name FnRow -Value "`"$exe`""
        Start-Process $exe
    }
    Write-Host "FnRow installed to $dest and set to start at login."
}
Write-Host 'Press the physical Esc key to switch between media keys and F1-F12.'
