# Stops FnRow, removes it from login startup, and deletes %LOCALAPPDATA%\FnRow.

Get-Process FnRow -ErrorAction SilentlyContinue | Stop-Process -Force
Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name FnRow -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500
Remove-Item (Join-Path $env:LOCALAPPDATA 'FnRow') -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'FnRow removed.'
