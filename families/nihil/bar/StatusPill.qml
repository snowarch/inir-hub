import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// The status at the bar's right: sound, the battery as a small cell (the charge filled in), the time in figures.
NButton {
    id: root

    readonly property real volume: Audio.value ?? 0
    readonly property bool muted: Audio.sink?.audio?.muted ?? false
    readonly property int notices: Notifications.list.length
    // The time leads to Today (the month and the notifications); the rest of the pill to Control.
    signal timeTapped()

    width: row.implicitWidth + NihilStyle.s(40)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: NihilStyle.s(16)

        NIcon {
            anchors.verticalCenter: parent.verticalCenter
            size: NihilStyle.s(20)
            text: root.muted || root.volume <= 0 ? "volume_off" : root.volume < 0.4 ? "volume_down" : "volume_up"
        }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            visible: Battery.available
            spacing: NihilStyle.s(1)
            Rectangle {
                width: NihilStyle.s(22)
                height: NihilStyle.s(11)
                radius: NihilStyle.s(3)
                color: "transparent"
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: NihilStyle.ink
                    opacity: 0.28
                }
                Rectangle {
                    x: NihilStyle.s(2); y: NihilStyle.s(2)
                    height: parent.height - NihilStyle.s(4)
                    width: Math.max(NihilStyle.s(2), (parent.width - NihilStyle.s(4)) * Battery.percentage)
                    radius: NihilStyle.s(1.5)
                    color: Battery.isLow && !Battery.isCharging ? NihilStyle.accent : NihilStyle.ink
                }
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: NihilStyle.s(2); height: NihilStyle.s(5); radius: 1
                color: NihilStyle.ink
                opacity: 0.4
            }
        }
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: clock.implicitWidth + (root.notices > 0 ? NihilStyle.s(14) : 0)
            height: root.height
            Behavior on width { NumberAnimation { duration: NihilStyle.quick } }
            NText {
                id: clock
                anchors.verticalCenter: parent.verticalCenter
                figures: true
                text: DateTime.timeDisplay
                font.pixelSize: NihilStyle.textBody
                color: NihilState.todayOpen ? NihilStyle.accent : NihilStyle.ink
            }
            Rectangle {
                visible: root.notices > 0
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                width: NihilStyle.s(7); height: width; radius: width / 2
                color: Notifications.silent ? NihilStyle.inkSoft : NihilStyle.accent
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -NihilStyle.s(8)
                cursorShape: Qt.PointingHandCursor
                onClicked: root.timeTapped()
            }
        }
    }
}
