pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.iris.widgets

// A week on the folder's foot: each day's initial (and date), today on the widget's colour.
Item {
    id: week
    required property var face
    property var today: new Date()
    property bool dates: false
    readonly property real cell: week.width / 7
    readonly property real disc: week.face.pick(20, 24, 32)
    readonly property var days: {
        const first = Number(Translation.locale.firstDayOfWeek ?? 1) % 7
        const start = new Date(week.today.getFullYear(), week.today.getMonth(), week.today.getDate())
        start.setDate(start.getDate() - (start.getDay() - first + 7) % 7)
        const out = []
        for (let i = 0; i < 7; i++) {
            const day = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
            out.push({ initial: Translation.locale.toString(day, "ddd").charAt(0).toUpperCase(), date: day.getDate(),
                now: day.getDate() === week.today.getDate() && day.getMonth() === week.today.getMonth() })
        }
        return out
    }
    implicitHeight: week.dates ? week.disc + week.face.px(week.face.type(11, 12, 14)) + week.face.dp(4) : week.disc

    Repeater {
        model: week.days
        Item {
            id: day
            required property var modelData
            required property int index
            x: Math.round(day.index * week.cell)
            width: Math.round(week.cell)
            height: week.height
            FaceText {
                visible: week.dates
                face: week.face
                anchors.horizontalCenter: parent.horizontalCenter
                text: day.modelData.initial
                color: day.modelData.now ? week.face.ink : week.face.inkTertiary
                size: week.face.type(10.5, 11, 13)
                weight: Font.DemiBold
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: week.disc
                height: week.disc
                radius: width / 2
                color: day.modelData.now ? week.face.shelf : "transparent"
                FaceText {
                    face: week.face
                    anchors.centerIn: parent
                    text: week.dates ? String(day.modelData.date) : day.modelData.initial
                    color: day.modelData.now ? week.face.inkOnShelf : week.dates ? week.face.inkSecondary : week.face.inkTertiary
                    size: week.face.type(11, 12, 15)
                    weight: day.modelData.now ? Font.Bold : Font.DemiBold
                    font.family: week.face.fontNumbers
                    font.features: ({ "tnum": 1 })
                }
            }
        }
    }
}
