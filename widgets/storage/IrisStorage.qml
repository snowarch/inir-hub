pragma ComponentBehavior: Bound

// The desktop card in iRiS (the widget design "iRiS"): the family's plate, glass and ink. The head says what is left on
// the drive it leads with; the bars below hold every drive. Small: the lead drive alone. Medium: up to three.
// Large: up to six, under what is left on all of them.
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.widgets

IrisWidgetFace {
    id: root

    readonly property var card: root.widget
    readonly property color live: root.nothing ? root.signal : root.accent
    readonly property bool drawn: root.card.emptyText.length === 0
    readonly property var shown: root.small ? (root.card.leadDrive ? [root.card.leadDrive] : []) : root.card.drivesFor(root.large ? 6 : 3)

    ColumnLayout {
        anchors.fill: parent
        spacing: root.dp(8)
        FaceHeader {
            face: root
            Layout.fillWidth: true
            glyph: "hard_drive"
            text: Translation.tr("Storage")
            trailing: !root.small && root.drawn ? root.card.countText : ""
            tint: root.live
        }
        // What is left, big: on the lead drive (small), on all of them (large), the word small beside it.
        Row {
            Layout.fillWidth: true
            visible: root.drawn && !root.medium
            spacing: root.dp(6)
            FaceText {
                id: big
                face: root
                text: root.large ? root.card.totalFree : root.card.leadFree
                size: root.large ? 34 : 26
                weight: Font.Bold
                font.family: root.fontNumbers
            }
            FaceText {
                face: root
                anchors.baseline: big.baseline
                text: root.card.freeWord
                color: root.inkSecondary
                size: 13
            }
        }
        StorageBars {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.drawn
            drives: root.shown
            leading: root.card.leadIn(root.shown)
            d: root.k
            t: root.t
            fontMain: root.fontMain
            fontNumbers: root.fontNumbers
            nameSize: 13
            figureSize: 12
            ink: root.ink
            inkMuted: root.inkSecondary
            track: root.fillQuiet
            fill: root.inkTertiary
            full: root.danger
            lit: root.live
            systemName: root.card.systemName
            homeName: root.card.homeName
            freeText: root.card.freeText
            sizeText: root.card.sizeText
            figure: root.small ? "size" : "free"
        }
        FaceText {
            face: root
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.drawn
            text: root.card.emptyText
            color: root.inkSecondary
            size: 13
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
