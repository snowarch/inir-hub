#!/usr/bin/env bash
# The plugin's part of its Hub page (plugin.json `choices`):
#   list    no options: the theme follows the palette on its own
#   leave   run by the Hub before it removes the plugin: the generated theme goes with it
set -euo pipefail
dir="${XDG_CONFIG_HOME:-$HOME/.config}/inir/plugins/rmpc"
case "${1:-list}" in
  leave)
    rm -f "$dir/theme.ron"
    rmdir "$dir" 2>/dev/null || true
    ;;
  *)
    printf "[]\n"
    ;;
esac
exit 0
