---
paths:
  - "themes/**"
  - "iris-themes/**"
---

# Colour themes and iRiS themes

Data, no code. A theme changes colours for every surface and every app iNiR themes, so it is read on everything.

## Colour themes (`themes/<id>/theme.json`)

- The Material palette: `name`, `description`, `author`, `darkmode` (`true` or `false`), and every `m3…` colour the
  template lists, as `#rrggbb`. `inir hub check` names each one that is missing. A missing role falls back to iNiR's,
  and the theme looks broken in one place.
- `darkmode` matches the palette: a light palette with `darkmode: true` puts light text on light panels.
- Text reads on its surface: body text at least 4.5:1 against the surface it sits on (`m3onSurface` on `m3surface`,
  `m3onPrimary` on `m3primary`, each `on…` on its pair), quiet text at least 3:1. No check measures this; test it.
- The Hub draws a small Material desktop in your colours. A real screenshot as `preview` says more.

## iRiS themes (`iris-themes/<id>/theme.json`)

- Starts with `"iris": "theme"` and `"version": 1`. `"id"` equals the folder name. `"values"` maps iRiS paths (`iris.…`)
  to values: keep only the values the theme is about; the rest follows the person's own choices.
- Made in iRiS's own Settings (its Themes), then exported with `inir iris theme export`, which prints the theme file.
- iRiS's own theme ids are taken. `inir hub check` refuses them.
- Try it on a light and a dark wallpaper: text on glass must read on both.

## Both

`hub.json` with `version`, `summary`, `authors` and `license`. No permissions: a theme runs nothing.
