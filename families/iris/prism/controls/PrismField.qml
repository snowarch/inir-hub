import QtQuick
import qs.modules.iris.prism.core

// Words typed into a pill; Enter or leaving it writes them.
Item {
    id: root
    property string text: ""
    property string placeholder: ""
    property string glyph: ""
    property bool commitOnEdit: false
    property alias input: input
    signal committed(string text)
    signal edited(string text)

    implicitWidth: PrismTheme.dp(200)
    implicitHeight: PrismTheme.dp(32)
    onTextChanged: if (!input.activeFocus) input.text = root.text

    // A pill lit from its left, as light falls on glass: brighter where the glyph sits, fading to the page; a hairline of
    // light on its top edge. Focus lifts it and draws the spectrum along its foot, the beam of the hero.
    property real lift: input.activeFocus ? 1 : area.containsMouse ? 0.5 : 0
    Behavior on lift { NumberAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
    Rectangle {
        id: pill
        anchors.fill: parent
        radius: height / 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.alpha(PrismTheme.ink, 0.1 + 0.05 * root.lift) }
            GradientStop { position: 0.55; color: Qt.alpha(PrismTheme.ink, 0.045 + 0.03 * root.lift) }
            GradientStop { position: 1; color: Qt.alpha(PrismTheme.ink, 0.02 + 0.02 * root.lift) }
        }
        border.width: 1
        border.color: Qt.alpha(PrismTheme.ink, 0.07 + 0.05 * root.lift)
    }
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: (parent.width - parent.height) * (0.35 + 0.65 * (input.activeFocus ? 1 : 0))
        height: 1
        opacity: input.activeFocus ? 0.9 : 0
        Behavior on width { NumberAnimation { duration: PrismTheme.ms(260); easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(200); easing.type: Easing.OutCubic } }
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.2; color: PrismTheme.tint("red") }
            GradientStop { position: 0.4; color: PrismTheme.tint("orange") }
            GradientStop { position: 0.6; color: PrismTheme.tint("green") }
            GradientStop { position: 0.8; color: PrismTheme.tint("blue") }
            GradientStop { position: 1; color: "transparent" }
        }
    }
    PrismGlyph {
        id: icon
        visible: root.glyph.length > 0
        x: PrismTheme.dp(10)
        anchors.verticalCenter: parent.verticalCenter
        text: root.glyph
        iconSize: PrismTheme.dp(16)
        color: input.activeFocus ? PrismTheme.ink : PrismTheme.ink2
    }
    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: root.glyph.length > 0 ? PrismTheme.dp(32) : PrismTheme.dp(14)
        anchors.rightMargin: PrismTheme.dp(14)
        verticalAlignment: TextInput.AlignVCenter
        color: PrismTheme.ink
        selectionColor: PrismTheme.accent
        selectedTextColor: PrismTheme.inkAccent
        font.family: PrismTheme.fontMain
        font.pixelSize: PrismTheme.small
        clip: true
        text: root.text
        onAccepted: { root.committed(text); focus = false }
        onActiveFocusChanged: if (!activeFocus && text !== root.text) root.committed(text)
        onTextEdited: root.edited(text)
        PrismText {
            visible: input.text.length === 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.placeholder
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.small
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.IBeamCursor
    }
}
