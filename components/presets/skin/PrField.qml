import QtQuick
import QtQuick.Controls

// A one-line text box on a tonal plate; the accent ring shows it has the keyboard.
Rectangle {
    id: root
    property alias text: edit.text
    property string placeholder: ""
    property string icon: ""
    signal accepted()
    readonly property bool focused: edit.activeFocus
    function focusField(): void { edit.forceActiveFocus() }
    function selectAll(): void { edit.selectAll() }

    implicitHeight: PrSkin.control
    implicitWidth: PrSkin.body * 12
    radius: PrSkin.radius
    color: PrSkin.plate
    border.width: focused ? 2 : 0
    border.color: PrSkin.accent

    PrGlyph {
        id: lead
        visible: root.icon !== ""
        x: PrSkin.gap
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        color: PrSkin.muted
    }
    TextField {
        id: edit
        anchors.fill: parent
        anchors.leftMargin: lead.visible ? lead.x + lead.width + PrSkin.small - leftPadding : 0
        leftPadding: PrSkin.gap
        rightPadding: PrSkin.gap
        background: null
        color: PrSkin.text
        placeholderText: root.placeholder
        placeholderTextColor: PrSkin.muted
        selectionColor: PrSkin.accent
        selectedTextColor: PrSkin.onAccent
        font.pixelSize: PrSkin.body
        verticalAlignment: TextInput.AlignVCenter
        onAccepted: root.accepted()
        Accessible.name: root.placeholder
    }
}
