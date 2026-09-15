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

Scope {
    id: root
    property string kind: "volume"
    property bool open: false
    property bool presentationVisible: false
    property bool presentationShown: false
    readonly property var screen: GlobalStates.focusedScreen
    readonly property var brightnessMonitor: Brightness.getMonitorForScreen(root.screen)
    readonly property var dockOptions: Config.options?.iris?.dock ?? ({})
    readonly property bool staticDockVisible: (root.dockOptions?.enable ?? true)
        && !(root.dockOptions?.autoHide ?? true)
    readonly property real dockHeight: (Math.max(28, Math.min(64,
        Number(root.dockOptions?.iconSize ?? 40))) + 24) * IrisStyle.density
    readonly property real surfaceBottomMargin: root.staticDockVisible
        ? root.dockHeight + 20 * IrisStyle.density
        : 18 * IrisStyle.density

    function show(nextKind: string): void {
        root.kind = nextKind
        root.open = true
        closePresentation.stop()
        root.presentationVisible = true
        Qt.callLater(() => root.presentationShown = true)
        hideTimer.restart()
    }

    function hide(): void {
        root.open = false
        root.presentationShown = false
        closePresentation.restart()
        GlobalStates.osdVolumeOpen = false
        GlobalStates.osdBrightnessOpen = false
        GlobalStates.osdMicOpen = false
    }

    readonly property real value: root.kind === "brightness"
        ? (root.brightnessMonitor?.brightness ?? 0)
        : root.kind === "mic"
            ? Math.max(0, Math.min(1, Audio.micVolume ?? 0))
            : Math.max(0, Math.min(1, Audio.value ?? 0))
    readonly property string icon: root.kind === "brightness" ? "brightness_6"
        : root.kind === "mic" ? (Audio.micMuted ? "mic_off" : "mic")
        : (Audio.sink?.audio?.muted ? "volume_off" : "volume_up")

    Timer { id: hideTimer; interval: 1500; onTriggered: root.hide() }
    Timer {
        id: closePresentation
        interval: IrisStyle.duration(90)
        onTriggered: root.presentationVisible = false
    }

    Connections {
        target: Brightness
        function onBrightnessChanged(): void { root.show("brightness") }
    }
    Connections {
        target: Audio.sink?.audio ?? null
        function onVolumeChanged(): void { root.show("volume") }
        function onMutedChanged(): void { root.show("volume") }
    }
    Connections {
        target: Audio
        function onMicVolumeChanged(): void { root.show("mic") }
        function onMicMutedChanged(): void { root.show("mic") }
    }
    Connections {
        target: GlobalStates
        function onOsdVolumeOpenChanged(): void { if (GlobalStates.osdVolumeOpen) root.show("volume") }
        function onOsdBrightnessOpenChanged(): void { if (GlobalStates.osdBrightnessOpen) root.show("brightness") }
        function onOsdMicOpenChanged(): void { if (GlobalStates.osdMicOpen) root.show("mic") }
    }

    PanelWindow {
        visible: root.presentationVisible
        screen: root.screen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:iris-osd"
        anchors { bottom: true; left: true; right: true }
        implicitHeight: root.surfaceBottomMargin + 76 * IrisStyle.density
        // Feedback never takes input from the windows beneath its strip.
        mask: Region { item: osdSurface }

        IrisSurface {
            id: osdSurface
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.surfaceBottomMargin
            width: Math.max(240, Math.min(parent.width - 24,
                Math.max(250, Number(Config.options?.iris?.osd?.width ?? 320) * IrisStyle.density)))
            height: 52 * IrisStyle.density
            raised: true
            radius: height / 2
            opacity: root.presentationShown ? 1 : 0
            transform: Translate {
                y: root.presentationShown ? 0 : 5 * IrisStyle.density
                Behavior on y { NumberAnimation { duration: IrisStyle.duration(90); easing.type: Easing.OutCubic } }
            }
            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(80); easing.type: Easing.OutCubic } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12 * IrisStyle.density
                anchors.rightMargin: 14 * IrisStyle.density
                spacing: 11 * IrisStyle.density

                MaterialSymbol {
                    text: root.icon
                    iconSize: 22 * IrisStyle.density
                    color: root.kind === "mic" && Audio.micMuted ? IrisStyle.danger : IrisStyle.accent
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1 * IrisStyle.density

                    IrisSlider {
                        Layout.fillWidth: true
                        enabled: false
                        value: root.value
                    }
                }

                IrisText {
                    text: Math.round(root.value * 100).toString().padStart(2, "0") + "%"
                    role: IrisText.Body
                    font.pixelSize: 15 * IrisStyle.typeScale
                    font.weight: Font.DemiBold
                    color: root.kind === "mic" && Audio.micMuted ? IrisStyle.danger : IrisStyle.text
                }

            }
        }
    }
}
