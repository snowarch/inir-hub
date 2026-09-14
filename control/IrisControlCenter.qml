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

PanelWindow {
    id: root

    readonly property var options: Config.options?.iris?.controlCenter ?? ({})
    readonly property var barOptions: Config.options?.iris?.bar ?? ({})
    readonly property bool barBottom: String(root.barOptions?.position ?? "top") === "bottom"
    readonly property var brightnessMonitor: Brightness.getMonitorForScreen(root.screen)

    visible: GlobalStates.controlPanelOpen
    screen: GlobalStates.focusedScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:iris-controls"
    anchors { left: true; right: true; top: true; bottom: true }
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    readonly property real edgeGap: (Number(root.barOptions?.height ?? 42)
        + Number(root.barOptions?.margin ?? 8) * 2) * IrisStyle.density + 8

    MouseArea { anchors.fill: parent; onClicked: GlobalStates.controlPanelOpen = false }
    Shortcut { sequence: "Escape"; onActivated: GlobalStates.controlPanelOpen = false }

    IrisSurface {
        id: panel
        anchors.right: IrisStyle.island ? undefined : parent.right
        anchors.horizontalCenter: IrisStyle.island ? parent.horizontalCenter : undefined
        anchors.rightMargin: 8
        anchors.top: root.barBottom ? undefined : parent.top
        anchors.bottom: root.barBottom ? parent.bottom : undefined
        anchors.topMargin: root.barBottom ? 0 : root.edgeGap
        anchors.bottomMargin: root.barBottom ? root.edgeGap : 0
        width: Math.min(parent.width - 16, Math.max(300, Number(root.options?.width ?? 360) * IrisStyle.density))
        implicitHeight: controls.implicitHeight + IrisStyle.panelPadding * 2
        raised: true

        ColumnLayout {
            id: controls
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: IrisStyle.panelPadding
            spacing: 14 * IrisStyle.density

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: IrisStyle.headerHeight

                IrisSectionHeader {
                    id: controlHeader
                    anchors.fill: parent
                    icon: "tune"
                    eyebrow: "IRIS / CONTROL"
                    title: Translation.tr("Quick controls")
                    subtitle: root.screen?.name ?? ""
                    indexText: DateTime.timeDisplay
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8 * IrisStyle.density

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8 * IrisStyle.density
                    IrisText { text: "AUDIO"; role: IrisText.Eyebrow }
                    Item { Layout.fillWidth: true }
                    IrisText {
                        text: Math.round((Audio.value ?? 0) * 100) + "%"
                        role: IrisText.Metric
                        font.pixelSize: 18 * IrisStyle.typeScale
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9 * IrisStyle.density
                    MaterialSymbol {
                        text: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
                        iconSize: 19 * IrisStyle.density
                        color: Audio.sink?.audio?.muted ? IrisStyle.danger : IrisStyle.accent
                    }
                    IrisSlider {
                        Layout.fillWidth: true
                        value: Math.max(0, Math.min(1, Audio.value ?? 0))
                        onMoved: next => Audio.setSinkVolume(next)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: IrisStyle.hairline
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8 * IrisStyle.density

                RowLayout {
                    Layout.fillWidth: true
                    IrisText { text: "DISPLAY"; role: IrisText.Eyebrow }
                    Item { Layout.fillWidth: true }
                    IrisText {
                        text: Math.round((root.brightnessMonitor?.brightness ?? 0) * 100) + "%"
                        role: IrisText.Metric
                        font.pixelSize: 18 * IrisStyle.typeScale
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9 * IrisStyle.density
                    MaterialSymbol { text: "brightness_6"; iconSize: 19 * IrisStyle.density; color: IrisStyle.accent }
                    IrisSlider {
                        Layout.fillWidth: true
                        enabled: root.brightnessMonitor !== null
                        value: root.brightnessMonitor?.brightness ?? 0
                        onMoved: next => { if (root.brightnessMonitor) root.brightnessMonitor.setBrightness(next) }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: IrisStyle.hairline }

            RowLayout {
                Layout.fillWidth: true
                IrisText { text: "SYSTEM"; role: IrisText.Eyebrow }
                Item { Layout.fillWidth: true }
                IrisText {
                    text: Appearance.m3colors.darkmode ? Translation.tr("Dark") : Translation.tr("Light")
                    role: IrisText.Meta
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8 * IrisStyle.density
                rowSpacing: 8 * IrisStyle.density

                IrisActionTile {
                    Layout.fillWidth: true
                    showChevron: false
                    selected: Network.wifiEnabled
                    materialIcon: Network.wifiEnabled ? "wifi" : "wifi_off"
                    title: Translation.tr("Wi-Fi")
                    subtitle: Network.networkName ?? ""
                    onClicked: Network.toggleWifi()
                }
                IrisActionTile {
                    Layout.fillWidth: true
                    showChevron: false
                    selected: !Audio.micMuted
                    materialIcon: Audio.micMuted ? "mic_off" : "mic"
                    title: Translation.tr("Microphone")
                    subtitle: Audio.micMuted ? Translation.tr("Muted") : Translation.tr("Active")
                    onClicked: Audio.toggleMicMute()
                }
                IrisActionTile {
                    Layout.fillWidth: true
                    showChevron: false
                    selected: Notifications.manualDndActive
                    materialIcon: Notifications.manualDndActive ? "notifications_off" : "notifications"
                    title: Translation.tr("Do not disturb")
                    subtitle: Notifications.manualDndActive ? Translation.tr("On") : Translation.tr("Off")
                    onClicked: Notifications.toggleSilent()
                }
                IrisActionTile {
                    Layout.fillWidth: true
                    showChevron: false
                    selected: Appearance.m3colors.darkmode
                    materialIcon: Appearance.m3colors.darkmode ? "dark_mode" : "light_mode"
                    title: Translation.tr("Dark mode")
                    subtitle: Appearance.m3colors.darkmode ? Translation.tr("Dark") : Translation.tr("Light")
                    onClicked: Appearance.toggleDarkMode()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                IrisButton {
                    Layout.fillWidth: true
                    implicitHeight: 38 * IrisStyle.density
                    quiet: true
                    onClicked: { GlobalStates.controlPanelOpen = false; GlobalStates.sessionOpen = true }
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        MaterialSymbol { text: "power_settings_new"; iconSize: 17 * IrisStyle.density; color: IrisStyle.text }
                        IrisText { text: Translation.tr("Session") }
                    }
                }
                IrisButton {
                    Layout.fillWidth: true
                    implicitHeight: 38 * IrisStyle.density
                    quiet: true
                    onClicked: Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "settings"])
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        MaterialSymbol { text: "settings"; iconSize: 17 * IrisStyle.density; color: IrisStyle.text }
                        IrisText { text: Translation.tr("Settings") }
                    }
                }
            }
        }
    }
}
