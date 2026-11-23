import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import "../skin"
import "../state"
import "../logic/NotesLogic.js" as Logic

// The notes of the chosen folder: search, a New note button, the list.
Rectangle {
    id: root
    required property var store
    property string current: ""
    property string heading: ""
    readonly property bool searching: root.store.query.trim() !== ""
    readonly property bool typing: search.focused
    signal picked(string rel)
    signal newNote()
    signal renameNote(string rel)
    signal trashNote(string rel)
    color: InkSkin.side
    radius: InkSkin.cardRadius

    function focusSearch(): void { search.focusField(); search.selectAll() }
    function when(ms: double): string {
        const a = Logic.ago(ms, Date.now());
        switch (a.k) {
        case "now": return Translation.tr("Just now");
        case "min": return Translation.tr("%1 min ago").arg(a.n);
        case "hour": return Translation.tr("%1 h ago").arg(a.n);
        case "yesterday": return Translation.tr("Yesterday");
        case "days": return Translation.tr("%1 days ago").arg(a.n);
        default: return Qt.formatDate(new Date(ms), Locale.ShortFormat);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: InkSkin.gap
        spacing: InkSkin.gap
        RowLayout {
            Layout.fillWidth: true
            InkText { Layout.fillWidth: true; Layout.leftMargin: InkSkin.small; text: root.heading; role: "label" }
            InkButton { label: Translation.tr("New note"); symbol: "add"; primary: true; onClicked: root.newNote() }
        }
        InkField {
            id: search
            Layout.fillWidth: true
            icon: "search"
            placeholder: Translation.tr("Search notes")
            onTextChanged: if (root.store.query !== text) root.store.query = text
        }
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: root.store.listed
            ScrollBar.vertical: InkScrollBar {}
            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property bool pinned: InkOptions.pins.indexOf(row.modelData.rel) >= 0
                readonly property bool on: root.current === row.modelData.rel
                width: ListView.view.width
                height: InkSkin.rowHeight
                radius: InkSkin.radius
                color: row.on ? InkSkin.rowOn : area.containsMouse ? InkSkin.hover : "transparent"
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: InkSkin.gap
                    anchors.rightMargin: InkSkin.gap
                    spacing: InkSkin.small
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        InkText { Layout.fillWidth: true; text: row.modelData.title; color: row.on ? InkSkin.rowOnInk : InkSkin.text }
                        InkText {
                            Layout.fillWidth: true
                            text: root.when(row.modelData.mtime) + (row.modelData.folder !== "" ? "  ·  " + row.modelData.folder : "")
                            role: "meta"; color: InkSkin.muted
                        }
                    }
                    InkGlyph { visible: row.pinned; name: "push_pin"; size: InkSkin.meta; color: InkSkin.muted }
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) { root.picked(row.modelData.rel); return; }
                        const rel = row.modelData.rel;
                        noteMenu.model = [
                            { text: row.pinned ? Translation.tr("Unpin") : Translation.tr("Pin"), iconName: "push_pin", action: () => InkOptions.togglePin(rel) },
                            { text: Translation.tr("Rename"), iconName: "edit", action: () => root.renameNote(rel) },
                            { text: Translation.tr("Move to folder"), iconName: "folder", action: () => moveLater.start(rel, row) },
                            { text: Translation.tr("Move to trash"), iconName: "delete", action: () => root.trashNote(rel) }
                        ];
                        noteMenu.open(row, Qt.point(mouse.x, mouse.y));
                    }
                }
            }
            InkText {
                anchors.centerIn: parent
                width: parent.width - InkSkin.pad * 2
                visible: list.count === 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                color: InkSkin.muted
                text: root.store.loading ? Translation.tr("Reading the notes folder…")
                    : root.searching ? Translation.tr("No note matches this search.")
                    : Translation.tr("No notes here yet. New note starts one.")
            }
        }
    }
    InkMenu { id: noteMenu }
    InkMenu { id: folderMenu }
    // The first menu closes before the second opens.
    Timer {
        id: moveLater
        property string rel: ""
        property Item anchor: null
        interval: 120
        function start(rel: string, anchor: Item): void { moveLater.rel = rel; moveLater.anchor = anchor; moveLater.restart() }
        onTriggered: {
            const rel = moveLater.rel;
            const here = Logic.folderOf(rel);
            const targets = [""].concat(root.store.folders).filter(f => f !== here);
            folderMenu.model = targets.map(f => ({
                text: f === "" ? Translation.tr("No folder") : f,
                iconName: f === "" ? "folder_off" : "folder",
                action: () => root.store.move(rel, Logic.relOf(f, Logic.titleOf(rel)))
            }));
            folderMenu.open(moveLater.anchor, Qt.point(InkSkin.pad, moveLater.anchor.height));
        }
    }
}
