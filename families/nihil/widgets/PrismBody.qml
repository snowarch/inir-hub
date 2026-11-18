import QtQuick
import Quickshell
import qs.modules.nihil.components
import qs.modules.nihil.style

// The sheet every Prism face stands on: paper, an ink rule and a printed shadow.
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
    // White light only (his 11-16: the split light read as a rainbow pasted on every card). The shader keeps its
    // spectrum path for a Design that asks for it.
    property bool white: true
    // One piece of glass instead of the folder (Prism's quiet and beam looks): no tab, flap or pane; its corners, and how
    // much of the beam it lets through (0: only a breath of it inside the glass near `prism`).
    property bool slab: false
    property real slabRadius: body.face.radius
    property real beamPass: 0

    readonly property real room: body.face.dp(40)
    // The shadow on the desktop: the widget's own, none with the background off.
    readonly property real shadow: body.face.clear ? 0
        : Math.max(0, Math.min(1, Number(body.face.widget?.familyOption("shadow", 0) ?? 0) / 100))

    IrisBodyShadow {
        anchors.fill: parent
        visible: !body.face.clear
    }
    Rectangle {
        anchors.fill: parent
        visible: !body.face.clear
        color: IrisStyle.surfaceOpaque
        border.width: IrisStyle.edgeWidth
        border.color: IrisStyle.text
    }

    // Where the tab's edge crosses height `y`: what sits in the tab ends before it, what sits on the flap after it.
    function edgeAt(y: real): real {
        return body.tabRight - body.lean / 2 + body.lean * Math.max(0, Math.min(1, y / Math.max(1, body.paneTop)))
    }
}
