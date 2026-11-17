---
paths:
  - "webapps/**"
---

# Web apps

A website opened as a tab in Material's left sidebar, signed in as the person, with the site's own storage. The tab shows
once the person turns on Web apps (Settings › Sidebars, or the Hub's "Show in the sidebar"), where iNiR's runtime can
host Chromium.

## manifest.json

- `id` (the folder name), `name`, `url` (https only, the site's official address), `icon` (a Material Symbols name),
  `version` (equal to `hub.json`'s), and `display`: `"tab"`.
- `iconPath`: a picture in the folder, when it ships one.
- `userscripts`: the script files in the folder that run inside the page. They need `inject`.

## Scripts and data

- Scripts run inside the page only with `inject`, and only to adapt the page to the sidebar (layout, dark mode). Never
  read, send or store what the person types or sees there.
- The site is the official one its name says: no mirrors, no link shorteners.
- `hosts` lists the site's own host.
- Preview: the sidebar open on the site, with nothing of the person's account in it.
