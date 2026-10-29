# Plays music on the Magic Trackpad's haptic motor (USB, interface 2, output report 0x53).
# The motor rings at one fixed pitch, so this is percussion: each pulse mixes a sharp "click"
# and a deep "thud", which gives kick, snare, hi-hat, tom and crash sounds.
#
#   .\trackpad-music.ps1                 # plays everything
#   .\trackpad-music.ps1 -Song sailor    # shave | groove | sailor | engine
#
# Rest a finger on the trackpad to feel it as well as hear it.

param([ValidateSet('all', 'shave', 'groove', 'sailor', 'engine')][string]$Song = 'all')

Add-Type -TypeDefinition @'
using System; using System.Diagnostics; using System.Collections.Generic; using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
public static class Pad {
  [StructLayout(LayoutKind.Sequential)] struct SP_DEVICE_INTERFACE_DATA { public uint cbSize; public Guid g; public uint flags; public IntPtr r; }
  [DllImport("hid.dll")] static extern void HidD_GetHidGuid(out Guid g);
  [DllImport("setupapi.dll", CharSet=CharSet.Unicode)] static extern IntPtr SetupDiGetClassDevs(ref Guid g, string e, IntPtr h, uint f);
  [DllImport("setupapi.dll")] static extern bool SetupDiEnumDeviceInterfaces(IntPtr s, IntPtr d, ref Guid g, uint i, ref SP_DEVICE_INTERFACE_DATA x);
  [DllImport("setupapi.dll", CharSet=CharSet.Unicode)] static extern bool SetupDiGetDeviceInterfaceDetail(IntPtr s, ref SP_DEVICE_INTERFACE_DATA x, IntPtr buf, uint size, out uint req, IntPtr d);
  [DllImport("setupapi.dll")] static extern bool SetupDiDestroyDeviceInfoList(IntPtr s);
  [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] static extern SafeFileHandle CreateFile(string n, uint a, uint s, IntPtr sec, uint c, uint f, IntPtr t);
  [DllImport("kernel32.dll", SetLastError=true)] static extern bool WriteFile(SafeFileHandle h, byte[] b, int n, out int w, IntPtr o);

  static SafeFileHandle dev;
  static readonly Stopwatch clock = Stopwatch.StartNew();

  // Finds the trackpad's actuator interface (USB-C A3120 = 0324, Lightning = 0265).
  public static bool Open() {
    Guid g; HidD_GetHidGuid(out g);
    IntPtr set = SetupDiGetClassDevs(ref g, null, IntPtr.Zero, 0x12);
    try {
      var d = new SP_DEVICE_INTERFACE_DATA(); d.cbSize = (uint)Marshal.SizeOf(d);
      for (uint i = 0; SetupDiEnumDeviceInterfaces(set, IntPtr.Zero, ref g, i, ref d); i++) {
        uint req; SetupDiGetDeviceInterfaceDetail(set, ref d, IntPtr.Zero, 0, out req, IntPtr.Zero);
        IntPtr buf = Marshal.AllocHGlobal((int)req); Marshal.WriteInt32(buf, IntPtr.Size == 8 ? 8 : 6);
        string path = SetupDiGetDeviceInterfaceDetail(set, ref d, buf, req, out req, IntPtr.Zero) ? Marshal.PtrToStringUni(new IntPtr(buf.ToInt64() + 4)) : "";
        Marshal.FreeHGlobal(buf);
        string p = path.ToLowerInvariant();
        if (p.Contains("vid_05ac") && (p.Contains("pid_0324") || p.Contains("pid_0265")) && p.Contains("mi_02")) {
          dev = CreateFile(path, 0xC0000000, 3, IntPtr.Zero, 3, 0, IntPtr.Zero);
          return !dev.IsInvalid;
        }
      }
      return false;
    } finally { SetupDiDestroyDeviceInfoList(set); }
  }

