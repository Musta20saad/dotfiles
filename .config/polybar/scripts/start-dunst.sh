#!/usr/bin/env bash
# Make sure dunst is the notification daemon (replaces whichever one is running)
conf="$HOME/.config/dunst/dunstrc"
pid=$(dbus-send --session --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus \
      org.freedesktop.DBus.GetConnectionUnixProcessID string:org.freedesktop.Notifications 2>/dev/null \
      | awk '/uint32/{print $2}')
if [ -n "$pid" ]; then
  if [ "$(cat /proc/$pid/comm 2>/dev/null)" = dunst ]; then
    dunstctl reload 2>/dev/null
    exit 0
  fi
  kill "$pid"
  sleep 0.5
fi
exec dunst -conf "$conf"
