pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

Item {
    id: root
    required property string moduleId
    property var targetScreen
    property string slot: ""

    readonly property bool customModule: root.moduleId.startsWith("custom:")
    implicitWidth: root.customModule
        ? (customLoader.item?.implicitWidth ?? 0)
        : (builtInLoader.item?.implicitWidth ?? 0)
    implicitHeight: Math.max(builtInLoader.item?.implicitHeight ?? 0, customLoader.item?.implicitHeight ?? 0)

    Loader {
        id: builtInLoader
        anchors.centerIn: parent
        active: !root.customModule
        sourceComponent: {
            switch (root.moduleId) {
            case "brand": return brandComponent
            case "workspaces": return workspacesComponent
            case "activeWindow": return activeWindowComponent
            case "status": return statusComponent
            case "clock": return clockComponent
            case "controls": return controlsComponent
            default: return null
            }
        }
    }

    Loader {
        id: customLoader
        anchors.centerIn: parent
        active: root.customModule
        source: active ? "IrisCustomModule.qml" : ""
        onLoaded: {
            if (item) {
                item.widgetId = root.moduleId.slice("custom:".length)
                item.slot = root.slot
                item.targetScreen = root.targetScreen
            }
        }
    }

    Component {
        id: brandComponent
        IrisButton {
            id: brandButton
            quiet: true
            implicitWidth: brandRow.implicitWidth + 18 * IrisStyle.density
            implicitHeight: Math.round(30 * IrisStyle.density)
            onClicked: GlobalStates.searchOpen = !GlobalStates.searchOpen

            RowLayout {
                id: brandRow
                anchors.centerIn: parent
                spacing: 7
                IrisMark { implicitSize: 17 * IrisStyle.density }
                IrisText {
                    text: "iRiS"
                    font.family: IrisStyle.fontTitle
                    font.pixelSize: 13 * IrisStyle.typeScale
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                }
            }
        }
    }

    Component {
        id: workspacesComponent
        RowLayout {
            spacing: 1
            readonly property var workspaces: {
                if (!CompositorService.isNiri) return []
                const all = NiriService.allWorkspaces ?? []
                const screenName = root.targetScreen?.name ?? ""
                const onOutput = screenName.length > 0 ? all.filter(ws => ws.output === screenName) : all
                return onOutput.slice(0, 8)
            }

            Repeater {
                model: parent.workspaces
                IrisButton {
                    id: workspaceButton
                    required property var modelData
                    quiet: true
                    implicitWidth: Math.round(28 * IrisStyle.density)
                    implicitHeight: Math.round(28 * IrisStyle.density)
                    onClicked: {
                        if (modelData?.id !== undefined) NiriService.switchToWorkspaceById(modelData.id)
                        else if (modelData?.idx !== undefined) NiriService.switchToWorkspace(modelData.idx)
                    }
                    IrisText {
                        anchors.centerIn: parent
                        text: String(modelData?.idx || "•")
                        font.family: IrisStyle.fontNumbers
                        font.pixelSize: 12 * IrisStyle.typeScale
                        font.weight: (workspaceButton.modelData?.is_active ?? false) ? Font.Bold : Font.Medium
                        color: (workspaceButton.modelData?.is_active ?? false) || workspaceButton.hovered
                            ? IrisStyle.text : IrisStyle.subtext
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: (workspaceButton.modelData?.is_active ?? false) ? 12 * IrisStyle.density : 0
                        height: 2 * IrisStyle.density
                        radius: height / 2
                        color: IrisStyle.accent
                        Behavior on width { NumberAnimation { duration: IrisStyle.duration(180); easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }

    Component {
        id: activeWindowComponent
        Item {
            implicitWidth: Math.min(
                360 * IrisStyle.density,
                Math.max(140, (root.targetScreen?.width ?? 1920) * 0.24),
                Math.max(96, activeWindowRow.implicitWidth))
            implicitHeight: Math.round(30 * IrisStyle.density)
            readonly property var activeToplevel: ToplevelManager.activeToplevel
            readonly property string appId: CompositorService.isNiri
                ? String(NiriService.activeWindow?.app_id ?? "")
                : String(activeToplevel?.appId ?? "")

            RowLayout {
                id: activeWindowRow
                anchors.centerIn: parent
                width: Math.min(parent.width, 360 * IrisStyle.density)
                spacing: 7 * IrisStyle.density

                SmartAppIcon {
                    visible: parent.parent.appId.length > 0
                    icon: parent.parent.appId
                    fallback: "application-x-executable"
                    iconSize: Math.round(18 * IrisStyle.density)
                }

                IrisText {
                    id: title
                    Layout.fillWidth: true
                    text: CompositorService.isNiri
                        ? String(NiriService.activeWindow?.title ?? "")
                        : String(parent.parent.activeToplevel?.title ?? "")
                    visible: text.length > 0
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    font.pixelSize: 12 * IrisStyle.typeScale
                    font.weight: Font.DemiBold
                    color: IrisStyle.text
                }
            }
        }
    }

    Component {
        id: statusComponent
        Item {
            implicitWidth: statusRow.implicitWidth + 18 * IrisStyle.density
            implicitHeight: Math.round(28 * IrisStyle.density)

            RowLayout {
                id: statusRow
                anchors.centerIn: parent
                spacing: Math.round(7 * IrisStyle.density)

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 16 * IrisStyle.density
                    color: IrisStyle.hairline
                }

                MaterialSymbol {
                    text: Network.wifi ? "wifi" : (Network.ethernet ? "lan" : "wifi_off")
                    iconSize: Math.round(16 * IrisStyle.density)
                    color: IrisStyle.subtext
                }
                MaterialSymbol {
                    text: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
                    iconSize: Math.round(16 * IrisStyle.density)
                    color: IrisStyle.subtext
                }
                RowLayout {
                    visible: Battery.available
                    spacing: 3
                    MaterialSymbol {
                        text: Battery.isCharging ? "battery_charging_full" : "battery_full"
                        iconSize: Math.round(16 * IrisStyle.density)
                        color: Battery.isLow ? IrisStyle.danger : IrisStyle.subtext
                    }
                    IrisText {
                        text: Math.round(Battery.percentage * 100) + "%"
                        font.family: IrisStyle.fontNumbers
                        font.pixelSize: 11 * IrisStyle.typeScale
                        color: Battery.isLow ? IrisStyle.danger : IrisStyle.subtext
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 16 * IrisStyle.density
                    color: IrisStyle.hairline
                }
            }
        }
    }

    Component {
        id: clockComponent
        IrisButton {
            id: clockButton
            quiet: true
            implicitWidth: clockText.implicitWidth + 18 * IrisStyle.density
            implicitHeight: Math.round(30 * IrisStyle.density)
            onClicked: GlobalStates.controlPanelOpen = !GlobalStates.controlPanelOpen
            IrisText {
                id: clockText
                anchors.centerIn: parent
                text: DateTime.timeDisplay
                font.family: IrisStyle.fontNumbers
                font.pixelSize: 12 * IrisStyle.typeScale
                font.weight: Font.DemiBold
            }
        }
    }

    Component {
        id: controlsComponent
        IrisIconButton {
            materialIcon: "tune"
            selected: GlobalStates.controlPanelOpen
            onClicked: GlobalStates.controlPanelOpen = !GlobalStates.controlPanelOpen
        }
    }
}
