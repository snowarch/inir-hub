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
    readonly property var options: Config.options?.iris?.dock ?? ({})
    readonly property real iconSize: Math.max(28, Math.min(64, Number(root.options?.iconSize ?? 40))) * IrisStyle.density
    readonly property bool top: (Config.options?.iris?.bar?.position ?? "top") === "bottom"
    readonly property var apps: TaskbarApps.apps.filter(app => app.appId !== "SEPARATOR")
    Component.onCompleted: CompositorService.setSortingConsumer("irisDock", true)
    Component.onDestruction: CompositorService.setSortingConsumer("irisDock", false)

    function activate(app): void {
        const windows = app.toplevels ?? []
        if (MinimizedWindows.countMinimizedForApp(app.appId) > 0) {
            MinimizedWindows.restoreLatestForApp(app.appId)
        } else if (windows.length > 0) {
            const current = windows.findIndex(window => window.activated)
            const next = windows[(current + 1) % windows.length]
            if (CompositorService.isNiri && next.niriWindowId !== undefined)
                NiriService.focusWindow(next.niriWindowId)
            else next.activate()
        } else {
            const entry = AppSearch.lookupDesktopEntry(app.appId)
            if (entry) AppSearch.launchEntry(entry)
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: window
            required property var modelData
            property var menuApp: null
            readonly property real dockHeight: root.iconSize + 24 * IrisStyle.density
            readonly property bool revealed: !(root.options?.autoHide ?? true) || hover.hovered || hideDelay.running || menuApp !== null
            screen: modelData
            visible: !GlobalStates.screenLocked && !GlobalStates.widgetEditMode
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:iris-dock"
            WlrLayershell.keyboardFocus: menuApp !== null ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors { left: true; right: true; top: root.top || window.menuApp !== null; bottom: !root.top || window.menuApp !== null }
            implicitHeight: dockHeight + 48 * IrisStyle.density
            mask: menuApp !== null ? fullRegion : dockRegion
            Region { id: fullRegion; width: window.width; height: window.height }
            Region { id: dockRegion; item: dock; Region { item: revealEdge } }

            Timer { id: hideDelay; interval: 400 }
            MouseArea {
                anchors.fill: parent
                visible: window.menuApp !== null
                onClicked: window.menuApp = null
            }
            Shortcut { sequence: "Escape"; enabled: window.menuApp !== null; onActivated: window.menuApp = null }
            Item {
                id: revealEdge
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: root.top ? parent.top : undefined
                anchors.bottom: root.top ? undefined : parent.bottom
                width: dock.width
                height: window.revealed ? window.dockHeight + 18 : 3
                HoverHandler {
                    id: hover
                    onHoveredChanged: { if (hovered) hideDelay.stop(); else hideDelay.restart() }
                }
            }

            IrisSurface {
                id: dock
                width: Math.min(window.width - 32, appRow.implicitWidth + 20 * IrisStyle.density)
                height: window.dockHeight
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.top ? (window.revealed ? 10 : -height)
                    : window.height - (window.revealed ? height + 10 : 0)
                radius: Math.min(IrisStyle.radius, height / 2)
                Behavior on y { NumberAnimation { duration: IrisStyle.duration(180); easing.type: Easing.OutCubic } }
                HoverHandler {
                    onHoveredChanged: { if (hovered) hideDelay.restart() }
                }
                Flickable {
                    anchors.fill: parent
                    anchors.margins: 10 * IrisStyle.density
                    contentWidth: appRow.implicitWidth
                    contentHeight: height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    Row {
                        id: appRow
                        spacing: 6 * IrisStyle.density
                        IrisIconButton {
                            implicitWidth: root.iconSize + 4 * IrisStyle.density
                            implicitHeight: window.dockHeight - 20 * IrisStyle.density
                            materialIcon: "apps"
                            iconSize: root.iconSize * 0.65
                            Accessible.name: Translation.tr("Applications")
                            onClicked: GlobalStates.searchOpen = !GlobalStates.searchOpen
                        }
                        Repeater {
                            model: root.apps
                            IrisButton {
                                id: appButton
                                required property var modelData
                                readonly property var desktopEntry: AppSearch.lookupDesktopEntry(modelData.appId)
                                quiet: true
                                implicitWidth: root.iconSize + 8 * IrisStyle.density
                                implicitHeight: window.dockHeight - 20 * IrisStyle.density
                                Accessible.name: desktopEntry?.name ?? modelData.appId
                                onClicked: root.activate(modelData)
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.RightButton
                                    onClicked: window.menuApp = appButton.modelData
                                }
                                SmartAppIcon {
                                    anchors.centerIn: parent
                                    icon: appButton.desktopEntry?.icon ?? appButton.modelData.appId
                                    fallback: "application-x-executable"
                                    iconSize: root.iconSize
                                    scale: appButton.hovered ? 1.08 : 1
                                    Behavior on scale { NumberAnimation { duration: IrisStyle.duration(110); easing.type: Easing.OutCubic } }
                                }
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: -5 * IrisStyle.density
                                    width: appButton.modelData.toplevels.some(t => t.activated) ? 12 : 4
                                    height: 3
                                    radius: 2
                                    visible: appButton.modelData.toplevels.length > 0
                                    color: IrisStyle.text
                                }
                                StyledToolTip { text: appButton.Accessible.name }
                            }
                        }
                    }
                }
            }

            IrisSurface {
                visible: window.menuApp !== null
                anchors.horizontalCenter: dock.horizontalCenter
                width: Math.min(320 * IrisStyle.density, window.width - 32)
                height: menuContent.implicitHeight + IrisStyle.panelPadding * 2
                y: root.top ? dock.y + dock.height + 8 : dock.y - height - 8
                ColumnLayout {
                    id: menuContent
                    anchors.fill: parent
                    anchors.margins: IrisStyle.panelPadding
                    spacing: 6
                    IrisText { Layout.fillWidth: true; text: AppSearch.lookupDesktopEntry(window.menuApp?.appId ?? "")?.name ?? ""; elide: Text.ElideRight; font.weight: Font.Bold }
                    Repeater {
                        model: window.menuApp?.toplevels ?? []
                        IrisButton {
                            required property var modelData
                            Layout.fillWidth: true
                            text: String(modelData.title ?? "").slice(0, 38)
                            quiet: true
                            onClicked: {
                                if (CompositorService.isNiri && modelData.niriWindowId !== undefined) NiriService.focusWindow(modelData.niriWindowId)
                                else modelData.activate()
                                window.menuApp = null
                            }
                        }
                    }
                    IrisButton {
                        Layout.fillWidth: true
                        text: Translation.tr("New window")
                        onClicked: {
                            const entry = AppSearch.lookupDesktopEntry(window.menuApp?.appId ?? "")
                            if (entry) AppSearch.launchEntry(entry)
                            window.menuApp = null
                        }
                    }
                    IrisButton {
                        Layout.fillWidth: true
                        text: window.menuApp?.pinned ? Translation.tr("Unpin") : Translation.tr("Pin to dock")
                        onClicked: { TaskbarApps.togglePin(window.menuApp.appId); window.menuApp = null }
                    }
                }
            }
        }
    }
}
