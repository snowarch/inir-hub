pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.widgets

// Dial · Watch: a watch with real hands, the minute in the accent, stepping when it turns; the day beside it.
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    readonly property date now: DateTime.clock.date
    readonly property color mark: root.island?.clockAccent ?? IrisStyle.accent
    readonly property int minute: Math.floor(root.now.getTime() / 60000)
    readonly property real figure: root.island?.figureSize ?? IrisStyle.typeHeadline
    readonly property string face: root.island?.nothingLook ? IrisStyle.fontDot : IrisStyle.figureFace(root.figure)
    readonly property real contentWidth: row.implicitWidth

    readonly property real size: Math.round(root.h - 10 * root.d)
    // Local minutes since the epoch: the hands only ever go forward, so a turn past midnight never unwinds.
    readonly property int localMinute: root.minute - root.now.getTimezoneOffset()

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(10 * root.d)
        Item {
            id: dial
            anchors.verticalCenter: parent.verticalCenter
            width: root.size
            height: root.size
            readonly property real c: root.size / 2
            // The face thins out with the strip: all twelve, the quarters, then the hands alone.
            readonly property bool fine: root.size >= Math.round(28 * root.d)
            readonly property bool quarters: root.size >= Math.round(24 * root.d)
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: IrisStyle.fillQuiet
            }
            Repeater {
                model: 12
                Item {
                    id: tick
                    required property int index
                    readonly property bool quarter: tick.index % 3 === 0
                    visible: tick.quarter ? dial.quarters : dial.fine
                    x: dial.c
                    y: dial.c
                    rotation: tick.index * 30
                    Rectangle {
                        x: -width / 2
                        y: -dial.c + Math.round(3 * root.d)
                        width: tick.quarter ? 2 : 1
                        height: tick.quarter ? Math.round(4 * root.d) : Math.round(2 * root.d)
                        antialiasing: true
                        color: tick.quarter ? IrisStyle.textSecondary : IrisStyle.textTertiary
                    }
                }
            }
            Rectangle {
                x: dial.c - width / 2
                y: dial.c - height
                width: Math.max(2.5, 3 * root.d)
                height: Math.round(dial.c * 0.5)
                radius: width / 2
                antialiasing: true
                color: IrisStyle.text
                transformOrigin: Item.Bottom
                rotation: root.localMinute * 0.5
                Behavior on rotation { enabled: IrisStyle.motionEnabled; NumberAnimation { duration: IrisStyle.duration(420); easing.type: Easing.OutCubic } }
            }
            Rectangle {
                x: dial.c - width / 2
                y: dial.c - height
                width: Math.max(2, 2 * root.d)
                height: Math.round(dial.c * 0.74)
                radius: width / 2
                antialiasing: true
                color: root.mark
                transformOrigin: Item.Bottom
                rotation: root.localMinute * 6
                Behavior on rotation { enabled: IrisStyle.motionEnabled; NumberAnimation { duration: IrisStyle.duration(420); easing.type: Easing.OutCubic } }
            }
            Rectangle {
                x: dial.c - width / 2
                y: dial.c - height / 2
                width: Math.round(5 * root.d)
                height: width
                radius: width / 2
                color: root.mark
            }
        }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(4 * root.d)
            IrisText {
                anchors.baseline: dayNumber.baseline
                text: Translation.locale.toString(root.now, "ddd").replace(/\./g, "")
                font.pixelSize: IrisStyle.typeMeta
                font.weight: IrisStyle.weight(Font.Medium)
                color: IrisStyle.textSecondary
            }
            IrisText {
                id: dayNumber
                text: Translation.locale.toString(root.now, "d")
                font.pixelSize: IrisStyle.typeLabel
                font.family: root.face
                font.weight: IrisStyle.weight(Font.Bold)
                font.features: ({ "tnum": 1 })
                color: IrisStyle.text
            }
        }
    }
}
