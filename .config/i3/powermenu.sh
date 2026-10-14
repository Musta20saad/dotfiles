#!/usr/bin/env bash
choice=$(printf "Logout\nSuspend\nReboot\nShutdown" | rofi -dmenu -i -p "Power")
case "$choice" in
  Logout)   i3-msg exit ;;
  Suspend)  systemctl suspend ;;
  Reboot)   systemctl reboot ;;
  Shutdown) systemctl poweroff ;;
esac
