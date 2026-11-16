# Network

What comes in and goes out of your connection, second by second, and its last minute drawn as a horizon: what came
in rises above the line, what went out hangs under it. Both sit on one scale, so they compare: a download and the
upload beside it both read, because the scale is logarithmic and set by the minute's highest rate. Until a minute
has passed, the horizon grows in from the right.

The card names the link the traffic takes (Wi-Fi, Ethernet, VPN, Mobile, or the interface's own name), the one your
default route uses right now.

| Family | Where it shows | How to add it |
| --- | --- | --- |
| Material | A card on the desktop | Edit the desktop, add a widget, Network |
| iRiS | The desktop card in the iRiS, Prism or Material design | Edit the desktop, add a widget, Network |

## Sizes

- **Small:** the rate coming in, what goes out, and a short horizon.
- **Medium:** both rates and the horizon, with the minute's peak (and, in Prism, how much came in).
- **Large:** the rates over a tall horizon, with the minute's peak and how much it moved.

## States

- **Measuring…** for the first second, before there are two readings to compare.
- **No connection** while there is no default route; it shows the traffic again as soon as one comes up.
- A change of link (Wi-Fi to Ethernet, a VPN coming up) starts a new minute, so two links never mix in one horizon.

## Settings

| Setting | What it changes |
| --- | --- |
| Speeds in | MB/s (bytes, steps of 1024, as file managers count) or Mb/s (bits, steps of 1000, as an internet plan is sold). Default: MB/s |

In edit mode, the Material card also picks the Shape or Instrument look, and the shape that holds the link's icon.
Under iRiS the card wears the family's widget designs like every other widget (iRiS, Prism or Material, picked on the
Look page of its sheet).

## Notes

It reads the kernel's own counters (`/proc/net/route` for the link, `/proc/net/dev` for the bytes), once a second and
only while the card is on a desktop someone can see: behind a fullscreen game or on a sleeping screen it stops, and
starts a new minute when it comes back. It runs no command, sends nothing anywhere and needs nothing installed. The
network's name (your Wi-Fi's SSID) never shows, so nothing private sits on the desktop.
