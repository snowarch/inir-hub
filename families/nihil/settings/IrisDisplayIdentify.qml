pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.nihil.components
import qs.modules.nihil.style

// Which screen is which: each real screen says its name on a plate in its middle, over
// everything, never taking a click. `only` names one screen (the one just picked on the desk); empty names them all.
Variants {
    id: root

    property string only: ""
    // Fading out before the loader lets it go.
    property bool leaving: false

    model: Quickshell.screens

    PanelWindow {
        id: sign
        required property var modelData
        readonly property var out: CompositorConfig.outputs.find(entry => entry.name === String(sign.modelData?.name ?? "")) ?? null
        readonly property bool named: root.only.length === 0 || root.only === String(sign.modelData?.name ?? "")
        readonly property real d: IrisStyle.density
        screen: sign.modelData
        visible: sign.named
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:iris-identify"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}

        Item {
            anchors.fill: parent
            property bool risen: false
            opacity: risen && !root.leaving ? 1 : 0
            Component.onCompleted: risen = true
            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(220); easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.centerIn: parent
                width: plate.implicitWidth + Math.round(64 * sign.d)
                height: plate.implicitHeight + Math.round(44 * sign.d)
                radius: 0
                color: IrisStyle.surfaceHighestOpaque

                Column {
                    id: plate
                    anchors.centerIn: parent
                    spacing: Math.round(6 * sign.d)
                    IrisText {
                        id: title
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: CompositorConfig.screenName(sign.out) || String(sign.modelData?.name ?? "")
                        font.pixelSize: IrisStyle.typeTitleL * 2
                        font.weight: IrisStyle.weight(Font.DemiBold)
                    }
                    IrisText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        readonly property real inches: CompositorConfig.inchesOf(sign.out)
                        // The connector only when the name above is not already it.
                        text: [String(sign.modelData?.name ?? "") === title.text ? "" : String(sign.modelData?.name ?? ""), inches > 0 ? `${Math.round(inches)}″` : "",
                            CompositorConfig.resolutionLabel(sign.out), CompositorConfig.rateLabel(sign.out?.current_rate ?? 0)]
                            .filter(part => part.length > 0).join(" · ")
                        color: IrisStyle.subtext
                        font.pixelSize: IrisStyle.typeHeadline
                        font.features: ({ "tnum": 1 })
                    }
                }
            }
        }
    }
}
