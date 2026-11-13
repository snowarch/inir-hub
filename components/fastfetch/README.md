# Fastfetch

A quiet fastfetch: no logo, eleven lines, and your wallpaper's accent on the icons and your name.
The colours follow every theme change in iNiR, light or dark.

## On or off

Settings › Hub › Fastfetch has one switch, **Use iNiR's fastfetch**.

- If you had no fastfetch config, it is on from the start.
- If you had your own config, it stays yours and the switch starts off: turn it on to try iNiR's. Yours is kept as
  `config.jsonc.before-inir` while it is on.
- Turn it off and your own config is back, exactly as it was (or fastfetch's own look, if you never had one).
  Removing the plugin does the same.

## Changing what it shows

In Settings › Hub › Fastfetch, while the switch is on: each chip is a line, click to show or hide it.

By hand, everything is in `~/.config/fastfetch/config.jsonc`, in the `modules` list: one line each, top to bottom.

- Hide a line: put `//` in front of it.
- Show one of the extras (host, theme, icons, font, cursor, swap, display, battery, ip, what's playing): take its `//` away.
- Reorder: move the line. A gap between groups is `"break",`.

Run `fastfetch` again and it's there. Anything fastfetch knows is listed by `fastfetch --list-modules`.

iNiR only ever rewrites the colour lines, the ones ending in `// inir:`; the rest of the file is yours. Delete one of
those marks and that colour stays put; delete them all (or add `// inir:ignore`) and iNiR leaves the whole file alone.

Needs `fastfetch` and `jq`.
