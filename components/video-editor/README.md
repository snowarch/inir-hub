# Video Editor

A single-clip editor for iNiR on Niri and Umbriel.
Open **Video Editor** from the app launcher in Material, iRiS, or Waffle.
Drop a local video into the window or choose **Browse Files**.

Trim with the timeline handles, crop with a preset and the draggable crop outline, rotate or flip,
and adjust playback speed or mute. Save a frame, compress MP4 video, export a GIF, or extract MP3 audio.
**Compress** exposes quality, output resolution, a sample-based size estimate, and GIF options.
Estimates are approximate; the final size depends on the video.

**Save Copy** creates a numbered `*_edited_N.mp4` beside the input. **Save and Replace** replaces an
MP4 input after encoding succeeds. For other input formats it creates `*_edited.mp4` beside the input.
GIF and MP3 exports create numbered adjacent files. Existing copies are never overwritten.
A failed or cancelled export leaves the input intact. Snapshots are numbered JPEGs in your XDG Pictures
folder (usually `~/Pictures`); they capture the original frame before editing transformations.

Controls, fonts, colors, rounding and shadows follow the active family. Theme, font and text scale
changes update live. All 18 Hub languages are supported.

## Requirements

- iNiR 3.1.2 or newer, with qs-rs/Quickshell and Qt 6 Multimedia support.
- Python 3; the backend uses only the standard library.
- FFmpeg and ffprobe. FFmpeg needs `libx264`, AAC, `libmp3lame`, JPEG encoding and the GIF palette filters.
- Optional: `wl-clipboard` (`wl-copy`) for **Copy Path**, `xdg-utils` (`xdg-open`) for opening exported
  files and folders, `libnotify` (`notify-send`) for notifications, and LosslessCut for the external editor option.

Automatic recording prompts use iNiR's recorder notifications and `RecorderStatus`. The fallback
path capture requires Linux `/proc` and wf-recorder, supplied by iNiR's recording setup.

On NixOS, add the programs to your own configuration and rebuild normally:

```nix
environment.systemPackages = with pkgs; [
  python3 ffmpeg wl-clipboard xdg-utils libnotify
  # losslesscut  # optional external editor
];
```

The plugin checks dependencies and displays processing errors in the window. It installs nothing.
Playback uses Qt Multimedia's FFmpeg backend; mpv is not required.

## Compositors

The component loads through the shell's plugin host and its launcher entry works the same on Niri
and Umbriel, in every family. Editing, playback and exports do not depend on the compositor.

It has been developed and validated on Niri only. **Umbriel is untested**: window focus/placement,
audio playback and the automatic recording prompt have not been verified there yet. Reports from
Umbriel users are welcome.

## Install and open

```sh
inir hub install video-editor
inir restart
```

For a local Hub checkout, run the official build/install flow from the Hub root:

```sh
inir hub build
INIR_HUB_SOURCES="$PWD/dist" inir hub install video-editor
inir restart
```

The component appears in every family's app launcher after the restart, on both compositors.
Optional keybind (Niri):

```kdl
Mod+Shift+V { spawn "inir" "video-editor" "toggle"; }
```

On Umbriel, iNiR carries your Niri keybinds over automatically at login and on updates; you can
also add the same command through Settings › Shortcuts or `~/.config/umbriel/config.d/90-user-extra.toml`.

| IPC | Effect |
| --- | --- |
| `inir video-editor toggle` | Open an empty editor or close it |
| `inir video-editor open` | Open/reset to an empty editor |
| `inir video-editor openFile /absolute/path/clip.mp4` | Open a local path or file URL |
| `inir video-editor prompt /absolute/path/recording.mp4` | Show the recording-finished prompt |
| `inir video-editor close` | Close the editor and prompt; stop workers |

Shortcuts: Space plays/pauses, Left/Right steps frames, Home/End seeks to trim boundaries,
I/O sets in/out, S cycles speed, P saves a frame, and Escape returns from export or closes the editor.

## Options and storage

The component keeps two options in `~/.config/inir/plugins/video-editor.json`:

```json
{
  "showEditPrompt": true,
  "openInLosslessCut": false
}
```

`showEditPrompt` enables the recording-finished prompt. `openInLosslessCut` routes its Edit button to
LosslessCut instead of the built-in editor. The options file is watched for changes and re-read when opening the editor or prompt.

When iNiR's recorder finishes successfully, its “Recording saved” notification supplies the exact
path. The prompt appears on the screen focused at completion, and **Edit Video** opens that clip.
With recorder notifications disabled or suppressed, the plugin captures wf-recorder's actual output
argument once when `RecorderStatus` reports a recording, then probes that path after recording stops.
It reads only a current-user recorder's `/proc` command line, cwd and process identity; it does not
scan video folders or poll while idle. Duplicate completion events show one prompt. Only files with
a playable video track produce a prompt. Completion while locked waits until unlock.

Very short recordings can finish before `RecorderStatus` exposes their PID. Keep recorder
notifications enabled for those clips; the `prompt` IPC remains available for other recorders.
`showEditPrompt: false` stops automatic capture/probing and disables the prompt.

Edits exist only in the current window; no project or edit history is saved. Closing the window stops
playback and workers. Cached thumbnails remain available for subsequent opens.

## Permissions

`hub.json` declares `process` and `files`:

- `process`: runs Python, FFmpeg and ffprobe, plus `wl-copy`, `xdg-open` or LosslessCut when requested.
- `files`: reads selected videos and active recorder metadata; writes adjacent exports, MP4
  replacements and Pictures snapshots. Options use `~/.config/inir/plugins/video-editor.json`;
  thumbnails and estimate samples use `$XDG_CACHE_HOME/inir/video-editor/`.

The component makes no network requests. Editing user media exceeds the Hub helper guide's usual
state/cache-only restriction; public Hub acceptance requires a policy exception for those files.

## Development and validation

From this folder:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s scripts -p 'test_*.py' -v
```

Tests use only the standard library and generated temporary media; media tests require FFmpeg.
From the Hub root:

```sh
inir hub check
inir hub validate components/video-editor
```

Before publishing, open the installed component in each family and exercise empty, loading, failed,
editing, rendering, cancellation and completed states in light/dark themes and at different scales.
The preview must be a real screenshot of the running component, containing only public test media.

## License and credits

GPLv3 (`GPL-3.0-only`), preserving the source editor's license. Author/maintainer: **Nachtasyl**
([GitHub](https://github.com/Nachtasyl)). The original QML video editor and `compress_video.py` come
from ii-p3drovfx-dev; its single-clip workflow and FFmpeg profiles form the basis of this port.
The iNiR common kit is imported from the shell. See [LICENSE](LICENSE).
