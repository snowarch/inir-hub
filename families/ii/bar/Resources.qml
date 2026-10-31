import qs.modules.common.widgets
import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options?.material?.bar?.borderless ?? false
    property bool alwaysShowAllResources: false
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: true

    property QtObject resourceMonitor: ResourceUsageMonitor { target: root }

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            shown: Config.options?.material?.bar?.resources?.showMemoryIndicator ?? true
            warningThreshold: Config.options?.resources?.memoryWarningThreshold ?? 90
        }

        Resource {
            iconName: "thermostat"
            percentage: ResourceUsage.tempPercentage
            shown: (Config.options?.material?.bar?.resources?.showTempIndicator ?? true) &&
                ((Config.options?.material?.bar?.resources?.alwaysShowTemp ?? true) || 
                    !MprisController.activePlayer ||
                    root.alwaysShowAllResources)
            Layout.leftMargin: shown ? 6 : 0
            cautionThreshold: Config.options?.resources?.tempCautionThreshold ?? 65
            warningThreshold: Config.options?.resources?.tempWarningThreshold ?? 80
        }

        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: (Config.options?.material?.bar?.resources?.showCpuIndicator ?? true) &&
                ((Config.options?.material?.bar?.resources?.alwaysShowCpu ?? true) || 
                    !(MprisController.titleOf(MprisController.activePlayer)?.length > 0) ||
                    root.alwaysShowAllResources)
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options?.resources?.cpuWarningThreshold ?? 90
        }

        Resource {
            iconName: "memory_alt"
            percentage: ResourceUsage.gpuUsage
            shown: (Config.options?.material?.bar?.resources?.showGpuIndicator ?? true) &&
                ((Config.options?.material?.bar?.resources?.alwaysShowGpu ?? true) || 
                    !(MprisController.titleOf(MprisController.activePlayer)?.length > 0) ||
                    root.alwaysShowAllResources)
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options?.resources?.gpuWarningThreshold ?? 90
        }

    }

    ResourcesPopup {
        hoverTarget: root
    }
}
