#!/usr/bin/env bash
set -euo pipefail

CFG="${XDG_CONFIG_HOME:-$HOME/.config}/illogical-impulse/config.json"
PLUGIN_CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/inir/plugins"
PLUGIN_CFG="$PLUGIN_CFG_DIR/inirconnect.json"
APP_ID="inirconnect"
OLD_ID="android-connect"

mkdir -p "$PLUGIN_CFG_DIR"
[[ -f "$PLUGIN_CFG" ]] || printf '{"windowed":false}\n' > "$PLUGIN_CFG"

has_bubble() {
  jq -e --arg id "$APP_ID" --arg old "$OLD_ID" '(.iris.bubbles.apps // []) | any(.appId == $id or .appId == $old)' "$CFG" >/dev/null 2>&1
}

has_dock() {
  jq -e --arg id "$APP_ID" --arg old "$OLD_ID" '(.dock.pinnedApps // []) | (index($id) != null or index($old) != null)' "$CFG" >/dev/null 2>&1
}

is_windowed() {
  jq -e '.windowed == true' "$PLUGIN_CFG" >/dev/null 2>&1
}

case "${1:-list}" in
  leave)
    if [[ -f "$CFG" ]]; then
      tmp="$(mktemp)"
      jq --arg id "$APP_ID" '
        if .iris.bubbles.apps then .iris.bubbles.apps |= map(select(.appId != $id)) else . end |
        if .dock.pinnedApps then .dock.pinnedApps |= map(select(. != $id)) else . end
      ' "$CFG" > "$tmp" && mv "$tmp" "$CFG"
    fi
    exit 0
    ;;
  toggle)
    choice="${2:-}"
    case "$choice" in
      bubble)
        tmp="$(mktemp)"
        if has_bubble; then
          jq --arg id "$APP_ID" --arg old "$OLD_ID" '.iris.bubbles.apps = ((.iris.bubbles.apps // []) | map(select(.appId != $id and .appId != $old)))' "$CFG" > "$tmp" && mv "$tmp" "$CFG"
        else
          jq --arg id "$APP_ID" '.iris.bubbles.apps = ((.iris.bubbles.apps // []) + [{"appId": $id, "place": "top-right", "fx": 0.5, "fy": 0.5}])' "$CFG" > "$tmp" && mv "$tmp" "$CFG"
        fi
        ;;
      windowed)
        tmp="$(mktemp)"
        if is_windowed; then
          jq '.windowed = false' "$PLUGIN_CFG" > "$tmp" && mv "$tmp" "$PLUGIN_CFG"
        else
          jq '.windowed = true' "$PLUGIN_CFG" > "$tmp" && mv "$tmp" "$PLUGIN_CFG"
        fi
        ;;
      dock)
        tmp="$(mktemp)"
        if has_dock; then
          jq --arg id "$APP_ID" '.dock.pinnedApps = ((.dock.pinnedApps // []) | map(select(. != $id)))' "$CFG" > "$tmp" && mv "$tmp" "$CFG"
        else
          jq --arg id "$APP_ID" '.dock.pinnedApps = ((.dock.pinnedApps // []) + [$id])' "$CFG" > "$tmp" && mv "$tmp" "$CFG"
        fi
        ;;
      open)
        nohup inir inirconnect open >/dev/null 2>&1 &
        ;;
    esac
    ;;
esac

bubble_on=false
has_bubble && bubble_on=true
windowed_on=false
is_windowed && windowed_on=true
dock_on=false
has_dock && dock_on=true

cat <<EOF
[
  {"id":"bubble","label":"Burbuja en iRiS","on":$bubble_on,"lead":true,"note":"Muestra la burbuja de iNiRConnect en la esquina superior derecha de iRiS para abrir el panel con un toque"},
  {"id":"windowed","label":"Modo ventana","on":$windowed_on},
  {"id":"dock","label":"Fijar en el Dock","on":$dock_on},
  {"id":"open","label":"Abrir panel ahora","on":false}
]
EOF
