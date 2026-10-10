# Shell Line

Any command, kept fresh on the Material desktop or the iRiS Island. What it prints picks the look:

| It prints | You see |
| --- | --- |
| `62%` or `62% used` | The figure and a wavy bar (it turns to your warning colour from 90 %) |
| `14` or `14 updates` | A large figure and its unit |
| Anything else | Up to 6 lines, each cut at the card's edge |

It runs the command with `sh -c`, so it needs the **process** permission.

## Settings

| Setting | What it changes |
| --- | --- |
| Label | The name above the output. Default: Home folder |
| Icon | A [Material Symbols](https://fonts.google.com/icons) name for the shape. Default: hard_drive |
| Command | What to run. Default: how full your home folder's disk is |
| Refresh every | Seconds between runs, 5 to 3600. Default: 300 |
| Lines of text to show | 1 to 6 |

In edit mode, pick the Shape or Instrument look and the shape itself.

Commands worth a card: `cat /sys/class/power_supply/BAT0/capacity` (battery, a bar), `checkupdates | wc -l` (updates, a figure), `curl -s 'wttr.in/?format=%t'` (temperature), `uptime -p` (lines).

It only runs while the card is on screen, once at load even behind windows. If the command fails, the card shows what it printed.

## For makers

The example of a widget that runs something: one `Process`, reused; a timer that stops when nobody can see the card; `shellline.js` deciding the look from the output; a failure state with words.
