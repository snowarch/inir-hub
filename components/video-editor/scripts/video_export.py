#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Atomic output publication: a failed or cancelled job never replaces input."""
import os
import tempfile
from pathlib import Path
from video_filters import ffmpeg_command, output_dimensions, selected_range
from video_probe import BackendError, probe_video


def fingerprint(path):
    info = path.stat()
    return info.st_dev, info.st_ino, info.st_size, info.st_mtime_ns


def output_path_for(spec):
    source, fmt = Path(spec["input"]), spec["format"]
    if spec["replaceOriginal"] and fmt == "mp4" and source.suffix.lower() == ".mp4":
        return source, True
    if spec["replaceOriginal"]:
        return source.with_name(f"{source.stem}_edited.{fmt}"), False
    index = 1
    while True:
        path = source.with_name(f"{source.stem}_edited_{index}.{fmt}")
        if not path.exists():
            return path, False
        index += 1


def temporary_output(final):
    fd, name = tempfile.mkstemp(prefix=".video-editor-", suffix=final.suffix, dir=final.parent)
    os.close(fd)
    return Path(name)


def publish(temporary, final, replace=False):
    if replace:
        os.replace(temporary, final)
    else:
        # Hard-link publication cannot overwrite a copy created concurrently.
        try:
            os.link(temporary, final)
        except FileExistsError as error:
            raise BackendError("output_exists", str(final)) from error
        temporary.unlink()


def export_video(spec, runner):
    metadata = probe_video(spec["input"], runner)
    source = Path(spec["input"])
    original = fingerprint(source)
    final, replaces_source = output_path_for(spec)
    temporary = temporary_output(final)
    try:
        _, source_duration = selected_range(spec, metadata)
        duration = source_duration if spec["format"] == "mp3" else source_duration / spec["playbackRate"]
        width, height = output_dimensions(spec, metadata)
        command = ffmpeg_command(spec, metadata, temporary, progress=True)
        runner.emit({"event": "started", "outputPath": str(final), "format": spec["format"],
                     "duration": duration, "width": width, "height": height})
        runner.render(command, duration)
        if not temporary.exists() or temporary.stat().st_size == 0:
            raise BackendError("empty_output")
        if replaces_source and fingerprint(source) != original:
            raise BackendError("input_changed")
        publish(temporary, final, replaces_source)
        runner.emit({"event": "finished", "outputPath": str(final), "size": final.stat().st_size,
                     "format": spec["format"], "replacedSource": replaces_source,
                     "duration": duration, "width": width, "height": height})
    finally:
        temporary.unlink(missing_ok=True)
