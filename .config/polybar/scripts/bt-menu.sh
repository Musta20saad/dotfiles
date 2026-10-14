#!/usr/bin/env bash
# Bluetooth menu. Enter = connect/disconnect/pair, Alt+Enter = options (forget)
source "$HOME/.config/polybar/scripts/menu-lib.sh"
guard bt || exit 0

if ! command -v bluetoothctl >/dev/null; then
  notify "Bluetooth" "bluetoothctl isn't installed"
  exit 0
fi

parse() { sed -n 's/^Device \([0-9A-Fa-f:]\{17\}\) \(.*\)$/\1|\2/p'; }
is_on() { bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; }

battery() { # mac -> percentage or empty
  bluetoothctl info "$1" 2>/dev/null | sed -n 's/.*Battery Percentage: 0x[0-9a-fA-F]* (\([0-9]*\)).*/\1/p'
}

bt_connect() { # mac name
  local out
  notify "Bluetooth" "Connecting to $2…" 2500
  out=$(timeout 15 bluetoothctl connect "$1" 2>&1)
  if grep -q 'Connection successful' <<<"$out"; then
    notify "Bluetooth" "Connected to $2"
  else
    notify "Bluetooth" "Couldn't connect to $2" 4000
  fi
}

bt_pair() { # mac name
  local out
  pkill -f 'bluetoothctl --timeout' 2>/dev/null     # pairing is flaky while scanning
  notify "Bluetooth" "Pairing with $2…" 4000
  out=$(timeout 30 bluetoothctl pair "$1" 2>&1)
  if grep -q 'Pairing successful' <<<"$out"; then
    bluetoothctl trust "$1" >/dev/null 2>&1
    out=$(timeout 15 bluetoothctl connect "$1" 2>&1)
    if grep -q 'Connection successful' <<<"$out"; then
      notify "Bluetooth" "Connected to $2"
    else
      notify "Bluetooth" "Paired with $2 but couldn't connect" 4000
    fi
  else
    notify "Bluetooth" "Couldn't pair with $2. If it needs a PIN, use Bluetooth settings." 6000
  fi
}

oadd() { ol+=("$1"); oa+=("$2"); }

dev_options() { # mac name connected
  local mac=$1 name=$2 conn=$3
  local -a ol oa
  while true; do
    ol=(); oa=()
    if [ "$conn" = 1 ]; then oadd "Disconnect" disc; else oadd "Connect" conn; fi
    oadd "Forget this device" forget
    oadd "‹  Back" back
    rofi_menu "${name:0:22}" "" < <(printf '%s\n' "${ol[@]}")
    [ "$RC" = 1 ] && exit 0
    [ -z "$IDX" ] && exit 0
    case "${oa[$IDX]}" in
      back) return 0 ;;
      conn) bt_connect "$mac" "$name"; exit 0 ;;
      disc)
        bluetoothctl disconnect "$mac" >/dev/null 2>&1
        notify "Bluetooth" "Disconnected from $name"
        exit 0 ;;
      forget)
        if confirm "Forget <b>$(esc "$name")</b>? You'll need to pair it again."; then
          bluetoothctl remove "$mac" >/dev/null 2>&1
          notify "Bluetooth" "Forgot $name"
          exit 0
        fi ;;
    esac
  done
}

declare -a labels acts
add() { labels+=("$1"); acts+=("$2"); }

started=0

