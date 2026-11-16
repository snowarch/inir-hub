pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common.functions
import qs.modules.iris.style

// Prism's own tokens: the dark music app of his 11-06 reference (near-black columns, grey captions, hairlines, white
// controls) and its light counterpart. Fonts, density and the person's accent come from IrisStyle; nothing here is read
// by any other surface.
Singleton {
    id: root

    readonly property bool light: IrisStyle.light
    readonly property real density: IrisStyle.settingsDensity
    function dp(value: real): real { return Math.round(value * root.density) }

    // The three columns, each a step apart as in the reference: the side rails a touch lighter than the middle.
    readonly property color canvas: root.light ? "#f5f5f7" : "#0f0f11" // iris-literal: Prism's middle column, its own neutral
    readonly property color rail: root.light ? "#ebebee" : "#161618" // iris-literal: Prism's side columns
    readonly property color railGlass: root.light ? "#c7ebebee" : "#b3161618" // iris-literal: the side column as glass, the panel's air showing through
    readonly property color raised: root.light ? "#ffffff" : "#1e1e21" // iris-literal: circles and fields standing on a rail
    readonly property color sunk: root.light ? "#e2e2e6" : "#050506" // iris-literal: a switch's track, darker than the page
    // A group's card (Raell Tech's page, his 11-14): a step above the middle column, under the fields' own fill.
    readonly property color card: root.light ? "#ffffff" : "#18181b" // iris-literal: Prism's group card, between canvas and raised
    readonly property color line: root.light ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.065) // iris-literal: Prism's own fills and scrims, scheme-aware above
    readonly property color fill: root.light ? Qt.rgba(0, 0, 0, 0.045) : Qt.rgba(1, 1, 1, 0.055) // iris-literal: Prism's own fills and scrims, scheme-aware above
    readonly property color fillHover: root.light ? Qt.rgba(0, 0, 0, 0.075) : Qt.rgba(1, 1, 1, 0.09) // iris-literal: Prism's own fills and scrims, scheme-aware above
    readonly property color fillPress: root.light ? Qt.rgba(0, 0, 0, 0.11) : Qt.rgba(1, 1, 1, 0.13) // iris-literal: Prism's own fills and scrims, scheme-aware above

    readonly property color ink: root.light ? "#1d1d1f" : "#ffffff" // iris-literal: Prism's text, Apple's label colours
    readonly property color ink2: root.light ? "#6e6e73" : "#a6a6ad" // iris-literal: secondary label
    readonly property color ink3: root.light ? "#8e8e93" : "#6e6e75" // iris-literal: tertiary label, numbers, headers
    readonly property color inkNav: root.light ? "#3a3a3c" : "#d6d6db" // iris-literal: a page's name in the sidebar, near the text (omusic-app)

    // The reference's white controls: a white pill on dark, its ink black; in light the same idea inverted.
    readonly property color solid: root.light ? "#1d1d1f" : "#ffffff" // iris-literal: the primary pill and chosen segment
    readonly property color inkSolid: root.light ? "#ffffff" : "#000000" // iris-literal: ink on that pill

    readonly property color accent: IrisStyle.accent
    readonly property color inkAccent: IrisStyle.inkOnAccent
    // The accent as text on the side column ("where you are", his 11-10): the person's hue, walked toward the ink
    // until it reads at 4.5:1 on the rail, so a deep or a pale accent still names the open page.
    readonly property color accentInk: {
        const hue = Qt.color(root.accent)
        for (let step = 0; step <= 10; step++) {
            const ink = ColorUtils.mix(root.ink, hue, step / 10)
            if (ColorUtils.contrastRatio(ink, root.rail) >= 4.5) return ink
        }
        return root.ink
    }
    // The open page's plate: its hue, quiet, as solid as the row hover (his 11-07: plates, never gradients).
    readonly property color accentPlate: ColorUtils.applyAlpha(root.accent, root.light ? 0.13 : 0.16) // iris-literal: the open page's plate, Prism's own quiet wash

    // Art stays dark in every scheme, like a record sleeve: the hero, the player, the glass card.
    readonly property color night: "#08080a" // iris-literal: the refraction's black, the same in every scheme
    readonly property color paper: "#ffffff" // iris-literal: light on the art, the same in every scheme
    // The numbers on a scene's parts and their name chip: smoke over the art, the same in every scheme (Options+).
    readonly property color spot: Qt.rgba(0.03, 0.03, 0.04, 0.72) // iris-literal: a disc over the scene, readable on light and dark art
    // Frosted glass over a picture (the profile card's sheet): the picture's light comes through, darkened to hold white words.
    readonly property color glassSheet: Qt.rgba(0.05, 0.05, 0.07, 0.42) // iris-literal: a frosted sheet over art, the same in every scheme
    readonly property color spotHover: Qt.rgba(0.03, 0.03, 0.04, 0.8) // iris-literal: the smoke deepening under the pointer
    readonly property color spotPress: Qt.rgba(0.03, 0.03, 0.04, 0.88) // iris-literal: the smoke pressed
    readonly property color spotEdge: Qt.rgba(1, 1, 1, 0.24) // iris-literal: the smoke disc's rim, so it holds on a dark window
    readonly property color spotInk2: Qt.rgba(1, 1, 1, 0.66) // iris-literal: a value beside the name on that smoke
    readonly property color spotScrim: Qt.rgba(0, 0, 0, 0.5) // iris-literal: the scene stepping back round the pointed part
    readonly property color spotShadow: Qt.rgba(0, 0, 0, 0.35) // iris-literal: a disc's lift off the art

    // The one colour that keeps its own meaning whatever the desktop's colours: red for what removes or failed.
    readonly property var tints: ({ red: "#ff453a", grey: "#8e8e93" }) // iris-literal: danger and its quiet fallback
    function tint(name: string): color { return root.tints[name] ?? root.tints.grey }

    // Each page's art in three colours (`.claude/ref/language`, the Design Archive posters: a ribbon's start, its end
    // and its core), all from one place (his 11-15: the wallpaper's colours, or a contrast to the person's accent): the
    // accent, the highlight and the wallpaper's own light, set at one glowing lightness in OKLCH. A colour too near
    // another gives way to the accent's opposite, so a ribbon always travels across a contrast; with no hue to read
    // (a grey wallpaper and accent) the art keeps the posters' blue and amber. A page's tint only orders the three
    // (start, end, core), so pages differ and every one of them wears the desktop's colours.
    readonly property var artHues: {
        const hueOf = c => Qt.color(c).hslSaturation < 0.12 ? -1 : IrisStyle.oklchHue(Qt.color(c))
        const apart = (x, y) => { const d = Math.abs(x - y) % 360; return Math.min(d, 360 - d) }
        // iris-literal: the posters' blue, used only when the desktop gives no hue
        const a = hueOf(IrisStyle.baseAccent) < 0 ? 264 : hueOf(IrisStyle.baseAccent)
        let b = hueOf(IrisStyle.secondaryAccent)
        if (b < 0 || apart(a, b) < 45) b = (a + 165) % 360
        let c = hueOf(IrisStyle.wallpaperLight)
        if (c < 0 || apart(c, a) < 35 || apart(c, b) < 35) c = (a + 300) % 360
        return [a, b, c]
    }
    readonly property var artOrders: ({ blue: [0, 1, 2], violet: [0, 2, 1], pink: [1, 0, 2], green: [2, 0, 1], amber: [1, 2, 0],
        red: [2, 1, 0], teal: [2, 0, 1], indigo: [0, 2, 1], orange: [1, 0, 2], grey: [0, 1, 2], holo: [0, 1, 2] })
    function palette(name: string): var {
        const order = root.artOrders[name] ?? root.artOrders.grey
        // Light over the night glows bright; pigment on paper sits a step deeper so it still reads as ink.
        return order.map((index, place) => IrisStyle.oklch(root.light ? 0.6 : 0.66 + (place === 2 ? 0.1 : 0), place === 2 ? 0.14 : 0.2, root.artHues[index]))
    }
    // The art's paper in light: the posters' warm off-white, a step from the white cards it shows behind.
    readonly property color paperLight: "#eeeae1" // iris-literal: the art's paper in light, Prism's own

    // Things you touch are objects (`.claude/ref/language`: the keycaps, the tactile faders, the Figma toggle's well).
    // A key is a cap on its own side: the side shows under it as a lip, a hairline of light runs on its top. A well is
    // cut into the card: dark, its lower lip catching light; light, its upper lip in shade. Solid layers, never a
    // gradient (his 11-07).
    readonly property real keyLip: 0 // his 11-15: keys stand flat, no stepped side
    readonly property color keyQuiet: root.light ? "#f1f1f4" : "#242428" // iris-literal: a quiet key's cap, a step off the card
    readonly property color wellEdge: root.light ? "#cbcbd1" : "#2b2b30" // iris-literal: the well's lit (dark) or shaded (light) lip
    function lum(c: color): real { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function keySide(face: color): color { return root.lum(face) > 0.6 ? Qt.darker(face, 1.34) : Qt.darker(face, 2.6) }
    function keyRim(face: color): color { return root.lum(face) > 0.6 ? face : Qt.lighter(face, 1.4) }
    function keyHover(face: color): color { return root.lum(face) > 0.6 ? Qt.darker(face, 1.06) : Qt.lighter(face, 1.22) }

    readonly property string fontMain: IrisStyle.fontMain
    readonly property string fontMono: IrisStyle.fontMono
    readonly property string fontNumbers: IrisStyle.fontNumbers.length > 0 ? IrisStyle.fontNumbers : IrisStyle.fontMain

    // The type ladder, in px at density 1: caption, small, body, row, head, title, display.
    readonly property real caption: 11 * IrisStyle.typeScale
    readonly property real small: 12 * IrisStyle.typeScale
    readonly property real body: 13 * IrisStyle.typeScale
    readonly property real row: 14 * IrisStyle.typeScale
    readonly property real head: 18 * IrisStyle.typeScale
    readonly property real title: 28 * IrisStyle.typeScale
    readonly property real display: 30 * IrisStyle.typeScale
    // A page's name on its poster (the posters' titles: one big word over the art's calm floor).
    readonly property real poster: 52 * IrisStyle.typeScale

    readonly property bool motion: IrisStyle.motionEnabled
    function ms(value: int): int { return root.motion ? value : 0 }
}
