#!/usr/bin/env bash
# The plugin's part of its Hub page (plugin.json `choices`):
#   list          [{id, label, on, lead?, note?}]: a switch for the compact layout, then one chip per cava style
#   toggle <id>   `compact` flips the layout; a style id picks that cava style; the theme is rewritten either way
#   leave         run by the Hub before it removes the plugin: the generated theme goes with it
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OWN="${XDG_CONFIG_HOME:-$HOME/.config}/inir/plugins"
SETTINGS="$OWN/rmpc.json"      # {"cava": "<style>", "layout": "full" | "compact"}
STYLES=(spectrum mirror top solid dense chunky)

read_key() { sed -n 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p' "$SETTINGS" 2>/dev/null | head -1 || true; }

cur_style() {
  local s; s="$(read_key cava)"
  for x in "${STYLES[@]}"; do [[ "$x" == "$s" ]] && { printf '%s' "$s"; return; }; done
  printf 'spectrum'
}
cur_layout() { [[ "$(read_key layout)" == compact ]] && printf 'compact' || printf 'full'; }

save() {
  mkdir -p "$OWN"
  printf '{"cava": "%s", "layout": "%s"}\n' "$1" "$2" > "$SETTINGS.tmp" && mv -f "$SETTINGS.tmp" "$SETTINGS"
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
    if [[ "$id" == compact ]]; then
      if [[ "$(cur_layout)" == compact ]]; then save "$(cur_style)" full; else save "$(cur_style)" compact; fi
    else
      ok=0
      for x in "${STYLES[@]}"; do [[ "$x" == "$id" ]] && ok=1; done
      [[ $ok -eq 1 ]] || exit 2
      save "$id" "$(cur_layout)"
    fi
    ;;
esac

now="$(cur_style)"
compact=false; [[ "$(cur_layout)" == compact ]] && compact=true
printf '[{"id":"compact","label":"Compact layout","on":%s,"lead":true,"note":"For terminals smaller than about 110x28"}' "$compact"
for x in "${STYLES[@]}"; do
  on=false; [[ "$x" == "$now" ]] && on=true
  printf ',{"id":"%s","label":"%s","on":%s}' "$x" "$x" "$on"
done
printf ']\n'
