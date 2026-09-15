pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common.functions
import qs.modules.iris.style

// Continuous media timeline: one uninterrupted capsule that thickens under the
// pointer (and while focused), instead of Material's split active/inactive
// track with a gap. No outline: focus reads from the thicker track and knob.
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
    property real stepSize: 0.05
    activeFocusOnTab: root.seekable

    property real dragValue: -1
    readonly property bool engaged: root.seekable && (pointer.containsMouse || pointer.pressed || root.activeFocus)
    readonly property real shownValue: Math.max(0, Math.min(1, root.dragValue >= 0 ? root.dragValue : root.value))

    implicitWidth: 200
    implicitHeight: Math.round(14 * IrisStyle.density)

    Accessible.role: Accessible.Slider
    Keys.onPressed: event => {
        if (!root.seekable) return
        let next = root.shownValue
        if (event.key === Qt.Key_Right || event.key === Qt.Key_Up) next += root.stepSize
        else if (event.key === Qt.Key_Left || event.key === Qt.Key_Down) next -= root.stepSize
        else if (event.key === Qt.Key_Home) next = 0
        else if (event.key === Qt.Key_End) next = 1
        else return
        next = Math.max(0, Math.min(1, next))
        root.moved(next)
        root.seekRequested(next)
        event.accepted = true
    }

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
        onPressed: mouse => { root.forceActiveFocus(); root.dragValue = valueAt(mouse.x); root.moved(root.dragValue) }
        onPositionChanged: mouse => { if (pressed) { root.dragValue = valueAt(mouse.x); root.moved(root.dragValue) } }
        onReleased: {
            if (root.dragValue >= 0) root.seekRequested(root.dragValue)
            root.dragValue = -1
        }
        onCanceled: root.dragValue = -1
        // A drag that wanders vertically stays on the slider instead of
        // scrolling the page it sits in.
        preventStealing: true
        // The wheel steps the value (and is not passed on to scroll the page).
        // Touchpad pixel deltas accumulate into the same steps.
        property real wheelAccumulator: 0
        onWheel: wheel => {
            const delta = (wheel.angleDelta.y || wheel.angleDelta.x) || (wheel.pixelDelta.y || wheel.pixelDelta.x) * 4
            pointer.wheelAccumulator += delta
            const steps = Math.trunc(pointer.wheelAccumulator / 120)
            if (steps === 0) return
            pointer.wheelAccumulator -= steps * 120
            const next = Math.max(0, Math.min(1, root.shownValue + steps * root.stepSize))
            root.moved(next)
            root.seekRequested(next)
        }
    }
}
