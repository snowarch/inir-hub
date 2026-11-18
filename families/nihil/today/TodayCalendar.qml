pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// The day named, then the month to walk on a raised card. A tap on the month's name comes back to today.
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

    onLiveChanged: if (!root.live) root.shift = 0

    spacing: NihilStyle.s(14)

    // The day, named.
    Column {
        width: root.width
        spacing: NihilStyle.s(2)
        NText {
            width: parent.width
            text: Qt.locale().dayName(root.now.getDay(), Locale.LongFormat)
            font.pixelSize: NihilStyle.textSmall
            font.weight: Font.Medium
            color: NihilStyle.accent
        }
        NDisplay {
            width: parent.width
            text: Translation.locale.toString(root.now, "d MMMM")
            elide: Text.ElideRight
            size: NihilStyle.s(28)
        }
    }

    // The month on a raised card.
    Rectangle {
        width: root.width
        height: month.implicitHeight + NihilStyle.s(20)
        radius: NihilStyle.rCard
        color: NihilStyle.piece
        border.width: 1
        border.color: NihilStyle.line

        Column {
            id: month
            x: NihilStyle.s(10)
            y: NihilStyle.s(8)
            width: parent.width - NihilStyle.s(20)
            spacing: NihilStyle.s(4)

            Item {
                width: parent.width
                height: NihilStyle.s(32)
                NText {
                    id: monthName
                    x: NihilStyle.s(6)
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.locale().standaloneMonthName(root.first.getMonth(), Locale.LongFormat) + " " + root.first.getFullYear()
                    font.weight: Font.DemiBold
                    color: monthTap.containsMouse ? NihilStyle.accent : NihilStyle.ink
                    MouseArea {
                        id: monthTap
                        anchors.fill: parent
                        enabled: root.shift !== 0
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shift = 0
                    }
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    NButton {
                        width: NihilStyle.s(28)
                        height: NihilStyle.s(28)
                        icon: "chevron_left"
                        iconSize: NihilStyle.s(16)
                        onClicked: root.shift -= 1
                    }
                    NButton {
                        width: NihilStyle.s(28)
                        height: NihilStyle.s(28)
                        icon: "chevron_right"
                        iconSize: NihilStyle.s(16)
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
                        width: month.width / 7
                        horizontalAlignment: Text.AlignHCenter
                        text: Qt.locale().dayName((root.startDay + dayName.index) % 7, Locale.ShortFormat)
                        font.pixelSize: NihilStyle.textLabel
                        font.weight: Font.Medium
                        color: NihilStyle.inkFaint
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

                        width: month.width / 7
                        height: NihilStyle.s(32)

                        Rectangle {
                            anchors.centerIn: parent
                            width: NihilStyle.s(28)
                            height: width
                            radius: width / 2
                            visible: step.today
                            color: NihilStyle.accent
                        }
                        NText {
                            anchors.centerIn: parent
                            visible: step.inMonth
                            figures: true
                            text: step.number
                            font.pixelSize: NihilStyle.textSmall
                            font.weight: step.today ? Font.DemiBold : Font.Normal
                            color: step.today ? NihilStyle.accentInk : NihilStyle.ink
                        }
                    }
                }
            }
        }
    }
}
