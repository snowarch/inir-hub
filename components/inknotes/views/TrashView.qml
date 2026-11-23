import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import "../skin"

// What was moved to the trash, with the days it is kept.
Rectangle {
    id: root
    required property var store
    property int days: 30
    signal emptyRequested()
    signal backRequested()
    property bool narrow: false
    color: InkSkin.side
    radius: InkSkin.cardRadius

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: InkSkin.gap
        spacing: InkSkin.gap
        RowLayout {
            Layout.fillWidth: true
            InkButton { visible: root.narrow; symbol: "arrow_back"; quiet: true; hint: Translation.tr("Back"); onClicked: root.backRequested() }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                InkText { Layout.fillWidth: true; text: Translation.tr("Trash"); role: "title" }
                InkText {
                    Layout.fillWidth: true; role: "meta"; color: InkSkin.muted
                    text: root.days > 0 ? Translation.tr("Notes are deleted for good after %1 days.").arg(root.days) : Translation.tr("Notes stay in the trash until you delete them.")
                }
            }
            InkButton { visible: list.count > 0; label: Translation.tr("Empty trash"); symbol: "delete_forever"; danger: true; onClicked: root.emptyRequested() }
        }
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: root.store.trash
            ScrollBar.vertical: InkScrollBar {}
            delegate: Rectangle {
                id: row
                required property var modelData
                width: ListView.view.width
                height: InkSkin.rowHeight
                radius: InkSkin.smallRadius
                color: InkSkin.plate
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: InkSkin.gap
                    anchors.rightMargin: InkSkin.gap
                    spacing: InkSkin.small
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        InkText { Layout.fillWidth: true; text: row.modelData.title }
                        InkText {
                            Layout.fillWidth: true; role: "meta"; color: InkSkin.muted
                            text: Translation.tr("Deleted %1").arg(Qt.formatDateTime(new Date(row.modelData.epoch), Locale.ShortFormat))
                                + (row.modelData.folder !== "" ? "  ·  " + row.modelData.folder : "")
                        }
                    }
                    InkButton { label: Translation.tr("Restore"); symbol: "restore_from_trash"; onClicked: root.store.restore(row.modelData) }
                    InkButton { label: Translation.tr("Delete forever"); danger: true; onClicked: root.store.deleteForever(row.modelData) }
                }
            }
            InkText {
                anchors.centerIn: parent
                visible: list.count === 0
                color: InkSkin.muted
                text: Translation.tr("The trash is empty.")
            }
        }
    }
}
