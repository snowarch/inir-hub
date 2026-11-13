pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// Tide: the Island holds water up to what it tells, the battery's charge (or the hour gone, or the day), the time
// over it. At rest the water lies still; when the charger goes in it rises from empty to the charge and rolls once,
// and under the pointer it sloshes and settles. Low, it turns the danger colour; charging, green
// (iris.bar.faces.tide).
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    // The water is the body's own: a song's wings ride over it (IrisIsland.faceWings).
    readonly property bool edge: true
    readonly property real d: IrisStyle.density
    readonly property var options: Config.options?.iris?.bar?.faces?.tide ?? ({})
    readonly property real pad: Math.round(16 * root.d)
    readonly property real gap: Math.round(8 * root.d)

    // What the water stands at.
    readonly property string fill: {
        const asked = String(root.options.fill ?? "battery")
        return asked === "battery" && !Battery.available ? "hour" : asked
    }
    readonly property date now: DateTime.clock.date
    readonly property real level: Math.max(0, Math.min(1, Number(Battery.percentage)))
    readonly property real share: root.fill === "battery" ? root.level
        : root.fill === "day" ? (root.now.getHours() * 60 + root.now.getMinutes()) / 1440
        : root.now.getMinutes() / 60
    readonly property bool charging: root.fill === "battery" && Battery.isCharging
    readonly property bool low: root.fill === "battery" && !Battery.isCharging && (Battery.isLow || root.level < 0.15)
    readonly property bool nothingLook: root.island?.nothingLook ?? false
    readonly property color tone: root.nothingLook ? IrisStyle.text
        : root.low ? IrisStyle.danger : root.charging ? IrisStyle.identity.green : IrisStyle.accent

    // The charge in figures beside the time, only while charging and only when the Island has room for it.
    readonly property bool figureWanted: root.charging && root.options.figure !== false
    readonly property real bare: clock.implicitWidth + 2 * root.pad
    readonly property bool figureFits: root.bare + root.gap + figure.implicitWidth <= (root.island?.faceRoom ?? Infinity)
    readonly property bool figureShown: root.figureWanted && root.figureFits
    readonly property real contentWidth: root.bare + (root.figureShown ? root.gap + figure.implicitWidth : 0)

    // The level rises on a spring; a slosh is a swell that dies away while the surface rolls on.
    IrisSpring { id: levelSpring; surface: "island"; intent: "move"; to: root.share; minimum: 0 }
    IrisSpring { id: swell; surface: "island"; intent: "move"; to: 0; minimum: 0 }
    property real phase: 0
    NumberAnimation {
        id: roll
        target: root
        property: "phase"
        duration: IrisStyle.duration(1600)
        easing.type: Easing.OutCubic
    }
    function slosh(fromEmpty: bool): void {
        if (!IrisStyle.motionEnabled) return
        if (fromEmpty) {
            levelSpring.value = 0
            levelSpring.kick()
        }
        swell.value = 1
        swell.kick()
        roll.from = root.phase
        roll.to = root.phase + 3 * Math.PI
        roll.restart()
    }
    onChargingChanged: if (root.charging) root.slosh(true)
    HoverHandler {
        id: hover
        onHoveredChanged: if (hovered) root.slosh(false)
    }

    // The glass the water sits in: just inside the body's edge.
    readonly property real inset: Math.round(3 * root.d)
    readonly property real glassTop: root.inset
    readonly property real glassBottom: root.height - root.inset
    readonly property real r: (root.glassBottom - root.glassTop) / 2
    readonly property real cy: root.height / 2
    readonly property real cxLeft: root.inset + root.r
    readonly property real cxRight: root.width - root.inset - root.r
    function edgeAt(x: real): real {
        const off = x < root.cxLeft ? root.cxLeft - x : x > root.cxRight ? x - root.cxRight : 0
        return Math.sqrt(Math.max(0, root.r * root.r - off * off))
    }
    // The water's surface: still at rest (a hair of wave so it reads as water), rolling while a swell lasts.
    readonly property real waterline: root.glassBottom - levelSpring.value * (root.glassBottom - root.glassTop)
    readonly property real amplitude: (0.7 + 2.6 * swell.value) * root.d
    function surfaceAt(x: real): real {
        const span = Math.max(1, root.width - 2 * root.inset)
        return root.waterline + root.amplitude * Math.sin((x - root.inset) / span * 4 * Math.PI + root.phase)
    }
    readonly property var outline: {
        const steps = 48
        const tops = [], bottoms = [], line = []
        for (let i = 0; i <= steps; i++) {
            const x = root.inset + (root.width - 2 * root.inset) * i / steps
            const half = root.edgeAt(x)
            const ceiling = root.cy - half, floor = root.cy + half
            const wave = root.surfaceAt(x)
            tops.push(Qt.point(x, Math.min(floor, Math.max(ceiling, wave))))
            bottoms.push(Qt.point(x, floor))
            if (wave > ceiling + 0.5 && wave < floor - 0.5)
                line.push(Qt.point(x, wave))
        }
        return { body: tops.concat(bottoms.reverse()), line: line }
    }

    Shape {
        anchors.fill: parent
        visible: levelSpring.value > 0.004
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0
                y1: root.waterline
                x2: 0
                y2: root.glassBottom
                GradientStop { position: 0; color: Qt.alpha(root.tone, root.nothingLook ? 0.16 : 0.3) }
                GradientStop { position: 1; color: Qt.alpha(root.tone, root.nothingLook ? 0.26 : 0.5) }
            }
            PathPolyline { path: root.outline.body }
        }
        // The surface catches the light.
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.outline.line.length > 1 ? Qt.alpha(root.tone, 0.9) : "transparent"
            strokeWidth: Math.max(1.5, Math.round(1.5 * root.d))
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: root.outline.line }
        }
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
        color: IrisStyle.text
        font.pixelSize: Math.round(13 * root.d)
        font.weight: IrisStyle.weight(Font.Bold)
        font.features: ({ "tnum": 1 })
    }
}
