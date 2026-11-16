# iNiR Cam

Live IP camera panel for iNiR: a grid of cameras, one enlarged, a wall of all of them, a form to add and edit them, and cameras you can pin to the desktop.

Inspired by [OmaCam](https://github.com/entroit/omacam) (MIT, Entroit).

## Features

- **Views**: a grid, one enlarged camera, a wall of every camera, and the form to add or edit one.
- **Pinned cameras**: pin a camera as its own window over the desktop, move and resize it, keep it above or below windows, and it comes back after a restart.
- **Brands**: Tapo, Dahua/Imou, Reolink, Hikvision, Amcrest, UniFi Protect, ONVIF and a custom URL.
- **Test connection** with `ffprobe` before saving a camera, so a wrong password or path is not a mystery later.
- **Add helpers**: enter one camera by hand, scan an NVR/DVR for its channels, or look for cameras on the network. A helper that is not there hides its own button.

## How the streams work

RTSP and RTSPS are drawn by `inircam-feeds`, a small helper that runs `ffmpeg` and keeps a fresh JPEG per camera for the panel to show. That path is used because Qt Multimedia's FFmpeg/VAAPI backend fails on some machines with `Invalid data found` or EGL texture errors, and a JPEG that is always ready never shows a broken video surface.

The frames live in `$XDG_RUNTIME_DIR/inircam`, a folder only you can read (mode 700), and the pullers run only while the panel or a pinned camera is on screen. Camera passwords travel in a 0600 file and the puller starts non-dumpable, so they do not show up in `ps` for anyone else.

Everything else (HTTP, MJPEG) plays through Qt Multimedia.

Grid tiles use the substream when a camera has one, and enlarged and wall views use the main stream.

## Opening it

From the app launcher, or:

```bash
inir inircam toggle
```

`inircam` also answers `open`, `close`, `manage`, `add`, `addNvr`, `discover`, `pin <cameraId>` and `pins`. Pin the panel to a key:

```kdl
Mod+Shift+C { spawn "inir" "inircam" "toggle"; }
```

## Adding a camera

**Cameras → Add camera**, pick a brand or **Custom URL**, enter the host and the camera's own login, then **Test connection** and save.

| Brand | Main stream |
| --- | --- |
| Tapo / TP-Link | `rtsp://{host}:554/stream1` |
| Dahua / Imou | `rtsp://{host}:554/cam/realmonitor?channel=1&subtype=0` |
| Reolink | `rtsp://{host}:554/h264Preview_01_main` |
| Hikvision | `rtsp://{host}:554/Streaming/Channels/101` |
| Amcrest | `rtsp://{host}:554/cam/realmonitor?channel=1&subtype=0` |
| UniFi Protect | `rtsps://{host}:7441/{cameraId}` |
| ONVIF / generic | `rtsp://{host}:554/` |
| HTTP / MJPEG | `http://{host}/` |
| Custom | any full `rtsp://`, `rtsps://` or `http://` URL |

Tapo cameras want a camera account from the Tapo app (Settings → Advanced → Camera Account), not the app login.

## Pinned cameras

The pin button in the panel, or `inir inircam pin <cameraId>`, gives a camera its own window: drag it by its header, resize it from its grip, and use its buttons to toggle always-on-top, open it in the panel, or close it. Pins survive a restart and are kept in the state folder.

## Where it keeps things

- `~/.config/inir/plugins/inircam.json` — the cameras, mode 600, because it holds camera passwords.
- the state folder — `inircam-pins.json`, where each pin sits.

## Requirements

- `ffmpeg` and `ffprobe` on `PATH`.
- Network access to the cameras or NVR.

## Permissions

- `process`: runs `ffprobe` to test a camera and the feed helper that pulls RTSP frames.
- `network`: connects to the cameras.
- `files`: reads and writes its options and the frames it shows.

## If a camera will not show

- **Stuck on “Connecting…”**: check the camera answers (`ffprobe -rtsp_transport tcp "<url>"`), run **Test connection** in the panel, and look at `$XDG_RUNTIME_DIR/inircam/feeds/*.log`.
- **One camera fails, the rest work**: brands disagree about substream paths and codecs; try another subtype or path.
- **Feeds stop after a while**: an RTSP session can drop. The panel restarts its pullers as it needs them; a restart of the panel also clears a stuck feed.
- **An NVR refuses a stream**: many allow only a few sessions at once, so too many main streams can make later ones time out.

## Credits

OmaCam by Entroit for the idea and its reference implementation of the camera panel.

## License

MIT, the license of this repository.
