pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.preview.parts

// Niri's strip as it tiles: three columns with the gaps between them, the focused one in its ring or border, corners,
// shadows and the opacity of the windows you are not using, all read from Niri itself.
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
    readonly property real dim: Math.max(0.2, Math.min(1, Number(winRoot.niri("window-rules", "inactive-opacity", 1))))
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
            { group: "Layout", x: gapX, y: Math.round(h * 0.5), part: Qt.rect(gapX - g / 2 - Math.round(3 * d), fy, g + Math.round(6 * d), fh), radius: Math.round(4 * d) }
        ]
    }

    Repeater {
        // The column on the left runs off the screen as Niri's strip does; the focused one sits in the middle.
        model: [{ x: -0.16, w: 0.34, focused: false }, { x: 0.18, w: 0.46, focused: true }, { x: 0.64, w: 0.42, focused: false }]
        Item {
            id: column
            required property var modelData
            readonly property real g: winRoot.gaps
            x: Math.round(winRoot.width * column.modelData.x + column.g / 2)
            y: Math.round(column.g + IrisStyle.weld)
            width: Math.round(winRoot.width * column.modelData.w - column.g)
            height: Math.round(winRoot.height - 2 * column.g - IrisStyle.weld)
            opacity: column.modelData.focused ? 1 : winRoot.dim

            RectangularShadow {
                visible: winRoot.shadows
                anchors.fill: app
                radius: app.radius
                blur: winRoot.softness * 0.6 * winRoot.d
                offset.y: 3 * winRoot.d
                color: IrisStyle.shadow
            }
            // The ring sits outside the focused window, as Niri draws it.
            Rectangle {
                visible: winRoot.ring && column.modelData.focused
                anchors.fill: app
                anchors.margins: -winRoot.ringWidth
                radius: app.radius + winRoot.ringWidth
                color: "transparent"
                border.width: winRoot.ringWidth
                border.color: winRoot.ringColour
            }
            Rectangle {
                id: app
                anchors.fill: parent
                radius: winRoot.corners
                // An app window is opaque whatever the shell's glass: the theme's own surface.
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
        glyph: "select_window"
        text: [Translation.tr("Gaps") + " " + Math.round(winRoot.gaps) + " px",
            winRoot.corners > 0 ? Translation.tr("Window corners") + " " + Math.round(winRoot.corners) + " px" : "",
            winRoot.ring ? Translation.tr("Focus ring") : winRoot.border ? Translation.tr("Border") : ""].filter(part => part.length > 0).join(" · ")
    }
}
