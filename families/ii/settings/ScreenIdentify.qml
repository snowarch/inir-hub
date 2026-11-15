pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Which screen is which: `show()` puts each real screen's name on a plate in its middle for a few seconds, over
// everything, never taking a click or the keyboard. Settings › Displays' Identify button.
Scope {
    id: root

    property bool leaving: false
    function show(): void {
        root.leaving = false
        gone.stop()
        signs.active = true
        hold.restart()
    }

    Timer {
        id: hold
        interval: 2600
        onTriggered: { root.leaving = true; gone.restart() }
    }
    Timer {
        id: gone
        interval: Appearance.animation.elementMoveFast.duration
        onTriggered: { signs.active = false; root.leaving = false }
    }

    LazyLoader {
        id: signs
        active: false
        Variants {
            model: Quickshell.screens
            PanelWindow {
                id: sign
                required property var modelData
                readonly property var out: CompositorConfig.outputs.find(entry => entry.name === String(sign.modelData?.name ?? "")) ?? null
                readonly property string connector: String(sign.modelData?.name ?? "")
                screen: sign.modelData
                color: "transparent"
                anchors { top: true; bottom: true; left: true; right: true }
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell:screen-identify"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                mask: Region {}

                StyledRectangularShadow {
                    target: plate
                    opacity: plate.opacity
                }
                Rectangle {
                    id: plate
                    property bool risen: false
                    anchors.centerIn: parent
                    width: column.implicitWidth + 64
                    height: column.implicitHeight + 44
                    radius: Appearance.rounding.large
                    color: Appearance.colors.colSurfaceContainerHigh
                    opacity: plate.risen && !root.leaving ? 1 : 0
                    scale: plate.risen && !root.leaving ? 1 : 0.94
                    Component.onCompleted: plate.risen = true
                    Behavior on opacity { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                    Behavior on scale { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }

                    Column {
                        id: column
                        anchors.centerIn: parent
                        spacing: 6
                        StyledText {
                            id: title
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: CompositorConfig.screenName(sign.out) || sign.connector
                            font.pixelSize: Appearance.font.pixelSize.huge * 2
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnSurface
                        }
                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            readonly property real inches: CompositorConfig.inchesOf(sign.out)
                            text: [sign.connector === title.text ? "" : sign.connector, inches > 0 ? `${Math.round(inches)}″` : "",
                                CompositorConfig.resolutionLabel(sign.out), CompositorConfig.rateLabel(sign.out?.current_rate ?? 0)]
                                .filter(part => part.length > 0).join(" · ")
                            font.pixelSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }
    }
}
