pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.bar.island

// Lumen: the Island's rim lit from below in two colours, as a lamp under glass, and a little of that light pooled at
// its foot. The light says something: the battery (its colour, and how far up the sides it climbs), the hour's sky,
// or a palette. Under the pointer, and once when the charger goes in, it climbs the whole rim (iris.bar.faces.lumen).
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
    readonly property real reach: hover.hovered || surge.running ? 0.5 : root.rest
    // The light climbs on a spring, so a pointer that leaves mid-climb turns it back from where it stands.
    IrisSpring { id: reachSpring; surface: "island"; intent: "move"; to: root.reach; minimum: 0 }
    readonly property real shownReach: reachSpring.value
    // Plugged in, the light runs up the whole rim once and settles at the charge: the charger took.
    readonly property bool charging: Battery.isCharging
    onChargingChanged: if (root.charging && root.light === "battery" && IrisStyle.motionEnabled) surge.restart()
    PauseAnimation { id: surge; duration: IrisStyle.duration(900) }
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
    IslandRim {
        anchors.fill: parent
        line: root.line
        halo: 0.32
        // From the foot (270 degrees) round by the right side, the top, the left side and home.
        angle: 270
        stops: [[0, root.foot], [Math.max(0.01, root.shownReach * 0.55), Qt.alpha(root.pair[1], 0.85)],
            [Math.min(0.499, root.shownReach), Qt.alpha(root.pair[1], 0)], [Math.max(0.501, 1 - root.shownReach), Qt.alpha(root.pair[0], 0)],
            [Math.min(0.99, 1 - root.shownReach * 0.55), Qt.alpha(root.pair[0], 0.85)], [1, root.foot]]
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
