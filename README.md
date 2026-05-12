# Keep Awake — KDE Plasma 6 Widget (Amphetamine for Linux / KDE)

> An **Amphetamine-style** toggle for **KDE Plasma 6**. Prevents your system from going to sleep — **while still letting the screen turn off**. Lightweight, no daemon of its own, just a thin UI on top of `systemd-inhibit`.

If you ever wanted a **Caffeine alternative for KDE** that does *not* keep your display blazing all night, this is it.

---

## ✨ Features

- 🟢 **Inhibit suspend, allow screen-off** by default. Uses `systemd-inhibit --what=sleep`, so only the sleep/hibernate path is blocked. Idle handling (screen blanking, screensaver, lock) is left alone — just like macOS Amphetamine's "Allow display sleep" option.
- 🌗 **"Allow display to sleep" switch** in the popup. Flip it off and the widget also inhibits idle (`--what=sleep:idle`) so the screen stays on too. Setting persists across reboots and can be switched live while active.
- 🖱️ **One-click toggle from the panel.** Left-click for popup with status, middle-click to toggle directly from the system tray.
- 🧊 **Tiny footprint.** No background daemon written by us — Plasma + systemd do all the work. The widget just calls `systemctl --user start/stop` on a small unit file.
- 🔁 **Survives panel reloads.** State is owned by a user systemd unit, so the inhibit doesn't vanish when Plasma restarts.
- 🎨 **Native Plasma 6 look.** Built with Plasma's QML APIs (Kirigami, PlasmaComponents). Respects your theme and panel size.
- 🆓 **MIT licensed.**

## 🤔 Why this exists

KDE Plasma's built-in **"Block Sleep and Screen Locking"** toggle does exactly what it says — it blocks *both*. There is no first-party way (in Plasma 6 as of this writing) to keep the machine awake but let the display power off after the usual idle timeout.

