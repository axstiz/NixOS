#!/usr/bin/env bash
# fastfetch (логотип + нагрузка) рисуется только если эта оболочка — первый
# kitty-терминал на текущем рабочем столе. При открытии второго терминала
# на том же столе (или новой вкладки) — ничего не выводим, чтобы не спамить.

if [ -z "${KITTY_WINDOW_ID:-}" ]; then
  # Мы не в kitty (vscode, emacs, и т.п.) — логотип не нужен.
  exit 0
fi

# Новая вкладка того же окна kitty (tab id > 1) — пропускаем.
if [ -n "${KITTY_TAB_ID:-}" ] && [ "$KITTY_TAB_ID" -gt 1 ] 2>/dev/null; then
  exit 0
fi

command -v fastfetch >/dev/null 2>&1 || exit 0
if ! command -v hyprctl >/dev/null 2>&1 || ! command -v python3 >/dev/null 2>&1; then
  fastfetch
  exit 0
fi

# Подсчёт kitty-окон на активном рабочем столе (без jq, через python3).
count=$(hyprctl clients -j 2>/dev/null | python3 -c '
import json, sys
try:
    clients = json.load(sys.stdin)
except Exception:
    sys.exit(2)
try:
    ws = json.loads(sys.argv[1])
except Exception:
    sys.exit(2)
n = 0
for c in clients:
    if str(c.get("class", "")).lower() == "kitty" and c.get("workspace", {}).get("id") == ws:
        n += 1
print(n)
' "$(hyprctl activeworkspace -j 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin).get("id"))' 2>/dev/null)" 2>/dev/null)

case "${count:-2}" in
  1) fastfetch ;;
esac
exit 0