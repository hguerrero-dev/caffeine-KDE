#!/usr/bin/env bash
# Keep Awake — toggle helper.
# Used by the keyboard shortcut (Super+Alt+C by default) and usable manually.
# Mirrors the widget logic: ON blocks suspend AND idle (screen stays on),
# OFF returns to normal power management. The widget polls systemd state,
# so its coffee-cup icon follows automatically a couple of seconds later.
set -uo pipefail

SLEEP_SVC="keep-awake.service"
FULL_SVC="keep-awake-full.service"

if systemctl --user is-active --quiet "$FULL_SVC" || systemctl --user is-active --quiet "$SLEEP_SVC"; then
    systemctl --user stop "$SLEEP_SVC" "$FULL_SVC"
    echo "Keep Awake: OFF (normal power management)"
else
    systemctl --user start "$FULL_SVC"
    echo "Keep Awake: ON (system and screen stay awake)"
fi
