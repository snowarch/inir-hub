#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Timeline thumbnails and original-frame JPEG snapshots."""
import hashlib
from pathlib import Path
from video_export import publish, temporary_output
from video_probe import BackendError, cache_root, number, probe_video


def save_frame(source, position, output, runner, thumbnail=False):
    temporary = temporary_output(output)
    try:
        command = ['ffmpeg', '-hide_banner', '-loglevel', 'error', '-nostdin', '-y',
                   '-ss', f'{position:.6f}', '-i', str(source), '-frames:v', '1']
        if thumbnail:
            command.extend(['-vf', 'scale=1280:-2'])
        runner.run(command + ['-q:v', '2', str(temporary)])
        if not temporary.stat().st_size:
            raise BackendError('empty_output')
        # Only the plugin's own cache frames may be refreshed in place.
        publish(temporary, output, replace=thumbnail)
    finally:
        temporary.unlink(missing_ok=True)


def thumbnails(raw, runner):
    metadata = probe_video(raw.get('input'), runner)
    source = Path(metadata['path'])
    identity = f"{source}:{source.stat().st_mtime_ns}:{metadata['size']}"
    directory = cache_root() / 'thumbnails' / hashlib.sha256(identity.encode()).hexdigest()[:24]
    directory.mkdir(parents=True, exist_ok=True)
    count = 8  # The original editor's thumbnail count.
    last_frame = max(0, metadata['duration'] - 1 / max(1, metadata['video']['fps']))
    for index in range(count):
        output = directory / f'frame-{index}.jpg'
        if not output.is_file() or not output.stat().st_size:
            save_frame(source, last_frame * index / (count - 1), output, runner, thumbnail=True)
        runner.emit({'event': 'thumbnail', 'index': index, 'path': str(output), 'url': output.as_uri()})
    runner.emit({'event': 'thumbnails_finished', 'count': count})


def snapshot(raw, runner):
    metadata = probe_video(raw.get('input'), runner)
    source = Path(metadata['path'])
    last_frame = metadata['duration'] - 1 / max(1, metadata['video']['fps'])
    position = max(0, min(number(raw.get('positionSeconds')), last_frame))
    directory = Path(raw.get('outputDir') or Path.home() / 'Pictures').expanduser().resolve()
    directory.mkdir(parents=True, exist_ok=True)
    stamp = f'{int(position // 60):02d}m{int(position % 60):02d}s{int(position % 1 * 100):02d}'
    stem = f'{source.stem}_snapshot_{stamp}'
    output = directory / f'{stem}.jpg'
    index = 1
    while output.exists():
        output = directory / f'{stem}_{index}.jpg'
        index += 1
    save_frame(source, position, output, runner)
    runner.emit({'ok': True, 'event': 'snapshot_done', 'path': str(output)})
