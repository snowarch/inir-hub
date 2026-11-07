import QtQuick
import QtQuick.Shapes
import qs.modules.iris.prism.core

// A motion curve drawn as itself: the line from rest to arrival on a faint grid, its two handles as solid discs on
// hairline arms. Dragging a handle reshapes the curve as it goes; release writes the four numbers once.
Item {
    id: root
    property var value: [0.16, 1, 0.3, 1]
    signal committed(var value)

    property var live: Array.from(root.value ?? [0.16, 1, 0.3, 1]).map(Number)
    property bool held: false
    onValueChanged: if (!root.held) root.live = Array.from(root.value ?? [0.16, 1, 0.3, 1]).map(Number)

    implicitWidth: PrismTheme.dp(260)
    implicitHeight: PrismTheme.dp(170)

    // Room above and below the square: a curve may overshoot its arrival or dip before it leaves.
    readonly property real pad: PrismTheme.dp(14)
    readonly property real box: Math.min(root.width - root.pad * 2, (root.height - root.pad * 2) / 1.5)
    readonly property real inset: (root.width - root.box) / 2
    readonly property real base: root.pad + root.box * 1.25
    function px(x: real): real { return root.inset + x * root.box }
    function py(y: real): real { return root.base - y * root.box }

    Rectangle {
        x: root.inset
        y: root.py(1)
        width: root.box
        height: root.box
        radius: PrismTheme.dp(10)
        color: PrismTheme.fill
    }
    Repeater {
        model: 3
        delegate: Rectangle {
            required property int index
            x: root.inset + root.box * (index + 1) / 4
            y: root.py(1)
            width: 1
            height: root.box
            color: PrismTheme.line
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: PrismTheme.line
            strokeWidth: 1
            fillColor: "transparent"
            startX: root.px(0); startY: root.py(0)
            PathLine { x: root.px(root.live[0]); y: root.py(root.live[1]) }
        }
        ShapePath {
            strokeColor: PrismTheme.line
            strokeWidth: 1
            fillColor: "transparent"
            startX: root.px(1); startY: root.py(1)
            PathLine { x: root.px(root.live[2]); y: root.py(root.live[3]) }
        }
        ShapePath {
            strokeColor: PrismTheme.ink
            strokeWidth: PrismTheme.dp(2.5)
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: root.px(0); startY: root.py(0)
            PathCubic {
                control1X: root.px(root.live[0]); control1Y: root.py(root.live[1])
                control2X: root.px(root.live[2]); control2Y: root.py(root.live[3])
                x: root.px(1); y: root.py(1)
            }
        }
    }

    Repeater {
        model: 2
        delegate: Rectangle {
            id: handle
            required property int index
            width: PrismTheme.dp(16)
            height: width
            radius: width / 2
            x: root.px(root.live[handle.index * 2]) - width / 2
            y: root.py(root.live[handle.index * 2 + 1]) - height / 2
            color: PrismTheme.solid
            border.width: PrismTheme.dp(3)
            border.color: PrismTheme.canvas
            scale: drag.pressed ? 1.2 : drag.containsMouse ? 1.1 : 1
            Behavior on scale { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
            MouseArea {
                id: drag
                anchors.fill: parent
                anchors.margins: -PrismTheme.dp(8)
                hoverEnabled: true
                preventStealing: true
                cursorShape: Qt.SizeAllCursor
                onPressed: root.held = true
                onPositionChanged: mouse => {
                    if (!pressed) return
                    const point = mapToItem(root, mouse.x, mouse.y)
                    const next = root.live.slice()
                    next[handle.index * 2] = Math.round(Math.max(0, Math.min(1, (point.x - root.inset) / root.box)) * 100) / 100
                    next[handle.index * 2 + 1] = Math.round(Math.max(-0.25, Math.min(1.25, (root.base - point.y) / root.box)) * 100) / 100
                    root.live = next
                }
                onReleased: { root.committed(root.live.slice()); root.held = false }
                onCanceled: { root.held = false; root.live = Array.from(root.value).map(Number) }
            }
        }
    }
}
