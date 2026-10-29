# Builds FnRow from source with the C# compiler that ships with Windows,
# installs it to %LOCALAPPDATA%\FnRow, starts it, and runs it at every login.
# No admin rights, no downloads.

$ErrorActionPreference = 'Stop'
$src = Join-Path $PSScriptRoot '..\fnrow\FnRow.cs'
$dest = Join-Path $env:LOCALAPPDATA 'FnRow'
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'

if (-not (Test-Path $csc)) { throw "C# compiler not found at $csc (.NET Framework 4.x is part of Windows 10/11)." }

New-Item -ItemType Directory -Force $dest | Out-Null
Copy-Item $src (Join-Path $dest 'FnRow.cs') -Force

& $csc /nologo /target:winexe /optimize /out:"$dest\FnRow.new.exe" `
    /r:System.Windows.Forms.dll /r:System.Drawing.dll "$dest\FnRow.cs"
if ($LASTEXITCODE -ne 0) { throw 'Compile failed.' }

Get-Process FnRow -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500
Move-Item "$dest\FnRow.new.exe" "$dest\FnRow.exe" -Force

Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name FnRow -Value "`"$dest\FnRow.exe`""
Start-Process "$dest\FnRow.exe"

Write-Host "FnRow installed to $dest and set to start at login."
Write-Host 'Press the physical Esc key to switch between media keys and F1-F12.'
