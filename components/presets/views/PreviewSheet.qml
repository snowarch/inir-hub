import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import "../skin"

// What Apply would change, as the dry run reports it.
InkSheet {
    id: root
    required property var store
    cardWidth: InkSkin.body * 40
    title: Translation.tr("Changes if applied")

    Flickable {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(InkSkin.body * 22, Math.max(InkSkin.body * 4, text.implicitHeight))
        clip: true
        contentWidth: width
        contentHeight: text.implicitHeight
        ScrollBar.vertical: InkScrollBar {}
        InkText {
            id: text
            width: parent.width
            role: "mono"
            wrapMode: Text.WrapAnywhere
            elide: Text.ElideNone
            color: root.store.busy ? InkSkin.muted : InkSkin.text
            text: root.store.busy ? Translation.tr("Reading the changes…") : root.store.ok ? root.store.previewText : root.store.message
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Item { Layout.fillWidth: true }
        InkButton { label: Translation.tr("Close"); primary: true; onClicked: root.closed() }
    }
}
