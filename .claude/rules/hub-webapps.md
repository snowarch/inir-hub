---
paths:
  - "webapps/**"
---

# Web apps

A website opened as a tab in Material's left sidebar, signed in as the person, with the site's own storage. The tab
shows once the person turns on Web apps (Settings › Sidebars, or the Hub's "Show in the sidebar"), where iNiR's
runtime carries Chromium.

- `manifest.json`: `id` (the folder name), `name`, `url` (https only), `icon` (a Material Symbols name), `version`
  (the same as `hub.json`'s), `display: "tab"`.
- The site is the one its name says, at its official address. No mirrors, no sites that host content without the
  rights to it, nothing behind a link shortener.
- Scripts run inside the page only with the `inject` permission, and only to adapt the page to the sidebar (layout,
  dark mode). Never read, send or store what the person types or sees there.
- `hosts` lists the site's own host.
- Preview: the sidebar open on the site, nothing of the person's account in it.
