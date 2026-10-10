# Countdown

Days left until a date you care about, with a face for every family.

| Family | Where it shows |
| --- | --- |
| Material | A card on the desktop: the figure in a Material shape you pick, and a wavy bar for how much of the wait has gone by |
| iRiS | A line on the Island's Desktop page |
| Waffle | A card in the Widgets panel |

## Settings

| Setting | What it changes |
| --- | --- |
| What it counts down to | The name above the figure. Default: New year |
| Date | `YYYY-MM-DD`, or `YYYY-MM-DDTHH:MM` for a time of day |

On the day itself it shows the hours and minutes left, then "Today" in a burst. After the date it counts the days since. In edit mode, pick the Shape or Instrument look, the shape, and whether the wait bar shows.

## For makers

This is the example of a widget with three faces. `countdown.js` holds all the logic; `Countdown.qml`, `IrisCountdown.qml` and `WaffleCountdown.qml` only lay it out with their family's own parts. The clock wakes once a minute, and only while the widget is on screen.
