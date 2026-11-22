pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

WBarAttachedPanelContent {
    id: root

    property Timer timer: Timer {
        id: autoCloseTimer
        running: true
        interval: Config.options?.osd?.timeout ?? 3000
        repeat: false
        onTriggered: root.close()
    }

    Connections {
        target: KeyboardIndicators
        function onPopupSequenceChanged() {
            autoCloseTimer.restart()
        }
    }

    contentItem: WPane {
        radius: height / 2
        screenX: root.panelScreenX + root.visualMargin
        screenY: root.panelScreenY + root.visualMargin
        screenWidth: root._screenW
        screenHeight: root._screenH
        contentItem: Item {
            implicitWidth: Math.max(Looks.dp(160), contentRow.implicitWidth + Looks.dp(32))
            implicitHeight: Looks.dp(56)

            RowLayout {
                id: contentRow
                anchors.fill: parent
                anchors.leftMargin: Looks.dp(10)
                anchors.rightMargin: Looks.dp(22)
                spacing: Looks.dp(12)

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: Looks.dp(36)
                    implicitHeight: Looks.dp(36)
                    radius: height / 2
                    color: Qt.alpha(Looks.colors.accent, Looks.dark ? 0.24 : 0.16)

                    FluentIcon {
                        anchors.centerIn: parent
                        icon: KeyboardIndicators.popupFluentIcon
                        implicitSize: Looks.dp(18)
                        color: Looks.colors.accent
                    }
                }

                WText {
                    Layout.fillWidth: true
                    text: KeyboardIndicators.popupText
                    font.pixelSize: Looks.font.pixelSize.large
                    font.weight: Looks.font.weight.strong
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }
    }
}
