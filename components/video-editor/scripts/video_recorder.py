#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Read the actual wf-recorder output argument, never guess a recent filename."""
import os
from pathlib import Path


def recording_path(pid, proc=Path('/proc')):
    pid = int(pid)
    path = ''
    if pid > 0:
        process = proc / str(pid)
        try:
            # Only starttime identifies the process; CPU counters change every tick.
            identity = (process / 'stat').read_text().rsplit(') ', 1)[1].split()[19]
            if process.stat().st_uid == os.getuid() and (process / 'comm').read_text().strip() == 'wf-recorder':
                arguments = [os.fsdecode(a) for a in (process / 'cmdline').read_bytes().split(b'\0') if a]
                for index, argument in enumerate(arguments):
                    if argument in ('-f', '--file') and index + 1 < len(arguments):
                        value = arguments[index + 1]
                    elif argument.startswith('--file='):
                        value = argument[7:]
                    else:
                        continue
                    if value:
                        output = Path(value)
                        if not output.is_absolute():
                            output = (process / 'cwd').resolve() / output
                        path = str(output.resolve())
                        break
                if (process / 'stat').read_text().rsplit(') ', 1)[1].split()[19] != identity:
                    path = ''
        except (OSError, ValueError, IndexError):
            path = ''  # A recorder can exit between the status signal and this read.
    return {'ok': True, 'event': 'recording_path', 'pid': pid, 'path': path}
