pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.services
import qs.modules.common.widgets
import qs.modules.nihil.style
import qs.modules.nihil.components
import qs.modules.nihil.preview.parts

// Niri's strip as it tiles: three columns with the gaps between them, the focused one in its ring or border, corners,
// shadows, how see-through the windows are in and out of focus and the blur behind them, all read from Niri itself.
PreviewScene {
    id: winRoot
    function colourOf(value: var, fallback: color): color { return String(value ?? "").length > 0 ? value : fallback }
    readonly property real gaps: Math.max(0, Number(winRoot.niri("layout", "gaps", 16)))
    readonly property bool border: winRoot.niri("layout", "border.enabled", false) === true
    readonly property real borderWidth: Number(winRoot.niri("layout", "border.width", 4))
    readonly property bool ring: winRoot.niri("layout", "focus-ring.enabled", false) === true
    readonly property real ringWidth: Number(winRoot.niri("layout", "focus-ring.width", 4))
    readonly property color ringColour: winRoot.colourOf(winRoot.niri("layout", "focus-ring.active-color", ""), IrisStyle.accent)
    readonly property color borderOn: winRoot.colourOf(winRoot.niri("layout", "border.active-color", ""), IrisStyle.accent)
    readonly property color borderOff: winRoot.colourOf(winRoot.niri("layout", "border.inactive-color", ""), IrisStyle.borderStrong)
    readonly property real corners: Math.max(0, Number(winRoot.niri("window-rules", "corner-radius", 0)))
    readonly property bool shadows: winRoot.niri("layout", "shadow.enabled", false) === true
    readonly property real softness: Number(winRoot.niri("layout", "shadow.softness", 30))
    // Niri sets how see-through windows are; Umbriel leaves it to each app and blurs behind the ones that are (its
    // `glass`). There the window out of focus stands for such an app, so the blur has something to show through.
    readonly property bool opacities: CompositorConfig.has("window-rules", "inactive-opacity")
    readonly property bool frosted: winRoot.niri("window-rules", "blur", false) === true || winRoot.niri("glass", "enabled", false) === true
    readonly property real dim: winRoot.opacities ? Math.max(0.2, Math.min(1, Number(winRoot.niri("window-rules", "inactive-opacity", 1))))
        : winRoot.frosted && winRoot.group === "Glass behind apps" ? 0.82 : 1
    readonly property real lit: winRoot.opacities ? Math.max(0.2, Math.min(1, Number(winRoot.niri("window-rules", "active-opacity", 1)))) : 1
    // The column on the left runs off the screen as Niri's strip does; the focused one sits in the middle.
    readonly property var columns: [{ x: -0.16, w: 0.34, focused: false }, { x: 0.18, w: 0.46, focused: true }, { x: 0.64, w: 0.42, focused: false }]
    function frameOf(column: var): rect {
        const g = winRoot.gaps
        return Qt.rect(Math.round(winRoot.width * column.x + g / 2), Math.round(g + IrisStyle.weld),
            Math.round(winRoot.width * column.w - g), Math.round(winRoot.height - 2 * g - IrisStyle.weld))
    }
    readonly property real naturalWidth: Math.round(680 * winRoot.d)
    readonly property real naturalHeight: Math.round(320 * winRoot.d)
    narrowest: Math.round(400 * winRoot.d)
    lowest: Math.round(220 * winRoot.d)
    // The focused window's parts a person points at: its frame (borders), a corner (shape), its title bar and the
    // dots in it (closing), and the gap beside it (layout). The page keeps those of its own groups.
    spots: {
        const g = winRoot.gaps, w = winRoot.width, h = winRoot.height, d = winRoot.d
        const fx = Math.round(w * 0.18 + g / 2), fy = Math.round(g + IrisStyle.weld)
        const fw = Math.round(w * 0.46 - g), fh = Math.round(h - 2 * g - IrisStyle.weld)
        const ring = winRoot.ring ? winRoot.ringWidth : 0
        const pad = Math.round(14 * d) + (winRoot.border ? winRoot.borderWidth : 0)
        const corner = Math.max(Math.round(40 * d), winRoot.corners * 2)
        const bar = pad + Math.round(24 * d)
        const gapX = Math.round(w * 0.18)
        return [
            { group: "Borders", x: fx + fw, y: Math.round(fy + fh * 0.42), part: Qt.rect(fx - ring, fy - ring, fw + 2 * ring, fh + 2 * ring), radius: winRoot.corners + ring },
            { group: "Shape", x: fx, y: fy + fh, part: Qt.rect(fx, fy + fh - corner, corner, corner), radius: winRoot.corners },
            { group: "Closing", x: fx + pad + Math.round(54 * d), y: fy + pad + Math.round(4 * d),
                part: Qt.rect(fx + pad - Math.round(6 * d), fy + pad - Math.round(6 * d), Math.round(48 * d), Math.round(20 * d)), radius: Math.round(10 * d) },
            { group: "Title bars", x: fx + fw - Math.round(28 * d), y: fy + Math.round(bar / 2), part: Qt.rect(fx, fy, fw, bar), radius: winRoot.corners },
            { group: "Layout", x: gapX, y: Math.round(h * 0.5), part: Qt.rect(gapX - g / 2 - Math.round(3 * d), fy, g + Math.round(6 * d), fh), radius: Math.round(4 * d) },
            { group: "Glass behind apps", x: Math.round(w * 0.64 + g / 2) + Math.round(w * 0.21), y: Math.round(h * 0.5),
                part: winRoot.frameOf(winRoot.columns[2]), radius: winRoot.corners }
        ]
    }

    // What shows through a see-through window, frosted when Niri blurs behind apps.
    ShaderEffectSource {
        id: wall
        anchors.fill: parent
        visible: false
        sourceItem: winRoot.frosted ? winRoot.wallpaperView?.textureItem ?? null : null
        live: true
    }
    Repeater {
        model: winRoot.frosted && (winRoot.lit < 1 || winRoot.dim < 1) ? winRoot.columns : []
        ClippingRectangle {
            id: frost
            required property var modelData
            readonly property rect frame: winRoot.frameOf(frost.modelData)
            x: frost.frame.x
            y: frost.frame.y
            width: frost.frame.width
            height: frost.frame.height
            radius: winRoot.corners
            color: "transparent"
            MultiEffect {
                x: -frost.x
                y: -frost.y
                width: winRoot.width
                height: winRoot.height
                source: wall
                autoPaddingEnabled: false
                blurEnabled: true
                blur: 1
                blurMax: Math.round(48 * winRoot.d)
            }
        }
    }

    Repeater {
        model: winRoot.columns
        Item {
            id: column
            required property var modelData
            readonly property rect frame: winRoot.frameOf(column.modelData)
            x: column.frame.x
            y: column.frame.y
            width: column.frame.width
            height: column.frame.height
            opacity: column.modelData.focused ? winRoot.lit : winRoot.dim

            RectangularShadow {
                offset.x: IrisStyle.shadowThrow
                visible: winRoot.shadows
                anchors.fill: app
                radius: 0
                blur: 0
                offset.y: IrisStyle.shadowThrow
                color: IrisStyle.shadow
            }
            // The ring sits outside the focused window, as Niri draws it.
            Rectangle {
                visible: winRoot.ring && column.modelData.focused
                anchors.fill: app
                anchors.margins: -winRoot.ringWidth
                radius: 0
                color: "transparent"
                border.width: winRoot.ringWidth
                border.color: winRoot.ringColour
            }
            Rectangle {
                id: app
                anchors.fill: parent
                radius: 0
                color: IrisStyle.surfaceOpaque
                border.width: winRoot.border ? winRoot.borderWidth : 0
                border.color: column.modelData.focused ? winRoot.borderOn : winRoot.borderOff
                WindowPage {
                    anchors.fill: parent
                    inset: winRoot.border ? winRoot.borderWidth : 0
                }
            }
        }
    }

    Caption {
        glyph: winRoot.group === "Glass behind apps" ? "blur_on" : "select_window"
        text: winRoot.group === "Glass behind apps"
            ? [winRoot.opacities ? Translation.tr("Window in focus") + " " + Math.round(winRoot.lit * 100) + " %" : "",
                winRoot.opacities ? Translation.tr("Windows out of focus") + " " + Math.round(winRoot.dim * 100) + " %" : "",
                winRoot.frosted ? Translation.tr("Blur behind apps") : ""].filter(part => part.length > 0).join(" · ")
            : [Translation.tr("Gaps") + " " + Math.round(winRoot.gaps) + " px",
            winRoot.corners > 0 ? Translation.tr("Window corners") + " " + Math.round(winRoot.corners) + " px" : "",
            winRoot.ring ? Translation.tr("Focus ring") : winRoot.border ? Translation.tr("Border") : ""].filter(part => part.length > 0).join(" · ")
    }
}
