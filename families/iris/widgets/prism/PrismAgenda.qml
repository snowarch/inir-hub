pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.iris.widgets

// Up next in Prism: the next event's day on the flap, its hour as the figure in the pane with its title beside it,
// the ones after it on the foot. With nothing coming, the pane says so and the foot says until when.
PrismFolder {
    id: root

    readonly property var today: DateTime.clock.date
    readonly property var events: Array.from(root.widget.upcomingEvents ?? [])
    readonly property var next: root.events[0] ?? null
    readonly property var after: root.events.slice(1, root.small ? 1 : root.medium ? 2 : 5)
    readonly property var figure: !root.next ? null : root.next.allDay
        ? { main: String(IrisFaceData.eventDate(root.next).getDate()), suffix: Translation.locale.toString(IrisFaceData.eventDate(root.next), "MMM").replace(/\.$/, "") }
        : IrisFaceData.timeParts(IrisFaceData.clockText(IrisFaceData.eventDate(root.next)))
    function daysTo(event: var): int {
        const start = new Date(root.today)
        start.setHours(0, 0, 0, 0)
        const day = new Date(IrisFaceData.eventDate(event))
        day.setHours(0, 0, 0, 0)
        return Math.round((day.getTime() - start.getTime()) / 86400000)
    }
    function dayLabel(event: var): string {
        const days = root.daysTo(event)
        return days === 0 ? Translation.tr("Today") : days === 1 ? Translation.tr("Tomorrow")
            : IrisFaceData.capitalized(Translation.locale.toString(IrisFaceData.eventDate(event), "ddd d"))
    }

    shelf: root.next && !root.nothing ? IrisFaceData.eventTint(root.next, root.accent) : root.nothing ? root.signal : root.accent
    tabGlyph: "event_upcoming"
    tabText: Translation.tr("Up next")
    flapText: root.next ? root.dayLabel(root.next) : ""

    // ── the pane: the next event ──
    Row {
        id: lead
        visible: root.next !== null
        x: root.inset
        y: Math.round(root.paneMiddle - height / 2)
        spacing: root.dp(2)
        FaceFigure {
            id: hour
            face: root
            text: root.figure?.main ?? ""
            size: root.type(34, 44, 60)
        }
        FaceText {
            face: root
            y: Math.round(hour.height * 0.52)
            text: root.figure?.suffix ?? ""
            color: root.inkSecondary
            size: root.type(12, 13, 16)
            weight: Font.Bold
        }
    }
    FaceText {
        visible: root.next !== null && !root.small
        face: root
        x: lead.x + lead.width + root.dp(14)
        width: root.width - root.inset - x
        y: Math.round(root.paneMiddle - height / 2)
        text: root.next ? IrisFaceData.eventTitle(root.next) : ""
        size: root.type(14, 16, 20)
        weight: Font.DemiBold
        wrapMode: Text.WordWrap
        maximumLineCount: root.large ? 3 : 2
        elide: Text.ElideRight
    }
    FaceText {
        visible: root.next === null
        face: root
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.paneMiddle - height / 2)
        text: Translation.tr("Nothing scheduled")
        size: root.type(15, 18, 24)
        weight: Font.Bold
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: root.px(12)
    }

    // ── the foot: the title (small) or what follows ──
    FaceText {
        visible: root.small || root.next === null
        face: root
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.footTop + (root.footHeight - height) / 2 - root.dp(2))
        text: root.next ? IrisFaceData.eventTitle(root.next) : Translation.tr("The next seven days are free")
        color: root.next ? root.ink : root.inkSecondary
        size: root.next ? 14 : 12.5
        weight: root.next ? Font.DemiBold : Font.Medium
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
    }
    Column {
        visible: !root.small && root.after.length > 0
        x: root.inset
        width: root.innerWidth
        y: root.large ? root.footTop + root.dp(22) : Math.round(root.footTop + (root.footHeight - height) / 2 - root.dp(2))
        spacing: root.dp(12)
        Repeater {
            model: root.small ? [] : root.after
            PrismEventLine {
                required property var modelData
                required property int index
                // Grouped by day: the day is said once, on the first event of it (the one before is the pane's).
                readonly property var before: index === 0 ? root.next : root.after[index - 1]
                readonly property bool sameDay: root.widget.groupByDay && root.daysTo(modelData) === root.daysTo(before)
                readonly property string place: root.widget.showLocation ? String(modelData.location ?? "").trim() : ""
                face: root
                width: root.innerWidth
                event: modelData
                beside: true
                when: (modelData.allDay ? root.dayLabel(modelData)
                    : (sameDay ? "" : root.dayLabel(modelData) + " ") + IrisFaceData.clockText(IrisFaceData.eventDate(modelData)))
                    + (place.length > 0 ? " · " + place : "")
            }
        }
    }
}
