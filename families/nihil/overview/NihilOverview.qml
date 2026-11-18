pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state

// The overview on every screen, the hot corner that opens it, the popup that names the workspace on a switch, and the
// windows pinned as thumbnails.
Scope {
    id: root

    readonly property var nihil: Config.options?.nihil

    Variants {
        model: Quickshell.screens
        OverviewScreen {}
    }

    // On the compositor's own overview: the poster behind its workspaces and NiHiL's parts over them.
    Loader {
        active: NihilState.nativeStage
        sourceComponent: PosterBackdrop {}
    }
    Variants {
        model: NihilState.nativeStage ? Quickshell.screens : []
        StageChrome {}
    }

    Variants {
        model: NihilState.pips
        WindowPip {}
    }

    // Hot corner or edge.
    Variants {
        model: (root.nihil?.modules?.hotCorner ?? true) ? Quickshell.screens : []
        PanelWindow {
            id: hot
            required property var modelData
            readonly property var options: root.nihil?.overview
            readonly property string at: hot.options?.hotCorner ?? "topLeft"
            readonly property string action: hot.options?.hotCornerAction ?? "windows"
            readonly property bool edge: hot.at === "topEdge" || hot.at === "bottomEdge"
            readonly property bool fullscreenNow: NiriService.activeWindow?.is_fullscreen ?? false
            screen: hot.modelData
            visible: hot.at !== "none" && hot.action !== "none" && (!hot.fullscreenNow || (hot.options?.hotCornerFullscreen ?? false))
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:nihil-hot"
            implicitWidth: hot.edge ? 0 : NihilStyle.s(72)
            implicitHeight: NihilStyle.s(72)
            mask: Region {
                x: hot.at.endsWith("Right") ? hot.width - 3 : 0
                y: hot.at.startsWith("bottom") ? hot.height - 3 : 0
                width: hot.edge ? hot.width : 3
                height: 3
            }
            anchors {
                top: hot.at.startsWith("top")
                bottom: hot.at.startsWith("bottom")
                left: hot.edge || hot.at.endsWith("Left")
                right: hot.edge || hot.at.endsWith("Right")
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    if (hot.options?.hotCornerRipples ?? true) ripple.restart()
                    if (hot.action === "apps") NihilState.toggleOverview("apps")
                    else if (hot.action === "searchWindows") NihilState.trigger("searchWindows")
                    else NihilState.toggleOverview("windows")
                }
            }
            Rectangle {
                id: ring
                x: (hot.at.endsWith("Right") ? hot.width : 0) - width / 2
                y: (hot.at.startsWith("bottom") ? hot.height : 0) - height / 2
                width: NihilStyle.s(120) * ring.grow
                height: width
                radius: width / 2
                color: "transparent"
                border.width: NihilStyle.s(2)
                border.color: NihilStyle.flareA
                opacity: 0
                property real grow: 0
                ParallelAnimation {
                    id: ripple
                    NumberAnimation { target: ring; property: "grow"; from: 0; to: 1; duration: NihilStyle.slow; easing.type: Easing.OutCubic }
                    NumberAnimation { target: ring; property: "opacity"; from: 0.9; to: 0; duration: NihilStyle.slow }
                }
            }
        }
    }

    // The workspace switcher popup.
    Variants {
        model: (root.nihil?.modules?.switcher ?? true) && (root.nihil?.switcher?.popup ?? "current") !== "off" ? Quickshell.screens : []
        PanelWindow {
            id: popup
            required property var modelData
            readonly property var options: root.nihil?.switcher
            readonly property string output: popup.modelData.name
            readonly property bool here: (popup.options?.popup ?? "current") === "all"
                || (GlobalStates.focusedScreen?.name ?? popup.output) === popup.output
            readonly property var workspaces: NihilState.workspacesOn(popup.output)
            readonly property int reached: NihilState.activeIndexOn(popup.output)
            readonly property bool onlyActive: (popup.options?.popupScope ?? "all") === "active"
            readonly property bool springs: (popup.options?.mode ?? "default") === "default"
            readonly property string arrival: popup.options?.animation ?? "default"
            property bool showing: false
            property real shown: popup.showing ? 1 : 0
            Behavior on shown { NumberAnimation { duration: popup.arrival === "none" ? 0 : NihilStyle.calm; easing.type: Easing.OutCubic } }

            screen: popup.modelData
            visible: popup.shown > 0 && !NihilState.overviewOpen
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:nihil-switcher"
            anchors { top: true; bottom: true; left: true; right: true }
            mask: Region {}

            onReachedChanged: {
                if (!popup.here || NihilState.overviewOpen) return
                popup.showing = true
                hide.restart()
            }
            Timer {
                id: hide
                interval: popup.options?.timeout ?? 900
                onTriggered: popup.showing = false
            }

            NGlass {
                readonly property real travel: (1 - popup.shown) * NihilStyle.s(36)
                x: (popup.width - width) * (popup.options?.horizontal ?? 0.5)
                    + (popup.arrival === "left" ? -travel : popup.arrival === "right" ? travel : 0)
                y: (popup.height - height) * (popup.options?.vertical ?? 0.95)
                    + (popup.arrival === "up" ? -travel : popup.arrival === "down" ? travel : 0)
                width: strip.implicitWidth + NihilStyle.s(28)
                height: NihilStyle.s(44)
                radius: height / 2
                opacity: popup.shown
                ignite: 0.4
                Row {
                    id: strip
                    anchors.centerIn: parent
                    spacing: NihilStyle.s(7)
                    NText {
                        visible: popup.onlyActive
                        anchors.verticalCenter: parent.verticalCenter
                        figures: true
                        text: String(popup.reached + 1)
                        font.weight: Font.DemiBold
                    }
                    Repeater {
                        model: popup.onlyActive ? [] : popup.workspaces
                        Rectangle {
                            required property int index
                            anchors.verticalCenter: parent.verticalCenter
                            width: index === popup.reached ? NihilStyle.s(34) : NihilStyle.s(10)
                            height: NihilStyle.s(10)
                            radius: height / 2
                            color: index === popup.reached ? NihilStyle.accent : NihilStyle.inkFaint
                            Behavior on width {
                                enabled: popup.springs
                                NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic }
                            }
                        }
                    }
                }
            }
        }
    }
}
