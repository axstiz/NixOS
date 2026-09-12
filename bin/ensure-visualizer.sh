#!/usr/bin/env bash
set -euo pipefail

WIDGETS_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/serpantinum/widgets"
mkdir -p "$WIDGETS_STATE"

# Ждём, пока IPC шелла поднимется.
for _ in $(seq 1 30); do
  if serpantinum ipc call wallpaper getWallpaperPath "" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

# Мониторы берём из самого композитора (без jq).
command -v hyprctl >/dev/null 2>&1 || exit 0
MONITORS=$(hyprctl monitors 2>/dev/null | awk '/^Monitor/{print $2}')

for M in $MONITORS; do
  SAFE=${M//[^a-zA-Z0-9_-]/_}
  LAYOUT="$WIDGETS_STATE/$SAFE/layout.json"

  # Виджет уже есть (в т.ч. настроен вручную в Guide -> Display -> Widgets) — не трогаем.
  if grep -qE '"wType"[[:space:]]*:[[:space:]]*"visualizer"' "$LAYOUT" 2>/dev/null; then
    continue
  fi

  # Добавляем виджет-визуализатор (bars) и сохраняем разметку через родной IPC.
  serpantinum ipc call "widgets-$SAFE" add decl_visualizer visualizer 300 430 880 180 1 "" 0 >/dev/null 2>&1 || true
  serpantinum ipc call "widgets-$SAFE" reload >/dev/null 2>&1 || true
done