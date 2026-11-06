pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.widgets

// Glyph: lamps set into the Island's rim, as on the back of a Nothing Phone, each one a fact you read by how far it
// is lit. The foot is the battery (or the hour on a machine without one), the left side what waits in your
// notifications, the right side the next event closing in over its last hour. A lamp that has nothing to say stays
// dark glass. Plugged in, the foot counts up to the charge and the figure rides beside the time; under the pointer
// every lamp counts up again (iris.bar.faces.glyph).
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    // The lamps are the body's edge: a song's wings ride inside them (IrisIsland.faceWings).
    readonly property bool edge: true
    readonly property real d: IrisStyle.density
    readonly property var options: Config.options?.iris?.bar?.faces?.glyph ?? ({})
    readonly property real line: Math.max(2, Math.round(2.5 * root.d))
    readonly property real pad: Math.round(16 * root.d)
    readonly property real gap: Math.round(8 * root.d)
    readonly property bool flipped: root.island?.bottomEdge ?? false
    readonly property int minute: Math.floor(DateTime.clock.date.getTime() / 60000)

    // The foot: the battery's charge, or the hour gone where there is no battery or the person asked for it.
    readonly property bool battery: String(root.options.foot ?? "battery") === "battery" && Battery.available
    readonly property real level: Math.max(0, Math.min(1, Number(Battery.percentage)))
    readonly property real footShare: root.battery ? root.level : (root.minute % 60) / 60
    readonly property bool low: root.battery && (Battery.isLow || root.level < 0.15) && !Battery.isCharging
    // The left side: up to three notifications waiting, a third of the lamp each.
    readonly property int waiting: root.options.notifications === false ? 0 : Notifications.unread
    readonly property real leftShare: Math.min(1, root.waiting / 3)
    // The right side: the next event within the hour, the lamp filling as it nears; lit whole while it runs.
    readonly property var entry: root.options.events === false ? null : IrisFaceData.nextEntry(root.minute * 60000, 60)
    readonly property real rightShare: !root.entry || root.entry.title.length === 0 ? 0
        : root.entry.running ? 1 : Math.max(0.08, 1 - root.entry.left / 60)

    readonly property color lit: IrisStyle.text
    readonly property color glass: Qt.alpha(IrisStyle.text, 0.1)

    // The charge in figures beside the time, only while charging and only when the Island has room for it.
    readonly property bool figureWanted: root.battery && Battery.isCharging && root.options.figure !== false
    readonly property real bare: clock.implicitWidth + 2 * root.pad
    readonly property bool figureFits: root.bare + root.gap + figure.implicitWidth <= (root.island?.faceRoom ?? Infinity)
    readonly property bool figureShown: root.figureWanted && root.figureFits
    readonly property real contentWidth: root.bare + (root.figureShown ? root.gap + figure.implicitWidth : 0)

    // Each lamp counts up on a spring: the share it says, from where it stands.
    IrisSpring { id: footSpring; surface: "island"; intent: "move"; to: root.footShare; minimum: 0 }
    IrisSpring { id: leftSpring; surface: "island"; intent: "move"; to: root.leftShare; minimum: 0 }
    IrisSpring { id: rightSpring; surface: "island"; intent: "move"; to: root.rightShare; minimum: 0 }
    function countUp(springs: var): void {
        if (!IrisStyle.motionEnabled) return
        for (const spring of springs) {
            spring.value = 0
            spring.kick()
        }
    }
    readonly property bool charging: Battery.isCharging
    onChargingChanged: if (root.charging && root.battery) root.countUp([footSpring])
    HoverHandler {
        id: hover
        onHoveredChanged: if (hovered) root.countUp([footSpring, leftSpring, rightSpring])
    }

    // One lamp: its dark glass along the whole run, the lit share over it with a little halo.
    component Lamp: Shape {
        id: lamp
        property real share: 0
        property color tone: root.lit
        // Which run it lights: "foot", "left" or "right" (root.runAt).
        property string run: "foot"
        function points(upTo: real): var {
            const out = []
            const n = lamp.run === "foot" ? 1 : Math.max(1, Math.ceil(24 * upTo))
            for (let i = 0; i <= n; i++)
                out.push(root.runAt(lamp.run, upTo * i / n))
            return out
        }
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.glass
            strokeWidth: root.line
            capStyle: ShapePath.RoundCap
            PathPolyline { path: lamp.points(1) }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: lamp.share > 0.005 ? Qt.alpha(lamp.tone, 0.22) : "transparent"
            strokeWidth: root.line * 3.2
            capStyle: ShapePath.RoundCap
            PathPolyline { path: lamp.share > 0.005 ? lamp.points(lamp.share) : [] }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: lamp.share > 0.005 ? lamp.tone : "transparent"
            strokeWidth: root.line
            capStyle: ShapePath.RoundCap
            PathPolyline { path: lamp.share > 0.005 ? lamp.points(lamp.share) : [] }
        }
    }

    // The rim's geometry: lamps sit just inside the body's edge.
    readonly property real inset: Math.round(4 * root.d) + root.line / 2
    readonly property real radius: root.height / 2 - root.inset
    readonly property real footY: root.flipped ? root.inset : root.height - root.inset
    readonly property real cxLeft: root.height / 2
    readonly property real cxRight: root.width - root.height / 2
    // Each side spans 150 degrees of its end, leaving glass between it and the foot; it fills from the foot.
    readonly property real sideSpan: 150 * Math.PI / 180

    // A point `t` of the way along a run, from the end it fills from. The sides start near the foot and climb
    // round their end of the Island; on the bottom edge everything mirrors, the foot being on top.
    function runAt(run: string, t: real): point {
        if (run === "foot")
            return Qt.point(root.cxLeft + t * (root.cxRight - root.cxLeft), root.footY)
        const sign = root.flipped ? -1 : 1
        const start = (Math.PI - root.sideSpan) / 2
        const a = run === "left" ? sign * (Math.PI / 2 + start + t * root.sideSpan) : sign * (Math.PI / 2 - start - t * root.sideSpan)
        return Qt.point((run === "left" ? root.cxLeft : root.cxRight) + root.radius * Math.cos(a), root.height / 2 + root.radius * Math.sin(a))
    }

    Lamp {
        run: "foot"
        share: footSpring.value
        tone: root.low ? IrisStyle.danger : root.lit
    }
    Lamp {
        run: "left"
        visible: root.options.notifications !== false
        share: leftSpring.value
    }
    Lamp {
        run: "right"
        visible: root.options.events !== false
        share: rightSpring.value
    }

    IrisClock {
        id: clock
        x: root.pad
        anchors.verticalCenter: parent.verticalCenter
        family: IrisStyle.figureFace(pixelSize)
        minorFamily: family
        pixelSize: root.island?.figureSize ?? IrisStyle.typeHeadline
        separatorColor: root.island?.clockAccent ?? IrisStyle.accent
    }
    IrisText {
        id: figure
        visible: root.figureShown
        x: clock.x + clock.implicitWidth + root.gap
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(root.level * 100) + "%"
        color: IrisStyle.identity.green
        font.pixelSize: Math.round(13 * root.d)
        font.weight: IrisStyle.weight(Font.Bold)
        font.features: ({ "tnum": 1 })
    }
}
