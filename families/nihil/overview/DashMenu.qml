pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state

// What a right click on a dash icon offers. `app` is the dash's entry; empty closes the menu.
Item {
    id: root

    property var app: null
    property point at: Qt.point(0, 0)
    required property string output

    readonly property var options: Config.options?.nihil?.dash
    readonly property var entry: root.app ? AppSearch.lookupDesktopEntry(root.app.appId) : null
    readonly property var workspace: NihilState.workspacesOn(root.output).find(ws => ws.is_active)
    readonly property var windows: root.app ? (NiriService.windows ?? []).filter(win => win.app_id === root.app.appId) : []
    readonly property var here: root.windows.filter(win => win.workspace_id === root.workspace?.id)
    readonly property var rows: {
        if (!root.app) return []
        const list = []
        const add = (icon, label, run) => list.push({ icon, label, run })
        if (root.entry) add("add", Translation.tr("New window"), () => { AppSearch.launchEntry(root.entry); NihilState.closeOverview() })
        add("push_pin", root.app.pinned ? Translation.tr("Unpin from dash") : Translation.tr("Pin to dash"), () => TaskbarApps.togglePin(root.app.appId))
        if ((root.options?.menuMoveApp ?? true) && root.windows.length > root.here.length)
            add("arrow_forward", Translation.tr("Move all here"), () => root.windows.forEach(win =>
                NiriService.moveWindowToWorkspaceById(win.id, root.workspace.id, false)))
        if ((root.options?.menuThumbnail ?? true) && root.windows.length > 0)
            add("image", Translation.tr("Pin as thumbnail"), () => NihilState.pin(root.windows[0]))
        if ((root.options?.menuCloseOnWorkspace ?? true) && root.here.length > 0)
            add("close", Translation.tr("Close on this workspace"), () => root.here.forEach(win => NiriService.closeWindow(win.id)))
        if (root.windows.length > 0)
            add("close", Translation.tr("Close all"), () => root.windows.forEach(win => NiriService.closeWindow(win.id)))
        if ((root.options?.menuForceQuit ?? true) && root.windows.length > 0)
            add("power", Translation.tr("Force quit"), () => root.windows.forEach(win => {
                if (win.pid) Quickshell.execDetached(["kill", "-9", String(win.pid)])
            }))
        return list
    }

    anchors.fill: parent
    visible: root.app !== null

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: root.app = null
    }

    NGlass {
        x: NihilStyle.clamp(root.at.x, NihilStyle.screenMargin, root.width - width - NihilStyle.screenMargin)
        y: NihilStyle.clamp(root.at.y, NihilStyle.screenMargin, root.height - height - NihilStyle.screenMargin)
        width: NihilStyle.s(236)
        height: column.implicitHeight + NihilStyle.s(12)
        radius: NihilStyle.radiusCard
        tint: NihilStyle.menuBackground
        followPointer: true
        Column {
            id: column
            x: NihilStyle.s(6)
            y: NihilStyle.s(6)
            width: parent.width - NihilStyle.s(12)
            Repeater {
                model: root.rows
                NButton {
                    id: row
                    required property var modelData
                    width: column.width
                    height: NihilStyle.s(34)
                    tone: "transparent"
                    Accessible.name: row.modelData.label
                    onClicked: { row.modelData.run(); root.app = null }
                    NIcon {
                        x: NihilStyle.s(10)
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.icon
                        size: NihilStyle.s(16)
                    }
                    NText {
                        x: NihilStyle.s(36)
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - x - NihilStyle.s(8)
                        text: row.modelData.label
                    }
                }
            }
        }
    }
}
