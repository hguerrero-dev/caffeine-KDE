#!/usr/bin/env bash
# Keep Awake — register global shortcut Super+Alt+C (override: ./setup-shortcut.sh "Meta+Alt+X")
#
# Plasma 6 mechanism (no khotkeys anymore):
#   1. ~/.local/share/applications/keep-awake-toggle.desktop  (the toggle command)
#   2. ~/.config/kglobalshortcutsrc  group [keep-awake-toggle.desktop]  key _launch
#   3. Runtime registration with KWin's kglobalaccel over D-Bus (no logout needed).
#
# Safe to re-run: if the entry already exists it only re-registers it live.
set -euo pipefail

KEY="${1:-Meta+Alt+C}"
TOGGLE_CMD="$HOME/.local/bin/keep-awake-toggle"
DESKTOP_ID="keep-awake-toggle.desktop"
DESKTOP_FILE="$HOME/.local/share/applications/$DESKTOP_ID"
GLOBAL="$HOME/.config/kglobalshortcutsrc"
NAME="Keep Awake"

if [[ ! -x "$TOGGLE_CMD" ]]; then
    echo "ERROR: $TOGGLE_CMD not found. Run ./install.sh first."
    exit 1
fi

echo "==> Backing up $GLOBAL to /tmp (once)"
cp -n "$GLOBAL" /tmp/kglobalshortcutsrc.bak-keepawake 2>/dev/null || true

echo "==> Writing $DESKTOP_FILE"
mkdir -p "$(dirname "$DESKTOP_FILE")"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=$NAME
GenericName=Toggle screen awake lock
Comment=Toggle Keep Awake: keep system and screen on, or return to normal
Exec=$TOGGLE_CMD
Icon=preferences-system-power-management
Terminal=false
Categories=Utility;
StartupNotify=false
X-KDE-GlobalAccel-CommandShortcut=true
EOF

if command -v kbuildsycoca6 >/dev/null 2>&1; then
    echo "==> Refreshing application cache"
    kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
fi

echo "==> Registering _launch = $KEY in kglobalshortcutsrc ([services] group)"
kwriteconfig6 --file kglobalshortcutsrc --group services --group "$DESKTOP_ID" --key _launch "$KEY,none,$NAME"
kwriteconfig6 --file kglobalshortcutsrc --group services --group "$DESKTOP_ID" --key _k_friendly_name "$NAME"

echo "==> Activating live in this session (D-Bus → KWin kglobalaccel)"
python3 - "$KEY" <<'EOF'
import sys
import dbus

key_name = sys.argv[1]
# Qt key code: Meta(0x10000000) | Alt(0x08000000) | letter.
# Only Meta+Alt+<letter> is supported by this script.
letter = key_name.split('+')[-1].upper()
if not (key_name.startswith('Meta+Alt+') and len(letter) == 1 and 'A' <= letter <= 'Z'):
    print(f'ERROR: unsupported key format: {key_name}')
    sys.exit(1)
KEY = 0x10000000 | 0x08000000 | ord(letter)
COMP = 'keep-awake-toggle.desktop'
ACT = '_launch'
FRIENDLY = 'Keep Awake'
AID = [COMP, ACT, FRIENDLY, FRIENDLY]

bus = dbus.SessionBus()
accel = dbus.Interface(bus.get_object('org.kde.kglobalaccel', '/kglobalaccel'),
                       'org.kde.KGlobalAccel')

before = accel.getGlobalShortcutsByKey(KEY)
# struct: (action, friendlyName, component, ...)
others = [t for t in before if not (str(t[0]) == ACT and str(t[2]) == COMP)]
if others:
    print(f'WARNING: {key_name} is already used by: {[(t[0], t[1]) for t in others]}')
    print('Choose another key: ./setup-shortcut.sh "Meta+Alt+X"')
    sys.exit(1)

accel.doRegister(AID)
seq = dbus.Array(
    [dbus.Struct([dbus.Array([dbus.Int32(KEY)], signature='i')],
                 signature='(ai)')],
    signature='a(ai)')
accel.setForeignShortcutKeys(AID, seq)

active = accel.shortcutKeys(AID)
print(f'Active keys for {COMP} {ACT}: {active}')
bound = [(str(t[0]), str(t[1]), str(t[2])) for t in accel.getGlobalShortcutsByKey(KEY)]
print(f'Lookup by key: {bound}')
if (ACT, FRIENDLY, COMP) in bound:
    print(f'OK: {key_name} is live.')
else:
    print(f'NOTE: key not yet active in this session (a logout/login will apply it).')
EOF

echo
echo "Done. Press $KEY to toggle Keep Awake."
echo "The widget icon follows automatically (it polls systemd every 2s)."
echo "Manage it later in System Settings → Keyboard → Shortcuts → Keep Awake."
