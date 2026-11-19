pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// The date set large, the month under it and what comes next at the foot. The wheel walks the months; the large figure
// then names the month shown, and a tap on it comes back to today.
Item {
    id: root

    property bool live: true
    property int shift: 0

    readonly property date now: DateTime.clock.date
    readonly property date first: new Date(root.now.getFullYear(), root.now.getMonth() + root.shift, 1)
    readonly property int startDay: Qt.locale().firstDayOfWeek % 7
    readonly property int lead: (root.first.getDay() - root.startDay + 7) % 7
    readonly property int days: new Date(root.first.getFullYear(), root.first.getMonth() + 1, 0).getDate()
    readonly property int rows: Math.ceil((root.lead + root.days) / 7)
    readonly property real cellWidth: root.width / 7
    readonly property real cellHeight: NihilStyle.s(38)

    // The next thing on the calendar, from what was written here and what is synced.
    readonly property var next: {
        const from = root.now.getTime()
        const own = (Events.list ?? []).map(event => ({ title: event.title, at: new Date(event.dateTime).getTime() }))
        const synced = CalendarSync.enabled ? (CalendarSync.events ?? []).filter(event => !event.allDay)
            .map(event => ({ title: event.title ?? event.summary ?? "", at: new Date(event.startDate).getTime() })) : []
        return [...own, ...synced].filter(event => event.at >= from).sort((a, b) => a.at - b.at)[0] ?? null
    }
    function whenNext(at: real): string {
        const then = new Date(at)
        const time = Qt.formatTime(then, Config.options?.time?.format ?? "hh:mm")
        const start = new Date(root.now.getFullYear(), root.now.getMonth(), root.now.getDate()).getTime()
        const away = Math.floor((at - start) / 86400000)
        if (away === 0) return Translation.tr("Today at %1").arg(time)
        if (away === 1) return Translation.tr("Tomorrow at %1").arg(time)
        return then.toLocaleDateString(Qt.locale(), "ddd d MMM") + ", " + time
    }

    onLiveChanged: if (!root.live) root.shift = 0

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => root.shift += event.angleDelta.y > 0 ? -1 : 1
    }

    NText {
        id: weekday
        width: parent.width
        height: NihilStyle.s(22)
        text: root.shift === 0 ? Qt.locale().dayName(root.now.getDay(), Locale.LongFormat) : Translation.tr("Back to today")
        font.pixelSize: NihilStyle.s(15)
        color: NihilStyle.inkSoft
    }

    MouseArea {
        id: hero
        y: weekday.height
        width: parent.width
        height: NihilStyle.s(112)
        enabled: root.shift !== 0
        cursorShape: root.shift !== 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.shift = 0

        Text {
            id: figure
            anchors.verticalCenter: parent.verticalCenter
            text: root.shift === 0 ? root.now.getDate() : Qt.locale().standaloneMonthName(root.first.getMonth(), Locale.ShortFormat)
            color: NihilStyle.ink
            renderType: Text.NativeRendering
            font.family: NihilStyle.display
            font.pixelSize: root.shift === 0 ? NihilStyle.s(104) : NihilStyle.s(72)
            font.weight: Font.ExtraLight
            font.letterSpacing: root.shift === 0 ? -NihilStyle.s(5) : -NihilStyle.s(2)
            font.features: { "tnum": 1 }
        }
        NText {
            anchors.left: figure.right
            anchors.leftMargin: NihilStyle.s(14)
            anchors.right: parent.right
            anchors.baseline: figure.baseline
            text: root.shift === 0 ? Qt.locale().standaloneMonthName(root.now.getMonth(), Locale.LongFormat) : root.first.getFullYear()
            font.pixelSize: NihilStyle.s(18)
            color: NihilStyle.inkSoft
        }
    }

    Row {
        id: initials
        y: hero.y + hero.height + NihilStyle.s(14)
        Repeater {
            model: 7
            NText {
                id: initial
                required property int index
                width: root.cellWidth
                horizontalAlignment: Text.AlignHCenter
                text: Qt.locale().dayName((root.startDay + initial.index) % 7, Locale.ShortFormat).slice(0, 2)
                font.pixelSize: NihilStyle.textLabel
                color: NihilStyle.inkFaint
            }
        }
    }

    Grid {
        y: initials.y + initials.height + NihilStyle.s(12)
        columns: 7
        Repeater {
            model: root.rows * 7
            Item {
                id: step

                required property int index
                readonly property int number: step.index - root.lead + 1
                readonly property bool inMonth: step.number >= 1 && step.number <= root.days
                readonly property bool today: root.shift === 0 && step.number === root.now.getDate()
                readonly property bool rest: !Qt.locale().weekDays.includes((root.startDay + step.index) % 7)

                width: root.cellWidth
                height: root.cellHeight

                NText {
                    anchors.centerIn: parent
                    visible: step.inMonth
                    figures: true
                    text: step.number
                    font.weight: step.today ? Font.DemiBold : Font.Normal
                    color: step.today ? NihilStyle.ink : step.rest ? NihilStyle.inkFaint : NihilStyle.inkSoft
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: NihilStyle.s(3)
                    visible: step.today
                    width: NihilStyle.s(22)
                    height: NihilStyle.s(2)
                    radius: height / 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: NihilStyle.specA }
                        GradientStop { position: 1; color: NihilStyle.specB }
                    }
                }
            }
        }
    }

    NWell {
        anchors.bottom: parent.bottom
        visible: root.next !== null
        width: parent.width
        height: NihilStyle.s(58)
        radius: NihilStyle.rCard

        Rectangle {
            x: NihilStyle.s(16)
            anchors.verticalCenter: parent.verticalCenter
            width: NihilStyle.s(3)
            height: NihilStyle.s(30)
            radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0; color: NihilStyle.specA }
                GradientStop { position: 1; color: NihilStyle.specB }
            }
        }
        Column {
            x: NihilStyle.s(30)
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - x - NihilStyle.s(14)
            spacing: NihilStyle.s(1)
            NText {
                width: parent.width
                text: root.next?.title ?? ""
                font.weight: Font.Medium
            }
            NText {
                width: parent.width
                text: root.next ? root.whenNext(root.next.at) : ""
                font.pixelSize: NihilStyle.textSmall
                color: NihilStyle.inkSoft
            }
        }
    }
}
