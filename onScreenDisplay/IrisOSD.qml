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
    readonly property var screen: GlobalStates.focusedScreen
    readonly property var brightnessMonitor: Brightness.getMonitorForScreen(root.screen)

    function show(nextKind: string): void {
        root.kind = nextKind
        root.open = true
        hideTimer.restart()
    }

    function hide(): void {
        root.open = false
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
        visible: root.open
        screen: root.screen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:iris-osd"
        anchors { bottom: true; left: true; right: true }
        implicitHeight: 94 * IrisStyle.density

        IrisSurface {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18 * IrisStyle.density
            width: Math.max(240, Math.min(parent.width - 24,
                Math.max(280, Number(Config.options?.iris?.osd?.width ?? 320) * IrisStyle.density)))
            height: 64 * IrisStyle.density
            raised: true

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12 * IrisStyle.density
                anchors.rightMargin: 14 * IrisStyle.density
                spacing: 11 * IrisStyle.density

                Rectangle {
                    Layout.preferredWidth: 3 * IrisStyle.density
                    Layout.preferredHeight: 36 * IrisStyle.density
                    radius: width / 2
                    color: root.kind === "mic" && Audio.micMuted ? IrisStyle.danger : IrisStyle.accent
                }

                MaterialSymbol {
                    text: root.icon
                    iconSize: 22 * IrisStyle.density
                    color: root.kind === "mic" && Audio.micMuted ? IrisStyle.danger : IrisStyle.accent
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1 * IrisStyle.density

                    RowLayout {
                        Layout.fillWidth: true
                        IrisText {
                            Layout.fillWidth: true
                            text: root.kind === "brightness" ? "DISPLAY"
                                : root.kind === "mic" ? "INPUT" : "AUDIO"
                            role: IrisText.Eyebrow
                        }
                        IrisText {
                            text: root.kind === "brightness" ? Translation.tr("Brightness")
                                : root.kind === "mic" ? Translation.tr("Microphone") : Translation.tr("Volume")
                            role: IrisText.Meta
                        }
                    }

                    IrisSlider {
                        Layout.fillWidth: true
                        enabled: false
                        value: root.value
                    }
                }

                IrisText {
                    text: Math.round(root.value * 100).toString().padStart(2, "0")
                    role: IrisText.Metric
                    font.pixelSize: 26 * IrisStyle.typeScale
                    color: root.kind === "mic" && Audio.micMuted ? IrisStyle.danger : IrisStyle.text
                }

                IrisText {
                    text: "%"
                    role: IrisText.Meta
                    color: IrisStyle.muted
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 9 * IrisStyle.density
                }
            }
        }
    }
}
