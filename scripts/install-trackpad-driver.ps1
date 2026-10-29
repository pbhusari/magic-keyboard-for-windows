# Makes a USB-C Magic Trackpad (A3120, USB ID 05AC:0324) a Windows precision touchpad
# by force-installing Apple's Boot Camp USB precision trackpad driver.
# Run in an elevated PowerShell. Use it with the trackpad plugged in by cable.
#
# Safety checks before anything is installed:
#   - the download must match a known SHA-256
#   - every catalog and .sys file must carry a valid Microsoft Windows Hardware Compatibility
#     Publisher signature (Windows also re-checks this at install time)
# Nothing needs test signing, Secure Boot changes, or trusting extra certificates.
#
# The driver's INF lists older trackpads only, so it's selected for the 0324 interface
# the same way Device Manager's "Have Disk" does.
# Undo: pnputil /enum-drivers  (find ApplePrecisionTrackpadUSB.inf's oemNN.inf), then
#       pnputil /delete-driver oemNN.inf /uninstall, and replug the trackpad.

$ErrorActionPreference = 'Stop'
$url = 'https://raw.githubusercontent.com/lc700x/MagicTrackPad2_Windows_Precision_Drivers/main/ApplePrecisionTrackpad_amd64(USB-C).zip'
$sha256 = '13F4255513AF88BAF31C311D17C0360F42394C8969E93D3401557156EC5B5163'
$hwid = 'USB\VID_05AC&PID_0324&MI_01'

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrators')
if (-not $admin) { throw 'Run this from an elevated PowerShell (Run as administrator).' }

$device = Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -like "$hwid\*" } | Select-Object -First 1
if (-not $device) { throw "No trackpad found with hardware ID $hwid. Plug it in with a USB cable." }

$work = Join-Path $env:TEMP ('apple-trackpad-' + [guid]::NewGuid())
New-Item -ItemType Directory $work | Out-Null
$zip = Join-Path $work 'driver.zip'
Invoke-WebRequest $url -OutFile $zip -UseBasicParsing
$actual = (Get-FileHash $zip -Algorithm SHA256).Hash
if ($actual -ne $sha256) { throw "Download hash mismatch ($actual). Not installing." }
Expand-Archive $zip (Join-Path $work 'x')

