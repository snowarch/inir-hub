pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.iris.widgets

// The month in Prism: the month on the tab, today on the flap, what comes next in the pane, the week (small, medium)
// or the whole month (large) on the foot, today on the widget's colour and a dot under each day that has events. The
// wheel over the month turns it; the flap brings it back to today.
PrismFolder {
    id: root

    readonly property var today: DateTime.clock.date
    readonly property var viewing: root.widget.viewingDate ?? root.today
    readonly property var cells: root.large ? root.widget.monthCells() : []
    readonly property var coming: IrisFaceData.upcomingEvents(root.today, 7).slice(0, root.small ? 1 : root.medium ? 2 : 3)
    readonly property bool turned: (root.widget.monthShift ?? 0) !== 0
    function eventsOn(date: var): int {
        return (Events.getEventsForDate(date) ?? []).length + (CalendarSync.getEventsForDate(date) ?? []).length
    }
    function dayOf(event: var): string {
        const day = IrisFaceData.eventDate(event)
        const sameDay = day.toDateString() === root.today.toDateString()
        const time = event?.allDay ? Translation.tr("All day") : IrisFaceData.clockText(day)
        return sameDay ? time : IrisFaceData.capitalized(Translation.locale.toString(day, "ddd")) + " " + time
    }

    tabGlyph: "calendar_month"
    tabText: IrisFaceData.capitalized(Translation.locale.toString(root.viewing, root.large ? "MMMM yyyy" : "MMMM"))
    flapText: root.turned ? Translation.tr("Today") : IrisFaceData.capitalized(Translation.locale.toString(root.today, "ddd d"))

    // ── the pane: what comes next ──
    Column {
        x: root.inset
        y: Math.round(root.paneMiddle - height / 2)
        width: root.innerWidth
        spacing: root.pick(6, 6, 10)
        Repeater {
            model: root.coming
            PrismEventLine {
                required property var modelData
                face: root
                width: root.innerWidth
                event: modelData
                when: root.dayOf(modelData)
                beside: root.medium
            }
        }
    }
    FaceText {
        visible: root.coming.length === 0
        face: root
        x: root.inset
        y: Math.round(root.paneMiddle - height / 2)
        width: root.innerWidth
        text: Translation.tr("The next seven days are free")
        color: root.inkSecondary
        size: root.type(13, 15, 18)
        weight: Font.DemiBold
        wrapMode: Text.WordWrap
        maximumLineCount: 2
    }

    // ── the foot: the week, or the month ──
    PrismWeek {
        visible: !root.large
        face: root
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.footTop + (root.footHeight - height) / 2 - root.dp(2))
        today: root.today
        dates: root.medium
    }
    Item {
        id: month
        visible: root.large
        x: root.inset
        y: root.footTop + root.dp(12)
        width: root.innerWidth
        height: root.height - root.dp(14) - y
        readonly property real cell: month.width / 7
        readonly property real head: root.dp(18)
        readonly property int rows: Math.max(1, Math.ceil(root.cells.length / 7))
        readonly property real pitch: (month.height - month.head) / month.rows
        readonly property real disc: Math.min(month.pitch - root.dp(4), root.dp(24))
        Repeater {
            model: root.large ? 7 : 0
            FaceText {
                required property int index
                face: root
                x: Math.round(index * month.cell)
                width: Math.round(month.cell)
                horizontalAlignment: Text.AlignHCenter
                text: {
                    const day = new Date(2024, 0, 7 + (root.widget.weekStart + index) % 7)
                    return Translation.locale.toString(day, "ddd").charAt(0).toUpperCase()
                }
                color: root.inkTertiary
                size: 11
                weight: Font.DemiBold
            }
        }
        Repeater {
            model: root.cells
            Item {
                id: cell
                required property var modelData
                required property int index
                readonly property bool now: cell.modelData.currentMonth && cell.modelData.date.toDateString() === root.today.toDateString()
                readonly property bool busy: cell.modelData.currentMonth && root.eventsOn(cell.modelData.date) > 0
                x: Math.round((cell.index % 7) * month.cell)
                y: Math.round(month.head + Math.floor(cell.index / 7) * month.pitch)
                width: Math.round(month.cell)
                height: Math.round(month.pitch)
                Rectangle {
                    anchors.centerIn: parent
                    width: month.disc
                    height: month.disc
                    radius: width / 2
                    color: cell.now ? root.shelf : "transparent"
                }
                FaceText {
                    visible: cell.modelData.currentMonth || root.widget.showAdjacentDays
                    face: root
                    anchors.centerIn: parent
                    text: String(cell.modelData.day)
                    color: cell.now ? root.inkOnShelf : cell.modelData.currentMonth ? root.inkSecondary : root.inkTertiary
                    opacity: cell.modelData.currentMonth ? 1 : 0.5
                    size: 12.5
                    weight: cell.now ? Font.Bold : Font.DemiBold
                    font.family: root.fontNumbers
                    font.features: ({ "tnum": 1 })
                }
                Rectangle {
                    visible: cell.busy && !cell.now
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.round(parent.height / 2 + month.disc / 2 - root.dp(3))
                    width: root.dp(4)
                    height: width
                    radius: width / 2
                    color: root.shelf
                }
            }
        }
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => root.widget.monthShift = (root.widget.monthShift ?? 0) + (event.angleDelta.y > 0 ? -1 : 1)
        }
    }
    Item {
        enabled: root.turned
        x: root.flapLeft
        y: root.flapTop
        width: root.flapRight - root.flapLeft
        height: root.paneTop - root.flapTop
        HoverHandler { cursorShape: root.turned ? Qt.PointingHandCursor : Qt.ArrowCursor }
        TapHandler { onTapped: root.widget.monthShift = 0 }
    }
}
