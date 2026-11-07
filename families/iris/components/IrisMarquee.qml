pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.modules.iris.style

// A line that never cuts its words (Apple's Now Playing title): longer than its box, it rests, slides through once at
// reading speed and comes round again, faded at the edges it passes. Without motion it elides.
Item {
    id: root
    property string text: ""
    property color color: IrisStyle.text
    property int pixelSize: IrisStyle.typeBody
    property int weight: Font.Normal
    property bool running: true
    // Where a line that fits sits in its box; a moving one always starts at the left.
    property int horizontalAlignment: Text.AlignLeft
    readonly property bool overflows: first.implicitWidth > root.width + 0.5
    readonly property bool moving: root.overflows && IrisStyle.motionEnabled
    readonly property real gap: Math.round(root.pixelSize * 2.5)
    readonly property real fade: Math.round(root.pixelSize * 1.2)
    property real offset: 0
    // One pass: the rest and the slide through, so a caller can run it once.
    readonly property int passDuration: 2600 + Math.round((first.implicitWidth + root.gap) / (30 * IrisStyle.density) * 1000)
    implicitWidth: first.implicitWidth
    implicitHeight: still.implicitHeight
    clip: true

    // Still: the line elided in its box. Moving: two whole copies on a strip, never elided (one text switching
    // between elided and whole mid-pass kept its cut layout and slid the "…" through).
    IrisText {
        id: still
        visible: !root.moving
        width: root.width
        horizontalAlignment: root.horizontalAlignment
        text: root.text
        color: root.color
        font: first.font
        maximumLineCount: 1
        elide: Text.ElideRight
    }
    Item {
        id: strip
        anchors.fill: parent
        visible: root.moving
        layer.enabled: root.moving
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: edges
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
        IrisText {
            id: first
            x: -root.offset
            text: root.text
            color: root.color
            font.pixelSize: root.pixelSize
            font.weight: IrisStyle.weight(root.weight)
            maximumLineCount: 1
            elide: Text.ElideNone
        }
        IrisText {
            x: first.x + first.implicitWidth + root.gap
            text: root.text
            color: root.color
            font: first.font
            elide: Text.ElideNone
        }
    }
    // The left edge fades only once the line has started to move: at rest the first letter stands clear.
    Item {
        id: edges
        anchors.fill: parent
        visible: false
        layer.enabled: root.moving
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.rgba(1, 1, 1, root.offset > 0 ? 0 : 1) } // iris-literal: mask alpha
                GradientStop { position: Math.min(0.49, root.fade / Math.max(1, root.width)); color: "white" }
                GradientStop { position: Math.max(0.51, 1 - root.fade / Math.max(1, root.width)); color: "white" }
                GradientStop { position: 1; color: "transparent" }
            }
        }
    }
    SequentialAnimation {
        running: root.running && root.moving && root.visible
        loops: Animation.Infinite
        onRunningChanged: if (!running) root.offset = 0
        PauseAnimation { duration: 2600 }
        NumberAnimation {
            target: root
            property: "offset"
            from: 0
            to: first.implicitWidth + root.gap
            // About 30 px a second at 1x: slow enough to read while it moves.
            duration: Math.round((first.implicitWidth + root.gap) / (30 * IrisStyle.density) * 1000)
            easing.type: Easing.Linear
        }
        PropertyAction { target: root; property: "offset"; value: 0 }
    }
}
