pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// An open folder: a pane of glass over the grid with its name to edit, its apps, and the key that dissolves it. An app
// dragged off the pane leaves the folder. A click outside or Escape closes it.
Item {
    id: root

    required property var folder
    required property NihilAppModel catalog

    readonly property var options: Config.options?.nihil?.folders ?? ({})
    readonly property int held: root.folder.apps.length
    readonly property int columns: (root.options.columns ?? 0) > 0 ? root.options.columns
        : Math.min(5, Math.ceil(Math.sqrt(root.held)))
    readonly property int rows: (root.options.rows ?? 0) > 0 ? root.options.rows
        : Math.ceil(root.held / Math.max(1, root.columns))
    readonly property real iconSize: (root.options.iconSize ?? -1) > 0 ? root.options.iconSize : NihilStyle.s(64)
    readonly property real spacing: NihilStyle.s(root.options.spacing ?? 12)
    readonly property real cell: root.iconSize + NihilStyle.s(44)
    readonly property real shownHeight: root.rows * root.cell + Math.max(0, root.rows - 1) * root.spacing
    readonly property string removeMode: root.options.removeButton ?? "click"
    property bool armed: false
    property bool carrying: false

    signal closed()

    focus: true
    Keys.onEscapePressed: root.closed()
    Component.onCompleted: root.forceActiveFocus()

    MouseArea {
        anchors.fill: parent
        onClicked: root.closed()
    }

    // A second press only counts while the key is still armed.
    Timer {
        interval: 3000
        running: root.armed
        onTriggered: root.armed = false
    }

    NGlass {
        id: pane
        x: (root.options.center ?? true) ? Math.round((root.width - width) / 2) : NihilStyle.s(48)
        y: Math.round((root.height - height) / 2)
        width: Math.min(root.width - NihilStyle.s(48),
            root.columns * root.cell + Math.max(0, root.columns - 1) * root.spacing + NihilStyle.s(40))
        height: Math.min(root.height - NihilStyle.s(48), head.height + root.shownHeight + NihilStyle.s(56))
        radius: NihilStyle.rPanel

        // Keeps a press on the pane from reaching the close area behind it.
        MouseArea { anchors.fill: parent }

        Item {
            id: head
            x: NihilStyle.s(20)
            y: NihilStyle.s(16)
            width: pane.width - NihilStyle.s(40)
            height: NihilStyle.s(40)

            NField {
                anchors.left: parent.left
                anchors.right: keys.left
                anchors.rightMargin: NihilStyle.gap
                anchors.verticalCenter: parent.verticalCenter
                value: root.folder.name
                placeholder: Translation.tr("Folder name")
                onCommitted: text => {
                    if (text.trim().length > 0)
                        root.catalog.renameFolder(root.folder.id, text.trim())
                }
            }

            Row {
                id: keys
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: NihilStyle.gap

                NButton {
                    visible: root.removeMode !== "hidden"
                    icon: "trash"
                    lit: root.armed
                    onClicked: {
                        if (root.removeMode === "doubleClick" && !root.armed) {
                            root.armed = true
                            return
                        }
                        root.catalog.removeFolder(root.folder.id)
                        root.closed()
                    }
                }
                NButton {
                    visible: root.options.closeButton ?? true
                    icon: "close"
                    onClicked: root.closed()
                }
            }
        }

        Flickable {
            id: scroller
            x: NihilStyle.s(20)
            y: head.y + head.height + NihilStyle.s(12)
            width: pane.width - NihilStyle.s(40)
            height: pane.height - y - NihilStyle.s(20)
            contentHeight: grid.implicitHeight
            clip: !root.carrying
            boundsBehavior: Flickable.StopAtBounds

            Grid {
                id: grid
                columns: root.columns
                spacing: root.spacing

                Repeater {
                    model: root.folder.apps
                    delegate: AppTile {
                        id: tile
                        required property var modelData
                        item: tile.modelData
                        width: root.cell
                        height: root.cell
                        iconSize: root.iconSize
                        onActivated: {
                            root.catalog.launch(tile.modelData)
                            root.closed()
                        }
                        onDragStarted: root.carrying = true
                        onDropped: (sceneX, sceneY) => {
                            root.carrying = false
                            const at = pane.mapFromItem(null, sceneX, sceneY)
                            if (!pane.contains(at))
                                root.catalog.removeFromFolder(root.folder.id, tile.modelData.id)
                        }
                    }
                }
            }
        }
    }
}
