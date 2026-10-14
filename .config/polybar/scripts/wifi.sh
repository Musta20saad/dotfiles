#!/usr/bin/env bash
source ~/.config/polybar/scripts/lib.sh
s=$(nmcli -t -f TYPE,STATE device 2>/dev/null)
if   echo "$s" | grep -q '^wifi:connected';     then g=f1eb; c="#7DD3FC"
elif echo "$s" | grep -q '^ethernet:connected'; then g=f0e8; c="#7DD3FC"
else g=f1eb; c="#F87171"; fi
echo "%{F$c}%{T2}$(icon $g)%{T-}%{F-}"
