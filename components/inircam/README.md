# iNiR Cam

IP camera viewer for [iNiR](https://github.com/snowarch/iNiR): a live camera panel (grid, enlarged, wall, manage) with pinnable desktop windows, plus a desktop widget.

Inspired by [OmaCam](https://github.com/entroit/omacam) (MIT, Entroit) and adapted for iNiR's component/widget system and runtime environment.

## Features

- **Camera panel**: grid view, enlarged single-camera view, all-cameras wall, and camera management/add/edit form.
- **Pinned cameras**: pin cameras as floating desktop windows that can stay above/below windows, be moved/resized, reopened in the panel, and persisted across restarts.
- **Desktop widget**: live camera grid on the desktop (`~/.config/inir/widgets/inircam`) with quick actions and iRiS face support.
- **RTSP/RTSPS and HTTP streams**: brand presets (Tapo, Dahua/Imou, Reolink, Hikvision, Amcrest, UniFi Protect, ONVIF/generic, HTTP/MJPEG, custom URL).
- **Connection testing/probing**: `ffprobe`-based probe to distinguish auth/path/offline/playback issues before/while using streams.
- **NVR/DVR scan & discovery helpers**: camera form includes manual add, NVR/DVR channel scan, and network discovery flows (when supported by bundled helpers).

## How it works (streams)

- **RTSP/RTSPS feeds** are rendered using an **ffmpeg frame-pull** pipeline for reliability on systems where Qt Multimedia's FFmpeg/VAAPI backend cannot display RTSP streams correctly.
  - `inircam-feeds` (bundled helper) runs `ffmpeg` processes that continuously refresh per-camera JPEG frames in `/tmp` (sub/main streams).
  - The panel/widget reads and displays those frames live.
  - The panel auto-syncs feed pullers periodically (and on camera changes) so dead streams are restarted.
- **Non-RTSP sources** (e.g. HTTP/MJPEG URLs, depending on context/implementation) may use the Qt Multimedia path where applicable.
- **Sub vs main streams**: grid/widget views typically use substreams for efficiency; enlarged/wall/main views can use higher-quality streams (depending on camera config and view).

> If feeds appear stuck on “Connecting…”, ensure `inircam-feeds` can reach the cameras/NVR and restart feed pullers (see [Troubleshooting](#troubleshooting)).

## Opening and controls

### Panel (component)

Open from iNiR (app launcher / component entry) or via IPC:

```bash
# Panel (component)
qs -p ~/.config/quickshell/inir ipc call inircam toggle
qs -p ~/.config/quickshell/inir ipc call inircam open
qs -p ~/.config/quickshell/inir ipc call inircam close
qs -p ~/.config/quickshell/inir ipc call inircam manage
qs -p ~/.config/quickshell/inir ipc call inircam add
qs -p ~/.config/quickshell/inir ipc call inircam addNvr
qs -p ~/.config/quickshell/inir ipc call inircam discover
qs -p ~/.config/quickshell/inir ipc call inircam pin "<cameraId>"
qs -p ~/.config/quickshell/inir ipc call inircam pins
```

Niri keybind example:

```kdl
Mod+Shift+C { spawn "qs" "-p" "/home/misomarchy/.config/quickshell/inir" "ipc" "call" "inircam" "toggle"; }
```

> Depending on your iNiR CLI version/config, `inir inircam <function>` may also route to the same IPC target.

### Desktop widget

The desktop widget (`custom.inircam`) registers `inircam-widget` IPC on the focused screen and provides quick actions in the widget UI (add/manage/open panel, etc.). It reads camera config from the shared inircam config file.

## Adding cameras

In the panel: **Cameras → Add camera**.

- Choose a brand preset or **Custom URL**
- Enter host/IP, credentials, and stream paths/URLs (main and optional substream)
- Use **Test connection** (ffprobe) before saving when possible

Common presets:

| Brand | Main stream template |
| --- | --- |
| Tapo / TP-Link | `rtsp://{host}:554/stream1` |
| Dahua / Imou | `rtsp://{host}:554/cam/realmonitor?channel=1&subtype=0` |
| Reolink | `rtsp://{host}:554/h264Preview_01_main` |
| Hikvision | `rtsp://{host}:554/Streaming/Channels/101` |
| Amcrest | `rtsp://{host}:554/cam/realmonitor?channel=1&subtype=0` |
| UniFi Protect | `rtsps://{host}:7441/{cameraId}` |
| ONVIF / generic RTSP | `rtsp://{host}:554/` (model-specific path often required) |
| HTTP / MJPEG | `http://{host}/` |
| Custom URL | full URL (`rtsp://`, `rtsps://`, `http://`, etc.) |

Notes:
- Tapo cameras usually require a **camera account** (Tapo app → camera → Settings → Advanced → Camera Account), not the app login.
- Some brands/models use different RTSP paths; use **Test connection** and adjust if needed.

## Pinned cameras

- Pin/unpin from the panel (or IPC `inircam pin <cameraId>`).
- Pinned cameras open as separate windows and can be moved/resized.
- Pin state is persisted by the component (see storage below).

## Storage and configuration

- **Camera config (shared)**: `~/.config/inir/plugins/inircam.json` (contains camera credentials/URLs; keep permissions restrictive)
- **Pinned windows/state**: stored by the component/plugin (e.g. pin store/config files alongside inircam plugin data, depending on implementation)
- **Desktop widget config**: managed by iNiR widget config (`widget.json` config keys; e.g. columns, click actions, etc.)

## Requirements

- **iNiR / Quickshell** environment with the inircam component/plugin installed
- **ffmpeg** and **ffprobe** (used for RTSP frame pulling and connection probing)
- Network access from this machine to the camera/NVR hosts
- For RTSP frame pulling: the bundled `inircam-feeds` helper must be able to run on the system

## Feed helper (`inircam-feeds`)

`inircam-feeds` manages ffmpeg processes that pull RTSP streams into continuously updated JPEG frames for the UI.

Typical usage:

```bash
# start or restart missing/dead feed pullers
~/.local/bin/inircam-feeds sync

# keep feeds alive in foreground (optional)
~/.local/bin/inircam-feeds daemon

# stop managed feed pullers
~/.local/bin/inircam-feeds stop
```

When installed as a component/module, a bundled copy may also be available in the inircam module directory; the panel attempts to auto-sync feeds periodically.

## Permissions

Declared in `hub.json` (component):

- `process` — runs `ffprobe`/helper processes for probing and feed pulling
- `network` — connects to camera/NVR streams and endpoints
- `files` — reads/writes camera/pin configuration and local runtime/frame files

## Privacy and security

- Streams go directly between your machine and your cameras/NVR (no cloud relay by this component).
- Camera credentials may be stored in `~/.config/inir/plugins/inircam.json`; protect this file and use least-privilege camera accounts where possible.
- Snapshots/recordings behavior depends on UI actions and implementation; frame pulling writes temporary JPEG frames for live display.

## Troubleshooting

- **Stuck on “Connecting…”**
  - Verify the camera/NVR is reachable (`ping`, `ffprobe` against the RTSP URL).
  - Restart feed pullers: `~/.local/bin/inircam-feeds sync` (or the bundled helper).
  - Check feed logs in `${XDG_RUNTIME_DIR:-/tmp}/inircam-feeds/*.log`.
  - Ensure credentials and stream paths are correct (use **Test connection**).
- **Some streams work, others fail**
  - Substream/main stream paths or codecs may differ by channel/model. Try different subtype/channel/path values.
  - NVRs may limit concurrent sessions; too many main streams can cause timeouts.
- **Feeds stop after some time**
  - RTSP sessions can drop; re-run `inircam-feeds sync` or keep the helper running (`daemon`) if needed.
  - Network instability/NVR timeouts can cause ffmpeg to exit and require restart.
- **Widget buttons do nothing**
  - Ensure the inircam panel component is installed/loaded (the widget triggers panel IPC actions).
  - Check logs for QML/IPC errors (`inir logs`).

## Comparison with OmaCam

iNiR Cam is inspired by [OmaCam](https://github.com/entroit/omacam), but it is **not a 1:1 port**:

- **Integration target**: OmaCam is an Omarchy bar plugin; iNiR Cam is an iNiR panel/component and desktop widget.
- **UI/UX**: similar concepts (grid/enlarged/wall, pinned players, probing), but different layouts, controls, and configuration surfaces.
- **Configuration model**: OmaCam uses a rich `~/.config/omacam/config.json` (keys, click actions, connection tuning, etc.). iNiR Cam currently stores camera config in `~/.config/inir/plugins/inircam.json` and uses iNiR widget/component settings where applicable; keybinding/click customization parity is not complete.
- **Streaming backend**: OmaCam uses Qt Multimedia/FFmpeg with a shared stream pool approach. iNiR Cam adds an **ffmpeg frame-pull fallback for RTSP** (via `inircam-feeds`) to work around RTSP rendering issues on affected systems; this trades some efficiency/latency characteristics for reliability.
- **Audio/snapshots/advanced tuning**: feature parity varies by implementation and environment; check the current UI and IPC for supported actions.

## Credits

- [OmaCam](https://github.com/entroit/omacam) (MIT, Entroit) — original concept and reference implementation for Omarchy
- iNiR and Quickshell ecosystem components used by this implementation

## License

MIT (see `LICENSE` in this component).
