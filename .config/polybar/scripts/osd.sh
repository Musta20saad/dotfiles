#!/usr/bin/env bash
# On-screen display for volume / brightness keys (few process spawns = snappy).
#   osd.sh volume up|down|mute      osd.sh brightness up|down
STEP=5
TAG=(-h string:x-dunst-stack-tag:osd)

show() { notify-send -u low -t 1500 "${TAG[@]}" -h "int:value:$2" "$1" "$3" & }

getvol()  { local o; o=$(pactl get-sink-volume @DEFAULT_SINK@); if [[ $o =~ ([0-9]+)% ]]; then V=${BASH_REMATCH[1]}; else V=0; fi; }
getmute() { local o; o=$(pactl get-sink-mute @DEFAULT_SINK@); M=${o##* }; }

case "$1" in
  volume)
    case "$2" in
      up)
        getvol
        if [ "$V" -ge 100 ]; then n=$V; else n=$((V + STEP)); [ "$n" -gt 100 ] && n=100; fi
        pactl set-sink-mute @DEFAULT_SINK@ 0 &
        pactl set-sink-volume @DEFAULT_SINK@ "${n}%"
        show "Volume" "$n" "${n}%" ;;
      down)
        getvol
        n=$((V - STEP)); [ "$n" -lt 0 ] && n=0
        pactl set-sink-volume @DEFAULT_SINK@ "${n}%"
        show "Volume" "$n" "${n}%" ;;
      mute)
        getmute
        if [ "$M" = yes ]; then
          pactl set-sink-mute @DEFAULT_SINK@ 0
          getvol
          show "Volume" "$V" "${V}%"
        else
          pactl set-sink-mute @DEFAULT_SINK@ 1
          show "Volume" 0 "Muted"
        fi ;;
    esac ;;
  brightness)
    case "$2" in
      up)   out=$(brightnessctl -m set "${STEP}%+") ;;
      down) out=$(brightnessctl -m -n set "${STEP}%-") ;;
    esac
    if [[ $out =~ ,([0-9]+)%, ]]; then p=${BASH_REMATCH[1]}
    else out=$(brightnessctl -m); if [[ $out =~ ,([0-9]+)%, ]]; then p=${BASH_REMATCH[1]}; else p=0; fi; fi
    show "Brightness" "$p" "${p}%"
    polybar-msg action "#brightness.hook.0" >/dev/null 2>&1 &
    ;;
esac
wait
