# Storage

Every drive this computer has mounted, what is left on each and a bar of what it holds. A drive past nine tenths
turns to the warning colour, and the card leads with it, so the one about to fill is seen before it does.

Each drive is named by its label; the system drive and a separate home drive without a label are named System and
Home. A drive mounted many times (a btrfs subvolume at `/`, `/home`, `/var/log`) shows once.

| Family | Where it shows | How to add it |
| --- | --- | --- |
| Material | A card on the desktop | Edit the desktop, add a widget, Storage |
| iRiS | The desktop card in the iRiS, Prism or Material design | Edit the desktop, add a widget, Storage |

## Sizes

- **Small:** what is left on the drive it leads with, and its bar with what the drive holds in all.
- **Medium:** up to three drives, each with what is left and its bar; the head counts them.
- **Large:** what is left on all of them, over up to six drives.

The card leads with the system drive, or with a drive past nine tenths when there is one. In Prism the lead drive's
bar wears the spectrum.

## States

- **Reading the drives…** until the first reading answers.
- **No drive to show** when nothing but system mounts is there.
- **Couldn't read the drives** when `df` gave no answer.

## Settings

In edit mode, the Material card picks the Shape or Instrument look and the shape that holds the drive icon. Under
iRiS the card wears the family's widget designs like every other widget (iRiS, Prism or Material, picked on the Look
page of its sheet).

## Notes

It runs `df` and `lsblk` once a minute, only while the card is on a desktop someone can see: behind a fullscreen
game or on a sleeping screen it stops. It skips what is not a drive (memory filesystems, `/boot`, `/efi`, snaps and
loop devices) and anything under 1 GB. Sizes are counted in powers of 1000, as the drive's own box says. It sends
nothing anywhere and needs nothing installed.
