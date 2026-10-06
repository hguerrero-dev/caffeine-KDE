#!/usr/bin/env bash
# Caffeine KDE — unified installer. Run ./install.sh and you're done.
#
# What it does, in order:
#   1. Installs the user systemd units (the actual inhibit locks).
#   2. Installs/upgrades the Plasma widget (coffee cup).
#   3. Installs the `keep-awake-toggle` command helper.
#   4. Registers the global shortcut Super+Alt+C (via ./setup-shortcut.sh).
#   5. Offers to restart Plasma so the widget reloads immediately.
#
# Re-running is safe (idempotent): every step can run twice without duplicates.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHORTCUT_KEY="${SHORTCUT_KEY:-Meta+Alt+C}"

echo "==> [1/5] Installing user systemd services"
mkdir -p "$HOME/.config/systemd/user"
cp "$REPO_DIR/systemd/keep-awake.service"      "$HOME/.config/systemd/user/keep-awake.service"
cp "$REPO_DIR/systemd/keep-awake-full.service" "$HOME/.config/systemd/user/keep-awake-full.service"
systemctl --user daemon-reload

echo "==> [2/5] Installing plasmoid package"
PKG_ID="com.burakgon.keepawake"
if kpackagetool6 --type Plasma/Applet --list 2>/dev/null | grep -q "^${PKG_ID}$"; then
    kpackagetool6 --type Plasma/Applet --upgrade "$REPO_DIR/package"
else
    kpackagetool6 --type Plasma/Applet --install "$REPO_DIR/package"
fi

echo "==> [3/5] Installing toggle helper"
mkdir -p "$HOME/.local/bin"
cp "$REPO_DIR/toggle.sh" "$HOME/.local/bin/keep-awake-toggle"
chmod +x "$HOME/.local/bin/keep-awake-toggle"

echo "==> [4/5] Registering global shortcut ($SHORTCUT_KEY)"
if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] || [[ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]]; then
    SHORTCUT_KEY="$SHORTCUT_KEY" bash "$REPO_DIR/setup-shortcut.sh" || {
        echo "WARNING: shortcut registration failed. Re-run ./setup-shortcut.sh later."
    }
else
    echo "WARNING: no D-Bus/session detected, skipping live shortcut registration."
    echo "         Run ./setup-shortcut.sh from your graphical session later."
fi

echo "==> [5/5] Reload Plasma widget"
RESTART="n"
if [[ -t 0 ]]; then
    read -r -p "Restart Plasma shell now to reload the widget? [Y/n] " RESTART || true
    [[ -z "$RESTART" ]] && RESTART="y"
fi
if [[ "$RESTART" =~ ^[YySs]$ ]]; then
    systemctl --user restart plasma-plasmashell.service
    sleep 2
    echo "Plasma reloaded."
else
    echo "Skipped. The new widget loads after you re-login or restart Plasma."
fi

echo
echo "Done. ☕"
echo "Add the widget: right-click panel/desktop → Add Widgets → search 'Caffeine KDE'."
echo "Toggle:        single left-click the coffee cup, or press $SHORTCUT_KEY anywhere."
echo "  ON  = cup with orange steam → system + screen stay awake."
echo "  OFF = plain cup             → normal power management."
echo "Manual:        keep-awake-toggle"
echo "Change key:    SHORTCUT_KEY=\"Meta+Alt+X\" ./setup-shortcut.sh"
