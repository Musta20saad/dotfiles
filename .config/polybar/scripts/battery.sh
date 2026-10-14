#!/usr/bin/env bash
source ~/.config/polybar/scripts/lib.sh
BACK=13
FWD=5
show() {
  b=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1); [ -z "$b" ] && return
  cap=$(<"$b/capacity")
  ac=0
  for f in /sys/class/power_supply/*/online; do
    [ -r "$f" ] && [ "$(<"$f")" = 1 ] && ac=1
  done
  if   [ "$cap" -ge 88 ]; then g=f240
  elif [ "$cap" -ge 63 ]; then g=f241
  elif [ "$cap" -ge 38 ]; then g=f242
  elif [ "$cap" -ge 13 ]; then g=f243
  else g=f244; fi
  col="#E6F1FF"; [ "$cap" -le 30 ] && col="#FDE68A"; [ "$cap" -le 15 ] && col="#F87171"
  if [ "$ac" = 1 ]; then
    col="#6EE7B7"
    echo "%{F$col}%{T2}$(icon $g)%{T-}%{O-$BACK}%{F#FFFFFF}%{T2}$(icon f0e7)%{T-}%{O$FWD}%{F-} $cap%"
  else
    echo "%{F$col}%{T2}$(icon $g)%{T-}%{F-} $cap%"
  fi
}
last=""
while true; do
  out=$(show)
  [ "$out" != "$last" ] && { echo "$out"; last="$out"; }
  sleep 1
done
