pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// The tuner's search field. A plate in the family's corner, or in Prism's grammar a pill: a soft sheen from the
// left, a hairline edge and, while typing, a thread of the spectrum under it.
FocusScope {
    id: root

    property var look
    property string placeholder: ""
    property alias text: input.text
    readonly property real d: root.look?.d ?? 1
    readonly property bool prism: root.look?.grammar === "prism"
    signal escaped()
    signal accepted()
    signal down()

    implicitHeight: Math.round((root.prism ? 34 : 38) * root.d)

    Rectangle {
        id: plate
        anchors.fill: parent
        radius: root.prism ? height / 2 : root.look.radiusSmall
        color: root.look.raised
        border.width: root.prism ? 1 : input.activeFocus ? 1 : 0
        border.color: root.prism ? Qt.alpha(root.look.ink, 0.07) : root.look.accent
        gradient: root.prism ? sheen : null
        Gradient {
            id: sheen
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.alpha(root.look.ink, 0.10) }
            GradientStop { position: 0.5; color: Qt.alpha(root.look.ink, 0.045) }
            GradientStop { position: 1; color: Qt.alpha(root.look.ink, 0.02) }
        }
    }
    // Prism's focus: the spectrum as a thread along the bottom, inside the round ends.
    Rectangle {
        visible: root.prism && input.activeFocus && (root.look.spectrum ?? []).length > 1
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        anchors.leftMargin: plate.radius
        anchors.rightMargin: plate.radius
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: root.look.spectrum?.[0] ?? "transparent" }
            GradientStop { position: 0.5; color: root.look.spectrum?.[3] ?? "transparent" }
            GradientStop { position: 1; color: root.look.spectrum?.[6] ?? "transparent" }
        }
    }
    RadioGlyph {
        id: glyph
        x: Math.round((root.prism ? 10 : 12) * root.d)
        anchors.verticalCenter: parent.verticalCenter
        look: root.look
        name: "search"
        size: Math.round((root.prism ? 16 : 18) * root.d)
        color: root.look.muted
    }
    TextInput {
        id: input
        anchors.left: glyph.right
        anchors.leftMargin: Math.round(10 * root.d)
        anchors.right: clear.left
        anchors.rightMargin: Math.round(4 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        focus: true
        clip: true
        font.family: root.look.font
        font.pixelSize: root.prism ? root.look.meta : root.look.body
        color: root.look.ink
        selectionColor: root.look.accent
        selectedTextColor: root.look.onAccent
        Keys.onEscapePressed: root.escaped()
        Keys.onReturnPressed: root.accepted()
        Keys.onEnterPressed: root.accepted()
        Keys.onDownPressed: root.down()
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            visible: input.text.length === 0
            text: root.placeholder
            elide: Text.ElideRight
            font: input.font
            color: root.prism ? root.look.muted : root.look.faint
        }
    }
    RadioButton {
        id: clear
        anchors.right: parent.right
        anchors.rightMargin: Math.round(4 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text.length > 0
        width: visible ? implicitWidth : 0
        look: root.look
        glyph: "close"
        size: Math.round((root.prism ? 26 : 28) * root.d)
        label: Translation.tr("Clear")
        onClicked: input.text = ""
    }
}
