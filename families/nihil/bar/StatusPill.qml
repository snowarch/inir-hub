import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// The status at the bar's right: sound, the battery as a small cell (the charge filled in), the time in figures.
NButton {
    id: root

    readonly property real volume: Audio.value ?? 0
    readonly property bool muted: Audio.sink?.audio?.muted ?? false

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
        NText {
            anchors.verticalCenter: parent.verticalCenter
            mono: true
            text: DateTime.timeDisplay
            font.pixelSize: NihilStyle.textBody
        }
    }
}
