import QtQuick
import QtQuick.Layouts
import qs.services
import "../skin"
import "../logic/PresetLogic.js" as Logic

// One setting of a preset: its group, its path and an editor for its value.
Item {
    id: root
    required property var entry
    property var edit: undefined
    property string groupLabel: ""
    signal edited(string raw, var value, bool valid)
    signal removeRequested()
    signal revertRequested()
    readonly property bool removed: root.edit !== undefined && root.edit.removed === true
    readonly property bool changed: root.edit !== undefined
    readonly property bool invalid: root.edit !== undefined && !root.removed && root.edit.valid === false
    readonly property bool on: root.edit !== undefined && !root.removed ? root.edit.value === true : root.entry.value === true
    readonly property bool typed: root.entry.kind === "number" || root.entry.kind === "string"
    property string lastRaw: ""
    implicitHeight: column.implicitHeight + PrSkin.small

    function revert(): void {
        const text = String(root.entry.value);
        root.lastRaw = text;
        field.text = text;
        root.revertRequested();
    }

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0
        RowLayout {
            Layout.fillWidth: true
            spacing: PrSkin.small
            opacity: root.removed ? 0.45 : 1
            Chip { text: root.groupLabel }
            PrText {
                Layout.fillWidth: true
                Layout.preferredWidth: PrSkin.body * 10
                text: root.entry.text
                role: "mono"
                color: PrSkin.muted
                elide: Text.ElideMiddle
                font.strikeout: root.removed
            }
            PrButton {
                visible: root.entry.kind === "bool"
                enabled: !root.removed
                label: root.on ? Translation.tr("On") : Translation.tr("Off")
                toggled: root.on
                onClicked: root.edited(String(!root.on), !root.on, true)
            }
            PrField {
                id: field
                visible: root.typed
                enabled: !root.removed
                Layout.preferredWidth: PrSkin.body * 14
                Component.onCompleted: {
                    const raw = root.edit !== undefined && root.edit.raw !== undefined ? root.edit.raw : String(root.entry.value);
                    root.lastRaw = raw;
                    field.text = root.typed ? raw : "";
                }
                onTextChanged: {
                    if (!root.typed || field.text === root.lastRaw) return;
                    root.lastRaw = field.text;
                    const parsed = Logic.parseValue(root.entry.kind, field.text);
                    root.edited(field.text, parsed.value, parsed.ok);
                }
            }
            PrText {
                visible: root.entry.kind === "json"
                Layout.preferredWidth: PrSkin.body * 14
                text: root.entry.shown
                role: "mono"
            }
            PrButton {
                visible: root.changed
                symbol: "undo"; quiet: true; hint: Translation.tr("Revert")
                onClicked: root.revert()
            }
            PrButton {
                visible: !root.removed
                symbol: "delete"; quiet: true; danger: true; hint: Translation.tr("Remove")
                onClicked: root.removeRequested()
            }
        }
        PrText {
            visible: root.invalid
            Layout.fillWidth: true
            role: "meta"
            color: PrSkin.danger
            text: Translation.tr("Enter a number.")
        }
    }
}
