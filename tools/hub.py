#!/usr/bin/env python3
"""iNiR Hub tool: validate items, scaffold new ones, and build the published catalogue.

    python3 tools/hub.py validate [ITEM_DIR ...]     check every item (or the given ones)
    python3 tools/hub.py bumps --base origin/main    changed items must raise their version
    python3 tools/hub.py new KIND ID [--author GH]   start an item from templates/KIND
    python3 tools/hub.py build [--out dist]          index.json, packages, previews, gallery

Standard library only. The build is reproducible: the same item folder always packs to the same
bytes, so a package's sha256 only changes when its content does.
"""

from __future__ import annotations

import argparse
import datetime as dt
import gzip
import hashlib
import html
import io
import json
import os
import re
import shutil
import struct
import subprocess
import sys
import tarfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCHEMA = 1

# kind -> folder in this repo, the file iNiR itself reads, and the families it reaches.
KINDS = {
    "widget": {"dir": "widgets", "native": "widget.json", "label": "Widget"},
    "theme": {"dir": "themes", "native": "theme.json", "label": "Colour theme"},
    "iris-theme": {"dir": "iris-themes", "native": "theme.json", "label": "iRiS theme"},
    "webapp": {"dir": "webapps", "native": "manifest.json", "label": "Web app"},
}
PERMISSIONS = {
    "process": "Runs commands on your computer",
    "network": "Talks to the internet",
    "files": "Reads or writes files outside its own folder",
    "inject": "Injects scripts into the site it opens",
}
FAMILIES = ("material", "iris", "waffle")
ID_RE = re.compile(r"^[a-z0-9][a-z0-9-]{1,46}[a-z0-9]$")
SEMVER_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")
HANDLE_RE = re.compile(r"^[A-Za-z0-9](?:[A-Za-z0-9-]{0,38})$")
HEX_RE = re.compile(r"^#[0-9a-fA-F]{6}$")
PREVIEW_EXT = (".webp", ".png", ".jpg", ".jpeg")
PREVIEW_MAX = 700 * 1024
PACKAGE_MAX = 2 * 1024 * 1024
LEFT_OUT = {"hub.json", "README.md", "CHANGELOG.md"}  # store listing, not part of what installs
CODE_EXT = (".qml", ".js", ".mjs", ".sh", ".py", ".fish")
# A Material theme must say at least these; the rest of customTheme falls back to iNiR's own.
THEME_REQUIRED = [
    "m3background", "m3onBackground", "m3surface", "m3onSurface", "m3surfaceVariant", "m3onSurfaceVariant",
    "m3surfaceContainerLowest", "m3surfaceContainerLow", "m3surfaceContainer", "m3surfaceContainerHigh",
    "m3surfaceContainerHighest", "m3outline", "m3outlineVariant", "m3primary", "m3onPrimary",
    "m3primaryContainer", "m3onPrimaryContainer", "m3secondary", "m3onSecondary", "m3secondaryContainer",
    "m3onSecondaryContainer", "m3tertiary", "m3onTertiary", "m3tertiaryContainer", "m3onTertiaryContainer",
    "m3error", "m3onError", "m3errorContainer", "m3onErrorContainer",
]

# iRiS ships these themes itself; a hub theme with one of these ids would sit beside the built-in one
# under the same name. Keep in step with `inir iris theme list` on the newest iNiR.
IRIS_BUILT_IN = {
    "iris", "liquid-glass", "frost", "obsidian", "aurora", "terminal", "neo-tokyo", "afterglow", "y2k",
    "faded-light", "film-burn", "grain-orb", "polaroid", "twilight", "daybreak", "horizon", "monolith", "sakura",
    "meadow", "unit-01", "magical-girl", "spirit-forest", "signal", "inir", "lume", "adaptive",
}
# iRiS's named accents, as hues, for the card drawn when an iRiS theme ships no screenshot.
IRIS_HUES = {"red": 4, "orange": 28, "yellow": 48, "green": 142, "teal": 176, "sky": 200, "blue": 214,
             "indigo": 240, "purple": 272, "pink": 330}

