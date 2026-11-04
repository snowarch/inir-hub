---
paths:
  - "components/**/*.py"
  - "components/**/*.sh"
  - "components/**/*.fish"
  - "widgets/**/*.py"
  - "widgets/**/*.sh"
---

# Helper scripts in an item

A script runs on every distro iNiR supports (Arch, Debian, Ubuntu, Fedora, Void…), with whatever the person has.

- **Nothing installed.** Python uses the standard library only (`json`, `urllib`, `subprocess`, `re`…): no `requests`,
  no `pip`, no virtualenv. A program the feature needs (`mpv`, `ffmpeg`) is checked with `shutil.which` / `command -v`
  and its absence is said in words in the item's window, with the package name. Never `sudo`, never a package manager.
- **Shebang and mode:** `#!/usr/bin/env python3` or `#!/usr/bin/env bash`, executable. Bash starts with
  `set -euo pipefail`.
- **Arguments are arguments.** `subprocess.run([...])` with a list, never `shell=True`; in bash, quote every
  `"$var"`. Text from the network or a file never becomes part of a command.
- **Network:** a timeout on every request (`urllib.request.urlopen(url, timeout=10)`), a `User-Agent` naming the
  item, and offline handled: print a clear error and exit non-zero, never hang. Only the hosts in `hub.json`.
- **Files:** read and write only under `$XDG_STATE_HOME`, `$XDG_CACHE_HOME` or `$XDG_CONFIG_HOME/inir/plugins/`, in
  names that start with the item's id. Never the person's other files, never another item's.
- **Output for QML:** one JSON object (or one per line for a stream) on stdout, errors on stderr, exit code 0 only on
  success. QML reads stdout with `StdioCollector` / `SplitParser` and shows stderr when it fails.
- **Secrets:** none in the repository. A key the person enters comes in as an argument or from the item's own file.
- **Tests** for a parser live beside it (`test_*.py`, standard `unittest`) and need no network.
- Declare `process` (and `network`, `files` as they apply) in `hub.json`.
