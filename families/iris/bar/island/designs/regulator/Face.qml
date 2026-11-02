pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.widgets

// Regulator: a jump hour and a retrograde minute. The hour stands in its window; a long needle, hung from behind the top
// of the screen, walks a printed arc through the hour and flies back when it ends.
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
    readonly property var parts: IrisFaceData.clockParts(DateTime.timeDisplay)
    readonly property real gaugeW: Math.round(232 * root.d)
    readonly property real reachR: Math.round(480 * root.d)
    readonly property real lowest: Math.round(root.h * 0.66)
    readonly property real sweep: 2 * Math.asin((root.gaugeW / 2 - Math.round(12 * root.d)) / root.reachR) * 180 / Math.PI
    readonly property int minuteOfHour: root.now.getMinutes()

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(8 * root.d)
        IrisNumber {
            anchors.verticalCenter: parent.verticalCenter
            text: root.parts.hours
            pixelSize: root.figure
            family: root.face
            weight: IrisStyle.figureWeight
        }
        Item {
            id: gauge
            width: root.gaugeW
            height: root.h
            clip: true
            readonly property point pivot: Qt.point(width / 2, root.lowest - root.reachR)
            Canvas {
                id: scale
                anchors.fill: parent
                readonly property var ink: [IrisStyle.text, IrisStyle.textSecondary, IrisStyle.textTertiary]
                onInkChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.translate(gauge.pivot.x, gauge.pivot.y)
                    ctx.textAlign = "center"
                    ctx.font = "600 " + IrisStyle.typeCaption + "px '" + IrisStyle.fontMain + "'"
                    for (let m = 0; m <= 60; m++) {
                        const a = -(m / 60 - 0.5) * root.sweep * Math.PI / 180
                        const major = m % 10 === 0
                        const five = m % 5 === 0
                        const len = major ? 7 : five ? 5 : 3
                        ctx.save()
                        ctx.rotate(a)
                        ctx.strokeStyle = major ? String(IrisStyle.text) : five ? String(IrisStyle.textSecondary) : String(IrisStyle.textTertiary)
                        ctx.lineWidth = major ? 1.5 : 1
                        ctx.beginPath()
                        ctx.moveTo(0, root.reachR - len)
                        ctx.lineTo(0, root.reachR)
                        ctx.stroke()
                        if (major) {
                            ctx.fillStyle = String(IrisStyle.textSecondary)
                            ctx.fillText(String(m), 0, root.reachR - 11)
                        }
                        ctx.restore()
                    }
                }
            }
            Rectangle {
                id: needle
                readonly property real length: root.reachR + Math.round(4 * root.d)
                x: gauge.pivot.x - width / 2
                y: gauge.pivot.y
                width: Math.max(1.5, 2 * root.d)
                height: needle.length
                antialiasing: true
                color: root.mark
                transform: Rotation {
                    id: swing
                    origin.x: needle.width / 2
                    origin.y: 0
                    angle: -(root.minuteOfHour / 60 - 0.5) * root.sweep
                    Behavior on angle {
                        enabled: IrisStyle.motionEnabled
                        // A sprung needle: a step lands, the fly-back on the hour passes its stop a little.
                        SpringAnimation { spring: 4; damping: 0.42; epsilon: 0.02 }
                    }
                }
            }
        }
    }
}
