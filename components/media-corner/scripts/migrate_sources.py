#!/usr/bin/env python3
"""Back up and upgrade the component's legacy source list without exposing its content."""
import json
import os
from pathlib import Path
import sys
import tempfile
from datetime import datetime, timezone


def migrate(path):
    if not path.exists():
        return {"status": "absent"}
    original = path.read_bytes()
    options = json.loads(original)
    if not isinstance(options, dict):
        raise ValueError("invalid options")
    if "sources" not in options:
        return {"status": "absent"}
    value = options["sources"]
    value = json.loads(value) if isinstance(value, str) else value
    if isinstance(value, dict) and value.get("schemaVersion") == 1 and isinstance(value.get("sources"), list):
        return {"status": "current", "count": len(value["sources"])}
    if not isinstance(value, list):
        raise ValueError("unrecognized sources format")
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    backup = path.with_name("media-corner.json.pre-sources-" + stamp)
    with backup.open("xb") as destination:
        os.fchmod(destination.fileno(), 0o600)
        destination.write(original)
    options["sources"] = json.dumps({"schemaVersion": 1, "sources": value}, ensure_ascii=False)
    temp = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=path.parent,
                                         prefix="media-corner-", delete=False) as target:
            temp = Path(target.name)
            os.fchmod(target.fileno(), 0o600)
            json.dump(options, target, ensure_ascii=False, indent=2)
            target.write("\n")
        if path.read_bytes() != original:
            raise ValueError("options changed during migration")
        os.replace(temp, path)
    finally:
        if temp and temp.exists():
            temp.unlink()
    return {"status": "migrated", "count": len(value)}


def main():
    config = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
    print(json.dumps(migrate(config / "inir" / "plugins" / "media-corner.json")))


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, UnicodeError) as error:
        print("Media Corner: " + str(error), file=sys.stderr)
        sys.exit(1)
