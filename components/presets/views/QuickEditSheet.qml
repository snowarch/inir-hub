import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import "../skin"
import "../logic/PresetLogic.js" as Logic

// Change or remove single settings of a preset without saving the whole look again.
PrSheet {
    id: root
    property var preset: null
    property var rows: []
    // Changed settings by dotted path: { raw, value, valid, removed }.
    property var edits: ({})
    property string query: ""
    readonly property var shownRows: root.rows.filter(row => root.query === "" || row.text.toLowerCase().indexOf(root.query.toLowerCase()) >= 0)
    readonly property int changedCount: Object.keys(root.edits).length
    readonly property bool valid: Object.keys(root.edits).every(key => root.edits[key].removed === true || root.edits[key].valid === true)
    signal submitted(var preset)

    cardWidth: PrSkin.body * 56
    title: Translation.tr("Quick edit")

    onOpenChanged: {
        if (!root.open) return;
        root.rows = root.preset ? Logic.flatten(root.preset) : [];
        root.edits = ({});
        search.text = "";
    }

    function groupLabel(id: string): string {
        const group = Logic.GROUPS.find(g => g.id === id);
        return group ? Translation.tr(group.label) : Translation.tr("Other");
    }
    function setEdit(entry: var, raw: string, value: var, valid: bool): void {
        const next = Object.assign({}, root.edits);
        if (valid && value === entry.value) delete next[entry.text];
        else next[entry.text] = { raw: raw, value: value, valid: valid, removed: false };
        root.edits = next;
    }
    function remove(entry: var): void {
        const next = Object.assign({}, root.edits);
        next[entry.text] = { raw: "", value: undefined, valid: true, removed: true };
        root.edits = next;
    }
    function revert(entry: var): void {
        const next = Object.assign({}, root.edits);
        delete next[entry.text];
        root.edits = next;
    }
    function result(): var {
        let out = root.preset;
        root.rows.forEach(row => {
            const edit = root.edits[row.text];
            if (edit === undefined) return;
            out = edit.removed ? Logic.removeValue(out, row.path) : Logic.setValue(out, row.path, edit.value);
        });
        return out;
    }

    PrText {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        color: PrSkin.muted
        text: Translation.tr("Change a value, or remove a setting so applying the preset leaves it as it is on your desktop.")
    }
    PrField {
        id: search
        Layout.fillWidth: true
        icon: "search"
        placeholder: Translation.tr("Search settings")
        onTextChanged: root.query = text
    }
    ListView {
        id: list
        Layout.fillWidth: true
        Layout.preferredHeight: PrSkin.body * 24
        clip: true
        model: root.shownRows
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: PrScrollBar {}
        delegate: QuickEditRow {
            id: item
            required property var modelData
            width: ListView.view.width
            entry: item.modelData
            edit: root.edits[item.modelData.text]
            groupLabel: root.groupLabel(item.modelData.group)
            onEdited: (raw, value, valid) => root.setEdit(item.modelData, raw, value, valid)
            onRemoveRequested: root.remove(item.modelData)
            onRevertRequested: root.revert(item.modelData)
        }
        PrText {
            visible: root.shownRows.length === 0
            anchors.centerIn: parent
            width: parent.width - PrSkin.pad * 2
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            color: PrSkin.muted
            text: root.rows.length === 0 ? Translation.tr("This preset has no settings.") : Translation.tr("No setting matches the search.")
        }
    }
    RowLayout {
        Layout.fillWidth: true
        PrText { Layout.fillWidth: true; role: "meta"; color: PrSkin.muted; text: root.changedCount > 0 ? Translation.tr("%1 changed").arg(root.changedCount) : "" }
        PrButton { label: Translation.tr("Cancel"); onClicked: root.closed() }
        PrButton {
            label: Translation.tr("Save")
            primary: true
            enabled: root.changedCount > 0 && root.valid
            onClicked: root.submitted(root.result())
        }
    }
}
