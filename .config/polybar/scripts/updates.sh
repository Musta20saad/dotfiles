#!/usr/bin/env bash
source ~/.config/polybar/scripts/lib.sh
# recount only when apt's package lists or dpkg's state changed, otherwise reuse the last answer
cache=/tmp/.polybar-updates
key="$(stat -c %Y /var/lib/dpkg/status 2>/dev/null)-$(stat -c %Y /var/lib/apt/lists 2>/dev/null)"
if [ -r "$cache" ] && [ "$(sed -n 1p "$cache")" = "$key" ]; then
  n=$(sed -n 2p "$cache")
else
  # what an upgrade would really install (skips held-back and phased packages)
  n=$(apt-get -s dist-upgrade 2>/dev/null | grep -c '^Inst')
  printf '%s\n%s\n' "$key" "$n" > "$cache"
fi
if [ "${n:-0}" -gt 0 ]; then
  echo "%{F#FDE68A}%{T2}$(icon f021)%{T-}%{F-} $n"
else
  echo "%{F#7C93AD}%{T2}$(icon f021)%{T-}%{F-}"
fi
