import QtQuick
import QtQuick.Layouts
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// A block's head in the sheet: the name in Prism's grey caption and, on the right, what it is set to now.
RowLayout {
    id: root
    property string text: ""
    property string note: ""
    Layout.fillWidth: true
    spacing: PrismTheme.dp(8)
    PrismText {
        Layout.fillWidth: true
        text: root.text
        color: PrismTheme.ink2
        font.pixelSize: PrismTheme.small
        font.weight: Font.DemiBold
    }
    PrismText {
        visible: root.note.length > 0
        Layout.maximumWidth: PrismTheme.dp(200)
        elide: Text.ElideRight
        text: root.note
        color: PrismTheme.ink3
        font.pixelSize: PrismTheme.small
    }
}
