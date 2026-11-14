#!/usr/bin/env python3
"""Write an API key from stdin to the component's private options file."""
import json
import os
from pathlib import Path
import sys
import signal


def save(path, key):
    original = path.read_bytes() if path.exists() else None
    data = json.loads(original) if original is not None else {}
    if not isinstance(data, dict):
        raise ValueError("invalid options")
    data["subtitleApiKey"] = key
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name("media-corner-key.tmp")
    created = False
    try:
        fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        created = True
        with os.fdopen(fd, "w", encoding="utf-8") as target:
            json.dump(data, target, ensure_ascii=False, indent=2)
            target.write("\n")
        if (path.read_bytes() if path.exists() else None) != original:
            raise ValueError("options changed; try again")
        os.replace(temporary, path)
    finally:
        if created and temporary.exists():
            temporary.unlink()


def main():
    config = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
    save(config / "inir" / "plugins" / "media-corner.json", sys.stdin.readline().rstrip("\n"))


if __name__ == "__main__":
    def stop(_signum, _frame):
        raise SystemExit(1)
    signal.signal(signal.SIGTERM, stop)
    try:
        main()
    except (OSError, ValueError, UnicodeError) as error:
        print("Media Corner: " + str(error), file=sys.stderr)
        sys.exit(1)
