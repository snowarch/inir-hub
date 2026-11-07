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

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: input.activeFocus ? PrismTheme.fillPress : area.containsMouse ? PrismTheme.fillHover : PrismTheme.fill
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(120) } }
    }
    PrismGlyph {
        id: icon
        visible: root.glyph.length > 0
        x: PrismTheme.dp(10)
        anchors.verticalCenter: parent.verticalCenter
        text: root.glyph
        iconSize: PrismTheme.dp(16)
        color: PrismTheme.ink2
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
            color: PrismTheme.ink3
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
