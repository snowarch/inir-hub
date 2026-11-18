pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import "../state"

ColumnLayout {
    id: root
    readonly property real d: ConnectStyle.density
    spacing: Math.round(6 * root.d)
    implicitHeight: titleText.implicitHeight + grid.implicitHeight + spacing

    StyledText {
        id: titleText
        text: Translation.tr("DEVICE STATUS")
        color: ConnectStyle.subtext
        font.family: ConnectStyle.fontLabel
        font.pixelSize: Math.max(9, Math.round(10 * root.d))
        font.weight: ConnectStyle.weight(Font.Bold)
        font.letterSpacing: 0.8
    }

    GridLayout {
        id: grid
        Layout.fillWidth: true
        Layout.fillHeight: true
        columns: 3
        columnSpacing: Math.round(6 * root.d)
        rowSpacing: Math.round(6 * root.d)

        Repeater {
            model: [
                {
                    icon: AndroidState.isCharging ? "battery_charging_full" : "battery_full",
                    tint: AndroidState.batteryLevel >= 0 ? ConnectStyle.success : ConnectStyle.gray,
                    label: Translation.tr("Battery"),
                    value: AndroidState.batteryLevel >= 0 ? `${AndroidState.batteryLevel}%` : "—"
                },
                {
                    icon: "cell_tower",
                    tint: AndroidState.connected ? ConnectStyle.accent : ConnectStyle.gray,
                    label: Translation.tr("Network"),
                    value: AndroidState.networkType
                },
                {
                    icon: "signal_cellular_alt",
                    tint: AndroidState.connected ? ConnectStyle.secondaryAccent : ConnectStyle.gray,
                    label: Translation.tr("Signal"),
                    value: Translation.tr(AndroidState.signalQuality)
                }
            ]

            delegate: ConnectPlate {
                id: card
                required property var modelData
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                Layout.minimumHeight: Math.round(46 * root.d)
                implicitHeight: Math.round(48 * root.d)
                radius: ConnectStyle.radiusTile
                color: cardMouse.containsMouse ? ConnectStyle.fillHover : ConnectStyle.formPlate
                Behavior on color { ColorAnimation { duration: ConnectStyle.feedbackDuration } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Math.round(8 * root.d)
                    anchors.rightMargin: Math.round(8 * root.d)
                    spacing: Math.round(7 * root.d)

                    ConnectSquircle {
                        Layout.preferredWidth: Math.round(26 * root.d)
                        Layout.preferredHeight: Math.round(26 * root.d)
                        glyph: card.modelData.icon
                        tint: card.modelData.tint
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            width: parent.width
                            elide: Text.ElideRight
                            text: card.modelData.label
                            color: ConnectStyle.subtext
                            font.family: ConnectStyle.fontMain
                            font.pixelSize: Math.max(9, Math.round(10 * root.d))
                        }

                        StyledText {
                            width: parent.width
                            elide: Text.ElideRight
                            text: card.modelData.value
                            color: ConnectStyle.text
                            font.family: ConnectStyle.fontTitle
                            font.pixelSize: ConnectStyle.typeMeta
                            font.weight: ConnectStyle.weight(Font.Bold)
                        }
                    }
                }

                MouseArea {
                    id: cardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }
        }
    }
}
