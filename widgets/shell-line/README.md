# Shell Line

The output of a command you choose, on the Material desktop or the iRiS Island.

It runs the command with `sh -c`, so it needs the **process** permission.

## Settings

| Setting | What it changes |
| --- | --- |
| Label | The name above the output. Default: Uptime |
| Command | What to run. Default: `uptime -p` |
| Refresh every | Seconds between runs, 5 to 3600 |
| Lines to show | 1 to 6 |

Some commands worth a line: `cat /sys/class/power_supply/BAT0/capacity`, `checkupdates | wc -l`, `curl -s wttr.in/?format=3`.

It only runs while the card is on screen. If the command fails, the card shows what it printed.

## For makers

The example of a widget that runs something: one `Process`, reused; a timer that stops when nobody can see the card; a failure state with words.
