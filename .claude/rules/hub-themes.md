---
paths:
  - "themes/**"
  - "iris-themes/**"
---

# Colour themes and iRiS themes

Data, no code. A theme changes colours for every surface and every app iNiR themes, so it is read on everything.

## Colour themes (`themes/<id>/theme.json`)

- A Material palette: `name`, `description`, `author`, `darkmode`, and every `m3…` colour the template lists, as
  `#rrggbb`. Leave none out: a missing role falls back to iNiR's and the theme looks broken in one place.
- Text on its surface reads: body text at least 4.5:1 against the surface it sits on (`m3onSurface` on `m3surface`,
  `m3onPrimary` on `m3primary`, each `on…` on its pair), quiet text at least 3:1.
- `darkmode` matches the palette: a light palette with `darkmode: true` puts light text on light panels.
- The Hub draws a small Material desktop in your colours; a real screenshot as `preview` says more.

## iRiS themes (`iris-themes/<id>/theme.json`)

- Made in iRiS (Settings, or Customize on the Island), then `inir iris theme export`. Keep `"id"` equal to the folder
  and only the `values` the theme is about: the rest follows the person's own choices.
- iRiS's own ids (`frost`, `afterglow`, `sakura`…) are taken.
- Try it on a light and a dark wallpaper: text on glass reads on both.

Both: `hub.json` with `version`, `summary`, `authors`, `license`; no permissions (a theme runs nothing).
