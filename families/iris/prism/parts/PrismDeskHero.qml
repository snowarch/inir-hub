pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.frame
import qs.modules.iris.style
import qs.modules.iris.settings
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// Layout, Windows and Glass open on the windows themselves, live, as Displays opens on the screen (his 11-20: "el mismo
// trato que le dimos a la página mouse y keyboard"). Layout draws the whole screen at its own points: the Island and the
// Dock where they stand, the room they and the free edges keep, and the windows the arrangement makes there, gaps
// included; beside it the room left for windows. Windows and Glass come closer, to two windows: the one in focus over
// a see-through terminal, so corners, border, focus ring, shadow, opacity and the blur behind read at a size they show.
// Everything is read from CompositorConfig, so it draws the same under Niri and Umbriel.
Rectangle {
    id: root

    // "layout", "windows" or "glass".
    property string page: "layout"
    readonly property bool whole: root.page === "layout"

    readonly property var screen: CompositorConfig.output
    readonly property string port: String(root.screen?.name ?? "")
    readonly property var room: CompositorConfig.logicalRect(root.screen)
    readonly property real aspect: CompositorConfig.aspectOf(root.screen) || 16 / 9
    readonly property url wallpaper: {
        const own = WallpaperListener.multiMonitorEnabled ? WallpaperListener.effectivePerMonitor?.[root.port]?.path : ""
        return own ? Wallpapers.stillUrlFor(own) : Wallpapers.effectiveWallpaperUrl
    }

    function v(comp: string, key: string, fallback: var, read: var): var {
        const spec = { comp: comp, key: key, fallback: fallback }
        if (read) spec.read = read
        return CompositorConfig.value(spec)
    }
    function number(comp: string, key: string, fallback: real): real {
        const found = Number(root.v(comp, key, fallback))
        return isFinite(found) ? found : fallback
    }
    // A colour the compositor keeps as text, or the theme's where it keeps none.
    function colourOf(value: var, fallback: var): var {
        const text = String(value ?? "")
        return /^#([0-9a-f]{3,4}|[0-9a-f]{6}|[0-9a-f]{8})$/i.test(text) ? text : fallback
    }

    // ---- the arrangement ----
    readonly property string mode: IrisOptions.layoutMode()
    readonly property real gaps: Math.max(0, root.number("layout", "gaps", 16))
    readonly property string centre: String(root.v("layout", "center-focused-column", "never", "center_focused"))
    readonly property bool tabbed: String(root.v("layout", "default-column-display", "normal")) === "tabbed"
    readonly property string mainSide: String(root.v("layout", "master.position", "left"))
    readonly property real mainShare: Math.max(0.2, Math.min(0.85, root.number("layout", "master.share", 0.55)))
    // The room iRiS keeps at each edge (IrisReservations: the frame, the Island, the bubbles, the Dock) and the free
    // space the compositor adds there.
    readonly property bool chassis: GlobalStates.barOpen && (Config.options?.enabledPanels ?? []).includes("irisBar")
    function kept(edge: string): real {
        return Math.max(0, IrisFrame.reserve(edge, root.chassis, root.port)) + Math.max(0, root.number("layout", "struts." + edge, 0))
    }
    readonly property var kept4: ({ top: root.kept("top"), bottom: root.kept("bottom"), left: root.kept("left"), right: root.kept("right") })
    // Where windows can stand, in points, gaps taken.
    readonly property var area: ({
        x: root.kept4.left + root.gaps,
        y: root.kept4.top + root.gaps,
        w: Math.max(0, root.room.width - root.kept4.left - root.kept4.right - 2 * root.gaps),
        h: Math.max(0, root.room.height - root.kept4.top - root.kept4.bottom - 2 * root.gaps)
    })
    readonly property var way: ({
        scrolling: [Translation.tr("Scrolling"), Translation.tr("Columns on an endless strip.")],
        dwindle: [Translation.tr("Dwindle"), Translation.tr("Each window halves the last.")],
        master: [Translation.tr("Main and stack"), Translation.tr("One large window, the rest beside it.")],
        stacking: [Translation.tr("Floating"), Translation.tr("Windows where you leave them.")]
    })[root.mode] ?? ["", ""]

    // ---- what every window wears ----
    readonly property real corner: Math.max(0, root.number("window-rules", "corner-radius", 0))
    readonly property bool border: root.v("layout", "border.enabled", false) === true
    readonly property real borderWidth: root.number("layout", "border.width", 4)
    readonly property color borderOn: root.colourOf(root.v("layout", "border.active-color", ""), PrismTheme.accent)
    readonly property color borderOff: root.colourOf(root.v("layout", "border.inactive-color", ""), Qt.alpha(PrismTheme.ink, 0.28))
    readonly property real outerLine: root.border ? Math.max(0, root.number("layout", "outer-border.width", 0)) : 0
    readonly property bool ring: root.v("layout", "focus-ring.enabled", false) === true
    readonly property real ringWidth: root.number("layout", "focus-ring.width", 4)
    readonly property color ringColour: root.colourOf(root.v("layout", "focus-ring.active-color", ""), PrismTheme.accent)
    readonly property bool shadow: root.v("layout", "shadow.enabled", false) === true
    readonly property real softness: root.number("layout", "shadow.softness", 30)
    readonly property real spread: root.number("layout", "shadow.spread", 5)
    readonly property real fallX: root.number("layout", "shadow.offset-x", 0)
    readonly property real fallY: root.number("layout", "shadow.offset-y", 5)
    readonly property real opacityOn: Math.max(0.2, Math.min(1, root.number("window-rules", "active-opacity", 1)))
    readonly property real opacityOff: Math.max(0.2, Math.min(1, root.number("window-rules", "inactive-opacity", 1)))
    // The blur behind see-through windows: Umbriel's glass, or Niri's blur rule with the shell's blur on.
    readonly property bool umbrielGlass: CompositorConfig.has("glass", "enabled")
    readonly property bool frosted: root.umbrielGlass ? root.v("glass", "enabled", true) === true
        : root.v("window-rules", "blur", false) === true && IrisCompositorBlur.usable
    readonly property real frost: root.umbrielGlass
        ? Math.max(0.15, Math.min(1, root.number("glass", "radius", 5) * Math.sqrt(root.number("glass", "passes", 2)) / 16))
        : (({ light: 0.35, balanced: 0.6, strong: 0.9 })[IrisCompositorBlur.strength] ?? 0.6)
    readonly property real frostColour: Math.max(-1, Math.min(1, (root.umbrielGlass ? root.number("glass", "saturation", 1.1) : IrisCompositorBlur.saturation) - 1))
    readonly property real frostLight: root.umbrielGlass ? Math.max(-1, Math.min(1, root.number("glass", "brightness", 0.9) - 1)) : 0
    readonly property real frostContrast: root.umbrielGlass ? Math.max(-1, Math.min(1, root.number("glass", "contrast", 0.9) - 1)) : 0

    // Drawing pixels per point. The whole screen fits its picture; up close the picture holds 1000 × 540 points.
    readonly property real k: root.whole ? (root.room.width > 0 ? picture.width / root.room.width : 0)
        : Math.min(picture.width / 1000, picture.height / 540)
    // The windows, in points: x, y, w, h; `focused` the one in focus, `tabs` a column of tabs, `term` a see-through one.
    readonly property var windows: {
        if (!root.whole) {
            const ox = (picture.width / Math.max(0.01, root.k) - 1000) / 2, oy = (picture.height / Math.max(0.01, root.k) - 540) / 2
            return [{ x: ox + 90, y: oy + 60, w: 520, h: 340, term: true }, { x: ox + 400, y: oy + 160, w: 520, h: 330, focused: true }]
        }
        const a = root.area, g = root.gaps
        if (a.w <= 0 || a.h <= 0) return []
        if (root.mode === "master") {
            const main = Math.round((a.w - g) * root.mainShare)
            const third = (a.h - 2 * g) / 3
            if (root.mainSide === "center") {
                const side = (a.w - main - 2 * g) / 2
                return [{ x: a.x, y: a.y, w: side, h: a.h }, { x: a.x + side + g, y: a.y, w: main, h: a.h, focused: true },
                    { x: a.x + side + main + 2 * g, y: a.y, w: side, h: (a.h - g) / 2 },
                    { x: a.x + side + main + 2 * g, y: a.y + (a.h - g) / 2 + g, w: side, h: (a.h - g) / 2 }]
            }
            const rest = a.w - g - main
            const mainX = root.mainSide === "right" ? a.x + rest + g : a.x
            const restX = root.mainSide === "right" ? a.x : a.x + main + g
            return [{ x: mainX, y: a.y, w: main, h: a.h, focused: true },
                { x: restX, y: a.y, w: rest, h: third }, { x: restX, y: a.y + third + g, w: rest, h: third },
                { x: restX, y: a.y + 2 * (third + g), w: rest, h: third }]
        }
        if (root.mode === "dwindle") {
            const half = (a.w - g) / 2, tall = (a.h - g) / 2, quarter = (half - g) / 2
            return [{ x: a.x, y: a.y, w: half, h: a.h, focused: true }, { x: a.x + half + g, y: a.y, w: half, h: tall },
                { x: a.x + half + g, y: a.y + tall + g, w: quarter, h: tall },
                { x: a.x + half + quarter + 2 * g, y: a.y + tall + g, w: quarter, h: tall }]
        }
        if (root.mode === "stacking")
            return [{ x: a.x + a.w * 0.05, y: a.y + a.h * 0.06, w: a.w * 0.46, h: a.h * 0.5 },
                { x: a.x + a.w * 0.5, y: a.y + a.h * 0.32, w: a.w * 0.44, h: a.h * 0.58 },
                { x: a.x + a.w * 0.24, y: a.y + a.h * 0.16, w: a.w * 0.5, h: a.h * 0.62, focused: true }]
        // Scrolling: a wide column in focus between narrower ones. Centred, or at the left edge with the next one
        // running off the screen; "when it overflows" centres it here, as the two never fit side by side.
        const wide = Math.round(a.w * 0.6), narrow = Math.round(a.w * 0.45)
        const at = root.centre === "never" ? a.x : a.x + (a.w - wide) / 2
        const split = (a.h - g) / 2
        return [{ x: at - g - narrow, y: a.y, w: narrow, h: a.h }, { x: at, y: a.y, w: wide, h: a.h, focused: true, tabs: root.tabbed },
            { x: at + wide + g, y: a.y, w: narrow, h: split }, { x: at + wide + g, y: a.y + split + g, w: narrow, h: split }]
    }

    // Beside the screen where the card has the room, under it where it does not. Up close the picture takes the card.
    readonly property bool wide: root.width >= PrismTheme.dp(560)
    readonly property real pad: PrismTheme.dp(20)
    readonly property bool plated: root.whole

    implicitHeight: !root.plated ? stage.height + 2 * root.pad
        : root.wide ? stage.height + 2 * root.pad : stage.height + plate.implicitHeight + 3 * root.pad
    radius: PrismTheme.cardRadius
    color: PrismTheme.card

    Accessible.role: Accessible.Graphic
    Accessible.name: root.whole ? [root.way[0], Translation.tr("Room for windows") + " " + Math.round(root.area.w) + " × " + Math.round(root.area.h)].filter(part => part.length > 0).join(", ")
        : Translation.tr("Window in focus")

    Item {
        id: stage
        x: root.pad
        y: root.pad
        width: root.plated && root.wide ? Math.round((root.width - 3 * root.pad) * 0.6) : root.width - 2 * root.pad
        height: root.whole ? Math.round(Math.max(PrismTheme.dp(170), Math.min(PrismTheme.dp(270), stage.width * 0.56)))
            : Math.round(Math.max(PrismTheme.dp(200), Math.min(PrismTheme.dp(300), stage.width * 0.4)))
        readonly property real bezel: Math.max(3, PrismTheme.dp(6))

        Rectangle {
            id: lid
            anchors.centerIn: parent
            width: root.whole ? Math.round(Math.min(stage.width, stage.height * root.aspect)) : stage.width
            height: root.whole ? Math.round(lid.width / root.aspect) : stage.height
            radius: PrismTheme.dp(9)
            color: "#0b0b0c" // iris-literal: the bezel is the hardware's black, whatever the theme
            border.width: 1
            border.color: PrismTheme.line

            Item {
                id: picture
                anchors.fill: parent
                anchors.margins: stage.bezel
                clip: true

                Image {
                    id: wall
                    anchors.fill: parent
                    source: root.wallpaper
                    sourceSize.width: Math.round(PrismTheme.dp(640))
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                }

                Repeater {
                    model: root.windows
                    AppWindow {}
                }

                // The frame round the screen, where iRiS wears one, over what runs off its edge.
                Rectangle {
                    visible: root.whole && IrisFrame.band > 0
                    anchors.fill: parent
                    color: "transparent"
                    border.width: Math.max(1, Math.round(IrisFrame.band * root.k))
                    border.color: "#000000" // iris-literal: the frame is the screen's own black
                }

                // The Island where it rests.
                Rectangle {
                    readonly property bool upright: IrisFrame.vertical(IrisFrame.islandEdge)
                    readonly property real across: 250 * root.k
                    readonly property real thick: IrisFrame.islandBand * root.k
                    readonly property real off: (IrisFrame.band + IrisFrame.islandMargin) * root.k
                    readonly property real hang: IrisFrame.notch ? thick / 2 : 0
                    visible: root.whole && !IrisFrame.islandAutoHide && root.chassis
                    width: upright ? thick + hang : across
                    height: upright ? across : thick + hang
                    x: upright ? (IrisFrame.islandEdge === "left" ? off - hang : picture.width - off - width + hang) : (picture.width - width) / 2
                    y: upright ? (picture.height - height) / 2 : (IrisFrame.islandEdge === "top" ? off - hang : picture.height - off - height + hang)
                    radius: Math.min(width, height) / 2
                    color: "#000000" // iris-literal: the Island is black at rest, as on the screen
                }

                // The bubbles on the edges where they stand out, at both ends of each edge they hold.
                Repeater {
                    model: root.whole && root.chassis && !IrisFrame.piecesAutoHide ? IrisFrame.edges.filter(edge => IrisFrame.piecesOn(edge, root.port)) : []
                    Item {
                        id: bubbles
                        required property string modelData
                        readonly property bool upright: IrisFrame.vertical(bubbles.modelData)
                        readonly property bool near: bubbles.modelData === "top" || bubbles.modelData === "left"
                        readonly property real thick: Math.max(1, IrisFrame.pieceBand * root.k)
                        readonly property real off: (IrisFrame.band + IrisFrame.pieceGapOn(bubbles.modelData)) * root.k
                        readonly property real corner: (IrisFrame.band + 18) * root.k
                        anchors.fill: parent
                        Repeater {
                            // At the start of the edge and at its end, each its length in points.
                            model: [[true, 150], [false, 104]]
                            Rectangle {
                                required property var modelData
                                readonly property real span: modelData[1] * root.k
                                readonly property real along: modelData[0] ? bubbles.corner
                                    : (bubbles.upright ? bubbles.height : bubbles.width) - bubbles.corner - span
                                readonly property real at: bubbles.near ? bubbles.off
                                    : (bubbles.upright ? bubbles.width : bubbles.height) - bubbles.off - bubbles.thick
                                x: bubbles.upright ? at : along
                                y: bubbles.upright ? along : at
                                width: bubbles.upright ? bubbles.thick : span
                                height: bubbles.upright ? span : bubbles.thick
                                radius: Math.min(width, height) / 2
                                color: "#000000" // iris-literal: the bubbles are the Island's black
                            }
                        }
                    }
                }

                // The Dock where it stays out, or the rail it lives in.
                Rectangle {
                    id: dock
                    readonly property bool upright: IrisFrame.vertical(IrisFrame.dockEdge)
                    readonly property real icon: IrisFrame.dockIcon * root.k
                    readonly property real thick: IrisFrame.dockBand * root.k
                    readonly property real off: (IrisFrame.band + IrisFrame.dockMargin) * root.k
                    readonly property real across: IrisFrame.rail ? (upright ? picture.height : picture.width) : 7 * (IrisFrame.dockIcon + 8) * root.k + thick - dock.icon
                    visible: root.whole && IrisFrame.dockVisualDepth > 0
                    width: upright ? thick : across
                    height: upright ? across : thick
                    x: upright ? (IrisFrame.dockEdge === "left" ? off : picture.width - off - width) : (picture.width - width) / 2
                    y: upright ? (picture.height - height) / 2 : (IrisFrame.dockEdge === "top" ? off : picture.height - off - height)
                    radius: IrisFrame.rail ? 0 : Math.min(width, height) * 0.32
                    color: Qt.alpha(PrismTheme.light ? "#f4f4f6" : "#1b1b1e", 0.86) // iris-literal: the Dock's glass in the scheme
                    border.width: 1
                    border.color: PrismTheme.line
                    Grid {
                        anchors.centerIn: parent
                        rows: dock.upright ? 7 : 1
                        columns: dock.upright ? 1 : 7
                        spacing: 8 * root.k
                        Repeater {
                            model: 7
                            Rectangle {
                                width: dock.icon
                                height: dock.icon
                                radius: width * 0.28
                                color: Qt.alpha(PrismTheme.ink, 0.22)
                            }
                        }
                    }
                }
            }
        }
    }

    // What the arrangement is, and the room it has.
    Column {
        id: plate
        visible: root.plated
        x: root.wide ? stage.x + stage.width + root.pad : root.pad
        y: root.wide ? Math.round((root.height - plate.implicitHeight) / 2) : stage.y + stage.height + root.pad
        width: root.wide ? root.width - plate.x - root.pad : root.width - 2 * root.pad
        spacing: PrismTheme.dp(3)

        PrismText {
            width: parent.width
            text: root.way[0]
            color: PrismTheme.ink
            font.pixelSize: PrismTheme.head
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
            maximumLineCount: 2
        }
        PrismText {
            width: parent.width
            text: root.way[1]
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.body
            wrapMode: Text.WordWrap
        }
        Item { width: 1; height: PrismTheme.dp(12) }
        Column {
            spacing: PrismTheme.dp(2)
            PrismText {
                text: Translation.tr("Room for windows")
                color: PrismTheme.ink3
                font.pixelSize: PrismTheme.caption
            }
            PrismText {
                text: Math.round(root.area.w) + " × " + Math.round(root.area.h)
                figures: true
                color: PrismTheme.ink
                font.pixelSize: PrismTheme.row
                font.weight: Font.DemiBold
            }
        }
    }

    // One window as the compositor draws it: its shadow, its focus ring outside it, its border inside its edge, the
    // blur behind it and the app at its opacity.
    component AppWindow: Item {
        id: win
        required property var modelData
        readonly property bool focused: win.modelData.focused === true
        readonly property bool term: win.modelData.term === true
        readonly property real see: win.focused ? root.opacityOn : root.opacityOff
        readonly property real round: root.corner * root.k
        readonly property real line: root.border ? Math.max(1, root.borderWidth * root.k) : 0
        readonly property real halo: root.ring && win.focused ? Math.max(1, root.ringWidth * root.k) : 0
        // Points to drawing pixels, never thinner than a pixel where the thing is there at all.
        function pt(value: real): real { return value * root.k }

        x: Math.round(win.pt(win.modelData.x))
        y: Math.round(win.pt(win.modelData.y))
        width: Math.round(win.pt(win.modelData.w))
        height: Math.round(win.pt(win.modelData.h))
        z: win.focused ? 2 : 1
        Behavior on x { NumberAnimation { duration: PrismTheme.ms(260); easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: PrismTheme.ms(260); easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: PrismTheme.ms(260); easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: PrismTheme.ms(260); easing.type: Easing.OutCubic } }

        RectangularShadow {
            visible: root.shadow
            anchors.fill: parent
            radius: win.round
            blur: win.pt(root.softness)
            spread: win.pt(root.spread)
            offset.x: win.pt(root.fallX)
            offset.y: win.pt(root.fallY)
            color: Qt.rgba(0, 0, 0, 0.47) // iris-literal: the compositor's own shadow colour
        }

        // The focus ring, outside the window, in the gap.
        Rectangle {
            visible: win.halo > 0
            anchors.fill: parent
            anchors.margins: -win.halo
            radius: win.round + win.halo
            color: "transparent"
            border.width: win.halo
            border.color: root.ringColour
        }

        // The blur: what lies behind, frosted, seen through the window where the app lets it through.
        Item {
            visible: root.frosted && (win.term || win.see < 1)
            x: -win.x
            y: -win.y
            width: picture.width
            height: picture.height
            Image {
                id: behind
                anchors.fill: parent
                source: root.wallpaper
                sourceSize.width: Math.round(PrismTheme.dp(640))
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: false
            }
            Item {
                id: hole
                anchors.fill: parent
                visible: false
                layer.enabled: true
                Rectangle {
                    x: win.x
                    y: win.y
                    width: win.width
                    height: win.height
                    radius: win.round
                }
            }
            MultiEffect {
                anchors.fill: parent
                source: behind
                // The mask is laid over the source as it is: no padding round it.
                autoPaddingEnabled: false
                blurEnabled: true
                blur: root.frost
                blurMax: 48
                saturation: root.frostColour
                brightness: root.frostLight
                contrast: root.frostContrast
                maskEnabled: true
                maskSource: hole
            }
        }

        // The app, at the window's opacity.
        Rectangle {
            id: face
            anchors.fill: parent
            radius: win.round
            opacity: win.see
            layer.enabled: win.see < 1
            color: win.term ? Qt.alpha(PrismTheme.light ? "#fbfbfd" : "#101012", 0.62) // iris-literal: a terminal's see-through page
                : PrismTheme.light ? "#f7f7f9" : "#1c1c1f" // iris-literal: a plain app window in the scheme
            clip: true
            Rectangle {
                visible: !win.term
                width: parent.width
                height: win.pt(34)
                color: PrismTheme.fill
            }
            Repeater {
                model: win.term ? [[0.3, 12, 26, true], [0.62, 12, 50], [0.48, 12, 74], [0.7, 12, 98], [0.2, 12, 122, true]]
                    : [[0.36, 22, 56], [0.72, 12, 96], [0.58, 12, 122], [0.66, 12, 148]]
                Rectangle {
                    required property var modelData
                    required property int index
                    visible: y + height < face.height - win.pt(12)
                    x: win.pt(24)
                    y: win.pt(modelData[2])
                    width: (face.width - win.pt(48)) * modelData[0]
                    height: Math.max(1, win.pt(modelData[1]))
                    radius: height / 2
                    color: modelData[3] === true ? PrismTheme.accent
                        : index === 0 && !win.term ? Qt.alpha(PrismTheme.ink, 0.5) : Qt.alpha(PrismTheme.ink, 0.18)
                }
            }
            Rectangle {
                visible: !win.term && height > 3
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: win.pt(20)
                width: win.pt(104)
                height: win.pt(32)
                radius: height / 2
                color: PrismTheme.accent
            }
        }

        // The border, inside the window's edge: the one in focus in its colour, every other in theirs; the outer line
        // darker round it.
        Rectangle {
            visible: win.line > 0
            anchors.fill: parent
            radius: win.round
            color: "transparent"
            border.width: win.line
            border.color: win.focused ? root.borderOn : root.borderOff
        }
        Rectangle {
            visible: win.line > 0 && root.outerLine > 0
            anchors.fill: parent
            anchors.margins: -Math.max(1, win.pt(root.outerLine))
            radius: win.round + Math.max(1, win.pt(root.outerLine))
            color: "transparent"
            border.width: Math.max(1, win.pt(root.outerLine))
            border.color: Qt.rgba(0, 0, 0, 0.55) // iris-literal: the outer line is the border's shadow
        }

        // A column of tabs: its bar beside it, the shown tab lit.
        Column {
            visible: win.modelData.tabs === true
            x: -Math.max(3, win.pt(10))
            y: win.pt(8)
            spacing: Math.max(1, win.pt(6))
            Repeater {
                model: 3
                Rectangle {
                    required property int index
                    width: Math.max(2, win.pt(4))
                    height: (win.height - win.pt(16) - 2 * Math.max(1, win.pt(6))) / 3
                    radius: width / 2
                    color: index === 0 ? root.borderOn : Qt.alpha(PrismTheme.ink, 0.35)
                }
            }
        }
    }
}
