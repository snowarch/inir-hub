pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// Type's head (his 11-18): the three faces iRiS sets, each in its own specimen, a type foundry's sheet: titles as a large
// pair of letters, text as a paragraph, figures as the hour in its weight. Each says which family it is; a press goes to
// the faces.
Item {
    id: root
    signal pickGroup(string title)

    readonly property real gap: PrismTheme.dp(10)
    readonly property bool narrow: root.width < PrismTheme.dp(640)
    readonly property real cardHeight: PrismTheme.dp(200)
    implicitHeight: root.narrow ? root.cardHeight * 2 + root.gap : root.cardHeight

    readonly property string titleFace: IrisStyle.faceTitle
    readonly property string textFace: IrisStyle.faceText
    readonly property string figureFace: IrisStyle.faceFigures
    readonly property var now: DateTime.clock.date

    component Specimen: Rectangle {
        id: card
        property string role: ""
        property string face: ""
        default property alias body: well.data
        radius: PrismTheme.dp(22)
        color: hit.pressed ? PrismTheme.fillPress : hit.containsMouse ? PrismTheme.fillHover : PrismTheme.sunk
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
        Item {
            id: well
            x: PrismTheme.dp(20)
            y: PrismTheme.dp(14)
            width: card.width - PrismTheme.dp(40)
            height: card.height - PrismTheme.dp(14) - foot.height - PrismTheme.dp(16)
        }
        Column {
            id: foot
            x: PrismTheme.dp(20)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: PrismTheme.dp(16)
            width: card.width - PrismTheme.dp(40)
            spacing: PrismTheme.dp(1)
            PrismText {
                width: parent.width
                text: Translation.tr(card.role)
                font.pixelSize: PrismTheme.row
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            PrismText {
                width: parent.width
                text: card.face
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.small
                elide: Text.ElideRight
            }
        }
        MouseArea {
            id: hit
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.pickGroup("Faces")
        }
        Accessible.role: Accessible.Button
        Accessible.name: Translation.tr(card.role) + ", " + card.face
    }

    Grid {
        columns: root.narrow ? 2 : 3
        spacing: root.gap
        readonly property real unit: root.narrow ? (root.width - root.gap) / 2 : (root.width - 2 * root.gap) / 10

        Specimen {
            role: "Titles"
            face: root.titleFace
            width: root.narrow ? parent.unit : parent.unit * 3.6
            height: root.cardHeight
            PrismText {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Aa"
                font.family: root.titleFace
                font.pixelSize: PrismTheme.dp(92)
                font.weight: Font.Bold
                font.letterSpacing: -2
            }
        }
        Specimen {
            role: "Text"
            face: root.textFace
            width: root.narrow ? parent.unit : parent.unit * 3.6
            height: root.cardHeight
            PrismText {
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                text: Translation.tr("Morning light on the desk, the coffee going cold, a song you had forgotten.")
                font.family: root.textFace
                font.pixelSize: PrismTheme.dp(17)
                lineHeight: 1.25
                wrapMode: Text.WordWrap
                maximumLineCount: 4
                elide: Text.ElideRight
            }
        }
        Specimen {
            role: "Figures"
            face: root.figureFace
            width: root.narrow ? root.width : parent.unit * 2.8
            height: root.cardHeight
            PrismText {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatTime(root.now, "hh:mm")
                font.family: root.figureFace
                font.pixelSize: PrismTheme.dp(58)
                font.weight: IrisStyle.figureWeight
                font.letterSpacing: -1.5
            }
        }
    }
}
