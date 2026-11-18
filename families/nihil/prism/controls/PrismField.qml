import QtQuick
import qs.modules.nihil.prism.core
import qs.modules.nihil.style

// Words typed into a well; Enter or leaving it writes them.
Item {
    id: root
    property string text: ""
    property string placeholder: ""
    property string glyph: ""
    property bool commitOnEdit: false
    property alias input: input
    signal committed(string text)
    signal edited(string text)
    // Enter, before the field lets go of focus: a search takes its first hit.
    signal entered(string text)

    implicitWidth: PrismTheme.dp(200)
    implicitHeight: PrismTheme.dp(32)
    onTextChanged: if (!input.activeFocus) input.text = root.text

    // Words typed into a well cut into the card (`.claude/ref/language`); focus draws the spectrum along its foot, light
    // bending at an edge (glass-spectral), never a fill.
    PrismWell {
        id: pill
        anchors.fill: parent
        hovered: area.containsMouse || input.activeFocus
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
            GradientStop { position: 0.2; color: IrisStyle.prismStops[6] }
            GradientStop { position: 0.4; color: IrisStyle.prismStops[5] }
            GradientStop { position: 0.6; color: IrisStyle.prismStops[3] }
            GradientStop { position: 0.8; color: IrisStyle.prismStops[1] }
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
        onAccepted: { root.entered(text); root.committed(text); focus = false }
        onActiveFocusChanged: if (!activeFocus && text !== root.text) root.committed(text)
        onTextEdited: root.edited(text)
        // Escape empties the words first (a search ends); with nothing typed it lets go, and the panel hears it.
        Keys.onEscapePressed: event => {
            if (text.length === 0) { event.accepted = false; return }
            text = ""
            root.edited("")
            root.committed("")
        }
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
