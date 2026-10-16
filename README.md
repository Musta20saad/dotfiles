# i3 setup: light-blue, floating and minimal

A clean, modern i3 desktop for Linux Mint. Floating rounded top bar, translucent rounded windows,
a matching app launcher, Wi-Fi and Bluetooth menus, and on-screen popups for volume and brightness.
Everything uses one light-blue palette.

## What's in this repo

| Path | What it configures |
|---|---|
| `.config/i3/` | i3 window manager: keybindings, gaps, startup programs |
| `.config/polybar/` | the top bar, plus `scripts/` for the menus, battery, volume, workspaces and update indicator |
| `.config/picom/` | compositor: rounded corners, shadows, quick fades, dimming of inactive windows |
| `.config/rofi/` | app launcher (`Mod+d`) |
| `.config/dunst/` | notifications and the volume/brightness popup |
| `.config/i3status/` | the original status bar config, unused since the move to Polybar |
| `gnome-terminal.dconf` | terminal colors and font |
| `backup.sh` | copies the configs into this repo and pushes to GitHub |

## Features

- **Bar:** workspaces 1 to 4 always shown (click to switch), date and clock in the middle, and on the right CPU, RAM,
  update indicator, Bluetooth, Wi-Fi, volume, brightness and battery. Colored icons, no emoji.
- **Wi-Fi menu** (click the icon): on/off switch, signal bars and security type, saved networks listed apart from others,
  connect with a password prompt, hidden networks, rescan. `Alt+Enter` on a network opens details
  (IP, router, DNS, band, speed), auto-join toggle and forget.
- **Bluetooth menu** (click the icon): on/off switch, paired devices with battery level, connect or disconnect with Enter,
  pair nearby devices from the list, `Alt+Enter` to forget a device.
- **Volume and brightness popup:** a bar at the bottom of the screen like Cinnamon's. Volume is capped at 100%.
- **Update indicator:** counts what an upgrade would really install. Click it to open Update Manager, right-click to recount.
- **Glass look:** translucent terminal with a blur behind it. `~/.config/picom/glass off` turns it off, `glass on` brings it back,
  `glass 25` sets the terminal transparency and `glass strength 2` sets the blur strength (lower is lighter on the GPU).
- **Auto tiling:** each new window splits the longer side of the focused one, so layouts balance themselves.
- **USB drives** mount automatically (`udiskie`). Eject everything with `Mod+Shift+u`.
- **Screenshots:** `Print` opens Flameshot. Copy with `Ctrl+C`, then paste anywhere.

## Keybindings

`Mod` is the Windows key.

| Keys | Action |
|---|---|
| `Mod+Return` | terminal |
| `Mod+d` | app launcher |
| `Mod+Shift+q` | close window |
| `Mod+1` to `Mod+9` | go to workspace |
| `Mod+Shift+1` to `Mod+Shift+9` | move window to workspace |
| `Mod+arrows` / `Mod+Shift+arrows` | focus / move window |
| `Mod+h` / `Mod+v` | split horizontally / vertically |
| `Mod+f` | fullscreen |
| `Mod+s` / `Mod+w` / `Mod+e` | stacking / tabbed / split layout |
| `Mod+Shift+space` | toggle floating |
| `Mod+drag` | left button moves, right button resizes a floating window |
| `Mod+minus` / `Mod+Shift+minus` | show / send to scratchpad |
| `Mod+Shift+u` | unmount USB drives |
| `Mod+Shift+e` | power menu (logout, suspend, reboot, shutdown) |
| `Mod+Shift+c` / `Mod+Shift+r` | reload / restart i3 |
| `Print` | screenshot |
| volume and brightness keys | adjust with an on-screen popup |

## Colors

| Use | Color |
|---|---|
| Background | `#0F1A2B` |
| Panels | `#162338` |
| Text | `#E6F1FF` |
| Dim text | `#7C93AD` |
| Accent | `#7DD3FC` |
| Volume | `#93C5FD` |
| Good / charging | `#6EE7B7` |
| Warning | `#FDE68A` |
| Danger | `#F87171` |

## What changed from a default i3 setup

- Replaced i3bar with a floating, rounded, translucent Polybar and removed the system tray.
  WiFi, Bluetooth, updates, volume, brightness and battery are drawn by small scripts instead.
- Added picom with rounded corners, shadows, quick fades, and a glass effect: the terminal is translucent with blur behind it.
  Only translucent windows are blurred and inactive windows are dimmed instead of made see-through, which keeps it light on the GPU.
  `start-picom.sh` makes sure picom is running at login and falls back to a simpler renderer if needed.
- Removed window borders and title bars so the rounded corners show cleanly. Gaps are 4px inside and 2px outside.
- Workspaces are plain numbers, with 1 to 4 always visible in the bar.
- Added autotiling, USB auto-mount, a Flameshot screenshot key and a rofi power menu.
- Added a themed rofi launcher, a high-contrast terminal theme and dunst popups for volume and brightness.
- Wi-Fi and Bluetooth menus open instantly from cached data and only one copy can run at a time.
- Volume and brightness scripts use few process spawns, so holding a key stays smooth.

## Restore on a new Linux Mint install

    sudo apt install -y i3 polybar picom rofi dunst flameshot fonts-font-awesome brightnessctl pavucontrol \
        udiskie python3-i3ipc libnotify-bin blueman network-manager-gnome numlockx feh exfatprogs ntfs-3g
    pip3 install --user --break-system-packages autotiling
    cp -r .config/* ~/.config/
    dconf load /org/gnome/terminal/ < gnome-terminal.dconf
    chmod +x ~/.config/polybar/*.sh ~/.config/polybar/scripts/*.sh

Then log into i3. Things you may need to adjust:

- the wallpaper path in `.config/i3/config`
- the battery name in the polybar scripts if yours isn't `BAT0`
- the workspace count (`N` in `.config/polybar/scripts/workspaces.py`)

## Where to tweak things

| To change | Edit |
|---|---|
| bar height, position, modules | `.config/polybar/config.ini` |
| bar icon colors | the scripts in `.config/polybar/scripts/` |
| Wi-Fi and Bluetooth menu look | `.config/polybar/scripts/menu.rasi` |
| popup position and style | `.config/dunst/dunstrc` |
| window effects | `.config/picom/picom.conf` or the `glass` command |
| gaps and keybindings | `.config/i3/config` |

## Backup

After changing anything, run `~/dotfiles/backup.sh`. It copies the configs here, commits and pushes.
