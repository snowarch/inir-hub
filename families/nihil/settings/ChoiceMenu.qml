pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.nihil.style

// The list a long choice opens beside its key, on the same glass as the page. A click anywhere else closes it.
Item {
    id: root

    // The row that asked: its choices, its value, and where a pick is written.
    property var row: null
    property point at: Qt.point(0, 0)

    readonly property bool shown: root.row !== null
    readonly property var current: root.row?.value

    signal picked(var value)

    function show(row: var, anchor: Item): void {
        root.row = row
        root.at = anchor.mapToItem(root, anchor.width, anchor.height + NihilStyle.s(4))
    }

    function close(): void {
        root.row = null
    }

    visible: root.shown

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    NGlass {
        id: sheet
        width: NihilStyle.s(260)
        height: Math.min(root.height - NihilStyle.s(24), rows.implicitHeight + NihilStyle.s(12))
        x: NihilStyle.clamp(root.at.x - width, NihilStyle.s(12), root.width - width - NihilStyle.s(12))
        y: NihilStyle.clamp(root.at.y, NihilStyle.s(12), root.height - height - NihilStyle.s(12))
        radius: NihilStyle.rCard

        Flickable {
            anchors.fill: parent
            anchors.margins: NihilStyle.s(6)
            clip: true
            contentHeight: rows.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: rows
                width: parent.width

                Repeater {
                    model: root.row?.choices ?? []

                    delegate: MouseArea {
                        id: row
                        required property var modelData
                        readonly property bool chosen: String(row.modelData.value) === String(root.current)

                        width: rows.width
                        height: NihilStyle.s(38)
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.picked(row.modelData.value)
                            root.close()
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: NihilStyle.rKey
                            color: row.chosen ? NihilStyle.chosen : (row.containsMouse ? NihilStyle.piece : "transparent")
                            Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
                        }
                        NText {
                            x: NihilStyle.s(12)
                            width: parent.width - NihilStyle.s(44)
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.label
                            elide: Text.ElideRight
                            font.weight: row.chosen ? Font.DemiBold : Font.Normal
                            color: NihilStyle.ink
                        }
                        NIcon {
                            anchors.right: parent.right
                            anchors.rightMargin: NihilStyle.s(10)
                            anchors.verticalCenter: parent.verticalCenter
                            visible: row.chosen
                            text: "check"
                            size: NihilStyle.s(16)
                            color: NihilStyle.accent
                        }
                    }
                }
            }
        }
    }
}
