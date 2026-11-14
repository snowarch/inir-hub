#!/usr/bin/env python3
"""Back up and upgrade the component's legacy source list without exposing its content."""
import json
import os
from pathlib import Path
import sys
import signal
from datetime import datetime, timezone


def migrate(path):
    original = path.read_bytes() if path.exists() else None
    options = json.loads(original) if original is not None else {}
    if not isinstance(options, dict):
        raise ValueError("invalid options")
    value = options.get("sources", [])
    value = json.loads(value) if isinstance(value, str) else value
    if isinstance(value, dict) and value.get("schemaVersion") == 1 and isinstance(value.get("sources"), list):
        return {"status": "current", "count": len(value["sources"])}
    if not isinstance(value, list):
        raise ValueError("unrecognized sources format")
    path.parent.mkdir(parents=True, exist_ok=True)
    if original is not None:
        stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
        backup = path.with_name("media-corner.json.pre-sources-" + stamp)
        with backup.open("xb") as destination:
            os.fchmod(destination.fileno(), 0o600)
            destination.write(original)
    options["sources"] = json.dumps({"schemaVersion": 1, "sources": value}, ensure_ascii=False)
    temp = path.with_name("media-corner-migration.tmp")
    created = False
    try:
        fd = os.open(temp, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        created = True
        with os.fdopen(fd, "w", encoding="utf-8") as target:
            json.dump(options, target, ensure_ascii=False, indent=2)
            target.write("\n")
        if (path.read_bytes() if path.exists() else None) != original:
            raise ValueError("options changed during migration")
        os.replace(temp, path)
    finally:
        if created and temp.exists():
            temp.unlink()
    return {"status": "migrated", "count": len(value)}


def main():
    config = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
    print(json.dumps(migrate(config / "inir" / "plugins" / "media-corner.json")))


if __name__ == "__main__":
    def stop(_signum, _frame):
        raise SystemExit(1)
    signal.signal(signal.SIGTERM, stop)
    try:
        main()
    except (OSError, ValueError, UnicodeError) as error:
        print("Media Corner: " + str(error), file=sys.stderr)
        sys.exit(1)
