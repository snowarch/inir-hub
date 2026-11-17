#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Representative sample encoding, retaining the original editor's approach."""
import tempfile
from pathlib import Path
from video_filters import ffmpeg_command, selected_range
from video_probe import BackendError, cache_root, probe_video


def estimate(spec, runner):
    metadata = probe_video(spec["input"], runner)
    start, duration = selected_range(spec, metadata)
    if spec["format"] == "mp3":
        if not metadata["audio"]["present"]:
            raise BackendError("no_audio")
        size = int(192000 / 8 * duration)
        return {"ok": True, "event": "estimate", "estimatedSize": size,
                "low": int(size * 0.95), "high": int(size * 1.05), "method": "bitrate-exact"}
    sample_duration = min(4, duration)
    offsets = sorted({0, max(0, (duration - sample_duration) / 2), max(0, duration - sample_duration)})
    sizes = []
    with tempfile.TemporaryDirectory(prefix="estimate-", dir=cache_root()) as directory:
        for index, offset in enumerate(offsets):
            sample = dict(spec, startSeconds=start + offset, endSeconds=start + offset + sample_duration)
            output = Path(directory) / f"sample-{index}.{spec['format']}"
            runner.run(ffmpeg_command(sample, metadata, output), timeout=120)
            if not output.exists() or not output.stat().st_size:
                raise BackendError("empty_output")
            sizes.append(output.stat().st_size)
    size = max(1, int(sum(sizes) / len(sizes) / sample_duration * duration * 1.02))
    return {"ok": True, "event": "estimate", "estimatedSize": size,
            "low": int(size * 0.78), "high": int(size * 1.28), "method": "sample-encode"}
