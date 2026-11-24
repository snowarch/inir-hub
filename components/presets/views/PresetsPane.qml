import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import "../skin"
import "../logic/PresetLogic.js" as Logic
import "../logic/StoreLogic.js" as Files

// The presets of the chosen folder: name, family, groups, how many settings, when it was made.
Rectangle {
    id: root
    required property var store
    property string current: ""
    property string heading: ""
    property bool narrow: false
    readonly property var shown: root.store.presets.filter(p => root.store.selectedFolder === "" || p.folder === root.store.selectedFolder)
    signal picked(string file)
    signal saveRequested()
    signal foldersRequested()
    color: InkSkin.side
    radius: InkSkin.cardRadius

    function groupLabel(id: string): string {
        const group = Logic.GROUPS.find(g => g.id === id);
        return group ? Translation.tr(group.label) : id;
    }
    function when(made: string): string {
        const ms = Files.madeMs(made);
        return isNaN(ms) ? Translation.tr("Unknown date") : Qt.formatDate(new Date(ms), Locale.ShortFormat);
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: InkSkin.gap
        spacing: InkSkin.gap
        RowLayout {
            Layout.fillWidth: true
            InkButton { visible: root.narrow; symbol: "arrow_back"; quiet: true; hint: Translation.tr("Folders"); onClicked: root.foldersRequested() }
            InkText { Layout.fillWidth: true; Layout.leftMargin: InkSkin.small; text: root.heading; role: "label" }
            InkButton { label: Translation.tr("Save current look"); symbol: "add"; primary: true; enabled: !root.store.busy; onClicked: root.saveRequested() }
        }
        InkText {
            visible: root.store.skipped > 0
            Layout.fillWidth: true
            wrapMode: Text.Wrap; role: "meta"; color: InkSkin.muted
            text: Translation.tr("%1 files in the folder are not presets and are ignored.").arg(root.store.skipped)
        }
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: root.shown
            ScrollBar.vertical: InkScrollBar {}
            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property bool on: root.current === row.modelData.file
                width: ListView.view.width
                height: content.implicitHeight + InkSkin.gap * 2
                radius: InkSkin.radius
                color: row.on ? InkSkin.rowOn : area.containsMouse ? InkSkin.hover : "transparent"
                ColumnLayout {
                    id: content
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: InkSkin.gap
                    anchors.rightMargin: InkSkin.gap
                    spacing: InkSkin.small / 2
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: InkSkin.small
                        InkText { Layout.fillWidth: true; text: row.modelData.name; color: row.on ? InkSkin.rowOnInk : InkSkin.text }
                        Chip { visible: row.modelData.family !== ""; text: Files.familyLabel(row.modelData.family) }
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: InkSkin.small / 2
                        Repeater {
                            model: row.modelData.groups
                            Chip { required property string modelData; text: root.groupLabel(modelData) }
                        }
                    }
                    InkText {
                        Layout.fillWidth: true
                        role: "meta"; color: InkSkin.muted
                        text: Translation.tr("%1 settings").arg(row.modelData.settings) + "  ·  " + root.when(row.modelData.made)
                            + (row.modelData.folder !== "" && root.store.selectedFolder === "" ? "  ·  " + row.modelData.folder : "")
                    }
                }
                MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: root.picked(row.modelData.file) }
            }
            InkText {
                anchors.centerIn: parent
                width: parent.width - InkSkin.pad * 2
                visible: list.count === 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                color: InkSkin.muted
                text: !root.store.loaded ? Translation.tr("Reading the presets folder…")
                    : root.store.presets.length === 0 ? Translation.tr("No presets yet. Save current look stores how your desktop looks now.")
                    : Translation.tr("No presets in this folder.")
            }
        }
    }
}
