#!/usr/bin/env bash
# Copies your configs into ~/dotfiles, commits and pushes to GitHub.
cd "$HOME/dotfiles" || exit 1
mkdir -p .config
for d in i3 polybar picom i3status rofi dunst; do
  rm -rf ".config/$d"
  [ -d "$HOME/.config/$d" ] && cp -r "$HOME/.config/$d" .config/
done
command -v dconf >/dev/null && dconf dump /org/gnome/terminal/ > gnome-terminal.dconf
git add -A
git commit -q -m "Update dotfiles $(date +%F)" || echo "No changes to save"
if git remote get-url origin >/dev/null 2>&1; then git push -q && echo "Backed up to GitHub"; fi