On macOS, [**Amphetamine**](https://apps.apple.com/us/app/amphetamine/id937984704) solves this neatly: keep the Mac awake, but let the screen sleep. On Linux there's [**Stimulator**](https://flathub.org/apps/io.github.sigmasd.stimulator) (works, but lives in its own window), and there's the venerable [**Caffeine**](https://github.com/caffeine-ng/caffeine-ng) (great, but historically keeps the display on too).

**Keep Awake** is a tiny native Plasma widget that just toggles a `systemd-inhibit --what=sleep` lock from the panel. That's the whole idea.

## 📦 Install

### One-liner (recommended)

```bash
git clone https://github.com/burakgon/keep-awake-kde.git
cd keep-awake-kde
./install.sh
```

That script does two things:

1. Drops `~/.config/systemd/user/keep-awake.service` and reloads the user systemd manager.
2. Installs the plasmoid via `kpackagetool6` into `~/.local/share/plasma/plasmoids/`.

Then **right-click your panel → Add Widgets → search "Keep Awake"** and drag it where you want it.

### Manual install

```bash
# 1. systemd user unit
mkdir -p ~/.config/systemd/user
cp systemd/keep-awake.service ~/.config/systemd/user/
systemctl --user daemon-reload

# 2. plasmoid
kpackagetool6 --type Plasma/Applet --install ./package
# or, if already installed:
kpackagetool6 --type Plasma/Applet --upgrade ./package
```

### Requirements

- **KDE Plasma 6** (Plasma 5 is not supported — the QML uses Plasma 6 imports)
- `systemd` with a working user manager (default on every modern systemd distro)
- `kpackagetool6` (ships with Plasma 6)

Tested on Arch / CachyOS with Plasma 6.6. Should work on Fedora KDE Spin, openSUSE Tumbleweed, KDE Neon, Kubuntu 24.04+, EndeavourOS, Manjaro KDE.

## 🚀 Usage

After adding the widget to your panel:

| Action | Result |
| --- | --- |
| **Left-click** the tray icon | Opens a popup with status + Turn On/Off button |
| **Middle-click** the tray icon | Toggles immediately, no popup |
| Hover the icon | Tooltip shows current state |

You can also drive it from a terminal — handy for shell aliases, keybindings, or scripts:

```bash
# Default mode: inhibit suspend, screen can still sleep
systemctl --user start  keep-awake.service
systemctl --user stop   keep-awake.service

# "Display stays on" mode: inhibit suspend AND idle
systemctl --user start  keep-awake-full.service
systemctl --user stop   keep-awake-full.service

systemd-inhibit --list | grep keep-awake     # see the active lock
```

In the widget's popup, the **Allow display to sleep** switch selects which of the two services runs. Off = screen stays on (`--what=sleep:idle`), on = screen can sleep (`--what=sleep`). The setting is remembered.

Bind a global shortcut in **System Settings → Shortcuts → Custom Shortcuts** if you want a hotkey.

## 🛠️ How it works

```
┌──────────────────┐   start/stop   ┌──────────────────────────┐   acquires   ┌──────────────────┐
│  Plasma widget   │ ─────────────▶ │ keep-awake.service       │ ───────────▶ │ logind inhibit   │
│  (QML + Kirigami)│                │ (user systemd unit)      │              │ lock --what=sleep│
└──────────────────┘                └──────────────────────────┘              └──────────────────┘
        ▲                                                                              │
        │                          poll: systemctl --user is-active                    │
        └──────────────────────────────────────────────────────────────────────────────┘
```

There are two tiny user units, each one line:

```ini
# keep-awake.service        — inhibit suspend, allow screen-off (default)
ExecStart=/usr/bin/systemd-inhibit --what=sleep      --who=keep-awake --why=user-request --mode=block sleep infinity

# keep-awake-full.service   — inhibit suspend AND screen-off
ExecStart=/usr/bin/systemd-inhibit --what=sleep:idle --who=keep-awake --why=user-request --mode=block sleep infinity
```

Only one of the two runs at a time. The widget picks the right one based on the **Allow display to sleep** switch.

`systemd-inhibit` documents these inhibition types ([man page](https://www.freedesktop.org/software/systemd/man/latest/systemd-inhibit.html)):

- `sleep` — block suspend / hibernate
- `idle` — block automatic idle detection (this is what dims/blanks the screen)
- `shutdown` — block reboot/poweroff

We deliberately take **only `sleep`**, leaving `idle` free. So your screen-off / lock-screen / screensaver behavior is unaffected.

## 🆚 Comparison

| | Keep Awake (this) | KDE built-in "Block Sleep" | [Stimulator](https://flathub.org/apps/io.github.sigmasd.stimulator) | [Caffeine-ng](https://github.com/caffeine-ng/caffeine-ng) | `systemd-inhibit` CLI |
| --- | --- | --- | --- | --- | --- |
| Native Plasma widget | ✅ | ✅ | ❌ (standalone window) | ⚠️ tray indicator | ❌ |
| Lets screen turn off | ✅ | ❌ | ✅ (separate toggle) | ✅ (v1.2+) | ✅ (`--what=sleep`) |
| Survives panel reload | ✅ (systemd) | ✅ | ❌ | ⚠️ | ✅ |
| No external runtime | ✅ | ✅ | ❌ (Flatpak) | ❌ (Python) | ✅ |

## 🧪 Verify it's doing what you think

KDE's Powerdevil has had quirks around respecting `systemd-inhibit` ([bug 457859](https://bugs.kde.org/show_bug.cgi?id=457859), [bug 464119](https://bugs.kde.org/show_bug.cgi?id=464119)). Run this sanity check on your machine:

1. System Settings → Power Management → set **Turn off screen** to 1 min, **Suspend session** to 2 min.
2. Turn the widget **on**.
3. Walk away for 3 minutes.

You should see the screen go black around 1 min, but the system should still be awake when you come back (mouse-wiggle wakes the display instantly, no resume-from-suspend lag, no lid-light cycle).

```bash
# while it's running, sanity-check the lock exists:
systemd-inhibit --list | grep keep-awake
```

## ❓ FAQ

**Does this drain my battery like a normal "caffeine" tool?**
No more than necessary. The CPU still goes idle, the disk still parks, the display still turns off. We only block the *suspend* state transition.

**Will it prevent the system from sleeping when I close the lid?**
Yes, while the toggle is on. The inhibit lock blocks the suspend path regardless of trigger.

**What happens at logout / reboot?**
The user systemd service stops with the session, so the inhibit lock is released cleanly. State does **not** persist across reboots — you turn it on when you want it on.

**Will it work on Wayland / X11?**
Both. It doesn't touch the display server; it only talks to systemd-logind.

**Plasma 5?**
Not supported. The QML uses `org.kde.plasma.plasmoid` (the Plasma 6 PlasmoidItem API) and `org.kde.plasma.plasma5support`. Patches welcome if someone wants a Plasma 5 branch.

## 🧹 Uninstall

```bash
./uninstall.sh
```

Or manually:

```bash
systemctl --user stop keep-awake.service keep-awake-full.service
rm ~/.config/systemd/user/keep-awake.service ~/.config/systemd/user/keep-awake-full.service
systemctl --user daemon-reload
kpackagetool6 --type Plasma/Applet --remove com.burakgon.keepawake
```

## 🤝 Contributing

PRs welcome — especially for:

- Translations (i18n strings are wrapped in `i18n(...)`)
- Optional "Auto-on for N minutes/hours" timer mode, like Amphetamine sessions
- Per-application triggers (auto-on while a specific app/window is focused)
- Icon polish (a proper coffee-cup / pill icon set instead of `redshift-status-*`)
- Global hotkey integration (System Settings → Shortcuts is currently the way; a built-in shortcut would be nicer)

Open an issue first if it's a bigger change.

## 📄 License

[MIT](LICENSE). Do whatever you want with it; attribution appreciated.

---

<sub>Keywords: KDE Plasma 6 widget, KDE plasmoid, KDE applet, Amphetamine for Linux, Amphetamine alternative Linux, Caffeine alternative KDE, prevent sleep Linux, keep awake Linux, inhibit suspend KDE, systemd-inhibit GUI, Linux power management widget, stay awake KDE, no sleep KDE, KDE Plasma extension.</sub>
