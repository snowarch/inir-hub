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

// The tray: what the chevron lifts, the running background apps as round keys on one piece over the bar's right
// end. A tap opens the app, a right tap its own menu; an empty tray says so.
NPopup {
    id: root

    open: NihilState.trayOpen
    namespace: "nihil:tray"
    onDismissed: NihilState.trayOpen = false

    readonly property var items: [...TrayService.pinnedItems, ...TrayService.unpinnedItems]
    readonly property int columns: Math.max(1, Math.min(4, root.items.length))

    NCard {
        width: Math.max(NihilStyle.cells(root.columns), NihilStyle.cells(3)) + NihilStyle.panelPad * 2
        height: (root.items.length > 0 ? grid.height : NihilStyle.cell) + NihilStyle.panelPad * 2
        x: parent.width - width - NihilStyle.edge
        y: root.barBottom ? parent.height - height - root.edgeBottom : root.edgeTop

        NText {
            anchors.centerIn: parent
            visible: root.items.length === 0
            figures: true
            text: Translation.tr("Nothing in the tray")
            color: NihilStyle.inkSoft
            font.pixelSize: NihilStyle.textSmall
        }

        Grid {
            id: grid
            anchors.right: parent.right
            columns: root.columns
            spacing: NihilStyle.cellGap
            Repeater {
                model: root.items
                delegate: NButton {
                    id: key
                    required property SystemTrayItem modelData
                    width: NihilStyle.cell
                    height: NihilStyle.cell
                    tone: NihilStyle.pieceRaised
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
                        implicitSize: Math.round(key.width * 0.42)
                        source: TrayService.getSafeIcon(key.modelData)
                    }
                }
            }
        }
    }
}
