---
paths:
  - "designs/**"
  - "templates/design/**"
---

# Designs

A Design is what iRiS becomes when someone wears it: colour, type, shape, material, edges, shadow, motion and the dialect
its controls speak, over iRiS's own components. It never moves anything or changes what anything does: what is where,
what shows and what it does stay the person's. Taking it off gives them their own iRiS back, untouched.

Start from `inir hub new design <id>`.

## Files

- `plugin.json`: `"kind": "design"`, `"families"` naming the one family it dresses (`["iris"]`),
  `"provides": "modules/<id>"`, and `"parts"` naming at most `preview` (its picture in Settings), `islandFace` (the Island
  at rest) and `insignia` (its mark). Nothing else of iRiS is drawn by a Design.
- `design.json`: its values, in the schema iRiS owns, `families/iris/designs/design.schema.json`, which describes every
  key. The top-level `tokens` holds `colour`, `type`, `shape`, `material`, `motion` and `look`. A value left out is iRiS's
  own (`families/iris/designs/iris/design.json`). A value set here is the Design's, and Settings hides the row it decides.
  `inir hub check` validates the file against the schema.
- `hub.json`: `provides`, `requires: ["iris"]`, and no permissions. A Design draws; it runs nothing.
- Faces it brings ship in its folder under a free licence (OFL or another), beside the licence, and are named in
  `tokens.type.files`.

## What it may not do

- Ship a control, a card, a scene, a widget face or a Settings page of its own. One set of components serves every
  Design, and a copy drifts from it. What a Design needs that iRiS can't draw yet (a corner, an edge, a material, a way
  to move) is an issue, and iRiS gets it for every Design.
- Ship a shader: `.frag`, `.vert`, `.qsb` and `.glsl` files are refused. Materials are iRiS's; a new one goes into iRiS
  for every Design.
- Pick a bouncing or elastic motion (the schema offers none). Fix colours that don't read: the check measures text 7:1
  on its surface, secondary text 4.5:1, an accent's mark 3:1, text on its raised surface 4.5:1, and ink on an accent or
  danger fill 4.5:1. Set glass on glass.
- Write the person's settings. A Design is read, never written.

## Proof before the pull request

```sh
inir hub build && INIR_HUB_SOURCES=$PWD/dist inir hub install <id>
```

Then in Settings › Style › Design, wear it in dark and light, solid and glass (or set `tokens.material.glass` to `refuse`,
which makes every body opaque and says so in Settings), over a dark and a light wallpaper. Check the Island at rest and
with music, the Control Center, Settings, a notification and the lock. Then remove it while it is worn:

```sh
INIR_HUB_SOURCES=$PWD/dist inir hub remove <id>
```

iRiS comes back with nothing new in `inir logs --issues`. The preview is a real screenshot of it running.
