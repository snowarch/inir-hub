---
paths:
  - "designs/**"
  - "templates/design/**"
---

# Designs

A Design is what iRiS becomes when someone wears it: colour, type, shape, material, edges, shadow, motion and the
dialect its controls speak, over iRiS's own components. It never moves anything or changes what anything does: what is
where, what shows and what it does stay the person's. Taking it off gives them their own iRiS back, untouched.

## Shape (`inir hub new design <id>` gives it)

- `plugin.json`: `"kind": "design"`, `"families": ["iris"]`, `"provides": "modules/<id>"`, and `"parts"` naming at
  most `preview` (its picture in Settings), `islandFace` (the Island at rest) and `insignia` (its mark). Nothing else
  of iRiS is drawn by a Design.
- `design.json`: its values, in the schema iRiS owns (`families/iris/designs/design.schema.json`, every key described
  there). Leave out what it doesn't change: iRiS's own value applies (`families/iris/designs/iris/design.json`).
  A value it sets is its own and Settings hides the row it decides. `inir hub check` validates it against the schema.
- `hub.json`: `"provides": "modules/<id>"`, `"requires": ["iris"]`, no permissions (a Design draws; it runs nothing).
- Faces it brings ship in its folder, OFL or another free licence beside them, listed in `design.json` › `type.files`.

## What it may not do

- Ship a control, a card, a scene, a widget face or a Settings page of its own: one set of components serves every
  Design, and a copy drifts from it. What a Design needs that iRiS can't draw yet (a corner, an edge, a material, a
  way to move) is asked for in an issue and added to iRiS for every Design.
- Ship a shader. Materials are iRiS's field; a new one goes there, inside the budget every Design keeps.
- Pick a bouncing or elastic motion (the schema offers none), fix colours that don't read (text 7:1 on its paper,
  secondary text 4.5:1, an accent's mark 3:1, ink on a filled colour 4.5:1: the check measures them), or set glass
  on glass.
- Write the person's settings. A Design is read, never written.

## Proof before the pull request

`inir hub build && INIR_HUB_SOURCES=$PWD/dist inir hub install <id>`, then Settings › Style › Design: wear it in dark
and light, solid and glass (or say in `design.json` it refuses glass), over a dark and a light wallpaper; the Island at
rest and with music, the Control Center, Settings, a notification, the lock. Then remove it while worn: iRiS comes
back with nothing new in `inir logs --issues`. The preview is a real screenshot of it running.
