#!/usr/bin/env bash
source ~/.config/polybar/scripts/lib.sh
command -v bluetoothctl >/dev/null || exit 0
if bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
  if [ -n "$(bluetoothctl devices Connected 2>/dev/null)" ]; then c="#7DD3FC"; else c="#E6F1FF"; fi
else c="#7C93AD"; fi
echo "%{F$c}%{T2}$(icon f293)%{T-}%{F-}"
