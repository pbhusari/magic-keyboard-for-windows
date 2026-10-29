// FnRow: makes the Magic Keyboard top row act like it does on a Mac.
// Media mode: F1-F12 do what their icons show. F-key mode: plain F1-F12.
// The physical Esc key toggles between the two (Caps Lock stays Escape via PowerToys).
// Holding any modifier always sends the plain F-key (so Alt+F4 etc. still work).
// Easter egg: type the Konami code (up up down down left right left right B A) and the
// Magic Trackpad's haptic motor taps out "shave and a haircut... two bits".
// No network access, no files written. Quit from the tray icon.
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;

static class FnRow
{
    const int WH_KEYBOARD_LL = 13, WM_KEYDOWN = 0x100, WM_SYSKEYDOWN = 0x104;
    const uint LLKHF_INJECTED = 0x10, KEYEVENTF_EXTENDEDKEY = 1, KEYEVENTF_KEYUP = 2;
    // PowerToys Keyboard Manager skips input tagged with this, so the Win key we send isn't remapped to Ctrl.
    static readonly UIntPtr Tag = new UIntPtr(1);

    [StructLayout(LayoutKind.Sequential)]
    struct KBDLLHOOKSTRUCT { public uint vk, scan, flags, time; public IntPtr extra; }
    delegate IntPtr HookProc(int code, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll")] static extern IntPtr SetWindowsHookEx(int id, HookProc proc, IntPtr mod, uint thread);
    [DllImport("user32.dll")] static extern bool UnhookWindowsHookEx(IntPtr hook);
    [DllImport("user32.dll")] static extern IntPtr CallNextHookEx(IntPtr hook, int code, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] static extern short GetAsyncKeyState(int vk);
    [DllImport("user32.dll")] static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
    [DllImport("user32.dll")] static extern uint MapVirtualKey(uint code, uint type);
    [DllImport("kernel32.dll")] static extern IntPtr GetModuleHandle(string name);

    static HookProc proc;
    static IntPtr hook;
    static bool mediaMode = true, escSwallowed, sleepPending;
    static readonly HashSet<uint> swallowed = new HashSet<uint>();
    static SynchronizationContext ui;
    static Osd osd;
    static NotifyIcon tray;

    [STAThread]
    static void Main()
    {
        bool first;
        using (new Mutex(true, "Local\\FnRow", out first))
        {
            if (!first) return;
            osd = new Osd();
            ui = SynchronizationContext.Current ?? new WindowsFormsSynchronizationContext();
            Brightness.Start(pct => ui.Post(_ => osd.Flash("Brightness  " + pct + "%"), null));

            var menu = new ContextMenuStrip();
            menu.Items.Add("Toggle media / F-keys (Esc)", null, (s, e) => Toggle());
            menu.Items.Add("Quit FnRow", null, (s, e) => Quit());
            tray = new NotifyIcon { Icon = SystemIcons.Application, ContextMenuStrip = menu, Visible = true };
            UpdateTray();

            proc = Hook;
            hook = SetWindowsHookEx(WH_KEYBOARD_LL, proc, GetModuleHandle(null), 0);
            Application.Run();
        }
    }

    static void Quit()
    {
        UnhookWindowsHookEx(hook);
        tray.Visible = false;
        Application.Exit();
    }

    static void Toggle()
    {
        mediaMode = !mediaMode;
        UpdateTray();
        osd.Flash(mediaMode ? "Media keys" : "F1 – F12");
    }

    static void UpdateTray() { tray.Text = "FnRow: " + (mediaMode ? "media keys" : "F1-F12"); }

    [DllImport("powrprof.dll")] static extern bool SetSuspendState(bool hibernate, bool force, bool disableWake);

    static bool Held(int vk) { return (GetAsyncKeyState(vk) & 0x8000) != 0; }

    // Short delay so the shortcut's keys are released before the PC sleeps (avoids stuck modifiers on wake).
    static void SleepSoon()
    {
        var t = new System.Windows.Forms.Timer { Interval = 700 };
        t.Tick += (s, e) => { t.Stop(); t.Dispose(); SetSuspendState(false, false, false); };
        t.Start();
    }

    static bool ModifiersHeld()
    {
        foreach (int vk in new[] { 0x10, 0x11, 0x12, 0x5B, 0x5C })
            if ((GetAsyncKeyState(vk) & 0x8000) != 0) return true;
        return false;
    }

    static IntPtr Hook(int code, IntPtr wParam, IntPtr lParam)
    {
        if (code >= 0)
        {
            var k = (KBDLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(KBDLLHOOKSTRUCT));
            bool down = wParam.ToInt32() == WM_KEYDOWN || wParam.ToInt32() == WM_SYSKEYDOWN;
            // Only physical keys; Caps Lock arrives here as an injected Esc from PowerToys and passes through.
            if ((k.flags & LLKHF_INJECTED) == 0)
            {
                if (down) Konami(k.vk);
                if (k.vk == 0x1B)
                {
                    if (down)
                    {
                        if (escSwallowed) return (IntPtr)1; // auto-repeat
                        if (!ModifiersHeld()) { escSwallowed = true; ui.Post(_ => Toggle(), null); return (IntPtr)1; }
                    }
                    else if (escSwallowed) { escSwallowed = false; return (IntPtr)1; }
                }
                // Ctrl+Cmd+Q (Win+Ctrl+Q after the PowerToys remap) puts the PC to sleep, like the Mac lock shortcut.
                else if (k.vk == 0x51 && (sleepPending || down && Held(0x5B) && Held(0x11)))
                {
                    if (down) sleepPending = true;
                    else { sleepPending = false; ui.Post(_ => SleepSoon(), null); }
                    return (IntPtr)1;
                }
                else if (k.vk >= 0x70 && k.vk <= 0x7B)
                {
                    if (down)
                    {
                        if (swallowed.Contains(k.vk))
                        {
                            if (Repeats(k.vk)) Act(k.vk);
                            return (IntPtr)1;
                        }
                        if (mediaMode && !ModifiersHeld()) { swallowed.Add(k.vk); Act(k.vk); return (IntPtr)1; }
                    }
                    else if (swallowed.Remove(k.vk)) return (IntPtr)1;
                }
            }
        }
        return CallNextHookEx(hook, code, wParam, lParam);
    }

    // Only remembers how far into the code you are; keys always pass through untouched.
    static readonly uint[] konamiCode = { 0x26, 0x26, 0x28, 0x28, 0x25, 0x27, 0x25, 0x27, 0x42, 0x41 };
    static int konamiPos;

    static void Konami(uint vk)
    {
        if (vk == konamiCode[konamiPos]) konamiPos++;
        else konamiPos = vk == konamiCode[0] ? 1 : 0;
        if (konamiPos < konamiCode.Length) return;
        konamiPos = 0;
        ui.Post(_ => osd.Flash("♪ two bits! ♪"), null);
        new Thread(Trackpad.ShaveAndAHaircut) { IsBackground = true }.Start();
    }

    // Holding brightness or volume keeps stepping, like on a Mac.
    static bool Repeats(uint vk) { return vk == 0x70 || vk == 0x71 || vk == 0x7A || vk == 0x7B; }

    static void Act(uint vk)
    {
        switch (vk)
        {
            case 0x70: Brightness.Step(-1); break;
            case 0x71: Brightness.Step(+1); break;
            default: ui.Post(_ => Send(vk), null); break;
        }
    }

    static void Send(uint fkey)
    {
        switch (fkey)
        {
            case 0x72: Combo(0x5B, 0x09); break;        // Mission Control -> Task View
            case 0x73: Combo(0x5B, 0x12, 0x20); break;  // Search -> Command Palette (Win+Alt+Space)
            case 0x74: Combo(0x5B, 0x48); break;        // Dictation -> voice typing (Win+H)
            case 0x75: Combo(0x5B, 0x4E); break;        // Do Not Disturb -> Notification Center (Win+N)
            case 0x76: Combo(0xB1); break;              // previous track
            case 0x77: Combo(0xB3); break;              // play / pause
            case 0x78: Combo(0xB0); break;              // next track
            case 0x79: Combo(0xAD); break;              // mute
            case 0x7A: Combo(0xAE); break;              // volume down
            case 0x7B: Combo(0xAF); break;              // volume up
        }
    }

    static void Combo(params byte[] keys)
    {
        foreach (var k in keys) keybd_event(k, Scan(k), Ext(k), Tag);
        for (int i = keys.Length - 1; i >= 0; i--) keybd_event(keys[i], Scan(keys[i]), Ext(keys[i]) | KEYEVENTF_KEYUP, Tag);
    }

    static byte Scan(byte vk) { return (byte)MapVirtualKey(vk, 0); }
    static uint Ext(byte vk) { return (vk == 0x5B || vk >= 0xAD && vk <= 0xB3) ? KEYEVENTF_EXTENDEDKEY : 0; }
}

// Monitor brightness over DDC/CI, on its own thread because monitor calls are slow.
static class Brightness
{
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    struct PHYSICAL_MONITOR { public IntPtr handle; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string desc; }
    delegate bool MonitorEnum(IntPtr hMon, IntPtr hdc, IntPtr rect, IntPtr data);
    [DllImport("user32.dll")] static extern bool EnumDisplayMonitors(IntPtr hdc, IntPtr clip, MonitorEnum cb, IntPtr data);
    [DllImport("dxva2.dll")] static extern bool GetNumberOfPhysicalMonitorsFromHMONITOR(IntPtr hMon, out uint count);
    [DllImport("dxva2.dll")] static extern bool GetPhysicalMonitorsFromHMONITOR(IntPtr hMon, uint count, [Out] PHYSICAL_MONITOR[] mons);
    [DllImport("dxva2.dll")] static extern bool DestroyPhysicalMonitors(uint count, PHYSICAL_MONITOR[] mons);
    [DllImport("dxva2.dll")] static extern bool GetMonitorBrightness(IntPtr h, out uint min, out uint cur, out uint max);
    [DllImport("dxva2.dll")] static extern bool SetMonitorBrightness(IntPtr h, uint value);

