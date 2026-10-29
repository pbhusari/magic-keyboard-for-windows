# Swaps the Mac modifier keys at the lowest level Windows offers (a Scancode Map),
# before Windows or any app sees the keypress:
#
#   Command (left)  -> Ctrl      Command (right) -> Ctrl      Control -> Win
#
# Doing this in PowerToys instead leaves Command+L physically pressing Win+L, which Windows
# acts on before any remapper can step in (it locks, or hangs input if locking is disabled).
# With the Scancode Map, Command+L is a real Ctrl+L, Control+L locks the PC like Win+L,
# and the layout also works on the sign-in screen.
#
# Caps Lock -> Esc stays in PowerToys on purpose: FnRow uses the physical Esc key as its
# media/F-key toggle, and a scancode-level Caps Lock -> Esc would be indistinguishable from it.
#
# Run from an elevated PowerShell, then restart Windows. Applies to every keyboard on this PC.
#   .\set-scancode-map.ps1          set the swap
#   .\set-scancode-map.ps1 -Undo    remove it (restart afterwards)

param([switch]$Undo)

$ErrorActionPreference = 'Stop'
$elevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrators')
if (-not $elevated) { throw 'Run from an elevated PowerShell (Run as administrator).' }

$key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout'

if ($Undo) {
    Remove-ItemProperty $key -Name 'Scancode Map' -ErrorAction SilentlyContinue
    Write-Host 'Scancode Map removed. Restart Windows to finish.'
    Write-Host 'Command will be the plain Windows key again; restore a PowerToys keymap with Win->Ctrl swaps if you still want them.'
    return
}

# Header (8 zero bytes), entry count including the terminator, then [new scancode, old scancode] pairs.
$map = [byte[]](
    0, 0, 0, 0, 0, 0, 0, 0,
    4, 0, 0, 0,
    0x1D, 0x00, 0x5B, 0xE0,   # left Win (Command)   -> left Ctrl
    0x1D, 0xE0, 0x5C, 0xE0,   # right Win (Command)  -> right Ctrl
    0x5B, 0xE0, 0x1D, 0x00,   # left Ctrl (Control)  -> left Win
    0, 0, 0, 0
)
Set-ItemProperty $key -Name 'Scancode Map' -Value $map -Type Binary
Write-Host 'Scancode Map set.'

# A leftover workaround from older versions of this repo turned Windows' lock shortcut off.
# It's no longer needed, so turn locking back on.
$policy = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
if ((Get-ItemProperty $policy -ErrorAction SilentlyContinue).DisableLockWorkstation) {
    Remove-ItemProperty $policy -Name DisableLockWorkstation
    Write-Host 'Re-enabled screen locking (Control+L now locks the PC).'
}

Write-Host 'Restart Windows for the swap to take effect.'
