pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.nihil.style

// The month: its name in the accent, the days under it, today a round accent dot. The wheel or the
// arrows turn the months; a click on the name comes back to this one.
NihilWidgetFace {
    id: root

    readonly property var viewing: root.widget.viewingDate
    readonly property bool browsing: root.widget.monthShift !== 0
    readonly property var cells: root.widget.monthCells()
    readonly property int rows: Math.ceil(root.cells.length / 7)

    function turn(step: int): void {
        root.widget.monthShift = step === 0 ? 0 : root.widget.monthShift + step
    }

    Item {
        id: head
        width: parent.width
        height: root.dp(24)

        NText {
            id: month
            anchors.left: parent.left
            anchors.right: arrows.left
            anchors.verticalCenter: parent.verticalCenter
            text: Translation.locale.toString(root.viewing, "MMMM")
            font.pixelSize: root.dp(root.small ? 14 : 16)
            font.weight: Font.DemiBold
            color: root.accent

            MouseArea {
                anchors.fill: parent
                enabled: root.browsing
                cursorShape: Qt.PointingHandCursor
                onClicked: root.turn(0)
            }
        }
        Row {
            id: arrows
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.dp(2)

            NText {
                anchors.verticalCenter: parent.verticalCenter
                rightPadding: root.dp(6)
                visible: root.browsing
                text: Translation.locale.toString(root.viewing, "yyyy")
                font.pixelSize: root.dp(12)
                color: root.inkSoft
            }
            Repeater {
                model: [{ glyph: "chevron_left", shift: -1 }, { glyph: "chevron_right", shift: 1 }]
                delegate: MouseArea {
                    id: arrow
                    required property var modelData
                    width: root.dp(22)
                    height: root.dp(22)
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.turn(arrow.modelData.shift)
                    NIcon {
                        anchors.centerIn: parent
                        text: arrow.modelData.glyph
                        size: root.dp(16)
                        color: arrow.containsMouse ? root.ink : root.inkSoft
                    }
                }
            }
        }
    }

    Item {
        id: table
        anchors.top: head.bottom
        anchors.topMargin: root.dp(6)
        anchors.bottom: parent.bottom
        width: parent.width
        readonly property real cellW: width / 7
        readonly property real dayRowH: root.dp(18)
        readonly property real cellH: (height - dayRowH) / Math.max(1, root.rows)

        Repeater {
            model: 7
            delegate: NText {
                required property int index
                font.pixelSize: root.dp(10)
                font.weight: Font.Medium
                x: Math.round(index * table.cellW)
                width: table.cellW
                height: table.dayRowH
                horizontalAlignment: Text.AlignHCenter
                text: Translation.locale.dayName((root.widget.weekStart + index) % 7, Locale.NarrowFormat)
                color: root.inkFaint
            }
        }

        Repeater {
            model: root.cells
            delegate: Item {
                id: cell
                required property var modelData
                required property int index
                x: Math.round((cell.index % 7) * table.cellW)
                y: Math.round(table.dayRowH + Math.floor(cell.index / 7) * table.cellH)
                width: table.cellW
                height: table.cellH
                visible: cell.modelData.currentMonth || root.widget.showAdjacentDays

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) - root.dp(2)
                    height: width
                    radius: width / 2
                    color: root.accent
                    visible: cell.modelData.isToday
                }
                NText {
                    anchors.centerIn: parent
                    figures: true
                    text: cell.modelData.day
                    font.pixelSize: root.dp(root.small ? 11 : 13)
                    font.weight: cell.modelData.isToday ? Font.DemiBold : Font.Normal
                    color: cell.modelData.isToday ? root.accentInk
                        : cell.modelData.currentMonth ? root.ink : root.inkFaint
                }
            }
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse
        enabled: !root.stacked
        onWheel: event => root.turn(event.angleDelta.y < 0 ? 1 : -1)
    }
}
