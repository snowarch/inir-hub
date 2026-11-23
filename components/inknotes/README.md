# Ink Notes

Markdown notes in plain files, with folders, search, pins and a trash. A window opened from the app launcher in Material, iRiS and Waffle.

- Notes are `.md` files in `Documents/inknotes` (or a hidden app folder, or any absolute folder, chosen in Settings). Folders are one level deep.
- A rich editor that writes Markdown: headings, bullets, numbers, checklists, code blocks, bold, italic, strikethrough, inline code, links, undo and redo, zoom, and a plain Markdown view.
- Trash in `.trash` inside the notes folder, kept 7, 30 or 90 days, or never purged. Purging happens only when the window opens.
- Options (location, sort, trash days, pins, last note, per-note font and size, zoom, pane and toolbar visibility) are in Ink Notes' own plugin file.

Full guide and shortcuts: `docs/inknotes/INKNOTES.md`.

## IPC

```
inir inknotes toggle
inir inknotes open
inir inknotes close
inir inknotes newNote
```

Keybind for Niri or Umbriel:

```kdl
Mod+Shift+N { spawn "inir" "inknotes" "toggle"; }
```

## Permissions

`files`: reads and writes the notes folder. `process`: runs mkdir, mv, rm, find and grep on it, and xdg-open for "Open notes folder". No network.

## Tests

```
node tests/test_md_ops.js
node tests/test_notes_logic.js
/usr/lib/qt6/bin/qmltestrunner -platform offscreen -input tests/tst_editor.qml
```
