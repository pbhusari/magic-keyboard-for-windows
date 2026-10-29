# Mac-style precision touchpad settings (needs a precision touchpad, see install-trackpad-driver.ps1).
#
#   Natural scrolling, tap to click, two-finger tap = right click, no corner right-click
#   3-finger swipes off (left to three-finger drag), 3-finger tap = middle click
#   4-finger swipes = Task View / show desktop / switch desktops, 4-finger tap = Notification Center
#   Sensitivity "Most sensitive", so holding keys (e.g. WASD in games) doesn't lock the touchpad
#
# Taps, corner click and sensitivity apply immediately. Windows only reloads the 3/4-finger
# gestures when they're changed in Settings, so if old gestures still fire, sign out and back in
# (or flip each gesture dropdown in Settings > Bluetooth & devices > Touchpad and back).

$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad'
$backup = Join-Path $env:TEMP ('touchpad-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.reg')
reg export 'HKCU\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad' $backup /y | Out-Null
Write-Host "Backed up current touchpad settings to $backup"

$values = [ordered]@{
    ScrollDirection         = 0   # natural ("down motion scrolls up")
    TapsEnabled             = 1
    TwoFingerTapEnabled     = 1
    RightClickZoneEnabled   = 0
    TapAndDrag              = 0   # conflicts with three-finger drag
    PanEnabled              = 1
    ZoomEnabled             = 1
    AAPThreshold            = 0   # most sensitive
    ThreeFingerSlideEnabled = 0   # nothing
    ThreeFingerTapEnabled   = 4   # middle mouse button
    FourFingerSlideEnabled  = 2   # switch desktops and show desktop
    FourFingerTapEnabled    = 2   # notification center
}
foreach ($name in $values.Keys) { Set-ItemProperty $key -Name $name -Value $values[$name] -Type DWord }

# Push the settings that the touchpad API exposes so they take effect without signing out.
Add-Type @'
using System; using System.Runtime.InteropServices;
public static class Touchpad {
    [DllImport("user32.dll")] static extern bool SystemParametersInfo(uint action, uint size, byte[] data, uint flags);
    public static bool Apply() {
        var buf = new byte[64]; BitConverter.GetBytes(1u).CopyTo(buf, 0);
        if (!SystemParametersInfo(0xAE, 64, buf, 0)) return false;          // SPI_GETTOUCHPADPARAMETERS
        uint bits = BitConverter.ToUInt32(buf, 16);
        bits |= 0x4 | 0x10 | 0x80 | 0x100;    // taps, two-finger tap, pan, zoom
        bits &= ~(0x8u | 0x20u | 0x200u);      // no tap-and-drag, no right-click zone, natural scroll
        BitConverter.GetBytes(bits).CopyTo(buf, 16);
        BitConverter.GetBytes(0u).CopyTo(buf, 20);                         // most sensitive
        return SystemParametersInfo(0xAF, 64, buf, 3);                      // SPI_SETTOUCHPADPARAMETERS
    }
}
'@
if ([Touchpad]::Apply()) { Write-Host 'Touchpad settings applied.' }
else { Write-Host 'No precision touchpad detected; settings saved and will apply once one is present.' }
