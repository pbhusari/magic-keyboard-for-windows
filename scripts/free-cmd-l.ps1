# Command+L physically sends Win+L, and Windows locks the screen on Win+L before
# PowerToys can remap it. The only way to free it up is to turn off Windows' lock
# shortcut entirely. Run with -Undo to turn locking back on.
#
# Trade-off: Lock disappears everywhere (Win+L, Start menu, Ctrl+Alt+Del screen).
# FnRow's Control+Command+Q puts the PC to sleep instead; set
# Settings > Accounts > Sign-in options > "require sign-in" to "When PC wakes up from sleep"
# so that sleep works as a lock.

param([switch]$Undo)

$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
if ($Undo) {
    Remove-ItemProperty $key -Name DisableLockWorkstation -ErrorAction SilentlyContinue
    Write-Host 'Windows lock shortcut re-enabled (Command+L locks the PC again).'
    return
}

$answer = Read-Host 'This disables locking the PC (Win+L, Start > Lock). Continue? (y/n)'
if ($answer -ne 'y') { Write-Host 'Cancelled.'; return }
New-Item -Path $key -Force | Out-Null
Set-ItemProperty $key -Name DisableLockWorkstation -Value 1 -Type DWord
Write-Host 'Done. Command+L now reaches PowerToys as Ctrl+L.'
