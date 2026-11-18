pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state

// The workspaces of one screen as a printed index: a number set large, what lives there, and a strip of its columns
// drawn to their real widths. The active one is lit; a click goes there, the wheel walks through them.
NGlass {
    id: root

    required property string output
    readonly property var workspaces: NihilState.workspacesOn(root.output)
    readonly property real screenW: Math.max(1, NiriService.outputs?.[root.output]?.logical?.width ?? 1920)
    readonly property real rowH: NihilStyle.s(52)
    readonly property real stripW: NihilStyle.s(64)

    implicitWidth: NihilStyle.s(196)
    implicitHeight: column.implicitHeight + NihilStyle.s(20)
    width: implicitWidth
    height: implicitHeight
    radius: NihilStyle.rPanel
    tint: Qt.alpha(NihilStyle.void_, 0.38)
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
        x: NihilStyle.s(10)
        y: NihilStyle.s(10)
        width: root.width - NihilStyle.s(20)

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
                    radius: NihilStyle.rKey
                    color: row.active ? NihilStyle.pieceRaised : row.containsMouse ? NihilStyle.piece : "transparent"
                    Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
                }
                NSpectrum {
                    x: 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: NihilStyle.s(2)
                    height: row.active ? parent.height - NihilStyle.s(18) : 0
                    Behavior on height { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
                }
                NDisplay {
                    id: number
                    x: NihilStyle.s(10)
                    anchors.verticalCenter: parent.verticalCenter
                    size: NihilStyle.s(34)
                    bloom: row.active ? 0.6 : 0
                    text: String(row.index + 1).padStart(2, "0")
                    color: row.active ? NihilStyle.ink : row.containsMouse ? NihilStyle.inkSoft : NihilStyle.inkFaint
                }
                Column {
                    anchors.left: number.right
                    anchors.leftMargin: NihilStyle.s(10)
                    anchors.right: parent.right
                    anchors.rightMargin: NihilStyle.s(8)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: NihilStyle.s(6)
                    NLabel {
                        width: parent.width
                        strong: row.active
                        text: row.name.length > 0 ? row.name
                            : row.windows.length > 0 ? root.appName(row.windows[0]) : Translation.tr("Empty")
                    }
                    // The columns, each as wide as it really is.
                    Row {
                        spacing: NihilStyle.s(2)
                        height: NihilStyle.s(4)
                        Repeater {
                            model: row.windows.slice(0, 8)
                            Rectangle {
                                required property var modelData
                                readonly property real share: (modelData.layout?.tile_size?.[0] ?? root.screenW / 2) / root.screenW
                                width: Math.max(NihilStyle.s(3), root.stripW * Math.min(1, share) / 2)
                                height: NihilStyle.s(4)
                                radius: 1
                                color: modelData.is_focused ? NihilStyle.ink : row.active ? NihilStyle.inkSoft : NihilStyle.inkFaint
                            }
                        }
                    }
                }
                NSpark {
                    x: number.x + number.width - size * 0.4
                    y: number.y - size * 0.25
                    size: NihilStyle.s(22)
                    opacity: row.active ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: NihilStyle.calm } }
                }
            }
        }
    }
}
