#!/usr/bin/env bash
# Starship custom module: path where EVERY depth level gets its own color.
# Palette cycles as the path gets deeper, so each folder level takes a
# new hue. fish-style shortening: leading segments shrink to 2 chars + …,
# the last two segments are kept whole so you can read where you are.
# Path root keeps the home icon; separator is a dim pipe.

COLORS=(
  '#cba6f7'  # mauve
  '#89b4fa'  # blue
  '#f5c2e7'  # pink
  '#fab387'  # peach
  '#94e2d5'  # teal
  '#f9e2af'  # yellow
)
SEP='#6c7086'  # dim separator

ROOT_ICON='󰋜'

fg() {
    local h="${1#\#}"
    printf '\033[38;2;%d;%d;%dm' \
        $((16#${h:0:2})) $((16#${h:2:2})) $((16#${h:4:2}))
}

p="$PWD"
if [[ "$p" == "$HOME" ]]; then
    printf '%s%s ~\033[0m\n' "$(fg '#cba6f7')" "$ROOT_ICON"
    exit 0
fi

rel=""
prefix=""
if [[ "$p" == "$HOME"* ]]; then
    rel="${p#"$HOME"/}"
    prefix="${ROOT_ICON} ~/"
else
    rel="${p#/}"
    prefix="/"
fi

IFS=/ read -ra parts <<< "$rel"
total=${#parts[@]}

out="$(fg '#cba6f7')${prefix%/}/"
sep="$(fg "$SEP")|"
for ((i=0; i<total; i++)); do
    seg="${parts[i]}"
    color="${COLORS[$(( i % ${#COLORS[@]} ))]}"
    if (( i < total - 2 && ${#seg} > 3 )); then
        seg="${seg:0:2}…"
    fi
    out+=$(fg "$color")"$seg"
    (( i < total - 1 )) && out+="$sep"
done

printf '%s\033[0m\n' "$out"
