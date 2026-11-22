#!/usr/bin/env bash
# The plugin's part of its Hub page (plugin.json `choices`):
#   list          [{id, label, on, lead?, note?}]: a switch for the compact layout, then one chip per cava shape,
#                 per cava colour and per bar symbol set
#   toggle <id>   `compact` flips the layout; a shape, colour or symbol id picks it; the theme is rewritten either way
#   leave         run by the Hub before it removes the plugin: the generated theme goes with it
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OWN="${XDG_CONFIG_HOME:-$HOME/.config}/inir/plugins"
SETTINGS="$OWN/rmpc.json"      # {"cava": "<shape>", "color": "<mode>", "symbols": "<set>", "layout": "full" | "compact"}
SHAPES=(spectrum mirror top dense chunky densemirror)
COLORS=(gradient solid layers)
SYMBOLS=(blocks braille shades)

read_key() { sed -n 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p' "$SETTINGS" 2>/dev/null | head -1 || true; }

# cur <key> <default> <allowed...>: the saved value when it is one of the allowed ones, else the default
cur() {
  local key="$1" def="$2" v x; shift 2
  v="$(read_key "$key")"
  for x in "$@"; do [[ "$x" == "$v" ]] && { printf '%s' "$v"; return; }; done
  printf '%s' "$def"
}
# Before the colour had its own choice, `solid` and `layers` were saved as the style.
cur_shape()   { cur cava spectrum "${SHAPES[@]}"; }
cur_color() {
  local legacy; legacy="$(read_key cava)"
  if [[ ( "$legacy" == solid || "$legacy" == layers ) && -z "$(read_key color)" ]]; then printf '%s' "$legacy"; return; fi
  cur color gradient "${COLORS[@]}"
}
cur_symbols() { cur symbols blocks "${SYMBOLS[@]}"; }
cur_layout()  { cur layout full full compact; }

save() {   # shape color symbols layout
  mkdir -p "$OWN"
  printf '{"cava": "%s", "color": "%s", "symbols": "%s", "layout": "%s"}\n' "$1" "$2" "$3" "$4" > "$SETTINGS.tmp" \
    && mv -f "$SETTINGS.tmp" "$SETTINGS"
  bash "$HERE/render.sh" || true
}

in_list() { local x t="$1"; shift; for x in "$@"; do [[ "$x" == "$t" ]] && return 0; done; return 1; }

case "${1:-list}" in
  leave)
    rm -f "$OWN/rmpc/theme.ron"
    rmdir "$OWN/rmpc" 2>/dev/null || true
    exit 0
    ;;
  toggle)
    id="${2:-}"
    if [[ "$id" == compact ]]; then
      if [[ "$(cur_layout)" == compact ]]; then l=full; else l=compact; fi
      save "$(cur_shape)" "$(cur_color)" "$(cur_symbols)" "$l"
    elif in_list "$id" "${SHAPES[@]}"; then
      save "$id" "$(cur_color)" "$(cur_symbols)" "$(cur_layout)"
    elif in_list "$id" "${COLORS[@]}"; then
      save "$(cur_shape)" "$id" "$(cur_symbols)" "$(cur_layout)"
    elif in_list "$id" "${SYMBOLS[@]}"; then
      save "$(cur_shape)" "$(cur_color)" "$id" "$(cur_layout)"
    else
      exit 2
    fi
    ;;
esac

shape="$(cur_shape)"; col="$(cur_color)"; sym="$(cur_symbols)"
compact=false; [[ "$(cur_layout)" == compact ]] && compact=true
printf '[{"id":"compact","label":"Compact layout","on":%s,"lead":true,"note":"For terminals smaller than about 110x28"}' "$compact"
for x in "${SHAPES[@]}"; do
  on=false; [[ "$x" == "$shape" ]] && on=true
  printf ',{"id":"%s","label":"shape: %s","on":%s}' "$x" "$x" "$on"
done
for x in "${COLORS[@]}"; do
  on=false; [[ "$x" == "$col" ]] && on=true
  printf ',{"id":"%s","label":"colour: %s","on":%s}' "$x" "$x" "$on"
done
for x in "${SYMBOLS[@]}"; do
  on=false; [[ "$x" == "$sym" ]] && on=true
  printf ',{"id":"%s","label":"symbols: %s","on":%s}' "$x" "$x" "$on"
done
printf ']\n'
