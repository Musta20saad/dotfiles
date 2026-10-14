# My i3 setup

Restore on a fresh Linux Mint install:

    sudo apt install -y i3 polybar picom rofi dunst flameshot fonts-font-awesome brightnessctl pavucontrol autotiling udiskie python3-i3ipc
    cp -r .config/* ~/.config/
    dconf load /org/gnome/terminal/ < gnome-terminal.dconf

Then log into i3. The wallpaper path in the i3 config may need updating.
