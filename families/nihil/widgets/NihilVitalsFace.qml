pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.nihil.style

// How hard the machine is working: one line for each part, its figure lit past nine tenths.
NihilWidgetFace {
    id: root

    readonly property var parts: {
        const list = [
            { name: Translation.tr("Processor"), level: ResourceUsage.cpuUsage, note: ResourceUsage.cpuTemp > 0 ? `${ResourceUsage.cpuTemp}°` : "" },
            { name: Translation.tr("Memory"), level: ResourceUsage.memoryUsedPercentage, note: "" }
        ]
        if (ResourceUsage.gpuUsage > 0 || ResourceUsage.gpuTemp > 0)
            list.push({ name: Translation.tr("Graphics"), level: ResourceUsage.gpuUsage, note: ResourceUsage.gpuTemp > 0 ? `${ResourceUsage.gpuTemp}°` : "" })
        if (root.large && ResourceUsage.swapTotal > 0)
            list.push({ name: Translation.tr("Swap"), level: ResourceUsage.swapUsedPercentage, note: "" })
        return root.small ? list.slice(0, 2) : list
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        spacing: root.dp(root.small ? 8 : 12)

        Repeater {
            model: root.parts

            delegate: Column {
                id: part
                required property var modelData
                readonly property bool high: part.modelData.level >= 0.9

                width: parent.width
                spacing: root.dp(4)

                Item {
                    width: parent.width
                    height: percent.implicitHeight

                    NLabel {
                        anchors.left: parent.left
                        anchors.right: percent.left
                        anchors.rightMargin: root.dp(8)
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: root.dp(3)
                        text: part.modelData.note.length > 0 ? `${part.modelData.name}   ${part.modelData.note}` : part.modelData.name
                    }
                    NDisplay {
                        id: percent
                        anchors.right: parent.right
                        text: String(Math.round(part.modelData.level * 100)).padStart(2, "0")
                        bloom: part.high ? 0.8 : 0.3
                        size: root.dp(root.small ? 22 : 28)
                        color: part.high ? NihilStyle.live : NihilStyle.ink
                    }
                }
                FaceBar {
                    width: parent.width
                    level: part.modelData.level
                    tint: NihilStyle.accent
                }
            }
        }
    }
}
