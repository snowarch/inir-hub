pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

// Which screen is which, as Windows answers it: `show()` puts each real screen's number (the one its tile wears in
// Settings › Display) on a plate at its lower left for a few seconds, with its name, over everything and never taking
// a click or the keyboard.
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
        interval: Looks.transition.duration.medium
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
                readonly property string connector: String(sign.modelData?.name ?? "")
                readonly property var out: CompositorConfig.outputs.find(entry => entry.name === sign.connector) ?? null
                screen: sign.modelData
                color: "transparent"
                anchors { top: true; bottom: true; left: true; right: true }
                // Kept clear of the taskbar and panels, as Windows sets the number above its taskbar.
                exclusionMode: ExclusionMode.Normal
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell:screen-identify"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                mask: Region {}

                Rectangle {
                    id: plate
                    property bool risen: false
                    x: Looks.dp(48)
                    y: sign.height - plate.height - Looks.dp(48) + (plate.risen && !root.leaving ? 0 : Looks.dp(12))
                    width: Math.max(Looks.dp(132), column.implicitWidth + Looks.dp(48))
                    height: column.implicitHeight + Looks.dp(32)
                    radius: Looks.settings.radiusXLarge
                    color: Looks.colors.bg1Base
                    border.width: 1
                    border.color: Looks.colors.bg1Border
                    opacity: plate.risen && !root.leaving ? 1 : 0
                    Component.onCompleted: plate.risen = true
                    Behavior on opacity { NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.medium : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate } }
                    Behavior on y { NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.medium : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate } }

                    Column {
                        id: column
                        x: Looks.dp(24)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Looks.dp(2)
                        WText {
                            text: String(CompositorConfig.outputs.findIndex(entry => entry.name === sign.connector) + 1)
                            font.pixelSize: Looks.dp(96)
                            font.weight: Looks.font.weight.strong
                            color: Looks.colors.fg
                        }
                        WText {
                            text: CompositorConfig.screenName(sign.out) || sign.connector
                            font.pixelSize: Looks.settings.body
                            color: Looks.colors.subfg
                        }
                    }
                }
            }
        }
    }
}
