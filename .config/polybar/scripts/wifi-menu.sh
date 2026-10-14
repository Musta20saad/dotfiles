#!/usr/bin/env bash
# Wi-Fi menu. Enter = connect, Alt+Enter = options (details / forget / auto-join)
source "$HOME/.config/polybar/scripts/menu-lib.sh"
guard wifi || exit 0

dev=$(nmcli -t -f DEVICE,TYPE device 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}')
if [ -z "$dev" ]; then
  notify "Wi-Fi" "No Wi-Fi adapter found"
  exit 0
fi

unesc() { printf '%s' "${1//\\:/:}"; }

# signal bars, filled part bright and the rest dim
bars() {
  local s=${1:-0} n=1 i on="" off=""
  local all=(▂ ▄ ▆ █)
  [ "$s" -ge 25 ] && n=2
  [ "$s" -ge 50 ] && n=3
  [ "$s" -ge 75 ] && n=4
  for i in 0 1 2 3; do
    if [ "$i" -lt "$n" ]; then on+=${all[$i]}; else off+=${all[$i]}; fi
  done
  printf "<span foreground='%s'>%s</span><span foreground='#33445C'>%s</span>" "$ACC" "$on" "$off"
}

seclabel() {
  case "$1" in
    ""|"--") echo "Open" ;;
    *WPA3*)  echo "WPA3" ;;
    *WPA2*)  echo "WPA2" ;;
    *WPA*)   echo "WPA" ;;
    *)       echo "${1%% *}" ;;
  esac
}

net_row() { # active signal security ssid
  local mark="  " name
  [ "$1" = 1 ] && mark="<span foreground='$ACC'>✓ </span>"
  if [ "${#4}" -gt 18 ]; then name="${4:0:17}…"; else name=$4; fi
  name=$(printf '%-18s' "$name")
  printf '%s%s  %s  <span foreground="%s">%s</span>' \
    "$mark" "$(bars "$2")" "$(esc "$name")" "$DIM" "$(seclabel "$3")"
}

# returns 0 when an attempt was made, 1 when the user backed out
connect_net() { # ssid security known
  local ssid=$1 sec=$2 known=$3 pw
  if [ "$known" = 1 ]; then
    notify "Wi-Fi" "Connecting to $ssid…" 2500
    if nmcli -w 25 connection up id "$ssid" ifname "$dev" >/dev/null 2>&1; then
      notify "Wi-Fi" "Connected to $ssid"
    else
      notify "Wi-Fi" "Couldn't connect to $ssid" 4000
    fi
    return 0
  fi
  if [ -n "$sec" ] && [ "$sec" != "--" ]; then
    pw=$(ask "Password" "Enter the password for <b>$(esc "$ssid")</b>" 1) || return 1
    [ -z "$pw" ] && return 1
    notify "Wi-Fi" "Connecting to $ssid…" 2500
    if nmcli -w 30 dev wifi connect "$ssid" password "$pw" ifname "$dev" >/dev/null 2>&1; then
      notify "Wi-Fi" "Connected to $ssid"
    else
      nmcli connection delete id "$ssid" >/dev/null 2>&1   # don't keep a profile with a wrong password
      notify "Wi-Fi" "Couldn't connect to $ssid. Wrong password?" 5000
    fi
  else
    notify "Wi-Fi" "Connecting to $ssid…" 2500
    if nmcli -w 25 dev wifi connect "$ssid" ifname "$dev" >/dev/null 2>&1; then
      notify "Wi-Fi" "Connected to $ssid"
    else
      notify "Wi-Fi" "Couldn't connect to $ssid" 4000
    fi
  fi
  return 0
}

oadd() { ol+=("$1"); oa+=("$2"); }

