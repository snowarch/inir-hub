import QtQuick
import QtQuick.Layouts
import qs.services
import "../skin"
import "../logic/PresetLogic.js" as Logic

// Three questions about groups of settings. save: name, folder and the groups to keep from the current look.
// update: the groups to read again from the current look. edit: the groups the preset keeps.
InkSheet {
    id: root
    property string mode: "save"
    property var available: []
    property var selected: []
    property var folders: []
    property string folder: ""
    property string presetName: ""
    property bool reading: false
    readonly property bool typing: nameField.focused
    readonly property bool named: root.mode !== "save" || root.presetName.trim() !== ""
    signal submitted(string name, string folder, var groups)

    cardWidth: InkSkin.body * 30
    title: root.mode === "save" ? Translation.tr("Save current look") : root.mode === "update" ? Translation.tr("Update from current look") : Translation.tr("Edit saved groups")

    onOpenChanged: if (root.open && root.mode === "save") { nameField.text = root.presetName; focusLater.restart() }
    Timer { id: focusLater; interval: 0; onTriggered: nameField.focusField() }

    function toggle(id: string, on: bool): void {
        root.selected = on ? root.selected.concat([id]) : root.selected.filter(x => x !== id);
    }

    InkField {
        id: nameField
        visible: root.mode === "save"
        Layout.fillWidth: true
        placeholder: Translation.tr("Preset name")
        onTextChanged: root.presetName = text
        onAccepted: if (root.selected.length > 0 && root.named) root.submitted(root.presetName.trim(), root.folder, root.selected)
    }
    InkText { visible: root.mode === "save"; Layout.fillWidth: true; text: Translation.tr("Folder"); role: "label" }
    InkSelect {
        visible: root.mode === "save"
        current: root.folder
        fallback: Translation.tr("No folder")
        options: [{ value: "", label: Translation.tr("No folder") }].concat(root.folders.map(f => ({ value: f, label: f })))
        onPicked: value => root.folder = value
    }
    InkText {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        color: InkSkin.muted
        text: root.reading ? Translation.tr("Reading the current look…")
            : root.mode === "save" ? Translation.tr("Groups to keep. A group the current look does not have cannot be chosen.")
            : root.mode === "update" ? Translation.tr("Groups to read again from the current look. The others stay as saved.")
            : Translation.tr("Groups the preset keeps. A group you leave out is removed from it.")
    }
    Repeater {
        model: Logic.GROUPS
        GroupCheck {
            id: check
            required property var modelData
            Layout.fillWidth: true
            label: Translation.tr(check.modelData.label)
            enabled: root.available.indexOf(check.modelData.id) >= 0
            checked: root.selected.indexOf(check.modelData.id) >= 0
            onToggled: value => root.toggle(check.modelData.id, value)
        }
    }
    InkText {
        visible: !root.reading && root.available.length === 0
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        color: InkSkin.danger
        text: Translation.tr("No settings could be read from the current look.")
    }
    RowLayout {
        Layout.fillWidth: true
        Item { Layout.fillWidth: true }
        InkButton { label: Translation.tr("Cancel"); onClicked: root.closed() }
        InkButton {
            label: root.mode === "save" ? Translation.tr("Save") : Translation.tr("Update")
            primary: true
            enabled: !root.reading && root.selected.length > 0 && root.named
            onClicked: root.submitted(root.presetName.trim(), root.folder, root.selected)
        }
    }
}
