pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// Dial · Tuner: the hour as the figure and the hour's minutes as a radio's scale behind a fixed needle, the minute
// riding the needle's head. The scale slides one step when the minute turns; nothing moves between.
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    readonly property real contentWidth: row.implicitWidth
    readonly property date now: DateTime.clock.date
    readonly property var parts: {
        const raw = String(DateTime.timeDisplay ?? "").trim()
        const period = raw.match(/\s*([^\d:.\s]+)$/)
        const pieces = (period ? raw.slice(0, period.index) : raw).split(/[:.]/)
        return { hours: String(pieces[0] ?? ""), minutes: String(pieces[1] ?? ""), period: period ? period[1] : "" }
    }
    readonly property color mark: root.island?.clockAccent ?? IrisStyle.accent
    readonly property real figurePx: Math.round((root.island?.figureSize ?? IrisStyle.typeHeadline) * 1.08)
    readonly property int minute: root.now.getHours() * 60 + root.now.getMinutes()
    readonly property real step: Math.round(4 * root.d)
    // Where the scale stands, in minutes; a turn of one or two slides, anything else (midnight, a wake) lands.
    property real at: root.minute
    onMinuteChanged: {
        if (!IrisStyle.motionEnabled || Math.abs(root.minute - root.at) > 3) { slide.stop(); root.at = root.minute; return }
        slide.restart()
    }
    NumberAnimation { id: slide; target: root; property: "at"; to: root.minute; duration: IrisStyle.duration(420); easing.type: Easing.OutCubic }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(7 * root.d)

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(2 * root.d)
            IrisText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.parts.hours
                font.pixelSize: root.figurePx
                font.family: root.island?.nothingLook ? IrisStyle.fontDot : IrisStyle.figureFace(root.figurePx)
                font.weight: IrisStyle.weight(Font.Bold)
                font.features: ({ "tnum": 1 })
                color: IrisStyle.text
            }
            IrisText {
                visible: root.parts.period.length > 0
                anchors.baseline: parent.children[0].baseline
                text: root.parts.period
                font.pixelSize: Math.round(9 * root.d)
                font.weight: IrisStyle.weight(Font.Bold)
                color: IrisStyle.textSecondary
            }
        }

        // The tuner window: a quiet plate, ticks every minute, taller every five, the quarters named, fading to its ends.
        Rectangle {
            id: tuner
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(118 * root.d)
            height: Math.round(root.h - 12 * root.d)
            radius: Math.min(height / 2, IrisStyle.radiusRow)
            color: IrisStyle.fillQuiet
            clip: true
            readonly property real middle: Math.round(width / 2)
            readonly property real foot: height - Math.round(5 * root.d)

            Repeater {
                model: 37
                Item {
                    id: tick
                    required property int index
                    readonly property int t: root.minute + tick.index - 18
                    readonly property int m: ((tick.t % 60) + 60) % 60
                    readonly property real place: tuner.middle + (tick.t - root.at) * root.step
                    x: Math.round(tick.place)
                    width: 1
                    height: tuner.height
                    opacity: Math.max(0, 1 - Math.abs(tick.place - tuner.middle) / tuner.middle)
                    Rectangle {
                        x: -width / 2
                        y: tuner.foot - height
                        width: Math.max(1, IrisStyle.devicePx)
                        height: Math.round((tick.m % 15 === 0 ? 9 : tick.m % 5 === 0 ? 6 : 3) * root.d)
                        color: tick.m % 5 === 0 ? IrisStyle.textSecondary : IrisStyle.hairlineStrong
                    }
                    IrisText {
                        visible: tick.m % 15 === 0
                        x: -implicitWidth / 2
                        y: Math.round(3 * root.d)
                        text: tick.m === 0 ? String((Math.floor(((tick.t / 60) % 24 + 24) % 24))).padStart(2, "0") : String(tick.m)
                        font.pixelSize: Math.round(8 * root.d)
                        font.family: IrisStyle.fontNumbers
                        font.weight: IrisStyle.weight(Font.DemiBold)
                        font.features: ({ "tnum": 1 })
                        color: IrisStyle.textTertiary
                    }
                }
            }
            // The needle stands still; the minute rides its head.
            Rectangle {
                x: tuner.middle - width / 2
                y: Math.round(3 * root.d) + needleHead.height
                width: Math.max(2, Math.round(1.5 * root.d))
                height: tuner.foot - y + Math.round(1 * root.d)
                radius: width / 2
                color: root.mark
            }
            Rectangle {
                id: needleHead
                x: tuner.middle - width / 2
                y: Math.round(2 * root.d)
                width: minuteText.implicitWidth + Math.round(8 * root.d)
                height: minuteText.implicitHeight
                radius: height / 2
                color: root.mark
                IrisText {
                    id: minuteText
                    anchors.centerIn: parent
                    text: root.parts.minutes
                    font.pixelSize: Math.round(10 * root.d)
                    font.family: IrisStyle.fontNumbers
                    font.weight: IrisStyle.weight(Font.Bold)
                    font.features: ({ "tnum": 1 })
                    color: IrisStyle.onTintFor(root.mark)
                }
            }
        }
    }
}
