import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// Restore defaults acts at once and says so with an Undo, never a question first.
Rectangle {
    id: root
    readonly property bool live: PrismModel.undo !== null
    implicitWidth: row.implicitWidth + PrismTheme.dp(28)
    implicitHeight: PrismTheme.dp(44)
    radius: height / 2
    color: PrismTheme.solid
    opacity: root.live ? 1 : 0
    visible: opacity > 0
    scale: root.live ? 1 : 0.94
    Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(200) } }
    Behavior on scale { NumberAnimation { duration: PrismTheme.ms(260); easing.type: Easing.OutBack } }

    // It goes by itself after a while, never while the pointer rests on it; the change stays.
    HoverHandler { id: hover }
    Timer {
        running: root.live && !hover.hovered
        interval: 6000
        onTriggered: PrismModel.undo = null
    }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: PrismTheme.dp(14)
        PrismText {
            anchors.verticalCenter: parent.verticalCenter
            text: Translation.tr("%1 settings back to their defaults").arg(PrismModel.undo?.steps?.length ?? 0)
            color: PrismTheme.inkSolid
            font.pixelSize: PrismTheme.body
        }
        PrismText {
            anchors.verticalCenter: parent.verticalCenter
            text: Translation.tr("Undo")
            color: PrismTheme.accent
            font.pixelSize: PrismTheme.body
            font.weight: Font.Bold
            MouseArea {
                anchors.fill: parent
                anchors.margins: -PrismTheme.dp(8)
                cursorShape: Qt.PointingHandCursor
                onClicked: PrismModel.undoRestore()
            }
        }
    }
}
