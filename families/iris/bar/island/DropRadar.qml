pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style

// AirDrop's mark: a disc with an arrow in rings. Held over the Island, a wave runs out through the rings; still,
// the rings rest as the mark itself.
Item {
    id: radar
    property color tint: IrisStyle.accent
    property bool live: false
    readonly property real r: Math.min(width, height) / 2
    readonly property real line: Math.max(1.6, 2 * IrisStyle.density)

    Repeater {
        model: [0.66, 1]
        Rectangle {
            required property real modelData
            anchors.centerIn: parent
            width: Math.round(radar.r * 2 * modelData - radar.line)
            height: width
            radius: width / 2
            color: "transparent"
            border.width: radar.line
            border.color: radar.tint
            opacity: radar.live ? 0.32 : (modelData < 1 ? 0.75 : 0.45)
        }
    }
    Repeater {
        model: radar.live ? 2 : 0
        Rectangle {
            id: wave
            required property int index
            property real t: 0
            anchors.centerIn: parent
            width: radar.r * 2 * (0.42 + 0.58 * wave.t)
            height: width
            radius: width / 2
            color: "transparent"
            border.width: radar.line * 1.15
            border.color: radar.tint
            opacity: Math.pow(1 - wave.t, 0.7)
            SequentialAnimation on t {
                running: radar.visible && IrisStyle.motionEnabled
                loops: Animation.Infinite
                PauseAnimation { duration: wave.index * 650 }
                NumberAnimation { from: 0; to: 1; duration: 1300; easing.type: Easing.OutSine }
            }
        }
    }
    Rectangle {
        anchors.centerIn: parent
        width: Math.round(radar.r * 0.86)
        height: width
        radius: width / 2
        color: radar.tint
        Glyph {
            anchors.centerIn: parent
            text: "arrow_downward_alt"
            iconSize: Math.round(parent.width * 0.78)
            color: IrisStyle.onTintFor(radar.tint)
        }
    }
}
