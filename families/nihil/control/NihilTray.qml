pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// The tray: what the chevron lifts, the apps running behind as tiles over the bar's right end. A tap opens the app, a
// right tap its own menu; an empty tray says so.
NPopup {
    id: root

    open: NihilState.trayOpen
    namespace: "nihil:tray"
    onDismissed: NihilState.trayOpen = false

    readonly property var items: [...TrayService.pinnedItems, ...TrayService.unpinnedItems]
    readonly property int columns: Math.max(1, Math.min(5, root.items.length))
    readonly property real side: NihilStyle.s(56)

    NRack {
        width: root.items.length > 0 ? grid.implicitWidth : NihilStyle.s(220)
        height: root.items.length > 0 ? grid.implicitHeight : root.side
        x: parent.width - width - NihilStyle.edge
        y: root.barBottom ? parent.height - height - root.edgeBottom : root.edgeTop

        NTile {
            anchors.fill: parent
            visible: root.items.length === 0
            NText {
                anchors.centerIn: parent
                text: Translation.tr("Nothing in the tray")
                font.pixelSize: NihilStyle.textSmall
                font.weight: Font.Bold
            }
        }

        Grid {
            id: grid
            columns: root.columns
            spacing: NihilStyle.seam
            Repeater {
                model: root.items
                delegate: NButton {
                    id: key
                    required property SystemTrayItem modelData
                    width: root.side
                    height: root.side
                    square: true
                    onClicked: {
                        if (!TrayService.smartToggle(key.modelData)) key.modelData.activate()
                        NihilState.trayOpen = false
                    }
                    onRightClicked: {
                        if (!key.modelData.hasMenu) { key.modelData.secondaryActivate(); return }
                        const at = key.mapToItem(null, 0, 0)
                        key.modelData.display(root, at.x, at.y)
                    }
                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: Math.round(key.width * 0.46)
                        source: TrayService.getSafeIcon(key.modelData)
                    }
                }
            }
        }
    }
}
