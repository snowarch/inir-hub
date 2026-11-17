pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"

ColumnLayout {
    id: root
    readonly property real d: IrisStyle.density
    spacing: Math.round(6 * root.d)
    implicitHeight: titleText.implicitHeight + grid.implicitHeight + spacing

    IrisText {
        id: titleText
        text: Translation.tr("DEVICE STATUS")
        color: IrisStyle.subtext
        font.family: IrisStyle.fontLabel
        font.pixelSize: Math.max(9, Math.round(10 * root.d))
        font.weight: IrisStyle.weight(Font.Bold)
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
                    tint: AndroidState.batteryLevel >= 0 ? IrisStyle.success : IrisStyle.identity.gray,
                    label: Translation.tr("Battery"),
                    value: AndroidState.batteryLevel >= 0 ? `${AndroidState.batteryLevel}%` : "—"
                },
                {
                    icon: "cell_tower",
                    tint: AndroidState.connected ? IrisStyle.accent : IrisStyle.identity.gray,
                    label: Translation.tr("Network"),
                    value: AndroidState.networkType
                },
                {
                    icon: "signal_cellular_alt",
                    tint: AndroidState.connected ? IrisStyle.secondaryAccent : IrisStyle.identity.gray,
                    label: Translation.tr("Signal"),
                    value: Translation.tr(AndroidState.signalQuality)
                }
            ]

            delegate: IrisPlate {
                id: card
                required property var modelData
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                Layout.minimumHeight: Math.round(46 * root.d)
                implicitHeight: Math.round(48 * root.d)
                radius: IrisStyle.radiusTile
                color: cardMouse.containsMouse ? IrisStyle.fillHover : IrisStyle.formPlate
                Behavior on color { ColorAnimation { duration: IrisStyle.feedbackDuration } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Math.round(8 * root.d)
                    anchors.rightMargin: Math.round(8 * root.d)
                    spacing: Math.round(7 * root.d)

                    IrisSquircle {
                        Layout.preferredWidth: Math.round(26 * root.d)
                        Layout.preferredHeight: Math.round(26 * root.d)
                        glyph: card.modelData.icon
                        tint: card.modelData.tint
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 0

                        IrisText {
                            width: parent.width
                            elide: Text.ElideRight
                            text: card.modelData.label
                            color: IrisStyle.subtext
                            font.pixelSize: Math.max(9, Math.round(10 * root.d))
                        }

                        IrisText {
                            width: parent.width
                            elide: Text.ElideRight
                            text: card.modelData.value
                            color: IrisStyle.text
                            font.family: IrisStyle.fontTitle
                            font.pixelSize: IrisStyle.typeMeta
                            font.weight: IrisStyle.weight(Font.Bold)
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
