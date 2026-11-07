import QtQuick
import Quickshell
import qs.modules.common.functions
import qs.modules.iris.style

// Prism's body (PrismBody.frag): the folder of frosted glass every Prism face stands on, drawn whole by one shader that
// reaches `room` past the face for its shadow and glow. Every measure is in the face's pixels.
Item {
    id: body
    required property var face

    // The tab, whose right edge crosses `tabRight` halfway down the header and leans `lean` across it.
    property real tabRight: 0
    property real lean: 0
    property real tabRadius: 0
    // The flap beside it: its top, right edge and corner.
    property real flapTop: 0
    property real flapRight: 0
    property real flapRadius: 0
    // The pane laid across the whole width.
    property real paneTop: 0
    property real paneBottom: 0
    property real paneRadius: 0
    // The beam: where it enters, where it breaks, the fan's direction and half spread (radians, y down).
    property point entry: Qt.point(0, 0)
    property point prism: Qt.point(0, 0)
    property real fanAngle: -0.42
    property real fanSpread: 0.29
    // How much light passes (0 none, 1 all), and the flap's colour.
    property real lightPass: 1
    property color shelf: body.face.accent
    // Nothing: white light only.
    property bool white: body.face.nothing ?? false

    readonly property real room: body.face.dp(40)

    Item {
        id: noFrost
        visible: false
        width: 1
        height: 1
        layer.enabled: true
    }

    ShaderEffect {
        id: glass
        x: -body.room
        y: -body.room
        width: body.width + 2 * body.room
        height: body.height + 2 * body.room
        fragmentShader: Qt.resolvedUrl("PrismBody.frag.qsb")
        readonly property bool light: body.face.lightBackdrop
        // Background off: the folder stays (it is the face) as smoked glass light enough to read through, no shadow.
        readonly property color tint: body.face.clear
            ? ColorUtils.applyAlpha(glass.light ? IrisStyle.frost : IrisStyle.surface, glass.light ? 0.72 : 0.62) : body.face.plateColor // iris-literal: background off keeps the folder (it is the face) as smoked glass
        readonly property vector4d frame: Qt.vector4d(body.width, body.height, body.room, body.lean)
        readonly property vector4d folder: Qt.vector4d(body.flapRight, body.tabRight, body.flapTop,
            1 / Math.max(0.5, Screen.devicePixelRatio))
        readonly property vector4d radii: Qt.vector4d(body.face.radius, body.tabRadius, body.flapRadius, body.paneRadius)
        readonly property vector4d pane: Qt.vector4d(0, body.paneTop, body.width, body.paneBottom)
        readonly property vector4d beam: Qt.vector4d(body.entry.x, body.entry.y, body.prism.x, body.prism.y)
        readonly property vector4d fan: Qt.vector4d(body.fanAngle, body.fanSpread, body.lightPass, body.white ? 1 : 0)
        readonly property vector4d tone: Qt.vector4d(glass.tint.r, glass.tint.g, glass.tint.b, glass.tint.a)
        readonly property vector4d shelf: Qt.vector4d(body.shelf.r, body.shelf.g, body.shelf.b, body.face.dp(14))
        readonly property vector4d look: Qt.vector4d(glass.light ? 1 : 0, body.face.frost !== null ? 1 : 0,
            glass.light ? 0.022 : 0.04, body.face.clear ? 0 : 1)
        readonly property Item frost: body.face.frost ?? noFrost
    }

    // Where the tab's edge crosses height `y`: what sits in the tab ends before it, what sits on the flap after it.
    function edgeAt(y: real): real {
        return body.tabRight - body.lean / 2 + body.lean * Math.max(0, Math.min(1, y / Math.max(1, body.paneTop)))
    }
}
