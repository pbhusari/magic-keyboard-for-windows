<div align="center">

# âŒ˜ Magic Keyboard for Windows

**Make an Apple Magic Keyboard and Magic Trackpad on Windows feel like they do on a Mac.**

<kbd>âŒ˜</kbd> for app shortcuts Â· Mac text navigation Â· a top row that does what its icons say Â· three-finger drag

![Windows 11](https://img.shields.io/badge/Windows%2011-0078D4?logo=windows11&logoColor=white)
![PowerToys](https://img.shields.io/badge/PowerToys-Keyboard%20Manager-5C2D91)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1-012456?logo=powershell&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

</div>

---

## âœ¨ Highlights

- **Mac modifier layout.** <kbd>âŒ˜</kbd> works as Ctrl, so <kbd>âŒ˜</kbd> <kbd>C</kbd>, <kbd>âŒ˜</kbd> <kbd>Tab</kbd> and <kbd>âŒ˜</kbd> <kbd>Q</kbd> do what you expect.
- **Mac text navigation.** <kbd>âŒ˜</kbd> <kbd>â†</kbd> jumps to the start of the line, <kbd>âŒ¥</kbd> <kbd>â†</kbd> jumps by word, <kbd>âŒ¥</kbd> <kbd>âŒ«</kbd> deletes a word.
- **A top row that matches its icons.** Brightness (real monitor brightness over DDC/CI), Task View, search, dictation, media and volume. <kbd>Esc</kbd> switches to plain F1â€“F12.
- **Precision touchpad support** for the USB-C Magic Trackpad, using Apple's own Microsoft-signed driver.
- **Mac gestures,** including three-finger drag.
- **Verified downloads.** No third-party binaries live in this repo. Scripts that download something check an exact SHA-256 hash and a Microsoft signature before installing.

## ðŸ§­ How it fits together

```mermaid
flowchart LR
    KB["âŒ¨ï¸ Magic Keyboard"]
    TP["ðŸ–±ï¸ Magic Trackpad"]

    subgraph keys ["Keyboard layer"]
        PT["PowerToys<br/>Keyboard Manager"]
        FR["FnRow<br/>(this repo)"]
    end

    subgraph touch ["Trackpad layer"]
        DRV["Apple precision<br/>trackpad driver"]
        TFD["ThreeFingerDrag"]
    end

    KB -- "âŒ˜ âŒƒ âŒ¥ Â· Caps Lock<br/>Mac shortcuts" --> PT
    KB -- "F1â€“F12 Â· Esc Â· âŒƒâŒ˜Q" --> FR
    PT -- "Ctrl / Win / Alt<br/>Home, End, Alt+Tabâ€¦" --> APPS["ðŸªŸ Windows & apps"]
    FR -- "media Â· volume<br/>Task View Â· sleep" --> APPS
    FR -- "brightness<br/>(DDC/CI)" --> MON["ðŸ–¥ï¸ Monitor"]

    TP --> DRV
    DRV -- "precision touchpad<br/>gestures Â· taps" --> APPS
    DRV --> TFD
    TFD -- "three-finger drag" --> APPS
```

> [!NOTE]
> Built and tested on Windows 11 with a USB-C Magic Keyboard (`05AC:0320`) and a USB-C Magic Trackpad A3120 (`05AC:0324`), both connected by cable.

---

## ðŸš€ Setup

**Requirements:** Windows 10 or 11, and [PowerToys](https://github.com/microsoft/PowerToys) with Keyboard Manager turned on:

```powershell
winget install Microsoft.PowerToys
```

Clone the repo, then run the scripts from PowerShell in the repo folder:

```powershell
git clone https://github.com/pbhusari/magic-keyboard-for-windows
cd magic-keyboard-for-windows

# âŒ¨ï¸ Keyboard
.\scripts\apply-powertoys-keymap.ps1
.\scripts\install-fnrow.ps1

# ðŸ–±ï¸ Magic Trackpad (run the driver script in an elevated PowerShell)
.\scripts\install-trackpad-driver.ps1
.\scripts\install-three-finger-drag.ps1
.\scripts\set-touchpad-gestures.ps1

# ðŸ”“ Optional: lets âŒ˜L work as Ctrl+L (read the trade-off below first)
.\scripts\free-cmd-l.ps1
```

> [!TIP]
> If Windows blocks the scripts, start PowerShell with `powershell -ExecutionPolicy Bypass`.

---

## âŒ¨ï¸ Keyboard

### Modifiers

<p align="center">
  <img src="assets/modifiers.svg" alt="Magic Keyboard bottom row: control acts as Win, option as Alt, command as Ctrl" width="640">
</p>

| Magic Keyboard | Acts as |
|:---:|:---:|
| <kbd>âŒ˜ Command</kbd> | Ctrl |
| <kbd>âŒƒ Control</kbd> | Win |
| <kbd>âŒ¥ Option</kbd> | Alt |
| <kbd>Caps Lock</kbd> | Esc |

Windows' Win-key shortcuts move to <kbd>âŒƒ</kbd>: <kbd>âŒƒ</kbd> <kbd>.</kbd> for emoji, <kbd>âŒƒ</kbd> <kbd>V</kbd> for clipboard history, <kbd>âŒƒ</kbd> <kbd>D</kbd> for the desktop, <kbd>âŒƒ</kbd> <kbd>â‡§</kbd> <kbd>S</kbd> for screenshots.

### Mac shortcuts

| Shortcut | Does |
|---|---|
| <kbd>âŒ˜</kbd> <kbd>Tab</kbd> | Switch apps |
| <kbd>âŒ˜</kbd> <kbd>Q</kbd> | Quit app |
| <kbd>âŒ˜</kbd> <kbd>Space</kbd> | Command Palette |
| <kbd>âŒ˜</kbd> <kbd>â†</kbd> / <kbd>â†’</kbd> | Start / end of line (add <kbd>â‡§</kbd> to select) |
| <kbd>âŒ˜</kbd> <kbd>â†‘</kbd> / <kbd>â†“</kbd> | Top / bottom of document (add <kbd>â‡§</kbd> to select) |
| <kbd>âŒ¥</kbd> <kbd>â†</kbd> / <kbd>â†’</kbd> | Jump by word (add <kbd>â‡§</kbd> to select) |
| <kbd>âŒ¥</kbd> <kbd>âŒ«</kbd> | Delete previous word |
| <kbd>âŒ˜</kbd> <kbd>[</kbd> / <kbd>]</kbd> | Back / forward |
| <kbd>âŒ˜</kbd> <kbd>â‡§</kbd> <kbd>[</kbd> / <kbd>]</kbd> | Previous / next tab |
| <kbd>âŒ˜</kbd> <kbd>â‡§</kbd> <kbd>Z</kbd> | Redo |
| <kbd>âŒ˜</kbd> <kbd>â‡§</kbd> <kbd>4</kbd> | Screenshot a region |
| <kbd>âŒ˜</kbd> <kbd>âŒ¥</kbd> <kbd>Esc</kbd> | Task Manager |
| <kbd>âŒƒ</kbd> <kbd>âŒ˜</kbd> <kbd>F</kbd> | Full screen |
| <kbd>âŒƒ</kbd> <kbd>âŒ˜</kbd> <kbd>Q</kbd> | Sleep |

### ðŸŽ›ï¸ Top row: FnRow

The Magic Keyboard sends plain F1â€“F12 to Windows. **FnRow** is a small background helper (about 250 lines of C#, in [`fnrow/FnRow.cs`](fnrow/FnRow.cs)) that turns them into what the keys show.

| Key | Icon | Media mode (default) |
|:---:|:---:|---|
| <kbd>F1</kbd> <kbd>F2</kbd> | ðŸ”… ðŸ”† | Monitor brightness down / up |
| <kbd>F3</kbd> | ðŸªŸ | Task View |
| <kbd>F4</kbd> | ðŸ” | Command Palette |
| <kbd>F5</kbd> | ðŸŽ™ï¸ | Windows voice typing |
| <kbd>F6</kbd> | ðŸŒ™ | Notification Center (Do Not Disturb lives there) |
| <kbd>F7</kbd> <kbd>F8</kbd> <kbd>F9</kbd> | âª â¯ï¸ â© | Previous / play-pause / next |
| <kbd>F10</kbd> <kbd>F11</kbd> <kbd>F12</kbd> | ðŸ”‡ ðŸ”‰ ðŸ”Š | Mute / volume down / volume up |
| <kbd>Esc</kbd> | | **Switch between media keys and F1â€“F12** |

- Holding any modifier sends the plain F-key, so <kbd>âŒ¥</kbd> <kbd>F4</kbd> still closes windows.
- FnRow is compiled on your machine by the C# compiler that ships with Windows. It has no network code, writes no files, runs as your user (not admin), and reacts only to <kbd>Esc</kbd>, F1â€“F12 and <kbd>âŒƒ</kbd> <kbd>âŒ˜</kbd> <kbd>Q</kbd>.
- It starts at login. Quit it from its tray icon, or remove it with `.\scripts\uninstall-fnrow.ps1`.

---

## ðŸ–±ï¸ Trackpad

| Gesture | Does |
|---|---|
| ðŸ¤ Three-finger drag | Drag windows, select text |
| ðŸ‘† Three-finger tap | Middle click |
| â¬†ï¸ Four-finger swipe up | Task View |
| â¬‡ï¸ Four-finger swipe down | Show desktop |
| â†”ï¸ Four-finger swipe left / right | Switch desktops |
| ðŸ‘† Four-finger tap | Notification Center |
| ðŸ“œ Two-finger scroll | Natural direction |

Touchpad sensitivity is set to *Most sensitive*, so holding keys (like WASD in games) doesn't lock the touchpad.

---

## ðŸ“ What's in the repo

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
| [`scripts/free-cmd-l.ps1`](scripts/free-cmd-l.ps1) | Lets âŒ˜L reach apps (`-Undo` to revert) |
| [`scripts/release-stuck-keys.ps1`](scripts/release-stuck-keys.ps1) | Fixes garbled typing from a stuck modifier |

---

## âš ï¸ Known limitations

<details>
<summary><b>âŒ˜L locks the PC</b></summary>

<br>

<kbd>âŒ˜</kbd> is physically the Win key, and Windows handles <kbd>Win</kbd> <kbd>L</kbd> before any remapper sees it. `free-cmd-l.ps1` fixes this by turning off the lock shortcut everywhere. Use <kbd>âŒƒ</kbd> <kbd>âŒ˜</kbd> <kbd>Q</kbd> (sleep) as your lock instead, and set *Settings â†’ Accounts â†’ Sign-in options* to require sign-in when the PC wakes up from sleep.

</details>

<details>
<summary><b>fn / ðŸŒ and the Lock key don't work</b></summary>

<br>

The keyboard handles them internally and sends Windows nothing, so no software can remap them. Use <kbd>âŒƒ</kbd> <kbd>.</kbd> for emoji and <kbd>âŒƒ</kbd> <kbd>âŒ˜</kbd> <kbd>Q</kbd> to sleep.

</details>

<details>
<summary><b>âŒƒ is the Win key</b></summary>

<br>

Mac Control habits trigger Windows shortcuts: <kbd>âŒƒ</kbd> <kbd>A</kbd> opens Quick Settings, <kbd>âŒƒ</kbd> <kbd>E</kbd> opens File Explorer, and <kbd>âŒƒ</kbd> <kbd>â†</kbd> / <kbd>â†’</kbd> snaps windows. To switch desktops, use <kbd>âŒƒ</kbd> <kbd>âŒ˜</kbd> <kbd>â†</kbd> / <kbd>â†’</kbd> or a four-finger swipe.

</details>

<details>
<summary><b>Some Windows shortcuts are replaced</b></summary>

<br>

Ctrl+Tab, Ctrl+Space, Ctrl+arrows, Ctrl+[ / ] and Alt+â† / â†’ now do their Mac equivalents. That affects tab cycling, VS Code autocomplete and Excel's jump-to-edge. PowerToys can apply shortcuts per app if you want exceptions.

</details>

<details>
<summary><b>Remaps don't work in admin windows</b></summary>

<br>

PowerToys can't remap keys in apps running as administrator unless PowerToys itself runs as administrator.

</details>

<details>
<summary><b>Typing goes weird after PowerToys restarts</b></summary>

<br>

Restarting PowerToys while a key is held can leave Ctrl stuck. Tap <kbd>âŒ˜</kbd>, or run `.\scripts\release-stuck-keys.ps1`.

</details>

<details>
<summary><b>The trackpad driver isn't an official match</b></summary>

<br>

Apple's driver doesn't list the A3120, so the script force-installs it, the same way Device Manager's *Have Disk* does. The script header explains how to undo it.

</details>

---

## ðŸ™ Credits

- [Microsoft PowerToys](https://github.com/microsoft/PowerToys) for Keyboard Manager
- Apple's Boot Camp precision trackpad driver, re-hosted by [lc700x/MagicTrackPad2_Windows_Precision_Drivers](https://github.com/lc700x/MagicTrackPad2_Windows_Precision_Drivers)
- [ClementGre/ThreeFingerDragOnWindows](https://github.com/ClementGre/ThreeFingerDragOnWindows) for three-finger drag

<div align="center">

<sub>MIT licensed Â· not affiliated with Apple or Microsoft</sub>

</div>
