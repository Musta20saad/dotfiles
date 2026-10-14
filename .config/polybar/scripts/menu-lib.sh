#!/usr/bin/env bash
# Shared helpers for the Wi-Fi / Bluetooth menus (sourced, not run directly)

shopt -u patsub_replacement 2>/dev/null   # keep "&" literal in ${var//x/&y}

ACC="#7DD3FC"
DIM="#7C93AD"
SD="$HOME/.config/polybar/scripts"
THEME_FILE="$SD/menu.rasi"

# escape text for pango markup
esc() {
  local s=$1
  s=${s//&/&amp;}
  s=${s//</&lt;}
  s=${s//>/&gt;}
  printf '%s' "$s"
}

notify() { notify-send -t "${3:-3000}" "$1" "$2"; }

# run something in the background without it holding the menu lock
bg() { "$@" >/dev/null 2>&1 9>&- & }

# one menu at a time, and ignore the click that just closed it
guard() {
  local name=$1 stamp="/tmp/.menu-$1-closed" now last
  if [ -r "$stamp" ]; then
    now=$(date +%s%3N)
    last=$(cat "$stamp" 2>/dev/null)
    [ $((now - ${last:-0})) -lt 450 ] && return 1
  fi
  exec 9>"/tmp/.menu-$name.lock"
  flock -n 9 || return 1
  trap "date +%s%3N > '$stamp'" EXIT
}

# toggle switch drawn with text
switch() {
  if [ "$1" = on ]; then
    printf "<span foreground='%s'>━━●  On</span>" "$ACC"
  else
    printf "<span foreground='%s'>●━━  Off</span>" "$DIM"
  fi
}

# "Label        value" row
kv() { printf "<span foreground='%s'>%-13s</span>%s" "$DIM" "$1" "$(esc "$2")"; }

# usage: rofi_menu "Prompt" "message" < rows     (sets IDX and RC)
# RC: 0 = Enter, 10 = Alt+Enter, 1 = cancelled
rofi_menu() {
  local out
  out=$(rofi -dmenu -i -markup-rows -no-custom -no-show-icons -disable-history \
        -format i -p "$1" ${2:+-mesg "$2"} -kb-custom-1 "Alt+Return" \
        -theme-str "$(<"$THEME_FILE")")
  RC=$?
  IDX=$out
}

# text prompt (empty list). usage: ask "Prompt" "message" [1 = hide typing]
ask() {
  local extra=()
  [ "$3" = 1 ] && extra=(-password)
  rofi -dmenu "${extra[@]}" -p "$1" -mesg "$2" -no-show-icons -disable-history \
       -theme-str "$(<"$THEME_FILE") listview { lines: 0; }" < /dev/null
}

# yes/no. usage: confirm "message"   (returns 0 when confirmed)
confirm() {
  rofi_menu "Confirm" "$1" < <(printf '%s\n' "Yes, continue" "Cancel")
  [ "$RC" = 0 ] && [ "$IDX" = 0 ]
}
