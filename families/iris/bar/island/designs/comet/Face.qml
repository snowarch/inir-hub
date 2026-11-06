pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

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

    Repeater {
        model: [{ inset: 0, alpha: 0.3, width: 5 }, { inset: 1.5, alpha: 1, width: 1 }]
        Shape {
            id: rim
            required property var modelData
            readonly property real gap: Math.round(rim.modelData.inset * root.d)
            readonly property real thick: root.line * rim.modelData.width
            readonly property real headAngle: root.angleOf(root.pointAt(root.at, rim.width, rim.height), rim.width, rim.height)
            // How far the light reaches behind the head, as a share of the turn: a fifth of the rim, or back to the top.
            readonly property real reach: {
                const back = root.track ? Qt.point(rim.width / 2, 0) : root.pointAt(root.at - 0.2, rim.width, rim.height)
                const span = (root.angleOf(back, rim.width, rim.height) - rim.headAngle + 360) % 360 / 360
                return Math.max(0.004, Math.min(0.996, span))
            }
            readonly property color dim: root.track ? Qt.alpha(IrisStyle.text, 0.12) : "transparent"
            anchors.fill: parent
            anchors.margins: Math.round(2 * root.d)
            opacity: rim.modelData.alpha
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "transparent"
                fillRule: ShapePath.OddEvenFill
                fillGradient: ConicalGradient {
                    centerX: rim.width / 2
                    centerY: rim.height / 2
                    angle: rim.headAngle
                    GradientStop { position: 0.0; color: root.head }
                    GradientStop { position: root.track ? rim.reach - 0.002 : rim.reach * 0.4; color: root.track ? root.palette[2] : Qt.alpha(root.palette[1], 0.75) }
                    GradientStop { position: rim.reach; color: root.track ? rim.dim : Qt.alpha(root.palette[2], 0) }
                    GradientStop { position: 1.0; color: rim.dim }
                }
                PathRectangle { x: rim.gap; y: rim.gap; width: rim.width - 2 * rim.gap; height: rim.height - 2 * rim.gap; radius: (rim.height - 2 * rim.gap) / 2 }
                PathRectangle {
                    x: rim.gap + rim.thick
                    y: rim.gap + rim.thick
                    width: Math.max(0, rim.width - 2 * (rim.gap + rim.thick))
                    height: Math.max(0, rim.height - 2 * (rim.gap + rim.thick))
                    radius: Math.max(0, (rim.height - 2 * (rim.gap + rim.thick)) / 2)
                }
            }
        }
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
