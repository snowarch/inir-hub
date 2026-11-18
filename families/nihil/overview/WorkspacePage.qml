pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.modules.common
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state
import "Expose.js" as Expose

// One workspace in the overview's centre: the wallpaper on a rounded page, its windows spread over it.
Item {
    id: root

    required property var workspace
    property bool current: false
    property bool built: true
    property bool open: false
    property string selectedKey: ""
    property real screenWidth: 1920
    signal windowActivated(var win)
    signal emptyClicked()

    readonly property var nihil: Config.options?.nihil
    readonly property string mode: root.nihil?.overview?.mode ?? "default"
    readonly property bool spread: !NihilState.holdStatic && (root.mode === "default" || (root.mode === "hover" && pointer.hovered))
    readonly property string liveScope: root.nihil?.motion?.workspaces ?? "activeOnly"
    readonly property var windows: NihilState.windowsOn(root.workspace.id)
    readonly property var items: root.windows.map(win => ({
        id: win.id,
        w: win.layout?.window_size?.[0] ?? 1280,
        h: win.layout?.window_size?.[1] ?? 800,
        column: win.layout?.pos_in_scrolling_layout?.[0] ?? 0
    }))
    readonly property real inset: NihilStyle.s(34)
    readonly property real footer: root.nihil?.windows?.heightCompensation ?? 0
    readonly property real maxScale: root.width / Math.max(1, root.screenWidth)
    readonly property var slots: {
        const w = root.width - root.inset * 2, h = root.height - root.inset * 2 - root.footer, gap = NihilStyle.s(26)
        return root.spread ? Expose.arrange(root.items, w, h, gap, root.maxScale)
            : Expose.inPlace(root.items, w, h, NihilStyle.s(8), root.maxScale)
    }

    HoverHandler { id: pointer }

    ClippingRectangle {
        anchors.fill: parent
        radius: root.nihil?.stage?.radius ?? 30
        color: (root.nihil?.stage?.background ?? true) ? NihilStyle.void_ : "transparent"
        Image {
            anchors.fill: parent
            visible: root.nihil?.stage?.background ?? true
            source: Wallpapers.effectiveWallpaperUrl
            sourceSize.width: 1280
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.emptyClicked()
    }

    Item {
        x: root.inset
        y: root.inset
        width: root.width - root.inset * 2
        height: root.height - root.inset * 2 - root.footer
        visible: root.built
        Repeater {
            model: root.built ? root.windows : []
            WindowCard {
                required property var modelData
                win: modelData
                slot: root.slots[modelData.id] ?? ({ x: 0, y: 0, w: 0, h: 0 })
                selected: root.selectedKey === String(modelData.id)
                live: root.open && root.liveScope !== "none" && (root.current || root.liveScope === "all")
                onActivated: root.windowActivated(modelData)
            }
        }
    }
}