# What the code does, as a reviewer would grep for it. A match the manifest does not declare fails.
DETECT = {
    "process": re.compile(r"\bProcess\s*\{|execDetached|ShellExec\.|\bbash\s+-c\b|\bsh\s+-c\b"),
    "network": re.compile(r"XMLHttpRequest|\bcurl\b|\bwget\b|\bWebSocket\b|\bfetch\s*\("),
    "files": re.compile(r"\bFileView\s*\{|\bFolderListModel\s*\{|\bwriteAdapter\b"),
}
# Never accepted: code that fetches more code, or hides what it does.
FORBIDDEN = [
    (re.compile(r"(curl|wget)[^\n|]*\|\s*(ba|z|fi)?sh\b"), "pipes a download into a shell"),
    (re.compile(r"\beval\s*\("), "uses eval()"),
    (re.compile(r"Qt\.createQmlObject\s*\("), "builds QML from a string"),
    (re.compile(r"source\s*:\s*[\"']https?://[^\"']*\.qml"), "loads QML from the internet"),
    (re.compile(r"atob\s*\(|base64\s+(-d|--decode)"), "decodes hidden content"),
]


class Report:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []
        self.gha = os.environ.get("GITHUB_ACTIONS") == "true"

    def error(self, where: Path | str, text: str) -> None:
        self.errors.append(f"{rel(where)}: {text}")
        if self.gha:
            print(f"::error file={rel(where)}::{text}")

    def warn(self, where: Path | str, text: str) -> None:
        self.warnings.append(f"{rel(where)}: {text}")
        if self.gha:
            print(f"::warning file={rel(where)}::{text}")

    def print(self) -> None:
        for line in self.warnings:
            print(f"warning  {line}", file=sys.stderr)
        for line in self.errors:
            print(f"error    {line}", file=sys.stderr)


def rel(path: Path | str) -> str:
    try:
        return str(Path(path).resolve().relative_to(ROOT))
    except ValueError:
        return str(path)


def load_json(path: Path, report: Report) -> dict | None:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        report.error(path, "missing")
        return None
    except (json.JSONDecodeError, UnicodeDecodeError) as exc:
        report.error(path, f"not valid JSON ({exc})")
        return None
    if not isinstance(data, dict):
        report.error(path, "must be a JSON object")
        return None
    return data


def semver(text: str) -> tuple[int, int, int] | None:
    m = SEMVER_RE.match(str(text or ""))
    return (int(m[1]), int(m[2]), int(m[3])) if m else None


def image_size(path: Path) -> tuple[int, int] | None:
    """Width and height of a PNG, JPEG or WebP, read from its header."""
    data = path.read_bytes()[:65536]
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        return struct.unpack(">II", data[16:24])
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        chunk = data[12:16]
        if chunk == b"VP8X":
            return 1 + int.from_bytes(data[24:27], "little"), 1 + int.from_bytes(data[27:30], "little")
        if chunk == b"VP8 ":
            w, h = struct.unpack("<HH", data[26:30])
            return w & 0x3FFF, h & 0x3FFF
        if chunk == b"VP8L":
            b = int.from_bytes(data[21:25], "little")
            return (b & 0x3FFF) + 1, ((b >> 14) & 0x3FFF) + 1
        return None
    if data[:2] == b"\xff\xd8":
        i = 2
        while i + 9 < len(data):
            if data[i] != 0xFF:
                i += 1
                continue
            marker = data[i + 1]
            length = struct.unpack(">H", data[i + 2:i + 4])[0]
            if marker in (0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF):
                h, w = struct.unpack(">HH", data[i + 5:i + 9])
                return w, h
            i += 2 + length
    return None


def item_dirs() -> list[Path]:
    out = []
    for kind, spec in KINDS.items():
        base = ROOT / spec["dir"]
        if base.is_dir():
            out += [p for p in sorted(base.iterdir()) if p.is_dir() and not p.name.startswith(".")]
    return out