while true; do
  labels=(); acts=()

  if ! is_on; then
    mesg="Bluetooth is off"
    add "$(printf '%-27s%s' 'Bluetooth' "$(switch off)")" toggle
    add "Bluetooth settings…" settings
    started=0
  else
    if [ "$started" = 0 ]; then
      bg bluetoothctl --timeout 12 scan on      # discover nearby devices while the menu is open
      started=1
    fi

    out=$(bluetoothctl devices Paired 2>/dev/null)
    [ -z "$out" ] && out=$(bluetoothctl paired-devices 2>/dev/null)
    mapfile -t paired < <(parse <<<"$out")
    mapfile -t connlist < <(bluetoothctl devices Connected 2>/dev/null | parse)

    unset isc isp; declare -A isc isp
    for d in "${connlist[@]}"; do isc[${d%%|*}]=1; done

    dv_mac=(); dv_name=(); dv_conn=()
    nr_mac=(); nr_name=()
    conn_names=()
    my_l=(); my_a=()

    # connected devices first, then the rest
    for pass in 1 0; do
      for d in "${paired[@]}"; do
        m=${d%%|*}; nm=${d#*|}
        isp[$m]=1
        c=0; [ -n "${isc[$m]}" ] && c=1
        [ "$c" != "$pass" ] && continue
        i=${#dv_mac[@]}
        dv_mac[i]=$m; dv_name[i]=$nm; dv_conn[i]=$c
        if [ "$c" = 1 ]; then
          conn_names+=("<b>$(esc "$nm")</b>")
          b=$(battery "$m")
          right=""; [ -n "$b" ] && right="<span foreground='$DIM'>${b}%</span>"
          mark="<span foreground='$ACC'>✓ </span>"
        else
          right=""; mark="  "
        fi
        t=$nm; [ "${#t}" -gt 24 ] && t="${t:0:23}…"
        t=$(printf '%-24s' "$t")
        my_l+=("${mark}$(esc "$t")${right}"); my_a+=("dev:$i")
      done
    done

    mapfile -t all < <(bluetoothctl devices 2>/dev/null | parse)
    for d in "${all[@]}"; do
      m=${d%%|*}; nm=${d#*|}
      [ -n "${isp[$m]}" ] && continue
      [ "$nm" = "${m//:/-}" ] && continue       # unnamed devices
      i=${#nr_mac[@]}
      nr_mac[i]=$m; nr_name[i]=$nm
    done

    if [ "${#conn_names[@]}" -gt 0 ]; then
      mesg="Connected: $(IFS=,; echo "${conn_names[*]}" | sed 's/,/, /g')"
    else
      mesg="No devices connected"
    fi
    mesg+=$'\n'"<span foreground='$DIM' size='small'>Enter: connect   ·   Alt+Enter: options</span>"

    add "$(printf '%-27s%s' 'Bluetooth' "$(switch on)")" toggle
    if [ "${#my_l[@]}" -gt 0 ]; then
      add "<span foreground='$DIM' size='small'>MY DEVICES</span>" noop
      for i in "${!my_l[@]}"; do add "${my_l[$i]}" "${my_a[$i]}"; done
    fi
    add "<span foreground='$DIM' size='small'>NEARBY DEVICES</span>" noop
    if [ "${#nr_mac[@]}" -gt 0 ]; then
      for i in "${!nr_mac[@]}"; do
        add "  $(esc "${nr_name[$i]}")" "near:$i"
      done
    else
      add "<span foreground='$DIM'>  Searching…</span>" noop
    fi
    add "Refresh nearby devices" refresh
    add "Bluetooth settings…" settings
  fi

  rofi_menu "Bluetooth" "$mesg" < <(printf '%s\n' "${labels[@]}")
  [ "$RC" = 1 ] && exit 0
  [ -z "$IDX" ] && exit 0
  act=${acts[$IDX]}

  case "$act" in
    noop) ;;
    toggle)
      if is_on; then
        bluetoothctl power off >/dev/null 2>&1
      else
        rfkill unblock bluetooth 2>/dev/null
        bluetoothctl power on >/dev/null 2>&1
      fi
      sleep 0.6; started=0 ;;
    refresh)
      bg bluetoothctl --timeout 12 scan on
      sleep 2 ;;
    settings)
      bg blueman-manager
      exit 0 ;;
    dev:*)
      i=${act#dev:}
      if [ "$RC" = 10 ]; then
        dev_options "${dv_mac[$i]}" "${dv_name[$i]}" "${dv_conn[$i]}"
      elif [ "${dv_conn[$i]}" = 1 ]; then
        bluetoothctl disconnect "${dv_mac[$i]}" >/dev/null 2>&1
        notify "Bluetooth" "Disconnected from ${dv_name[$i]}"
        exit 0
      else
        bt_connect "${dv_mac[$i]}" "${dv_name[$i]}"
        exit 0
      fi ;;
    near:*)
      i=${act#near:}
      bt_pair "${nr_mac[$i]}" "${nr_name[$i]}"
      exit 0 ;;
  esac
done
