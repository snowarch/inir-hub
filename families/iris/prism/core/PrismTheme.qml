pragma Singleton
import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.iris.style

// Prism's own tokens: the dark music app of his 11-06 reference (columns a step apart, grey captions, hairlines, white
// controls) and its light counterpart, cut from the shell's own surfaces and text (his 11-20: "tiene que respetar la
// shell"): a material, a Design or the wallpaper's tint reaches Settings too. Fonts, density and the person's accent
// come from IrisStyle; nothing here is read by any other surface.
Singleton {
    id: root

    readonly property bool light: IrisStyle.light
    // A share of the way from one colour to another.
    function step(from: color, to: color, share: real): color { return ColorUtils.mix(to, from, share) }
    readonly property color shellSurface: IrisStyle.surfaceOpaque
    readonly property color shellHigh: IrisStyle.surfaceHighOpaque
    readonly property color shellHighest: IrisStyle.surfaceHighestOpaque
    readonly property real density: IrisStyle.settingsDensity
    // Prism's own measure (his 11-19: "todo es demasiado grande"): every distance inside the panel a step under iRiS's
    // density, so a page holds more at a calmer size. The window itself keeps its room (`room`).
    readonly property real fine: 0.88
    function dp(value: real): real { return Math.round(value * root.density * root.fine) }
    function room(value: real): real { return Math.round(value * root.density) }
    // Prism's resting size on a screen this many points across and down: the room it was drawn for, growing with a
    // larger screen up to a comfortable reach (on a 27″ screen at 100 % it sat as a small island in the middle).
    function restWidth(across: real): real { return Math.round(Math.max(root.room(1280), Math.min(across * 0.72, root.room(1560)))) }
    function restHeight(down: real): real { return Math.round(Math.max(root.room(840), Math.min(down * 0.82, root.room(1040)))) }

    // The panel's material follows the shell's glass (Settings › Glass; his 11-16, and 11-20: "tiene que respetar la
    // shell"), over the desktop and as a window alike: Blur lays a veil of the canvas over what the compositor blurs
    // behind the panel, Glass blurs the wallpaper inside it, Off is the solid canvas. Settings window › Material alone
    // overrides it: Solid keeps Prism solid over a glass desktop, Glass gives it glass over a solid one.
    readonly property bool windowHost: String(Config.options?.iris?.appearance?.settingsHost ?? "overlay") === "window"
    readonly property string ownMaterial: IrisStyle.surfaceMaterial("settings")
    readonly property bool wantsGlass: root.ownMaterial === "glass" || (root.ownMaterial === "" && IrisStyle.glassy)
    // A window cannot know where it sits on screen, so it cannot cut the wallpaper's glass: it takes the compositor's
    // blur instead, where the compositor gives it one (Niri: any surface that publishes its region; Umbriel: only under
    // Blur, whose rule names the window), else it stays solid.
    readonly property bool windowCanBlur: IrisCompositorBlur.usable
        && (CompositorService.isUmbriel ? IrisStyle.glassCompositor : Appearance.compositorBlurActive)
    readonly property bool glassBlur: root.wantsGlass && (IrisStyle.glassCompositor || (root.windowHost && root.windowCanBlur))
    readonly property bool glassWallpaper: root.wantsGlass && !root.windowHost && !IrisStyle.glassCompositor && Appearance.effectsEnabled
    // Settings window › Corners: Auto is Prism's own round.
    readonly property real corner: IrisStyle.surfaceRadius("settings", root.dp(28))
    readonly property bool glass: root.glassBlur || root.glassWallpaper
    // How much canvas lies over the glass: the person's Tint, held to the floor where the ink still reads. Dark, the
    // desktop behind is a black haze (his 11-16: "negro difuminado"), never the wallpaper's colour through a thin veil.
    readonly property real veil: root.glass ? Math.max(root.light ? 0.5 : 0.74, IrisStyle.glassTint) : 1

    // The three columns, each a step apart as in the reference. Dark, the steps climb from the shell's surface toward
    // its raised one: the side rails a touch lighter than the middle. Light (Ink too), the ground sinks toward the
    // shell's deepest well and the sheets rise toward white, Ink's a smaller rise so the page stays easy on the eyes.
    // Over glass every layer is the same step of the solid scheme made smoke: dark, a black sheet that deepens what is
    // behind it (folders-glass, the dark folder), never white over the blur (his 11-16: "el blur es blanco"); light,
    // a white frost. No layer has an outline: its fill alone sets it off (his 11-16: "bordes slop").
    readonly property color canvas: root.light ? root.step(root.shellSurface, root.shellHighest, 0.35) : root.shellSurface
    readonly property color rail: root.light ? root.step(root.shellSurface, root.shellHighest, 0.75) : root.step(root.shellSurface, root.shellHigh, 0.55)
    readonly property color railGlass: root.glass ? (root.light ? Qt.rgba(1, 1, 1, 0.34) : Qt.rgba(0.086, 0.086, 0.094, 0.5)) // iris-literal: the side column, smoke over the page
        : ColorUtils.applyAlpha(root.rail, root.light ? 0.78 : 0.7)
    readonly property color raised: root.glass ? (root.light ? Qt.rgba(1, 1, 1, 0.62) : Qt.rgba(0.118, 0.118, 0.13, 0.62)) // iris-literal: a field, smoke over glass
        : root.light ? root.card : root.shellHigh
    readonly property color sunk: root.glass ? (root.light ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(0, 0, 0, 0.32)) // iris-literal: a track cut into frosted glass
        : root.light ? root.step(root.shellHighest, root.ink, 0.05) : root.step(root.shellSurface, "black", 0.55)
    // A control's track (a switch off, the segments' ground, a level's groove): a step under the card.
    readonly property color track: root.glass ? (root.light ? Qt.rgba(0, 0, 0, 0.09) : Qt.rgba(0, 0, 0, 0.42)) // iris-literal: a track under smoked glass
        : root.light ? root.step(root.shellHighest, root.ink, 0.04) : root.shellSurface
    readonly property color knobOff: root.light ? "white" : root.step(root.shellHighest, root.ink, 0.2)
    // A group's card (Raell Tech's page, his 11-14): a step above the middle column, under the fields' own fill.
    readonly property color card: root.glass ? (root.light ? Qt.rgba(1, 1, 1, 0.62) : Qt.rgba(0.15, 0.15, 0.165, 0.6)) // iris-literal: the page's sheet, smoke a step over the panel's glass
        : root.light ? root.step(root.shellSurface, "white", IrisStyle.ink ? 0.35 : 0.75) : root.step(root.shellSurface, root.shellHigh, 0.8)
    // A group's card and every picture on the page share one radius.
    readonly property real cardRadius: root.dp(22)
    // A folder on the shelf: under the page's sheet, over the ground (B · Carpeta: the drawer sits lower than the page).
    readonly property color folder: root.glass ? (root.light ? Qt.rgba(1, 1, 1, 0.42) : Qt.rgba(0.09, 0.09, 0.1, 0.62)) // iris-literal: a folder, smoke over the panel's glass
        : root.light ? root.step(root.canvas, root.card, 0.75) : root.step(root.shellSurface, root.shellHigh, 0.35)
    // The bar that rows pass under (the strip): denser glass, so what scrolls beneath it never reads through.
    readonly property color bar: root.glass ? ColorUtils.applyAlpha(root.canvas, Math.min(0.94, root.veil + 0.3)) : root.raised
    readonly property color line: root.light ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.065) // iris-literal: Prism's own fills and scrims, scheme-aware above
    readonly property color fill: root.light ? Qt.rgba(0, 0, 0, 0.045) : Qt.rgba(1, 1, 1, 0.055) // iris-literal: Prism's own fills and scrims, scheme-aware above
    readonly property color fillHover: root.light ? Qt.rgba(0, 0, 0, 0.075) : Qt.rgba(1, 1, 1, 0.09) // iris-literal: Prism's own fills and scrims, scheme-aware above
    readonly property color fillPress: root.light ? Qt.rgba(0, 0, 0, 0.11) : Qt.rgba(1, 1, 1, 0.13) // iris-literal: Prism's own fills and scrims, scheme-aware above

    readonly property color ink: IrisStyle.text
    // Each step still reads at 4.5:1 on the card and the rail (his 11-19: legibility): what a row does, then captions
    // and numbers. A share of the ink over the card, moved toward the ink only as far as that needs.
    function legible(share: real): color {
        for (let at = share; at < 1; at += 0.04) {
            const c = root.step(root.card, root.ink, at)
            if (ColorUtils.contrastRatio(c, root.card) >= 4.5 && ColorUtils.contrastRatio(c, root.rail) >= 4.5) return c
        }
        return root.ink
    }
    readonly property color ink2: root.legible(0.68)
    readonly property color ink3: root.legible(0.52)
    // A page's name in the sidebar, near the text (omusic-app).
    readonly property color inkNav: root.step(root.rail, root.ink, 0.86)

    // The reference's white controls: a white pill on dark, its ink black; in light the same idea inverted.
    readonly property color solid: root.ink
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
    // A sheet over a picture (the profile, the player): the picture blurred through black smoke that holds white words.
    readonly property color glassSheet: Qt.rgba(0.03, 0.03, 0.04, 0.6) // iris-literal: a smoked sheet over art, the same in every scheme
    // Keys and tags on that sheet: a deeper smoke, no outline.
    readonly property color frost: Qt.rgba(0, 0, 0, 0.3) // iris-literal: a key's body on the smoked sheet
    readonly property color frostHover: Qt.rgba(0, 0, 0, 0.42) // iris-literal: the key deepening under the pointer
    readonly property color frostPress: Qt.rgba(0, 0, 0, 0.52) // iris-literal: the key pressed
    readonly property color spotHover: Qt.rgba(0.03, 0.03, 0.04, 0.8) // iris-literal: the smoke deepening under the pointer
    readonly property color spotPress: Qt.rgba(0.03, 0.03, 0.04, 0.88) // iris-literal: the smoke pressed
    readonly property color spotInk2: Qt.rgba(1, 1, 1, 0.66) // iris-literal: a value beside the name on that smoke
    readonly property color spotScrim: Qt.rgba(0, 0, 0, 0.5) // iris-literal: the scene stepping back round the pointed part
    readonly property color spotShadow: Qt.rgba(0, 0, 0, 0.35) // iris-literal: a disc's lift off the art

    // The one colour that keeps its own meaning whatever the desktop's colours: red for what removes or failed.
    readonly property var tints: ({ red: "#ff453a", grey: "#8e8e93" }) // iris-literal: danger and its quiet fallback
    function tint(name: string): color { return root.tints[name] ?? root.tints.grey }

    // Each page's art in three colours, the desktop's own and nothing else (his 11-17: "los acentos deben de ser usados
    // del wallpaper o theming"): the accent, the highlight and the wallpaper's light, each keeping its own hue and as
    // much colour as it has, held to one lightness and capped quiet. A grey wallpaper gives grey art; no colour is
    // invented to make a contrast. A page's tint only orders the three, so neighbours lead with different ones.
    function chromaOf(c: color): real {
        const lin = x => x <= 0.04045 ? x / 12.92 : Math.pow((x + 0.055) / 1.055, 2.4)
        const r = lin(c.r), g = lin(c.g), b = lin(c.b)
        const l_ = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
        const m_ = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
        const s_ = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
        const a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
        const bb = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
        return Math.sqrt(a * a + bb * bb)
    }
    readonly property var artSources: [IrisStyle.baseAccent, IrisStyle.secondaryAccent, IrisStyle.wallpaperLight].map(c => Qt.color(c))
    readonly property var artOrders: ({ blue: [0, 1, 2], violet: [0, 2, 1], pink: [1, 0, 2], green: [2, 0, 1], amber: [1, 2, 0],
        red: [2, 1, 0], teal: [2, 0, 1], indigo: [0, 2, 1], orange: [1, 0, 2], grey: [0, 1, 2], holo: [0, 1, 2] })
    function palette(name: string): var { return root.paletteAt(name, 0) }
    function paletteAt(name: string, turn: int): var {
        const base = root.artOrders[name] ?? root.artOrders.grey
        const k = ((turn % 3) + 3) % 3
        const order = base.slice(k).concat(base.slice(0, k))
        return order.map((index, place) => {
            const c = root.artSources[index]
            // The three keep their own hue and colour (his 11-18: the head read grey): one deep, one bright, one light.
            const lightness = root.light ? [0.64, 0.7, 0.8][place] : [0.56, 0.68, 0.76][place]
            return IrisStyle.oklch(lightness, Math.min(root.chromaOf(c) * 1.15, 0.17), IrisStyle.oklchHue(c))
        })
    }
    // The graphs' one mark (Technical Minimalism, his 11-17): the person's accent, the line that names what a page is about.
    readonly property color mark: IrisStyle.accent
    // The art's paper in light: the posters' warm off-white, a step from the white cards it shows behind.
    readonly property color paperLight: "#eeeae1" // iris-literal: the art's paper in light, Prism's own

    // Things you touch are objects (`.claude/ref/language`: the keycaps, the tactile faders, the Figma toggle's well).
    // A key is a cap on its own side: the side shows under it as a lip, a hairline of light runs on its top. A well is
    // cut into the card: dark, its lower lip catching light; light, its upper lip in shade. Solid layers, never a
    // gradient (his 11-07).
    readonly property real keyLip: 0 // his 11-15: keys stand flat, no stepped side
    readonly property color keyQuiet: root.glass ? (root.light ? Qt.rgba(1, 1, 1, 0.7) : Qt.rgba(0.141, 0.141, 0.157, 0.72)) // iris-literal: a key's cap, smoke over glass
        : root.light ? root.canvas : root.step(root.shellHigh, root.shellHighest, 0.6)
    // A frosted face reads as what it lies on: the scheme's page under its share of white.
    function lum(c: color): real { return (0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b) * c.a + (root.light ? 0.95 : 0.05) * (1 - c.a) }
    function keyHover(face: color): color {
        // A smoked face lifts toward the ink a step; a frosted one thickens.
        if (face.a < 1) return root.light ? ColorUtils.applyAlpha(face, Math.min(1, face.a + 0.14))
            : Qt.rgba(face.r + 0.06, face.g + 0.06, face.b + 0.065, Math.min(1, face.a + 0.06))
        return root.lum(face) > 0.6 ? Qt.darker(face, 1.06) : Qt.lighter(face, 1.22)
    }

    readonly property string fontMain: IrisStyle.fontMain
    readonly property string fontMono: IrisStyle.fontMono
    readonly property string fontNumbers: IrisStyle.fontNumbers.length > 0 ? IrisStyle.fontNumbers : IrisStyle.fontMain

    // The type ladder, in px at density 1: caption, small, body, row, head, title, display. Each step reads apart from
    // the next in size or weight: a page's name (display) over its groups' names (head) over a row's name (row, Medium)
    // over what the row does (small, ink2). Long languages wrap a row or shrink a page's name to its width; nothing is cut.
    // A desktop settings app's sizes (his 11-19: everything was too big): a row's name at 13.5, what it does at 11.5.
    readonly property real caption: 10.5 * IrisStyle.typeScale
    readonly property real small: 11.5 * IrisStyle.typeScale
    readonly property real body: 12.5 * IrisStyle.typeScale
    readonly property real row: 13.5 * IrisStyle.typeScale
    readonly property real head: 16 * IrisStyle.typeScale
    readonly property real title: 24 * IrisStyle.typeScale
    readonly property real display: 32 * IrisStyle.typeScale
    // A page's name on its poster (the posters' titles: one big word over the art's calm floor).
    readonly property real poster: 44 * IrisStyle.typeScale

    readonly property bool motion: IrisStyle.motionEnabled
    // Settings window › Motion speed: how fast the panel opens and closes.
    readonly property real openSpeed: IrisStyle.surfaceSpeed("settings")
    function ms(value: int): int { return root.motion ? value : 0 }
}