  // One actuator pulse. Caps keep the click (<= 0x20) and thud (<= 0x40) parts in a safe range.
  static void Hit(int strength, int sharp, int deep) {
    var b = new byte[64];
    var t = new byte[] { 0x53, 0x01, (byte)Math.Min(strength, 0x40), 0x78, 0x02, (byte)Math.Min(sharp, 0x20), 0x24, 0x30, 0x06, 0x01, (byte)Math.Min(deep, 0x40), 0x18, 0x48, 0x12 };
    Array.Copy(t, b, t.Length);
    int w; WriteFile(dev, b, 64, out w, IntPtr.Zero);
  }
  static void Kick()   { Hit(0x34, 0x02, 0x40); }
  static void Snare()  { Hit(0x2C, 0x20, 0x0A); }
  static void Ghost()  { Hit(0x14, 0x14, 0x04); }
  static void Hat()    { Hit(0x10, 0x12, 0x00); }
  static void Crash()  { Hit(0x40, 0x20, 0x40); }
  static void TomHi()  { Hit(0x2C, 0x10, 0x20); }
  static void TomMid() { Hit(0x30, 0x0A, 0x2C); }
  static void TomLow() { Hit(0x34, 0x04, 0x3A); }

  static void WaitUntil(double ms) { while (clock.Elapsed.TotalMilliseconds < ms) { } }
  public static void Rest(double ms) { WaitUntil(clock.Elapsed.TotalMilliseconds + ms); }

  // Step sequencer, one char per 16th note. kick/snare: x hit, o ghost. hat: x hat, X crash. tom: 1 high, 2 mid, 3 low.
  public static void Pattern(int bpm, int repeats, string kick, string snare, string hat, string tom) {
    double step = 60000.0 / bpm / 4, t0 = clock.Elapsed.TotalMilliseconds; int n = kick.Length;
    for (int r = 0; r < repeats; r++)
      for (int i = 0; i < n; i++) {
        WaitUntil(t0 + (r * n + i) * step);
        if (kick[i] == 'x') Kick();
        if (snare[i] == 'x') Snare(); else if (snare[i] == 'o') Ghost();
        if (hat[i] == 'x') Hat(); else if (hat[i] == 'X') Crash();
        if (tom[i] == '1') TomHi(); else if (tom[i] == '2') TomMid(); else if (tom[i] == '3') TomLow();
      }
    WaitUntil(t0 + repeats * n * step);
  }

  // Free rhythm: one voice per note (k s h c), lengths in beats.
  public static void Rhythm(int bpm, string voices, double[] beats) {
    double t = clock.Elapsed.TotalMilliseconds;
    for (int i = 0; i < beats.Length; i++) {
      WaitUntil(t);
      switch (voices[i]) { case 'k': Kick(); break; case 's': Snare(); break; case 'h': Hat(); break; case 'c': Crash(); break; }
      t += beats[i] * 60000.0 / bpm;
    }
    WaitUntil(t);
  }

  // A melody's rhythm, voiced by pitch: height 0 = low note (deep thud) .. 1 = high note (sharp click).
  // kickEvery > 0 adds a kick underneath every N beats.
  public static void Melody(int bpm, double[] heights, double[] beats, int kickEvery) {
    double beatMs = 60000.0 / bpm, t = clock.Elapsed.TotalMilliseconds, start = t, total = 0;
    foreach (var b in beats) total += b;
    var kicks = new List<double>();
    if (kickEvery > 0) for (double k = 0; k < total; k += kickEvery) kicks.Add(start + k * beatMs);
    int ki = 0;
    for (int i = 0; i < beats.Length; i++) {
      while (ki < kicks.Count && kicks[ki] < t - 1) { WaitUntil(kicks[ki]); Kick(); ki++; }
      WaitUntil(t);
      bool kickNow = ki < kicks.Count && Math.Abs(kicks[ki] - t) < 1;
      double h = heights[i];
      Hit(kickNow ? 0x38 : 0x2A, (int)(0x04 + h * 0x1C), (int)((1 - h) * 0x3C) + (kickNow ? 0x10 : 0));
      if (kickNow) ki++;
      t += beats[i] * beatMs;
    }
    WaitUntil(t);
  }

  // Engine rev: pulses speed up and get stronger, optionally easing off again.
  public static void Rev(double slowMs, double fastMs, int pulses, bool fallBack) {
    double t = clock.Elapsed.TotalMilliseconds;
    for (int i = 0; i < pulses; i++) {
      double f = (double)i / (pulses - 1);
      WaitUntil(t); Hit((int)(0x14 + f * 0x2C), (int)(0x06 + f * 0x10), (int)(0x30 - f * 0x10));
      t += slowMs + (fastMs - slowMs) * f;
    }
    if (fallBack) for (int i = 0; i < pulses / 3; i++) {
      double f = 1 - (double)i / (pulses / 3);
      WaitUntil(t); Hit((int)(0x14 + f * 0x20), 0x08, 0x28); t += fastMs + (slowMs - fastMs) * (1 - f);
    }
    WaitUntil(t);
  }
}
'@

