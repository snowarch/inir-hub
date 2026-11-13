import QtQuick
import Quickshell
import qs.modules.iris.style

// Prism's body (PrismGlass.frag): the folder of frosted glass every Prism face stands on, drawn whole by one shader that
// reaches `room` past the face for its shadow. Nothing glows past its edge; the shadow on the desktop is the widget's
// `iris.shadow` (0 to 100, off by factory: his 11-07). Every measure is in the face's pixels.
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
    // One piece of glass instead of the folder (Prism's quiet and beam looks): no tab, flap or pane; its corners, and how
    // much of the beam it lets through (0: only its rim splits the light near `prism`).
    property bool slab: false
    property real slabRadius: body.face.radius
    property real beamPass: 0

    readonly property real room: body.face.dp(40)
    // The shadow on the desktop: the widget's own, none with the background off.
    readonly property real shadow: body.face.clear ? 0
        : Math.max(0, Math.min(1, Number(body.face.widget?.familyOption("shadow", 0) ?? 0) / 100))

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
        fragmentShader: Qt.resolvedUrl("PrismGlass.frag.qsb")
        // Background off means no glass at all, as on every other widget (his 11-07: the shelf's "hide every background"
        // left Prism's folders standing as smoked glass): the face's ink stands on the wallpaper with Lume's shadow.
        visible: !body.face.clear
        readonly property bool light: body.face.lightBackdrop
        readonly property color tint: body.face.plateColor
        readonly property vector4d frame: Qt.vector4d(body.width, body.height, body.room, body.lean)
        readonly property vector4d folder: Qt.vector4d(body.flapRight, body.tabRight, body.flapTop,
            1 / Math.max(0.5, Screen.devicePixelRatio))
        readonly property vector4d radii: Qt.vector4d(body.face.radius, body.tabRadius, body.flapRadius, body.paneRadius)
        readonly property vector4d pane: Qt.vector4d(0, body.paneTop, body.width, body.paneBottom)
        readonly property vector4d beam: Qt.vector4d(body.entry.x, body.entry.y, body.prism.x, body.prism.y)
        readonly property vector4d fan: Qt.vector4d(body.fanAngle, body.fanSpread, body.lightPass, body.white ? 1 : 0)
        readonly property vector4d tone: Qt.vector4d(glass.tint.r, glass.tint.g, glass.tint.b, glass.tint.a)
        readonly property vector4d shelf: Qt.vector4d(body.shelf.r, body.shelf.g, body.shelf.b, 0)
        readonly property vector4d look: Qt.vector4d(glass.light ? 1 : 0, body.face.frost !== null ? 1 : 0,
            glass.light ? 0.022 : 0.04, body.shadow)
        readonly property vector4d form: Qt.vector4d(body.slab ? 1 : 0, body.slabRadius, body.beamPass, 0)
        readonly property Item frost: body.face.frost ?? noFrost
        // Prism's light, the shell's one source of it (IrisStyle.prismStops).
        readonly property var stops: IrisStyle.prismStops
        readonly property vector4d s0: Qt.vector4d(stops[0].r, stops[0].g, stops[0].b, 1)
        readonly property vector4d s1: Qt.vector4d(stops[1].r, stops[1].g, stops[1].b, 1)
        readonly property vector4d s2: Qt.vector4d(stops[2].r, stops[2].g, stops[2].b, 1)
        readonly property vector4d s3: Qt.vector4d(stops[3].r, stops[3].g, stops[3].b, 1)
        readonly property vector4d s4: Qt.vector4d(stops[4].r, stops[4].g, stops[4].b, 1)
        readonly property vector4d s5: Qt.vector4d(stops[5].r, stops[5].g, stops[5].b, 1)
        readonly property vector4d s6: Qt.vector4d(stops[6].r, stops[6].g, stops[6].b, 1)
    }

    // Where the tab's edge crosses height `y`: what sits in the tab ends before it, what sits on the flap after it.
    function edgeAt(y: real): real {
        return body.tabRight - body.lean / 2 + body.lean * Math.max(0, Math.min(1, y / Math.max(1, body.paneTop)))
    }
}
