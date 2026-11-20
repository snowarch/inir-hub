---
paths:
  - "components/**/*.py"
  - "components/**/*.sh"
---

# Helper scripts

A helper script of an item (a component's today; a widget's or a web app's follows the same rules) runs on every distro
iNiR supports, with whatever the person has.

- **Nothing installed.** Python uses the standard library only (`json`, `urllib`, `subprocess`, `re`…). A program the
  feature needs (`mpv`, `ffmpeg`) is checked with `shutil.which` or `command -v`, and its absence is said in words in the
  item's window, with the package name.
- **Shebang and mode:** `#!/usr/bin/env python3` or `#!/usr/bin/env bash`, executable. Bash starts with `set -euo pipefail`.
- **Arguments are arguments.** `subprocess.run([...])` with a list, never `shell=True`. In bash, quote every `"$var"`.
  Text from the network or a file never becomes part of a command.
- **Network:** a timeout on every request (`urllib.request.urlopen(url, timeout=…)`), and a `User-Agent` naming the item.
  Offline is an error: print a clear message and exit non-zero, never hang. Only the hosts in `hub.json`.
- **Files:** read and write only under `$XDG_STATE_HOME`, `$XDG_CACHE_HOME` or `$XDG_CONFIG_HOME/inir/plugins/`, in names
  that start with the item's id. Never the person's other files, never another item's.
- **Output for QML:** one JSON object (or one per line for a stream) on stdout, errors on stderr, exit code 0 only on
  success. QML reads stdout with `StdioCollector` or `SplitParser`, and shows stderr when it fails.
- **Secrets:** a key the person enters comes in as an argument or from the item's own file.
- **Tests** for a parser live beside it (`test_*.py`, standard `unittest`) and need no network.
