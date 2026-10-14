#!/usr/bin/env bash
b=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
[ -z "$b" ] && exit 0
cap=$(cat "$b/capacity"); st=$(cat "$b/status")
n=$((cap * 8 / 100)); bar=""; rest=""
for ((i=0;i<n;i++)); do bar+="━"; done
for ((i=n;i<8;i++)); do rest+="━"; done
col="#6EE7B7"; [ "$cap" -le 15 ] && [ "$st" != "Charging" ] && col="#F87171"
pre=""; [ "$st" = "Charging" ] && pre="⚡ "
echo "$pre%{F$col}$bar%{F#2B3C52}$rest%{F-} $cap%"
