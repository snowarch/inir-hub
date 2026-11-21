#!/usr/bin/env bash
# The plugin's part of its Hub page (plugin.json `choices`):
#   list          [{id, label, on}]: one chip per cava style
#   toggle <id>   picks that cava style and rewrites the theme
#   leave         run by the Hub before it removes the plugin: the generated theme goes with it
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OWN="${XDG_CONFIG_HOME:-$HOME/.config}/inir/plugins"
SETTINGS="$OWN/rmpc.json"
STYLES=(spectrum mirror top solid dense chunky)

current() {
  local s
  s="$(sed -n 's/.*"cava"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p' "$SETTINGS" 2>/dev/null | head -1 || true)"
  for x in "${STYLES[@]}"; do [[ "$x" == "$s" ]] && { printf '%s' "$s"; return; }; done
  printf 'spectrum'
}

case "${1:-list}" in
  leave)
    rm -f "$OWN/rmpc/theme.ron"
    rmdir "$OWN/rmpc" 2>/dev/null || true
    exit 0
    ;;
  toggle)
    id="${2:-}"
    ok=0
    for x in "${STYLES[@]}"; do [[ "$x" == "$id" ]] && ok=1; done
    [[ $ok -eq 1 ]] || exit 2
    mkdir -p "$OWN"
    printf '{"cava": "%s"}\n' "$id" > "$SETTINGS.tmp" && mv -f "$SETTINGS.tmp" "$SETTINGS"
    bash "$HERE/render.sh" || true
    ;;
esac

now="$(current)"
printf '['
sep=""
for x in "${STYLES[@]}"; do
  on=false; [[ "$x" == "$now" ]] && on=true
  printf '%s{"id":"%s","label":"%s","on":%s}' "$sep" "$x" "$x" "$on"
  sep=","
done
printf ']\n'
