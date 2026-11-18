pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// The day as the reference's dot figures, its weekday and month beside them; under them the month, one round cell per
// day, today lit in the signal. The arrows walk the months; a tap on the title comes back to this one.
Item {
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
    readonly property real cell: (root.width - NihilStyle.s(6) * 6) / 7

    height: top.height + NihilStyle.s(14) + names.height + NihilStyle.s(6) + grid.height

    Item {
        id: top
        width: parent.width
        height: NihilStyle.s(62)
        DotText {
            id: dayDots
            anchors.verticalCenter: parent.verticalCenter
            x: NihilStyle.s(4)
            text: String(root.now.getDate()).padStart(2, "0")
            dot: NihilStyle.s(6)
            color: NihilStyle.ink
        }
        Column {
            anchors.left: dayDots.right
            anchors.leftMargin: NihilStyle.s(14)
            anchors.verticalCenter: parent.verticalCenter
            spacing: NihilStyle.s(2)
            NText {
                text: Qt.locale().dayName(root.now.getDay(), Locale.LongFormat)
                font.pixelSize: NihilStyle.textLarge
                font.weight: Font.DemiBold
                font.capitalization: Font.Capitalize
            }
            MouseArea {
                width: monthWord.implicitWidth; height: monthWord.implicitHeight
                cursorShape: root.shift !== 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.shift = 0
                NText {
                    id: monthWord
                    text: root.first.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                    font.capitalization: Font.Capitalize
                    color: root.shift === 0 ? NihilStyle.inkSoft : NihilStyle.accent
                }
            }
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: NihilStyle.s(6)
            NButton {
                width: NihilStyle.s(36); height: width
                tone: NihilStyle.pieceRaised
                icon: "chevron_left"
                iconSize: NihilStyle.s(20)
                onClicked: root.shift -= 1
            }
            NButton {
                width: NihilStyle.s(36); height: width
                tone: NihilStyle.pieceRaised
                icon: "chevron_right"
                iconSize: NihilStyle.s(20)
                onClicked: root.shift += 1
            }
        }
    }

    Row {
        id: names
        y: top.height + NihilStyle.s(14)
        spacing: NihilStyle.s(6)
        Repeater {
            model: 7
            delegate: NText {
                required property int index
                width: root.cell
                horizontalAlignment: Text.AlignHCenter
                text: Qt.locale().dayName((root.startDay + index) % 7, Locale.NarrowFormat)
                font.pixelSize: NihilStyle.textSmall
                font.capitalization: Font.AllUppercase
                color: NihilStyle.inkSoft
            }
        }
    }

    Grid {
        id: grid
        y: names.y + names.height + NihilStyle.s(6)
        columns: 7
        spacing: NihilStyle.s(6)
        Repeater {
            model: root.rows * 7
            delegate: Rectangle {
                id: day
                required property int index
                readonly property int number: day.index - root.lead + 1
                readonly property bool inMonth: day.number >= 1 && day.number <= root.days
                readonly property bool today: root.shift === 0 && day.number === root.now.getDate()
                readonly property bool weekend: {
                    const weekday = (root.startDay + day.index) % 7
                    return weekday === 0 || weekday === 6
                }
                width: root.cell
                height: Math.min(root.cell, NihilStyle.s(36))
                radius: height / 2
                color: day.today ? NihilStyle.accent : "transparent"
                NText {
                    anchors.centerIn: parent
                    visible: day.inMonth
                    figures: true
                    text: day.number
                    font.pixelSize: NihilStyle.textSmall
                    font.weight: day.today ? Font.Bold : Font.Medium
                    color: day.today ? NihilStyle.onAccent : day.weekend ? NihilStyle.inkSoft : NihilStyle.ink
                }
            }
        }
    }
}
