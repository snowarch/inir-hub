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
    readonly property bool morphOpen: GlobalStates.controlPanelOpen

    visible: root.morphOpen || panel.progress > 0
    screen: GlobalStates.focusedScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:iris-controls"
    anchors { left: true; right: true; top: true; bottom: true }
    WlrLayershell.keyboardFocus: GlobalStates.controlPanelOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    readonly property real edgeGap: (Number(root.barOptions?.height ?? 42)
        + ((root.barOptions?.notch ?? false) ? 0 : Number(root.barOptions?.margin ?? 8) * 2)) * IrisStyle.density + 8 * IrisStyle.density
    // Island surfaces hang under the part that opened them; Classic keeps its
    // right-aligned drawer.
    readonly property var origin: GlobalStates.irisMorphOrigin
    readonly property real panelWidth: Math.min(root.width - 16, IrisStyle.island
        ? Math.max(360, Number(root.options?.width ?? 380)) * IrisStyle.density
        : Math.max(300, Number(root.options?.width ?? 360) * IrisStyle.density))
    readonly property real contentPadding: (IrisStyle.island ? 16 * IrisStyle.density : IrisStyle.panelPadding)

    MouseArea { anchors.fill: parent; onClicked: GlobalStates.controlPanelOpen = false }
    Shortcut { sequence: "Escape"; onActivated: GlobalStates.controlPanelOpen = false }

    IrisMorphSurface {
        id: panel
        open: root.morphOpen
        contentReady: contents.contentHeight > 0
        radius: IrisStyle.island ? Math.round(30 * IrisStyle.density) : IrisStyle.radius
        x: IrisStyle.island && root.origin
            ? Math.max(8, Math.min(root.width - width - 8, root.origin.x + root.origin.width / 2 - width / 2))
            : IrisStyle.island ? (root.width - width) / 2 : root.width - width - 12 * IrisStyle.density
        y: root.barBottom ? root.height - height - root.edgeGap : root.edgeGap
        width: root.panelWidth
        height: Math.min(root.height - root.edgeGap - 12, contents.contentHeight + root.contentPadding * 2)

        MouseArea { anchors.fill: parent }

        Flickable {
            id: contents
            anchors.fill: parent
            anchors.margins: root.contentPadding
            contentHeight: IrisStyle.island ? (alternate.item?.implicitHeight ?? 0) : controls.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true

        Loader {
            id: alternate
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            active: IrisStyle.island
            sourceComponent: IrisQuickPanel { targetScreen: root.screen }
        }

        ColumnLayout {
            id: controls
            visible: !IrisStyle.island
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 14 * IrisStyle.density

            Item {
                visible: !IrisStyle.island
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? IrisStyle.headerHeight : 0

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

            RowLayout {
                visible: IrisStyle.island
                Layout.fillWidth: true
                spacing: 8 * IrisStyle.density

                IrisText {
                    Layout.fillWidth: true
                    text: Translation.tr("Control Center")
                    font.family: IrisStyle.fontTitle
                    font.pixelSize: 17 * IrisStyle.typeScale
                    font.weight: Font.DemiBold
                }
                IrisText {
                    text: DateTime.timeDisplay
                    role: IrisText.Meta
                    color: IrisStyle.subtext
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8 * IrisStyle.density

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8 * IrisStyle.density
                    IrisText {
                        text: IrisStyle.island ? Translation.tr("Sound") : "AUDIO"
                        role: IrisStyle.island ? IrisText.Meta : IrisText.Eyebrow
                        font.weight: IrisStyle.island ? Font.DemiBold : Font.Bold
                    }
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
                    IrisText {
                        text: IrisStyle.island ? Translation.tr("Display") : "DISPLAY"
                        role: IrisStyle.island ? IrisText.Meta : IrisText.Eyebrow
                        font.weight: IrisStyle.island ? Font.DemiBold : Font.Bold
                    }
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
                IrisText {
                    text: IrisStyle.island ? Translation.tr("Controls") : "SYSTEM"
                    role: IrisStyle.island ? IrisText.Meta : IrisText.Eyebrow
                    font.weight: IrisStyle.island ? Font.DemiBold : Font.Bold
                }
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
}
