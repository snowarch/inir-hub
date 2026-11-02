# Fastfetch

A quiet fastfetch: no logo, eleven lines, and your wallpaper's accent on the icons and your name.
The colours follow every theme change in iNiR, light or dark.

## Changing what it shows

In Settings › Hub › Fastfetch, under What it shows: each chip is a line, click to show or hide it.

By hand, everything is in `~/.config/fastfetch/config.jsonc`, in the `modules` list: one line each, top to bottom.

- Hide a line: put `//` in front of it.
- Show one of the extras (host, theme, icons, font, cursor, swap, display, battery, ip, what's playing): take its `//` away.
- Reorder: move the line. A gap between groups is `"break",`.

Run `fastfetch` again and it's there. Anything fastfetch knows is listed by `fastfetch --list-modules`.

iNiR only ever rewrites the colour lines, the ones ending in `// inir:`; the rest of the file is yours. Delete one of
those marks and that colour stays put.

## Installing and removing

If you already had a config, it is kept next to the new one as `config.jsonc.before-inir`. Removing the plugin
leaves the config where it is, with the last colours it had; to go back, rename `config.jsonc.before-inir` to
`config.jsonc`.

Needs `fastfetch` and `jq`.