net_options() { # ssid known active security
  local ssid=$1 known=$2 active=$3 sec=$4
  local conn=$ssid auto="" ip gw dns line sg ch fq rt sc band
  local -a ol oa
  while true; do
    ol=(); oa=()
    if [ "$active" = 1 ]; then
      conn=$(nmcli -g GENERAL.CONNECTION device show "$dev" 2>/dev/null)
      ip=$(nmcli -g IP4.ADDRESS device show "$dev" 2>/dev/null | head -1)
      gw=$(nmcli -g IP4.GATEWAY device show "$dev" 2>/dev/null | head -1)
      dns=$(nmcli -g IP4.DNS device show "$dev" 2>/dev/null | paste -sd' ' -)
      line=$(nmcli -t -f IN-USE,SIGNAL,CHAN,FREQ,RATE,SECURITY dev wifi list --rescan no 2>/dev/null | grep '^\*' | head -1)
      IFS=: read -r _ sg ch fq rt sc <<<"$line"
      band=""
      if [ -n "$fq" ]; then
        if   [ "${fq%% *}" -ge 5925 ] 2>/dev/null; then band="6 GHz"
        elif [ "${fq%% *}" -ge 4900 ] 2>/dev/null; then band="5 GHz"
        else band="2.4 GHz"; fi
        [ -n "$ch" ] && band="$band · ch $ch"
      fi
      oadd "$(kv "IP address" "${ip%%/*}")" noop
      [ -n "$gw" ]   && oadd "$(kv "Router" "$gw")" noop
      [ -n "$dns" ]  && oadd "$(kv "DNS" "$dns")" noop
      [ -n "$sg" ]   && oadd "$(printf "<span foreground='%s'>%-13s</span>%s %s%%" "$DIM" "Signal" "$(bars "$sg")" "$sg")" noop
      [ -n "$band" ] && oadd "$(kv "Band" "$band")" noop
      [ -n "$rt" ]   && oadd "$(kv "Speed" "$rt")" noop
      [ -n "$sc" ]   && oadd "$(kv "Security" "$sc")" noop
      oadd "Disconnect" disc
    else
      oadd "Connect" conn
    fi
    if [ "$known" = 1 ]; then
      auto=$(nmcli -g connection.autoconnect connection show id "$conn" 2>/dev/null)
      if [ "$auto" = no ]; then auto=off; else auto=on; fi
      oadd "$(printf '%-27s%s' 'Auto-join' "$(switch "$auto")")" auto
      oadd "Forget this network" forget
    fi
    oadd "‹  Back" back

    rofi_menu "${ssid:0:22}" "" < <(printf '%s\n' "${ol[@]}")
    [ "$RC" = 1 ] && exit 0
    [ -z "$IDX" ] && exit 0
    case "${oa[$IDX]}" in
      noop) ;;
      back) return 0 ;;
      conn) connect_net "$ssid" "$sec" "$known" && exit 0 ;;
      disc)
        nmcli device disconnect "$dev" >/dev/null 2>&1
        notify "Wi-Fi" "Disconnected from $ssid"
        exit 0 ;;
      auto)
        if [ "$auto" = on ]; then
          nmcli connection modify id "$conn" connection.autoconnect no >/dev/null 2>&1
        else
          nmcli connection modify id "$conn" connection.autoconnect yes >/dev/null 2>&1
        fi ;;
      forget)
        if confirm "Forget <b>$(esc "$ssid")</b>? You'll need the password again."; then
          nmcli connection delete id "$conn" >/dev/null 2>&1
          notify "Wi-Fi" "Forgot $ssid"
          exit 0
        fi ;;
    esac
  done
}

declare -a labels acts
add() { labels+=("$1"); acts+=("$2"); }

bg nmcli dev wifi rescan      # refresh the scan cache for next time, never blocks the menu

while true; do
  labels=(); acts=()
  radio=$(nmcli radio wifi)

  if [ "$radio" != enabled ]; then
    mesg="Wi-Fi is off"
    add "$(printf '%-27s%s' 'Wi-Fi' "$(switch off)")" toggle
    add "Network settings…" settings
  else
    unset known seen; declare -A known seen
    n_ssid=(); n_sec=(); n_known=(); n_act=()
    kn_l=(); kn_a=(); ot_l=(); ot_a=()
    cur_label=""; cur_a=""; cur_ssid=""

    mapfile -t kn < <(nmcli -t -f NAME,TYPE connection show 2>/dev/null)
    for l in "${kn[@]}"; do
      [ "${l##*:}" = "802-11-wireless" ] && known["$(unesc "${l%:*}")"]=1
    done

    # cached scan results: instant, strongest first
    mapfile -t rows < <(nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list --rescan no 2>/dev/null | sort -t: -k2,2nr)
    for r in "${rows[@]}"; do
      IFS=: read -r inuse sig sec ssid <<<"$r"
      [ "$inuse" = "*" ] && cur_ssid=$(unesc "$ssid")
    done

    n=0
    for r in "${rows[@]}"; do
      IFS=: read -r inuse sig sec ssid <<<"$r"
      ssid=$(unesc "$ssid")
      [ -z "$ssid" ] && continue
      [ -n "${seen[$ssid]}" ] && continue
      seen[$ssid]=1
      isk=0; [ -n "${known[$ssid]}" ] && isk=1
      isa=0; [ "$ssid" = "$cur_ssid" ] && isa=1
      n_ssid[n]=$ssid; n_sec[n]=$sec; n_known[n]=$isk; n_act[n]=$isa
      row=$(net_row "$isa" "$sig" "$sec" "$ssid")
      if   [ "$isa" = 1 ]; then cur_label=$row; cur_a="net:$n"
      elif [ "$isk" = 1 ]; then kn_l+=("$row"); kn_a+=("net:$n")
      else                      ot_l+=("$row"); ot_a+=("net:$n")
      fi
      n=$((n + 1))
    done

    if [ -n "$cur_ssid" ]; then
      ip=$(nmcli -g IP4.ADDRESS device show "$dev" 2>/dev/null | head -1)
      mesg="Connected to <b>$(esc "$cur_ssid")</b>  ·  ${ip%%/*}"
    else
      mesg="Not connected"
    fi
    mesg+=$'\n'"<span foreground='$DIM' size='small'>Enter: connect   ·   Alt+Enter: options</span>"

    add "$(printf '%-27s%s' 'Wi-Fi' "$(switch on)")" toggle
    [ -n "$cur_label" ] && add "$cur_label" "$cur_a"
    if [ "${#kn_l[@]}" -gt 0 ]; then
      add "<span foreground='$DIM' size='small'>KNOWN NETWORKS</span>" noop
      for i in "${!kn_l[@]}"; do add "${kn_l[$i]}" "${kn_a[$i]}"; done
    fi
    if [ "${#ot_l[@]}" -gt 0 ]; then
      add "<span foreground='$DIM' size='small'>OTHER NETWORKS</span>" noop
      for i in "${!ot_l[@]}"; do add "${ot_l[$i]}" "${ot_a[$i]}"; done
    fi
    add "Scan again" rescan
    add "Join hidden network…" hidden
    add "Network settings…" settings
  fi

  rofi_menu "Wi-Fi" "$mesg" < <(printf '%s\n' "${labels[@]}")
  [ "$RC" = 1 ] && exit 0
  [ -z "$IDX" ] && exit 0
  act=${acts[$IDX]}

  case "$act" in
    noop) ;;
    toggle)
      if [ "$radio" = enabled ]; then nmcli radio wifi off; else nmcli radio wifi on; sleep 1.2; fi
      sleep 0.3 ;;
    rescan)
      notify "Wi-Fi" "Scanning…" 1500
      nmcli dev wifi rescan >/dev/null 2>&1
      sleep 2 ;;
    settings)
      bg nm-connection-editor
      exit 0 ;;
    hidden)
      s=$(ask "Network name" "Join a hidden network") || continue
      [ -z "$s" ] && continue
      p=$(ask "Password" "Password for <b>$(esc "$s")</b> (leave empty if it's open)" 1) || continue
      notify "Wi-Fi" "Connecting to $s…" 2500
      if [ -n "$p" ]; then
        nmcli -w 30 dev wifi connect "$s" password "$p" hidden yes ifname "$dev" >/dev/null 2>&1; ok=$?
      else
        nmcli -w 30 dev wifi connect "$s" hidden yes ifname "$dev" >/dev/null 2>&1; ok=$?
      fi
      if [ "$ok" = 0 ]; then
        notify "Wi-Fi" "Connected to $s"
      else
        nmcli connection delete id "$s" >/dev/null 2>&1
        notify "Wi-Fi" "Couldn't connect to $s" 4000
      fi
      exit 0 ;;
    net:*)
      i=${act#net:}
      if [ "$RC" = 10 ] || [ "${n_act[$i]}" = 1 ]; then
        net_options "${n_ssid[$i]}" "${n_known[$i]}" "${n_act[$i]}" "${n_sec[$i]}"
      else
        connect_net "${n_ssid[$i]}" "${n_sec[$i]}" "${n_known[$i]}" && exit 0
      fi ;;
  esac
done
