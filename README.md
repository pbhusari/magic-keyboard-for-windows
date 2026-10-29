<div align="center">

# ⌘ Magic Keyboard for Windows

**Make an Apple Magic Keyboard and Magic Trackpad on Windows feel like they do on a Mac.**

<kbd>⌘</kbd> for app shortcuts · Mac text navigation · a top row that does what its icons say · three-finger drag

![Windows 11](https://img.shields.io/badge/Windows%2011-0078D4?logo=windows11&logoColor=white)
![PowerToys](https://img.shields.io/badge/PowerToys-Keyboard%20Manager-5C2D91)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1-012456?logo=powershell&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

</div>

---

## ✨ Highlights

- **Mac modifier layout.** <kbd>⌘</kbd> works as Ctrl, so <kbd>⌘</kbd> <kbd>C</kbd>, <kbd>⌘</kbd> <kbd>Tab</kbd> and <kbd>⌘</kbd> <kbd>Q</kbd> do what you expect.
- **Mac text navigation.** <kbd>⌘</kbd> <kbd>←</kbd> jumps to the start of the line, <kbd>⌥</kbd> <kbd>←</kbd> jumps by word, <kbd>⌥</kbd> <kbd>⌫</kbd> deletes a word.
- **A top row that matches its icons.** Brightness (real monitor brightness over DDC/CI), Task View, search, dictation, media and volume. <kbd>Esc</kbd> switches to plain F1–F12.
- **Precision touchpad support** for the USB-C Magic Trackpad, using Apple's own Microsoft-signed driver.
- **Mac gestures,** including three-finger drag.
- **Verified downloads.** No third-party binaries live in this repo. Scripts that download something check an exact SHA-256 hash and a Microsoft signature before installing.

## 🧭 How it fits together

```mermaid
flowchart LR
    KB["⌨️ Magic Keyboard"]
    TP["🖱️ Magic Trackpad"]

    subgraph keys ["Keyboard layer"]
        PT["PowerToys<br/>Keyboard Manager"]
        FR["FnRow<br/>(this repo)"]
    end

    subgraph touch ["Trackpad layer"]
        DRV["Apple precision<br/>trackpad driver"]
        TFD["ThreeFingerDrag"]
    end

    KB -- "⌘ ⌃ ⌥ · Caps Lock<br/>Mac shortcuts" --> PT
    KB -- "F1–F12 · Esc · ⌃⌘Q" --> FR
    PT -- "Ctrl / Win / Alt<br/>Home, End, Alt+Tab…" --> APPS["🪟 Windows & apps"]
    FR -- "media · volume<br/>Task View · sleep" --> APPS
    FR -- "brightness<br/>(DDC/CI)" --> MON["🖥️ Monitor"]

    TP --> DRV
    DRV -- "precision touchpad<br/>gestures · taps" --> APPS
    DRV --> TFD
    TFD -- "three-finger drag" --> APPS
```

> [!NOTE]
> Built and tested on Windows 11 with a USB-C Magic Keyboard (`05AC:0320`) and a USB-C Magic Trackpad A3120 (`05AC:0324`), both connected by cable.

---

## 🚀 Setup

**Requirements:** Windows 10 or 11, and [PowerToys](https://github.com/microsoft/PowerToys) with Keyboard Manager turned on:

```powershell
winget install Microsoft.PowerToys
```

Clone the repo, then run the scripts from PowerShell in the repo folder:

```powershell
git clone https://github.com/pbhusari/magic-keyboard-for-windows
cd magic-keyboard-for-windows

# ⌨️ Keyboard
.\scripts\apply-powertoys-keymap.ps1
.\scripts\install-fnrow.ps1

# 🖱️ Magic Trackpad (run the driver script in an elevated PowerShell)
.\scripts\install-trackpad-driver.ps1
.\scripts\install-three-finger-drag.ps1
.\scripts\set-touchpad-gestures.ps1

# 🔓 Optional: lets ⌘L work as Ctrl+L (read the trade-off below first)
.\scripts\free-cmd-l.ps1
```

> [!TIP]
> If Windows blocks the scripts, start PowerShell with `powershell -ExecutionPolicy Bypass`.

---

## ⌨️ Keyboard

### Modifiers

<p align="center">
  <img src="assets/modifiers.svg" alt="Magic Keyboard bottom row: control acts as Win, option as Alt, command as Ctrl" width="640">
</p>

| Magic Keyboard | Acts as |
|:---:|:---:|
| <kbd>⌘ Command</kbd> | Ctrl |
| <kbd>⌃ Control</kbd> | Win |
| <kbd>⌥ Option</kbd> | Alt |
| <kbd>Caps Lock</kbd> | Esc |

Windows' Win-key shortcuts move to <kbd>⌃</kbd>: <kbd>⌃</kbd> <kbd>.</kbd> for emoji, <kbd>⌃</kbd> <kbd>V</kbd> for clipboard history, <kbd>⌃</kbd> <kbd>D</kbd> for the desktop, <kbd>⌃</kbd> <kbd>⇧</kbd> <kbd>S</kbd> for screenshots.

### Mac shortcuts

| Shortcut | Does |
|---|---|
| <kbd>⌘</kbd> <kbd>Tab</kbd> | Switch apps |
| <kbd>⌘</kbd> <kbd>Q</kbd> | Quit app |
| <kbd>⌘</kbd> <kbd>Space</kbd> | Command Palette |
| <kbd>⌘</kbd> <kbd>←</kbd> / <kbd>→</kbd> | Start / end of line (add <kbd>⇧</kbd> to select) |
| <kbd>⌘</kbd> <kbd>↑</kbd> / <kbd>↓</kbd> | Top / bottom of document (add <kbd>⇧</kbd> to select) |
| <kbd>⌥</kbd> <kbd>←</kbd> / <kbd>→</kbd> | Jump by word (add <kbd>⇧</kbd> to select) |
| <kbd>⌥</kbd> <kbd>⌫</kbd> | Delete previous word |
| <kbd>⌘</kbd> <kbd>[</kbd> / <kbd>]</kbd> | Back / forward |
| <kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>[</kbd> / <kbd>]</kbd> | Previous / next tab |
| <kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>Z</kbd> | Redo |
| <kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>4</kbd> | Screenshot a region |
| <kbd>⌘</kbd> <kbd>⌥</kbd> <kbd>Esc</kbd> | Task Manager |
| <kbd>⌃</kbd> <kbd>⌘</kbd> <kbd>F</kbd> | Full screen |
| <kbd>⌃</kbd> <kbd>⌘</kbd> <kbd>Q</kbd> | Sleep |

### 🎛️ Top row: FnRow

The Magic Keyboard sends plain F1–F12 to Windows. **FnRow** is a small background helper (about 250 lines of C#, in [`fnrow/FnRow.cs`](fnrow/FnRow.cs)) that turns them into what the keys show.

| Key | Icon | Media mode (default) |
|:---:|:---:|---|
| <kbd>F1</kbd> <kbd>F2</kbd> | 🔅 🔆 | Monitor brightness down / up |
| <kbd>F3</kbd> | 🪟 | Task View |
| <kbd>F4</kbd> | 🔍 | Command Palette |
| <kbd>F5</kbd> | 🎙️ | Windows voice typing |
| <kbd>F6</kbd> | 🌙 | Notification Center (Do Not Disturb lives there) |
| <kbd>F7</kbd> <kbd>F8</kbd> <kbd>F9</kbd> | ⏪ ⏯️ ⏩ | Previous / play-pause / next |
| <kbd>F10</kbd> <kbd>F11</kbd> <kbd>F12</kbd> | 🔇 🔉 🔊 | Mute / volume down / volume up |
| <kbd>Esc</kbd> | | **Switch between media keys and F1–F12** |

- Holding any modifier sends the plain F-key, so <kbd>⌥</kbd> <kbd>F4</kbd> still closes windows.
- FnRow is compiled on your machine by the C# compiler that ships with Windows. It has no network code, writes no files, runs as your user (not admin), and reacts only to <kbd>Esc</kbd>, F1–F12 and <kbd>⌃</kbd> <kbd>⌘</kbd> <kbd>Q</kbd>.
- It starts at login. Quit it from its tray icon, or remove it with `.\scripts\uninstall-fnrow.ps1`.

---

## 🖱️ Trackpad

| Gesture | Does |
|---|---|
| 🤏 Three-finger drag | Drag windows, select text |
| 👆 Three-finger tap | Middle click |
| ⬆️ Four-finger swipe up | Task View |
| ⬇️ Four-finger swipe down | Show desktop |
| ↔️ Four-finger swipe left / right | Switch desktops |
| 👆 Four-finger tap | Notification Center |
| 📜 Two-finger scroll | Natural direction |

Touchpad sensitivity is set to *Most sensitive*, so holding keys (like WASD in games) doesn't lock the touchpad.

---

## 📁 What's in the repo

| Path | Purpose |
|---|---|
| [`powertoys/default.json`](powertoys/default.json) | PowerToys Keyboard Manager config |
| [`fnrow/FnRow.cs`](fnrow/FnRow.cs) | FnRow source |
| [`scripts/apply-powertoys-keymap.ps1`](scripts/apply-powertoys-keymap.ps1) | Installs the keymap and backs up yours first |
| [`scripts/install-fnrow.ps1`](scripts/install-fnrow.ps1) | Builds and installs FnRow, and runs it at login |
| [`scripts/uninstall-fnrow.ps1`](scripts/uninstall-fnrow.ps1) | Removes FnRow |
| [`scripts/install-trackpad-driver.ps1`](scripts/install-trackpad-driver.ps1) | Verifies and installs Apple's precision trackpad driver |
| [`scripts/install-three-finger-drag.ps1`](scripts/install-three-finger-drag.ps1) | Verifies and installs ThreeFingerDragOnWindows |
| [`scripts/set-touchpad-gestures.ps1`](scripts/set-touchpad-gestures.ps1) | Applies the gestures and taps above |
| [`scripts/free-cmd-l.ps1`](scripts/free-cmd-l.ps1) | Lets ⌘L reach apps (`-Undo` to revert) |
| [`scripts/release-stuck-keys.ps1`](scripts/release-stuck-keys.ps1) | Fixes garbled typing from a stuck modifier |

---

## ⚠️ Known limitations

<details>
<summary><b>⌘L locks the PC</b></summary>

<br>

<kbd>⌘</kbd> is physically the Win key, and Windows handles <kbd>Win</kbd> <kbd>L</kbd> before any remapper sees it. `free-cmd-l.ps1` fixes this by turning off the lock shortcut everywhere. Use <kbd>⌃</kbd> <kbd>⌘</kbd> <kbd>Q</kbd> (sleep) as your lock instead, and set *Settings → Accounts → Sign-in options* to require sign-in when the PC wakes up from sleep.

</details>

<details>
<summary><b>fn / 🌐 and the Lock key don't work</b></summary>

<br>

The keyboard handles them internally and sends Windows nothing, so no software can remap them. Use <kbd>⌃</kbd> <kbd>.</kbd> for emoji and <kbd>⌃</kbd> <kbd>⌘</kbd> <kbd>Q</kbd> to sleep.

</details>

<details>
<summary><b>⌃ is the Win key</b></summary>

<br>

Mac Control habits trigger Windows shortcuts: <kbd>⌃</kbd> <kbd>A</kbd> opens Quick Settings, <kbd>⌃</kbd> <kbd>E</kbd> opens File Explorer, and <kbd>⌃</kbd> <kbd>←</kbd> / <kbd>→</kbd> snaps windows. To switch desktops, use <kbd>⌃</kbd> <kbd>⌘</kbd> <kbd>←</kbd> / <kbd>→</kbd> or a four-finger swipe.

</details>

<details>
<summary><b>Some Windows shortcuts are replaced</b></summary>

<br>

Ctrl+Tab, Ctrl+Space, Ctrl+arrows, Ctrl+[ / ] and Alt+← / → now do their Mac equivalents. That affects tab cycling, VS Code autocomplete and Excel's jump-to-edge. PowerToys can apply shortcuts per app if you want exceptions.

</details>

<details>
<summary><b>Remaps don't work in admin windows</b></summary>

<br>

PowerToys can't remap keys in apps running as administrator unless PowerToys itself runs as administrator.

</details>

<details>
<summary><b>Typing goes weird after PowerToys restarts</b></summary>

<br>

Restarting PowerToys while a key is held can leave Ctrl stuck. Tap <kbd>⌘</kbd>, or run `.\scripts\release-stuck-keys.ps1`.

</details>

<details>
<summary><b>The trackpad driver isn't an official match</b></summary>

<br>

Apple's driver doesn't list the A3120, so the script force-installs it, the same way Device Manager's *Have Disk* does. The script header explains how to undo it.

</details>

---

## 🙏 Credits

- [Microsoft PowerToys](https://github.com/microsoft/PowerToys) for Keyboard Manager
- Apple's Boot Camp precision trackpad driver, re-hosted by [lc700x/MagicTrackPad2_Windows_Precision_Drivers](https://github.com/lc700x/MagicTrackPad2_Windows_Precision_Drivers)
- [ClementGre/ThreeFingerDragOnWindows](https://github.com/ClementGre/ThreeFingerDragOnWindows) for three-finger drag

<div align="center">

<sub>MIT licensed · not affiliated with Apple or Microsoft</sub>

</div>
