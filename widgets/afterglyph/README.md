# Afterglyph

What is playing, your wallpaper, a picture or a word, redrawn as glowing glyphs: characters chosen by how bright each
spot is and which way its edges run. It grows in when the picture changes and is still at rest.

| Family | Where it shows |
| --- | --- |
| Material | A plate on the desktop, with the song under it |
| iRiS | The same plate on the desktop |
| Waffle | A card in the Widgets panel |

## Settings

| Setting | What it changes |
| --- | --- |
| What it draws | What is playing (else the wallpaper), only what is playing, the wallpaper, a picture or GIF, or a word |
| Picture or GIF | The full path of the file to draw |
| Word | The word drawn when it draws a word |
| Look | Picture colours, your accent, Phosphor, Amber, Blueprint or Paper |
| Glyph size | How large each character is |
| Glow | How far the light spreads around the characters |
| Grow in | Whether the glyphs grow in when the picture changes |
| Plate | The dark plate behind the glyphs |
| Caption | The song and the grid size under the plate |

The whole wallpaper can be drawn this way too: **Settings › Wallpaper › Draw the wallpaper as glyphs**.

## Credit

The glyph look follows [Afterglyph](https://github.com/winchxyz/afterglyph) by winchxyz (MIT). This widget is a new
drawing of it on the graphics card, through the base's `GlyphArt`; no code of the web app is included.

## For makers

`afterglyph.js` picks what to draw; `AfterglyphView.qml` stages it and hands it to `GlyphArt`; the two faces only lay
it out. Nothing runs at rest: a GIF moves only while the widget is on screen.
