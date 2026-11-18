pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common

// NiHiL's tokens, its only owner of colour, type and measure (DESIGN.md). Every surface is a flat neutral piece, a
// pill, a circle or a squircle on the wallpaper, with one signal colour for what is on: the scheme's own roles with
// their hue taken out (cards) or held vivid (the signal), never a colour picked by hand.
Singleton {
    id: root

    readonly property var options: Config.options?.nihil ?? null
    readonly property var m3: Appearance.m3colors
    readonly property bool dark: root.m3?.darkmode ?? true

    readonly property var theme: root.options?.theme ?? null
    function clamp(value: real, low: real, high: real): real { return Math.max(low, Math.min(high, value)) }

    // The signal, the person's choice (Settings > Look): "signal" the scheme's error hue kept vivid (the red of a glyph
    // light), "dynamic" the wallpaper's primary, "tertiary" its second colour, "custom" a hue they picked, "ink" no
    // colour at all (what is on inverts). `vividness` holds any of them back.
    readonly property string accentMode: String(root.theme?.accent ?? "signal")
    readonly property bool dynamic: root.accentMode === "dynamic"
    readonly property real vividness: root.clamp(Number(root.theme?.vividness ?? 1), 0.4, 1)
    readonly property real hue: root.clamp(Number(root.theme?.hue ?? 0), 0, 360)
    function vivid(source: color, saturation: real, lightness: real): color {
        const hue = source.hslHue < 0 ? 0 : source.hslHue
        return Qt.hsla(hue, Math.max(source.hslSaturation, saturation) * root.vividness, lightness, 1)
    }
    function hueColor(degrees: real): color {
        return Qt.hsla(root.clamp(degrees, 0, 360) / 360, 0.84 * root.vividness, root.dark ? 0.6 : 0.46, 1)
    }
    // A role with its hue taken out: the piece reads as NiHiL's grey on any wallpaper.
    function neutral(source, lightness, alpha) {
        const hue = (source?.hslHue ?? 0) < 0 ? 0 : (source?.hslHue ?? 0)
        return Qt.hsla(hue, 0, lightness, alpha === undefined ? 1 : alpha)
    }
    readonly property color signalColor: root.vivid(root.m3.m3error, 0.84, 0.5)
    readonly property color wallpaperColor: root.vivid(root.m3.m3primary, 0.62, root.dark ? 0.64 : 0.5)
    readonly property color secondColor: root.vivid(root.m3.m3tertiary, 0.62, root.dark ? 0.64 : 0.5)
    readonly property color accent: root.accentMode === "ink" ? root.ink
        : root.accentMode === "custom" ? root.hueColor(root.hue)
        : root.accentMode === "dynamic" ? root.wallpaperColor
        : root.accentMode === "tertiary" ? root.secondColor
        : root.signalColor
    // How far the signal reaches: "quiet" lights only what is on, "balanced" also levels and meters, "vivid" titles too.
    readonly property string reach: String(root.theme?.reach ?? "balanced")
    readonly property color litLevel: root.reach === "quiet" ? root.ink : root.accent
    readonly property color onLitLevel: root.reach === "quiet" ? root.paper : root.onAccent
    readonly property color heading: root.reach === "vivid" ? root.accent : root.ink
    // Ink on the signal: dark on a light signal (a pale yellow), white otherwise.
    readonly property color onAccent: (0.299 * root.accent.r + 0.587 * root.accent.g + 0.114 * root.accent.b) > 0.66
        ? root.neutral(root.m3.m3onSurface, 0.08) : root.neutral(root.m3.m3surface, 0.99)

    // Pieces: near-black in the dark scheme, paper white in the light one; a raised piece inside one (a menu's row,
    // a chip) one step up. Lightness comes from the scheme's surfaces so a deeper or paler scheme carries through.
    // `tint` lets the wallpaper's hue into the greys, `pieceAlpha` lets the wallpaper through the outer pieces.
    readonly property real _base: root.m3.m3surfaceContainerLow.hslLightness
    readonly property real tint: root.clamp(Number(root.theme?.tint ?? 0), 0, 0.35)
    readonly property real pieceAlpha: root.clamp(Number(root.theme?.opacity ?? 1), 0.55, 1)
    readonly property real _tintHue: root.m3.m3primary.hslHue < 0 ? 0 : root.m3.m3primary.hslHue
    function tone(lightness: real, alpha: real): color { return Qt.hsla(root._tintHue, root.tint, lightness, alpha) }
    readonly property color piece: root.tone(root.dark ? 0.085 : 0.93, root.pieceAlpha)
    readonly property color pieceRaised: root.tone(root.dark ? 0.16 : 0.85, 1)
    readonly property color pieceHover: root.tone(root.dark ? 0.22 : 0.79, 1)
    // The paper tile: the one piece of a block printed the other way round, the block's lead.
    readonly property color plate: root.ink
    readonly property color onPlate: root.tone(root.dark ? 0.07 : 0.97, 1)
    readonly property color well: root.tone(root.dark ? 0.06 : 0.99, 1)
    // The colour of the ground itself, the ink a lit piece prints in when the signal is the ink.
    readonly property color paper: root.tone(root.dark ? 0.08 : 0.98, 1)
    readonly property color ink: root.dark ? root.neutral(root.m3.m3onSurface, 0.96) : root.neutral(root.m3.m3onSurface, 0.07)
    readonly property color inkSoft: root.dark ? root.neutral(root.m3.m3onSurface, 0.74) : root.neutral(root.m3.m3onSurface, 0.3)
    // An unlit dot (RAM, battery): there, not glowing.
    readonly property color dotOff: root.dark ? root.neutral(root.m3.m3onSurface, 0.32) : root.neutral(root.m3.m3onSurface, 0.8)
    // What a hovered piece is tinted with: a step toward the ink.
    readonly property color hoverVeil: root.neutral(root.m3.m3onSurface, root.dark ? 1 : 0, 0.08)
    readonly property color scrim: root.neutral(root.m3.m3scrim, 0, root.dark ? 0.42 : 0.22)
    readonly property color shadow: root.neutral(root.m3.m3shadow, 0, root.dark ? 0.5 : 0.18)

    // Measure: one unit scaled with the shell's type size and NiHiL's own scale row.
    readonly property real scale: (root.options?.theme?.scale ?? 1) * (Appearance.fontSizeScale ?? 1)
    function s(px: real): real { return Math.round(px * root.scale) }
    readonly property real button: root.s(46)
    // Tiles stand a seam apart, packed into blocks.
    readonly property real seam: root.s(4)
    readonly property real tileRadius: root.s(12 * root.corners)
    readonly property real gap: root.seam
    readonly property real edge: root.s(10)
    // Corners: `corners` softens or tightens every piece; `softKeys` turns round keys into squircles.
    readonly property real corners: root.clamp(Number(root.theme?.corners ?? 1), 0.35, 1.25)
    readonly property bool roundKeys: String(root.theme?.keys ?? "tile") === "round"
    function keyRadius(width: real, height: real, square: bool): real {
        const side = Math.min(width, height)
        return root.roundKeys && !square ? side / 2 : Math.min(side / 2, root.tileRadius)
    }
    readonly property real rowRadius: root.s(10 * root.corners)
    readonly property real rowHeight: root.s(48)
    // A section is one piece; its rows sit `sectionPad` in, their corners concentric with the piece's.
    readonly property real sectionPad: root.s(4)
    readonly property real sectionRowRadius: Math.max(root.s(4), root.cardRadius - root.sectionPad)
    readonly property bool squareDots: String(root.theme?.dotShape ?? "round") === "square"
    readonly property real cardRadius: root.s(16 * root.corners)
    readonly property real pad: root.s(16)
    // The bar floats: its pieces stand off the screen's edge by `barMargin`; the room it keeps is both.
    readonly property real barMargin: root.s(8)
    readonly property real barZone: root.button + root.barMargin * 2
    // A panel is one piece holding a grid of `cell` keys `cellGap` apart (the control and power panels are four cells
    // wide), `panelPad` in from its rounded edge.
    readonly property real cell: root.s(68)
    readonly property real cellGap: root.seam
    readonly property real panelPad: root.s(10)
    readonly property real panelRadius: root.s(16 * root.corners)
    function cells(n: int): real { return n * root.cell + (n - 1) * root.cellGap }

    // Type: Hanken Grotesk to read, figures in its tabular numbers so a clock or a percent never shifts; Doto, a
    // dot-matrix face with round dots, for a heading or a name drawn in dots where DotText's grid has no letter for it.
    // Both ship with NiHiL (assets/fonts, OFL). "system" reads in the shell's own main font instead.
    function face(file: string): url { return Qt.resolvedUrl(`../assets/fonts/${file}.ttf`) }
    readonly property FontLoader sansLoader: FontLoader { source: root.face("HankenGrotesk") }
    readonly property FontLoader dotsLoader: FontLoader { source: root.face("DotoRound") }
    function loaded(loader: FontLoader, fallback: string): string {
        return loader.status === FontLoader.Ready && loader.name.length > 0 ? loader.name : fallback
    }
    readonly property string systemFont: String(Config.options?.appearance?.typography?.mainFont ?? "")
    readonly property string grotesk: String(root.theme?.font ?? "grotesk") === "system" && root.systemFont.length > 0
        ? root.systemFont : root.loaded(root.sansLoader, "sans-serif")
    readonly property string dots: root.loaded(root.dotsLoader, root.grotesk)
    readonly property real textMicro: root.s(11)
    readonly property real textSmall: root.s(12)
    readonly property real textBody: root.s(14)
    readonly property real textLarge: root.s(17)
    readonly property real textTitle: root.s(24)
    readonly property real textDisplay: root.s(34)

    // Motion: short and settled, no bounce. "calm" shortens it, "off" and game mode take it away.
    readonly property string motionChoice: String(root.theme?.motion ?? "full")
    readonly property bool motion: root.motionChoice !== "off" && !(Appearance._gameModeActive ?? false)
        && !(Config.options?.performance?.reduceAnimations ?? false)
    readonly property real _pace: root.motionChoice === "calm" ? 0.6 : 1
    readonly property int quick: root.motion ? Math.round(140 * root._pace) : 0
    readonly property int calm: root.motion ? Math.round(240 * root._pace) : 0
}
