import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// A long page's foot, read in parts: the next part as a large card named by its first group (the rest small under
// it), the part before a quiet capsule at its side. The last part offers the first again, so it never ends on nothing.
Item {
    id: root
    property string previous: ""
    property string next: ""
    property string first: ""
    // The other groups the next part holds, named small under its first.
    property var then: []
    property int position: 1
    property int count: 1
    signal pick(string title)

    readonly property string ahead: root.next.length > 0 ? root.next : root.first
    implicitHeight: PrismTheme.dp(104)

    // Back one group: a capsule with its chevron and name.
    Item {
        id: back
        visible: root.previous.length > 0
        width: visible ? Math.min(PrismTheme.dp(260), root.width * 0.3) : 0
        height: parent.height
        Rectangle {
            anchors.fill: parent
            radius: PrismTheme.dp(24)
            color: backArea.pressed ? PrismTheme.fillPress : backArea.containsMouse ? PrismTheme.fillHover : PrismTheme.fill
            scale: backArea.pressed ? 0.98 : 1
            Behavior on color { ColorAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
        }
        PrismGlyph {
            id: backGlyph
            x: PrismTheme.dp(16)
            anchors.verticalCenter: parent.verticalCenter
            text: "chevron_left"
            iconSize: PrismTheme.dp(20)
            color: PrismTheme.ink2
        }
        Column {
            anchors.left: backGlyph.right
            anchors.leftMargin: PrismTheme.dp(6)
            anchors.right: parent.right
            anchors.rightMargin: PrismTheme.dp(18)
            anchors.verticalCenter: parent.verticalCenter
            spacing: PrismTheme.dp(2)
            PrismText {
                text: Translation.tr("Previous")
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.small
            }
            PrismText {
                width: parent.width
                text: Translation.tr(root.previous)
                elide: Text.ElideRight
                font.pixelSize: PrismTheme.row
                font.weight: Font.DemiBold
            }
        }
        MouseArea {
            id: backArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Link
            Accessible.name: Translation.tr(root.previous)
            onClicked: root.pick(root.previous)
        }
    }

    // Ahead: the next group's name large, how many settings wait in it, the solid circle that goes.
    Item {
        anchors.left: back.visible ? back.right : parent.left
        anchors.leftMargin: back.visible ? PrismTheme.dp(10) : 0
        anchors.right: parent.right
        height: parent.height
        Rectangle {
            anchors.fill: parent
            radius: PrismTheme.dp(24)
            color: aheadArea.pressed ? PrismTheme.fillPress : aheadArea.containsMouse ? PrismTheme.fillHover : PrismTheme.raised
            scale: aheadArea.pressed ? 0.99 : 1
            Behavior on color { ColorAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
        }
        Column {
            anchors.left: parent.left
            anchors.leftMargin: PrismTheme.dp(24)
            anchors.right: go.left
            anchors.rightMargin: PrismTheme.dp(16)
            anchors.verticalCenter: parent.verticalCenter
            spacing: PrismTheme.dp(3)
            PrismText {
                width: parent.width
                text: root.next.length > 0
                    ? Translation.tr("Next") + "  ·  " + String(root.position + 1).padStart(2, "0") + " / " + String(root.count).padStart(2, "0")
                    : Translation.tr("Back to the start")
                figures: true
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.small
            }
            PrismText {
                width: parent.width
                text: Translation.tr(root.ahead)
                elide: Text.ElideRight
                font.pixelSize: PrismTheme.head
                font.weight: Font.Bold
                font.letterSpacing: -0.2
            }
            PrismText {
                width: parent.width
                visible: root.next.length > 0 && root.then.length > 0
                text: root.then.join("  ·  ")
                elide: Text.ElideRight
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.small
            }
        }
        PrismRound {
            id: go
            anchors.right: parent.right
            anchors.rightMargin: PrismTheme.dp(22)
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: PrismTheme.dp(40)
            solid: true
            glyph: root.next.length > 0 ? "arrow_forward" : "first_page"
            glyphSize: PrismTheme.dp(20)
            onClicked: root.pick(root.ahead)
        }
        MouseArea {
            id: aheadArea
            anchors.fill: parent
            anchors.rightMargin: PrismTheme.dp(70)
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Link
            Accessible.name: Translation.tr(root.ahead)
            onClicked: root.pick(root.ahead)
        }
    }
}
