pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state

// The workspaces of one screen as a list: the icons of what lives there and its name. The active one sits on a raised
// plate; a click goes there, the wheel walks through them.
NGlass {
    id: root

    required property string output
    readonly property var workspaces: NihilState.workspacesOn(root.output)
    readonly property real rowH: NihilStyle.s(44)

    implicitWidth: NihilStyle.s(210)
    implicitHeight: column.implicitHeight + NihilStyle.s(20)
    width: implicitWidth
    height: implicitHeight
    radius: NihilStyle.rPanel
        tracks: true

    function appName(win: var): string {
        return AppSearch.lookupDesktopEntry(win?.app_id ?? "")?.name ?? String(win?.app_id ?? "")
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => NihilState.stepWorkspace(root.output, event.angleDelta.y > 0 ? -1 : 1)
    }

    Column {
        id: column
        x: NihilStyle.s(8)
        y: NihilStyle.s(10)
        width: root.width - NihilStyle.s(16)
        spacing: NihilStyle.s(2)

        Repeater {
            model: root.workspaces
            MouseArea {
                id: row
                required property var modelData
                required property int index
                readonly property bool active: row.modelData.is_active
                readonly property var windows: NihilState.windowsOn(row.modelData.id)
                readonly property string name: String(row.modelData.name ?? "")
                width: column.width
                height: root.rowH
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.Button
                Accessible.name: Translation.tr("Workspace %1").arg(row.index + 1)
                onClicked: NiriService.switchToWorkspaceById(row.modelData.id)

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: row.active ? NihilStyle.chosen : row.containsMouse ? NihilStyle.piece : "transparent"
                    Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
                }
                // What lives there: up to three icons, overlapping a little; an empty workspace shows a quiet ring.
                Item {
                    id: faces
                    x: NihilStyle.s(10)
                    anchors.verticalCenter: parent.verticalCenter
                    width: NihilStyle.s(52)
                    height: NihilStyle.s(22)
                    Rectangle {
                        visible: row.windows.length === 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: NihilStyle.s(20)
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.width: 1
                        border.color: NihilStyle.inkFaint
                    }
                    Repeater {
                        model: row.windows.slice(0, 3)
                        NAppIcon {
                            required property var modelData
                            required property int index
                            x: index * NihilStyle.s(14)
                            size: NihilStyle.s(22)
                            appId: modelData.app_id ?? ""
                            opacity: row.active || row.containsMouse ? 1 : 0.7
                        }
                    }
                }
                NText {
                    anchors.left: faces.right
                    anchors.leftMargin: NihilStyle.s(6)
                    anchors.right: parent.right
                    anchors.rightMargin: NihilStyle.s(10)
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.name.length > 0 ? row.name
                        : row.windows.length > 0 ? root.appName(row.windows.find(win => win.is_focused) ?? row.windows[0]) : Translation.tr("Empty")
                    color: row.active ? NihilStyle.ink : NihilStyle.inkSoft
                    font.weight: row.active ? Font.DemiBold : Font.Medium
                }
            }
        }
    }
}
