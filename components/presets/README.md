# Presets

Save the look of your desktop as named presets, keep them in folders, and apply one with a click. A window opened from the app launcher in Material, iRiS and Waffle.

- **Save current look** exports the look iNiR has now and keeps the groups you choose: shell family, bar, theme, typography, icons, wallpaper, dock, surfaces, panels. A group the current look does not have cannot be chosen.
- **Apply** imports the preset with `inir look import`; **Also apply the wallpaper** turns the wallpaper off for that apply. **Preview changes** shows what an apply would change (a dry run). **Undo last apply** restores the snapshot taken before it (`inir look restore 1`).
- **Update from current look** reads the groups you pick again from the current look. **Edit saved groups** drops groups from a preset. Presets can be renamed, moved to another folder and deleted (to a trash folder).
- Presets are files, `<name>.look.json`, in `~/.local/share/inir-presets` (folders one level deep). A different absolute folder can be set as `root` in the plugin file. Removed presets and folders go to `.trash` in that folder; nothing is deleted for good.
- Options (`root`, `lastFolder`, `applyWallpaper`) are in Presets' own plugin file, `~/.config/inir/plugins/presets.json`.
- Presets never write iNiR's settings themselves: every change to the desktop is made by `inir look import` or `inir look restore`.

Full guide: `docs/presets/PRESETS.md`.

## IPC

```
inir presets toggle
inir presets open
inir presets close
inir presets apply <name>
```

`apply` opens the window and applies the preset with that name (case does not matter).

Keybind for Niri or Umbriel:

```kdl
Mod+Shift+P { spawn "inir" "presets" "toggle"; }
```

## Permissions

`files`: reads and writes the presets folder. `process`: runs `inir look export|import|restore`, and mkdir, mv, rm and find on the presets folder, and xdg-open for "Open presets folder". No network.

## Tests

```
node tests/test_preset_logic.js
node tests/test_store_logic.js
```
