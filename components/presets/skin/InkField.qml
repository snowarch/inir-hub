import QtQuick

// A one-line text field: a rounded tonal plate, an optional leading icon, no underline.
Item {
    id: root
    property string text: ""
    property string placeholder: ""
    property string icon: ""
    signal accepted()
    readonly property bool focused: input.activeFocus
    function focusField(): void { input.forceActiveFocus() }
    function selectAll(): void { input.selectAll() }
    implicitHeight: InkSkin.control
    implicitWidth: InkSkin.body * 12

    Rectangle {
        anchors.fill: parent
        radius: InkSkin.radius
        color: InkSkin.plate
        border.width: input.activeFocus ? 2 : 0
        border.color: InkSkin.accent
    }
    InkGlyph {
        id: lead
        visible: root.icon !== ""
        anchors.left: parent.left
        anchors.leftMargin: InkSkin.gap
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        color: InkSkin.muted
    }
    TextInput {
        id: input
        anchors.left: lead.visible ? lead.right : parent.left
        anchors.leftMargin: lead.visible ? InkSkin.small : InkSkin.gap
        anchors.right: parent.right
        anchors.rightMargin: InkSkin.gap
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        text: root.text
        color: InkSkin.text
        selectionColor: InkSkin.accent
        selectedTextColor: InkSkin.onAccent
        font.family: InkSkin.mainFont
        font.pixelSize: InkSkin.body
        onTextChanged: if (root.text !== input.text) root.text = input.text
        onAccepted: root.accepted()
        Accessible.name: root.placeholder
    }
    InkText {
        anchors.fill: input
        visible: input.text === ""
        text: root.placeholder
        color: InkSkin.muted
        verticalAlignment: Text.AlignVCenter
    }
}
