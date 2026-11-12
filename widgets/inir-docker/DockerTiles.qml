import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.services
import "docker.js" as Docker

// The tile grid layout: two visual cards per row.

GridLayout {
    id: root

    property var backend
    property real scaleFactor: 1
    property color ink: "white"
    property color accent: "white"
    property string numbersFamily: ""

    columns: 2
    columnSpacing: Math.round(8 * root.scaleFactor)
    rowSpacing: Math.round(8 * root.scaleFactor)

    function tileColor(status): color {
        if (status === "running") return Appearance.colors.colPrimary
        if (status === "exited") return Appearance.colors.colError
        return ColorUtils.applyAlpha(root.ink, 0.55)
    }

    function barColor(percent): color {
        if (percent >= 85) return Appearance.colors.colError
        return root.accent
    }

    Repeater {
        model: root.backend.shown
        delegate: DockerTile {
            required property var modelData

            Layout.fillWidth: true
            Layout.preferredWidth: Math.round(190 * root.scaleFactor)

            name: modelData.name
            statusText: root.backend.statusLabel(modelData.status)
            statusIcon: root.backend.statusIcon(modelData.status)
            statusColor: root.tileColor(modelData.status)
            cpuText: modelData.cpuPercent.length > 0 ? modelData.cpuPercent : "—"
            cpuPercent: root.backend.percentOf(modelData.cpuPercent)
            cpuColor: root.barColor(root.backend.percentOf(modelData.cpuPercent))
            memText: modelData.memUsageBytes > 0 ? Docker.formatBytes(modelData.memUsageBytes) : "—"
            memPercent: root.backend.percentOf(modelData.memPercent)
            memColor: root.barColor(root.backend.percentOf(modelData.memPercent))
            selected: root.backend.selectedId === modelData.fullId
            scaleFactor: root.scaleFactor
            ink: root.ink
            accent: root.accent
            numbersFamily: root.numbersFamily
            onClicked: root.backend.selectContainer(modelData)
        }
    }
}