    static int pending;
    static readonly AutoResetEvent wake = new AutoResetEvent(false);

    public static void Start(Action<int> report)
    {
        var t = new Thread(() =>
        {
            while (true)
            {
                wake.WaitOne();
                int steps = Interlocked.Exchange(ref pending, 0);
                if (steps != 0) { int pct = Apply(steps); if (pct >= 0) report(pct); }
            }
        });
        t.IsBackground = true;
        t.Start();
    }

    public static void Step(int dir) { Interlocked.Add(ref pending, dir); wake.Set(); }

    static int Apply(int steps)
    {
        int shown = -1;
        EnumDisplayMonitors(IntPtr.Zero, IntPtr.Zero, (hMon, hdc, rect, data) =>
        {
            uint n;
            if (!GetNumberOfPhysicalMonitorsFromHMONITOR(hMon, out n) || n == 0) return true;
            var mons = new PHYSICAL_MONITOR[n];
            if (!GetPhysicalMonitorsFromHMONITOR(hMon, n, mons)) return true;
            foreach (var m in mons)
            {
                uint min, cur, max;
                if (!GetMonitorBrightness(m.handle, out min, out cur, out max) || max <= min) continue;
                int pct = (int)Math.Round((cur - min) * 100.0 / (max - min) / 10.0) * 10 + steps * 10;
                pct = Math.Max(0, Math.Min(100, pct));
                SetMonitorBrightness(m.handle, (uint)(min + (max - min) * pct / 100));
                shown = pct;
            }
            DestroyPhysicalMonitors(n, mons);
            return true;
        }, IntPtr.Zero);
        return shown;
    }
}

// Magic Trackpad haptic actuator: output report 0x53 on the trackpad's vendor interface 2.
// Mixing the sharp "click" and deep "thud" parts of each pulse gives different drum sounds.
static class Trackpad
{
    [StructLayout(LayoutKind.Sequential)] struct SP_DEVICE_INTERFACE_DATA { public uint cbSize; public Guid g; public uint flags; public IntPtr r; }
    [DllImport("hid.dll")] static extern void HidD_GetHidGuid(out Guid g);
    [DllImport("setupapi.dll", CharSet = CharSet.Unicode)] static extern IntPtr SetupDiGetClassDevs(ref Guid g, string e, IntPtr h, uint f);
    [DllImport("setupapi.dll")] static extern bool SetupDiEnumDeviceInterfaces(IntPtr s, IntPtr d, ref Guid g, uint i, ref SP_DEVICE_INTERFACE_DATA x);
    [DllImport("setupapi.dll", CharSet = CharSet.Unicode)] static extern bool SetupDiGetDeviceInterfaceDetail(IntPtr s, ref SP_DEVICE_INTERFACE_DATA x, IntPtr buf, uint size, out uint req, IntPtr d);
    [DllImport("setupapi.dll")] static extern bool SetupDiDestroyDeviceInfoList(IntPtr s);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern Microsoft.Win32.SafeHandles.SafeFileHandle CreateFile(string n, uint a, uint s, IntPtr sec, uint c, uint f, IntPtr t);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool WriteFile(Microsoft.Win32.SafeHandles.SafeFileHandle h, byte[] b, int n, out int w, IntPtr o);

