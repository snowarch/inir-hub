# Workspaces

Your workspaces on the desktop, drawn the way Niri lays them out: one lane per workspace of the screen, top to bottom
as Niri stacks them. Each lane holds its columns left to right, as wide as they are on the screen; windows stacked
in a column split it, floating windows stand together at the end. The workspace you are on stands taller and its
window in focus is lit; in every other workspace the window it comes back to is a step brighter. An empty workspace
is a thin slot, so the room goes to the ones with windows.

| Family | Where it shows | How to add it |
| --- | --- | --- |
| Material | A card on the desktop | Edit the desktop, add a widget, Workspaces |
| iRiS | The desktop card in the iRiS, Prism or Material design | Edit the desktop, add a widget, Workspaces |

It works on Niri and Umbriel. On another compositor the card says so. iRiS's own Workspaces bubble and Waffle's Task
View already show workspaces on their surfaces, so this widget only lives on the desktop.

## Using it

- **Press a window** to go to it: Niri focuses it, on its workspace.
- **Press a lane** outside its windows to go to that workspace.
- **Each window says its app:** the icon where it fits, the name beside it where the window is wide enough. Titles
  never show, so nothing private sits on the desktop.

Nothing reacts while the desktop is in edit mode, so the card can be moved.

## Sizes

- **Small:** the workspace in use and the two around it, app icons where they fit.
- **Medium:** three workspaces with their numbers, and the apps named on windows wide enough.
- **Large:** up to six workspaces; the Material card also names the one in use.

When there are more workspaces than fit, the card shows the one in use and its neighbours.

## Settings

| Setting | What it changes |
| --- | --- |
| App icons | The app's icon on each window, where it fits. Default: on |

In edit mode, the Material card also picks the Shape or Instrument look, and the shape that holds the number of the
workspace in use. Under iRiS the card wears the family's widget designs like every other widget (iRiS, Prism or
Material, picked on the Look page of its sheet).

## Notes

It reads the layout iNiR already gets from the compositor, and redraws only when a window opens, closes or moves,
never when a title changes. It runs no command and needs nothing installed.
