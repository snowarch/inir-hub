pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common.functions
import qs.modules.iris.style

// Continuous media timeline: one uninterrupted capsule that thickens under the
// pointer, instead of Material's split active/inactive track with a gap.
Item {
    id: root

    property real value: 0
    property bool seekable: true
    property color fillColor: IrisStyle.text
    property color trackColor: ColorUtils.applyAlpha(IrisStyle.text, 0.2)
    signal seekRequested(real value)
    // Emitted continuously while dragging (settings levels); media seeks only
    // commit on release through seekRequested.
    signal moved(real value)
    property bool knob: false

    property real dragValue: -1
    readonly property bool engaged: root.seekable && (pointer.containsMouse || pointer.pressed)
    readonly property real shownValue: Math.max(0, Math.min(1, root.dragValue >= 0 ? root.dragValue : root.value))

    implicitWidth: 200
    implicitHeight: Math.round(14 * IrisStyle.density)

    Accessible.role: Accessible.Slider

    Item {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: Math.round((root.engaged ? 8 : 5) * IrisStyle.density)
        Behavior on height { NumberAnimation { duration: IrisStyle.duration(120); easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: root.trackColor
        }
        Item {
            width: track.width * root.shownValue
            height: track.height
            clip: true
            Rectangle {
                width: track.width
                height: track.height
                radius: height / 2
                color: root.fillColor
            }
        }
    }

    Rectangle {
        visible: root.knob
        width: Math.round((root.engaged ? 20 : 18) * IrisStyle.density)
        height: width
        radius: width / 2
        x: Math.max(0, Math.min(root.width - width, root.width * root.shownValue - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        color: "#ffffff"
        border.width: 1
        border.color: ColorUtils.applyAlpha("#000000", 0.12)
        Behavior on width { NumberAnimation { duration: IrisStyle.duration(120); easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        anchors.topMargin: -4
        anchors.bottomMargin: -4
        enabled: root.seekable
        hoverEnabled: true
        cursorShape: root.seekable ? Qt.PointingHandCursor : Qt.ArrowCursor
        function valueAt(px: real): real { return Math.max(0, Math.min(1, px / Math.max(1, width))) }
        onPressed: mouse => { root.dragValue = valueAt(mouse.x); root.moved(root.dragValue) }
        onPositionChanged: mouse => { if (pressed) { root.dragValue = valueAt(mouse.x); root.moved(root.dragValue) } }
        onReleased: {
            if (root.dragValue >= 0) root.seekRequested(root.dragValue)
            root.dragValue = -1
        }
        onCanceled: root.dragValue = -1
    }
}
