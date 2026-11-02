pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style

IrisWidgetFace {
    id: root
    readonly property bool weekStyle: String(root.widget.familyOption("face", "month")) === "week"
    designFace: root.weekStyle ? "" : IrisDesign.skin("widgetCalendar")

    readonly property var today: DateTime.clock.date
    readonly property var viewing: root.widget.viewingDate
    readonly property bool browsing: root.widget.monthShift !== 0
    readonly property bool adjacent: root.widget.showAdjacentDays
    readonly property var upcoming: IrisFaceData.upcomingEvents(root.today, 7)
    // Only the weeks the month reaches (the engine drops the rest).
    readonly property var cells: root.widget.monthCells()
    // A picked day (click it in the month) takes the place of today in the readout; click it again, or the big day,
    // to let go. The wheel over the month turns the page.
    property var picked: null
    readonly property var focusDay: root.picked ?? root.today
    readonly property var pickedEvents: root.picked ? root.eventsOn(root.picked) : []
    readonly property var shownEvents: root.picked ? root.pickedEvents : root.upcoming
    readonly property var nextEvent: root.shownEvents[0] ?? null
    readonly property string weekday: IrisFaceData.capitalized(Translation.locale.toString(root.focusDay, "dddd"))
    readonly property string emptyLine: root.picked ? Translation.tr("Nothing on this day") : Translation.tr("No events this week")
    function eventsOn(date: var): var {
        return Array.from(Events.getEventsForDate(date) ?? []).concat(Array.from(CalendarSync.getEventsForDate(date) ?? []))
    }
    function sameDay(a: var, b: var): bool {
        return Boolean(a) && Boolean(b) && a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
    }
    function turn(step: int): void {
        root.picked = null
        root.widget.monthShift = step === 0 ? 0 : root.widget.monthShift + step
    }
    // Today as Apple marks it, in the person's accent: a solid fill with its own ink (a pale bubble with dark ink read
    // as chosen, not as today). Under Nothing it is the signal.
    readonly property color todayFill: root.nothing ? root.signal : IrisStyle.accentFill
    readonly property color todayInk: root.nothing ? IrisStyle.onTintFor(root.signal) : IrisStyle.inkOnAccentFill
    readonly property string monthName: IrisFaceData.capitalized(Translation.locale.standaloneMonthName(root.viewing.getMonth()))

    component MonthHead: Row {
        id: head
        property real size: 12
        spacing: root.dp(4)
        FaceText {
            face: root
            text: root.monthName
            color: root.accent
            size: head.size
            weight: Font.Bold
        }
        FaceText {
            face: root
            visible: root.viewing.getFullYear() !== root.today.getFullYear() || head.size > 14
            text: root.viewing.getFullYear()
            color: root.inkTertiary
            size: head.size
            weight: Font.Medium
        }
    }

    // The month sized from the room it has: the cell decides the digits and today's disc, so a small grid is not
    // cramped and a large one is not a sprinkle of 10 px numbers over a big plate.
    component MonthGrid: Item {
        id: grid
        property bool header: true
        // a picked day needs somewhere to read it; the small face has none
        property bool picks: true
        readonly property int rows: Math.max(1, Math.ceil(root.cells.length / 7))
        readonly property real cellW: grid.width / 7
        readonly property real headH: grid.header ? Math.ceil(gridHead.height) + root.dp(6) : 0
        readonly property real daySize: Math.max(8.5, Math.min(11, grid.cellW * 0.3 / root.t))
        readonly property real dayRowH: Math.ceil(dayProbe.height) + root.dp(4)
        readonly property real cellH: Math.max(1, (grid.height - grid.headH - grid.dayRowH) / grid.rows)
        readonly property real digits: Math.max(10, Math.min(15, Math.min(grid.cellW, grid.cellH) * 0.5 / root.t))
        readonly property real disc: Math.max(root.dp(14), Math.min(Math.floor(Math.min(grid.cellW, grid.cellH)) - root.dp(1),
            Math.round(root.px(grid.digits) * 2.1)))

        MonthHead {
            id: gridHead
            visible: grid.header
            size: 12
        }
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => { if (Math.abs(event.angleDelta.y) >= 60) root.turn(event.angleDelta.y < 0 ? 1 : -1) }
        }
        FaceText {
            id: dayProbe
            face: root
            visible: false
            text: "M"
            size: grid.daySize
            weight: Font.DemiBold
        }
        Item {
            y: grid.headH
            width: grid.width
            Repeater {
                model: 7
                FaceText {
                    required property int index
                    face: root
                    x: Math.round(index * grid.cellW + (grid.cellW - width) / 2)
                    text: Translation.locale.dayName((root.widget.weekStart + index) % 7, Locale.NarrowFormat).toUpperCase()
                    color: root.inkTertiary
                    size: grid.daySize
                    weight: Font.DemiBold
                }
            }
        }
        Repeater {
            model: root.cells
            Item {
                id: cell
                required property var modelData
                required property int index
                readonly property var date: new Date(root.viewing.getFullYear(), root.viewing.getMonth()
                    + (cell.modelData.currentMonth ? 0 : cell.index < 7 ? -1 : 1), cell.modelData.day)
                readonly property bool chosen: root.sameDay(root.picked, cell.date)
                x: Math.round((cell.index % 7) * grid.cellW)
                y: Math.round(grid.headH + grid.dayRowH + Math.floor(cell.index / 7) * grid.cellH)
                width: Math.round(((cell.index % 7) + 1) * grid.cellW) - x
                height: Math.round(grid.headH + grid.dayRowH + (Math.floor(cell.index / 7) + 1) * grid.cellH) - y
                Rectangle {
                    x: Math.round((cell.width - width) / 2)
                    y: Math.round((cell.height - height) / 2)
                    width: grid.disc
                    height: width
                    radius: IrisStyle.capsule(width)
                    visible: cell.modelData.isToday || cell.chosen || (dayHover.hovered && cell.modelData.currentMonth && grid.picks)
                    color: cell.modelData.isToday ? root.todayFill : cell.chosen ? root.fillActive : root.fillHover
                    border.width: cell.chosen && !cell.modelData.isToday ? 1 : 0
                    border.color: root.accent
                }
                HoverHandler { id: dayHover; cursorShape: grid.picks || !cell.modelData.currentMonth ? Qt.PointingHandCursor : Qt.ArrowCursor }
                TapHandler {
                    onTapped: {
                        if (!cell.modelData.currentMonth)
                            root.turn(cell.index < 7 ? -1 : 1)
                        else if (grid.picks)
                            root.picked = cell.chosen ? null : cell.date
                    }
                }
                FaceText {
                    face: root
                    x: Math.round((cell.width - width) / 2)
                    y: Math.round((cell.height - height) / 2)
                    visible: cell.modelData.currentMonth || root.adjacent
                    text: cell.modelData.day
                    color: cell.modelData.isToday ? root.todayInk
                        : cell.modelData.currentMonth ? root.ink : root.inkTertiary
                    size: grid.digits
                    weight: cell.modelData.isToday ? Font.Bold : Font.Medium
                    font.family: root.fontNumbers
                    font.features: ({ "tnum": 1 })
                }
            }
        }
    }

    // An event as a tinted rule beside its name and when; the rule is as tall as the two lines, never the room left.
    component EventLine: Item {
        id: line
        property var event: null
        implicitHeight: lineText.height
        Rectangle {
            width: root.dp(3)
            height: lineText.height
            radius: IrisStyle.capsule(width)
            color: IrisFaceData.eventTint(line.event, root.accent)
        }
        Column {
            id: lineText
            x: root.dp(11)
            width: line.width - x
            FaceText {
                face: root
                width: lineText.width
                text: IrisFaceData.eventTitle(line.event)
                size: 12.5
                weight: Font.DemiBold
            }
            FaceText {
                face: root
                width: lineText.width
                text: IrisFaceData.eventWhen(line.event, root.today)
                color: root.inkSecondary
                size: 11.5
            }
        }
    }

    MonthGrid {
        visible: root.small && !root.weekStyle
        anchors.fill: parent
        picks: false
    }

    Loader {
        anchors.fill: parent
        active: root.weekStyle
        sourceComponent: Component { WeekView {} }
    }

    // The Week: today and the days ahead as columns, each day's events where they fall between morning and midnight, so a
    // full afternoon is seen before it is read. It rolls from today: on a Sunday a Monday-to-Sunday week is all past, and
    // a person looks here for what comes. Small keeps three days; large lists what comes under them.
    component WeekView: ColumnLayout {
        id: week
        spacing: root.dp(root.small ? 0 : 8)
        readonly property string dayKey: Qt.formatDate(root.today, "yyyyMMdd")
        // Rebuilt when the day turns, not on every minute of the clock.
        readonly property var days: {
            void week.dayKey
            const start = new Date()
            return Array.from({ length: root.small ? 3 : 7 }, (_, i) => new Date(start.getFullYear(), start.getMonth(), start.getDate() + i))
        }

        RowLayout {
            visible: !root.small
            Layout.fillHeight: false
            Layout.fillWidth: true
            spacing: root.dp(10)
            MonthHead { size: root.large ? 15 : 13 }
            // Large lists the events under the week; on medium this line is all there is of them.
            FaceText {
                face: root
                visible: root.medium
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: root.nextEvent ? IrisFaceData.eventTitle(root.nextEvent) + " · " + IrisFaceData.eventWhen(root.nextEvent, root.today) : root.emptyLine
                color: root.nextEvent ? root.inkSecondary : root.inkTertiary
                size: 12
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.dp(4)
            Repeater {
                model: week.days
                DayColumn {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                }
            }
        }
        Column {
            visible: root.large
            Layout.fillHeight: false
            Layout.fillWidth: true
            spacing: root.dp(8)
            Repeater {
                model: root.large ? root.shownEvents.slice(0, 3) : []
                EventLine {
                    required property var modelData
                    width: parent.width
                    event: modelData
                }
            }
            FaceText {
                face: root
                visible: root.shownEvents.length === 0
                width: parent.width
                text: root.emptyLine
                color: root.inkTertiary
                size: 12.5
            }
        }
    }

    component DayColumn: Rectangle {
        id: column
        required property var modelData
        readonly property bool isToday: root.sameDay(column.modelData, root.today)
        readonly property bool isPicked: root.sameDay(column.modelData, root.picked)
        readonly property var events: root.eventsOn(column.modelData)
        radius: root.dp(8)
        color: column.isPicked ? root.fillActive : column.isToday || press.containsMouse ? root.fill : root.fillQuiet
        // The day's reach: most plans start after breakfast, and six hours of empty morning cost the evening its room.
        readonly property real firstHour: 6
        readonly property real hours: 24 - column.firstHour

        Column {
            id: dayHead
            y: root.dp(root.large ? 8 : 6)
            width: parent.width
            FaceText {
                face: root
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Translation.locale.toString(column.modelData, "ddd").replace(/\./g, "").slice(0, 2)
                color: column.isToday ? root.heading : root.inkTertiary
                size: 10.5
                weight: Font.DemiBold
            }
            FaceFigure {
                face: root
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: column.modelData.getDate()
                size: root.large ? 18 : 16
                tone: column.isToday ? root.accent : root.ink
                rolls: false
            }
        }
        Item {
            id: span
            x: root.dp(4)
            y: dayHead.y + dayHead.height + root.dp(4)
            width: parent.width - 2 * x
            height: parent.height - y - root.dp(5)
            clip: true
            Repeater {
                model: column.events
                Rectangle {
                    id: block
                    required property var modelData
                    readonly property date starts: IrisFaceData.eventDate(block.modelData)
                    readonly property real hour: block.starts.getHours() + block.starts.getMinutes() / 60
                    readonly property real length: {
                        const ends = new Date(block.modelData?.endDate ?? 0).getTime()
                        const hours = (ends - block.starts.getTime()) / 3600000
                        return hours > 0 && hours < 24 ? hours : 1
                    }
                    readonly property bool allDay: Boolean(block.modelData?.allDay)
                    y: block.allDay ? 0 : Math.round(span.height * Math.max(0, block.hour - column.firstHour) / column.hours)
                    width: span.width
                    height: block.allDay ? root.dp(5) : Math.max(root.dp(6), Math.round(span.height * block.length / column.hours))
                    radius: root.dp(3)
                    color: IrisFaceData.eventTint(block.modelData, root.accent)
                }
            }
        }
        MouseArea {
            id: press
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.picked = column.isPicked ? null : column.modelData
        }
    }

    Item {
        visible: root.medium && !root.weekStyle
        anchors.fill: parent

        Column {
            id: dayColumn
            width: Math.round(root.contentWidth * 0.36)
            spacing: 0
            FaceText {
                face: root
                width: dayColumn.width
                text: root.weekday
                color: root.accent
                size: 12
                weight: Font.Bold
            }
            FaceFigure {
                face: root
                width: dayColumn.width
                text: root.focusDay.getDate()
                size: 46
                tone: root.picked ? root.inkSecondary : root.ink
                TapHandler { enabled: root.picked !== null || root.browsing; onTapped: root.turn(0) }
            }
            Item { width: 1; height: root.dp(6) }
            // what the day holds reads right under it, not at the far edge
            EventLine {
                visible: root.nextEvent !== null
                width: dayColumn.width
                event: root.nextEvent
            }
            FaceText {
                face: root
                visible: root.nextEvent === null
                width: dayColumn.width
                text: IrisFaceData.unwidowed(root.emptyLine)
                color: root.inkSecondary
                size: 12
                wrapMode: Text.WordWrap
                maximumLineCount: 2
            }
        }
        MonthGrid {
            x: dayColumn.width + root.dp(16)
            width: parent.width - x
            height: parent.height
        }
    }

    Item {
        id: largeFace
        visible: root.large && !root.weekStyle
        anchors.fill: parent
        // As many of the coming events (up to three) as leave the month a comfortable row per week: the month leads.
        readonly property real eventH: largeProbe.implicitHeight
        readonly property real chrome: largeHead.height + root.dp(10) + root.dp(8) + 1 + root.dp(12) + root.dp(20)
        function weekRow(count: int): real {
            const list = count > 0 ? count * largeFace.eventH + (count - 1) * root.dp(8) : Math.ceil(largeEmpty.implicitHeight)
            return (largeFace.height - largeFace.chrome - list) / Math.max(1, Math.ceil(root.cells.length / 7))
        }
        readonly property int eventsShown: {
            let count = Math.min(root.shownEvents.length, 3)
            while (count > 1 && largeFace.weekRow(count) < root.dp(30))
                --count
            return count
        }

        EventLine { id: largeProbe; visible: false; width: 1; event: root.shownEvents[0] ?? null }

        RowLayout {
            id: largeHead
            width: parent.width
            spacing: root.dp(4)
            MonthHead {
                Layout.fillWidth: true
                size: 18
            }
            Repeater {
                model: [
                    { glyph: "today", shift: 0, shown: root.browsing || root.picked !== null, name: Translation.tr("Today") },
                    { glyph: "chevron_left", shift: -1, shown: true, name: Translation.tr("Previous month") },
                    { glyph: "chevron_right", shift: 1, shown: true, name: Translation.tr("Next month") }
                ]
                Rectangle {
                    id: navButton
                    required property var modelData
                    visible: navButton.modelData.shown
                    Layout.preferredWidth: root.dp(28)
                    Layout.preferredHeight: root.dp(28)
                    radius: IrisStyle.capsule(width)
                    color: navHover.hovered ? root.fillHover : root.fillQuiet
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: navButton.modelData.glyph
                        iconSize: root.px(18)
                        color: root.inkSecondary
                    }
                    HoverHandler { id: navHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.turn(navButton.modelData.shift) }
                    Accessible.role: Accessible.Button
                    Accessible.name: navButton.modelData.name
                }
            }
        }
        MonthGrid {
            y: largeHead.height + root.dp(10)
            width: parent.width
            height: largeRule.y - y - root.dp(8)
            header: false
        }
        Rectangle {
            id: largeRule
            y: largeList.y - root.dp(12)
            width: parent.width
            height: 1
            color: root.hairline
        }
        Column {
            id: largeList
            y: parent.height - height
            width: parent.width
            spacing: root.dp(8)
            Repeater {
                model: root.shownEvents.slice(0, largeFace.eventsShown)
                EventLine {
                    required property var modelData
                    width: largeList.width
                    event: modelData
                }
            }
            FaceText {
                id: largeEmpty
                face: root
                visible: largeFace.eventsShown === 0
                width: largeList.width
                text: root.emptyLine
                color: root.inkSecondary
                size: 12.5
            }
        }
    }
}
