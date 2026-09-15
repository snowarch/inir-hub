pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.iris.style

// A figure that counts: when the text changes, only the characters that
// changed roll, the old one leaving and the new one arriving in the counting
// direction (up for values that grow, down for countdowns). Sizes and
// baseline like a Text so it drops into rows that align on baselines.
Item {
    id: root

    property string text: ""
    property string family: IrisStyle.fontNumbers
    property real pixelSize: 15 * IrisStyle.typeScale
    property int weight: Font.Normal
    property real letterSpacing: 0
    property color color: IrisStyle.text
    property int renderType: Text.NativeRendering
    // Countdowns roll the other way.
    property bool countDown: false

    implicitWidth: row.implicitWidth
    implicitHeight: probe.implicitHeight
    baselineOffset: probe.baselineOffset

    Text {
        id: probe
        visible: false
        text: "0"
        font.family: root.family
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        font.features: ({ "tnum": 1 })
    }

    component Glyph: Text {
        font.family: root.family
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        font.letterSpacing: root.letterSpacing
        font.features: ({ "tnum": 1 })
        color: root.color
        renderType: root.renderType
    }

    Row {
        id: row
        Repeater {
            model: root.text.length
            Item {
                id: slot
                required property int index
                readonly property string character: root.text.charAt(slot.index)
                // Rolls run 0 → 1; the old character leaves as the new one lands.
                property real roll: 1
                property string previous: ""
                width: Math.max(current.implicitWidth, slot.roll < 1 ? leaving.implicitWidth : 0)
                height: probe.implicitHeight
                // Structure never changes while rolling (clip always on, glyphs only
                // fade): these figures live inside clipping chassis, which stop
                // painting when their scene changes shape live.
                clip: true

                onCharacterChanged: {
                    const old = current.shown
                    current.shown = slot.character
                    if (!IrisStyle.motionEnabled || IrisStyle.morphDuration <= 0 || !root.visible) return
                    rollAnimation.stop()
                    slot.previous = old
                    slot.roll = 0
                    rollAnimation.start()
                }

                readonly property real travel: slot.height * 0.7 * (root.countDown ? -1 : 1)

                Glyph {
                    id: leaving
                    text: slot.previous
                    y: -slot.travel * slot.roll
                    opacity: 1 - slot.roll
                }
                Glyph {
                    id: current
                    property string shown: ""
                    Component.onCompleted: current.shown = slot.character
                    text: slot.character
                    y: slot.travel * (1 - slot.roll)
                    opacity: slot.roll
                }

                NumberAnimation {
                    id: rollAnimation
                    target: slot
                    property: "roll"
                    to: 1
                    duration: IrisStyle.morphDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: IrisStyle.morphCurve
                }
            }
        }
    }

    Accessible.role: Accessible.StaticText
    Accessible.name: root.text
}
