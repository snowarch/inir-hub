import QtQuick
import QtQuick.Layouts
import qs.services
import "../skin"
import "../state"
import "../editor"
import "../logic/NotesLogic.js" as Logic

// The open note: its title and state, the format bar, the text.
Rectangle {
    id: root
    property string rel: ""
    property string folderName: ""
    property string saveState: "saved"
    property bool narrow: false
    readonly property alias editor: rich
    readonly property bool has: root.rel !== ""
    readonly property var font: InkOptions.fontOf(root.rel)
    readonly property int percent: Math.max(80, Math.min(200, InkOptions.zoom))
    readonly property real sizeFactor: ({ small: 0.85, large: 1.2, larger: 1.45 })[root.font.size] ?? 1
    signal renameRequested()
    signal backRequested()
    signal foldersToggled()
    signal listToggled()
    signal newNote()
    signal linkRequested()
    color: InkSkin.side
    radius: InkSkin.cardRadius

    function setZoom(percent: int): void { InkOptions.set("zoom", Math.max(80, Math.min(200, percent))) }
    function zoomBy(direction: int): void { root.setZoom(root.percent + direction * 10) }
    function toggleRaw(): void { rich.setRaw(!rich.rawMode) }

    readonly property var marks: [
        { sym: "format_bold", hint: Translation.tr("Bold (Ctrl+B)"), on: rich.fmt.bold, act: () => rich.toggleInline("bold") },
        { sym: "format_italic", hint: Translation.tr("Italic (Ctrl+I)"), on: rich.fmt.italic, act: () => rich.toggleInline("italic") },
        { sym: "format_strikethrough", hint: Translation.tr("Strikethrough (Ctrl+Shift+X)"), on: rich.fmt.strikeout, act: () => rich.toggleInline("strikeout") },
        { sym: "code", hint: Translation.tr("Inline code (Ctrl+E)"), on: false, act: () => rich.inlineCode() },
        { sym: "link", hint: Translation.tr("Link (Ctrl+K)"), on: false, act: () => root.linkRequested() },
        { sym: "format_list_bulleted", hint: Translation.tr("Bullets (Ctrl+Shift+8)"), on: false, act: () => rich.block("ul") },
        { sym: "format_list_numbered", hint: Translation.tr("Numbers (Ctrl+Shift+7)"), on: false, act: () => rich.block("ol") },
        { sym: "checklist", hint: Translation.tr("Checklist (Ctrl+Shift+9)"), on: false, act: () => rich.block("task") },
        { sym: "data_object", hint: Translation.tr("Code block"), on: false, act: () => rich.block("code") }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: InkSkin.gap
        spacing: InkSkin.gap

        RowLayout {
            Layout.fillWidth: true
            spacing: InkSkin.small
            InkButton { visible: root.narrow; symbol: "arrow_back"; quiet: true; hint: Translation.tr("Back"); onClicked: root.backRequested() }
            InkButton {
                visible: !root.narrow; symbol: "folder"; quiet: true; toggled: InkOptions.showFolders
                hint: Translation.tr("Folders (Ctrl+\\)"); onClicked: root.foldersToggled()
            }
            InkButton {
                visible: !root.narrow; symbol: "format_list_bulleted"; quiet: true; toggled: InkOptions.showList
                hint: Translation.tr("Note list (Ctrl+Shift+\\)"); onClicked: root.listToggled()
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                InkText {
                    id: title
                    Layout.fillWidth: true
                    text: root.has ? Logic.titleOf(root.rel) : ""
                    role: "title"
                    MouseArea { anchors.fill: parent; enabled: root.has; cursorShape: Qt.PointingHandCursor; onClicked: root.renameRequested() }
                }
                InkText {
                    Layout.fillWidth: true
                    visible: root.has
                    role: "meta"; color: InkSkin.muted
                    text: (root.folderName !== "" ? root.folderName : Translation.tr("No folder")) + "  ·  "
                        + (root.saveState === "saving" ? Translation.tr("Saving…") : root.saveState === "failed" ? Translation.tr("Could not save") : Translation.tr("Saved"))
                }
            }
            InkButton {
                visible: root.has; symbol: "build"; quiet: true; toggled: InkOptions.showToolbar
                hint: Translation.tr("Format bar (Ctrl+Shift+T)"); onClicked: InkOptions.set("showToolbar", !InkOptions.showToolbar)
            }
        }

        Flow {
            Layout.fillWidth: true
            visible: root.has && InkOptions.showToolbar
            spacing: InkSkin.small
            InkGroup {
                InkButton { symbol: "undo"; quiet: true; hint: Translation.tr("Undo (Ctrl+Z)"); onClicked: rich.undo() }
                InkButton { symbol: "redo"; quiet: true; hint: Translation.tr("Redo (Ctrl+Shift+Z)"); onClicked: rich.redo() }
            }
            InkGroup {
                InkSelect {
                    quiet: true
                    symbol: "title"; fallback: Translation.tr("Text style"); hint: Translation.tr("Paragraph style")
                    options: [
                        { value: "p", label: Translation.tr("Body (Ctrl+0)") },
                        { value: "h1", label: Translation.tr("Heading 1 (Ctrl+1)") },
                        { value: "h2", label: Translation.tr("Heading 2 (Ctrl+2)") },
                        { value: "h3", label: Translation.tr("Heading 3 (Ctrl+3)") }
                    ]
                    onPicked: value => { rich.block(value); rich.focusEditor() }
                }
            }
            InkGroup {
                Repeater {
                    model: root.marks.slice(0, 5)
                    InkButton {
                        required property var modelData
                        symbol: modelData.sym; quiet: true; toggled: modelData.on; hint: modelData.hint
                        onClicked: { modelData.act(); rich.focusEditor() }
                    }
                }
            }
            InkGroup {
                Repeater {
                    model: root.marks.slice(5)
                    InkButton {
                        required property var modelData
                        symbol: modelData.sym; quiet: true; toggled: modelData.on; hint: modelData.hint
                        onClicked: { modelData.act(); rich.focusEditor() }
                    }
                }
            }
            InkGroup {
                InkSelect {
                    quiet: true
                    symbol: "text_fields"; hint: Translation.tr("Font"); current: root.font.family
                    options: [
                        { value: "default", label: Translation.tr("Default font") },
                        { value: "serif", label: Translation.tr("Serif") },
                        { value: "mono", label: Translation.tr("Mono") }
                    ]
                    onPicked: value => InkOptions.setFont(root.rel, "family", value)
                }
                InkSelect {
                    quiet: true
                    symbol: "format_size"; hint: Translation.tr("Text size"); current: root.font.size
                    options: [
                        { value: "small", label: Translation.tr("Small") },
                        { value: "default", label: Translation.tr("Default size") },
                        { value: "large", label: Translation.tr("Large") },
                        { value: "larger", label: Translation.tr("Larger") }
                    ]
                    onPicked: value => InkOptions.setFont(root.rel, "size", value)
                }
                InkButton { label: root.percent + "%"; quiet: true; hint: Translation.tr("Reset zoom (Ctrl+= and Ctrl+- change it)"); onClicked: root.setZoom(100) }
            }
            InkGroup {
                InkButton {
                    symbol: "markdown"; quiet: true; toggled: rich.rawMode
                    hint: Translation.tr("Markdown text (Ctrl+Shift+M)"); onClicked: { root.toggleRaw(); rich.focusEditor() }
                }
            }
        }

        RichEditor {
            id: rich
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.has
            ink: InkSkin.text
            muted: InkSkin.muted
            selection: InkSkin.accent
            selectionInk: InkSkin.onAccent
            linkInk: InkSkin.accent
            fontFamily: root.font.family === "serif" ? "serif" : root.font.family === "mono" ? "monospace" : InkSkin.mainFont
            monoFamily: InkSkin.monoFont
            pixelSize: Math.round(InkSkin.body * 1.1 * root.percent / 100 * root.sizeFactor)
            margin: InkSkin.pad
            onLinkRequested: root.linkRequested()
            onZoomStep: direction => root.zoomBy(direction)
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.has
            spacing: InkSkin.gap
            Item { Layout.fillHeight: true }
            InkText { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: Translation.tr("No note is open."); role: "title" }
            InkText {
                Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; color: InkSkin.muted
                text: Translation.tr("Choose a note from the list, or start a new one.")
            }
            InkButton { Layout.alignment: Qt.AlignHCenter; label: Translation.tr("New note"); symbol: "add"; primary: true; onClicked: root.newNote() }
            Item { Layout.fillHeight: true }
        }
    }
}
