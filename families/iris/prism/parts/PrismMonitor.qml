import QtQuick
import QtQuick.Shapes
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// Displays' picture (the B · Carpeta study): the screen drawn in thin white lines on the inset card, what the shell
// shows on it (the island, the dock, a widget) as plain outlines, and a pin on each part that has a group on the page.
// No glow, no glint, no colour: a drawing, not a render (his 11-17).
Item {
    id: root
    // { group, x, y } in the screen's own fractions; the first one says its name.
    property var pins: []
    property string current: ""
    signal pick(string group)

    readonly property real sw: Math.min(root.width * 0.7, (root.height - PrismTheme.dp(40)) * 16 / 9 / 1.2)
    readonly property real sh: root.sw * 9 / 16
    readonly property real sx: Math.round((root.width - root.sw) / 2)
    readonly property real sy: Math.round(PrismTheme.dp(4))
    readonly property color ink: Qt.rgba(1, 1, 1, 0.58) // iris-literal: the drawing's line on the night card
    readonly property color faint: Qt.rgba(1, 1, 1, 0.3) // iris-literal: what the screen shows, a step quieter

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        // The screen and its glass.
        ShapePath {
            strokeColor: root.ink
            strokeWidth: 1.2
            fillColor: "transparent"
            PathRectangle { x: root.sx; y: root.sy; width: root.sw; height: root.sh; radius: PrismTheme.dp(10) }
        }
        ShapePath {
            strokeColor: root.faint
            strokeWidth: 1
            fillColor: "transparent"
            PathRectangle { x: root.sx + 7; y: root.sy + 7; width: root.sw - 14; height: root.sh - 14; radius: PrismTheme.dp(5) }
        }
        // What the shell shows: the island at the top, the dock at the foot, a widget at the left.
        ShapePath {
            strokeColor: root.faint
            strokeWidth: 1
            fillColor: "transparent"
            PathRectangle { x: root.sx + root.sw * 0.41; y: root.sy + 14; width: root.sw * 0.18; height: root.sh * 0.07; radius: root.sh * 0.035 }
        }
        ShapePath {
            strokeColor: root.faint
            strokeWidth: 1
            fillColor: "transparent"
            PathRectangle { x: root.sx + root.sw * 0.34; y: root.sy + root.sh - 14 - root.sh * 0.08; width: root.sw * 0.32; height: root.sh * 0.08; radius: root.sh * 0.04 }
        }
        ShapePath {
            strokeColor: root.faint
            strokeWidth: 1
            fillColor: "transparent"
            PathRectangle { x: root.sx + 18; y: root.sy + root.sh * 0.22; width: root.sw * 0.15; height: root.sh * 0.2; radius: 6 }
        }
        // The neck and the foot.
        ShapePath {
            strokeColor: root.ink
            strokeWidth: 1.2
            fillColor: "transparent"
            startX: root.sx + root.sw / 2 - 14; startY: root.sy + root.sh
            PathLine { x: root.sx + root.sw / 2 - 20; y: root.sy + root.sh + root.sh * 0.2 }
            PathMove { x: root.sx + root.sw / 2 + 14; y: root.sy + root.sh }
            PathLine { x: root.sx + root.sw / 2 + 20; y: root.sy + root.sh + root.sh * 0.2 }
        }
        ShapePath {
            strokeColor: root.ink
            strokeWidth: 1.2
            fillColor: "transparent"
            PathRectangle { x: root.sx + root.sw * 0.3; y: root.sy + root.sh * 1.2; width: root.sw * 0.4; height: 9; radius: 4.5 }
        }
    }

    // The pins: a white dot on its part; the open group's, or the first, says its name on a smoked tag.
    Repeater {
        model: root.pins
        delegate: Item {
            id: pin
            required property var modelData
            required property int index
            readonly property bool named: pinArea.containsMouse || (root.current.length > 0 ? root.current === pin.modelData.group : pin.index === 0)
            readonly property real disc: pin.named ? PrismTheme.dp(28) : PrismTheme.dp(22)
            x: Math.round(root.sx + root.sw * pin.modelData.x - pin.disc / 2)
            y: Math.round(root.sy + root.sh * pin.modelData.y - pin.disc / 2)
            width: tag.width
            height: pin.disc
            // Named: a white dot and the group's name on smoke. Unnamed: a small dot in a smoked disc.
            Rectangle {
                id: tag
                width: pin.disc + (pin.named ? label.implicitWidth + PrismTheme.dp(8) : 0)
                height: parent.height
                radius: height / 2
                color: pinArea.containsMouse ? PrismTheme.spotHover : PrismTheme.spot
                Rectangle {
                    x: pin.named ? PrismTheme.dp(5) : (pin.disc - width) / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: pin.named ? PrismTheme.dp(18) : PrismTheme.dp(6)
                    height: width
                    radius: width / 2
                    color: PrismTheme.paper
                }
                PrismText {
                    id: label
                    x: PrismTheme.dp(30)
                    anchors.verticalCenter: parent.verticalCenter
                    visible: pin.named
                    text: Translation.tr(pin.modelData.group)
                    color: PrismTheme.paper
                    font.pixelSize: PrismTheme.small
                }
            }
            MouseArea {
                id: pinArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.pick(pin.modelData.group)
            }
        }
    }
}
