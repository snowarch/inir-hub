# Countdown

Days left until a date you care about: a trip, a birthday, the new year. On the day itself it counts the hours and
minutes, then says Today; after it, it counts the days since.

| Family | Where it shows | How to add it |
| --- | --- | --- |
| Material | A card on the desktop | Edit the desktop, add a widget, Countdown |
| iRiS desktop | The same card in the iRiS, Prism or Material design: the days left as the figure, the wait as a ruler whose tick for today is lit | Edit the desktop, add a widget, Countdown |
| Material sidebars | A card in the left sidebar's Widgets column; a tab of the right sidebar | The card shows once installed (Settings › Panels › Widgets hides it); the tab: Settings › Sidebars › Right sidebar, Countdown |
| iRiS Island | A line on the Island's Desktop page | The Island's Desktop page, add, Countdown |
| Waffle | A card in the Widgets panel | It shows in the panel once installed |

## Sizes

- **Small:** the days left and their words.
- **Medium:** the days left, the share of the wait gone and the wait.
- **Large:** the days left, the date in full and a longer wait.

The wait runs from the day the date was set to the day itself.

## Settings

| Setting | What it changes |
| --- | --- |
| What it counts down to | The name above the figure. Default: New year |
| Date | `YYYY-MM-DD`, or `YYYY-MM-DDTHH:MM` for a time of day |

Change them on the desktop card's sheet in edit mode, or in Material's Settings › Widgets › Countdown, which shows
them while it is only in the sidebars. Every face reads the same two settings. On the desktop, edit mode also picks the Shape or Instrument look, the shape
the figure sits in, and whether the bar for how much of the wait has gone by shows; the sidebar card wears the same
shape and bar.

## For makers

Countdown is the hub's example of a widget with a face for every place: `countdown.js` holds the logic, and
`Countdown.qml`, `SidebarCountdown.qml`, `IrisCountdown.qml` and `WaffleCountdown.qml` only lay it out with their
family's parts. Under iRiS the desktop card has a face per widget design, `IrisCountdownCard.qml` and
`PrismCountdown.qml`, which draw the wait with one shared part, `CountdownRuler.qml`. [guides/widgets.md](https://github.com/snowarch/inir-hub/blob/main/guides/widgets.md) explains each face.
