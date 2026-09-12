#!/usr/bin/env bash
set -euo pipefail

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/serpantinum/wallpaper"
WP="$HOME/Pictures/Wallpapers/wallpaper.png"

[[ -f "$WP" ]] || exit 0

# Обойной движок Serpantinum хранит выбранные обои в current_<screen>.
# Если выбор уже есть (в т.ч. сделанный вручную пикером) — не трогаем.
if ls "$CACHE"/current_* >/dev/null 2>&1; then
  exit 0
fi

# Ждём, пока IPC шелла поднимется (daemon стартует вместе с Hyprland).
for _ in $(seq 1 30); do
  if serpantinum ipc call wallpaper getWallpaperPath "" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

serpantinum ipc call wallpaper setWallpaper all "$WP" fade >/dev/null 2>&1 || true