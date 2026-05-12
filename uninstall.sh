#!/usr/bin/env bash
set -euo pipefail

PKG_ID="com.burakgon.keepawake"

echo "==> Stopping and removing user services"
systemctl --user stop keep-awake.service      2>/dev/null || true
systemctl --user stop keep-awake-full.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/keep-awake.service"
rm -f "$HOME/.config/systemd/user/keep-awake-full.service"
systemctl --user daemon-reload

echo "==> Removing plasmoid package"
kpackagetool6 --type Plasma/Applet --remove "$PKG_ID" 2>/dev/null || true

echo "Done."