$dir = Join-Path $work 'x\ApplePrecisionTrackpadUSB'
foreach ($f in Get-ChildItem $dir -File | Where-Object Extension -in '.cat', '.sys') {
    $sig = Get-AuthenticodeSignature $f.FullName
    if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notlike 'CN=Microsoft Windows Hardware Compatibility Publisher*') {
        throw "$($f.Name) is not validly signed by Microsoft (status $($sig.Status)). Not installing."
    }
}
$inf = Join-Path $dir 'ApplePrecisionTrackpadUSB.inf'
Write-Host 'Download verified. Staging driver package...'
pnputil /add-driver "$inf"

Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public static class ForceDriver {
  [StructLayout(LayoutKind.Sequential)] public struct DEVINFO { public uint cbSize; public Guid ClassGuid; public uint DevInst; public IntPtr Reserved; }
  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)] public struct INSTALLPARAMS {
    public uint cbSize; public uint Flags; public uint FlagsEx; public IntPtr hwndParent; public IntPtr MsgHandler; public IntPtr MsgCtx;
    public IntPtr FileQueue; public UIntPtr ClassInstallReserved; public uint Reserved;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst=260)] public string DriverPath; }
  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)] public struct DRVINFO {
    public uint cbSize; public uint DriverType; public UIntPtr Reserved;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst=256)] public string Description;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst=256)] public string MfgName;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst=256)] public string ProviderName;
    public long DriverDate; public ulong DriverVersion; }
  [DllImport("setupapi.dll", SetLastError=true)] static extern IntPtr SetupDiCreateDeviceInfoList(IntPtr g, IntPtr h);
  [DllImport("setupapi.dll", SetLastError=true, CharSet=CharSet.Unicode)] static extern bool SetupDiOpenDeviceInfo(IntPtr s, string id, IntPtr h, uint f, ref DEVINFO d);
  [DllImport("setupapi.dll", SetLastError=true, CharSet=CharSet.Unicode)] static extern bool SetupDiGetDeviceInstallParams(IntPtr s, ref DEVINFO d, ref INSTALLPARAMS p);
  [DllImport("setupapi.dll", SetLastError=true, CharSet=CharSet.Unicode)] static extern bool SetupDiSetDeviceInstallParams(IntPtr s, ref DEVINFO d, ref INSTALLPARAMS p);
  [DllImport("setupapi.dll", SetLastError=true)] static extern bool SetupDiBuildDriverInfoList(IntPtr s, ref DEVINFO d, uint t);
  [DllImport("setupapi.dll", SetLastError=true, CharSet=CharSet.Unicode)] static extern bool SetupDiEnumDriverInfo(IntPtr s, ref DEVINFO d, uint t, uint i, ref DRVINFO r);
  [DllImport("setupapi.dll", SetLastError=true, CharSet=CharSet.Unicode)] static extern bool SetupDiSetSelectedDriver(IntPtr s, ref DEVINFO d, ref DRVINFO r);
  [DllImport("setupapi.dll", SetLastError=true)] static extern bool SetupDiDestroyDeviceInfoList(IntPtr s);
  [DllImport("newdev.dll", SetLastError=true, CharSet=CharSet.Unicode)] static extern bool DiInstallDevice(IntPtr h, IntPtr s, ref DEVINFO d, ref DRVINFO r, uint f, out bool reboot);
  static void Check(bool ok, string what) { if (!ok) throw new Exception(what + " failed, Win32 error " + Marshal.GetLastWin32Error()); }
  public static string Run(string instanceId, string inf) {
    IntPtr set = SetupDiCreateDeviceInfoList(IntPtr.Zero, IntPtr.Zero);
    try {
      var d = new DEVINFO(); d.cbSize = (uint)Marshal.SizeOf(typeof(DEVINFO));
      Check(SetupDiOpenDeviceInfo(set, instanceId, IntPtr.Zero, 0, ref d), "OpenDeviceInfo");
      var p = new INSTALLPARAMS(); p.cbSize = (uint)Marshal.SizeOf(typeof(INSTALLPARAMS));
      Check(SetupDiGetDeviceInstallParams(set, ref d, ref p), "GetInstallParams");
      p.Flags |= 0x00010000;   // DI_ENUMSINGLEINF: only this INF
      p.FlagsEx |= 0x00000800; // DI_FLAGSEX_ALLOWEXCLUDEDDRVS
      p.DriverPath = inf;
      Check(SetupDiSetDeviceInstallParams(set, ref d, ref p), "SetInstallParams");
      Check(SetupDiBuildDriverInfoList(set, ref d, 1), "BuildDriverInfoList");
      var r = new DRVINFO(); r.cbSize = (uint)Marshal.SizeOf(typeof(DRVINFO));
      Check(SetupDiEnumDriverInfo(set, ref d, 1, 0, ref r), "EnumDriverInfo");
      Check(SetupDiSetSelectedDriver(set, ref d, ref r), "SetSelectedDriver");
      bool reboot;
      Check(DiInstallDevice(IntPtr.Zero, set, ref d, ref r, 0, out reboot), "DiInstallDevice");
      return "Installed " + r.Description + (reboot ? " (restart required)" : "");
    } finally { SetupDiDestroyDeviceInfoList(set); }
  }
}
'@
Write-Host ([ForceDriver]::Run($device.InstanceId, $inf))
Remove-Item $work -Recurse -Force
Write-Host 'Check Settings > Bluetooth & devices > Touchpad, then run set-touchpad-gestures.ps1.'
