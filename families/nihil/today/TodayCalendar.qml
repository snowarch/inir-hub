pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// The day in large thin figures beside its name, then the month to walk. A tap on the month's name comes back to today.
Column {
    id: root

    property bool live: true
    property int shift: 0

    readonly property date now: DateTime.clock.date
    readonly property date first: new Date(root.now.getFullYear(), root.now.getMonth() + root.shift, 1)
    readonly property int startDay: Qt.locale().firstDayOfWeek % 7
    readonly property int lead: (root.first.getDay() - root.startDay + 7) % 7
    readonly property int days: new Date(root.first.getFullYear(), root.first.getMonth() + 1, 0).getDate()
    readonly property int rows: Math.ceil((root.lead + root.days) / 7)
    readonly property real cell: root.width / 7

    onLiveChanged: if (!root.live) root.shift = 0

    spacing: NihilStyle.s(10)

    Item {
        width: root.width
        height: NihilStyle.s(72)

        NText {
            id: day
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            figures: true
            text: root.now.getDate()
            font.pixelSize: NihilStyle.s(64)
            font.weight: Font.Light
        }
        Column {
            anchors.left: day.right
            anchors.leftMargin: NihilStyle.s(12)
            anchors.right: keys.left
            anchors.verticalCenter: parent.verticalCenter

            NText {
                width: parent.width
                text: Qt.locale().dayName(root.now.getDay(), Locale.LongFormat)
                elide: Text.ElideRight
                font.weight: Font.Medium
                font.capitalization: Font.Capitalize
            }
            NText {
                width: parent.width
                text: Qt.locale().standaloneMonthName(root.first.getMonth(), Locale.LongFormat) + " " + root.first.getFullYear()
                elide: Text.ElideRight
                font.capitalization: Font.Capitalize
                color: root.shift === 0 ? NihilStyle.inkSoft : NihilStyle.accent

                MouseArea {
                    anchors.fill: parent
                    enabled: root.shift !== 0
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shift = 0
                }
            }
        }
        Row {
            id: keys
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            NButton {
                icon: "chevron_left"
                onClicked: root.shift -= 1
            }
            NButton {
                icon: "chevron_right"
                onClicked: root.shift += 1
            }
        }
    }

    Row {
        Repeater {
            model: 7
            delegate: NText {
                id: dayName
                required property int index
                width: root.cell
                horizontalAlignment: Text.AlignHCenter
                text: Qt.locale().dayName((root.startDay + dayName.index) % 7, Locale.NarrowFormat)
                font.pixelSize: NihilStyle.textSmall
                color: NihilStyle.inkSoft
            }
        }
    }

    Grid {
        columns: 7

        Repeater {
            model: root.rows * 7
            delegate: Item {
                id: step

                required property int index
                readonly property int number: step.index - root.lead + 1
                readonly property bool inMonth: step.number >= 1 && step.number <= root.days
                readonly property bool today: root.shift === 0 && step.number === root.now.getDate()

                width: root.cell
                height: NihilStyle.s(34)

                Rectangle {
                    anchors.centerIn: parent
                    width: NihilStyle.s(30)
                    height: NihilStyle.s(30)
                    radius: width / 2
                    visible: step.today
                    color: NihilStyle.accent
                }
                NText {
                    anchors.centerIn: parent
                    visible: step.inMonth
                    figures: true
                    text: step.number
                    font.weight: step.today ? Font.DemiBold : Font.Normal
                    color: step.today ? NihilStyle.onAccent : NihilStyle.ink
                }
            }
        }
    }
}
