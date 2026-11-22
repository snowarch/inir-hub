#!/usr/bin/env bash
# The plugin's part of its Hub page (plugin.json `choices`):
#   list          [{id, label, on, lead?, note?}]: a switch for the compact layout, then one chip per cava shape,
#                 cava colour, bar symbol set, progress bar and Directories look
#   toggle <id>   `compact` flips the layout; any other id picks that option; the theme is rewritten either way
#   leave         run by the Hub before it removes the plugin: the generated theme goes with it
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OWN="${XDG_CONFIG_HOME:-$HOME/.config}/inir/plugins"
SETTINGS="$OWN/rmpc.json"
SHAPES=(spectrum mirror top dense chunky densemirror)
COLORS=(gradient solid layers)
SYMBOLS=(blocks braille shades)
PROGRESS=(plain line dots rounded)
DIRS=(columns tree)

read_key() { sed -n 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p' "$SETTINGS" 2>/dev/null | head -1 || true; }

# cur <key> <default> <allowed...>: the saved value when it is one of the allowed ones, else the default
cur() {
  local key="$1" def="$2" v x; shift 2
  v="$(read_key "$key")"
  for x in "$@"; do [[ "$x" == "$v" ]] && { printf '%s' "$v"; return; }; done
  printf '%s' "$def"
}
in_list() { local x t="$1"; shift; for x in "$@"; do [[ "$x" == "$t" ]] && return 0; done; return 1; }

load() {
  SH="$(cur cava spectrum "${SHAPES[@]}")"
  # Before the colour had its own choice, `solid` and `layers` were saved as the style.
  local legacy; legacy="$(read_key cava)"
  if [[ ( "$legacy" == solid || "$legacy" == layers ) && -z "$(read_key color)" ]]; then CO="$legacy"
  else CO="$(cur color gradient "${COLORS[@]}")"; fi
  SY="$(cur symbols blocks "${SYMBOLS[@]}")"
  LA="$(cur layout full full compact)"
  PR="$(cur progress plain "${PROGRESS[@]}")"
  DI="$(cur dirs columns "${DIRS[@]}")"
}

save() {
  mkdir -p "$OWN"
  printf '{"cava": "%s", "color": "%s", "symbols": "%s", "layout": "%s", "progress": "%s", "dirs": "%s"}\n' \
    "$SH" "$CO" "$SY" "$LA" "$PR" "$DI" > "$SETTINGS.tmp" && mv -f "$SETTINGS.tmp" "$SETTINGS"
  bash "$HERE/render.sh" || true
}

case "${1:-list}" in
  leave)
    rm -f "$OWN/rmpc/theme.ron"
    rmdir "$OWN/rmpc" 2>/dev/null || true
    exit 0
    ;;
  toggle)
    id="${2:-}"
    load
    if [[ "$id" == compact ]]; then
      if [[ "$LA" == compact ]]; then LA=full; else LA=compact; fi
    elif in_list "$id" "${SHAPES[@]}";   then SH="$id"
    elif in_list "$id" "${COLORS[@]}";   then CO="$id"
    elif in_list "$id" "${SYMBOLS[@]}";  then SY="$id"
    elif in_list "$id" "${PROGRESS[@]}"; then PR="$id"
    elif in_list "$id" "${DIRS[@]}";     then DI="$id"
    else exit 2
    fi
    save
    ;;
esac

load
compact=false; [[ "$LA" == compact ]] && compact=true
printf '[{"id":"compact","label":"Compact layout","on":%s,"lead":true,"note":"For terminals smaller than about 110x28"}' "$compact"
chips() {   # prefix current ids...
  local prefix="$1" now="$2" x on; shift 2
  for x in "$@"; do
    on=false; [[ "$x" == "$now" ]] && on=true
    printf ',{"id":"%s","label":"%s%s","on":%s}' "$x" "$prefix" "$x" "$on"
  done
}
chips "shape: " "$SH" "${SHAPES[@]}"
chips "colour: " "$CO" "${COLORS[@]}"
chips "symbols: " "$SY" "${SYMBOLS[@]}"
chips "progress: " "$PR" "${PROGRESS[@]}"
chips "directories: " "$DI" "${DIRS[@]}"
printf ']\n'
