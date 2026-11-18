import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// The machine's state on one tile: the network, the sound and the charge drawn as strokes. It opens Control.
NButton {
    id: root

    readonly property real volume: Audio.value ?? 0
    readonly property bool muted: Audio.sink?.audio?.muted ?? false

    width: row.implicitWidth + NihilStyle.s(26)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: NihilStyle.s(12)

        NIcon {
            anchors.verticalCenter: parent.verticalCenter
            size: NihilStyle.s(19)
            text: Network.wifiEnabled || Network.ethernet ? (Network.ethernet ? "lan" : "wifi") : "wifi_off"
            color: root.ink
        }
        NIcon {
            anchors.verticalCenter: parent.verticalCenter
            size: NihilStyle.s(19)
            text: root.muted || root.volume <= 0 ? "volume_off" : root.volume < 0.4 ? "volume_down" : "volume_up"
            color: root.ink
        }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            visible: Battery.available
            spacing: NihilStyle.s(6)
            NTicks {
                anchors.verticalCenter: parent.verticalCenter
                width: NihilStyle.s(34)
                height: NihilStyle.s(16)
                count: 8
                level: Battery.percentage
                litColor: Battery.isLow && !Battery.isCharging ? NihilStyle.accent : root.ink
            }
            NText {
                anchors.verticalCenter: parent.verticalCenter
                figures: true
                text: Math.round(Battery.percentage * 100)
                font.pixelSize: NihilStyle.textSmall
                font.weight: Font.Bold
                color: root.ink
            }
        }
    }
}
