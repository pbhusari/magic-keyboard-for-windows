# Stops FnRow, removes it from login startup (normal or admin), and deletes %LOCALAPPDATA%\FnRow.
# If FnRow was installed with -Admin, run this from an elevated PowerShell so the task can be removed.

Get-Process FnRow -ErrorAction SilentlyContinue | Stop-Process -Force
Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name FnRow -ErrorAction SilentlyContinue
if (Get-ScheduledTask -TaskName 'FnRow' -ErrorAction SilentlyContinue) {
    try { Unregister-ScheduledTask -TaskName 'FnRow' -Confirm:$false -ErrorAction Stop; Write-Host 'Removed the FnRow login task.' }
    catch { Write-Host 'Could not remove the admin FnRow task. Re-run this from an elevated PowerShell.' }
}
Start-Sleep -Milliseconds 500
Remove-Item (Join-Path $env:LOCALAPPDATA 'FnRow') -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'FnRow removed.'
