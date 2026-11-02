pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.widgets

// Ledger · Entry: the time and what comes next, dotted leaders between them. The distance is real: a dot for every
// quarter of an hour left, so the Island tightens as the event nears; while it runs the dots take the accent and count
// down to its end. Nothing ahead, the entry is the day. Only the resting clock; the engine draws media, timers, notices
// and levels.
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    // A slim strip keeps the entry on the time's line.
    readonly property bool stacks: root.h >= Math.round(34 * root.d)
    readonly property real contentWidth: row.implicitWidth
    readonly property date now: DateTime.clock.date
    readonly property color mark: root.island?.clockAccent ?? IrisStyle.accent
    readonly property int minute: Math.floor(root.now.getTime() / 60000)
    readonly property real nameRoom: Math.round(132 * root.d)

    readonly property int maxDots: 12
    readonly property int minutesPerDot: 15
    // Past this the day says more than a far-off hour.
    readonly property int reachMinutes: 720

    function dotsTo(ms: real): int {
        return Math.min(root.maxDots, Math.max(1, Math.ceil(ms / 60000 / root.minutesPerDot)))
    }

    readonly property var entry: {
        const at = root.minute * 60000
        const here = new Date(at)
        const running = Array.from(CalendarSync.getEventsForDate(here) ?? []).find(event => !event.allDay && event.endDate
            && new Date(event.startDate).getTime() <= at && at < new Date(event.endDate).getTime())
        if (running) {
            const end = new Date(running.endDate)
            return { title: IrisFaceData.eventTitle(running), dots: root.dotsTo(end.getTime() - at), live: true,
                gloss: Translation.tr("until %1").arg(IrisFaceData.clockText(end)) }
        }
        const ahead = IrisFaceData.upcomingEvents(here, 1)
        const next = ahead.find(event => {
            const left = IrisFaceData.eventDate(event).getTime() - at
            return !event.allDay && left > 0 && left <= root.reachMinutes * 60000
        })
        if (next) {
            const start = IrisFaceData.eventDate(next)
            return { title: IrisFaceData.eventTitle(next), dots: root.dotsTo(start.getTime() - at), live: false,
                gloss: IrisFaceData.clockText(start) }
        }
        const allDay = ahead.find(event => event.allDay && IrisFaceData.eventDate(event).getTime() <= at)
        return { title: allDay ? IrisFaceData.eventTitle(allDay) : "", dots: 3, live: false, gloss: "" }
    }
    readonly property bool named: root.entry.title.length > 0
    readonly property string dayDate: Translation.locale.toString(root.now, "d MMM").replace(/\.$/, "")

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(9 * root.d)

        IrisClock {
            id: clock
            anchors.verticalCenter: parent.verticalCenter
            pixelSize: root.island?.figureSize ?? IrisStyle.typeHeadline
            family: root.island?.nothingLook ? IrisStyle.fontDot : IrisStyle.figureFace(pixelSize)
            separatorColor: root.mark
        }

        // Leaders stand on the figures' baseline, as on a printed page.
        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: Math.round(clock.pixelSize * 0.32)
            spacing: Math.round(4 * root.d)
            Repeater {
                model: root.maxDots
                Rectangle {
                    required property int index
                    visible: index < root.entry.dots
                    width: Math.max(2, Math.round(2 * root.d))
                    height: width
                    radius: width / 2
                    color: root.entry.live ? root.mark : IrisStyle.textTertiary
                }
            }
        }

        Column {
            visible: root.stacks
            anchors.verticalCenter: parent.verticalCenter
            IrisText {
                width: Math.min(implicitWidth, root.nameRoom)
                text: root.named ? root.entry.title : Translation.locale.toString(root.now, "dddd").toUpperCase()
                elide: Text.ElideRight
                font.pixelSize: Math.round((root.named ? 12 : 9) * root.d)
                font.weight: IrisStyle.weight(root.named ? Font.DemiBold : Font.Bold)
                font.letterSpacing: root.named ? 0 : 1.1
                color: root.named ? IrisStyle.text : root.mark
            }
            IrisText {
                text: root.entry.gloss || root.dayDate
                font.pixelSize: Math.round((root.named ? 10 : 12) * root.d)
                font.weight: IrisStyle.weight(Font.Medium)
                font.features: ({ "tnum": 1 })
                color: IrisStyle.subtext
            }
        }
        Row {
            visible: !root.stacks
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(6 * root.d)
            IrisText {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, root.nameRoom)
                text: root.named ? root.entry.title : Translation.locale.toString(root.now, "ddd d").replace(/\./g, "").toUpperCase()
                elide: Text.ElideRight
                font.pixelSize: Math.round(11 * root.d)
                font.weight: IrisStyle.weight(Font.DemiBold)
                font.letterSpacing: root.named ? 0 : 0.8
                color: root.named ? IrisStyle.text : IrisStyle.subtext
            }
            IrisText {
                visible: root.entry.gloss.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: root.entry.gloss
                font.pixelSize: Math.round(10 * root.d)
                font.weight: IrisStyle.weight(Font.Medium)
                font.features: ({ "tnum": 1 })
                color: IrisStyle.subtext
            }
        }
    }
}
