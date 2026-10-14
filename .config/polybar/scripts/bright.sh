#!/usr/bin/env bash
case "$1" in
  up)   brightnessctl set 5%+ ;;
  down) brightnessctl -n set 5%- ;;
esac
polybar-msg action "#brightness.hook.0" >/dev/null 2>&1
