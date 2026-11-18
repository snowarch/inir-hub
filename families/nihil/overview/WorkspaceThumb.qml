pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.modules.common
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state
import "Expose.js" as Expose

// A workspace in the strip: its windows in miniature, a label, a close key; drop a window here to move it.
Item {
    id: root

    required property var workspace
    required property int number
    property bool open: false

    readonly property var options: Config.options?.nihil?.thumbnails
    readonly property var windows: NihilState.windowsOn(root.workspace.id)
    readonly property bool active: root.workspace.is_active
    readonly property bool hot: hand.containsMouse || closeKey.containsMouse || drop.containsDrag
    readonly property string closeMode: root.options?.closeButton ?? "doubleClick"
    readonly property var slots: Expose.inPlace(root.windows.map(win => ({
        id: win.id,
        w: win.layout?.window_size?.[0] ?? 1280,
        h: win.layout?.window_size?.[1] ?? 800,
        column: win.layout?.pos_in_scrolling_layout?.[0] ?? 0
    })), root.width - NihilStyle.s(8), root.height - NihilStyle.s(8), NihilStyle.s(2), 1)
    readonly property string label: {
        const mode = root.options?.labels ?? "indexApp"
        const first = root.windows[0]
        const app = first ? (AppSearch.lookupDesktopEntry?.(first.app_id)?.name ?? first.app_id ?? "") : ""
        switch (mode) {
        case "none": return ""
        case "index": return String(root.number)
        case "app": return app
        case "name": return root.workspace.name ?? String(root.number)
        case "windowTitle": return first?.title ?? String(root.number)
        }
        return app.length > 0 ? root.number + ": " + app : String(root.number)
    }

    function closeAll(): void { root.windows.forEach(win => NiriService.closeWindow(win.id)) }

    ClippingRectangle {
        anchors.fill: parent
        radius: NihilStyle.rCard
        color: NihilStyle.void_
        Image {
            anchors.fill: parent
            source: Wallpapers.effectiveWallpaperUrl
            sourceSize.width: 480
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        Repeater {
            model: root.open ? root.windows : []
            WindowShot {
                id: mini
                required property var modelData
                readonly property var slot: root.slots[mini.modelData.id] ?? ({ x: 0, y: 0, w: 0, h: 0 })
                readonly property string scope: Config.options?.nihil?.motion?.workspaces ?? "activeOnly"
                x: mini.slot.x + NihilStyle.s(4)
                y: mini.slot.y + NihilStyle.s(4)
                width: mini.slot.w
                height: mini.slot.h
                radius: NihilStyle.s(4)
                windowId: mini.modelData.id
                appId: mini.modelData.app_id ?? ""
                decodeWidth: 320
                live: root.open && mini.scope !== "none" && (root.active || mini.scope === "all")
            }
        }
    }

    NGlass {
        anchors.fill: parent
        radius: NihilStyle.rCard
        tint: "transparent"
        grain: 0
        shadow: root.active ? 1 : 0.4
        flare: root.active ? NihilStyle.glassFlare * 0.5 : 0
        rim: root.active ? 1.4 : root.hot ? 0.9 : 0.35
        ignite: drop.containsDrag ? 1 : root.active ? 0.4 : 0
        light: Qt.point(root.width / 2, 0)
    }

    MouseArea {
        id: hand
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: NiriService.switchToWorkspaceById(root.workspace.id)
    }

    DropArea {
        id: drop
        anchors.fill: parent
        keys: ["nihil-window"]
        onDropped: event => {
            const id = event.source?.windowId
            if (id !== undefined && event.source.win?.workspace_id !== root.workspace.id)
                NiriService.moveWindowToWorkspaceById(id, root.workspace.id, false)
            event.accept()
        }
    }

    NGlass {
        visible: root.label.length > 0 && (!(root.options?.labelsOnHover ?? true) || root.hot || root.active)
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: NihilStyle.s(5)
        width: Math.min(tag.implicitWidth + NihilStyle.s(14), root.width - NihilStyle.s(10))
        height: NihilStyle.s(20)
        radius: height / 2
        shadow: 0
        NText {
            id: tag
            anchors.fill: parent
            anchors.leftMargin: NihilStyle.s(7)
            anchors.rightMargin: NihilStyle.s(7)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: root.label
            font.pixelSize: NihilStyle.s(11)
            font.weight: Font.DemiBold
        }
    }

    NButton {
        id: closeKey
        visible: root.closeMode !== "hidden" && root.hot && root.windows.length > 0
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: NihilStyle.s(4)
        width: NihilStyle.s(22)
        height: NihilStyle.s(22)
        radius: height / 2
        tone: NihilStyle.scrim
        icon: "close"
        iconSize: NihilStyle.s(11)
        Accessible.name: Translation.tr("Close all windows on this workspace")
        onClicked: mouse => {
            if (root.closeMode === "click" || (root.closeMode === "ctrlClick" && (mouse?.modifiers & Qt.ControlModifier)))
                root.closeAll()
        }
        onDoubleClicked: if (root.closeMode === "doubleClick") root.closeAll()
    }
}
