# Countdown

Days left until a date you care about, with a face for every family.

| Family | Where it shows |
| --- | --- |
| Material | A card on the desktop: the figure in a Material shape you pick, and a wavy bar for how much of the wait has gone by |
| iRiS desktop | The same card in the iRiS, Prism or Material design: the days left as the figure, and the wait as a ruler whose tick for today is lit |
| Material sidebars | A card in the left sidebar's Widgets column; a tab of the right sidebar once you turn it on in Settings › Sidebars |
| iRiS Island | A line on the Island's Desktop page |
| Waffle | A card in the Widgets panel |

## Settings

| Setting | What it changes |
| --- | --- |
| What it counts down to | The name above the figure. Default: New year |
| Date | `YYYY-MM-DD`, or `YYYY-MM-DDTHH:MM` for a time of day |

On the day itself it shows the hours and minutes left, then "Today". After the date it counts the days since, without the wait. In edit mode, pick the Shape or Instrument look, the shape, and whether the wait shows.

## Sizes

- **Small:** the days left and their words.
- **Medium:** the days left, the share of the wait gone and the wait.
- **Large:** the days left, the date in full and a longer wait.

The wait runs from the day the date was set to the day itself.

## For makers

This is the example of a widget with four faces. `countdown.js` holds all the logic; `Countdown.qml`, `SidebarCountdown.qml`, `IrisCountdown.qml` and `WaffleCountdown.qml` only lay it out with their family's own parts. Under iRiS the desktop card has a face per widget design, `IrisCountdownCard.qml` and `PrismCountdown.qml`, both reading the Material card's values and drawing the wait with one shared part, `CountdownRuler.qml`. The clock wakes once a minute, and only while the widget is on screen.
