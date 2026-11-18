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

    // The signal: the scheme's error hue kept vivid (the red of a glyph light), or, with Dynamic on, the
    // wallpaper's primary hue at the same strength.
    readonly property bool dynamic: (root.options?.theme?.accent ?? "signal") === "dynamic"
    function vivid(source: color, saturation: real, lightness: real): color {
        const hue = source.hslHue < 0 ? 0 : source.hslHue
        return Qt.hsla(hue, Math.max(source.hslSaturation, saturation), lightness, 1)
    }
    // A role with its hue taken out: the piece reads as NiHiL's grey on any wallpaper.
    function neutral(source, lightness, alpha) {
        const hue = (source?.hslHue ?? 0) < 0 ? 0 : (source?.hslHue ?? 0)
        return Qt.hsla(hue, 0, lightness, alpha === undefined ? 1 : alpha)
    }
    readonly property color accent: root.dynamic
        ? root.vivid(root.m3.m3primary, 0.62, root.dark ? 0.64 : 0.5)
        : root.vivid(root.m3.m3error, 0.84, 0.5)
    // Ink on the signal: dark on a light signal (a pale yellow), white otherwise.
    readonly property color onAccent: (0.299 * root.accent.r + 0.587 * root.accent.g + 0.114 * root.accent.b) > 0.66
        ? root.neutral(root.m3.m3onSurface, 0.08) : root.neutral(root.m3.m3surface, 0.99)

    // Pieces: near-black in the dark scheme, paper white in the light one; a raised piece inside one (a menu's row,
    // a chip) one step up. Lightness comes from the scheme's surfaces so a deeper or paler scheme carries through.
    readonly property real _base: root.m3.m3surfaceContainerLow.hslLightness
    readonly property color piece: root.dark ? root.neutral(root.m3.m3surface, Math.min(0.13, Math.max(0.09, root._base)))
        : root.neutral(root.m3.m3surface, 0.94)
    readonly property color pieceRaised: root.dark ? root.neutral(root.m3.m3surface, 0.2) : root.neutral(root.m3.m3surface, 0.86)
    readonly property color pieceHover: root.dark ? root.neutral(root.m3.m3surface, 0.25) : root.neutral(root.m3.m3surface, 0.8)
    readonly property color well: root.dark ? root.neutral(root.m3.m3surface, 0.06) : root.neutral(root.m3.m3surface, 0.99)
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
    readonly property real button: root.s(54)
    readonly property real gap: root.s(9)
    readonly property real edge: root.s(16)
    readonly property real cardRadius: root.s(26)
    readonly property real pad: root.s(16)
    // The bar floats: its pieces stand off the screen's edge by `barMargin`; the room it keeps is both.
    readonly property real barMargin: root.s(14)
    readonly property real barZone: root.button + root.barMargin * 2
    // A panel is one piece holding a grid of `cell` keys `cellGap` apart (the control and power panels are four cells
    // wide), `panelPad` in from its rounded edge.
    readonly property real cell: root.s(52)
    readonly property real cellGap: root.s(8)
    readonly property real panelPad: root.s(11)
    readonly property real panelRadius: root.s(24)
    function cells(n: int): real { return n * root.cell + (n - 1) * root.cellGap }

    // Type: Space Grotesk to read, Space Mono for figures and labels, Bodoni for the one serif word (the search
    // field, a day's name, a quote's author). They ship with NiHiL (assets/fonts, OFL).
    function face(file: string): url { return Qt.resolvedUrl(`../assets/fonts/${file}.ttf`) }
    readonly property FontLoader groteskLoader: FontLoader { source: root.face("SpaceGrotesk") }
    readonly property FontLoader monoLoader: FontLoader { source: root.face("SpaceMono-Regular") }
    readonly property FontLoader monoBoldLoader: FontLoader { source: root.face("SpaceMono-Bold") }
    readonly property FontLoader serifLoader: FontLoader { source: root.face("BodoniModa") }
    function loaded(loader: FontLoader, fallback: string): string {
        return loader.status === FontLoader.Ready && loader.name.length > 0 ? loader.name : fallback
    }
    readonly property string grotesk: root.loaded(root.groteskLoader, "Inter")
    readonly property string mono: root.loaded(root.monoLoader, "monospace")
    readonly property string serif: root.loaded(root.serifLoader, "serif")
    readonly property real textSmall: root.s(11)
    readonly property real textBody: root.s(13)
    readonly property real textLarge: root.s(16)
    readonly property real textTitle: root.s(22)

    // Motion: short and settled, no bounce.
    readonly property bool motion: !(Appearance._gameModeActive ?? false)
    readonly property int quick: root.motion ? 140 : 0
    readonly property int calm: root.motion ? 240 : 0
}
