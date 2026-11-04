pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.bar.island

// Rings: three rings nested as a watch's activity rings, outside in: how much of the day has gone (red), the battery
// or, on a desktop, the week (green), the month (blue); the time and the day beside them. They move once a minute.
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
    readonly property real size: Math.round(root.h - 10 * root.d)
    readonly property real band: Math.max(2.5, Math.round(root.size * 0.12))
    readonly property real contentWidth: row.implicitWidth
    readonly property var levels: [
        { value: root.day, tint: IrisStyle.identity.red },
        { value: Battery.available ? Battery.percentage : root.week, tint: Battery.available && Battery.isLow ? IrisStyle.danger : IrisStyle.identity.green },
        { value: root.month, tint: IrisStyle.identity.sky }
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
