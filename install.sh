#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing user systemd services"
mkdir -p "$HOME/.config/systemd/user"
cp "$REPO_DIR/systemd/keep-awake.service"      "$HOME/.config/systemd/user/keep-awake.service"
cp "$REPO_DIR/systemd/keep-awake-full.service" "$HOME/.config/systemd/user/keep-awake-full.service"
systemctl --user daemon-reload

echo "==> Installing plasmoid package"
PKG_ID="com.burakgon.keepawake"
if kpackagetool6 --type Plasma/Applet --list 2>/dev/null | grep -q "^${PKG_ID}$"; then
    kpackagetool6 --type Plasma/Applet --upgrade "$REPO_DIR/package"
else
    kpackagetool6 --type Plasma/Applet --install "$REPO_DIR/package"
fi

echo
echo "Done."
echo "Add the widget: right-click panel/desktop → Add Widgets → search 'Keep Awake'."
echo "Toggle:        middle-click the tray icon, or open the popup and press the button."
echo "Display mode:  open the popup and use the 'Allow display to sleep' switch."
echo "Manual:        systemctl --user start|stop keep-awake.service       (display can sleep)"
echo "               systemctl --user start|stop keep-awake-full.service  (display stays on)"
