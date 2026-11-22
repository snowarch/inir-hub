pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

WBarAttachedPanelContent {
    id: root

    readonly property var event: DeviceEvents.last

    property Timer timer: Timer {
        id: autoCloseTimer
        running: true
        interval: (Config.options?.osd?.timeout ?? 3000) + 1500
        repeat: false
        onTriggered: root.close()
    }

    Connections {
        target: DeviceEvents
        function onHappened() {
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
            implicitWidth: Math.min(Looks.dp(400), Math.max(Looks.dp(240), contentRow.implicitWidth + Looks.dp(32)))
            implicitHeight: Looks.dp(56)

            RowLayout {
                id: contentRow
                anchors.fill: parent
                anchors.leftMargin: Looks.dp(10)
                anchors.rightMargin: Looks.dp(22)
                spacing: Looks.dp(12)

                Rectangle {
                    readonly property color tone: root.event?.tone === "warn" ? Looks.colors.danger : root.event?.tone === "on" ? Looks.colors.accent : Looks.colors.fg
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: Looks.dp(36)
                    implicitHeight: Looks.dp(36)
                    radius: height / 2
                    color: Qt.alpha(tone, Looks.dark ? 0.2 : 0.14)

                    FluentIcon {
                        anchors.centerIn: parent
                        icon: root.event?.fluentIcon ?? "checkmark"
                        implicitSize: Looks.dp(18)
                        color: parent.tone
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 0

                    WText {
                        Layout.fillWidth: true
                        text: root.event?.title ?? ""
                        font.pixelSize: Looks.font.pixelSize.normal
                        font.weight: Looks.font.weight.strong
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                    WText {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: root.event?.detail ?? ""
                        color: Looks.colors.subfg
                        font.pixelSize: Looks.font.pixelSize.small
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }

                WText {
                    visible: (root.event?.value ?? -1) >= 0
                    text: (root.event?.value ?? 0) + "%"
                    font.pixelSize: Looks.font.pixelSize.small
                    font.weight: Looks.font.weight.strong
                }
            }
        }
    }
}
