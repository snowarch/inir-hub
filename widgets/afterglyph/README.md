# Afterglyph

What is playing, your wallpaper, a picture, a word or a built-in subject, redrawn as glowing glyphs: each character is
chosen by how bright its spot is and which way its edges run. It takes its colours from your theme or from the
picture, grows in when the subject changes and is still at rest.

| Family | Where it shows |
| --- | --- |
| Material | A plate on the desktop, with the subject's name under it |
| iRiS | The same plate on the desktop |
| Waffle | A card in the Widgets panel |

## Settings

| Setting | What it changes |
| --- | --- |
| Shows | What is playing (else the wallpaper), only what is playing, the wallpaper, a picture or GIF, a word, or a built-in subject: Iris, Planet, Jellyfish, Helix, Knot, Heart, Crystal, Amphora, Mushroom |
| Picture | Opens the file chooser: any picture or GIF |
| Word | The word drawn; `\|` starts a new line |
| Style | One of sixteen: Signal, Theme, Terminal, Matrix, Amber CRT, Blueprint, Halftone, Blocks, Vapor, Glitch, Prism, Thermal, Gold, Kaleido, Newsprint, Typewriter. Picking one sets its characters, colours and screen |
| Size | Small, medium or large, or drag a corner in edit mode to any width and height |
| Backdrop, Readout | The dark plate behind the glyphs; the name and grid size under it |
| Characters | The character set (or your own), their size, edge lines, shimmer, rain, outline |
| Colour | Palette (your theme, the picture, thirteen fixed ones or your own three, picked from swatches), backdrop, saturation, contrast, hue, rainbow, drift |
| Screen | Glow, scanlines, grain, colour fringe, curve, glitch, paper, mirror |
| Subject | Cut the subject from its background, by brightness or by colour |
| Moves | A still picture sways, breathes rings of light and shimmers; how it appears, speed, camera |

The whole wallpaper can be drawn this way too: **Settings › Wallpaper › Draw the wallpaper as glyphs**.

## Credit

Afterglyph is a port of [Afterglyph](https://github.com/winchxyz/afterglyph) by winchxyz (MIT): its looks, character
sets, palettes, screen effects and built-in subjects, rewritten as shaders for the graphics card in the base's
`GlyphArt`. Its webcam, sound, 3D relief of pictures and export are not part of the widget.

## For makers

`afterglyph.js` picks what to draw; `AfterglyphView.qml` stages it and hands it to `GlyphArt`; the two faces only lay
it out. Nothing runs at rest unless Motion is on, and then only while the widget is on screen.
