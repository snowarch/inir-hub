import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import "../skin"

// What Apply would change, as the dry run reports it.
PrSheet {
    id: root
    required property var store
    cardWidth: PrSkin.body * 40
    title: Translation.tr("Changes if applied")

    Flickable {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(PrSkin.body * 22, Math.max(PrSkin.body * 4, text.implicitHeight))
        clip: true
        contentWidth: width
        contentHeight: text.implicitHeight
        ScrollBar.vertical: PrScrollBar {}
        PrText {
            id: text
            width: parent.width
            role: "mono"
            wrapMode: Text.WrapAnywhere
            elide: Text.ElideNone
            color: root.store.busy ? PrSkin.muted : PrSkin.text
            text: root.store.busy ? Translation.tr("Reading the changes…") : root.store.ok ? root.store.previewText : root.store.message
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Item { Layout.fillWidth: true }
        PrButton { label: Translation.tr("Close"); primary: true; onClicked: root.closed() }
    }
}
