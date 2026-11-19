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

// The dock: a strip of glass on an edge of each screen with the pinned and running apps (DockStrip). Resting on an
// icon shows the app's windows over it (DockPreview); a right click opens its menu. It steps aside while the overview is
// open (the overview carries its own dash) and, unless it is always shown, while windows cover the workspace; the pointer
// at the edge brings it back.
Item {
    id: root

    readonly property bool enabled: Config.options?.nihil?.modules?.dock ?? true

    // The running apps come from the compositor's sorted toplevels, which stay empty until a consumer claims them. One
    // claim serves every screen.
    function claim(): void { CompositorService.setSortingConsumer("nihilDock", root.enabled) }
    onEnabledChanged: root.claim()
    Component.onCompleted: root.claim()
    Component.onDestruction: CompositorService.setSortingConsumer("nihilDock", false)

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
            readonly property real depth: strip.across + dock.margin * 2
            readonly property bool menuOpen: menu.app !== null
            readonly property bool previewOpen: preview.app !== null
            readonly property bool wanted: !NihilState.overviewOpen && (dock.menuOpen || dock.previewOpen || hover.hovered
                || dock.visibility === "always" || (dock.visibility === "desktop" && dock.bare))
            property bool shown: dock.wanted
            // Room past the glass for swollen icons and the preview; an open menu takes the whole screen, so a click anywhere
            // else closes it.
            readonly property real room: dock.menuOpen ? (dock.vertical ? dock.modelData.width : dock.modelData.height) - dock.depth
                : dock.previewOpen ? preview.across + NihilStyle.s(16) : strip.reach + NihilStyle.s(4)

            screen: dock.modelData
            visible: root.enabled
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
            implicitHeight: dock.vertical ? 0 : dock.depth + dock.room
            implicitWidth: dock.vertical ? dock.depth + dock.room : 0
            mask: Region {
                item: dock.menuOpen ? frame : dock.shown || dock.reveal > 0.01 ? zone : trigger
                Region { item: dock.previewOpen ? preview : null }
            }
            BackgroundEffect.blurRegion: CompositorService.blurRegions && NihilStyle.blur && dock.reveal > 0.5 ? strip.region : null

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

            // The app the pointer rests on: its preview comes after a moment and leaves a moment after the pointer does.
            // Where along the strip the menu was asked for.
            property real menuAlong: 0
            property var pointedApp: null
            property var pointedKey: null
            Timer {
                id: warmUp
                interval: dock.previewOpen ? 80 : 420
                onTriggered: {
                    preview.app = dock.pointedApp
                    preview.key = dock.pointedKey
                }
            }
            Timer {
                id: coolDown
                interval: 280
                onTriggered: if (!preview.hovered && !dock.pointedApp) preview.app = null
            }

            Item {
                id: frame
                anchors.fill: parent

                HoverHandler { id: hover }

                // A thin strip on the edge that catches the pointer while the dock is away.
                // It spans only the strip, so a pointer beside the dock is not caught.
                Item {
                    id: trigger
                    width: dock.vertical ? NihilStyle.s(3) : strip.width
                    height: dock.vertical ? strip.height : NihilStyle.s(3)
                    x: dock.vertical ? (dock.edge === "right" ? parent.width - width : 0) : strip.x
                    y: dock.vertical ? strip.y : parent.height - height
                }

                // The strip's span along the edge, from its far side to the screen's edge. It takes the margin too, so a
                // pointer resting at the edge keeps the dock shown.
                Item {
                    id: zone
                    readonly property real extent: strip.across + dock.margin
                    width: dock.vertical ? zone.extent : strip.width
                    height: dock.vertical ? strip.height : zone.extent
                    x: dock.vertical ? (dock.edge === "right" ? parent.width - zone.extent : 0) : strip.x
                    y: dock.vertical ? strip.y : parent.height - zone.extent
                }

                DockStrip {
                    id: strip
                    output: dock.output
                    edge: dock.edge
                    opacity: dock.reveal
                    readonly property real away: (1 - dock.reveal) * (strip.across + dock.margin)
                    x: !dock.vertical ? (frame.width - width) / 2
                        : dock.edge === "left" ? dock.margin - strip.away : frame.width - width - dock.margin + strip.away
                    y: dock.vertical ? (frame.height - height) / 2 : frame.height - height - dock.margin + strip.away
                    onPointed: (app, key) => {
                        dock.pointedApp = app
                        dock.pointedKey = key
                        if (app && !dock.menuOpen) { coolDown.stop(); warmUp.restart() }
                        else { warmUp.stop(); coolDown.restart() }
                    }
                    // The menu opens beside the strip, in the room the window grows towards.
                    onMenuAsked: (app, at) => {
                        preview.app = null
                        dock.menuAlong = dock.vertical ? at.y : at.x
                        menu.app = app
                    }
                }

                DockPreview {
                    id: preview
                    property var key: null
                    // Distance it stands from the edge, across the dock.
                    readonly property real across: preview.vertical ? preview.implicitWidth : preview.implicitHeight
                    readonly property point anchor: preview.key ? preview.key.mapToItem(frame, preview.key.width / 2, preview.key.height / 2) : Qt.point(0, 0)
                    vertical: dock.vertical
                    pictures: dock.options?.previews ?? true
                    visible: preview.app !== null && dock.reveal > 0.9
                    width: implicitWidth
                    height: implicitHeight
                    x: dock.edge === "bottom" ? NihilStyle.clamp(preview.anchor.x - width / 2, NihilStyle.s(8), frame.width - width - NihilStyle.s(8))
                        : dock.edge === "left" ? dock.depth + NihilStyle.s(4) : frame.width - dock.depth - width - NihilStyle.s(4)
                    y: dock.edge === "bottom" ? frame.height - dock.depth - height - NihilStyle.s(4)
                        : NihilStyle.clamp(preview.anchor.y - height / 2, NihilStyle.s(8), frame.height - height - NihilStyle.s(8))
                    onHoveredChanged: if (!preview.hovered && !dock.pointedApp) coolDown.restart()
                }

                // Bound to the frame, which grows to make room for it after it opens.
                DashMenu {
                    id: menu
                    output: dock.output
                    above: dock.edge === "bottom"
                    at: dock.edge === "bottom" ? Qt.point(dock.menuAlong - NihilStyle.s(118), frame.height - dock.depth - NihilStyle.s(8))
                        : dock.edge === "left" ? Qt.point(dock.depth, dock.menuAlong - NihilStyle.s(20))
                        : Qt.point(frame.width - dock.depth - NihilStyle.s(236), dock.menuAlong - NihilStyle.s(20))
                }
            }
        }
    }
}
