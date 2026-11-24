import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import "../skin"

// All presets, each folder, and the way to the folder on disk.
Rectangle {
    id: root
    required property var store
    signal picked(string folder)
    signal newFolder()
    signal renameFolder(string name)
    signal deleteFolder(string name)
    color: PrSkin.side
    radius: PrSkin.cardRadius

    function countOf(folder: string): int { return root.store.presets.filter(p => p.folder === folder).length }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: PrSkin.gap
        spacing: PrSkin.small

        RowLayout {
            Layout.fillWidth: true
            PrText { Layout.fillWidth: true; Layout.leftMargin: PrSkin.small; text: Translation.tr("Folders"); role: "label" }
            PrButton { symbol: "create_new_folder"; quiet: true; hint: Translation.tr("New folder"); enabled: !root.store.busy; onClicked: root.newFolder() }
        }
        PaneRow {
            Layout.fillWidth: true
            label: Translation.tr("All presets"); symbol: "palette"; badge: String(root.store.presets.length)
            selected: root.store.selectedFolder === ""
            onClicked: root.picked("")
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
                label: row.modelData; symbol: "folder"; badge: String(root.countOf(row.modelData))
                selected: root.store.selectedFolder === row.modelData
                onClicked: root.picked(row.modelData)
                onMenu: at => { menu.model = [
                    { text: Translation.tr("Rename"), iconName: "edit", action: () => root.renameFolder(row.modelData) },
                    { text: Translation.tr("Move to trash"), iconName: "delete", action: () => root.deleteFolder(row.modelData) }
                ]; menu.open(row, at); }
            }
            ScrollBar.vertical: PrScrollBar {}
            PrText {
                visible: root.store.folders.length === 0
                width: parent.width
                text: Translation.tr("No folders yet.")
                role: "meta"; color: PrSkin.muted; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter
            }
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: PrSkin.edge }
        PaneRow { Layout.fillWidth: true; label: Translation.tr("Open presets folder"); symbol: "open_in_new"; onClicked: Quickshell.execDetached(["xdg-open", root.store.rootDir]) }
    }
    PrMenu { id: menu }
}
