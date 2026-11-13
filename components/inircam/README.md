# InirCam

Live IP camera viewer for iNiR Hub (generic iNiR and inir-omarchy fork).

- Camera grid, enlarged view, camera wall, and pinned picture-in-picture players
- RTSP and HTTP/MJPEG streams, with TCP-first RTSP and ffprobe diagnostics
- Persistent camera list in `~/.config/inir/inircam/cameras.json` (mode 600)

## Usage

Open/close via IPC:

```bash
inir inircam toggle
```

Add cameras from the Manage view inside the panel. Streams are fetched over the network from addresses you configure.
