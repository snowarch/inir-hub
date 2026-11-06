pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.bar.island

// Aura: the Island ringed in the spectrum, as a phone's edge lights when its assistant listens; the time in the
// middle. The colours stand still at rest and turn once round while the pointer is over the Island. The colours and
// the turn are the person's (iris.bar.faces.aura).
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    // The ring is the body's edge: a song's wings ride inside it (IrisIsland.faceWings).
    readonly property bool edge: true
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    readonly property real contentWidth: clock.implicitWidth + Math.round(26 * root.d)
    readonly property real line: Math.max(1.5, Math.round(2 * root.d))
    property real turn: 30
    readonly property var options: Config.options?.iris?.bar?.faces?.aura ?? ({})
    // Five stops round the ring; the sixth closes it on the first.
    readonly property var palette: IrisStyle.islandLight(String(root.options.colours ?? "spectrum"), DateTime.clock.date.getHours())
    readonly property bool hovered: aura.hovered

    HoverHandler { id: aura }
    NumberAnimation on turn {
        running: root.hovered && IrisStyle.motionEnabled && root.options.turns !== false
        from: root.turn
        to: root.turn + 360
        duration: 2400
        loops: 1
    }

    IslandRim {
        anchors.fill: parent
        line: root.line
        halo: 0.28
        angle: root.turn
        stops: [[0, root.palette[0]], [0.2, root.palette[1]], [0.4, root.palette[2]], [0.6, root.palette[3]], [0.8, root.palette[4]], [1, root.palette[0]]]
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