    static string FindActuator()
    {
        Guid g; HidD_GetHidGuid(out g);
        IntPtr set = SetupDiGetClassDevs(ref g, null, IntPtr.Zero, 0x12);
        try
        {
            var d = new SP_DEVICE_INTERFACE_DATA(); d.cbSize = (uint)Marshal.SizeOf(d);
            for (uint i = 0; SetupDiEnumDeviceInterfaces(set, IntPtr.Zero, ref g, i, ref d); i++)
            {
                uint req; SetupDiGetDeviceInterfaceDetail(set, ref d, IntPtr.Zero, 0, out req, IntPtr.Zero);
                IntPtr buf = Marshal.AllocHGlobal((int)req);
                Marshal.WriteInt32(buf, IntPtr.Size == 8 ? 8 : 6);
                string path = SetupDiGetDeviceInterfaceDetail(set, ref d, buf, req, out req, IntPtr.Zero)
                    ? Marshal.PtrToStringUni(new IntPtr(buf.ToInt64() + 4)) : "";
                Marshal.FreeHGlobal(buf);
                string p = path.ToLowerInvariant();
                if (p.Contains("vid_05ac") && (p.Contains("pid_0324") || p.Contains("pid_0265")) && p.Contains("mi_02")) return path;
            }
            return null;
        }
        finally { SetupDiDestroyDeviceInfoList(set); }
    }

