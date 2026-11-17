#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""One request per worker; stdout is newline-delimited JSON for Quickshell."""
import json
import shutil
import signal
import subprocess
import sys
from video_probe import BackendError, Cancelled, Runner, local_path, probe_video, require_commands
from video_filters import normalize_spec
from video_export import export_video
from video_estimate import estimate
from video_images import snapshot, thumbnails
from video_recorder import recording_path


def main(argv):
    request_id = ""

    def emit(data):
        print(json.dumps(dict(data, requestId=request_id), ensure_ascii=False, separators=(",", ":")), flush=True)

    runner = Runner(emit)
    signal.signal(signal.SIGTERM, runner.interrupt)
    signal.signal(signal.SIGINT, runner.interrupt)
    try:
        if len(argv) != 2:
            raise BackendError("invalid_spec")
        operation, raw = argv[0], json.loads(argv[1])
        if not isinstance(raw, dict):
            raise BackendError("invalid_spec")
        request_id = str(raw.get("requestId", ""))
        if operation == "recording_path":
            emit(recording_path(raw.get("pid", 0)))
        elif operation == "probe":
            require_commands("ffmpeg", "ffprobe")
            emit(probe_video(raw.get("input"), runner))
        elif operation in ("thumbnails", "snapshot"):
            {"thumbnails": thumbnails, "snapshot": snapshot}[operation](raw, runner)
        elif operation in ("estimate", "export"):
            response = {"estimate": estimate, "export": export_video}[operation](normalize_spec(raw), runner)
            if response is not None:
                emit(response)
        elif operation == "launch_losslesscut":
            path = local_path(raw.get("input"))
            if not path.is_file():
                raise BackendError("input_missing", str(path))
            executable = shutil.which("losslesscut") or shutil.which("LosslessCut")
            if not executable:
                raise BackendError("missing_dependency", dependency="LosslessCut")
            # The external editor stays open after this worker exits.
            subprocess.Popen([executable, str(path)], stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL, start_new_session=True)
            emit({"ok": True, "event": "launched"})
        else:
            raise BackendError("invalid_spec")
        return 0
    except Cancelled:
        emit({"ok": False, "event": "cancelled"})
        return 130
    except BackendError as error:
        emit(dict(error.fields, ok=False, event="error", code=error.code, detail=error.detail))
        print(error.detail or error.code, file=sys.stderr)
        return 1
    except (ValueError, TypeError, OSError) as error:
        emit({"ok": False, "event": "error", "code": "backend_failed", "detail": str(error)})
        print(str(error), file=sys.stderr)
        return 1
    finally:
        runner.stop()


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
