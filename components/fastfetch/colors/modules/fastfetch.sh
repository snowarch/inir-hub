#!/usr/bin/env bash
# The colour lines of iNiR's ~/.config/fastfetch/config.jsonc (each ends in `// inir:<palette role>`) take the theme's
# palette. A config of the person's own is never written: iNiR's look replaces it only when they turn it on in
# Settings › Hub › Fastfetch (look.sh says who owns the file).
set -euo pipefail

source "${INIR_COLOR_RUNTIME:?run by iNiR: scripts/colors/apply-targets.sh fastfetch}"
COLOR_MODULE_ID="fastfetch"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/look.sh"

command -v fastfetch >/dev/null 2>&1 || { log_module "fastfetch not installed, skipping"; exit 0; }

look="$(ff_look)"
if [[ -z "$look" ]]; then
  # The first run since it was installed (the hub runs it once then): iNiR's look only where nothing of theirs is.
  if ff_is_inir "$FF_CONFIG"; then
    look=inir
  elif [[ -e "$FF_CONFIG" || -L "$FF_CONFIG" ]]; then
    look=theirs
    log_module "$FF_CONFIG is the person's own: kept, iNiR's look waits in its Hub page"
  else
    look=inir
    ff_paint "$FF_PLUGIN/config.jsonc" | ff_write "$FF_CONFIG"
  fi
  ff_set_look "$look"
fi
[[ "$look" == inir ]] || exit 0

# They replaced or deleted iNiR's file by hand: what is there now is theirs.
if ! ff_is_inir "$FF_CONFIG"; then
  ff_set_look theirs
  log_module "$FF_CONFIG is no longer iNiR's: left alone from now on"
  exit 0
fi

if ff_paint "$FF_CONFIG" | write_if_changed "$FF_CONFIG"; then
  log_module "colours written to $FF_CONFIG"
fi
exit 0