if (-not [Pad]::Open()) { Write-Host 'Magic Trackpad not found. Plug it in by USB cable.'; return }
$none = '................'

if ($Song -in 'all', 'shave') {
  # "Shave and a haircut... two bits!" (traditional)
  [Pad]::Rhythm(120, 'kshhskcc', [double[]](1, 0.5, 0.5, 1, 1, 2, 1, 1))
  [Pad]::Rest(600)
}

if ($Song -in 'all', 'groove') {
  # Original funk groove at 104 BPM, with a fill into a crash.
  [Pad]::Pattern(104, 3, 'x.....x.x.....x.', '....x..o....x...', 'x.x.x.x.x.x.x.x.', $none)
  [Pad]::Pattern(104, 1, 'x.....x.x.......', '....x.......xxxx', 'x.x.x.x.x.x.....', $none)
  [Pad]::Pattern(104, 1, 'x...............', $none, 'X...............', $none)
  [Pad]::Rest(600)
}

if ($Song -in 'all', 'sailor') {
  # "Drunken Sailor" (traditional sea shanty). Heights: D=0 E=.15 F=.3 G=.45 A=.6 B=.75 C=.85 high D=1.
  $D = 0; $E = 0.15; $F = 0.3; $G = 0.45; $A = 0.6; $B = 0.75; $C = 0.85; $D2 = 1.0
  $line  = @(1, .5, .5, 1, .5, .5, 1, 1, 1, 1)
  $end   = @($C, $A, $G, $E, $D, $D);  $endB = @(1, 1, 1, 1, 2, 2)
  $verseH = @($A,$A,$A,$A,$A,$A,$A,$D,$F,$A) + @($G,$G,$G,$G,$G,$G,$G,$C,$E,$G) + @($A,$A,$A,$A,$A,$A,$A,$B,$C,$D2) + $end
  $verseB = $line + $line + $line + $endB
  $chorus = @(2, 2, 1, 1, 1, 1)
  $chorusH = @($A,$A,$A,$D,$F,$A) + @($G,$G,$G,$C,$E,$G) + @($A,$A,$A,$B,$C,$D2) + $end
  $chorusB = $chorus + $chorus + $chorus + $endB
  [Pad]::Rhythm(126, 'kkkk', [double[]](1, 1, 1, 1))
  [Pad]::Melody(126, [double[]]$verseH, [double[]]$verseB, 0)
  [Pad]::Melody(126, [double[]]$chorusH, [double[]]$chorusB, 1)
  [Pad]::Melody(134, [double[]]$verseH, [double[]]$verseB, 2)
  [Pad]::Melody(140, [double[]]$chorusH, [double[]]$chorusB, 1)
  [Pad]::Rhythm(140, 'kkc', [double[]](0.5, 0.5, 1))
  [Pad]::Rest(600)
}

if ($Song -in 'all', 'engine') {
  # Original: two engine revs, a redline, then fast driving rock at 180 BPM.
  [Pad]::Rev(90, 25, 16, $true); [Pad]::Rest(150)
  [Pad]::Rev(80, 18, 20, $true); [Pad]::Rest(150)
  [Pad]::Rev(70, 9, 40, $false)
  [Pad]::Pattern(180, 1, 'x...............', $none, 'X...............', $none)
  [Pad]::Pattern(180, 4, 'x.x...x.x.x...x.', '....x.......x...', 'x.x.x.x.x.x.x.x.', $none)
  [Pad]::Pattern(180, 1, 'x.x...x.x.......', '....x...x.x.xxxx', 'x.x.x.x.x.......', $none)
  [Pad]::Pattern(180, 4, 'x.x.x.x.x.x.x.x.', '....x.......x...', 'X...x...x...x...', $none)
  [Pad]::Pattern(180, 1, 'x.x.x.x.........', '........x.x.x.x.', 'x...x...........', '........1.2.3.3.')
  [Pad]::Rev(60, 10, 24, $false)
  [Pad]::Pattern(180, 1, 'x...............', $none, 'X...............', $none)
}
