#!/usr/bin/env bash
source ~/.config/polybar/scripts/lib.sh
command -v brightnessctl >/dev/null || exit 0
p=$(brightnessctl -m | cut -d, -f4 | tr -d %)
echo "%{F#7DD3FC}%{T2}$(icon f185)%{T-}%{F-} ${p}%"
