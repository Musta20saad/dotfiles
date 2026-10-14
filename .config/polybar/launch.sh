#!/usr/bin/env bash
pkill -f "pactl subscribe"; pkill -f scripts/battery.sh; pkill -f scripts/workspaces.py; killall -q polybar
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.2; done
polybar main &
