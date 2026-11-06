pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.iris.style

// A battery drawn as the thing itself: a rounded case, its terminal and a row of cells lit by the charge (the last one
// by its share). Charging is warm and the cell being filled breathes while the face is seen; low is danger. Under
// Nothing the cells are its dot matrix, three dots high, the low charge in signal.
Item {
    id: root
    required property var face
    property real level: 0
    property bool charging: false
    property bool low: false
    property int count: 5

    readonly property real shown: Math.max(0, Math.min(1, Number.isFinite(root.level) ? root.level : 0))
    readonly property bool dots: root.face.nothing ?? false
    readonly property color tone: root.low && !root.charging ? root.face.danger
        : root.charging ? root.face.warm : root.face.ink
    readonly property real wall: Math.max(1, Math.round(root.height * 0.07))
    readonly property real pad: Math.max(2, Math.round(root.height * 0.13))
    readonly property real nub: Math.max(2, Math.round(root.height * 0.11))
    readonly property real gap: Math.max(2, Math.round(root.pad * 0.7))
    // The cell being filled: it breathes only while charging on a face that is seen.
    readonly property int filling: Math.min(root.count - 1, Math.floor(root.shown * root.count))
    property real breath: 1
    SequentialAnimation on breath {
        running: root.charging && root.shown < 1 && (root.face.moving ?? false) && IrisStyle.motionEnabled
        loops: Animation.Infinite
        onRunningChanged: if (!running) root.breath = 1
        NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
    }

    implicitWidth: root.face.dp(96)
    implicitHeight: root.face.dp(34)

    Rectangle {
        id: shell
        width: root.width - root.nub - root.wall
        height: root.height
        radius: Math.round(root.height * 0.28)
        color: "transparent"
        border.width: root.wall
        border.color: Qt.alpha(root.face.ink, root.dots ? 0.28 : 0.38)
    }
    Rectangle {
        x: shell.width + root.wall
        anchors.verticalCenter: shell.verticalCenter
        width: root.nub
        height: Math.round(root.height * 0.36)
        radius: width / 2
        color: Qt.alpha(root.face.ink, root.dots ? 0.28 : 0.38)
    }

    Row {
        id: cells
        visible: !root.dots
        x: root.wall + root.pad
        y: root.wall + root.pad
        width: shell.width - 2 * (root.wall + root.pad)
        height: root.height - 2 * (root.wall + root.pad)
        spacing: root.gap
        readonly property real cellWidth: (cells.width - root.gap * (root.count - 1)) / Math.max(1, root.count)
        Repeater {
            model: root.dots ? 0 : root.count
            Rectangle {
                id: cell
                required property int index
                readonly property real share: Math.max(0, Math.min(1, root.shown * root.count - cell.index))
                width: cells.cellWidth
                height: cells.height
                radius: Math.max(1, Math.round(Math.min(width, height) * 0.22))
                color: root.face.fillQuiet
                Rectangle {
                    width: Math.round(parent.width * cell.share)
                    height: parent.height
                    radius: parent.radius
                    color: root.tone
                    opacity: cell.index === root.filling && root.charging ? root.breath : 1
                }
            }
        }
    }

    // Nothing: columns of three dots, lit left to right.
    Grid {
        id: matrix
        visible: root.dots
        readonly property real dot: Math.max(2, Math.floor((root.height - 2 * (root.wall + root.pad)) / 3 * 0.72))
        readonly property real pitch: Math.max(matrix.dot + 1, (root.height - 2 * (root.wall + root.pad) - matrix.dot) / 2)
        readonly property int across: Math.max(2, Math.floor((shell.width - 2 * (root.wall + root.pad) - matrix.dot) / matrix.pitch) + 1)
        readonly property int lit: root.shown <= 0 ? 0 : Math.max(1, Math.round(root.shown * matrix.across))
        x: Math.round((shell.width - (matrix.across - 1) * matrix.pitch - matrix.dot) / 2)
        y: Math.round((root.height - 2 * matrix.pitch - matrix.dot) / 2)
        columns: matrix.across
        rowSpacing: matrix.pitch - matrix.dot
        columnSpacing: matrix.pitch - matrix.dot
        Repeater {
            model: root.dots ? matrix.across * 3 : 0
            Rectangle {
                id: dot
                required property int index
                readonly property int column: dot.index % matrix.across
                width: matrix.dot
                height: matrix.dot
                radius: width / 2
                color: dot.column < matrix.lit ? root.tone : root.face.fillQuiet
                opacity: dot.column === matrix.lit - 1 && root.charging ? root.breath : 1
            }
        }
    }
}