    static void Hit(Microsoft.Win32.SafeHandles.SafeFileHandle h, byte strength, byte sharp, byte deep)
    {
        var b = new byte[64];
        var t = new byte[] { 0x53, 0x01, strength, 0x78, 0x02, sharp, 0x24, 0x30, 0x06, 0x01, deep, 0x18, 0x48, 0x12 };
        Array.Copy(t, b, t.Length);
        int w; WriteFile(h, b, b.Length, out w, IntPtr.Zero);
    }

    public static void ShaveAndAHaircut()
    {
        string path = FindActuator();
        if (path == null) return;
        using (var h = CreateFile(path, 0xC0000000, 3, IntPtr.Zero, 3, 0, IntPtr.Zero))
        {
            if (h.IsInvalid) return;
            // kick, snare, hat, hat, snare, (rest) ... kick, crash: 120 BPM
            var voices = "kshhsk..cc";
            var beats = new[] { 1.0, 0.5, 0.5, 1, 1, 2, 0, 0, 1, 1 };
            var clock = System.Diagnostics.Stopwatch.StartNew(); double at = 0;
            for (int i = 0; i < voices.Length; i++)
            {
                if (voices[i] == '.') continue;
                while (clock.Elapsed.TotalMilliseconds < at) Thread.Sleep(1);
                switch (voices[i])
                {
                    case 'k': Hit(h, 0x34, 0x02, 0x40); break;
                    case 's': Hit(h, 0x2C, 0x20, 0x0A); break;
                    case 'h': Hit(h, 0x10, 0x12, 0x00); break;
                    case 'c': Hit(h, 0x40, 0x20, 0x40); break;
                }
                at += beats[i] * 500;
            }
        }
    }
}

// Small on-screen indicator that never takes focus or blocks clicks.
class Osd : Form
{
    readonly Label label;
    readonly System.Windows.Forms.Timer hideTimer;

    public Osd()
    {
        FormBorderStyle = FormBorderStyle.None;
        ShowInTaskbar = false;
        TopMost = true;
        StartPosition = FormStartPosition.Manual;
        BackColor = Color.FromArgb(32, 32, 32);
        Opacity = 0.92;
        Size = new Size(240, 56);
        label = new Label { Dock = DockStyle.Fill, ForeColor = Color.White, Font = new Font("Segoe UI", 13f), TextAlign = ContentAlignment.MiddleCenter };
        Controls.Add(label);
        hideTimer = new System.Windows.Forms.Timer { Interval = 1100 };
        hideTimer.Tick += (s, e) => { hideTimer.Stop(); Hide(); };
        CreateHandle();
    }

    protected override bool ShowWithoutActivation { get { return true; } }

    protected override CreateParams CreateParams
    {
        get
        {
            var cp = base.CreateParams;
            cp.ExStyle |= 0x08000000 | 0x80 | 0x20 | 0x8; // no-activate, tool window, click-through, topmost
            return cp;
        }
    }

    public void Flash(string text)
    {
        label.Text = text;
        var wa = Screen.PrimaryScreen.WorkingArea;
        Location = new Point(wa.Left + (wa.Width - Width) / 2, wa.Bottom - Height - 90);
        if (!Visible) Show();
        hideTimer.Stop();
        hideTimer.Start();
    }
}
