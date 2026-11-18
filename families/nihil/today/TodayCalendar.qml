pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// The day on a paper tile; beside it the month's name, the keys that walk the months and the day's hours as strokes;
// under them the month as a grid of steps, today the signal's. A tap on the name comes back to this month.
Column {
    id: root

    property bool live: true
    property int shift: 0
    onLiveChanged: if (!root.live) root.shift = 0

    readonly property date now: DateTime.clock.date
    readonly property date first: new Date(root.now.getFullYear(), root.now.getMonth() + root.shift, 1)
    readonly property int startDay: Qt.locale().firstDayOfWeek % 7
    readonly property int lead: (root.first.getDay() - root.startDay + 7) % 7
    readonly property int days: new Date(root.first.getFullYear(), root.first.getMonth() + 1, 0).getDate()
    readonly property int rows: Math.ceil((root.lead + root.days) / 7)
    readonly property real g: NihilStyle.seam
    readonly property real dayShare: (root.now.getHours() * 60 + root.now.getMinutes()) / 1440

    spacing: root.g

    Row {
        spacing: root.g

        NTile {
            id: day
            width: NihilStyle.s(150)
            height: NihilStyle.s(136)
            paper: true
            caption: Qt.locale().dayName(root.now.getDay(), Locale.LongFormat)
            NFigure {
                x: day.pad - NihilStyle.s(2)
                anchors.bottom: parent.bottom
                anchors.bottomMargin: NihilStyle.s(2)
                size: NihilStyle.s(92)
                text: String(root.now.getDate())
                color: day.ink
            }
        }

        Column {
            spacing: root.g

            NTile {
                id: month
                width: root.width - day.width - root.g
                height: NihilStyle.s(84)
                interactive: root.shift !== 0
                caption: String(root.first.getFullYear())
                onClicked: root.shift = 0
                NText {
                    x: month.pad
                    width: month.width - month.pad * 2
                    y: NihilStyle.s(28)
                    text: Qt.locale().standaloneMonthName(root.first.getMonth(), Locale.LongFormat)
                    font.pixelSize: NihilStyle.textTitle
                    font.weight: Font.Black
                    font.capitalization: Font.Capitalize
                    color: root.shift === 0 ? NihilStyle.ink : NihilStyle.accent
                }
                NTicks {
                    x: month.pad
                    width: month.width - month.pad * 2
                    height: NihilStyle.s(10)
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: NihilStyle.s(10)
                    count: 24
                    level: root.dayShare
                    marked: true
                }
            }
            Row {
                spacing: root.g
                NButton {
                    width: (month.width - root.g) / 2
                    height: NihilStyle.s(48)
                    square: true
                    icon: "chevron_left"
                    iconSize: NihilStyle.s(22)
                    onClicked: root.shift -= 1
                }
                NButton {
                    width: (month.width - root.g) / 2
                    height: NihilStyle.s(48)
                    square: true
                    icon: "chevron_right"
                    iconSize: NihilStyle.s(22)
                    onClicked: root.shift += 1
                }
            }
        }
    }

    NTile {
        id: sheet
        width: root.width
        height: grid.y + grid.height + NihilStyle.s(10)

        Row {
            id: names
            x: NihilStyle.s(10)
            y: NihilStyle.s(10)
            spacing: grid.spacing
            Repeater {
                model: 7
                delegate: NCaps {
                    required property int index
                    width: grid.cell
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale().dayName((root.startDay + index) % 7, Locale.NarrowFormat)
                    color: NihilStyle.inkSoft
                }
            }
        }

        Grid {
            id: grid
            readonly property real cell: (sheet.width - NihilStyle.s(20) - grid.spacing * 6) / 7
            x: NihilStyle.s(10)
            y: names.y + names.height + NihilStyle.s(6)
            columns: 7
            spacing: NihilStyle.s(3)
            Repeater {
                model: root.rows * 7
                delegate: Rectangle {
                    id: step
                    required property int index
                    readonly property int number: step.index - root.lead + 1
                    readonly property bool inMonth: step.number >= 1 && step.number <= root.days
                    readonly property bool today: root.shift === 0 && step.number === root.now.getDate()
                    readonly property bool gone: root.shift < 0 || (root.shift === 0 && step.number < root.now.getDate())
                    width: grid.cell
                    height: NihilStyle.s(34)
                    radius: NihilStyle.s(7 * NihilStyle.corners)
                    color: !step.inMonth ? "transparent" : step.today ? NihilStyle.accent : NihilStyle.pieceRaised
                    NText {
                        anchors.centerIn: parent
                        visible: step.inMonth
                        figures: true
                        text: step.number
                        font.pixelSize: NihilStyle.s(13)
                        font.weight: step.today ? Font.Black : Font.DemiBold
                        color: step.today ? NihilStyle.onAccent : step.gone ? NihilStyle.inkSoft : NihilStyle.ink
                    }
                }
            }
        }
    }
}
