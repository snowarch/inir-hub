pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.bar.island

// Rings: three rings nested as a watch's activity rings, outside in red, green and blue; each counts what the person
// picks (iris.bar.faces.rings): the day gone, the week, the month, the year or the battery (the week on a desktop).
// The time and the day beside them. They move once a minute.
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    readonly property date now: DateTime.clock.date
    readonly property real day: (root.now.getHours() * 60 + root.now.getMinutes()) / 1440
    readonly property real week: (((root.now.getDay() + 6) % 7) + root.day) / 7
    readonly property int monthDays: new Date(root.now.getFullYear(), root.now.getMonth() + 1, 0).getDate()
    readonly property real month: (root.now.getDate() - 1 + root.day) / root.monthDays
    readonly property int yearDays: new Date(root.now.getFullYear(), 1, 29).getMonth() === 1 ? 366 : 365
    readonly property real year: (Math.round((new Date(root.now.getFullYear(), root.now.getMonth(), root.now.getDate()) - new Date(root.now.getFullYear(), 0, 1)) / 86400000) + root.day) / root.yearDays
    readonly property var options: Config.options?.iris?.bar?.faces?.rings ?? ({})
    readonly property var counts: ["day", "week", "month", "year", "battery"]
    function pick(key: string, fallback: string): string { return root.counts.includes(String(root.options[key])) ? String(root.options[key]) : fallback }
    function share(kind: string): real {
        switch (kind) {
        case "week": return root.week
        case "month": return root.month
        case "year": return root.year
        case "battery": return Battery.available ? Battery.percentage : root.week
        default: return root.day
        }
    }
    function ring(kind: string, tint: color): var {
        return { value: root.share(kind), tint: kind === "battery" && Battery.available && Battery.isLow && !Battery.isCharging ? IrisStyle.danger : tint }
    }
    readonly property real size: Math.round(root.h - 10 * root.d)
    readonly property real band: Math.max(2.5, Math.round(root.size * 0.12))
    readonly property real contentWidth: row.implicitWidth
    readonly property var levels: [
        root.ring(root.pick("outer", "day"), IrisStyle.identity.red),
        root.ring(root.pick("middle", "battery"), IrisStyle.identity.green),
        root.ring(root.pick("inner", "month"), IrisStyle.identity.sky)
    ]

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(10 * root.d)
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: root.size
            height: root.size
            Repeater {
                model: root.levels
                ProgressRing {
                    required property var modelData
                    required property int index
                    readonly property real inset: index * (root.band + Math.max(1, root.band * 0.25))
                    x: inset
                    y: inset
                    width: root.size - 2 * inset
                    height: width
                    stroke: root.band
                    tint: modelData.tint
                    progress: modelData.value
                    Behavior on progress { NumberAnimation { duration: IrisStyle.duration(700); easing.type: Easing.OutCubic } }
                }
            }
        }
        IrisClock {
            anchors.verticalCenter: parent.verticalCenter
            family: IrisStyle.figureFace(pixelSize)
            minorFamily: family
            pixelSize: root.island?.figureSize ?? IrisStyle.typeHeadline
            separatorColor: root.island?.clockAccent ?? IrisStyle.accent
        }
        IrisText {
            anchors.verticalCenter: parent.verticalCenter
            text: Translation.locale.dayName(root.now.getDay(), Locale.ShortFormat) + " " + root.now.getDate()
            color: IrisStyle.textSecondary
            font.pixelSize: IrisStyle.typeMeta
            font.weight: IrisStyle.weight(Font.DemiBold)
        }
    }
}
