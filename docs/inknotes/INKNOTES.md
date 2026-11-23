# Ink Notes

Open **Ink Notes** from the app launcher in Material, iRiS or Waffle. It opens a window with three panes: folders, the list of notes, and the editor.

## Notes and folders

Every note is a plain Markdown file (`.md`). Folders are real folders, one level deep. By default they live in `Documents/inknotes`. **Settings** can move the location to a hidden app folder or to any absolute folder; changing it does not move existing notes.

**New note** creates an empty note in the folder you are viewing and puts the cursor in it. Click the title to rename the note. Right-click a note to pin it, rename it, move it to another folder or move it to the trash. Right-click a folder to rename it or move it to the trash. Search looks in titles and in the text of every note.

The folder and list panes can be hidden with their buttons in the editor header (Ctrl+\\ and Ctrl+Shift+\\); the editor then takes the whole window. In a narrow window one pane shows at a time, with a back button.

## Editing

The editor shows formatted text and saves Markdown. Typing `# `, `## `, `### `, `- `, `* `, `1. ` or `[] ` at the start of a line starts a heading, list or checklist; three backticks and Enter start a code block. Enter after a heading gives body text, and Enter on an empty list item leaves the list. Click a checklist box to tick it.

| Keys | Action |
| --- | --- |
| Ctrl+B, Ctrl+I, Ctrl+Shift+X | Bold, italic, strikethrough |
| Ctrl+E, Ctrl+K | Inline code, link |
| Ctrl+0 to Ctrl+3 | Body, heading 1 to 3 |
| Ctrl+Shift+7, 8, 9 | Numbers, bullets, checklist |
| Ctrl+Z, Ctrl+Shift+Z | Undo, redo |
| Ctrl+Shift+M | Show the Markdown text |
| Ctrl+=, Ctrl+-, Ctrl+wheel | Zoom from 80 % to 200 % |
| Ctrl+Shift+T | Hide or show the format bar |
| Ctrl+N, Ctrl+F | New note, search |
| Delete | Move the selected note to the trash (not while typing) |
| Escape | Leave the field; a second press closes the window |

Each note remembers its own font (default, serif, mono) and size. Notes save a moment after you stop typing, when you switch notes and when the window closes.

## Trash

Deleted notes and folders go to `.trash` inside the notes folder. **Trash** lists them with **Restore** and **Delete forever**, and **Empty trash** deletes everything after a confirmation. Items older than the days chosen in Settings (7, 30, 90 or never) are removed when the window opens; nothing runs while it is closed.

## Settings

Notes location, sort order (last edited or title), days to keep trashed notes, and a button that opens the notes folder in your file manager. Options are kept in Ink Notes' own plugin file.
