pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style

// Control Center level: a thick capsule whose light fill is the value, with the
// glyph living inside it (dark over the fill, light over the track). Vertical
// capsules fill from the bottom with the glyph at their foot.
Item {
    id: root

    property real value: 0
    property string icon: "volume_up"
    property bool muted: false
    property bool vertical: false
    property color fillColor: IrisStyle.text
    signal moved(real value)
    signal iconClicked()

    property real dragValue: -1
    readonly property real shownValue: Math.max(0, Math.min(1, root.dragValue >= 0 ? root.dragValue : root.value))
    readonly property real thickness: root.vertical ? root.width : root.height
    readonly property real span: root.vertical ? root.height : root.width

    implicitWidth: root.vertical ? Math.round(46 * IrisStyle.density) : 260
    implicitHeight: root.vertical ? 120 : Math.round(44 * IrisStyle.density)
    Accessible.role: Accessible.Slider

    Rectangle {
        id: track
        anchors.fill: parent
        radius: root.thickness / 2
        color: ColorUtils.applyAlpha(IrisStyle.text, 0.1)
        scale: pointer.pressed ? 1.015 : 1
        Behavior on scale { NumberAnimation { duration: IrisStyle.duration(120); easing.type: Easing.OutCubic } }

        Item {
            id: fillClip
            // Never shorter than the glyph pocket so an empty level still
            // reads as a capsule with its icon, not a bare dot.
            property real length: Math.max(root.thickness, root.span * root.shownValue)
            Behavior on length {
                enabled: root.dragValue < 0
                NumberAnimation { duration: IrisStyle.duration(110); easing.type: Easing.OutCubic }
            }
            y: root.vertical ? track.height - fillClip.length : 0
            width: root.vertical ? track.width : fillClip.length
            height: root.vertical ? fillClip.length : track.height
            clip: true
            Rectangle {
                y: -fillClip.y
                width: track.width
                height: track.height
                radius: root.thickness / 2
                color: root.muted ? ColorUtils.applyAlpha(IrisStyle.text, 0.35) : root.fillColor
            }
        }

        MaterialSymbol {
            readonly property real pocket: (root.thickness - iconSize) / 2
            x: pocket
            y: root.vertical ? track.height - root.thickness + pocket : pocket
            text: root.icon
            fill: 1
            iconSize: Math.round((root.vertical ? 19 : 20) * IrisStyle.density)
            color: root.muted ? IrisStyle.text : IrisStyle.surface
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        // A drag that wanders stays on the level instead of scrolling the page.
        preventStealing: true
        function valueAt(mouse): real {
            return Math.max(0, Math.min(1, root.vertical ? 1 - mouse.y / Math.max(1, height) : mouse.x / Math.max(1, width)))
        }
        function inPocket(mouse): bool {
            return root.vertical ? mouse.y > height - root.thickness : mouse.x < root.thickness
        }
        onPressed: mouse => {
            if (inPocket(mouse)) return
            root.dragValue = valueAt(mouse)
            root.moved(root.dragValue)
        }
        onPositionChanged: mouse => {
            if (!pressed || root.dragValue < 0) return
            root.dragValue = valueAt(mouse)
            root.moved(root.dragValue)
        }
        onReleased: mouse => {
            if (root.dragValue < 0 && inPocket(mouse)) root.iconClicked()
            root.dragValue = -1
        }
        onCanceled: root.dragValue = -1
        // Wheel notches step 5 %; touchpad pixel deltas accumulate into steps.
        property real wheelAccumulator: 0
        onWheel: wheel => {
            const delta = (wheel.angleDelta.y || wheel.angleDelta.x) || (wheel.pixelDelta.y || wheel.pixelDelta.x) * 4
            pointer.wheelAccumulator += delta
            const steps = Math.trunc(pointer.wheelAccumulator / 120)
            if (steps === 0) return
            pointer.wheelAccumulator -= steps * 120
            root.moved(Math.max(0, Math.min(1, root.value + steps * 0.05)))
        }
    }
}
