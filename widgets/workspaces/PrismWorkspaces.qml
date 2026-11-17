pragma ComponentBehavior: Bound

// The desktop card in Prism (the widget design "Prism" of iRiS): the lanes are the body, the window in focus a white
// tile (the refs' lit key), the head counts what is open. Small: three lanes of icons.
// Medium: three with their numbers and the apps named where a window is wide enough. Large: up to six.
import QtQuick
import qs.services
import qs.modules.iris.style
import qs.modules.iris.widgets
import qs.modules.iris.widgets.prism

PrismFolder {
    id: root

    readonly property var card: root.widget
    readonly property bool drawn: root.card.emptyText.length === 0

    tabGlyph: "view_week"
    tabText: Translation.tr("Workspaces")
    flapText: root.drawn ? (root.small ? String(root.card.open) : root.card.openText) : ""
    flapGlyph: root.drawn && root.small ? "select_window" : ""
    lightPass: root.card.here ? 1 : 0.55

    // The slab gives the lanes its whole body under the head.
    readonly property real lanesTop: root.paneTop + root.pick(2, 2, 4)
    readonly property real lanesBottom: root.footBottom - root.pick(6, 6, 10)

    WorkspaceLanes {
        id: lanes
        visible: root.drawn
        x: root.inset
        y: root.lanesTop
        width: root.innerWidth
        height: root.lanesBottom - root.lanesTop
        d: root.k
        t: root.t
        lanes: root.card.lanesFor(root.large ? 6 : 3)
        steerable: root.card.steerable
        icons: root.card.icons
        names: !root.small
        numberWidth: root.small ? 0 : 18
        numberSize: root.type(12, 12, 13)
        wordSize: root.type(10.5, 11, 12)
        maxLane: root.large ? 76 : root.small ? 30 : 34
        fontNumbers: root.fontNumbers
        fontMain: root.fontMain
        feedback: IrisStyle.feedbackDuration
        ink: root.ink
        inkMuted: root.inkTertiary
        number: root.inkTertiary
        numberActive: root.ink
        well: root.fillQuiet
        wellHover: root.fill
        wellActive: root.fill
        tile: root.fillActive
        tileHover: IrisStyle.trackOf(root.ink)
        tileHere: IrisStyle.trackOf(root.ink)
        lit: root.ink
        onLit: root.onFill(root.ink)
        radius: root.pick(9, 10, 12)
    }
    FaceText {
        visible: !root.drawn
        face: root
        x: root.inset
        y: root.lanesTop
        width: root.innerWidth
        height: root.height - root.inset - root.lanesTop
        text: root.card.emptyText
        color: root.inkSecondary
        size: root.type(12, 13, 14)
        wrapMode: Text.WordWrap
        maximumLineCount: 3
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
