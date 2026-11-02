#!/usr/bin/env bash
# The Hub's chips for this plugin (plugin.json `choices`): `list` prints [{id, label, on}] for every module line of
# ~/.config/fastfetch/config.jsonc, `toggle <id>` comments that line in or out first. Only the leading // moves.
set -euo pipefail
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/config.jsonc"
[[ -f "$CONFIG" ]] || { printf '[]\n'; exit 0; }

if [[ "${1:-list}" == "toggle" ]]; then
  id="${2:-}"
  [[ "$id" =~ ^[a-z]+$ ]] || exit 2
  tmp="$(mktemp "$CONFIG.XXXXXX")"
  sed -E "s#^([[:space:]]*)//[[:space:]]*(\\{ \"type\": \"$id\",)#\\1\\2#;t;s#^([[:space:]]*)(\\{ \"type\": \"$id\",)#\\1// \\2#" "$CONFIG" > "$tmp"
  chmod --reference="$CONFIG" "$tmp" 2>/dev/null || true
  mv -f "$tmp" "$CONFIG"
fi

re='^[[:space:]]*(//[[:space:]]*)?\{ "type": "([a-z]+)",'
first=1
printf '['
while IFS= read -r line; do
  [[ "$line" =~ $re ]] || continue
  id="${BASH_REMATCH[2]}" on=true
  [[ -n "${BASH_REMATCH[1]}" ]] && on=false
  label="$(sed -n 's/.*{#separator}\([a-z ]*\)".*/\1/p' <<<"$line")"
  case "$id" in title) label="name" ;; colors) label="colours" ;; esac
  (( first )) || printf ','
  first=0
  printf '{"id":"%s","label":"%s","on":%s}' "$id" "${label:-$id}" "$on"
done < "$CONFIG"
printf ']\n'
