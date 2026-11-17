#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Local input probing and cancellable subprocess ownership."""
import ctypes
import json
import math
import os
import shutil
import signal
import subprocess
import tempfile
import time
from pathlib import Path
from urllib.parse import unquote, urlsplit


class BackendError(Exception):
    def __init__(self, code, detail="", **fields):
        super().__init__(detail)
        self.code, self.detail, self.fields = code, detail, fields


class Cancelled(Exception):
    pass


def number(value, fallback=0.0):
    try:
        result = float(value)
        return result if math.isfinite(result) else fallback
    except (ValueError, TypeError):
        return fallback


def fraction(value):
    try:
        parts = str(value).split("/")
        return number(parts[0]) / number(parts[1]) if len(parts) == 2 else number(value)
    except ZeroDivisionError:
        return 0.0


def local_path(value):
    if not isinstance(value, str) or not value or "\0" in value:
        raise BackendError("invalid_input")
    if value.startswith("file:"):
        url = urlsplit(value)
        if url.netloc not in ("", "localhost"):
            raise BackendError("local_files_only")
        value = unquote(url.path)
    elif "://" in value:
        raise BackendError("local_files_only")
    return Path(value).expanduser().resolve()


def require_commands(*names):
    for name in names:
        if not shutil.which(name):
            raise BackendError("missing_dependency", dependency=name)


def cache_root():
    base = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache")))
    result = base / "inir" / "video-editor"
    result.mkdir(parents=True, exist_ok=True)
    return result


def _child_lifetime():
    # Linux parent-death signal also covers a shell forcibly killing the worker.
    parent = os.getppid()
    ctypes.CDLL(None).prctl(1, signal.SIGKILL, 0, 0, 0)
    if parent == 1 or os.getppid() != parent:
        os.kill(os.getpid(), signal.SIGKILL)


class Runner:
    def __init__(self, emit):
        self.emit = emit
        self.child = None

    def interrupt(self, *_):
        raise Cancelled()

    def stop(self):
        child = self.child
        if child is None:
            return
        if child.poll() is None:
            try:
                os.killpg(child.pid, signal.SIGTERM)
                child.wait(timeout=2)
            except (ProcessLookupError, subprocess.TimeoutExpired):
                if child.poll() is None:
                    os.killpg(child.pid, signal.SIGKILL)
                    child.wait()
        self.child = None

    def start(self, command, **streams):
        require_commands(command[0])
        self.child = subprocess.Popen(command, text=True, start_new_session=True,
                                      preexec_fn=_child_lifetime, **streams)

    def run(self, command, timeout=120):
        try:
            self.start(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            stdout, stderr = self.child.communicate(timeout=timeout)
            if self.child.returncode:
                raise BackendError("command_failed", stderr.strip())
            return stdout
        except subprocess.TimeoutExpired as error:
            raise BackendError("command_timeout", command[0]) from error
        finally:
            self.stop()

    def render(self, command, duration):
        started = time.monotonic()
        # A file drains stderr independently of progress, avoiding pipe deadlocks.
        with tempfile.TemporaryFile(mode="w+") as errors:
            try:
                self.start(command, stdout=subprocess.PIPE, stderr=errors)
                for line in self.child.stdout:
                    key, _, value = line.strip().partition("=")
                    if key in ("out_time_us", "out_time_ms"):
                        self.emit({"event": "progress", "value": min(1, max(0, number(value) / 1e6 / duration)),
                                   "elapsed": time.monotonic() - started})
                if self.child.wait():
                    errors.seek(0)
                    raise BackendError("command_failed", errors.read().strip())
            finally:
                if self.child and self.child.stdout:
                    self.child.stdout.close()
                self.stop()


def probe_video(value, runner):
    path = local_path(value)
    if not path.is_file():
        raise BackendError("input_missing", str(path))
    try:
        data = json.loads(runner.run(["ffprobe", "-v", "error", "-show_format", "-show_streams",
                                     "-of", "json", str(path)], timeout=30))
    except json.JSONDecodeError as error:
        raise BackendError("invalid_response", str(error)) from error
    streams, fmt = data.get("streams", []), data.get("format", {})
    video = next((s for s in streams if s.get("codec_type") == "video"), {})
    audio = next((s for s in streams if s.get("codec_type") == "audio"), {})
    duration = number(fmt.get("duration"), number(video.get("duration")))
    if not video or duration <= 0 or number(video.get("width")) < 2 or number(video.get("height")) < 2:
        raise BackendError("invalid_video")
    return {"ok": True, "event": "metadata", "path": str(path), "url": path.as_uri(),
            "size": path.stat().st_size, "modifiedNs": str(path.stat().st_mtime_ns), "duration": duration,
            "format": {"name": fmt.get("format_name", ""), "bitrate": number(fmt.get("bit_rate"))},
            "video": {"codec": video.get("codec_name", ""), "width": int(video["width"]),
                      "height": int(video["height"]), "fps": fraction(video.get("avg_frame_rate")) or fraction(video.get("r_frame_rate")),
                      "bitrate": number(video.get("bit_rate"))},
            "audio": {"present": bool(audio), "codec": audio.get("codec_name", ""),
                      "channels": int(number(audio.get("channels"))), "bitrate": number(audio.get("bit_rate"))}}
