#!/usr/bin/env bash
# The colour lines of ~/.config/fastfetch/config.jsonc (each ends in `// inir:<palette role>`) take the theme's
# palette; every other line is the person's. A config without those lines is kept beside it, once, and replaced.
set -euo pipefail

source "${INIR_COLOR_RUNTIME:?run by iNiR: scripts/colors/apply-targets.sh fastfetch}"
COLOR_MODULE_ID="fastfetch"

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PALETTE_FILE="$STATE_DIR/user/generated/palette.json"
CONFIG="$XDG_CONFIG_HOME/fastfetch/config.jsonc"

command -v fastfetch >/dev/null 2>&1 || { log_module "fastfetch not installed, skipping"; exit 0; }
[[ -s "$PALETTE_FILE" ]] || { log_module "no palette yet, skipping"; exit 0; }
command -v jq >/dev/null 2>&1 || { log_module "jq is missing, skipping"; exit 0; }

mkdir -p "$(dirname "$CONFIG")"
source_file="$CONFIG"
if ! grep -qs '// inir:' "$CONFIG"; then
  [[ -f "$CONFIG" && ! -e "$CONFIG.before-inir" ]] && cp -p "$CONFIG" "$CONFIG.before-inir"
  source_file="$PLUGIN_DIR/config.jsonc"
fi

# One sed expression per role the file names: "key": "<anything>"  ->  "key": "38;2;R;G;B" (truecolor works on every
# fastfetch; #RRGGBB only from 2.42).
script=()
while IFS= read -r role; do
  hex="$(jq -r --arg r "$role" '.[$r] // empty' "$PALETTE_FILE")"
  [[ "$hex" =~ ^#[0-9A-Fa-f]{6}$ ]] || continue
  sgr="$(printf '38;2;%d;%d;%d' "0x${hex:1:2}" "0x${hex:3:2}" "0x${hex:5:2}")"
  script+=(-e "s|^\\([[:space:]]*\"[^\"]*\"[[:space:]]*:[[:space:]]*\\)\"[^\"]*\"\\(,\\{0,1\\}[[:space:]]*// inir:${role}[[:space:]]*\\)\$|\\1\"${sgr}\"\\2|")
done < <(grep -o '// inir:[a-z_]*' "$source_file" | sed 's|// inir:||' | sort -u)

if sed "${script[@]}" "$source_file" | write_if_changed "$CONFIG"; then
  log_module "colours written to $CONFIG"
fi
exit 0