def kind_of(folder: Path) -> str | None:
    parent = folder.resolve().parent.name
    return next((k for k, s in KINDS.items() if s["dir"] == parent), None)


def files_of(folder: Path) -> list[Path]:
    return sorted(p for p in folder.rglob("*") if p.is_file() and ".git" not in p.parts)


def pascal(item_id: str) -> str:
    return "".join(part[:1].upper() + part[1:] for part in item_id.split("-"))


def qml_entry_points(native: dict, item_id: str) -> dict[str, str]:
    """Surface -> file, as iNiR's CustomWidgets reads widget.json."""
    points = {}
    main = native.get("main")
    if main is None:
        main = f"{pascal(item_id)}.qml"
    if main:
        points["desktop"] = str(main)
    iris = native.get("iris") if isinstance(native.get("iris"), dict) else {}
    if str(iris.get("main") or "").strip():
        points["island"] = str(iris["main"]).strip()
    waffle = native.get("waffle") if isinstance(native.get("waffle"), dict) else {}
    if str(waffle.get("main") or "").strip():
        points["waffle-widgets"] = str(waffle["main"]).strip()
    return points


def check_item(folder: Path, report: Report) -> dict | None:
    """Validate one item; return its catalogue entry (without package fields) or None."""
    kind = kind_of(folder)
    item_id = folder.name
    if kind is None:
        report.error(folder, f"items live in one of: {', '.join(s['dir'] + '/' for s in KINDS.values())}")
        return None
    if not ID_RE.match(item_id):
        report.error(folder, "folder name is the id: 3-48 chars, lowercase letters, digits and dashes")
    hub = load_json(folder / "hub.json", report)
    native = load_json(folder / KINDS[kind]["native"], report)
    if hub is None or native is None:
        return None
    before = len(report.errors)

    version = str(hub.get("version", ""))
    if not semver(version):
        report.error(folder / "hub.json", f'"version" must be x.y.z, got "{version}"')
    summary = str(hub.get("summary", "")).strip()
    if not 8 <= len(summary) <= 90:
        report.error(folder / "hub.json", '"summary" is one line for the card, 8-90 characters')
    authors = hub.get("authors")
    if not isinstance(authors, list) or not authors or not all(HANDLE_RE.match(str(a)) for a in authors):
        report.error(folder / "hub.json", '"authors" lists GitHub handles, e.g. ["octocat"]')
        authors = []
    license_ = str(hub.get("license", "")).strip()
    if not license_:
        report.error(folder / "hub.json", '"license" is an SPDX id such as "MIT" or "GPL-3.0-or-later"')
    tags = hub.get("tags", [])
    if not isinstance(tags, list) or len(tags) > 6 or not all(re.match(r"^[a-z0-9-]{2,20}$", str(t)) for t in tags):
        report.error(folder / "hub.json", '"tags": up to 6 lowercase words')
        tags = []
    min_inir = str(hub.get("minInir", "")).strip()
    if min_inir and not semver(min_inir):
        report.error(folder / "hub.json", '"minInir" must be x.y.z')
    declared = hub.get("permissions", [])
    if not isinstance(declared, list) or any(p not in PERMISSIONS for p in declared):
        report.error(folder / "hub.json", f'"permissions" may hold: {", ".join(PERMISSIONS)}')
        declared = []

    name = str(native.get("name", "")).strip()
    description = str(native.get("description", "") or hub.get("description", "")).strip()
    if not name:
        report.error(folder / KINDS[kind]["native"], '"name" is required')
    if len(description) > 600:
        report.error(folder, "description: keep it under 600 characters")

    entry: dict = {"surfaces": [], "families": []}
    native_version = native.get("version")

    if kind == "widget":
        points = qml_entry_points(native, item_id)
        if not points:
            report.error(folder / "widget.json", "declares no surface: give it main, iris.main or waffle.main")
        for surface, file in points.items():
            if not (folder / file).is_file():
                report.error(folder / "widget.json", f"{surface} entry point {file} does not exist")
        desktop = points.get("desktop")
        if desktop and (folder / desktop).is_file():
            text = (folder / desktop).read_text(encoding="utf-8", errors="replace")
            if f'"custom.{item_id}"' not in text:
                report.error(folder / desktop, f'configEntryName must be "custom.{item_id}" (the folder name)')
        entry["surfaces"] = list(points)
        families = []
        if "desktop" in points:
            families += ["material", "iris"]
        if "island" in points and "iris" not in families:
            families.append("iris")
        if "waffle-widgets" in points:
            families.append("waffle")
        entry["families"] = families
        entry["icon"] = str(native.get("icon") or "widgets")
        if str(native_version) != version:
            report.error(folder / "widget.json", f'"version" ({native_version}) must match hub.json ({version})')
    elif kind == "theme":
        if not isinstance(native.get("darkmode"), bool):
            report.error(folder / "theme.json", '"darkmode" is true or false')
        missing = [k for k in THEME_REQUIRED if k not in native]
        if missing:
            report.error(folder / "theme.json", f"missing colours: {', '.join(missing)}")
        for key, value in native.items():
            if key.startswith("m3") and not HEX_RE.match(str(value)):
                report.error(folder / "theme.json", f'{key} must be "#rrggbb", got "{value}"')
        entry["surfaces"] = ["colours"]
        entry["families"] = ["material", "waffle"]
        entry["icon"] = "palette"
        entry["swatch"] = [native.get(k, "#000000") for k in ("m3background", "m3surfaceContainer", "m3primary",
                                                                "m3secondary", "m3tertiary", "m3onSurface")]
        entry["dark"] = bool(native.get("darkmode"))
    elif kind == "iris-theme":
        if native.get("iris") != "theme" or native.get("version") != 1:
            report.error(folder / "theme.json", 'an iRiS theme starts with "iris": "theme", "version": 1')
        if native.get("id") != item_id:
            report.error(folder / "theme.json", f'"id" must be "{item_id}" (the folder name)')
        values = native.get("values")
        if not isinstance(values, dict) or not values or not all(str(k).startswith("iris.") for k in values):
            report.error(folder / "theme.json", '"values" maps iRiS paths ("iris.…") to values; export one from '
                                                "iRiS Settings › Colour › Themes")
        if item_id in IRIS_BUILT_IN:
            report.error(folder, f'"{item_id}" is one of iRiS\'s own themes: pick another id')
        entry["surfaces"] = ["look"]
        entry["families"] = ["iris"]
        entry["icon"] = "style"
        entry["_values"] = values if isinstance(values, dict) else {}
    elif kind == "webapp":
        if native.get("id") != item_id:
            report.error(folder / "manifest.json", f'"id" must be "{item_id}" (the folder name)')
        url = str(native.get("url", ""))
        if not url.startswith("https://"):
            report.error(folder / "manifest.json", '"url" must be https://')
        for script in native.get("userscripts", []) or []:
            if not (folder / script).is_file():
                report.error(folder / "manifest.json", f"userscript {script} does not exist")
        if native.get("userscripts") and "inject" not in declared:
            report.error(folder / "hub.json", 'userscripts inject code into the site: declare "inject"')
        icon_path = native.get("iconPath")
        if icon_path and not (folder / icon_path).is_file():
            report.error(folder / "manifest.json", f"iconPath {icon_path} does not exist")
        entry["surfaces"] = ["sidebar"]
        entry["families"] = ["material"]
        entry["icon"] = str(native.get("icon") or "language")
        entry["url"] = url
        if str(native_version) != version:
            report.error(folder / "manifest.json", f'"version" ({native_version}) must match hub.json ({version})')

    # What the code does against what it says it does.
    found: set[str] = set()
    for path in files_of(folder):
        if path.suffix not in CODE_EXT:
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        for perm, pattern in DETECT.items():
            if pattern.search(text):
                found.add(perm)
        for pattern, why in FORBIDDEN:
            if pattern.search(text):
                report.error(path, f"not accepted: {why}")
        if path.suffix in (".sh", ".py", ".fish") and kind != "webapp":
            found.add("process")
    for perm in sorted(found - set(declared)):
        report.error(folder / "hub.json", f'the code {PERMISSIONS[perm].lower()}: declare "{perm}" in "permissions"')
    for perm in sorted(set(declared) - found - {"inject"}):
        report.warn(folder / "hub.json", f'declares "{perm}" but no code needs it')

    # Store listing.
    preview = hub.get("preview")
    preview_path = folder / str(preview) if preview else None
    if preview_path is None:
        if kind not in ("theme", "iris-theme"):
            report.error(folder / "hub.json", '"preview" is required: a screenshot of it running (see CONTRIBUTING.md)')
    elif preview_path.suffix.lower() not in PREVIEW_EXT:
        report.error(folder / "hub.json", f"preview {preview} must be a .webp, .png or .jpg")
        preview_path = None
    elif not preview_path.is_file():
        report.error(folder / "hub.json", f"{preview} is missing: add a screenshot of it running (CONTRIBUTING.md › Previews)")
        preview_path = None
    else:
        size = preview_path.stat().st_size
        dims = image_size(preview_path)
        if size > PREVIEW_MAX:
            report.error(preview_path, f"{size // 1024} KB; keep previews under {PREVIEW_MAX // 1024} KB (WebP helps)")
        if dims is None:
            report.error(preview_path, "could not read its size; is it really an image?")
        else:
            w, h = dims
            if w < 800 or h < 450:
                report.error(preview_path, f"{w}x{h} is too small: at least 800x450")
            if not 1.2 <= w / h <= 2.0:
                report.error(preview_path, f"{w}x{h}: a landscape shot between 6:5 and 2:1 (16:10 is ideal)")
    if not (folder / "README.md").is_file():
        report.warn(folder, "no README.md: say what it does and how to set it up")

    total = sum(p.stat().st_size for p in files_of(folder) if p.name not in LEFT_OUT and p != preview_path)
    if total > PACKAGE_MAX:
        report.error(folder, f"{total // 1024} KB to install; keep items under {PACKAGE_MAX // 1024 // 1024} MB")

    if len(report.errors) > before:
        return None
    entry.update({
        "id": item_id,
        "kind": kind,
        "name": name,
        "summary": summary,
        "description": description,
        "version": version,
        "authors": authors,
        "license": license_,
        "tags": tags,
        "permissions": [p for p in PERMISSIONS if p in declared],
        "minInir": min_inir,
        "_preview": preview_path,
        "_folder": folder,
    })
    return entry


