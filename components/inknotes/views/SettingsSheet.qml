import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import "../skin"
import "../state"
import "../logic/NotesLogic.js" as Logic

// Where the notes are, how they are sorted, how long the trash keeps them.
InkSheet {
    id: root
    required property string rootPath
    readonly property bool typing: custom.focused
    title: Translation.tr("Settings")
    property bool customInvalid: false

    onOpenChanged: if (root.open) { custom.text = InkOptions.customPath; root.customInvalid = false }

    InkText { Layout.fillWidth: true; text: Translation.tr("Notes location"); color: InkSkin.muted; role: "meta" }
    InkSelect {
        current: InkOptions.location
        options: [
            { value: "documents", label: Translation.tr("Documents folder") },
            { value: "hidden", label: Translation.tr("Hidden app folder") },
            { value: "custom", label: Translation.tr("Another folder") }
        ]
        onPicked: value => InkOptions.set("location", value)
    }
    RowLayout {
        Layout.fillWidth: true
        visible: InkOptions.location === "custom"
        InkField { id: custom; Layout.fillWidth: true; placeholder: Translation.tr("Absolute folder path") }
        InkButton {
            label: Translation.tr("Use folder")
            onClicked: {
                root.customInvalid = !Logic.validRoot(custom.text);
                if (!root.customInvalid) InkOptions.set("customPath", custom.text);
            }
        }
    }
    InkText {
        visible: root.customInvalid
        Layout.fillWidth: true; wrapMode: Text.Wrap; color: InkSkin.danger
        text: Translation.tr("Use an absolute path without \"..\" that is not inside a trash folder.")
    }
    InkText { Layout.fillWidth: true; wrapMode: Text.Wrap; role: "meta"; color: InkSkin.muted; text: root.rootPath + "\n" + Translation.tr("Changing the location does not move your notes.") }

    InkText { Layout.fillWidth: true; text: Translation.tr("Sort notes by"); color: InkSkin.muted; role: "meta" }
    InkSelect {
        current: InkOptions.sort
        fallback: Translation.tr("Last edited")
        options: [{ value: "edited", label: Translation.tr("Last edited") }, { value: "title", label: Translation.tr("Title") }]
        onPicked: value => InkOptions.set("sort", value)
    }
    InkText { Layout.fillWidth: true; text: Translation.tr("Keep trashed notes"); color: InkSkin.muted; role: "meta" }
    InkSelect {
        current: InkOptions.trashDays
        fallback: Translation.tr("30 days")
        options: [
            { value: 7, label: Translation.tr("7 days") },
            { value: 30, label: Translation.tr("30 days") },
            { value: 90, label: Translation.tr("90 days") },
            { value: 0, label: Translation.tr("Never delete") }
        ]
        onPicked: value => InkOptions.set("trashDays", value)
    }
    RowLayout {
        Layout.fillWidth: true
        InkButton { label: Translation.tr("Open notes folder"); symbol: "open_in_new"; onClicked: Quickshell.execDetached(["xdg-open", root.rootPath]) }
        Item { Layout.fillWidth: true }
        InkButton { label: Translation.tr("Done"); primary: true; onClicked: root.closed() }
    }
}
