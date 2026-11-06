pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.widgets

// World: the time here and a city's beside it, as the Clock app keeps them: a small watch, light by day and dark by night,
// the city's name over its time, how far ahead or behind it is and a +1 when it is already tomorrow there. A second city
// sits beside the first when the person picks one (iris.bar.faces.world). It moves with the minute clock; the shell
// reads each zone's offset every few minutes while the face shows; the hands spring to each new minute. Short of room it
// lets go of how far apart, then the watches, then the second city: the Island never cuts a name or a time.
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    readonly property date now: DateTime.clock.date
    readonly property color mark: root.island?.clockAccent ?? IrisStyle.accent
    readonly property real figure: root.island?.figureSize ?? IrisStyle.typeHeadline
    readonly property string face: root.island?.nothingLook ? IrisStyle.fontDot : IrisStyle.figureFace(root.figure)
    readonly property real contentWidth: row.implicitWidth
    // A slim strip lays each city on one line.
    readonly property bool stacks: root.h >= Math.round(34 * root.d)

    readonly property var options: Config.options?.iris?.bar?.faces?.world ?? ({})
    readonly property string zone: String(root.options.zone ?? "").length > 0 ? String(root.options.zone) : "Asia/Tokyo"
    readonly property string second: String(root.options.second ?? "none")
    readonly property bool apart: root.options.apart !== false
    readonly property bool watch: root.options.watch !== false
    readonly property var shown: root.second !== "none" && root.second.length > 0 && root.second !== root.zone ? [root.zone, root.second] : [root.zone]
    readonly property bool two: root.shown.length > 1
    readonly property int here: -root.now.getTimezoneOffset()

    // What the Island gives the face, and what of it the cities keep: both with everything, without how far apart, without
    // the watches, then the first city alone. A name is never cut.
    readonly property real room: root.island?.faceRoom ?? Math.round(291 * root.d)
    readonly property real lead: clock.implicitWidth + 2 * row.spacing + 1
    function needAt(count: int, apart: bool, watch: bool): real {
        return root.lead + first.need(apart, watch) + (count > 1 ? cities.spacing + other.need(apart, watch) : 0)
    }
    readonly property var plan: {
        const steps = [[root.apart, root.watch], [false, root.watch], [false, false]]
        for (const count of root.two ? [2, 1] : [1])
            for (const step of steps)
                if (root.needAt(count, step[0], step[1]) <= root.room)
                    return { count: count, apart: step[0], watch: step[1] }
        return { count: 1, apart: false, watch: false }
    }
    readonly property bool showApart: root.plan.apart
    readonly property bool showWatch: root.plan.watch

    // The zones it asks the shell to keep, given back when it goes.
    property var held: []
    function hold(): void {
        const next = root.shown.slice()
        if (JSON.stringify(next) === JSON.stringify(root.held))
            return
        next.forEach(tz => WorldClock.want(tz))
        root.held.forEach(tz => WorldClock.release(tz))
        root.held = next
    }
    onShownChanged: root.hold()
    Component.onCompleted: root.hold()
    Component.onDestruction: root.held.forEach(tz => WorldClock.release(tz))

    // "+3 h", "−5:30 h"; nothing when the city keeps this clock.
    function gap(minutes: int): string {
        if (minutes === 0)
            return ""
        const away = Math.abs(minutes)
        const span = away % 60 === 0 ? String(away / 60) : Math.floor(away / 60) + ":" + (away % 60 < 10 ? "0" : "") + away % 60
        return (minutes > 0 ? "+" : "−") + Translation.tr("%1 h").arg(span)
    }

    component City: Row {
        id: city
        required property string tz
        readonly property var offset: WorldClock.offsetOf(city.tz)
        readonly property bool known: city.offset !== undefined
        readonly property int shift: city.known ? Number(city.offset) - root.here : 0
        readonly property date at: new Date(root.now.getTime() + city.shift * 60000)
        readonly property int dayShift: {
            const there = new Date(city.at.getFullYear(), city.at.getMonth(), city.at.getDate())
            const ours = new Date(root.now.getFullYear(), root.now.getMonth(), root.now.getDate())
            return Math.round((there.getTime() - ours.getTime()) / 86400000)
        }
        readonly property bool daylight: city.at.getHours() >= 6 && city.at.getHours() < 18
        readonly property string name: IrisFaceData.cityName(city.tz)
        readonly property string time: city.known ? IrisFaceData.clockText(city.at) : "--:--"
        readonly property string apartText: city.known ? root.gap(city.shift) : ""
        readonly property bool apartShown: root.showApart && city.apartText.length > 0
        spacing: Math.round(7 * root.d)

        // Its width with or without each extra, from what each text measures alone (never from the row it lays out).
        function need(apart: bool, watch: bool): real {
            const name = nameText.implicitWidth
            const away = apart && city.apartText.length > 0 ? apartMeasure.implicitWidth : 0
            const time = cityTime.implicitWidth + (city.dayShift !== 0 ? timeRow.spacing + dayMark.implicitWidth : 0)
            const text = root.stacks ? Math.max(name + (away > 0 ? nameRow.spacing + away : 0), time)
                : name + textGrid.columnSpacing + time + (away > 0 ? timeRow.spacing + away : 0)
            return (watch ? dial.s + city.spacing : 0) + text
        }

        // The Clock app's watch: a light face by day and a dark one by night in either scheme, its hands at the city's hour.
        Item {
            id: dial
            visible: root.showWatch
            anchors.verticalCenter: parent.verticalCenter
            readonly property real s: Math.round(Math.min(root.h - 16 * root.d, 24 * root.d))
            readonly property real c: dial.s / 2
            readonly property color plate: city.daylight ? (IrisStyle.light ? IrisStyle.surfaceHighOpaque : IrisStyle.text)
                : IrisStyle.light ? IrisStyle.text : IrisStyle.fillActive
            readonly property color hands: city.daylight === IrisStyle.light ? IrisStyle.text : IrisStyle.onTintFor(IrisStyle.text)
            readonly property int minuteOfDay: city.at.getHours() * 60 + city.at.getMinutes()
            width: dial.s
            height: dial.s
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: dial.plate
                // A white face on a light Island keeps its rim.
                border.width: IrisStyle.light && city.daylight ? 1 : 0
                border.color: IrisStyle.hairlineStrong
                Behavior on color { enabled: IrisStyle.motionEnabled; ColorAnimation { duration: IrisStyle.duration(600) } }
            }
            Rectangle {
                x: dial.c - width / 2
                y: dial.c - height
                width: Math.max(2, 2 * root.d)
                height: Math.round(dial.c * 0.5)
                radius: width / 2
                antialiasing: true
                color: dial.hands
                transformOrigin: Item.Bottom
                rotation: dial.minuteOfDay * 0.5
                Behavior on rotation { enabled: IrisStyle.motionEnabled; SpringAnimation { spring: 5; damping: 0.5; modulus: 360; epsilon: 0.05 } }
            }
            Rectangle {
                x: dial.c - width / 2
                y: dial.c - height
                width: Math.max(1.5, 1.5 * root.d)
                height: Math.round(dial.c * 0.78)
                radius: width / 2
                antialiasing: true
                color: dial.hands
                transformOrigin: Item.Bottom
                rotation: (dial.minuteOfDay % 60) * 6
                Behavior on rotation { enabled: IrisStyle.motionEnabled; SpringAnimation { spring: 5; damping: 0.5; modulus: 360; epsilon: 0.05 } }
            }
            Rectangle {
                x: dial.c - width / 2
                y: dial.c - height / 2
                width: Math.round(4 * root.d)
                height: width
                radius: width / 2
                color: root.mark
            }
        }
        Grid {
            id: textGrid
            anchors.verticalCenter: parent.verticalCenter
            columns: root.stacks ? 1 : 2
            columnSpacing: Math.round(5 * root.d)
            rowSpacing: 0
            verticalItemAlignment: Grid.AlignVCenter
            Row {
                id: nameRow
                spacing: Math.round(5 * root.d)
                IrisText {
                    id: nameText
                    text: city.name
                    font.pixelSize: IrisStyle.typeCaption
                    font.weight: IrisStyle.weight(Font.DemiBold)
                    color: IrisStyle.textSecondary
                }
                IrisText {
                    id: apartMeasure
                    visible: city.apartShown && root.stacks
                    text: city.apartText
                    font.pixelSize: IrisStyle.typeCaption
                    font.weight: IrisStyle.weight(Font.Medium)
                    font.features: ({ "tnum": 1 })
                    color: IrisStyle.textTertiary
                }
            }
            Row {
                id: timeRow
                spacing: Math.round(3 * root.d)
                IrisText {
                    id: cityTime
                    text: city.time
                    font.pixelSize: root.stacks ? IrisStyle.typeMeta : IrisStyle.typeFootnote
                    font.weight: IrisStyle.weight(Font.DemiBold)
                    font.features: ({ "tnum": 1 })
                    color: IrisStyle.text
                }
                // Tomorrow or yesterday there, the way a flight's arrival says it.
                IrisText {
                    id: dayMark
                    visible: city.dayShift !== 0
                    anchors.top: cityTime.top
                    text: (city.dayShift > 0 ? "+" : "−") + Math.abs(city.dayShift)
                    font.pixelSize: Math.max(8, IrisStyle.typeCaption - 2)
                    font.weight: IrisStyle.weight(Font.Bold)
                    font.features: ({ "tnum": 1 })
                    color: root.mark
                }
                IrisText {
                    visible: city.apartShown && !root.stacks
                    anchors.verticalCenter: cityTime.verticalCenter
                    text: city.apartText
                    font.pixelSize: IrisStyle.typeCaption
                    font.weight: IrisStyle.weight(Font.Medium)
                    font.features: ({ "tnum": 1 })
                    color: IrisStyle.textTertiary
                }
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(10 * root.d)
        IrisClock {
            id: clock
            anchors.verticalCenter: parent.verticalCenter
            pixelSize: root.figure
            family: root.face
            separatorColor: root.mark
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: Math.round(root.h * 0.46)
            color: IrisStyle.hairlineStrong
        }
        Row {
            id: cities
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(14 * root.d)
            City { id: first; tz: root.zone }
            City { id: other; visible: root.two && root.plan.count > 1; tz: root.two ? root.shown[1] : "" }
        }
    }
}
