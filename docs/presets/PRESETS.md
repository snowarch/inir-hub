# Presets

Open **Presets** from the app launcher in Material, iRiS or Waffle. It opens a window with three panes: folders, the list of presets, and the details of the chosen preset.

## Save a look

**Save current look** reads the look iNiR has now. Give it a name, pick a folder, and tick the groups to keep:

| Group | What it holds |
| --- | --- |
| Shell family | Which family is worn |
| Bar | The bar of each family |
| Theme | Theme, palette, custom theme, wallpaper theming |
| Typography | Fonts |
| Icons | iRiS icon set |
| Wallpaper | The wallpaper |
| Dock | The dock of each family |
| Surfaces | Widgets, surround, settings look, Waffle theming and background |
| Panels | Sidebars, notifications, control center, lock, task view |

A group the current look does not have is greyed out. A name that is already used in the folder gets a number.

## Apply

Choose a preset and press **Apply**. **Also apply the wallpaper** appears when the preset holds one; leave it off to keep your current wallpaper. **Preview changes** runs the apply without changing anything and lists what would change.

After an apply, **Undo last apply** (also in the message at the bottom) brings back the look from before it.

`inir presets apply <name>` opens the window and applies the preset with that name.

## Change a preset

- **Update from current look**: pick the groups to read again from the current look; the others stay as saved.
- **Edit saved groups**: untick a group to remove it from the preset.
- **Rename**, **Move** to another folder, **Delete**.

Right-click a folder to rename it or move it to the trash. In a narrow window one pane shows at a time, with a back button.

## Files

A preset is a file `<name>.look.json` in `~/.local/share/inir-presets`, inside a folder of its own or at the top. **Open presets folder** shows it in your file manager. Deleted presets and folders go to `.trash` in that folder. Setting `root` in Presets' plugin file (`~/.config/inir/plugins/presets.json`) to another absolute folder moves where presets are kept; it does not move existing ones.
