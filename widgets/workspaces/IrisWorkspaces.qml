pragma ComponentBehavior: Bound

// The desktop card in iRiS (the widget design "iRiS"): the family's plate, glass and ink. The lanes lead; the head
// counts what is open. Small: three lanes of icons. Medium: three with their numbers and the apps named where a
// window is wide enough. Large: up to six.
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.widgets

IrisWidgetFace {
    id: root

    readonly property var card: root.widget
    readonly property color live: root.nothing ? root.signal : root.accent

    component Lanes: WorkspaceLanes {
        d: root.k
        t: root.t
        steerable: root.card.steerable
        fontNumbers: root.fontNumbers
        fontMain: root.fontMain
        feedback: IrisStyle.feedbackDuration
        numberSize: 13
        wordSize: 11
        ink: root.ink
        inkMuted: root.inkTertiary
        number: root.inkTertiary
        numberActive: root.live
        well: root.fillQuiet
        wellHover: root.fill
        wellActive: root.fill
        tile: root.fillActive
        tileHover: IrisStyle.trackOf(root.ink)
        tileHere: IrisStyle.trackOf(root.ink)
        lit: root.live
        onLit: root.onFill(root.live)
        radius: 12
    }
    component Words: FaceText {
        face: root
        text: root.card.emptyText
        color: root.inkSecondary
        size: 13
        wrapMode: Text.WordWrap
        maximumLineCount: 3
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    readonly property bool drawn: root.card.emptyText.length === 0

    ColumnLayout {
        anchors.fill: parent
        spacing: root.dp(8)
        FaceHeader {
            face: root
            Layout.fillWidth: true
            glyph: "view_week"
            text: Translation.tr("Workspaces")
            trailing: !root.small && root.drawn ? root.card.openText : ""
            tint: root.live
        }
        Lanes {
            id: lanes
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.drawn
            lanes: root.card.lanesFor(root.large ? 6 : 3)
            numberWidth: root.small ? 0 : 18
            maxLane: root.large ? 76 : root.small ? 30 : 36
            icons: root.card.icons
            names: !root.small
        }
        Words {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.drawn
        }
    }
}
