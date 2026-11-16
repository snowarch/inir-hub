# Cameras

Your cameras from the camera panel, as a grid on the desktop.

It installs alongside **Cameras** (`inircam`), the panel that adds cameras, scans an NVR and pins
feeds. The panel does the work and this card shows it: no stream is opened here, no password is
read here, and nothing is written here. The card reads only the frames the panel writes, never the
panel's own settings file — it asks the panel for its cameras over IPC instead.

| Family | Where it shows |
| --- | --- |
| Material | A card on the desktop: the cameras as a grid, on the plate you already use |

## Settings

| Setting | What it changes |
| --- | --- |
| Columns | How many tiles across, 1 to 4. Default: 2 |
| Show how many cameras | The count next to the title. Default: on |
| Click | What clicking a tile does: pin that camera to the desktop, open the panel, or nothing. Default: pin |

Resize the card and the tiles follow. The gear opens the panel's manage view.

## How it stays honest

The card asks the panel for the camera list and asks it to keep the frames running while the card
is on screen. When the card is hidden it lets the frames go, and the panel stops them when nobody
holds them — the same rule the panel follows for itself. A camera that cannot be reached says
"No signal" instead of showing an old picture.

## Requirements

- iNiR 3.1.0 or later, with the **Cameras** panel (`inircam`) installed
- `ffmpeg`, which the panel uses to pull the RTSP frames
