#!/usr/bin/env bash
# Polybar volume module: updates the instant the volume changes, with almost no process spawning
source ~/.config/polybar/scripts/lib.sh
C="#93C5FD"; R="#F87171"
G_MUTE=$(icon f026); G_LOW=$(icon f027); G_HIGH=$(icon f028)

show() {
  local out vol mute g
  out=$(pactl get-sink-volume @DEFAULT_SINK@)
  if [[ $out =~ ([0-9]+)% ]]; then vol=${BASH_REMATCH[1]}; else vol=0; fi
  out=$(pactl get-sink-mute @DEFAULT_SINK@)
  mute=${out##* }
  if [ "$mute" = yes ]; then
    echo "%{F$R}%{T2}$G_MUTE%{T-}%{F-}"
  else
    if   [ "$vol" -ge 50 ]; then g=$G_HIGH
    elif [ "$vol" -gt 0 ];  then g=$G_LOW
    else g=$G_MUTE; fi
    echo "%{F$C}%{T2}$g%{T-}%{F-} ${vol}%"
  fi
}

show
pactl subscribe | grep --line-buffered -E "on (sink|server)" | while read -r _; do
  while read -r -t 0.05 _; do :; done     # merge a burst of events into one redraw
  show
done
