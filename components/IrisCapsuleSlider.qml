pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style

// Control Center level: a thick capsule whose light fill is the value, with the
// glyph living inside it (dark over the fill, light over the track).
Item {
    id: root

    property real value: 0
    property string icon: "volume_up"
    property bool muted: false
    property color fillColor: IrisStyle.text
    signal moved(real value)
    signal iconClicked()

    property real dragValue: -1
    readonly property real shownValue: Math.max(0, Math.min(1, root.dragValue >= 0 ? root.dragValue : root.value))

    implicitWidth: 260
    implicitHeight: Math.round(44 * IrisStyle.density)
    Accessible.role: Accessible.Slider

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: ColorUtils.applyAlpha(IrisStyle.text, 0.1)
        scale: pointer.pressed ? 1.015 : 1
        Behavior on scale { NumberAnimation { duration: IrisStyle.duration(120); easing.type: Easing.OutCubic } }

        Item {
            id: fillClip
            // Never narrower than the glyph pocket so an empty level still
            // reads as a capsule with its icon, not a bare dot.
            width: Math.max(track.height, track.width * root.shownValue)
            height: track.height
            clip: true
            Behavior on width {
                enabled: root.dragValue < 0
                NumberAnimation { duration: IrisStyle.duration(110); easing.type: Easing.OutCubic }
            }
            Rectangle {
                width: track.width
                height: track.height
                radius: height / 2
                color: root.muted ? ColorUtils.applyAlpha(IrisStyle.text, 0.35) : root.fillColor
            }
        }

        MaterialSymbol {
            anchors.left: parent.left
            anchors.leftMargin: (track.height - iconSize) / 2
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            fill: 1
            iconSize: Math.round(20 * IrisStyle.density)
            color: root.muted ? IrisStyle.text : IrisStyle.surface
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function valueAt(px: real): real { return Math.max(0, Math.min(1, px / Math.max(1, width))) }
        onPressed: mouse => {
            if (mouse.x < track.height) return
            root.dragValue = valueAt(mouse.x)
            root.moved(root.dragValue)
        }
        onPositionChanged: mouse => {
            if (!pressed || root.dragValue < 0) return
            root.dragValue = valueAt(mouse.x)
            root.moved(root.dragValue)
        }
        onReleased: mouse => {
            if (root.dragValue < 0 && mouse.x < track.height) root.iconClicked()
            root.dragValue = -1
        }
        onCanceled: root.dragValue = -1
        onWheel: wheel => {
            const delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y * 4
            root.moved(Math.max(0, Math.min(1, root.value + (delta > 0 ? 0.05 : -0.05))))
        }
    }
}
