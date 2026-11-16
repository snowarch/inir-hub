#!/usr/bin/env python3
"""Expose Media Corner's own style setting in Community Hub."""
import json
import os
from pathlib import Path
import sys
import tempfile


def main():
    config = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
    path = config / "inir" / "plugins" / "media-corner.json"
    try:
        with path.open(encoding="utf-8") as source:
            options = json.load(source)
        if not isinstance(options, dict):
            raise ValueError("La configuración no es un objeto JSON")
    except FileNotFoundError:
        options = {}
    style = options.get("style", "")
    if len(sys.argv) > 1 and sys.argv[1] == "toggle":
        if len(sys.argv) != 3 or sys.argv[2] not in ("normal", "prism"):
            raise ValueError("Estilo desconocido")
        style = sys.argv[2]
        options["style"] = style
        path.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=path.parent,
                                         prefix="media-corner-", delete=False) as target:
            temp = Path(target.name)
            try:
                json.dump(options, target, ensure_ascii=False, indent=2)
                target.write("\n")
                target.flush()
                os.fchmod(target.fileno(), 0o600)
            except Exception:
                temp.unlink(missing_ok=True)
                raise
        os.replace(temp, path)
    print(json.dumps([
        {"id": "normal", "label": "Normal", "on": style == "normal"},
        {"id": "prism", "label": "Prism", "on": style == "prism"},
    ]))


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print("Media Corner: " + str(error), file=sys.stderr)
        sys.exit(1)
