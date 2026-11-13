#!/usr/bin/env bash
# tools/min-inir.sh [VERSION]: run in an inir-hub checkout; fails naming each item whose minInir is newer than VERSION
# (default: the VERSION on snowarch/iNiR main, what people have). Hub main is production: what it serves must load there.
set -euo pipefail
main="${1:-${INIR_MAIN_VERSION:-$(curl -fsSL --max-time 15 https://raw.githubusercontent.com/snowarch/iNiR/main/VERSION)}}"
main="${main//[[:space:]]/}"
bad=0
for f in */*/hub.json; do
    m=$(jq -r '.minInir // empty' "$f")
    [ -n "$m" ] || continue
    if [ "$(printf '%s\n%s\n' "$m" "$main" | sort -V | tail -1)" != "$main" ]; then
        echo "${f%/hub.json} asks iNiR $m; main is $main"; bad=1
    fi
done
exit $bad
