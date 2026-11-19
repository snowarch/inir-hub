import QtQuick
import qs.services

// A line to type in, a tile of its own. `value` is what is kept: `edited` follows each key, `committed` is Enter or
// leaving the field. Escape puts the kept value back, and so does a line `accepts` turns down.
Rectangle {
    id: root

    property string value: ""
    property string placeholder: ""
    property string glyph: ""
    property bool mono: false
    property bool clearable: false
    property var accepts: null
    // A search field that leads a surface sets its own size.
    property real textSize: 0
    property real glyphSize: NihilStyle.s(18)
    property int textWeight: Font.Medium
    readonly property alias text: input.text
    readonly property bool typing: input.activeFocus
    property alias echoMode: input.echoMode
    signal edited(string text)
    signal committed(string text)
    // Enter, and the arrows for a list the field steers (the clipboard's, a search's).
    signal entered()
    signal stepped(int by)
    // Left and right, while nothing is written: the grid under the field walks sideways.
    signal walked(int by)

    function take(): void { input.forceActiveFocus(); input.selectAll() }
    // Takes the keys with what is written kept, the cursor after it: typing goes on from there.
    function resume(): void { input.forceActiveFocus(); input.cursorPosition = input.length }
    function clear(): void { input.text = ""; root.edited("") }

    onValueChanged: if (!input.activeFocus) input.text = root.value
    Component.onCompleted: input.text = root.value

    implicitWidth: NihilStyle.s(230)
    implicitHeight: NihilStyle.s(40)
    radius: NihilStyle.rKey
    color: "transparent"

    NWell {
        anchors.fill: parent
        radius: root.radius
        lit: input.activeFocus ? 0.55 : 0
    }

    NIcon {
        id: mark
        visible: root.glyph.length > 0
        anchors.left: parent.left
        anchors.leftMargin: NihilStyle.s(13)
        anchors.verticalCenter: parent.verticalCenter
        text: root.glyph
        size: root.glyphSize
        color: NihilStyle.inkSoft
    }

    TextInput {
        id: input
        anchors.left: mark.visible ? mark.right : parent.left
        anchors.leftMargin: NihilStyle.s(mark.visible ? 8 : 15)
        anchors.right: wipe.visible ? wipe.left : parent.right
        anchors.rightMargin: NihilStyle.s(wipe.visible ? 4 : 15)
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        selectByMouse: true
        color: NihilStyle.ink
        selectionColor: NihilStyle.accent
        selectedTextColor: NihilStyle.accentInk
        font.family: NihilStyle.grotesk
        font.features: root.mono ? { "tnum": 1 } : ({})
        font.pixelSize: root.textSize > 0 ? root.textSize : Math.max(NihilStyle.textBody, Math.round(root.height * 0.3))
        font.weight: root.textWeight
        Accessible.role: Accessible.EditableText
        Accessible.name: root.placeholder
        onTextEdited: root.edited(input.text)
        onAccepted: root.entered()
        passwordCharacter: "\u25CF"
        Keys.onUpPressed: root.stepped(-1)
        Keys.onDownPressed: root.stepped(1)
        Keys.onLeftPressed: event => { event.accepted = input.length === 0; if (event.accepted) root.walked(-1) }
        Keys.onRightPressed: event => { event.accepted = input.length === 0; if (event.accepted) root.walked(1) }
        function keep(): void {
            if (input.text === root.value) return
            if (root.accepts && !root.accepts(input.text)) { input.text = root.value; return }
            root.committed(input.text)
        }
        onEditingFinished: input.keep()
        Keys.onEscapePressed: event => {
            event.accepted = input.text !== root.value
            input.text = root.value
            root.edited(root.value)
        }
    }
    NText {
        anchors.fill: input
        visible: input.text.length === 0
        text: root.placeholder
        color: NihilStyle.inkSoft
        font.family: input.font.family
        font.pixelSize: input.font.pixelSize
        font.weight: root.textWeight
    }

    NButton {
        id: wipe
        visible: root.clearable && input.text.length > 0
        anchors.right: parent.right
        anchors.rightMargin: NihilStyle.s(6)
        anchors.verticalCenter: parent.verticalCenter
        width: NihilStyle.s(28)
        height: NihilStyle.s(28)
        tone: "transparent"
        icon: "close"
        iconSize: NihilStyle.s(16)
        Accessible.name: Translation.tr("Clear")
        onClicked: { root.clear(); input.forceActiveFocus() }
    }
}
