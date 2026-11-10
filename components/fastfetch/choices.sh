#!/usr/bin/env bash
# The plugin's part of its Hub page (plugin.json `choices`), in every family:
#   list          [{id, label, on, lead?, note?}]: first "look", iNiR's look on or off (a lead: drawn as a switch with
#                 its note), then, while it is on, one chip per line of iNiR's config.jsonc
#   toggle look   turns iNiR's look on or off (look.sh); toggle <line> comments that line of iNiR's file in or out
#   leave         run by the Hub before it removes the plugin: the person's own config back, nothing of iNiR's left
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/look.sh"

case "${1:-list}" in
  leave)
    ff_leave
    exit 0
    ;;
  toggle)
    id="${2:-}"
    [[ "$id" =~ ^[a-z]+$ ]] || exit 2
    if [[ "$id" == look ]]; then
      if ff_is_inir "$FF_CONFIG"; then ff_off; else ff_on; fi
    elif ff_is_inir "$FF_CONFIG"; then
      sed -E "s#^([[:space:]]*)//[[:space:]]*(\\{ \"type\": \"$id\",)#\\1\\2#;t;s#^([[:space:]]*)(\\{ \"type\": \"$id\",)#\\1// \\2#" \
        "$FF_CONFIG" | ff_write "$FF_CONFIG"
    fi
    ;;
esac

if ff_is_inir "$FF_CONFIG"; then
  on=true
  if [[ -e "$FF_THEIRS" || -L "$FF_THEIRS" ]]; then note="Turn it off to get your own config back"
  else note="Turn it off for fastfetch's own look"; fi
else
  on=false
  if [[ -e "$FF_CONFIG" || -L "$FF_CONFIG" ]]; then note="Your own config is in use; iNiR leaves it alone"
  else note="Fastfetch shows its own look"; fi
fi
printf '[{"id":"look","label":"Use iNiR'"'"'s fastfetch","on":%s,"lead":true,"note":"%s"}' "$on" "$note"

if [[ "$on" == true ]]; then
  re='^[[:space:]]*(//[[:space:]]*)?\{ "type": "([a-z]+)",'
  while IFS= read -r line; do
    [[ "$line" =~ $re ]] || continue
    id="${BASH_REMATCH[2]}" shown=true
    [[ -n "${BASH_REMATCH[1]}" ]] && shown=false
    label="$(sed -n 's/.*{#separator}\([a-z ]*\)".*/\1/p' <<<"$line")"
    case "$id" in title) label="name" ;; colors) label="colours" ;; esac
    printf ',{"id":"%s","label":"%s","on":%s}' "$id" "${label:-$id}" "$shown"
  done < "$FF_CONFIG"
fi
printf ']\n'
