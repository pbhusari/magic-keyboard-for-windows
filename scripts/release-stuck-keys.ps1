# Fixes "typing does weird things" after PowerToys restarts mid-keypress:
# sends a release for every modifier key and reports anything still held.
# Releases are tagged so PowerToys Keyboard Manager passes them through unchanged.

Add-Type @'
using System; using System.Runtime.InteropServices;
public static class StuckKeys {
    [DllImport("user32.dll")] static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
    [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vk);
    public static void Up(byte vk) { keybd_event(vk, 0, 2, new UIntPtr(1)); }
    public static void Tap(byte vk) { keybd_event(vk, 0, 0, new UIntPtr(1)); keybd_event(vk, 0, 2, new UIntPtr(1)); }
}
'@

$names = @{ 0xA0='Left Shift'; 0xA1='Right Shift'; 0xA2='Left Ctrl'; 0xA3='Right Ctrl'; 0xA4='Left Alt'; 0xA5='Right Alt'; 0x5B='Left Win'; 0x5C='Right Win' }
function Held { $names.Keys | Where-Object { [StuckKeys]::GetAsyncKeyState($_) -band 0x8000 } | ForEach-Object { $names[$_] } }

$before = @(Held)
Write-Host ('Held before: ' + $(if ($before) { $before -join ', ' } else { 'none' }))

[StuckKeys]::Tap(0xFF)  # unused key, so releasing Win doesn't open Start
foreach ($vk in 0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0x5B, 0x5C, 0x10, 0x11, 0x12) { [StuckKeys]::Up([byte]$vk) }
Start-Sleep -Milliseconds 300

$after = @(Held)
Write-Host ('Held after:  ' + $(if ($after) { $after -join ', ' } else { 'none' }))
if ($after) { Write-Host 'Still stuck: press and release the physical key once (for Ctrl, tap Command).' }
