#!/usr/bin/env bash
# Caffeine KDE — uninstaller. Removes everything ./install.sh put in place.
set -euo pipefail

PKG_ID="com.burakgon.keepawake"
DESKTOP_ID="keep-awake-toggle.desktop"

echo "==> Stopping and removing user services"
systemctl --user stop keep-awake.service      2>/dev/null || true
systemctl --user stop keep-awake-full.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/keep-awake.service"
rm -f "$HOME/.config/systemd/user/keep-awake-full.service"
systemctl --user daemon-reload

echo "==> Removing plasmoid package"
kpackagetool6 --type Plasma/Applet --remove "$PKG_ID" 2>/dev/null || true

echo "==> Removing toggle helper and launcher"
rm -f "$HOME/.local/bin/keep-awake-toggle"
rm -f "$HOME/.local/share/applications/$DESKTOP_ID"
command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 --noincremental >/dev/null 2>&1 || true

echo "==> Removing global shortcut registration"
python3 - "$DESKTOP_ID" <<'EOF' 2>/dev/null || true
import sys, os
cfg = os.path.expanduser('~/.config/kglobalshortcutsrc')
want = (f'[services][{sys.argv[1]}]', f'[{sys.argv[1]}]')
lines = open(cfg).read().splitlines(keepends=True)
out, skip = [], False
for ln in lines:
    if ln.strip() in want:
        skip = True
        continue
    if skip and ln.startswith('['):
        skip = False
    if not skip:
        out.append(ln)
open(cfg, 'w').writelines(out)
print('shortcut entry removed (re-login if the key still fires)')
EOF

echo "Done. Remove the widget from your panel if it's still there."
