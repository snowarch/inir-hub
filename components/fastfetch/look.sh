# shellcheck shell=bash
# Who owns ~/.config/fastfetch/config.jsonc, for the colour module and the Hub page (choices.sh).
# The file is iNiR's while it carries colour marks (`// inir:<palette role>`); any other file is the person's and is
# never written. Turning iNiR's look on keeps theirs as config.jsonc.before-inir; turning it off, or removing the
# plugin, puts it back. `// inir:ignore` anywhere in a file keeps it theirs.

FF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch"
FF_CONFIG="$FF_DIR/config.jsonc"
FF_THEIRS="$FF_CONFIG.before-inir"
FF_OWN_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/inir/plugins"
FF_LOOK="$FF_OWN_DIR/fastfetch.json"      # {"look": "inir" | "theirs"}; missing = just installed
FF_KEPT="$FF_OWN_DIR/fastfetch.jsonc"     # iNiR's file while the look is off, with the lines they picked
FF_PLUGIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FF_PALETTE="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated/palette.json"

ff_is_inir() {
  [[ -f "$1" ]] && grep -Eqs '// inir:[a-z_]+' "$1" && ! grep -qs '// inir:ignore' "$1"
}

ff_look() {
  [[ -f "$FF_LOOK" ]] || return 0
  sed -n 's/.*"look"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p' "$FF_LOOK" | head -1
}

ff_set_look() {
  mkdir -p "$FF_OWN_DIR"
  printf '{"look": "%s"}\n' "$1" > "$FF_LOOK.tmp" && mv -f "$FF_LOOK.tmp" "$FF_LOOK"
}

# ff_paint SOURCE: SOURCE on stdout, each marked colour line on the theme's palette (truecolor works on every
# fastfetch; #RRGGBB only from 2.42). Without a palette or jq it comes out as it went in.
ff_paint() {
  local source="$1" role hex sgr
  local -a script=()
  if [[ -s "$FF_PALETTE" ]] && command -v jq >/dev/null 2>&1; then
    while IFS= read -r role; do
      hex="$(jq -r --arg r "$role" '.[$r] // empty' "$FF_PALETTE")"
      [[ "$hex" =~ ^#[0-9A-Fa-f]{6}$ ]] || continue
      sgr="$(printf '38;2;%d;%d;%d' "0x${hex:1:2}" "0x${hex:3:2}" "0x${hex:5:2}")"
      script+=(-e "s|^\\([[:space:]]*\"[^\"]*\"[[:space:]]*:[[:space:]]*\\)\"[^\"]*\"\\(,\\{0,1\\}[[:space:]]*// inir:${role}[[:space:]]*\\)\$|\\1\"${sgr}\"\\2|")
    done < <(grep -o '// inir:[a-z_]*' "$source" | sed 's|// inir:||' | sort -u)
  fi
  if ((${#script[@]})); then sed "${script[@]}" "$source"; else cat "$source"; fi
}

# ff_write FILE: stdin into FILE in one move, never through a half-written file.
ff_write() {
  mkdir -p "$(dirname "$1")"
  cat > "$1.inir-tmp" && mv -f "$1.inir-tmp" "$1"
}

# On: theirs is kept aside (an older copy left from before keeps its date), iNiR's comes back with the lines they
# picked last time, on the current palette.
ff_on() {
  if [[ -e "$FF_CONFIG" || -L "$FF_CONFIG" ]] && ! ff_is_inir "$FF_CONFIG"; then
    if [[ -e "$FF_THEIRS" ]] && ! cmp -s "$FF_THEIRS" "$FF_CONFIG"; then
      mv -f "$FF_THEIRS" "$FF_THEIRS-$(date -r "$FF_THEIRS" +%Y%m%d-%H%M%S)"
    fi
    mv -f "$FF_CONFIG" "$FF_THEIRS"
  fi
  if ! ff_is_inir "$FF_CONFIG"; then
    local source="$FF_PLUGIN/config.jsonc"
    ff_is_inir "$FF_KEPT" && source="$FF_KEPT"
    ff_paint "$source" | ff_write "$FF_CONFIG"
  fi
  rm -f "$FF_KEPT"
  ff_set_look inir
}

# Off: iNiR's file is kept for next time and theirs is put back; with none, fastfetch shows its own default.
ff_off() {
  if ff_is_inir "$FF_CONFIG"; then
    mkdir -p "$FF_OWN_DIR"
    mv -f "$FF_CONFIG" "$FF_KEPT"
  fi
  if [[ -e "$FF_THEIRS" || -L "$FF_THEIRS" ]] && [[ ! -e "$FF_CONFIG" && ! -L "$FF_CONFIG" ]]; then
    mv -f "$FF_THEIRS" "$FF_CONFIG"
  fi
  ff_set_look theirs
}

# Before the Hub removes the plugin: theirs back, nothing of iNiR's left.
ff_leave() {
  ff_off
  rm -f "$FF_KEPT" "$FF_LOOK"
}
