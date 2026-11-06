pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.bar.island

// Comet: one light runs round the Island's rim with its tail fading behind it, and where its head stands counts the
// hour, the day or the battery, read clockwise from the top. Track lights the whole way gone instead of a tail. The
// head moves once a minute and runs a lap while the pointer is over the Island (iris.bar.faces.comet).
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    // The rim is the body's edge: a song's wings ride inside it (IrisIsland.faceWings).
    readonly property bool edge: true
    readonly property real d: IrisStyle.density
    readonly property real contentWidth: clock.implicitWidth + Math.round(30 * root.d)
    readonly property real line: Math.max(1.5, Math.round(2 * root.d))
    readonly property var options: Config.options?.iris?.bar?.faces?.comet ?? ({})
    readonly property date now: DateTime.clock.date
    readonly property string counts: {
        const asked = String(root.options.counts ?? "hour")
        return asked === "battery" && !Battery.available ? "hour" : ["hour", "day", "battery"].includes(asked) ? asked : "hour"
    }
    readonly property real share: root.counts === "battery" ? Math.max(0, Math.min(1, Number(Battery.percentage)))
        : root.counts === "day" ? (root.now.getHours() * 60 + root.now.getMinutes()) / 1440
        : root.now.getMinutes() / 60
    readonly property bool track: String(root.options.trail ?? "tail") === "track"
    readonly property var palette: IrisStyle.islandLight(String(root.options.colours ?? "spectrum"), root.now.getHours())
    // A low battery counts in the warning colour, whatever the palette.
    readonly property bool low: root.counts === "battery" && Battery.isLow && !Battery.isCharging
    readonly property color head: root.low ? IrisStyle.danger : root.palette[0]
    property real lap: 0
    readonly property real at: (root.share + root.lap) % 1

    // The rim as one loop from the top centre, clockwise; `t` is a share of its length.
    function pointAt(t: real, w: real, h: real): point {
        const r = h / 2
        const straight = Math.max(0, w - h)
        const arc = Math.PI * r
        const total = 2 * straight + 2 * arc
        let s = ((t % 1) + 1) % 1 * total
        const cx = w / 2
        const cy = h / 2
        if (s < straight / 2) return Qt.point(cx + s, cy - r)
        s -= straight / 2
        if (s < arc) { const a = s / r; return Qt.point(cx + straight / 2 + r * Math.sin(a), cy - r * Math.cos(a)) }
        s -= arc
        if (s < straight) return Qt.point(cx + straight / 2 - s, cy + r)
        s -= straight
        if (s < arc) { const a = s / r; return Qt.point(cx - straight / 2 - r * Math.sin(a), cy + r * Math.cos(a)) }
        s -= arc
        return Qt.point(cx - straight / 2 + s, cy - r)
    }
    // The angle a point stands at, seen from the middle: counter-clockwise from three o'clock, as a gradient turns.
    function angleOf(p: point, w: real, h: real): real {
        return (Math.atan2(h / 2 - p.y, p.x - w / 2) * 180 / Math.PI + 360) % 360
    }

    HoverHandler { id: hover }
    SequentialAnimation {
        running: hover.hovered && !root.track && IrisStyle.motionEnabled && root.options.laps !== false
        NumberAnimation { target: root; property: "lap"; from: 0; to: 1; duration: 1800; easing.type: Easing.InOutCubic }
        PropertyAction { target: root; property: "lap"; value: 0 }
    }

    // The rim's own box (IslandRim draws inside a 2 dp margin): where the head stands on it, and how far round the
    // light reaches behind it, a fifth of the rim or back to the top.
    readonly property real rimWidth: root.width - 2 * Math.round(2 * root.d)
    readonly property real rimHeight: root.height - 2 * Math.round(2 * root.d)
    readonly property real headAngle: root.angleOf(root.pointAt(root.at, root.rimWidth, root.rimHeight), root.rimWidth, root.rimHeight)
    readonly property real reach: {
        const back = root.track ? Qt.point(root.rimWidth / 2, 0) : root.pointAt(root.at - 0.2, root.rimWidth, root.rimHeight)
        const span = (root.angleOf(back, root.rimWidth, root.rimHeight) - root.headAngle + 360) % 360 / 360
        return Math.max(0.004, Math.min(0.996, span))
    }
    readonly property color dim: root.track ? Qt.alpha(IrisStyle.text, 0.12) : "transparent"

    IslandRim {
        anchors.fill: parent
        line: root.line
        angle: root.headAngle
        stops: [[0, root.head],
            [root.track ? root.reach - 0.002 : root.reach * 0.4, root.track ? root.palette[2] : Qt.alpha(root.palette[1], 0.75)],
            [root.reach, root.track ? root.dim : Qt.alpha(root.palette[2], 0)],
            [1, root.dim]]
    }
    // The head: a bead of light on the rim, with its glow.
    Item {
        id: bead
        readonly property real inner: Math.round(2 * root.d) + Math.round(1.5 * root.d) + root.line / 2
        readonly property point spot: root.pointAt(root.at, root.width - 2 * bead.inner, root.height - 2 * bead.inner)
        x: bead.inner + bead.spot.x
        y: bead.inner + bead.spot.y
        Rectangle {
            anchors.centerIn: parent
            width: root.line * 4.5
            height: width
            radius: width / 2
            color: Qt.alpha(root.head, 0.28)
        }
        Rectangle {
            anchors.centerIn: parent
            width: root.line * 2.2
            height: width
            radius: width / 2
            color: root.head
        }
    }
    IrisClock {
        id: clock
        anchors.centerIn: parent
        family: IrisStyle.figureFace(pixelSize)
        minorFamily: family
        pixelSize: root.island?.figureSize ?? IrisStyle.typeHeadline
        separatorColor: root.island?.clockAccent ?? IrisStyle.accent
    }
}
