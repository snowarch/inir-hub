pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state
import qs.modules.nihil.overview

// The dash on the desktop: the same pinned and running apps on the same glass, on an edge of each screen. It steps
// aside while the overview is open (the overview carries its own dash) and, unless it is always shown, while
// windows cover the workspace; the pointer at the edge brings it back.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: dock

        required property var modelData
        readonly property var options: Config.options?.nihil?.dock
        readonly property string edge: ["left", "right"].includes(dock.options?.position) ? dock.options.position : "bottom"
        readonly property bool vertical: dock.edge !== "bottom"
        // "always" keeps its room, "desktop" shows on an empty workspace, "hover" only at the pointer.
        readonly property string visibility: dock.options?.visibility ?? "desktop"
        readonly property var outputs: Array.from(dock.options?.screenList ?? [])
        readonly property string output: dock.modelData.name
        readonly property var workspace: NihilState.workspacesOn(dock.output).find(ws => ws.is_active)
        readonly property bool bare: NihilState.windowsOn(dock.workspace?.id).length === 0
        readonly property real margin: NihilStyle.s(dock.options?.margin ?? 8)
        readonly property real depth: dash.across + dock.margin * 2
        readonly property bool menuOpen: menu.app !== null
        readonly property bool wanted: !NihilState.overviewOpen && (dock.menuOpen || hover.hovered
            || dock.visibility === "always" || (dock.visibility === "desktop" && dock.bare))
        property bool shown: dock.wanted

        screen: dock.modelData
        visible: (Config.options?.nihil?.modules?.dock ?? true)
            && (dock.outputs.length === 0 || dock.outputs.includes(dock.output))
        color: "transparent"
        WlrLayershell.namespace: "quickshell:nihil-dock"
        WlrLayershell.layer: WlrLayer.Top
        exclusiveZone: dock.visibility === "always" ? dock.depth : 0
        anchors {
            bottom: dock.edge === "bottom" || dock.vertical
            top: dock.vertical
            left: dock.edge !== "right"
            right: dock.edge !== "left"
        }
        // The right-click menu needs room above the dash; the window grows only while it is open.
        implicitHeight: dock.vertical ? 0 : dock.depth + (dock.menuOpen ? NihilStyle.s(320) : 0)
        implicitWidth: dock.vertical ? dock.depth + (dock.menuOpen ? NihilStyle.s(260) : 0) : 0
        mask: Region { item: dock.menuOpen ? frame : dock.shown || dock.reveal > 0.01 ? dash : trigger }
        BackgroundEffect.blurRegion: CompositorService.blurRegions && NihilStyle.blur && dock.reveal > 0.5 ? dash.region : null

        // Hiding waits a moment, so a pointer crossing the edge does not make it flicker.
        onWantedChanged: {
            if (dock.wanted) { hideDelay.stop(); dock.shown = true }
            else hideDelay.restart()
        }
        Timer {
            id: hideDelay
            interval: 450
            onTriggered: dock.shown = dock.wanted
        }

        property real reveal: dock.shown ? 1 : 0
        Behavior on reveal { NumberAnimation { duration: NihilStyle.durationMedium; easing.type: Easing.OutCubic } }

        Item {
            id: frame
            anchors.fill: parent

            HoverHandler { id: hover }

            // A thin strip on the edge that catches the pointer while the dash is away.
            Item {
                id: trigger
                width: dock.vertical ? NihilStyle.s(3) : parent.width
                height: dock.vertical ? parent.height : NihilStyle.s(3)
                x: dock.edge === "right" ? parent.width - width : 0
                y: dock.vertical ? 0 : parent.height - height
            }

            Dash {
                id: dash
                // The window ends a few pixels past the glass: a drop shadow would be cut there in a hard dark band.
                shadow: 0
                look: dock.options
                output: dock.output
                position: dock.edge
                room: dock.vertical ? frame.height - dock.margin * 2 : frame.width - dock.margin * 2
                opacity: dock.reveal
                readonly property real away: (1 - dock.reveal) * (dash.across + dock.margin)
                x: !dock.vertical ? (frame.width - width) / 2
                    : dock.edge === "left" ? dock.margin - dash.away : frame.width - width - dock.margin + dash.away
                y: dock.vertical ? (frame.height - height) / 2 : frame.height - height - dock.margin + dash.away
                // The menu opens beside the dash, in the room the window grows towards.
                onMenuAsked: (app, at) => {
                    menu.at = dock.edge === "bottom" ? Qt.point(at.x - NihilStyle.s(118), 0)
                        : dock.edge === "left" ? Qt.point(dock.depth, at.y) : Qt.point(0, at.y)
                    menu.app = app
                }
            }

            DashMenu {
                id: menu
                output: dock.output
            }
        }
    }
}
