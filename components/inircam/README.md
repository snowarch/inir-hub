# Inircam

A camera panel for iNiR: your IP cameras as live pictures on the desktop, and
pinned as small windows that stay up while you work.

- **Grid** of every camera, **All cameras** as a wall, and one camera **enlarged**
- **Pin** a camera to the desktop: a small floating window you can move and
  resize, which stays there while the panel is closed
- RTSP and HTTP/MJPEG streams, with TCP-first RTSP
- **Test connection** before you save a camera, so a wrong address or password is
  told to you right away
- Cameras are kept in this component's own file
  (`~/.config/inir/plugins/inircam.json`, readable by you only)

## Opening it

Every family's app launcher lists **Inircam**; a click opens the panel. From a
terminal:

```bash
inir inircam toggle
```

A keybind for it, in Niri's or Umbriel's config:

```kdl
Mod+Shift+C { spawn "inir" "inircam" "toggle"; }
```

## Adding a camera

In the panel: **Cameras → Add camera**. Fill in the name, the host or IP, the
username and password, and the stream address. **Test connection** checks it
before you save.

The brand presets fill the address for you:

| Brand | Main stream |
| --- | --- |
| Tapo / TP-Link | `rtsp://{host}:554/stream1` |
| Dahua / Imou | `rtsp://{host}:554/cam/realmonitor?channel=1&subtype=0` |
| Reolink | `rtsp://{host}:554/h264Preview_01_main` |
| Hikvision | `rtsp://{host}:554/Streaming/Channels/101` |
| Amcrest | `rtsp://{host}:554/cam/realmonitor?channel=1&subtype=0` |
| UniFi Protect | `rtsps://{host}:7441/{cameraId}` |
| ONVIF / generic RTSP | `rtsp://{host}:554/` |
| HTTP / MJPEG | `http://{host}/` |
| Custom URL | your own address |

A camera that speaks a different path is a **Custom URL**: write the whole
address yourself. The low-resolution address is optional; without it the grid
uses the main stream.

Tapo cameras need their own RTSP login: create a camera account in the Tapo
app (Settings → Advanced → Camera Account) and use that login here, not the
one you see in the app.

## Pinning a camera

Open a camera and press **Pin to desktop** (or use the **Pin** button in the
camera list). The pinned camera becomes a small window on the desktop:

- drag it to move it, drag its corner to resize it
- hover it for the controls: mute, keep above the windows or on the desktop,
  open it in the panel, unpin it
- double click opens it in the panel

Pinned cameras are remembered and come back after a restart.

## What it needs

- **ffprobe** (from `ffmpeg`) for **Test connection** and for telling a wrong
  password apart from an unreachable camera
- Qt Multimedia with the FFmpeg backend, which iNiR already carries

## Permissions

- `network` — it opens the camera streams
- `process` — it runs `ffprobe` to test a camera
- `files` — it keeps the camera list and the pinned cameras

Nothing is sent anywhere: the streams go straight from the camera to your
computer, and the camera list never leaves it.

## Commands

| Command | What it does |
| --- | --- |
| `inir inircam toggle` | Open or close the panel |
| `inir inircam open` | Open the panel |
| `inir inircam close` | Close the panel |
| `inir inircam pin CAMERA_ID` | Pin a camera to the desktop, or unpin it |
| `inir inircam pins` | Every pinned camera, as JSON |

## Credits

Built on the idea of [omacam](https://github.com/entroit/omacam) (MIT), Entroit's
camera viewer for the Omarchy bar.

## License

MIT.