def validate_all(paths: list[str]) -> tuple[list[dict], Report]:
    report = Report()
    folders = [Path(p).resolve() for p in paths] if paths else item_dirs()
    entries = []
    seen: dict[str, Path] = {}
    for folder in folders:
        if folder.name in seen:
            report.error(folder, f'id "{folder.name}" is taken by {rel(seen[folder.name])}')
            continue
        seen[folder.name] = folder
        entry = check_item(folder, report)
        if entry:
            entries.append(entry)
    if not paths:
        for kind_dir in {s["dir"] for s in KINDS.values()}:
            for stray in (ROOT / kind_dir).glob("*"):
                if stray.is_file() and stray.name != ".gitkeep":
                    report.error(stray, "only item folders belong here")
    return entries, report


def pack(entry: dict) -> bytes:
    """A deterministic .tar.gz of what installs: sorted paths, zero times and owners."""
    folder: Path = entry["_folder"]
    preview: Path | None = entry["_preview"]
    raw = io.BytesIO()
    with tarfile.open(fileobj=raw, mode="w", format=tarfile.PAX_FORMAT) as tar:
        for path in files_of(folder):
            if path.name in LEFT_OUT or path == preview:
                continue
            arc = path.relative_to(folder).as_posix()
            info = tarfile.TarInfo(arc)
            info.size = path.stat().st_size
            info.mode = 0o755 if os.access(path, os.X_OK) else 0o644
            info.mtime = 0
            info.uid = info.gid = 0
            info.uname = info.gname = ""
            with path.open("rb") as fh:
                tar.addfile(info, fh)
    out = io.BytesIO()
    with gzip.GzipFile(fileobj=out, mode="wb", mtime=0, compresslevel=9) as gz:
        gz.write(raw.getvalue())
    return out.getvalue()


