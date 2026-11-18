pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.nihil.style

// The list a long choice opens beside its key, on the same glass as the page. A click anywhere else closes it.
Item {
    id: root

    property var option: null
    property var current
    property point at: Qt.point(0, 0)

    readonly property bool shown: root.option !== null

    signal picked(var value)

    function show(option: var, anchor: Item, current: var): void {
        root.option = option
        root.current = current
        root.at = anchor.mapToItem(root, anchor.width, anchor.height + NihilStyle.s(4))
    }

    function close(): void {
        root.option = null
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
                    model: root.option?.options ?? []

                    delegate: MouseArea {
                        id: row
                        required property var modelData
                        readonly property bool chosen: row.modelData.value === root.current

                        width: rows.width
                        height: NihilStyle.s(38)
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.picked(row.modelData.value)
                            root.close()
                        }

                        // The chosen one is a bone plate; hover is a faint tint.
                        Rectangle {
                            anchors.fill: parent
                            radius: NihilStyle.rKey
                            color: row.chosen ? NihilStyle.ink : (row.containsMouse ? NihilStyle.piece : "transparent")
                            Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
                        }
                        NText {
                            x: NihilStyle.s(12)
                            width: parent.width - NihilStyle.s(44)
                            anchors.verticalCenter: parent.verticalCenter
                            text: Translation.tr(row.modelData.label)
                            elide: Text.ElideRight
                            font.weight: row.chosen ? Font.DemiBold : Font.Normal
                            color: row.chosen ? NihilStyle.void_ : NihilStyle.ink
                        }
                        NSpark {
                            anchors.right: parent.right
                            anchors.rightMargin: NihilStyle.s(12)
                            anchors.verticalCenter: parent.verticalCenter
                            visible: row.chosen
                            size: NihilStyle.s(14)
                            tint: NihilStyle.void_
                        }
                    }
                }
            }
        }
    }
}
