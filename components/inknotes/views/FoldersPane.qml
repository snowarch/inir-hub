import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import "../skin"
import "../logic/NotesLogic.js" as Logic

// All notes, No folder, each folder, and the way to Trash and Settings.
Rectangle {
    id: root
    required property var store
    property string view: Logic.ALL
    property bool trashOpen: false
    signal picked(string view)
    signal newFolder()
    signal renameFolder(string name)
    signal deleteFolder(string name)
    signal trashRequested()
    signal settingsRequested()
    color: InkSkin.side

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: InkSkin.gap
        spacing: InkSkin.small

        RowLayout {
            Layout.fillWidth: true
            InkText { Layout.fillWidth: true; Layout.leftMargin: InkSkin.small; text: Translation.tr("Folders"); role: "title" }
            InkButton { symbol: "create_new_folder"; quiet: true; hint: Translation.tr("New folder"); onClicked: root.newFolder() }
        }
        PaneRow {
            Layout.fillWidth: true
            label: Translation.tr("All notes"); symbol: "description"; badge: String(root.store.allCount)
            selected: !root.trashOpen && root.view === Logic.ALL
            onClicked: root.picked(Logic.ALL)
        }
        PaneRow {
            Layout.fillWidth: true
            label: Translation.tr("No folder"); symbol: "folder_off"; badge: String(root.store.rootCount)
            selected: !root.trashOpen && root.view === Logic.NONE
            onClicked: root.picked(Logic.NONE)
        }
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: root.store.folders
            delegate: PaneRow {
                id: row
                required property string modelData
                width: ListView.view.width
                label: row.modelData; symbol: "folder"; badge: String(root.store.countOf(row.modelData))
                selected: !root.trashOpen && root.view === row.modelData
                onClicked: root.picked(row.modelData)
                onMenu: at => { menu.model = [
                    { text: Translation.tr("Rename"), iconName: "edit", action: () => root.renameFolder(row.modelData) },
                    { text: Translation.tr("Move to trash"), iconName: "delete", action: () => root.deleteFolder(row.modelData) }
                ]; menu.open(row, at); }
            }
            ScrollBar.vertical: InkScrollBar {}
            InkText {
                visible: root.store.folders.length === 0
                width: parent.width
                text: Translation.tr("No folders yet.")
                role: "meta"; color: InkSkin.muted; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter
            }
        }
        PaneRow { Layout.fillWidth: true; label: Translation.tr("Trash"); symbol: "delete"; selected: root.trashOpen; onClicked: root.trashRequested() }
        PaneRow { Layout.fillWidth: true; label: Translation.tr("Settings"); symbol: "settings"; onClicked: root.settingsRequested() }
    }
    InkMenu { id: menu }
}
