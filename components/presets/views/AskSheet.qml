import QtQuick
import QtQuick.Layouts
import qs.services
import "../skin"

// One question over the window: a text to enter, or a plain confirmation.
PrSheet {
    id: root
    property string message: ""
    property bool field: false
    property string value: ""
    property string action: ""
    property bool danger: false
    readonly property bool typing: input.focused
    signal accepted(string value)

    onOpenChanged: if (root.open && root.field) { input.text = root.value; focusLater.restart() }
    Timer { id: focusLater; interval: 0; onTriggered: { input.focusField(); input.selectAll() } }

    PrText { visible: root.message !== ""; Layout.fillWidth: true; text: root.message; wrapMode: Text.Wrap; color: PrSkin.muted }
    PrField { id: input; visible: root.field; Layout.fillWidth: true; onAccepted: root.accepted(input.text) }
    RowLayout {
        Layout.fillWidth: true
        Item { Layout.fillWidth: true }
        PrButton { label: Translation.tr("Cancel"); onClicked: root.closed() }
        PrButton { label: root.action; primary: !root.danger; danger: root.danger; onClicked: root.accepted(input.text) }
    }
}
