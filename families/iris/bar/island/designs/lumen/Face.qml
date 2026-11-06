pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// Lumen: the Island's rim lit from below in two colours, as a lamp under glass, and a little of that light pooled at
// its foot. The light says something: the battery (its colour, and how far up the sides it climbs), the hour's sky,
// or a palette. Under the pointer it climbs the whole rim (iris.bar.faces.lumen).
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    // The rim is the body's edge: a song's wings ride inside it (IrisIsland.faceWings).
    readonly property bool edge: true
    readonly property real d: IrisStyle.density
    readonly property real contentWidth: clock.implicitWidth + Math.round(30 * root.d)
    readonly property real line: Math.max(1.5, Math.round(2 * root.d))
    readonly property var options: Config.options?.iris?.bar?.faces?.lumen ?? ({})
    readonly property string light: {
        const asked = String(root.options.light ?? "battery")
        return asked === "battery" && !Battery.available ? "sky" : asked
    }
    readonly property real level: Math.max(0, Math.min(1, Number(Battery.percentage)))
    readonly property var pair: {
        const id = IrisStyle.identity
        if (root.light === "battery") {
            if (Battery.isCharging) return [id.green, id.sky]
            if (Battery.isLow || root.level < 0.2) return [id.red, id.orange]
            if (root.level < 0.5) return [id.yellow, id.orange]
            return [id.green, id.teal]
        }
        const stops = IrisStyle.islandLight(root.light === "sky" ? "day" : root.light, DateTime.clock.date.getHours())
        return [stops[0], stops[2]]
    }
    // How far up the sides the light climbs, as a share of the turn from the foot (half reaches the top): the battery's
    // charge when it tells the battery.
    readonly property real rest: root.light === "battery" ? 0.12 + 0.3 * root.level : 0.34
    readonly property real reach: hover.hovered ? 0.5 : root.rest
    property real shownReach: root.reach
    Behavior on shownReach { NumberAnimation { duration: IrisStyle.duration(420); easing.type: Easing.OutCubic } }
    readonly property color foot: Qt.tint(root.pair[0], Qt.alpha(root.pair[1], 0.5))

    HoverHandler { id: hover }

    // The light pooled at the foot, inside the body.
    Rectangle {
        anchors.fill: parent
        anchors.margins: Math.round(2 * root.d)
        radius: height / 2
        visible: root.options.pool !== false
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.alpha(root.foot, 0.24) }
        }
    }
    Repeater {
        model: [{ inset: 0, alpha: 0.32, width: 5 }, { inset: 1.5, alpha: 1, width: 1 }]
        Shape {
            id: rim
            required property var modelData
            readonly property real gap: Math.round(rim.modelData.inset * root.d)
            readonly property real thick: root.line * rim.modelData.width
            anchors.fill: parent
            anchors.margins: Math.round(2 * root.d)
            opacity: rim.modelData.alpha
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "transparent"
                fillRule: ShapePath.OddEvenFill
                // From the foot (270 degrees) round by the right side, the top, the left side and home.
                fillGradient: ConicalGradient {
                    centerX: rim.width / 2
                    centerY: rim.height / 2
                    angle: 270
                    GradientStop { position: 0.0; color: root.foot }
                    GradientStop { position: Math.max(0.01, root.shownReach * 0.55); color: Qt.alpha(root.pair[1], 0.85) }
                    GradientStop { position: Math.min(0.499, root.shownReach); color: Qt.alpha(root.pair[1], 0) }
                    GradientStop { position: Math.max(0.501, 1 - root.shownReach); color: Qt.alpha(root.pair[0], 0) }
                    GradientStop { position: Math.min(0.99, 1 - root.shownReach * 0.55); color: Qt.alpha(root.pair[0], 0.85) }
                    GradientStop { position: 1.0; color: root.foot }
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
    IrisClock {
        id: clock
        anchors.centerIn: parent
        family: IrisStyle.figureFace(pixelSize)
        minorFamily: family
        pixelSize: root.island?.figureSize ?? IrisStyle.typeHeadline
        separatorColor: root.island?.clockAccent ?? IrisStyle.accent
    }
}