def git(*args: str) -> str:
    try:
        return subprocess.run(["git", "-C", str(ROOT), *args], capture_output=True, text=True, check=True).stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""


def theme_card(entry: dict) -> str:
    """A palette card for a Material theme that ships no screenshot: the theme is its colours."""
    bg, container, primary, secondary, tertiary, ink = entry["swatch"]
    name = html.escape(entry["name"])
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="800" viewBox="0 0 1280 800">
<rect width="1280" height="800" fill="{bg}"/>
<rect x="96" y="96" width="1088" height="608" rx="48" fill="{container}"/>
<circle cx="296" cy="400" r="120" fill="{primary}"/>
<circle cx="536" cy="400" r="88" fill="{secondary}"/>
<circle cx="728" cy="400" r="64" fill="{tertiary}"/>
<rect x="856" y="336" width="232" height="28" rx="14" fill="{ink}"/>
<rect x="856" y="388" width="168" height="20" rx="10" fill="{ink}" fill-opacity="0.55"/>
<rect x="856" y="428" width="200" height="20" rx="10" fill="{ink}" fill-opacity="0.35"/>
<title>{name}</title>
</svg>
"""


def hsl(hue: float, sat: float, light: float) -> str:
    """#rrggbb from HSL in degrees and 0..1."""
    c = (1 - abs(2 * light - 1)) * sat
    x = c * (1 - abs((hue / 60) % 2 - 1))
    m = light - c / 2
    r, g, b = [(c, x, 0), (x, c, 0), (0, c, x), (0, x, c), (x, 0, c), (c, 0, x)][int(hue % 360 // 60)]
    return "#" + "".join(f"{round((v + m) * 255):02x}" for v in (r, g, b))


def iris_card(entry: dict) -> str:
    """A card for an iRiS theme that ships no screenshot: its accent, highlight and shape on the Island."""
    values = entry.get("_values", {})

    def hue_of(choice_key: str, hue_key: str, fallback: float | None) -> float | None:
        choice = str(values.get(choice_key, ""))
        if choice == "custom":
            return float(values.get(hue_key, fallback or 0))
        return IRIS_HUES.get(choice, fallback)

    accent_hue = hue_of("iris.appearance.accent", "iris.appearance.theme.accentHue", None)
    highlight_hue = hue_of("iris.appearance.highlight", "iris.appearance.theme.highlightHue", 32)
    accent = hsl(accent_hue, 0.52, 0.58) if accent_hue is not None else "#a7adb4"
    highlight = hsl(highlight_hue, 0.82, 0.62)
    shape = max(0.0, min(2.0, float(values.get("iris.appearance.theme.shape", 100)) / 100))
    hue = accent_hue if accent_hue is not None else 220
    bg_top, bg_bottom = hsl(hue, 0.22, 0.16), hsl(hue, 0.30, 0.07)
    body, plate, ink = hsl(hue, 0.10, 0.10), hsl(hue, 0.10, 0.17), hsl(hue, 0.12, 0.88)
    island_r = round(30 * shape)
    plate_r = round(22 * shape)
    dock_r = round(26 * shape)
    app_r = round(14 * shape)
    dock_apps = "\n".join(
        f'<rect x="{476 + i * 68}" y="682" width="56" height="56" rx="{app_r}" '
        + (f'fill="{accent}"/>' if i == 2 else f'fill="{ink}" fill-opacity="0.16"/>')
        for i in range(5))
    name = html.escape(entry["name"])
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="800" viewBox="0 0 1280 800">
<defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{bg_top}"/><stop offset="1" stop-color="{bg_bottom}"/></linearGradient></defs>
<rect width="1280" height="800" fill="url(#sky)"/>
<rect x="380" y="0" width="520" height="560" rx="{island_r}" fill="{body}" fill-opacity="0.92"/>
<rect x="580" y="32" width="120" height="16" rx="8" fill="{ink}" fill-opacity="0.85"/>
<rect x="420" y="96" width="440" height="200" rx="{plate_r}" fill="{plate}"/>
<circle cx="520" cy="196" r="64" fill="none" stroke="{ink}" stroke-opacity="0.12" stroke-width="12"/>
<circle cx="520" cy="196" r="64" fill="none" stroke="{accent}" stroke-width="12" stroke-linecap="round"
        stroke-dasharray="282 402" transform="rotate(-90 520 196)"/>
<rect x="624" y="160" width="180" height="22" rx="11" fill="{ink}" fill-opacity="0.85"/>
<rect x="624" y="200" width="132" height="16" rx="8" fill="{ink}" fill-opacity="0.45"/>
<circle cx="816" cy="140" r="10" fill="{highlight}"/>
<rect x="420" y="320" width="440" height="88" rx="{plate_r}" fill="{plate}"/>
<rect x="452" y="358" width="376" height="12" rx="6" fill="{ink}" fill-opacity="0.12"/>
<rect x="452" y="358" width="236" height="12" rx="6" fill="{accent}"/>
<rect x="420" y="432" width="208" height="96" rx="{plate_r}" fill="{accent}"/>
<rect x="652" y="432" width="208" height="96" rx="{plate_r}" fill="{plate}"/>
<circle cx="700" cy="480" r="18" fill="{highlight}"/>
<rect x="452" y="668" width="376" height="84" rx="{dock_r}" fill="{body}" fill-opacity="0.92"/>
{dock_apps}
<title>{name}</title>
</svg>
"""


def build(out: Path) -> int:
    entries, report = validate_all([])
    report.print()
    if report.errors:
        print(f"build stopped: {len(report.errors)} error(s)", file=sys.stderr)
        return 1
    if out.exists():
        shutil.rmtree(out)
    (out / "packages").mkdir(parents=True)
    (out / "previews").mkdir()
    commit = git("rev-parse", "HEAD")
    items = []
    for entry in sorted(entries, key=lambda e: (e["kind"], e["id"])):
        data = pack(entry)
        package = f"packages/{entry['id']}-{entry['version']}.tar.gz"
        (out / package).write_bytes(data)
        preview_rel = ""
        if entry["_preview"] is not None:
            preview_rel = f"previews/{entry['id']}{entry['_preview'].suffix.lower()}"
            shutil.copyfile(entry["_preview"], out / preview_rel)
        elif entry["kind"] in ("theme", "iris-theme"):
            preview_rel = f"previews/{entry['id']}.svg"
            card = iris_card(entry) if entry["kind"] == "iris-theme" else theme_card(entry)
            (out / preview_rel).write_text(card, encoding="utf-8")
        folder_rel = entry["_folder"].relative_to(ROOT).as_posix()
        updated = git("log", "-1", "--format=%cs", "--", folder_rel) or dt.date.today().isoformat()
        item = {k: v for k, v in entry.items() if not k.startswith("_")}
        item.update({
            "preview": preview_rel,
            "package": package,
            "sha256": hashlib.sha256(data).hexdigest(),
            "size": len(data),
            "updated": updated,
            "path": folder_rel,
        })
        items.append(item)
    index = {
        "schema": SCHEMA,
        "name": "iNiR Hub",
        "home": "https://github.com/snowarch/inir-hub",
        "commit": commit,
        "generated": dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat(),
        "permissions": PERMISSIONS,
        "items": items,
    }
    (out / "index.json").write_text(json.dumps(index, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    gallery = ROOT / "tools" / "gallery.html"
    if gallery.is_file():
        shutil.copyfile(gallery, out / "index.html")
    (out / ".nojekyll").write_text("")
    print(f"built {len(items)} item(s) into {rel(out)}")
    return 0


def bumps(base: str) -> int:
    """Every item whose files changed since BASE must carry a higher version than it had there."""
    report = Report()
    changed = git("diff", "--name-only", f"{base}...HEAD").splitlines()
    touched = set()
    for path in changed:
        parts = Path(path).parts
        if len(parts) >= 2 and any(parts[0] == s["dir"] for s in KINDS.values()):
            touched.add(Path(parts[0]) / parts[1])
        if parts and parts[0] == "dist":
            report.error(path, "dist/ is built by CI; leave it out of the pull request")
    for item in sorted(touched):
        folder = ROOT / item
        if not folder.is_dir():
            continue  # removed
        old = git("show", f"{base}:{item.as_posix()}/hub.json")
        if not old:
            continue  # new item
        try:
            old_version = semver(json.loads(old).get("version"))
        except json.JSONDecodeError:
            old_version = None
        try:
            new_version = semver(json.loads((folder / "hub.json").read_text()).get("version"))
        except (json.JSONDecodeError, OSError):
            new_version = None
        if old_version and new_version and new_version <= old_version:
            report.error(folder / "hub.json", "files changed: raise \"version\" so installed copies update")
    report.print()
    return 1 if report.errors else 0


def new(kind: str, item_id: str, author: str) -> int:
    if kind not in KINDS:
        print(f"kind is one of: {', '.join(KINDS)}", file=sys.stderr)
        return 2
    if not ID_RE.match(item_id):
        print("id: 3-48 chars, lowercase letters, digits and dashes", file=sys.stderr)
        return 2
    taken = [p for p in item_dirs() if p.name == item_id]
    if taken:
        print(f'"{item_id}" is taken by {rel(taken[0])}', file=sys.stderr)
        return 1
    src = ROOT / "templates" / kind
    dest = ROOT / KINDS[kind]["dir"] / item_id
    shutil.copytree(src, dest)
    name = " ".join(w.capitalize() for w in item_id.split("-"))
    for path in files_of(dest):
        if path.suffix in (".json", ".qml", ".md", ".js"):
            text = path.read_text(encoding="utf-8")
            text = (text.replace("__ID__", item_id).replace("__NAME__", name)
                    .replace("__PASCAL__", pascal(item_id)).replace("__AUTHOR__", author or "your-github-handle"))
            path.write_text(text, encoding="utf-8")
        if "__PASCAL__" in path.name:
            path.rename(path.with_name(path.name.replace("__PASCAL__", pascal(item_id))))
    print(f"created {rel(dest)}")
    print("next: edit it, add preview.webp, then: python3 tools/hub.py validate " + rel(dest))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(prog="hub.py", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("validate")
    p.add_argument("items", nargs="*")
    p = sub.add_parser("bumps")
    p.add_argument("--base", default="origin/main")
    p = sub.add_parser("new")
    p.add_argument("kind", choices=list(KINDS))
    p.add_argument("id")
    p.add_argument("--author", default="")
    p = sub.add_parser("build")
    p.add_argument("--out", default=str(ROOT / "dist"))
    args = parser.parse_args()

    if args.cmd == "validate":
        entries, report = validate_all(args.items)
        report.print()
        if report.errors:
            print(f"{len(report.errors)} error(s)", file=sys.stderr)
            return 1
        print(f"{len(entries)} item(s) ok" + (f", {len(report.warnings)} warning(s)" if report.warnings else ""))
        return 0
    if args.cmd == "bumps":
        return bumps(args.base)
    if args.cmd == "new":
        return new(args.kind, args.id, args.author)
    return build(Path(args.out).resolve())


if __name__ == "__main__":
    sys.exit(main())
