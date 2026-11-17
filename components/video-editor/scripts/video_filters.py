#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Export profiles adapted from ii-p3drovfx-dev's compress_video.py."""
from video_probe import BackendError, local_path, number


def normalize_spec(raw):
    if not isinstance(raw, dict):
        raise BackendError("invalid_spec")
    crop = raw.get("crop") or {}
    if not isinstance(crop, dict):
        raise BackendError("invalid_spec")
    fmt = raw.get("format", "mp4")
    if fmt not in ("mp4", "mp3", "gif"):
        raise BackendError("invalid_spec")
    rotation = int(number(raw.get("rotation"))) % 360
    if rotation not in (0, 90, 180, 270):
        raise BackendError("invalid_spec")
    return {"input": str(local_path(raw.get("input"))), "format": fmt,
            "startSeconds": max(0, number(raw.get("startSeconds"))),
            "endSeconds": number(raw.get("endSeconds"), -1),
            "crop": {k: number(crop.get(k), default) for k, default in
                     (("x", 0), ("y", 0), ("w", -1), ("h", -1), ("uiW", 1), ("uiH", 1))},
            "crf": max(18, min(36, int(number(raw.get("crf"), 18)))),
            "rotation": rotation, "flipHorizontal": raw.get("flipHorizontal") is True,
            "flipVertical": raw.get("flipVertical") is True, "mute": raw.get("mute") is True,
            "replaceOriginal": raw.get("replaceOriginal") is True,
            "outputResolution": raw.get("outputResolution", "original"),
            "playbackRate": max(0.25, min(2, number(raw.get("playbackRate"), 1))),
            "gifFps": max(5, min(60, int(number(raw.get("gifFps"), 15)))),
            "gifScale": max(0.1, min(1, number(raw.get("gifScale"), 0.5))),
            "gifDither": raw.get("gifDither") if raw.get("gifDither") in
                         ("bayer", "floyd_steinberg", "sierra2_4a", "none") else "bayer",
            "gifColors": max(32, min(256, int(number(raw.get("gifColors"), 256))))}


def selected_range(spec, metadata):
    duration = metadata["duration"]
    start = min(duration, spec["startSeconds"])
    end = min(duration, spec["endSeconds"]) if spec["endSeconds"] >= 0 else duration
    if end - start < 0.01:
        raise BackendError("invalid_trim")
    return start, end - start


def even(value, minimum=2):
    result = max(minimum, int(round(value)))
    return result - result % 2


def crop_dimensions(spec, metadata):
    video, crop = metadata["video"], spec["crop"]
    width, height = video["width"], video["height"]
    if crop["w"] <= 0 or crop["h"] <= 0:
        return 0, 0, width, height
    if crop["uiW"] <= 0 or crop["uiH"] <= 0:
        raise BackendError("invalid_crop")
    x = min(width - 2, even(crop["x"] * width / crop["uiW"], 0))
    y = min(height - 2, even(crop["y"] * height / crop["uiH"], 0))
    w = min(width - x, even(crop["w"] * width / crop["uiW"]))
    h = min(height - y, even(crop["h"] * height / crop["uiH"]))
    return x, y, even(w), even(h)


def output_dimensions(spec, metadata):
    _, _, w, h = crop_dimensions(spec, metadata)
    if spec["rotation"] in (90, 270):
        w, h = h, w
    target = {"1080p": 1080, "720p": 720, "480p": 480}.get(spec["outputResolution"])
    if target and h > target:
        w, h = even(w * target / h), target
    if spec["format"] == "gif":
        w, h = even(w * spec["gifScale"]), even(h * spec["gifScale"])
    return w, h


def transform_filters(spec, metadata):
    filters = []
    x, y, w, h = crop_dimensions(spec, metadata)
    if (x, y, w, h) != (0, 0, metadata["video"]["width"], metadata["video"]["height"]):
        filters.append(f"crop={w}:{h}:{x}:{y}")
    rotation = spec["rotation"]
    if rotation == 90:
        filters.append("transpose=1")
    elif rotation == 180:
        filters.extend(["hflip", "vflip"])
    elif rotation == 270:
        filters.append("transpose=2")
    if spec["flipHorizontal"]:
        filters.append("hflip")
    if spec["flipVertical"]:
        filters.append("vflip")
    filters.append(f"setpts=(PTS-STARTPTS)/{spec['playbackRate']:.6f}")
    w, h = output_dimensions(spec, metadata)
    filters.append(f"scale={w}:{h}:flags=lanczos")
    return filters


def atempo(rate):
    filters = []
    while rate < 0.5:
        filters.append("atempo=0.5")
        rate *= 2
    filters.append(f"atempo={rate:.6f}")
    return ",".join(filters)


def ffmpeg_command(spec, metadata, output, progress=False):
    start, duration = selected_range(spec, metadata)
    # Trim in source time, then transform timestamps. This avoids selecting a
    # different source interval when changing the original editor's speed.
    command = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-nostdin", "-y",
               "-ss", f"{start:.6f}", "-t", f"{duration:.6f}", "-i", spec["input"]]
    fmt = spec["format"]
    if fmt == "mp3":
        if not metadata["audio"]["present"]:
            raise BackendError("no_audio")
        command.extend(["-vn", "-map", "0:a:0", "-c:a", "libmp3lame", "-b:a", "192k"])
    else:
        filters = ",".join(transform_filters(spec, metadata))
        if fmt == "gif":
            filters += (f",fps={spec['gifFps']},split[a][b];[a]palettegen=stats_mode=diff:max_colors={spec['gifColors']}[p];"
                        f"[b][p]paletteuse=dither={spec['gifDither']}"
                        + (":bayer_scale=3" if spec["gifDither"] == "bayer" else "") + ":diff_mode=rectangle")
            command.extend(["-vf", filters, "-an", "-loop", "0"])
        else:
            command.extend(["-vf", filters, "-map", "0:v:0", "-c:v", "libx264", "-preset", "fast",
                            "-crf", str(spec["crf"]), "-pix_fmt", "yuv420p"])
            if spec["mute"] or not metadata["audio"]["present"]:
                command.append("-an")
            else:
                command.extend(["-map", "0:a:0", "-c:a", "aac", "-b:a", "192k",
                                "-af", atempo(spec["playbackRate"])])
            command.extend(["-movflags", "+faststart"])
    if progress:
        command.extend(["-progress", "pipe:1", "-nostats"])
    command.append(str(output))
    return command
