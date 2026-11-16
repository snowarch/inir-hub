pragma ComponentBehavior: Bound

// The wait as a ruler, drawn the same in the iRiS and Prism faces: one tick per stretch of the wait, from the day the
// date was set to the day itself. The ones gone stand in ink, the ones ahead are a track, and today's tick stands
// whole and lit (Prism lays its spectrum over it, and aims the card's light there).
import QtQuick

Item {
    id: root

    property real fraction: 0
    property int ticks: 24
    property real d: 1
    property int feedback: 140 // literal: a face passes its family's feedback duration
    property color ink: "transparent"
    property color track: "transparent"
    property color lit: "transparent"
    property Component litEffect: null

    function dp(v: real): real { return Math.round(v * root.d) }
    readonly property int today: Math.max(0, Math.min(root.ticks - 1, Math.floor(root.fraction * root.ticks)))
    readonly property real step: root.width / Math.max(1, root.ticks)
    // Where today's tick stands in this item, for a face that aims its light there.
    readonly property real todayX: Math.round((root.today + 0.5) * root.step)

    Repeater {
        model: root.ticks
        Rectangle {
            id: tick
            required property int index
            readonly property bool now: tick.index === root.today
            width: Math.max(root.dp(2), Math.round(root.step * (tick.now ? 0.56 : 0.36)))
            height: tick.now ? root.height : Math.round(root.height * (tick.index < root.today ? 0.62 : 0.46))
            x: Math.round((tick.index + 0.5) * root.step - width / 2)
            y: root.height - height
            radius: width / 2
            color: tick.now ? root.lit : tick.index < root.today ? root.ink : root.track
            layer.enabled: tick.now && root.litEffect !== null
            layer.smooth: true
            layer.effect: root.litEffect
            Behavior on color { ColorAnimation { duration: root.feedback; easing.type: Easing.OutCubic } }
        }
    }
}
