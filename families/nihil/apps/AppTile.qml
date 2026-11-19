pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// One place in the grid: an app, or a folder showing what it holds. The place lights from below under the pointer or the keys.
// A press and a drag carries the tile; `dropped` says where it landed.
MouseArea {
    id: root

    required property var item
    property real iconSize: NihilStyle.s(64)
    property bool selected: false

    readonly property var options: Config.options?.nihil?.apps ?? ({})
    readonly property var folderOptions: Config.options?.nihil?.folders ?? ({})
    readonly property bool isFolder: root.item.kind === "folder"
    readonly property string names: root.options.names ?? "ellipsized"
    readonly property bool lit: root.selected || root.containsMouse
    readonly property bool showName: root.names !== "hidden" || root.lit
    readonly property bool wholeName: root.names === "expanded" || (root.names === "ellipsized" && root.lit)

    // 2x2 always; 3x3 once a folder holds at least five (3) or nine (4) apps.
    readonly property int previewSide: {
        const grid = root.folderOptions.previewGrid ?? 2
        const held = root.item.apps?.length ?? 0
        return (grid === 3 && held >= 5) || (grid === 4 && held >= 9) ? 3 : 2
    }

    signal activated()
    signal openFolder()
    signal menuAsked(real x, real y)
    signal dragStarted()
    signal dropped(real sceneX, real sceneY)
    signal previewUsed(var app)

    enabled: root.item.kind !== "gap"
    opacity: root.item.kind === "gap" ? 0 : 1
    z: root.drag.active ? 10 : 0
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    preventStealing: root.drag.active
    drag.target: root.isFolder ? null : carried
    drag.threshold: NihilStyle.s(12)

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            root.menuAsked(mouse.x, mouse.y)
        else if (root.isFolder)
            root.openFolder()
        else
            root.activated()
    }
    onReleased: {
        if (!drag.active)
            return
        const at = carried.mapToItem(null, carried.width / 2, carried.height / 2)
        carried.x = 0
        carried.y = 0
        root.dropped(at.x, at.y)
    }
    drag.onActiveChanged: if (drag.active) root.dragStarted()

    Item {
        id: carried
        width: root.width
        height: root.height
        z: root.drag.active ? 10 : 0
        scale: root.drag.active ? 1.08 : 1
        Behavior on scale { NumberAnimation { duration: NihilStyle.quick; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: NihilStyle.r(22)
            color: NihilStyle.pieceRaised
            opacity: root.lit ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: NihilStyle.quick } }
        }

        Column {
            anchors.centerIn: parent
            width: parent.width - NihilStyle.s(12)
            spacing: NihilStyle.s(8)

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.iconSize
                height: root.iconSize

                NAppIcon {
                    anchors.centerIn: parent
                    visible: !root.isFolder
                    appId: root.isFolder ? "" : (root.item.icon || root.item.id)
                    size: root.iconSize
                }

                Rectangle {
                    anchors.fill: parent
                    visible: root.isFolder
                    radius: NihilStyle.rCard
                    color: NihilStyle.piece
                    border.width: 1
                    border.color: NihilStyle.hair

                    Grid {
                        anchors.centerIn: parent
                        columns: root.previewSide
                        spacing: NihilStyle.s(3)

                        Repeater {
                            model: root.isFolder ? root.item.apps.slice(0, root.previewSide * root.previewSide) : []
                            delegate: NAppIcon {
                                id: preview
                                required property var modelData
                                appId: preview.modelData.icon || preview.modelData.id
                                size: (root.iconSize - NihilStyle.s(14)) / root.previewSide

                                // With active previews each icon opens its own app.
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: root.folderOptions.activePreview ?? false
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.previewUsed(preview.modelData)
                                }
                            }
                        }
                    }
                }


                Rectangle {
                    visible: (root.options.packageBadge ?? true) && (root.item.package ?? "").length > 0
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: NihilStyle.s(18)
                    height: width
                    radius: width / 2
                    color: NihilStyle.carbon
                    border.width: 1
                    border.color: NihilStyle.hair

                    NText {
                        anchors.centerIn: parent
                        text: String(root.item.package ?? "").slice(0, 1).toUpperCase()
                        font.pixelSize: NihilStyle.textLabel
                        font.weight: Font.DemiBold
                        color: NihilStyle.inkSoft
                    }
                }
            }

            Item {
                width: parent.width
                height: name.implicitHeight + NihilStyle.s(6)
                visible: root.showName

                NText {
                    id: name
                    anchors.centerIn: parent
                    width: parent.width - NihilStyle.s(8)
                    horizontalAlignment: Text.AlignHCenter
                    text: root.item.name ?? ""
                    elide: root.wholeName ? Text.ElideNone : Text.ElideRight
                    wrapMode: root.wholeName ? Text.Wrap : Text.NoWrap
                    maximumLineCount: root.wholeName ? 3 : 1
                    font.pixelSize: NihilStyle.textBody
                    font.weight: Font.Normal
                    color: root.lit ? NihilStyle.ink : Qt.alpha(NihilStyle.ink, 0.78)
                }
            }
        }
    }
}
